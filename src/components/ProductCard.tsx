import React from 'react';
import { Plus, Package } from 'lucide-react';
import { motion } from 'framer-motion';
import { Product } from '../types';

interface ProductCardProps {
  product: Product;
  onAddToCart: (product: Product) => void;
}

export const ProductCard: React.FC<ProductCardProps> = ({ product, onAddToCart }) => {
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
    }).format(amount);
  };

  return (
    <motion.div
      whileHover={{ scale: 1.02 }}
      whileTap={{ scale: 0.98 }}
      className="bg-dark-100/50 backdrop-blur-sm border border-gray-700 rounded-xl p-4 hover:border-neon-blue/50 transition-all duration-300 group"
    >
      <div className="relative mb-3">
        <img
          src={product.image}
          alt={product.name}
          className="w-full h-32 object-cover rounded-lg bg-dark-200"
          onError={(e) => {
            const target = e.target as HTMLImageElement;
            target.style.display = 'none';
            target.nextElementSibling?.classList.remove('hidden');
          }}
        />
        <div className="hidden w-full h-32 bg-dark-200 rounded-lg flex items-center justify-center">
          <Package className="w-8 h-8 text-gray-500" />
        </div>
        
        <div className="absolute top-2 right-2">
          <span className={`px-2 py-1 text-xs rounded-full ${
            product.stock > 10 ? 'bg-green-500/20 text-green-400' : 
            product.stock > 0 ? 'bg-yellow-500/20 text-yellow-400' : 
            'bg-red-500/20 text-red-400'
          }`}>
            Stock: {product.stock}
          </span>
        </div>
      </div>
      
      <div className="space-y-2">
        <h3 className="font-semibold text-sm line-clamp-2 group-hover:text-neon-blue transition-colors">
          {product.name}
        </h3>
        
        <div className="flex items-center justify-between text-xs text-gray-400">
          <span>{product.brand}</span>
          <span>{product.partNumber}</span>
        </div>
        
        <div className="flex items-center gap-1 text-xs text-gray-400">
          <span className="bg-dark-200 px-2 py-1 rounded">{product.category}</span>
        </div>
        
        <div className="flex items-center justify-between">
          <div className="text-sm">
            <span className="font-bold text-neon-blue">{formatCurrency(product.price)}</span>
          </div>
          
          <motion.button
            whileHover={{ scale: 1.1 }}
            whileTap={{ scale: 0.9 }}
            onClick={() => onAddToCart(product)}
            disabled={product.stock === 0}
            className="bg-gradient-to-r from-neon-blue to-neon-green p-2 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed hover:shadow-lg hover:shadow-neon-blue/25 transition-all duration-300"
          >
            <Plus className="w-4 h-4 text-white" />
          </motion.button>
        </div>
      </div>
    </motion.div>
  );
};
