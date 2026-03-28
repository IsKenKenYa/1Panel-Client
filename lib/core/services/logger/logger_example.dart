import 'package:flutter/material.dart';
import 'logger_service.dart';

/// 日志使用示例
class LoggerExample {
  /// 示例方法，展示不同级别日志的使用
  static void demonstrateLogging() {
    // Trace级别日志 - 仅在Debug模式输出
    appLogger.tWithPackage('example', '这是一条Trace级别日志，用于追踪详细的执行流程');

    // Debug级别日志 - 仅在Debug模式输出
    appLogger.dWithPackage('example', '这是一条Debug级别日志，用于调试信息');

    // Info级别日志 - 在Debug和Profile模式输出
    appLogger.iWithPackage('example', '这是一条Info级别日志，用于一般信息');

    // Warning级别日志 - 在所有模式输出
    appLogger.wWithPackage('example', '这是一条Warning级别日志，用于警告信息');

    // Error级别日志 - 在所有模式输出
    appLogger.eWithPackage('example', '这是一条Error级别日志，用于错误信息');

    // Fatal级别日志 - 在所有模式输出
    appLogger.fWithPackage('example', '这是一条Fatal级别日志，用于严重错误信息');

    // 带异常和堆栈跟踪的日志
    try {
      // 模拟一个异常
      throw Exception('这是一个示例异常');
    } catch (e, stackTrace) {
      appLogger.eWithPackage('example', '捕获到异常',
          error: e, stackTrace: stackTrace);
    }

    // 对象日志
    final user = {'name': 'John', 'age': 30, 'email': 'john@example.com'};
    appLogger.iWithPackage('example.data', '用户信息: $user');

    // 列表日志
    final items = ['item1', 'item2', 'item3'];
    appLogger.dWithPackage('example.data', '项目列表: $items');

    // 布尔值日志
    final isLoggedIn = true;
    appLogger.iWithPackage('example.data', '用户登录状态: $isLoggedIn');

    // 数字日志
    final count = 42;
    appLogger.dWithPackage('example.data', '计数器值: $count');

    // 空值日志
    final nullableValue = null;
    appLogger.wWithPackage('example.data', '空值检查: $nullableValue');
  }
}

/// 日志使用示例页面
class LoggerExamplePage extends StatelessWidget {
  const LoggerExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志使用示例'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                appLogger.iWithPackage('example.ui', '点击了"演示日志"按钮');
                LoggerExample.demonstrateLogging();
              },
              child: const Text('演示日志'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                appLogger.iWithPackage('example.ui', '点击了"模拟错误"按钮');
                _simulateError();
              },
              child: const Text('模拟错误'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                appLogger.iWithPackage('example.ui', '点击了"网络请求"按钮');
                _simulateNetworkRequest();
              },
              child: const Text('模拟网络请求'),
            ),
          ],
        ),
      ),
    );
  }

  /// 模拟错误
  void _simulateError() {
    try {
      // 模拟一个错误
      throw Exception('这是一个模拟的错误');
    } catch (e, stackTrace) {
      appLogger.eWithPackage('example.error', '模拟错误捕获',
          error: e, stackTrace: stackTrace);
    }
  }

  /// 模拟网络请求
  void _simulateNetworkRequest() {
    appLogger.iWithPackage('example.network', '开始模拟网络请求');

    // 模拟网络请求延迟
    Future.delayed(const Duration(seconds: 2), () {
      appLogger.iWithPackage('example.network', '网络请求完成');

      // 模拟成功响应
      final response = {'status': 'success', 'data': '示例数据'};
      appLogger.dWithPackage('example.network', '网络响应: $response');
    });
  }
}
