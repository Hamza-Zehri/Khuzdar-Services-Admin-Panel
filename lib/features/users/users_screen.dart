import 'package:flutter/material.dart';
import '../../core/models/all_models.dart';
import '../../core/services/admin_firestore_service.dart';
import '../../shared/widgets/data_table_widget.dart';
import '../../shared/widgets/badge_widget.dart';
import '../../core/constants/app_colors.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();
  String _searchQuery = '';
  Map<String, String> _revealedPhones = {};

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
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Phone')),
                      DataColumn(label: Text('Rating')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: users.map((u) {
                      final isLowRating = u.rating < 2.0 && u.rating > 0;
                      return DataRow(
                        color: MaterialStateProperty.all(
                          u.isBlocked 
                            ? AppColors.background 
                            : (isLowRating ? AppColors.danger.withOpacity(0.05) : null)
                        ),
                        cells: [
                          DataCell(Text(u.name)),
                          DataCell(
                            Row(
                              children: [
                                Text(_revealedPhones[u.id] ?? '***-****'),
                                if (!_revealedPhones.containsKey(u.id))
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
                              children: [
                                if (u.role != 'admin')
                                IconButton(
                                  icon: Icon(u.isBlocked ? Icons.lock_open : Icons.block, color: u.isBlocked ? Colors.green : AppColors.danger),
                                  tooltip: u.isBlocked ? 'Unblock' : 'Block',
                                  onPressed: () => _toggleBlock(u),
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
