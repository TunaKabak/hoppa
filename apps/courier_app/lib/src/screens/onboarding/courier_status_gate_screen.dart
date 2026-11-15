import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_auth/core_auth.dart';
import 'package:core_network/core_network.dart';
import '../../models/courier_models.dart';

class CourierStatusGateScreen extends ConsumerStatefulWidget {
  final CourierProfile profile;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLogout;

  const CourierStatusGateScreen({
    super.key,
    required this.profile,
    required this.onRefresh,
    required this.onLogout,
  });

  @override
  ConsumerState<CourierStatusGateScreen> createState() =>
      _CourierStatusGateScreenState();
}

class _CourierStatusGateScreenState
    extends ConsumerState<CourierStatusGateScreen> {
  static const Color _hoppaOrange = Color(0xFFFF6B00);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _plateController;

  String _selectedVehicleType = 'MOTORCYCLE';
  double _maxServiceDistanceKm = 15.0;
  bool _isSubmitting = false;
  bool _isRefreshing = false;

  static const List<_VehicleChoice> _vehicleChoices = [
    _VehicleChoice('MOTORCYCLE', 'Motosiklet', Icons.two_wheeler_rounded, true),
    _VehicleChoice('CAR', 'Otomobil', Icons.directions_car_rounded, true),
    _VehicleChoice('BICYCLE', 'Bisiklet', Icons.pedal_bike_rounded, false),
    _VehicleChoice('FOOT', 'Yaya', Icons.directions_walk_rounded, false),
  ];

  @override
  void initState() {
    super.initState();
    final initialName = _resolveInitialName(widget.profile);
    _nameController = TextEditingController(text: initialName);
    _plateController = TextEditingController(
      text: widget.profile.vehiclePlate ?? '',
    );

    final initialVehicle = widget.profile.vehicleType;
    if (initialVehicle != null &&
        _vehicleChoices.any((choice) => choice.code == initialVehicle)) {
      _selectedVehicleType = initialVehicle;
    }

    final dist = widget.profile.maxServiceDistanceKm;
    if (dist != null && dist >= 1 && dist <= 50) {
      _maxServiceDistanceKm = dist;
    }
  }

  String _resolveInitialName(CourierProfile profile) {
    if (profile.name != null && profile.name!.trim().isNotEmpty) {
      return profile.name!.trim();
    }
    final full = profile.user?.fullName ?? '';
    if (full.isNotEmpty && full != 'Misafir Kullanıcı') {
      return full;
    }
    return '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  bool get _needsApplicationForm {
    return !widget.profile.hasProfile ||
        widget.profile.status == 'NOT_APPLIED' ||
        widget.profile.status == 'REJECTED';
  }

  bool get _requiresPlate =>
      _selectedVehicleType == 'MOTORCYCLE' || _selectedVehicleType == 'CAR';

  String _vehicleLabel(String? code) {
    for (final choice in _vehicleChoices) {
      if (choice.code == code) return choice.label;
    }
    return code ?? 'Belirtilmemiş';
  }

  Future<void> _submitApplication() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      final plateText = _plateController.text.trim().toUpperCase();
      await ref
          .read(apiClientProvider)
          .post(
            '/api/couriers/me/apply',
            body: {
              'name': _nameController.text.trim(),
              'vehicleType': _selectedVehicleType,
              if (plateText.isNotEmpty) 'vehiclePlate': plateText,
              'maxServiceDistanceKm': _maxServiceDistanceKm.round(),
            },
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kurye başvurunuz başarıyla gönderildi!'),
          backgroundColor: Color(0xFF00A651),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await widget.onRefresh();
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Başvuru gönderilemedi: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hoppa Kurye',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton.icon(
            onPressed: (_isSubmitting || _isRefreshing)
                ? null
                : () async => await widget.onLogout(),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Çıkış'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _needsApplicationForm
                    ? _buildApplicationForm(context)
                    : _buildStatusSummaryView(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationForm(BuildContext context) {
    final theme = Theme.of(context);
    final isRejected = widget.profile.status == 'REJECTED';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isRejected) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Önceki kurye başvurunuz onaylanmadı. Bilgilerinizi güncelleyip yeniden başvurabilirsiniz.',
                    style: TextStyle(
                      color: Color(0xFF991B1B),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _hoppaOrange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.two_wheeler_rounded,
                          color: _hoppaOrange,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isRejected
                                  ? 'Yeniden Kurye Başvurusu'
                                  : 'Hoppa Kurye Başvurusu',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Teslimatlara başlamak için profil bilgilerinizi tamamlayın.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  TextFormField(
                    controller: _nameController,
                    enabled: !_isSubmitting,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().length < 2) {
                        return 'Lütfen adınızı ve soyadınızı girin';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      hintText: 'Örn. Ahmet Yılmaz',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    'Araç Tipi',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _vehicleChoices.map((choice) {
                      final selected = _selectedVehicleType == choice.code;
                      return ChoiceChip(
                        selected: selected,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              choice.icon,
                              size: 18,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF475569),
                            ),
                            const SizedBox(width: 6),
                            Text(choice.label),
                          ],
                        ),
                        selectedColor: _hoppaOrange,
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: const Color(0xFFF8FAFC),
                        side: BorderSide(
                          color: selected
                              ? _hoppaOrange
                              : const Color(0xFFE2E8F0),
                        ),
                        onSelected: _isSubmitting
                            ? null
                            : (_) {
                                setState(() {
                                  _selectedVehicleType = choice.code;
                                });
                              },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  TextFormField(
                    controller: _plateController,
                    enabled: !_isSubmitting,
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (_requiresPlate &&
                          (value == null || value.trim().length < 3)) {
                        return 'Motosiklet ve otomobil için plaka gereklidir';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: _requiresPlate
                          ? 'Araç Plakası'
                          : 'Araç Plakası (Opsiyonel)',
                      hintText: 'Örn. NG 123',
                      prefixIcon: const Icon(Icons.pin_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Maksimum Hizmet Mesafesi',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _hoppaOrange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_maxServiceDistanceKm.round()} km',
                          style: const TextStyle(
                            color: _hoppaOrange,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _maxServiceDistanceKm,
                    min: 2,
                    max: 40,
                    divisions: 38,
                    activeColor: _hoppaOrange,
                    label: '${_maxServiceDistanceKm.round()} km',
                    onChanged: _isSubmitting
                        ? null
                        : (val) => setState(() => _maxServiceDistanceKm = val),
                  ),
                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitApplication,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _isSubmitting
                          ? 'Gönderiliyor...'
                          : (isRejected ? 'Yeniden Başvur' : 'Başvuruyu Gönder'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSummaryView(BuildContext context) {
    final theme = Theme.of(context);
    final statusMeta = _resolveStatusMeta(widget.profile.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: statusMeta.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusMeta.icon, color: statusMeta.color, size: 36),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusMeta.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusMeta.badge,
                  style: TextStyle(
                    color: statusMeta.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              statusMeta.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statusMeta.description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF475569),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),

            // Profile summary box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Başvuru Özeti',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SummaryRow(
                    icon: Icons.person_outline,
                    label: 'Ad Soyad',
                    value: widget.profile.displayName,
                  ),
                  if (widget.profile.phoneNumber != null)
                    _SummaryRow(
                      icon: Icons.phone_outlined,
                      label: 'Telefon',
                      value: widget.profile.phoneNumber!,
                    ),
                  _SummaryRow(
                    icon: Icons.two_wheeler_outlined,
                    label: 'Araç Tipi',
                    value: _vehicleLabel(widget.profile.vehicleType),
                  ),
                  if (widget.profile.vehiclePlate != null &&
                      widget.profile.vehiclePlate!.isNotEmpty)
                    _SummaryRow(
                      icon: Icons.pin_outlined,
                      label: 'Plaka',
                      value: widget.profile.vehiclePlate!,
                    ),
                  if (widget.profile.maxServiceDistanceKm != null)
                    _SummaryRow(
                      icon: Icons.radar_outlined,
                      label: 'Hizmet Yarıçapı',
                      value:
                          '${widget.profile.maxServiceDistanceKm!.round()} km',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            ElevatedButton.icon(
              onPressed: _isRefreshing ? null : _handleRefresh,
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(_isRefreshing ? 'Kontrol Ediliyor...' : 'Durumu Yenile'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isRefreshing ? null : () async => await widget.onLogout(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF475569),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Çıkış Yap'),
            ),
          ],
        ),
      ),
    );
  }

  _StatusMeta _resolveStatusMeta(String status) {
    switch (status) {
      case 'INTERVIEWING':
        return const _StatusMeta(
          badge: 'MÜLAKAT AŞAMASI',
          title: 'Görüşme Sürecindesiniz',
          description:
              'Başvurunuz ön değerlendirmeyi geçti. Operasyon ekibimiz kısa süre içinde sizinle iletişime geçecektir.',
          icon: Icons.forum_rounded,
          color: Color(0xFF2563EB),
        );
      case 'SUSPENDED':
        return const _StatusMeta(
          badge: 'ASKIYA ALINDI',
          title: 'Kurye Hesabınız Askıya Alındı',
          description:
              'Hesabınız şu anda aktif görev kabul edememektedir. Detaylı bilgi için Hoppa operasyon ekibiyle iletişime geçin.',
          icon: Icons.block_rounded,
          color: Color(0xFFDC2626),
        );
      case 'APPLIED':
      default:
        return const _StatusMeta(
          badge: 'İNCELEMEDE',
          title: 'Başvurunuz Değerlendiriliyor',
          description:
              'Kurye başvurunuz ekibimize ulaştı. Onay süreci tamamlandığında nöbete çıkıp sipariş almaya başlayabilirsiniz.',
          icon: Icons.hourglass_top_rounded,
          color: Color(0xFFFF6B00),
        );
    }
  }
}

class _VehicleChoice {
  final String code;
  final String label;
  final IconData icon;
  final bool requiresPlate;

  const _VehicleChoice(this.code, this.label, this.icon, this.requiresPlate);
}

class _StatusMeta {
  final String badge;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _StatusMeta({
    required this.badge,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 17, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
