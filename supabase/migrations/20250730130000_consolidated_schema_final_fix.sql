-- ------------------------------------------------------------------------------------
-- Consolidated Initial Schema for AutoParts POS
-- Version: 4.0 (Final Fix)
-- Description: This script sets up the entire database schema, including tables,
--              custom types, functions, RLS policies, and initial seed data.
--              This version fixes all previous syntax errors.
-- ------------------------------------------------------------------------------------

--
-- Enable HTTP extension
--
CREATE EXTENSION IF NOT EXISTS http WITH SCHEMA extensions;

--
-- Create custom ENUM type for user roles (Idempotent way)
--
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE public.user_role AS ENUM (
            'store_owner',
            'warehouse_admin',
            'shopkeeper'
        );
    END IF;
END
$$;

--
-- Create custom ENUM type for customer types
--
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'customer_type') THEN
        CREATE TYPE public.customer_type AS ENUM (
            'retail',
            'wholesale'
        );
    END IF;
END
$$;

--
-- Create custom ENUM type for payment methods
--
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_method') THEN
        CREATE TYPE public.payment_method AS ENUM (
            'cash',
            'card',
            'transfer',
            'qris'
        );
    END IF;
END
$$;

--
-- Create custom ENUM type for shift status
--
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'shift_status') THEN
        CREATE TYPE public.shift_status AS ENUM (
            'open',
            'closed'
        );
    END IF;
END
$$;

--
-- Create custom ENUM type for inventory movement types
--
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'inventory_movement_type') THEN
        CREATE TYPE public.inventory_movement_type AS ENUM (
            'in',
            'out',
            'adjustment'
        );
    END IF;
END
$$;


