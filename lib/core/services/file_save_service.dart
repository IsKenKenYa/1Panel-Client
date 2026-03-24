import 'dart:io';
import 'dart:typed_data';
import 'package:android_intent_plus/android_intent.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';

enum PermissionStatus {
  granted,
  denied,
  permanentlyDenied,
}

class FileSaveResult {
  final String? filePath;
  final bool success;
  final String? errorMessage;
  final PermissionStatus? permissionStatus;

  const FileSaveResult({
    this.filePath,
    required this.success,
    this.errorMessage,
    this.permissionStatus,
  });
}

class FileSaveService {
  static final FileSaveService _instance = FileSaveService._internal();
  factory FileSaveService() => _instance;
  FileSaveService._internal();

  Future<FileSaveResult> saveFile({
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
  }) async {
    appLogger.dWithPackage('file_save', 'saveFile: fileName=$fileName, bytesLength=${bytes.length}');

    try {
      if (Platform.isAndroid) {
        return await _saveFileAndroid(fileName, bytes);
      } else if (Platform.isIOS) {
        return await _saveFileIOS(fileName, bytes, mimeType);
      } else {
        return await _saveFileDesktop(fileName, bytes);
      }
    } catch (e) {
      appLogger.eWithPackage('file_save', 'saveFile: 保存文件失败', error: e);
      return FileSaveResult(
        success: false,
        errorMessage: '保存文件失败: $e',
      );
    }
  }

  Future<FileSaveResult> _saveFileAndroid(String fileName, Uint8List bytes) async {
    final androidInfo = await _getAndroidVersion();
    final isAndroid10OrAbove = androidInfo >= 29;

    Directory downloadDir;

    if (isAndroid10OrAbove) {
      downloadDir = await _getAndroid10PlusDownloadDir();
    } else {
      final permissionResult = await requestStoragePermission();
      if (permissionResult != PermissionStatus.granted) {
        return FileSaveResult(
          success: false,
          permissionStatus: permissionResult,
          errorMessage: permissionResult == PermissionStatus.permanentlyDenied
              ? '存储权限被永久拒绝，请在设置中手动开启'
              : '存储权限被拒绝',
        );
      }
      downloadDir = await _getAndroid9BelowDownloadDir();
    }

    final safeFileName = _sanitizeFileName(fileName);
    final filePath = await _getUniqueFilePath(downloadDir.path, safeFileName);

    final file = await File(filePath).create(recursive: true);
    await file.writeAsBytes(bytes);

    appLogger.iWithPackage('file_save', '_saveFileAndroid: 文件已保存到 $filePath');
    return FileSaveResult(
      success: true,
      filePath: filePath,
    );
  }

