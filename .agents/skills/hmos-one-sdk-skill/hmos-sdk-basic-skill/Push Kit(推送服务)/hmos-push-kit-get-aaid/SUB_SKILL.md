---
name: hmos-push-kit-get-aaid
description: 获取应用匿名标识符AAID，支持Phone/Tablet/PC/Wearable/TV设备，仅Stage模型可用，适用于推送服务Token申请、应用身份标识场景
---

# 获取AAID技能

## 功能描述

本技能提供获取和删除应用匿名标识符（AAID，Anonymous Application Identifier）的能力。AAID用于标识运行在移动智能终端设备上的应用实例，具有以下特性：

- **匿名化、无隐私风险**：AAID和已有的任何标识符都不关联，每个应用只能访问应用本身的AAID
- **唯一性**：同一设备上不同应用的AAID不同，不同设备上同一应用的AAID也不同
- **可变性**：AAID会在应用卸载重装、调用删除接口、恢复出厂设置、清除应用数据时发生变化
- **长度固定**：AAID总长度为36位

## 使用场景

### 触发词
- "获取AAID"
- "获取应用匿名标识符"
- "AAID"
- "应用身份标识"
- "删除AAID"

### 能做
- 获取当前应用实例的AAID
- 删除当前应用实例的AAID
- 提供Promise和Callback两种异步调用方式
- 适用于推送服务Token申请前的应用身份标识场景
- 适用于需要唯一应用实例标识的业务场景

### 绝不做
- 不提供跨应用的AAID访问能力
- 不提供AAID持久化存储能力（AAID由系统管理）
- 不支持FA模型应用
- 不在设备不支持的场景下强制调用

### 补充
- 仅支持Stage模型
- 需要设备支持：Phone、Tablet、PC/2in1（所有版本），Wearable（5.1.0(18)及以上），TV（5.1.1(19)及以上）
- 起始版本：4.0.0(10)
- 元服务支持：从5.0.0(12)版本开始

## 调用规范和规则

### 输入约束
- 无输入参数要求
- 调用环境必须是Stage模型
- 设备类型必须在支持列表内

### 执行约束
- API调用为异步操作，需要使用await或回调函数处理结果
- 不支持同步调用
- 单次调用最大耗时：建议在3秒内完成
- 建议调用频次：不超过每秒10次

### 内容约束
- 禁止在FA模型中使用
- 禁止在不支持的设备类型上调用
- 禁止在未处理错误码的情况下直接使用返回值
- 必须导入正确的模块：`@kit.PushKit`

### 降级约束
- 如果设备不支持，应提前检测设备类型并提示用户
- 如果API调用失败，建议重试机制（最多3次）
- 如果服务不可用，应提供友好的错误提示
- 如果获取失败，可考虑使用其他应用标识方案（如应用自定义ID）

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认应用使用Stage模型
2. 确认设备类型在支持列表内（Phone/Tablet/PC/2in1/Wearable/TV）
3. 确认HarmonyOS版本在4.0.0(10)及以上
4. 导入必要的模块

**模块导入**：
```typescript
import { AAID } from '@kit.PushKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000; // 日志域
```

### 步骤2：获取AAID（Promise方式）

**推荐方式**：
```typescript
/**
 * 获取AAID（Promise方式）
 * @returns Promise<string> AAID字符串
 */
async function getAAID(): Promise<string> {
  try {
    const aaid: string = await AAID.getAAID();
    hilog.info(DOMAIN, 'AAID', 'Succeeded in getting AAID: %{public}s', aaid);
    return aaid;
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, 'AAID', 'Failed to get AAID: %{public}d %{public}s', e.code, e.message);
    throw e;
  }
}

// 调用示例
getAAID().then((aaid: string) => {
  console.log('AAID:', aaid);
}).catch((err: BusinessError) => {
  console.error('Error:', err.message);
});
```

### 步骤3：获取AAID（Callback方式）

**回调方式**：
```typescript
/**
 * 获取AAID（Callback方式）
 * @param callback 回调函数
 */
function getAAIDWithCallback(callback: (err: BusinessError | null, aaid?: string) => void): void {
  try {
    AAID.getAAID((err: BusinessError, data: string) => {
      if (err) {
        hilog.error(DOMAIN, 'AAID', 'Failed to get AAID: %{public}d %{public}s', err.code, err.message);
        callback(err);
      } else {
        hilog.info(DOMAIN, 'AAID', 'Succeeded in getting AAID: %{public}s', data);
        callback(null, data);
      }
    });
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, 'AAID', 'Failed to get AAID: %{public}d %{public}s', e.code, e.message);
    callback(e);
  }
}

// 调用示例
getAAIDWithCallback((err, aaid) => {
  if (err) {
    console.error('Error:', err.message);
  } else {
    console.log('AAID:', aaid);
  }
});
```

### 步骤4：删除AAID（Promise方式）

