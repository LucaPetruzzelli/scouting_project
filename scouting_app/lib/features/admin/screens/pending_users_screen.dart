import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../../profile/providers/campetti_provider.dart';
import '../../profile/providers/censimenti_provider.dart';
import '../../profile/repositories/censimenti_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class PendingUsersScreen extends ConsumerWidget {
  const PendingUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pannello di Gestione'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(pendingUsersProvider.notifier).loadPendingUsers();
                ref.read(pendingCampettiProvider.notifier).loadPending();
                ref.read(pendingCensimentiProvider.notifier).loadPending();
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Iscrizioni', icon: Icon(Icons.person_add)),
              Tab(text: 'Campi svolti', icon: Icon(Icons.backpack)),
              Tab(text: 'Censimenti', icon: Icon(Icons.security)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PendingUsersTab(),
            _PendingCampettiTab(),
            _PendingCensimentiTab(),
          ],
        ),
      ),
    );
  }
}

class _PendingUsersTab extends ConsumerWidget {
  const _PendingUsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingUsersAsync = ref.watch(pendingUsersProvider);

    return pendingUsersAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return const Center(child: Text('Nessun utente in attesa.'));
        }
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildUserCard(context, ref, user);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Errore: $err')),
    );
  }

  Widget _buildUserCard(BuildContext context, WidgetRef ref, Map<String, dynamic> user) {
    final nome = user['nome'] ?? '';
    final cognome = user['cognome'] ?? '';
    final email = user['email'] ?? '';
    
    String eta = '';
    if (user['data_di_nascita'] != null) {
      final dob = DateTime.tryParse(user['data_di_nascita']);
      if (dob != null) {
        final age = DateTime.now().year - dob.year;
        eta = '$age anni';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text('$nome $cognome', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$email - $eta'),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text('Rifiuta', style: TextStyle(color: Colors.red)),
                  onPressed: () => _confirmReject(context, ref, user['id'], '$nome $cognome'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Revisiona e Approva'),
                  onPressed: () => _showEditAndApproveDialog(context, ref, user),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _confirmReject(BuildContext context, WidgetRef ref, String userId, String fullName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rifiutare Registrazione?'),
        content: Text('Sei sicuro di voler rifiutare l\'iscrizione di $fullName? L\'account non potrà più accedere.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(pendingUsersProvider.notifier).rejectUser(userId);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utente rifiutato con successo')));
              }
            },
            child: const Text('Rifiuta', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditAndApproveDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> user) {
    final nomeController = TextEditingController(text: user['nome'] ?? '');
    final cognomeController = TextEditingController(text: user['cognome'] ?? '');
    
    // Convert to strict branch names if present
    String branch = user['branch'] ?? 'Branco';
    if (!['Branco', 'Reparto', 'Clan/Fuoco', 'Co.Ca.'].contains(branch)) {
      branch = 'Branco';
    }

    String role = user['role'] ?? 'socio';
    if (!['socio', 'capo', 'capo gruppo'].contains(role)) {
      role = 'socio';
    }

    String genere = user['genere'] ?? 'M';
    
    final squadNameController = TextEditingController(text: user['squad_name'] ?? '');
    String? squadRole = user['squad_role'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Revisiona e Approva'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Verifica ed eventualmente correggi i dati prima di accettare l\'iscrizione:'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nomeController,
                    decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cognomeController,
                    decoration: const InputDecoration(labelText: 'Cognome', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: genere,
                    decoration: const InputDecoration(labelText: 'Genere', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'M', child: Text('Maschio')),
                      DropdownMenuItem(value: 'F', child: Text('Femmina')),
                      DropdownMenuItem(value: 'O', child: Text('Altro')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => genere = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: branch,
                    decoration: const InputDecoration(labelText: 'Branca Assegnata', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Branco', child: Text('Branco')),
                      DropdownMenuItem(value: 'Reparto', child: Text('Reparto')),
                      DropdownMenuItem(value: 'Clan/Fuoco', child: Text('Clan/Fuoco')),
                      DropdownMenuItem(value: 'Co.Ca.', child: Text('Co.Ca.')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => branch = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'Ruolo', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'socio', child: Text('Socio')),
                      DropdownMenuItem(value: 'capo', child: Text('Capo')),
                      DropdownMenuItem(value: 'capo gruppo', child: Text('Capo Gruppo')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => role = val);
                    },
                  ),
                  if (branch == 'Reparto') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: squadNameController,
                      decoration: const InputDecoration(labelText: 'Nome Squadriglia (es. Aquile)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: squadRole,
                      decoration: const InputDecoration(labelText: 'Ruolo in Squadriglia', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Nessuno (Socio Semplice)')),
                        DropdownMenuItem(value: 'capo', child: Text('Capo Squadriglia')),
                        DropdownMenuItem(value: 'vice', child: Text('Vice Capo Squadriglia')),
                      ],
                      onChanged: (val) => setState(() => squadRole = val),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  
                  final updatedData = {
                    'nome': nomeController.text,
                    'cognome': cognomeController.text,
                    'genere': genere,
                    'branch': branch,
                    'role': role,
                    'squad_name': squadNameController.text.trim().isEmpty ? null : squadNameController.text.trim(),
                    'squad_role': squadRole,
                  };
                  
                  final success = await ref.read(pendingUsersProvider.notifier).approveUser(user['id'], updatedData);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utente approvato e aggiornato con successo!')));
                  }
                },
                child: const Text('Salva e Approva'),
              ),
            ],
          );
        }
      ),
    );
  }
}

