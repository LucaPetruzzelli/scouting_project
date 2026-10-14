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

  final List<String> _branche = ['Tutte', 'Branco', 'Reparto', 'Clan/Fuoco', 'Comunità Capi'];
  final List<String> _ruoli = ['Tutti', 'Socio', 'Capo'];

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    try {
      final queryText = _searchController.text.trim().toLowerCase();
      var query = Supabase.instance.client
          .from('profiles')
          .select('id, first_name, last_name, username, jungle_name, branca, role, avatar_url, is_maestro_specialita, specialties_mastered')
          .eq('status', 'approved');

      if (_selectedBranca != 'Tutte') {
        query = query.eq('branca', _selectedBranca);
      }
      if (_selectedRole == 'Capo') {
        query = query.ilike('role', '%capo%');
      } else if (_selectedRole == 'Socio') {
        query = query.not('role', 'ilike', '%capo%');
      }
      if (_onlyMaestriSpecialita) {
        query = query.eq('is_maestro_specialita', true);
      }

      final data = await query.order('first_name');
     final filtered = (data as List).cast<Map<String, dynamic>>().where((user) {
      final roleStr = (user['role'] ?? '').toString().toLowerCase();
      if (_selectedRole == 'Capo' && !roleStr.contains('capo') && !roleStr.contains('leader')) {
        return false;
      }
      if (_selectedRole == 'Socio' && (roleStr.contains('capo') || roleStr.contains('leader'))) {
        return false;
  }
  if (queryText.isEmpty) return true;
        final username = (user['username'] ?? '').toString().toLowerCase();
        final fullName = '${user['first_name']} ${user['last_name']}'.toLowerCase();
        final jungle = (user['jungle_name'] ?? '').toString().toLowerCase();
        return username.contains(queryText) ||
            fullName.contains(queryText) ||
            jungle.contains(queryText);
      }).toList();

      if (mounted) setState(() => _results = filtered);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDisplayName(Map<String, dynamic> user) {
    final isCapoBranco = user['branca'] == 'Branco' &&
        (user['role'] ?? '').toString().toLowerCase().contains('capo') &&
        (user['jungle_name'] ?? '').toString().isNotEmpty;
    if (isCapoBranco) {
      return '${user['jungle_name']} (${user['first_name']} ${user['last_name']})';
    }
    return '${user['first_name']} ${user['last_name']}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ricerca Membri')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _performSearch(),
              decoration: InputDecoration(
                hintText: 'Cerca per nome o @username (es. @mariorossi)',
                prefixIcon: const Icon(Icons.search_rounded),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedBranca,
                    items: _branche
                        .map((b) => DropdownMenuItem(value: b, child: Text('Branca: $b')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedBranca = v);
                        _performSearch();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
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
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const Center(child: Text('Nessun membro trovato con questi filtri.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _results.length,
                        itemBuilder: (ctx, i) {
                          final user = _results[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text((user['first_name'] ?? 'U')[0].toUpperCase()),
                              ),
                              title: Text(
                                _formatDisplayName(user),
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                '${user['username'] ?? ''} • ${user['branca'] ?? ''} (${user['role'] ?? ''})',
                              ),
                              trailing: user['is_maestro_specialita'] == true
                                  ? const Tooltip(
                                      message: 'Maestro di Specialità',
                                      child: Icon(Icons.workspace_premium, color: Colors.amber),
                                    )
                                  : const Icon(Icons.chevron_right),
                              onTap: () {
                                // Apre il profilo in sola lettura rispettando le regole di privacy
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