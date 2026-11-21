import 'dart:async';

/// 进程与 SSH 会话使用请求驱动的 WebSocket，每次查询完成后安排下一次。
class SessionPoller {
  Timer? _timer;

  void start(
    Future<void> Function() query,
    void Function(Object, StackTrace) onError,
  ) {
    cancel();
    var failed = false;
    void schedule() {
      late final Timer timer;
      timer = Timer(Duration(seconds: failed ? 15 : 3), () async {
        try {
          await query();
          failed = false;
        } catch (error, trace) {
          if (_timer != timer) return;
          if (!failed) onError(error, trace);
          failed = true;
        }
        if (_timer == timer) schedule();
      });
      _timer = timer;
    }

    schedule();
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
