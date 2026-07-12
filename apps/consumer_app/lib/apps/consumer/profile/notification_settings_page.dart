import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core_auth/core_auth.dart';
import 'package:core_network/core_network.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends ConsumerState<NotificationSettingsPage> {
  bool _notifyOrderStatus = true;
  bool _notifyCampaigns = true;
  bool _notifyNews = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load initial values from the auth state
    final authState = ref.read(authControllerProvider);
    if (authState is AuthAuthenticated) {
      // In the future if we fetch user preferences, we can populate them.
      // Wait, let's look at the database schema. We added:
      // notifyOrderStatus, notifyCampaigns, notifyNews.
      // We can fetch the updated profile or use defaults. Let's load from backend on init!
      _fetchPreferences();
    }
  }

  Future<void> _fetchPreferences() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/api/consumer/profile');
      final data = response['data'];
      if (data != null && mounted) {
        setState(() {
          _notifyOrderStatus = data['notifyOrderStatus'] ?? true;
          _notifyCampaigns = data['notifyCampaigns'] ?? true;
          _notifyNews = data['notifyNews'] ?? true;
        });
      }
    } catch (e) {
      debugPrint("Error fetching notification settings: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePreference(String key, bool value) async {
    setState(() {
      if (key == 'notifyOrderStatus') _notifyOrderStatus = value;
      if (key == 'notifyCampaigns') _notifyCampaigns = value;
      if (key == 'notifyNews') _notifyNews = value;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.put(
        '/api/consumer/profile',
        body: {
          key: value,
        },
      );
      
      // Update local storage too so it is consistent
      final authState = ref.read(authControllerProvider);
      if (authState is AuthAuthenticated) {
        // Just refresh user state locally if needed
        // Note: we can keep auth state in sync
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ayar kaydedilemedi: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
        // Rollback state
        setState(() {
          if (key == 'notifyOrderStatus') _notifyOrderStatus = !value;
          if (key == 'notifyCampaigns') _notifyCampaigns = !value;
          if (key == 'notifyNews') _notifyNews = !value;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const kPrimaryColor = Color(0xFF00A651);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        title: Text(
          "Bildirim Ayarları",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    "Hangi bildirimleri almak istediğinizi detaylı olarak yönetin.",
                    style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  
                  // Order Status Switch Card
                  _buildSwitchCard(
                    title: "Sipariş Durumu Bildirimleri",
                    description: "Siparişinizin onaylanması, yola çıkması ve teslim edilmesi durumlarında anlık bildirim alın.",
                    value: _notifyOrderStatus,
                    onChanged: (val) => _updatePreference('notifyOrderStatus', val),
                    icon: Icons.shopping_bag_rounded,
                    iconColor: Colors.blue,
                  ),
                  
                  const SizedBox(height: 16),

                  // Campaign Switch Card
                  _buildSwitchCard(
                    title: "Kampanyalar & Fırsatlar",
                    description: "Hoppa kuponları, dükkan indirimleri ve özel promosyonlar hakkında bilgilendirilin.",
                    value: _notifyCampaigns,
                    onChanged: (val) => _updatePreference('notifyCampaigns', val),
                    icon: Icons.local_offer_rounded,
                    iconColor: Colors.orange,
                  ),

                  const SizedBox(height: 16),

                  // News Switch Card
                  _buildSwitchCard(
                    title: "Haberler & Güncellemeler",
                    description: "Uygulamaya yeni eklenen özellikler, yeni dükkanlar ve haberler hakkında bilgi alın.",
                    value: _notifyNews,
                    onChanged: (val) => _updatePreference('notifyNews', val),
                    icon: Icons.campaign_rounded,
                    iconColor: Colors.purple,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color iconColor,
  }) {
    const kPrimaryColor = Color(0xFF00A651);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeColor: kPrimaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