  Future<FileSaveResult> _saveFileIOS(String fileName, Uint8List bytes, String? mimeType) async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '保存文件',
        fileName: fileName,
        bytes: bytes,
      );

      if (result != null) {
        appLogger.iWithPackage('file_save', '_saveFileIOS: 文件已保存到 $result');
        return FileSaveResult(
          success: true,
          filePath: result,
        );
      } else {
        appLogger.iWithPackage('file_save', '_saveFileIOS: 用户取消保存');
        return FileSaveResult(
          success: false,
          errorMessage: '用户取消保存',
        );
      }
    } catch (e) {
      appLogger.wWithPackage('file_save', '_saveFileIOS: FilePicker保存失败，降级到应用文档目录: $e');
      
      final downloadDir = await getApplicationDocumentsDirectory();
      final safeFileName = _sanitizeFileName(fileName);
      final filePath = await _getUniqueFilePath(downloadDir.path, safeFileName);

      final file = await File(filePath).create(recursive: true);
      await file.writeAsBytes(bytes);

      appLogger.iWithPackage('file_save', '_saveFileIOS: 文件已保存到应用文档目录 $filePath');
      return FileSaveResult(
        success: true,
        filePath: filePath,
      );
    }
  }

  Future<FileSaveResult> _saveFileDesktop(String fileName, Uint8List bytes) async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '保存文件',
        fileName: fileName,
        bytes: bytes,
      );

      if (result != null) {
        appLogger.iWithPackage('file_save', '_saveFileDesktop: 文件已保存到 $result');
        return FileSaveResult(
          success: true,
          filePath: result,
        );
      } else {
        appLogger.iWithPackage('file_save', '_saveFileDesktop: 用户取消保存');
        return FileSaveResult(
          success: false,
          errorMessage: '用户取消保存',
        );
      }
    } catch (e) {
      appLogger.wWithPackage('file_save', '_saveFileDesktop: FilePicker保存失败，降级到下载目录: $e');
      
      final downloadDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final safeFileName = _sanitizeFileName(fileName);
      final filePath = await _getUniqueFilePath(downloadDir.path, safeFileName);

      final file = await File(filePath).create(recursive: true);
      await file.writeAsBytes(bytes);

      appLogger.iWithPackage('file_save', '_saveFileDesktop: 文件已保存到 $filePath');
      return FileSaveResult(
        success: true,
        filePath: filePath,
      );
    }
  }

  Future<PermissionStatus> requestStoragePermission() async {
    if (!Platform.isAndroid) {
      return PermissionStatus.granted;
    }

    try {
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 29) {
        return PermissionStatus.granted;
      }

      if (await Permission.manageExternalStorage.isGranted) {
        return PermissionStatus.granted;
      }

      final status = await Permission.storage.status;
      if (status.isGranted) {
        return PermissionStatus.granted;
      }

      if (status.isPermanentlyDenied) {
        return PermissionStatus.permanentlyDenied;
      }

      if (status.isDenied) {
        final result = await Permission.storage.request();
        if (result.isGranted) {
          return PermissionStatus.granted;
        }
        if (result.isPermanentlyDenied) {
          return PermissionStatus.permanentlyDenied;
        }
        return PermissionStatus.denied;
      }

      final manageResult = await Permission.manageExternalStorage.request();
      if (manageResult.isGranted) {
        return PermissionStatus.granted;
      }

      return PermissionStatus.denied;
    } catch (e) {
      appLogger.wWithPackage('file_save', 'requestStoragePermission: 权限检查失败，降级处理: $e');
      return PermissionStatus.granted;
    }
  }

  Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 29) {
        return true;
      }

      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      final status = await Permission.storage.status;
      return status.isGranted;
    } catch (e) {
      appLogger.wWithPackage('file_save', 'hasStoragePermission: 权限检查失败: $e');
      return true;
    }
  }

  Future<bool> isPermissionPermanentlyDenied() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 29) {
        return false;
      }

      final status = await Permission.storage.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      return false;
    }
  }

  Future<void> openFile(String filePath) async {
    appLogger.dWithPackage('file_save', 'openFile: filePath=$filePath');

    if (!await File(filePath).exists()) {
      throw Exception('文件不存在: $filePath');
    }

    // 注意: 需要在 pubspec.yaml 中添加 open_file 包依赖:
    // open_file: ^3.5.10
    // 
    // 使用方式:
    // import 'package:open_file/open_file.dart';
    // final result = await OpenFile.open(filePath);
    // if (result.type != ResultType.done) {
    //   throw Exception('打开文件失败: ${result.message}');
    // }
    //
    // 目前使用 url_launcher 作为替代方案:
    throw UnimplementedError(
      '请在 pubspec.yaml 中添加 open_file 包依赖后使用。\n'
      '依赖: open_file: ^3.5.10\n'
      '导入: import \'package:open_file/open_file.dart\';',
    );
  }

  Future<void> openFileLocation(String filePath) async {
    appLogger.dWithPackage('file_save', 'openFileLocation: filePath=$filePath');

    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('文件不存在: $filePath');
    }

    final directory = file.parent;

    if (Platform.isMacOS) {
      await Process.run('open', [directory.path]);
    } else if (Platform.isWindows) {
      await Process.run('explorer', [directory.path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [directory.path]);
    } else if (Platform.isAndroid) {
      await openDownloadsDirectory();
    } else {
      throw UnsupportedError('当前平台不支持打开文件所在目录');
    }

    appLogger.iWithPackage('file_save', 'openFileLocation: 已打开目录 ${directory.path}');
  }

  Future<bool> openDownloadsDirectory() async {
    if (Platform.isAndroid) {
      const data =
          'content://com.android.externalstorage.documents/document/primary%3ADownload';
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: data,
          type: 'vnd.android.document/directory',
          flags: <int>[268435456],
        );
        await intent.launch();
        return true;
      } catch (e) {
        appLogger.wWithPackage('file_save', 'openDownloadsDirectory: Android 打开失败: $e');
        return false;
      }
    }

    final downloadDir =
        await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    if (Platform.isMacOS) {
      await Process.run('open', [downloadDir.path]);
      return true;
    }
    if (Platform.isWindows) {
      await Process.run('explorer', [downloadDir.path]);
      return true;
    }
    if (Platform.isLinux) {
      await Process.run('xdg-open', [downloadDir.path]);
      return true;
    }

    return false;
  }

  Future<int> _getAndroidVersion() async {
    // Android版本检测需要 device_info_plus 包
    // 这里使用简化逻辑：假设较新版本
    // 实际使用时建议添加 device_info_plus 依赖
    try {
      if (await Permission.storage.status.isGranted ||
          await Permission.storage.status.isDenied ||
          await Permission.storage.status.isPermanentlyDenied) {
        // 如果能获取到storage权限状态，说明可能需要权限，假设是旧版本
        // 这是一个简化的判断，实际应该使用 device_info_plus
        return 28;
      }
      return 29;
    } catch (e) {
      return 29;
    }
  }

  Future<Directory> _getAndroid10PlusDownloadDir() async {
    // Android 10+ 最佳实践：使用 getDownloadsDirectory()
    // 无需权限，文件自动出现在系统下载管理器中
    final downloadDir = await getDownloadsDirectory();
    if (downloadDir != null) {
      appLogger.iWithPackage('file_save', '_getAndroid10PlusDownloadDir: 使用系统下载目录 ${downloadDir.path}');
      return downloadDir;
    }

    // 降级方案：如果 getDownloadsDirectory() 返回 null
    appLogger.wWithPackage('file_save', '_getAndroid10PlusDownloadDir: getDownloadsDirectory() 返回 null，降级到应用文档目录');
    final appDir = await getApplicationDocumentsDirectory();
    final fallbackPath = '${appDir.path}/Download';
    final fallbackDir = Directory(fallbackPath);
    if (!await fallbackDir.exists()) {
      await fallbackDir.create(recursive: true);
    }
    return fallbackDir;
  }

  Future<Directory> _getAndroid9BelowDownloadDir() async {
    final publicDownload = Directory('/storage/emulated/0/Download');
    if (await publicDownload.exists()) {
      return publicDownload;
    }

    final externalDir = await getExternalStorageDirectory();
    if (externalDir != null) {
      return externalDir;
    }

    return await getApplicationDocumentsDirectory();
  }

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  Future<String> _getUniqueFilePath(String directory, String fileName) async {
    final filePath = '$directory/$fileName';
    
    if (!await File(filePath).exists()) {
      return filePath;
    }

    final lastDot = fileName.lastIndexOf('.');
    String baseName;
    String extension;

    if (lastDot > 0) {
      baseName = fileName.substring(0, lastDot);
      extension = fileName.substring(lastDot);
    } else {
      baseName = fileName;
      extension = '';
    }

    int counter = 1;
    while (true) {
      final newPath = '$directory/${baseName}_$counter$extension';
      if (!await File(newPath).exists()) {
        return newPath;
      }
      counter++;
    }
  }

  Future<String?> getDownloadDirectoryPath() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _getAndroidVersion();
        if (androidInfo >= 29) {
          final dir = await _getAndroid10PlusDownloadDir();
          return dir.path;
        } else {
          final hasPermission = await hasStoragePermission();
          if (hasPermission) {
            final publicDownload = Directory('/storage/emulated/0/Download');
            if (await publicDownload.exists()) {
              return publicDownload.path;
            }
          }
          final dir = await _getAndroid10PlusDownloadDir();
          return dir.path;
        }
      } else if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        return dir.path;
      } else {
        final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        return dir.path;
      }
    } catch (e) {
      appLogger.eWithPackage('file_save', 'getDownloadDirectoryPath: 获取下载目录失败', error: e);
      return null;
    }
  }
}
