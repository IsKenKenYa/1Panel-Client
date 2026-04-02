# 修复服务器详情页面磁盘信息显示问题

## Introduction

在服务器详情页面（Server Detail Page），磁盘使用率显示为"--"，而CPU、内存、负载等其他指标均能正常显示。通过调试脚本 `test/debug/dashboard_disk_debug.dart` 验证，Dashboard API (`/api/v2/dashboard/base`) 返回的数据结构正确且包含完整的磁盘信息，但当前实现使用的 Monitor API (`/api/v2/hosts/monitor/search`) 未能正确提供磁盘数据。

**测试环境**：小米13, MIUI 14, v0.5.0-alpha.1+1, HTTPS + 域名 + 证书

**影响范围**：所有使用服务器详情页面查看磁盘使用率的用户

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN 用户打开服务器详情页面 THEN 磁盘信息显示为"--"而非实际百分比

1.2 WHEN ServerRepository.loadServerMetrics 调用 MonitorRepository.getCurrentMetrics 获取监控数据 THEN 返回的 MonitorMetricsSnapshot.diskPercent 为 null

1.3 WHEN Monitor API (`/api/v2/hosts/monitor/search`) 返回响应 THEN diskData 字段可能缺失或为空数组

### Expected Behavior (Correct)

2.1 WHEN 用户打开服务器详情页面 THEN 磁盘信息 SHALL 显示实际的使用百分比（例如："51.6%"）

2.2 WHEN ServerRepository.loadServerMetrics 获取监控数据 THEN 返回的 ServerMetricsSnapshot.diskPercent SHALL 包含有效的磁盘使用百分比值

2.3 WHEN 系统获取服务器指标 THEN SHALL 使用 Dashboard API (`/api/v2/dashboard/base/default/default`) 获取当前快照数据，该API已验证返回正确的磁盘数据结构：
```json
{
  "data": {
    "currentInfo": {
      "diskData": [
        {
          "path": "/",
          "device": "/dev/vda2",
          "type": "ext4",
          "total": 42156257280,
          "used": 20793126912,
          "free": 19521269760,
          "usedPercent": 51.57742302625523
        }
      ]
    }
  }
}
```

### Unchanged Behavior (Regression Prevention)

3.1 WHEN 用户查看服务器详情页面的CPU使用率 THEN 系统 SHALL CONTINUE TO 正确显示CPU百分比

3.2 WHEN 用户查看服务器详情页面的内存使用率 THEN 系统 SHALL CONTINUE TO 正确显示内存百分比

3.3 WHEN 用户查看服务器详情页面的系统负载 THEN 系统 SHALL CONTINUE TO 正确显示负载值

3.4 WHEN 用户刷新服务器详情页面 THEN 系统 SHALL CONTINUE TO 更新所有指标数据

3.5 WHEN 系统需要获取历史监控数据或时间序列数据 THEN 系统 SHALL CONTINUE TO 使用 MonitorRepository 的相关方法

## Bug Condition & Property

### Bug Condition Function

```pascal
FUNCTION isBugCondition(X)
  INPUT: X of type ServerMetricsRequest
  OUTPUT: boolean
  
  // 当使用 Monitor API 获取服务器指标时触发bug
  RETURN X.apiEndpoint = "/api/v2/hosts/monitor/search" 
         AND X.requestedMetrics CONTAINS "diskPercent"
END FUNCTION
```

### Property Specification - Fix Checking

```pascal
// Property: 磁盘信息正确显示
FOR ALL X WHERE isBugCondition(X) DO
  result ← loadServerMetrics'(X.serverId)
  ASSERT result.diskPercent IS NOT NULL
  ASSERT result.diskPercent >= 0 AND result.diskPercent <= 100
  ASSERT UI_displays(result.diskPercent) != "--"
END FOR
```

### Property Specification - Preservation Checking

```pascal
// Property: 其他指标不受影响
FOR ALL X WHERE NOT isBugCondition(X) DO
  ASSERT loadServerMetrics(X) = loadServerMetrics'(X)
END FOR

// Property: CPU、内存、负载指标保持正常
FOR ALL serverId DO
  oldMetrics ← loadServerMetrics(serverId)
  newMetrics ← loadServerMetrics'(serverId)
  ASSERT newMetrics.cpuPercent = oldMetrics.cpuPercent
  ASSERT newMetrics.memoryPercent = oldMetrics.memoryPercent
  ASSERT newMetrics.load = oldMetrics.load
END FOR
```

## Root Cause Analysis

**数据流路径**：
1. `ServerDetailHeaderCard` (UI) → 显示磁盘信息
2. `ServerRepository.loadServerMetrics` → 调用监控数据获取
3. `MonitorRepository.getCurrentMetrics` → 调用 Monitor API
4. Monitor API (`/api/v2/hosts/monitor/search`) → 返回数据结构与 Dashboard API 不同

**问题根源**：
- Monitor API 的响应格式：`data[].param.value[].diskData`
- Dashboard API 的响应格式：`data.currentInfo.diskData`
- Monitor API 可能未返回 diskData 或数据格式不匹配
- Dashboard API 已验证返回正确且完整的磁盘数据

**推荐修复方案**：使用 Dashboard API 替代 Monitor API 获取当前快照数据
- Dashboard API 专门设计用于获取当前快照数据
- 数据结构更简单直接
- 已通过调试脚本验证服务器返回正确的磁盘数据

## Counterexample

**输入**：
- 服务器ID: "test-server-001"
- 服务器配置：URL = "https://panel.example.com", API Key = "valid-key"
- 真实磁盘使用率：51.6%

**当前行为（F）**：
```dart
final metrics = await serverRepository.loadServerMetrics("test-server-001");
// metrics.diskPercent = null
// UI 显示: "磁盘: --"
```

**期望行为（F'）**：
```dart
final metrics = await serverRepository.loadServerMetrics("test-server-001");
// metrics.diskPercent = 51.6
// UI 显示: "磁盘: 51.6%"
```

## Related Files

- `lib/features/server/server_repository.dart` - 加载服务器指标的入口
- `lib/data/repositories/monitor_repository.dart` - Monitor API 调用
- `lib/data/repositories/dashboard_repository.dart` - Dashboard API 调用（需要添加方法）
- `lib/features/server/widgets/server_detail_header_card.dart` - UI 显示组件
- `lib/features/server/server_models.dart` - 数据模型
- `test/debug/dashboard_disk_debug.dart` - 调试验证脚本
