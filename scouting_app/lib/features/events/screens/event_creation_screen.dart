import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/event_model.dart';
import '../providers/events_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import '../widgets/multi_select_target_dialog.dart';

class EventCreationScreen extends ConsumerStatefulWidget {
  final EventModel? eventToEdit;
  const EventCreationScreen({super.key, this.eventToEdit});

  @override
  ConsumerState<EventCreationScreen> createState() => _EventCreationScreenState();
}

class _EventCreationScreenState extends ConsumerState<EventCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _feeController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  String _eventType = 'Riunione';
  bool _hasFee = false;
  bool _hasGroups = false;

  // Target Settings
  late TargetSelection _targetSelection;

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      final e = widget.eventToEdit!;
      _titleController.text = e.title;
      _descController.text = e.description ?? '';
      _locationController.text = e.location ?? '';
      _eventType = e.eventType;
      _hasFee = e.fee != null;
      if (e.fee != null) {
        _feeController.text = e.fee.toString();
      }
      _startDate = e.startDate;
      _endDate = e.endDate;
      _hasGroups = e.hasGroups;
      _targetSelection = TargetSelection(
        roles: e.targetRoles,
        branches: e.targetBranches,
        squads: e.targetSquads,
        users: e.targetUsers,
      );
      _initialized = true;
    } else {
      // Inizializzazione temporanea, verrà sovrascritta nel primo build quando il profilo è disponibile
      _targetSelection = TargetSelection(roles: [], branches: [], squads: [], users: []);
    }
  }

  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    final dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startDate = dateTime;
        if (_endDate == null || _endDate!.isBefore(dateTime)) {
          _endDate = dateTime.add(const Duration(hours: 2));
        }
      } else {
        _endDate = dateTime;
      }
    });
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleziona le date dell\'evento')));
      return;
    }

    final profile = ref.read(authProvider).profile;
    if (profile == null) return;

    final role = profile['role'] as String?;
    final branch = profile['branch'] as String?;
    final squadName = profile['squad_name'] as String?;
    final squadRole = profile['squad_role'] as String?;
    final extraPerms = profile['extra_permissions'] as Map<String, dynamic>?;
    final canCreateGroup = extraPerms?['can_create_group_events'] == true;

    List<String> finalRoles = List.from(_targetSelection.roles);
    List<String> finalBranches = List.from(_targetSelection.branches);
    List<String> finalSquads = List.from(_targetSelection.squads);
    List<String> finalUsers = List.from(_targetSelection.users);

    final isCapoGruppo = role == 'capo gruppo';
    final isCapoUnita = role == 'capo';
    final isCapoSquad = role == 'socio' && (squadRole == 'capo' || squadRole == 'vice');

    if (!isCapoGruppo && !(isCapoUnita && canCreateGroup)) {
      if (isCapoUnita) {
        // Forza la branca del capo se non specificata (già filtrata dal dialog, ma per sicurezza backend-side)
        if (finalBranches.isEmpty && finalUsers.isEmpty) {
          finalBranches = [branch ?? ''];
        }
      } else if (isCapoSquad) {
        // Forza squadriglia
        if (finalSquads.isEmpty && finalUsers.isEmpty) {
          finalSquads = [squadName ?? ''];
        }
      }
    }

    setState(() => _isSaving = true);

    try {
      final event = EventModel(
        id: widget.eventToEdit?.id ?? '', // Lasciamo generare a Supabase se vuoto
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        location: _locationController.text.trim(),
        createdBy: widget.eventToEdit?.createdBy ?? profile['id'],
        targetRoles: finalRoles,
        targetBranches: finalBranches,
        targetSquads: finalSquads,
        targetUsers: finalUsers,
        eventType: _eventType,
        fee: _hasFee ? double.tryParse(_feeController.text.replaceAll(',', '.')) : null,
        hasGroups: _hasGroups,
        groupsData: widget.eventToEdit?.groupsData ?? const [],
        createdAt: widget.eventToEdit?.createdAt ?? DateTime.now(),
      );

      if (_hasGroups) {
        setState(() => _isSaving = false);
        context.push('/events/create/groups', extra: event);
      } else {
        if (event.id.isNotEmpty) {
          await ref.read(eventsProvider.notifier).updateEvent(event);
        } else {
          await ref.read(eventsProvider.notifier).createEvent(event);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(event.id.isNotEmpty ? 'Evento aggiornato!' : 'Evento creato!')));
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authProvider).profile;
    if (profile == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (!_initialized) {
      final userBranch = profile['branch'] as String?;
      if (userBranch != null && userBranch.isNotEmpty) {
        _targetSelection = TargetSelection(roles: [], branches: [userBranch], squads: [], users: []);
      }
      _initialized = true;
    }

    final role = profile['role'] as String?;
    final branch = profile['branch'] as String?;
    final extraPerms = profile['extra_permissions'] as Map<String, dynamic>?;
    
    final canCreateGroup = extraPerms?['can_create_group_events'] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventToEdit != null ? 'Modifica Evento' : 'Nuovo Evento'),
        actions: [
          IconButton(
            icon: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Icon(_hasGroups ? Icons.arrow_forward : Icons.check),
            onPressed: _isSaving ? null : _saveEvent,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _eventType,
              decoration: const InputDecoration(labelText: 'Tipo di Evento', border: OutlineInputBorder()),
              items: ['Riunione', 'Uscita', 'Campo', 'Altro'].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _eventType = val);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titolo Evento', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Obbligatorio' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Descrizione (opzionale)', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Luogo (opzionale)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Prevede una quota?'),
              value: _hasFee,
              onChanged: (val) => setState(() => _hasFee = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (_hasFee)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextFormField(
                  controller: _feeController,
                  decoration: const InputDecoration(labelText: 'Quota (€)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.euro)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => v!.isEmpty ? 'Inserisci la quota' : null,
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_month),
                    label: Text(_startDate == null ? 'Inizio' : DateFormat('dd/MM/yy HH:mm').format(_startDate!)),
                    onPressed: () => _pickDateTime(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(_endDate == null ? 'Fine' : DateFormat('dd/MM/yy HH:mm').format(_endDate!)),
                    onPressed: () => _pickDateTime(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Prevede la divisione in gruppi?'),
              subtitle: const Text('Seleziona per smistare i partecipanti in sottogruppi'),
              value: _hasGroups,
              onChanged: (val) => setState(() => _hasGroups = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            const Text('Destinatari', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            Card(
              child: ListTile(
                leading: const Icon(Icons.people),
                title: Text(_targetSelection.branches.isEmpty && _targetSelection.roles.isEmpty && _targetSelection.squads.isEmpty && _targetSelection.users.isEmpty
                    ? 'Tutto il gruppo (o default)'
                    : 'Selezione personalizzata'),
                subtitle: Text(
                  'Branche: ${_targetSelection.branches.length} | Ruoli: ${_targetSelection.roles.length} | Squadriglie: ${_targetSelection.squads.length} | Utenti Singoli: ${_targetSelection.users.length}'
                ),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final result = await showDialog<TargetSelection>(
                    context: context,
                    builder: (context) => MultiSelectTargetDialog(
                      initialSelection: _targetSelection,
                      userRole: role ?? 'socio',
                      userBranch: branch ?? '',
                      userSquad: profile['squad_name'] ?? '',
                      canCreateGroupEvents: canCreateGroup,
                    ),
                  );

                  if (result != null) {
                    setState(() => _targetSelection = result);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
