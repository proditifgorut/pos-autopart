import React, { useMemo } from 'react';
import { Home, CreditCard, Package, Settings, BarChart3, Users, Archive, Clock } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { UserRole } from '../types/database';

interface NavigationProps {
  activeTab?: string;
  onTabChange?: (tab: string) => void;
}

const allNavItems = [
  { id: 'dashboard', icon: Home, label: 'Dashboard', roles: ['store_owner', 'warehouse_admin', 'shopkeeper'] as UserRole[] },
  { id: 'pos', icon: CreditCard, label: 'Kasir', roles: ['store_owner', 'shopkeeper'] as UserRole[] },
  { id: 'products', icon: Package, label: 'Produk', roles: ['store_owner', 'shopkeeper'] as UserRole[] },
  { id: 'product-management', icon: Settings, label: 'Atur Produk', roles: ['store_owner', 'warehouse_admin'] as UserRole[] },
  { id: 'stock', icon: Archive, label: 'Stok', roles: ['store_owner', 'warehouse_admin'] as UserRole[] },
  { id: 'shift', icon: Clock, label: 'Shift', roles: ['store_owner', 'shopkeeper'] as UserRole[] },
  { id: 'customers', icon: Users, label: 'Pelanggan', roles: ['store_owner', 'shopkeeper'] as UserRole[] },
  { id: 'reports', icon: BarChart3, label: 'Laporan', roles: ['store_owner'] as UserRole[] },
];

export const Navigation: React.FC<NavigationProps> = ({ activeTab, onTabChange }) => {
  const { role } = useAuth();

  const navItems = useMemo(() => {
    if (!role) return [];
    return allNavItems.filter(item => item.roles.includes(role));
  }, [role]);

  return (
    <nav className="fixed bottom-0 left-0 right-0 bg-dark-100/80 backdrop-blur-lg border-t border-neon-blue/20 md:relative md:border-t-0 md:border-r md:bg-transparent md:backdrop-blur-none overflow-x-auto">
      <div className="flex md:flex-col min-w-max md:min-w-0">
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;
          
          return (
            <button
              key={item.id}
              onClick={() => onTabChange?.(item.id)}
              className={`flex-shrink-0 md:flex-shrink flex flex-col md:flex-row items-center justify-center md:justify-start gap-1 md:gap-3 p-3 md:p-4 transition-all duration-300 hover:bg-neon-blue/10 min-w-[80px] md:min-w-0 ${
                isActive
                  ? 'text-neon-blue bg-neon-blue/10 border-t-2 md:border-t-0 md:border-r-2 border-neon-blue'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              <Icon className="w-5 h-5 md:w-6 md:h-6" />
              <span className="text-xs md:text-sm font-medium whitespace-nowrap">{item.label}</span>
            </button>
          );
        })}
      </div>
    </nav>
  );
};
