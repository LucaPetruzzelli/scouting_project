import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/campetti_provider.dart';

/// Restituisce i tipi di campetto disponibili in base alla branca e al ruolo
List<String> getCampettoTypes(String branch, String role) {
  final isCapo = role == 'capo' || role == 'capo gruppo';
  if (isCapo) {
    return ['CFT', 'CFM L/C', 'CFM E/G', 'CFM R/S', 'CFA', 'CCG'];
  }
  switch (branch) {
    case 'l/c':
      return ['Piccole Orme', 'Piccole Tracce', 'Altro L/C'];
    case 'e/g':
      return ['Specialità', 'Capi Squadriglia', 'Specialità Squadriglia', 'Competenza', 'Candidature Competenza', 'Guidoncini verdi', 'Maestro di competenza', 'Altro E/G'];
    case 'r/s':
      return ['ROSS', 'Partenti', 'EPPPI', 'Campi R/S estero', 'Altro R/S'];
    default:
      return ['Altro'];
  }
}

class ProfileCampettiSection extends ConsumerStatefulWidget {
  final Map<String, dynamic> profile;

  const ProfileCampettiSection({super.key, required this.profile});

  @override
  ConsumerState<ProfileCampettiSection> createState() => _ProfileCampettiSectionState();
}

class _ProfileCampettiSectionState extends ConsumerState<ProfileCampettiSection> {
  Future<void> _showAddDialog() async {
    final branch = widget.profile['branch'] ?? '';
    final role = widget.profile['role'] ?? 'socio';
    final types = getCampettoTypes(branch, role);

    String title = '';
    String selectedType = types.first;
    DateTime? startDate;
    DateTime? endDate;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Aggiungi campo svolto'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Titolo'),
                    onChanged: (v) => title = v,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setDialogState(() => selectedType = v ?? types.first),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(startDate == null
                        ? 'Data inizio: non selezionata'
                        : 'Inizio: ${DateFormat('dd/MM/yyyy').format(startDate!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setDialogState(() => startDate = d);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(endDate == null
                        ? 'Data fine: non selezionata'
                        : 'Fine: ${DateFormat('dd/MM/yyyy').format(endDate!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setDialogState(() => endDate = d);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
              FilledButton(
                onPressed: () async {
                  if (title.trim().isEmpty || startDate == null || endDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Compila tutti i campi')),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  final success = await ref.read(myCampettiProvider.notifier).addCampetto(
                    title.trim(), selectedType, startDate!, endDate!
                  );
                  if (success && mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Richiesta aggiunta! In attesa di validazione.')),
                    );
                  }
                },
                child: const Text('Aggiungi'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final campettiAsync = ref.watch(myCampettiProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Campi svolti',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Aggiorna',
                  onPressed: () {
                    ref.read(myCampettiProvider.notifier).loadCampetti();
                  },
                ),
                TextButton.icon(
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Aggiungi'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        campettiAsync.when(
          data: (campetti) {
            if (campetti.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Nessun campo aggiunto ancora.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              );
            }
            return Column(
              children: campetti.map((c) {
                final start = DateTime.tryParse(c['data_inizio'] ?? '');
                final end = DateTime.tryParse(c['data_fine'] ?? '');
                final dateStr = (start != null && end != null)
                    ? '${DateFormat('dd/MM/yyyy').format(start)} — ${DateFormat('dd/MM/yyyy').format(end)}'
                    : '';
                
                final status = c['status'];
                IconData statusIcon = Icons.pending_actions;
                Color statusColor = Colors.orange;
                if (status == 'approved') {
                  statusIcon = Icons.check_circle;
                  statusColor = Colors.green;
                } else if (status == 'rejected') {
                  statusIcon = Icons.cancel;
                  statusColor = Colors.red;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.backpack_outlined, color: Theme.of(context).colorScheme.primary),
                    ),
                    title: Text(c['titolo'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((c['tipo'] ?? '').isNotEmpty)
                          Chip(
                            label: Text(c['tipo'], style: const TextStyle(fontSize: 11)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        if (dateStr.isNotEmpty)
                          Text(dateStr, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'Stato: $status',
                          child: Icon(statusIcon, color: statusColor, size: 20),
                        ),
                        if (status == 'pending')
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Rimuovi richiesta'),
                                  content: const Text('Sei sicuro di voler eliminare questa richiesta?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Rimuovi')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                ref.read(myCampettiProvider.notifier).removeCampetto(c['id']);
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Text('Errore nel caricamento: $e'),
        ),
      ],
    );
  }
}
