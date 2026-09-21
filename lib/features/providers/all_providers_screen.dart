import 'package:flutter/material.dart';
import '../../core/models/all_models.dart';
import '../../core/services/admin_firestore_service.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/data_table_widget.dart';
import '../../shared/widgets/badge_widget.dart';
import '../../shared/widgets/status_display.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/app_colors.dart';

class AllProvidersScreen extends StatefulWidget {
  const AllProvidersScreen({super.key});

  @override
  State<AllProvidersScreen> createState() => _AllProvidersScreenState();
}

class _AllProvidersScreenState extends State<AllProvidersScreen> {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();
  String _searchQuery = '';

  Future<void> _toggleBlock(ProviderModel provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block Provider'),
        content: Text(
          'Block the account associated with ${provider.type == ProviderType.shop ? 'shop' : 'provider'} '
          '(${shortId(provider.userId)})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _firestoreService.blockProvider(provider.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Provider account blocked')),
      );
    }
  }

  void _confirmDelete(ProviderModel provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Provider?'),
        content: Text(
          'Are you sure you want to permanently delete this provider and their associated user account '
          '(${shortId(provider.userId)})? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _firestoreService.deleteUser(provider.userId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Provider and user deleted successfully'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: const Text(
              'Delete Permanently',
              style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: PageHeader(
              title: 'All Providers',
              subtitle: 'Monitor registered providers and their status',
              trailing: SizedBox(
                width: 320,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by name or area…',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<ProviderModel>>(
              stream: _firestoreService.streamAllProviders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return StatusDisplay.loading();
                }
                if (snapshot.hasError) {
                  return StatusDisplay.error(detail: '${snapshot.error}');
                }

                var providers = snapshot.data ?? [];
                if (_searchQuery.isNotEmpty) {
                  providers = providers.where((p) {
                    final area = p.area.toLowerCase();
                    final shop = (p.shop?.shopName ?? '').toLowerCase();
                    final uid = p.userId.toLowerCase();
                    return area.contains(_searchQuery) ||
                        shop.contains(_searchQuery) ||
                        uid.contains(_searchQuery);
                  }).toList();
                }

                if (providers.isEmpty) {
                  return StatusDisplay.empty(
                    message: _searchQuery.isNotEmpty
                        ? 'No providers match your search'
                        : 'No providers yet',
                    detail: 'Providers will appear here once they sign up and get verified',
                  );
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: CustomDataTable(
                    columns: const [
                      DataColumn2(label: Text('Name'), size: ColumnSize.L),
                      DataColumn2(label: Text('Type'), size: ColumnSize.S),
                      DataColumn2(label: Text('Category'), size: ColumnSize.M),
                      DataColumn2(label: Text('Area'), size: ColumnSize.M),
                      DataColumn2(label: Text('Rating'), size: ColumnSize.S),
                      DataColumn2(label: Text('Status'), size: ColumnSize.S),
                      DataColumn2(
                        label: Text('Actions'),
                        fixedWidth: 110,
                      ),
                    ],
                    rows: providers.map((p) {
                      final statusColor =
                          p.verificationStatus == VerificationStatus.approved
                              ? AppColors.success
                              : (p.verificationStatus == VerificationStatus.rejected
                                    ? AppColors.danger
                                    : AppColors.accent);
                      return DataRow(
                        cells: [
                          DataCell(
                            FutureBuilder<UserModel?>(
                              future: _firestoreService.fetchUserInfo(p.userId),
                              builder: (context, userSnap) {
                                final name = userSnap.data?.name ?? '…';
                                final displayName = p.type == ProviderType.shop
                                    ? (p.shop?.shopName ?? 'Shop ($name)')
                                    : name;
                                return Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
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
                              color: statusColor,
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.block_rounded,
                                      color: AppColors.danger),
                                  tooltip: 'Block account',
                                  onPressed: () => _toggleBlock(p),
                                ),
                                IconButton(
                                  icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.danger),
                                  tooltip: 'Remove provider',
                                  onPressed: () => _confirmDelete(p),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}