-- ------------------------------------------------------------------------------------
-- TABLE: profiles
-- Stores user profile information, linked to auth.users
-- ------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    updated_at timestamp with time zone,
    full_name text NOT NULL,
    avatar_url text,
    role public.user_role NOT NULL DEFAULT 'shopkeeper'::public.user_role
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------------
-- TABLE: categories
-- Stores product categories like 'Engine', 'Brake', 'Suspension'
-- ------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.categories (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL UNIQUE,
    description text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------------
-- TABLE: brands
-- Stores product brands like 'Toyota', 'Bosch', 'Denso'
-- ------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.brands (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL UNIQUE,
    country text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);
ALTER TABLE public.brands ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------------
-- TABLE: car_models
-- Stores car models and their specifications
-- ------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.car_models (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    brand text NOT NULL,
    model text NOT NULL,
    year_start integer NOT NULL,
    year_end integer,
    variant text,
    engine_code text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);
ALTER TABLE public.car_models ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------------
-- TABLE: products
-- Stores all product information
-- ------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.products (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    description text,
    price numeric(10,2) NOT NULL DEFAULT 0.00,
    stock integer NOT NULL DEFAULT 0,
    min_stock integer NOT NULL DEFAULT 5,
    category_id uuid REFERENCES public.categories(id),
    brand_id uuid REFERENCES public.brands(id),
    part_number text NOT NULL,
    barcode text,
    image_url text,
    weight numeric(8,2),
    dimensions text,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    UNIQUE(part_number, brand_id)
);
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_products_name ON public.products USING gin (to_tsvector('simple'::regconfig, name));
CREATE INDEX IF NOT EXISTS idx_products_part_number ON public.products(part_number);

-- ------------------------------------------------------------------------------------
-- TABLE: product_car_compatibility
-- Maps products to compatible car models (many-to-many)
-- ------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.product_car_compatibility (
    product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    car_model_id uuid NOT NULL REFERENCES public.car_models(id) ON DELETE CASCADE,
    PRIMARY KEY (product_id, car_model_id)
);
ALTER TABLE public.product_car_compatibility ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------------
-- TABLE: customers
-- Stores customer information
-- ------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.customers (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    phone text NOT NULL UNIQUE,
    email text,
    address text,
    customer_type public.customer_type NOT NULL DEFAULT 'retail'::public.customer_type,
    total_purchases numeric(12,2) NOT NULL DEFAULT 0.00,
    last_purchase timestamp with time zone,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------------
-- TABLE: shifts
-- Tracks staff work shifts
-- ------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.shifts (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    staff_id uuid NOT NULL REFERENCES public.profiles(id),
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone,
    opening_cash numeric(10,2) NOT NULL,
    closing_cash numeric(10,2),
    total_sales numeric(12,2),
    total_transactions integer,
    status public.shift_status NOT NULL DEFAULT 'open'::public.shift_status
);
ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------------
-- TABLE: transactions
-- Records all sales transactions
-- ------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.transactions (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id uuid REFERENCES public.customers(id),
    staff_id uuid NOT NULL REFERENCES public.profiles(id),
    shift_id uuid REFERENCES public.shifts(id),
    transaction_date timestamp with time zone NOT NULL DEFAULT now(),
    subtotal numeric(10,2) NOT NULL,
    tax numeric(10,2) NOT NULL,
    discount numeric(10,2) NOT NULL DEFAULT 0.00,
    total_amount numeric(10,2) NOT NULL,
    payment_method public.payment_method NOT NULL,
    payment_amount numeric(10,2) NOT NULL,
    change_amount numeric(10,2) NOT NULL DEFAULT 0.00,
    notes text
);
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------------
-- TABLE: transaction_items
-- Details of items within a transaction (many-to-many)
-- ------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.transaction_items (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    transaction_id uuid NOT NULL REFERENCES public.transactions(id) ON DELETE CASCADE,
    product_id uuid NOT NULL REFERENCES public.products(id),
    quantity integer NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    subtotal numeric(10,2) NOT NULL
);
ALTER TABLE public.transaction_items ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------------
-- TABLE: inventory_movements
-- Tracks all stock movements
-- ------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.inventory_movements (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id uuid NOT NULL REFERENCES public.products(id),
    movement_type public.inventory_movement_type NOT NULL,
    quantity integer NOT NULL,
    reference_type text,
    reference_id text,
    notes text,
    created_at timestamp with time zone NOT NULL DEFAULT now()
);
ALTER TABLE public.inventory_movements ENABLE ROW LEVEL SECURITY;


-- ------------------------------------------------------------------------------------
-- FUNCTIONS
-- ------------------------------------------------------------------------------------

-- Function to get the role of the currently authenticated user
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS public.user_role
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

-- Function to automatically create a profile when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url)
  VALUES (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');
  RETURN new;
END;
$$;

-- Trigger for handle_new_user
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Function to update product stock and log movement
CREATE OR REPLACE FUNCTION public.update_product_stock_on_sale(p_product_id uuid, p_quantity_sold integer, p_transaction_id uuid)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    -- Update product stock
    UPDATE public.products
    SET stock = stock - p_quantity_sold
    WHERE id = p_product_id;

    -- Log inventory movement
    INSERT INTO public.inventory_movements (product_id, movement_type, quantity, reference_type, reference_id)
    VALUES (p_product_id, 'out', -p_quantity_sold, 'transaction', p_transaction_id::text);
END;
$$;


-- ------------------------------------------------------------------------------------
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ------------------------------------------------------------------------------------

-- Profiles
CREATE POLICY "Users can view their own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
CREATE POLICY "Store owners can manage all profiles" ON public.profiles FOR ALL USING (public.get_my_role() = 'store_owner');

-- Categories, Brands, Car Models (General Read Access, Admin Write Access)
CREATE POLICY "Allow public read access" ON public.categories FOR SELECT USING (true);
CREATE POLICY "Allow admin write access" ON public.categories FOR ALL USING (public.get_my_role() IN ('store_owner', 'warehouse_admin'));

CREATE POLICY "Allow public read access" ON public.brands FOR SELECT USING (true);
CREATE POLICY "Allow admin write access" ON public.brands FOR ALL USING (public.get_my_role() IN ('store_owner', 'warehouse_admin'));

CREATE POLICY "Allow public read access" ON public.car_models FOR SELECT USING (true);
CREATE POLICY "Allow admin write access" ON public.car_models FOR ALL USING (public.get_my_role() IN ('store_owner', 'warehouse_admin'));

-- Products
CREATE POLICY "Allow public read access to active products" ON public.products FOR SELECT USING (is_active = true);
CREATE POLICY "Allow authenticated read access" ON public.products FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Allow admin write access" ON public.products FOR ALL USING (public.get_my_role() IN ('store_owner', 'warehouse_admin'));

-- Product Car Compatibility
CREATE POLICY "Allow public read access" ON public.product_car_compatibility FOR SELECT USING (true);
CREATE POLICY "Allow admin write access" ON public.product_car_compatibility FOR ALL USING (public.get_my_role() IN ('store_owner', 'warehouse_admin'));

-- Customers
CREATE POLICY "Allow staff to view customers" ON public.customers FOR SELECT USING (public.get_my_role() IN ('store_owner', 'shopkeeper'));
CREATE POLICY "Allow staff to manage customers" ON public.customers FOR INSERT WITH CHECK (public.get_my_role() IN ('store_owner', 'shopkeeper'));
CREATE POLICY "Allow staff to manage customers" ON public.customers FOR UPDATE USING (public.get_my_role() IN ('store_owner', 'shopkeeper'));

-- Shifts
CREATE POLICY "Users can manage their own shifts" ON public.shifts FOR ALL USING (auth.uid() = staff_id);
CREATE POLICY "Store owners can view all shifts" ON public.shifts FOR SELECT USING (public.get_my_role() = 'store_owner');

-- Transactions & Transaction Items
CREATE POLICY "Staff can create transactions" ON public.transactions FOR INSERT WITH CHECK (auth.uid() = staff_id);
CREATE POLICY "Staff can view their own transactions" ON public.transactions FOR SELECT USING (auth.uid() = staff_id);
CREATE POLICY "Store owners can view all transactions" ON public.transactions FOR SELECT USING (public.get_my_role() = 'store_owner');

CREATE POLICY "Allow related access for transaction items" ON public.transaction_items FOR ALL USING (
  (SELECT public.get_my_role() = 'store_owner') OR
  (EXISTS (SELECT 1 FROM transactions WHERE id = transaction_id AND staff_id = auth.uid()))
);

-- Inventory Movements
CREATE POLICY "Admins can view inventory movements" ON public.inventory_movements FOR SELECT USING (public.get_my_role() IN ('store_owner', 'warehouse_admin'));
CREATE POLICY "System can insert inventory movements" ON public.inventory_movements FOR INSERT WITH CHECK (true); -- Handled by functions

-- ------------------------------------------------------------------------------------
-- SEED DATA
-- ------------------------------------------------------------------------------------
-- Note: This is a small subset of data for demonstration purposes.

-- Insert Categories
INSERT INTO public.categories (name, description) VALUES
('Filter', 'Filter udara, oli, bensin, dll'),
('Rem', 'Kampas rem, piringan, minyak rem'),
('Suspensi', 'Shock absorber, per, bushing'),
('Mesin', 'Busi, timing belt, oli mesin'),
('Kelistrikan', 'Aki, bohlam, sekring')
ON CONFLICT (name) DO NOTHING;

-- Insert Brands
INSERT INTO public.brands (name, country) VALUES
('Toyota Genuine Parts', 'Jepang'),
('Daihatsu Genuine Parts', 'Jepang'),
('Honda Genuine Parts', 'Jepang'),
('Bosch', 'Jerman'),
('Denso', 'Jepang'),
('NGK', 'Jepang'),
('Brembo', 'Italia'),
('KYB', 'Jepang')
ON CONFLICT (name) DO NOTHING;

-- Insert Car Models
INSERT INTO public.car_models (brand, model, year_start, year_end, variant) VALUES
('Toyota', 'Avanza', 2015, 2021, '1.3 G'),
('Daihatsu', 'Xenia', 2015, 2023, '1.3 R'),
('Honda', 'Brio', 2018, 2023, 'Satya E')
ON CONFLICT DO NOTHING;

-- Insert Products (Example)
-- This requires getting UUIDs from previously inserted data.
-- For a real seed, you'd use variables. For this script, we'll skip complex product seeding.
-- You can add products through the application's UI.

-- Example of how to add a product if you knew the IDs:
-- WITH cat AS (SELECT id FROM categories WHERE name = 'Filter'),
--      brd AS (SELECT id FROM brands WHERE name = 'Denso')
-- INSERT INTO public.products (name, price, stock, category_id, brand_id, part_number)
-- SELECT 'Filter Udara Avanza/Xenia', 150000, 50, cat.id, brd.id, 'DXA-1109'
-- FROM cat, brd
-- ON CONFLICT (part_number, brand_id) DO NOTHING;

-- ------------------------------------------------------------------------------------
-- END OF SCRIPT
-- ------------------------------------------------------------------------------------
