import 'package:flutter/services.dart';

import '../../data/models/file_models.dart';
import '../../features/files/services/file_browser_service.dart';
import '../../features/files/services/file_recycle_service.dart';
import '../../features/files/services/file_transfer_service.dart';
import 'native_channel_write_handlers.dart';

class NativeChannelHarmonyFileSecondary {
  static Future<Object?> dispatch(String method, dynamic arguments) async {
    final args = Map<String, Object?>.from(arguments as Map);
    switch (method) {
      case 'getHarmonyFileSecondary':
        return _load(args);
      case 'operateHarmonyFileSecondary':
        return _operate(args);
      default:
        throw MissingPluginException(method);
    }
  }

  static Future<Object?> _load(Map<String, Object?> args) async {
    switch (args['route']) {
      case '/files/favorites':
        final files = await FileBrowserService().searchFavoriteFiles(
          path: '/',
          page: args['page'] as int,
        );
        return files.map((file) => file.toJson()).toList();
      case '/files/mounts':
        final mounts = await FileBrowserService().getMountInfo();
        return mounts.map((mount) => mount.toJson()).toList();
      case '/files/recycle':
        final files = await FileRecycleService().searchRecycleBin(
          path: '/',
          page: args['page'] as int,
        );
        return files.map((file) => file.toJson()).toList();
      case '/files/recycle-status':
        final status = await FileRecycleService().getRecycleBinStatus();
        return [status.toJson()];
      case '/files/history':
        return FileTransferService().searchHistory(
          args['path'] as String,
          page: args['page'] as int,
        );
      case '/files/share':
        return FileTransferService().searchShares();
      case '/files/wget':
        return FileTransferService().getWgetProgress();
      case '/files/permission':
        final ownerOptions = await FileBrowserService().getUserGroup();
        return [ownerOptions.toJson()];
      default:
        throw ArgumentError.value(args['route'], 'route');
    }
  }

  static Future<Object?> _operate(Map<String, Object?> args) async {
    final rawItem = args['item'] as Map?;
    final item = rawItem?.cast<String, Object?>();
    switch (args['action']) {
      case 'unfavorite':
        final result = await NativeChannelWriteHandlers.removeFavoriteHandler({
          'id': (item!['favoriteID'] ?? item['id']) as int,
        });
        if (result['success'] != true) {
          throw StateError(result['error'] as String);
        }
      case 'restore-recycle':
        await FileRecycleService().restoreFile(RecycleBinReduceRequest(
          rName: item!['rName'] as String,
          from: item['from'] as String,
          name: item['name'] as String,
        ));
      case 'delete-recycle':
        await FileRecycleService().deleteRecycleBinFiles([
          RecycleBinItem(
            sourcePath: item!['path'] as String,
            name: item['name'] as String,
            isDir: item['isDir'] as bool,
            size: item['size'] as int,
            rName: item['rName'] as String,
            from: item['from'] as String,
          ),
        ]);
      case 'clear-recycle':
        await FileRecycleService().clearRecycleBin();
      case 'preview-history':
        return FileTransferService().getHistoryContent(item!['id'] as int);
      case 'restore-history':
        await FileTransferService().restoreHistory(item!['id'] as int);
      case 'delete-history':
        await FileTransferService().deleteHistory(item!['id'] as int);
      case 'delete-share':
        await FileTransferService().deleteShare(item!['path'] as String);
      case 'create-share':
        final result = await FileTransferService().createShare(
          path: args['path'] as String,
          expireMinutes: int.parse(args['expireMinutes'] as String),
          password: args['password'] as String,
        );
        return result['link'];
      case 'copy-share':
        return FileTransferService().shareLink(item!['code'] as String);
      case 'stop-wget':
        await FileTransferService().stopWget(item!['key'] as String);
      case 'change-mode':
        await FileBrowserService().changeFileMode(
          args['path'] as String,
          int.parse(args['mode'] as String, radix: 8),
          sub: args['recursive'] as bool?,
        );
      case 'change-owner':
        await FileBrowserService().changeFileOwner(
          args['path'] as String,
          args['user'] as String,
          args['group'] as String,
          sub: args['recursive'] as bool?,
        );
      default:
        throw ArgumentError.value(args['action'], 'action');
    }
    return null;
  }
}
