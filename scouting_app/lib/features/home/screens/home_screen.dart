import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../../notifications/providers/notifications_provider.dart';

import '../widgets/greeting_header.dart';
import '../widgets/soci_dashboard.dart';
import '../widgets/capi_dashboard.dart';
import '../../profile/screens/profile_screen.dart';
import '../../events/screens/events_list_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState.status == AuthStatus.authenticatedPending) {
      return _buildPendingScreen(context, ref);
    }

    if (authState.status == AuthStatus.authenticatedActive) {
      return _buildActiveScreen(context, ref, authState.profile);
    }

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  Widget _buildPendingScreen(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('In attesa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_empty, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Richiesta Inviata!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Il tuo account è attualmente in attesa di approvazione da parte di un Capo Unità. Riprova ad accedere più tardi.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Aggiorna Stato'),
                onPressed: () => ref.read(authProvider.notifier).refreshProfile(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveScreen(BuildContext context, WidgetRef ref, Map<String, dynamic>? profile) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AGESCI Bari 10'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final notifState = ref.watch(notificationsProvider);
              final count = notifState.value?.where((n) => !n.isRead).length ?? 0;
              
              return IconButton(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text(count.toString()),
                  child: const Icon(Icons.notifications_none),
                ),
                onPressed: () => context.push('/notifications'),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: _buildBody(profile),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'Eventi'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profilo'),
        ],
      ),
    );
  }

  Widget _buildBody(Map<String, dynamic>? profile) {
    if (_selectedIndex == 0) {
      return _buildDashboard(profile);
    } else if (_selectedIndex == 1) {
      return const EventsListScreen();
    } else {
      return const ProfileScreen();
    }
  }

  Widget _buildDashboard(Map<String, dynamic>? profile) {
    final role = profile?['role'] ?? 'socio';
    final isCapo = role == 'capo' || role == 'capo gruppo';

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        GreetingHeader(profile: profile),
        const SizedBox(height: 32),
        if (isCapo)
          CapiDashboard(profile: profile)
        else
          SociDashboard(profile: profile),
      ],
    );
  }
}
