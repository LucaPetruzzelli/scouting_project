import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../events/models/event_model.dart';
import '../../events/providers/events_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../events/providers/event_payments_provider.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authProvider).profile;
    final isCapo = profile != null &&
        (profile['role'] == 'capo' || profile['role'] == 'capo gruppo');
    // Tab: Dettagli sempre visibile; Presenze e Quote solo per capi
    final tabCount = isCapo ? 3 : 1;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authProvider).profile;
    final role = profile?['role'] ?? 'socio';
    final isCapo = role == 'capo' || role == 'capo gruppo';
    final isCreator = profile != null && widget.event.createdBy == profile['id'];

    final color = _eventTypeColor(widget.event.eventType);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            actions: [
              if (isCapo || isCreator)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      context.push('/events/edit', extra: widget.event);
                    } else if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Elimina evento'),
                          content: const Text('Sei sicuro di voler eliminare questo evento?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Elimina', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && mounted) {
                        await ref.read(eventsProvider.notifier).deleteEvent(widget.event.id);
                        if (mounted) context.pop();
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    if (isCapo || isCreator)
                      const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Modifica'))),
                    if (isCapo || isCreator)
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Elimina', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                  ],
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.event.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _eventTypeIcon(widget.event.eventType),
                    size: 80,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ),
            bottom: isCapo
                ? TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Colors.white,
                    tabs: const [
                      Tab(text: 'Dettagli'),
                      Tab(text: 'Presenze'),
                      Tab(text: 'Quote'),
                    ],
                  )
                : null,
          ),
        ],
        body: isCapo
            ? TabBarView(
                controller: _tabController,
                children: [
                  _buildDetailsTab(profile),
                  _buildAttendanceTab(profile),
                  _buildPaymentsTab(profile),
                ],
              )
            : _buildDetailsTab(profile),
      ),
    );
  }

  // ─── TAB DETTAGLI ────────────────────────────────────────────────────────────

  Widget _buildDetailsTab(Map<String, dynamic>? profile) {
    final e = widget.event;
    final dateFormat = DateFormat('EEEE d MMMM yyyy', 'it_IT');
    final timeFormat = DateFormat('HH:mm');
    final role = profile?['role'] ?? 'socio';
    final isAdult = profile?['is_adult'] == true;
    final canConfirm = isAdult || role == 'socio'; // tutti i soci maggiorenni possono confermare

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tipo di evento
        _infoChip(e.eventType, _eventTypeColor(e.eventType)),

        const SizedBox(height: 16),

        // Date e orari
        _infoCard(
          icon: Icons.calendar_today,
          title: 'Data e orario',
          content: '${dateFormat.format(e.startDate)}\n${timeFormat.format(e.startDate)} – ${timeFormat.format(e.endDate)}',
        ),

        // Luogo
        if (e.location != null && e.location!.isNotEmpty)
          _infoCard(
            icon: Icons.location_on,
            title: 'Luogo',
            content: e.location!,
          ),

        // Descrizione
        if (e.description != null && e.description!.isNotEmpty)
          _infoCard(
            icon: Icons.description,
            title: 'Descrizione',
            content: e.description!,
          ),

        // Quota
        if (e.fee != null)
          _infoCard(
            icon: Icons.euro,
            title: 'Quota di partecipazione',
            content: '€ ${e.fee!.toStringAsFixed(2)}',
            contentColor: Colors.green,
          ),

        // Target (solo capi)
        if (profile != null && (profile['role'] == 'capo' || profile['role'] == 'capo gruppo')) ...[
          if (e.targetBranches.isNotEmpty)
            _infoCard(
              icon: Icons.groups,
              title: 'Branche destinatarie',
              content: e.targetBranches.join(', '),
            ),
          if (e.targetRoles.isNotEmpty)
            _infoCard(
              icon: Icons.badge,
              title: 'Ruoli destinatari',
              content: e.targetRoles.join(', '),
            ),
        ],

        const SizedBox(height: 20),

        // Pulsante conferma presenza (soci maggiorenni)
        if (canConfirm) ...[
          const Text(
            'La tua partecipazione',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          _AttendanceConfirmationWidget(event: widget.event, profile: profile),
        ],

        const SizedBox(height: 20),

        // Pulsante gestione logistica (solo capi)
        // Solo i capi possono aggiungere/rimuovere membri del gruppo logistica
        if (profile != null && (profile['role'] == 'capo' || profile['role'] == 'capo gruppo')) ...[
          if (e.logisticsUsers.isNotEmpty || profile['role'] == 'capo' || profile['role'] == 'capo gruppo')
            OutlinedButton.icon(
              icon: const Icon(Icons.local_shipping, size: 20),
              label: const Text('Gestisci Logistica'),
              onPressed: () => context.push('/events/logistics', extra: e),
            ),
        ],

        const SizedBox(height: 20),

        // Pulsante gestione quote (se prevede quota ed è capo/logistica)
        if (e.fee != null) ...[
          if (profile != null &&
              (profile['role'] == 'capo' ||
                  profile['role'] == 'capo gruppo' ||
                  (e.logisticsUsers.contains(profile['id'])))) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.euro),
              label: const Text('Gestisci Quote'),
              onPressed: () => context.push('/events/payments', extra: e),
            ),
          ] else ...[
            // Socio: mostra solo il suo stato pagamento
            _SocioPaymentStatusWidget(event: widget.event, profile: profile),
          ],
        ],
      ],
    );
  }

  // ─── TAB PRESENZE (solo capi) ─────────────────────────────────────────────

  Widget _buildAttendanceTab(Map<String, dynamic>? profile) {
    final paymentsAsync = ref.watch(eventPaymentsProvider(widget.event));

    return paymentsAsync.when(
      data: (data) {
        final participants = data['participants'] as List<Map<String, dynamic>>;
        if (participants.isEmpty) {
          return const Center(child: Text('Nessun partecipante registrato.'));
        }

        final present = participants.where((p) => p['actual_present'] == true).length;
        final absent = participants.where((p) => p['actual_present'] == false).length;
        final pending = participants.length - present - absent;

        return Column(
          children: [
            // Riepilogo presenze
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statBadge('Presenti', present, Colors.green),
                  _statBadge('Assenti', absent, Colors.red),
                  _statBadge('N/D', pending, Colors.grey),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final p = participants[index];
                  final nome = '${p['nome'] ?? ''} ${p['cognome'] ?? ''}'.trim();
                  final isPresent = p['actual_present'];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPresent == true
                          ? Colors.green.withOpacity(0.2)
                          : isPresent == false
                              ? Colors.red.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                      child: Text(
                        nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: isPresent == true
                              ? Colors.green
                              : isPresent == false
                                  ? Colors.red
                                  : Colors.grey,
                        ),
                      ),
                    ),
                    title: Text(nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(p['branch'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pulsante presente
                        IconButton(
                          icon: Icon(
                            Icons.check_circle,
                            color: isPresent == true ? Colors.green : Colors.grey.shade300,
                          ),
                          onPressed: () => ref
                              .read(eventPaymentsProvider(widget.event).notifier)
                              .markAttendance(p['id'], true),
                          tooltip: 'Presente',
                        ),
                        // Pulsante assente
                        IconButton(
                          icon: Icon(
                            Icons.cancel,
                            color: isPresent == false ? Colors.red : Colors.grey.shade300,
                          ),
                          onPressed: () => ref
                              .read(eventPaymentsProvider(widget.event).notifier)
                              .markAttendance(p['id'], false),
                          tooltip: 'Assente',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Errore: $err')),
    );
  }

  // ─── TAB QUOTE (solo capi) ────────────────────────────────────────────────

  Widget _buildPaymentsTab(Map<String, dynamic>? profile) {
    if (widget.event.fee == null) {
      return const Center(
        child: Text('Questo evento non prevede una quota.'),
      );
    }
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.euro),
        label: const Text('Apri Gestione Quote'),
        onPressed: () => context.push('/events/payments', extra: widget.event),
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────────

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String content,
    Color? contentColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(
          content,
          style: TextStyle(
            color: contentColor ?? Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _infoChip(String label, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _statBadge(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    );
  }

  Color _eventTypeColor(String type) {
    switch (type) {
      case 'Riunione': return Colors.blue;
      case 'Uscita': return Colors.green;
      case 'Campo': return Colors.orange;
      default: return Colors.purple;
    }
  }

  IconData _eventTypeIcon(String type) {
    switch (type) {
      case 'Riunione': return Icons.groups_2;
      case 'Uscita': return Icons.hiking;
      case 'Campo': return Icons.cabin;
      default: return Icons.event;
    }
  }
}

// ─── WIDGET CONFERMA PRESENZA ─────────────────────────────────────────────────

class _AttendanceConfirmationWidget extends ConsumerStatefulWidget {
  final EventModel event;
  final Map<String, dynamic>? profile;

  const _AttendanceConfirmationWidget({required this.event, required this.profile});

  @override
  ConsumerState<_AttendanceConfirmationWidget> createState() =>
      _AttendanceConfirmationWidgetState();
}

class _AttendanceConfirmationWidgetState
    extends ConsumerState<_AttendanceConfirmationWidget> {
  String _status = 'pending'; // pending, confirmed, declined
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confermo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: BorderSide(
                color: _status == 'confirmed' ? Colors.green : Colors.grey,
                width: _status == 'confirmed' ? 2 : 1,
              ),
              backgroundColor: _status == 'confirmed' ? Colors.green.withOpacity(0.1) : null,
            ),
            onPressed: _loading ? null : () => _setAttendance('confirmed'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Non vengo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(
                color: _status == 'declined' ? Colors.red : Colors.grey,
                width: _status == 'declined' ? 2 : 1,
              ),
              backgroundColor: _status == 'declined' ? Colors.red.withOpacity(0.1) : null,
            ),
            onPressed: _loading ? null : () => _setAttendance('declined'),
          ),
        ),
      ],
    );
  }

  Future<void> _setAttendance(String status) async {
    setState(() => _loading = true);
    try {
      final userId = widget.profile?['id'] as String?;
      if (userId == null) return;
      
      await ref
          .read(eventPaymentsProvider(widget.event).notifier)
          .confirmAttendance(userId, status);
      
      if (mounted) setState(() => _status = status);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── WIDGET STATO PAGAMENTO SOCIO ────────────────────────────────────────────

class _SocioPaymentStatusWidget extends ConsumerWidget {
  final EventModel event;
  final Map<String, dynamic>? profile;

  const _SocioPaymentStatusWidget({required this.event, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Recupera il pagamento del socio stesso
    final paymentsAsync = ref.watch(eventPaymentsProvider(event));

    return paymentsAsync.when(
      data: (data) {
        final participants = data['participants'] as List<Map<String, dynamic>>;
        final userId = profile?['id'] as String?;
        final myEntry = participants.where((p) => p['id'] == userId).firstOrNull;

        if (myEntry == null) return const SizedBox.shrink();

        final hasPaid = myEntry['has_paid'] == true;

        return Card(
          color: hasPaid
              ? Colors.green.withOpacity(0.1)
              : Colors.orange.withOpacity(0.1),
          child: ListTile(
            leading: Icon(
              hasPaid ? Icons.check_circle : Icons.pending,
              color: hasPaid ? Colors.green : Colors.orange,
            ),
            title: Text(
              hasPaid ? 'Quota pagata' : 'Quota da pagare',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: hasPaid ? Colors.green : Colors.orange,
              ),
            ),
            subtitle: Text(
              hasPaid
                  ? 'Il capo ha confermato il pagamento'
                  : 'Quota: € ${event.fee!.toStringAsFixed(2)}. Il capo verificherà il tuo bonifico.',
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
