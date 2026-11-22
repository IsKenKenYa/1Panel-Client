---
name: hmos-health-service-kit-read-three-ring
description: 读取实时三环活动数据，包括步数、活动热量、锻炼时长、活动小时数及目标数据，需要日常活动数据读权限，适用于健康监测和健身追踪场景
---

# 实时三环数据读取技能

## 功能描述

本技能用于读取HarmonyOS运动健康服务的实时三环数据。实时三环数据包括用户当日的实时步数、活动热量、锻炼时长、活动小时数以及对应的目标数据。该数据可以帮助应用实时展示用户的运动健康状态，适用于健身追踪、健康监测等场景。

**API版本要求**: 从5.1.1(19) Release版本开始支持，支持Wearable设备开发。

## 使用场景

### 触发词
- "读取实时三环数据"
- "获取步数数据"
- "读取活动热量"
- "查询锻炼时长"
- "获取实时活动数据"
- "读取三环数据"

### 能做
- 读取用户当日实时步数及步数目标
- 读取用户当日活动热量及热量目标
- 读取用户当日锻炼时长及时长目标
- 读取用户当日活动小时数及小时数目标
- 提供完整的ActivityReport数据结构

### 绝不做
- 不写入或修改三环数据
- 不读取历史三环数据（仅读取实时当日数据）
- 不处理未授权用户的数据请求
- 不支持未初始化healthStore的调用

### 补充
- 需要先完成Health Service Kit服务申请和Client ID配置
- 必须调用healthStore.init()初始化后才能使用
- 用户必须授权日常活动数据读权限
- stepsGoal、activeCaloriesGoal等目标字段可选，若用户未设置目标则无法读取

## 调用规范和规则

### 输入约束
- 无输入参数要求
- 调用前必须完成healthStore初始化
- 调用前必须获得用户授权

### 执行约束
- 最大耗时: 5秒（API调用）
- 需要网络连接
- 需要用户已登录华为账号
- 需要用户已同意运动健康隐私协议

### 内容约束
- 禁止缓存或持久化存储三环数据
- 禁止在未授权情况下调用API
- 禁止绕过init()直接调用readActivityReport()
- 禁止使用虚假或推测的API参数

### 降级约束
- 权限未授权: 提示用户授权日常活动数据读权限
- 服务未初始化: 提示调用healthStore.init()初始化
- 网络失败: 提示网络异常，建议稍后重试
- 服务异常: 记录错误日志，提示服务暂时不可用

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 检查是否已申请Health Service Kit服务
2. 检查是否已配置Client ID
3. 检查是否已调用healthStore.init()初始化
4. 检查用户是否已授权日常活动数据读权限

**参数准备**:
```typescript
// 无需准备参数，直接调用API
```

### 步骤2: 导入模块

**示例代码**:
```typescript
import { healthService } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
```

### 步骤3: 调用API读取三环数据

