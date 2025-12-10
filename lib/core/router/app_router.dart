import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/add_person_screen.dart';
import '../../features/admin/presentation/screens/manage_users_screen.dart';
import '../../features/admin/presentation/screens/add_shop_screen.dart';
import '../../features/admin/presentation/screens/manage_shops_screen.dart';
import '../../features/admin/presentation/screens/add_product_screen.dart';
import '../../features/admin/presentation/screens/manage_products_screen.dart';
import '../../features/admin/presentation/screens/add_location_screen.dart';
import '../../features/admin/presentation/screens/manage_locations_screen.dart';
import '../../features/sales/presentation/screens/sales_home_screen.dart';
import '../../features/sales/presentation/screens/shop_list_screen.dart';
import '../../features/billing/presentation/screens/billing_home_screen.dart';
import '../../features/delivery/presentation/screens/delivery_home_screen.dart';
import '../../features/owner/presentation/screens/owner_dashboard_screen.dart';

class GoRouterNotifier extends ChangeNotifier {
  final Ref _ref;
  
  GoRouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) {
      notifyListeners();
    });
    _ref.listen(currentUserProvider, (_, __) {
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = GoRouterNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.asData?.value != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        final userState = ref.read(currentUserProvider);
        final user = userState.asData?.value;
        
        if (user == null) {
          // User data not loaded yet, stay on login momentarily
          return null;
        }

        debugPrint('🔄 Redirecting ${user.role.name} user to dashboard');

        switch (user.role.name) {
          case 'owner':
            return '/owner';
          case 'admin':
            return '/admin';
          case 'sales':
            return '/sales';
          case 'billing':
            return '/billing';
          case 'delivery':
            return '/delivery';
          default:
            return '/sales';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/owner',
        builder: (context, state) => const OwnerDashboardScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'add-person',
            builder: (context, state) => const AddPersonScreen(),
          ),
          GoRoute(
            path: 'manage-users',
            builder: (context, state) => const ManageUsersScreen(),
          ),
          GoRoute(
            path: 'add-shop',
            builder: (context, state) => const AddShopScreen(),
          ),
          GoRoute(
            path: 'manage-shops',
            builder: (context, state) => const ManageShopsScreen(),
          ),
          GoRoute(
            path: 'add-product',
            builder: (context, state) => const AddProductScreen(),
          ),
          GoRoute(
            path: 'manage-products',
            builder: (context, state) => const ManageProductsScreen(),
          ),
          GoRoute(
            path: 'add-location',
            builder: (context, state) => const AddLocationScreen(),
          ),
          GoRoute(
            path: 'manage-locations',
            builder: (context, state) => const ManageLocationsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/sales',
        builder: (context, state) => const SalesHomeScreen(),
        routes: [
          GoRoute(
            path: 'shops',
            builder: (context, state) => const ShopListScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/billing',
        builder: (context, state) => const BillingHomeScreen(),
      ),
      GoRoute(
        path: '/delivery',
        builder: (context, state) => const DeliveryHomeScreen(),
      ),
    ],
  );
});
