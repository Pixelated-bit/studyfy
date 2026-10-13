import 'package:flutter/material.dart';
import '../data/study_tips.dart';

class InsightsScreen extends StatelessWidget {
  final String subject;

  const InsightsScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final guide = guideFor(subject);
    final general = guideFor('');
    return Scaffold(
      appBar: AppBar(title: Text('How to study $subject')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            guide.subject,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(guide.summary),
          const SizedBox(height: 16),
          for (var i = 0; i < guide.methods.length; i++)
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(guide.methods[i]),
              ),
            ),
          if (guide.subject != general.subject) ...[
            const SizedBox(height: 16),
            Text(
              'For any subject',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final tip in general.methods.take(3))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline),
                title: Text(tip),
              ),
          ],
        ],
      ),
    );
  }
}