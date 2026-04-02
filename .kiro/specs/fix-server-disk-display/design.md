# 修复服务器详情页面磁盘信息显示问题 - 设计文档

## Overview

本设计文档描述了如何修复服务器详情页面磁盘使用率显示为"--"的问题。通过调试验证，Dashboard API (`/api/v2/dashboard/base`) 返回正确的磁盘数据，而当前使用的 Monitor API (`/api/v2/hosts/monitor/search`) 未能提供有效的磁盘信息。修复方案是在 `DashboardRepository` 中添加新方法获取当前服务器指标，并修改 `ServerRepository.loadServerMetrics` 使用 Dashboard API 替代 Monitor API 获取当前快照数据。

## Glossary

- **Bug_Condition (C)**: 当使用 Monitor API 获取服务器指标且请求包含磁盘数据时触发的条件
- **Property (P)**: 修复后磁盘使用率应显示实际百分比值（如 51.6%）而非"--"
- **Preservation**: CPU、内存、负载等其他指标的显示和刷新功能必须保持不变
- **ServerMetricsSnapshot**: 定义在 `lib/features/server/server_models.dart` 中的数据模型，包含 CPU、内存、磁盘、负载四个指标
- **DashboardRepository**: 定义在 `lib/data/repositories/dashboard_repository.dart` 中的仓库类，负责调用 Dashboard API
- **MonitorRepository**: 定义在 `lib/data/repositories/monitor_repository.dart` 中的仓库类，负责调用 Monitor API 获取监控数据
- **ServerRepository**: 定义在 `lib/features/server/server_repository.dart` 中的仓库类，负责服务器列表管理和指标获取

## Bug Details

### Bug Condition

当用户打开服务器详情页面时，磁盘使用率显示为"--"。`ServerRepository.loadServerMetrics` 方法调用 `MonitorRepository.getCurrentMetrics` 获取监控数据，但返回的 `MonitorMetricsSnapshot.diskPercent` 为 null。Monitor API (`/api/v2/hosts/monitor/search`) 的响应中 diskData 字段可能缺失或为空数组，导致无法提取磁盘使用率。

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type ServerMetricsRequest
  OUTPUT: boolean
  
  RETURN input.apiEndpoint = "/api/v2/hosts/monitor/search"
         AND input.requestedMetrics CONTAINS "diskPercent"
         AND correspondingDiskDataExists()
         AND diskPercentNotExtracted()
END FUNCTION
```

### Examples

- **场景1**: 用户打开服务器详情页面，服务器实际磁盘使用率为 51.6%
  - 期望: 显示"磁盘: 51.6%"
  - 实际: 显示"磁盘: --"

- **场景2**: 用户刷新服务器详情页面，服务器有多个磁盘分区
  - 期望: 显示第一个磁盘的使用率（如"磁盘: 45.2%"）
  - 实际: 显示"磁盘: --"

- **场景3**: 服务器没有磁盘数据（diskData 为空数组）
  - 期望: diskPercent 为 null，显示"磁盘: --"（这是正确的边界情况）

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- CPU 使用率必须继续正确显示实际百分比
- 内存使用率必须继续正确显示实际百分比
- 系统负载（load1）必须继续正确显示数值
- 刷新服务器详情页面时所有指标必须继续更新
- 历史监控数据和时间序列数据的获取必须继续使用 MonitorRepository

**Scope:**
所有不涉及当前服务器指标快照获取的功能应完全不受影响。这包括:
- 服务器列表的显示和管理
- 服务器配置的添加、删除、切换
- 历史监控图表的显示
- 其他使用 MonitorRepository 的功能模块

## Hypothesized Root Cause

基于 bug 描述和调试脚本验证，最可能的问题是:

1. **API 选择不当**: Monitor API 设计用于获取时间序列监控数据，其响应格式复杂（`data[].param.value[].diskData`），可能在某些情况下不返回 diskData 字段

2. **数据解析问题**: MonitorRepository.parseMetricsResponse 在解析 Monitor API 响应时，diskData 字段可能缺失或格式不匹配，导致 diskPercent 为 null

3. **API 数据完整性**: Dashboard API 专门设计用于获取当前快照数据，响应格式简单直接（`data.currentInfo.diskData`），调试脚本已验证其返回正确且完整的磁盘数据

4. **架构设计**: 当前实现混用了两个 API，Dashboard API 用于仪表盘页面，Monitor API 用于服务器详情页面，但 Dashboard API 更适合获取当前快照

## Correctness Properties

Property 1: Bug Condition - 磁盘使用率正确显示

_For any_ 服务器详情页面加载请求，当服务器存在磁盘数据时，修复后的 loadServerMetrics 方法 SHALL 返回有效的 diskPercent 值（0-100 之间的数字），UI SHALL 显示实际的磁盘使用百分比而非"--"。

**Validates: Requirements 2.1, 2.2, 2.3**

Property 2: Preservation - 其他指标显示不变

_For any_ 服务器详情页面加载请求，修复后的 loadServerMetrics 方法 SHALL 返回与原方法相同的 cpuPercent、memoryPercent 和 load 值，保持 CPU、内存、负载指标的正确显示。

**Validates: Requirements 3.1, 3.2, 3.3, 3.4**

## Fix Implementation

### Changes Required

假设我们的根因分析正确，需要进行以下修改:

**File 1**: `lib/data/repositories/dashboard_repository.dart`

**Changes**:
1. **添加新方法 getCurrentServerMetrics**: 调用 `getDashboardBase()` 获取 Dashboard API 数据
   - 从 `data.currentInfo` 中提取 CPU、内存、磁盘、负载数据
   - 返回 `ServerMetricsSnapshot` 对象
   - 处理 diskData 为空数组的边界情况（diskPercent 设为 null）

2. **数据映射逻辑**:
   - `currentInfo.cpuUsedPercent` → `cpuPercent`
   - `currentInfo.memoryUsedPercent` → `memoryPercent`
   - `currentInfo.diskData[0].usedPercent` → `diskPercent`（如果 diskData 非空）
   - `currentInfo.load1` → `load`

3. **错误处理**: 如果 API 调用失败或数据格式异常，返回空的 `ServerMetricsSnapshot`

**File 2**: `lib/features/server/server_repository.dart`

**Function**: `loadServerMetrics`

**Specific Changes**:
1. **移除 MonitorRepository 调用**: 删除 `monitorRepo.getCurrentMetrics(client)` 调用

2. **添加 DashboardRepository 调用**: 
   - 实例化 `DashboardRepository`
   - 调用 `dashboardRepo.getCurrentServerMetrics()`
   - 直接返回结果（已经是 `ServerMetricsSnapshot` 类型）

3. **保持错误处理**: 维持现有的 try-catch 结构和日志记录

4. **保持返回类型**: 方法签名和返回类型完全不变

## Testing Strategy

### Validation Approach

测试策略分为两个阶段：首先在未修复的代码上运行探索性测试以确认 bug 存在并理解根因，然后在修复后验证 bug 已解决且未引入回归。

### Exploratory Bug Condition Checking

**Goal**: 在实施修复前，通过测试确认 bug 存在并验证根因分析。如果测试结果与假设不符，需要重新分析根因。

**Test Plan**: 编写集成测试模拟服务器详情页面加载流程，在未修复的代码上运行以观察失败模式。同时运行调试脚本验证 Dashboard API 返回正确数据。

**Test Cases**:
1. **Monitor API 磁盘数据缺失测试**: 调用 `MonitorRepository.getCurrentMetrics`，验证返回的 diskPercent 为 null（将在未修复代码上失败）
2. **Dashboard API 磁盘数据完整性测试**: 运行 `test/debug/dashboard_disk_debug.dart`，验证 Dashboard API 返回完整的 diskData（应该通过）
3. **ServerRepository 当前行为测试**: 调用 `ServerRepository.loadServerMetrics`，验证返回的 diskPercent 为 null（将在未修复代码上失败）
4. **边界情况测试**: 模拟 diskData 为空数组的情况，验证 diskPercent 应为 null（这是正确行为）

**Expected Counterexamples**:
- Monitor API 响应中 diskData 字段缺失或为空
- MonitorRepository.parseMetricsResponse 无法提取 diskPercent
- ServerRepository.loadServerMetrics 返回 diskPercent = null
- UI 显示"磁盘: --"

### Fix Checking

**Goal**: 验证修复后，所有存在磁盘数据的服务器都能正确显示磁盘使用率。

**Pseudocode:**
```
FOR ALL serverId WHERE serverHasDiskData(serverId) DO
  result := loadServerMetrics_fixed(serverId)
  ASSERT result.diskPercent IS NOT NULL
  ASSERT result.diskPercent >= 0 AND result.diskPercent <= 100
  ASSERT UI_displays(result.diskPercent) != "--"
