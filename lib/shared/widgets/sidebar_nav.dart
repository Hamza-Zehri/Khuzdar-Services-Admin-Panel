import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/stats_provider.dart';
import '../../providers/admin_auth_provider.dart';
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
          drawer: isDesktop ? null : Drawer(backgroundColor: AppColors.sidebarBgStart, child: _buildSidebar(context)),
          appBar: isDesktop
              ? null
              : AppBar(
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu_rounded),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  title: const Text('Khuzdar Admin'),
                ),
          body: Row(
            children: [
              if (isDesktop)
                SizedBox(
                  width: 264,
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.sidebarBgStart, AppColors.sidebarBgEnd],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Brand
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Khuzdar Admin',
                          style: TextStyle(
                            color: AppColors.sidebarText,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Service Marketplace',
                          style: TextStyle(
                            color: AppColors.sidebarMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.borderDark, thickness: 1),
            const SizedBox(height: 8),
            Expanded(
              child: Consumer<StatsProvider>(
                builder: (context, statsData, _) {
                  final pendingCount = statsData.stats['pendingApprovals'] ?? 0;

                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _NavItem(
                        icon: Icons.dashboard_outlined,
                        selectedIcon: Icons.dashboard_rounded,
                        title: 'Dashboard',
                        isSelected: location == '/',
                        onTap: () => context.go('/'),
                      ),
                      _NavItem(
                        icon: Icons.person_add_alt_1_outlined,
                        selectedIcon: Icons.person_add_alt_1_rounded,
                        title: 'Pending Providers',
                        badgeCount: pendingCount,
                        isSelected: location == '/pending-providers',
                        onTap: () => context.go('/pending-providers'),
                      ),
                      _NavItem(
                        icon: Icons.groups_outlined,
                        selectedIcon: Icons.groups_rounded,
                        title: 'All Providers',
                        isSelected: location == '/providers',
                        onTap: () => context.go('/providers'),
                      ),
                      _NavItem(
                        icon: Icons.manage_accounts_outlined,
                        selectedIcon: Icons.manage_accounts_rounded,
                        title: 'Users',
                        isSelected: location == '/users',
                        onTap: () => context.go('/users'),
                      ),
                      _NavItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        selectedIcon: Icons.chat_bubble_rounded,
                        title: 'Chats Monitor',
                        isSelected: location == '/chats',
                        onTap: () => context.go('/chats'),
                      ),
                      _NavItem(
                        icon: Icons.campaign_outlined,
                        selectedIcon: Icons.campaign_rounded,
                        title: 'Notifications',
                        isSelected: location == '/broadcast',
                        onTap: () => context.go('/broadcast'),
                      ),
                      _NavItem(
                        icon: Icons.report_outlined,
                        selectedIcon: Icons.report_rounded,
                        title: 'Reports',
                        isSelected: location == '/reports',
                        onTap: () => context.go('/reports'),
                      ),
                      _NavItem(
                        icon: Icons.category_outlined,
                        selectedIcon: Icons.category_rounded,
                        title: 'Categories',
                        isSelected: location == '/categories',
                        onTap: () => context.go('/categories'),
                      ),
                      const Divider(color: AppColors.borderDark, height: 24),
                      _NavItem(
                        icon: Icons.logout_rounded,
                        title: 'Logout',
                        isSelected: false,
                        onTap: () => Provider.of<AdminAuthProvider>(context, listen: false).signOut(),
                      ),
                    ],
                  );
                },
              ),
            ),
            // Admin card + credits
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.shield_rounded, size: 18, color: Color(0xFF06251C)),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Super Admin',
                          style: TextStyle(
                            color: AppColors.sidebarText,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Full access',
                          style: TextStyle(color: AppColors.sidebarMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                '© Developed by Engr. Hamza Asad',
                style: TextStyle(
                  color: AppColors.sidebarMuted,
                  fontSize: 10,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    this.selectedIcon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: Colors.white.withValues(alpha: 0.05),
          splashColor: Colors.white.withValues(alpha: 0.08),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? const Border(left: BorderSide(color: AppColors.primaryLight, width: 3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? (selectedIcon ?? icon) : icon,
                  color: isSelected ? AppColors.primaryLight : AppColors.sidebarMuted,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.sidebarText : AppColors.sidebarMuted,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
      ),
    );
  }
}