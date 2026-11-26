import 'dart:io';
import 'dart:typed_data';

import 'package:android_intent_plus/android_intent.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:onepanel_client/core/platform/platform_capabilities.dart';
import 'package:onepanel_client/core/platform/services/ohos_platform_channel.dart';
import 'package:onepanel_client/core/platform/services/platform_system_paths.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'browser_file_operations.dart';

typedef DirectoryResolver = Future<Directory> Function();

class PlatformFileService {
  PlatformFileService({
    PlatformCapabilitiesSnapshot? capabilities,
    OhosPlatformChannel? ohosChannel,
    DirectoryResolver? fallbackDirectoryResolver,
    AppPreferencesService? preferencesService,
  })  : _capabilities = capabilities ?? PlatformCapabilities.current(),
        _ohosChannel = ohosChannel ?? const OhosPlatformChannel(),
        _fallbackDirectoryResolver = fallbackDirectoryResolver,
        _preferencesService = preferencesService ?? AppPreferencesService();

  final PlatformCapabilitiesSnapshot _capabilities;
  final OhosPlatformChannel _ohosChannel;
  final DirectoryResolver? _fallbackDirectoryResolver;
  final AppPreferencesService _preferencesService;

  Future<String?> pickFile({bool withData = false}) async {
    final result = await selectFiles(withData: withData);
    return result?.files.single.path;
  }

  /// 选择多个文件，返回本地路径列表。
  Future<List<String>> pickFiles() async {
    final result = await selectFiles(allowMultiple: true);
    if (result == null) return const <String>[];
    return result.files.map((f) => f.path).whereType<String>().toList();
  }

