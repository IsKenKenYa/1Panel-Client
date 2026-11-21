import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:onepanel_client/features/server/server_repository.dart';

import '../services/logger/logger_service.dart';
import 'api_config.dart';

/// 持有调试语义句柄，避免被回收导致语义树关闭。
SemanticsHandle? _debugSemanticsHandle;

/// 调试走查：构建参数 `ONEPANEL_FORCE_SEMANTICS=true` 时强制开启语义树，
/// 供 uiautomator 读取 Flutter 界面元素（仅调试构建生效）。
void applyDebugSemanticsIfRequested() {
  if (!kDebugMode) return;
  const requested = bool.fromEnvironment('ONEPANEL_FORCE_SEMANTICS');
  if (!requested) return;
  _debugSemanticsHandle ??= WidgetsBinding.instance.ensureSemantics();
  appLogger.i('debug semantics enabled for UI automation');
}

/// 调试走查用的服务器种子配置入口。
///
/// 桌面临时环境变量（`ONEPANEL_SEED_SERVER_URL` / `ONEPANEL_SEED_API_KEY`）
/// 在启动时直接读取；iOS 由原生壳把同样的环境变量经通道转发给
/// [applySeedConfig]。
Future<void> applyDebugSeedConfig() async {
  if (!kDebugMode || kIsWeb) return;
  const defineUrl = String.fromEnvironment('ONEPANEL_SEED_SERVER_URL');
  const defineKey = String.fromEnvironment('ONEPANEL_SEED_API_KEY');
  const defineName = String.fromEnvironment('ONEPANEL_SEED_SERVER_NAME');
  final url = Platform.environment['ONEPANEL_SEED_SERVER_URL'] ??
      (defineUrl.isEmpty ? null : defineUrl);
  final apiKey = Platform.environment['ONEPANEL_SEED_API_KEY'] ??
      (defineKey.isEmpty ? null : defineKey);
  if (url == null || url.isEmpty || apiKey == null || apiKey.isEmpty) {
    appLogger.d('seed config skipped: no environment seed values');
    return;
  }
  final envName = Platform.environment['ONEPANEL_SEED_SERVER_NAME'];
  await applySeedConfig(
    url: url,
    apiKey: apiKey,
    name: envName ?? (defineName.isEmpty ? null : defineName),
  );
}

/// 将种子服务器写入正式配置存储并设为当前服务器。
///
/// 相同地址的既有配置沿用其标识与名称，不会产生重复条目。
Future<void> applySeedConfig({
  required String url,
  required String apiKey,
  String? name,
}) async {
  final seedName = name == null || name.isEmpty ? 'Seed Server' : name;
  final configs = await ApiConfigManager.getServerMetadata();
  final metadata = configs.where((config) =>
      config.panelType == ApiConfig.onePanelType && config.url == url).firstOrNull;
  // 种子注入的目的就是用传入的凭据覆盖现有配置，因此凭据读不出来
  // 也要继续，才能修复历史上损坏的条目。
  final matched = metadata == null
      ? null
      : await ApiConfigManager.getConfigAllowMissingCredential(metadata.id);
  final config = ApiConfig(
    id: matched?.id ?? 'server_seed_${DateTime.now().millisecondsSinceEpoch}',
    name: matched?.name ?? seedName,
    panelType: ApiConfig.onePanelType,
    tokenValidity: matched?.tokenValidity ?? 0,
    allowInsecureTls: matched?.allowInsecureTls ?? false,
    isDefault: matched?.isDefault ?? false,
    lastUsed: matched?.lastUsed,
    additionalCredentials: matched?.additionalCredentials ?? const {},
    url: url,
    apiKey: apiKey,
  );
  const repository = ServerRepository();
  await repository.saveConfig(config);
  await repository.setCurrent(config.id);
  appLogger.i('seed config applied');
}
