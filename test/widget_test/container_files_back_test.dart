import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/api/v2/container_v2.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/container_docker_models.dart';
import 'package:dio/dio.dart';
import 'package:onepanel_client/features/containers/pages/container_files_page.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

class _MockContainerV2Api extends Mock implements ContainerV2Api {}

ContainerFileInfo _dir(String name) => ContainerFileInfo(
      name: name,
      path: '/$name',
      isDir: true,
      isLink: false,
    );

/// 阶段1-类2 回归：容器文件浏览页与文件模块同款——子路径时 AppBar 显示返回键
/// 且系统返回先回上级目录，而不是直接退出页面。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildHarness(_MockContainerV2Api api) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ContainerFilesPage(
        containerId: 'c1',
        containerName: 'web',
        apiOverride: () async => api,
      ),
    );
  }

  setUpAll(() {
    registerFallbackValue(ContainerFileRequest(
      containerId: 'c1',
      path: '/',
    ));
  });

  testWidgets('子路径下 AppBar 显示返回键且点击回上级目录（类2）', (tester) async {
    final api = _MockContainerV2Api();
    when(() => api.searchContainerFiles(any(that: isA<ContainerFileRequest>()
          .having((r) => r.path, 'path', '/'),
        ))).thenAnswer((_) async => Response<List<ContainerFileInfo>>(
          data: [_dir('etc'), _dir('usr')],
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 200,
        ));
    when(() => api.searchContainerFiles(any(that: isA<ContainerFileRequest>()
          .having((r) => r.path, 'path', '/etc/'),
        ))).thenAnswer((_) async => Response<List<ContainerFileInfo>>(
          data: [_dir('nginx')],
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 200,
        ));

    await tester.pumpWidget(buildHarness(api));
    await tester.pumpAndSettle();

    // 进入子目录 /etc/
    await tester.tap(find.text('etc'));
    await tester.pumpAndSettle();

    // AppBar leading 应为返回键（进入子路径前是根路径，无路由栈 → 无 leading）。
    // 页内面包屑返回按钮（commonBack）与 AppBar 返回键（backButtonTooltip）
    // tooltip 文本同为 "Back" 且同屏，这里断言 Tooltip 总数为 2
    //（leading 返回键 + 面包屑返回按钮），并验证 leading 的 IconButton 可点。
    expect(
      find.byTooltip(MaterialLocalizations.of(
        tester.element(find.byType(ContainerFilesPage).first),
      ).backButtonTooltip),
      findsNWidgets(2),
      reason: '子路径下必须显示返回键（对齐文件模块行为）',
    );

    // 点击 AppBar leading 返回键（第一个 tooltip）→ 回到根目录列表。
    // 面包屑返回按钮与 leading 同 tooltip 文本，tap 需限定第一个匹配。
    await tester.tap(find.byTooltip(MaterialLocalizations.of(
      tester.element(find.byType(ContainerFilesPage).first),
    ).backButtonTooltip).first);
    await tester.pumpAndSettle();
    expect(find.text('usr'), findsOneWidget,
        reason: '返回键应回上级目录，而非退出页面');
  });

  testWidgets('页面 Scaffold 背景显式 surface（类3）', (tester) async {
    final api = _MockContainerV2Api();
    when(() => api.searchContainerFiles(any())).thenAnswer(
      (_) async => Response<List<ContainerFileInfo>>(
        data: const [],
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 200,
      ),
    );

    await tester.pumpWidget(buildHarness(api));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(ContainerFilesPage).first);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(
      scaffold.backgroundColor,
      equals(Theme.of(context).colorScheme.surface),
      reason: 'AGENTS.md：Scaffold 背景必须显式 surface',
    );
  });
}
