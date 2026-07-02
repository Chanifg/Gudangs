import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/main_shell.dart';
import '../screens/dashboard/login_screen.dart';
import '../screens/settings/pin_setup_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/inventory/raw_material_detail_screen.dart';
import '../screens/inventory/raw_material_form_screen.dart';
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
import '../screens/settings/edit_profile_screen.dart';
import '../screens/settings/stock_adjustment_screen.dart';
import '../screens/settings/audit_log_screen.dart';
import '../services/auth_service.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        if (previous?.isAuthenticated != next.isAuthenticated || previous?.hasPin != next.hasPin) {
          notifyListeners();
        }
      },
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final hasPin = authState.hasPin;
      final isAuthenticated = authState.isAuthenticated;

      final isGoingToSetup = state.matchedLocation == '/setup-pin';
      final isGoingToLogin = state.matchedLocation == '/login';

      if (!hasPin) {
        return isGoingToSetup ? null : '/setup-pin';
      }

      if (!isAuthenticated) {
        return (isGoingToLogin || isGoingToSetup) ? null : '/login';
      }

      // If authenticated and trying to go to login/setup, redirect to dashboard
      if (isGoingToLogin || isGoingToSetup) {
        return '/dashboard';
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
    
    // Bottom Navigation Shell Route (Only for tabs that show bottom bar)
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
        
        // Unified inventory tab showing Tabbed InventoryScreen
        GoRoute(
          path: '/inventory',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: InventoryScreen(),
          ),
        ),

        // BOM (Bill of Materials) Routes
        GoRoute(
          path: '/inventory/bom',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: BomListScreen(),
          ),
        ),

        // Transactions Routes
        GoRoute(
          path: '/transactions',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ActivityListScreen(),
          ),
        ),

        // Employees Routes
        GoRoute(
          path: '/employees',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: EmployeeListScreen(),
          ),
        ),

        // More Tab Routes
        GoRoute(
          path: '/more',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),

    // =========================================================================
    // Root-level Routes (Full screen pages that cover the Bottom Tab Bar)
    // =========================================================================

    // Raw Materials Sub-pages
    GoRoute(
      path: '/inventory/raw-materials/add',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const RawMaterialFormScreen(),
    ),
    GoRoute(
      path: '/inventory/raw-materials/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return RawMaterialDetailScreen(materialId: id);
      },
    ),
    GoRoute(
      path: '/inventory/raw-materials/:id/edit',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return RawMaterialFormScreen(materialId: id);
      },
    ),

    // Finished Goods Sub-pages
    GoRoute(
      path: '/inventory/finished-goods/add',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const FinishedGoodFormScreen(),
    ),
    GoRoute(
      path: '/inventory/finished-goods/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return FinishedGoodDetailScreen(finishedGoodId: id);
      },
    ),
    GoRoute(
      path: '/inventory/finished-goods/:id/edit',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return FinishedGoodFormScreen(goodId: id);
      },
    ),

    // BOM Sub-pages
    GoRoute(
      path: '/inventory/bom/add',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const BomFormScreen(),
    ),
    GoRoute(
      path: '/inventory/bom/:id/edit',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return BomFormScreen(bomId: id);
      },
    ),

    // Transactions Forms & Sub-pages
    GoRoute(
      path: '/transactions/inbound',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const InboundListScreen(),
    ),
    GoRoute(
      path: '/transactions/inbound/add',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const InboundFormScreen(),
    ),
    GoRoute(
      path: '/transactions/outbound',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const OutboundListScreen(),
    ),
    GoRoute(
      path: '/transactions/outbound/add',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const OutboundFormScreen(),
    ),
    GoRoute(
      path: '/transactions/activity/add',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final empId = state.uri.queryParameters['employeeId'];
        return ActivityFormScreen(preselectedEmployeeId: empId);
      },
    ),
    GoRoute(
      path: '/transactions/activity/:id/edit',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final activityId = state.pathParameters['id']!;
        return ActivityFormScreen(activityId: activityId);
      },
    ),

    // Production Execution & History
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

    // Employees Sub-pages
    GoRoute(
      path: '/employees/add',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const EmployeeFormScreen(),
    ),
    GoRoute(
      path: '/employees/:id/edit',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final employeeId = state.pathParameters['id']!;
        return EmployeeFormScreen(employeeId: employeeId);
      },
    ),

    // More Tab Sub-pages
    GoRoute(
      path: '/more/salary',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const SalaryScreen(),
    ),
    GoRoute(
      path: '/more/reports',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      path: '/more/stats',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const StatsScreen(),
    ),
    GoRoute(
      path: '/more/edit-profile',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/more/job-types/add',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const JobTypeFormScreen(),
    ),
    GoRoute(
      path: '/more/job-types/:id/edit',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final jobTypeId = state.pathParameters['id']!;
        return JobTypeFormScreen(jobTypeId: jobTypeId);
      },
    ),
    GoRoute(
      path: '/more/stock-adjustment',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final itemId = state.uri.queryParameters['itemId'];
        final itemType = state.uri.queryParameters['itemType'];
        return StockAdjustmentScreen(
          preselectedItemId: itemId,
          preselectedItemType: itemType,
        );
      },
    ),
    GoRoute(
      path: '/more/audit-log',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const AuditLogScreen(),
    ),
  ],
  );
});
