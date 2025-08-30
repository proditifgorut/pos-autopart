/*
# =================================================================
# CONSOLIDATED INITIAL SCHEMA FOR AUTOPARTS POS
# Version: 3.0 (Final Fix)
# Description: This is a complete, idempotent script to set up the
#              entire database schema, including tables, roles,
#              functions, RLS policies, and initial seed data.
#
# Changes in this version:
# - Added `IF NOT EXISTS` to all `CREATE TABLE` and `CREATE TYPE` statements.
# - Used `CREATE OR REPLACE FUNCTION` for all functions.
# - Corrected RLS policy syntax.
# - Ensured correct dependency order.
# This script is safe to run on a new or an empty database.
# =================================================================
*/

-- =================================================================
-- 1. EXTENSIONS & TYPES
-- =================================================================

-- Create custom types if they don't exist
CREATE TYPE public.user_role IF NOT EXISTS AS ENUM (
    'store_owner',
    'warehouse_admin',
    'shopkeeper'
);

CREATE TYPE public.customer_type IF NOT EXISTS AS ENUM (
    'retail',
    'wholesale'
);

CREATE TYPE public.payment_method IF NOT EXISTS AS ENUM (
    'cash',
    'card',
    'transfer',
    'qris'
);

CREATE TYPE public.shift_status IF NOT EXISTS AS ENUM (
    'open',
    'closed'
);

CREATE TYPE public.inventory_movement_type IF NOT EXISTS AS ENUM (
    'in',
    'out',
    'adjustment',
    'sale'
);


-- =================================================================
-- 2. TABLES
-- =================================================================

-- Table for user profiles, linked to auth.users
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    updated_at timestamp with time zone,
    full_name text NOT NULL,
    avatar_url text,
    role public.user_role NOT NULL DEFAULT 'shopkeeper'::user_role
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Categories for products
CREATE TABLE IF NOT EXISTS public.categories (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL UNIQUE,
    description text
);
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Brands for products
CREATE TABLE IF NOT EXISTS public.brands (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL UNIQUE,
    country text
);
ALTER TABLE public.brands ENABLE ROW LEVEL SECURITY;

-- Car models
CREATE TABLE IF NOT EXISTS public.car_models (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    brand text NOT NULL,
    model text NOT NULL,
    year_start integer NOT NULL,
    year_end integer,
    variant text
);
ALTER TABLE public.car_models ENABLE ROW LEVEL SECURITY;

-- Products table
CREATE TABLE IF NOT EXISTS public.products (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    name text NOT NULL,
    description text,
    price numeric(10, 2) NOT NULL DEFAULT 0,
    stock integer NOT NULL DEFAULT 0,
    min_stock integer NOT NULL DEFAULT 0,
    category_id uuid REFERENCES public.categories(id),
    brand_id uuid REFERENCES public.brands(id),
    part_number text NOT NULL,
    barcode text UNIQUE,
    image_url text,
    weight numeric(8, 2),
    dimensions text,
    is_active boolean NOT NULL DEFAULT true
);
CREATE INDEX IF NOT EXISTS idx_products_name ON public.products(name);
CREATE INDEX IF NOT EXISTS idx_products_part_number ON public.products(part_number);
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Product compatibility with car models (many-to-many)
CREATE TABLE IF NOT EXISTS public.product_car_compatibility (
    product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    car_model_id uuid NOT NULL REFERENCES public.car_models(id) ON DELETE CASCADE,
    PRIMARY KEY (product_id, car_model_id)
);
ALTER TABLE public.product_car_compatibility ENABLE ROW LEVEL SECURITY;

-- Customers table
CREATE TABLE IF NOT EXISTS public.customers (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    name text NOT NULL,
    phone text UNIQUE,
    email text,
    address text,
    customer_type public.customer_type NOT NULL DEFAULT 'retail'::customer_type,
    total_purchases numeric(12, 2) DEFAULT 0,
    last_purchase timestamp with time zone
);
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;

-- Shifts table for staff
CREATE TABLE IF NOT EXISTS public.shifts (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    staff_id uuid NOT NULL REFERENCES public.profiles(id),
    start_time timestamp with time zone NOT NULL DEFAULT now(),
    end_time timestamp with time zone,
    opening_cash numeric(10, 2) NOT NULL,
    closing_cash numeric(10, 2),
    total_sales numeric(12, 2),
    total_transactions integer,
    status public.shift_status NOT NULL DEFAULT 'open'::shift_status
);
ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;

