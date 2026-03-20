import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reminder.dart';
import '../../providers/profiles_provider.dart';
import '../../providers/reminders_provider.dart';
import '../../utils/reminder_utils.dart';
import 'reminder_form_sheet.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileId = context.read<ProfilesProvider>().activeProfileId;
      if (profileId != null) {
        debugPrint('[RemindersScreen] DEBUG: mount, loading reminders for profileId=$profileId');
        context.read<RemindersProvider>().loadReminders(profileId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Напоминания')),
      body: Consumer<RemindersProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final reminders = provider.reminders;
          debugPrint('[RemindersScreen] DEBUG: rendering ${reminders.length} reminders');
          if (reminders.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            itemCount: reminders.length,
            itemBuilder: (ctx, i) => _ReminderCard(reminder: reminders[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('Нет напоминаний', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _openForm(context, null),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, Reminder? reminder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReminderFormSheet(existingReminder: reminder),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  const _ReminderCard({required this.reminder});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        debugPrint('[RemindersScreen] DEBUG: swipe-delete reminder id=${reminder.id}');
        context.read<RemindersProvider>().deleteReminder(reminder.id!);
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF00897B).withAlpha(30),
          child: Icon(reminderTypeIcon(reminder.type), color: const Color(0xFF00897B)),
        ),
        title: Text(reminder.title),
        subtitle: Text(scheduleDescription(reminder)),
        trailing: Switch(
          value: reminder.isActive,
          onChanged: (_) => context.read<RemindersProvider>().toggleActive(reminder.id!),
          activeColor: const Color(0xFF00897B),
        ),
        onTap: () => _openEditSheet(context),
      ),
    );
  }

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReminderFormSheet(existingReminder: reminder),
    );
  }
}
