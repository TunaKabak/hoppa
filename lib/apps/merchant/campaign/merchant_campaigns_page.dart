import 'package:flutter/material.dart';
import 'package:hoppa/shared/core/services/campaign_service.dart';
import 'package:hoppa/apps/merchant/campaign/create_campaign_wizard.dart';
import 'package:hoppa/apps/merchant/merchant_main_layout.dart';
import 'package:hoppa/shared/models/campaign.dart';

class MerchantCampaignsPage extends StatelessWidget {
  final String businessId;

  const MerchantCampaignsPage({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    final campaignService = CampaignService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kampanyalarım"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => merchantDrawerKey.currentState?.openDrawer(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CreateCampaignWizard(businessId: businessId),
            ),
          );
        },
        label: const Text("Yeni Kampanya"),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Campaign>>(
        stream: campaignService.getCampaignsForBusiness(businessId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Henüz bir kampanya oluşturmadınız.",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final campaigns = snapshot.data!;
          final now = DateTime.now();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: campaigns.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final campaign = campaigns[index];
              final isExpired = campaign.endDate.isBefore(now);
              final isScheduled = campaign.startDate.isAfter(now);

              Color statusColor;
              String statusText;

              if (isExpired) {
                statusColor = Colors.grey;
                statusText = "Süresi Doldu";
              } else if (isScheduled) {
                statusColor = Colors.orange;
                statusText = "Planlandı";
              } else if (campaign.isActive) {
                statusColor = Colors.green;
                statusText = "Aktif";
              } else {
                statusColor = Colors.red;
                statusText = "Durduruldu";
              }

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (campaign.imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                campaign.imageUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.local_offer,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.local_offer,
                                color: statusColor,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  campaign.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  campaign.type == CampaignType.percentage
                                      ? "%${campaign.discountValue.toStringAsFixed(0)} İndirim"
                                      : "${campaign.discountValue.toStringAsFixed(2)} ₺ (Sabit Fiyat)",
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: campaign.isActive,
                            activeThumbColor: Colors.green,
                            onChanged: isExpired
                                ? null
                                : (val) async {
                                    await campaignService.updateCampaign(
                                      campaign.id,
                                      {'isActive': val},
                                    );
                                  },
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${_formatDate(campaign.startDate)} - ${_formatDate(campaign.endDate)}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              statusText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}.${date.month}.${date.year}";
  }
}
