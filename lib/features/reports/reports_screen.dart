import 'package:flutter/material.dart';
import '../../core/services/admin_firestore_service.dart';
import '../../shared/widgets/data_table_widget.dart';
import '../../shared/widgets/badge_widget.dart';
import '../../core/constants/app_colors.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();

  void _resolveReport(String id) async {
    await _firestoreService.resolveReport(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report Marked as Resolved'), backgroundColor: Colors.green));
  }

  void _blockReportedUser(String uid, String role) async {
    // Assuming we could pass role to block either provider or user
    // For now we assume the reported party might map to a generic block.
    // In our service we split provider/user block. We'll do a basic check here or use User.
    // Let's assume it blocks them as a user.
    await _firestoreService.blockUser(uid);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User Blocked'), backgroundColor: AppColors.danger));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firestoreService.streamReports(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

            final reports = snapshot.data ?? [];

            if (reports.isEmpty) {
              return const Center(child: Text('No reports exist.', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)));
            }

            return CustomDataTable(
              columns: const [
                DataColumn(label: Text('Reporter Name')),
                DataColumn(label: Text('Reported UID')),
                DataColumn(label: Text('Reason')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: reports.map((r) {
                final status = r['status'] ?? 'open';
                final isResolved = status == 'resolved';
                final date = r['createdAt'] != null ? r['createdAt'].toDate().toString() : '';

                return DataRow(
                  color: MaterialStateProperty.all(isResolved ? null : AppColors.accent.withOpacity(0.05)),
                  cells: [
                    DataCell(Text(r['reporterName'] ?? 'Unknown')),
                    DataCell(Text((r['reportedUid'] ?? 'Unknown').toString().substring(0, 8))), // Should have real id
                    DataCell(Text(r['reason'] ?? 'No reason provided')),
                    DataCell(Text(date)),
                    DataCell(
                      BadgeWidget(
                        text: status.toUpperCase(),
                        color: isResolved ? Colors.green : AppColors.accent,
                      )
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (!isResolved)
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              tooltip: 'Mark Resolved',
                              onPressed: () => _resolveReport(r['id']),
                            ),
                          if (!isResolved)
                            IconButton(
                              icon: const Icon(Icons.block, color: AppColors.danger),
                              tooltip: 'Block Reported Entity',
                              onPressed: () => _blockReportedUser(r['reportedUid'], 'user'),
                            ),
                        ],
                      )
                    ),
                  ]
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
