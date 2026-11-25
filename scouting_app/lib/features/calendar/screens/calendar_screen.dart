import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../events/providers/events_provider.dart';
import '../../events/models/event_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../../core/theme/app_colors.dart';

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
          Consumer(
            builder: (context, ref, child) {
              final notifState = ref.watch(notificationsProvider);
              final count = notifState.value?.where((n) => !n.isRead).length ?? 0;

              return IconButton(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text(count.toString()),
                  child: const Icon(Icons.notifications_none),
                ),
                onPressed: () => context.push('/notifications'),
              );
            },
          ),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<CalendarView>(
          selected: {currentView},
          onSelectionChanged: (val) {
            ref.read(calendarViewProvider.notifier).state = val.first;
          },
          segments: const [
            ButtonSegment(
              value: CalendarView.month,
              label: Text('Mese'),
              icon: Icon(Icons.calendar_month, size: 16),
            ),
            ButtonSegment(
              value: CalendarView.week,
              label: Text('Settimana'),
              icon: Icon(Icons.view_week, size: 16),
            ),
            ButtonSegment(
              value: CalendarView.day,
              label: Text('Giorno'),
              icon: Icon(Icons.view_day, size: 16),
            ),
          ],
        ),
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
      // NON cambiare la data selezionata quando si naviga tra i mesi
      // La data selezionata rimane quella scelta dall'utente (o oggi se non ha selezionato nulla)
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
    final totalCells = leadingBlanks + daysInMonth;
    // Arrotonda al multiplo di 7 più vicino (minimo 35 celle = 5 settimane)
    final cellsCount = totalCells < 35 ? 35 : ((totalCells / 7).ceil() * 7);
    final weeksNeeded = cellsCount ~/ 7;

    final today = DateTime.now();
    final isCurrentMonth = firstDayOfMonth.year == today.year && firstDayOfMonth.month == today.month;

    // Verifica se l'utente ha selezionato un giorno specifico in questo mese
    final isSelectedDayInCurrentMonth = selectedDate.year == firstDayOfMonth.year &&
        selectedDate.month == firstDayOfMonth.month;

    // Raggruppa eventi per data
    Map<String, List<EventModel>> eventsByDay = {};
    for (final event in events) {
      final key = DateFormat('yyyy-MM-dd').format(event.startDate);
      eventsByDay.putIfAbsent(key, () => []).add(event);
    }

    // Determina quali eventi mostrare:
    // - Se l'utente ha selezionato un giorno in questo mese: solo eventi di quel giorno
    // - Altrimenti: tutti gli eventi del mese corrente visualizzato
    List<EventModel> eventsToShow;
    String emptyMessage;
    if (isSelectedDayInCurrentMonth) {
      final selectedKey = DateFormat('yyyy-MM-dd').format(selectedDate);
      eventsToShow = eventsByDay[selectedKey] ?? [];
      final weekday = DateFormat('EEEE', 'it_IT').format(selectedDate);
      final day = selectedDate.day;
      final month = DateFormat('MMMM', 'it_IT').format(selectedDate);
      emptyMessage = 'nessun evento in programma $weekday $day $month';
    } else {
      // Mostra tutti gli eventi del mese visualizzato
      eventsToShow = [];
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(firstDayOfMonth.year, firstDayOfMonth.month, day);
        final key = DateFormat('yyyy-MM-dd').format(date);
        eventsToShow.addAll(eventsByDay[key] ?? []);
      }
      final month = DateFormat('MMMM', 'it_IT').format(firstDayOfMonth);
      emptyMessage = 'nessun evento in programma per $month';
    }

    // Altezza fissa per ogni riga settimana
    const double weekRowHeight = 76.0;

    return CustomScrollView(
      slivers: [
        // Header giorni settimana - altezza fissa
        SliverToBoxAdapter(
          child: SizedBox(
            height: 28,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'].map((d) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 4)),

        // Griglia giorni con righe ad altezza fissa
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: List.generate(weeksNeeded, (weekIndex) {
                return SizedBox(
                  height: weekRowHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(7, (dayIndex) {
                      final cellIndex = weekIndex * 7 + dayIndex;

                      // Celle vuote all'inizio del mese
                      if (cellIndex < leadingBlanks) {
                        return const Expanded(child: SizedBox.shrink());
                      }

                      // Celle vuote alla fine del mese
                      if (cellIndex >= leadingBlanks + daysInMonth) {
                        return const Expanded(child: SizedBox.shrink());
                      }

                      final day = cellIndex - leadingBlanks + 1;
                      final date = DateTime(firstDayOfMonth.year, firstDayOfMonth.month, day);
                      final dateKey = DateFormat('yyyy-MM-dd').format(date);
                      final dayEvents = eventsByDay[dateKey] ?? [];

                      // Evidenzia SOLO il giorno corrente nel mese corrente
                      final isToday = isCurrentMonth && date.year == today.year && date.month == today.month && date.day == today.day;
                      // Evidenzia il giorno selezionato (se in questo mese)
                      final isSelected = isSelectedDayInCurrentMonth && date.year == selectedDate.year && date.month == selectedDate.month && date.day == selectedDate.day;

                      return Expanded(
                        child: GestureDetector(
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
                                              : isToday
                                                  ? Colors.white
                                                                                                : _getBranchBackgroundColor(e.targetBranches),
                                          shape: BoxShape.circle,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: Divider(height: 1)),

        // Lista eventi - scorre insieme alla griglia
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (eventsToShow.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      emptyMessage,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: _buildEventTile(eventsToShow[index]),
              );
            },
            childCount: eventsToShow.isEmpty ? 1 : eventsToShow.length,
          ),
        ),
        // Spazio extra in fondo per non tagliare l'ultimo evento
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
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

    // Lista eventi del giorno selezionato
    final key = DateFormat('yyyy-MM-dd').format(selectedDate);
    final dayEvents = eventsByDay[key] ?? [];

    // Formatta messaggio vuoto con giorno settimana, giorno, mese
    final weekday = DateFormat('EEEE', 'it_IT').format(selectedDate);
    final day = selectedDate.day;
    final month = DateFormat('MMMM', 'it_IT').format(selectedDate);
    final emptyMessage = 'nessun evento in programma $weekday $day $month';

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
          child: dayEvents.isEmpty
              ? Center(
                  child: Text(
                    emptyMessage,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: dayEvents.length,
                  itemBuilder: (context, index) => _buildEventTile(dayEvents[index]),
                ),
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

    // Formatta messaggio vuoto con giorno settimana, giorno, mese
    final weekday = DateFormat('EEEE', 'it_IT').format(selectedDate);
    final day = selectedDate.day;
    final month = DateFormat('MMMM', 'it_IT').format(selectedDate);
    final emptyMessage = 'nessun evento in programma $weekday $day $month';

    if (dayEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
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
    final branchLabel = _formatBranchLabel(event.targetBranches);
    final branchColor = _getBranchLabelColor(event.targetBranches);
    final timeStr = DateFormat('HH:mm').format(event.startDate);
    final endTimeStr = DateFormat('HH:mm').format(event.endDate);
    final profile = ref.read(authProvider).profile;
    final isCapo = profile != null &&
        (profile['role'] == 'capo' || profile['role'] == 'capo gruppo');
    final isCreator = profile != null && event.createdBy == profile['id'];

    // Single subtle tinted background - no visible gradient bands
    final backgroundTint = branchColor.withValues(alpha: 0.035);
    final borderColor = branchColor.withValues(alpha: 0.22);
    final accentBarColor = branchColor.withValues(alpha: 0.85);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      elevation: 0,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/events/detail', extra: event),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            // Single solid tinted color - eliminates gradient banding
            color: backgroundTint,
            // Left accent border as primary visual indicator
            border: Border(
              left: BorderSide(color: accentBarColor, width: 4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Branch label chip - solid background with white text for high contrast
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: branchColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: branchColor.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                branchLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            if (event.fee != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
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
                        const SizedBox(height: 8),
                        Text(
                          event.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
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
                      icon: Icon(Icons.more_vert, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
        ),
      );
  }

  /// Gets the background color for an event tile based on target branches
  /// Rules:
  /// - Pure yellow for branco-only
  /// - Pure green for reparto-only
  /// - Pure red for clan-only (or fuoco)
  /// - Pure purple for comunità capi-only (or coca) OR for "gruppo" (all 4 branches)
  /// - Blended colors for multi-branch events that don't include all 4 branches
  Color _getBranchBackgroundColor(List<String> targetBranches) {
    if (targetBranches.isEmpty) {
      return Theme.of(context).colorScheme.surface;
    }

    final colors = _mapBranchesToColors(targetBranches);

    // Se non ci sono colori riconosciuti, restituisci superficie
    if (colors.isEmpty) {
      return Theme.of(context).colorScheme.surface;
    }

    // Se c'è un solo colore, restituiscilo puro
    if (colors.length == 1) {
      return colors.first;
    }

    // Verifica se abbiamo tutte e 4 le branche (branco, reparto, clan, comunità capi)
    final hasBranco = colors.contains(AppColors.brancoYellow);
    final hasReparto = colors.contains(AppColors.repartoGreen);
    final hasClan = colors.contains(AppColors.clanRed);
    final hasCoca = colors.contains(AppColors.cocaPurple);

    // Se ci sono tutte e 4 le branche (gruppo completo), restituisci viola puro
    if (hasBranco && hasReparto && hasClan && hasCoca) {
      return AppColors.cocaPurple;
    }

    // Altrimenti, blend dei colori presenti
    return _blendColors(colors);
  }

  /// Maps branch names to their corresponding colors
  List<Color> _mapBranchesToColors(List<String> branches) {
    final colors = <Color>[];
    final normalizedBranches = branches.map((b) => b.toLowerCase().trim()).toList();

    for (final branch in normalizedBranches) {
      if (branch == 'branco') {
        colors.add(AppColors.brancoYellow);
      } else if (branch == 'reparto') {
        colors.add(AppColors.repartoGreen);
      } else if (branch == 'clan' || branch == 'fuoco' || branch == 'clan/fuoco') {
        colors.add(AppColors.clanRed);
      } else if (branch == 'comunità capi' || branch == 'coca' || branch == 'co.ca.') {
        colors.add(AppColors.cocaPurple);
      }
      // Nota: 'gruppo' non viene mappato qui - viene gestito in _getBranchBackgroundColor
      // controllando se tutte e 4 le branche sono presenti
    }

    return colors;
  }

  /// Blends multiple colors together by averaging their RGB components
  Color _blendColors(List<Color> colors) {
    if (colors.isEmpty) {
      return Theme.of(context).colorScheme.surface;
    }

    int r = 0, g = 0, b = 0;

    for (final color in colors) {
      r += color.r.toInt();
      g += color.g.toInt();
      b += color.b.toInt();
    }

    final count = colors.length;
    return Color.fromARGB(
      255,
      r ~/ count,
      g ~/ count,
      b ~/ count,
    );
  }

  /// Formats branch names for display in event tiles
  /// - All 4 branches → "Gruppo"
  /// - Single branch → short name (e.g., "Co.Ca.", "Branco")
  /// - Multiple branches → comma-separated short names
  String _formatBranchLabel(List<String> branches) {
    if (branches.isEmpty) return 'Evento';

    final normalized = branches.map((b) => b.toLowerCase().trim()).toList();

    // Check if all 4 branches are present (Gruppo)
    final hasBranco = normalized.contains('branco');
    final hasReparto = normalized.contains('reparto');
    final hasClan = normalized.contains('clan') || normalized.contains('fuoco') || normalized.contains('clan/fuoco');
    final hasCoca = normalized.contains('comunità capi') || normalized.contains('coca') || normalized.contains('co.ca.');

    if (hasBranco && hasReparto && hasClan && hasCoca) {
      return 'Gruppo';
    }

    // Map to short display names
    final shortNames = <String>[];
    for (final branch in normalized) {
      if (branch == 'branco') {
        shortNames.add('Branco');
      } else if (branch == 'reparto') {
        shortNames.add('Reparto');
      } else if (branch == 'clan' || branch == 'fuoco' || branch == 'clan/fuoco') {
        shortNames.add('Clan');
      } else if (branch == 'comunità capi' || branch == 'coca' || branch == 'co.ca.') {
        shortNames.add('Co.Ca.');
      }
    }

    return shortNames.join(', ');
  }

  /// Gets the color for the branch label chip based on target branches
  /// Uses the same logic as background color but returns a vibrant version for text
  Color _getBranchLabelColor(List<String> branches) {
    if (branches.isEmpty) return Colors.grey;

    final colors = _mapBranchesToColors(branches);

    if (colors.isEmpty) return Colors.grey;

    // Single branch → use that branch's color
    if (colors.length == 1) {
      return colors.first;
    }

    // All 4 branches (Gruppo) → purple
    final hasBranco = colors.contains(AppColors.brancoYellow);
    final hasReparto = colors.contains(AppColors.repartoGreen);
    final hasClan = colors.contains(AppColors.clanRed);
    final hasCoca = colors.contains(AppColors.cocaPurple);

    if (hasBranco && hasReparto && hasClan && hasCoca) {
      return AppColors.cocaPurple;
    }

    // Multiple branches → blend
    return _blendColors(colors);
  }

  Widget? _buildFab() {
    final profile = ref.read(authProvider).profile;
    if (profile == null) return null;

    final isCapo = profile['role'] == 'capo' || profile['role'] == 'capo gruppo';

    // Anche capo squadriglia può creare riunioni di squadriglia
    final squadRole = profile['squad_role'] as String?;
    final canCreate = isCapo || squadRole == 'capo' || squadRole == 'vice';

    if (!canCreate) return null;

    return FloatingActionButton.extended(
      onPressed: () => context.push('/events/create'),
      icon: const Icon(Icons.add),
      label: const Text('Nuova Attività'),
    );
  }
}
