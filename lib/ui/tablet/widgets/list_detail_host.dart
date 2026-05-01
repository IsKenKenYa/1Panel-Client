import 'package:flutter/material.dart';

class ListDetailHost extends StatelessWidget {
  const ListDetailHost({
    super.key,
    required this.listPane,
    required this.detailPane,
    this.listPaneWidth = 320,
    this.isDetailMode = false,
  });

  final Widget listPane;
  final Widget? detailPane;
  final double listPaneWidth;
  final bool isDetailMode;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 600;

    if (isCompact) {
      return isDetailMode && detailPane != null ? detailPane! : listPane;
    }

    return Row(
      children: [
        SizedBox(
          width: listPaneWidth,
          child: listPane,
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: detailPane ?? const Center(child: Text('Select an item')),
        ),
      ],
    );
  }
}