class _PendingCampettiTab extends ConsumerWidget {
  const _PendingCampettiTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCampettiAsync = ref.watch(pendingCampettiProvider);

    return pendingCampettiAsync.when(
      data: (campetti) {
        if (campetti.isEmpty) {
          return const Center(child: Text('Nessun campo in attesa di validazione.'));
        }
        return ListView.builder(
          itemCount: campetti.length,
          itemBuilder: (context, index) {
            final c = campetti[index];
            final profile = c['profiles']; // Dati joinati da Supabase
            final reqNome = profile?['nome'] ?? '';
            final reqCognome = profile?['cognome'] ?? '';
            final reqBranch = profile?['branch'] ?? '';
            final reqRole = profile?['role'] ?? '';

            final start = DateTime.tryParse(c['data_inizio'] ?? '');
            final end = DateTime.tryParse(c['data_fine'] ?? '');
            final dateStr = (start != null && end != null)
                ? '${DateFormat('dd/MM/yyyy').format(start)} — ${DateFormat('dd/MM/yyyy').format(end)}'
                : '';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ExpansionTile(
                title: Text(c['titolo'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Richiesto da: $reqNome $reqCognome ($reqRole, $reqBranch)'),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                  child: Icon(Icons.backpack, color: Theme.of(context).colorScheme.onTertiaryContainer),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((c['tipo'] ?? '').isNotEmpty) Text('Tipo: ${c['tipo']}'),
                        if (dateStr.isNotEmpty) Text('Periodo: $dateStr'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text('Rifiuta', style: TextStyle(color: Colors.red)),
                          onPressed: () async {
                            final success = await ref.read(pendingCampettiProvider.notifier).reject(c['id']);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Campo rifiutato')));
                            }
                          },
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Approva'),
                          onPressed: () async {
                            final success = await ref.read(pendingCampettiProvider.notifier).approve(c['id']);
                            if (context.mounted) {
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Campo approvato!')));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Errore: non hai i permessi RLS per approvare questo campo.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Errore: $err')),
    );
  }
}

class _PendingCensimentiTab extends ConsumerWidget {
  const _PendingCensimentiTab();

  Future<void> _viewDocument(BuildContext context, WidgetRef ref, String filePath) async {
    final url = await ref.read(censimentiRepositoryProvider).getFileUrl(filePath);
    if (url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossibile aprire il file')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCensimentiAsync = ref.watch(pendingCensimentiProvider);

    return pendingCensimentiAsync.when(
      data: (documents) {
        if (documents.isEmpty) {
          return const Center(child: Text('Nessun documento in attesa di validazione.'));
        }
        return ListView.builder(
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final c = documents[index];
            final profile = c['profiles'];
            final reqNome = profile?['nome'] ?? '';
            final reqCognome = profile?['cognome'] ?? '';
            final reqBranch = profile?['branch'] ?? '';
            final reqRole = profile?['role'] ?? '';
            final anno = c['anno'] ?? DateTime.now().year;
            final docType = c['document_type'] ?? 'Documento Sconosciuto';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ExpansionTile(
                title: Text('$docType (Censimento $anno)', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Caricato da: $reqNome $reqCognome ($reqRole, $reqBranch)'),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(Icons.description, color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton.icon(
                      onPressed: () => _viewDocument(context, ref, c['file_url']),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Visualizza Documento'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text('Rifiuta', style: TextStyle(color: Colors.red)),
                          onPressed: () async {
                            final success = await ref.read(pendingCensimentiProvider.notifier).reject(c['id']);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documento rifiutato')));
                            }
                          },
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Approva'),
                          onPressed: () async {
                            final success = await ref.read(pendingCensimentiProvider.notifier).approve(c['id']);
                            if (context.mounted) {
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documento approvato!')));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Errore durante l\'approvazione.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Errore: $err')),
    );
  }
}
