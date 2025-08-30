import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ShoppingCart, CreditCard, X, Plus, Minus, Trash2 } from 'lucide-react';
import { CartItem } from './CartItem';
import { CartItem as CartItemType, Customer } from '../types';

interface CartProps {
  cartItems: CartItemType[];
  onUpdateQuantity: (productId: string, quantity: number) => void;
  onRemoveItem: (productId: string) => void;
  onClearCart: () => void;
  onCheckout: (paymentMethod: string, paymentAmount: number, customer?: Customer) => void;
}

export const Cart: React.FC<CartProps> = ({
  cartItems,
  onUpdateQuantity,
  onRemoveItem,
  onClearCart,
  onCheckout
}) => {
  const [showCheckout, setShowCheckout] = useState(false);
  const [paymentMethod, setPaymentMethod] = useState<'cash' | 'card' | 'transfer' | 'qris'>('cash');
  const [paymentAmount, setPaymentAmount] = useState<string>('');
  const [customerPhone, setCustomerPhone] = useState('');

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
    }).format(amount);
  };

  const subtotal = cartItems.reduce((sum, item) => sum + (item.product.price * item.quantity), 0);
  const tax = subtotal * 0.11; // PPN 11%
  const discount = 0; // Could be dynamic
  const total = subtotal + tax - discount;

  const change = paymentMethod === 'cash' ? Math.max(0, (parseFloat(paymentAmount) || 0) - total) : 0;

  const handleCheckout = () => {
    if (paymentMethod === 'cash' && (parseFloat(paymentAmount) || 0) < total) {
      alert('Jumlah pembayaran kurang dari total belanja');
      return;
    }

    onCheckout(paymentMethod, parseFloat(paymentAmount) || total);
    setShowCheckout(false);
    setPaymentAmount('');
    setCustomerPhone('');
  };

  if (cartItems.length === 0) {
    return (
      <div className="p-4">
        <div className="flex flex-col items-center justify-center py-20 text-center">
          <ShoppingCart className="w-20 h-20 text-gray-500 mb-4" />
          <h3 className="text-xl font-semibold text-gray-400 mb-2">Keranjang Kosong</h3>
          <p className="text-gray-500">Silakan tambahkan produk ke keranjang</p>
        </div>
      </div>
    );
  }

  return (
    <div className="p-4 space-y-4">
      {/* Cart Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-bold">Keranjang ({cartItems.length})</h2>
        <button
          onClick={onClearCart}
          className="text-red-400 hover:text-red-300 text-sm flex items-center gap-1"
        >
          <Trash2 className="w-4 h-4" />
          Kosongkan
        </button>
      </div>

      {/* Cart Items */}
      <div className="space-y-3 max-h-96 overflow-y-auto">
        <AnimatePresence>
          {cartItems.map((item) => (
            <CartItem
              key={item.product.id}
              item={item}
              onUpdateQuantity={onUpdateQuantity}
              onRemove={onRemoveItem}
            />
          ))}
        </AnimatePresence>
      </div>

      {/* Cart Summary */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-dark-100/50 backdrop-blur-sm border border-gray-700 rounded-xl p-4 space-y-3"
      >
        <div className="flex justify-between text-sm">
          <span className="text-gray-400">Subtotal</span>
          <span>{formatCurrency(subtotal)}</span>
        </div>
        
        <div className="flex justify-between text-sm">
          <span className="text-gray-400">Pajak (PPN 11%)</span>
          <span>{formatCurrency(tax)}</span>
        </div>
        
        {discount > 0 && (
          <div className="flex justify-between text-sm">
            <span className="text-gray-400">Diskon</span>
            <span className="text-green-400">-{formatCurrency(discount)}</span>
          </div>
        )}
        
        <div className="border-t border-gray-600 pt-3">
          <div className="flex justify-between text-lg font-bold">
            <span>Total</span>
            <span className="text-neon-blue">{formatCurrency(total)}</span>
          </div>
        </div>
      </motion.div>

      {/* Checkout Button */}
      <motion.button
        whileHover={{ scale: 1.02 }}
        whileTap={{ scale: 0.98 }}
        onClick={() => setShowCheckout(true)}
        className="w-full bg-gradient-to-r from-neon-blue to-neon-green py-4 rounded-xl font-semibold text-white hover:shadow-lg hover:shadow-neon-blue/25 transition-all duration-300"
      >
        <div className="flex items-center justify-center gap-2">
          <CreditCard className="w-5 h-5" />
          Checkout - {formatCurrency(total)}
        </div>
      </motion.button>

      {/* Checkout Modal */}
      <AnimatePresence>
        {showCheckout && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-end md:items-center justify-center p-4"
          >
            <motion.div
              initial={{ y: 100, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              exit={{ y: 100, opacity: 0 }}
              className="bg-dark-100 border border-gray-700 rounded-t-xl md:rounded-xl w-full max-w-md max-h-[80vh] overflow-y-auto"
            >
              <div className="p-6 space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="text-xl font-bold">Checkout</h3>
                  <button
                    onClick={() => setShowCheckout(false)}
                    className="p-2 hover:bg-dark-200 rounded-lg"
                  >
                    <X className="w-5 h-5" />
                  </button>
                </div>

                {/* Customer Info */}
                <div>
                  <label className="block text-sm font-medium mb-2">No. Telepon Pelanggan (Opsional)</label>
                  <input
                    type="tel"
                    value={customerPhone}
                    onChange={(e) => setCustomerPhone(e.target.value)}
                    placeholder="08xx-xxxx-xxxx"
                    className="w-full bg-dark-200 border border-gray-600 rounded-lg px-3 py-2 focus:outline-none focus:border-neon-blue"
                  />
                </div>

                {/* Payment Method */}
                <div>
                  <label className="block text-sm font-medium mb-2">Metode Pembayaran</label>
                  <div className="grid grid-cols-2 gap-2">
                    {[
                      { value: 'cash', label: 'Tunai' },
                      { value: 'card', label: 'Kartu' },
                      { value: 'transfer', label: 'Transfer' },
                      { value: 'qris', label: 'QRIS' }
                    ].map((method) => (
                      <button
                        key={method.value}
                        onClick={() => setPaymentMethod(method.value as any)}
                        className={`p-3 rounded-lg border transition-colors ${
                          paymentMethod === method.value
                            ? 'border-neon-blue bg-neon-blue/20 text-neon-blue'
                            : 'border-gray-600 hover:border-gray-500'
                        }`}
                      >
                        {method.label}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Payment Amount (for cash) */}
                {paymentMethod === 'cash' && (
                  <div>
                    <label className="block text-sm font-medium mb-2">Jumlah Pembayaran</label>
                    <input
                      type="number"
                      value={paymentAmount}
                      onChange={(e) => setPaymentAmount(e.target.value)}
                      placeholder={total.toString()}
                      className="w-full bg-dark-200 border border-gray-600 rounded-lg px-3 py-2 focus:outline-none focus:border-neon-blue"
                    />
                    {change > 0 && (
                      <p className="text-sm text-green-400 mt-1">
                        Kembalian: {formatCurrency(change)}
                      </p>
                    )}
                  </div>
                )}

                {/* Total Summary */}
                <div className="bg-dark-200/50 rounded-lg p-4 space-y-2">
                  <div className="flex justify-between">
                    <span className="text-gray-400">Total</span>
                    <span className="font-bold text-neon-blue">{formatCurrency(total)}</span>
                  </div>
                </div>

                {/* Checkout Action */}
                <button
                  onClick={handleCheckout}
                  className="w-full bg-gradient-to-r from-neon-blue to-neon-green py-3 rounded-lg font-semibold text-white hover:shadow-lg transition-all duration-300"
                >
                  Proses Pembayaran
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};
