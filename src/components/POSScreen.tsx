import React, { useState, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Search, Minus, Plus, CreditCard, Printer, X } from 'lucide-react';
import { useReactToPrint } from 'react-to-print';
import { useProducts } from '../hooks/useProducts';
import { useTransactions } from '../hooks/useTransactions';
import { useShifts } from '../hooks/useShifts';
import { Receipt } from './Receipt';
import { Product, Transaction, TransactionItem } from '../types/database';
import { useAuth } from '../contexts/AuthContext';

interface CartItem {
  product: Product;
  quantity: number;
}

export const POSScreen: React.FC = () => {
  const { products, loading: productsLoading } = useProducts();
  const { createTransaction } = useTransactions();
  const { currentShift } = useShifts();
  const { user } = useAuth();
  const receiptRef = useRef<HTMLDivElement>(null);

  const [cartItems, setCartItems] = useState<CartItem[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [showCheckout, setShowCheckout] = useState(false);
  const [showReceipt, setShowReceipt] = useState(false);
  const [lastTransaction, setLastTransaction] = useState<Transaction | null>(null);
  const [paymentMethod, setPaymentMethod] = useState<'cash' | 'card' | 'transfer' | 'qris'>('cash');
  const [paymentAmount, setPaymentAmount] = useState<string>('');
  const [customerPhone, setCustomerPhone] = useState('');

  const handlePrint = useReactToPrint({
    content: () => receiptRef.current,
  });

  const addToCart = (product: Product) => {
    if (product.stock === 0) {
      alert('Stok habis!');
      return;
    }

    setCartItems(prev => {
      const existing = prev.find(item => item.product.id === product.id);
      if (existing) {
        if (existing.quantity >= product.stock) {
          alert('Stok tidak mencukupi');
          return prev;
        }
        return prev.map(item =>
          item.product.id === product.id
            ? { ...item, quantity: item.quantity + 1 }
            : item
        );
      }
      return [...prev, { product, quantity: 1 }];
    });
  };

  const updateQuantity = (productId: string, quantity: number) => {
    if (quantity === 0) {
      setCartItems(prev => prev.filter(item => item.product.id !== productId));
      return;
    }

    setCartItems(prev =>
      prev.map(item =>
        item.product.id === productId
          ? { ...item, quantity: Math.min(quantity, item.product.stock) }
          : item
      )
    );
  };

  const clearCart = () => {
    setCartItems([]);
  };

  const handleCheckout = async () => {
    if (!currentShift) {
      alert('Silakan buka shift terlebih dahulu');
      return;
    }
    
    if (!user) {
      alert('Sesi tidak valid, silakan login ulang');
      return;
    }

    if (cartItems.length === 0) {
      alert('Keranjang kosong');
      return;
    }

    if (paymentMethod === 'cash' && (parseFloat(paymentAmount) || 0) < total) {
      alert('Jumlah pembayaran kurang dari total belanja');
      return;
    }

    try {
      const subtotal = cartItems.reduce((sum, item) => sum + (item.product.price * item.quantity), 0);
      const tax = subtotal * 0.11;
      const discount = 0;
      const totalAmount = subtotal + tax - discount;
      const paymentAmountNum = parseFloat(paymentAmount) || totalAmount;
      const change = paymentMethod === 'cash' ? Math.max(0, paymentAmountNum - totalAmount) : 0;

      const transactionData = {
        customer_id: customerPhone ? undefined : undefined, // Handle customer lookup
        subtotal,
        tax,
        discount,
        total_amount: totalAmount,
        payment_method: paymentMethod,
        payment_amount: paymentAmountNum,
        change_amount: change,
        shift_id: currentShift.id
      };

      const transactionItems: Omit<TransactionItem, 'id' | 'transaction_id'>[] = cartItems.map(item => ({
        product_id: item.product.id,
        quantity: item.quantity,
        unit_price: item.product.price,
        subtotal: item.product.price * item.quantity
      }));

      const transaction = await createTransaction(transactionData, transactionItems);
      
      const fullTransaction: Transaction = {
        ...transaction,
        transaction_items: transactionItems.map((item, index) => ({
          ...item,
          id: `item-${index}`,
          transaction_id: transaction.id,
          products: cartItems.find(ci => ci.product.id === item.product_id)?.product
        }))
      };

      setLastTransaction(fullTransaction);
      setShowCheckout(false);
      setShowReceipt(true);
      clearCart();
      setPaymentAmount('');
      setCustomerPhone('');

    } catch (error) {
      console.error('Error creating transaction:', error);
      alert('Gagal memproses transaksi');
    }
  };

  const filteredProducts = products.filter(product =>
    product.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    product.part_number.toLowerCase().includes(searchQuery.toLowerCase()) ||
    product.barcode.includes(searchQuery)
  );

  const subtotal = cartItems.reduce((sum, item) => sum + (item.product.price * item.quantity), 0);
  const tax = subtotal * 0.11;
  const discount = 0;
  const total = subtotal + tax - discount;
  const change = paymentMethod === 'cash' ? Math.max(0, (parseFloat(paymentAmount) || 0) - total) : 0;

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
    }).format(amount);
  };

  if (!currentShift) {
    return (
      <div className="p-4 text-center py-20">
        <h3 className="text-xl font-semibold text-gray-400 mb-2">Shift Belum Dibuka</h3>
        <p className="text-gray-500">Silakan buka shift terlebih dahulu untuk memulai transaksi</p>
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col lg:flex-row">
      {/* Products Section */}
      <div className="flex-1 p-4 space-y-4">
        {/* Search */}
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
          <input
            type="text"
            placeholder="Cari produk, part number, atau scan barcode..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-dark-100/50 border border-gray-700 rounded-xl pl-10 pr-4 py-3 text-white placeholder-gray-400 focus:outline-none focus:border-neon-blue transition-colors"
          />
        </div>

        {/* Products Grid */}
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-3 max-h-[calc(100vh-200px)] overflow-y-auto">
          {filteredProducts.map((product) => (
            <motion.div
              key={product.id}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              onClick={() => addToCart(product)}
              className="bg-dark-100/50 backdrop-blur-sm border border-gray-700 rounded-lg p-3 cursor-pointer hover:border-neon-blue/50 transition-all duration-300"
            >
              <div className="aspect-square bg-dark-200 rounded-lg mb-2 flex items-center justify-center overflow-hidden">
                <img
                  src={product.image_url || 'https://img-wrapper.vercel.app/image?url=https://img-wrapper.vercel.app/image?url=https://placehold.co/100x100'}
                  alt={product.name}
                  className="w-full h-full object-cover"
                  onError={(e) => {
                    (e.target as HTMLImageElement).src = 'https://img-wrapper.vercel.app/image?url=https://img-wrapper.vercel.app/image?url=https://placehold.co/100x100';
                  }}
                />
              </div>
              
              <h3 className="font-medium text-xs mb-1 line-clamp-2">{product.name}</h3>
              <p className="text-xs text-gray-400 mb-1">{product.part_number}</p>
              <div className="flex justify-between items-center">
                <span className="font-bold text-neon-blue text-sm">{formatCurrency(product.price)}</span>
                <span className={`text-xs px-1 py-0.5 rounded ${
                  product.stock > 10 ? 'bg-green-500/20 text-green-400' : 
                  product.stock > 0 ? 'bg-yellow-500/20 text-yellow-400' : 
                  'bg-red-500/20 text-red-400'
                }`}>
                  {product.stock}
                </span>
              </div>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Cart Section */}
      <div className="w-full lg:w-96 bg-dark-100/50 backdrop-blur-sm border-l border-gray-700 flex flex-col">
        {/* Cart Header */}
        <div className="p-4 border-b border-gray-700">
          <div className="flex items-center justify-between">
            <h3 className="font-semibold">Keranjang ({cartItems.length})</h3>
            {cartItems.length > 0 && (
              <button
                onClick={clearCart}
                className="text-red-400 hover:text-red-300 text-sm"
              >
                Kosongkan
              </button>
            )}
          </div>
        </div>

        {/* Cart Items */}
        <div className="flex-1 p-4 space-y-3 overflow-y-auto max-h-64">
          {cartItems.map((item) => (
            <motion.div
              key={item.product.id}
              layout
              className="bg-dark-200/50 rounded-lg p-3"
            >
              <div className="flex justify-between items-start mb-2">
                <div className="flex-1 min-w-0">
                  <h4 className="font-medium text-sm line-clamp-1">{item.product.name}</h4>
                  <p className="text-xs text-gray-400">{item.product.part_number}</p>
                </div>
                <span className="text-sm font-semibold text-neon-blue ml-2">
                  {formatCurrency(item.product.price * item.quantity)}
                </span>
              </div>
              
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => updateQuantity(item.product.id, item.quantity - 1)}
                    className="w-6 h-6 bg-dark-300 rounded flex items-center justify-center hover:bg-neon-blue/20"
                  >
                    <Minus className="w-3 h-3" />
                  </button>
                  <span className="w-8 text-center text-sm">{item.quantity}</span>
                  <button
                    onClick={() => updateQuantity(item.product.id, item.quantity + 1)}
                    disabled={item.quantity >= item.product.stock}
                    className="w-6 h-6 bg-dark-300 rounded flex items-center justify-center hover:bg-neon-blue/20 disabled:opacity-50"
                  >
                    <Plus className="w-3 h-3" />
                  </button>
                </div>
                <span className="text-xs text-gray-400">
                  {formatCurrency(item.product.price)} x {item.quantity}
                </span>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Cart Summary */}
        {cartItems.length > 0 && (
          <div className="p-4 border-t border-gray-700 space-y-3">
            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-400">Subtotal</span>
                <span>{formatCurrency(subtotal)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Pajak (PPN 11%)</span>
                <span>{formatCurrency(tax)}</span>
              </div>
              <div className="flex justify-between font-bold text-lg border-t border-gray-600 pt-2">
                <span>Total</span>
                <span className="text-neon-blue">{formatCurrency(total)}</span>
              </div>
            </div>
            
            <button
              onClick={() => setShowCheckout(true)}
              className="w-full bg-gradient-to-r from-neon-blue to-neon-green py-3 rounded-lg font-semibold hover:shadow-lg transition-all duration-300"
            >
              <div className="flex items-center justify-center gap-2">
                <CreditCard className="w-5 h-5" />
                Checkout
              </div>
            </button>
          </div>
        )}
      </div>

      {/* Checkout Modal */}
      <AnimatePresence>
        {showCheckout && (
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
              className="bg-dark-100 border border-gray-700 rounded-xl w-full max-w-md max-h-[90vh] overflow-y-auto"
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
                  className="w-full bg-gradient-to-r from-neon-blue to-neon-green py-3 rounded-lg font-semibold hover:shadow-lg transition-all duration-300"
                >
                  Proses Pembayaran
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Receipt Modal */}
      <AnimatePresence>
        {showReceipt && lastTransaction && (
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
              className="bg-white rounded-xl max-w-sm w-full max-h-[90vh] overflow-hidden"
            >
              <div className="p-4 bg-dark-100 text-white flex items-center justify-between">
                <h3 className="font-bold">Transaksi Berhasil</h3>
                <button
                  onClick={() => setShowReceipt(false)}
                  className="p-2 hover:bg-dark-200 rounded-lg"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
              
              <div className="max-h-[70vh] overflow-y-auto">
                <Receipt ref={receiptRef} transaction={lastTransaction} />
              </div>
              
              <div className="p-4 bg-dark-100 flex gap-2">
                <button
                  onClick={handlePrint}
                  className="flex-1 bg-gradient-to-r from-neon-blue to-neon-green py-2 rounded-lg font-semibold text-white flex items-center justify-center gap-2"
                >
                  <Printer className="w-4 h-4" />
                  Print
                </button>
                <button
                  onClick={() => setShowReceipt(false)}
                  className="px-6 py-2 border border-gray-600 rounded-lg hover:bg-dark-200 transition-colors text-white"
                >
                  Tutup
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};
