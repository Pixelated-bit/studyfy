import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'add_task_screen.dart';
import 'home_screen.dart';
import 'stats_screen.dart';
import 'insights_screen.dart';
import '../data/study_tips.dart';
import 'focus_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final ApiService _api = ApiService();
  final NotificationService _notifications = NotificationService();
  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tasks = await _api.getTasks();
      List<Map<String, dynamic>> logs = [];
      try {
        logs = await _api.getLogs();
      } catch (e) {}
      setState(() {
        _tasks = tasks;
        _logs = logs;
      });
    } catch (e) {
      setState(() => _error = 'Could not reach the server.\nIs the API running?');
    } finally {
      setState(() => _loading = false);
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _timeText(DateTime d) => TimeOfDay.fromDateTime(d).format(context);

  // Days in a row (ending today or yesterday) with at least one completed session
  int _streak() {
    final studyDays = <DateTime>{};
    for (final t in _tasks) {
      if (t.isDone) {
        final d = t.dueDate.toLocal();
        studyDays.add(DateTime(d.year, d.month, d.day));
      }
    }
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    // If nothing is done today yet, the streak is still alive from yesterday
    if (!studyDays.contains(day)) {
      day = day.subtract(const Duration(days: 1));
    }
    var count = 0;
    while (studyDays.contains(day)) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  Future<void> _toggleDone(Task task) async {
    try {
      final saved = await _api.updateTask(task.copyWith(isDone: !task.isDone));
      await _notifications.scheduleTask(saved);
      await _load();
    } catch (e) {
      _showMessage('Could not update the session');
    }
  }

  Future<void> _addSession() async {
    final newTask = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (context) => const AddTaskScreen()),
    );
    if (newTask != null) {
      try {
        final saved = await _api.addTask(newTask);
        await _notifications.scheduleTask(saved);
        await _load();
      } catch (e) {
        _showMessage('Could not save the session');
      }
    }
  }

  Future<void> _openAll() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
    _load(); // refresh when coming back
  }

  void _openStats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StatsScreen(tasks: _tasks)),
    );
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Widget _streakCard() {
    final streak = _streak();
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.local_fire_department,
                size: 44, color: Colors.deepOrange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    streak == 1 ? '1 day streak' : '$streak day streak',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    streak == 0
                        ? 'Complete a session today to start your streak.'
                        : 'Keep it going. Study a little every day.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _todayPlan(List<Task> today) {
    final done = today.where((t) => t.isDone).length;
    final progress = today.isEmpty ? 0.0 : done / today.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's plan",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (today.isEmpty)
              const Text('Nothing planned for today. Tap + to plan a session.')
            else ...[
              LinearProgressIndicator(value: progress, minHeight: 8),
              const SizedBox(height: 4),
              Text('$done of ${today.length} sessions done'),
              const SizedBox(height: 8),
              for (final task in today)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Checkbox(
                    value: task.isDone,
                    onChanged: (_) => _toggleDone(task),
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration:
                      task.isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(
                      '${task.subject}  •  ${_timeText(task.dueDate.toLocal())}'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _upNext() {
    final now = DateTime.now();
    final upcoming = _tasks
        .where((t) => !t.isDone && t.dueDate.toLocal().isAfter(now))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    if (upcoming.isEmpty) return const SizedBox.shrink();
    final next = upcoming.first;
    final d = next.dueDate.toLocal();
    return Card(
      child: ListTile(
        leading: const Icon(Icons.schedule),
        title: const Text('Up next'),
        subtitle: Text(
            '${next.title} (${next.subject})\n${d.day}/${d.month} at ${_timeText(d)}'),
        isThreeLine: true,
      ),
    );
  }
  // Shows study tips for today's first unfinished session, or the next one
  Widget _insightCard(List<Task> today) {
    final now = DateTime.now();
    Task? target;
    for (final t in today) {
      if (!t.isDone) {
        target = t;
        break;
      }
    }
    if (target == null) {
      final upcoming = _tasks
          .where((t) => !t.isDone && t.dueDate.toLocal().isAfter(now))
          .toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      if (upcoming.isNotEmpty) target = upcoming.first;
    }
    if (target == null) return const SizedBox.shrink();
    final subject = target.subject;
    final guide = guideFor(subject);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'How to study $subject',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(guide.summary),
            const SizedBox(height: 8),
            for (final method in guide.methods.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $method'),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InsightsScreen(subject: subject),
                  ),
                ),
                child: const Text('See all tips'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _minutesToday() {
    final now = DateTime.now();
    var total = 0;
    for (final log in _logs) {
      final d = DateTime.parse(log['studied_at'] as String).toLocal();
      if (_sameDay(d, now)) total += (log['minutes'] as num).toInt();
    }
    return total;
  }

  // The subject of the next unfinished session, or "General"
  String _focusSubject() {
    final now = DateTime.now();
    final open = _tasks
        .where((t) => !t.isDone && !t.dueDate.toLocal().isBefore(
        DateTime(now.year, now.month, now.day)))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return open.isEmpty ? 'General' : open.first.subject;
  }

  Future<void> _startFocus() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => FocusScreen(subject: _focusSubject()),
      ),
    );
    if (result == true) _load();
  }

  Widget _focusCard() {
    final minutes = _minutesToday();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.timer, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$minutes min studied today',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('Next focus: ${_focusSubject()}'),
                ],
              ),
            ),
            FilledButton(
              onPressed: _startFocus,
              child: const Text('Focus'),
            ),
          ],
        ),
      ),
    );
  }


  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    }
    final now = DateTime.now();
    final today = _tasks
        .where((t) => _sameDay(t.dueDate.toLocal(), now))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _greeting(),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          const Text('Small steps every day beat long cramming sessions.'),
          const SizedBox(height: 16),
          _streakCard(),
          const SizedBox(height: 8),
          _focusCard(),
          const SizedBox(height: 8),
          _todayPlan(today),
          const SizedBox(height: 8),
          _upNext(),
          const SizedBox(height: 8),
          _insightCard(today),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _openAll,
            icon: const Icon(Icons.list),
            label: const Text('All sessions'),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Studyfy'),
        actions: [
          IconButton(
            tooltip: 'Stats',
            icon: const Icon(Icons.bar_chart),
            onPressed: _openStats,
          ),
        ],
      ),
      body: _body(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSession,
        icon: const Icon(Icons.add),
        label: const Text('Plan session'),
      ),
    );
  }
}