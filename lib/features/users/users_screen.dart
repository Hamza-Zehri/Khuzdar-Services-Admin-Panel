import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../core/models/all_models.dart';
import '../../core/services/admin_firestore_service.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/data_table_widget.dart';
import '../../shared/widgets/badge_widget.dart';
import '../../shared/widgets/status_display.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();
  String _searchQuery = '';
  final Map<String, String> _revealedPhones = {};

  Future<void> _toggleBlock(UserModel user) async {
    final action = user.isBlocked ? 'unblock' : 'block';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user.isBlocked ? 'Unblock User' : 'Block User'),
        content: Text(
          'Are you sure you want to $action "${user.name.isEmpty ? shortId(user.id) : user.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isBlocked ? AppColors.success : AppColors.danger,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(user.isBlocked ? 'Unblock' : 'Block'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    if (user.isBlocked) {
      await _firestoreService.unblockUser(user.id);
    } else {
      await _firestoreService.blockUser(user.id);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(user.isBlocked ? 'User unblocked' : 'User blocked'),
          backgroundColor: user.isBlocked ? Colors.green : AppColors.danger,
        ),
      );
    }
  }

  Future<void> _revealPhone(String userId) async {
    final phone = await _firestoreService.revealPhone(userId);
    if (!mounted) return;
    setState(() {
      _revealedPhones[userId] = phone;
    });
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to permanently delete "${user.name.isEmpty ? shortId(user.id) : user.name}"?\n\n'
          'This will also remove their provider profile. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _firestoreService.deleteUser(user.id);
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
              title: 'All Users',
              subtitle: 'Search, manage and monitor registered users',
              trailing: SizedBox(
                width: 320,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by name…',
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
            child: StreamBuilder<List<UserModel>>(
              stream: _firestoreService.streamAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return StatusDisplay.loading();
                }
                if (snapshot.hasError) {
                  return StatusDisplay.error(detail: '${snapshot.error}');
                }

                var users = snapshot.data ?? [];
                if (_searchQuery.isNotEmpty) {
                  users = users
                      .where((u) => u.name.toLowerCase().contains(_searchQuery))
                      .toList();
                }

                if (users.isEmpty) {
                  return StatusDisplay.empty(
                    message: _searchQuery.isNotEmpty
                        ? 'No users match your search'
                        : 'No users yet',
                    detail: _searchQuery.isNotEmpty
                            ? 'Try a different name'
                            : 'Users will appear here once they sign up',
                  );
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: CustomDataTable(
                    columns: const [
                      DataColumn2(label: Text('Name'), size: ColumnSize.L),
                      DataColumn2(label: Text('Phone'), size: ColumnSize.L),
                      DataColumn2(label: Text('Rating'), size: ColumnSize.S),
                      DataColumn2(label: Text('Role'), size: ColumnSize.S),
                      DataColumn2(label: Text('Status'), size: ColumnSize.S),
                      DataColumn2(label: Text('Actions'), size: ColumnSize.M),
                    ],
                    rows: users.map((u) {
                      final isLowRating = u.rating < 2.0 && u.rating > 0;
                      return DataRow(
                        color: WidgetStateProperty.all(
                          u.isBlocked
                              ? AppColors.background
                              : (isLowRating
                                    ? AppColors.danger.withValues(alpha: 0.05)
                                    : null),
                        ),
                        cells: [
                          DataCell(
                            Text(
                              u.name.isEmpty ? 'ID: ${shortId(u.id)}' : u.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    _revealedPhones[u.id] ??
                                        (u.phone.isEmpty
                                            ? 'No phone'
                                            : u.maskedPhone),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!_revealedPhones.containsKey(u.id) &&
                                    u.phone.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(
                                        Icons.visibility_outlined,
                                        size: 17),
                                    color: AppColors.textSecondary,
                                    tooltip: 'Reveal phone number',
                                    onPressed: () => _revealPhone(u.id),
                                  ),
                              ],
                            ),
                          ),
                          DataCell(Text(u.rating.toStringAsFixed(1))),
                          DataCell(Text(capitalize(u.role.name))),
                          DataCell(
                            BadgeWidget(
                              text: u.isBlocked ? 'Blocked' : 'Active',
                              color: u.isBlocked
                                  ? AppColors.danger
                                  : AppColors.success,
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (u.role != UserRole.admin)
                                  IconButton(
                                    icon: Icon(
                                      u.isBlocked
                                          ? Icons.lock_open_rounded
                                          : Icons.block_rounded,
                                      color: u.isBlocked
                                          ? AppColors.success
                                          : AppColors.danger,
                                    ),
                                    tooltip: u.isBlocked ? 'Unblock' : 'Block',
                                    onPressed: () => _toggleBlock(u),
                                  ),
                                if (u.role != UserRole.admin)
                                  IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppColors.danger),
                                    tooltip: 'Delete user',
                                    onPressed: () => _deleteUser(u),
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