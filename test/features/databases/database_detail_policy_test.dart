import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('redis detail does not request generic config file endpoint', () async {
    final source = await File(
      'lib/data/repositories/database_repository.dart',
    ).readAsString();

    expect(
      source.contains(
        "if (item.scope == DatabaseScope.mysql) {\n      rawConfigFile =",
      ),
      isTrue,
    );
    expect(
      source.contains(
        "} else if (item.scope == DatabaseScope.postgresql) {\n      rawConfigFile =",
      ),
      isTrue,
    );
    expect(
      source.contains(
          "} else if (item.scope == DatabaseScope.redis) {\n      status ="),
      isTrue,
    );
  });
}
