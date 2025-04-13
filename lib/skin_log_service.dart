import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SkinLogService {
  static const String _key = 'skin_logs';

  // Save today's analysis
  static Future<void> saveDailyLog(Map<String, dynamic> analysis) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = await getLogs();

    logs.add({
      'timestamp': DateTime.now().toIso8601String(),
      'data': analysis,
    });

    await prefs.setString(_key, jsonEncode(logs));
  }

  // Retrieve all stored logs
  static Future<List<Map<String, dynamic>>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null) return [];

    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.cast<Map<String, dynamic>>();
  }

  // Get logs from the last 14 days
  static Future<List<Map<String, dynamic>>> getRecentLogs() async {
    final allLogs = await getLogs();
    final cutoff = DateTime.now().subtract(const Duration(days: 14));
    return allLogs.where((log) {
      final time = DateTime.parse(log['timestamp']);
      return time.isAfter(cutoff);
    }).toList();
  }
}
