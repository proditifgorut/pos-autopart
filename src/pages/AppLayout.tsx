import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Navigation } from '../components/Navigation';
import { Header } from '../components/Header';
import { Dashboard } from '../components/Dashboard';
import { ProductCatalog } from '../components/ProductCatalog';
import { ProductManagement } from '../components/ProductManagement';
import { StockManagement } from '../components/StockManagement';
import { POSScreen } from '../components/POSScreen';
import { ShiftManagement } from '../components/ShiftManagement';
import { useAuth } from '../contexts/AuthContext';

export const AppLayout: React.FC = () => {
  const { role } = useAuth();
  const [activeTab, setActiveTab] = useState('dashboard');

  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard':
        return <Dashboard />;
      case 'pos':
        return <POSScreen />;
      case 'products':
        return <ProductCatalog onAddToCart={() => {}} />;
      case 'product-management':
        return <ProductManagement />;
      case 'stock':
        return <StockManagement />;
      case 'shift':
        return <ShiftManagement />;
      case 'customers':
        return (
          <div className="p-4 text-center py-20">
            <h3 className="text-xl font-semibold text-gray-400 mb-2">Manajemen Pelanggan</h3>
            <p className="text-gray-500">Fitur ini akan segera hadir</p>
          </div>
        );
      case 'reports':
        return (
          <div className="p-4 text-center py-20">
            <h3 className="text-xl font-semibold text-gray-400 mb-2">Laporan Penjualan</h3>
            <p className="text-gray-500">Fitur ini akan segera hadir</p>
          </div>
        );
      case 'settings':
        return (
          <div className="p-4 text-center py-20">
            <h3 className="text-xl font-semibold text-gray-400 mb-2">Pengaturan</h3>
            <p className="text-gray-500">Fitur ini akan segera hadir</p>
          </div>
        );
      default:
        return <Dashboard />;
    }
  };

  const getPageTitle = () => {
    switch (activeTab) {
      case 'dashboard':
        return 'AutoParts POS';
      case 'pos':
        return 'Kasir';
      case 'products':
        return 'Katalog Produk';
      case 'product-management':
        return 'Manajemen Produk';
      case 'stock':
        return 'Manajemen Stok';
      case 'shift':
        return 'Manajemen Shift';
      case 'customers':
        return 'Pelanggan';
      case 'reports':
        return 'Laporan';
      case 'settings':
        return 'Pengaturan';
      default:
        return 'AutoParts POS';
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-dark-50 via-dark-100 to-dark-200 text-white">
      {/* Desktop Sidebar */}
      <div className="hidden md:block fixed left-0 top-0 bottom-0 w-64 z-40">
        <div className="h-full bg-dark-100/80 backdrop-blur-lg border-r border-neon-blue/20">
          <div className="p-6 border-b border-neon-blue/20">
            <h1 className="text-2xl font-bold bg-gradient-to-r from-neon-blue to-neon-green bg-clip-text text-transparent">
              AutoParts POS
            </h1>
            <p className="text-sm text-gray-400 mt-1">Sistem Kasir Onderdil</p>
          </div>
          <Navigation activeTab={activeTab} onTabChange={setActiveTab} />
        </div>
      </div>

      {/* Main Content */}
      <div className="md:ml-64 min-h-screen">
        <Header 
          title={getPageTitle()}
          cartItemCount={0}
          onCartClick={() => setActiveTab('pos')}
        />
        
        <main className="pb-20 md:pb-0">
          <AnimatePresence mode="wait">
            <motion.div
              key={activeTab}
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              transition={{ duration: 0.2 }}
            >
              {renderContent()}
            </motion.div>
          </AnimatePresence>
        </main>
      </div>

      {/* Mobile Navigation */}
      <div className="md:hidden fixed bottom-0 left-0 right-0 z-50">
        <Navigation activeTab={activeTab} onTabChange={setActiveTab} />
      </div>
    </div>
  );
}
