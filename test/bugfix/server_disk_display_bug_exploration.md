# Bug Condition 探索性测试结果

## Property 1: Bug Condition - Monitor API 磁盘数据缺失

### 测试目标
验证当前实现中磁盘数据显示为"--"的bug存在。

### 测试方法
使用调试脚本 `test/debug/dashboard_disk_debug.dart` 验证真实服务器的API返回数据。

### 测试结果

#### Dashboard API 验证 ✅
运行调试脚本验证 Dashboard API (`/api/v2/dashboard/base/default/default`) 返回正确的磁盘数据：

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

**结论**: Dashboard API 返回完整且正确的磁盘数据 ✅

#### 当前实现验证 ❌
根据代码分析和用户反馈：

1. **ServerRepository.loadServerMetrics** 使用 `MonitorRepository.getCurrentMetrics`
2. **MonitorRepository.getCurrentMetrics** 调用 `/api/v2/hosts/monitor/search` API
3. **Monitor API** 的响应格式与 Dashboard API 不同
4. **结果**: `diskPercent` 为 null，UI 显示 "--"

### 反例 (Counterexample)

**输入**:
- 服务器: 真实1Panel服务器
- 实际磁盘使用率: 51.6%

**当前行为 (Bug)**:
```dart
final metrics = await serverRepository.loadServerMetrics(serverId);
// metrics.diskPercent = null
// UI 显示: "磁盘: --"
```

**期望行为**:
```dart
final metrics = await serverRepository.loadServerMetrics(serverId);
// metrics.diskPercent = 51.6
// UI 显示: "磁盘: 51.6%"
```

### Bug Condition 确认

✅ **Bug 存在**: 磁盘信息显示为 "--"  
✅ **根本原因**: Monitor API 未返回有效的 diskPercent  
✅ **修复方案**: 使用 Dashboard API 替代 Monitor API

### 下一步

继续执行任务 2: 编写保留性属性测试
