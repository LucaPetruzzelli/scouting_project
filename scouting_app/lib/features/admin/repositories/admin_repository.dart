import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(Supabase.instance.client);
});

class AdminRepository {
  final SupabaseClient _supabase;

  AdminRepository(this._supabase);

  // Ottiene la lista degli utenti in attesa di approvazione
  Future<List<Map<String, dynamic>>> getPendingUsers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Errore durante il recupero degli utenti pending: $e');
      return [];
    }
  }

  // Approva un utente e ne aggiorna i dati
  Future<bool> approveUser(String userId, Map<String, dynamic> updatedData) async {
    try {
      final dataToUpdate = {
        ...updatedData,
        'status': 'active',
      };
      await _supabase.from('profiles').update(dataToUpdate).eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('Errore durante l\'approvazione dell\'utente: $e');
      return false;
    }
  }

  // Rifiuta/elimina un utente in attesa
  Future<bool> rejectUser(String userId) async {
    try {
      // Impostiamo a rejected invece di cancellarlo, così manteniamo lo storico. 
      // Se si preferisce si può usare .delete()
      await _supabase.from('profiles').update({
        'status': 'rejected',
      }).eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('Errore durante il rifiuto dell\'utente: $e');
      return false;
    }
  }

  // Ottiene tutti gli utenti (es. attivi) con la possibilità di filtrare per branch o status
  Future<List<Map<String, dynamic>>> getUsers({String? status, String? branch}) async {
    try {
      var query = _supabase.from('profiles').select();
      
      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }
      if (branch != null && branch.isNotEmpty) {
        query = query.eq('branch', branch);
      }
      
      final response = await query.order('cognome', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Errore durante il recupero degli utenti: $e');
      return [];
    }
  }

  // Ottiene i contatti dei genitori per un dato utente
  Future<Map<String, dynamic>?> getParentContact(String profileId) async {
    try {
      final data = await _supabase
          .from('parents_contacts')
          .select()
          .eq('profile_id', profileId)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('Errore durante il recupero dei contatti genitore: $e');
      return null;
    }
  }

  // Aggiorna tutti i campi di un profilo
  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _supabase.from('profiles').update(data).eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('Errore durante l\'aggiornamento dell\'utente: $e');
      return false;
    }
  }
}