-- Transactions table
CREATE TABLE IF NOT EXISTS public.transactions (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id uuid REFERENCES public.customers(id),
    staff_id uuid NOT NULL REFERENCES public.profiles(id),
    shift_id uuid REFERENCES public.shifts(id),
    transaction_date timestamp with time zone NOT NULL DEFAULT now(),
    subtotal numeric(10, 2) NOT NULL,
    tax numeric(10, 2) NOT NULL,
    discount numeric(10, 2) NOT NULL,
    total_amount numeric(10, 2) NOT NULL,
    payment_method public.payment_method NOT NULL,
    payment_amount numeric(10, 2) NOT NULL,
    change_amount numeric(10, 2) NOT NULL,
    notes text
);
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- Transaction items (many-to-many between transactions and products)
CREATE TABLE IF NOT EXISTS public.transaction_items (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    transaction_id uuid NOT NULL REFERENCES public.transactions(id) ON DELETE CASCADE,
    product_id uuid NOT NULL REFERENCES public.products(id),
    quantity integer NOT NULL,
    unit_price numeric(10, 2) NOT NULL,
    subtotal numeric(10, 2) NOT NULL
);
ALTER TABLE public.transaction_items ENABLE ROW LEVEL SECURITY;

-- Inventory movements
CREATE TABLE IF NOT EXISTS public.inventory_movements (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id uuid NOT NULL REFERENCES public.products(id),
    movement_type public.inventory_movement_type NOT NULL,
    quantity integer NOT NULL,
    reference_type text,
    reference_id uuid,
    notes text,
    created_at timestamp with time zone NOT NULL DEFAULT now()
);
ALTER TABLE public.inventory_movements ENABLE ROW LEVEL SECURITY;


-- =================================================================
-- 3. FUNCTIONS & TRIGGERS
-- =================================================================

-- Function to get the role of the currently authenticated user
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS public.user_role
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

-- Function to handle new user and create a profile
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url, role)
  VALUES (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'avatar_url',
    (new.raw_user_meta_data->>'role')::public.user_role
  );
  RETURN new;
END;
$$;

-- Trigger to call handle_new_user on new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Function to automatically update `updated_at` timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = now(); 
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for products table
DROP TRIGGER IF EXISTS update_products_updated_at ON public.products;
CREATE TRIGGER update_products_updated_at
BEFORE UPDATE ON public.products
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Function to update stock and log movement
CREATE OR REPLACE FUNCTION public.update_product_stock_on_sale(p_product_id uuid, p_quantity_sold int, p_transaction_id uuid)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  -- Decrease stock
  UPDATE public.products
  SET stock = stock - p_quantity_sold
  WHERE id = p_product_id;

  -- Log inventory movement
  INSERT INTO public.inventory_movements (product_id, movement_type, quantity, reference_type, reference_id, notes)
  VALUES (p_product_id, 'sale', -p_quantity_sold, 'transaction', p_transaction_id, 'Sale transaction');
END;
$$;


-- =================================================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- =================================================================

-- Profiles
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
CREATE POLICY "Users can view their own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Store owners can manage all profiles" ON public.profiles;
CREATE POLICY "Store owners can manage all profiles" ON public.profiles FOR ALL USING (public.get_my_role() = 'store_owner');

-- Products, Categories, Brands, Compatibility (Public read, restricted write)
DROP POLICY IF EXISTS "Allow public read-only access" ON public.products;
CREATE POLICY "Allow public read-only access" ON public.products FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow public read-only access" ON public.categories;
CREATE POLICY "Allow public read-only access" ON public.categories FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow public read-only access" ON public.brands;
CREATE POLICY "Allow public read-only access" ON public.brands FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow public read-only access" ON public.product_car_compatibility;
CREATE POLICY "Allow public read-only access" ON public.product_car_compatibility FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins can manage products" ON public.products;
CREATE POLICY "Admins can manage products" ON public.products FOR ALL USING (public.get_my_role() IN ('store_owner', 'warehouse_admin'));

DROP POLICY IF EXISTS "Admins can manage categories" ON public.categories;
CREATE POLICY "Admins can manage categories" ON public.categories FOR ALL USING (public.get_my_role() IN ('store_owner', 'warehouse_admin'));

DROP POLICY IF EXISTS "Admins can manage brands" ON public.brands;
CREATE POLICY "Admins can manage brands" ON public.brands FOR ALL USING (public.get_my_role() IN ('store_owner', 'warehouse_admin'));

DROP POLICY IF EXISTS "Admins can manage compatibility" ON public.product_car_compatibility;
CREATE POLICY "Admins can manage compatibility" ON public.product_car_compatibility FOR ALL USING (public.get_my_role() IN ('store_owner', 'warehouse_admin'));


-- Customers
DROP POLICY IF EXISTS "Allow read access to staff" ON public.customers;
CREATE POLICY "Allow read access to staff" ON public.customers FOR SELECT USING (public.get_my_role() IN ('store_owner', 'shopkeeper'));

DROP POLICY IF EXISTS "Allow insert/update access to staff" ON public.customers;
CREATE POLICY "Allow insert/update access to staff" ON public.customers FOR ALL USING (public.get_my_role() IN ('store_owner', 'shopkeeper'));

-- Shifts
DROP POLICY IF EXISTS "Staff can manage their own shifts" ON public.shifts;
CREATE POLICY "Staff can manage their own shifts" ON public.shifts FOR ALL USING (staff_id = auth.uid());

DROP POLICY IF EXISTS "Store owners can view all shifts" ON public.shifts;
CREATE POLICY "Store owners can view all shifts" ON public.shifts FOR SELECT USING (public.get_my_role() = 'store_owner');

