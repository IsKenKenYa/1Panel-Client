# macOS 服务器删除崩溃修复

## 问题描述

在 macOS 上删除服务器时，应用程序会因 Stack Overflow 错误而崩溃。此问题仅在 macOS 上出现，其他平台不受影响。

## 根本原因

崩溃是由多个问题共同作用引起的：

### 1. 导航期间的 Widget 树重建

在 `ServerDetailPage` 中，页面使用 `context.watch<ServerProvider>()`，这会导致每当 provider 更新时整个页面都会重建。删除服务器时：

1. 用户确认删除
2. `_deleteServer()` 调用 `serverProvider.delete()`
3. `delete()` 调用 `load()` 触发 `notifyListeners()`
4. `context.watch<ServerProvider>()` 检测到变化并触发 `build()`
5. 同时，`navigator.maybePop()` 试图关闭页面
6. 这些操作同时发生，导致 widget 树处于不一致状态
7. 结果：在 `RenderObject.dropChild` 中发生 Stack Overflow

### 2. ServerListViewModel 中的监听器递归

`ServerListViewModel` 有一个可能触发递归更新的监听器：

```dart
_serverProvider.addListener(() => _onProviderUpdated(context));
```

这个监听器会调用 `_onProviderUpdated()`，然后又会调用 `notifyListeners()`，可能创建反馈循环。

### 3. 指标定时器访问已删除的服务器

`ServerProvider` 有一个周期性定时器会尝试为服务器加载指标，包括可能已删除的服务器，导致额外的状态不一致。

### 4. 缺少 Dispose 保护

Provider 在调用 `notifyListeners()` 之前没有检查是否已被 dispose，这可能在清理期间导致问题。

## 解决方案

### 1. 删除前关闭页面

在 `ServerDetailPage._deleteServer()` 中，现在在确认后立即关闭页面，然后再开始删除过程：

```dart
// 先关闭页面以避免删除期间的 widget 树问题
navigator.pop();

await serverProvider.delete(target.config.id);
```

这防止了 widget 树在被拆除时尝试重建。

### 2. 简化 ServerListViewModel 中的监听器

移除了捕获 `BuildContext` 的闭包，替换为简单的转发监听器：

```dart
void _onProviderChanged() {
  // 只通知监听器，不触发引导标记
  notifyListeners();
}
```

引导标记现在仅在初始加载后检查，而不是每次 provider 更新时都检查。

### 3. 删除期间停止指标定时器

`delete()` 方法现在在删除前停止指标刷新定时器，只有在还有剩余服务器时才重新启动：

```dart
Future<void> delete(String id) async {
  stopMetricsAutoRefresh();
  
  try {
    await _repository.removeConfig(id);
    await load();
  } finally {
    if (_servers.isNotEmpty) {
      startMetricsAutoRefresh();
    }
  }
}
```

### 4. 添加 Dispose 保护

添加了 `_isDisposed` 标志，并在整个 provider 中进行检查，以防止 dispose 后的操作：

```dart
bool _isDisposed = false;

Future<void> load() async {
  if (_isDisposed) return;
  // ...
  safeNotifyListeners();
}

@override
void dispose() {
  _isDisposed = true;
  stopMetricsAutoRefresh();
  super.dispose();
}
```

## 修改的文件

- `lib/features/server/server_detail_page.dart` - 删除前关闭页面
- `lib/features/server/view_models/server_list_view_model.dart` - 简化监听器
- `lib/features/server/server_provider.dart` - 添加 dispose 保护和定时器管理

## 测试方法

应用这些修复后：

1. 在 macOS 上运行应用
2. 添加一个服务器
3. 打开服务器详情页面
4. 从详情页面删除服务器
5. 验证应用不会崩溃
6. 验证返回到服务器列表
7. 再添加一个服务器
8. 从服务器列表页面删除它
9. 验证不会发生崩溃
10. 测试文件浏览和其他功能以确保没有回归

## 为什么只在 macOS 上出现？

该问题更容易在 macOS 上出现，原因包括：
- 桌面平台上不同的 widget 重建时序
- macOS 特定的渲染树行为
- 具有多个嵌套 provider 的桌面布局复杂性
- Flutter 在 macOS 上处理导航的时序差异

## 预防措施

为防止将来出现类似问题：

1. **在破坏性操作前关闭页面**：当删除当前页面依赖的项目时，先关闭页面
2. **避免在监听器中捕获 BuildContext**：使用显式方法调用代替
3. **始终检查 dispose 状态**：为执行异步操作的 provider 添加 `_isDisposed` 标志
4. **状态更改前停止定时器**：在修改定时器依赖的数据的操作之前取消周期性定时器
5. **使用 safeNotifyListeners()**：使用 SafeChangeNotifier mixin 防止 dispose 后的通知
6. **在所有平台上测试**：桌面平台的行为可能与移动平台不同
