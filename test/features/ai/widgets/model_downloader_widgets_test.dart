import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/theme/app_theme.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/model_downloader_models.dart';
import 'package:onepanel_client/data/models/setting_models.dart';
import 'package:onepanel_client/features/ai/model_downloader_service.dart';
import 'package:onepanel_client/features/ai/providers/model_downloader_provider.dart';
import 'package:onepanel_client/features/ai/widgets/model_downloader_sections.dart';
import 'package:onepanel_client/features/ai/widgets/model_downloader_settings_sheet.dart';
import 'package:onepanel_client/features/ai/widgets/model_downloader_tab_widget.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _MockModelDownloaderService extends Mock
    implements ModelDownloaderService {}

Widget wrap(Widget child, {ModelDownloaderProvider? provider}) {
  final theme = AppTheme.create(
    ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FE4)),
  );
  final scoped = provider == null
      ? child
      : ChangeNotifierProvider<ModelDownloaderProvider>.value(
          value: provider,
          child: child,
        );
  return MaterialApp(
    theme: theme,
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: scoped),
  );
}

ModelDownloaderProvider emptyProvider() {
  final service = _MockModelDownloaderService();
  when(() => service.searchFeatured(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        family: any(named: 'family'),
        info: any(named: 'info'),
      )).thenAnswer((_) async => const FeaturedModelPage());
  when(() => service.searchTasks(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        status: any(named: 'status'),
        includeLocal: any(named: 'includeLocal'),
      )).thenAnswer((_) async => const PageResult<ModelDownloadTaskItem>(
        items: <ModelDownloadTaskItem>[],
        total: 0,
      ));
  when(() => service.searchLocal(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        info: any(named: 'info'),
        downloadType: any(named: 'downloadType'),
      )).thenAnswer((_) async => const PageResult<LocalModelItem>(
        items: <LocalModelItem>[],
        total: 0,
      ));
  when(() => service.getSettings()).thenAnswer(
    (_) async => const ModelDownloaderSetting(modelDir: '/opt/models'),
  );
  return ModelDownloaderProvider(service: service);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ModelDownloaderTabWidget', () {
    testWidgets('renders the four sections with empty states', (tester) async {
      final provider = emptyProvider();
      addTearDown(provider.dispose);

      await tester.pumpWidget(wrap(
        const ModelDownloaderTabWidget(),
        provider: provider,
      ));
      await tester.pump();

      expect(find.text('推荐模型'), findsOneWidget);
      expect(find.text('模型市场'), findsOneWidget);
      expect(find.text('下载任务'), findsOneWidget);
      expect(find.text('本地模型'), findsOneWidget);

      // 下载设置入口位于四个分区之后，需要滚动到可见区域。
      await tester.scrollUntilVisible(
        find.text('下载设置'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('下载设置'), findsOneWidget);
    });
  });

  group('ModelDownloaderSettingsSheet', () {
    testWidgets('shows the endpoint and token fields', (tester) async {
      final provider = emptyProvider();
      addTearDown(provider.dispose);

      await tester.pumpWidget(wrap(
        const ModelDownloaderSettingsSheet(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      expect(find.text('模型目录'), findsOneWidget);
      expect(find.text('Hugging Face 地址'), findsOneWidget);
      expect(find.text('Hugging Face 令牌'), findsOneWidget);
      expect(find.text('ModelScope 地址'), findsOneWidget);
      expect(find.text('ModelScope 令牌'), findsOneWidget);
    });
  });

  group('Model sections', () {
    testWidgets('featured section shows an empty hint', (tester) async {
      final provider = emptyProvider();
      addTearDown(provider.dispose);
      await provider.loadFeatured();

      await tester.pumpWidget(wrap(
        ModelFeaturedSection(provider: provider),
        provider: provider,
      ));
      await tester.pump();

      expect(find.text('推荐模型'), findsOneWidget);
      expect(find.text('暂无推荐模型'), findsOneWidget);
    });

    testWidgets('tasks section lists a running download', (tester) async {
      final provider = emptyProvider();
      addTearDown(provider.dispose);
      await tester.pumpWidget(wrap(
        ModelTasksSection(provider: provider),
        provider: provider,
      ));
      await tester.pump();

      expect(find.text('下载任务'), findsOneWidget);
    });

    testWidgets('local section shows an empty hint', (tester) async {
      final provider = emptyProvider();
      addTearDown(provider.dispose);

      await tester.pumpWidget(wrap(
        ModelLocalSection(provider: provider),
        provider: provider,
      ));
      await tester.pump();

      expect(find.text('本地模型'), findsOneWidget);
      expect(find.text('暂无本地模型'), findsOneWidget);
    });
  });
}
