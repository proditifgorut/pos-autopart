-- =================================================================
-- Consolidated Initial Schema for AutoParts POS
-- Version: 4.0 (Idempotent Fix)
-- Description: This single script sets up the entire database schema,
-- including tables, types, functions, RLS policies, and initial data.
-- It is designed to be idempotent and fixes previous syntax errors.
-- =================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =================================================================
-- SECTION 1: CUSTOM TYPES (ENUMS) - Idempotent Creation
-- =================================================================

-- User Role ENUM
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE public.user_role AS ENUM (
            'store_owner',
            'warehouse_admin',
            'shopkeeper'
        );
    END IF;
END$$;

-- Payment Method ENUM
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_method_enum') THEN
        CREATE TYPE public.payment_method_enum AS ENUM (
            'cash',
            'card',
            'transfer',
            'qris'
        );
    END IF;
END$$;

-- Shift Status ENUM
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'shift_status_enum') THEN
        CREATE TYPE public.shift_status_enum AS ENUM (
            'open',
            'closed'
        );
    END IF;
END$$;

-- Inventory Movement Type ENUM
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'inventory_movement_type_enum') THEN
        CREATE TYPE public.inventory_movement_type_enum AS ENUM (
            'in',
            'out',
            'adjustment',
            'sale'
        );
    END IF;
END$$;

-- Customer Type ENUM
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'customer_type_enum') THEN
        CREATE TYPE public.customer_type_enum AS ENUM (
            'retail',
            'wholesale'
        );
    END IF;
END$$;


-- =================================================================
-- SECTION 2: TABLES
-- =================================================================

-- Profiles Table (for user roles and extra data)
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    updated_at timestamptz,
    full_name text,
    avatar_url text,
    role public.user_role NOT NULL DEFAULT 'shopkeeper'
);

