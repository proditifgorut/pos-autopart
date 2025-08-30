import React, { useState, useMemo } from 'react';
import { motion } from 'framer-motion';
import { Search, Filter, Package } from 'lucide-react';
import { ProductCard } from './ProductCard';
import { Product, CartItem } from '../types';
import { mockProducts } from '../data/mockData';

interface ProductCatalogProps {
  onAddToCart: (product: Product) => void;
}

export const ProductCatalog: React.FC<ProductCatalogProps> = ({ onAddToCart }) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('');
  const [selectedBrand, setSelectedBrand] = useState('');
  const [showFilters, setShowFilters] = useState(false);

  const categories = useMemo(() => {
    return Array.from(new Set(mockProducts.map(p => p.category)));
  }, []);

  const brands = useMemo(() => {
    return Array.from(new Set(mockProducts.map(p => p.brand)));
  }, []);

  const filteredProducts = useMemo(() => {
    return mockProducts.filter(product => {
      const matchesSearch = product.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                           product.partNumber.toLowerCase().includes(searchQuery.toLowerCase()) ||
                           product.brand.toLowerCase().includes(searchQuery.toLowerCase());
      const matchesCategory = !selectedCategory || product.category === selectedCategory;
      const matchesBrand = !selectedBrand || product.brand === selectedBrand;
      
      return matchesSearch && matchesCategory && matchesBrand;
    });
  }, [searchQuery, selectedCategory, selectedBrand]);

  return (
    <div className="p-4 space-y-4">
      {/* Search Bar */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="relative"
      >
        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
        <input
          type="text"
          placeholder="Cari produk, part number, atau brand..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="w-full bg-dark-100/50 border border-gray-700 rounded-xl pl-10 pr-12 py-3 text-white placeholder-gray-400 focus:outline-none focus:border-neon-blue transition-colors"
        />
        <button
          onClick={() => setShowFilters(!showFilters)}
          className={`absolute right-3 top-1/2 transform -translate-y-1/2 p-1 rounded-lg transition-colors ${
            showFilters ? 'text-neon-blue bg-neon-blue/20' : 'text-gray-400 hover:text-white'
          }`}
        >
          <Filter className="w-5 h-5" />
        </button>
      </motion.div>

      {/* Filters */}
      {showFilters && (
        <motion.div
          initial={{ opacity: 0, height: 0 }}
          animate={{ opacity: 1, height: 'auto' }}
          exit={{ opacity: 0, height: 0 }}
          className="bg-dark-100/50 backdrop-blur-sm border border-gray-700 rounded-xl p-4 space-y-4"
        >
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">Kategori</label>
              <select
                value={selectedCategory}
                onChange={(e) => setSelectedCategory(e.target.value)}
                className="w-full bg-dark-200 border border-gray-600 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-neon-blue"
              >
                <option value="">Semua Kategori</option>
                {categories.map(category => (
                  <option key={category} value={category}>{category}</option>
                ))}
              </select>
            </div>
            
            <div>
              <label className="block text-sm font-medium mb-2">Brand</label>
              <select
                value={selectedBrand}
                onChange={(e) => setSelectedBrand(e.target.value)}
                className="w-full bg-dark-200 border border-gray-600 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-neon-blue"
              >
                <option value="">Semua Brand</option>
                {brands.map(brand => (
                  <option key={brand} value={brand}>{brand}</option>
                ))}
              </select>
            </div>
          </div>
          
          <button
            onClick={() => {
              setSelectedCategory('');
              setSelectedBrand('');
              setSearchQuery('');
            }}
            className="text-sm text-neon-blue hover:text-neon-green transition-colors"
          >
            Reset Filter
          </button>
        </motion.div>
      )}

      {/* Product Count */}
      <div className="flex items-center gap-2 text-sm text-gray-400">
        <Package className="w-4 h-4" />
        <span>Menampilkan {filteredProducts.length} produk</span>
      </div>

      {/* Products Grid */}
      <motion.div 
        layout
        className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4"
      >
        {filteredProducts.map((product, index) => (
          <motion.div
            key={product.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.05 }}
          >
            <ProductCard 
              product={product} 
              onAddToCart={onAddToCart}
            />
          </motion.div>
        ))}
      </motion.div>

      {filteredProducts.length === 0 && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="text-center py-12"
        >
          <Package className="w-16 h-16 text-gray-500 mx-auto mb-4" />
          <h3 className="text-lg font-semibold text-gray-400 mb-2">Produk tidak ditemukan</h3>
          <p className="text-gray-500">Coba ubah kata kunci pencarian atau filter</p>
        </motion.div>
      )}
    </div>
  );
};
