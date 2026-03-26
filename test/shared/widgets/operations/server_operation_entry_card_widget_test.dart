import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/operations_center/widgets/server_operation_entry_card_widget.dart';

void main() {
  testWidgets('ServerOperationEntryCardWidget displays title and reacts to tap',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ServerOperationEntryCardWidget(
            title: 'Test Entry',
            subtitle: 'Sub',
            icon: Icons.ac_unit,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Test Entry'), findsOneWidget);
    await tester.tap(find.byType(ServerOperationEntryCardWidget));
    expect(tapped, isTrue);
  });
}
