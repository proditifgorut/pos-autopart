export type UserRole = 'store_owner' | 'warehouse_admin' | 'shopkeeper';

export interface Profile {
  id: string;
  updated_at?: string;
  full_name: string;
  avatar_url?: string;
  role: UserRole;
}

export interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  stock: number;
  min_stock: number;
  category_id: string;
  brand_id: string;
  part_number: string;
  barcode: string;
  image_url: string;
  weight: number;
  dimensions: string;
  is_active: boolean;
  categories?: { name: string };
  brands?: { name: string };
}

export interface Category {
  id: string;
  name: string;
  description: string;
}

export interface Brand {
  id: string;
  name: string;
  country: string;
}

export interface Customer {
  id: string;
  name: string;
  phone: string;
  email?: string;
  address?: string;
  customer_type: 'retail' | 'wholesale';
  total_purchases: number;
  last_purchase?: string;
}

export interface Transaction {
  id: string;
  customer_id?: string;
  staff_id: string;
  transaction_date: string;
  subtotal: number;
  tax: number;
  discount: number;
  total_amount: number;
  payment_method: 'cash' | 'card' | 'transfer' | 'qris';
  payment_amount: number;
  change_amount: number;
  notes?: string;
  shift_id?: string;
  transaction_items?: TransactionItem[];
  customers?: Customer;
}

export interface TransactionItem {
  id: string;
  transaction_id: string;
  product_id: string;
  quantity: number;
  unit_price: number;
  subtotal: number;
  products?: Product;
}

export interface Shift {
  id: string;
  staff_id: string;
  start_time: string;
  end_time?: string;
  opening_cash: number;
  closing_cash?: number;
  total_sales?: number;
  total_transactions?: number;
  status: 'open' | 'closed';
}

export interface InventoryMovement {
  id: string;
  product_id: string;
  movement_type: 'in' | 'out' | 'adjustment';
  quantity: number;
  reference_type?: string;
  reference_id?: string;
  notes?: string;
  created_at: string;
}
