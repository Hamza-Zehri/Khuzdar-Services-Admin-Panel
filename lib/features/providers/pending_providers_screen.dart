import 'package:flutter/material.dart';
import '../../core/models/all_models.dart';
import '../../core/services/admin_firestore_service.dart';
import '../../shared/widgets/badge_widget.dart';
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Provider Approved'), backgroundColor: Colors.green));
  }

  Future<void> _rejectProvider(String id) async {
    // Show dialog for specific reason
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Provider'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason for rejection'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty && mounted) {
      await _firestoreService.rejectProvider(id, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Provider Rejected'), backgroundColor: AppColors.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<ProviderModel>>(
        stream: _firestoreService.streamPendingProviders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final providers = snapshot.data ?? [];

          if (providers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('No pending providers to review!', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24.0),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(provider.type == ProviderType.shop ? '🏪' : '👤'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<UserModel?>(
                              future: _firestoreService.fetchUserInfo(provider.userId),
                              builder: (context, userSnap) {
                                final name = userSnap.data?.name ?? 'Loading...';
                                final phone = userSnap.data?.phone ?? '';
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      provider.type == ProviderType.shop 
                                          ? '${provider.shop?.shopName ?? 'Shop'} ($name)'
                                          : name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    if (phone.isNotEmpty)
                                      Text(phone, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            Text('${provider.category.label} • ${provider.area}', style: const TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      BadgeWidget(text: 'Pending', color: AppColors.accent),

                      const SizedBox(width: 24),
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        tooltip: 'Approve',
                        onPressed: () => _approveProvider(provider.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: AppColors.danger),
                        tooltip: 'Reject',
                        onPressed: () => _rejectProvider(provider.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
