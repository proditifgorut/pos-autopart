import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Database types
export interface DatabaseProduct {
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
  created_at: string;
  updated_at: string;
  categories: { name: string };
  brands: { name: string };
}

export interface DatabaseTransaction {
  id: string;
  customer_id?: string;
  staff_id: string;
  transaction_date: string;
  subtotal: number;
  tax: number;
  discount: number;
  total_amount: number;
  payment_method: string;
  payment_amount: number;
  change_amount: number;
  notes?: string;
  shift_id?: string;
}

export interface DatabaseShift {
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
