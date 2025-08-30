import React, { useState } from 'react';
import { supabase } from '../lib/supabase';
import { motion } from 'framer-motion';
import { LogIn } from 'lucide-react';

export const LoginPage: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-dark-50 via-dark-100 to-dark-200 p-4">
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="w-full max-w-md bg-dark-100/50 backdrop-blur-lg border border-neon-blue/20 rounded-xl p-8 shadow-2xl shadow-neon-blue/10"
      >
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold bg-gradient-to-r from-neon-blue to-neon-green bg-clip-text text-transparent">
            AutoParts POS
          </h1>
          <p className="text-gray-400 mt-2">Silakan login untuk melanjutkan</p>
        </div>

        <form onSubmit={handleLogin} className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              className="w-full bg-dark-200 border border-gray-600 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-neon-blue transition-colors"
              placeholder="anda@email.com"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="w-full bg-dark-200 border border-gray-600 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-neon-blue"
              placeholder="••••••••"
            />
          </div>
          
          {error && <p className="text-red-400 text-sm">{error}</p>}

          <div>
            <motion.button
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              type="submit"
              disabled={loading}
              className="w-full bg-gradient-to-r from-neon-blue to-neon-green py-3 rounded-lg font-semibold text-white hover:shadow-lg hover:shadow-neon-blue/25 transition-all duration-300 disabled:opacity-50"
            >
              {loading ? (
                <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mx-auto"></div>
              ) : (
                <div className="flex items-center justify-center gap-2">
                  <LogIn className="w-5 h-5" />
                  Login
                </div>
              )}
            </motion.button>
          </div>
        </form>
      </motion.div>
    </div>
  );
};