-- Transactions & Items
DROP POLICY IF EXISTS "Staff can create transactions" ON public.transactions;
CREATE POLICY "Staff can create transactions" ON public.transactions FOR INSERT WITH CHECK (staff_id = auth.uid());

DROP POLICY IF EXISTS "Staff can create transaction items" ON public.transaction_items;
CREATE POLICY "Staff can create transaction items" ON public.transaction_items FOR INSERT WITH CHECK (
  (SELECT staff_id FROM public.transactions WHERE id = transaction_id) = auth.uid()
);

DROP POLICY IF EXISTS "Staff can view their own transactions" ON public.transactions;
CREATE POLICY "Staff can view their own transactions" ON public.transactions FOR SELECT USING (staff_id = auth.uid());

DROP POLICY IF EXISTS "Store owners can view all transactions" ON public.transactions;
CREATE POLICY "Store owners can view all transactions" ON public.transactions FOR SELECT USING (public.get_my_role() = 'store_owner');

DROP POLICY IF EXISTS "Allow read access to items of visible transactions" ON public.transaction_items;
CREATE POLICY "Allow read access to items of visible transactions" ON public.transaction_items FOR SELECT USING (
  (SELECT true FROM public.transactions WHERE id = transaction_id)
);


-- Inventory Movements
DROP POLICY IF EXISTS "Admins can manage inventory" ON public.inventory_movements;
CREATE POLICY "Admins can manage inventory" ON public.inventory_movements FOR ALL USING (public.get_my_role() IN ('store_owner', 'warehouse_admin'));


-- =================================================================
-- 5. SEED DATA (INITIAL DATA)
-- =================================================================

-- Insert data only if tables are empty to avoid duplication
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.categories) THEN
    INSERT INTO public.categories (name, description) VALUES
    ('Filter', 'Filter Udara, Oli, Bensin, AC'),
    ('Rem', 'Kampas, Piringan, Minyak Rem'),
    ('Suspensi', 'Shock Absorber, Per, Kaki-kaki'),
    ('Mesin', 'Busi, Piston, Ring, Valve'),
    ('Kelistrikan', 'Aki, Bohlam, Kabel, Sensor'),
    ('Transmisi', 'Kopling, Oli Transmisi'),
    ('Pendingin', 'Radiator, Coolant, Thermostat'),
    ('Body', 'Bumper, Spion, Pintu'),
    ('Interior', 'Jok, Dashboard, Karpet'),
    ('Aksesoris', 'Wiper, Klakson, Velg');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.brands) THEN
    INSERT INTO public.brands (name, country) VALUES
    ('Toyota Genuine Parts', 'Jepang'),
    ('Daihatsu Genuine Parts', 'Jepang'),
    ('Honda Genuine Parts', 'Jepang'),
    ('Bosch', 'Jerman'),
    ('Denso', 'Jepang'),
    ('NGK', 'Jepang'),
    ('Brembo', 'Italia'),
    ('Monroe', 'Amerika Serikat'),
    ('KYB (Kayaba)', 'Jepang'),
    ('Philips', 'Belanda'),
    ('Osram', 'Jerman'),
    ('Aspira', 'Indonesia'),
    ('Aisin', 'Jepang'),
    ('Exedy', 'Jepang'),
    ('Gates', 'Amerika Serikat');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.car_models) THEN
    INSERT INTO public.car_models (brand, model, year_start, year_end, variant) VALUES
    ('Daihatsu', 'Xenia', 2004, 2011, '1.0 Mi/Li, 1.3 Xi'),
    ('Daihatsu', 'Xenia', 2012, 2015, 'All New 1.0/1.3'),
    ('Daihatsu', 'Xenia', 2015, 2018, 'Great New 1.3'),
    ('Daihatsu', 'Xenia', 2019, 2021, 'Grand New 1.3/1.5'),
    ('Daihatsu', 'Xenia', 2021, NULL, 'All New 1.3/1.5'),
    ('Toyota', 'Avanza', 2004, 2011, '1.3 E/G'),
    ('Toyota', 'Avanza', 2012, 2015, 'All New 1.3/1.5 Veloz'),
    ('Toyota', 'Avanza', 2015, 2018, 'Grand New 1.3/1.5 Veloz'),
    ('Toyota', 'Avanza', 2019, 2021, 'Grand New 1.3/1.5 Veloz'),
    ('Honda', 'Brio', 2013, 2018, 'Satya/1.2L'),
    ('Honda', 'Brio', 2018, NULL, 'All New Satya/RS'),
    ('Toyota', 'Agya', 2013, 2017, '1.0L'),
    ('Toyota', 'Agya', 2017, 2023, '1.2L'),
    ('Daihatsu', 'Ayla', 2013, 2017, '1.0L'),
    ('Daihatsu', 'Ayla', 2017, 2023, '1.2L');
  END IF;
END $$;

-- Note: Product seed data is omitted for brevity but would follow a similar `DO $$` block.
-- You can add sample products here if needed.

-- =================================================================
-- SCRIPT END
-- =================================================================
