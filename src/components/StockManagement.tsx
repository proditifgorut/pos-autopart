import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Package, TrendingUp, TrendingDown, AlertTriangle, Edit } from 'lucide-react';
import { useProducts } from '../hooks/useProducts';

export const StockManagement: React.FC = () => {
  const { products, loading, updateStock } = useProducts();
  const [selectedProduct, setSelectedProduct] = useState<string>('');
  const [movementType, setMovementType] = useState<'in' | 'out' | 'adjustment'>('in');
  const [quantity, setQuantity] = useState('');
  const [notes, setNotes] = useState('');

  const handleStockUpdate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedProduct || !quantity) return;

    try {
      await updateStock(selectedProduct, parseInt(quantity), movementType, notes);
      setSelectedProduct('');
      setQuantity('');
      setNotes('');
      alert('Stok berhasil diupdate!');
    } catch (error) {
      console.error('Error updating stock:', error);
      alert('Gagal mengupdate stok');
    }
  };

  const lowStockProducts = products.filter(p => p.stock <= p.min_stock);
  const outOfStockProducts = products.filter(p => p.stock === 0);

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
    }).format(amount);
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
      <h2 className="text-2xl font-bold">Manajemen Stok</h2>

      {/* Stock Statistics */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-dark-100/50 backdrop-blur-sm border border-gray-700 rounded-xl p-4"
        >
          <div className="flex items-center justify-between mb-2">
            <Package className="w-8 h-8 text-blue-400" />
            <span className="text-2xl font-bold">{products.length}</span>
          </div>
          <p className="text-sm text-gray-400">Total Produk</p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="bg-dark-100/50 backdrop-blur-sm border border-gray-700 rounded-xl p-4"
        >
          <div className="flex items-center justify-between mb-2">
            <AlertTriangle className="w-8 h-8 text-yellow-400" />
            <span className="text-2xl font-bold text-yellow-400">{lowStockProducts.length}</span>
          </div>
          <p className="text-sm text-gray-400">Stok Menipis</p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-dark-100/50 backdrop-blur-sm border border-gray-700 rounded-xl p-4"
        >
          <div className="flex items-center justify-between mb-2">
            <TrendingDown className="w-8 h-8 text-red-400" />
            <span className="text-2xl font-bold text-red-400">{outOfStockProducts.length}</span>
          </div>
          <p className="text-sm text-gray-400">Stok Habis</p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="bg-dark-100/50 backdrop-blur-sm border border-gray-700 rounded-xl p-4"
        >
          <div className="flex items-center justify-between mb-2">
            <TrendingUp className="w-8 h-8 text-green-400" />
            <span className="text-2xl font-bold text-green-400">
              {formatCurrency(products.reduce((sum, p) => sum + (p.price * p.stock), 0))}
            </span>
          </div>
          <p className="text-sm text-gray-400">Nilai Stok</p>
        </motion.div>
      </div>

      {/* Stock Movement Form */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4 }}
        className="bg-dark-100/50 backdrop-blur-sm border border-gray-700 rounded-xl p-6"
      >
        <h3 className="text-lg font-semibold mb-4">Update Stok</h3>
        
        <form onSubmit={handleStockUpdate} className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">Produk</label>
              <select
                value={selectedProduct}
                onChange={(e) => setSelectedProduct(e.target.value)}
                required
                className="w-full bg-dark-200 border border-gray-600 rounded-lg px-3 py-2 focus:outline-none focus:border-neon-blue"
              >
                <option value="">Pilih Produk</option>
                {products.map(product => (
                  <option key={product.id} value={product.id}>
                    {product.name} ({product.part_number})
                  </option>
                ))}
              </select>
            </div>
            
            <div>
              <label className="block text-sm font-medium mb-2">Tipe Pergerakan</label>
              <select
                value={movementType}
                onChange={(e) => setMovementType(e.target.value as any)}
                className="w-full bg-dark-200 border border-gray-600 rounded-lg px-3 py-2 focus:outline-none focus:border-neon-blue"
              >
                <option value="in">Stok Masuk</option>
                <option value="out">Stok Keluar</option>
                <option value="adjustment">Penyesuaian</option>
              </select>
            </div>
            
            <div>
              <label className="block text-sm font-medium mb-2">
                {movementType === 'adjustment' ? 'Stok Baru' : 'Jumlah'}
              </label>
              <input
                type="number"
                value={quantity}
                onChange={(e) => setQuantity(e.target.value)}
                required
                min="0"
                className="w-full bg-dark-200 border border-gray-600 rounded-lg px-3 py-2 focus:outline-none focus:border-neon-blue"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium mb-2">Catatan</label>
              <input
                type="text"
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="Opsional"
                className="w-full bg-dark-200 border border-gray-600 rounded-lg px-3 py-2 focus:outline-none focus:border-neon-blue"
              />
            </div>
          </div>
          
          <button
            type="submit"
            className="bg-gradient-to-r from-neon-blue to-neon-green px-6 py-2 rounded-lg font-semibold hover:shadow-lg transition-all duration-300"
          >
            Update Stok
          </button>
        </form>
      </motion.div>

      {/* Low Stock Alert */}
      {lowStockProducts.length > 0 && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="bg-red-500/10 border border-red-500/30 rounded-xl p-6"
        >
          <div className="flex items-center gap-3 mb-4">
            <AlertTriangle className="w-6 h-6 text-red-400" />
            <h3 className="text-lg font-semibold text-red-400">Peringatan Stok Menipis</h3>
          </div>
          
          <div className="space-y-2 max-h-64 overflow-y-auto">
            {lowStockProducts.map((product) => (
              <div key={product.id} className="flex items-center justify-between p-3 bg-red-500/5 rounded-lg">
                <div>
                  <p className="font-medium">{product.name}</p>
                  <p className="text-sm text-gray-400">{product.part_number}</p>
                </div>
                <div className="text-right">
                  <p className="font-semibold text-red-400">
                    Sisa: {product.stock} / Min: {product.min_stock}
                  </p>
                  <p className="text-sm text-gray-400">{product.categories?.name}</p>
                </div>
              </div>
            ))}
          </div>
        </motion.div>
      )}

      {/* Stock List */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.6 }}
        className="bg-dark-100/50 backdrop-blur-sm border border-gray-700 rounded-xl overflow-hidden"
      >
        <div className="p-4 border-b border-gray-700">
          <h3 className="text-lg font-semibold">Daftar Stok Produk</h3>
        </div>
        
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-dark-200/50">
              <tr>
                <th className="text-left p-4">Produk</th>
                <th className="text-left p-4">Kategori</th>
                <th className="text-left p-4">Stok Saat Ini</th>
                <th className="text-left p-4">Stok Minimum</th>
                <th className="text-left p-4">Nilai Stok</th>
                <th className="text-left p-4">Status</th>
              </tr>
            </thead>
            <tbody>
              {products.map((product) => (
                <tr key={product.id} className="border-t border-gray-700 hover:bg-dark-200/30">
                  <td className="p-4">
                    <div>
                      <p className="font-medium">{product.name}</p>
                      <p className="text-xs text-gray-400">{product.part_number}</p>
                    </div>
                  </td>
                  <td className="p-4">{product.categories?.name}</td>
                  <td className="p-4 font-semibold">{product.stock}</td>
                  <td className="p-4">{product.min_stock}</td>
                  <td className="p-4 font-semibold text-neon-blue">
                    {formatCurrency(product.price * product.stock)}
                  </td>
                  <td className="p-4">
                    <span className={`px-2 py-1 text-xs rounded-full ${
                      product.stock === 0 
                        ? 'bg-red-500/20 text-red-400'
                        : product.stock <= product.min_stock
                        ? 'bg-yellow-500/20 text-yellow-400'
                        : 'bg-green-500/20 text-green-400'
                    }`}>
                      {product.stock === 0 
                        ? 'Habis'
                        : product.stock <= product.min_stock
                        ? 'Menipis'
                        : 'Normal'
                      }
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </motion.div>
    </div>
  );
};
