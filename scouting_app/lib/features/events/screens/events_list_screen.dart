import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/events_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class EventsListScreen extends ConsumerWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    final profile = ref.watch(authProvider).profile;

    return Scaffold(
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return const Center(child: Text('Nessun evento in programma.'));
          }
          
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (event.description != null) ...[
                        Text(event.description!),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        '${DateFormat('dd/MM/yyyy HH:mm').format(event.startDate)} - ${DateFormat('HH:mm').format(event.endDate)}',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary),
                      ),
                      if (event.location != null && event.location!.isNotEmpty) ...[
                        Text('📍 ${event.location}', style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                      if (event.fee != null && profile != null) ...[
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final role = profile['role'];
                            final isCapo = role == 'capo' || role == 'capo gruppo';
                            final isLogistica = event.logisticsUsers.contains(profile['id']);
                            if (isCapo || isLogistica) {
                              return OutlinedButton.icon(
                                icon: const Icon(Icons.euro, size: 16),
                                label: const Text('Gestisci Quote'),
                                onPressed: () => context.push('/events/payments', extra: event),
                              );
                            }
                            return const SizedBox.shrink();
                          }
                        ),
                      ],
                    ],
                  ),
                  trailing: (profile != null && (profile['role'] == 'capo gruppo' || event.createdBy == profile['id']))
                      ? PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              context.push('/events/edit', extra: event);
                            } else if (value == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Elimina evento'),
                                  content: const Text('Sei sicuro di voler eliminare questo evento?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Elimina')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(eventsProvider.notifier).deleteEvent(event.id);
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Modifica')),
                            const PopupMenuItem(value: 'delete', child: Text('Elimina', style: TextStyle(color: Colors.red))),
                          ],
                        )
                      : const Icon(Icons.event),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Errore: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/events/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
