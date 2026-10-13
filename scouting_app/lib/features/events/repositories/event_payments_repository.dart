import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventPaymentsRepositoryProvider = Provider<EventPaymentsRepository>((ref) {
  return EventPaymentsRepository(Supabase.instance.client);
});

class EventPaymentsRepository {
  final SupabaseClient _supabase;

  EventPaymentsRepository(this._supabase);

  // Fetch all profiles that match the event targets
  // E siccome questo è un pochino complesso farlo in una query SQL da client con gli array JSON,
  // scarichiamo tutti gli utenti della branca/ruolo (oppure tutti) e filtriamo.
  // Dato che il DB è piccolo (gruppo scout), va bene fare una query e poi filtrare in locale.
  Future<List<Map<String, dynamic>>> getExpectedParticipants(
    List<String> branches,
    List<String> roles,
    List<String> squads,
    List<String> specificUsers,
  ) async {
    try {
      final response = await _supabase.from('profiles').select('id, nome, cognome, branch, role, squad_name');
      final allProfiles = List<Map<String, dynamic>>.from(response);

      return allProfiles.where((p) {
        // Se l'utente è in specificUsers, partecipa
        if (specificUsers.contains(p['id'])) return true;
        // Se non ci sono target specifici, è per tutti?
        if (branches.isEmpty && roles.isEmpty && squads.isEmpty && specificUsers.isEmpty) return true;
        // Check branches
        if (branches.isNotEmpty && branches.contains(p['branch'])) return true;
        // Check roles
        if (roles.isNotEmpty && roles.contains(p['role'])) return true;
        // Check squads
        if (squads.isNotEmpty && squads.contains(p['squad_name'])) return true;

        return false;
      }).toList();
    } catch (e) {
      print('Errore getExpectedParticipants: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPayments(String eventId) async {
    try {
      final response = await _supabase
          .from('event_payments')
          .select()
          .eq('event_id', eventId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Errore getPayments: $e');
      return [];
    }
  }

  Future<bool> togglePayment(String eventId, String profileId, bool hasPaid) async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (hasPaid) {
        // Inserisci o aggiorna a true
        await _supabase.from('event_payments').upsert({
          'event_id': eventId,
          'profile_id': profileId,
          'has_paid': true,
          'verified_by': uid,
        }, onConflict: 'event_id, profile_id');
      } else {
        // Aggiorna a false (o elimina)
        await _supabase.from('event_payments').update({
          'has_paid': false,
          'verified_by': uid,
        }).eq('event_id', eventId).eq('profile_id', profileId);
      }
      return true;
    } catch (e) {
      print('Errore togglePayment: $e');
      return false;
    }
  }
}