-- Categories Table
CREATE TABLE IF NOT EXISTS public.categories (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    name text NOT NULL UNIQUE,
    description text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Brands Table
CREATE TABLE IF NOT EXISTS public.brands (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    name text NOT NULL UNIQUE,
    country text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Products Table
CREATE TABLE IF NOT EXISTS public.products (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    name text NOT NULL,
    description text,
    price numeric NOT NULL DEFAULT 0,
    stock integer NOT NULL DEFAULT 0,
    min_stock integer NOT NULL DEFAULT 0,
    category_id uuid REFERENCES public.categories(id),
    brand_id uuid REFERENCES public.brands(id),
    part_number text NOT NULL,
    barcode text UNIQUE,
    image_url text,
    weight numeric,
    dimensions text,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(part_number, brand_id)
);

-- Customers Table
CREATE TABLE IF NOT EXISTS public.customers (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    name text NOT NULL,
    phone text NOT NULL UNIQUE,
    email text,
    address text,
    customer_type public.customer_type_enum NOT NULL DEFAULT 'retail',
    total_purchases numeric NOT NULL DEFAULT 0,
    last_purchase timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Shifts Table
CREATE TABLE IF NOT EXISTS public.shifts (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    staff_id uuid NOT NULL REFERENCES auth.users(id),
    start_time timestamptz NOT NULL,
    end_time timestamptz,
    opening_cash numeric NOT NULL,
    closing_cash numeric,
    total_sales numeric,
    total_transactions integer,
    status public.shift_status_enum NOT NULL DEFAULT 'open'
);

-- Transactions Table
CREATE TABLE IF NOT EXISTS public.transactions (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    customer_id uuid REFERENCES public.customers(id),
    staff_id uuid NOT NULL REFERENCES auth.users(id),
    shift_id uuid REFERENCES public.shifts(id),
    transaction_date timestamptz NOT NULL DEFAULT now(),
    subtotal numeric NOT NULL,
    tax numeric NOT NULL,
    discount numeric NOT NULL,
    total_amount numeric NOT NULL,
    payment_method public.payment_method_enum NOT NULL,
    payment_amount numeric NOT NULL,
    change_amount numeric NOT NULL,
    notes text
);

-- Transaction Items Table
CREATE TABLE IF NOT EXISTS public.transaction_items (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    transaction_id uuid NOT NULL REFERENCES public.transactions(id) ON DELETE CASCADE,
    product_id uuid NOT NULL REFERENCES public.products(id),
    quantity integer NOT NULL,
    unit_price numeric NOT NULL,
    subtotal numeric NOT NULL
);

-- Inventory Movements Table
CREATE TABLE IF NOT EXISTS public.inventory_movements (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id uuid NOT NULL REFERENCES public.products(id),
    movement_type public.inventory_movement_type_enum NOT NULL,
    quantity integer NOT NULL,
    reference_type text,
    reference_id text,
    notes text,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- =================================================================
-- SECTION 3: DATABASE FUNCTIONS & TRIGGERS
-- =================================================================

-- Function to get the role of the current user
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS public.user_role
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

-- Trigger function to create a profile when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url, role)
  VALUES (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url', 'shopkeeper');
  RETURN new;
END;
$$;

-- Trigger to call the function on new user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- RPC to update stock and log movement
CREATE OR REPLACE FUNCTION public.update_product_stock_on_sale(p_product_id uuid, p_quantity_sold integer, p_transaction_id uuid)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    -- Update product stock
    UPDATE public.products
    SET stock = stock - p_quantity_sold
    WHERE id = p_product_id;

    -- Insert into inventory movements
    INSERT INTO public.inventory_movements (product_id, movement_type, quantity, reference_type, reference_id, notes)
    VALUES (p_product_id, 'sale', -p_quantity_sold, 'transaction', p_transaction_id::text, 'Sale transaction');
END;
$$;

-- =================================================================
-- SECTION 4: ROW LEVEL SECURITY (RLS)
-- =================================================================

-- Enable RLS for all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transaction_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_movements ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to prevent conflicts
DROP POLICY IF EXISTS "Profiles are viewable by users who created them." ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile." ON public.profiles;
DROP POLICY IF EXISTS "Store owners can manage all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Public can view categories" ON public.categories;
DROP POLICY IF EXISTS "Public can view brands" ON public.brands;
DROP POLICY IF EXISTS "Public can view active products" ON public.products;
DROP POLICY IF EXISTS "Admins can manage products" ON public.products;
DROP POLICY IF EXISTS "Shop staff can view customers" ON public.customers;
DROP POLICY IF EXISTS "Shop staff can insert customers" ON public.customers;
DROP POLICY IF EXISTS "Shop staff can update customers" ON public.customers;
DROP POLICY IF EXISTS "Users can view their own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Store owners can view all transactions" ON public.transactions;
DROP POLICY IF EXISTS "Shop staff can create transactions" ON public.transactions;
DROP POLICY IF EXISTS "Users can view items of transactions they can see" ON public.transaction_items;
DROP POLICY IF EXISTS "Shop staff can create transaction items" ON public.transaction_items;
DROP POLICY IF EXISTS "Users can manage their own shifts" ON public.shifts;
DROP POLICY IF EXISTS "Store owners can view all shifts" ON public.shifts;
DROP POLICY IF EXISTS "Admins can view inventory movements" ON public.inventory_movements;
DROP POLICY IF EXISTS "System can insert inventory movements (via functions)" ON public.inventory_movements;


-- Profiles Policies
CREATE POLICY "Profiles are viewable by users who created them." ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile." ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Store owners can manage all profiles" ON public.profiles FOR ALL USING (public.get_my_role() = 'store_owner');

-- Public Read-Only Policies (for non-sensitive data)
CREATE POLICY "Public can view categories" ON public.categories FOR SELECT USING (true);
CREATE POLICY "Public can view brands" ON public.brands FOR SELECT USING (true);
CREATE POLICY "Public can view active products" ON public.products FOR SELECT USING (is_active = true);

-- Product Management Policies
CREATE POLICY "Admins can manage products" ON public.products FOR ALL USING (public.get_my_role() IN ('store_owner', 'warehouse_admin'));

-- Customer Management Policies
CREATE POLICY "Shop staff can view customers" ON public.customers FOR SELECT USING (public.get_my_role() IN ('store_owner', 'shopkeeper'));
CREATE POLICY "Shop staff can insert customers" ON public.customers FOR INSERT WITH CHECK (public.get_my_role() IN ('store_owner', 'shopkeeper'));
CREATE POLICY "Shop staff can update customers" ON public.customers FOR UPDATE USING (public.get_my_role() IN ('store_owner', 'shopkeeper'));

-- Transaction Policies
CREATE POLICY "Users can view their own transactions" ON public.transactions FOR SELECT USING (staff_id = auth.uid());
CREATE POLICY "Store owners can view all transactions" ON public.transactions FOR SELECT USING (public.get_my_role() = 'store_owner');
CREATE POLICY "Shop staff can create transactions" ON public.transactions FOR INSERT WITH CHECK (public.get_my_role() IN ('store_owner', 'shopkeeper') AND staff_id = auth.uid());

-- Transaction Items Policies
CREATE POLICY "Users can view items of transactions they can see" ON public.transaction_items FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.transactions WHERE id = transaction_id
  )
);
CREATE POLICY "Shop staff can create transaction items" ON public.transaction_items FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.transactions WHERE id = transaction_id AND staff_id = auth.uid()
  )
);

