import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../core/services/admin_firestore_service.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/data_table_widget.dart';
import '../../shared/widgets/badge_widget.dart';
import '../../shared/widgets/status_display.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/app_colors.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();

  Future<void> _resolveReport(String id) async {
    await _firestoreService.resolveReport(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report marked as resolved')),
    );
  }

  Future<void> _blockReportedUser(String uid, String role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block Reported Entity'),
        content: Text(
          'Block the ${role == 'provider' ? 'provider' : 'user'} account '
          '(${shortId(uid)})?',
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
    await _firestoreService.blockUser(uid);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User blocked'), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Reports',
              subtitle: 'User-submitted reports awaiting review',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firestoreService.streamReports(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return StatusDisplay.loading();
                  }
                  if (snapshot.hasError) {
                    return StatusDisplay.error(detail: '${snapshot.error}');
                  }

                  final reports = snapshot.data ?? [];

                  if (reports.isEmpty) {
                    return StatusDisplay.empty(
                      message: 'No reports yet',
                      detail: 'Everything looks clear',
                    );
                  }

                  return CustomDataTable(
                    minWidth: 720,
                    columns: const [
                      DataColumn2(label: Text('Reporter'), size: ColumnSize.M),
                      DataColumn2(label: Text('Reported ID'), size: ColumnSize.M),
                      DataColumn2(label: Text('Reason'), size: ColumnSize.L),
                      DataColumn2(label: Text('Date'), size: ColumnSize.M),
                      DataColumn2(label: Text('Status'), size: ColumnSize.S),
                      DataColumn2(label: Text('Actions'), fixedWidth: 100),
                    ],
                    rows: reports.map((r) {
                      final status = (r['status'] ?? 'open').toString();
                      final isResolved = status == 'resolved';
                      final rawDate = r['createdAt'];
                      DateTime? ts;
                      if (rawDate is Timestamp) {
                        ts = rawDate.toDate();
                      } else if (rawDate is String) {
                        ts = DateTime.tryParse(rawDate);
                      }

                      return DataRow(
                        color: WidgetStateProperty.all(
                          isResolved ? null : AppColors.accent.withValues(alpha: 0.04),
                        ),
                        cells: [
                          DataCell(Text(r['reporterName'] ?? 'Unknown')),
                          DataCell(
                            Text(shortId(r['reportedUid']?.toString())),
                          ),
                          DataCell(Text(r['reason'] ?? 'No reason provided')),
                          DataCell(Text(formatDate(ts))),
                          DataCell(
                            BadgeWidget(
                              text: capitalize(status),
                              color: isResolved ? AppColors.success : AppColors.accent,
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isResolved)
                                  IconButton(
                                    icon: const Icon(Icons.check_circle_outline_rounded,
                                        color: AppColors.success),
                                    tooltip: 'Mark resolved',
                                    onPressed: () => _resolveReport(r['id']),
                                  ),
                                if (!isResolved)
                                  IconButton(
                                    icon: const Icon(Icons.block_rounded,
                                        color: AppColors.danger),
                                    tooltip: 'Block reported entity',
                                    onPressed: () =>
                                        _blockReportedUser(r['reportedUid'].toString(), 'user'),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}