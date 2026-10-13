import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/scout_card.dart';
import '../widgets/profile_campetti_section.dart';
import '../widgets/profile_specialties_section.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;

    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final nome = profile['nome'] ?? 'Scout';
    final cognome = profile['cognome'] ?? '';
    final role = profile['role'] ?? 'socio';
    final branch = profile['branch'] ?? 'Non assegnata';
    final jungleName = profile['jungle_name'] as String?;

    // Determina se mostrare la sezione specialità
    // Solo per soci (non capi) del Branco (l/c) o Reparto (e/g)
    final isSocio = role == 'socio';
    final showSpecialties = isSocio && (branch == 'l/c' || branch == 'e/g');

    // I campetti dei capi sono visibili solo a capi
    // (il check di visibilità lato UI è già garantito dato che
    //  ogni utente vede solo il proprio profilo qui)
    final showCampetti = true; // tutti i ruoli vedono la propria sezione campetti

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Card identità
        ScoutCard(
          name: nome,
          surname: cognome,
          role: role,
          branch: branch,
          jungleName: jungleName,
        ),
        const SizedBox(height: 8),

        // Soprannome (solo capi branco): chip informativo
        if ((role == 'capo' || role == 'capo gruppo') && branch == 'l/c' && jungleName != null && jungleName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Chip(
              avatar: const Icon(Icons.forest, size: 18),
              label: Text('Soprannome della giungla: $jungleName'),
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
        if (showCampetti) ...[
          ProfileCampettiSection(profile: profile),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
        ],

        // Sezione Specialità e Competenze (solo soci L/C ed E/G)
        if (showSpecialties) ...[
          ProfileSpecialtiesSection(profile: profile),
          const SizedBox(height: 24),
        ],

        // Placeholder per sezioni future
        if (!showSpecialties)
          Center(
            child: Text(
              'Altre sezioni del profilo in arrivo...',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}
