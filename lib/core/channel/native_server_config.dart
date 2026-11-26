import '../../features/server/server_connection_service.dart';
import '../../features/shell/controllers/pinned_modules_controller.dart';
import '../../features/shell/models/client_module.dart';
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
  // 同地址留空表示沿用旧凭据；旧凭据不存在时没有可沿用的内容，必须拒绝，
  // 否则保存会写入空密钥并报告成功。
  if (sameAddress && (key == null || key.isEmpty) &&
      existing.apiKey.isEmpty &&
      (type == ApiConfig.onePanelType)) {
    throw ArgumentError('Enter an API key for this server');
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

Future<ApiConfig> readNativeServerForEdit(String id) async {
  try {
    return await ApiConfigManager.getConfig(id);
  } on MissingCredentialException {
    return (await ApiConfigManager.getServerMetadata())
        .firstWhere((config) => config.id == id);
  }
}

Future<Map<String, Object?>> testHarmonyServerConnection(
  Map<Object?, Object?> fields,
) async {
  final id = fields['id'] as String?;
  final existing = id == null ? null : await readNativeServerForEdit(id);
  final config = readNativeServerConfig(
    fields,
    id: id ?? '',
    existing: existing,
  );
  final result = await ServerConnectionService().testConfig(config);
  return {
    'success': result.success,
    'error': result.errorMessage,
    'operatingSystem': result.operatingSystem,
    'responseTimeMs': result.responseTime?.inMilliseconds,
  };
}

Future<List<String>> getHarmonyPinnedModules(
  PinnedModulesController controller,
) async {
  if (!controller.isLoaded) await controller.load();
  return controller.pins.map((module) => module.storageId).toList();
}

Future<List<String>> setHarmonyPinnedModules(
  PinnedModulesController controller,
  Map<Object?, Object?>? fields,
) async {
  if (!controller.isLoaded) await controller.load();
  if (fields == null) {
    await controller.reset();
  } else {
    final primary = clientModuleFromId(fields['primary'] as String);
    final secondary = clientModuleFromId(fields['secondary'] as String);
    if (primary == null ||
        !primary.pinnable ||
        secondary == null ||
        !secondary.pinnable ||
        primary == secondary) {
      throw ArgumentError('Two different pinnable modules are required');
    }
    await controller.setPin(0, primary);
    await controller.setPin(1, secondary);
  }
  return controller.pins.map((module) => module.storageId).toList();
}
