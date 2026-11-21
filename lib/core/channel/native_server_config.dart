import '../config/api_config.dart';

/// 原生界面使用配置版本检测编辑冲突。
Map<String, Object?> describeNativeServer(
  ApiConfig config, {
  required bool isCurrent,
}) =>
    {
      'id': config.id,
      'revision': config.revision,
      'name': config.name,
      'url': config.url,
      'panelType': config.panelType,
      'isCurrent': isCurrent,
    };

ApiConfig readNativeServerConfig(
  Map<Object?, Object?> fields, {
  required String id,
  ApiConfig? existing,
}) {
  if (existing != null) {
    final revision = fields['revision'];
    if (revision is! String || revision.isEmpty || revision != existing.revision) {
      throw StateError('服务器配置已更改，请重新打开编辑页面');
    }
  }
  final type = fields['panelType'] as String? ?? existing?.panelType;
  if (type == null || type.isEmpty) {
    throw ArgumentError('panelType is required');
  }
  if (existing != null && type != existing.panelType) {
    throw ArgumentError('已有连接不能更改面板类型');
  }
  final key = fields['apiKey'] as String?;
  final fieldsValue = fields['additionalCredentials'] as Map?;
  final url = (fields['url'] as String).trim();
  final sameAddress = existing != null && url == existing.url;
  if (!sameAddress && (key == null || key.isEmpty) &&
      (type == ApiConfig.onePanelType || (existing?.apiKey.isNotEmpty ?? false))) {
    throw ArgumentError('请为该服务器地址输入 API Key');
  }
  if (!sameAddress && fieldsValue == null &&
      (existing?.additionalCredentials.isNotEmpty ?? false)) {
    throw ArgumentError('请为新地址提供面板凭据');
  }
  return ApiConfig(
    id: id,
    panelType: type,
    name: fields['name'] as String,
    url: url,
    apiKey: key == null || key.isEmpty ? existing?.apiKey ?? '' : key,
    additionalCredentials: fieldsValue == null
        ? existing?.additionalCredentials ?? const {}
        : Map<String, String>.from(fieldsValue),
    tokenValidity: existing?.tokenValidity ?? 0,
    allowInsecureTls: existing?.allowInsecureTls ?? false,
    isDefault: existing?.isDefault ?? false,
    lastUsed: existing?.lastUsed,
  );
}
