import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../providers/registration_provider.dart';
import '../../../core/theme/theme_provider.dart';

class RegistrationStep3Screen extends ConsumerStatefulWidget {
  const RegistrationStep3Screen({super.key});

  @override
  ConsumerState<RegistrationStep3Screen> createState() => _RegistrationStep3ScreenState();
}

class _RegistrationStep3ScreenState extends ConsumerState<RegistrationStep3Screen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
  }

  void _validatePassword() {
    final text = _passwordController.text;
    setState(() {
      _hasMinLength = text.length >= 8;
      _hasUppercase = text.contains(RegExp(r'[A-Z]'));
      _hasLowercase = text.contains(RegExp(r'[a-z]'));
      _hasNumber = text.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePassword);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      ref.read(registrationProvider.notifier).updatePassword(_passwordController.text);
      
      final error = await ref.read(registrationProvider.notifier).submitRegistration();
      
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (error == null) {
        // Mostra modale di successo e torna al login
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Richiesta Inviata'),
            content: const Text('La tua richiesta di registrazione è stata inviata con successo. Riceverai un\'email non appena un Capo l\'avrà approvata.'),
            actions: [
              TextButton(
                onPressed: () {
                  context.pop(); // Chiude modale
                  context.go('/login'); // Torna alla home/login
                },
                child: const Text('Torna al Login'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $error'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationProvider);
    final isMinorenne = state.isMinorenne;
    
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              ref.read(themeProvider.notifier).setTheme(isDarkMode ? ThemeMode.light : ThemeMode.dark);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('AGESCI Bari 10', style: Theme.of(context).textTheme.displayLarge),
                  const SizedBox(height: 8),
                  Text('Registrazione', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text('Riepilogo e Conferma', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 32),

                  // Stepper Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStepIndicator(context, '1', 'Dati Base', isActive: false, isCompleted: true),
                      _buildLine(context, isCompleted: true),
                      _buildStepIndicator(context, '2', 'Indirizzo', isActive: false, isCompleted: true),
                      _buildLine(context, isCompleted: true),
                      _buildStepIndicator(context, '3', 'Riepilogo', isActive: true),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Riepilogo Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Riepilogo Dati', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const Divider(),
                        _buildSummaryRow('Nome', state.nome),
                        _buildSummaryRow('Cognome', state.cognome),
                        _buildSummaryRow('Nato il', state.dataDiNascita != null ? '${state.dataDiNascita!.day}/${state.dataDiNascita!.month}/${state.dataDiNascita!.year}' : ''),
                        _buildSummaryRow('Residenza', '${state.indirizzo}, ${state.citta} (${state.provincia})'),
                        _buildSummaryRow('Email', state.email),
                        _buildSummaryRow('Cellulare', state.cellulare),
                        
                        if (state.branch != 'Co.Ca.') ...[
                          if (isMinorenne) ...[
                            const Divider(),
                            Text('Dati Genitori', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            _buildSummaryRow('Email Genitore 1', state.emailGenitore1),
                            _buildSummaryRow('Telefono Genitore 1', state.telefonoGenitore1),
                          ] else ...[
                            const Divider(),
                            Text('Contatto Emergenza', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            _buildSummaryRow('Nome', state.nomeTutoreLegale),
                            _buildSummaryRow('Telefono', state.telefonoGenitore1), // In step 2 we mapped emergenza to genitore1 if adult
                          ],
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          label: 'Crea una Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          controller: _passwordController,
                          isRequired: true,
                          validator: (v) {
                            if (!_hasMinLength || !_hasUppercase || !_hasLowercase || !_hasNumber || !_hasSpecialChar) {
                              return 'La password non rispetta tutti i requisiti';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildPasswordRules(),
                        const SizedBox(height: 24),
                        CustomTextField(
                          label: 'Conferma Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          controller: _confirmPasswordController,
                          isRequired: true,
                          validator: (v) {
                            if (v != _passwordController.text) {
                              return 'Le password non coincidono';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: 'Indietro',
                                isSecondary: true,
                                onPressed: () => context.pop(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: CustomButton(
                                text: 'Conferma Registrazione',
                                isLoading: _isLoading,
                                onPressed: _submit,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordRules() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requisiti password:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          _buildRuleRow('Almeno 8 caratteri', _hasMinLength),
          const SizedBox(height: 4),
          _buildRuleRow('Almeno una lettera maiuscola', _hasUppercase),
          const SizedBox(height: 4),
          _buildRuleRow('Almeno una lettera minuscola', _hasLowercase),
          const SizedBox(height: 4),
          _buildRuleRow('Almeno un numero', _hasNumber),
          const SizedBox(height: 4),
          _buildRuleRow('Almeno un carattere speciale', _hasSpecialChar),
        ],
      ),
    );
  }

  Widget _buildRuleRow(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.circle_outlined,
          size: 16,
          color: isValid ? Colors.green : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isValid ? Colors.green : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context, String step, String title, {required bool isActive, bool isCompleted = false}) {
    final color = isActive || isCompleted ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5);
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isActive || isCompleted ? color : color.withOpacity(0.2),
          child: isCompleted 
            ? Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.onPrimary)
            : Text(
                step,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Theme.of(context).colorScheme.onPrimary : color,
                ),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(BuildContext context, {bool isCompleted = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8).copyWith(bottom: 16),
        height: 2,
        color: isCompleted ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2),
      ),
    );
  }
}
