import React from 'react';
import { motion } from 'framer-motion';
import { TrendingUp, Package, Users, CreditCard, Calendar, Clock } from 'lucide-react';
import { mockTransactions, mockProducts } from '../data/mockData';
import { format } from 'date-fns';
import { id } from 'date-fns/locale';

export const Dashboard: React.FC = () => {
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
    }).format(amount);
  };

  const todayTransactions = mockTransactions.filter(t => 
    format(t.date, 'yyyy-MM-dd') === format(new Date(), 'yyyy-MM-dd')
  );

  const todayRevenue = todayTransactions.reduce((sum, t) => sum + t.total, 0);
  const lowStockProducts = mockProducts.filter(p => p.stock <= 5);

  const stats = [
    {
      title: 'Penjualan Hari Ini',
      value: formatCurrency(todayRevenue),
      icon: TrendingUp,
      color: 'from-green-500 to-green-600',
      change: '+12.5%'
    },
    {
      title: 'Transaksi Hari Ini',
      value: todayTransactions.length.toString(),
      icon: CreditCard,
      color: 'from-blue-500 to-blue-600',
      change: '+8.2%'
    },
    {
      title: 'Stok Menipis',
      value: lowStockProducts.length.toString(),
      icon: Package,
      color: 'from-red-500 to-red-600',
      change: '-2.1%'
    },
    {
      title: 'Total Produk',
      value: mockProducts.length.toString(),
      icon: Package,
      color: 'from-purple-500 to-purple-600',
      change: '+5.3%'
    },
  ];

  return (
    <div className="p-4 space-y-6">
      {/* Welcome Section */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-gradient-to-r from-neon-blue/20 to-neon-green/20 rounded-xl p-6 border border-neon-blue/30"
      >
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-2xl font-bold mb-2">Selamat Datang, Budi!</h2>
            <p className="text-gray-300">Siap melayani pelanggan hari ini</p>
          </div>
          <div className="text-right">
            <p className="text-sm text-gray-400">
              {format(new Date(), 'EEEE, dd MMMM yyyy', { locale: id })}
            </p>
            <p className="text-lg font-semibold text-neon-blue">
              {format(new Date(), 'HH:mm')}
            </p>
          </div>
        </div>
      </motion.div>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {stats.map((stat, index) => {
          const Icon = stat.icon;
          return (
            <motion.div
              key={stat.title}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              className="bg-dark-100/50 backdrop-blur-sm border border-gray-700 rounded-xl p-4 hover:border-neon-blue/50 transition-all duration-300"
            >
              <div className="flex items-center justify-between mb-3">
                <div className={`p-2 rounded-lg bg-gradient-to-r ${stat.color}`}>
                  <Icon className="w-5 h-5 text-white" />
                </div>
                <span className={`text-xs font-medium ${
                  stat.change.startsWith('+') ? 'text-green-400' : 'text-red-400'
                }`}>
                  {stat.change}
                </span>
              </div>
              <h3 className="text-2xl font-bold mb-1">{stat.value}</h3>
              <p className="text-sm text-gray-400">{stat.title}</p>
            </motion.div>
          );
        })}
      </div>

      {/* Recent Transactions */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4 }}
        className="bg-dark-100/50 backdrop-blur-sm border border-gray-700 rounded-xl p-6"
      >
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold">Transaksi Terbaru</h3>
          <Clock className="w-5 h-5 text-gray-400" />
        </div>
        
        <div className="space-y-3 max-h-64 overflow-y-auto">
          {todayTransactions.slice(0, 5).map((transaction) => (
            <div key={transaction.id} className="flex items-center justify-between p-3 bg-dark-200/50 rounded-lg">
              <div>
                <p className="font-medium text-sm">#{transaction.id.slice(0, 8)}</p>
                <p className="text-xs text-gray-400">
                  {transaction.customer?.name || 'Walk-in Customer'}
                </p>
                <p className="text-xs text-gray-500">
                  {format(transaction.date, 'HH:mm')}
                </p>
              </div>
              <div className="text-right">
                <p className="font-semibold text-neon-blue">{formatCurrency(transaction.total)}</p>
                <p className="text-xs text-gray-400 capitalize">{transaction.paymentMethod}</p>
              </div>
            </div>
          ))}
        </div>
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
            <Package className="w-6 h-6 text-red-400" />
            <h3 className="text-lg font-semibold text-red-400">Peringatan Stok</h3>
          </div>
          
          <div className="space-y-2">
            {lowStockProducts.slice(0, 3).map((product) => (
              <div key={product.id} className="flex items-center justify-between p-2 bg-red-500/5 rounded-lg">
                <div>
                  <p className="font-medium text-sm">{product.name}</p>
                  <p className="text-xs text-gray-400">{product.partNumber}</p>
                </div>
                <span className="text-red-400 font-semibold">Sisa: {product.stock}</span>
              </div>
            ))}
          </div>
        </motion.div>
      )}
    </div>
  );
};
