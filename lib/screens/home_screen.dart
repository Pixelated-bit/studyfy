import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'add_task_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  final NotificationService _notifications = NotificationService();
  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;

  // Filters
  String _statusFilter = 'all'; // 'all', 'todo' or 'done'
  String? _subjectFilter; // null means every subject

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tasks = await _api.getTasks();
      setState(() => _tasks = tasks);
    } catch (e) {
      setState(() => _error = 'Could not reach the server.\nIs the API running?');
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _priorityColor(int priority) {
    if (priority == 3) return Colors.red;
    if (priority == 2) return Colors.orange;
    return Colors.green;
  }

  List<Task> get _visibleTasks {
    return _tasks.where((task) {
      if (_statusFilter == 'todo' && task.isDone) return false;
      if (_statusFilter == 'done' && !task.isDone) return false;
      if (_subjectFilter != null && task.subject != _subjectFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  List<String> get _subjects {
    final set = _tasks.map((t) => t.subject).toSet().toList();
    set.sort();
    return set;
  }

  Future<void> _toggleDone(Task task) async {
    try {
      final saved = await _api.updateTask(task.copyWith(isDone: !task.isDone));
      await _notifications.scheduleTask(saved); // cancels it if done
      await _loadTasks();
    } catch (e) {
      _showMessage('Could not update the task');
    }
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await _api.deleteTask(task.id!);
      await _notifications.cancelTask(task.id!);
      await _loadTasks();
    } catch (e) {
      _showMessage('Could not delete the task');
    }
  }

  Future<void> _openAddScreen() async {
    final newTask = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (context) => const AddTaskScreen()),
    );
    if (newTask != null) {
      try {
        final saved = await _api.addTask(newTask);
        await _notifications.scheduleTask(saved);
        await _loadTasks();
      } catch (e) {
        _showMessage('Could not save the task');
      }
    }
  }

  Future<void> _openEditScreen(Task task) async {
    final updated = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (context) => AddTaskScreen(task: task)),
    );
    if (updated != null) {
      try {
        final saved = await _api.updateTask(updated);
        await _notifications.scheduleTask(saved);
        await _loadTasks();
      } catch (e) {
        _showMessage('Could not update the task');
      }
    }
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

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: _statusFilter == 'all',
            onSelected: (_) => setState(() => _statusFilter = 'all'),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('To do'),
            selected: _statusFilter == 'todo',
            onSelected: (_) => setState(() => _statusFilter = 'todo'),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Done'),
            selected: _statusFilter == 'done',
            onSelected: (_) => setState(() => _statusFilter = 'done'),
          ),
          const SizedBox(width: 16),
          for (final subject in _subjects) ...[
            FilterChip(
              label: Text(subject),
              selected: _subjectFilter == subject,
              onSelected: (selected) =>
                  setState(() => _subjectFilter = selected ? subject : null),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 72, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildList() {
    final tasks = _visibleTasks;
    if (_tasks.isEmpty) {
      return _emptyState(Icons.menu_book, 'No tasks yet.\nTap + to add one.');
    }
    if (tasks.isEmpty) {
      return _emptyState(Icons.filter_list_off, 'No tasks match this filter.');
    }
    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          final overdue = isOverdue(task);
          final due = task.dueDate.toLocal();
          return Dismissible(
            key: ValueKey(task.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => _deleteTask(task),
            child: ListTile(
              onTap: () => _openEditScreen(task),
              leading: Checkbox(
                value: task.isDone,
                onChanged: (_) => _toggleDone(task),
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text(
                overdue
                    ? '${task.subject}  •  OVERDUE (${due.day}/${due.month})'
                    : '${task.subject}  •  Due ${due.day}/${due.month}',
                style: TextStyle(color: overdue ? Colors.red : null),
              ),
              trailing: Icon(Icons.flag, color: _priorityColor(task.priority)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
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
            FilledButton(onPressed: _loadTasks, child: const Text('Try again')),
          ],
        ),
      );
    }
    return Column(
      children: [
        _buildFilters(),
        Expanded(child: _buildList()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Studyfy'),
        actions: [
          IconButton(
            tooltip: 'Test notification',
            icon: const Icon(Icons.notifications_active),
            onPressed: _notifications.showTest,
          ),
          IconButton(
            tooltip: 'Stats',
            icon: const Icon(Icons.bar_chart),
            onPressed: _openStats,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddScreen,
        child: const Icon(Icons.add),
      ),
    );
  }
}