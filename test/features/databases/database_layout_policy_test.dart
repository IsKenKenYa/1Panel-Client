import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('database module keeps desktop grid list and split detail layout',
      () async {
    final listSource = await File(
      'lib/features/databases/databases_page.dart',
    ).readAsString();
    final detailSource = await File(
      'lib/features/databases/databases_detail_page.dart',
    ).readAsString();
    final sectionsSource = await File(
      'lib/features/databases/widgets/database_detail_sections_widget.dart',
    ).readAsString();

    expect(listSource.contains('GridView.builder('), isTrue);
    expect(listSource.contains('crossAxisCount: columns'), isTrue);
    expect(
        detailSource.contains('final isWide = constraints.maxWidth >= 1080;'),
        isTrue);
    expect(detailSource.contains('child: Row('), isTrue);
    expect(sectionsSource.contains('_RedisStatusGrid'), isTrue);
    expect(sectionsSource.contains('_InfoTile('), isTrue);
  });
}