  Future<FilePickerResult?> selectFiles({
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    List<String>? allowedExtensions,
  }) async {
    if (!_capabilities.supportsNativeFilePicker) {
      return FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        withData: withData,
        withReadStream: withReadStream,
        type: allowedExtensions == null ? FileType.any : FileType.custom,
        allowedExtensions: allowedExtensions,
      );
    }
    final paths = await _ohosChannel.pickFiles(
      allowMultiple: allowMultiple,
      allowedExtensions: allowedExtensions,
    );
    if (paths.isEmpty) return null;
    final files = <PlatformFile>[];
    for (final path in paths) {
      final file = File(path);
      files.add(PlatformFile(
        name: p.basename(path),
        path: path,
        size: await file.length(),
        bytes: withData ? await file.readAsBytes() : null,
        readStream: withReadStream ? file.openRead() : null,
      ));
    }
    return FilePickerResult(files);
  }

  /// Save bytes using a structured save pipeline. Replaces the previous
  /// silent-fallback flow that always returned a string path.
  Future<SaveOutcome> saveBytesStructured({
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
    String? category,
  }) async {
    final safeFileName = _sanitizeFileName(fileName);
    if (_capabilities.isWeb) {
      return SaveOutcome(
        uri: BrowserFileOperations.download(bytes, safeFileName,
            mimeType: mimeType),
        displayName: safeFileName,
        kind: SaveLocationKind.publicDownloadDir,
        category: category,
      );
    }
    final usePicker = await _shouldUsePicker();
    final mimeKind = _classifyMimeKind(mimeType);
    final effectiveCategory = category ?? _defaultCategoryForMime(mimeType);
    final subDir = await _loadSubDirectoryName();

    if (_capabilities.supportsNativeFileSave) {
      if (usePicker) {
        final outcome = await _ohosChannel.pickAndSaveBytesByKind(
          fileName: safeFileName,
          bytes: bytes,
          mimeKind: mimeKind,
          mimeType: mimeType,
        );
        return outcome == null
            ? SaveOutcome.cancelled()
            : _outcomeFromOhos(outcome, safeFileName);
      }
      final outcome = await _ohosChannel.saveBytesToPublicDownload(
        fileName: safeFileName,
        bytes: bytes,
        category: effectiveCategory,
        subDir: subDir,
      );
      return _outcomeFromOhos(outcome, safeFileName);
    }

    // Non-OHOS platforms use file_picker.
    if (usePicker) {
      try {
        final result = await FilePicker.platform.saveFile(
          dialogTitle: '保存文件',
          fileName: safeFileName,
          bytes: bytes,
        );
        if (result != null && result.isNotEmpty) {
          return SaveOutcome(
            uri: result,
            displayName: safeFileName,
            kind: SaveLocationKind.pickerUri,
            category: effectiveCategory,
          );
        }
        return SaveOutcome.cancelled();
      } catch (error, stackTrace) {
        appLogger.wWithPackage(
          'core.platform.file_service',
          'FilePicker save failed, falling back to default directory',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    final path = await _saveToFallbackDirectory(
      fileName: safeFileName,
      bytes: bytes,
      subDir: subDir,
      category: effectiveCategory,
    );
    return SaveOutcome(
      uri: path,
      displayName: subDir.isNotEmpty
          ? '$subDir/$effectiveCategory/$safeFileName'
          : '$effectiveCategory/$safeFileName',
      kind: SaveLocationKind.publicDownloadDir,
      category: effectiveCategory,
    );
  }

  /// Backwards-compatible wrapper that returns a filesystem path. Prefer
  /// [saveBytesStructured] in new code so the UI can render the saved
  /// location display name rather than the raw path.
  Future<String> saveBytes({
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
  }) async {
    final outcome = await saveBytesStructured(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );
    return outcome.uri;
  }

  Future<void> openFile(String filePath) async {
    if (!await File(filePath).exists()) {
      throw FileSystemException('文件不存在', filePath);
    }

    if (_capabilities.isOhos) {
      final opened = await _tryOpenOhosPath(filePath);
      if (opened) {
        return;
      }
    }

    if (Platform.isMacOS) {
      await Process.run('open', <String>[filePath]);
      return;
    }
    if (Platform.isWindows) {
      await Process.run('cmd', <String>['/c', 'start', '', filePath],
          runInShell: true);
      return;
    }
    if (Platform.isLinux) {
      await Process.run('xdg-open', <String>[filePath]);
      return;
    }
    if (Platform.isAndroid || Platform.isIOS) {
      // No reliable cross-app file opener on mobile; open the parent
      // directory so the user can tap the file in their file manager.
      appLogger.wWithPackage(
        'core.platform.file_service',
        '当前平台不支持直接打开文件，将打开文件所在目录',
      );
      await _openDirectoryWithHost(filePath);
      return;
    }

    throw UnsupportedError('当前平台不支持打开文件');
  }

  /// Open a saved outcome through the most appropriate mechanism. For
  /// content:// URIs from picker, this calls [OhosPlatformChannel.openUri]
  /// so OHOS launches the system file viewer with a temporary read
  /// grant. For filesystem paths, falls through to [openFile].
  Future<bool> openSaveOutcome(SaveOutcome outcome) async {
    if (_capabilities.isWeb) return false;
    if (_capabilities.isOhos) {
      if (outcome.kind == SaveLocationKind.pickerUri &&
          (outcome.uri.startsWith('content://') ||
              outcome.uri.startsWith('file://'))) {
        try {
          return await _ohosChannel.openUri(outcome.uri);
        } catch (error, stackTrace) {
          appLogger.wWithPackage(
            'core.platform.file_service',
            'openUri failed, falling back to file path opener',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
      final opened = await _tryOpenOhosPath(outcome.uri);
      if (opened) return true;
    }
    try {
      await openFile(outcome.uri);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> openDirectory(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      throw FileSystemException('目录不存在', path);
    }

    if (_capabilities.isOhos) {
      final opened = await _tryOpenOhosDirectory(path);
      if (opened) {
        return;
      }
    }

    await _openDirectoryPathWithHost(path);
  }

  Future<String?> getDownloadDirectoryPath() async {
    if (_capabilities.isWeb) return null;
    try {
      if (_capabilities.supportsAndroidIntent) {
        // Use explicit path instead of getDownloadsDirectory() —
        // the latter is unreliable on some Android OEM ROMs.
        final dir = Directory('/storage/emulated/0/Download');
        if (await dir.exists()) {
          return dir.path;
        }
        final extDir = await getExternalStorageDirectory();
        return extDir?.path ?? (await _getFallbackDownloadDir()).path;
      }

      return (await _getFallbackDownloadDir()).path;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'core.platform.file_service',
        'getDownloadDirectoryPath failed',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<bool> openDownloadsDirectory() async {
    if (_capabilities.isWeb) return false;
    if (_capabilities.supportsAndroidIntent) {
      const data =
          'content://com.android.externalstorage.documents/document/primary%3ADownload';
      try {
        final intent = const AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: data,
          type: 'vnd.android.document/directory',
          flags: <int>[268435456],
        );
        await intent.launch();
        return true;
      } catch (error, stackTrace) {
        appLogger.wWithPackage(
          'core.platform.file_service',
          'Android open downloads directory failed',
          error: error,
          stackTrace: stackTrace,
        );
        return false;
      }
    }

    final path = await getDownloadDirectoryPath();
    if (path == null) {
      return false;
    }
    try {
      await openDirectory(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Reads the picker toggle from AppPreferencesService. Failures fall
  // back to `true` so the picker is always offered by default.
  Future<bool> _shouldUsePicker() async {
    try {
      return await _preferencesService.loadUseFilePickerForFileOperations();
    } catch (_) {
      return true;
    }
  }

  String _classifyMimeKind(String? mimeType) {
    if (mimeType == null) return 'document';
    if (mimeType.startsWith('audio/')) return 'audio';
    if (mimeType.startsWith('image/') || mimeType.startsWith('video/')) {
      return 'image_video';
    }
    return 'document';
  }

  String _defaultCategoryForMime(String? mimeType) {
    if (mimeType == null) return 'files';
    if (mimeType.startsWith('image/')) return 'images';
    if (mimeType.startsWith('video/')) return 'videos';
    if (mimeType.startsWith('audio/')) return 'audio';
    if (mimeType.startsWith('text/')) return 'logs';
    return 'files';
  }

  SaveOutcome _outcomeFromOhos(OhosSaveOutcome outcome, String fallbackName) {
    return SaveOutcome(
      uri: outcome.uri,
      displayName: outcome.displayName.isNotEmpty
          ? outcome.displayName
          : fallbackName,
      kind: outcome.kind,
      category: outcome.category,
    );
  }

  Future<String> _saveToFallbackDirectory({
    required String fileName,
    required Uint8List bytes,
    String subDir = '',
    String? category,
  }) async {
    final directory = await _resolveTargetDir(
      subDir: subDir,
      category: category,
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final filePath = await _getUniqueFilePath(directory.path, fileName);
    final file = await File(filePath).create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  // Compose <downloads>/<subDir>/<category> for the silent save path.
  // Returns a path under the application documents directory when
  // PlatformSystemPaths cannot resolve a real system download dir
  // (which is only expected in unusual environments).
  Future<Directory> _resolveTargetDir({
    required String subDir,
    String? category,
  }) async {
    final resolved = await PlatformSystemPaths.defaultDownloadDir();
    final base = resolved ?? await _getFallbackDownloadDir();
    final segments = <String>[base.path];
    if (subDir.trim().isNotEmpty) {
      segments.add(_sanitizeSubDirName(subDir));
    }
    if (category != null && category.isNotEmpty) {
      segments.add(_sanitizeSubDirName(category));
    }
    return Directory(segments.join(Platform.pathSeparator));
  }

  String _sanitizeSubDirName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_');
  }

  Future<String> _loadSubDirectoryName() async {
    try {
      return await _preferencesService.loadFileSaveSubDirectoryName();
    } catch (_) {
      return AppPreferencesService.defaultFileSaveSubDirectoryName;
    }
  }

  Future<Directory> _getFallbackDownloadDir() async {
    if (_fallbackDirectoryResolver != null) {
      return _fallbackDirectoryResolver();
    }
    if (_capabilities.isOhos || Platform.isAndroid || Platform.isIOS) {
      final documents = await getApplicationDocumentsDirectory();
      return Directory('${documents.path}/exports');
    }
    // Desktop fallback: use the platform-abstracted system download dir
    // (PlatformSystemPaths handles env vars and platform quirks). Only
    // fall back to ApplicationDocumentsDirectory when the resolution
    // itself fails (e.g. $HOME is unset, or path_provider throws).
    final resolved = await PlatformSystemPaths.defaultDownloadDir();
    if (resolved != null) {
      return resolved;
    }
    return getApplicationDocumentsDirectory();
  }

  /// Appends numeric suffixes (`_1`, `_2`, ...) to avoid overwriting existing
  /// files when the user exports the same name multiple times in a session.
  Future<String> _getUniqueFilePath(String directory, String fileName) async {
    final filePath = '$directory/$fileName';

    if (!await File(filePath).exists()) {
      return filePath;
    }

    final lastDot = fileName.lastIndexOf('.');
    final baseName = lastDot > 0 ? fileName.substring(0, lastDot) : fileName;
    final extension = lastDot > 0 ? fileName.substring(lastDot) : '';

    const maxAttempts = 9999;
    var counter = 1;
    while (counter <= maxAttempts) {
      final newPath = '$directory/${baseName}_$counter$extension';
      if (!await File(newPath).exists()) {
        return newPath;
      }
      counter++;
    }
    throw FileSystemException(
      '无法生成唯一文件名，已尝试 $maxAttempts 次',
      '$directory/$fileName',
    );
  }

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  Future<bool> _tryOpenOhosPath(String path) async {
    try {
      return _ohosChannel.openPath(path);
    } catch (error, stackTrace) {
      appLogger.wWithPackage(
        'core.platform.file_service',
        'OHOS openPath failed',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> _tryOpenOhosDirectory(String path) async {
    try {
      return _ohosChannel.openDirectory(path);
    } catch (error, stackTrace) {
      appLogger.wWithPackage(
        'core.platform.file_service',
        'OHOS openDirectory failed',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> _openDirectoryWithHost(String filePath) async {
    await _openDirectoryPathWithHost(File(filePath).parent.path);
  }

  Future<void> _openDirectoryPathWithHost(String directoryPath) async {
    if (Platform.isMacOS) {
      await Process.run('open', <String>[directoryPath]);
      return;
    }
    if (Platform.isWindows) {
      await Process.run('explorer', <String>[directoryPath]);
      return;
    }
    if (Platform.isLinux) {
      await Process.run('xdg-open', <String>[directoryPath]);
      return;
    }
    throw UnsupportedError('当前平台不支持打开文件所在目录');
  }
}

/// Structured save result. Replaces the old `String?` return value from
/// [PlatformFileService.saveBytes] in new code. The `kind` field tells
/// the UI which success message to render.
class SaveOutcome {
  final String uri;
  final String displayName;
  final SaveLocationKind kind;
  final String? category;
  // True when the native picker failed and the service fell back to
  // the app's private directory. The UI should surface a warning toast
  // in this case.
  final bool privateFallbackUsed;

  const SaveOutcome({
    required this.uri,
    required this.displayName,
    required this.kind,
    this.category,
    this.privateFallbackUsed = false,
  });

  factory SaveOutcome.cancelled() => const SaveOutcome(
        uri: '',
        displayName: '',
        kind: SaveLocationKind.other,
      );

  bool get isCancelled => uri.isEmpty;
}
