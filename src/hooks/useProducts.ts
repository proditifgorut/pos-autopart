import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { Product, Category, Brand } from '../types/database';

export const useProducts = () => {
  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [brands, setBrands] = useState<Brand[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchProducts = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('products')
        .select(`
          *,
          categories(name),
          brands(name)
        `)
        .eq('is_active', true)
        .order('name');

      if (error) throw error;
      setProducts(data || []);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const fetchCategories = async () => {
    try {
      const { data, error } = await supabase
        .from('categories')
        .select('*')
        .order('name');

      if (error) throw error;
      setCategories(data || []);
    } catch (err: any) {
      setError(err.message);
    }
  };

  const fetchBrands = async () => {
    try {
      const { data, error } = await supabase
        .from('brands')
        .select('*')
        .order('name');

      if (error) throw error;
      setBrands(data || []);
    } catch (err: any) {
      setError(err.message);
    }
  };

  const addProduct = async (product: Omit<Product, 'id'>) => {
    try {
      const { data, error } = await supabase
        .from('products')
        .insert([product])
        .select()
        .single();

      if (error) throw error;
      await fetchProducts();
      return data;
    } catch (err: any) {
      setError(err.message);
      throw err;
    }
  };

  const updateProduct = async (id: string, updates: Partial<Product>) => {
    try {
      const { data, error } = await supabase
        .from('products')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      await fetchProducts();
      return data;
    } catch (err: any) {
      setError(err.message);
      throw err;
    }
  };

  const deleteProduct = async (id: string) => {
    try {
      const { error } = await supabase
        .from('products')
        .update({ is_active: false })
        .eq('id', id);

      if (error) throw error;
      await fetchProducts();
    } catch (err: any) {
      setError(err.message);
      throw err;
    }
  };

  const updateStock = async (productId: string, quantity: number, movementType: 'in' | 'out' | 'adjustment', notes?: string) => {
    try {
      // Start a transaction
      const { data: product, error: productError } = await supabase
        .from('products')
        .select('stock')
        .eq('id', productId)
        .single();

      if (productError) throw productError;

      let newStock = product.stock;
      if (movementType === 'in' || movementType === 'adjustment') {
        newStock = quantity;
      } else if (movementType === 'out') {
        newStock = Math.max(0, product.stock - quantity);
      }

      // Update product stock
      const { error: updateError } = await supabase
        .from('products')
        .update({ stock: newStock })
        .eq('id', productId);

      if (updateError) throw updateError;

      // Record inventory movement
      const { error: movementError } = await supabase
        .from('inventory_movements')
        .insert([{
          product_id: productId,
          movement_type: movementType,
          quantity: movementType === 'out' ? -quantity : quantity,
          notes
        }]);

      if (movementError) throw movementError;

      await fetchProducts();
    } catch (err: any) {
      setError(err.message);
      throw err;
    }
  };

  useEffect(() => {
    fetchProducts();
    fetchCategories();
    fetchBrands();
  }, []);

  return {
    products,
    categories,
    brands,
    loading,
    error,
    addProduct,
    updateProduct,
    deleteProduct,
    updateStock,
    refreshProducts: fetchProducts
  };
};
