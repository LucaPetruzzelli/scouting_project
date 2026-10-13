import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../providers/registration_provider.dart';
import '../../../core/theme/theme_provider.dart';

class RegistrationStep2Screen extends ConsumerStatefulWidget {
  const RegistrationStep2Screen({super.key});

  @override
  ConsumerState<RegistrationStep2Screen> createState() => _RegistrationStep2ScreenState();
}

class _RegistrationStep2ScreenState extends ConsumerState<RegistrationStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  
  final _indirizzoController = TextEditingController();
  final _cittaController = TextEditingController();
  final _provinciaController = TextEditingController();
  final _capController = TextEditingController();
  final _cellulareController = TextEditingController();
  final _emailController = TextEditingController();

  final _emailGenitore1Controller = TextEditingController();
  final _emailGenitore2Controller = TextEditingController();
  final _telefonoGenitore1Controller = TextEditingController();
  final _telefonoGenitore2Controller = TextEditingController();
  final _nomeTutoreLegaleController = TextEditingController();
  final _telefonoEmergenzaController = TextEditingController();

  @override
  void dispose() {
    _indirizzoController.dispose();
    _cittaController.dispose();
    _provinciaController.dispose();
    _capController.dispose();
    _cellulareController.dispose();
    _emailController.dispose();
    _emailGenitore1Controller.dispose();
    _emailGenitore2Controller.dispose();
    _telefonoGenitore1Controller.dispose();
    _telefonoGenitore2Controller.dispose();
    _nomeTutoreLegaleController.dispose();
    _telefonoEmergenzaController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final isMinorenne = ref.read(registrationProvider).isMinorenne;
      
      ref.read(registrationProvider.notifier).updateIndirizzo(
        indirizzo: _indirizzoController.text,
        citta: _cittaController.text,
        provincia: _provinciaController.text,
        cap: _capController.text,
        cellulare: _cellulareController.text,
        email: _emailController.text,
        emailGenitore1: isMinorenne ? _emailGenitore1Controller.text : '',
        emailGenitore2: isMinorenne ? _emailGenitore2Controller.text : '',
        telefonoGenitore1: isMinorenne ? _telefonoGenitore1Controller.text : _telefonoEmergenzaController.text,
        telefonoGenitore2: isMinorenne ? _telefonoGenitore2Controller.text : '',
        nomeTutoreLegale: isMinorenne ? '' : _nomeTutoreLegaleController.text,
      );
      context.push('/register/step3');
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
                  Text('Indirizzo e Contatti', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 32),

                  // Stepper Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStepIndicator(context, '1', 'Dati Base', isActive: false, isCompleted: true),
                      _buildLine(context, isCompleted: true),
                      _buildStepIndicator(context, '2', 'Indirizzo', isActive: true),
                      _buildLine(context),
                      _buildStepIndicator(context, '3', 'Riepilogo', isActive: false),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          label: 'Indirizzo di Residenza',
                          placeholder: 'Via Roma, 1',
                          icon: Icons.home_outlined,
                          controller: _indirizzoController,
                          isRequired: true,
                          validator: (v) => v!.isEmpty ? 'Campo obbligatorio' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: CustomTextField(
                                label: 'Città',
                                placeholder: 'Bari',
                                controller: _cittaController,
                                isRequired: true,
                                validator: (v) => v!.isEmpty ? 'Obbligatorio' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: CustomTextField(
                                label: 'Provincia',
                                placeholder: 'BA',
                                controller: _provinciaController,
                                isRequired: true,
                                validator: (v) => v!.isEmpty ? 'Obbligatorio' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: CustomTextField(
                                label: 'CAP',
                                placeholder: '70100',
                                controller: _capController,
                                keyboardType: TextInputType.number,
                                isRequired: true,
                                validator: (v) => v!.isEmpty ? 'Obbligatorio' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Cellulare',
                          placeholder: '333...',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          controller: _cellulareController,
                          isRequired: !isMinorenne,
                          validator: (v) => (!isMinorenne && (v == null || v.isEmpty)) ? 'Campo obbligatorio per maggiorenni' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Email',
                          placeholder: 'mario@email.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          controller: _emailController,
                          isRequired: true,
                          validator: (v) => (v == null || v.isEmpty) ? 'Campo obbligatorio' : null,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        if (state.branch != 'Co.Ca.') ...[
                          if (isMinorenne) ...[
                            Text('Dati Genitori/Tutori (Socio Minorenne)', style: Theme.of(context).textTheme.titleMedium),
                            const Divider(),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'Email Genitore/Tutore 1',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              controller: _emailGenitore1Controller,
                              isRequired: true,
                              validator: (v) => v!.isEmpty ? 'Campo obbligatorio per i minorenni' : null,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'Telefono Genitore/Tutore 1',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              controller: _telefonoGenitore1Controller,
                              isRequired: true,
                              validator: (v) => v!.isEmpty ? 'Campo obbligatorio per i minorenni' : null,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'Email Genitore/Tutore 2 (Facoltativo)',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              controller: _emailGenitore2Controller,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'Telefono Genitore/Tutore 2 (Facoltativo)',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              controller: _telefonoGenitore2Controller,
                            ),
                          ] else ...[
                            Text('Contatto Emergenza (Socio Maggiorenne)', style: Theme.of(context).textTheme.titleMedium),
                            const Divider(),
                            const SizedBox(height: 8),
                            Text(
                              'Come richiesto, devi fornire i dati di almeno un genitore o tutore legale per le emergenze. Questi dati saranno visibili solo ai capi.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'Nome Genitore/Tutore Legale',
                              icon: Icons.person_outline,
                              controller: _nomeTutoreLegaleController,
                              isRequired: true,
                              validator: (v) => v!.isEmpty ? 'Campo obbligatorio' : null,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'Telefono Emergenza Genitore/Tutore',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              controller: _telefonoEmergenzaController,
                              isRequired: true,
                              validator: (v) => v!.isEmpty ? 'Campo obbligatorio' : null,
                            ),
                          ],
                        ],
                        
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
                                text: 'Continua',
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
