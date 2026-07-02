import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/main_shell.dart';
import '../screens/dashboard/login_screen.dart';
import '../screens/settings/pin_setup_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/inventory/raw_material_list_screen.dart';
import '../screens/inventory/raw_material_detail_screen.dart';
import '../screens/inventory/raw_material_form_screen.dart';
import '../screens/inventory/finished_good_list_screen.dart';
import '../screens/inventory/finished_good_detail_screen.dart';
import '../screens/inventory/finished_good_form_screen.dart';
import '../screens/bom/bom_list_screen.dart';
import '../screens/bom/bom_form_screen.dart';
import '../screens/production/production_screen.dart';
import '../screens/production/production_history_screen.dart';
import '../screens/inbound/inbound_list_screen.dart';
import '../screens/inbound/inbound_form_screen.dart';
import '../screens/outbound/outbound_list_screen.dart';
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
        
        // Unified inventory route redirecting to raw materials
        GoRoute(
          path: '/inventory',
          redirect: (context, state) => '/inventory/raw-materials',
        ),

        // Raw Materials Routes
        GoRoute(
          path: '/inventory/raw-materials',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: RawMaterialListScreen(),
          ),
          routes: [
            GoRoute(
              path: 'add',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const RawMaterialFormScreen(),
            ),
            GoRoute(
              path: ':id',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return RawMaterialDetailScreen(rawMaterialId: id);
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return RawMaterialFormScreen(rawMaterialId: id);
                  },
                ),
              ],
            ),
          ],
        ),

        // Finished Goods Routes
        GoRoute(
          path: '/inventory/finished-goods',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: FinishedGoodListScreen(),
          ),
          routes: [
            GoRoute(
              path: 'add',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const FinishedGoodFormScreen(),
            ),
            GoRoute(
              path: ':id',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return FinishedGoodDetailScreen(finishedGoodId: id);
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return FinishedGoodFormScreen(finishedGoodId: id);
                  },
                ),
              ],
            ),
          ],
        ),

        // BOM (Bill of Materials) Routes
        GoRoute(
          path: '/inventory/bom',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: BomListScreen(),
          ),
          routes: [
            GoRoute(
              path: 'add',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const BomFormScreen(),
            ),
            GoRoute(
              path: ':id/edit',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return BomFormScreen(bomId: id);
              },
            ),
          ],
        ),

        // Transactions Routes (including inbound/outbound lists and forms)
        GoRoute(
          path: '/transactions',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ActivityListScreen(), // Keep activity list as default transaction page
          ),
          routes: [
            GoRoute(
              path: 'inbound',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const InboundListScreen(),
            ),
            GoRoute(
              path: 'inbound/add',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const InboundFormScreen(),
            ),
            GoRoute(
              path: 'outbound',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const OutboundListScreen(),
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

        // Production Execution & History Routes
        GoRoute(
          path: '/production',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const ProductionScreen(),
        ),
        GoRoute(
          path: '/production/history',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const ProductionHistoryScreen(),
        ),

        // Employees Routes
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

        // More Tab Routes (salary, reports, stats, pin, job-types)
        GoRoute(
          path: '/more',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
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
