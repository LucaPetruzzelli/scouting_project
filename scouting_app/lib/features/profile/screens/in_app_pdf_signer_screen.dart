// lib/features/profile/screens/in_app_pdf_signer_screen.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/services/security_service.dart';

class InAppPdfSignerScreen extends StatefulWidget {
  final String documentTitle; // es. "Modulo Censimento 2026", "Scheda Medica", "Modulo Privacy"
  final String memberFullName;
  final bool isMinor;
  final Function(Uint8List pdfBytes) onPdfSignedAndSubmitted;

  const InAppPdfSignerScreen({
    super.key,
    required this.documentTitle,
    required this.memberFullName,
    required this.isMinor,
    required this.onPdfSignedAndSubmitted,
  });

  @override
  State<InAppPdfSignerScreen> createState() => _InAppPdfSignerScreenState();
}

class _InAppPdfSignerScreenState extends State<InAppPdfSignerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _signerNameCtrl = TextEditingController();
  final _allergiesNotesCtrl = TextEditingController();
  final _FiscalCodeCtrl = TextEditingController();
  final List<Offset?> _signaturePoints = [];
  bool _privacyAccepted = false;
  bool _isGenerating = false;

  Future<Uint8List?> _exportSignaturePng() async {
    if (_signaturePoints.isEmpty) return null;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 150));
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < _signaturePoints.length - 1; i++) {
      if (_signaturePoints[i] != null && _signaturePoints[i + 1] != null) {
        canvas.drawLine(_signaturePoints[i]!, _signaturePoints[i + 1]!, paint);
      }
    }
    final picture = recorder.endRecording();
    final img = await picture.toImage(400, 150);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _signAndSubmit() async {
    if (!_formKey.currentState!.validate() || !_privacyAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila tutti i campi e accetta le clausole.')),
      );
      return;
    }
    if (_signaturePoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apponi la firma nel riquadro dedicato.')),
      );
      return;
    }

    // 1. Verifica Biometrica o PIN di 4/6 cifre prima della firma
    final authenticated = await SecurityService.authenticateForSensitiveData(
      context,
      reason: 'Autorizza la firma digitale del documento ${widget.documentTitle}',
    );
    if (!authenticated) return;

    setState(() => _isGenerating = true);
    try {
      final signatureBytes = await _exportSignaturePng();
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('GRUPPO SCOUT AGESCI BARI 10',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(widget.documentTitle,
                  style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Text('Socio interessato: ${widget.memberFullName} '
                  '(${widget.isMinor ? "Minorenne" : "Maggiorenne"})'),
              pw.Text('Sottoscritto da: ${_signerNameCtrl.text.trim()}'),
              pw.Text('Codice Fiscale: ${_FiscalCodeCtrl.text.trim()}'),
              pw.SizedBox(height: 12),
              pw.Text('Dichiarazioni / Note mediche e allergie:'),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Text(_allergiesNotesCtrl.text.trim().isEmpty
                    ? 'Nessuna nota aggiuntiva dichiarata.'
                    : _allergiesNotesCtrl.text.trim()),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Con la presente si autorizza il trattamento dei dati personali e sanitari '
                'ai sensi del GDPR esclusivamente per le finalità associative AGESCI Bari 10.',
              ),
              pw.SizedBox(height: 24),
              pw.Text('Data: ${DateTime.now().toIso8601String().split('T').first}'),
              pw.SizedBox(height: 12),
              pw.Text('Firma autografa digitale:'),
              if (signatureBytes != null)
                pw.Container(
                  height: 80,
                  width: 220,
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Image(pw.MemoryImage(signatureBytes)),
                ),
            ],
          ),
        ),
      );

      final bytes = await pdf.save();
      widget.onPdfSignedAndSubmitted(bytes);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Compila: ${widget.documentTitle}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.isMinor
                  ? 'Compilazione riservata al Genitore/Tutore Legale di ${widget.memberFullName}'
                  : 'Compilazione Socio Maggiorenne: ${widget.memberFullName}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _signerNameCtrl,
              decoration: InputDecoration(
                labelText: widget.isMinor
                    ? 'Nome e Cognome Genitore/Tutore Firmatario *'
                    : 'Nome e Cognome Socio Firmatario *',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _FiscalCodeCtrl,
              decoration: const InputDecoration(labelText: 'Codice Fiscale *'),
              validator: (v) => (v == null || v.trim().length < 11) ? 'Inserisci un CF valido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _allergiesNotesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Allergie, intolleranze, farmaci o note per i Capi',
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _privacyAccepted,
              onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
              title: const Text(
                'Confermo la veridicità dei dati inseriti e accetto l\'informativa sulla privacy AGESCI.',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Firma qui sotto con il dito:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => setState(() => _signaturePoints.clear()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Pulisci firma'),
                ),
              ],
            ),
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: GestureDetector(
                onPanUpdate: (details) {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box != null) {
                    setState(() => _signaturePoints.add(details.localPosition));
                  }
                },
                onPanEnd: (_) => _signaturePoints.add(null),
                child: CustomPaint(
                  painter: _SignaturePainter(_signaturePoints),
                  size: Size.infinite,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isGenerating ? null : _signAndSubmit,
              icon: const Icon(Icons.verified_user_rounded),
              label: Text(_isGenerating
                  ? 'Crittografia e invio in corso...'
                  : 'Firma con Biometria/PIN e Invia ai Capi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}