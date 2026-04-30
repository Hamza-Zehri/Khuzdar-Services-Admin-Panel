import 'package:flutter/material.dart';
import '../../../core/models/all_models.dart';
import '../../../core/services/admin_firestore_service.dart';

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = AdminFirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
      ),
      body: StreamBuilder<List<CategoryModel>>(
        stream: firestore.streamCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No categories found.', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _seedCategories(context),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Seed Default Categories'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final cat = categories[i];
              return Card(
                child: ListTile(
                  leading: Text(cat.emoji, style: const TextStyle(fontSize: 24)),
                  title: Text(cat.label),
                  subtitle: Text(cat.labelUrdu),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showCategoryDialog(context, cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }

  void _seedCategories(BuildContext context) async {
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
        const SnackBar(content: Text('Default categories added successfully!')),
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
        content: Text('Are you sure you want to delete "${category.label}"? Providers in this category will lose their connection.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
