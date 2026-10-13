import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../providers/registration_provider.dart';
import '../../../core/theme/theme_provider.dart';

class RegistrationStep1Screen extends ConsumerStatefulWidget {
  const RegistrationStep1Screen({super.key});

  @override
  ConsumerState<RegistrationStep1Screen> createState() => _RegistrationStep1ScreenState();
}

class _RegistrationStep1ScreenState extends ConsumerState<RegistrationStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cognomeController = TextEditingController();
  String? _genere;
  String? _branch;
  DateTime? _dataDiNascita;

  @override
  void dispose() {
    _nomeController.dispose();
    _cognomeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _dataDiNascita != null) {
      ref.read(registrationProvider.notifier).updateDatiBase(
            nome: _nomeController.text,
            cognome: _cognomeController.text,
            genere: _genere!,
            dataDiNascita: _dataDiNascita!,
            branch: _branch!,
          );
      context.push('/register/step2');
    } else if (_dataDiNascita == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci la data di nascita')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  Text(
                    'AGESCI Bari 10',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Registrazione',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dati del socio da registrare',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  
                  // Info Alert
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Importante', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                              const SizedBox(height: 4),
                              Text(
                                'La tua registrazione è soggetta all\'approvazione di un Capo. Riceverai un\'email di conferma una volta che il tuo account sarà stato validato.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blue[800]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Stepper Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStepIndicator(context, '1', 'Dati Base', isActive: true),
                      _buildLine(context),
                      _buildStepIndicator(context, '2', 'Indirizzo', isActive: false),
                      _buildLine(context),
                      _buildStepIndicator(context, '3', 'Riepilogo', isActive: false),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          label: 'Nome',
                          placeholder: 'Mario',
                          icon: Icons.person_outline,
                          controller: _nomeController,
                          isRequired: true,
                          validator: (v) => v!.isEmpty ? 'Campo obbligatorio' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Cognome',
                          placeholder: 'Rossi',
                          icon: Icons.badge_outlined,
                          controller: _cognomeController,
                          isRequired: true,
                          validator: (v) => v!.isEmpty ? 'Campo obbligatorio' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        // Genere Dropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Genere', style: Theme.of(context).textTheme.labelMedium),
                                Text(' *', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.wc, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                              value: _genere,
                              items: const [
                                DropdownMenuItem(value: 'M', child: Text('Maschio')),
                                DropdownMenuItem(value: 'F', child: Text('Femmina')),
                                DropdownMenuItem(value: 'O', child: Text('Altro')),
                              ],
                              onChanged: (val) => setState(() => _genere = val),
                              validator: (v) => v == null ? 'Seleziona un genere' : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Branch Dropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Branca', style: Theme.of(context).textTheme.labelMedium),
                                Text(' *', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.group_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                              value: _branch,
                              items: const [
                                DropdownMenuItem(value: 'Branco', child: Text('Branco')),
                                DropdownMenuItem(value: 'Reparto', child: Text('Reparto')),
                                DropdownMenuItem(value: 'Clan/Fuoco', child: Text('Clan/Fuoco')),
                                DropdownMenuItem(value: 'Co.Ca.', child: Text('Co.Ca.')),
                              ],
                              onChanged: (val) => setState(() => _branch = val),
                              validator: (v) => v == null ? 'Seleziona la tua branca' : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Data Nascita
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Data di Nascita', style: Theme.of(context).textTheme.labelMedium),
                                Text(' *', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime(2010),
                                  firstDate: DateTime(1950),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() => _dataDiNascita = date);
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                                child: Text(
                                  _dataDiNascita != null 
                                    ? '${_dataDiNascita!.day}/${_dataDiNascita!.month}/${_dataDiNascita!.year}'
                                    : 'Seleziona data',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        CustomButton(
                          text: 'Continua',
                          onPressed: _submit,
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

  Widget _buildStepIndicator(BuildContext context, String step, String title, {required bool isActive}) {
    final color = isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5);
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isActive ? color : color.withOpacity(0.2),
          child: Text(
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
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8).copyWith(bottom: 16),
        height: 2,
        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2),
      ),
    );
  }
}
