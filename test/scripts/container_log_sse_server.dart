import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// B73 真实链路测试用的本地 1Panel 日志服务。
///
/// HTTP 协议由 `dart:io` 的 [HttpServer] 实现，本文件只负责 1Panel 的业务
/// 响应：`/api/v2/containers/search/log` 按上游格式推送 SSE（普通帧
/// `data: <base64>`，失败帧 `event: error` 加明文），
/// `/api/v2/containers/download/log` 返回纯文本快照，
/// `/status` 返回连接与断开统计，供测试断言客户端取消真的关闭了连接。
///
/// 用法：`dart run test/scripts/container_log_sse_server.dart <url 文件> <场景文件>`
/// 写好 url 文件后常驻运行。场景文件每行一条指令：
/// `log:<text>`、`error:<text>`、`hold`、`eof`，`:name` 行设置容器名。
class ContainerLogSseServer {
  ContainerLogSseServer(this.statusFile, this.scenarioFile, {this.port = 0});

  final File statusFile;
  final File scenarioFile;
  /// 期望端口；0 表示由系统分配。测试用固定端口，模拟器测试宿主不需要
  /// 读取宿主环境变量即可定位服务。
  final int port;

  final Map<String, _ActiveStream> _active = <String, _ActiveStream>{};
  int _started = 0;
  int _closedByClient = 0;
  int _closedByServer = 0;
  /// 快照响应体；null 表示返回 500，用于验证失败路径。
  String? _snapshotBody;

  Future<void> start() async {
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      port,
      shared: false,
    );
    final baseUrl = 'http://127.0.0.1:${server.port}';
    await statusFile.writeAsString(baseUrl);
    stdout.writeln('listening $baseUrl');
    await for (final request in server) {
      unawaited(_handle(request));
    }
  }

  Future<void> _handle(HttpRequest request) async {
    final path = request.uri.path;
    if (path == '/status') {
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(<String, Object?>{
        'started': _started,
        'closedByClient': _closedByClient,
        'closedByServer': _closedByServer,
        'active': _active.keys.toList(),
      }));
      await request.response.close();
      return;
    }
    // 测试用例逐例设置响应脚本与快照行为。
    if (path == '/scenario' && request.method == 'POST') {
      final body = await utf8.decodeStream(request);
      await scenarioFile.writeAsString(body);
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }
    if (path == '/snapshot' && request.method == 'POST') {
      final body = await utf8.decodeStream(request);
      // 空请求体表示让服务端按生产失败路径返回 500。
      _snapshotBody = body.isEmpty ? null : body;
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }
    if (path == '/api/v2/containers/search/log') {
      await _streamLogs(request);
      return;
    }
    if (path == '/api/v2/containers/download/log') {
      await _snapshot(request);
      return;
    }
    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }

  Future<void> _snapshot(HttpRequest request) async {
    // `snapshotBody == null` 表示按生产服务端行为返回 500，用于验证失败路径。
    final body = _snapshotBody;
    if (body == null) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('snapshot unavailable');
      await request.response.close();
      return;
    }
    request.response.headers.contentType =
        ContentType('text', 'plain', charset: 'utf-8');
    request.response.write(body);
    await request.response.close();
  }

  Future<void> _streamLogs(HttpRequest request) async {
    final container = request.uri.queryParameters['container'] ?? '';
    _started += 1;
    final stream = _ActiveStream(container);
    _active[container] = stream;
    request.response.headers.contentType = ContentType('text', 'event-stream');
    request.response.bufferOutput = false;
    // 检测客户端断开：周期性写注释行，写入失败即连接已由调用方取消。
    final heartbeat = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (stream.closed) return;
      try {
        request.response.write(': ping\n\n');
      } catch (_) {
        stream.closeByClient();
      }
    });
    stream.onCloseByClient = () {
      _closedByClient += 1;
      _active.remove(container);
    };
    stream.onCloseByServer = () {
      _closedByServer += 1;
      _active.remove(container);
    };

    try {
      for (final step in await _readScenario()) {
        if (stream.closed) break;
        switch (step.type) {
          case 'log':
            final bytes = base64Encode(utf8.encode(step.text));
            request.response.write('data: $bytes\n\n');
          case 'error':
            request.response.write('event: error\ndata: ${step.text}\n\n');
          case 'hold':
            await Future<void>.delayed(const Duration(seconds: 3));
          case 'eof':
            break;
        }
        await request.response.flush();
        if (step.type == 'eof') break;
      }
      if (!stream.closed) {
        stream.closeByServer();
      }
    } catch (_) {
      stream.closeByClient();
    } finally {
      heartbeat.cancel();
      try {
        await request.response.close();
      } catch (_) {
        stream.closeByClient();
      }
    }
  }

  Future<List<_Step>> _readScenario() async {
    final text = await scenarioFile.readAsString();
    final steps = <_Step>[];
    for (final line in const LineSplitter().convert(text)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      if (trimmed == 'hold') {
        steps.add(const _Step('hold', ''));
      } else if (trimmed == 'eof') {
        steps.add(const _Step('eof', ''));
      } else if (trimmed.startsWith('log:')) {
        steps.add(_Step('log', _decodeEscapes(trimmed.substring(4))));
      } else if (trimmed.startsWith('error:')) {
        steps.add(_Step('error', _decodeEscapes(trimmed.substring(6))));
      }    }
    return steps;
  }
}

class _Step {
  const _Step(this.type, this.text);

  final String type;
  final String text;
}

/// 场景文件每行一条指令，行内不能含真实换行；`\n` 转义在这里还原。
///
/// 日志内容本身常带换行，转义写法让一条指令保持单行。
String _decodeEscapes(String raw) =>
    raw.replaceAll(r'\n', '\n').replaceAll(r'\t', '\t');

class _ActiveStream {
  _ActiveStream(this.container);

  final String container;
  bool closed = false;
  void Function()? onCloseByClient;
  void Function()? onCloseByServer;

  void closeByClient() {
    if (closed) return;
    closed = true;
    onCloseByClient?.call();
  }

  void closeByServer() {
    if (closed) return;
    closed = true;
    onCloseByServer?.call();
  }
}

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln(
      'usage: container_log_sse_server.dart <url-file> <scenario-file> [port]',
    );
    exit(64);
  }
  final port = args.length >= 3 ? int.parse(args[2]) : 0;
  final server = ContainerLogSseServer(
    File(args[0]),
    File(args[1]),
    port: port,
  );
  await server.start();
}