import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CapiDashboard extends StatelessWidget {
  final Map<String, dynamic>? profile;

  const CapiDashboard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final role = profile?['role'] ?? 'capo';
    final isCapoGruppo = role == 'capo gruppo';
    final extraPerms = profile?['extra_permissions'] as Map<String, dynamic>?;
    final canAddCapi = isCapoGruppo || extraPerms?['can_add_leaders'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Azioni Rapide',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildActionCard(
              context,
              title: 'Nuova Attività',
              icon: Icons.event_available,
              color: Colors.green,
              onTap: () => context.push('/events/create'),
            ),
            _buildActionCard(
              context,
              title: 'Gestione Iscritti',
              icon: Icons.people,
              color: Colors.blue,
              onTap: () => context.push('/admin/users'),
            ),
            _buildActionCard(
              context,
              title: 'Richieste Iscrizione',
              icon: Icons.group_add,
              color: Colors.orange,
              onTap: () => context.push('/admin/pending'),
            ),
            _buildActionCard(
              context,
              title: 'Calendario',
              icon: Icons.calendar_month,
              color: Colors.purple,
              onTap: () => context.push('/calendar'),
            ),
            if (canAddCapi)
              _buildActionCard(
                context,
                title: 'Aggiungi Capo',
                icon: Icons.person_add_alt_1,
                color: Colors.red,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funzione in sviluppo')),
                  );
                },
              ),
            if (isCapoGruppo)
              _buildActionCard(
                context,
                title: 'Esporta Dati',
                icon: Icons.download,
                color: Colors.teal,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Esportazione CSV in sviluppo')),
                  );
                },
              ),
            _buildActionCard(
              context,
              title: 'Logistica',
              icon: Icons.local_shipping,
              color: Colors.orange,
              onTap: () {
                // Vai al magazzino per gestire la logistica
                context.push('/warehouse', extra: profile);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
