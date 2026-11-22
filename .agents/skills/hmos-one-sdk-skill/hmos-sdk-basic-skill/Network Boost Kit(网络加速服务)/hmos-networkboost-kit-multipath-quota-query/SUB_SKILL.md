---
name: hmos-networkboost-kit-multipath-quota-query
description: 查询应用多网配额使用情况，获取已使用和剩余配额次数及时长，需申请ohos.permission.LINKTURBO权限，配额以24小时周期刷新，适用于多网加速场景配额管理和优化
---

# 多网配额查询技能

## 功能描述

本技能提供HarmonyOS应用多网配额查询能力，通过调用`netHandover.getMultiPathQuotaStats()`接口获取当前应用的多网并发配额使用情况。返回已使用配额（次数和时长）和剩余配额（次数和时长），帮助应用合理分配多网加速资源。

**核心能力**：
- 获取已使用多网配额次数和时长
- 获取剩余多网配额次数和时长
- 配额24小时周期刷新机制
- 配额耗尽限制使用提示

**限制条件**：
- 需申请`ohos.permission.LINKTURBO`权限
- API版本要求：6.0.0(20)及以上
- 配额周期为24小时自动刷新
- 配额耗尽后请求多网会抛出错误码

## 使用场景

### 触发词
- "查询多网配额"
- "获取多网配额"
- "多网配额查询"
- "配额使用情况"
- "剩余配额查询"
- "多网加速配额"

### 能做
- 查询当前应用多网配额使用情况
- 获取已使用配额次数和时长信息
- 获取剩余配额次数和时长信息
- 在配额耗尽前合理规划多网使用策略
- 监控配额使用状态优化资源分配

### 绝不做
- 不增加或修改配额数值（配额由系统管理）
- 不清空已使用配额（配额24小时自动刷新）
- 不绕过配额限制强制使用多网
- 不处理其他NetworkBoost Kit功能（如连接迁移、多网请求等）

### 补充
- 配额包括次数配额和时长配额两种类型
- 配额耗尽后请求多网会返回错误码1013620004
- 建议在发起多网请求前先查询配额情况
- 配额查询不影响实际配额使用

## 调用规范和规则

### 输入约束
- 无需输入参数
- 调用前需确认已申请`ohos.permission.LINKTURBO`权限
- 调用前需确认API版本≥6.0.0(20)

### 执行约束
- 调用方式：同步调用，立即返回结果
- 调用频次：无限制，可根据需要随时查询
- 最大耗时：通常<100ms
- 权限校验：必须具备`ohos.permission.LINKTURBO`权限

### 内容约束
- 禁止伪造配额数据
- 禁止篡改配额信息
- 禁止推测配额刷新时间（由系统管理）
- 必须使用官方API接口获取配额

### 降级约束
- 权限校验失败：提示用户申请`ohos.permission.LINKTURBO`权限
- API版本不支持：提示用户升级系统版本至6.0.0(20)及以上
- 内部处理异常：记录错误日志，提示用户稍后重试
- 系统处理异常：检查网络管理服务状态，重启应用后重试

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认已申请`ohos.permission.LINKTURBO`权限
2. 确认系统版本≥6.0.0(20)
3. 导入必要模块：`@kit.NetworkBoostKit`和`@kit.BasicServicesKit`

**权限配置示例**：
```json
// module.json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.LINKTURBO",
        "reason": "$string:linkturbo_reason"
      }
    ]
  }
}
```

**参数准备**：
```typescript
// 导入必要模块
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2：调用API获取配额

**示例代码**：
```typescript
/**
 * 查询多网配额使用情况
 * @returns 返回配额信息，包括已使用和剩余配额
 */
function queryMultiPathQuota(): netHandover.MultiPathQuota {
  try {
    // 调用同步接口获取配额信息
    const quota: netHandover.MultiPathQuota = netHandover.getMultiPathQuotaStats();
    
    // 输出已使用配额信息
    console.info('[QuotaQuery] 已使用配额次数: ' + quota.used.count);
    console.info('[QuotaQuery] 已使用配额时长(秒): ' + quota.used.duration);
    
    // 输出剩余配额信息
    console.info('[QuotaQuery] 剩余配额次数: ' + quota.remaining.count);
    console.info('[QuotaQuery] 剩余配额时长(秒): ' + quota.remaining.duration);
    
    return quota;
  } catch (err) {
    const error = err as BusinessError;
    console.error('[QuotaQuery] 查询失败 - 错误码: ' + error.code + ', 错误信息: ' + error.message);
    throw error;
  }
}
```

### 步骤3：错误处理

**错误处理代码**：
```typescript
/**
 * 安全查询多网配额，包含完整错误处理
 */
