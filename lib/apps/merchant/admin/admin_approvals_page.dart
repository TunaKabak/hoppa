import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/merchant_admin_service.dart';

class AdminApprovalsPage extends StatefulWidget {
  const AdminApprovalsPage({super.key});

  @override
  State<AdminApprovalsPage> createState() => _AdminApprovalsPageState();
}

class _AdminApprovalsPageState extends State<AdminApprovalsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final MerchantAdminService _adminService = MerchantAdminService();
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
                () => _adminService.approveMerchant(userId),
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
                () => _adminService.rejectMerchant(userId, tc.text),
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
                () => _adminService.requestRevisionMerchant(userId, tc.text),
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
                () => _adminService.holdMerchant(userId),
                "Başvuru beklemeye alındı.",
              );
            },
            child: const Text("Beklet", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Kalıcı Sil", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey)),
        content: const Text("Bu kullanıcı kaydını veritabanından KALICI olarak silmek istiyor musunuz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
            onPressed: () {
              Navigator.pop(ctx);
              _handleAction(
                () => _adminService.deleteMerchant(userId),
                "Kullanıcı başarıyla silindi.",
              );
            },
            child: const Text("Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Yeni Başvuru';
        break;
      case 'on_hold':
        color = Colors.blue;
        label = 'Beklemede';
        break;
      case 'revision_requested':
        color = Colors.purple;
        label = 'Revizyon İstendi';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Reddedildi';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("İşletme Başvuruları", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('business_users')
                      .where('status', whereIn: ['pending', 'on_hold', 'revision_requested', 'rejected'])
                      .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text("Bir hata oluştu."));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
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
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final userId = docs[index].id;
                  final businessName = data['businessName'] ?? 'İsimsiz İşletme';
                  final email = data['email'] ?? '';
                  final phone = data['phone'] ?? '';
                  final date = data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate().toString() : '';
                  final status = data['status'] ?? 'pending';

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
                                child: Text(businessName, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                              ),
                              _buildBadge(status),
                            ],
                          ),
                          const Divider(height: 16),
                          _buildInfoRow(Icons.email_outlined, email),
                          _buildInfoRow(Icons.phone_outlined, phone),
                          _buildInfoRow(Icons.calendar_today_outlined, date.split('.')[0]),
                          
                          if (status == 'rejected' || status == 'revision_requested') ...[
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
                                      status == 'rejected' ? (data['rejectionReason'] ?? 'Sebep yok') : (data['revisionMessage'] ?? 'Sebep yok'),
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
                                onPressed: () => _confirmApprove(userId, businessName),
                              ),
                              
                              if (status != 'rejected')
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                  icon: const Icon(Icons.close, size: 18),
                                  label: const Text("Reddet"),
                                  onPressed: () => _promptReject(userId),
                                ),
                                
                              if (status != 'revision_requested')
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                                  icon: const Icon(Icons.edit_note, size: 18),
                                  label: const Text("Revizyon"),
                                  onPressed: () => _promptRevision(userId),
                                ),
                                
                              if (status != 'on_hold')
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                                  icon: const Icon(Icons.pause, size: 18),
                                  label: const Text("Beklet"),
                                  onPressed: () => _confirmHold(userId),
                                ),
                                
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade700, foregroundColor: Colors.white),
                                icon: const Icon(Icons.delete, size: 18),
                                label: const Text("Sil"),
                                onPressed: () => _confirmDelete(userId),
                              ),
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
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 13)),
        ],
      ),
    );
  }
}
