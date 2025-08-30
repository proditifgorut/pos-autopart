import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, Search, Edit, Trash2, Package, AlertTriangle } from 'lucide-react';
import { useProducts } from '../hooks/useProducts';
import { Product } from '../types/database';

export const ProductManagement: React.FC = () => {
  const { products, categories, brands, loading, addProduct, updateProduct, deleteProduct } = useProducts();
  const [showAddForm, setShowAddForm] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('');

  const [formData, setFormData] = useState({
    name: '',
    description: '',
    price: '',
    stock: '',
    min_stock: '',
    category_id: '',
    brand_id: '',
    part_number: '',
    barcode: '',
    image_url: '',
    weight: '',
    dimensions: ''
  });

  const resetForm = () => {
    setFormData({
      name: '',
      description: '',
      price: '',
      stock: '',
      min_stock: '',
      category_id: '',
      brand_id: '',
      part_number: '',
      barcode: '',
      image_url: '',
      weight: '',
      dimensions: ''
    });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const productData = {
        ...formData,
        price: parseFloat(formData.price),
        stock: parseInt(formData.stock),
        min_stock: parseInt(formData.min_stock),
        weight: parseFloat(formData.weight),
        is_active: true
      };

      if (editingProduct) {
        await updateProduct(editingProduct.id, productData);
      } else {
        await addProduct(productData);
      }

      resetForm();
      setShowAddForm(false);
      setEditingProduct(null);
    } catch (error) {
      console.error('Error saving product:', error);
    }
  };

  const handleEdit = (product: Product) => {
    setFormData({
      name: product.name,
      description: product.description,
      price: product.price.toString(),
      stock: product.stock.toString(),
      min_stock: product.min_stock.toString(),
      category_id: product.category_id,
      brand_id: product.brand_id,
      part_number: product.part_number,
      barcode: product.barcode,
      image_url: product.image_url,
      weight: product.weight.toString(),
      dimensions: product.dimensions
    });
    setEditingProduct(product);
    setShowAddForm(true);
  };

  const handleDelete = async (product: Product) => {
    if (window.confirm(`Hapus produk ${product.name}?`)) {
      await deleteProduct(product.id);
    }
  };

  const filteredProducts = products.filter(product => {
    const matchesSearch = product.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         product.part_number.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCategory = !selectedCategory || product.category_id === selectedCategory;
    return matchesSearch && matchesCategory;
  });

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
    <div className="p-4 space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold">Manajemen Produk</h2>
        <motion.button
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
          onClick={() => setShowAddForm(true)}
          className="bg-gradient-to-r from-neon-blue to-neon-green px-4 py-2 rounded-lg font-semibold flex items-center gap-2"
        >
          <Plus className="w-5 h-5" />
          Tambah Produk
        </motion.button>
      </div>

      {/* Search and Filter */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
          <input
            type="text"
            placeholder="Cari produk atau part number..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-dark-100/50 border border-gray-700 rounded-lg pl-10 pr-4 py-2 focus:outline-none focus:border-neon-blue"
          />
        </div>
        
        <select
          value={selectedCategory}
          onChange={(e) => setSelectedCategory(e.target.value)}
          className="bg-dark-100/50 border border-gray-700 rounded-lg px-4 py-2 focus:outline-none focus:border-neon-blue"
        >
          <option value="">Semua Kategori</option>
          {categories.map(category => (
            <option key={category.id} value={category.id}>{category.name}</option>
          ))}
        </select>
      </div>

      {/* Products Table */}
      <div className="bg-dark-100/50 backdrop-blur-sm border border-gray-700 rounded-xl overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-dark-200/50">
              <tr>
                <th className="text-left p-4">Produk</th>
                <th className="text-left p-4">Part Number</th>
                <th className="text-left p-4">Kategori</th>
                <th className="text-left p-4">Harga</th>
                <th className="text-left p-4">Stok</th>
                <th className="text-left p-4">Aksi</th>
              </tr>
            </thead>
            <tbody>
              {filteredProducts.map((product) => (
                <tr key={product.id} className="border-t border-gray-700 hover:bg-dark-200/30">
                  <td className="p-4">
                    <div className="flex items-center gap-3">
                      <img
                        src={product.image_url || 'https://img-wrapper.vercel.app/image?url=https://placehold.co/40x40'}
                        alt={product.name}
                        className="w-10 h-10 rounded-lg object-cover bg-dark-200"
                      />
                      <div>
                        <p className="font-medium">{product.name}</p>
                        <p className="text-xs text-gray-400">{product.brands?.name}</p>
                      </div>
                    </div>
                  </td>
                  <td className="p-4 font-mono text-sm">{product.part_number}</td>
                  <td className="p-4">{product.categories?.name}</td>
                  <td className="p-4 font-semibold text-neon-blue">{formatCurrency(product.price)}</td>
                  <td className="p-4">
                    <div className="flex items-center gap-2">
                      <span className={`font-semibold ${
                        product.stock <= product.min_stock ? 'text-red-400' : 'text-green-400'
                      }`}>
                        {product.stock}
                      </span>
                      {product.stock <= product.min_stock && (
                        <AlertTriangle className="w-4 h-4 text-red-400" />
                      )}
                    </div>
                  </td>
                  <td className="p-4">
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => handleEdit(product)}
                        className="p-2 text-blue-400 hover:bg-blue-500/20 rounded-lg transition-colors"
                      >
                        <Edit className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => handleDelete(product)}
                        className="p-2 text-red-400 hover:bg-red-500/20 rounded-lg transition-colors"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Add/Edit Product Modal */}
      <AnimatePresence>
        {showAddForm && (
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
              className="bg-dark-100 border border-gray-700 rounded-xl w-full max-w-2xl max-h-[90vh] overflow-y-auto"
            >
              <div className="p-6">
                <h3 className="text-xl font-bold mb-4">
                  {editingProduct ? 'Edit Produk' : 'Tambah Produk Baru'}
                </h3>
                
                <form onSubmit={handleSubmit} className="space-y-4">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium mb-2">Nama Produk</label>
                      <input
                        type="text"
                        required
                        value={formData.name}
                        onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                        className="w-full bg-dark-200 border border-gray-600 rounded-lg px-3 py-2 focus:outline-none focus:border-neon-blue"
                      />
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium mb-2">Part Number</label>
                      <input
                        type="text"
                        required
                        value={formData.part_number}
                        onChange={(e) => setFormData({ ...formData, part_number: e.target.value })}
                        className="w-full bg-dark-200 border border-gray-600 rounded-lg px-3 py-2 focus:outline-none focus:border-neon-blue"
                      />
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium mb-2">Kategori</label>
                      <select
                        required
                        value={formData.category_id}
                        onChange={(e) => setFormData({ ...formData, category_id: e.target.value })}
                        className="w-full bg-dark-200 border border-gray-600 rounded-lg px-3 py-2 focus:outline-none focus:border-neon-blue"
                      >
                        <option value="">Pilih Kategori</option>
                        {categories.map(category => (
                          <option key={category.id} value={category.id}>{category.name}</option>
                        ))}
                      </select>
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium mb-2">Brand</label>
                      <select
                        required
                        value={formData.brand_id}
                        onChange={(e) => setFormData({ ...formData, brand_id: e.target.value })}
                        className="w-full bg-dark-200 border border-gray-600 rounded-lg px-3 py-2 focus:outline-none focus:border-neon-blue"
                      >
                        <option value="">Pilih Brand</option>
                        {brands.map(brand => (
                          <option key={brand.id} value={brand.id}>{brand.name}</option>
                        ))}
                      </select>
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium mb-2">Harga</label>
                      <input
                        type="number"
                        required
                        min="0"
                        step="1000"
                        value={formData.price}
                        onChange={(e) => setFormData({ ...formData, price: e.target.value })}
                        className="w-full bg-dark-200 border border-gray-600 rounded-lg px-3 py-2 focus:outline-none focus:border-neon-blue"
                      />
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium mb-2">Stok</label>
                      <input
                        type="number"
                        required
                        min="0"
                        value={formData.stock}
                        onChange={(e) => setFormData({ ...formData, stock: e.target.value })}
                        className="w-full bg-dark-200 border border-gray-600 rounded-lg px-3 py-2 focus:outline-none focus:border-neon-blue"
                      />
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium mb-2">Minimum Stok</label>
                      <input
                        type="number"
                        required
                        min="0"
                        value={formData.min_stock}
                        onChange={(e) => setFormData({ ...formData, min_stock: e.target.value })}
                        className="w-full bg-dark-200 border border-gray-600 rounded-lg px-3 py-2 focus:outline-none focus:border-neon-blue"
                      />
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium mb-2">Barcode</label>
                      <input
                        type="text"
                        value={formData.barcode}
                        onChange={(e) => setFormData({ ...formData, barcode: e.target.value })}
                        className="w-full bg-dark-200 border border-gray-600 rounded-lg px-3 py-2 focus:outline-none focus:border-neon-blue"
                      />
                    </div>
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium mb-2">Deskripsi</label>
                    <textarea
                      value={formData.description}
                      onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                      rows={3}
                      className="w-full bg-dark-200 border border-gray-600 rounded-lg px-3 py-2 focus:outline-none focus:border-neon-blue"
                    />
                  </div>
                  
                  <div className="flex gap-3 pt-4">
                    <button
                      type="submit"
                      className="flex-1 bg-gradient-to-r from-neon-blue to-neon-green py-2 rounded-lg font-semibold hover:shadow-lg transition-all duration-300"
                    >
                      {editingProduct ? 'Update Produk' : 'Tambah Produk'}
                    </button>
                    <button
                      type="button"
                      onClick={() => {
                        setShowAddForm(false);
                        setEditingProduct(null);
                        resetForm();
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
