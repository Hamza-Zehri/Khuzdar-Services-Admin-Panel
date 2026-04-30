import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/stats_provider.dart';
import 'badge_widget.dart';

class SidebarNav extends StatelessWidget {
  final Widget child;

  const SidebarNav({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 900;
        return Scaffold(
          drawer: isDesktop ? null : Drawer(child: _buildSidebar(context)),
          appBar: isDesktop
              ? null
              : AppBar(
                  title: const Text('Admin Panel'),
                ),
          body: Row(
            children: [
              if (isDesktop)
                SizedBox(
                  width: 240,
                  child: _buildSidebar(context),
                ),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    
    return Container(
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo Area
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(Icons.admin_panel_settings, color: AppColors.primary, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Khuzdar Admin',
                    style: TextStyle(
                      color: AppColors.sidebarText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Consumer<StatsProvider>(
              builder: (context, statsData, _) {
                final pendingCount = statsData.stats['pendingApprovals'] ?? 0;
                
                return ListView(
                  children: [
                    _NavItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      isSelected: location == '/',
                      onTap: () => context.go('/'),
                    ),
                    _NavItem(
                      icon: Icons.person_add,
                      title: 'Pending Providers',
                      badgeCount: pendingCount,
                      isSelected: location == '/pending-providers',
                      onTap: () => context.go('/pending-providers'),
                    ),
                    _NavItem(
                      icon: Icons.people,
                      title: 'All Providers',
                      isSelected: location == '/providers',
                      onTap: () => context.go('/providers'),
                    ),
                    _NavItem(
                      icon: Icons.manage_accounts,
                      title: 'Users',
                      isSelected: location == '/users',
                      onTap: () => context.go('/users'),
                    ),
                    _NavItem(
                      icon: Icons.chat,
                      title: 'Chats Monitor',
                      isSelected: location == '/chats',
                      onTap: () => context.go('/chats'),
                    ),
                    _NavItem(
                      icon: Icons.campaign,
                      title: 'Notifications',
                      isSelected: location == '/broadcast',
                      onTap: () => context.go('/broadcast'),
                    ),
                    _NavItem(
                      icon: Icons.report,
                      title: 'Reports',
                      isSelected: location == '/reports',
                      onTap: () => context.go('/reports'),
                    ),
                    _NavItem(
                      icon: Icons.category_outlined,
                      title: 'Categories',
                      isSelected: location == '/categories',
                      onTap: () => context.go('/categories'),
                    ),
                    const Divider(color: Colors.white24, height: 32),
                    _NavItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      isSelected: false,
                      onTap: () => Provider.of<AdminAuthProvider>(context, listen: false).signOut(),
                    ),
                  ],
                );
              }
            ),
          ),
          // Bottom admin profile & credits
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Icon(Icons.person, color: AppColors.sidebarText),
                SizedBox(width: 8),
                Text(
                  'Super Admin',
                  style: TextStyle(color: AppColors.sidebarText, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              '© Developed by Engr. Hamza Asad',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 10,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
            border: isSelected ? const Border(left: BorderSide(color: AppColors.primary, width: 4)) : null,
          ),
          padding: EdgeInsets.symmetric(horizontal: isSelected ? 12.0 : 16.0, vertical: 12.0),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.sidebarText.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? AppColors.sidebarText : AppColors.sidebarText.withValues(alpha: 0.7),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
              if (badgeCount > 0)
                BadgeWidget(
                  text: badgeCount.toString(),
                  color: AppColors.accent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
