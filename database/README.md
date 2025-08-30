# Database Schema untuk POS Onderdil Mobil

## Deskripsi
Database schema lengkap untuk sistem Point of Sale (POS) onderdil mobil dengan fokus pada mobil-mobil populer di Indonesia:
- **Daihatsu**: Xenia, Ayla
- **Toyota**: Avanza, Agya
- **Honda**: Brio

## Struktur Database

### Tables Utama

1. **categories** - Kategori onderdil (Engine, Brake, Suspension, dll)
2. **brands** - Brand/merk onderdil (Toyota, Daihatsu, Honda, Bosch, dll)
3. **car_models** - Model mobil dengan spesifikasi lengkap
4. **products** - Produk onderdil dengan harga dan stok
5. **product_car_compatibility** - Kompatibilitas produk dengan mobil
6. **customers** - Data pelanggan (retail/wholesale)
7. **users** - Staff/kasir sistem
8. **transactions** - Transaksi penjualan
9. **transaction_items** - Detail item dalam transaksi
10. **inventory_movements** - Tracking pergerakan stok

### Data Dummy yang Tersedia

#### Mobil dan Varian:
- **Daihatsu Xenia**: Generasi 2004-2011, 2012-2015, 2015-2023
- **Toyota Avanza**: Generasi 2004-2011, 2012-2015, 2015-2021
- **Honda Brio**: Generasi 2013-2018, 2018-2023
- **Toyota Agya**: Generasi 2013-2017, 2017-2023
- **Daihatsu Ayla**: Generasi 2013-2017, 2017-2023

#### Onderdil yang Tersedia:
- Filter Udara (semua model)
- Filter Oli (semua model)
- Kampas Rem Depan & Belakang
- Shock Absorber Depan
- Busi (sesuai tipe mesin)
- Timing Belt

#### Brand Onderdil:
- Original: Toyota Genuine Parts, Daihatsu Genuine Parts, Honda Genuine Parts
- Aftermarket: Bosch, Denso, NGK, Brembo, Monroe, KYB, dll

## Cara Penggunaan

### 1. Setup di Supabase
```sql
-- Jalankan file dbonderdil.sql di Supabase SQL Editor
-- File ini akan membuat semua tabel, data dummy, dan konfigurasi
```

### 2. Konfigurasi Row Level Security (RLS)
Database sudah dikonfigurasi dengan RLS untuk keamanan:
- Public read access untuk produk dan transaksi
- Authenticated user access untuk insert/update

### 3. Indexes yang Sudah Dibuat
- Performance optimized untuk pencarian produk
- Index pada kategori, brand, part number
- Index pada transaksi berdasarkan tanggal dan customer

## Fitur Database

### Relational Integrity
- Foreign key constraints untuk menjaga konsistensi data
- Trigger untuk auto-update timestamps

### Kompatibilitas Produk
- Sistem mapping produk ke mobil yang kompatibel
- Support untuk satu produk yang cocok untuk multiple mobil

### Inventory Management
- Tracking stok real-time
- Minimum stock alerts
- Inventory movement history

### Transaction Management
- Complete transaction flow
- Support multiple payment methods
- Automatic tax calculation (PPN 11%)

## Query Contoh

### Cari produk untuk mobil tertentu:
```sql
SELECT p.*, b.name as brand_name, c.name as category_name
FROM products p
JOIN brands b ON p.brand_id = b.id
JOIN categories c ON p.category_id = c.id
JOIN product_car_compatibility pcc ON p.id = pcc.product_id
JOIN car_models cm ON pcc.car_model_id = cm.id
WHERE cm.brand = 'Toyota' AND cm.model LIKE '%Avanza%';
```

### Laporan penjualan harian:
```sql
SELECT 
  DATE(transaction_date) as tanggal,
  COUNT(*) as jumlah_transaksi,
  SUM(total_amount) as total_penjualan
FROM transactions
WHERE DATE(transaction_date) = CURRENT_DATE
GROUP BY DATE(transaction_date);
```

### Produk dengan stok menipis:
```sql
SELECT name, stock, min_stock, part_number
FROM products
WHERE stock <= min_stock
ORDER BY stock ASC;
```

## Catatan Penting
- Semua harga dalam Rupiah (IDR)
- Timestamps menggunakan timezone Indonesia
- Support untuk customer retail dan wholesale
- Sistem role-based access (admin, manager, cashier)

Gunakan database ini sebagai foundation untuk aplikasi POS onderdil mobil yang lengkap dan scalable.
