import 'package:onepanel_client/data/models/cronjob_form_request_models.dart';

/// 定时任务编辑请求构造。
///
/// 服务端 `/cronjobs/update` 用请求字段整体覆盖数据库列，未提交的字段会
/// 被写成空值。原生编辑表单只收集名称、表达式与脚本文本，所以其余字段
/// 必须从原始记录回填，否则 nginx 日志切割、清理、快照等任务会丢失站点、
/// 排除规则、保留份数与告警配置。
CronjobOperateRequest buildCronjobOperateRequest(
  Map<dynamic, dynamic> arguments, {
  int? id,
  Map<String, dynamic> existing = const <String, dynamic>{},
}) {
  final name = (arguments['name'] as String? ?? '').trim();
  final spec = (arguments['spec'] as String? ?? '').trim();
  if (name.isEmpty || spec.isEmpty) {
    throw ArgumentError('name and spec are required');
  }
  final type =
      (arguments['type'] as String? ?? existing['type'] as String? ?? '').trim();
  if (type.isEmpty) {
    throw ArgumentError('type is required');
  }

  String pick(String key, String fallback) {
    final value = arguments[key];
    if (value is String && value.trim().isNotEmpty) return value;
    return fallback;
  }

  int pickInt(String key, int fallback) {
    final parsed = int.tryParse('${arguments[key] ?? ''}');
    return parsed ?? fallback;
  }

  bool pickBool(String key, bool fallback) {
    final value = arguments[key];
    return value is bool ? value : fallback;
  }

  final snapshotRule = arguments['snapshotRule'];
  return CronjobOperateRequest(
    id: id,
    name: name,
    groupID: pickInt('groupID', (existing['groupID'] as int?) ?? 0),
    type: type,
    specCustom: pickBool('specCustom', (existing['specCustom'] as bool?) ?? true),
    spec: spec,
    executor: pick('executor', (existing['executor'] as String?) ?? ''),
    scriptMode: pick('scriptMode', (existing['scriptMode'] as String?) ?? 'input'),
    script: pick('script', (existing['script'] as String?) ?? ''),
    command: pick('command', (existing['command'] as String?) ?? ''),
    containerName:
        pick('containerName', (existing['containerName'] as String?) ?? ''),
    user: pick('user', (existing['user'] as String?) ?? ''),
    scriptID: pickInt('scriptID', (existing['scriptID'] as int?) ?? 0),
    appID: pick('appID', (existing['appID'] as String?) ?? ''),
    website: pick('website', (existing['website'] as String?) ?? ''),
    exclusionRules:
        pick('exclusionRules', (existing['exclusionRules'] as String?) ?? ''),
    dbType: pick('dbType', (existing['dbType'] as String?) ?? ''),
    dbName: pick('dbName', (existing['dbName'] as String?) ?? ''),
    url: pick('url', (existing['url'] as String?) ?? ''),
    isDir: pickBool('isDir', (existing['isDir'] as bool?) ?? false),
    sourceDir: pick('sourceDir', (existing['sourceDir'] as String?) ?? ''),
    snapshotRule: snapshotRule is Map
        ? CronjobSnapshotRule.fromJson(
            snapshotRule.cast<String, dynamic>(),
          )
        : CronjobSnapshotRule.fromJson(
            (existing['snapshotRule'] as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{},
          ),
    sourceAccountIDs:
        pick('sourceAccountIDs', (existing['sourceAccountIDs'] as String?) ?? ''),
    downloadAccountID:
        pickInt('downloadAccountID', (existing['downloadAccountID'] as int?) ?? 0),
    retainCopies: pickInt('retainCopies', (existing['retainCopies'] as int?) ?? 1),
    retryTimes: pickInt('retryTimes', (existing['retryTimes'] as int?) ?? 0),
    timeout: pickInt('timeout', (existing['timeout'] as int?) ?? 3600),
    ignoreErr: pickBool('ignoreErr', (existing['ignoreErr'] as bool?) ?? false),
    secret: pick('secret', (existing['secret'] as String?) ?? ''),
    args: pick('args', (existing['args'] as String?) ?? ''),
    alertCount: pickInt('alertCount', (existing['alertCount'] as int?) ?? 0),
    alertTitle: pick('alertTitle', (existing['alertTitle'] as String?) ?? ''),
    alertMethod: pick('alertMethod', (existing['alertMethod'] as String?) ?? ''),
    scopes:
        (existing['scopes'] as List?)?.map((entry) => '$entry').toList() ??
            const <String>[],
  );
}