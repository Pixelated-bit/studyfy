import 'package:flutter/material.dart';
import '../models/task.dart';

class AddTaskScreen extends StatefulWidget {
  // If a task is passed in, the screen is in "edit" mode.
  final Task? task;

  const AddTaskScreen({super.key, this.task});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _subjectController;
  late DateTime _dueDate; // holds both the date AND the time
  late int _priority;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _subjectController = TextEditingController(text: task?.subject ?? '');
    final now = DateTime.now();
    // New sessions start as tomorrow at 6:00 pm
    _dueDate = task?.dueDate.toLocal() ??
        DateTime(now.year, now.month, now.day + 1, 18, 0);
    _priority = task?.priority ?? 2;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final earliest = _dueDate.isBefore(now) ? _dueDate : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(earliest.year, earliest.month, earliest.day),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        // Keep the time that was already chosen
        _dueDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _dueDate.hour,
          _dueDate.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _dueDate.hour, minute: _dueDate.minute),
    );
    if (picked != null) {
      setState(() {
        // Keep the date that was already chosen
        _dueDate = DateTime(
          _dueDate.year,
          _dueDate.month,
          _dueDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        id: widget.task?.id,
        title: _titleController.text.trim(),
        subject: _subjectController.text.trim(),
        dueDate: _dueDate,
        priority: _priority,
        isDone: widget.task?.isDone ?? false,
      );
      Navigator.pop(context, task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeText = TimeOfDay.fromDateTime(_dueDate).format(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Session' : 'Plan a Study Session'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'What will you study?',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject (e.g. Maths)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Enter a subject' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text('${_dueDate.day}/${_dueDate.month}/${_dueDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start time (you get a reminder then)'),
                subtitle: Text(timeText),
                trailing: const Icon(Icons.access_time),
                onTap: _pickTime,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Low')),
                  DropdownMenuItem(value: 2, child: Text('Medium')),
                  DropdownMenuItem(value: 3, child: Text('High')),
                ],
                onChanged: (value) => setState(() => _priority = value!),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                child: Text(_isEditing ? 'Update Session' : 'Save Session'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}