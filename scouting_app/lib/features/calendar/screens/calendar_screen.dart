import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../events/providers/events_provider.dart';
import '../../events/models/event_model.dart';
import '../../auth/providers/auth_provider.dart';

// Enum per la vista del calendario
enum CalendarView { month, week, day }

// Provider per la data selezionata e la vista
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final calendarViewProvider = StateProvider<CalendarView>((ref) => CalendarView.month);
final eventTypeFilterProvider = StateProvider<String?>((ref) => null);

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late PageController _pageController;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _pageController = PageController(initialPage: 1000);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(calendarViewProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final eventTypeFilter = ref.watch(eventTypeFilterProvider);
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              final now = DateTime.now();
              ref.read(selectedDateProvider.notifier).state = now;
              setState(() {
                _currentMonth = DateTime(now.year, now.month, 1);
                _pageController.jumpToPage(1000);
              });
            },
            tooltip: 'Oggi',
          ),
        ],
      ),
      body: Column(
        children: [
          // Selettore vista
          _buildViewSelector(view),
          
          // Filtri per tipo evento
          _buildEventTypeFilter(eventTypeFilter),

          // Header con navigazione mese/settimana
          _buildNavigationHeader(view, selectedDate),

          // Corpo del calendario
          Expanded(
            child: eventsAsync.when(
              data: (allEvents) {
                // Filtra per tipo se selezionato
                final events = eventTypeFilter == null
                    ? allEvents
                    : allEvents.where((e) => e.eventType == eventTypeFilter).toList();

                if (view == CalendarView.month) {
                  return _buildMonthView(events, selectedDate);
                } else if (view == CalendarView.week) {
                  return _buildWeekView(events, selectedDate);
                } else {
                  return _buildDayView(events, selectedDate);
                }
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Errore: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildViewSelector(CalendarView currentView) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<CalendarView>(
        selected: {currentView},
        onSelectionChanged: (val) {
          ref.read(calendarViewProvider.notifier).state = val.first;
        },
        segments: const [
          ButtonSegment(value: CalendarView.month, label: Text('Mese'), icon: Icon(Icons.calendar_month, size: 16)),
          ButtonSegment(value: CalendarView.week, label: Text('Settimana'), icon: Icon(Icons.view_week, size: 16)),
          ButtonSegment(value: CalendarView.day, label: Text('Giorno'), icon: Icon(Icons.view_day, size: 16)),
        ],
      ),
    );
  }

  Widget _buildEventTypeFilter(String? currentFilter) {
    final filters = [
      (null, 'Tutti'),
      ('Riunione', 'Riunioni'),
      ('Uscita', 'Uscite'),
      ('Campo', 'Campi'),
      ('Altro', 'Altro'),
    ];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: filters.map((f) {
          final isSelected = currentFilter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f.$2),
              selected: isSelected,
              onSelected: (_) {
                ref.read(eventTypeFilterProvider.notifier).state = isSelected ? null : f.$1;
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNavigationHeader(CalendarView view, DateTime selectedDate) {
    String title;
    if (view == CalendarView.month) {
      title = DateFormat('MMMM yyyy', 'it_IT').format(_currentMonth);
    } else if (view == CalendarView.week) {
      final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      title = '${DateFormat('dd MMM', 'it_IT').format(startOfWeek)} – ${DateFormat('dd MMM yyyy', 'it_IT').format(endOfWeek)}';
    } else {
      title = DateFormat('EEEE, d MMMM yyyy', 'it_IT').format(selectedDate);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _navigate(-1, view),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _navigate(1, view),
          ),
        ],
      ),
    );
  }

  void _navigate(int direction, CalendarView view) {
    final current = ref.read(selectedDateProvider);
    if (view == CalendarView.month) {
      setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + direction, 1);
      });
      ref.read(selectedDateProvider.notifier).state = _currentMonth;
    } else if (view == CalendarView.week) {
      ref.read(selectedDateProvider.notifier).state =
          current.add(Duration(days: 7 * direction));
    } else {
      ref.read(selectedDateProvider.notifier).state =
          current.add(Duration(days: direction));
    }
  }

  // ─── VISTA MENSILE ───────────────────────────────────────────────────────────

  Widget _buildMonthView(List<EventModel> events, DateTime selectedDate) {
    final firstDayOfMonth = _currentMonth;
    final daysInMonth = DateTime(firstDayOfMonth.year, firstDayOfMonth.month + 1, 0).day;

    // Giorno della settimana del primo giorno (1=Lun, 7=Dom → adattiamo a 0-based)
    int firstWeekday = firstDayOfMonth.weekday; // 1=Lun, 7=Dom
    int leadingBlanks = firstWeekday - 1; // quante celle vuote all'inizio
    final totalCells = _calculateCellCount(firstDayOfMonth, daysInMonth);
    final weeksNeeded = _calculateWeeksNeeded(leadingBlanks, daysInMonth);

    final today = DateTime.now();

    // Raggruppa eventi per data
    Map<String, List<EventModel>> eventsByDay = {};
    for (final event in events) {
      final key = DateFormat('yyyy-MM-dd').format(event.startDate);
      eventsByDay.putIfAbsent(key, () => []).add(event);
    }

    // Lista eventi del giorno selezionato
    final selectedKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    final selectedEvents = eventsByDay[selectedKey] ?? [];

    // Calcola l'altezza della griglia basata sul numero di settimane
    final weekHeaderHeight = 40.0; // altezza header giorni settimana
    final dividerHeight = 1.0;
    final eventsSectionMinHeight = 100.0; // altezza minima per la sezione eventi

    return Column(
      children: [
        // Header giorni settimana
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'].map((d) {
              return Expanded(
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),

        // Griglia giorni con altezza dinamica
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: SizedBox(
            height: weeksNeeded * 72.0, // 72 = altezza media di una riga (72 * 6 = 432px per 6 settimane)
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: totalCells,
                itemBuilder: (context, index) {
                  // Celle vuote all'inizio del mese
                  if (index < leadingBlanks) return const SizedBox.shrink();

                  // Celle vuote alla fine del mese (se necessario per riempire 6 settimane)
                  if (index >= leadingBlanks + daysInMonth) return const SizedBox.shrink();

                  final day = index - leadingBlanks + 1;
                  final date = DateTime(firstDayOfMonth.year, firstDayOfMonth.month, day);
                  final dateKey = DateFormat('yyyy-MM-dd').format(date);
                  final dayEvents = eventsByDay[dateKey] ?? [];
                  final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
                  final isSelected = date.year == selectedDate.year && date.month == selectedDate.month && date.day == selectedDate.day;

                  return GestureDetector(
                    onTap: () {
                      ref.read(selectedDateProvider.notifier).state = date;
                    },
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : isToday
                                ? Colors.red
                                : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : isToday
                                      ? Colors.white
                                      : null,
                              fontSize: 13,
                            ),
                          ),
                          if (dayEvents.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: dayEvents.take(3).map((e) {
                                return Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.only(right: 1),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : _eventTypeColor(e.eventType),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        const Divider(height: 1),

        // Lista eventi del giorno selezionato
        Expanded(
          child: selectedEvents.isEmpty
              ? Center(
                  child: Text(
                    'Nessun evento il ${DateFormat('d MMMM', 'it_IT').format(selectedDate)}',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: selectedEvents.length,
                  itemBuilder: (context, index) {
                    return _buildEventTile(selectedEvents[index]);
                  },
                ),
        ),
      ],
    );
  }

  // ─── VISTA SETTIMANALE ───────────────────────────────────────────────────────

  Widget _buildWeekView(List<EventModel> events, DateTime selectedDate) {
    final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    final today = DateTime.now();

    // Raggruppa eventi per data
    Map<String, List<EventModel>> eventsByDay = {};
    for (final event in events) {
      final key = DateFormat('yyyy-MM-dd').format(event.startDate);
      eventsByDay.putIfAbsent(key, () => []).add(event);
    }

    return Column(
      children: [
        // Header giorni settimana con numeri
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Row(
            children: days.map((day) {
              final key = DateFormat('yyyy-MM-dd').format(day);
              final hasEvents = (eventsByDay[key] ?? []).isNotEmpty;
              final isToday = day.year == today.year && day.month == today.month && day.day == today.day;
              final isSelected = day.year == selectedDate.year && day.month == selectedDate.month && day.day == selectedDate.day;

              return Expanded(
                child: GestureDetector(
                  onTap: () => ref.read(selectedDateProvider.notifier).state = day,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: isSelected ? Border(bottom: BorderSide(color: Theme.of(context).colorScheme.primary, width: 3)) : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('E', 'it_IT').format(day).substring(0, 3).toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: isToday
                              ? BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                )
                              : null,
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isToday
                                    ? Colors.white
                                    : isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                              ),
                            ),
                          ),
                        ),
                        if (hasEvents)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const Divider(height: 1),

        // Lista eventi del giorno selezionato
        Expanded(
          child: () {
            final key = DateFormat('yyyy-MM-dd').format(selectedDate);
            final dayEvents = eventsByDay[key] ?? [];
            if (dayEvents.isEmpty) {
              return Center(
                child: Text(
                  'Nessun evento il ${DateFormat('EEEE d MMMM', 'it_IT').format(selectedDate)}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: dayEvents.length,
              itemBuilder: (context, index) => _buildEventTile(dayEvents[index]),
            );
          }(),
        ),
      ],
    );
  }

  // ─── VISTA GIORNALIERA ───────────────────────────────────────────────────────

  Widget _buildDayView(List<EventModel> events, DateTime selectedDate) {
    final dayEvents = events.where((e) {
      return e.startDate.year == selectedDate.year &&
          e.startDate.month == selectedDate.month &&
          e.startDate.day == selectedDate.day;
    }).toList();

    if (dayEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'Nessun evento oggi',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: dayEvents.length,
      itemBuilder: (context, index) => _buildEventTile(dayEvents[index], expanded: true),
    );
  }

  // ─── CARD EVENTO ─────────────────────────────────────────────────────────────

  Widget _buildEventTile(EventModel event, {bool expanded = false}) {
    final color = _eventTypeColor(event.eventType);
    final timeStr = DateFormat('HH:mm').format(event.startDate);
    final endTimeStr = DateFormat('HH:mm').format(event.endDate);
    final profile = ref.read(authProvider).profile;
    final isCapo = profile != null &&
        (profile['role'] == 'capo' || profile['role'] == 'capo gruppo');
    final isCreator = profile != null && event.createdBy == profile['id'];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/events/detail', extra: event),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colore evento tipo
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            event.eventType,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        if (event.fee != null) ...[ 
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '€ ${event.fee!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '$timeStr – $endTimeStr',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (event.location != null && event.location!.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.location_on, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              event.location!,
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isCapo || isCreator)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      context.push('/events/edit', extra: event);
                    } else if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Elimina evento'),
                          content: const Text('Sei sicuro?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Elimina', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && mounted) {
                        await ref.read(eventsProvider.notifier).deleteEvent(event.id);
                      }
                    } else if (value == 'payments') {
                      context.push('/events/payments', extra: event);
                    }
                  },
                  itemBuilder: (_) => [
                    if (isCapo || isCreator)
                      const PopupMenuItem(value: 'edit', child: Text('Modifica')),
                    if (event.fee != null)
                      const PopupMenuItem(value: 'payments', child: Text('Gestione Quote')),
                    if (isCapo || isCreator)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Elimina', style: TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _eventTypeColor(String type) {
    switch (type) {
      case 'Riunione': return Colors.blue;
      case 'Uscita': return Colors.green;
      case 'Campo': return Colors.orange;
      default: return Colors.purple;
    }
  }

  Widget? _buildFab() {
    final profile = ref.read(authProvider).profile;
    final isCapo = profile != null &&
        (profile['role'] == 'capo' || profile['role'] == 'capo gruppo');

    // Anche capo squadriglia può creare riunioni di squadriglia
    final squadRole = profile?['squad_role'] as String?;
    final canCreate = isCapo || squadRole == 'capo' || squadRole == 'vice';

    if (!canCreate) return null;

    return FloatingActionButton.extended(
      onPressed: () => context.push('/events/create'),
      icon: const Icon(Icons.add),
      label: const Text('Nuova Attività'),
    );
  }

  /// Calcola il numero massimo di celle necessarie per visualizzare il mese
  /// Garantisce sempre almeno 6 settimane (42 celle)
  int _calculateCellCount(DateTime firstDayOfMonth, int daysInMonth) {
    final firstWeekday = firstDayOfMonth.weekday; // 1=Lun, 7=Dom
    final leadingBlanks = firstWeekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    // Sempre almeno 6 settimane (42 celle)
    return totalCells < 42 ? 42 : totalCells;
  }

  /// Calcola il numero di settimane necessarie per visualizzare il mese
  /// in base al primo giorno della settimana e ai giorni del mese
  int _calculateWeeksNeeded(int leadingBlanks, int daysInMonth) {
    final totalCells = leadingBlanks + daysInMonth;
    final weeks = (totalCells / 7).ceil();
    return weeks < 6 ? 6 : weeks;
  }
}
