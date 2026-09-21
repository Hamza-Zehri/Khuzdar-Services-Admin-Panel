import 'package:flutter/material.dart';
import '../../core/models/all_models.dart';
import '../../core/services/admin_firestore_service.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/badge_widget.dart';
import '../../shared/widgets/status_display.dart';
import '../../core/constants/app_colors.dart';

class PendingProvidersScreen extends StatefulWidget {
  const PendingProvidersScreen({super.key});

  @override
  State<PendingProvidersScreen> createState() => _PendingProvidersScreenState();
}

class _PendingProvidersScreenState extends State<PendingProvidersScreen> {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();

  Future<void> _approveProvider(String id) async {
    await _firestoreService.approveProvider(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Provider approved')),
    );
  }

  Future<void> _rejectProvider(String id) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Provider'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Required — this is shared with the provider',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a reason')),
                );
                return;
              }
              Navigator.pop(context, text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (reason != null && mounted) {
      await _firestoreService.rejectProvider(id, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Provider rejected'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: PageHeader(
              title: 'Pending Approvals',
              subtitle: 'Review and approve new service providers',
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<ProviderModel>>(
              stream: _firestoreService.streamPendingProviders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return StatusDisplay.loading();
                }
                if (snapshot.hasError) {
                  return StatusDisplay.error(detail: '${snapshot.error}');
                }

                final providers = snapshot.data ?? [];

                if (providers.isEmpty) {
                  return StatusDisplay.empty(
                    message: 'No pending providers to review',
                    detail: 'New sign-ups will appear here automatically',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final provider = providers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                provider.type == ProviderType.shop ? '🏪' : '👤',
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FutureBuilder<UserModel?>(
                                future: _firestoreService.fetchUserInfo(provider.userId),
                                builder: (context, userSnap) {
                                  final name = userSnap.data?.name ?? '…';
                                  final phone = userSnap.data?.phone ?? '';
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        provider.type == ProviderType.shop
                                            ? '${provider.shop?.shopName ?? 'Shop'} ($name)'
                                            : name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (phone.isNotEmpty)
                                        Text(
                                          phone,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${provider.category.label} • ${provider.area}',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            const BadgeWidget(text: 'PENDING', color: AppColors.accent),
                            const SizedBox(width: 12),
                            TextButton.icon(
                              onPressed: () => _approveProvider(provider.id),
                              icon: const Icon(Icons.check_circle_outline_rounded,
                                  color: AppColors.success, size: 19),
                              label: const Text('Approve',
                                  style: TextStyle(color: AppColors.success)),
                            ),
                            const SizedBox(width: 4),
                            TextButton.icon(
                              onPressed: () => _rejectProvider(provider.id),
                              icon: const Icon(Icons.cancel_outlined,
                                  color: AppColors.danger, size: 19),
                              label: const Text('Reject',
                                  style: TextStyle(color: AppColors.danger)),
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
    );
  }
}