import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/ui/routing/ui_target.dart';
import 'package:onepanel_client/ui/routing/ui_target_resolver.dart';

class AdaptiveLayoutSpec {
  const AdaptiveLayoutSpec({
    required this.target,
    required this.size,
  });

  final UiTarget target;
  final Size size;

  bool get isPhone => target.isPhone;
  bool get isTablet => target.isTablet;
  bool get isDesktop => target.isDesktop;
  TabletKind get tabletKind => target.tabletKind;
  double get width => size.width;

  /// 触控目标 ≥48dp：紧凑密度仅桌面生效，移动端保持默认密度。
  VisualDensity get adaptiveDensity =>
      isDesktop ? VisualDensity.compact : VisualDensity.standard;

  static AdaptiveLayoutSpec of(BuildContext context) {
    final size = _WorkspaceSize.of(context);
    return AdaptiveLayoutSpec(
      target: UiTargetResolver.resolve(context, width: size.width),
      size: size,
    );
  }

  EdgeInsets get pagePadding {
    if (isDesktop) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    }
    if (isTablet) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    }
    return AppDesignTokens.pagePadding;
  }

  double get contentMaxWidth {
    if (isDesktop) {
      return 1280;
    }
    if (isTablet) {
      switch (tabletKind) {
        case TabletKind.ipad:
          return 980;
        case TabletKind.androidPad:
        case TabletKind.harmonyPad:
          return 1040;
        case TabletKind.webTablet:
          return 1024;
        case TabletKind.none:
          return 960;
      }
    }
    return width;
  }

  BoxConstraints get dialogConstraints {
    if (isDesktop) {
      return const BoxConstraints(maxWidth: 640);
    }
    if (isTablet) {
      return const BoxConstraints(maxWidth: 720);
    }
    return BoxConstraints(maxWidth: (width - 32).clamp(0.0, 560.0).toDouble());
  }

  EdgeInsets get dialogInsetPadding {
    if (isDesktop) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 24);
    }
    if (isTablet) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 24);
  }

  double get filesBodyMaxWidth {
    if (isDesktop) {
      return 1100;
    }
    if (isTablet) {
      return 980;
    }
    return width;
  }

  double get settingsBodyMaxWidth {
    if (isDesktop) {
      return 900;
    }
    if (isTablet) {
      return 860;
    }
    return width;
  }

  double get dashboardMaxWidth {
    if (isDesktop) {
      return 1280;
    }
    if (isTablet) {
      return 1040;
    }
    return width;
  }

  bool get useTabletSplitScaffold => isTablet && width >= 900;
}

/// 为导航内容区或分栏提供其自身的可用尺寸。
class AdaptiveLayoutViewport extends StatelessWidget {
  const AdaptiveLayoutViewport({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final outer = _WorkspaceSize.of(context);
      return _WorkspaceSize(
        size: Size(
          constraints.hasBoundedWidth ? constraints.maxWidth : outer.width,
          constraints.hasBoundedHeight ? constraints.maxHeight : outer.height,
        ),
        child: child,
      );
    });
  }
}

class _WorkspaceSize extends InheritedWidget {
  const _WorkspaceSize({required this.size, required super.child});

  final Size size;

  static Size of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_WorkspaceSize>()?.size ??
        MediaQuery.sizeOf(context);
  }

  @override
  bool updateShouldNotify(_WorkspaceSize oldWidget) => size != oldWidget.size;
}

class AdaptiveWidthContainer extends StatelessWidget {
  const AdaptiveWidthContainer({
    super.key,
    required this.maxWidth,
    required this.child,
    this.alignment = Alignment.topCenter,
    this.padding,
  });

  final double maxWidth;
  final Widget child;
  final Alignment alignment;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: AdaptiveLayoutViewport(child: child),
    );

    if (padding != null) {
      content = Padding(
        padding: padding!,
        child: content,
      );
    }

    return Align(
      alignment: alignment,
      child: content,
    );
  }
}
