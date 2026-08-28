import React, { useState, useEffect, useRef } from 'react';
import Head from 'next/head';
import MerchantLayout from '../../../components/merchant/MerchantLayout';
import GuidedOnboardingWidget from '../../../components/merchant/GuidedOnboardingWidget';
import { 
  ShoppingBag, Clock, CheckCircle2, XCircle, Bike, AlertTriangle, 
  Printer, Volume2, VolumeX, ChevronRight, X, RefreshCw,
  User, Phone, MapPin, CreditCard, FileText, Package, Eye,
  Check, Info, Sparkles, Navigation, ArrowRight
} from 'lucide-react';
import { merchantApiFetch } from '../../../utils/merchant-auth';
import { useMerchantTheme } from '../../../context/MerchantThemeContext';

export default function MerchantOrdersPage() {
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  const [orders, setOrders] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [audioEnabled, setAudioEnabled] = useState(true);
  const [selectedOrderForDetail, setSelectedOrderForDetail] = useState<any | null>(null);
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

        // If detail modal is open, refresh selected order data
        if (selectedOrderForDetail) {
          const updated = res.data.find((o: any) => o.id === selectedOrderForDetail.id);
          if (updated) setSelectedOrderForDetail(updated);
        }
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
      await fetchOrders();
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
      if (selectedOrderForDetail?.id === cancelModalOrder.id) {
        setSelectedOrderForDetail(null);
      }
      await fetchOrders();
    } catch (err: any) {
      alert(err.message || 'Sipariş iptal edilemedi.');
    }
  };

  const triggerDirectPrint = (order: any) => {
    setSelectedOrderForReceipt(order);
    setTimeout(() => {
      window.print();
    }, 150);
  };

  // Group orders by status
  const pendingOrders = orders.filter((o) => o.status === 'PENDING');
  const preparingOrders = orders.filter((o) => o.status === 'PREPARING');
  const onTheWayOrders = orders.filter((o) => o.status === 'ON_THE_WAY' || o.status === 'READY_FOR_PICKUP');
  const completedOrders = orders.filter((o) => o.status === 'DELIVERED');

  const ordersHeaderActions = (
    <div className="flex items-center gap-2.5">
      <button
        onClick={() => setAudioEnabled(!audioEnabled)}
        className={`px-3.5 py-2 rounded-xl backdrop-blur-md border text-xs font-bold flex items-center gap-2 transition-all ${
          audioEnabled 
            ? 'bg-emerald-500/30 text-white border-emerald-300/40' 
            : 'bg-white/15 text-white/70 border-white/20 hover:text-white'
        }`}
      >
        {audioEnabled ? <Volume2 className="w-4 h-4 text-emerald-300" /> : <VolumeX className="w-4 h-4" />}
        <span>{audioEnabled ? 'Sesli Alarm Açık' : 'Sesli Alarm Kapalı'}</span>
      </button>

      <button
        onClick={fetchOrders}
        className="p-2 rounded-xl bg-white/15 hover:bg-white/25 border border-white/20 text-white transition-colors"
        title="Yenile"
      >
        <RefreshCw className="w-4 h-4" />
      </button>
    </div>
  );

  return (
    <MerchantLayout 
      title="Canlı Sipariş Portalı" 
      subtitle="Mutfak, paketleme ve kurye süreçlerinizi anlık takip edin (Detay için karta tıklayın)"
      headerIcon={ShoppingBag}
      headerActions={ordersHeaderActions}
      activeTab="orders"
    >
      <Head>
        <title>Canlı Sipariş Portalı | Hoppa Merchant</title>
      </Head>

      {/* Embedded CSS for Isolated 80mm Thermal Receipt Printing */}
      <style jsx global>{`
        @media print {
          body * {
            visibility: hidden !important;
          }
          #thermal-receipt-container,
          #thermal-receipt-container * {
            visibility: visible !important;
          }
          #thermal-receipt-container {
            display: block !important;
            position: absolute !important;
            left: 0 !important;
            top: 0 !important;
            width: 80mm !important;
            padding: 2mm !important;
            box-shadow: none !important;
            border: none !important;
          }
          @page {
            size: 80mm auto;
            margin: 0;
          }
        }
      `}</style>

      <div className="space-y-6">
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
                      onViewDetail={() => setSelectedOrderForDetail(order)}
                      onApprove={() => handleUpdateStatus(order.id, 'PREPARING')}
                      onCancel={() => setCancelModalOrder(order)}
                      onPrint={() => triggerDirectPrint(order)}
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
                      onViewDetail={() => setSelectedOrderForDetail(order)}
                      onDeliver={() => handleUpdateStatus(order.id, 'ON_THE_WAY')}
                      onCancel={() => setCancelModalOrder(order)}
                      onPrint={() => triggerDirectPrint(order)}
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
                      onViewDetail={() => setSelectedOrderForDetail(order)}
                      onComplete={() => handleUpdateStatus(order.id, 'DELIVERED')}
                      onPrint={() => triggerDirectPrint(order)}
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
                      onViewDetail={() => setSelectedOrderForDetail(order)}
                      onPrint={() => triggerDirectPrint(order)}
                    />
                  ))
                )}
              </div>
            </div>

          </div>
        )}
      </div>

      {/* ========================================================================= */}
      {/* Comprehensive Order Details Modal */}
      {/* ========================================================================= */}
      {selectedOrderForDetail && (
        <OrderDetailModal
          order={selectedOrderForDetail}
          isDark={isDark}
          onClose={() => setSelectedOrderForDetail(null)}
          onApprove={() => handleUpdateStatus(selectedOrderForDetail.id, 'PREPARING')}
          onDeliver={() => handleUpdateStatus(selectedOrderForDetail.id, 'ON_THE_WAY')}
          onComplete={() => handleUpdateStatus(selectedOrderForDetail.id, 'DELIVERED')}
          onCancel={() => setCancelModalOrder(selectedOrderForDetail)}
          onPrint={() => triggerDirectPrint(selectedOrderForDetail)}
        />
      )}

      {/* ========================================================================= */}
      {/* Receipt Print Preview & Print Trigger Modal */}
      {/* ========================================================================= */}
      {selectedOrderForReceipt && (
        <div className="fixed inset-0 z-50 bg-slate-950/70 backdrop-blur-md flex items-center justify-center p-4">
          <div className={`border rounded-3xl p-6 w-full max-w-md space-y-4 transition-colors ${
            isDark ? 'bg-slate-900 border-slate-800 text-white' : 'bg-white border-slate-200 text-slate-900 shadow-xl'
          }`}>
            <div className="flex items-center justify-between pb-3 border-b border-slate-200 dark:border-slate-800">
              <div className="flex items-center gap-2">
                <Printer className="w-5 h-5 text-[#FF6B00]" />
                <h3 className="font-bold text-base">Termal Fiş Yazdırma Önizleme</h3>
              </div>
              <button onClick={() => setSelectedOrderForReceipt(null)} className="p-1 text-slate-400 hover:text-slate-600 dark:hover:text-white">
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Visual preview of the 80mm thermal ticket */}
            <div className="max-h-[60vh] overflow-y-auto p-4 bg-slate-100 text-slate-950 rounded-2xl font-mono text-xs shadow-inner">
              <ThermalReceiptContent order={selectedOrderForReceipt} />
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
                <span>Yazdır (80mm POS)</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Hidden Isolated Print Target for @media print */}
      <div id="thermal-receipt-container" style={{ display: 'none' }}>
        {selectedOrderForReceipt && (
          <ThermalReceiptContent order={selectedOrderForReceipt} />
        )}
      </div>

      {/* ========================================================================= */}
      {/* Cancel Order Modal */}
      {/* ========================================================================= */}
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
                className={`w-full border rounded-xl p-3 text-xs font-semibold hoppa-select ${
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

// =============================================================================
// Single Order Card Component
// =============================================================================
function OrderCard({ 
  order, 
  isDark, 
  onViewDetail,
  onApprove, 
  onDeliver, 
  onComplete, 
  onCancel, 
  onPrint 
}: any) {
  const items = order.items || [];
  const itemCount = items.reduce((acc: number, i: any) => acc + (Number(i.quantity) || 1), 0);
  const customerName = order.consumer
    ? `${order.consumer.name || ''} ${order.consumer.surname || ''}`.trim()
    : (order.user?.fullName || order.customerName || 'Müşteri');
  const orderTotal = Number(order.totalAmount ?? order.total ?? order.finalAmount ?? 0);

  const getStatusBadge = () => {
    switch (order.status) {
      case 'PENDING':
        return <span className="px-2 py-0.5 rounded-full text-[10px] font-black bg-amber-500/15 text-amber-500 border border-amber-500/30">Bekliyor</span>;
      case 'PREPARING':
        return <span className="px-2 py-0.5 rounded-full text-[10px] font-black bg-[#FF6B00]/15 text-[#FF6B00] border border-[#FF6B00]/30">Hazırlanıyor</span>;
      case 'ON_THE_WAY':
        return <span className="px-2 py-0.5 rounded-full text-[10px] font-black bg-indigo-500/15 text-indigo-500 border border-indigo-500/30">Yolda</span>;
      case 'DELIVERED':
        return <span className="px-2 py-0.5 rounded-full text-[10px] font-black bg-[#00A651]/15 text-[#00A651] border border-[#00A651]/30">Tamamlandı</span>;
      default:
        return <span className="px-2 py-0.5 rounded-full text-[10px] font-black bg-slate-500/15 text-slate-500">{order.status}</span>;
    }
  };

  return (
    <div 
      onClick={onViewDetail}
      className={`border rounded-2xl p-4 space-y-3 transition-all cursor-pointer hover:border-[#FF6B00]/50 hover:shadow-lg ${
        isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
      }`}
    >
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

        <div className="flex items-center gap-1.5" onClick={(e) => e.stopPropagation()}>
          {getStatusBadge()}
          <button
            onClick={onPrint}
            className="p-1.5 rounded-lg border border-slate-200 dark:border-slate-800 text-slate-400 hover:text-slate-700 dark:hover:text-white transition-colors"
            title="Fiş Yazdır"
          >
            <Printer className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      {/* Customer Info */}
      <div className="text-xs">
        <p className="font-bold truncate text-slate-800 dark:text-slate-100">{customerName || 'Müşteri'}</p>
        <p className="text-slate-500 dark:text-slate-400 text-[11px] line-clamp-1">{order.deliveryAddress || 'Adres bilgisi yok'}</p>
        {order.customerNote && (
          <p className="text-[10px] text-amber-600 dark:text-amber-400 font-medium bg-amber-50 dark:bg-amber-950/40 p-1.5 rounded-lg mt-1 line-clamp-1">
            💬 {order.customerNote}
          </p>
        )}
      </div>

      {/* Items Summary */}
      <div className="p-2.5 rounded-xl bg-slate-50 dark:bg-slate-950 border border-slate-200 dark:border-slate-800 text-xs space-y-1">
        {items.slice(0, 3).map((item: any, idx: number) => {
          const itemUnitPrice = Number(item.unitPrice ?? item.price ?? item.product?.price ?? 0);
          const itemQty = Number(item.quantity) || 1;
          const itemTotal = itemUnitPrice * itemQty;
          return (
            <div key={idx} className="flex justify-between font-semibold text-slate-700 dark:text-slate-300">
              <span className="truncate">{itemQty}x {item.product?.name || item.name || 'Ürün'}</span>
              <span className="text-slate-500 font-bold shrink-0 ml-2">₺{itemTotal.toFixed(2)}</span>
            </div>
          );
        })}
        {items.length > 3 && (
          <p className="text-[10px] text-slate-400 font-bold text-center pt-1">
            +{items.length - 3} ürün daha (Detay için tıkla)...
          </p>
        )}
      </div>

      {/* Total & Action Buttons */}
      <div className="pt-2 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between" onClick={(e) => e.stopPropagation()}>
        <div>
          <span className="text-[10px] text-slate-400 uppercase font-bold block">Toplam</span>
          <span className="text-sm font-black text-[#FF6B00]">₺{orderTotal.toFixed(2)}</span>
        </div>

        <div className="flex items-center gap-1.5">
          <button
            onClick={onViewDetail}
            className="p-2 rounded-xl bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 font-bold text-xs hover:bg-slate-200 dark:hover:bg-slate-700"
            title="Detay Gör"
          >
            <Eye className="w-3.5 h-3.5" />
          </button>

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

// =============================================================================
// Comprehensive Order Detail Modal Component
// =============================================================================
function OrderDetailModal({
  order,
  isDark,
  onClose,
  onApprove,
  onDeliver,
  onComplete,
  onCancel,
  onPrint,
}: any) {
  const items = order.items || [];
  const customerName = order.consumer
    ? `${order.consumer.name || ''} ${order.consumer.surname || ''}`.trim()
    : (order.user?.fullName || order.customerName || 'Müşteri');
  const customerPhone = order.consumer?.phone || order.user?.phoneNumber || order.customerPhone || '';
  const orderTotal = Number(order.totalAmount ?? order.total ?? order.finalAmount ?? 0);
  const deliveryFee = Number(order.deliveryFee ?? 0);
  const subtotal = orderTotal > deliveryFee ? orderTotal - deliveryFee : orderTotal;

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/75 backdrop-blur-md flex items-center justify-center p-4 sm:p-6 overflow-y-auto">
      <div className={`border rounded-3xl w-full max-w-3xl shadow-2xl flex flex-col max-h-[90vh] overflow-hidden ${
        isDark ? 'bg-slate-900 border-slate-800 text-white' : 'bg-white border-slate-200 text-slate-900'
      }`}>
        
        {/* Modal Header */}
        <div className="p-6 border-b border-slate-200 dark:border-slate-800 flex items-center justify-between shrink-0">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-[#FF6B00]/15 text-[#FF6B00] flex items-center justify-center font-black">
              <ShoppingBag className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-lg font-black tracking-tight font-mono">
                  #{order.orderNumber || order.id.slice(-6)}
                </h2>
                <span className={`px-2.5 py-0.5 rounded-full text-xs font-black ${
                  order.status === 'PENDING' ? 'bg-amber-500/20 text-amber-500' :
                  order.status === 'PREPARING' ? 'bg-[#FF6B00]/20 text-[#FF6B00]' :
                  order.status === 'ON_THE_WAY' ? 'bg-indigo-500/20 text-indigo-500' :
                  order.status === 'DELIVERED' ? 'bg-[#00A651]/20 text-[#00A651]' : 'bg-rose-500/20 text-rose-500'
                }`}>
                  {order.status === 'PENDING' ? 'Yeni Sipariş' :
                   order.status === 'PREPARING' ? 'Hazırlanıyor' :
                   order.status === 'ON_THE_WAY' ? 'Kuryede / Yolda' :
                   order.status === 'DELIVERED' ? 'Teslim Edildi' : order.status}
                </span>
              </div>
              <p className="text-xs text-slate-400 font-semibold mt-0.5">
                {new Date(order.createdAt).toLocaleDateString('tr-TR')} • {new Date(order.createdAt).toLocaleTimeString('tr-TR')}
              </p>
            </div>
          </div>

          <button 
            onClick={onClose}
            className="p-2 rounded-xl text-slate-400 hover:text-slate-600 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Scrollable Content */}
        <div className="p-6 overflow-y-auto space-y-6 flex-1">
          
          {/* Customer and Delivery Cards Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            
            {/* Customer Contact */}
            <div className={`p-4 rounded-2xl border space-y-3 ${
              isDark ? 'bg-slate-950/60 border-slate-800' : 'bg-slate-50 border-slate-200'
            }`}>
              <div className="flex items-center gap-2 text-[#FF6B00] font-bold text-xs uppercase tracking-wider">
                <User className="w-4 h-4" />
                <span>Müşteri Bilgileri</span>
              </div>
              <div className="space-y-1 text-xs">
                <p className="font-extrabold text-sm">{customerName}</p>
                {customerPhone && (
                  <a 
                    href={`tel:${customerPhone}`}
                    className="flex items-center gap-1.5 text-[#FF6B00] hover:underline font-semibold"
                  >
                    <Phone className="w-3.5 h-3.5" />
                    <span>{customerPhone}</span>
                  </a>
                )}
              </div>
            </div>

            {/* Delivery Address & Model */}
            <div className={`p-4 rounded-2xl border space-y-3 ${
              isDark ? 'bg-slate-950/60 border-slate-800' : 'bg-slate-50 border-slate-200'
            }`}>
              <div className="flex items-center gap-2 text-[#FF6B00] font-bold text-xs uppercase tracking-wider">
                <MapPin className="w-4 h-4" />
                <span>Teslimat Adresi</span>
              </div>
              <div className="text-xs space-y-1">
                <p className="font-semibold text-slate-700 dark:text-slate-300 leading-relaxed">
                  {order.deliveryAddress || 'Adres detayı belirtilmedi'}
                </p>
                <div className="flex flex-wrap gap-2 pt-1">
                  <span className="px-2 py-0.5 rounded-lg bg-indigo-500/10 text-indigo-500 text-[10px] font-bold">
                    {order.fulfillmentModel === 'PICKUP' ? '📦 Gel Al Siparişi' : '🛵 Adrese Teslimat'}
                  </span>
                  {order.courier && (
                    <span className="px-2 py-0.5 rounded-lg bg-[#00A651]/10 text-[#00A651] text-[10px] font-bold">
                      Kurye: {order.courier.name || 'Atandı'}
                    </span>
                  )}
                </div>
              </div>
            </div>

          </div>

          {/* Delivery Preferences and Notes (if any) */}
          {(order.customerNote || order.dontRingBell || order.leaveAtDoor || order.substitutionPreference) && (
            <div className="p-4 rounded-2xl bg-amber-500/10 border border-amber-500/30 text-amber-900 dark:text-amber-200 space-y-2">
              <div className="flex items-center gap-2 font-bold text-xs">
                <AlertTriangle className="w-4 h-4 text-amber-500" />
                <span>Müşteri Notu & Teslimat Tercihleri</span>
              </div>
              {order.customerNote && (
                <p className="text-xs font-semibold bg-white/50 dark:bg-slate-900/50 p-2.5 rounded-xl border border-amber-500/20">
                  "{order.customerNote}"
                </p>
              )}
              <div className="flex flex-wrap gap-2 pt-1 text-[11px] font-bold">
                {order.dontRingBell && (
                  <span className="px-2 py-1 rounded-lg bg-amber-500/20 text-amber-700 dark:text-amber-300">
                    🔕 Zili Çalma
                  </span>
                )}
                {order.leaveAtDoor && (
                  <span className="px-2 py-1 rounded-lg bg-amber-500/20 text-amber-700 dark:text-amber-300">
                    🚪 Kapıya Bırak
                  </span>
                )}
                {order.substitutionPreference && (
                  <span className="px-2 py-1 rounded-lg bg-amber-500/20 text-amber-700 dark:text-amber-300">
                    🔄 Ürün Yoksa: {order.substitutionPreference === 'SUBSTITUTE' ? 'Muadil ürün seç' : 'Siparişi iptal et/iade et'}
                  </span>
                )}
              </div>
            </div>
          )}

          {/* Order Items & Options Detailed Breakdown */}
          <div className="space-y-3">
            <h3 className="font-extrabold text-sm uppercase tracking-wider flex items-center gap-2">
              <Package className="w-4 h-4 text-[#FF6B00]" />
              <span>Sipariş Kalemleri ({items.length} Çeşit Ürün)</span>
            </h3>

            <div className="divide-y divide-slate-100 dark:divide-slate-800 border rounded-2xl overflow-hidden">
              {items.map((item: any, idx: number) => {
                const unitPrice = Number(item.unitPrice ?? item.price ?? item.product?.price ?? 0);
                const quantity = Number(item.quantity) || 1;
                const totalItemPrice = unitPrice * quantity;
                const options = item.options || [];

                return (
                  <div key={idx} className={`p-4 transition-colors ${
                    isDark ? 'bg-slate-950/40 hover:bg-slate-950/80' : 'bg-slate-50/70 hover:bg-slate-100/70'
                  }`}>
                    <div className="flex items-start justify-between gap-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-xl bg-[#FF6B00]/15 text-[#FF6B00] font-black text-sm flex items-center justify-center shrink-0">
                          {quantity}x
                        </div>
                        <div>
                          <p className="font-extrabold text-sm text-slate-900 dark:text-white">
                            {item.product?.name || item.name || 'Ürün'}
                          </p>
                          <p className="text-xs text-slate-400 font-medium">
                            Birim Fiyat: ₺{unitPrice.toFixed(2)}
                          </p>
                        </div>
                      </div>

                      <div className="text-right shrink-0 font-mono font-black text-sm text-[#FF6B00]">
                        ₺{totalItemPrice.toFixed(2)}
                      </div>
                    </div>

                    {/* Selected Options / Addons Breakdown */}
                    {options.length > 0 && (
                      <div className="mt-3 ml-12 pl-3 border-l-2 border-[#FF6B00]/30 space-y-1">
                        <p className="text-[11px] font-bold text-slate-400 uppercase">Seçilen Tercihler & Özelleştirmeler:</p>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-1 text-xs">
                          {options.map((opt: any, optIdx: number) => {
                            const optPrice = Number(opt.price ?? 0);
                            const isRemoval = opt.actionType === 'REMOVE' || optPrice < 0;
                            return (
                              <div key={optIdx} className="flex items-center justify-between bg-white dark:bg-slate-900 px-2 py-1 rounded-lg border border-slate-200 dark:border-slate-800 text-[11px]">
                                <span className="font-semibold text-slate-700 dark:text-slate-300">
                                  {isRemoval ? '❌ ' : '➕ '}
                                  {opt.groupName ? `${opt.groupName}: ` : ''}
                                  {opt.name || opt.optionName}
                                </span>
                                {optPrice !== 0 && (
                                  <span className="font-bold font-mono text-[#FF6B00]">
                                    {optPrice > 0 ? `+₺${optPrice.toFixed(2)}` : `-₺${Math.abs(optPrice).toFixed(2)}`}
                                  </span>
                                )}
                              </div>
                            );
                          })}
                        </div>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          {/* Payment & Total Amount Summary */}
          <div className={`p-4 rounded-2xl border space-y-2 text-xs font-semibold ${
            isDark ? 'bg-slate-950/60 border-slate-800' : 'bg-slate-50 border-slate-200'
          }`}>
            <div className="flex justify-between text-slate-500 dark:text-slate-400">
              <span>Ara Toplam (Ürünler)</span>
              <span className="font-mono">₺{subtotal.toFixed(2)}</span>
            </div>
            {deliveryFee > 0 && (
              <div className="flex justify-between text-slate-500 dark:text-slate-400">
                <span>Teslimat Ücreti</span>
                <span className="font-mono">₺{deliveryFee.toFixed(2)}</span>
              </div>
            )}
            <div className="flex justify-between items-center pt-2 border-t border-slate-200 dark:border-slate-800 text-sm font-black">
              <span>GENEL TOPLAM</span>
              <span className="font-mono text-base text-[#FF6B00]">₺{orderTotal.toFixed(2)}</span>
            </div>
            <div className="pt-2 flex items-center justify-between text-[11px] text-slate-400 font-bold border-t border-slate-200/50 dark:border-slate-800/50">
              <span>Ödeme Yöntemi: {order.paymentMethod || 'Online Ödeme'}</span>
              <span className="text-[#00A651]">Ödeme Durumu: {order.paymentStatus === 'COMPLETED' || !order.paymentStatus ? 'Ödendi' : order.paymentStatus}</span>
            </div>
          </div>

        </div>

        {/* Modal Footer Actions */}
        <div className="p-5 border-t border-slate-200 dark:border-slate-800 flex flex-wrap items-center justify-between gap-3 shrink-0 bg-slate-50 dark:bg-slate-950/50">
          <button
            onClick={onPrint}
            className="px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-200 font-bold text-xs hover:bg-slate-100 dark:hover:bg-slate-700 flex items-center gap-2 shadow-sm"
          >
            <Printer className="w-4 h-4 text-[#FF6B00]" />
            <span>Mutfak Fişi Yazdır</span>
          </button>

          <div className="flex items-center gap-2">
            {order.status === 'PENDING' && (
              <>
                <button
                  onClick={onCancel}
                  className="px-4 py-2.5 rounded-xl bg-rose-500/10 text-rose-500 font-bold text-xs hover:bg-rose-500/20"
                >
                  İptal Et
                </button>
                <button
                  onClick={onApprove}
                  className="px-5 py-2.5 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white font-bold text-xs shadow-md flex items-center gap-1.5"
                >
                  <span>Siparişi Onayla & Hazırla</span>
                  <ArrowRight className="w-4 h-4" />
                </button>
              </>
            )}

            {order.status === 'PREPARING' && (
              <>
                <button
                  onClick={onCancel}
                  className="px-4 py-2.5 rounded-xl bg-rose-500/10 text-rose-500 font-bold text-xs hover:bg-rose-500/20"
                >
                  İptal Et
                </button>
                <button
                  onClick={onDeliver}
                  className="px-5 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs shadow-md flex items-center gap-1.5"
                >
                  <Bike className="w-4 h-4" />
                  <span>Kuryeye Teslim Et / Yola Çıkar</span>
                </button>
              </>
            )}

            {(order.status === 'ON_THE_WAY' || order.status === 'READY_FOR_PICKUP') && (
              <button
                onClick={onComplete}
                className="px-5 py-2.5 rounded-xl bg-[#00A651] hover:bg-[#008C44] text-white font-bold text-xs shadow-md flex items-center gap-1.5"
              >
                <CheckCircle2 className="w-4 h-4" />
                <span>Teslimatı Tamamla</span>
              </button>
            )}

            <button
              onClick={onClose}
              className="px-4 py-2.5 rounded-xl bg-slate-200 dark:bg-slate-800 text-slate-700 dark:text-slate-300 font-bold text-xs"
            >
              Kapat
            </button>
          </div>
        </div>

      </div>
    </div>
  );
}

// =============================================================================
// Isolated 80mm Thermal POS Receipt Template
// =============================================================================
function ThermalReceiptContent({ order }: { order: any }) {
  if (!order) return null;

  const items = order.items || [];
  const customerName = order.consumer
    ? `${order.consumer.name || ''} ${order.consumer.surname || ''}`.trim()
    : (order.user?.fullName || order.customerName || 'Müşteri');
  const customerPhone = order.consumer?.phone || order.user?.phoneNumber || order.customerPhone || '';
  const orderTotal = Number(order.totalAmount ?? order.total ?? order.finalAmount ?? 0);
  const deliveryFee = Number(order.deliveryFee ?? 0);
  const subtotal = orderTotal > deliveryFee ? orderTotal - deliveryFee : orderTotal;
  const shopName = order.shop?.name || 'HOPPA İŞLETMESİ';

  return (
    <div className="receipt-body text-slate-950 font-mono text-[11px] leading-tight space-y-2 select-text">
      {/* Header */}
      <div className="text-center pb-2 border-b-2 border-dashed border-slate-950 space-y-1">
        <h1 className="font-black text-sm uppercase tracking-wider">{shopName}</h1>
        <p className="font-bold text-[10px]">HOPPA SİPARİŞ & MUTFAK FİŞİ</p>
        <p className="text-[10px]">Sipariş No: #{order.orderNumber || order.id.slice(-6)}</p>
        <p className="text-[10px]">{new Date(order.createdAt).toLocaleString('tr-TR')}</p>
        <div className="inline-block border border-slate-950 px-2 py-0.5 font-bold text-[10px] uppercase">
          {order.fulfillmentModel === 'PICKUP' ? 'GEL-AL (MÜŞTERİ ALACAK)' : 'ADRESE TESLİMAT'}
        </div>
      </div>

      {/* Customer Info */}
      <div className="py-1 border-b border-dashed border-slate-950 space-y-0.5">
        <div className="flex justify-between">
          <span className="font-bold">Müşteri:</span>
          <span className="font-black">{customerName}</span>
        </div>
        {customerPhone && (
          <div className="flex justify-between">
            <span className="font-bold">Tel:</span>
            <span>{customerPhone}</span>
          </div>
        )}
        <div className="pt-0.5">
          <span className="font-bold">Adres: </span>
          <span className="font-medium">{order.deliveryAddress || 'Belirtilmedi'}</span>
        </div>
      </div>

      {/* Special Customer Notes & Instructions */}
      {(order.customerNote || order.dontRingBell || order.leaveAtDoor) && (
        <div className="py-1 border-b-2 border-slate-950 bg-slate-200/60 p-1.5 rounded space-y-0.5">
          <p className="font-black text-[10px] uppercase">⚠️ SİPARİŞ NOTU & TERCİHİ:</p>
          {order.customerNote && <p className="font-bold">"{order.customerNote}"</p>}
          {order.dontRingBell && <p className="font-bold">🔔 ZİLİ ÇALMAYIN</p>}
          {order.leaveAtDoor && <p className="font-bold">🚪 KAPIYA BIRAKIN</p>}
        </div>
      )}

      {/* Products Table */}
      <div className="py-1 border-b-2 border-dashed border-slate-950 space-y-1.5">
        <div className="flex justify-between font-black text-[10px] uppercase border-b border-slate-400 pb-0.5">
          <span>ÜRÜN / ADET</span>
          <span>TUTAR</span>
        </div>

        {items.map((item: any, idx: number) => {
          const unitPrice = Number(item.unitPrice ?? item.price ?? item.product?.price ?? 0);
          const quantity = Number(item.quantity) || 1;
          const totalItemPrice = unitPrice * quantity;
          const options = item.options || [];

          return (
            <div key={idx} className="space-y-0.5">
              <div className="flex justify-between font-bold">
                <span className="truncate pr-1">{quantity}x {item.product?.name || item.name}</span>
                <span className="shrink-0">₺{totalItemPrice.toFixed(2)}</span>
              </div>
              {options.map((opt: any, optIdx: number) => (
                <div key={optIdx} className="text-[10px] pl-3 text-slate-700 flex justify-between">
                  <span>
                    {opt.actionType === 'REMOVE' ? '- ' : '+ '}
                    {opt.name || opt.optionName}
                  </span>
                  {Number(opt.price || 0) > 0 && (
                    <span>+₺{Number(opt.price).toFixed(2)}</span>
                  )}
                </div>
              ))}
            </div>
          );
        })}
      </div>

      {/* Totals */}
      <div className="pt-1 space-y-0.5">
        <div className="flex justify-between">
          <span>Ara Toplam:</span>
          <span>₺{subtotal.toFixed(2)}</span>
        </div>
        {deliveryFee > 0 && (
          <div className="flex justify-between">
            <span>Teslimat Ücreti:</span>
            <span>₺{deliveryFee.toFixed(2)}</span>
          </div>
        )}
        <div className="flex justify-between font-black text-xs border-t border-slate-950 pt-1">
          <span>TOPLAM TUTAR:</span>
          <span>₺{orderTotal.toFixed(2)}</span>
        </div>
        <div className="flex justify-between text-[10px] font-bold pt-0.5">
          <span>Ödeme:</span>
          <span>{order.paymentMethod || 'Online Kredi Kartı'} ({order.paymentStatus === 'COMPLETED' || !order.paymentStatus ? 'ÖDENDİ' : 'BEKLİYOR'})</span>
        </div>
      </div>

      {/* Footer */}
      <div className="text-center pt-3 border-t border-dashed border-slate-950 text-[9px] space-y-0.5">
        <p className="font-black">*** AFİYET OLSUN ***</p>
        <p>Hoppa Hızlı Teslimat Portalı</p>
        <p>hoppa.app</p>
      </div>
    </div>
  );
}
