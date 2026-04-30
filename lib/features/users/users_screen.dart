import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../core/models/all_models.dart';
import '../../core/services/admin_firestore_service.dart';
import '../../shared/widgets/data_table_widget.dart';
import '../../shared/widgets/badge_widget.dart';
import '../../core/constants/app_colors.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();
  String _searchQuery = '';
  final Map<String, String> _revealedPhones = {};

  void _toggleBlock(UserModel user) async {
    if (user.isBlocked) {
      await _firestoreService.unblockUser(user.id);
    } else {
      await _firestoreService.blockUser(user.id);
    }
  }

  void _revealPhone(String userId) async {
    final phone = await _firestoreService.revealPhone(userId);
    setState(() {
      _revealedPhones[userId] = phone;
    });
  }

  void _deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to permanently delete "${user.name.isEmpty ? user.id.substring(0, 8) : user.name}"?\n\nThis will also remove their provider profile. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _firestoreService.deleteUser(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by name',
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
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _firestoreService.streamAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var users = snapshot.data ?? [];
                
                if (_searchQuery.isNotEmpty) {
                  users = users.where((u) => u.name.toLowerCase().contains(_searchQuery)).toList();
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                            : (isLowRating ? AppColors.danger.withValues(alpha: 0.05) : null)
                        ),
                        cells: [
                          DataCell(Text(u.name.isEmpty ? 'ID: ${u.id.substring(0, 8)}' : u.name)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: Text(
                                    _revealedPhones[u.id] ?? (u.phone.isEmpty ? 'No Phone' : u.maskedPhone),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!_revealedPhones.containsKey(u.id) && u.phone.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.visibility, size: 16),
                                    onPressed: () => _revealPhone(u.id),
                                  )
                              ],
                            )
                          ),
                          DataCell(Text(u.rating.toStringAsFixed(1))),
                          DataCell(Text(u.role.name)),
                          DataCell(
                            BadgeWidget(
                              text: u.isBlocked ? 'Blocked' : 'Active',
                              color: u.isBlocked ? AppColors.danger : Colors.green,
                            )
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (u.role != UserRole.admin)
                                  IconButton(
                                    icon: Icon(
                                      u.isBlocked ? Icons.lock_open : Icons.block,
                                      color: u.isBlocked ? Colors.green : AppColors.danger,
                                    ),
                                    tooltip: u.isBlocked ? 'Unblock' : 'Block',
                                    onPressed: () => _toggleBlock(u),
                                  ),
                                if (u.role != UserRole.admin)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                    tooltip: 'Delete User',
                                    onPressed: () => _deleteUser(u),
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