**删除标识符**：
```typescript
/**
 * 删除AAID（Promise方式）
 * @returns Promise<void>
 */
async function deleteAAID(): Promise<void> {
  try {
    await AAID.deleteAAID();
    hilog.info(DOMAIN, 'AAID', 'Succeeded in deleting AAID');
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, 'AAID', 'Failed to delete AAID: %{public}d %{public}s', e.code, e.message);
    throw e;
  }
}

// 调用示例
deleteAAID().then(() => {
  console.log('AAID deleted successfully');
}).catch((err: BusinessError) => {
  console.error('Error:', err.message);
});
```

### 步骤5：删除AAID（Callback方式）

**回调删除**：
```typescript
/**
 * 删除AAID（Callback方式）
 * @param callback 回调函数
 */
function deleteAAIDWithCallback(callback: (err: BusinessError | null) => void): void {
  try {
    AAID.deleteAAID((err: BusinessError) => {
      if (err) {
        hilog.error(DOMAIN, 'AAID', 'Failed to delete AAID: %{public}d %{public}s', err.code, err.message);
        callback(err);
      } else {
        hilog.info(DOMAIN, 'AAID', 'Succeeded in deleting AAID');
        callback(null);
      }
    });
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, 'AAID', 'Failed to delete AAID: %{public}d %{public}s', e.code, e.message);
    callback(e);
  }
}

// 调用示例
deleteAAIDWithCallback((err) => {
  if (err) {
    console.error('Error:', err.message);
  } else {
    console.log('AAID deleted successfully');
  }
});
```

### 步骤6：错误处理

**完整错误处理示例**：
```typescript
/**
 * 错误处理封装
 */
async function handleAAIDError(error: BusinessError): Promise<void> {
  switch (error.code) {
    case 401:
      console.error('参数错误：', error.message);
      // 检查参数类型和必填项
      break;
    case 1000900001:
      console.error('系统内部错误：', error.message);
      // 建议重试
      break;
    case 1000900006:
      console.error('连接AAID服务失败：', error.message);
      // 检查PushService状态，稍后重试
      break;
    case 1000900007:
      console.error('AAID服务内部错误：', error.message);
      // 服务内部错误，建议稍后重试
      break;
    default:
      console.error('未知错误：', error.code, error.message);
      // 处理其他错误
      break;
  }
}

// 使用示例
try {
  const aaid = await AAID.getAAID();
  console.log('AAID:', aaid);
} catch (err) {
  const e: BusinessError = err as BusinessError;
  await handleAAIDError(e);
}
```

### 步骤7：降级处理

**降级方案**：
```typescript
/**
 * 带重试机制的获取AAID
 * @param maxRetries 最大重试次数，默认3次
 * @param retryDelay 重试延迟（毫秒），默认1000ms
 * @returns Promise<string> AAID字符串
 */
async function getAAIDWithRetry(maxRetries: number = 3, retryDelay: number = 1000): Promise<string> {
  let lastError: BusinessError | null = null;
  
  for (let i = 0; i < maxRetries; i++) {
    try {
      const aaid = await AAID.getAAID();
      return aaid;
    } catch (err) {
      lastError = err as BusinessError;
      hilog.warn(DOMAIN, 'AAID', 'Retry %{public}d/%{public}d failed: %{public}s', i + 1, maxRetries, lastError.message);
      
      // 如果是参数错误，不需要重试
      if (lastError.code === 401) {
        throw lastError;
      }
      
      // 等待后重试
      if (i < maxRetries - 1) {
        await new Promise(resolve => setTimeout(resolve, retryDelay));
      }
    }
  }
  
  // 所有重试失败后的降级方案
  hilog.error(DOMAIN, 'AAID', 'All retries failed, using fallback');
  throw lastError!;
}

/**
 * 降级方案：生成自定义应用标识
 * @returns string 自定义应用标识
 */
function generateCustomAppId(): string {
  // 使用时间戳和随机数生成唯一标识
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(2, 15);
  return `custom_${timestamp}_${random}`;
}

// 使用示例
async function getOrGenerateAAID(): Promise<string> {
  try {
    // 尝试获取AAID（带重试）
    return await getAAIDWithRetry(3, 1000);
  } catch (err) {
    // 降级方案：使用自定义应用标识
    hilog.warn(DOMAIN, 'AAID', 'Failed to get AAID, using custom ID');
    return generateCustomAppId();
  }
}
```

## 错误码说明

| 错误码 | 说明 | 可能原因 | 解决方法 |
|-------|------|---------|---------|
| 401 | 参数错误 | 1. 必填参数未指定<br>2. 参数类型不正确 | 1. 检查参数是否正确传递<br>2. 确认参数类型符合要求 |
| 1000900001 | 系统内部错误 | 其他未知错误 | 1. 重试操作<br>2. 如问题持续，通过在线提单反馈 |
| 1000900006 | 连接AAID服务失败 | PushService运行异常 | 1. 重试操作<br>2. 检查设备Push服务状态<br>3. 如问题持续，通过在线提单反馈 |
| 1000900007 | AAID服务内部错误 | PushService内部处理超时或异常 | 1. 重试操作<br>2. 如问题持续，通过在线提单反馈 |

