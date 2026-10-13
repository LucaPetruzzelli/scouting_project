import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';

final registrationProvider = StateNotifierProvider<RegistrationNotifier, RegistrationState>((ref) {
  return RegistrationNotifier(ref.read(authRepositoryProvider));
});

class RegistrationState {
  final String nome;
  final String cognome;
  final String genere;
  final DateTime? dataDiNascita;
  final String branch;
  
  final String indirizzo;
  final String citta;
  final String provincia;
  final String cap;
  final String cellulare;
  final String email;

  final String emailGenitore1;
  final String emailGenitore2;
  final String telefonoGenitore1;
  final String telefonoGenitore2;
  final String nomeTutoreLegale;

  final String password;

  RegistrationState({
    this.nome = '',
    this.cognome = '',
    this.genere = '',
    this.dataDiNascita,
    this.branch = '',
    this.indirizzo = '',
    this.citta = '',
    this.provincia = '',
    this.cap = '',
    this.cellulare = '',
    this.email = '',
    this.emailGenitore1 = '',
    this.emailGenitore2 = '',
    this.telefonoGenitore1 = '',
    this.telefonoGenitore2 = '',
    this.nomeTutoreLegale = '',
    this.password = '',
  });

  bool get isMinorenne {
    if (dataDiNascita == null) return false;
    final today = DateTime.now();
    int age = today.year - dataDiNascita!.year;
    if (today.month < dataDiNascita!.month ||
        (today.month == dataDiNascita!.month && today.day < dataDiNascita!.day)) {
      age--;
    }
    return age < 18;
  }

  RegistrationState copyWith({
    String? nome,
    String? cognome,
    String? genere,
    DateTime? dataDiNascita,
    String? branch,
    String? indirizzo,
    String? citta,
    String? provincia,
    String? cap,
    String? cellulare,
    String? email,
    String? emailGenitore1,
    String? emailGenitore2,
    String? telefonoGenitore1,
    String? telefonoGenitore2,
    String? nomeTutoreLegale,
    String? password,
  }) {
    return RegistrationState(
      nome: nome ?? this.nome,
      cognome: cognome ?? this.cognome,
      genere: genere ?? this.genere,
      dataDiNascita: dataDiNascita ?? this.dataDiNascita,
      branch: branch ?? this.branch,
      indirizzo: indirizzo ?? this.indirizzo,
      citta: citta ?? this.citta,
      provincia: provincia ?? this.provincia,
      cap: cap ?? this.cap,
      cellulare: cellulare ?? this.cellulare,
      email: email ?? this.email,
      emailGenitore1: emailGenitore1 ?? this.emailGenitore1,
      emailGenitore2: emailGenitore2 ?? this.emailGenitore2,
      telefonoGenitore1: telefonoGenitore1 ?? this.telefonoGenitore1,
      telefonoGenitore2: telefonoGenitore2 ?? this.telefonoGenitore2,
      nomeTutoreLegale: nomeTutoreLegale ?? this.nomeTutoreLegale,
      password: password ?? this.password,
    );
  }
}

class RegistrationNotifier extends StateNotifier<RegistrationState> {
  final AuthRepository _authRepository;

  RegistrationNotifier(this._authRepository) : super(RegistrationState());

  void updateDatiBase({
    required String nome,
    required String cognome,
    required String genere,
    required DateTime dataDiNascita,
    required String branch,
  }) {
    state = state.copyWith(
      nome: nome,
      cognome: cognome,
      genere: genere,
      dataDiNascita: dataDiNascita,
      branch: branch,
    );
  }

  void updateIndirizzo({
    required String indirizzo,
    required String citta,
    required String provincia,
    required String cap,
    required String cellulare,
    required String email,
    String emailGenitore1 = '',
    String emailGenitore2 = '',
    String telefonoGenitore1 = '',
    String telefonoGenitore2 = '',
    String nomeTutoreLegale = '',
  }) {
    state = state.copyWith(
      indirizzo: indirizzo,
      citta: citta,
      provincia: provincia,
      cap: cap,
      cellulare: cellulare,
      email: email,
      emailGenitore1: emailGenitore1,
      emailGenitore2: emailGenitore2,
      telefonoGenitore1: telefonoGenitore1,
      telefonoGenitore2: telefonoGenitore2,
      nomeTutoreLegale: nomeTutoreLegale,
    );
  }

  void updatePassword(String password) {
    state = state.copyWith(password: password);
  }

  Future<String?> submitRegistration() async {
    // Calcoliamo i dati tutore/genitore in base alla minore età
    final nomeTutore = state.isMinorenne 
        ? "Genitore: ${state.emailGenitore1}" // Qui si potrebbe prendere anche il nome, al momento non lo abbiamo nel form
        : state.nomeTutoreLegale;
        
    final emailTutore = state.isMinorenne ? state.emailGenitore1 : null;
    final telefonoTutore = state.isMinorenne ? state.telefonoGenitore1 : null;
    final isEmergencyContact = !state.isMinorenne; // Se è maggiorenne, è un contatto di emergenza

    final error = await _authRepository.signUp(
      email: state.email,
      password: state.password,
      nome: state.nome,
      cognome: state.cognome,
      genere: state.genere,
      dataDiNascita: state.dataDiNascita!,
      branch: state.branch,
      cellulare: state.cellulare,
      indirizzo: state.indirizzo,
      cap: state.cap,
      comune: state.citta,
      provincia: state.provincia,
      nomeTutore: nomeTutore,
      emailTutore: emailTutore,
      telefonoTutore: telefonoTutore,
      isEmergencyContact: isEmergencyContact,
    );
    
    return error;
  }
}
