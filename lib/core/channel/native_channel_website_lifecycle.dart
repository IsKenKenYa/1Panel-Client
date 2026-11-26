import '../../data/models/website_models.dart';
import '../../data/repositories/website_repository.dart';
import '../../features/websites/services/website_domain_service.dart';

class NativeChannelWebsiteLifecycleHandlers {
  static Future<dynamic> dispatch(String method, dynamic arguments) async {
    final args = Map<String, dynamic>.from(arguments as Map);
    final repository = WebsiteRepository();
    switch (method) {
      case 'searchNativeWebsites':
        final result = await repository.searchWebsites(
          name: args['name'] as String?,
          type: args['type'] as String?,
          websiteGroupId: args['groupId'] as int?,
          page: args['page'] as int,
          pageSize: args['pageSize'] as int,
        );
        return {
          'items': result.items.map((item) => item.toJson()).toList(),
          'total': result.total,
        };
      case 'getNativeWebsiteDetail':
        return (await repository.getWebsiteDetail(args['id'] as int)).toJson();
      case 'getNativeWebsiteGroups':
        return (await repository.listWebsiteGroups())
            .map((group) => {'id': group.id, 'name': group.name})
            .toList();
      case 'createNativeWebsite':
        final domain = args['primaryDomain'] as String;
        final port = args['port'] as int?;
        final request = WebsiteCreate(
          alias: args['alias'] as String,
          name: domain,
          type: args['type'] as String,
          webSiteGroupId: args['groupId'] as int,
          remark: args['remark'] as String?,
          appType: 'installed',
          runtimeId: args['runtimeId'] as int?,
          siteDir: args['siteDir'] as String?,
          proxyType: args['proxyType'] as String?,
          proxy: args['proxy'] as String?,
          port: port,
          parentWebsiteId: args['parentWebsiteId'] as int?,
          ipv6: args['ipv6'] as bool,
          domains: [WebsiteDomain(domain: domain, port: port, ssl: false)],
          taskId: DateTime.now().millisecondsSinceEpoch.toString(),
        );
        await repository.preCheckWebsite({});
        await repository.createWebsite(request);
        return null;
      case 'updateNativeWebsite':
        await repository.updateWebsiteByModel(WebsiteUpdate(
          id: args['id'] as int,
          primaryDomain: args['primaryDomain'] as String,
          remark: args['remark'] as String,
          webSiteGroupId: args['groupId'] as int,
          ipv6: args['ipv6'] as bool,
          favorite: args['favorite'] as bool,
        ));
        return null;
      case 'operateNativeWebsites':
        final ids = (args['ids'] as List).cast<int>();
        final operation = args['operation'] as String;
        if (operation == 'delete') {
          await repository.batchDelete(ids);
        } else {
          await repository.batchOperate(ids: ids, operate: operation);
        }
        return null;
      case 'setNativeWebsiteGroup':
        await repository.batchSetGroup(
          ids: (args['ids'] as List).cast<int>(),
          groupId: args['groupId'] as int,
        );
        return null;
      case 'setNativeDefaultWebsite':
        await repository.changeDefaultServer(id: args['id'] as int);
        return null;
      case 'updateNativeWebsiteDomain':
        await WebsiteDomainService().updateDomain(
          id: args['id'] as int,
          domain: args['domain'] as String?,
          port: args['port'] as int?,
          ssl: args['ssl'] as bool?,
        );
        return null;
      case 'getNativeDefaultWebsiteHtml':
        return repository.getDefaultHtml(args['type'] as String);
      case 'updateNativeDefaultWebsiteHtml':
        await repository.updateDefaultHtml(
          type: args['type'] as String,
          content: args['content'] as String,
        );
        return null;
      default:
        throw ArgumentError.value(method, 'method');
    }
  }
}
