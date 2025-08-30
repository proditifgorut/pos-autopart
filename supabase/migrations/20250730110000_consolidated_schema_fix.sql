/*
# =================================================================
# KUMPULAN SKEMA DATABASE AWAL - AUTOPARTS POS
# =================================================================
# Versi: 1.1.0
# Tanggal: 30 Juli 2025
# Deskripsi:
# Skrip SQL ini membuat seluruh skema database untuk aplikasi
# AutoParts POS, termasuk:
#   - Tabel-tabel inti (produk, transaksi, pengguna, dll.)
#   - Tipe data kustom (ENUM untuk peran pengguna).
#   - Fungsi-fungsi helper (untuk mengambil peran pengguna).
#   - Data awal (dummy data) untuk mobil, produk, brand, dll.
#   - Kebijakan Keamanan Tingkat Baris (Row Level Security - RLS).
#   - Trigger untuk sinkronisasi data.
#
# Instruksi Penggunaan:
# 1. Pastikan database Anda dalam keadaan bersih (reset jika perlu).
# 2. Jalankan seluruh skrip ini di SQL Editor Supabase Anda.
#
# Perubahan dari v1.0.0:
# - Memperbaiki sintaks pada beberapa kebijakan RLS (CREATE POLICY).
# - Menggunakan 'FOR ALL' atau memisahkan 'FOR INSERT' dan 'FOR UPDATE'
#   untuk menghindari error sintaks.
*/

-- =================================================================
-- BAGIAN 1: PEMBERSIHAN (OPSIONAL, JIKA MENJALANKAN ULANG)
-- =================================================================
-- Disarankan untuk mereset database dari UI Supabase untuk hasil terbaik.
-- Namun, jika Anda ingin menjalankan ulang, drop tabel dalam urutan terbalik.

-- drop policy if exists "Shopkeepers can create transactions" on "public"."transactions";
-- drop policy if exists "Shopkeepers can see their own transactions" on "public"."transactions";
-- drop policy if exists "Store owners can see all transactions" on "public"."transactions";
-- drop policy if exists "Staff can manage their own shifts" on "public"."shifts";
-- drop policy if exists "Staff can see their own shifts" on "public"."shifts";
-- drop policy if exists "Shopkeepers can see products" on "public"."products";
-- drop policy if exists "Warehouse admins can update stock" on "public"."products";
-- drop policy if exists "Store owners can manage everything" on "public"."products";
-- drop policy if exists "Enable read access for all users" on "public"."profiles";
-- drop policy if exists "Users can insert their own profile" on "public"."profiles";
-- drop policy if exists "Users can update their own profile" on "public"."profiles";
-- drop policy if exists "Shop staff can manage customers" on "public"."customers";
-- drop policy if exists "Enable read access for all users" on "public"."customers";
-- drop policy if exists "Enable read access for all users" on "public"."categories";
-- drop policy if exists "Enable read access for all users" on "public"."brands";

-- drop table if exists inventory_movements;
-- drop table if exists transaction_items;
-- drop table if exists transactions;
-- drop table if exists shifts;
-- drop table if exists product_car_compatibility;
-- drop table if exists products;
-- drop table if exists categories;
-- drop table if exists brands;
-- drop table if exists car_models;
-- drop table if exists customers;
-- drop table if exists profiles;
-- drop function if exists public.handle_new_user();
-- drop function if exists public.get_my_role();
-- drop function if exists public.update_product_stock_on_sale(uuid, integer, uuid);
-- drop type if exists public.user_role;


-- =================================================================
-- BAGIAN 2: TIPE DATA KUSTOM
-- =================================================================
/*
  # Tipe Data Peran Pengguna (user_role)
  Membuat tipe data ENUM untuk peran pengguna agar konsisten.
*/
create type public.user_role as enum ('store_owner', 'warehouse_admin', 'shopkeeper');


-- =================================================================
-- BAGIAN 3: PEMBUATAN TABEL
-- =================================================================

/* # Tabel: profiles
   Menyimpan data profil pengguna yang terhubung dengan sistem autentikasi Supabase.
*/
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  updated_at timestamp with time zone,
  full_name text not null,
  avatar_url text,
  role user_role not null default 'shopkeeper'
);
comment on table public.profiles is 'Tabel profil untuk setiap pengguna terautentikasi.';

/* # Tabel: categories
   Menyimpan kategori-kategori produk.
*/
create table public.categories (
  id uuid default gen_random_uuid() primary key,
  name text not null unique,
  description text,
  created_at timestamp with time zone default now() not null
);
comment on table public.categories is 'Kategori untuk produk onderdil.';

