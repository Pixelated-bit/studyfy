class Task {
  final int? id;
  final String title;
  final String subject;
  final DateTime dueDate;
  final int priority; // 1 = low, 2 = medium, 3 = high
  final bool isDone;

  const Task({
    this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    this.priority = 2,
    this.isDone = false,
  });

  // Makes a copy of the task with some values changed
  Task copyWith({
    int? id,
    String? title,
    String? subject,
    DateTime? dueDate,
    int? priority,
    bool? isDone,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
    );
  }

  // Turns the task into a Map (needed to send it to the server)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'dueDate': dueDate.toUtc().toIso8601String(),
      'priority': priority,
      'isDone': isDone,
    };
  }

  // Builds a task from a Map (when data comes back from the server)
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int?,
      title: json['title'] as String,
      subject: json['subject'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      priority: json['priority'] as int,
      isDone: json['isDone'] as bool,
    );
  }
}