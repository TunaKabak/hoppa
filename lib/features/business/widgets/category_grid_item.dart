import 'package:flutter/material.dart';

class CategoryGridItem extends StatelessWidget {
  final Map<String, dynamic> category;
  final bool isFeatured;
  final String? backgroundImage;
  final VoidCallback onTap;

  const CategoryGridItem({
    super.key,
    required this.category,
    required this.isFeatured,
    this.backgroundImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final catName = category['name'] as String;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: isFeatured ? null : Border.all(color: Colors.grey.shade100),
          image: isFeatured && backgroundImage != null
              ? DecorationImage(
                  image: AssetImage(backgroundImage!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          children: [
            if (isFeatured)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isFeatured) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (category['color'] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        category['icon'] as IconData,
                        size: 32,
                        color: category['color'] as Color,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    catName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isFeatured ? 22 : 15,
                      color: isFeatured ? Colors.white : Colors.black,
                      shadows: isFeatured
                          ? [
                              const Shadow(
                                color: Colors.black45,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
