import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/main_shell.dart';
import '../screens/dashboard/login_screen.dart';
import '../screens/settings/pin_setup_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/inventory/product_list_screen.dart';
import '../screens/inventory/product_detail_screen.dart';
import '../screens/inventory/product_form_screen.dart';
import '../screens/inbound/inbound_form_screen.dart';
import '../screens/outbound/outbound_form_screen.dart';
import '../screens/employees/employee_list_screen.dart';
import '../screens/employees/employee_form_screen.dart';
import '../screens/activities/activity_list_screen.dart';
import '../screens/activities/activity_form_screen.dart';
import '../screens/salary/salary_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/reports/stats_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/job_type_form_screen.dart';
import '../services/auth_service.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/dashboard',
  redirect: (context, state) {
    final hasPin = AuthService.hasPinSetup();
    final isGoingToSetup = state.matchedLocation == '/setup-pin';
    
    if (!hasPin) {
      return isGoingToSetup ? null : '/setup-pin';
    }

    // Simple auth check state (we will hook it up with auth provider later)
    // For now we check if going to login or setup
    return null;
  },
  routes: [
    GoRoute(
      path: '/setup-pin',
      builder: (context, state) => const PinSetupScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    
    // Bottom Navigation Shell Route
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/inventory',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProductListScreen(),
          ),
          routes: [
            GoRoute(
              path: 'add',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const ProductFormScreen(),
            ),
            GoRoute(
              path: ':id',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) {
                final productId = state.pathParameters['id']!;
                return ProductDetailScreen(productId: productId);
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final productId = state.pathParameters['id']!;
                    return ProductFormScreen(productId: productId);
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/transactions',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ActivityListScreen(), // Under BottomNav tab: Histori
          ),
          routes: [
            GoRoute(
              path: 'inbound/add',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const InboundFormScreen(),
            ),
            GoRoute(
              path: 'outbound/add',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const OutboundFormScreen(),
            ),
            GoRoute(
              path: 'activity/add',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) {
                final empId = state.uri.queryParameters['employeeId'];
                return ActivityFormScreen(preselectedEmployeeId: empId);
              },
            ),
            GoRoute(
              path: 'activity/:id/edit',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) {
                final activityId = state.pathParameters['id']!;
                return ActivityFormScreen(activityId: activityId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/employees',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: EmployeeListScreen(),
          ),
          routes: [
            GoRoute(
              path: 'add',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const EmployeeFormScreen(),
            ),
            GoRoute(
              path: ':id/edit',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) {
                final employeeId = state.pathParameters['id']!;
                return EmployeeFormScreen(employeeId: employeeId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/more',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(), // Profil / Settings / More screen
          ),
          routes: [
            GoRoute(
              path: 'salary',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const SalaryScreen(),
            ),
            GoRoute(
              path: 'reports',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const ReportsScreen(),
            ),
            GoRoute(
              path: 'stats',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const StatsScreen(),
            ),
            GoRoute(
              path: 'job-types/add',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const JobTypeFormScreen(),
            ),
            GoRoute(
              path: 'job-types/:id/edit',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) {
                final jobTypeId = state.pathParameters['id']!;
                return JobTypeFormScreen(jobTypeId: jobTypeId);
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
