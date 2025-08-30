/*
          # [Consolidated Initial Schema]
          This script creates the entire database schema, including tables, roles, functions, RLS policies, and initial seed data.
          It is designed to be run on a fresh or reset Supabase project to ensure a clean setup.

          ## Query Description: [This is a foundational script. Running it on a database with existing, conflicting tables will cause errors.
          It's highly recommended to reset your database before applying this script to avoid any conflicts.
          This will set up all necessary structures for the AutoParts POS application to function correctly.]
          
          ## Metadata:
          - Schema-Category: ["Structural", "Data"]
          - Impact-Level: ["High"]
          - Requires-Backup: true
          - Reversible: false
          
          ## Structure Details:
          - Creates all application tables: categories, brands, car_models, products, customers, profiles, shifts, transactions, etc.
          - Creates custom types: user_role, payment_method, etc.
          - Creates functions and triggers for auth integration and stock management.
          
          ## Security Implications:
          - RLS Status: Enabled on all tables.
          - Policy Changes: Yes, this script defines all RLS policies for the application.
          - Auth Requirements: Policies are based on JWT claims and the custom 'profiles' table.
          
          ## Performance Impact:
          - Indexes: Adds indexes to foreign keys and frequently queried columns for performance.
          - Triggers: Adds a trigger to sync new users from `auth.users` to `public.profiles`.
          - Estimated Impact: Establishes the baseline performance characteristics of the database.
          */

-- 1. EXTENSIONS
create extension if not exists "uuid-ossp" with schema extensions;

-- 2. CUSTOM TYPES
create type public.user_role as enum ('store_owner', 'warehouse_admin', 'shopkeeper');
create type public.payment_method as enum ('cash', 'card', 'transfer', 'qris');
create type public.inventory_movement_type as enum ('in', 'out', 'adjustment', 'sale');
create type public.shift_status as enum ('open', 'closed');
create type public.customer_type as enum ('retail', 'wholesale');

-- 3. TABLES
-- These are created in an order that respects foreign key dependencies.

create table public.categories (
    id uuid default extensions.uuid_generate_v4() primary key,
    name text not null unique,
    description text,
    created_at timestamp with time zone default now() not null,
    updated_at timestamp with time zone default now() not null
);
comment on table public.categories is 'Stores product categories like Engine, Brake, etc.';

create table public.brands (
    id uuid default extensions.uuid_generate_v4() primary key,
    name text not null unique,
    country text,
    created_at timestamp with time zone default now() not null,
    updated_at timestamp with time zone default now() not null
);
comment on table public.brands is 'Stores product brands like Toyota, Bosch, etc.';

create table public.car_models (
    id uuid default extensions.uuid_generate_v4() primary key,
    brand text not null,
    model text not null,
    year_start integer not null,
    year_end integer,
    variant text
);
comment on table public.car_models is 'Stores car models and their production years.';

create table public.products (
    id uuid default extensions.uuid_generate_v4() primary key,
    name text not null,
    description text,
    price numeric(10, 2) not null default 0.00,
    stock integer not null default 0,
    min_stock integer not null default 5,
    category_id uuid references public.categories(id),
    brand_id uuid references public.brands(id),
    part_number text not null unique,
    barcode text unique,
    image_url text,
    weight numeric(8, 2),
    dimensions text,
    is_active boolean default true not null,
    created_at timestamp with time zone default now() not null,
    updated_at timestamp with time zone default now() not null
);
comment on table public.products is 'Stores all product information.';

create table public.product_car_compatibility (
    product_id uuid not null references public.products(id) on delete cascade,
    car_model_id uuid not null references public.car_models(id) on delete cascade,
    primary key (product_id, car_model_id)
);
comment on table public.product_car_compatibility is 'Maps which products are compatible with which car models.';

create table public.customers (
    id uuid default extensions.uuid_generate_v4() primary key,
    name text not null,
    phone text not null unique,
    email text unique,
    address text,
    customer_type public.customer_type default 'retail'::public.customer_type not null,
    total_purchases numeric(12, 2) default 0.00,
    last_purchase timestamp with time zone,
    created_at timestamp with time zone default now() not null,
    updated_at timestamp with time zone default now() not null
);
comment on table public.customers is 'Stores customer information.';

