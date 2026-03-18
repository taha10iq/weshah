// lib/core/router/app_router.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/customers/customers_screen.dart';
import '../../presentation/screens/customers/customer_form_screen.dart';
import '../../presentation/screens/customers/customer_detail_screen.dart';
import '../../presentation/screens/orders/orders_screen.dart';
import '../../presentation/screens/orders/order_form_screen.dart';
import '../../presentation/screens/orders/order_detail_screen.dart';
import '../../presentation/screens/about/about_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/widgets/common/main_layout.dart';
import '../../features/users/pages/user_management_page.dart';

// ── تمرير ProviderContainer لاستخدامه داخل redirect ────────────────
GoRouter createRouter(ProviderContainer container) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: _AuthNotifierListenable(container),
    redirect: (context, state) {
      // نقرأ مباشرة من authNotifierProvider (public.users)
      final authState = container.read(authNotifierProvider);
      final loggedIn = authState.valueOrNull != null;
      final goingToLogin = state.matchedLocation == '/login';

      if (!loggedIn && !goingToLogin) return '/login';
      if (loggedIn && goingToLogin) return '/dashboard';
      return null;
    },
    routes: [
      // ── صفحة تسجيل الدخول (خارج ShellRoute) ────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      // ── الصفحات الرئيسية داخل Shell ─────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/customers',
            name: 'customers',
            builder: (context, state) => const CustomersScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'customer-new',
                builder: (context, state) => const CustomerFormScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'customer-detail',
                builder: (context, state) => CustomerDetailScreen(
                  customerId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'customer-edit',
                    builder: (context, state) => CustomerFormScreen(
                      customerId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (context, state) => const OrdersScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'order-new',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return OrderFormScreen(
                    preselectedCustomerId: extra?['customerId'] as String?,
                  );
                },
              ),
              GoRoute(
                path: ':id',
                name: 'order-detail',
                builder: (context, state) =>
                    OrderDetailScreen(orderId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'order-edit',
                    builder: (context, state) =>
                        OrderFormScreen(orderId: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/about',
            name: 'about',
            builder: (context, state) => const AboutScreen(),
          ),
          GoRoute(
            path: '/users',
            name: 'users',
            builder: (context, state) => const UserManagementPage(),
          ),
        ],
      ),
    ],
  );
}

// ── يخبر GoRouter بإعادة التقييم كلما تغيرت حالة المصادقة ──────────
class _AuthNotifierListenable extends ChangeNotifier {
  _AuthNotifierListenable(ProviderContainer container) {
    container.listen<AsyncValue>(
      authNotifierProvider,
      (_, __) => notifyListeners(),
    );
  }
}
