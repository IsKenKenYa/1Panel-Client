import 'package:flutter/widgets.dart';

/// 当前路由、桌面模块和应用均可见时，允许页面刷新数据。
class PageVisibilityListener extends StatefulWidget {
  const PageVisibilityListener({
    super.key,
    required this.onChanged,
    required this.child,
  });

  final ValueChanged<bool> onChanged;
  final Widget child;

  static bool routeIsVisible(BuildContext context) {
    // Flutter-OH 与 Flutter 共用这个 TickerMode 查询。
    // ignore: deprecated_member_use
    final ticking = TickerMode.of(context);
    final current = ModalRoute.isCurrentOf(context) ?? true;
    return ticking && current;
  }

  @override
  State<PageVisibilityListener> createState() => _PageVisibilityListenerState();
}

class _PageVisibilityListenerState extends State<PageVisibilityListener>
    with WidgetsBindingObserver {
  bool _routeVisible = false;
  bool _foreground = true;
  bool _reportedVisible = false;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeVisible = PageVisibilityListener.routeIsVisible(context);
    if (_scheduled || _reportedVisible == (_routeVisible && _foreground)) {
      return;
    }
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) _reportVisibility();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _reportVisibility();
  }

  void _reportVisibility() {
    final visible = _routeVisible && _foreground;
    if (visible == _reportedVisible) return;
    _reportedVisible = visible;
    widget.onChanged(visible);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_reportedVisible) widget.onChanged(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
