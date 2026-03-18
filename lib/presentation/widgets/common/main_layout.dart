// lib/presentation/widgets/common/main_layout.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weshah/presentation/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    if (isWide) {
      return _DesktopLayout(child: child);
    }
    return _MobileLayout(child: child);
  }
}

class _DesktopLayout extends StatelessWidget {
  final Widget child;
  const _DesktopLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _SideNavigation(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final Widget child;
  const _MobileLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child, bottomNavigationBar: _BottomNavigation());
  }
}

class _SideNavigation extends ConsumerWidget {
  final _navItems = const [
    _NavItem(
      icon: Icons.dashboard_rounded,
      label: 'لوحة التحكم',
      route: '/dashboard',
    ),
    _NavItem(icon: Icons.people_rounded, label: 'العملاء', route: '/customers'),
    _NavItem(
      icon: Icons.assignment_rounded,
      label: 'الطلبات',
      route: '/orders',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.asData?.value;

    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 8)],
      ),
      child: Column(
        children: [
          // معلومات المستخدم أعلى الشعار
          if (profile != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName,
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: profile.isAdmin ? Colors.green : Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            profile.isAdmin ? 'مدير' : 'موظف',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Logo/Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'وشاح',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'نظام إدارة الطلبات',
                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          // Nav Items
          ..._navItems.map((item) {
            final isActive = location.startsWith(item.route);
            return _SideNavItem(item: item, isActive: isActive);
          }),
          const Spacer(),
          // زر الملف الشخصي وتغيير كلمة المرور
          if (profile != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              child: Material(
                color: location.startsWith('/profile')
                    ? Colors.white.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context.go('/profile'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.manage_accounts_rounded,
                          color: location.startsWith('/profile')
                              ? Colors.white
                              : Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'الملف الشخصي',
                          style: GoogleFonts.cairo(
                            color: location.startsWith('/profile')
                                ? Colors.white
                                : Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          // زر إدارة المستخدمين للمدير فقط
          if (profile != null && profile.isAdmin) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Material(
                color: location.startsWith('/users')
                    ? Colors.white.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context.go('/users'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.manage_accounts,
                          color: location.startsWith('/users')
                              ? Colors.white
                              : Colors.white54,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'إدارة المستخدمين',
                          style: GoogleFonts.cairo(
                            color: location.startsWith('/users')
                                ? Colors.white
                                : Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Text(
              'v1.0.0',
              style: GoogleFonts.cairo(color: Colors.white38, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;

  const _SideNavItem({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.go(item.route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isActive ? Colors.white : Colors.white70,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: GoogleFonts.cairo(
                    color: isActive ? Colors.white : Colors.white70,
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppTheme.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return NavigationBar(
      backgroundColor: AppTheme.primaryColor,
      indicatorColor: Colors.white.withOpacity(0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return GoogleFonts.cairo(
          color: Colors.white,
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.bold
              : FontWeight.normal,
        );
      }),
      selectedIndex: _getIndex(location),
      onDestinationSelected: (i) {
        switch (i) {
          case 0:
            context.go('/dashboard');
            break;
          case 1:
            context.go('/customers');
            break;
          case 2:
            context.go('/orders');
            break;
          case 3:
            context.go('/profile');
            break;
        }
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.dashboard_rounded, color: Colors.white70),
          selectedIcon: const Icon(
            Icons.dashboard_rounded,
            color: Colors.white,
          ),
          label: 'لوحة التحكم',
        ),
        NavigationDestination(
          icon: const Icon(Icons.people_rounded, color: Colors.white70),
          selectedIcon: const Icon(Icons.people_rounded, color: Colors.white),
          label: 'العملاء',
        ),
        NavigationDestination(
          icon: const Icon(Icons.assignment_rounded, color: Colors.white70),
          selectedIcon: const Icon(
            Icons.assignment_rounded,
            color: Colors.white,
          ),
          label: 'الطلبات',
        ),
        NavigationDestination(
          icon: const Icon(
            Icons.account_circle_outlined,
            color: Colors.white70,
          ),
          selectedIcon: const Icon(
            Icons.account_circle_rounded,
            color: Colors.white,
          ),
          label: 'حسابي',
        ),
      ],
    );
  }

  int _getIndex(String location) {
    if (location.startsWith('/customers')) return 1;
    if (location.startsWith('/orders')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
