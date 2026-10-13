import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CapiDashboard extends StatelessWidget {
  final Map<String, dynamic>? profile;

  const CapiDashboard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    // Controllo se è capo gruppo
    final role = profile?['role'] ?? 'capo';
    final isCapoGruppo = role == 'capo gruppo'; // o logica simile se ci sono ruoli specifici

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
              onTap: () {
                // TODO: navigare a creazione evento
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Creazione evento in sviluppo')),
                );
              },
            ),
            _buildActionCard(
              context,
              title: 'Gestione Iscritti',
              icon: Icons.people,
              color: Colors.blue,
              onTap: () {
                context.push('/admin/users');
              },
            ),
            _buildActionCard(
              context,
              title: 'Richieste Iscrizione',
              icon: Icons.group_add,
              color: Colors.orange,
              onTap: () {
                context.push('/admin/pending');
              },
            ),
            _buildActionCard(
              context,
              title: 'Modifica Eventi',
              icon: Icons.edit_calendar,
              color: Colors.purple,
              onTap: () {
                // TODO: navigare a modifica eventi
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Modifica eventi in sviluppo')),
                );
              },
            ),
            if (isCapoGruppo)
              _buildActionCard(
                context,
                title: 'Aggiungi Capo',
                icon: Icons.person_add_alt_1,
                color: Colors.red,
                onTap: () {
                  // TODO: navigare a aggiunta capo
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Aggiunta capo in sviluppo')),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, {
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
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
