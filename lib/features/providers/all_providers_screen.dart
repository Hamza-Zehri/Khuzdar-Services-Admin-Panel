import 'package:flutter/material.dart';
import '../../core/models/all_models.dart';
import '../../core/services/admin_firestore_service.dart';
import '../../shared/widgets/data_table_widget.dart';
import '../../shared/widgets/badge_widget.dart';
import '../../core/constants/app_colors.dart';

class AllProvidersScreen extends StatefulWidget {
  const AllProvidersScreen({super.key});

  @override
  State<AllProvidersScreen> createState() => _AllProvidersScreenState();
}

class _AllProvidersScreenState extends State<AllProvidersScreen> {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();
  String _searchQuery = '';

  void _toggleBlock(ProviderModel provider) async {
    // Since isBlocked is not in ProviderModel, we just call the block method
    // which handles the associated user account.
    await _firestoreService.blockProvider(provider.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Requested block for associated user')),
      );
    }
  }

  void _confirmDelete(ProviderModel provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Provider?'),
        content: Text('Are you sure you want to PERMANENTLY delete this provider and their associated user account? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _firestoreService.deleteUser(provider.userId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Provider and user deleted successfully'), backgroundColor: AppColors.danger),
                );
              }
            },
            child: const Text('Delete Permanently', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search by name or area',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Filters could be added here
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ProviderModel>>(
              stream: _firestoreService.streamAllProviders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var providers = snapshot.data ?? [];
                
                if (_searchQuery.isNotEmpty) {
                  providers = providers.where((p) {
                    final area = p.area.toLowerCase();
                    final shop = (p.shop?.shopName ?? '').toLowerCase();
                    final uid = p.userId.toLowerCase();
                    return area.contains(_searchQuery) || shop.contains(_searchQuery) || uid.contains(_searchQuery);
                  }).toList();
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: CustomDataTable(
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Area')),
                      DataColumn(label: Text('Rating')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: providers.map((p) {
                      return DataRow(
                        cells: [
                          DataCell(
                            FutureBuilder<UserModel?>(
                              future: _firestoreService.fetchUserInfo(p.userId),
                              builder: (context, userSnap) {
                                final name = userSnap.data?.name ?? '...';
                                return Text(p.type == ProviderType.shop ? (p.shop?.shopName ?? 'Shop ($name)') : name);
                              },
                            ),
                          ),
                          DataCell(Text(p.type == ProviderType.shop ? 'Shop' : 'Individual')),
                          DataCell(Text(p.category.label)),
                          DataCell(Text(p.area)),
                          DataCell(Text(p.rating.toStringAsFixed(1))),
                          DataCell(
                            BadgeWidget(
                              text: p.verificationStatus.name.toUpperCase(),
                              color: (p.verificationStatus == VerificationStatus.approved ? Colors.green : AppColors.accent),
                            )
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.block, color: AppColors.danger),
                                  tooltip: 'Block User',
                                  onPressed: () => _toggleBlock(p),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                  tooltip: 'Remove Provider',
                                  onPressed: () => _confirmDelete(p),
                                ),
                              ],
                            )
                          ),
                        ]
                      );
                    }).toList(),
                  ),
                );

              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
