import 'package:flutter/material.dart';

class AnimatedSlidingToggle extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final Color activeColor;
  final Color inactiveColor;
  final Color backgroundColor;

  const AnimatedSlidingToggle({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.activeColor = const Color(0xFF00A651), // Varsayılan Yeşil
    this.inactiveColor = const Color(0xFF757575), // Gri
    this.backgroundColor = const Color(0xFFF5F5F5), // Açık Gri Zemin
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Her bir sekmenin genişliği
          final double tabWidth = constraints.maxWidth / labels.length;

          return Stack(
            children: [
              // 1. Hareket Eden Beyaz Kutu (Arka Plan)
              AnimatedAlign(
                alignment: Alignment(
                  // Matematik: 0..N indeksini -1.0..1.0 aralığına çevirir
                  -1.0 + (selectedIndex * 2 / (labels.length - 1)),
                  0.0,
                ),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutBack, // Yaylanma efekti
                child: Container(
                  width: tabWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Metinler
              Row(
                children: List.generate(labels.length, (index) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(index),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: selectedIndex == index
                                ? activeColor
                                : inactiveColor,
                            fontFamily: 'Inter', // Global font
                          ),
                          child: Text(
                            labels[index],
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
