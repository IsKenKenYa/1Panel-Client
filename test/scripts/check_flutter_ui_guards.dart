import 'dart:io';

const List<String> _uiRoots = <String>['lib/features', 'lib/pages'];

const Set<String> _legacyRawDialogFiles = <String>{
  'lib/pages/settings/settings_page.dart',
};

const Set<String> _legacyRawScaffoldMessengerFiles = <String>{
  'lib/features/files/files_page/files_page_async_actions_part.dart',
};

const Set<String> _legacyDirectApiImportFiles = <String>{
  'lib/features/ai/pages/ai_agent_plugins_page.dart',
  'lib/features/containers/pages/container_files_page.dart',
  'lib/features/containers/pages/container_inspect_page.dart',
  'lib/features/containers/pages/container_maintenance_page.dart',
  'lib/features/containers/pages/docker_config_page.dart',
  'lib/features/containers/pages/image_operations_page.dart',
  'lib/features/databases/pages/database_mongodb_page.dart',
  'lib/features/databases/pages/database_mysql_variables_page.dart',
  'lib/features/databases/pages/database_pg_privileges_page.dart',
  'lib/features/databases/pages/database_redis_persistence_page.dart',
  'lib/features/databases/pages/database_remote_config_page.dart',
  'lib/features/databases/pages/database_slow_log_page.dart',
  'lib/features/files/file_history_page.dart',
  'lib/features/files/file_permission_page.dart',
  'lib/features/files/recycle_bin_status_page.dart',
  'lib/features/host_assets/pages/host_diagnostics_page.dart',
  'lib/features/toolbox/pages/toolbox_supervisor_page.dart',
  'lib/features/websites/pages/website_auth_basic_page.dart',
  'lib/features/websites/pages/website_load_balancer_page.dart',
};

final RegExp _rawDialogPattern = RegExp(
  r'\b(?:showDialog|showModalBottomSheet)\s*[<(]|\bAlertDialog\s*[.(]',
);
final RegExp _rawScaffoldMessengerPattern = RegExp(r'\bScaffoldMessenger\.of\(');
final RegExp _directApiImportPattern = RegExp(r'''import\s+['"].*api/v2/''');
final RegExp _uiPresentationFilePattern = RegExp(
  r'(_page|_widget|_dialog|_sheet|_form|_part)\.dart$',
);

void main() {
  final failures = <String>[];
  final existingFiles = <String>{};

  for (final root in _uiRoots) {
    final directory = Directory(root);
    if (!directory.existsSync()) continue;
    final files =
        directory
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .where((file) => !file.path.endsWith('.g.dart'))
            .where((file) => !file.path.endsWith('.freezed.dart'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final path = file.path.replaceAll('\\', '/');
      existingFiles.add(path);
      final lines = file.readAsLinesSync();
      final codeLoc = _countCodeLines(lines);
      if (codeLoc > 1000) {
        failures.add('$path 超出 1000 LOC 上限 (当前 $codeLoc 行)');
      }

      if (!_legacyRawDialogFiles.contains(path)) {
        for (var i = 0; i < lines.length; i++) {
          if (_rawDialogPattern.hasMatch(lines[i])) {
            failures.add(
              '$path:${i + 1} 禁止直接调用 showDialog / showModalBottomSheet / AlertDialog，'
              '请复用 AppFormDialog / showAppTextInputDialog / showAdaptiveFormPanel / ConfirmActionSheetWidget',
            );
          }
        }
      }

      if (!_legacyRawScaffoldMessengerFiles.contains(path)) {
        for (var i = 0; i < lines.length; i++) {
          if (_rawScaffoldMessengerPattern.hasMatch(lines[i])) {
            failures.add(
              '$path:${i + 1} 禁止直接调用 ScaffoldMessenger.of，请使用 SnackBarUtils',
            );
          }
        }
      }

      if (_uiPresentationFilePattern.hasMatch(path) &&
          !_legacyDirectApiImportFiles.contains(path)) {
        for (var i = 0; i < lines.length; i++) {
          if (_directApiImportPattern.hasMatch(lines[i])) {
            failures.add('$path:${i + 1} UI 层禁止直接导入 api/v2/，请通过 Service/Repository 访问');
          }
        }
      }
    }
  }

  for (final file in _legacyRawDialogFiles) {
    if (!existingFiles.contains(file)) {
      failures.add('基线中已不存在的文件请移除: $file');
    } else if (!_fileMatches(file, _rawDialogPattern)) {
      failures.add('已完成整改的文件请从 _legacyRawDialogFiles 移除以锁定成果: $file');
    }
  }

  if (failures.isNotEmpty) {
    for (final failure in failures) {
      stderr.writeln(failure);
    }
    stderr.writeln('Flutter UI 复用与分层守卫检查失败: ${failures.length} 项');
    exitCode = 1;
    return;
  }

  stdout.writeln('Flutter UI 复用与分层守卫检查通过: ${existingFiles.length} 个文件');
}

bool _fileMatches(String path, RegExp pattern) {
  final lines = File(path).readAsLinesSync();
  return lines.any(pattern.hasMatch);
}

int _countCodeLines(List<String> lines) {
  var count = 0;
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('//')) continue;
    count++;
  }
  return count;
}
