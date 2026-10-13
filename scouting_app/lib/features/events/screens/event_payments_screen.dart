import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../providers/event_payments_provider.dart';

class EventPaymentsScreen extends ConsumerStatefulWidget {
  final EventModel event;
  
  const EventPaymentsScreen({super.key, required this.event});

  @override
  ConsumerState<EventPaymentsScreen> createState() => _EventPaymentsScreenState();
}

class _EventPaymentsScreenState extends ConsumerState<EventPaymentsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(eventPaymentsProvider(widget.event));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Quote'),
      ),
      body: paymentsAsync.when(
        data: (data) {
          final allParticipants = data['participants'] as List<Map<String, dynamic>>;
          
          final filteredParticipants = allParticipants.where((p) {
            if (_searchQuery.isEmpty) return true;
            final nome = (p['nome'] ?? '').toString().toLowerCase();
            final cognome = (p['cognome'] ?? '').toString().toLowerCase();
            final q = _searchQuery.toLowerCase();
            return nome.contains(q) || cognome.contains(q) || '$nome $cognome'.contains(q);
          }).toList();

          final totalExpected = allParticipants.length;
          final totalPaid = allParticipants.where((p) => p['has_paid'] == true).length;
          final fee = widget.event.fee ?? 0.0;
          final totalCollected = totalPaid * fee;

          return Column(
            children: [
              // Summary Card
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('Paganti', style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 4),
                          Text('$totalPaid / $totalExpected', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.blue)),
                        ],
                      ),
                      Column(
                        children: [
                          Text('Totale Raccolto', style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 4),
                          Text('€ ${totalCollected.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Cerca socio...',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                  },
                ),
              ),

              // List
              Expanded(
                child: filteredParticipants.isEmpty
                    ? const Center(child: Text('Nessun socio trovato.'))
                    : ListView.builder(
                        itemCount: filteredParticipants.length,
                        itemBuilder: (context, index) {
                          final p = filteredParticipants[index];
                          final nome = p['nome'] ?? '';
                          final cognome = p['cognome'] ?? '';
                          final branch = p['branch'] ?? '';
                          final hasPaid = p['has_paid'] == true;

                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(nome.isNotEmpty ? nome[0].toUpperCase() : '?'),
                            ),
                            title: Text('$nome $cognome', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Branca: $branch'),
                            trailing: Checkbox(
                              value: hasPaid,
                              onChanged: (val) async {
                                if (val != null) {
                                  final success = await ref.read(eventPaymentsProvider(widget.event).notifier).togglePayment(p['id'], val);
                                  if (!success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Errore durante il salvataggio della quota.')));
                                  }
                                }
                              },
                            ),
                            onTap: () async {
                              final success = await ref.read(eventPaymentsProvider(widget.event).notifier).togglePayment(p['id'], !hasPaid);
                              if (!success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Errore durante il salvataggio della quota.')));
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Errore: $err')),
      ),
    );
  }
}
