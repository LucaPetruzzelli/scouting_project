import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/scout_card.dart';
import '../widgets/profile_campetti_section.dart';
import '../widgets/profile_specialties_section.dart';
import '../../../core/theme/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;
    final themeMode = ref.watch(themeProvider);

    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Impostazioni'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.light_mode),
                        title: const Text('Tema Chiaro'),
                        trailing: Radio<ThemeMode>(
                          value: ThemeMode.light,
                          groupValue: themeMode,
                          onChanged: (mode) {
                            ref.read(themeProvider.notifier).setTheme(mode!);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.dark_mode),
                        title: const Text('Tema Scuro'),
                        trailing: Radio<ThemeMode>(
                          value: ThemeMode.dark,
                          groupValue: themeMode,
                          onChanged: (mode) {
                            ref.read(themeProvider.notifier).setTheme(mode!);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.brightness_auto),
                        title: const Text('Automatico'),
                        trailing: Radio<ThemeMode>(
                          value: ThemeMode.system,
                          groupValue: themeMode,
                          onChanged: (mode) {
                            ref.read(themeProvider.notifier).setTheme(mode!);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Card identità
            ScoutCard(
              name: profile['nome'] ?? 'Scout',
              surname: profile['cognome'] ?? '',
              role: profile['role'] ?? 'socio',
              branch: profile['branch'] ?? 'Non assegnata',
              jungleName: profile['jungle_name'] as String?,
            ),
            const SizedBox(height: 8),

            // Soprannome (solo capi branco): chip informativo
            if ((profile['role'] == 'capo' || profile['role'] == 'capo gruppo') &&
                profile['branch'] == 'l/c' &&
                profile['jungle_name'] != null &&
                (profile['jungle_name'] as String).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Chip(
                  avatar: const Icon(Icons.forest, size: 18),
                  label: Text('Soprannome della giungla: ${profile['jungle_name']}'),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                ),
              ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),

            // Sezione Censimento (Privata)
            ListTile(
              leading: const Icon(Icons.security, color: Colors.blue),
              title: const Text('Gestione Censimento'),
              subtitle: const Text('Ricevuta bonifico e stato di registrazione'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                context.push('/profile/censimento');
              },
            ),

            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 16),

            // Sezione Campetti
            ProfileCampettiSection(profile: profile),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Sezione Specialità e Competenze (solo soci L/C ed E/G)
            _buildSpecialtiesSection(profile),

            // Placeholder per sezioni future
            if (!(_profileIsSocioWithSpecialties(profile)))
              Center(
                child: Text(
                  'Altre sezioni del profilo in arrivo...',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

bool _profileIsSocioWithSpecialties(Map<String, dynamic>? profile) {
  if (profile == null) return false;
  final role = profile['role'] ?? 'socio';
  final branch = profile['branch'] ?? 'Non assegnata';
  final isSocio = role == 'socio';
  return isSocio && (branch == 'l/c' || branch == 'e/g');
}

Widget _buildSpecialtiesSection(Map<String, dynamic>? profile) {
  if (!_profileIsSocioWithSpecialties(profile)) {
    return const SizedBox.shrink();
  }
  return Column(
    children: [
      ProfileSpecialtiesSection(profile: profile!),
      const SizedBox(height: 24),
    ],
  );
}