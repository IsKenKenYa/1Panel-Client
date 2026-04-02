# 监控页面设置整合与数据修复

## 变更概述

本次更新将之前移除的监控页面功能全部整合到右上角的设置对话框中，并修复了监控数据显示为"--"和图表数据为空的问题。

## 1. 设置对话框功能整合

### 新增/恢复的设置项

所有监控相关设置现在都集中在右上角的设置对话框中（图标：tune）：

1. **监控开关**
   - 启用/禁用监控功能

2. **刷新间隔设置**
   - 选项：3秒、5秒（默认）、10秒、30秒、1分钟
   - 功能：控制监控数据的自动刷新频率

3. **时间范围设置**
   - 选项：最近1小时、最近6小时、最近24小时、最近7天
   - 功能：控制图表显示的时间跨度

4. **数据点数量设置**
   - 选项：6点（30分钟）、12点（1小时）、1000点（全部）
   - 功能：控制图表显示的数据点密度

5. **GPU监控设置**
   - GPU监控开关
   - GPU刷新间隔（5秒、10秒、30秒、1分钟）

6. **数据保留设置**
   - 滑块：1-365天
   - 功能：控制历史数据保留时长

7. **数据清理**
   - 按钮：清理数据
   - 功能：清理历史监控数据

### UI改进

- 设置图标：`Icons.settings` → `Icons.tune`（更符合调整/配置的语义）
- 对话框宽度：200px → 400px（提供更好的布局空间）
- 使用分隔线（Divider）区分不同设置组
- 所有下拉框使用 `initialValue` 替代已弃用的 `value` 参数
- 设置项分组清晰，易于理解

## 2. 监控数据显示修复

### 问题诊断

根据 `docs/development/modules/监控管理/monitor_faq.md` 中的Q11：

**为什么磁盘和负载数据显示为"--"？**

可能原因：
1. 磁盘数据为空：服务器端未配置IO监控
2. 负载字段名错误：字段名可能是 `cpuLoad1` 而不是 `load1`
3. 监控服务未启动

### 解决方案

#### 2.1 使用Dashboard API获取当前指标 ✅

**实现位置**: `lib/features/monitoring/monitoring_service.dart`

**策略**：
1. 优先使用 `GET /api/v2/dashboard/current/default/default`
2. 如果失败，降级使用 `POST /api/v2/hosts/monitor/search`

**优势**：
- Dashboard API 专门用于获取当前实时指标，更可靠
- 数据结构清晰，字段名标准（`cpuPercent`, `memoryPercent`, `diskPercent`, `load1`）
- 不依赖监控历史数据配置

**代码示例**：
```dart
// 优先使用dashboard API
final response = await client.get('/api/v2/dashboard/current/default/default');
final payload = data['data'] as Map<String, dynamic>?;

// 解析磁盘数据
double? diskPercent;
final diskDataList = payload['diskData'] as List?;
if (diskDataList != null && diskDataList.isNotEmpty) {
  final firstDisk = diskDataList.first as Map<String, dynamic>?;
  diskPercent = (firstDisk?['usedPercent'] as num?)?.toDouble();
}

return MonitorMetricsSnapshot(
  cpuPercent: (payload['cpuUsedPercent'] as num?)?.toDouble(),
  memoryPercent: (payload['memoryUsedPercent'] as num?)?.toDouble(),
  diskPercent: diskPercent,
  load1: (payload['load1'] as num?)?.toDouble(),
  // ...
);
```

#### 2.2 增强时间序列数据解析容错性 ✅

**实现位置**: `lib/data/repositories/monitor_repository.dart`

**策略**：
- IO数据支持多种字段名：`disk`, `diskRead`, `diskWrite`, `ioRead`, `ioWrite`
- 网络数据支持多种字段名：`networkIn`, `up`, `down`, `networkOut`
- 使用 try-catch 替代 `orElse` 避免类型问题

