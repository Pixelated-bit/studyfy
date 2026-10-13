import 'package:flutter/material.dart';
import '../models/task.dart';

// True if the task is not done and its due date is before today
bool isOverdue(Task task) {
  if (task.isDone) return false;
  final due = task.dueDate.toLocal();
  final today = DateTime.now();
  return DateTime(due.year, due.month, due.day)
      .isBefore(DateTime(today.year, today.month, today.day));
}

class StatsScreen extends StatelessWidget {
  final List<Task> tasks;

  const StatsScreen({super.key, required this.tasks});

  Widget _statCard(BuildContext context, String label, int value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                '$value',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = tasks.length;
    final done = tasks.where((t) => t.isDone).length;
    final pending = total - done;
    final overdue = tasks.where(isOverdue).length;
    final percent = total == 0 ? 0.0 : done / total;

    final Map<String, List<Task>> bySubject = {};
    for (final task in tasks) {
      bySubject.putIfAbsent(task.subject, () => []).add(task);
    }
    final subjects = bySubject.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: total == 0
          ? const Center(child: Text('Add some tasks to see your stats.'))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Overall progress',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: percent, minHeight: 14),
          ),
          const SizedBox(height: 6),
          Text('${(percent * 100).round()}% of tasks completed'),
          const SizedBox(height: 16),
          Row(
            children: [
              _statCard(context, 'Total', total, Colors.indigo),
              _statCard(context, 'Done', done, Colors.green),
            ],
          ),
          Row(
            children: [
              _statCard(context, 'To do', pending, Colors.orange),
              _statCard(context, 'Overdue', overdue, Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'By subject',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final subject in subjects) ...[
            Builder(builder: (context) {
              final list = bySubject[subject]!;
              final subjectDone = list.where((t) => t.isDone).length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$subject: $subjectDone / ${list.length} done'),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: subjectDone / list.length,
                      minHeight: 8,
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}