/* # Tabel: brands
   Menyimpan merk-merk produk.
*/
create table public.brands (
  id uuid default gen_random_uuid() primary key,
  name text not null unique,
  country text,
  created_at timestamp with time zone default now() not null
);
comment on table public.brands is 'Brand atau merk dari produk onderdil.';

/* # Tabel: car_models
   Menyimpan data model mobil.
*/
create table public.car_models (
  id uuid default gen_random_uuid() primary key,
  brand text not null,
  model text not null,
  year_start integer not null,
  year_end integer,
  variant text
);
comment on table public.car_models is 'Model mobil yang didukung oleh toko.';

/* # Tabel: products
   Tabel utama untuk data produk onderdil.
*/
create table public.products (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  description text,
  price numeric not null check (price >= 0),
  stock integer not null default 0 check (stock >= 0),
  min_stock integer not null default 5 check (min_stock >= 0),
  category_id uuid references public.categories(id),
  brand_id uuid references public.brands(id),
  part_number text not null unique,
  barcode text unique,
  image_url text,
  weight numeric,
  dimensions text,
  is_active boolean default true not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);
comment on table public.products is 'Daftar semua produk onderdil yang dijual.';

/* # Tabel: product_car_compatibility
   Tabel pivot untuk menghubungkan produk dengan model mobil yang kompatibel.
*/
create table public.product_car_compatibility (
  product_id uuid references public.products(id) on delete cascade not null,
  car_model_id uuid references public.car_models(id) on delete cascade not null,
  primary key (product_id, car_model_id)
);
comment on table public.product_car_compatibility is 'Menentukan produk mana yang cocok untuk mobil mana.';

/* # Tabel: customers
   Menyimpan data pelanggan.
*/
create table public.customers (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  phone text not null unique,
  email text,
  address text,
  customer_type text default 'retail' not null,
  total_purchases numeric default 0,
  last_purchase timestamp with time zone,
  created_at timestamp with time zone default now() not null
);
comment on table public.customers is 'Data pelanggan toko.';

/* # Tabel: shifts
   Mencatat sesi kerja (shift) dari setiap staf.
*/
create table public.shifts (
  id uuid default gen_random_uuid() primary key,
  staff_id uuid references public.profiles(id) not null,
  start_time timestamp with time zone not null,
  end_time timestamp with time zone,
  opening_cash numeric not null,
  closing_cash numeric,
  total_sales numeric,
  total_transactions integer,
  status text default 'open' not null
);
comment on table public.shifts is 'Mencatat sesi kerja kasir (buka/tutup shift).';

/* # Tabel: transactions
   Mencatat semua transaksi penjualan.
*/
create table public.transactions (
  id uuid default gen_random_uuid() primary key,
  customer_id uuid references public.customers(id),
  staff_id uuid references public.profiles(id) not null,
  shift_id uuid references public.shifts(id),
  transaction_date timestamp with time zone default now() not null,
  subtotal numeric not null,
  tax numeric not null,
  discount numeric not null,
  total_amount numeric not null,
  payment_method text not null,
  payment_amount numeric not null,
  change_amount numeric not null,
  notes text
);
comment on table public.transactions is 'Header untuk setiap transaksi penjualan.';

/* # Tabel: transaction_items
   Mencatat detail item dari setiap transaksi.
*/
create table public.transaction_items (
  id uuid default gen_random_uuid() primary key,
  transaction_id uuid references public.transactions(id) on delete cascade not null,
  product_id uuid references public.products(id) not null,
  quantity integer not null,
  unit_price numeric not null,
  subtotal numeric not null
);
comment on table public.transaction_items is 'Detail item per transaksi.';

/* # Tabel: inventory_movements
   Mencatat semua pergerakan stok.
*/
create table public.inventory_movements (
  id uuid default gen_random_uuid() primary key,
  product_id uuid references public.products(id) not null,
  movement_type text not null, -- 'in', 'out', 'adjustment'
  quantity integer not null,
  reference_type text, -- 'transaction', 'purchase_order', 'manual'
  reference_id text,
  notes text,
  created_at timestamp with time zone default now() not null
);
comment on table public.inventory_movements is 'Riwayat pergerakan stok masuk dan keluar.';


-- =================================================================
-- BAGIAN 4: FUNGSI DAN TRIGGER
-- =================================================================

/* # Fungsi: handle_new_user
   Trigger yang secara otomatis membuat profil baru di tabel `profiles`
   setiap kali ada pengguna baru mendaftar di `auth.users`.
*/
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

-- Membuat trigger pada tabel auth.users
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

