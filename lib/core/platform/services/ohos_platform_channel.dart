import 'package:flutter/services.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';

import 'ohos_channel_names.dart';

/// Structured outcome returned by OHOS save operations. Distinguishes
/// the three save targets so the UI can show appropriate success toasts.
enum SaveLocationKind {
  /// File saved into the public Downloads directory.
  publicDownloadDir,

  /// File saved into a user-picked location (content:// URI returned).
  pickerUri,

  /// File fell back to the app's private directory. Should only happen
  /// when the picker is unavailable; the UI is expected to surface a
  /// warning in this case.
  privateFallback,

  /// Saved location is unknown / not classified.
  other,
}

class OhosSaveOutcome {
  final String uri;
  final String displayName;
  final SaveLocationKind kind;
  final String? category;

  const OhosSaveOutcome({
    required this.uri,
    required this.displayName,
    required this.kind,
    this.category,
  });

  factory OhosSaveOutcome.fromMap(Map<String, Object?> map) {
    return OhosSaveOutcome(
      uri: (map['uri'] as String?) ?? '',
      displayName: (map['displayName'] as String?) ?? '',
      kind: _parseKind(map['kind'] as String?),
      category: map['category'] as String?,
    );
  }

  static SaveLocationKind _parseKind(String? raw) {
    switch (raw) {
      case 'publicDownloadDir':
        return SaveLocationKind.publicDownloadDir;
      case 'pickerUri':
        return SaveLocationKind.pickerUri;
      case 'privateFallback':
        return SaveLocationKind.privateFallback;
      default:
        return SaveLocationKind.other;
    }
  }
}

class OhosPlatformChannel {
  const OhosPlatformChannel({
    MethodChannel channel = const MethodChannel(channelName),
  }) : _channel = channel;

  static const String channelName = OhosChannelNames.ohosPlatform;

  final MethodChannel _channel;

  Future<Map<String, Object?>> getRuntimeInfo() async {
    final raw = await _channel.invokeMapMethod<String, Object?>(
      'getRuntimeInfo',
    );
    return raw ?? const <String, Object?>{};
  }

  Future<String> saveBytes({
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
  }) async {
    final result = await _channel.invokeMethod<String>(
      'saveBytes',
      <String, Object?>{
        'fileName': fileName,
        'bytes': bytes,
        'mimeType': mimeType,
      },
    );
    return result ?? '';
  }

  Future<OhosSaveOutcome?> pickAndSaveBytes({
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
  }) async {
    // Routes to the kind-aware native picker with default `document` kind.
    return pickAndSaveBytesByKind(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
      mimeKind: 'document',
    );
  }

  /// Route picker selection based on MIME classification. `mimeKind` is
  /// one of `document`, `audio`, `image_video`. Returns `null` on user
  /// cancel.
  Future<OhosSaveOutcome?> pickAndSaveBytesByKind({
    required String fileName,
    required Uint8List bytes,
    required String mimeKind,
    String? mimeType,
  }) async {
    final raw = await _channel.invokeMapMethod<String, Object?>(
      'pickAndSaveBytesByKind',
      <String, Object?>{
        'fileName': fileName,
        'bytes': bytes,
        'mimeType': mimeType,
        'mimeKind': mimeKind,
      },
    );
    if (raw == null) return null;
    return OhosSaveOutcome.fromMap(raw);
  }

  Future<OhosSaveOutcome> saveBytesToPublicDownload({
    required String fileName,
    required Uint8List bytes,
    required String category,
    String? subDir,
  }) async {
    final raw = await _channel.invokeMapMethod<String, Object?>(
      'saveBytesToPublicDownload',
      <String, Object?>{
        'fileName': fileName,
        'bytes': bytes,
        'category': category,
        'subDir': subDir,
      },
    );
    if (raw == null) {
      throw PlatformException(
        code: 'ohos_platform_error',
        message: 'saveBytesToPublicDownload returned null',
      );
    }
    return OhosSaveOutcome.fromMap({
      ...raw,
      'kind': 'publicDownloadDir',
      'category': category,
    });
  }

  Future<bool> openPath(String path) async {
    final opened = await _channel.invokeMethod<bool>(
      'openPath',
      <String, Object?>{'path': path},
    );
    return opened == true;
  }

  Future<bool> openDirectory(String path) async {
    final opened = await _channel.invokeMethod<bool>(
      'openDirectory',
      <String, Object?>{'path': path},
    );
    return opened == true;
  }

  /// Open a content:// URI via the system file viewer. Used for files
  /// saved through picker dialogs.
  Future<bool> openUri(String contentUri) async {
    final opened = await _channel.invokeMethod<bool>(
      'openUri',
      <String, Object?>{'uri': contentUri},
    );
    return opened == true;
  }

  Future<String?> pickSaveDirectory() {
    return _channel.invokeMethod<String>('pickSaveDirectory');
  }

  Future<List<String>> pickFiles({
    required bool allowMultiple,
    List<String>? allowedExtensions,
  }) async {
    final paths = await _channel.invokeListMethod<String>('pickFiles', {
      'allowMultiple': allowMultiple,
      'fileSuffixFilters': [
        for (final extension in allowedExtensions ?? const <String>[])
          '.$extension',
      ],
    });
    return paths!;
  }

  /// Returns the OHOS public download directory the native side exposes
  /// to the user. Maps to `Files/Downloads/...` in the system Files app.
  /// Returns a map `{ path, displayName }` so callers can render a
  /// user-friendly location name. The native side is responsible for
  /// `mkdir` on missing directories.
  Future<Map<String, Object?>> getPublicDownloadDir() async {
    final raw = await _channel.invokeMapMethod<String, Object?>(
      'getPublicDownloadDir',
    );
    return raw ?? const <String, Object?>{};
  }

  Future<String> saveBytesToDownload({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final result = await _channel.invokeMethod<String>(
      'saveBytesToDownload',
      <String, Object?>{
        'fileName': fileName,
        'bytes': bytes,
      },
    );
    return result ?? '';
  }

  // Duplicates OhosDownloadService's channel so diagnostics and legacy callers
  // can access downloads without depending on the full service.
  static const MethodChannel _downloadChannel =
      MethodChannel(OhosChannelNames.ohosDownload);

  Future<String?> downloadFile({
    required String url,
    required String savedDir,
    String? fileName,
    Map<String, String>? headers,
    bool? usePicker,
  }) async {
    final chooseLocation = usePicker ??
        await AppPreferencesService().loadUseFilePickerForFileOperations();
    return _downloadChannel.invokeMethod<String>(
      'enqueue',
      <String, Object?>{
        'url': url,
        'savedDir': savedDir,
        'fileName': fileName,
        'headers': headers ?? <String, String>{},
        'usePicker': chooseLocation,
      },
    );
  }

  Future<void> pauseDownload(String taskId) async {
    await _downloadChannel.invokeMethod<void>('pause', <String, Object?>{
      'taskId': taskId,
    });
  }

  Future<void> resumeDownload(String taskId) async {
    await _downloadChannel.invokeMethod<void>('resume', <String, Object?>{
      'taskId': taskId,
    });
  }

  Future<void> cancelDownload(String taskId) async {
    await _downloadChannel.invokeMethod<void>('cancel', <String, Object?>{
      'taskId': taskId,
    });
  }
}
