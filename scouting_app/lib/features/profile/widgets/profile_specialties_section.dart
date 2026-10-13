import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSpecialtiesSection extends StatefulWidget {
  final Map<String, dynamic> profile;

  const ProfileSpecialtiesSection({super.key, required this.profile});

  @override
  State<ProfileSpecialtiesSection> createState() => _ProfileSpecialtiesSectionState();
}

class _ProfileSpecialtiesSectionState extends State<ProfileSpecialtiesSection> {
  List<Map<String, dynamic>> _achieved = [];
  List<Map<String, dynamic>> _current = [];
  bool _isSaving = false;

  String get _branchLabel {
    final branch = widget.profile['branch'] ?? '';
    if (branch == 'l/c') return 'Specialità';
    return 'Specialità e Competenze';
  }

  @override
  void initState() {
    super.initState();
    final rawA = widget.profile['specialties_achieved'];
    if (rawA is List) {
      _achieved = List<Map<String, dynamic>>.from(rawA.map((e) => Map<String, dynamic>.from(e)));
    }
    final rawC = widget.profile['specialties_current'];
    if (rawC is List) {
      _current = List<Map<String, dynamic>>.from(rawC.map((e) => Map<String, dynamic>.from(e)));
    }
  }

  Future<void> _saveToDb() async {
    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'specialties_achieved': _achieved,
            'specialties_current': _current,
          })
          .eq('id', widget.profile['id']);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showAddDialog({required bool isAchieved}) async {
    String name = '';
    String year = DateTime.now().year.toString();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAchieved ? 'Aggiungi $_branchLabel conquistata' : 'Aggiungi $_branchLabel anno in corso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Nome $_branchLabel'),
              onChanged: (v) => name = v,
            ),
            if (isAchieved) ...[
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(labelText: 'Anno di conquista (es. 2024)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => year = v,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          FilledButton(
            onPressed: () {
              if (name.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Inserisci un nome')),
                );
                return;
              }
              Navigator.pop(ctx);
              setState(() {
                if (isAchieved) {
                  _achieved = [..._achieved, {'name': name.trim(), 'year': year}];
                } else {
                  _current = [..._current, {'name': name.trim(), 'status': 'in_corso'}];
                }
              });
              _saveToDb();
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(bool isAchieved, int index) async {
    setState(() {
      if (isAchieved) {
        _achieved = [..._achieved]..removeAt(index);
      } else {
        _current = [..._current]..removeAt(index);
      }
    });
    await _saveToDb();
  }

  Widget _buildChipList(List<Map<String, dynamic>> items, bool isAchieved, Color color) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          isAchieved ? 'Nessuna specialità conquistata ancora.' : 'Nessuna specialità in corso.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: List.generate(items.length, (i) {
        final item = items[i];
        final label = isAchieved
            ? '${item['name']}${item['year'] != null ? ' (${item['year']})' : ''}'
            : item['name'] ?? '';
        return Chip(
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: color.withOpacity(0.15),
          side: BorderSide(color: color.withOpacity(0.4)),
          deleteIcon: Icon(Icons.close, size: 16, color: color),
          onDeleted: () => _deleteItem(isAchieved, i),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.tertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _branchLabel,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (_isSaving)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
        const SizedBox(height: 16),

        // Sezione "Conquistate (anni precedenti)"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '✅ Conquistate',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
            ),
            TextButton.icon(
              onPressed: () => _showAddDialog(isAchieved: true),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Aggiungi'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildChipList(_achieved, true, primaryColor),
        const SizedBox(height: 20),

        // Sezione "Anno in corso"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🎯 Anno in corso',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: secondaryColor,
                  ),
            ),
            TextButton.icon(
              onPressed: () => _showAddDialog(isAchieved: false),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Aggiungi'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildChipList(_current, false, secondaryColor),
      ],
    );
  }
}
