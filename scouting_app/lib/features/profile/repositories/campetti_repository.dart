import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final campettiRepositoryProvider = Provider<CampettiRepository>((ref) {
  return CampettiRepository(Supabase.instance.client);
});

class CampettiRepository {
  final SupabaseClient _supabase;

  CampettiRepository(this._supabase);

  // Ottieni i campetti di uno specifico profilo
  Future<List<Map<String, dynamic>>> getCampettiByProfile(String profileId) async {
    try {
      final response = await _supabase
          .from('campetti')
          .select()
          .eq('profile_id', profileId)
          .order('data_inizio', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Errore recupero campetti: $e');
      return [];
    }
  }

  // Aggiungi un nuovo campetto
  Future<bool> insertCampetto(Map<String, dynamic> data) async {
    try {
      await _supabase.from('campetti').insert(data);
      return true;
    } catch (e) {
      print('Errore inserimento campetto: $e');
      return false;
    }
  }

  // Elimina un campetto (se permesso dalle policy RLS)
  Future<bool> deleteCampetto(String id) async {
    try {
      await _supabase.from('campetti').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Errore eliminazione campetto: $e');
      return false;
    }
  }

  // Ottieni tutti i campetti in attesa di validazione (per i capi)
  Future<List<Map<String, dynamic>>> getPendingCampetti() async {
    try {
      // Dobbiamo specificare la Foreign Key (!profile_id) perché campetti ha due FK verso profiles
      final response = await _supabase
          .from('campetti')
          .select('*, profiles!profile_id(nome, cognome, role, branch)')
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Errore recupero campetti in attesa: $e');
      return [];
    }
  }

  // Valida o rifiuta un campetto
  Future<bool> updateCampettoStatus(String id, String status) async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      final myProfile = await _supabase.from('profiles').select().eq('id', uid as Object).maybeSingle();
      print('DEBUG IL MIO PROFILO: $myProfile');

      final response = await _supabase.from('campetti').update({
        'status': status,
        'validated_by': uid,
      }).eq('id', id).select();
      
      print('DEBUG UPDATE CAMPETTO: $response');
      
      if (response.isEmpty) {
        print('Nessuna riga modificata. Probabilmente bloccato dalla policy RLS UPDATE.');
        return false;
      }
      return true;
    } catch (e) {
      print('Errore aggiornamento status campetto: $e');
      return false;
    }
  }
}
