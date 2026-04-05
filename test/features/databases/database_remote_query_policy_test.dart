import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('remote database search uses engine types instead of remote sentinel',
      () async {
    final source = await File(
      'lib/data/repositories/database_repository.dart',
    ).readAsString();

    expect(
      source.contains("'mysql,mariadb,postgresql,redis,redis-cluster'"),
      isTrue,
    );
    expect(source.contains("type: 'remote'"), isFalse);
    expect(source.contains('.where((item) => item.host?.isNotEmpty == true)'),
        isTrue);
  });
}
