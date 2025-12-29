import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DebugLogger {
  static Future<void> log(String message) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/debug_log.txt');
    final timestamp = DateTime.now().toIso8601String();
    await file.writeAsString('[$timestamp] $message\n', mode: FileMode.append);
  }

  static Future<String> readLog() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/debug_log.txt');
    if (await file.exists()) {
      return await file.readAsString();
    }
    return "No logs yet.";
  }

  static Future<void> clearLog() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/debug_log.txt');
    if (await file.exists()) {
      await file.writeAsString('');
    }
  }
}
