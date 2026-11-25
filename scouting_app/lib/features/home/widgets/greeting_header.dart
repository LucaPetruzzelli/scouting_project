import 'package:flutter/material.dart';

class GreetingHeader extends StatelessWidget {
  final Map<String, dynamic>? profile;

  const GreetingHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final nome = profile?['nome'] ?? 'Scout';
    final role = profile?['role'] ?? 'socio';
    final branch = profile?['branch'] ?? 'Non assegnata';
    final jungleName = profile?['jungle_name'] as String?;

    // Capo del branco con soprannome: mostra il soprannome
    final isCapoBranco = (role == 'capo' || role == 'capo gruppo') && branch == 'l/c';
    final displayName = (isCapoBranco && jungleName != null && jungleName.isNotEmpty)
        ? jungleName
        : nome;

    // Determina il saluto in base all'ora
    final hour = DateTime.now().hour;
    String greeting = 'Buongiorno';
    if (hour >= 13 && hour < 18) {
      greeting = 'Buon pomeriggio';
    } else if (hour >= 18) {
      greeting = 'Buonasera';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Saluto
        Text(
          '$greeting, $displayName!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        
        // Citazione BP
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Icon(Icons.format_quote, size: 32, color: Colors.black38),
                const SizedBox(height: 8),
                Text(
                  '"Cerca di lasciare questo mondo un po\' migliore di come l\'hai trovato."',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '- Baden-Powell',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
