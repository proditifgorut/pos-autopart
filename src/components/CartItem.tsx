import React from 'react';
import { Minus, Plus, Trash2 } from 'lucide-react';
import { motion } from 'framer-motion';
import { CartItem as CartItemType } from '../types';

interface CartItemProps {
  item: CartItemType;
  onUpdateQuantity: (productId: string, quantity: number) => void;
  onRemove: (productId: string) => void;
}

export const CartItem: React.FC<CartItemProps> = ({ item, onUpdateQuantity, onRemove }) => {
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
    }).format(amount);
  };

  const subtotal = item.product.price * item.quantity;

  return (
    <motion.div
      layout
      initial={{ opacity: 0, x: -20 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: 20 }}
      className="bg-dark-100/50 backdrop-blur-sm border border-gray-700 rounded-lg p-4 hover:border-neon-blue/50 transition-all duration-300"
    >
      <div className="flex gap-3">
        <img
          src={item.product.image}
          alt={item.product.name}
          className="w-16 h-16 object-cover rounded-lg bg-dark-200"
        />
        
        <div className="flex-1 min-w-0">
          <h3 className="font-medium text-sm line-clamp-2 mb-1">{item.product.name}</h3>
          <p className="text-xs text-gray-400 mb-2">{item.product.brand} • {item.product.partNumber}</p>
          
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <motion.button
                whileTap={{ scale: 0.9 }}
                onClick={() => onUpdateQuantity(item.product.id, Math.max(0, item.quantity - 1))}
                className="w-8 h-8 bg-dark-200 rounded-lg flex items-center justify-center hover:bg-neon-blue/20 transition-colors"
              >
                <Minus className="w-4 h-4" />
              </motion.button>
              
              <span className="w-8 text-center font-medium">{item.quantity}</span>
              
              <motion.button
                whileTap={{ scale: 0.9 }}
                onClick={() => onUpdateQuantity(item.product.id, item.quantity + 1)}
                disabled={item.quantity >= item.product.stock}
                className="w-8 h-8 bg-dark-200 rounded-lg flex items-center justify-center hover:bg-neon-blue/20 transition-colors disabled:opacity-50"
              >
                <Plus className="w-4 h-4" />
              </motion.button>
            </div>
            
            <motion.button
              whileTap={{ scale: 0.9 }}
              onClick={() => onRemove(item.product.id)}
              className="p-2 text-red-400 hover:bg-red-500/20 rounded-lg transition-colors"
            >
              <Trash2 className="w-4 h-4" />
            </motion.button>
          </div>
          
          <div className="flex justify-between items-center mt-2 pt-2 border-t border-gray-700">
            <span className="text-xs text-gray-400">{formatCurrency(item.product.price)} x {item.quantity}</span>
            <span className="font-bold text-neon-blue">{formatCurrency(subtotal)}</span>
          </div>
        </div>
      </div>
    </motion.div>
  );
};
