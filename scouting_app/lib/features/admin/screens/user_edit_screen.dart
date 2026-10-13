import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_provider.dart';
class UserEditScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;

  const UserEditScreen({super.key, required this.user});

  @override
  ConsumerState<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends ConsumerState<UserEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nomeController;
  late TextEditingController _cognomeController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  late TextEditingController _indirizzoController;
  late TextEditingController _civicoController;
  late TextEditingController _capController;
  late TextEditingController _comuneController;
  late TextEditingController _provinciaController;
  late TextEditingController _squadNameController;

  
  String? _status;
  String? _branch;
  String? _role;
  String? _squadRole;
  bool _canCreateGroupEvents = false;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.user['nome']);
    _cognomeController = TextEditingController(text: widget.user['cognome']);
    _emailController = TextEditingController(text: widget.user['email']);
    _telefonoController = TextEditingController(text: widget.user['telefono']);
    _indirizzoController = TextEditingController(text: widget.user['indirizzo']);
    _civicoController = TextEditingController(text: widget.user['civico']);
    _capController = TextEditingController(text: widget.user['cap']);
    _comuneController = TextEditingController(text: widget.user['comune']);
    _provinciaController = TextEditingController(text: widget.user['provincia']);
    _squadNameController = TextEditingController(text: widget.user['squad_name']);
    
    _status = widget.user['status'];
    _branch = widget.user['branch'];
    _role = widget.user['role'];
    _squadRole = widget.user['squad_role'];
    
    final extraPerms = widget.user['extra_permissions'] as Map<String, dynamic>?;
    if (extraPerms != null && extraPerms['can_create_group_events'] == true) {
      _canCreateGroupEvents = true;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cognomeController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _indirizzoController.dispose();
    _civicoController.dispose();
    _capController.dispose();
    _comuneController.dispose();
    _provinciaController.dispose();
    _squadNameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    final updatedData = {
      'nome': _nomeController.text.trim(),
      'cognome': _cognomeController.text.trim(),
      'email': _emailController.text.trim(),
      'telefono': _telefonoController.text.trim(),
      'indirizzo': _indirizzoController.text.trim(),
      'civico': _civicoController.text.trim(),
      'cap': _capController.text.trim(),
      'comune': _comuneController.text.trim(),
      'provincia': _provinciaController.text.trim(),
      'status': _status,
      'branch': _branch,
      'role': _role,
      'squad_name': _squadNameController.text.trim().isEmpty ? null : _squadNameController.text.trim(),
      'squad_role': _squadRole,
      'extra_permissions': {
        'can_create_group_events': _canCreateGroupEvents,
      },
    };

    final success = await ref.read(usersListProvider.notifier).updateUser(widget.user['id'], updatedData);
    
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utente aggiornato con successo')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Errore durante l\'aggiornamento')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentProfile = ref.watch(authProvider).profile;
    final isCurrentUserCapoGruppo = currentProfile != null && currentProfile['role'] == 'capo gruppo';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifica Utente'),
        actions: [
          IconButton(
            icon: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
              : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveChanges,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text('Informazioni Personali', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (v) => v!.isEmpty ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _cognomeController,
              decoration: const InputDecoration(labelText: 'Cognome'),
              validator: (v) => v!.isEmpty ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(labelText: 'Telefono'),
            ),
            
            const SizedBox(height: 24),
            const Text('Indirizzo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(controller: _indirizzoController, decoration: const InputDecoration(labelText: 'Indirizzo')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _civicoController, decoration: const InputDecoration(labelText: 'Civico'))),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _capController, decoration: const InputDecoration(labelText: 'CAP'))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(flex: 2, child: TextFormField(controller: _comuneController, decoration: const InputDecoration(labelText: 'Comune'))),
                const SizedBox(width: 8),
                Expanded(flex: 1, child: TextFormField(controller: _provinciaController, decoration: const InputDecoration(labelText: 'Provincia (Sigla)'))),
              ],
            ),

            const SizedBox(height: 24),
            const Text('Dati Amministrativi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Stato'),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('In Attesa')),
                DropdownMenuItem(value: 'active', child: Text('Attivo')),
                DropdownMenuItem(value: 'rejected', child: Text('Rifiutato')),
              ],
              onChanged: (val) => setState(() => _status = val),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _branch,
              decoration: const InputDecoration(labelText: 'Branca'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Non Assegnata')),
                DropdownMenuItem(value: 'Lupetti/Coccinelle', child: Text('Lupetti/Coccinelle')),
                DropdownMenuItem(value: 'Esploratori/Guide', child: Text('Esploratori/Guide')),
                DropdownMenuItem(value: 'Rover/Scolte', child: Text('Rover/Scolte')),
                DropdownMenuItem(value: 'Co.Ca.', child: Text('Co.Ca.')),
              ],
              onChanged: (val) => setState(() => _branch = val),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Ruolo'),
              items: const [
                DropdownMenuItem(value: 'socio', child: Text('Socio')),
                DropdownMenuItem(value: 'capo', child: Text('Capo (Admin)')),
              ],
              onChanged: (val) => setState(() => _role = val),
            ),
            
            if (_branch == 'Esploratori/Guide') ...[
              const SizedBox(height: 24),
              const Text('Reparto / Squadriglia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _squadNameController,
                decoration: const InputDecoration(labelText: 'Nome Squadriglia (es. Aquile)'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _squadRole,
                decoration: const InputDecoration(labelText: 'Ruolo in Squadriglia'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Nessuno (Socio Semplice)')),
                  DropdownMenuItem(value: 'capo', child: Text('Capo Squadriglia')),
                  DropdownMenuItem(value: 'vice', child: Text('Vice Capo Squadriglia')),
                ],
                onChanged: (val) => setState(() => _squadRole = val),
              ),
            ],

            if (isCurrentUserCapoGruppo) ...[
              const SizedBox(height: 24),
              const Text('Permessi Extra (Capo Gruppo)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Può creare eventi di Gruppo'),
                subtitle: const Text('Se attivo, questo capo potrà invitare tutti i soci o altre branche.'),
                value: _canCreateGroupEvents,
                onChanged: (val) => setState(() => _canCreateGroupEvents = val),
              ),
            ],
            
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: const Text('Salva Modifiche'),
            ),
          ],
        ),
      ),
    );
  }
}