/* # Fungsi: get_my_role
   Fungsi untuk mengambil peran pengguna yang sedang login dari tabel `profiles`.
*/
create or replace function public.get_my_role()
returns user_role
language sql
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

/* # Fungsi: update_product_stock_on_sale
   Fungsi RPC untuk mengurangi stok produk dan mencatat pergerakan inventaris
   setelah transaksi penjualan.
*/
create or replace function public.update_product_stock_on_sale(p_product_id uuid, p_quantity_sold integer, p_transaction_id uuid)
returns void
language plpgsql
as $$
begin
  -- Kurangi stok di tabel products
  update public.products
  set stock = stock - p_quantity_sold
  where id = p_product_id;

  -- Catat pergerakan stok keluar
  insert into public.inventory_movements(product_id, movement_type, quantity, reference_type, reference_id, notes)
  values (p_product_id, 'out', -p_quantity_sold, 'transaction', p_transaction_id::text, 'Penjualan');
end;
$$;


-- =================================================================
-- BAGIAN 5: AKTIVASI ROW LEVEL SECURITY (RLS)
-- =================================================================

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.brands enable row level security;
alter table public.customers enable row level security;
alter table public.products enable row level security;
alter table public.shifts enable row level security;
alter table public.transactions enable row level security;
alter table public.transaction_items enable row level security;
alter table public.inventory_movements enable row level security;


-- =================================================================
-- BAGIAN 6: KEBIJAKAN RLS (ROW LEVEL SECURITY POLICIES)
-- =================================================================
-- Catatan: Kebijakan di bawah ini memberikan akses dasar.
-- Anda mungkin perlu menyesuaikannya sesuai kebutuhan bisnis yang lebih spesifik.

-- Kebijakan untuk tabel `brands` dan `categories`
create policy "Enable read access for all users" on public.brands for select using (true);
create policy "Enable read access for all users" on public.categories for select using (true);

-- Kebijakan untuk tabel `customers`
create policy "Enable read access for all users" on public.customers for select using (true);
-- **FIXED**: Menggunakan 'FOR ALL' dengan 'USING' dan 'WITH CHECK'
create policy "Shop staff can manage customers" on public.customers
  for all
  using (public.get_my_role() in ('store_owner', 'shopkeeper'))
  with check (public.get_my_role() in ('store_owner', 'shopkeeper'));

-- Kebijakan untuk tabel `profiles`
create policy "Users can update their own profile" on public.profiles for update using (auth.uid() = id);
create policy "Users can insert their own profile" on public.profiles for insert with check (auth.uid() = id);
create policy "Enable read access for all users" on public.profiles for select using (true);

-- Kebijakan untuk tabel `products`
create policy "Store owners can manage everything" on public.products
  for all
  using (true)
  with check (public.get_my_role() = 'store_owner');

create policy "Warehouse admins can update stock" on public.products
  for update
  using (public.get_my_role() in ('store_owner', 'warehouse_admin'))
  with check (public.get_my_role() in ('store_owner', 'warehouse_admin'));

create policy "Shopkeepers can see products" on public.products
  for select
  using (public.get_my_role() in ('store_owner', 'shopkeeper'));

-- Kebijakan untuk tabel `shifts`
create policy "Staff can see their own shifts" on public.shifts for select using (auth.uid() = staff_id);
-- **FIXED**: Menggunakan 'FOR ALL' dengan 'USING' dan 'WITH CHECK'
create policy "Staff can manage their own shifts" on public.shifts
  for all
  using (auth.uid() = staff_id)
  with check (auth.uid() = staff_id);

-- Kebijakan untuk tabel `transactions` dan `transaction_items`
create policy "Store owners can see all transactions" on public.transactions for select using (public.get_my_role() = 'store_owner');
create policy "Store owners can see all transaction items" on public.transaction_items for select using (public.get_my_role() = 'store_owner');

create policy "Shopkeepers can see their own transactions" on public.transactions for select using (auth.uid() = staff_id);
create policy "Shopkeepers can see their own transaction items" on public.transaction_items for select
  using (exists(select 1 from transactions where transactions.id = transaction_items.transaction_id and transactions.staff_id = auth.uid()));

create policy "Shopkeepers can create transactions" on public.transactions
  for insert
  with check (auth.uid() = staff_id and public.get_my_role() in ('store_owner', 'shopkeeper'));
create policy "Shopkeepers can create transaction items" on public.transaction_items
  for insert
  with check (exists(select 1 from transactions where transactions.id = transaction_items.transaction_id and transactions.staff_id = auth.uid()));