**代码示例**：
```dart
// 尝试从多个可能的字段获取值
double? value = (valueMap[valueKey] as num?)?.toDouble();

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

## 3. 文件变更清单

### 修改的文件

1. **lib/features/monitoring/monitoring_page.dart**
   - ✅ 恢复完整的设置对话框（所有功能集成）
   - ✅ 修复 `DropdownButtonFormField` 弃用警告
   - ✅ 更改设置图标为 `Icons.tune`
   - ✅ 优化对话框布局和分组

2. **lib/features/monitoring/monitoring_service.dart**
   - ✅ 添加Dashboard API作为主要数据源
   - ✅ 实现降级策略
   - ✅ 添加日志记录

3. **lib/data/repositories/monitor_repository.dart**
   - ✅ 增强数据解析容错性
   - ✅ 支持多种字段名格式

4. **lib/features/server/server_provider.dart**
   - ✅ 添加自动刷新功能（10秒间隔）

5. **lib/features/server/server_list_page.dart**
   - ✅ 移除冗余文本和未使用代码

### 新增的文件

1. **test/debug/monitor_data_debug.dart**
   - 监控数据调试脚本
   - 用于测试真实API响应

2. **test/features/monitoring/dashboard_api_integration_test.dart**
   - Dashboard API集成测试
   - 验证数据解析和容错性

3. **test/features/server/server_list_ui_simplification_test.dart**
   - 服务器列表UI简化测试

4. **test/features/monitoring/monitoring_page_simplification_test.dart**
   - 监控页面简化测试

5. **docs/ui/monitoring_settings_consolidation.md**
   - 本文档

## 4. API端点使用

### 当前指标获取（修复"--"显示问题）

**端点**: `GET /api/v2/dashboard/current/default/default`
- 返回字段：`cpuUsedPercent`, `memoryUsedPercent`, `diskData[].usedPercent`, `load1`, `load5`, `load15`
- 优点：专门用于实时数据，字段名标准，更可靠

**降级方式**: `POST /api/v2/hosts/monitor/search`
- 参数：`param=all`, `startTime`, `endTime`
- 用途：当Dashboard API不可用时使用

### 时间序列数据获取（修复图表数据为空问题）

**端点**: `POST /api/v2/hosts/monitor/search`
- 参数：`param=all`, `startTime`, `endTime`
- 返回：包含 `base`, `io`, `network` 等多个param的数据数组
- 解析：支持多种字段名，增强容错性

## 5. 测试验证

### 单元测试
```bash
flutter test test/features/server/server_list_ui_simplification_test.dart \
             test/features/monitoring/monitoring_page_simplification_test.dart \
             test/features/monitoring/dashboard_api_integration_test.dart
```

结果：11个测试全部通过 ✅

### 静态分析
```bash
flutter analyze lib/
```

结果：无问题 ✅

## 6. 用户体验改进

### 设置访问
- 所有监控设置集中在右上角的调整图标（tune）
- 一个对话框包含所有配置，避免UI混乱
- 设置分组清晰，使用分隔线区分

### 数据可靠性
- 使用Dashboard API提高当前指标的可靠性
- 多字段名支持确保兼容性
- 优雅降级策略保证稳定性

### 性能优化
- 用户可自定义刷新频率（3秒-1分钟）
- 数据点数量可配置（6-1000点）
- GPU监控可独立控制

## 7. 调试工具

### 使用调试脚本诊断问题

如果监控数据仍然显示异常，可以运行调试脚本查看真实API响应：

```bash
# 1. 配置.env文件
cp .env.example .env
# 编辑.env，设置PANEL_BASE_URL和PANEL_API_KEY

# 2. 运行调试脚本
flutter test test/debug/monitor_data_debug.dart
```

调试脚本会输出：
- 各个param（all, base, io, network）的完整API响应
- 每个响应的数据结构和字段名
- 帮助定位字段名不匹配或数据为空的问题

## 8. 已知限制与解决方案

### 限制1: IO和网络数据依赖后端配置

**现象**: 磁盘IO和网络图表显示"暂无数据"

**原因**: 1Panel服务器端未启用IO/网络监控

**解决方案**:
1. 登录1Panel服务器端
2. 进入监控设置
3. 启用IO监控和网络监控
4. 等待数据采集（通常需要几分钟）

### 限制2: 历史数据需要时间积累

**现象**: 新安装的系统图表数据很少

**原因**: 监控服务刚启动，历史数据未积累

**解决方案**:
- 等待监控服务运行一段时间
- 数据会随时间自动积累
- 可以调整时间范围查看可用数据

### 限制3: 字段名可能因版本而异

**现象**: 某些字段显示为"--"

**原因**: 不同版本的1Panel后端可能使用不同的字段名

**解决方案**:
- 已实现多字段名支持
- 如果仍有问题，运行调试脚本查看实际字段名
- 根据实际字段名更新解析逻辑

## 9. 后续优化建议

1. **添加数据状态指示器**
   - 显示最后更新时间
   - 显示数据来源（Dashboard API / Monitor API）
   - 显示数据质量指标

2. **增强错误提示**
   - 当数据为空时，提供具体的排查建议
   - 链接到相关文档或设置页面
   - 提供一键诊断功能

3. **添加数据导出功能**
   - 支持导出监控数据为CSV/JSON
   - 方便用户进行离线分析

4. **优化图表性能**
   - 实现数据采样算法
   - 使用虚拟滚动
   - 缓存已渲染数据

---

**文档版本**: 1.1  
**创建时间**: 2026-04-02  
**最后更新**: 2026-04-02  
**作者**: Kiro AI Assistant