function safeQueryQuota(): void {
  try {
    const quota = queryMultiPathQuota();
    
    // 检查配额是否充足
    if (quota.remaining.count <= 0 || quota.remaining.duration <= 0) {
      console.warn('[QuotaQuery] 配额已耗尽，请等待24小时后自动刷新');
      // 提示用户配额不足或调整使用策略
    }
    
  } catch (err) {
    const error = err as BusinessError;
    
    // 根据错误码进行针对性处理
    switch (error.code) {
      case 201:
        console.error('[QuotaQuery] 权限校验失败，请申请ohos.permission.LINKTURBO权限');
        break;
      case 1013600001:
        console.error('[QuotaQuery] 内部处理异常，请稍后重试');
        break;
      case 1013600002:
        console.error('[QuotaQuery] 系统处理异常，请检查网络管理服务状态');
        break;
      default:
        console.error('[QuotaQuery] 未知错误: ' + error.message);
    }
  }
}
```

### 步骤4：降级处理

**降级处理代码**：
```typescript
/**
 * 配额查询降级方案
 */
function fallbackQuotaQuery(): void {
  try {
    // 主方案：直接查询配额
    const quota = queryMultiPathQuota();
    processQuotaInfo(quota);
  } catch (err) {
    const error = err as BusinessError;
    
    if (error.code === 201) {
      // 降级方案1：提示申请权限
      console.warn('[QuotaQuery] 降级方案：请先申请ohos.permission.LINKTURBO权限');
      showPermissionRequestDialog();
    } else if (error.code === 801) {
      // 降级方案2：提示升级系统版本
      console.warn('[QuotaQuery] 降级方案：当前系统版本不支持，请升级至6.0.0(20)及以上');
      showVersionUpgradePrompt();
    } else {
      // 降级方案3：使用默认策略
      console.warn('[QuotaQuery] 降级方案：使用保守的多网使用策略');
      useConservativeStrategy();
    }
  }
}

/**
 * 处理配额信息
 */
