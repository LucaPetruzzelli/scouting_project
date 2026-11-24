import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/event_model.dart';
import '../providers/event_logistics_provider.dart';
import '../../auth/providers/auth_provider.dart';

class EventLogisticsScreen extends ConsumerStatefulWidget {
  final EventModel event;

  const EventLogisticsScreen({super.key, required this.event});

  @override
  ConsumerState<EventLogisticsScreen> createState() => _EventLogisticsScreenState();
}

class _EventLogisticsScreenState extends ConsumerState<EventLogisticsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Set<String> _selectedUserIds = {};
  bool _hasSyncedData = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize selected user IDs from provider data
    if (!_hasSyncedData) {
      final logisticsAsync = ref.watch(eventLogisticsProvider(widget.event));
      if (logisticsAsync.hasValue && _selectedUserIds.isEmpty) {
        final data = logisticsAsync.value;
        if (data != null) {
          final logisticsUserIds = Set<String>.from(data['logisticsUserIds'] ?? {});
          if (mounted && logisticsUserIds.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedUserIds = logisticsUserIds;
                  _hasSyncedData = true;
                });
              }
            });
          }
        }
      }
    }
  }

  Future<void> _saveLogistics() async {
    final newIds = _selectedUserIds.toList();
    await ref.read(eventLogisticsProvider(widget.event).notifier).updateLogisticsUsers(newIds);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logistica aggiornata: ${_selectedUserIds.length} membri selezionati')),
      );
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final logisticsAsync = ref.watch(eventLogisticsProvider(widget.event));
    final profile = ref.watch(authProvider).profile;

    final role = profile?['role'] as String?;
    final isCapo = role == 'capo' || role == 'capo gruppo';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gruppo Logistica'),
        actions: [
          if (isCapo)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: logisticsAsync.hasValue ? _saveLogistics : null,
            ),
        ],
      ),
      body: logisticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Errore: $err')),
        data: (data) {
          final allParticipants = List<Map<String, dynamic>>.from(data['allParticipants']);
          final logisticsUserIds = Set<String>.from(data['logisticsUserIds'] ?? {});

          // Use selected user IDs (local state) or fallback to provider data
          final displaySelectedIds = _selectedUserIds.isNotEmpty ? _selectedUserIds : logisticsUserIds;

          final filteredParticipants = allParticipants.where((p) {
            if (_searchQuery.isEmpty) return true;
            final nome = (p['nome'] ?? '').toString().toLowerCase();
            final cognome = (p['cognome'] ?? '').toString().toLowerCase();
            final q = _searchQuery.toLowerCase();
            return nome.contains(q) || cognome.contains(q) || '$nome $cognome'.contains(q);
          }).toList();

          return Column(
            children: [
              // Info Card
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "I membri della logistica hanno accesso al magazzino durante l'evento e possono confermare le quote dei partecipanti.",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
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

              // Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filteredParticipants.length} soci disponibili',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${displaySelectedIds.length} membri logistica',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // List of participants
              Expanded(
                child: filteredParticipants.isEmpty
                    ? const Center(child: Text('Nessun socio trovato.'))
                    : ListView.builder(
                        itemCount: filteredParticipants.length,
                        itemBuilder: (context, index) {
                          final p = filteredParticipants[index];
                          final userId = p['id'] as String;
                          final nome = p['nome'] ?? '';
                          final cognome = p['cognome'] ?? '';
                          final branch = p['branch'] ?? '';
                          final squad = p['squad_name'] ?? '';
                          final isWarehouseKeeper = p['is_warehouse_keeper'] == true;
                          final isSelected = displaySelectedIds.contains(userId);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSelected
                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                                  : null,
                              child: Text(nome.isNotEmpty ? nome[0].toUpperCase() : '?'),
                            ),
                            title: Text(
                              '$nome $cognome',
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              'Branca: $branch • Squadriglia: $squad${isWarehouseKeeper ? ' • Magazziniere' : ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Switch(
                              value: isSelected,
                              onChanged: isCapo ? (val) {
                                setState(() {
                                  if (val) {
                                    _selectedUserIds.add(userId);
                                  } else {
                                    _selectedUserIds.remove(userId);
                                  }
                                });
                              } : null,
                            ),
                            onTap: isCapo
                                ? () {
                                    setState(() {
                                      if (_selectedUserIds.contains(userId)) {
                                        _selectedUserIds.remove(userId);
                                      } else {
                                        _selectedUserIds.add(userId);
                                      }
                                    });
                                  }
                                : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: isCapo
          ? FloatingActionButton.extended(
              onPressed: _saveLogistics,
              icon: const Icon(Icons.save),
              label: const Text('Salva'),
            )
          : null,
    );
  }
}