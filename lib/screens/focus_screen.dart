import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FocusScreen extends StatefulWidget {
  final String subject;

  const FocusScreen({super.key, required this.subject});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  final ApiService _api = ApiService();
  int _minutes = 25;
  late int _remaining = _minutes * 60; // seconds left
  Timer? _timer;
  DateTime? _endTime;
  bool _running = false;

  bool get _notStarted => _remaining == _minutes * 60 && !_running;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _chooseLength(int minutes) {
    setState(() {
      _minutes = minutes;
      _remaining = minutes * 60;
    });
  }

  void _start() {
    _endTime = DateTime.now().add(Duration(seconds: _remaining));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = _endTime!.difference(DateTime.now()).inSeconds;
      if (left <= 0) {
        _complete();
      } else {
        setState(() => _remaining = left);
      }
    });
    setState(() => _running = true);
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  Future<void> _save(int minutes) async {
    if (minutes < 1) return;
    try {
      await _api.addLog(widget.subject, minutes);
    } catch (e) {
      _showMessage('Could not save your study time');
    }
  }

  Future<void> _complete() async {
    _timer?.cancel();
    setState(() {
      _remaining = 0;
      _running = false;
    });
    await _save(_minutes);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Well done!'),
        content: Text('You studied ${widget.subject} for $_minutes minutes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  // Stop early and save the full minutes studied so far
  Future<void> _finishEarly() async {
    _timer?.cancel();
    final studied = (_minutes * 60 - _remaining) ~/ 60;
    await _save(studied);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _clock() {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final total = _minutes * 60;
    final progress = total == 0 ? 0.0 : 1 - (_remaining / total);
    return Scaffold(
      appBar: AppBar(title: Text('Focus: ${widget.subject}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_notStarted)
              Wrap(
                spacing: 8,
                children: [
                  for (final m in [15, 25, 45])
                    ChoiceChip(
                      label: Text('$m min'),
                      selected: _minutes == m,
                      onSelected: (_) => _chooseLength(m),
                    ),
                ],
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                    ),
                  ),
                  Text(
                    _clock(),
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Put your phone down and focus on one thing.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _running ? _pause : _start,
              icon: Icon(_running ? Icons.pause : Icons.play_arrow),
              label: Text(_running ? 'Pause' : (_notStarted ? 'Start' : 'Resume')),
            ),
            const SizedBox(height: 12),
            if (!_notStarted)
              OutlinedButton(
                onPressed: _finishEarly,
                child: const Text('Finish and save'),
              ),
          ],
        ),
      ),
    );
  }
}