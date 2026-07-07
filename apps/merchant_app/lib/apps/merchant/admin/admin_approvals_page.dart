import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'providers/super_admin_providers.dart';

class AdminApprovalsPage extends ConsumerStatefulWidget {
  const AdminApprovalsPage({super.key});

  @override
  ConsumerState<AdminApprovalsPage> createState() => _AdminApprovalsPageState();
}

class _AdminApprovalsPageState extends ConsumerState<AdminApprovalsPage> {
  bool _isLoading = false;

  Future<void> _handleAction(Future<void> Function() action, String successMessage) async {
    setState(() => _isLoading = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmApprove(String userId, String businessName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Onayla", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("$businessName adlı işletmenin başvurusunu onaylamak istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(ctx);
              _handleAction(
                () => ref.read(pendingMerchantsProvider.notifier).updateMerchantStatus(
                      id: userId,
                      status: 'ACTIVE',
                    ),
                "$businessName başarıyla onaylandı.",
              );
            },
            child: const Text("Onayla", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _promptReject(String userId) {
    final tc = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Reddet", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red)),
        content: TextField(
          controller: tc,
          decoration: const InputDecoration(
            labelText: "Reddetme Sebebi",
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _handleAction(
                () => ref.read(pendingMerchantsProvider.notifier).updateMerchantStatus(
                      id: userId,
                      status: 'REJECTED',
                      revisionMessage: tc.text,
                    ),
                "Başvuru reddedildi.",
              );
            },
            child: const Text("Reddet", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _promptRevision(String userId) {
    final tc = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Revizyon İste", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.orange)),
        content: TextField(
          controller: tc,
          decoration: const InputDecoration(
            labelText: "Eksik / Hatalı Bilgi Detayı",
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(ctx);
              _handleAction(
                () => ref.read(pendingMerchantsProvider.notifier).updateMerchantStatus(
                      id: userId,
                      status: 'REVISION',
                      revisionMessage: tc.text,
                    ),
                "Revizyon talebi gönderildi.",
              );
            },
            child: const Text("Gönder", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmHold(String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Beklemeye Al", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue)),
        content: const Text("Bu başvuruyu daha sonra incelemek üzere beklemeye almak istiyor musunuz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              Navigator.pop(ctx);
              _handleAction(
                () => ref.read(pendingMerchantsProvider.notifier).updateMerchantStatus(
                      id: userId,
                      status: 'ON_HOLD',
                    ),
                "Başvuru beklemeye alındı.",
              );
            },
            child: const Text("Beklet", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'PENDING':
        color = Colors.orange;
        label = 'Yeni Başvuru';
        break;
      case 'ON_HOLD':
        color = Colors.blue;
        label = 'Beklemede';
        break;
      case 'REVISION':
        color = Colors.purple;
        label = 'Revizyon İstendi';
        break;
      case 'REJECTED':
        color = Colors.red;
        label = 'Reddedildi';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingMerchantsAsyncValue = ref.watch(pendingMerchantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("İşletme Başvuruları", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          pendingMerchantsAsyncValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text("Bir hata oluştu: \$err", style: GoogleFonts.inter(color: Colors.red)),
            ),
            data: (merchants) {
              if (merchants.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
                      const SizedBox(height: 16),
                      Text("İşlem bekleyen başvuru yok.", style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade600))
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: merchants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final merchant = merchants[index];
                  final status = merchant.status;
                  final date = merchant.createdAt != null 
                      ? DateFormat('dd/MM/yyyy HH:mm').format(merchant.createdAt!)
                      : '';

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(merchant.businessName, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                              ),
                              _buildBadge(status),
                            ],
                          ),
                          const Divider(height: 16),
                          _buildInfoRow(Icons.email_outlined, merchant.email),
                          _buildInfoRow(Icons.phone_outlined, merchant.phone ?? 'Belirtilmemiş'),
                          _buildInfoRow(Icons.calendar_today_outlined, date),
                          
                          if (status == 'REJECTED' || status == 'REVISION') ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: Colors.red.shade800),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      merchant.revisionMessage ?? 'Sebep belirtilmemiş',
                                      style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 16),
                          
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // Onayla
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text("Onayla"),
                                onPressed: () => _confirmApprove(merchant.id, merchant.businessName),
                              ),
                              
                              if (status != 'REJECTED')
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                  icon: const Icon(Icons.close, size: 18),
                                  label: const Text("Reddet"),
                                  onPressed: () => _promptReject(merchant.id),
                                ),
                                
                              if (status != 'REVISION')
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                                  icon: const Icon(Icons.edit_note, size: 18),
                                  label: const Text("Revizyon"),
                                  onPressed: () => _promptRevision(merchant.id),
                                ),
                                
                              if (status != 'ON_HOLD')
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                                  icon: const Icon(Icons.pause, size: 18),
                                  label: const Text("Beklet"),
                                  onPressed: () => _confirmHold(merchant.id),
                                ),
                                
                              // Kalıcı sil yerine status = REJECTED ile çöpe atacağız veya listeden gizleyeceğiz
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            )
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text, 
              style: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 13),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

