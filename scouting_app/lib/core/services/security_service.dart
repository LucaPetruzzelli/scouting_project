import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecurityService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _pinStorageKey = 'scouting_user_security_pin';

  /// Verifica se l'utente ha almeno un fattore 2FA/MFA verificato su Supabase
  /// Verifica se l'utente ha almeno un fattore 2FA/MFA verificato su Supabase
  static Future<bool> isMfaEnabled() async {
    final client = Supabase.instance.client;
    try {
      final res = await client.auth.mfa.listFactors();
      return res.all.any((factor) => factor.status == FactorStatus.verified);
    } catch (_) {
      return false;
    }
  }

  /// Imposta il PIN locale di 4 o 6 cifre (per genitori, soci maggiorenni e capi)
  static Future<void> setLocalPin(String pin) async {
    if (pin.length != 4 && pin.length != 6) {
      throw ArgumentError('Il PIN deve essere di 4 o 6 cifre.');
    }
    await _secureStorage.write(key: _pinStorageKey, value: pin);
  }

  static Future<bool> hasLocalPin() async {
    final pin = await _secureStorage.read(key: _pinStorageKey);
    return pin != null && pin.isNotEmpty;
  }

  /// Richiede autenticazione Biometrica o, in alternativa, il PIN locale
  /// prima di visualizzare o firmare dati sensibili (schede mediche, PDF, allergie)
  static Future<bool> authenticateForSensitiveData(
    BuildContext context, {
    String reason = 'Autenticati per accedere ai dati sensibili o firmare documenti',
  }) async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (canCheckBiometrics && isDeviceSupported) {
        final didAuthenticate = await _localAuth.authenticate(
          localizedReason: reason,
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
          ),
        );
        if (didAuthenticate) return true;
      }
    } catch (_) {
      // Fallback sul PIN locale in caso di errore o assenza di biometria
    }

    if (!context.mounted) return false;
    return await _showPinDialog(context);
  }

  static Future<bool> _showPinDialog(BuildContext context) async {
    final savedPin = await _secureStorage.read(key: _pinStorageKey);
    final controller = TextEditingController();
    final isCreatingPin = savedPin == null;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isCreatingPin ? 'Configura PIN di Sicurezza' : 'Inserisci PIN di Sicurezza',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCreatingPin
                  ? 'Imposta un PIN di 4 o 6 cifre per proteggere i dati medici e firmare i PDF in-app.'
                  : 'Inserisci il tuo PIN locale di 4 o 6 cifre per proseguire.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'PIN (4 o 6 cifre)',
                prefixIcon: Icon(Icons.pin_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () async {
              final input = controller.text.trim();
              if (isCreatingPin) {
                if (input.length == 4 || input.length == 6) {
                  await setLocalPin(input);
                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                }
              } else if (input == savedPin) {
                Navigator.of(ctx).pop(true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('PIN errato. Riprova.')),
                );
              }
            },
            child: Text(isCreatingPin ? 'Salva e Accedi' : 'Sblocca'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}