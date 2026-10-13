import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../events/providers/events_provider.dart';
import '../../events/models/event_model.dart';
import 'package:intl/intl.dart';

class SociDashboard extends ConsumerWidget {
  final Map<String, dynamic>? profile;

  const SociDashboard({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Il mio percorso',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                context,
                title: 'Specialità in corso',
                count: '2',
                icon: Icons.star_border,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoCard(
                context,
                title: 'Impegni attivi',
                count: '1',
                icon: Icons.assignment_outlined,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        Text(
          'Attività Imminenti',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        eventsAsync.when(
          data: (events) {
            final now = DateTime.now();
            final sevenDaysFromNow = now.add(const Duration(days: 7));
            final upcomingEvents = events.where((e) {
              return e.endDate.isAfter(now) && e.startDate.isBefore(sevenDaysFromNow);
            }).toList();
            
            if (upcomingEvents.isEmpty) {
              return const Text('Nessuna attività in programma per i prossimi 7 giorni.');
            }
            
            return Column(
              children: upcomingEvents.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildEventCard(
                    context,
                    title: e.title,
                    description: e.description,
                    location: e.location ?? 'Nessun luogo specificato',
                    date: DateFormat('E d MMM, HH:mm', 'it_IT').format(e.startDate),
                    cost: e.fee != null ? '€ ${e.fee!.toStringAsFixed(2)}' : null,
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Text('Errore nel caricamento eventi: $err'),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, {required String title, required String count, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            count,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, {required String title, String? description, required String location, required String date, String? cost}) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  date,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                if (cost != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cost,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
