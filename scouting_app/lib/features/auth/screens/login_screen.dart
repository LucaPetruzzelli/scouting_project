import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/theme_provider.dart';

double _calculateWelcomeFontSize(double maxWidth) {
  // Font size per "Benvenuto" che si adatta dinamicamente
  final minWidth = 320.0;
  final maxWidthLimit = 800.0;

  final minFontSize = 18.0;
  final maxFontSize = 24.0;

  final normalizedWidth = ((maxWidth - minWidth) / (maxWidthLimit - minWidth)).clamp(0.0, 1.0);
  final fontSize = minFontSize + (maxFontSize - minFontSize) * normalizedWidth;

  return fontSize;
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Inserisci email e password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref.read(authProvider.notifier).signIn(email, password);
    
    if (!mounted) return;
    
    if (!success) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Credenziali errate o account inesistente.';
      });
    }
    // Se ha successo, il router (GoRouter) reindirizzerà in automatico grazie al listener
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
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxWidth = constraints.maxWidth;
                        // Calcola la dimensione del logo in base alla larghezza disponibile
                        final logoSize = (maxWidth * 0.4).clamp(100.0, 200.0);
                        return Image.asset(
                          isDarkMode
                              ? 'assets/images/loghi_ba10/BARI10_Bianco_HiRes.png'
                              : 'assets/images/loghi_ba10/BARI10_Nero_HiRes.png',
                          width: logoSize,
                          height: logoSize,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback in caso l'immagine non esiste
                            return Container(
                              width: logoSize,
                              height: logoSize,
                              color: Colors.grey,
                              child: const Icon(Icons.image_not_supported, size: 40),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxWidth = constraints.maxWidth;
                        final fontSize = _calculateWelcomeFontSize(maxWidth);
                        return Text(
                          'Benvenuto',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  CustomTextField(
                    label: 'Email',
                    placeholder: 'mario@email.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Password',
                    placeholder: 'Inserisci la tua password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    controller: _passwordController,
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Accedi',
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      context.push('/register/step1');
                    },
                    child: Text(
                      'Non hai un account? Registrati',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
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
}
