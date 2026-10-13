import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notifications_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsProvider);
    final theme = Theme.of(context);

    // Imposta la lingua di timeago in italiano (se disponibile, o usa default)
    timeago.setLocaleMessages('it', timeago.ItMessages());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bacheca Messaggi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Segna tutto come già letto',
            onPressed: () {
              ref.read(notificationsProvider.notifier).markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tutte le notifiche segnate come lette')),
              );
            },
          ),
        ],
      ),
      body: notificationsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Errore nel caricamento delle notifiche', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.read(notificationsProvider.notifier).loadNotifications(),
                child: const Text('Riprova'),
              )
            ],
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('Nessuna notifica', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text('La tua bacheca è vuota.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(notificationsProvider.notifier).loadNotifications(),
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isUnread = !notification.isRead;

                return Dismissible(
                  key: Key(notification.id),
                  direction: DismissDirection.horizontal,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    ref.read(notificationsProvider.notifier).deleteNotification(notification.id);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Notifica eliminata'), 
                        duration: const Duration(seconds: 4),
                        action: SnackBarAction(
                          label: 'ANNULLA',
                          textColor: theme.colorScheme.primaryContainer,
                          backgroundColor: theme.colorScheme.primary,
                          onPressed: () {
                            ref.read(notificationsProvider.notifier).restoreNotification(notification.id);
                          },
                        ),
                      ),
                    );
                  },
                  child: Material(
                    color: isUnread 
                        ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                        : Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (isUnread) {
                          ref.read(notificationsProvider.notifier).markAsRead(notification.id);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4, right: 16),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isUnread ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications,
                                size: 20,
                                color: isUnread ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notification.title,
                                          style: TextStyle(
                                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        timeago.format(notification.createdAt, locale: 'it'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isUnread ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification.message,
                                    style: TextStyle(
                                      color: isUnread ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isUnread)
                              Container(
                                margin: const EdgeInsets.only(left: 8, top: 24),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
