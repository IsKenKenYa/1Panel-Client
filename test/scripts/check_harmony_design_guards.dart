import 'dart:io';

const String nativeUiRoot = 'ohos/entry/src/main/ets/native_ui';
const String nativeBridgePath =
    'ohos/entry/src/main/ets/native_ui/HarmonyNativeBridge.ets';
const String nativeShellPath =
    'ohos/entry/src/main/ets/native_ui/HarmonyNativeShell.ets';

void main() {
  final failures = <String>[];
  final nativeUiDirectory = Directory(nativeUiRoot);
  if (!nativeUiDirectory.existsSync()) {
    stderr.writeln('缺少 HarmonyOS 原生 UI 目录: $nativeUiRoot');
    exitCode = 1;
    return;
  }

  final files =
      nativeUiDirectory
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((file) => file.path.endsWith('.ets'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final lines = file.readAsLinesSync();
    _checkCall(
      failures,
      file.path,
      lines,
      '.bindMenu(',
      'systemMaterial: menuMaterial',
      lookAhead: 4,
    );
    _checkCall(
      failures,
      file.path,
      lines,
      '.bindContextMenu(',
      'systemMaterial: menuMaterial',
      lookAhead: 4,
    );
    _checkCall(
      failures,
      file.path,
      lines,
      '.bindSheet(',
      'systemMaterial: sheetMaterial',
      lookAhead: 10,
    );
    _checkSplitPlaceholder(failures, file.path, lines);
  }

  _checkMaterialDefinition(
    failures,
    nativeBridgePath,
    'sheetMaterial',
    'uiMaterial.ImmersiveStyle.ULTRA_THICK',
  );
  _checkMaterialDefinition(
    failures,
    nativeBridgePath,
    'menuMaterial',
    'uiMaterial.ImmersiveStyle.THICK',
  );
  _checkMaterialDefinition(
    failures,
    nativeBridgePath,
    'titleBarMaterial',
    'uiMaterial.ImmersiveStyle.ULTRA_THIN',
  );
  _checkMaterialDefinition(
    failures,
    nativeShellPath,
    'navigationMaterial',
    'uiMaterial.ImmersiveStyle.THIN',
  );

  if (failures.isNotEmpty) {
    for (final failure in failures) {
      stderr.writeln(failure);
    }
    stderr.writeln('HarmonyOS 设计规范检查失败: ${failures.length} 项');
    exitCode = 1;
    return;
  }

  stdout.writeln('HarmonyOS 设计规范检查通过: ${files.length} 个 ArkTS 文件');
}

void _checkCall(
  List<String> failures,
  String path,
  List<String> lines,
  String call,
  String requiredText, {
  required int lookAhead,
}) {
  for (var index = 0; index < lines.length; index++) {
    if (!lines[index].contains(call)) {
      continue;
    }
    final endIndex = index + lookAhead < lines.length
        ? index + lookAhead
        : lines.length;
    final block = lines.sublist(index, endIndex).join('\n');
    if (!block.contains(requiredText)) {
      failures.add('$path:${index + 1} 缺少 $requiredText');
    }
  }
}

void _checkSplitPlaceholder(
  List<String> failures,
  String path,
  List<String> lines,
) {
  for (var index = 0; index < lines.length; index++) {
    if (!lines[index].contains('.mode(NavigationMode.Auto)')) {
      continue;
    }
    final endIndex = index + 12 < lines.length ? index + 12 : lines.length;
    final block = lines.sublist(index, endIndex).join('\n');
    if (!block.contains('.splitPlaceholder(')) {
      failures.add('$path:${index + 1} 分栏模式缺少 .splitPlaceholder(');
    }
    return;
  }
}

void _checkMaterialDefinition(
  List<String> failures,
  String path,
  String name,
  String requiredStyle,
) {
  final file = File(path);
  if (!file.existsSync()) {
    failures.add('缺少文件: $path');
    return;
  }
  final content = file.readAsStringSync();
  final declaration = RegExp(
    '$name[\\s\\S]*?$requiredStyle',
    dotAll: true,
  );
  if (!declaration.hasMatch(content)) {
    failures.add('$path $name 未使用 $requiredStyle');
  }
}