**示例代码**:
```typescript
try {
  const result: healthService.workout.ActivityReport = await healthService.workout.readActivityReport();
  hilog.info(0x0000, 'testTag', 'Succeeded in reading ActivityReport');
  
  // 处理返回的三环数据
  const steps = result.steps; // 步数
  const stepsGoal = result.stepsGoal; // 步数目标（可选）
  const activeCalories = result.activeCalories; // 活动热量（单位：卡）
  const activeCaloriesGoal = result.activeCaloriesGoal; // 活动热量目标（可选）
  const exercise = result.exercise; // 锻炼时长（单位：分钟）
  const exerciseGoal = result.exerciseGoal; // 锻炼时长目标（可选）
  const activeHours = result.activeHours; // 活动小时数
  const activeHoursGoal = result.activeHoursGoal; // 活动小时数目标（可选）
  
  // 遍历所有字段
  Object.keys(result).forEach(key => {
    hilog.info(0x0000, 'testTag', `the ${key} is ${result[key]}`);
  });
  
  return result;
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to read ActivityReport. Code: ${err.code}, message: ${err.message}`);
  throw err;
}
```

### 步骤4: 错误处理

**错误处理代码**:
```typescript
try {
  const result = await healthService.workout.readActivityReport();
  // 处理数据...
} catch (error) {
  switch (error.code) {
    case 201:
      hilog.error(0x0000, 'testTag', 'Permission denied. Please request user authorization for daily activity data read permission.');
      // 引导用户授权
      break;
    case 14500101:
      hilog.error(0x0000, 'testTag', 'Service exception. Please try again later.');
      // 服务异常，稍后重试
      break;
    case 1002702001:
      hilog.error(0x0000, 'testTag', 'Account not logged in. Please login with HUAWEI ID.');
      // 引导用户登录
      break;
    case 1002703001:
      hilog.error(0x0000, 'testTag', 'User privacy not agreed. Please launch Health app first.');
      // 引导用户启动运动健康App
      break;
    default:
      hilog.error(0x0000, 'testTag', `Unknown error: ${error.code}, message: ${error.message}`);
      // 处理其他错误
  }
}
```

### 步骤5: 降级处理

**降级处理代码**:
```typescript
async function readThreeRingDataWithFallback(): Promise<healthService.workout.ActivityReport | null> {
  try {
    // 尝试读取三环数据
    const result = await healthService.workout.readActivityReport();
    return result;
  } catch (error) {
    if (error.code === 201) {
      // 权限未授权，引导用户授权
      hilog.warn(0x0000, 'testTag', 'Permission not granted, requesting authorization...');
      // 调用用户授权接口（参考health-add-permissions.md）
      // 重新尝试读取
      try {
        const result = await healthService.workout.readActivityReport();
        return result;
      } catch (retryError) {
        hilog.error(0x0000, 'testTag', 'Failed after authorization request');
        return null;
      }
    } else if (error.code === 14500101) {
      // 服务异常，返回null并提示用户
      hilog.warn(0x0000, 'testTag', 'Service temporarily unavailable');
      return null;
    } else {
      // 其他错误，记录日志
      hilog.error(0x0000, 'testTag', `Unexpected error: ${error.code}`);
      return null;
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限验证失败，缺少日常活动数据读权限 | 参考[管理用户授权](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-add-permissions)引导用户授权 |
| 14500101 | 服务异常 | 稍后重试，若持续失败则通过在线提单反馈 |
| 1002702001 | 账号未登录 | 引导用户登录华为账号后重新调用 |
| 1002703001 | 用户隐私未同意 | 引导用户启动运动健康App同意隐私协议 |
| 401 | 参数不合法 | 检查调用方式是否符合规范 |
| 801 | 设备不支持此API | 确认设备API版本≥5.1.1(19) Release |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.HealthServiceKit": "API 12+"
  }
}
```

### 环境要求
- HarmonyOS API版本: ≥5.1.1(19) Release
- 设备类型: Wearable设备支持
- 开发环境: DevEco Studio 3.1+

### 常见编译问题

**问题1: 模块导入失败**
```
Error: Cannot find module '@kit.HealthServiceKit'
```
**解决方法**: 确认HarmonyOS SDK版本≥API 12，在DevEco Studio中更新SDK

**问题2: 类型定义缺失**
```
Error: Property 'workout' does not exist on type 'healthService'
```
**解决方法**: 确认使用正确的API路径 `healthService.workout.readActivityReport()`

**问题3: 初始化未完成**
```
Error: Service not initialized
```
**解决方法**: 在调用前先执行 `healthStore.init()` 初始化

## 常见问题与解决方法

### Q1: 读取的目标数据为undefined怎么办？
**原因**: 用户未在运动健康App中设置目标值，目标字段为可选字段
**解决方法**: 
- 检查目标字段是否存在（使用可选链操作符）
- 若目标未设置，提示用户在运动健康App中设置目标
- 使用默认值或不显示目标完成度

### Q2: 调用API时提示权限错误（错误码201）
**原因**: 用户未授权日常活动数据读权限
**解决方法**: 
- 参考[管理用户授权](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-add-permissions)引导用户授权
- 使用用户授权接口拉起授权流程
- 授权成功后重新调用API

### Q3: 如何确认healthStore是否已初始化？
**原因**: 未调用init()方法导致服务未就绪
**解决方法**: 
- 在应用启动时调用 `healthStore.init()`
- 等待init()完成后再调用readActivityReport()
- 使用Promise确保初始化顺序

### Q4: 设备不支持此API怎么办？
**原因**: 设备API版本低于5.1.1(19) Release
**解决方法**: 
- 检查设备系统版本是否符合要求
- 在代码中添加API版本判断
- 提示用户升级系统版本

### Q5: 数据读取频率有限制吗？
**原因**: API调用可能受系统限制
**解决方法**: 
- 避免高频重复调用（建议间隔≥1秒）
- 实现合理的调用策略
- 使用缓存机制减少重复调用

## 输出结果报告

执行完成后输出以下信息:

```typescript
{
  "status": "success",
  "data": {
    "steps": number,
    "stepsGoal": number | undefined,
    "activeCalories": number,
    "activeCaloriesGoal": number | undefined,
    "exercise": number,
    "exerciseGoal": number | undefined,
    "activeHours": number,
    "activeHoursGoal": number | undefined
  },
  "apiUsed": [
    "healthService.workout.readActivityReport()"
  ],
  "timestamp": "ISO 8601格式时间戳"
}
```

**数据字段说明**:
- `steps`: 当前步数（必填）
- `stepsGoal`: 步数目标（可选，若用户未设置则为undefined）
- `activeCalories`: 活动热量，单位为卡（必填）
- `activeCaloriesGoal`: 活动热量目标，单位为卡（可选）
- `exercise`: 锻炼时长，单位为分钟（必填）
- `exerciseGoal`: 锻炼时长目标，单位为分钟（可选）
- `activeHours`: 活动小时数（必填）
- `activeHoursGoal`: 活动小时数目标（可选）

## 参考文档

- [API开发指南](references/health-wearable-three-ring-read.md)
- [API参考说明](references/health-api-healthservice.md)
- [申请运动健康服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-apply)
- [配置Client ID](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-configuration-client-id)
- [管理用户授权](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-add-permissions)
- [权限说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-permission-description)
- [错误码参考](references/errorcode-healthservice.md)

## 完整示例代码

- [ArkTS完整示例](assets/example_read_three_ring.ets)
- [初始化示例](assets/example_init.ets)
- [授权检查示例](assets/example_permission_check.ets)

## 测试用例

### 正向测试用例
- [正常读取三环数据](tests/test_positive.ets): 已授权用户读取完整三环数据
- [读取未设置目标的数据](tests/test_no_goal.ets): 用户未设置目标时读取数据
- [多次连续读取](tests/test_multiple_reads.ets): 测试连续调用稳定性

### 边界测试用例
- [API版本边界测试](tests/test_api_version.ets): 测试最低API版本5.1.1(19)支持
- [数据类型边界测试](tests/test_data_boundary.ets): 测试数值边界情况
- [并发调用测试](tests/test_concurrent.ets): 测试并发调用处理

### 异常测试用例
- [权限未授权测试](tests/test_no_permission.ets): 测试未授权场景错误处理
- [服务未初始化测试](tests/test_not_initialized.ets): 测试未初始化场景
- [网络异常测试](tests/test_network_error.ets): 测试网络异常降级
- [服务异常测试](tests/test_service_error.ets): 测试服务异常处理