-- Kebijakan untuk tabel `inventory_movements`
create policy "Admins can see all inventory movements" on public.inventory_movements
  for select
  using (public.get_my_role() in ('store_owner', 'warehouse_admin'));


-- =================================================================
-- BAGIAN 7: DATA AWAL (DUMMY DATA)
-- =================================================================
-- Data ini bersifat contoh dan dapat Anda modifikasi.

-- Insert Categories
insert into public.categories (name, description) values
('Engine', 'Komponen mesin'),
('Brake', 'Sistem pengereman'),
('Suspension', 'Sistem suspensi'),
('Electrical', 'Komponen kelistrikan'),
('Body', 'Komponen bodi mobil'),
('Transmission', 'Sistem transmisi'),
('Filters', 'Filter udara, oli, bensin'),
('Wheels & Tires', 'Roda dan ban'),
('Exhaust', 'Sistem pembuangan'),
('Cooling', 'Sistem pendingin');

-- Insert Brands
insert into public.brands (name, country) values
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
('Federal', 'Indonesia'),
('Aisin', 'Japan'),
('Exedy', 'Japan');

-- Insert Car Models
insert into public.car_models (brand, model, year_start, year_end, variant) values
-- Daihatsu Xenia
('Daihatsu', 'Xenia', 2004, 2011, '1.0 Mi/Li'),
('Daihatsu', 'Xenia', 2004, 2011, '1.3 Xi/Ri'),
('Daihatsu', 'Xenia', 2012, 2015, '1.0 D/M'),
('Daihatsu', 'Xenia', 2012, 2015, '1.3 X/R'),
('Daihatsu', 'Xenia', 2015, 2018, '1.0 M'),
('Daihatsu', 'Xenia', 2015, 2018, '1.3 X/R'),
('Daihatsu', 'Xenia', 2019, 2021, '1.3 R'),
('Daihatsu', 'Xenia', 2019, 2021, '1.5 R'),
('Daihatsu', 'Xenia', 2021, 2023, '1.3 M/X/R'),
-- Toyota Avanza
('Toyota', 'Avanza', 2004, 2011, '1.3 E/G'),
('Toyota', 'Avanza', 2006, 2011, '1.5 S'),
('Toyota', 'Avanza', 2012, 2015, '1.3 E/G'),
('Toyota', 'Avanza', 2012, 2015, '1.5 G/Veloz'),
('Toyota', 'Avanza', 2015, 2018, '1.3 E/G'),
('Toyota', 'Avanza', 2015, 2018, '1.5 G/Veloz'),
('Toyota', 'Avanza', 2019, 2021, '1.3 E/G'),
('Toyota', 'Avanza', 2019, 2021, '1.5 G/Veloz'),
('Toyota', 'Avanza', 2021, 2023, '1.3 E / 1.5 G'),
-- Honda Brio
('Honda', 'Brio', 2013, 2018, '1.2 Satya S/E'),
('Honda', 'Brio', 2013, 2018, '1.2 Sport'),
('Honda', 'Brio', 2018, 2023, '1.2 Satya S/E'),
('Honda', 'Brio', 2018, 2023, '1.2 RS'),
-- Toyota Agya
('Toyota', 'Agya', 2013, 2017, '1.0 E/G'),
('Toyota', 'Agya', 2013, 2017, '1.0 TRD S'),
('Toyota', 'Agya', 2017, 2020, '1.0 G'),
('Toyota', 'Agya', 2017, 2023, '1.2 G/TRD'),
('Toyota', 'Agya', 2020, 2023, '1.2 GR Sport'),
('Toyota', 'Agya', 2023, 2025, '1.2 E/G/GR Sport'),
-- Daihatsu Ayla
('Daihatsu', 'Ayla', 2013, 2017, '1.0 D/M/X'),
('Daihatsu', 'Ayla', 2013, 2017, '1.0 Elegant'),
('Daihatsu', 'Ayla', 2017, 2020, '1.0 D/M/X'),
('Daihatsu', 'Ayla', 2017, 2023, '1.2 X/R'),
('Daihatsu', 'Ayla', 2020, 2023, '1.2 R Deluxe'),
('Daihatsu', 'Ayla', 2023, 2025, '1.0 M/X / 1.2 R');

-- Selesai --
-- Anda dapat menambahkan data produk dan kompatibilitas di sini.
-- Contoh:
-- with filter_id as (select id from categories where name = 'Filters'),
--      denso_id as (select id from brands where name = 'Denso')
-- insert into products (name, price, stock, category_id, brand_id, part_number, barcode)
-- values ('Filter Udara Avanza/Xenia', 150000, 50, filter_id, denso_id, 'DXA-123', '899000000001');
