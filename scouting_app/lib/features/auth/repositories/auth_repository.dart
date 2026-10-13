import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Future<String?> signUp({
    required String email,
    required String password,
    required String nome,
    required String cognome,
    required String genere,
    required DateTime dataDiNascita,
    required String branch,
    required String cellulare,
    required String indirizzo,
    required String cap,
    required String comune,
    required String provincia,
    // Dati opzionali per genitore/tutore
    String? nomeTutore,
    String? emailTutore,
    String? telefonoTutore,
    bool isEmergencyContact = false,
  }) async {
    try {
      // 1. Crea l'utente su Supabase Auth
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final User? user = res.user;
      if (user == null) return 'Errore sconosciuto: impossibile creare l\'utente.';

      // 2. Inserisci i dati anagrafici nella tabella 'profiles'
      final profileData = await _supabase.from('profiles').insert({
        'id': user.id,
        'nome': nome,
        'cognome': cognome,
        'genere': genere,
        'data_di_nascita': dataDiNascita.toIso8601String(),
        'email': email,
        'telefono': cellulare,
        'indirizzo': indirizzo,
        'cap': cap,
        'comune': comune,
        'provincia': provincia,
        'branch': branch,
        'role': 'socio', // Role default, verrà confermato/modificato dal Capo
        'status': 'pending', // In attesa di approvazione da un capo
      }).select();

      if (profileData.isEmpty) {
        return 'Errore: il profilo non è stato salvato nel database. Potrebbe essere un blocco dei permessi (RLS) su Supabase.';
      }

      // 3. Se ci sono dati del genitore/tutore, inseriscili in 'parents_contacts'
      if (nomeTutore != null && nomeTutore.isNotEmpty && telefonoTutore != null && telefonoTutore.isNotEmpty) {
        await _supabase.from('parents_contacts').insert({
          'profile_id': user.id,
          'nome': nomeTutore,
          'email': emailTutore,
          'telefono': telefonoTutore,
          'is_emergency_contact': isEmergencyContact,
        });
      }

      return null;
    } on AuthException catch (e) {
      print('Errore Auth: ${e.message}');
      return e.message;
    } catch (e) {
      print('Errore durante la registrazione: $e');
      return e.toString();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return res.user != null;
    } catch (e) {
      print('Errore durante il login: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      return data;
    } catch (e) {
      print('Errore durante il recupero del profilo: $e');
      return null;
    }
  }
}
