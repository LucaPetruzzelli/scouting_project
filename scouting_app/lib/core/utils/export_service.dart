import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  /// Esporta i dati selezionati in un file CSV e offre di condividerlo/salvarlo.
  static Future<void> exportToCsv({
    required List<Map<String, dynamic>> users,
    required List<String> fieldsToExport,
  }) async {
    try {
      if (users.isEmpty || fieldsToExport.isEmpty) return;

      List<List<dynamic>> rows = [];
      
      // Aggiungi la riga di intestazione
      rows.add(fieldsToExport);

      // Aggiungi i dati
      for (var user in users) {
        List<dynamic> row = [];
        for (var field in fieldsToExport) {
          // Gestiamo campi vuoti o null
          row.add(user[field] ?? '');
        }
        rows.add(row);
      }

      // Converti in CSV
      String csvData = const ListToCsvConverter().convert(rows);

      // Salva in un file temporaneo
      final tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/export_scout_${DateTime.now().millisecondsSinceEpoch}.csv';
      final File file = File(filePath);
      await file.writeAsString(csvData);

      // Usa share_plus per permettere all'utente di salvare il file, inviarlo per email, ecc.
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Esportazione dati scout',
      );
    } catch (e) {
      print('Errore durante l\'esportazione in CSV: $e');
      rethrow;
    }
  }
}
