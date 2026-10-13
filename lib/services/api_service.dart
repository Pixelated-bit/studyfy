import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class ApiService {
  // With "adb reverse tcp:3000 tcp:3000", localhost works on a USB phone.
  static const String baseUrl = 'http://localhost:3000';

  static const Duration _timeout = Duration(seconds: 8);

  Future<List<Task>> getTasks() async {
    final response =
    await http.get(Uri.parse('$baseUrl/tasks')).timeout(_timeout);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Task.fromJson(json)).toList();
    }
    throw Exception('Failed to load tasks');
  }

  Future<Task> addTask(Task task) async {
    final response = await http
        .post(
      Uri.parse('$baseUrl/tasks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(task.toJson()),
    )
        .timeout(_timeout);
    if (response.statusCode == 201) {
      return Task.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to add task');
  }

  Future<Task> updateTask(Task task) async {
    final response = await http
        .put(
      Uri.parse('$baseUrl/tasks/${task.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(task.toJson()),
    )
        .timeout(_timeout);
    if (response.statusCode == 200) {
      return Task.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update task');
  }

  Future<void> deleteTask(int id) async {
    final response =
    await http.delete(Uri.parse('$baseUrl/tasks/$id')).timeout(_timeout);
    if (response.statusCode != 204) {
      throw Exception('Failed to delete task');
    }
  }

  // Saves a finished study block
  Future<void> addLog(String subject, int minutes) async {
    final response = await http
        .post(
      Uri.parse('$baseUrl/logs'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'subject': subject, 'minutes': minutes}),
    )
        .timeout(_timeout);
    if (response.statusCode != 201) {
      throw Exception('Failed to save study log');
    }
  }

  // Reads all study blocks (newest first)
  Future<List<Map<String, dynamic>>> getLogs() async {
    final response =
    await http.get(Uri.parse('$baseUrl/logs')).timeout(_timeout);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load study logs');
  }
}