create table public.profiles (
    id uuid not null primary key references auth.users(id) on delete cascade,
    full_name text,
    avatar_url text,
    role public.user_role not null default 'shopkeeper'::public.user_role,
    updated_at timestamp with time zone default now() not null
);
comment on table public.profiles is 'Stores public profile information for authenticated users.';

create table public.shifts (
    id uuid default extensions.uuid_generate_v4() primary key,
    staff_id uuid not null references public.profiles(id),
    start_time timestamp with time zone not null,
    end_time timestamp with time zone,
    opening_cash numeric(10, 2) not null,
    closing_cash numeric(10, 2),
    total_sales numeric(12, 2),
    total_transactions integer,
    status public.shift_status not null default 'open'::public.shift_status
);
comment on table public.shifts is 'Manages staff work shifts.';

create table public.transactions (
    id uuid default extensions.uuid_generate_v4() primary key,
    customer_id uuid references public.customers(id),
    staff_id uuid not null references public.profiles(id),
    shift_id uuid references public.shifts(id),
    transaction_date timestamp with time zone default now() not null,
    subtotal numeric(10, 2) not null,
    tax numeric(10, 2) not null,
    discount numeric(10, 2) default 0.00,
    total_amount numeric(10, 2) not null,
    payment_method public.payment_method not null,
    payment_amount numeric(10, 2) not null,
    change_amount numeric(10, 2) default 0.00,
    notes text
);
comment on table public.transactions is 'Records all sales transactions.';

create table public.transaction_items (
    id uuid default extensions.uuid_generate_v4() primary key,
    transaction_id uuid not null references public.transactions(id) on delete cascade,
    product_id uuid not null references public.products(id),
    quantity integer not null,
    unit_price numeric(10, 2) not null,
    subtotal numeric(10, 2) not null
);
comment on table public.transaction_items is 'Details of items within a transaction.';

create table public.inventory_movements (
    id uuid default extensions.uuid_generate_v4() primary key,
    product_id uuid not null references public.products(id),
    movement_type public.inventory_movement_type not null,
    quantity integer not null,
    reference_type text,
    reference_id text,
    notes text,
    created_at timestamp with time zone default now() not null,
    staff_id uuid references public.profiles(id)
);
comment on table public.inventory_movements is 'Tracks all stock movements (in, out, adjustments).';

-- 4. INDEXES
create index on public.products (name);
create index on public.products (category_id);
create index on public.products (brand_id);
create index on public.transactions (transaction_date);
create index on public.transactions (staff_id);

-- 5. FUNCTIONS AND TRIGGERS

