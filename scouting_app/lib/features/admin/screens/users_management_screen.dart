import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';
import '../../../core/utils/export_service.dart';
import 'user_edit_screen.dart';

class UsersManagementScreen extends ConsumerStatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  ConsumerState<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends ConsumerState<UsersManagementScreen> {
  Set<String> selectedUserIds = {};
  bool isExporting = false;

  void _exportSelectedUsers(List<Map<String, dynamic>> allUsers) async {
    final selectedUsers = allUsers.where((u) => selectedUserIds.contains(u['id'])).toList();
    
    if (selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno un utente da esportare.')),
      );
      return;
    }

    setState(() => isExporting = true);

    try {
      // Definiamo i campi che vogliamo esportare. Possiamo aggiungere altre chiavi presenti nel DB.
      final fields = [
        'id', 'nome', 'cognome', 'genere', 'data_di_nascita', 'email', 'telefono',
        'indirizzo', 'civico', 'cap', 'comune', 'provincia', 'branch', 'role', 'status'
      ];
      
      await ExportService.exportToCsv(users: selectedUsers, fieldsToExport: fields);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore esportazione: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(usersFilterProvider);
    final usersState = ref.watch(usersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Utenti e Dati'),
        actions: [
          if (usersState is AsyncData && usersState.value!.isNotEmpty)
            IconButton(
              icon: isExporting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Icon(Icons.download),
              tooltip: 'Esporta Selezionati',
              onPressed: isExporting ? null : () => _exportSelectedUsers(usersState.value!),
            ),
        ],
      ),
      body: Column(
        children: [
          // Sezione Filtri
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: filter.branch,
                    decoration: const InputDecoration(labelText: 'Branca', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tutte')),
                      DropdownMenuItem(value: 'Lupetti/Coccinelle', child: Text('L/C')),
                      DropdownMenuItem(value: 'Esploratori/Guide', child: Text('E/G')),
                      DropdownMenuItem(value: 'Rover/Scolte', child: Text('R/S')),
                      DropdownMenuItem(value: 'Co.Ca.', child: Text('Co.Ca.')),
                    ],
                    onChanged: (val) {
                      ref.read(usersFilterProvider.notifier).state = UsersFilter(status: filter.status, branch: val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: filter.status,
                    decoration: const InputDecoration(labelText: 'Stato', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tutti')),
                      DropdownMenuItem(value: 'active', child: Text('Attivi')),
                      DropdownMenuItem(value: 'pending', child: Text('In Attesa')),
                      DropdownMenuItem(value: 'rejected', child: Text('Rifiutati')),
                    ],
                    onChanged: (val) {
                      ref.read(usersFilterProvider.notifier).state = UsersFilter(status: val, branch: filter.branch);
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Lista Utenti
          Expanded(
            child: usersState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Errore: $err')),
              data: (users) {
                if (users.isEmpty) {
                  return const Center(child: Text('Nessun utente trovato con i filtri attuali.'));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final userId = user['id'];
                    final isSelected = selectedUserIds.contains(userId);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                selectedUserIds.add(userId);
                              } else {
                                selectedUserIds.remove(userId);
                              }
                            });
                          },
                        ),
                        title: Text('${user['nome']} ${user['cognome']}'),
                        subtitle: Text('Branca: ${user['branch'] ?? 'N/D'} - Stato: ${user['status']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserEditScreen(user: user),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (usersState is AsyncData) {
            setState(() {
              if (selectedUserIds.length == usersState.value!.length) {
                selectedUserIds.clear();
              } else {
                selectedUserIds.addAll(usersState.value!.map((u) => u['id'] as String));
              }
            });
          }
        },
        label: const Text('Seleziona Tutti'),
        icon: const Icon(Icons.select_all),
      ),
    );
  }
}
