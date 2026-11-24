import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/registration_step1_screen.dart';
import '../../features/auth/screens/registration_step2_screen.dart';
import '../../features/auth/screens/registration_step3_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/admin/screens/pending_users_screen.dart';
import '../../features/admin/screens/users_management_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/events/screens/events_list_screen.dart';
import '../../features/events/screens/event_creation_screen.dart';
import '../../features/events/screens/event_groups_screen.dart';
import '../../features/events/screens/event_logistics_screen.dart';
import '../../features/events/models/event_model.dart';
import '../../features/profile/screens/censimento_screen.dart';
import '../../features/events/screens/event_payments_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/calendar/screens/event_detail_screen.dart';
import '../../features/warehouse/screens/warehouse_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      final isAuth = authState.status == AuthStatus.authenticatedActive ||
          authState.status == AuthStatus.authenticatedPending;

      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToRegister = state.matchedLocation.startsWith('/register');

      if (authState.status == AuthStatus.initial) {
        return null;
      }

      if (!isAuth && !isGoingToLogin && !isGoingToRegister) {
        return '/login';
      }

      if (isAuth && isGoingToLogin) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/register/step1',
        builder: (context, state) => const RegistrationStep1Screen(),
      ),
      GoRoute(
        path: '/register/step2',
        builder: (context, state) => const RegistrationStep2Screen(),
      ),
      GoRoute(
        path: '/register/step3',
        builder: (context, state) => const RegistrationStep3Screen(),
      ),
      GoRoute(
        path: '/admin/pending',
        builder: (context, state) => const PendingUsersScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const UsersManagementScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/events',
        builder: (context, state) => const EventsListScreen(),
      ),
      GoRoute(
        path: '/events/create',
        builder: (context, state) => const EventCreationScreen(),
      ),
      GoRoute(
        path: '/events/edit',
        builder: (context, state) {
          final event = state.extra as EventModel;
          return EventCreationScreen(eventToEdit: event);
        },
      ),
      GoRoute(
        path: '/events/create/groups',
        builder: (context, state) {
          final event = state.extra as EventModel;
          return EventGroupsScreen(draftEvent: event);
        },
      ),
      GoRoute(
        path: '/events/logistics',
        builder: (context, state) {
          final event = state.extra as EventModel;
          return EventLogisticsScreen(event: event);
        },
      ),
      GoRoute(
        path: '/events/payments',
        builder: (context, state) {
          final event = state.extra as EventModel;
          return EventPaymentsScreen(event: event);
        },
      ),
      GoRoute(
        path: '/events/detail',
        builder: (context, state) {
          final event = state.extra as EventModel;
          return EventDetailScreen(event: event);
        },
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/warehouse',
        builder: (context, state) {
          final profile = state.extra as Map<String, dynamic>?;
          // If no profile passed, try to get from auth provider
          return WarehouseScreen(
            userBranca: profile?['branch'] as String? ?? '',
            canEditPermanent: profile?['role'] == 'capo' || profile?['role'] == 'capo gruppo' || profile?['is_warehouse_keeper'] == true,
            hasTemporaryLogisticsAccess: profile?['hasTemporaryLogisticsAccess'] == true,
          );
        },
      ),
      GoRoute(
        path: '/profile/censimento',
        builder: (context, state) => const CensimentoScreen(),
      ),
    ],
  );

  ref.listen(authProvider, (previous, next) {
    if (previous?.status != next.status) {
      router.refresh();
    }
  });

  return router;
});
