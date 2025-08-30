import React, { forwardRef } from 'react';
import { format } from 'date-fns';
import { id } from 'date-fns/locale';
import { Transaction } from '../types/database';

interface ReceiptProps {
  transaction: Transaction;
}

export const Receipt = forwardRef<HTMLDivElement, ReceiptProps>(
  ({ transaction }, ref) => {
    const formatCurrency = (amount: number) => {
      return new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR',
      }).format(amount);
    };

    return (
      <div ref={ref} className="bg-white text-black p-6 max-w-sm mx-auto font-mono text-sm">
        {/* Header */}
        <div className="text-center mb-4 border-b-2 border-dashed border-gray-300 pb-4">
          <h1 className="font-bold text-lg">AUTOPARTS POS</h1>
          <p>Sistem Kasir Onderdil Mobil</p>
          <p>Jl. Raya Otomotif No. 123</p>
          <p>Telp: (021) 1234-5678</p>
        </div>

        {/* Transaction Info */}
        <div className="mb-4 space-y-1">
          <div className="flex justify-between">
            <span>No. Transaksi:</span>
            <span className="font-bold">#{transaction.id.slice(0, 8)}</span>
          </div>
          <div className="flex justify-between">
            <span>Tanggal:</span>
            <span>{format(new Date(transaction.transaction_date), 'dd/MM/yyyy HH:mm', { locale: id })}</span>
          </div>
          <div className="flex justify-between">
            <span>Kasir:</span>
            <span>Staff</span>
          </div>
          {transaction.customers && (
            <div className="flex justify-between">
              <span>Pelanggan:</span>
              <span>{transaction.customers.name}</span>
            </div>
          )}
        </div>

        {/* Items */}
        <div className="border-t border-b border-dashed border-gray-300 py-2 mb-4">
          {transaction.transaction_items?.map((item, index) => (
            <div key={index} className="mb-2">
              <div className="font-medium">{item.products?.name}</div>
              <div className="flex justify-between text-xs">
                <span>{item.quantity} x {formatCurrency(item.unit_price)}</span>
                <span>{formatCurrency(item.subtotal)}</span>
              </div>
              <div className="text-xs text-gray-600">{item.products?.part_number}</div>
            </div>
          ))}
        </div>

        {/* Totals */}
        <div className="space-y-1 mb-4">
          <div className="flex justify-between">
            <span>Subtotal:</span>
            <span>{formatCurrency(transaction.subtotal)}</span>
          </div>
          <div className="flex justify-between">
            <span>Pajak (PPN 11%):</span>
            <span>{formatCurrency(transaction.tax)}</span>
          </div>
          {transaction.discount > 0 && (
            <div className="flex justify-between">
              <span>Diskon:</span>
              <span>-{formatCurrency(transaction.discount)}</span>
            </div>
          )}
          <div className="flex justify-between font-bold text-lg border-t border-dashed border-gray-300 pt-1">
            <span>TOTAL:</span>
            <span>{formatCurrency(transaction.total_amount)}</span>
          </div>
        </div>

        {/* Payment */}
        <div className="space-y-1 mb-4">
          <div className="flex justify-between">
            <span>Pembayaran ({transaction.payment_method.toUpperCase()}):</span>
            <span>{formatCurrency(transaction.payment_amount)}</span>
          </div>
          {transaction.change_amount > 0 && (
            <div className="flex justify-between">
              <span>Kembalian:</span>
              <span>{formatCurrency(transaction.change_amount)}</span>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="text-center text-xs border-t border-dashed border-gray-300 pt-4">
          <p>Terima kasih atas kunjungan Anda!</p>
          <p>Barang yang sudah dibeli tidak dapat dikembalikan</p>
          <p>kecuali ada perjanjian khusus</p>
          <br />
          <p>*** STRUK INI ADALAH BUKTI PEMBAYARAN YANG SAH ***</p>
        </div>
      </div>
    );
  }
);

Receipt.displayName = 'Receipt';
