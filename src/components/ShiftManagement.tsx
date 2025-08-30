import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Clock, DollarSign, TrendingUp, Users, LogIn, LogOut } from 'lucide-react';
import { useShifts } from '../hooks/useShifts';
import { format } from 'date-fns';
import { id } from 'date-fns/locale';

export const ShiftManagement: React.FC = () => {
  const { currentShift, shifts, openShift, closeShift, loading } = useShifts();
  const [showOpenShift, setShowOpenShift] = useState(false);
  const [showCloseShift, setShowCloseShift] = useState(false);
  const [openingCash, setOpeningCash] = useState('');
  const [closingCash, setClosingCash] = useState('');

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
    }).format(amount);
  };

  const handleOpenShift = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await openShift(parseFloat(openingCash));
      setShowOpenShift(false);
      setOpeningCash('');
      alert('Shift berhasil dibuka!');
    } catch (error) {
      console.error('Error opening shift:', error);
      alert('Gagal membuka shift');
    }
  };

  const handleCloseShift = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await closeShift(parseFloat(closingCash));
      setShowCloseShift(false);
      setClosingCash('');
      alert('Shift berhasil ditutup!');
    } catch (error) {
      console.error('Error closing shift:', error);
      alert('Gagal menutup shift');
    }
  };

  if (loading) {
    return (
      <div className="p-4 flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-neon-blue"></div>
      </div>
    );
  }

  return (
    <div className="p-4 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold">Manajemen Shift</h2>
        {currentShift ? (
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={() => setShowCloseShift(true)}
            className="bg-gradient-to-r from-red-500 to-red-600 px-4 py-2 rounded-lg font-semibold flex items-center gap-2"
          >
            <LogOut className="w-5 h-5" />
            Tutup Shift
          </motion.button>
        ) : (
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={() => setShowOpenShift(true)}
            className="bg-gradient-to-r from-neon-blue to-neon-green px-4 py-2 rounded-lg font-semibold flex items-center gap-2"
          >
            <LogIn className="w-5 h-5" />
            Buka Shift
          </motion.button>
        )}
      </div>

      {/* Current Shift Status */}
      {currentShift ? (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-gradient-to-r from-green-500/20 to-green-600/20 border border-green-500/30 rounded-xl p-6"
        >
          <div className="flex items-center gap-3 mb-4">
            <Clock className="w-6 h-6 text-green-400" />
            <h3 className="text-lg font-semibold text-green-400">Shift Aktif</h3>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <p className="text-sm text-gray-400">Mulai Shift</p>
              <p className="font-semibold">
                {format(new Date(currentShift.start_time), 'dd/MM/yyyy HH:mm', { locale: id })}
              </p>
            </div>
            <div>
              <p className="text-sm text-gray-400">Modal Awal</p>
              <p className="font-semibold text-green-400">
                {formatCurrency(currentShift.opening_cash)}
              </p>
            </div>
            <div>
              <p className="text-sm text-gray-400">Durasi</p>
              <p className="font-semibold">
                {Math.floor((new Date().getTime() - new Date(currentShift.start_time).getTime()) / (1000 * 60 * 60))} jam
              </p>
            </div>
          </div>
        </motion.div>
      ) : (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-dark-100/50 backdrop-blur-sm border border-gray-700 rounded-xl p-6 text-center"
        >
          <Clock className="w-16 h-16 text-gray-500 mx-auto mb-4" />
          <h3 className="text-lg font-semibold text-gray-400 mb-2">Tidak Ada Shift Aktif</h3>
          <p className="text-gray-500 mb-4">Silakan buka shift untuk memulai transaksi</p>
        </motion.div>
      )}

      {/* Shift History */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
        className="bg-dark-100/50 backdrop-blur-sm border border-gray-700 rounded-xl overflow-hidden"
      >
        <div className="p-4 border-b border-gray-700">
          <h3 className="text-lg font-semibold">Riwayat Shift</h3>
        </div>
        
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-dark-200/50">
              <tr>
                <th className="text-left p-4">Tanggal</th>
                <th className="text-left p-4">Durasi</th>
                <th className="text-left p-4">Modal Awal</th>
                <th className="text-left p-4">Modal Akhir</th>
                <th className="text-left p-4">Total Penjualan</th>
                <th className="text-left p-4">Transaksi</th>
                <th className="text-left p-4">Status</th>
              </tr>
            </thead>
            <tbody>
              {shifts.map((shift) => {
                const duration = shift.end_time 
                  ? Math.floor((new Date(shift.end_time).getTime() - new Date(shift.start_time).getTime()) / (1000 * 60 * 60))
                  : null;
                
                return (
                  <tr key={shift.id} className="border-t border-gray-700 hover:bg-dark-200/30">
                    <td className="p-4">
                      <div>
                        <p className="font-medium">
                          {format(new Date(shift.start_time), 'dd/MM/yyyy', { locale: id })}
                        </p>
                        <p className="text-xs text-gray-400">
                          {format(new Date(shift.start_time), 'HH:mm', { locale: id })} - 
                          {shift.end_time ? format(new Date(shift.end_time), 'HH:mm', { locale: id }) : 'Aktif'}
                        </p>
                      </div>
                    </td>
                    <td className="p-4">
                      {duration ? `${duration} jam` : '-'}
                    </td>
                    <td className="p-4 font-semibold">
                      {formatCurrency(shift.opening_cash)}
                    </td>
                    <td className="p-4 font-semibold">
                      {shift.closing_cash ? formatCurrency(shift.closing_cash) : '-'}
                    </td>
                    <td className="p-4 font-semibold text-neon-blue">
                      {shift.total_sales ? formatCurrency(shift.total_sales) : '-'}
                    </td>
                    <td className="p-4">
                      {shift.total_transactions || 0}
                    </td>
                    <td className="p-4">
                      <span className={`px-2 py-1 text-xs rounded-full ${
                        shift.status === 'open' 
                          ? 'bg-green-500/20 text-green-400'
                          : 'bg-gray-500/20 text-gray-400'
                      }`}>
                        {shift.status === 'open' ? 'Aktif' : 'Selesai'}
                      </span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </motion.div>

      {/* Open Shift Modal */}
      <AnimatePresence>
        {showOpenShift && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4"
          >
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              className="bg-dark-100 border border-gray-700 rounded-xl w-full max-w-md"
            >
              <div className="p-6">
                <h3 className="text-xl font-bold mb-4">Buka Shift Baru</h3>
                
                <form onSubmit={handleOpenShift} className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium mb-2">Modal Awal Kasir</label>
                    <input
                      type="number"
                      value={openingCash}
                      onChange={(e) => setOpeningCash(e.target.value)}
                      required
                      min="0"
                      step="1000"
                      placeholder="0"
                      className="w-full bg-dark-200 border border-gray-600 rounded-lg px-3 py-2 focus:outline-none focus:border-neon-blue"
                    />
                    <p className="text-xs text-gray-400 mt-1">
                      Masukkan jumlah uang tunai di laci kasir saat memulai shift
                    </p>
                  </div>
                  
                  <div className="flex gap-3 pt-4">
                    <button
                      type="submit"
                      className="flex-1 bg-gradient-to-r from-neon-blue to-neon-green py-2 rounded-lg font-semibold hover:shadow-lg transition-all duration-300"
                    >
                      Buka Shift
                    </button>
                    <button
                      type="button"
                      onClick={() => {
                        setShowOpenShift(false);
                        setOpeningCash('');
                      }}
                      className="px-6 py-2 border border-gray-600 rounded-lg hover:bg-dark-200 transition-colors"
                    >
                      Batal
                    </button>
                  </div>
                </form>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Close Shift Modal */}
      <AnimatePresence>
        {showCloseShift && currentShift && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4"
          >
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              className="bg-dark-100 border border-gray-700 rounded-xl w-full max-w-md"
            >
              <div className="p-6">
                <h3 className="text-xl font-bold mb-4">Tutup Shift</h3>
                
                <div className="bg-dark-200/50 rounded-lg p-4 mb-4">
                  <div className="flex justify-between mb-2">
                    <span>Modal Awal:</span>
                    <span className="font-semibold">{formatCurrency(currentShift.opening_cash)}</span>
                  </div>
                  <div className="flex justify-between mb-2">
                    <span>Durasi Shift:</span>
                    <span className="font-semibold">
                      {Math.floor((new Date().getTime() - new Date(currentShift.start_time).getTime()) / (1000 * 60 * 60))} jam
                    </span>
                  </div>
                </div>
                
                <form onSubmit={handleCloseShift} className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium mb-2">Modal Akhir Kasir</label>
                    <input
                      type="number"
                      value={closingCash}
                      onChange={(e) => setClosingCash(e.target.value)}
                      required
                      min="0"
                      step="1000"
                      placeholder="0"
                      className="w-full bg-dark-200 border border-gray-600 rounded-lg px-3 py-2 focus:outline-none focus:border-neon-blue"
                    />
                    <p className="text-xs text-gray-400 mt-1">
                      Hitung total uang tunai di laci kasir saat ini
                    </p>
                  </div>
                  
                  <div className="flex gap-3 pt-4">
                    <button
                      type="submit"
                      className="flex-1 bg-gradient-to-r from-red-500 to-red-600 py-2 rounded-lg font-semibold hover:shadow-lg transition-all duration-300"
                    >
                      Tutup Shift
                    </button>
                    <button
                      type="button"
                      onClick={() => {
                        setShowCloseShift(false);
                        setClosingCash('');
                      }}
                      className="px-6 py-2 border border-gray-600 rounded-lg hover:bg-dark-200 transition-colors"
                    >
                      Batal
                    </button>
                  </div>
                </form>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};