## 编译和修复问题

### 依赖声明
```json
{
  "name": "aaid_example",
  "version": "1.0.0",
  "dependencies": {
    "@kit.PushKit": "^4.0.0",
    "@kit.BasicServicesKit": "^4.0.0",
    "@kit.PerformanceAnalysisKit": "^4.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK：4.0.0(10)及以上
- 模型约束：仅支持Stage模型
- 设备类型：Phone、Tablet、PC/2in1、Wearable（5.1.0(18)+）、TV（5.1.1(19)+）
- 开发工具：DevEco Studio 4.0及以上

### 常见编译问题

**问题1：找不到@kit.PushKit模块**
```
Error: Cannot find module '@kit.PushKit'
```
**解决方法**：
1. 确认HarmonyOS SDK版本在4.0.0(10)及以上
2. 在`build-profile.json5`中配置正确的SDK版本
3. 同步项目依赖

**问题2：Stage模型导入错误**
```
Error: This API can only be used in Stage model
```
**解决方法**：
1. 确认项目使用Stage模型
2. 检查`module.json5`配置文件
3. 确保不在FA模型代码中调用此API

**问题3：设备类型不支持**
```
Error: The device does not support this API
```
**解决方法**：
1. 检查设备类型是否在支持列表中
2. 对于Wearable设备，确认HarmonyOS版本在5.1.0(18)及以上
3. 对于TV设备，确认HarmonyOS版本在5.1.1(19)及以上

## 常见问题与解决方法

### Q1：获取AAID时返回空字符串或undefined
**原因**：
- Push服务未初始化
- 设备不支持
- 网络问题

**解决方法**：
1. 检查设备类型和系统版本
2. 确认应用配置正确
3. 检查网络连接
4. 添加重试机制

### Q2：删除AAID后立即获取，返回的值不同
**原因**：
- AAID删除后，系统会自动生成新的AAID
- 这是正常行为，符合设计预期

**解决方法**：
- 这是正常现象，删除AAID会触发重新生成
- 如果需要保持AAID不变，不要调用删除接口

### Q3：应用卸载重装后AAID发生变化
**原因**：
- AAID与应用实例绑定，卸载重装后为新的应用实例

**解决方法**：
- 这是正常行为，符合隐私设计
- 如需持久化标识，建议使用服务器端生成并存储

### Q4：在Wearable设备上调用失败
**原因**：
- Wearable设备从5.1.0(18)版本开始支持

**解决方法**：
1. 检查设备HarmonyOS版本
2. 如果版本较低，提示用户升级系统
3. 在代码中添加版本检查

### Q5：调用API时抛出异常但未进入catch块
**原因**：
- 使用了同步调用方式
- 未正确使用async/await

**解决方法**：
1. 确保使用async/await或Promise.then/catch
2. 不要混用同步和异步调用

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "aaid": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "length": 36,
  "apiUsed": [
    "AAID.getAAID"
  ],
  "deviceInfo": {
    "deviceType": "Phone",
    "apiVersion": "4.0.0(10)"
  },
  "timestamp": "2026-07-03T00:35:00.000Z"
}
```

或删除AAID：

```json
{
  "status": "success",
  "operation": "delete",
  "apiUsed": [
    "AAID.deleteAAID"
  ],
  "timestamp": "2026-07-03T00:35:00.000Z"
}
```

## 参考文档

- [API开发指南](references/push-get-aaid.md)
- [API参考说明](references/push-aaid-api.md)
- [ArkTS API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/push-error-code)

## 完整示例代码

- [ArkTS示例（Promise方式）](assets/get_aaid_promise.ets)
- [ArkTS示例（Callback方式）](assets/get_aaid_callback.ets)
- [完整业务示例](assets/aaid_complete_example.ets)

## 测试用例

### 正向测试用例
- [获取AAID成功](tests/test_positive.ets)：正常获取AAID，验证返回值长度为36位
- [删除AAID成功](tests/test_positive.ets)：正常删除AAID，验证操作成功
- [Promise方式调用](tests/test_positive.ets)：使用Promise方式调用，验证异步处理正确

### 边界测试用例
- [设备类型边界](tests/test_boundary.ets)：在不同支持设备上测试（Phone/Tablet/PC/Wearable/TV）
- [版本边界](tests/test_boundary.ets)：在最低支持版本4.0.0(10)上测试
- [多次调用](tests/test_boundary.ets)：连续多次调用getAAID，验证返回值一致性

### 异常测试用例
- [参数错误](tests/test_exception.ets)：传入错误参数类型，验证错误码401
- [服务不可用](tests/test_exception.ets)：模拟Push服务不可用，验证错误码1000900006
- [网络异常](tests/test_exception.ets)：模拟网络异常场景，验证错误处理
- [FA模型调用](tests/test_exception.ets)：在FA模型中调用，验证API不可用