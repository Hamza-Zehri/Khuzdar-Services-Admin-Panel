import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../core/models/all_models.dart';
import '../../core/services/admin_firestore_service.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/data_table_widget.dart';
import '../../shared/widgets/status_display.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/app_colors.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();

  Future<void> _deleteRating(RatingModel rating) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Rating?'),
        content: Text(
          'Remove this ${rating.rating.toStringAsFixed(1)}-star rating by '
          '${shortId(rating.fromUserId)} against ${shortId(rating.toUserId)}?\n\n'
          'This will remove the review and the provider stats will be '
          'recomputed on their next rating.',
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
    await _firestoreService.deleteRating(rating.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rating deleted (${shortId(rating.id)})')),
    );
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
              title: 'Reviews',
              subtitle: 'All ratings between customers and providers',
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<RatingModel>>(
              stream: _firestoreService.streamAllRatings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return StatusDisplay.loading();
                }
                if (snapshot.hasError) {
                  return StatusDisplay.error(detail: '${snapshot.error}');
                }

                final ratings = snapshot.data ?? [];
                if (ratings.isEmpty) {
                  return StatusDisplay.empty(
                    message: 'No reviews yet',
                    detail: 'Ratings appear here once completed jobs are rated',
                  );
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: CustomDataTable(
                    minWidth: 860,
                    columns: const [
                      DataColumn2(label: Text('From'), size: ColumnSize.L),
                      DataColumn2(label: Text('To'), size: ColumnSize.L),
                      DataColumn2(label: Text('Rating'), size: ColumnSize.S),
                      DataColumn2(label: Text('Comment'), size: ColumnSize.L),
                      DataColumn2(label: Text('Date'), size: ColumnSize.M),
                      DataColumn2(
                        label: Text('Actions'),
                        fixedWidth: 80,
                      ),
                    ],
                    rows: ratings.map((r) {
                      return DataRow(
                        color: WidgetStateProperty.all(
                          r.rating <= 2
                              ? AppColors.danger.withValues(alpha: 0.05)
                              : null,
                        ),
                        cells: [
                          DataCell(
                            _UserCell(userId: r.fromUserId, fallback: 'Customer'),
                          ),
                          DataCell(
                            _UserCell(userId: r.toUserId, fallback: 'Provider'),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 18, color: AppColors.accent),
                                const SizedBox(width: 4),
                                Text(r.rating.toStringAsFixed(1)),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              (r.comment ?? '').isEmpty
                                  ? '—'
                                  : r.comment!,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DataCell(Text(formatDate(r.createdAt))),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: AppColors.danger),
                              tooltip: 'Delete rating',
                              onPressed: () => _deleteRating(r),
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

class _UserCell extends StatelessWidget {
  final String userId;
  final String fallback;

  const _UserCell({required this.userId, required this.fallback});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: AdminFirestoreService().fetchUserInfo(userId),
      builder: (context, snap) {
        final name = snap.data?.name;
        if (name == null || name.isEmpty) {
          return Text(fallback);
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              shortId(userId),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}