-- Function to handle new user creation
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, avatar_url, role)
  values (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url', 'shopkeeper');
  return new;
end;
$$;

-- Trigger to call the function when a new user is created in auth.users
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Function to update 'updated_at' timestamps
create or replace function public.update_updated_at_column()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Triggers for 'updated_at'
create trigger handle_updated_at before update on public.categories for each row execute procedure public.update_updated_at_column();
create trigger handle_updated_at before update on public.brands for each row execute procedure public.update_updated_at_column();
create trigger handle_updated_at before update on public.products for each row execute procedure public.update_updated_at_column();
create trigger handle_updated_at before update on public.customers for each row execute procedure public.update_updated_at_column();
create trigger handle_updated_at before update on public.profiles for each row execute procedure public.update_updated_at_column();


-- RPC function to update stock after a sale
create or replace function public.update_product_stock_on_sale(p_product_id uuid, p_quantity_sold integer, p_transaction_id uuid)
returns void
language plpgsql
as $$
begin
  -- Decrease stock in products table
  update public.products
  set stock = stock - p_quantity_sold
  where id = p_product_id;

  -- Record the movement in inventory_movements
  insert into public.inventory_movements (product_id, movement_type, quantity, reference_type, reference_id, staff_id)
  values (p_product_id, 'sale', -p_quantity_sold, 'transaction', p_transaction_id::text, auth.uid());
end;
$$;


-- 6. ROW LEVEL SECURITY (RLS)

-- Enable RLS on all tables
alter table public.categories enable row level security;
alter table public.brands enable row level security;
alter table public.car_models enable row level security;
alter table public.products enable row level security;
alter table public.product_car_compatibility enable row level security;
alter table public.customers enable row level security;
alter table public.profiles enable row level security;
alter table public.shifts enable row level security;
alter table public.transactions enable row level security;
alter table public.transaction_items enable row level security;
alter table public.inventory_movements enable row level security;

-- Helper function to get user role
create or replace function public.get_my_role()
returns text
language sql
stable
as $$
  select role from public.profiles where id = auth.uid();
$$;

-- RLS POLICIES

-- Profiles
create policy "Users can view their own profile" on public.profiles for select using (auth.uid() = id);
create policy "Users can update their own profile" on public.profiles for update using (auth.uid() = id);
create policy "Store owners can view all profiles" on public.profiles for select using (public.get_my_role() = 'store_owner');

-- Public read-only tables (for authenticated users)
create policy "Authenticated users can view public data" on public.categories for select using (auth.role() = 'authenticated');
create policy "Authenticated users can view public data" on public.brands for select using (auth.role() = 'authenticated');
create policy "Authenticated users can view public data" on public.car_models for select using (auth.role() = 'authenticated');
create policy "Authenticated users can view public data" on public.product_car_compatibility for select using (auth.role() = 'authenticated');

-- Products
create policy "Authenticated users can view products" on public.products for select using (auth.role() = 'authenticated');
create policy "Admins can manage products" on public.products for all using (public.get_my_role() in ('store_owner', 'warehouse_admin'));

-- Customers
create policy "Shop staff can view customers" on public.customers for select using (public.get_my_role() in ('store_owner', 'shopkeeper'));
create policy "Shop staff can manage customers" on public.customers for insert, update using (public.get_my_role() in ('store_owner', 'shopkeeper'));

-- Shifts
create policy "Users can manage their own shifts" on public.shifts for all using (auth.uid() = staff_id);
create policy "Store owners can view all shifts" on public.shifts for select using (public.get_my_role() = 'store_owner');

-- Transactions
create policy "Shop staff can create transactions" on public.transactions for insert with check (public.get_my_role() in ('store_owner', 'shopkeeper') and auth.uid() = staff_id);
create policy "Users can view their own transactions" on public.transactions for select using (auth.uid() = staff_id);
create policy "Store owners can view all transactions" on public.transactions for select using (public.get_my_role() = 'store_owner');

-- Transaction Items
create policy "Users can manage items for their own transactions" on public.transaction_items for all using (
  exists (
    select 1 from public.transactions
    where id = transaction_id and staff_id = auth.uid()
  )
);
create policy "Store owners can view all transaction items" on public.transaction_items for select using (public.get_my_role() = 'store_owner');

-- Inventory Movements
create policy "Admins can manage inventory" on public.inventory_movements for all using (public.get_my_role() in ('store_owner', 'warehouse_admin'));


-- 7. SEED DATA

-- Categories
insert into public.categories (name, description) values
('Engine', 'Komponen mesin dan terkait'),
('Brake', 'Sistem pengereman'),
('Suspension', 'Sistem suspensi dan peredam kejut'),
('Electrical', 'Komponen kelistrikan dan aki'),
('Body', 'Bagian bodi dan eksterior'),
('Transmission', 'Sistem transmisi'),
('Filter', 'Filter oli, udara, dan bahan bakar'),
('Cooling', 'Sistem pendingin mesin'),
('Exhaust', 'Sistem pembuangan gas'),
('Lighting', 'Lampu dan sistem penerangan');

-- Brands
insert into public.brands (name, country) values
('Toyota Genuine Parts', 'Jepang'),
('Daihatsu Genuine Parts', 'Jepang'),
('Honda Genuine Parts', 'Jepang'),
('Bosch', 'Jerman'),
('Denso', 'Jepang'),
('NGK', 'Jepang'),
('Brembo', 'Italia'),
('Monroe', 'USA'),
('KYB', 'Jepang'),
('Philips', 'Belanda'),
('Osram', 'Jerman'),
('Aspira', 'Indonesia'),
('Federal', 'Indonesia'),
('Aisin', 'Jepang'),
('Exedy', 'Jepang');

-- Car Models (contoh)
insert into public.car_models (brand, model, year_start, year_end, variant) values
('Daihatsu', 'Xenia', 2004, 2011, '1.0 Mi/Li'),
('Daihatsu', 'Xenia', 2004, 2011, '1.3 Xi/Ri'),
('Daihatsu', 'Xenia', 2012, 2015, '1.0 D/M'),
('Daihatsu', 'Xenia', 2012, 2015, '1.3 X/R'),
('Toyota', 'Avanza', 2004, 2011, '1.3 E/G'),
('Toyota', 'Avanza', 2012, 2015, '1.3 E/G'),
('Toyota', 'Avanza', 2015, 2021, '1.3 E/G'),
('Honda', 'Brio', 2013, 2018, 'Satya 1.2'),
('Honda', 'Brio', 2018, 2023, 'Satya E/RS 1.2'),
('Toyota', 'Agya', 2013, 2017, '1.0 G/TRD'),
('Toyota', 'Agya', 2017, 2023, '1.2 G/TRD'),
('Daihatsu', 'Ayla', 2013, 2017, '1.0 M/X'),
('Daihatsu', 'Ayla', 2017, 2023, '1.2 R');

-- Products (contoh)
-- Gunakan subquery untuk mendapatkan ID dari nama
insert into public.products (name, price, stock, min_stock, category_id, brand_id, part_number, barcode, image_url) values
('Filter Udara Avanza/Xenia', 85000, 50, 10, (select id from categories where name='Filter'), (select id from brands where name='Denso'), 'DXA-1001', '899000000001', 'https://img-wrapper.vercel.app/image?url=https://via.placeholder.com/150/00f5ff/000000?Text=DXA-1001'),
('Filter Oli Avanza/Xenia/Agya/Ayla', 35000, 100, 20, (select id from categories where name='Filter'), (select id from brands where name='Aspira'), 'ASP-2001', '899000000002', 'https://img-wrapper.vercel.app/image?url=https://via.placeholder.com/150/00ff41/000000?Text=ASP-2001'),
('Kampas Rem Depan Brio', 275000, 30, 5, (select id from categories where name='Brake'), (select id from brands where name='Brembo'), 'BRM-3005', '899000000003', 'https://img-wrapper.vercel.app/image?url=https://via.placeholder.com/150/ff0080/FFFFFF?Text=BRM-3005'),
('Busi NGK BKR6E-11 Avanza/Xenia 1.3', 25000, 200, 50, (select id from categories where name='Electrical'), (select id from brands where name='NGK'), 'NGK-BKR6E11', '899000000004', 'https://img-wrapper.vercel.app/image?url=https://via.placeholder.com/150/8000ff/FFFFFF?Text=NGK-BKR6E11'),
('Shock Absorber Belakang Avanza/Xenia', 450000, 20, 4, (select id from categories where name='Suspension'), (select id from brands where name='KYB'), 'KYB-AVZ01', '899000000005', 'https://img-wrapper.vercel.app/image?url=https://via.placeholder.com/150/f97316/FFFFFF?Text=KYB-AVZ01');

-- Product Compatibility (contoh)
insert into public.product_car_compatibility (product_id, car_model_id)
select
    (select id from products where part_number = 'DXA-1001'), id from car_models where model in ('Avanza', 'Xenia');
insert into public.product_car_compatibility (product_id, car_model_id)
select
    (select id from products where part_number = 'ASP-2001'), id from car_models where model in ('Avanza', 'Xenia', 'Agya', 'Ayla');
insert into public.product_car_compatibility (product_id, car_model_id)
select
    (select id from products where part_number = 'BRM-3005'), id from car_models where model = 'Brio';

-- Dummy Customer
insert into public.customers (name, phone, email, customer_type) values
('Pelanggan Retail', '080000000000', 'retail@example.com', 'retail'),
('Bengkel Maju Jaya', '081234567890', 'bengkel@example.com', 'wholesale');

commit;
