import '../../data/models/openresty_models.dart';
import '../../data/models/website_models.dart';
import '../../data/repositories/website_repository.dart';
import '../../features/websites/services/website_config_service.dart';

class NativeChannelWebsiteConfigHandlers {
  static Future<dynamic> dispatch(String method, dynamic arguments) async {
    final args = Map<String, dynamic>.from(arguments as Map);
    final service = WebsiteConfigService();
    final websiteId = args['websiteId'] as int;
    switch (method) {
      case 'getNativeWebsiteNginx':
        final file = await service.getConfigFile(websiteId: websiteId);
        return {'path': file.path, 'content': file.content};
      case 'saveNativeWebsiteNginx':
        await service.saveConfigFile(
          websiteId: websiteId,
          content: args['content'] as String,
        );
        return null;
      case 'saveNativeWebsiteRuleSource':
        final name = args['name'] as String;
        final content = args['content'] as String;
        final request = {
          'websiteID': websiteId,
          'name': name,
          'content': content,
        };
        switch (args['ruleType'] as String) {
          case 'proxy':
            await service.updateProxy(
              websiteId: websiteId,
              name: name,
              content: content,
            );
          case 'redirect':
            await service.updateRedirectFile(request);
          case 'loadbalance':
            await service.updateLoadBalancerFile(request);
          default:
            throw ArgumentError.value(args['ruleType'], 'ruleType');
        }
        return null;
      case 'getNativeWebsiteResource':
        final website = await WebsiteRepository().getWebsiteDetail(websiteId);
        final canChangeDatabase =
            website.type == 'static' || website.type == 'runtime';
        final resources = await service.getResource(websiteId);
        return {
          'resources': resources.map((resource) => resource.toJson()).toList(),
          'canChangeDatabase': canChangeDatabase,
          'databaseId': website.dbId,
          'databaseType': website.dbType,
          'databases': canChangeDatabase
              ? await service.getDatabases()
              : const <Map<String, dynamic>>[],
        };
      case 'setNativeWebsiteDatabase':
        await service.changeDatabase({
          'websiteID': websiteId,
          'databaseID': args['databaseId'] as int,
          if (args['databaseType'] != null)
            'databaseType': args['databaseType'] as String,
        });
        return null;
      case 'setNativeWebsitePhp':
        await service.updatePhpVersion(
          websiteId: websiteId,
          runtimeId: args['runtimeId'] as int?,
        );
        return null;
      case 'getNativeWebsiteScope':
        return (await service.loadScope(
          websiteId: websiteId,
          scope: NginxKey.values.firstWhere((key) => key.value == args['scope']),
        )).toJson();
      case 'saveNativeWebsiteScope':
        await service.updateScope(
          websiteId: websiteId,
          scope: NginxKey.values.firstWhere((key) => key.value == args['scope']),
          params: (args['params'] as List)
              .map((item) => WebsiteNginxParam.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList(),
        );
        return null;
      default:
        throw ArgumentError.value(method, 'method');
    }
  }
}
