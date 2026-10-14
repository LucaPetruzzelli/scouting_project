// lib/features/warehouse/screens/warehouse_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WarehouseScreen extends StatefulWidget {
  final String userBranca; // 'Branco', 'Reparto', 'Clan/Fuoco', 'Gruppo'
  final bool canEditPermanent; // True se Capo o Magazziniere fisso
  final bool hasTemporaryLogisticsAccess; // True se membro Logistica durante un evento attivo

  const WarehouseScreen({
    super.key,
    required this.userBranca,
    required this.canEditPermanent,
    required this.hasTemporaryLogisticsAccess,
  });

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  bool get _hasAccess =>
      widget.userBranca != 'Branco' &&
      (widget.canEditPermanent || widget.hasTemporaryLogisticsAccess);

  @override
  void initState() {
    super.initState();
    if (_hasAccess) _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client
          .from('warehouse_inventory')
          .select()
          .order('name');
      if (mounted) {
        setState(() => _items = (res as List).cast<Map<String, dynamic>>());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Magazzino di Gruppo')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Accesso riservato ai Capi, ai Magazzinieri di Reparto/Clan '
              'e ai membri del gruppo Logistica durante un\'uscita o campo.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Magazzino e Inventario'),
        actions: [
          if (widget.hasTemporaryLogisticsAccess && !widget.canEditPermanent)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Chip(label: Text('Accesso Logistica Temporaneo')),
            ),
        ],
      ),
      floatingActionButton: widget.canEditPermanent
          ? FloatingActionButton.extended(
              onPressed: () {
                // Dialog aggiunta materiale (tende, casse, attrezzi)
              },
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi Materiale'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (ctx, i) {
                final item = _items[i];
                final status = item['condition_status'] ?? 'funzionante';
                final isBroken = status == 'da riparare';

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isBroken
                          ? Colors.orange.withValues(alpha: 0.2)
                          : Colors.green.withValues(alpha: 0.2),
                      child: Icon(
                        isBroken ? Icons.build_circle_outlined : Icons.inventory_2_outlined,
                        color: isBroken ? Colors.orange.shade800 : Colors.green.shade800,
                      ),
                    ),
                    title: Text(
                      '${item['name']} (Qtà: ${item['quantity'] ?? 1})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Branca/Squadriglia: ${item['assigned_to'] ?? 'Gruppo'} • '
                      'Stato: ${status.toString().toUpperCase()}',
                    ),
                  ),
                );
              },
            ),
    );
  }
}