import React from 'react';
import { Bell, Search, User, ShoppingCart, LogOut } from 'lucide-react';
import { motion } from 'framer-motion';
import { useAuth } from '../contexts/AuthContext';

interface HeaderProps {
  title: string;
  cartItemCount?: number;
  onSearchChange?: (query: string) => void;
  onCartClick?: () => void;
}

export const Header: React.FC<HeaderProps> = ({ 
  title, 
  cartItemCount = 0, 
  onSearchChange,
  onCartClick 
}) => {
  const { profile, signOut } = useAuth();

  return (
    <motion.header 
      initial={{ y: -100, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      className="bg-dark-100/80 backdrop-blur-lg border-b border-neon-blue/20 sticky top-0 z-30"
    >
      <div className="flex items-center justify-between p-4">
        <div className="flex items-center gap-4">
          <h1 className="text-xl md:text-2xl font-bold bg-gradient-to-r from-neon-blue to-neon-green bg-clip-text text-transparent">
            {title}
          </h1>
        </div>
        
        <div className="flex items-center gap-3">
          {onSearchChange && (
            <div className="hidden md:flex relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
              <input
                type="text"
                placeholder="Cari produk..."
                onChange={(e) => onSearchChange(e.target.value)}
                className="bg-dark-200 border border-gray-600 rounded-lg pl-10 pr-4 py-2 text-sm focus:outline-none focus:border-neon-blue transition-colors"
              />
            </div>
          )}
          
          <button className="relative p-2 hover:bg-dark-200 rounded-lg transition-colors">
            <Bell className="w-5 h-5 text-gray-400" />
            <span className="absolute -top-1 -right-1 w-3 h-3 bg-neon-pink rounded-full"></span>
          </button>
          
          {onCartClick && (
            <button 
              onClick={onCartClick}
              className="relative p-2 hover:bg-dark-200 rounded-lg transition-colors"
            >
              <ShoppingCart className="w-5 h-5 text-gray-400" />
              {cartItemCount > 0 && (
                <span className="absolute -top-1 -right-1 bg-neon-blue text-xs rounded-full w-5 h-5 flex items-center justify-center font-medium">
                  {cartItemCount}
                </span>
              )}
            </button>
          )}
          
          <div className="group relative">
            <button className="flex items-center gap-2 p-2 hover:bg-dark-200 rounded-lg transition-colors">
              <div className="w-8 h-8 bg-gradient-to-r from-neon-blue to-neon-green rounded-full flex items-center justify-center">
                {profile?.avatar_url ? (
                  <img src={profile.avatar_url} alt={profile.full_name} className="w-full h-full rounded-full object-cover" />
                ) : (
                  <User className="w-4 h-4 text-white" />
                )}
              </div>
            </button>
            <div className="absolute top-full right-0 mt-2 w-48 bg-dark-100 border border-gray-700 rounded-lg shadow-lg opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none group-hover:pointer-events-auto">
              <div className="p-2">
                <div className="px-2 py-1">
                  <p className="font-semibold text-sm">{profile?.full_name}</p>
                  <p className="text-xs text-gray-400">{profile?.role}</p>
                </div>
                <div className="h-px bg-gray-700 my-1"></div>
                <button
                  onClick={signOut}
                  className="w-full text-left flex items-center gap-2 px-2 py-1 text-sm text-red-400 hover:bg-red-500/20 rounded"
                >
                  <LogOut className="w-4 h-4" />
                  Logout
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </motion.header>
  );
};
