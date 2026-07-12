import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core_shared/shared/core/services/language_provider.dart';
import 'package:provider/provider.dart' as p;

class LanguageSelectionPage extends ConsumerWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageProvider = p.Provider.of<LanguageProvider>(context);
    final currentLocale = languageProvider.currentLocale;
    const kPrimaryColor = Color(0xFF00A651);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        title: Text(
          "Dil Seçimi / Language",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              "Lütfen tercih ettiğiniz uygulama dilini seçin.",
              style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildLanguageCard(
              context,
              title: "Türkçe",
              subtitle: "Turkish",
              flag: "🇹🇷",
              isSelected: currentLocale.languageCode == 'tr',
              onTap: () {
                languageProvider.changeLanguage(const Locale('tr', 'TR'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Dil Türkçe olarak değiştirildi.")),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildLanguageCard(
              context,
              title: "English",
              subtitle: "English",
              flag: "🇬🇧",
              isSelected: currentLocale.languageCode == 'en',
              onTap: () {
                languageProvider.changeLanguage(const Locale('en', 'US'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Language changed to English.")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const kPrimaryColor = Color(0xFF00A651);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.grey.shade200,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? kPrimaryColor : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: kPrimaryColor,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
