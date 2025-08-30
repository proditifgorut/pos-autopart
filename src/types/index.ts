export interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  stock: number;
  category: string;
  brand: string;
  partNumber: string;
  barcode: string;
  image: string;
  carModel: string[];
  weight: number;
  dimensions: string;
}

export interface CartItem {
  product: Product;
  quantity: number;
  discount: number;
}

export interface Customer {
  id: string;
  name: string;
  phone: string;
  email?: string;
  address?: string;
  type: 'retail' | 'wholesale';
  totalPurchases: number;
  lastPurchase?: Date;
}

export interface Transaction {
  id: string;
  customerId?: string;
  customer?: Customer;
  items: CartItem[];
  subtotal: number;
  tax: number;
  discount: number;
  total: number;
  paymentMethod: 'cash' | 'card' | 'transfer' | 'qris';
  paymentAmount: number;
  change: number;
  date: Date;
  cashierId: string;
  notes?: string;
}

export interface User {
  id: string;
  name: string;
  email: string;
  role: 'admin' | 'cashier';
  avatar?: string;
}
