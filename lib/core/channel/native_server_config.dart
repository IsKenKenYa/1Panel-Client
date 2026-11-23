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
      'tokenValidity': config.tokenValidity,
      'allowInsecureTls': config.allowInsecureTls,
    };

ApiConfig readNativeServerConfig(
  Map<Object?, Object?> fields, {
  required String id,
  ApiConfig? existing,
}) {
  if (existing != null) {
    final revision = fields['revision'];
    if (revision is! String || revision.isEmpty || revision != existing.revision) {
      throw StateError('Server configuration changed; reopen the editor');
    }
  }
  final type = fields['panelType'] as String? ?? existing?.panelType;
  if (type == null || type.isEmpty) {
    throw ArgumentError('panelType is required');
  }
  if (existing != null && type != existing.panelType) {
    throw ArgumentError('Panel type cannot change for an existing connection');
  }
  final key = fields['apiKey'] as String?;
  final fieldsValue = fields['additionalCredentials'] as Map?;
  final url = (fields['url'] as String).trim();
  final sameAddress = existing != null && url == existing.url;
  if (!sameAddress && (key == null || key.isEmpty) &&
      (type == ApiConfig.onePanelType || (existing?.apiKey.isNotEmpty ?? false))) {
    throw ArgumentError('Enter an API key for this server address');
  }
  if (!sameAddress && fieldsValue == null &&
      (existing?.additionalCredentials.isNotEmpty ?? false)) {
    throw ArgumentError('Provide credentials for the new address');
  }
  final tokenValidity = int.tryParse('${fields['tokenValidity'] ?? ''}');
  if (tokenValidity != null && (tokenValidity < 0 || tokenValidity > 9999)) {
    throw ArgumentError.value(tokenValidity, 'tokenValidity');
  }
  final insecure = fields['allowInsecureTls'];
  if (insecure != null && insecure is! bool) {
    throw ArgumentError.value(insecure, 'allowInsecureTls');
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
    tokenValidity: tokenValidity ?? existing?.tokenValidity ?? 0,
    allowInsecureTls:
        insecure as bool? ?? existing?.allowInsecureTls ?? false,
    isDefault: existing?.isDefault ?? false,
    lastUsed: existing?.lastUsed,
  );
}
