import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:onepanel_client/core/services/logger/logger_service.dart';

/// 应用图标的磁盘缓存。
///
/// 面板 `/apps/icon/:key` 对远程图标返回 302 跳转到图标 CDN，跟随跳转后
/// 必须等 CDN 响应，弱网下会超过请求超时。上游前端对远程图标直接把地址
/// 交给浏览器，只有本地图标才走面板接口；客户端同一套语义下仍需要
/// 落盘，避免每次进入页面都重新请求。
class AppIconCache {
  const AppIconCache._();

  static const Duration _maxAge = Duration(days: 30);
  static const String _directoryName = 'kenpanel_app_icons';

  /// 读取缓存，缺失或过期时返回 null。
  static Future<String?> read(String appKey) async {
    final file = await _file(appKey);
    if (file == null) return null;
    try {
      if (!await file.exists()) return null;
      final modified = await file.lastModified();
      if (DateTime.now().difference(modified) > _maxAge) return null;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      return 'data:image/png;base64,${base64Encode(bytes)}';
    } catch (error) {
      appLogger.wWithPackage('app-icon', '读取图标缓存失败: $error');
      return null;
    }
  }

  /// 写入缓存。字节来自网络，面板本身已按 PNG 返回。
  static Future<void> write(String appKey, Uint8List bytes) async {
    if (bytes.isEmpty) return;
    final file = await _file(appKey);
    if (file == null) return;
    try {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
    } catch (error) {
      appLogger.wWithPackage('app-icon', '写入图标缓存失败: $error');
    }
  }

  /// 清除全部图标缓存，供设置页缓存清理调用。
  static Future<void> clear() async {
    try {
      final directory = await _directory();
      if (await directory.exists()) await directory.delete(recursive: true);
    } catch (error) {
      appLogger.wWithPackage('app-icon', '清理图标缓存失败: $error');
    }
  }

  static Future<Directory> _directory() async {
    final support = await getApplicationSupportDirectory();
    return Directory(path.join(support.path, _directoryName));
  }

  static Future<File?> _file(String appKey) async {
    if (appKey.isEmpty) return null;
    final directory = await _directory();
    final digest = md5.convert(utf8.encode(appKey)).toString();
    return File(path.join(directory.path, '$digest.png'));
  }
}