END FOR
```

### Preservation Checking

**Goal**: 验证修复后，CPU、内存、负载等其他指标的显示完全不受影响。

**Pseudocode:**
```
FOR ALL serverId DO
  oldMetrics := loadServerMetrics_original(serverId)
  newMetrics := loadServerMetrics_fixed(serverId)
  ASSERT newMetrics.cpuPercent = oldMetrics.cpuPercent
  ASSERT newMetrics.memoryPercent = oldMetrics.memoryPercent
  ASSERT newMetrics.load = oldMetrics.load
END FOR
```

**Testing Approach**: 属性测试（Property-Based Testing）推荐用于保留性检查，因为:
- 自动生成多种服务器配置和状态的测试用例
- 捕获手动单元测试可能遗漏的边界情况
- 提供强有力的保证：所有非 bug 输入的行为保持不变

**Test Plan**: 首先在未修复代码上观察 CPU、内存、负载的正常显示行为，然后编写属性测试验证修复后这些行为保持一致。

**Test Cases**:
1. **CPU 指标保留测试**: 观察未修复代码的 CPU 显示正常，编写测试验证修复后 CPU 值相同
2. **内存指标保留测试**: 观察未修复代码的内存显示正常，编写测试验证修复后内存值相同
3. **负载指标保留测试**: 观察未修复代码的负载显示正常，编写测试验证修复后负载值相同
4. **刷新功能保留测试**: 验证刷新服务器详情页面后所有指标继续更新

### Unit Tests

- 测试 `DashboardRepository.getCurrentServerMetrics` 方法正确解析 Dashboard API 响应
- 测试 diskData 为空数组时 diskPercent 正确设为 null
- 测试 API 调用失败时返回空的 ServerMetricsSnapshot
- 测试 `ServerRepository.loadServerMetrics` 正确调用 DashboardRepository
- 测试数据映射逻辑：Dashboard API 字段正确映射到 ServerMetricsSnapshot

### Property-Based Tests

- 生成随机服务器配置，验证所有配置下磁盘数据都能正确提取
- 生成随机 Dashboard API 响应（包含不同数量的磁盘），验证解析逻辑健壮性
- 测试边界情况：空 diskData、单磁盘、多磁盘、极端使用率值（0%, 100%）
- 验证 CPU、内存、负载指标在各种场景下保持一致

### Integration Tests

- 测试完整的服务器详情页面加载流程，验证磁盘使用率正确显示
- 测试刷新服务器详情页面，验证所有指标（包括磁盘）都更新
- 测试切换不同服务器，验证每个服务器的磁盘数据独立正确
- 测试网络异常情况下的降级行为（返回空 ServerMetricsSnapshot）
