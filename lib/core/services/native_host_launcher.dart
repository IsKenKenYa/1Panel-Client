import 'dart:io';

import 'package:path/path.dart' as p;

/// WinUI3 原生宿主（OnePanelNativeHost.exe）的定位与拉起。
/// 候选规则与 windows/runner/render_mode_bootstrap.cpp 的
/// ResolveNativeHostExecutablePath 保持一致。
class NativeHostLauncher {
  NativeHostLauncher({
    bool Function(String path)? exists,
    Future<void> Function(String executablePath)? startProcess,
    String? runnerExeDir,
  })  : _exists = exists ?? ((path) => File(path).existsSync()),
        _startProcess = startProcess ?? _defaultStartProcess,
        _runnerExeDir = runnerExeDir;

  final bool Function(String path) _exists;
  final Future<void> Function(String executablePath) _startProcess;
  final String? _runnerExeDir;

  static const String _hostFileName = 'OnePanelNativeHost.exe';

  /// 宿主 exe 候选路径（顺序即优先级，与 C++ bootstrap 一致）：
  /// ① runner 输出目录旁的 native 子目录；② 同级；
  /// ③④⑤⑥ 开发形态下仓库源码树的 dotnet build 产物（csproj 钉
  /// RuntimeIdentifier win-x64 时产物在 RID 子目录下，两种形态都探测）。
  static List<String> candidatePaths(String runnerExeDir) {
    List<String> repoCandidate(String buildMode, {bool rid = false}) {
      final segments = [
        runnerExeDir,
        '..',
        '..',
        '..',
        '..',
        '..',
        'windows',
        'runner',
        'native_host',
        'OnePanelNativeHost',
        'bin',
        buildMode,
        'net8.0-windows10.0.19041.0',
        if (rid) 'win-x64',
        _hostFileName,
      ];
      return segments;
    }

    return [
      p.join(runnerExeDir, 'native', _hostFileName),
      p.join(runnerExeDir, _hostFileName),
      p.joinAll(repoCandidate('Debug', rid: true)),
      p.joinAll(repoCandidate('Debug')),
      p.joinAll(repoCandidate('Release', rid: true)),
      p.joinAll(repoCandidate('Release')),
    ];
  }

  /// 拉起宿主进程；未找到 exe 或非 Windows 平台返回 false。
  Future<bool> launch() async {
    if (!Platform.isWindows) {
      return false;
    }
    final runnerExeDir =
        _runnerExeDir ?? p.dirname(Platform.resolvedExecutable);
    for (final candidate in candidatePaths(runnerExeDir)) {
      if (_exists(candidate)) {
        await _startProcess(candidate);
        return true;
      }
    }
    return false;
  }
}

Future<void> _defaultStartProcess(String executablePath) async {
  await Process.start(
    executablePath,
    const [],
    workingDirectory: p.dirname(executablePath),
    mode: ProcessStartMode.detached,
  );
}
