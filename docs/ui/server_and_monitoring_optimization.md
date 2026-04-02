# 服务器列表与监控页面优化

## 优化内容

### 1. 服务器列表页面简化
- 移除了服务器卡片底部的"监控数据已加载"和"查看详情"文本
- 移除了未使用的 `_hasMetrics` 方法
- 移除了未使用的 `scheme` 变量

### 2. 服务器列表自动刷新
- 添加了自动刷新功能，每10秒自动更新服务器监控指标
- 在 `ServerProvider` 中添加了 `Timer` 机制
- 当服务器列表加载完成后自动启动定时刷新
- 在 `dispose` 时正确清理定时器资源

### 3. 监控页面简化
- 移除了顶部工具栏的复杂选择器：
  - 数据点数量选择器（show_chart图标）
  - 刷新间隔选择器（timer图标）
  - 时间范围选择器（history图标）
- 保留了核心功能：
  - 刷新按钮
  - 设置按钮
- 简化了设置对话框：
  - 移除了GPU自动刷新设置
  - 移除了GPU刷新间隔设置
  - 保留了基本的监控开关和数据保留天数设置

### 4. 监控数据解析优化
- 增强了IO数据解析的容错性，支持多种字段名：
  - `disk`, `diskRead`, `diskWrite`, `ioRead`, `ioWrite`
- 增强了网络数据解析的容错性，支持多种字段名：
  - `networkIn`, `up`, `down`, `networkOut`
- 修复了 `parseTimeSeriesResponse` 函数中的 `orElse` 类型错误
- 使用 try-catch 替代 `orElse` 参数以避免类型问题

## 技术细节

### 自动刷新实现
```dart
// ServerProvider
Timer? _metricsRefreshTimer;
static const Duration _metricsRefreshInterval = Duration(seconds: 10);

void startMetricsAutoRefresh() {
  _metricsRefreshTimer?.cancel();
  _metricsRefreshTimer = Timer.periodic(_metricsRefreshInterval, (_) {
    if (_servers.isNotEmpty) {
      loadMetrics();
    }
  });
}
```

### 数据解析容错
```dart
// 尝试从多个可能的字段获取值
double? value;
value = (valueMap[valueKey] as num?)?.toDouble();

if (value == null) {
  if (valueKey == 'disk') {
    value = (valueMap['diskRead'] as num?)?.toDouble() ??
        (valueMap['diskWrite'] as num?)?.toDouble() ??
        (valueMap['ioRead'] as num?)?.toDouble() ??
        (valueMap['ioWrite'] as num?)?.toDouble();
  } else if (valueKey == 'networkIn') {
    value = (valueMap['up'] as num?)?.toDouble() ??
        (valueMap['down'] as num?)?.toDouble() ??
        (valueMap['networkOut'] as num?)?.toDouble();
  }
}
```

## 测试覆盖
- 创建了 `test/features/server/server_list_ui_simplification_test.dart`
- 创建了 `test/features/monitoring/monitoring_page_simplification_test.dart`
- 所有测试通过（7个测试）
- `flutter analyze` 无警告

## 文件变更
- `lib/features/server/server_list_page.dart` - 简化UI，移除冗余文本
- `lib/features/server/server_provider.dart` - 添加自动刷新
- `lib/features/monitoring/monitoring_page.dart` - 简化工具栏和设置
- `lib/data/repositories/monitor_repository.dart` - 增强数据解析容错性
