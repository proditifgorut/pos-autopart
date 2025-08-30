import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { Shift } from '../types/database';
import { useAuth } from '../contexts/AuthContext';

export const useShifts = () => {
  const { user } = useAuth();
  const [currentShift, setCurrentShift] = useState<Shift | null>(null);
  const [shifts, setShifts] = useState<Shift[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchCurrentShift = async () => {
    if (!user) return;
    try {
      const { data, error } = await supabase
        .from('shifts')
        .select('*')
        .eq('status', 'open')
        .eq('staff_id', user.id)
        .order('start_time', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (error) throw error;
      setCurrentShift(data);
    } catch (err: any) {
      setError(err.message);
    }
  };

  const fetchShifts = async () => {
    if (!user) return;
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('shifts')
        .select('*')
        .eq('staff_id', user.id)
        .order('start_time', { ascending: false })
        .limit(10);

      if (error) throw error;
      setShifts(data || []);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const openShift = async (openingCash: number) => {
    if (!user) throw new Error('User not authenticated');
    try {
      const { data, error } = await supabase
        .from('shifts')
        .insert([{
          staff_id: user.id,
          start_time: new Date().toISOString(),
          opening_cash: openingCash,
          status: 'open'
        }])
        .select()
        .single();

      if (error) throw error;
      setCurrentShift(data);
      await fetchShifts();
      return data;
    } catch (err: any) {
      setError(err.message);
      throw err;
    }
  };

  const closeShift = async (closingCash: number) => {
    if (!user) throw new Error('User not authenticated');
    try {
      if (!currentShift) throw new Error('No active shift to close');

      const { data: shiftTransactions, error: transactionError } = await supabase
        .from('transactions')
        .select('total_amount')
        .eq('shift_id', currentShift.id);

      if (transactionError) throw transactionError;

      const totalSales = shiftTransactions?.reduce((sum, t) => sum + t.total_amount, 0) || 0;
      const totalTransactions = shiftTransactions?.length || 0;

      const { data, error } = await supabase
        .from('shifts')
        .update({
          end_time: new Date().toISOString(),
          closing_cash: closingCash,
          total_sales: totalSales,
          total_transactions: totalTransactions,
          status: 'closed'
        })
        .eq('id', currentShift.id)
        .select()
        .single();

      if (error) throw error;
      setCurrentShift(null);
      await fetchShifts();
      return data;
    } catch (err: any) {
      setError(err.message);
      throw err;
    }
  };

  useEffect(() => {
    if (user) {
      fetchCurrentShift();
      fetchShifts();
    } else {
      setLoading(false);
    }
  }, [user]);

  return {
    currentShift,
    shifts,
    loading,
    error,
    openShift,
    closeShift,
    refreshShifts: fetchShifts
  };
};
