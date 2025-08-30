/*
          # [Auth] User Roles & Profiles
          This migration sets up the foundation for multi-user authentication with role-based access control (RBAC).

          ## Query Description: This operation is STRUCTURAL and SAFE.
          1. Creates a `user_role` enum for defining user roles.
          2. Creates a `profiles` table to store public user data and their role, linked to `auth.users`.
          3. Sets up a trigger (`on_auth_user_created`) to automatically create a user profile upon new user sign-up.
          4. Enables Row Level Security (RLS) on key tables and defines policies based on user roles.
          
          This is a non-destructive operation but essential for enabling user authentication.

          ## Metadata:
          - Schema-Category: "Structural"
          - Impact-Level: "Low"
          - Requires-Backup: false
          - Reversible: true (with manual cleanup)
          
          ## Structure Details:
          - **Types Created**: `user_role`
          - **Tables Created**: `profiles`
          - **Triggers Created**: `on_auth_user_created` on `auth.users`
          - **RLS Policies**: Added to `products`, `transactions`, `shifts`, `customers`.
          
          ## Security Implications:
          - RLS Status: Enabled on critical tables.
          - Policy Changes: Yes, this is the core of the change.
          - Auth Requirements: Policies are based on `auth.uid()` and custom claims.
          
          ## Performance Impact:
          - Indexes: Adds a primary key and foreign key index on `profiles`.
          - Triggers: Adds one trigger on `auth.users` table for `INSERT`.
          - Estimated Impact: Negligible performance impact on auth operations.
          */

-- 1. Create a type for user roles
CREATE TYPE user_role AS ENUM ('store_owner', 'warehouse_admin', 'shopkeeper');

-- 2. Create a table for public profiles
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL PRIMARY KEY,
  updated_at TIMESTAMPTZ,
  full_name TEXT,
  avatar_url TEXT,
  role user_role NOT NULL DEFAULT 'shopkeeper'
);

-- Set up Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public profiles are viewable by everyone." ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile." ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile." ON profiles FOR UPDATE USING (auth.uid() = id);

-- 3. Set up a trigger to automatically create a profile for new users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url, role)
  VALUES (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'avatar_url',
    'shopkeeper' -- Default role
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 4. Update foreign key references to use the new profiles table if needed
-- Example: update staff_id in transactions and shifts to reference profiles(id)
-- Note: Ensure staff_id columns in transactions and shifts are UUID and have a foreign key to auth.users(id) or profiles(id)
ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_staff_id_fkey;
ALTER TABLE transactions
  ADD CONSTRAINT transactions_staff_id_fkey
  FOREIGN KEY (staff_id) REFERENCES auth.users(id);

ALTER TABLE shifts DROP CONSTRAINT IF EXISTS shifts_staff_id_fkey;
ALTER TABLE shifts
  ADD CONSTRAINT shifts_staff_id_fkey
  FOREIGN KEY (staff_id) REFERENCES auth.users(id);


-- 5. Add get_my_role() function
CREATE OR REPLACE FUNCTION get_my_role()
RETURNS user_role AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE;

-- 6. Setup RLS policies for other tables

-- PRODUCTS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access for store owners on products" ON products;
CREATE POLICY "Allow all access for store owners on products" ON products
  FOR ALL USING (get_my_role() = 'store_owner');

DROP POLICY IF EXISTS "Allow warehouse admins to manage products" ON products;
CREATE POLICY "Allow warehouse admins to manage products" ON products
  FOR ALL USING (get_my_role() = 'warehouse_admin');

DROP POLICY IF EXISTS "Allow shopkeepers to read products" ON products;
CREATE POLICY "Allow shopkeepers to read products" ON products
  FOR SELECT USING (get_my_role() = 'shopkeeper');

-- TRANSACTIONS
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access for store owners on transactions" ON transactions;
CREATE POLICY "Allow all access for store owners on transactions" ON transactions
  FOR ALL USING (get_my_role() = 'store_owner');

DROP POLICY IF EXISTS "Allow shopkeepers to manage their own transactions" ON transactions;
CREATE POLICY "Allow shopkeepers to manage their own transactions" ON transactions
  FOR ALL USING (get_my_role() = 'shopkeeper' AND staff_id = auth.uid());

-- SHIFTS
ALTER TABLE shifts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access for store owners on shifts" ON shifts;
CREATE POLICY "Allow all access for store owners on shifts" ON shifts
  FOR ALL USING (get_my_role() = 'store_owner');

DROP POLICY IF EXISTS "Allow shopkeepers to manage their own shifts" ON shifts;
CREATE POLICY "Allow shopkeepers to manage their own shifts" ON shifts
  FOR ALL USING (get_my_role() = 'shopkeeper' AND staff_id = auth.uid());

-- CUSTOMERS
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow store owners and shopkeepers to manage customers" ON customers;
CREATE POLICY "Allow store owners and shopkeepers to manage customers" ON customers
  FOR ALL USING (get_my_role() IN ('store_owner', 'shopkeeper'));

-- INVENTORY MOVEMENTS
ALTER TABLE inventory_movements ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow store owners and warehouse admins to manage inventory" ON inventory_movements;
CREATE POLICY "Allow store owners and warehouse admins to manage inventory" ON inventory_movements
  FOR ALL USING (get_my_role() IN ('store_owner', 'warehouse_admin'));
