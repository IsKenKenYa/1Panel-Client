import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/services/native_host_launcher.dart';
import 'package:path/path.dart' as p;

/// B24 回归：UI 渲染模式选「原生模式」后立即拉起 WinUI3 宿主。
/// 候选路径规则与 windows/runner/render_mode_bootstrap.cpp 的
/// ResolveNativeHostExecutablePath 保持一致（顺序即优先级）。
void main() {
  group('NativeHostLauncher.candidatePaths', () {
    test('returns 4 candidates in bootstrap order', () {
      const runnerExeDir = r'C:\repo\build\windows\x64\runner\Debug';

      final candidates = NativeHostLauncher.candidatePaths(runnerExeDir);

      expect(candidates, [
        // ① runner 输出目录旁的 native 子目录（发布形态约定）。
        p.join(runnerExeDir, 'native', 'OnePanelNativeHost.exe'),
        // ② runner 输出目录同级。
        p.join(runnerExeDir, 'OnePanelNativeHost.exe'),
        // ③④ 开发形态：仓库源码树的 dotnet build 产物（Debug/Release）。
        p.join(
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
          'Debug',
          'net8.0-windows10.0.19041.0',
          'OnePanelNativeHost.exe',
        ),
        p.join(
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
          'Release',
          'net8.0-windows10.0.19041.0',
          'OnePanelNativeHost.exe',
        ),
      ]);
    });
  });

  group('NativeHostLauncher.launch', () {
    test('returns false and never starts a process when host exe is absent',
        () {
      var started = <String>[];
      final launcher = NativeHostLauncher(
        exists: (_) => false,
        startProcess: (path) async => started.add(path),
        runnerExeDir: r'C:\repo\build\windows\x64\runner\Debug',
      );

      expect(launcher.launch(), completion(isFalse));
      expect(started, isEmpty);
    });

    test('starts the first existing candidate', () async {
      const existingCandidateIndex = 1;
      final started = <String>[];
      final candidates = NativeHostLauncher.candidatePaths(
        r'C:\repo\build\windows\x64\runner\Debug',
      );
      final launcher = NativeHostLauncher(
        exists: (path) => path == candidates[existingCandidateIndex],
        startProcess: (path) async => started.add(path),
        runnerExeDir: r'C:\repo\build\windows\x64\runner\Debug',
      );

      await expectLater(launcher.launch(), completion(isTrue));
      expect(started, [candidates[existingCandidateIndex]]);
    });
  });
}
