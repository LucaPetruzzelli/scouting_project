import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/event_model.dart';
import '../providers/events_provider.dart';
import '../../admin/providers/admin_provider.dart';

class EventGroupsScreen extends ConsumerStatefulWidget {
  final EventModel draftEvent;

  const EventGroupsScreen({super.key, required this.draftEvent});

  @override
  ConsumerState<EventGroupsScreen> createState() => _EventGroupsScreenState();
}

class _EventGroupsScreenState extends ConsumerState<EventGroupsScreen> {
  int _numGroups = 2;
  late List<TextEditingController> _groupNameControllers;
  final Map<String, int> _userGroupMap = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _groupNameControllers = List.generate(
      _numGroups,
      (index) {
        final controller = TextEditingController(text: 'Gruppo ${index + 1}');
        controller.addListener(() {
          if (mounted) setState(() {});
        });
        return controller;
      },
    );
    Future.microtask(() => ref.read(usersListProvider.notifier).loadUsers());
  }

  @override
  void dispose() {
    for (var controller in _groupNameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateGroupCount(int delta) {
    setState(() {
      final newCount = _numGroups + delta;
      if (newCount < 1 || newCount > 20) return;

      if (delta > 0) {
        final controller = TextEditingController(text: 'Gruppo $newCount');
        controller.addListener(() {
          if (mounted) setState(() {});
        });
        _groupNameControllers.add(controller);
      } else {
        _groupNameControllers.last.dispose();
        _groupNameControllers.removeLast();
        // Rimuovi anche le assegnazioni degli utenti al gruppo cancellato
        _userGroupMap.removeWhere((key, value) => value == _numGroups - 1);
      }
      _numGroups = newCount;
    });
  }

  Future<void> _saveEvent() async {
    setState(() => _isSaving = true);

    try {
      final List<Map<String, dynamic>> groupsData = List.generate(_numGroups, (index) {
        final assignedUsers = _userGroupMap.entries
            .where((e) => e.value == index)
            .map((e) => e.key)
            .toList();
            
        return {
          'name': _groupNameControllers[index].text.trim(),
          'members': assignedUsers,
        };
      });

      final finalEvent = EventModel(
        id: widget.draftEvent.id,
        title: widget.draftEvent.title,
        description: widget.draftEvent.description,
        startDate: widget.draftEvent.startDate,
        endDate: widget.draftEvent.endDate,
        location: widget.draftEvent.location,
        createdBy: widget.draftEvent.createdBy,
        targetRoles: widget.draftEvent.targetRoles,
        targetBranches: widget.draftEvent.targetBranches,
        targetSquads: widget.draftEvent.targetSquads,
        targetUsers: widget.draftEvent.targetUsers,
        eventType: widget.draftEvent.eventType,
        fee: widget.draftEvent.fee,
        hasGroups: true,
        groupsData: groupsData,
        createdAt: widget.draftEvent.createdAt,
      );

      if (finalEvent.id.isNotEmpty) {
        await ref.read(eventsProvider.notifier).updateEvent(finalEvent);
      } else {
        await ref.read(eventsProvider.notifier).createEvent(finalEvent);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evento creato con gruppi!')));
        // Torna alla home
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  bool _isUserTargeted(dynamic user) {
    final e = widget.draftEvent;
    
    // Se non c'è nessun filtro esplicito e l'evento è stato creato "per tutti"
    if (e.targetRoles.isEmpty && e.targetBranches.isEmpty && e.targetSquads.isEmpty && e.targetUsers.isEmpty) {
      return true;
    }

    final String id = user['id'];
    if (e.targetUsers.contains(id)) return true;

    final String role = user['role'] ?? 'socio';
    final String branch = user['branch'] ?? '';
    final String squad = user['squad_name'] ?? '';

    if (e.targetBranches.contains(branch)) return true;
    if (e.targetRoles.contains(role)) return true;
    if (e.targetSquads.contains(squad)) return true;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Composizione Gruppi'),
        actions: [
          IconButton(
            icon: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveEvent,
          )
        ],
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Errore: $err')),
        data: (users) {
          final targetedUsers = users.where(_isUserTargeted).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Numero di gruppi:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _updateGroupCount(-1),
                              ),
                              Text('$_numGroups', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => _updateGroupCount(1),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Genera dinamicamente i TextField per i nomi dei gruppi
                      ...List.generate(_numGroups, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: TextFormField(
                            controller: _groupNameControllers[index],
                            decoration: InputDecoration(
                              labelText: 'Nome Gruppo ${index + 1}',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        );
                      }),
                      const Divider(height: 32, thickness: 2),
                      const Text(
                        'Assegna i Partecipanti',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Non è obbligatorio assegnare tutti. Chi non ha un gruppo vedrà l\'evento comunque.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final u = targetedUsers[index];
                    final userId = u['id'] as String;
                    final name = '${u['nome']} ${u['cognome']}';
                    final subtitle = '${u['branch'] ?? 'Nessuna'} • ${u['squad_name'] ?? '-'}';

                    final assignedGroupIndex = _userGroupMap[userId];

                    return ListTile(
                      title: Text(name),
                      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
                      trailing: DropdownButton<int?>(
                        value: assignedGroupIndex,
                        hint: const Text('Nessun gruppo'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Nessun gruppo'),
                          ),
                          ...List.generate(_numGroups, (gIndex) {
                            return DropdownMenuItem<int?>(
                              value: gIndex,
                              child: Text(_groupNameControllers[gIndex].text.isEmpty ? 'Gruppo ${gIndex + 1}' : _groupNameControllers[gIndex].text),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() {
                            if (val == null) {
                              _userGroupMap.remove(userId);
                            } else {
                              _userGroupMap[userId] = val;
                            }
                          });
                        },
                      ),
                    );
                  },
                  childCount: targetedUsers.length,
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          );
        },
      ),
    );
  }
}
