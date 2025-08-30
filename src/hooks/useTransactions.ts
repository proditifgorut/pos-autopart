import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { Transaction, TransactionItem } from '../types/database';
import { useAuth } from '../contexts/AuthContext';

export const useTransactions = () => {
  const { user } = useAuth();
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchTransactions = async (limit?: number) => {
    try {
      setLoading(true);
      let query = supabase
        .from('transactions')
        .select(`
          *,
          customers(name, phone),
          transaction_items(
            *,
            products(name, part_number)
          )
        `)
        .order('transaction_date', { ascending: false });

      if (limit) {
        query = query.limit(limit);
      }

      const { data, error } = await query;

      if (error) throw error;
      setTransactions(data || []);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const createTransaction = async (
    transactionData: Omit<Transaction, 'id' | 'transaction_date' | 'staff_id'>,
    items: Omit<TransactionItem, 'id' | 'transaction_id'>[]
  ) => {
    if (!user) throw new Error("User not authenticated");
    try {
      // Create transaction
      const { data: transaction, error: transactionError } = await supabase
        .from('transactions')
        .insert([{
          ...transactionData,
          staff_id: user.id,
          transaction_date: new Date().toISOString()
        }])
        .select()
        .single();

      if (transactionError) throw transactionError;

      // Create transaction items
      const transactionItems = items.map(item => ({
        ...item,
        transaction_id: transaction.id
      }));

      const { error: itemsError } = await supabase
        .from('transaction_items')
        .insert(transactionItems);

      if (itemsError) throw itemsError;

      // Update product stocks
      for (const item of items) {
        const { error: stockError } = await supabase.rpc('update_product_stock_on_sale', {
          p_product_id: item.product_id,
          p_quantity_sold: item.quantity,
          p_transaction_id: transaction.id
        });

        if (stockError) console.error('Stock update RPC error:', stockError);
      }

      await fetchTransactions();
      return transaction;
    } catch (err: any) {
      setError(err.message);
      throw err;
    }
  };

  useEffect(() => {
    fetchTransactions();
  }, []);

  return {
    transactions,
    loading,
    error,
    createTransaction,
    refreshTransactions: fetchTransactions
  };
};