-- Shift Policies
CREATE POLICY "Users can manage their own shifts" ON public.shifts FOR ALL USING (staff_id = auth.uid());
CREATE POLICY "Store owners can view all shifts" ON public.shifts FOR SELECT USING (public.get_my_role() = 'store_owner');

-- Inventory Movement Policies
CREATE POLICY "Admins can view inventory movements" ON public.inventory_movements FOR SELECT USING (public.get_my_role() IN ('store_owner', 'warehouse_admin'));
CREATE POLICY "System can insert inventory movements (via functions)" ON public.inventory_movements FOR INSERT WITH CHECK (true);

-- =================================================================
-- SECTION 5: DUMMY DATA
-- =================================================================

-- Insert Categories
INSERT INTO public.categories (name, description) VALUES
('Filter', 'Filter Udara, Oli, Bensin, AC'),
('Brake System', 'Kampas Rem, Piringan, Minyak Rem'),
('Suspension', 'Shock Absorber, Per, Bushing'),
('Engine Parts', 'Busi, Piston, Gasket'),
('Electrical', 'Aki, Bohlam, Sekring'),
('Body Parts', 'Bumper, Spion, Pintu'),
('Transmission', 'Kopling, Oli Transmisi'),
('Cooling System', 'Radiator, Thermostat, Water Pump'),
('Exhaust System', 'Knalpot, Muffler'),
('Fluids & Chemicals', 'Oli Mesin, Air Radiator, Pembersih')
ON CONFLICT (name) DO NOTHING;

-- Insert Brands
INSERT INTO public.brands (name, country) VALUES
('Toyota Genuine Parts', 'Japan'),
('Daihatsu Genuine Parts', 'Japan'),
('Honda Genuine Parts', 'Japan'),
('Bosch', 'Germany'),
('Denso', 'Japan'),
('NGK', 'Japan'),
('Brembo', 'Italy'),
('Monroe', 'USA'),
('KYB', 'Japan'),
('Philips', 'Netherlands'),
('Osram', 'Germany'),
('Aspira', 'Indonesia'),
('Federal Parts', 'Indonesia'),
('Kayaba', 'Japan'),
('Aisin', 'Japan')
ON CONFLICT (name) DO NOTHING;

-- =================================================================
-- END OF SCRIPT
-- =================================================================
