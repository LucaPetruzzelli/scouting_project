import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../admin/providers/admin_provider.dart';

class TargetSelection {
  final List<String> roles;
  final List<String> branches;
  final List<String> squads;
  final List<String> users;

  TargetSelection({
    required this.roles,
    required this.branches,
    required this.squads,
    required this.users,
  });
}

class MultiSelectTargetDialog extends ConsumerStatefulWidget {
  final TargetSelection initialSelection;
  final String userRole;
  final String userBranch;
  final String userSquad;
  final bool canCreateGroupEvents;

  const MultiSelectTargetDialog({
    super.key,
    required this.initialSelection,
    required this.userRole,
    required this.userBranch,
    required this.userSquad,
    required this.canCreateGroupEvents,
  });

  @override
  ConsumerState<MultiSelectTargetDialog> createState() => _MultiSelectTargetDialogState();
}

class _MultiSelectTargetDialogState extends ConsumerState<MultiSelectTargetDialog> {
  final TextEditingController _searchController = TextEditingController();
  
  late Set<String> _selectedRoles;
  late Set<String> _selectedBranches;
  late Set<String> _selectedSquads;
  late Set<String> _selectedUsers;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedRoles = Set.from(widget.initialSelection.roles);
    _selectedBranches = Set.from(widget.initialSelection.branches);
    _selectedSquads = Set.from(widget.initialSelection.squads);
    _selectedUsers = Set.from(widget.initialSelection.users);
    
    Future.microtask(() => ref.read(usersListProvider.notifier).loadUsers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(
      context,
      TargetSelection(
        roles: _selectedRoles.toList(),
        branches: _selectedBranches.toList(),
        squads: _selectedSquads.toList(),
        users: _selectedUsers.toList(),
      ),
    );
  }

  bool get _isAllSelected => _selectedBranches.length == 4; // 4 branches in total

