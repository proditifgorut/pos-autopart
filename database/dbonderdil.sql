-- Database Schema untuk POS Onderdil Mobil
-- Sistem manajemen onderdil untuk Xenia, Avanza, Brio, Agya, Ayla

-- Table: categories (Kategori onderdil)
CREATE TABLE categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  icon VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: brands (Merk onderdil)
CREATE TABLE brands (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  country VARCHAR(50),
  website VARCHAR(200),
  logo_url VARCHAR(500),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: car_models (Model mobil)
CREATE TABLE car_models (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  brand VARCHAR(50) NOT NULL,
  model VARCHAR(100) NOT NULL,
  year_start INTEGER,
  year_end INTEGER,
  engine_type VARCHAR(50),
  fuel_type VARCHAR(20),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: products (Produk onderdil)
CREATE TABLE products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  description TEXT,
  part_number VARCHAR(100) UNIQUE NOT NULL,
  barcode VARCHAR(50),
  category_id UUID REFERENCES categories(id),
  brand_id UUID REFERENCES brands(id),
  price DECIMAL(15,2) NOT NULL,
  cost_price DECIMAL(15,2),
  stock INTEGER DEFAULT 0,
  min_stock INTEGER DEFAULT 5,
  max_stock INTEGER DEFAULT 100,
  weight DECIMAL(8,2),
  dimensions VARCHAR(50),
  image_url VARCHAR(500),
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: product_car_compatibility (Kompatibilitas produk dengan mobil)
CREATE TABLE product_car_compatibility (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID REFERENCES products(id),
  car_model_id UUID REFERENCES car_models(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: customers (Pelanggan)
CREATE TABLE customers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  phone VARCHAR(20),
  email VARCHAR(100),
  address TEXT,
  customer_type VARCHAR(20) DEFAULT 'retail', -- retail, wholesale
  tax_number VARCHAR(50),
  credit_limit DECIMAL(15,2) DEFAULT 0,
  total_purchases DECIMAL(15,2) DEFAULT 0,
  last_purchase_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: users (Staff/Kasir)
CREATE TABLE users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  phone VARCHAR(20),
  role VARCHAR(20) DEFAULT 'cashier', -- admin, cashier, manager
  password_hash VARCHAR(200),
  avatar_url VARCHAR(500),
  is_active BOOLEAN DEFAULT true,
  last_login TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: transactions (Transaksi penjualan)
CREATE TABLE transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  transaction_number VARCHAR(50) UNIQUE NOT NULL,
  customer_id UUID REFERENCES customers(id),
  cashier_id UUID REFERENCES users(id),
  subtotal DECIMAL(15,2) NOT NULL,
  discount_amount DECIMAL(15,2) DEFAULT 0,
  tax_amount DECIMAL(15,2) DEFAULT 0,
  total_amount DECIMAL(15,2) NOT NULL,
  payment_method VARCHAR(20), -- cash, card, transfer, qris
  payment_amount DECIMAL(15,2),
  change_amount DECIMAL(15,2) DEFAULT 0,
  status VARCHAR(20) DEFAULT 'completed', -- pending, completed, cancelled
  notes TEXT,
  transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: transaction_items (Item dalam transaksi)
CREATE TABLE transaction_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  transaction_id UUID REFERENCES transactions(id),
  product_id UUID REFERENCES products(id),
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(15,2) NOT NULL,
  discount_amount DECIMAL(15,2) DEFAULT 0,
  total_price DECIMAL(15,2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: inventory_movements (Pergerakan stok)
CREATE TABLE inventory_movements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID REFERENCES products(id),
  movement_type VARCHAR(20), -- in, out, adjustment
  quantity INTEGER NOT NULL,
  reference_type VARCHAR(20), -- purchase, sale, adjustment
  reference_id UUID,
  notes TEXT,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- INSERT DATA DUMMY

-- Categories
INSERT INTO categories (name, description, icon) VALUES
('Engine', 'Komponen mesin dan sistem pembakaran', 'engine'),
('Brake', 'Sistem rem dan komponen pengereman', 'brake-disc'),
('Suspension', 'Sistem suspensi dan shock absorber', 'suspension'),
('Electrical', 'Sistem kelistrikan dan elektronik', 'battery'),
('Body', 'Komponen bodi dan eksterior', 'car'),
('Transmission', 'Sistem transmisi dan kopling', 'gears'),
('Cooling', 'Sistem pendingin dan radiator', 'thermometer'),
('Fuel System', 'Sistem bahan bakar dan injeksi', 'fuel'),
('Exhaust', 'Sistem pembuangan dan knalpot', 'wind'),
('Interior', 'Komponen interior dan aksesoris', 'seat');

-- Brands
INSERT INTO brands (name, description, country, website) VALUES
('Toyota Genuine Parts', 'Suku cadang asli Toyota', 'Japan', 'https://toyota.co.id'),
('Daihatsu Genuine Parts', 'Suku cadang asli Daihatsu', 'Japan', 'https://daihatsu.co.id'),
('Honda Genuine Parts', 'Suku cadang asli Honda', 'Japan', 'https://honda.co.id'),
('Bosch', 'Komponen otomotif premium', 'Germany', 'https://bosch.com'),
('Denso', 'Sistem kelistrikan dan AC', 'Japan', 'https://denso.com'),
('NGK', 'Busi dan sistem pengapian', 'Japan', 'https://ngk.com'),
('Brembo', 'Sistem rem premium', 'Italy', 'https://brembo.com'),
('Monroe', 'Shock absorber dan suspensi', 'USA', 'https://monroe.com'),
('KYB', 'Shock absorber dan komponen suspensi', 'Japan', 'https://kyb.com'),
('Philips', 'Lampu dan sistem pencahayaan', 'Netherlands', 'https://philips.com'),
('Osram', 'Lampu otomotif', 'Germany', 'https://osram.com'),
('Bendix', 'Kampas rem dan komponen brake', 'USA', 'https://bendix.com'),
('Gates', 'Timing belt dan belt sistem', 'USA', 'https://gates.com'),
('Mann Filter', 'Filter udara, oli, dan bahan bakar', 'Germany', 'https://mannfilter.com'),
('Mobil 1', 'Oli mesin premium', 'USA', 'https://mobil1.com');

-- Car Models
INSERT INTO car_models (brand, model, year_start, year_end, engine_type, fuel_type) VALUES
('Daihatsu', 'Xenia 1.0 M', 2004, 2011, '3SZ-VE 1.0L', 'Gasoline'),
('Daihatsu', 'Xenia 1.3 Xi', 2004, 2011, 'K3-VE 1.3L', 'Gasoline'),
('Daihatsu', 'Xenia 1.3 Li', 2004, 2011, 'K3-VE 1.3L', 'Gasoline'),
('Daihatsu', 'New Xenia 1.0 M', 2012, 2015, '1KR-VE 1.0L', 'Gasoline'),
('Daihatsu', 'New Xenia 1.3 X', 2012, 2015, '2NR-VE 1.3L', 'Gasoline'),
('Daihatsu', 'New Xenia 1.3 R', 2012, 2015, '2NR-VE 1.3L', 'Gasoline'),
('Daihatsu', 'Grand New Xenia 1.0 M', 2015, 2023, '1KR-VE 1.0L', 'Gasoline'),
('Daihatsu', 'Grand New Xenia 1.3 X', 2015, 2023, '2NR-VE 1.3L', 'Gasoline'),
('Daihatsu', 'Grand New Xenia 1.3 R', 2015, 2023, '2NR-VE 1.3L', 'Gasoline'),
('Toyota', 'Avanza 1.0 E', 2004, 2011, '3SZ-VE 1.0L', 'Gasoline'),
('Toyota', 'Avanza 1.3 G', 2004, 2011, 'K3-VE 1.3L', 'Gasoline'),
('Toyota', 'Avanza 1.3 S', 2004, 2011, 'K3-VE 1.3L', 'Gasoline'),
('Toyota', 'New Avanza 1.0 E', 2012, 2015, '1KR-VE 1.0L', 'Gasoline'),
('Toyota', 'New Avanza 1.3 G', 2012, 2015, '2NR-VE 1.3L', 'Gasoline'),
('Toyota', 'New Avanza 1.3 Veloz', 2012, 2015, '2NR-VE 1.3L', 'Gasoline'),
('Toyota', 'Grand New Avanza 1.0 E', 2015, 2021, '1KR-VE 1.0L', 'Gasoline'),
('Toyota', 'Grand New Avanza 1.3 G', 2015, 2021, '2NR-VE 1.3L', 'Gasoline'),
('Toyota', 'Grand New Avanza 1.3 Veloz', 2015, 2021, '2NR-VE 1.3L', 'Gasoline'),
('Honda', 'Brio Satya S', 2013, 2018, 'L12B 1.2L', 'Gasoline'),
('Honda', 'Brio Satya E', 2013, 2018, 'L12B 1.2L', 'Gasoline'),
('Honda', 'New Brio Satya S', 2018, 2023, 'L12B 1.2L', 'Gasoline'),
('Honda', 'New Brio Satya E', 2018, 2023, 'L12B 1.2L', 'Gasoline'),
('Toyota', 'Agya 1.0 E', 2013, 2017, '1KR-FE 1.0L', 'Gasoline'),
('Toyota', 'Agya 1.0 G', 2013, 2017, '1KR-FE 1.0L', 'Gasoline'),
('Toyota', 'Agya 1.0 TRD S', 2013, 2017, '1KR-FE 1.0L', 'Gasoline'),
('Toyota', 'New Agya 1.0 E', 2017, 2023, '1KR-VE 1.0L', 'Gasoline'),
('Toyota', 'New Agya 1.0 G', 2017, 2023, '1KR-VE 1.0L', 'Gasoline'),
('Toyota', 'New Agya 1.2 TRD', 2017, 2023, '3NR-FE 1.2L', 'Gasoline'),
('Daihatsu', 'Ayla 1.0 D', 2013, 2017, '1KR-FE 1.0L', 'Gasoline'),
('Daihatsu', 'Ayla 1.0 M', 2013, 2017, '1KR-FE 1.0L', 'Gasoline'),
('Daihatsu', 'Ayla 1.0 X', 2013, 2017, '1KR-FE 1.0L', 'Gasoline'),
('Daihatsu', 'New Ayla 1.0 D', 2017, 2023, '1KR-VE 1.0L', 'Gasoline'),
('Daihatsu', 'New Ayla 1.0 M', 2017, 2023, '1KR-VE 1.0L', 'Gasoline'),
('Daihatsu', 'New Ayla 1.2 R', 2017, 2023, '3NR-FE 1.2L', 'Gasoline');

-- Products (Sample onderdil untuk mobil-mobil tersebut)
INSERT INTO products (name, description, part_number, barcode, category_id, brand_id, price, cost_price, stock, weight, dimensions, image_url) 
SELECT 
  'Filter Udara ' || cm.brand || ' ' || cm.model,
  'Filter udara original untuk ' || cm.brand || ' ' || cm.model || ' tahun ' || cm.year_start || '-' || cm.year_end,
  'FA-' || UPPER(SUBSTRING(cm.brand, 1, 3)) || '-' || LPAD((ROW_NUMBER() OVER())::TEXT, 4, '0'),
  '123456789' || LPAD((ROW_NUMBER() OVER())::TEXT, 4, '0'),
  c.id,
  CASE cm.brand 
    WHEN 'Toyota' THEN (SELECT id FROM brands WHERE name = 'Toyota Genuine Parts')
    WHEN 'Daihatsu' THEN (SELECT id FROM brands WHERE name = 'Daihatsu Genuine Parts')
    WHEN 'Honda' THEN (SELECT id FROM brands WHERE name = 'Honda Genuine Parts')
  END,
  CASE 
    WHEN cm.brand IN ('Toyota', 'Honda') THEN 85000 + (RANDOM() * 40000)::INTEGER
    ELSE 75000 + (RANDOM() * 35000)::INTEGER
  END,
  CASE 
    WHEN cm.brand IN ('Toyota', 'Honda') THEN 55000 + (RANDOM() * 25000)::INTEGER
    ELSE 45000 + (RANDOM() * 20000)::INTEGER
  END,
  (RANDOM() * 50 + 10)::INTEGER,
  0.3 + (RANDOM() * 0.5),
  '25x20x5cm',
  'https://picsum.photos/400/300?random=' || (ROW_NUMBER() OVER())::TEXT
FROM car_models cm, categories c
WHERE c.name = 'Engine'
LIMIT 33;

INSERT INTO products (name, description, part_number, barcode, category_id, brand_id, price, cost_price, stock, weight, dimensions, image_url) 
SELECT 
  'Filter Oli ' || cm.brand || ' ' || cm.model,
  'Filter oli mesin original untuk ' || cm.brand || ' ' || cm.model,
  'FO-' || UPPER(SUBSTRING(cm.brand, 1, 3)) || '-' || LPAD((ROW_NUMBER() OVER())::TEXT, 4, '0'),
  '223456789' || LPAD((ROW_NUMBER() OVER())::TEXT, 4, '0'),
  c.id,
  CASE cm.brand 
    WHEN 'Toyota' THEN (SELECT id FROM brands WHERE name = 'Toyota Genuine Parts')
    WHEN 'Daihatsu' THEN (SELECT id FROM brands WHERE name = 'Daihatsu Genuine Parts')
    WHEN 'Honda' THEN (SELECT id FROM brands WHERE name = 'Honda Genuine Parts')
  END,
  CASE 
    WHEN cm.brand IN ('Toyota', 'Honda') THEN 45000 + (RANDOM() * 25000)::INTEGER
    ELSE 35000 + (RANDOM() * 20000)::INTEGER
  END,
  CASE 
    WHEN cm.brand IN ('Toyota', 'Honda') THEN 25000 + (RANDOM() * 15000)::INTEGER
    ELSE 20000 + (RANDOM() * 12000)::INTEGER
  END,
  (RANDOM() * 80 + 20)::INTEGER,
  0.2 + (RANDOM() * 0.3),
  '10x10x8cm',
  'https://picsum.photos/400/300?random=' || (100 + ROW_NUMBER() OVER())::TEXT
FROM car_models cm, categories c
WHERE c.name = 'Engine'
LIMIT 33;

INSERT INTO products (name, description, part_number, barcode, category_id, brand_id, price, cost_price, stock, weight, dimensions, image_url) 
SELECT 
  'Kampas Rem Depan ' || cm.brand || ' ' || cm.model,
  'Kampas rem depan original untuk ' || cm.brand || ' ' || cm.model,
  'KRD-' || UPPER(SUBSTRING(cm.brand, 1, 3)) || '-' || LPAD((ROW_NUMBER() OVER())::TEXT, 4, '0'),
  '323456789' || LPAD((ROW_NUMBER() OVER())::TEXT, 4, '0'),
  c.id,
  (SELECT id FROM brands WHERE name = 'Bendix'),
  CASE 
    WHEN cm.brand IN ('Toyota', 'Honda') THEN 180000 + (RANDOM() * 120000)::INTEGER
    ELSE 150000 + (RANDOM() * 100000)::INTEGER
  END,
  CASE 
    WHEN cm.brand IN ('Toyota', 'Honda') THEN 120000 + (RANDOM() * 80000)::INTEGER
    ELSE 100000 + (RANDOM() * 60000)::INTEGER
  END,
  (RANDOM() * 40 + 5)::INTEGER,
  1.2 + (RANDOM() * 0.8),
  '20x15x2cm',
  'https://picsum.photos/400/300?random=' || (200 + ROW_NUMBER() OVER())::TEXT
FROM car_models cm, categories c
WHERE c.name = 'Brake'
LIMIT 33;

INSERT INTO products (name, description, part_number, barcode, category_id, brand_id, price, cost_price, stock, weight, dimensions, image_url) 
SELECT 
  'Kampas Rem Belakang ' || cm.brand || ' ' || cm.model,
  'Kampas rem belakang original untuk ' || cm.brand || ' ' || cm.model,
  'KRB-' || UPPER(SUBSTRING(cm.brand, 1, 3)) || '-' || LPAD((ROW_NUMBER() OVER())::TEXT, 4, '0'),
  '423456789' || LPAD((ROW_NUMBER() OVER())::TEXT, 4, '0'),
  c.id,
  (SELECT id FROM brands WHERE name = 'Bendix'),
  CASE 
    WHEN cm.brand IN ('Toyota', 'Honda') THEN 120000 + (RANDOM() * 80000)::INTEGER
    ELSE 100000 + (RANDOM() * 60000)::INTEGER
  END,
  CASE 
    WHEN cm.brand IN ('Toyota', 'Honda') THEN 80000 + (RANDOM() * 50000)::INTEGER
    ELSE 65000 + (RANDOM() * 40000)::INTEGER
  END,
  (RANDOM() * 30 + 5)::INTEGER,
  0.8 + (RANDOM() * 0.6),
  '15x12x2cm',
  'https://picsum.photos/400/300?random=' || (300 + ROW_NUMBER() OVER())::TEXT
FROM car_models cm, categories c
WHERE c.name = 'Brake'
LIMIT 33;

INSERT INTO products (name, description, part_number, barcode, category_id, brand_id, price, cost_price, stock, weight, dimensions, image_url) 
SELECT 
  'Shock Absorber Depan ' || cm.brand || ' ' || cm.model,
  'Shock absorber depan untuk ' || cm.brand || ' ' || cm.model,
  'SAD-' || UPPER(SUBSTRING(cm.brand, 1, 3)) || '-' || LPAD((ROW_NUMBER() OVER())::TEXT, 4, '0'),
  '523456789' || LPAD((ROW_NUMBER() OVER())::TEXT, 4, '0'),
  c.id,
  (SELECT id FROM brands WHERE name = 'KYB'),
  CASE 
    WHEN cm.brand IN ('Toyota', 'Honda') THEN 450000 + (RANDOM() * 300000)::INTEGER
    ELSE 380000 + (RANDOM() * 250000)::INTEGER
  END,
  CASE 
    WHEN cm.brand IN ('Toyota', 'Honda') THEN 300000 + (RANDOM() * 200000)::INTEGER
    ELSE 250000 + (RANDOM() * 150000)::INTEGER
  END,
  (RANDOM() * 20 + 3)::INTEGER,
  2.5 + (RANDOM() * 1.5),
  '40x15x15cm',
  'https://picsum.photos/400/300?random=' || (400 + ROW_NUMBER() OVER())::TEXT
FROM car_models cm, categories c
WHERE c.name = 'Suspension'
LIMIT 33;

INSERT INTO products (name, description, part_number, barcode, category_id, brand_id, price, cost_price, stock, weight, dimensions, image_url) 
SELECT 
  'Busi ' || cm.brand || ' ' || cm.model,
  'Busi standar untuk ' || cm.brand || ' ' || cm.model || ' mesin ' || cm.engine_type,
  'BUS-' || UPPER(SUBSTRING(cm.brand, 1, 3)) || '-' || LPAD((ROW_NUMBER() OVER())::TEXT, 4, '0'),
  '623456789' || LPAD((ROW_NUMBER() OVER())::TEXT, 4, '0'),
  c.id,
  (SELECT id FROM brands WHERE name = 'NGK'),
  CASE 
    WHEN cm.brand IN ('Toyota', 'Honda') THEN 35000 + (RANDOM() * 25000)::INTEGER
    ELSE 28000 + (RANDOM() * 20000)::INTEGER
  END,
  CASE 
    WHEN cm.brand IN ('Toyota', 'Honda') THEN 22000 + (RANDOM() * 15000)::INTEGER
    ELSE 18000 + (RANDOM() * 12000)::INTEGER
  END,
  (RANDOM() * 100 + 20)::INTEGER,
  0.1 + (RANDOM() * 0.05),
  '8x3x3cm',
  'https://picsum.photos/400/300?random=' || (500 + ROW_NUMBER() OVER())::TEXT
FROM car_models cm, categories c
WHERE c.name = 'Electrical'
LIMIT 33;

INSERT INTO products (name, description, part_number, barcode, category_id, brand_id, price, cost_price, stock, weight, dimensions, image_url) 
SELECT 
  'Timing Belt ' || cm.brand || ' ' || cm.model,
  'Timing belt untuk ' || cm.brand || ' ' || cm.model || ' mesin ' || cm.engine_type,
  'TB-' || UPPER(SUBSTRING(cm.brand, 1, 3)) || '-' || LPAD((ROW_NUMBER() OVER())::TEXT, 4, '0'),
  '723456789' || LPAD((ROW_NUMBER() OVER())::TEXT, 4, '0'),
  c.id,
  (SELECT id FROM brands WHERE name = 'Gates'),
  CASE 
    WHEN cm.brand IN ('Toyota', 'Honda') THEN 180000 + (RANDOM() * 120000)::INTEGER
    ELSE 150000 + (RANDOM() * 100000)::INTEGER
  END,
  CASE 
    WHEN cm.brand IN ('Toyota', 'Honda') THEN 120000 + (RANDOM() * 80000)::INTEGER
    ELSE 100000 + (RANDOM() * 60000)::INTEGER
  END,
  (RANDOM() * 25 + 5)::INTEGER,
  0.4 + (RANDOM() * 0.3),
  '30x5x2cm',
  'https://picsum.photos/400/300?random=' || (600 + ROW_NUMBER() OVER())::TEXT
FROM car_models cm, categories c
WHERE c.name = 'Engine'
LIMIT 33;

-- Buat kompatibilitas produk dengan mobil
INSERT INTO product_car_compatibility (product_id, car_model_id)
SELECT p.id, cm.id
FROM products p, car_models cm
WHERE p.name LIKE '%' || cm.brand || '%' || cm.model || '%'
OR p.name LIKE '%' || cm.brand || '%';

-- Sample customers
INSERT INTO customers (name, phone, email, address, customer_type, total_purchases) VALUES
('Budi Santoso', '081234567890', 'budi@email.com', 'Jl. Raya Jakarta No. 123', 'retail', 2500000),
('Sari Motor Workshop', '087654321098', 'sari.motor@email.com', 'Jl. Sudirman No. 456', 'wholesale', 15000000),
('Ahmad Kurniawan', '085567891234', 'ahmad@email.com', 'Jl. Gatot Subroto No. 789', 'retail', 850000),
('Bengkel Maju Jaya', '081987654321', 'maju.jaya@email.com', 'Jl. Ahmad Yani No. 321', 'wholesale', 8500000),
('Dewi Lestari', '089876543210', 'dewi@email.com', 'Jl. Diponegoro No. 654', 'retail', 1200000);

-- Sample users/staff
INSERT INTO users (name, email, phone, role, password_hash, is_active) VALUES
('Budi Santoso', 'budi@autoparts.com', '081234567890', 'cashier', '$2a$10$example_hash', true),
('Siti Nurhaliza', 'siti@autoparts.com', '087654321098', 'cashier', '$2a$10$example_hash', true),
('Ahmad Fauzi', 'ahmad@autoparts.com', '085567891234', 'manager', '$2a$10$example_hash', true),
('Rina Pratiwi', 'rina@autoparts.com', '081987654321', 'admin', '$2a$10$example_hash', true);

-- Sample transactions
INSERT INTO transactions (transaction_number, customer_id, cashier_id, subtotal, discount_amount, tax_amount, total_amount, payment_method, payment_amount, change_amount, transaction_date)
SELECT 
  'TXN-' || TO_CHAR(NOW() - (RANDOM() * INTERVAL '30 days'), 'YYYYMMDD') || '-' || LPAD((ROW_NUMBER() OVER())::TEXT, 4, '0'),
  (SELECT id FROM customers ORDER BY RANDOM() LIMIT 1),
  (SELECT id FROM users WHERE role = 'cashier' ORDER BY RANDOM() LIMIT 1),
  (RANDOM() * 500000 + 100000)::DECIMAL(15,2),
  0,
  ((RANDOM() * 500000 + 100000) * 0.11)::DECIMAL(15,2),
  ((RANDOM() * 500000 + 100000) * 1.11)::DECIMAL(15,2),
  (ARRAY['cash', 'card', 'transfer', 'qris'])[FLOOR(RANDOM() * 4 + 1)],
  ((RANDOM() * 500000 + 100000) * 1.11 + RANDOM() * 50000)::DECIMAL(15,2),
  (RANDOM() * 50000)::DECIMAL(15,2),
  NOW() - (RANDOM() * INTERVAL '30 days')
FROM generate_series(1, 20);

-- Sample transaction items (untuk setiap transaksi)
INSERT INTO transaction_items (transaction_id, product_id, quantity, unit_price, total_price)
SELECT 
  t.id,
  p.id,
  (RANDOM() * 3 + 1)::INTEGER,
  p.price,
  p.price * (RANDOM() * 3 + 1)::INTEGER
FROM transactions t
CROSS JOIN LATERAL (
  SELECT id, price FROM products ORDER BY RANDOM() LIMIT (RANDOM() * 4 + 1)::INTEGER
) p;

-- Update transaction totals berdasarkan items
UPDATE transactions SET 
  subtotal = (
    SELECT COALESCE(SUM(total_price), 0) 
    FROM transaction_items 
    WHERE transaction_id = transactions.id
  ),
  tax_amount = (
    SELECT COALESCE(SUM(total_price), 0) * 0.11
    FROM transaction_items 
    WHERE transaction_id = transactions.id
  ),
  total_amount = (
    SELECT COALESCE(SUM(total_price), 0) * 1.11
    FROM transaction_items 
    WHERE transaction_id = transactions.id
  );

-- Create indexes untuk performance
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_brand ON products(brand_id);
CREATE INDEX idx_products_part_number ON products(part_number);
CREATE INDEX idx_transactions_date ON transactions(transaction_date);
CREATE INDEX idx_transactions_customer ON transactions(customer_id);
CREATE INDEX idx_transaction_items_transaction ON transaction_items(transaction_id);
CREATE INDEX idx_product_car_compatibility_product ON product_car_compatibility(product_id);
CREATE INDEX idx_product_car_compatibility_car ON product_car_compatibility(car_model_id);

-- Create triggers untuk update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_brands_updated_at BEFORE UPDATE ON brands FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS (Row Level Security) untuk keamanan
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policies (sesuaikan dengan kebutuhan auth)
CREATE POLICY "Enable read access for all users" ON products FOR SELECT USING (true);
CREATE POLICY "Enable insert for authenticated users only" ON products FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users only" ON products FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Enable read access for all users" ON transactions FOR SELECT USING (true);
CREATE POLICY "Enable insert for authenticated users only" ON transactions FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable read access for all users" ON customers FOR SELECT USING (true);
CREATE POLICY "Enable insert for authenticated users only" ON customers FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users only" ON customers FOR UPDATE USING (auth.role() = 'authenticated');
