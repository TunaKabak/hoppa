import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoppa/shared/models/category_model.dart';
import 'package:hoppa/apps/merchant/providers/merchant_api_providers.dart';

class CascadingCategorySelector extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  final String? initialCategoryName;
  final Function(String? categoryId, String categoryName) onChanged;

  const CascadingCategorySelector({
    super.key,
    this.initialCategoryId,
    this.initialCategoryName,
    required this.onChanged,
  });

  @override
  ConsumerState<CascadingCategorySelector> createState() => _CascadingCategorySelectorState();
}

class _CascadingCategorySelectorState extends ConsumerState<CascadingCategorySelector> {
  Category? _selectedRoot;
  Category? _selectedSub;
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(merchantCategoryTreeProvider);

    return categoriesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, st) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text("Kategoriler yüklenemedi: $err", style: const TextStyle(color: Colors.red)),
      ),
      data: (categories) {
        if (!_isInitialized) {
          if (widget.initialCategoryId != null && widget.initialCategoryId!.isNotEmpty) {
            for (final root in categories) {
              if (root.id == widget.initialCategoryId) {
                _selectedRoot = root;
                _selectedSub = null;
                _isInitialized = true;
                break;
              }
              for (final sub in root.children) {
                if (sub.id == widget.initialCategoryId) {
                  _selectedRoot = root;
                  _selectedSub = sub;
                  _isInitialized = true;
                  break;
                }
              }
            }
          }
          if (!_isInitialized && widget.initialCategoryName != null && widget.initialCategoryName!.isNotEmpty) {
            for (final root in categories) {
              if (root.name == widget.initialCategoryName) {
                _selectedRoot = root;
                _selectedSub = null;
                _isInitialized = true;
                break;
              }
              for (final sub in root.children) {
                if (sub.name == widget.initialCategoryName) {
                  _selectedRoot = root;
                  _selectedSub = sub;
                  _isInitialized = true;
                  break;
                }
              }
            }
          }
          _isInitialized = true;
        }

        final roots = categories;
        final subs = _selectedRoot?.children ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<Category>(
              value: _selectedRoot,
              decoration: const InputDecoration(
                labelText: "Ana Kategori",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: roots.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedRoot = val;
                  _selectedSub = null;
                });
                if (val != null) {
                  widget.onChanged(val.id, val.name);
                }
              },
              validator: (v) => v == null ? "Zorunlu alan" : null,
            ),
            if (_selectedRoot != null && subs.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<Category>(
                value: _selectedSub,
                decoration: const InputDecoration(
                  labelText: "Alt Kategori",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.subdirectory_arrow_right_outlined),
                ),
                items: subs.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedSub = val;
                  });
                  if (val != null) {
                    widget.onChanged(val.id, val.name);
                  }
                },
                validator: (v) => v == null ? "Zorunlu alan" : null,
              ),
            ],
          ],
        );
      },
    );
  }
}
