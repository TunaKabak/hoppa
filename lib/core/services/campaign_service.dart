import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoppa/models/campaign.dart';

class CampaignService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // KAMPANYA OLUŞTUR
  Future<void> createCampaign(Campaign campaign) async {
    await _db.collection('vendor_campaigns').add(campaign.toMap());
  }

  // KAMPANYA GÜNCELLE
  Future<void> updateCampaign(String id, Map<String, dynamic> data) async {
    await _db.collection('vendor_campaigns').doc(id).update(data);
  }

  // KAMPANYA SİL
  Future<void> deleteCampaign(String id) async {
    await _db.collection('vendor_campaigns').doc(id).delete();
  }

  // İŞLETME KAMPANYALARINI GETİR (Tablo/Liste için)
  Stream<List<Campaign>> getCampaignsForBusiness(String vendorId) {
    print("Fetching campaigns for vendorId: $vendorId");
    return _db
        .collection('vendor_campaigns')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) {
          print("Campaigns found: ${snapshot.docs.length}");
          return snapshot.docs
              .map((doc) {
                try {
                  return Campaign.fromMap(doc.data(), doc.id);
                } catch (e) {
                  print("Campaign Parse Error (${doc.id}): $e");
                  return null;
                }
              })
              .where((c) => c != null)
              .cast<Campaign>()
              .toList();
        });
  }

  // AKTİF KAMPANYALARI GETİR (Müşteri için)
  // Firestore'da karmaşık filtreleme yerine istemci tarafında filtreleme yapacağız
  // Çünkü 'targetProducts' array-contains ve tarih aralığı sorgusu aynı anda zor olabilir.
  // Basitçe o işletmenin tüm aktif (isActive=true) kampanyalarını çekip
  // tarih kontrolünü bellekte yapmak daha güvenli.
  Stream<List<Campaign>> getActiveCampaigns(String vendorId) {
    final now = DateTime.now();
    return _db
        .collection('vendor_campaigns')
        .where('vendorId', isEqualTo: vendorId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return Campaign.fromMap(doc.data(), doc.id);
                } catch (e) {
                  print("Active Campaign Parse Error (${doc.id}): $e");
                  return null;
                }
              })
              .where(
                (c) =>
                    c != null &&
                    c.startDate.isBefore(now) &&
                    c.endDate.isAfter(now),
              )
              .cast<Campaign>()
              .toList();
        });
  }
}
