# 实现计划

- [x] 1. 编写 Bug Condition 探索性测试
  - **Property 1: Bug Condition** - Monitor API 磁盘数据缺失
  - **关键**: 此测试必须在未修复代码上失败 - 失败确认 bug 存在
  - **不要尝试修复测试或代码当它失败时**
  - **注意**: 此测试编码了期望行为 - 它将在实现后通过时验证修复
  - **目标**: 暴露反例以证明 bug 存在
  - **作用域 PBT 方法**: 对于确定性 bug，将属性作用域限定为具体失败案例以确保可重现性
  - 测试实现细节来自设计文档中的 Bug Condition
  - 测试断言应匹配设计文档中的 Expected Behavior Properties
  - 在未修复代码上运行测试
  - **预期结果**: 测试失败（这是正确的 - 它证明 bug 存在）
  - 记录发现的反例以理解根本原因
  - 当测试编写、运行并记录失败时标记任务完成
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3_

- [x] 2. 编写保留性属性测试（在实现修复之前）
  - **Property 2: Preservation** - CPU/内存/负载指标保持不变
  - **重要**: 遵循观察优先方法
  - 在未修复代码上观察非 bug 输入的行为
  - 编写属性测试捕获来自 Preservation Requirements 的观察行为模式
  - 属性测试生成许多测试用例以提供更强保证
  - 在未修复代码上运行测试
  - **预期结果**: 测试通过（这确认了要保留的基线行为）
  - 当测试编写、运行并在未修复代码上通过时标记任务完成
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 3. 修复磁盘信息显示问题

  - [x] 3.1 在 DashboardRepository 添加 getCurrentServerMetrics 方法
    - 调用 `getDashboardBase()` 获取 Dashboard API 数据
    - 从 `data.currentInfo` 中提取 CPU、内存、磁盘、负载数据
    - 数据映射逻辑:
      - `currentInfo.cpuUsedPercent` → `cpuPercent`
      - `currentInfo.memoryUsedPercent` → `memoryPercent`
      - `currentInfo.diskData[0].usedPercent` → `diskPercent`（如果 diskData 非空）
      - `currentInfo.load1` → `load`
    - 处理 diskData 为空数组的边界情况（diskPercent 设为 null）
    - 返回 `ServerMetricsSnapshot` 对象
    - 错误处理: 如果 API 调用失败或数据格式异常，返回空的 `ServerMetricsSnapshot`
    - _Bug_Condition: isBugCondition(input) where input.apiEndpoint = "/api/v2/hosts/monitor/search" AND input.requestedMetrics CONTAINS "diskPercent"_
    - _Expected_Behavior: result.diskPercent IS NOT NULL AND result.diskPercent >= 0 AND result.diskPercent <= 100_
    - _Preservation: CPU、内存、负载指标保持正常显示和刷新功能_
    - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 3.4, 3.5_

  - [x] 3.2 修改 ServerRepository.loadServerMetrics 使用 Dashboard API
    - 移除 MonitorRepository 调用: 删除 `monitorRepo.getCurrentMetrics(client)` 调用
    - 添加 DashboardRepository 调用:
      - 实例化 `DashboardRepository`
      - 调用 `dashboardRepo.getCurrentServerMetrics()`
      - 直接返回结果（已经是 `ServerMetricsSnapshot` 类型）
    - 保持错误处理: 维持现有的 try-catch 结构和日志记录
    - 保持返回类型: 方法签名和返回类型完全不变
    - _Bug_Condition: isBugCondition(input) where input.apiEndpoint = "/api/v2/hosts/monitor/search"_
    - _Expected_Behavior: loadServerMetrics 返回有效的 diskPercent 值_
    - _Preservation: CPU、内存、负载指标的获取逻辑保持不变_
    - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 3.4, 3.5_

  - [x] 3.3 验证 bug condition 探索性测试现在通过
    - **Property 1: Expected Behavior** - 磁盘数据正确提取
    - **重要**: 重新运行步骤 1 中的相同测试 - 不要编写新测试
    - 步骤 1 中的测试编码了期望行为
    - 当此测试通过时，它确认期望行为得到满足
    - 运行步骤 1 中的 bug condition 探索性测试
    - **预期结果**: 测试通过（确认 bug 已修复）
    - _Requirements: 2.1, 2.2, 2.3_

  - [x] 3.4 验证保留性测试仍然通过
    - **Property 2: Preservation** - CPU/内存/负载指标保持不变
    - **重要**: 重新运行步骤 2 中的相同测试 - 不要编写新测试
    - 运行步骤 2 中的保留性属性测试
    - **预期结果**: 测试通过（确认没有回归）
    - 确认修复后所有测试仍然通过（没有回归）
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 4. Checkpoint - 确保所有测试通过
  - 确保所有测试通过，如有问题请询问用户
