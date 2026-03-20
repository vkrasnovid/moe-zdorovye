import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reminders_provider.dart';
import '../utils/reminder_utils.dart';

class UpcomingRemindersCard extends StatelessWidget {
  final VoidCallback onViewAll;

  const UpcomingRemindersCard({super.key, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Consumer<RemindersProvider>(
      builder: (context, provider, _) {
        final active = provider.reminders.where((r) => r.isActive).take(3).toList();
        debugPrint('[UpcomingRemindersCard] DEBUG: displaying ${active.length} upcoming reminders');
        if (active.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'Ближайшие напоминания',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...active.map((r) => ListTile(
                  dense: true,
                  leading: Icon(reminderTypeIcon(r.type), color: const Color(0xFF00897B), size: 20),
                  title: Text(r.title, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(scheduleDescription(r), style: const TextStyle(fontSize: 12)),
                )),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onViewAll,
                    child: const Text('Все напоминания →', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