function processQuotaInfo(quota: netHandover.MultiPathQuota): void {
  // 根据配额情况调整多网使用策略
  const remainingRatio = quota.remaining.count / (quota.used.count + quota.remaining.count);
  
  if (remainingRatio < 0.2) {
    console.warn('[QuotaQuery] 配额剩余不足20%，建议减少多网使用频率');
  } else if (remainingRatio < 0.5) {
    console.info('[QuotaQuery] 配额剩余约50%，合理使用多网加速');
  } else {
    console.info('[QuotaQuery] 配额充足，可正常使用多网加速');
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限校验失败 | 在module.json5中申请`ohos.permission.LINKTURBO`权限 |
| 1013600001 | 内部处理异常（如状态机异常） | 记录日志，稍后重试；检查应用状态是否正常 |
| 1013600002 | 系统处理异常（如IPC失败、服务启动失败） | 检查网络管理服务状态，重启应用或设备 |
| 801 | 设备不支持该API | 确认系统版本≥6.0.0(20)，提示用户升级系统 |

**配额耗尽相关错误码**（在请求多网时可能遇到）：
| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1013620004 | 配额耗尽，无法发起多网请求 | 等待24小时配额自动刷新，或调整使用策略减少多网使用 |

## 编译和修复问题

### 依赖声明
```json
// oh-package.json5
{
  "dependencies": {
    "@kit.NetworkBoostKit": "^6.0.0",
    "@kit.BasicServicesKit": "^6.0.0"
  }
}
```

### 环境要求
- HarmonyOS系统版本：≥6.0.0(20)
- DevEco Studio版本：≥5.0.0
- SDK API版本：≥12

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.NetworkBoostKit'
```
**解决方法**：
1. 检查SDK版本是否≥12
2. 在DevEco Studio中更新SDK至最新版本
3. 确认oh-package.json5中已声明依赖

**问题2：权限未配置**
```
Error: Permission denied: ohos.permission.LINKTURBO
```
**解决方法**：
1. 在module.json5的requestPermissions中添加权限声明
2. 提供权限申请理由（reason字段）
3. 对于敏感权限，可能需要用户动态授权

**问题3：API版本不支持**
```
Error: API not supported on this device
```
**解决方法**：
1. 确认设备系统版本≥6.0.0(20)
2. 使用条件编译或版本检查适配低版本设备
3. 提示用户升级系统版本

**问题4：类型定义缺失**
```
Error: Property 'MultiPathQuota' does not exist on type 'netHandover'
```
**解决方法**：
1. 确认导入语句正确：`import { netHandover } from '@kit.NetworkBoostKit'`
2. 检查SDK版本是否包含该类型定义
3. 使用完整类型路径：`netHandover.MultiPathQuota`

## 常见问题与解决方法

### Q1：查询配额返回空值或异常
**原因**：
- 权限未正确申请或授权
- 系统版本不支持该API
- 网络管理服务未启动

**解决方法**：
1. 检查module.json5权限配置
2. 确认系统版本≥6.0.0(20)
3. 重启应用或设备恢复服务状态

### Q2：配额数值不符合预期
**原因**：
- 配额由系统统一管理，不同应用配额可能不同
- 配额24小时周期刷新，刷新时间由系统决定
- 配额消耗规则由系统定义

**解决方法**：
1. 理解配额是系统资源，由系统统一分配
2. 通过查询配额合理规划使用策略
3. 不要尝试修改或伪造配额数值

### Q3：配额耗尽后如何处理
**原因**：
- 已达到配额次数或时长上限
- 24小时周期内配额使用完毕

**解决方法**：
1. 等待24小时系统自动刷新配额
2. 在配额耗尽前合理规划多网使用频率和时长
3. 配额不足时减少多网加速使用，优先使用单网传输
4. 监控配额使用情况，提前预警

### Q4：如何判断是否应该发起多网请求
**原因**：
- 需要评估配额充足性和业务需求

**解决方法**：
1. 先调用`getMultiPathQuotaStats()`查询剩余配额
2. 判断剩余配额是否满足业务需求（次数和时长）
3. 配额充足时才发起多网请求，避免配额耗尽错误
4. 根据业务优先级合理分配配额资源

### Q5：多应用场景配额冲突如何处理
**原因**：
- 多个应用共享系统配额资源
- 配额分配策略由系统决定

**解决方法**：
1. 理解配额是应用级别资源，各应用独立配额
2. 各应用独立查询和管理自身配额
3. 高优先级应用可适当增加配额使用频率
4. 低优先级应用减少配额占用，释放资源

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "quotaInfo": {
    "used": {
      "count": 5,
      "duration": 1200
    },
    "remaining": {
      "count": 10,
      "duration": 2400
    }
  },
  "quotaRatio": "33.3%",
  "quotaStatus": "充足",
  "recommendation": "可正常使用多网加速",
  "apiUsed": [
    "netHandover.getMultiPathQuotaStats()"
  ],
  "timestamp": "2026-07-03T10:30:00Z"
}
```

**字段说明**：
- `status`: 查询状态（success/failed）
- `quotaInfo`: 配额详细信息（已使用和剩余）
- `quotaRatio`: 已使用配额占比
- `quotaStatus`: 配额状态评估（充足/不足/耗尽）
- `recommendation`: 使用建议
- `apiUsed`: 使用的API列表
- `timestamp`: 查询时间戳

## 参考文档

- [多网配额查询开发指南](networkboost-netmultipath-getmultipathquota.md)
- [netHandover API参考说明](networkboost-nethandover.md)

## 完整示例代码

- [ArkTS完整示例代码](get_multipath_quota_example.ets)
- [权限配置示例](permission_config.json)

## 测试用例

### 正向测试用例
- [基础配额查询测试](test_query_quota_basic.ets)：验证配额查询基本功能
- [配额充足场景测试](test_quota_sufficient.ets)：验证配额充足时的正常使用
- [配额不足预警测试](test_quota_warning.ets)：验证配额不足时的预警机制

### 边界测试用例
- [配额耗尽边界测试](test_quota_exhausted.ets)：验证配额接近耗尽时的处理
- [高频查询性能测试](test_high_frequency_query.ets)：验证高频查询的性能表现
- [零配额初始状态测试](test_zero_quota.ets)：验证零配额初始状态的查询

### 异常测试用例
- [权限缺失异常测试](test_permission_missing.ets)：验证权限缺失时的错误处理
- [版本不支持异常测试](test_version_unsupported.ets)：验证低版本设备的降级处理
- [系统服务异常测试](test_service_error.ets)：验证系统异常时的降级方案
- [内部异常处理测试](test_internal_error.ets)：验证内部异常的错误恢复