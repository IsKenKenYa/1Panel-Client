import '../../data/models/openresty_models.dart';
import '../../features/openresty/providers/openresty_provider.dart';
import '../../features/security_gateway/providers/security_gateway_center_provider.dart';
import '../../shared/security_gateway/models/security_gateway_models.dart';
import '../config/api_config.dart';

class NativeChannelWebsiteSecurityHandlers {
  static OpenRestyProvider? _openResty;
  static String? _serverIdentity;

  static Future<dynamic> dispatch(String method, dynamic arguments) async {
    final args = arguments == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(arguments as Map);
    switch (method) {
      case 'getNativeOpenrestyState':
        final provider = await _openRestyProvider();
        if (args['refresh'] == true) await provider.refresh();
        return _openRestyState(provider);
      case 'performNativeOpenrestyAction':
        return _performOpenResty(args);
      case 'releaseNativeOpenrestyState':
        _openResty?.dispose();
        _openResty = null;
        _serverIdentity = null;
        return null;
      case 'getNativeSecurityGatewayState':
        return _securityGatewayState(args);
      case 'rollbackNativeSecurityGateway':
        return _securityGatewayState(args, restore: true);
      default:
        throw ArgumentError.value(method, 'method');
    }
  }

  static Future<OpenRestyProvider> _openRestyProvider() async {
    final config = await ApiConfigManager.getCurrentConfig();
    if (config == null) throw StateError('No active server configured');
    final identity = '${config.id}:${config.revision}';
    if (_openResty == null || _serverIdentity != identity) {
      _openResty?.dispose();
      _openResty = OpenRestyProvider();
      _serverIdentity = identity;
      await _openResty!.loadAll();
    }
    return _openResty!;
  }

  static Future<Map<String, dynamic>> _performOpenResty(
    Map<String, dynamic> args,
  ) async {
    final provider = await _openRestyProvider();
    bool? applied;
    switch (args['action'] as String) {
      case 'stageHttps':
        provider.stageHttpsUpdate(
          httpsEnabled: args['httpsEnabled'] as bool,
          sslRejectHandshake: args['sslRejectHandshake'] as bool,
        );
        break;
      case 'applyHttps':
        applied = await provider.applyHttpsDraft();
        break;
      case 'discardHttps':
        provider.discardHttpsDraft();
        break;
      case 'restoreHttps':
        applied = await provider.rollbackHttps();
        break;
      case 'stageModule':
        final module = provider.moduleList.firstWhere(
          (module) => module.name == args['name'],
        );
        provider.stageModuleUpdate(
          module: module,
          enable: args['enable'] as bool,
          packages: args['packages'] as String,
          params: args['params'] as String,
          script: args['script'] as String,
        );
        break;
      case 'applyModule':
        applied = await provider.applyModuleDraft();
        break;
      case 'discardModule':
        provider.discardModuleDraft();
        break;
      case 'restoreModules':
        applied = await provider.rollbackModules();
        break;
      case 'stageConfig':
        provider.stageConfigUpdate(args['content'] as String);
        break;
      case 'applyConfig':
        applied = await provider.applyConfigDraft();
        break;
      case 'discardConfig':
        provider.discardConfigDraft();
        break;
      case 'restoreConfig':
        applied = await provider.rollbackConfig();
        break;
      case 'saveSource':
        await provider.updateConfigSource(args['content'] as String);
        applied = provider.error == null;
        break;
      case 'build':
        await provider.buildOpenResty(
          mirror: args['mirror'] as String,
          taskId: args['taskId'] as String,
        );
        applied = true;
        break;
      case 'loadScope':
        await provider.loadScope(
          scope: NginxKey.values.firstWhere(
            (scope) => scope.value == args['scope'],
          ),
          websiteId: args['websiteId'] as int?,
        );
        break;
      default:
        throw ArgumentError.value(args['action'], 'action');
    }
    return {..._openRestyState(provider), 'applied': applied};
  }

  static Map<String, dynamic> _openRestyState(OpenRestyProvider provider) => {
        'error': provider.error,
        'notInstalled': provider.notInstalled,
        'running': provider.isRunning,
        'status': provider.status,
        'https': provider.https,
        'modules': provider.moduleList.map((module) => module.toJson()).toList(),
        'mirror': provider.modules?['mirror'],
        'configContent': provider.configContent,
        'lastBuildMessage': provider.lastBuildMessage,
        'scopeParams': provider.scopeParams.map((param) => param.toJson()).toList(),
        'httpsDraft': _draft(provider.httpsDraft),
        'moduleDraft': _draft(provider.moduleDraft),
        'configDraft': _draft(provider.configDraft),
        'canRestoreHttps': provider.httpsRollbackSnapshot != null,
        'canRestoreModules': provider.moduleRollbackSnapshot != null,
        'canRestoreConfig': provider.configRollbackSnapshot != null,
        'risks': provider.riskNotices.map(_risk).toList(),
      };

  static Map<String, dynamic>? _draft(ConfigDraftState<dynamic>? draft) {
    if (draft == null) return null;
    return {
      'hasChanges': draft.hasChanges,
      'diffs': draft.diffItems
          .map((item) => {
                'field': item.field,
                'label': item.label,
                'currentValue': item.currentValue,
                'nextValue': item.nextValue,
              })
          .toList(),
      'risks': draft.risks.map(_risk).toList(),
    };
  }

  static Map<String, dynamic> _risk(RiskNotice notice) => {
        'level': notice.level.name,
        'title': notice.title,
        'message': notice.message,
      };

  static Future<Map<String, dynamic>> _securityGatewayState(
    Map<String, dynamic> args, {
    bool restore = false,
  }) async {
    final provider = SecurityGatewayCenterProvider(
      initialWebsiteId: args['websiteId'] as int?,
    );
    try {
      await provider.load();
      final applied = restore ? await provider.rollbackLatest() : null;
      return {
        'error': provider.error,
        'panelTlsEnabled': provider.panelTlsEnabled,
        'panelSslInfo': provider.panelSslInfo,
        'certificates': provider.certificates.map((cert) => cert.toJson()).toList(),
        'expiringCertificateCount': provider.expiringCertificateCount,
        'openRestyRunning': provider.openRestyRunning,
        'openRestyHttps': provider.openRestySnapshot.https,
        'risks': provider.riskNotices.map(_risk).toList(),
        'recentSnapshots': provider.recentSnapshots
            .map((snapshot) => {
                  'scope': snapshot.scope,
                  'title': snapshot.title,
                  'summary': snapshot.summary,
                  'createdAt': snapshot.createdAt.toIso8601String(),
                })
            .toList(),
        'applied': applied,
      };
    } finally {
      provider.dispose();
    }
  }
}
