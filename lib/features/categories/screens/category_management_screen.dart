import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/all_models.dart';
import '../../../core/services/admin_firestore_service.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_display.dart';

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = AdminFirestoreService();

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: PageHeader(
              title: 'Category Management',
              subtitle: 'Organise the service categories shown in the app',
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<CategoryModel>>(
              stream: firestore.streamCategories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return StatusDisplay.loading();
                }
                if (snapshot.hasError) {
                  return StatusDisplay.error(detail: '${snapshot.error}');
                }

                final categories = snapshot.data ?? [];

                if (categories.isEmpty) {
                  return StatusDisplay.empty(
                    message: 'No categories found',
                    detail: 'Add your first category or seed the defaults',
                    onRetry: () => _seedCategories(context),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 96),
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final cat = categories[i];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(cat.emoji, style: const TextStyle(fontSize: 22)),
                        ),
                        title: Text(
                          cat.label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          cat.labelUrdu,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              color: AppColors.textSecondary,
                              tooltip: 'Edit category',
                              onPressed: () => _showCategoryDialog(context, cat),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: AppColors.danger),
                              tooltip: 'Delete category',
                              onPressed: () => _confirmDelete(context, cat),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(context, null),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Category'),
      ),
    );
  }

  Future<void> _seedCategories(BuildContext context) async {
    final firestore = AdminFirestoreService();
    final defaults = [
      {'label': 'Electrician', 'labelUrdu': 'الیکٹریشن', 'emoji': '⚡', 'order': 1},
      {'label': 'Plumber', 'labelUrdu': 'پلمبر', 'emoji': '🚿', 'order': 2},
      {'label': 'Tailor', 'labelUrdu': 'درزی', 'emoji': '✂️', 'order': 3},
      {'label': 'Teacher', 'labelUrdu': 'استاد', 'emoji': '📚', 'order': 4},
      {'label': 'Carpenter', 'labelUrdu': 'بڑھئی', 'emoji': '🪵', 'order': 5},
      {'label': 'Mechanic', 'labelUrdu': 'میکینک', 'emoji': '🔧', 'order': 6},
      {'label': 'Painter', 'labelUrdu': 'پینٹر', 'emoji': '🖌️', 'order': 7},
      {'label': 'Cleaner', 'labelUrdu': 'کلینر', 'emoji': '🧹', 'order': 8},
    ];

    for (final data in defaults) {
      await firestore.addCategory(CategoryModel(
        id: '',
        label: data['label'] as String,
        labelUrdu: data['labelUrdu'] as String,
        emoji: data['emoji'] as String,
        order: data['order'] as int,
      ));
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default categories added successfully')),
      );
    }
  }

  void _showCategoryDialog(BuildContext context, CategoryModel? category) {
    final labelController = TextEditingController(text: category?.label);
    final labelUrduController = TextEditingController(text: category?.labelUrdu);
    final emojiController = TextEditingController(text: category?.emoji ?? '📁');
    final orderController = TextEditingController(text: category?.order.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Add Category' : 'Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Label (English)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelUrduController,
              decoration: const InputDecoration(labelText: 'Label (Urdu)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emojiController,
              decoration: const InputDecoration(labelText: 'Emoji'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: orderController,
              decoration: const InputDecoration(labelText: 'Order'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (labelController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Label is required')),
                );
                return;
              }
              final newCat = CategoryModel(
                id: category?.id ?? '',
                label: labelController.text.trim(),
                labelUrdu: labelUrduController.text.trim(),
                emoji: emojiController.text.trim(),
                order: int.tryParse(orderController.text) ?? 0,
              );
              if (category == null) {
                AdminFirestoreService().addCategory(newCat);
              } else {
                AdminFirestoreService().updateCategory(newCat);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete "${category.label}"? '
          'Providers in this category will lose their connection to it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              AdminFirestoreService().deleteCategory(category.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}