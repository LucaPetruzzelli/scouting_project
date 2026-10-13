import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

final censimentiRepositoryProvider = Provider<CensimentiRepository>((ref) {
  return CensimentiRepository(Supabase.instance.client);
});

class CensimentiRepository {
  final SupabaseClient _supabase;

  CensimentiRepository(this._supabase);

  Future<List<Map<String, dynamic>>> getMyCensimentoDocuments(int anno) async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return [];

      final response = await _supabase
          .from('censimenti_documents')
          .select()
          .eq('profile_id', uid)
          .eq('anno', anno);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Errore getMyCensimentoDocuments: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPendingCensimentoDocuments() async {
    try {
      final response = await _supabase
          .from('censimenti_documents')
          .select('*, profiles!profile_id(nome, cognome, role, branch)')
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Errore getPendingCensimentoDocuments: $e');
      return [];
    }
  }

  Future<bool> uploadDocument(int anno, String documentType, File file, {String? existingDocId}) async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return false;

      // Upload file to Storage
      final fileExtension = p.extension(file.path);
      // Rimuovi spazi e caratteri speciali dal tipo per il nome del file
      final safeType = documentType.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
      final fileName = 'censimento_${anno}_${safeType}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final filePath = '$uid/$fileName';

      await _supabase.storage.from('private_documents').upload(filePath, file);

      // Save to database
      if (existingDocId != null) {
        // Update existing rejected/pending row
        await _supabase.from('censimenti_documents').update({
          'status': 'pending',
          'file_url': filePath,
          'validated_by': null,
          'created_at': DateTime.now().toIso8601String(),
        }).eq('id', existingDocId);
      } else {
        // Insert new row
        await _supabase.from('censimenti_documents').insert({
          'profile_id': uid,
          'anno': anno,
          'document_type': documentType,
          'file_url': filePath,
        });
      }

      return true;
    } catch (e) {
      print('Errore uploadDocument: $e');
      return false;
    }
  }

  Future<bool> updateDocumentStatus(String id, String status) async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      final response = await _supabase.from('censimenti_documents').update({
        'status': status,
        'validated_by': uid,
      }).eq('id', id).select();

      return response.isNotEmpty;
    } catch (e) {
      print('Errore updateStatus documento: $e');
      return false;
    }
  }

  Future<String> getFileUrl(String filePath) async {
    try {
      final signedUrl = await _supabase.storage.from('private_documents').createSignedUrl(filePath, 60);
      return signedUrl;
    } catch (e) {
      print('Errore getFileUrl: $e');
      return '';
    }
  }
}
