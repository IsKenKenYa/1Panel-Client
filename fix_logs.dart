import 'dart:io';

void main() {
  final file = File('lib/core/channel/native_channel_read_handlers.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll(
    "appLogger.e('Failed to get containers for native: $e');",
    "if (e.toString().contains('No API config available')) {\n        appLogger.i('getContainers skipped: No active server configured.');\n      } else {\n        appLogger.e('Failed to get containers for native: $e');\n      }"
  );
  
  content = content.replaceAll(
    "appLogger.e('Failed to get firewall rules for native: $e');",
    "if (e.toString().contains('No API config available')) {\n        appLogger.i('getFirewall rules skipped: No active server configured.');\n      } else {\n        appLogger.e('Failed to get firewall rules for native: $e');\n      }"
  );

  content = content.replaceAll(
    "appLogger.e('Failed to get cronjobs for native: $e');",
    "if (e.toString().contains('No API config available')) {\n        appLogger.i('getCronjobs skipped: No active server configured.');\n      } else {\n        appLogger.e('Failed to get cronjobs for native: $e');\n      }"
  );

  content = content.replaceAll(
    "appLogger.e('Failed to get backups for native: $e');",
    "if (e.toString().contains('No API config available')) {\n        appLogger.i('getBackups skipped: No active server configured.');\n      } else {\n        appLogger.e('Failed to get backups for native: $e');\n      }"
  );

  content = content.replaceAll(
    "appLogger.e('Failed to get AI models for native: $e');",
    "if (e.toString().contains('No API config available')) {\n        appLogger.i('getAI models skipped: No active server configured.');\n      } else {\n        appLogger.e('Failed to get AI models for native: $e');\n      }"
  );
  
  file.writeAsStringSync(content);
}
