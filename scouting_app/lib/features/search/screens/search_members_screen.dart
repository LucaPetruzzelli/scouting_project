// lib/features/search/screens/search_members_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchMembersScreen extends StatefulWidget {
  const SearchMembersScreen({super.key});

  @override
  State<SearchMembersScreen> createState() => _SearchMembersScreenState();
}

class _SearchMembersScreenState extends State<SearchMembersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedBranca = 'Tutte';
  String _selectedRole = 'Tutti';
  bool _onlyMaestriSpecialita = false;
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  // Branche che corrispondono ai valori ENUM nel DB: branco, reparto, clan, gruppo, Co.Ca.
  final List<String> _branche = ['Tutte', 'branco', 'reparto', 'clan', 'gruppo', 'Co.Ca.'];
  final List<String> _brancheLabels = ['Tutte', 'Branco', 'Reparto', 'Clan/Fuoco', 'Gruppo', 'Comunità Capi'];
  final List<String> _ruoli = ['Tutti', 'Socio', 'Capo'];

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    try {
      // Usa i nomi corretti delle colonne del DB (nome, cognome, branch, role)
      var query = Supabase.instance.client
          .from('profiles')
          .select('id, nome, cognome, username, jungle_name, branch, role, is_maestro_specialita')
          .eq('status', 'active'); // Solo utenti approvati e attivi

      if (_selectedBranca != 'Tutte') {
        query = query.eq('branch', _selectedBranca);
      }

      if (_onlyMaestriSpecialita) {
        query = query.eq('is_maestro_specialita', true);
      }

      final data = await query.order('cognome').order('nome');
      final queryText = _searchController.text.trim().toLowerCase();

      final filtered = (data as List).cast<Map<String, dynamic>>().where((user) {
        // Filtro ruolo lato client (evita query complesse)
        final roleStr = (user['role'] ?? '').toString().toLowerCase();
        if (_selectedRole == 'Capo' &&
            !roleStr.contains('capo') &&
            !roleStr.contains('leader')) {
          return false;
        }
        if (_selectedRole == 'Socio' &&
            (roleStr.contains('capo') || roleStr.contains('leader'))) {
          return false;
        }

        // Filtro testo di ricerca
        if (queryText.isEmpty) return true;

        final username = (user['username'] ?? '').toString().toLowerCase();
        final nome = (user['nome'] ?? '').toString().toLowerCase();
        final cognome = (user['cognome'] ?? '').toString().toLowerCase();
        final fullName = '$nome $cognome';
        final jungle = (user['jungle_name'] ?? '').toString().toLowerCase();

        return username.contains(queryText) ||
            fullName.contains(queryText) ||
            nome.contains(queryText) ||
            cognome.contains(queryText) ||
            jungle.contains(queryText);
      }).toList();

      if (mounted) setState(() => _results = filtered);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nella ricerca: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDisplayName(Map<String, dynamic> user) {
    final branch = (user['branch'] ?? '').toString().toLowerCase();
    final isCapoBranco = branch == 'branco' &&
        (user['role'] ?? '').toString().toLowerCase().contains('capo') &&
        (user['jungle_name'] ?? '').toString().isNotEmpty;
    if (isCapoBranco) {
      return '${user['jungle_name']} (${user['nome']} ${user['cognome']})';
    }
    return '${user['nome'] ?? ''} ${user['cognome'] ?? ''}'.trim();
  }

  String _formatBrancaLabel(String brancaDb) {
    switch (brancaDb.toLowerCase()) {
      case 'branco': return 'Branco';
      case 'reparto': return 'Reparto';
      case 'clan': return 'Clan/Fuoco';
      case 'gruppo': return 'Gruppo';
      case 'co.ca.': return 'Comunità Capi';
      default: return brancaDb;
    }
  }

  String _formatRoleLabel(String roleDb) {
    switch (roleDb.toLowerCase()) {
      case 'socio': return 'Socio';
      case 'capo': return 'Capo';
      case 'capo gruppo': return 'Capo Gruppo';
      case 'genitore': return 'Genitore';
      default: return roleDb;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ricerca Membri')),
      body: Column(
        children: [
          // Barra di ricerca
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _performSearch(),
              decoration: InputDecoration(
                hintText: 'Cerca per nome, cognome o @username',
                prefixIcon: const Icon(Icons.search_rounded),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Filtri
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Filtro branca
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedBranca,
                    items: List.generate(_branche.length, (i) {
                      return DropdownMenuItem(
                        value: _branche[i],
                        child: Text('Branca: ${_brancheLabels[i]}'),
                      );
                    }),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedBranca = v);
                        _performSearch();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Filtro ruolo
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    items: _ruoli
                        .map((r) => DropdownMenuItem(value: r, child: Text('Ruolo: $r')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedRole = v);
                        _performSearch();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('Maestri di Specialità'),
                  selected: _onlyMaestriSpecialita,
                  onSelected: (val) {
                    setState(() => _onlyMaestriSpecialita = val);
                    _performSearch();
                  },
                ),
              ],
            ),
          ),

          // Contatore risultati
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_results.length} membro${_results.length == 1 ? '' : 'i'} trovato${_results.length == 1 ? '' : 'i'}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),

          const Divider(height: 1),

          // Lista risultati
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64,
                                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                            const SizedBox(height: 16),
                            Text(
                              'Nessun membro trovato',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _results.length,
                        itemBuilder: (ctx, i) {
                          final user = _results[i];
                          final nome = user['nome'] as String? ?? '';
                          final cognome = user['cognome'] as String? ?? '';
                          final displayName = _formatDisplayName(user);
                          final username = user['username'] as String? ?? '';
                          final branca = _formatBrancaLabel(user['branch'] as String? ?? '');
                          final role = _formatRoleLabel(user['role'] as String? ?? '');
                          final isMaestro = user['is_maestro_specialita'] == true;
                          final initial = nome.isNotEmpty
                              ? nome[0].toUpperCase()
                              : (cognome.isNotEmpty ? cognome[0].toUpperCase() : '?');

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primaryContainer,
                                child: Text(
                                  initial,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                displayName,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                '${username.isNotEmpty ? '$username • ' : ''}$branca • $role',
                              ),
                              trailing: isMaestro
                                  ? const Tooltip(
                                      message: 'Maestro di Specialità',
                                      child: Icon(Icons.workspace_premium, color: Colors.amber),
                                    )
                                  : const Icon(Icons.chevron_right),
                              onTap: () {
                                // TODO: Aprire profilo in sola lettura
                                // context.push('/profile/view', extra: user['id']);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
