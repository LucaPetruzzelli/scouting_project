import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/censimenti_provider.dart';

class CensimentoScreen extends ConsumerStatefulWidget {
  const CensimentoScreen({super.key});

  @override
  ConsumerState<CensimentoScreen> createState() => _CensimentoScreenState();
}

class _CensimentoScreenState extends ConsumerState<CensimentoScreen> {
  bool _isUploading = false;
  final int currentYear = DateTime.now().year;

  final List<String> _documentTypes = [
    'Privacy',
    'Consenso',
    'Iscrizione',
    'Scheda Medica',
    'Ricevuta Bonifico',
    'Altro'
  ];

  Future<void> _uploadFile(bool fromGallery, String documentType, {String? existingDocId}) async {
    File? file;

    try {
      if (fromGallery) {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (pickedFile != null) {
          file = File(pickedFile.path);
        }
      } else {
        FilePickerResult? result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        );
        if (result != null && result.files.single.path != null) {
          file = File(result.files.single.path!);
        }
      }

      if (file == null) return;

      setState(() => _isUploading = true);
      
      final success = await ref.read(myCensimentoProvider.notifier).uploadDocument(
        documentType, 
        file, 
        existingDocId: existingDocId
      );
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Documento "$documentType" caricato con successo!')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore durante il caricamento di "$documentType".')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showUploadOptions(String documentType, {String? existingDocId}) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              title: Text('Carica $documentType', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Carica Immagine (Galleria)'),
              onTap: () {
                Navigator.pop(context);
                _uploadFile(true, documentType, existingDocId: existingDocId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Scegli File (PDF/Immagine)'),
              onTap: () {
                Navigator.pop(context);
                _uploadFile(false, documentType, existingDocId: existingDocId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNewDocumentDialog() {
    String selectedType = _documentTypes.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Nuovo Documento'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Seleziona il tipo di documento che vuoi caricare:'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: _documentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) {
                    if (val != null) setStateDialog(() => selectedType = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showUploadOptions(selectedType);
                },
                child: const Text('Avanti'),
              ),
            ],
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final censimentoAsync = ref.watch(myCensimentoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documenti Censimento'),
      ),
      body: censimentoAsync.when(
        data: (documents) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Icon(Icons.security, size: 48, color: Colors.blue),
                        const SizedBox(height: 16),
                        Text(
                          'Censimento $currentYear',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Carica qui tutti i documenti richiesti per il censimento (es. Privacy, Consenso, Scheda Medica, Ricevuta Bonifico).',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : _showNewDocumentDialog,
                          icon: _isUploading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                            : const Icon(Icons.add),
                          label: const Text('Aggiungi Documento'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'I tuoi documenti:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: documents.isEmpty
                    ? const Center(child: Text('Nessun documento caricato per questo anno.'))
                    : ListView.builder(
                        itemCount: documents.length,
                        itemBuilder: (context, index) {
                          final doc = documents[index];
                          return _buildDocumentCard(doc);
                        },
                      ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Errore: $e')),
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    final status = doc['status'] as String;
    final type = doc['document_type'] as String;
    final id = doc['id'] as String;

    IconData icon;
    Color color;
    String statusText;

    switch (status) {
      case 'approved':
        icon = Icons.check_circle;
        color = Colors.green;
        statusText = 'Approvato';
        break;
      case 'rejected':
        icon = Icons.error;
        color = Colors.red;
        statusText = 'Rifiutato';
        break;
      case 'pending':
      default:
        icon = Icons.access_time_filled;
        color = Colors.orange;
        statusText = 'In attesa';
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: color, size: 36),
        title: Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Stato: $statusText'),
        trailing: status != 'approved' 
          ? IconButton(
              icon: const Icon(Icons.upload),
              tooltip: 'Ricarica file',
              onPressed: _isUploading ? null : () => _showUploadOptions(type, existingDocId: id),
            )
          : const Icon(Icons.lock, color: Colors.grey),
      ),
    );
  }
}
