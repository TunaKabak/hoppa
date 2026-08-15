import React, { useState, useEffect, useRef } from 'react';
import Head from 'next/head';
import MerchantLayout from '../../../components/merchant/MerchantLayout';
import GuidedOnboardingWidget from '../../../components/merchant/GuidedOnboardingWidget';
import { 
  ShoppingBag, Clock, CheckCircle2, XCircle, Bike, AlertTriangle, 
  Printer, Volume2, VolumeX, ChevronRight, X, RefreshCw 
} from 'lucide-react';
import { merchantApiFetch } from '../../../utils/merchant-auth';
import { useMerchantTheme } from '../../../context/MerchantThemeContext';

export default function MerchantOrdersPage() {
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  const [orders, setOrders] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [audioEnabled, setAudioEnabled] = useState(true);
  const [selectedOrderForReceipt, setSelectedOrderForReceipt] = useState<any | null>(null);
  const [cancelModalOrder, setCancelModalOrder] = useState<any | null>(null);
  const [cancelReason, setCancelReason] = useState('Stok yetersizliği');

  const prevPendingCount = useRef(0);

  useEffect(() => {
    fetchOrders();
    const interval = setInterval(fetchOrders, 10000); // 10s auto-refresh
    return () => clearInterval(interval);
  }, []);

  const fetchOrders = async () => {
    try {
      const res = await merchantApiFetch('/merchant/orders');
      if (res.data) {
        setOrders(res.data);

        // Check for new pending orders to trigger audio chime
        const pendingCount = res.data.filter((o: any) => o.status === 'PENDING').length;
        if (pendingCount > prevPendingCount.current && audioEnabled) {
          playChime();
        }
        prevPendingCount.current = pendingCount;
      }
    } catch (err) {
      console.error('Siparişler alınamadı:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const playChime = () => {
    try {
      const ctx = new (window.AudioContext || (window as any).webkitAudioContext)();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(587.33, ctx.currentTime); // D5 note
      osc.frequency.exponentialRampToValueAtTime(880, ctx.currentTime + 0.3); // A5 note
      gain.gain.setValueAtTime(0.3, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.5);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.5);
    } catch (e) {
      console.error('Audio play error:', e);
    }
  };

  const handleUpdateStatus = async (orderId: string, newStatus: string) => {
    try {
      await merchantApiFetch(`/merchant/orders/${orderId}/status`, {
        method: 'PUT',
        body: JSON.stringify({ status: newStatus }),
      });
      fetchOrders();
    } catch (err: any) {
      alert(err.message || 'Sipariş durumu güncellenemedi.');
    }
  };

  const handleCancelOrder = async () => {
    if (!cancelModalOrder) return;
    try {
      await merchantApiFetch(`/merchant/orders/${cancelModalOrder.id}/cancel`, {
        method: 'POST',
        body: JSON.stringify({ reason: cancelReason }),
      });
      setCancelModalOrder(null);
      fetchOrders();
    } catch (err: any) {
      alert(err.message || 'Sipariş iptal edilemedi.');
    }
  };

  // Group orders by status
  const pendingOrders = orders.filter((o) => o.status === 'PENDING');
  const preparingOrders = orders.filter((o) => o.status === 'PREPARING');
  const onTheWayOrders = orders.filter((o) => o.status === 'ON_THE_WAY' || o.status === 'READY_FOR_PICKUP');
  const completedOrders = orders.filter((o) => o.status === 'DELIVERED');
  const cancelledOrders = orders.filter((o) => o.status === 'CANCELLED');

  return (
    <MerchantLayout title="Canlı Sipariş Portalı" activeTab="orders">
      <div className="space-y-6">
        {/* Top Header & Alarm Switch */}
        <div className={`flex flex-col sm:flex-row sm:items-center justify-between gap-4 border rounded-3xl p-6 transition-colors ${
          isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
        }`}>
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-2xl bg-[#FF6B00] text-white flex items-center justify-center font-bold shadow-lg shadow-[#FF6B00]/25">
              <ShoppingBag className="w-6 h-6" />
            </div>
            <div>
              <h1 className="text-2xl font-black tracking-tight">Canlı Sipariş Portalı</h1>
              <p className="text-xs font-semibold text-slate-500 dark:text-slate-400 mt-0.5">
                Mutfak ve paketleme süreçlerinizi anlık takip edin
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={() => setAudioEnabled(!audioEnabled)}
              className={`px-4 py-2.5 rounded-xl border text-xs font-bold flex items-center gap-2 transition-all ${
                audioEnabled 
                  ? 'bg-[#00A651]/15 text-[#00A651] border-[#00A651]/30' 
                  : 'bg-slate-100 dark:bg-slate-800 text-slate-500 border-slate-200 dark:border-slate-700'
              }`}
            >
              {audioEnabled ? <Volume2 className="w-4 h-4" /> : <VolumeX className="w-4 h-4" />}
              <span>{audioEnabled ? 'Sesli Alarm Açık' : 'Sesli Alarm Kapalı'}</span>
            </button>

            <button
              onClick={fetchOrders}
              className="p-2.5 rounded-xl border border-slate-200 dark:border-slate-800 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
              title="Yenile"
            >
              <RefreshCw className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Guided Onboarding Bar */}
        <GuidedOnboardingWidget pendingOrdersCount={pendingOrders.length} />

        {/* Kanban Columns Grid */}
        {isLoading ? (
          <div className={`text-center py-20 rounded-3xl border ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
          }`}>
            <div className="w-10 h-10 border-3 border-[#FF6B00] border-t-transparent rounded-full animate-spin mx-auto mb-3" />
            <p className="text-xs text-slate-400 font-semibold">Canlı sipariş akışı yükleniyor...</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            
            {/* Column 1: PENDING (Yeni Gelenler) */}
            <div className="space-y-4">
              <div className="flex items-center justify-between px-2">
                <div className="flex items-center gap-2">
                  <span className="w-3 h-3 rounded-full bg-amber-500 animate-pulse" />
                  <h3 className="font-extrabold text-sm uppercase tracking-wider">Yeni Gelenler</h3>
                </div>
                <span className="px-2.5 py-0.5 rounded-full text-xs font-black bg-amber-500/20 text-amber-500">
                  {pendingOrders.length}
                </span>
              </div>

              <div className="space-y-3">
                {pendingOrders.length === 0 ? (
                  <div className={`p-6 text-center rounded-2xl border text-slate-400 text-xs font-semibold ${
                    isDark ? 'bg-slate-900/50 border-slate-800' : 'bg-slate-50 border-slate-200'
                  }`}>
                    Bekleyen yeni sipariş yok.
                  </div>
                ) : (
                  pendingOrders.map((order) => (
                    <OrderCard
                      key={order.id}
                      order={order}
                      isDark={isDark}
                      onApprove={() => handleUpdateStatus(order.id, 'PREPARING')}
                      onCancel={() => setCancelModalOrder(order)}
                      onPrint={() => setSelectedOrderForReceipt(order)}
                    />
                  ))
                )}
              </div>
            </div>

            {/* Column 2: PREPARING (Hazırlanıyor) */}
            <div className="space-y-4">
              <div className="flex items-center justify-between px-2">
                <div className="flex items-center gap-2">
                  <span className="w-3 h-3 rounded-full bg-[#FF6B00]" />
                  <h3 className="font-extrabold text-sm uppercase tracking-wider">Hazırlanıyor</h3>
                </div>
                <span className="px-2.5 py-0.5 rounded-full text-xs font-black bg-[#FF6B00]/20 text-[#FF6B00]">
                  {preparingOrders.length}
                </span>
              </div>

              <div className="space-y-3">
                {preparingOrders.length === 0 ? (
                  <div className={`p-6 text-center rounded-2xl border text-slate-400 text-xs font-semibold ${
                    isDark ? 'bg-slate-900/50 border-slate-800' : 'bg-slate-50 border-slate-200'
                  }`}>
                    Hazırlanan sipariş yok.
                  </div>
                ) : (
                  preparingOrders.map((order) => (
                    <OrderCard
                      key={order.id}
                      order={order}
                      isDark={isDark}
                      onDeliver={() => handleUpdateStatus(order.id, 'ON_THE_WAY')}
                      onCancel={() => setCancelModalOrder(order)}
                      onPrint={() => setSelectedOrderForReceipt(order)}
                    />
                  ))
                )}
              </div>
            </div>

            {/* Column 3: ON_THE_WAY (Yoldakiler / Kuryede) */}
            <div className="space-y-4">
              <div className="flex items-center justify-between px-2">
                <div className="flex items-center gap-2">
                  <span className="w-3 h-3 rounded-full bg-indigo-500" />
                  <h3 className="font-extrabold text-sm uppercase tracking-wider">Yolda / Kuryede</h3>
                </div>
                <span className="px-2.5 py-0.5 rounded-full text-xs font-black bg-indigo-500/20 text-indigo-500">
                  {onTheWayOrders.length}
                </span>
              </div>

              <div className="space-y-3">
                {onTheWayOrders.length === 0 ? (
                  <div className={`p-6 text-center rounded-2xl border text-slate-400 text-xs font-semibold ${
                    isDark ? 'bg-slate-900/50 border-slate-800' : 'bg-slate-50 border-slate-200'
                  }`}>
                    Yolda olan sipariş yok.
                  </div>
                ) : (
                  onTheWayOrders.map((order) => (
                    <OrderCard
                      key={order.id}
                      order={order}
                      isDark={isDark}
                      onComplete={() => handleUpdateStatus(order.id, 'DELIVERED')}
                      onPrint={() => setSelectedOrderForReceipt(order)}
                    />
                  ))
                )}
              </div>
            </div>

            {/* Column 4: DELIVERED (Tamamlananlar) */}
            <div className="space-y-4">
              <div className="flex items-center justify-between px-2">
                <div className="flex items-center gap-2">
                  <span className="w-3 h-3 rounded-full bg-[#00A651]" />
                  <h3 className="font-extrabold text-sm uppercase tracking-wider">Tamamlananlar</h3>
                </div>
                <span className="px-2.5 py-0.5 rounded-full text-xs font-black bg-[#00A651]/20 text-[#00A651]">
                  {completedOrders.length}
                </span>
              </div>

              <div className="space-y-3 max-h-[70vh] overflow-y-auto pr-1">
                {completedOrders.length === 0 ? (
                  <div className={`p-6 text-center rounded-2xl border text-slate-400 text-xs font-semibold ${
                    isDark ? 'bg-slate-900/50 border-slate-800' : 'bg-slate-50 border-slate-200'
                  }`}>
                    Tamamlanan sipariş yok.
                  </div>
                ) : (
                  completedOrders.map((order) => (
                    <OrderCard
                      key={order.id}
                      order={order}
                      isDark={isDark}
                      onPrint={() => setSelectedOrderForReceipt(order)}
                    />
                  ))
                )}
              </div>
            </div>

          </div>
        )}
      </div>

      {/* Receipt Print Modal */}
      {selectedOrderForReceipt && (
        <div className="fixed inset-0 z-50 bg-slate-950/70 backdrop-blur-md flex items-center justify-center p-4">
          <div className={`border rounded-3xl p-6 w-full max-w-md space-y-4 transition-colors ${
            isDark ? 'bg-slate-900 border-slate-800 text-white' : 'bg-white border-slate-200 text-slate-900 shadow-xl'
          }`}>
            <div className="flex items-center justify-between pb-3 border-b border-slate-200 dark:border-slate-800">
              <h3 className="font-bold text-base">Mutfak & Fatura Fişi</h3>
              <button onClick={() => setSelectedOrderForReceipt(null)} className="p-1 text-slate-400">
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Printable Receipt Area */}
            <div id="receipt-print-area" className="p-4 bg-slate-100 text-slate-900 rounded-2xl font-mono text-xs space-y-3">
              <div className="text-center border-b border-slate-300 pb-2">
                <h2 className="font-black text-sm uppercase">HOPPA TESLİMAT FİŞİ</h2>
                <p className="text-[10px]">Sipariş No: #{selectedOrderForReceipt.orderNumber || selectedOrderForReceipt.id.slice(-6)}</p>
                <p className="text-[10px]">{new Date(selectedOrderForReceipt.createdAt).toLocaleString('tr-TR')}</p>
              </div>

              <div>
                <p className="font-bold uppercase text-[10px]">Müşteri Bilgisi:</p>
                <p className="font-bold">
                  {selectedOrderForReceipt.consumer
                    ? `${selectedOrderForReceipt.consumer.name || ''} ${selectedOrderForReceipt.consumer.surname || ''}`.trim()
                    : (selectedOrderForReceipt.user?.fullName || selectedOrderForReceipt.customerName || 'Müşteri')}
                </p>
                <p>{selectedOrderForReceipt.consumer?.phone || selectedOrderForReceipt.user?.phoneNumber || selectedOrderForReceipt.customerPhone || ''}</p>
                <p className="text-[10px] text-slate-600 mt-0.5">{selectedOrderForReceipt.deliveryAddress || 'Teslimat adresi'}</p>
              </div>

              <div className="border-t border-b border-slate-300 py-2 space-y-1">
                {(selectedOrderForReceipt.items || []).map((item: any, idx: number) => {
                  const itemUnitPrice = Number(item.unitPrice ?? item.price ?? item.product?.price ?? 0);
                  const itemQty = Number(item.quantity) || 1;
                  const itemTotal = itemUnitPrice * itemQty;
                  return (
                    <div key={idx} className="flex justify-between font-bold">
                      <span>{itemQty}x {item.product?.name || item.name || 'Ürün'}</span>
                      <span>₺{itemTotal.toFixed(2)}</span>
                    </div>
                  );
                })}
              </div>

              <div className="flex justify-between font-black text-sm">
                <span>TOPLAM TUTAR:</span>
                <span>₺{Number(selectedOrderForReceipt.totalAmount ?? selectedOrderForReceipt.total ?? selectedOrderForReceipt.finalAmount ?? 0).toFixed(2)}</span>
              </div>
            </div>

            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                onClick={() => setSelectedOrderForReceipt(null)}
                className="px-4 py-2.5 rounded-xl bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 text-xs font-bold"
              >
                Kapat
              </button>
              <button
                onClick={() => window.print()}
                className="px-5 py-2.5 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white text-xs font-bold shadow-md flex items-center gap-2"
              >
                <Printer className="w-4 h-4" />
                <span>Yazdır</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Cancel Order Modal */}
      {cancelModalOrder && (
        <div className="fixed inset-0 z-50 bg-slate-950/70 backdrop-blur-md flex items-center justify-center p-4">
          <div className={`border rounded-3xl p-6 w-full max-w-md space-y-4 ${
            isDark ? 'bg-slate-900 border-slate-800 text-white' : 'bg-white border-slate-200 text-slate-900 shadow-xl'
          }`}>
            <h3 className="font-bold text-base text-rose-500">Siparişi İptal Et</h3>
            <p className="text-xs text-slate-400">
              #{cancelModalOrder.orderNumber || cancelModalOrder.id.slice(-6)} numaralı siparişi iptal etmek istediğinize emin misiniz?
            </p>

            <div>
              <label className="block text-xs font-bold uppercase mb-1 text-slate-400">İptal Sebebi</label>
              <select
                value={cancelReason}
                onChange={(e) => setCancelReason(e.target.value)}
                className={`w-full border rounded-xl p-3 text-xs font-semibold outline-none ${
                  isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-800'
                }`}
              >
                <option value="Stok yetersizliği">Stok yetersizliği / Ürün tükendi</option>
                <option value="Yoğunluk nedeniyle hazırlayamama">Aşırı yoğunluk nedeniyle sipariş kabul edilemiyor</option>
                <option value="Müşteri talebi">Müşteri talebi üzerine</option>
                <option value="Kapanış saati geçti">Kapanış saati geçti</option>
              </select>
            </div>

            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                onClick={() => setCancelModalOrder(null)}
                className="px-4 py-2.5 rounded-xl bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 text-xs font-bold"
              >
                Vazgeç
              </button>
              <button
                onClick={handleCancelOrder}
                className="px-5 py-2.5 rounded-xl bg-rose-500 hover:bg-rose-600 text-white text-xs font-bold shadow-md"
              >
                Siparişi İptal Et
              </button>
            </div>
          </div>
        </div>
      )}
    </MerchantLayout>
  );
}

// Single Order Card Component
function OrderCard({ order, isDark, onApprove, onDeliver, onComplete, onCancel, onPrint }: any) {
  const items = order.items || [];
  const itemCount = items.reduce((acc: number, i: any) => acc + (Number(i.quantity) || 1), 0);
  const customerName = order.consumer
    ? `${order.consumer.name || ''} ${order.consumer.surname || ''}`.trim()
    : (order.user?.fullName || order.customerName || 'Müşteri');
  const orderTotal = Number(order.totalAmount ?? order.total ?? order.finalAmount ?? 0);

  return (
    <div className={`border rounded-2xl p-4 space-y-3 transition-all ${
      isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
    }`}>
      {/* Top info */}
      <div className="flex items-center justify-between">
        <div>
          <span className="font-mono text-xs font-black text-[#FF6B00]">
            #{order.orderNumber || order.id.slice(-6)}
          </span>
          <span className="text-[10px] text-slate-400 block font-semibold">
            {new Date(order.createdAt).toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' })}
          </span>
        </div>

        <button
          onClick={onPrint}
          className="p-1.5 rounded-lg border border-slate-200 dark:border-slate-800 text-slate-400 hover:text-slate-700 dark:hover:text-white"
          title="Fiş Yazdır"
        >
          <Printer className="w-3.5 h-3.5" />
        </button>
      </div>

      {/* Customer Info */}
      <div className="text-xs">
        <p className="font-bold truncate">{customerName || 'Müşteri'}</p>
        <p className="text-slate-500 dark:text-slate-400 text-[11px] line-clamp-1">{order.deliveryAddress || 'Adres bilgisi yok'}</p>
      </div>

      {/* Items Summary */}
      <div className="p-2.5 rounded-xl bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 text-xs space-y-1">
        {items.slice(0, 3).map((item: any, idx: number) => {
          const itemUnitPrice = Number(item.unitPrice ?? item.price ?? item.product?.price ?? 0);
          const itemQty = Number(item.quantity) || 1;
          const itemTotal = itemUnitPrice * itemQty;
          return (
            <div key={idx} className="flex justify-between font-semibold">
              <span className="truncate">{itemQty}x {item.product?.name || item.name || 'Ürün'}</span>
              <span className="text-slate-500 font-bold shrink-0 ml-2">₺{itemTotal.toFixed(2)}</span>
            </div>
          );
        })}
        {items.length > 3 && (
          <p className="text-[10px] text-slate-400 font-bold text-center pt-1">
            +{items.length - 3} ürün daha...
          </p>
        )}
      </div>

      {/* Total & Action Buttons */}
      <div className="pt-2 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between">
        <div>
          <span className="text-[10px] text-slate-400 uppercase font-bold block">Toplam</span>
          <span className="text-sm font-black text-[#FF6B00]">₺{orderTotal.toFixed(2)}</span>
        </div>

        <div className="flex items-center gap-1.5">
          {onCancel && (
            <button
              onClick={onCancel}
              className="p-2 rounded-xl bg-rose-500/10 text-rose-500 font-bold text-xs hover:bg-rose-500/20"
              title="İptal Et"
            >
              <XCircle className="w-4 h-4" />
            </button>
          )}

          {onApprove && (
            <button
              onClick={onApprove}
              className="px-3 py-2 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white font-bold text-xs shadow-md flex items-center gap-1"
            >
              <span>Hazırla</span>
              <ChevronRight className="w-3.5 h-3.5" />
            </button>
          )}

          {onDeliver && (
            <button
              onClick={onDeliver}
              className="px-3 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs shadow-md flex items-center gap-1"
            >
              <Bike className="w-3.5 h-3.5" />
              <span>Kuryeye Ver</span>
            </button>
          )}

          {onComplete && (
            <button
              onClick={onComplete}
              className="px-3 py-2 rounded-xl bg-[#00A651] hover:bg-[#008C44] text-white font-bold text-xs shadow-md flex items-center gap-1"
            >
              <CheckCircle2 className="w-3.5 h-3.5" />
              <span>Tamamla</span>
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
