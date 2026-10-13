import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class DocumentCompressor {
  /// Comprime un'immagine JPEG/PNG/HEIC riducendone dimensioni e qualità
  static Future<File?> compressImage(File file, {int quality = 70, int minWidth = 1200, int minHeight = 1200}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(
        tempDir.path, 
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg'
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: CompressFormat.jpeg,
      );

      if (result == null) return null;
      
      return File(result.path);
    } catch (e) {
      debugPrint('Errore durante la compressione dell\'immagine: $e');
      return file; // Ritorna il file originale se la compressione fallisce
    }
  }

  /// Metodo generico che capisce se è un'immagine da comprimere o un PDF da controllare
  static Future<File> processFile(File file, {double maxPdfSizeMb = 2.0}) async {
    final extension = p.extension(file.path).toLowerCase();
    final isImage = ['.jpg', '.jpeg', '.png', '.heic'].contains(extension);

    if (isImage) {
      final compressed = await compressImage(file);
      return compressed ?? file;
    } else if (extension == '.pdf') {
      // Per i PDF controlliamo solo le dimensioni
      final bytes = await file.length();
      final sizeMb = bytes / (1024 * 1024);
      
      if (sizeMb > maxPdfSizeMb) {
        throw Exception(
          'Il file PDF è troppo grande (${sizeMb.toStringAsFixed(1)} MB). Il limite è $maxPdfSizeMb MB. '
          'Per favore riduci le dimensioni del PDF prima di caricarlo.'
        );
      }
      return file;
    }

    return file;
  }
}
