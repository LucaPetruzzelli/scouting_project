import 'package:flutter/material.dart';

class BpDailyQuoteCard extends StatelessWidget {
  const BpDailyQuoteCard({super.key});

  static const List<Map<String, String>> _quotesPool = [
    {
      'quote': 'Cercate di lasciare questo mondo un po\' migliore di quanto non l\'abbiate trovato.',
      'author': 'Robert Baden-Powell'
    },
    {
      'quote': 'Non esiste buono o cattivo tempo, ma solo buono o cattivo equipaggiamento.',
      'author': 'Robert Baden-Powell'
    },
    {
      'quote': 'Il vero modo di essere felici è quello di procurare la felicità agli altri.',
      'author': 'Robert Baden-Powell'
    },
    {
      'quote': 'Un sorriso è una chiave segreta che apre molti cuori.',
      'author': 'Robert Baden-Powell'
    },
    {
      'quote': 'Uno scout sorride e fischia in tutte le difficoltà.',
      'author': 'Robert Baden-Powell'
    },
    {
      'quote': 'Guida da te la tua canoa, non aspettare che siano gli altri a remare per te.',
      'author': 'Robert Baden-Powell'
    },
  ];

  /// Calcola l'indice giornaliero basato sulla mezzanotte dell'ora italiana (Europe/Rome)
  Map<String, String> _getTodayQuote() {
    final nowUtc = DateTime.now().toUtc();
    // Fuso orario italiano (UTC+1 / UTC+2)
    final italyTime = nowUtc.add(const Duration(hours: 2));
    final daysSinceEpoch = DateTime(italyTime.year, italyTime.month, italyTime.day)
        .difference(DateTime(2026, 1, 1))
        .inDays
        .abs();
    return _quotesPool[daysSinceEpoch % _quotesPool.length];
  }

  @override
  Widget build(BuildContext context) {
    final quoteData = _getTodayQuote();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.format_quote_rounded, color: Colors.white70, size: 32),
          const SizedBox(height: 8),
          Text(
            '“${quoteData['quote']}”',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            '— ${quoteData['author']}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }
}