  void _toggleAll(bool? val) {
    setState(() {
      if (val == true) {
        _selectedBranches.addAll(['Branco', 'Reparto', 'Clan/Fuoco', 'Co.Ca.']);
        _selectedRoles.clear();
        _selectedSquads.clear();
        _selectedUsers.clear();
      } else {
        _selectedBranches.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersListProvider);
    final isCapoGruppo = widget.userRole == 'capo gruppo';
    final isCapo = widget.userRole == 'capo';

    final canSelectMacro = isCapoGruppo || (isCapo && widget.canCreateGroupEvents);

    return AlertDialog(
      title: const Text('Seleziona Destinatari'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Cerca (nome, ruolo o branca)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: usersAsync.when(
                data: (users) {
                  if (_searchQuery.isNotEmpty) {
                    return _buildSearchResults(users);
                  }
                  
                  return ListView(
                    children: [
                      if (canSelectMacro)
                        CheckboxListTile(
                          title: const Text('Tutto il Gruppo (Seleziona tutto)', style: TextStyle(fontWeight: FontWeight.bold)),
                          value: _isAllSelected,
                          onChanged: _toggleAll,
                        ),
                      
                      const Divider(),
                      
                      if (canSelectMacro || widget.userBranch == 'Branco')
                        _buildBranchSection('Branco', users),
                      
                      if (canSelectMacro || widget.userBranch == 'Reparto')
                        _buildBranchSection('Reparto', users),
                      
                      if (canSelectMacro || widget.userBranch == 'Clan/Fuoco')
                        _buildBranchSection('Clan/Fuoco', users),
                      
                      if (canSelectMacro || widget.userBranch == 'Co.Ca.')
                        _buildBranchSection('Co.Ca.', users),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Text('Errore: $err'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
        ElevatedButton(onPressed: _submit, child: const Text('Conferma')),
      ],
    );
  }

  Widget _buildSearchResults(List<dynamic> users) {
    final filteredUsers = users.where((u) {
      final name = '${u['nome']} ${u['cognome']}'.toLowerCase();
      final branch = (u['branch'] ?? '').toString().toLowerCase();
      final role = (u['role'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || branch.contains(_searchQuery) || role.contains(_searchQuery);
    }).toList();

    if (filteredUsers.isEmpty) return const Text('Nessun utente trovato.');

    return ListView(
      children: filteredUsers.map((u) {
        final id = u['id'];
        final name = '${u['nome']} ${u['cognome']}';
        final subtitle = '${u['role'] ?? 'socio'} • ${u['branch'] ?? 'Nessuna'}';

        return CheckboxListTile(
          title: Text(name),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          value: _selectedUsers.contains(id),
          onChanged: (val) {
            setState(() {
              if (val == true) {
                _selectedUsers.add(id);
              } else {
                _selectedUsers.remove(id);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildBranchSection(String branchName, List<dynamic> allUsers) {
    final branchUsers = allUsers.where((u) => u['branch'] == branchName).toList();
    final isBranchSelected = _selectedBranches.contains(branchName);

    // Raggruppa per squadriglia (se Reparto)
    final Map<String, List<dynamic>> squadsMap = {};
    final List<dynamic> noSquadUsers = [];

    if (branchName == 'Reparto') {
      for (var u in branchUsers) {
        final squad = u['squad_name'] as String?;
        if (squad != null && squad.trim().isNotEmpty) {
          squadsMap.putIfAbsent(squad, () => []).add(u);
        } else {
          noSquadUsers.add(u);
        }
      }
    } else {
      noSquadUsers.addAll(branchUsers);
    }

    return ExpansionTile(
      title: Text(branchName, style: const TextStyle(fontWeight: FontWeight.bold)),
      initiallyExpanded: isBranchSelected,
      children: [
        CheckboxListTile(
          title: Text('Intera branca ($branchName)'),
          subtitle: const Text('Seleziona per includere tutti (anche futuri iscritti)'),
          value: isBranchSelected,
          onChanged: (val) {
            setState(() {
              if (val == true) {
                _selectedBranches.add(branchName);
                // Rimuovi eventuali sotto-selezioni per non avere duplicati
                _selectedUsers.removeAll(branchUsers.map((u) => u['id'].toString()));
                _selectedSquads.removeAll(squadsMap.keys);
              } else {
                _selectedBranches.remove(branchName);
              }
            });
          },
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        
        // Se non è selezionata l'intera branca, mostra squadriglie e utenti
        if (!isBranchSelected) ...[
          const Divider(),
          if (squadsMap.isNotEmpty) ...[
            for (var entry in squadsMap.entries)
              _buildSquadSection(entry.key, entry.value),
          ],
          
          if (noSquadUsers.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text('Singoli Utenti:', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            for (var u in noSquadUsers)
              _buildUserCheckbox(u),
          ]
        ],
      ],
    );
  }

  Widget _buildSquadSection(String squadName, List<dynamic> squadUsers) {
    final isSquadSelected = _selectedSquads.contains(squadName);

    return ExpansionTile(
      title: Text('Squadriglia $squadName'),
      initiallyExpanded: isSquadSelected,
      children: [
        CheckboxListTile(
          title: Text('Intera squadriglia ($squadName)'),
          value: isSquadSelected,
          onChanged: (val) {
            setState(() {
              if (val == true) {
                _selectedSquads.add(squadName);
                _selectedUsers.removeAll(squadUsers.map((u) => u['id'].toString()));
              } else {
                _selectedSquads.remove(squadName);
              }
            });
          },
        ),
        if (!isSquadSelected)
          for (var u in squadUsers)
            _buildUserCheckbox(u),
      ],
    );
  }

  Widget _buildUserCheckbox(dynamic user) {
    final id = user['id'].toString();
    final name = '${user['nome']} ${user['cognome']}';
    
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: CheckboxListTile(
        title: Text(name),
        value: _selectedUsers.contains(id),
        onChanged: (val) {
          setState(() {
            if (val == true) {
              _selectedUsers.add(id);
            } else {
              _selectedUsers.remove(id);
            }
          });
        },
      ),
    );
  }
}
