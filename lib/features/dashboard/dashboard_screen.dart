import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/stats_provider.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/stat_card.dart';
import '../../core/constants/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Dashboard Overview',
              subtitle: 'Real-time statistics for the Khuzdar marketplace',
            ),
            const SizedBox(height: 24),
            Consumer<StatsProvider>(
              builder: (context, statsData, _) {
                final stats = statsData.stats;
                final cols = MediaQuery.of(context).size.width > 1200
                    ? 4
                    : (MediaQuery.of(context).size.width > 800 ? 2 : 1);
                return GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: cols == 1 ? 2.4 : 2.2,
                  children: [
                    StatCard(
                      title: 'Total Users',
                      value: stats['totalUsers'].toString(),
                      icon: Icons.people_alt_rounded,
                      accentColor: AppColors.primary,
                    ),
                    StatCard(
                      title: 'Total Providers',
                      value: stats['totalProviders'].toString(),
                      icon: Icons.storefront_rounded,
                      accentColor: AppColors.info,
                    ),
                    StatCard(
                      title: 'Pending Approvals',
                      value: stats['pendingApprovals'].toString(),
                      icon: Icons.pending_actions_rounded,
                      accentColor: (stats['pendingApprovals'] ?? 0) > 0
                          ? AppColors.accent
                          : AppColors.textMuted,
                    ),
                    StatCard(
                      title: 'Active Chats',
                      value: stats['activeChats'].toString(),
                      icon: Icons.forum_rounded,
                      accentColor: AppColors.success,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1000;
                final pipeline = _buildPipeline(context);
                final actions = _buildQuickActions(context);
                if (!isWide) {
                  return Column(
                    children: [pipeline, const SizedBox(height: 16), actions],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: pipeline),
                    const SizedBox(width: 16),
                    Expanded(flex: 1, child: actions),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipeline(BuildContext context) {
    return Consumer<StatsProvider>(
      builder: (context, statsData, _) {
        final stats = statsData.stats;
        final total = (stats['totalProviders'] ?? 0);
        final pending = (stats['pendingApprovals'] ?? 0).clamp(0, total);
        final approved = (total - pending).clamp(0, total);
        final progress = total > 0 ? approved / total : 0.0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Provider Verification',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Live progress across the provider pipeline',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$approved',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'of $total providers approved',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: AppColors.surfaceAlt,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _LegendDot(color: AppColors.primary, label: '$approved approved'),
                  const Spacer(),
                  _LegendDot(color: AppColors.accent, label: '$pending pending'),
                ],
              ),
              const Divider(height: 32),
              _buildMetricRow(
                icon: Icons.people_alt_rounded,
                color: AppColors.primary,
                label: 'Total registered users',
                value: '${stats['totalUsers'] ?? 0}',
              ),
              _buildMetricRow(
                icon: Icons.forum_rounded,
                color: AppColors.success,
                label: 'Active chats right now',
                value: '${stats['activeChats'] ?? 0}',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Shortcuts to common admin tasks',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.verified_user_outlined,
            color: AppColors.primary,
            title: 'Approve providers',
            trailing: 'Pending queue',
            onTap: () => context.go('/pending-providers'),
          ),
          _ActionTile(
            icon: Icons.campaign_outlined,
            color: AppColors.accent,
            title: 'Send notification',
            trailing: 'Push + in-app',
            onTap: () => context.go('/broadcast'),
          ),
          _ActionTile(
            icon: Icons.category_outlined,
            color: AppColors.info,
            title: 'Manage categories',
            trailing: 'Create / edit',
            onTap: () => context.go('/categories'),
          ),
          _ActionTile(
            icon: Icons.flag_outlined,
            color: AppColors.danger,
            title: 'View reports',
            trailing: 'Open cases',
            onTap: () => context.go('/reports'),
          ),
          _ActionTile(
            icon: Icons.forum_outlined,
            color: AppColors.success,
            title: 'Monitor chats',
            trailing: 'Live',
            onTap: () => context.go('/chats'),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: AppColors.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (trailing != null)
                      Text(
                        trailing!,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}