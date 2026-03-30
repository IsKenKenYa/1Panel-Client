import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/shared/widgets/log_viewer/log_toolbar.dart';
import 'package:onepanel_client/shared/widgets/log_viewer/log_viewer_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ui_overflow_test_utils.dart';

class _FakeLogViewerController extends LogViewerController {
  String _query;
  int _current;
  final int _total;

  _FakeLogViewerController({
    String query = 'error',
    int current = 1,
    int total = 1200,
  })  : _query = query,
        _current = current,
        _total = total;

  @override
  String get searchQuery => _query;

  @override
  int get totalMatches => _total;

  @override
  int get currentMatchCount => _current;

  @override
  void search(String query) {
    _query = query;
    notifyListeners();
  }

  @override
  int? previousMatch() {
    if (_total <= 0) {
      return null;
    }
    _current = _current > 1 ? _current - 1 : _total;
    notifyListeners();
    return _current - 1;
  }

  @override
  int? nextMatch() {
    if (_total <= 0) {
      return null;
    }
    _current = _current < _total ? _current + 1 : 1;
    notifyListeners();
    return _current - 1;
  }
}

void main() {
  group('LogToolbar overflow guard', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    for (final variant in kCoreOverflowVariants) {
      testWidgets('search suffix stays stable in ${variant.name}',
          (tester) async {
        final controller = _FakeLogViewerController();

        await pumpOverflowHarness(
          tester,
          variant: variant,
          settle: false,
          child: LogToolbar(
            controller: controller,
            onRefresh: () {},
            onScrollToBottom: () {},
            isAutoScrolling: false,
          ),
        );

        await expectNoFlutterExceptions(
          tester,
          reason: 'LogToolbar raised Flutter exceptions for ${variant.name}',
        );

        final counterText =
            '${controller.currentMatchCount}/${controller.totalMatches}';
        final counterFinder = find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == counterText,
        );
        expect(counterFinder, findsOneWidget);

        final counterWidget = tester.widget<Text>(counterFinder);
        expect(counterWidget.maxLines, 1);
        expect(counterWidget.overflow, TextOverflow.ellipsis);
      });
    }
  });
}
