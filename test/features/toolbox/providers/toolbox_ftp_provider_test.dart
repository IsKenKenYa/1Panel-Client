import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/toolbox_models.dart';
import 'package:onepanel_client/features/toolbox/providers/toolbox_ftp_provider.dart';
import 'package:onepanel_client/features/toolbox/services/toolbox_ftp_service.dart';

class _FakeToolboxFtpService extends ToolboxFtpService {
  int loadSnapshotCallCount = 0;
  int syncUsersCallCount = 0;
  int createUserCallCount = 0;
  int updateUserCallCount = 0;
  int deleteUsersCallCount = 0;
  int operateServiceCallCount = 0;

  String? lastKeyword;
  int? lastPage;
  String? lastOperation;
  FtpCreate? lastCreateRequest;
  FtpUpdate? lastUpdateRequest;
  List<int>? lastDeletedIds;

  bool failNextMutation = false;

  void _throwIfNeeded() {
    if (failNextMutation) {
      failNextMutation = false;
      throw Exception('mock ftp mutation failure');
    }
  }

  @override
  Future<ToolboxFtpSnapshot> loadSnapshot({
    int page = 1,
    int pageSize = 50,
    String? keyword,
  }) async {
    loadSnapshotCallCount += 1;
    lastPage = page;
    lastKeyword = keyword;

    final users = List<FtpInfo>.generate(
      pageSize,
      (index) => FtpInfo(
        id: page * 100 + index,
        user: keyword == null ? 'user-$index' : '$keyword-$index',
        path: '/home/user-$index',
      ),
    );

    return ToolboxFtpSnapshot(
      baseInfo: const FtpBaseInfo(status: 'running', baseDir: '/data/ftp'),
      users: users,
    );
  }

  @override
  Future<void> syncUsers() async {
    syncUsersCallCount += 1;
  }

  @override
  Future<void> createUser(FtpCreate request) async {
    _throwIfNeeded();
    createUserCallCount += 1;
    lastCreateRequest = request;
  }

  @override
  Future<void> updateUser(FtpUpdate request) async {
    _throwIfNeeded();
    updateUserCallCount += 1;
    lastUpdateRequest = request;
  }

  @override
  Future<void> deleteUsers(List<int> ids) async {
    _throwIfNeeded();
    deleteUsersCallCount += 1;
    lastDeletedIds = ids;
  }

  @override
  Future<void> operateService(String operation) async {
    _throwIfNeeded();
    operateServiceCallCount += 1;
    lastOperation = operation;
  }
}

void main() {
  test('ToolboxFtpProvider load reads base info and users', () async {
    final service = _FakeToolboxFtpService();
    final provider = ToolboxFtpProvider(service: service);

    await provider.load();

    expect(provider.error, isNull);
    expect(provider.baseInfo.status, 'running');
    expect(provider.users, hasLength(50));
    expect(provider.hasMoreUsers, isTrue);
    expect(service.lastPage, 1);
    expect(service.lastKeyword, isNull);
  });

  test('ToolboxFtpProvider setKeyword resets page and passes filter', () async {
    final service = _FakeToolboxFtpService();
    final provider = ToolboxFtpProvider(service: service);

    await provider.load();
    await provider.nextPage();
    expect(provider.page, 2);

    provider.setKeyword('ops');
    expect(provider.keyword, 'ops');
    expect(provider.page, 1);

    await provider.load();
    expect(service.lastPage, 1);
    expect(service.lastKeyword, 'ops');
  });

  test('ToolboxFtpProvider createUser mutates and refreshes', () async {
    final service = _FakeToolboxFtpService();
    final provider = ToolboxFtpProvider(service: service);
    await provider.load();

    final ok = await provider.createUser(
      const FtpCreate(user: 'ops', password: 'secret', path: '/data/ops'),
    );

    expect(ok, isTrue);
    expect(provider.error, isNull);
    expect(service.createUserCallCount, 1);
    expect(service.lastCreateRequest?.user, 'ops');
    expect(service.loadSnapshotCallCount, 2);
  });

  test('ToolboxFtpProvider syncUsers refreshes data', () async {
    final service = _FakeToolboxFtpService();
    final provider = ToolboxFtpProvider(service: service);

    final ok = await provider.syncUsers();

    expect(ok, isTrue);
    expect(service.syncUsersCallCount, 1);
    expect(service.loadSnapshotCallCount, 1);
  });

  test('ToolboxFtpProvider operation failure exposes error', () async {
    final service = _FakeToolboxFtpService();
    final provider = ToolboxFtpProvider(service: service);
    service.failNextMutation = true;

    final ok = await provider.operateService('stop');

    expect(ok, isFalse);
    expect(provider.error, contains('mock ftp mutation failure'));
    expect(service.operateServiceCallCount, 0);
  });
}
