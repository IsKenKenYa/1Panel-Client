import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/features/files/files_page.dart';
import 'package:onepanel_client/features/files/files_provider.dart';
import 'package:onepanel_client/features/files/files_service.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FilesService])
import '../files_provider_test.mocks.dart';

class _FakeCurrentServerController extends CurrentServerController {
  final ApiConfig _config = ApiConfig(
    id: 's1',
    name: 'Demo',
    url: 'http://demo.test',
    apiKey: 'key',
    allowInsecureTls: true,
    isDefault: true,
  );

  @override
  bool get hasServer => true;

  @override
  ApiConfig? get currentServer => _config;

  @override
  String? get currentServerId => _config.id;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desktop files page builds without stack overflow',
      (tester) async {
    final currentServerController = _FakeCurrentServerController();
    final mockService = MockFilesService();
    when(mockService.getCurrentServer()).thenAnswer(
      (_) async => currentServerController.currentServer,
    );
    when(mockService.getFiles(
      path: anyNamed('path'),
      search: anyNamed('search'),
      page: anyNamed('page'),
      pageSize: anyNamed('pageSize'),
      expand: anyNamed('expand'),
      sortBy: anyNamed('sortBy'),
      sortOrder: anyNamed('sortOrder'),
      showHidden: anyNamed('showHidden'),
    )).thenAnswer(
      (_) async => const [
        FileInfo(
          name: 'demo.txt',
          path: '/demo.txt',
          isDir: false,
          size: 128,
          mode: '0644',
          type: 'file',
          user: 'root',
          group: 'root',
          permission: 'rw-r--r--',
        ),
      ],
    );
    when(mockService.searchFavoriteFiles(path: anyNamed('path')))
        .thenAnswer((_) async => const []);

    final provider = FilesProvider(service: mockService);
    await provider.loadFiles(path: '/');

    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: currentServerController,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FilesPage(
            provider: provider,
            autoInitialize: false,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('demo.txt'), findsOneWidget);
    expect(find.byType(FilesPage), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
    currentServerController.dispose();
    await tester.pump();
  });
}
