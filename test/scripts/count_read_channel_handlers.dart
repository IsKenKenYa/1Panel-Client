import 'dart:io';

/// 读通道规模与口径核对脚本。
///
/// 三个计数口径分别说明，避免人工估算：
/// - 门面声明：`NativeChannelReadHandlers` 里全部 static 成员（含非 dispatch 的
///   `bindContainerLogChannel`）
/// - dispatch 通道：`NativeChannelManager` 中转发到读门面的 case 数量
/// - 实现方法：各实现文件里的 static 方法数量之和
///
/// 用法：`dart run test/scripts/count_read_channel_handlers.dart`
void main() {
  final facade = File('lib/core/channel/native_channel_read_handlers.dart');
  final manager = File('lib/core/channel/native_channel_manager.dart');
  final channelDir = Directory('lib/core/channel');

  final facadeDecls = _countStaticMembers(facade.readAsStringSync());
  final dispatchCases =
      _count(manager.readAsStringSync(), 'return NativeChannelReadHandlers.');

  final implementationFiles = channelDir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.contains('native_channel_read_'))
      .where((file) => !file.path.contains('native_channel_read_handlers'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  var implementationTotal = 0;
  final perFile = <String>[];
  for (final file in implementationFiles) {
    final source = file.readAsStringSync();
    final count = _countStaticMembers(source, includePrivate: false);
    implementationTotal += count;
    perFile.add(
      '${_relative(file.path)}\t方法 $count\t逻辑行 ${_logicalLines(source)}',
    );
  }

  stdout.writeln('门面声明\t$facadeDecls');
  stdout.writeln('dispatch 通道\t$dispatchCases');
  stdout.writeln('非 dispatch 注入方法\t${facadeDecls - dispatchCases}');
  stdout.writeln('实现方法合计\t$implementationTotal');
  stdout.writeln('---');
  stdout.writeln(
    '口径说明：门面声明 = dispatch 通道 + 非 dispatch 注入方法'
    '（`bindContainerLogChannel` 由 init 注入通道，不参与方法派发）',
  );
  for (final line in perFile) {
    stdout.writeln(line);
  }
  final maxLines = perFile
      .map((line) => int.parse(line.split('逻辑行 ').last))
      .reduce((a, b) => a > b ? a : b);
  stdout.writeln('---');
  stdout.writeln('单文件最大逻辑行\t$maxLines');
}

/// 统计 `static` 成员声明数。
///
/// 按行首两空格的 `static` 前缀计数；`includePrivate` 为 false 时跳过
/// 以下划线开头的方法名，得到对外方法数。
int _countStaticMembers(String source, {bool includePrivate = true}) {
  var total = 0;
  for (final line in source.split('\n')) {
    final trimmed = line.trimLeft();
    if (!trimmed.startsWith('static ')) continue;
    if (line.length - trimmed.length != 2) continue;
    if (!includePrivate) {
      final name = trimmed
          .substring('static '.length)
          .replaceFirst(RegExp(r'^[A-Za-z0-9<>,? ]+ '), '');
      if (name.startsWith('_')) continue;
    }
    total += 1;
  }
  return total;
}

int _count(String text, String needle) =>
    RegExp(RegExp.escape(needle)).allMatches(text).length;

/// 逻辑行：非空且非纯注释行。
int _logicalLines(String text) => text
    .split('\n')
    .where((line) => line.trim().isNotEmpty)
    .where((line) => !line.trim().startsWith('//'))
    .length;

String _relative(String path) =>
    path.replaceFirst('${Directory.current.path}/', '');