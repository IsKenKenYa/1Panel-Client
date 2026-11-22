---
name: hmos-account-kit-minors-protection-mode-switch
description: 应用与系统联动切换未成年人模式，支持查询和订阅系统未成年人模式状态，获取年龄段信息，适用于未成年人保护场景
---

# 应用与系统联动切换未成年人模式技能

## 功能描述

本技能实现应用与系统未成年人模式的联动切换功能，通过查询和订阅两种方式获取系统未成年人模式状态及年龄段信息，帮助应用快速实现未成年人保护机制。

**核心功能**：
- 查询系统未成年人模式开启状态
- 订阅系统未成年人模式公共事件，实时感知状态变化
- 获取年龄段信息，实现内容分级展示
- 支持同步和异步两种调用方式

## 使用场景

### 触发词
- "未成年人模式"
- "联动切换未成年人模式"
- "查询未成年人模式状态"
- "订阅未成年人模式事件"
- "获取年龄段信息"
- "未成年人保护"

### 能做
- 查询系统未成年人模式是否开启
- 获取未成年人年龄段信息（lowerAge、upperAge）
- 订阅系统未成年人模式开启/关闭事件
- 实时感知系统未成年人模式状态变化
- 根据年龄段实现内容分级展示
- 缓存未成年人模式状态和年龄段信息

### 绝不做
- 不直接开启/关闭系统未成年人模式（需使用其他API）
- 不验证未成年人模式密码（需使用verifyMinorsProtectionCredential）
- 不处理超出Account Kit范围的请求
- 不在不支持未成年人模式的设备环境强制调用

### 补充
- 需先配置签名和指纹，无需配置公钥指纹、Client ID和账号权限
- 设备开机未解锁状态下，minorsProtectionMode字段返回false
- 建议缓存未成年人模式状态和年龄段信息，避免重复调用
- PC/2in1设备暂不支持从控制中心开启未成年人模式

## 调用规范和规则

### 输入约束
- 无必需参数输入
- 应用需在Stage模型下运行
- 需在应用Ability的onCreate生命周期或自定义组件的aboutToAppear生命周期调用

### 执行约束
- 最大耗时：同步接口立即返回，异步接口建议设置超时5秒
- API调用频次：建议缓存结果，避免频繁调用
- 订阅事件：需在Ability onCreate生命周期创建订阅者

### 内容约束
- 禁止生成：不生成开启/关闭未成年人模式的代码
- 禁止使用高危函数：不使用eval、exec等高危函数
- 禁止操作：不直接修改系统未成年人模式设置

### 降级约束
- 设备不支持未成年人模式：提示用户当前设备环境不支持
- 网络失败：使用缓存的状态信息（如有）
- 服务不可用：提示用户服务暂时不可用，稍后重试

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查设备是否支持未成年人模式系统能力（SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection）
2. 检查当前设备环境是否支持未成年人模式（调用supportMinorsMode）
3. 确认应用已配置签名和指纹

**参数准备**：
```typescript
import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';
```

### 步骤2：订阅系统未成年人模式公共事件

**推荐在Ability的onCreate生命周期调用**：

```typescript
const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
  events: [commonEventManager.Support.COMMON_EVENT_MINORSMODE_ON,
    commonEventManager.Support.COMMON_EVENT_MINORSMODE_OFF]
};

let subscriber: commonEventManager.CommonEventSubscriber | null = null;

commonEventManager.createSubscriber(subscribeInfo)
  .then((commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
    subscriber = commonEventSubscriber;
    commonEventManager.subscribe(subscriber,
      (error: BusinessError, data: commonEventManager.CommonEventData) => {
        if (error) {
          hilog.error(0x0000, 'testTag', 
            `Failed to subscribe. Code: ${error.code}, message: ${error.message}`);
          return;
        }
        if (data.event === commonEventManager.Support.COMMON_EVENT_MINORSMODE_ON) {
          hilog.info(0x0000, 'testTag', 'Minors mode turned ON');
          // 开启应用的未成年人模式，刷新年龄段信息缓存
        }
        if (data.event === commonEventManager.Support.COMMON_EVENT_MINORSMODE_OFF) {
          hilog.info(0x0000, 'testTag', 'Minors mode turned OFF');
          // 关闭应用的未成年人模式，取消年龄限制
        }
      });
  })
  .catch((error: BusinessError) => {
    hilog.error(0x0000, 'testTag', 
      `Failed to create subscriber. Code: ${error.code}, message: ${error.message}`);
  });
```

### 步骤3：查询未成年人模式状态（同步方式）

**推荐在自定义组件的aboutToAppear生命周期或Ability onCreate生命周期调用**：

```typescript
if (canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
  try {
    if (minorsProtection.supportMinorsMode()) {
      const minorsProtectionInfo: minorsProtection.MinorsProtectionInfo =
        minorsProtection.getMinorsProtectionInfoSync();
      
      const minorsProtectionMode: boolean = minorsProtectionInfo.minorsProtectionMode;
      hilog.info(0x0000, 'testTag', 
        `Minors protection mode: ${minorsProtectionMode.valueOf()}`);
      
      if (minorsProtectionMode) {
        const ageGroup: minorsProtection.AgeGroup | undefined = minorsProtectionInfo.ageGroup;
        if (ageGroup) {
          hilog.info(0x0000, 'testTag', `Age range: [${ageGroup.lowerAge}, ${ageGroup.upperAge})`);
          // 根据年龄段刷新内容展示，建议缓存年龄段信息
        }
      } else {
        // 未成年人模式未开启，展示内容不做限制
      }
    } else {
      hilog.info(0x0000, 'testTag', 
        'Current device environment does not support minors mode');
    }
  } catch (error) {
    hilog.error(0x0000, 'testTag',
      `Failed to query minors mode. Code: ${error.code}, Message: ${error.message}`);
  }
} else {
  hilog.info(0x0000, 'testTag', 
    'Current device does not support minors protection API');
}
```

### 步骤4：查询未成年人模式状态（异步方式）

**使用Promise异步回调**：

```typescript
if (canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
  try {
    if (minorsProtection.supportMinorsMode()) {
      minorsProtection.getMinorsProtectionInfo()
        .then((minorsProtectionInfo: minorsProtection.MinorsProtectionInfo) => {
          const minorsProtectionMode: boolean = minorsProtectionInfo.minorsProtectionMode;
          hilog.info(0x0000, 'testTag', 
            `Minors protection mode: ${minorsProtectionMode.valueOf()}`);
          
          if (minorsProtectionMode) {
            const ageGroup: minorsProtection.AgeGroup | undefined = minorsProtectionInfo.ageGroup;
            if (ageGroup) {
              hilog.info(0x0000, 'testTag', 
                `Age range: [${ageGroup.lowerAge}, ${ageGroup.upperAge})`);
              // 根据年龄段刷新内容展示
            }
          } else {
            // 未成年人模式未开启，展示内容不做限制
          }
        })
        .catch((error: BusinessError<Object>) => {
          hilog.error(0x0000, 'testTag', 
            `Failed to get minors info. Code: ${error.code}, Message: ${error.message}`);
        });
    } else {
      hilog.info(0x0000, 'testTag', 
        'Current device environment does not support minors mode');
    }
  } catch (error) {
    hilog.error(0x0000, 'testTag',
      `Failed to check support. Code: ${error.code}, Message: ${error.message}`);
  }
} else {
  hilog.info(0x0000, 'testTag', 
    'Current device does not support minors protection API');
}
```

### 步骤5：错误处理

**错误码处理示例**：

```typescript
function handleMinorsModeError(error: BusinessError): void {
  switch (error.code) {
    case 1001502009:
      hilog.error(0x0000, 'testTag', 'Internal error occurred');
      break;
    case 1009900002:
      hilog.error(0x0000, 'testTag', 'Minors mode is not enabled');
      break;
    case 1009900011:
      hilog.error(0x0000, 'testTag', 'Service not available');
      break;
    default:
      hilog.error(0x0000, 'testTag', 
        `Unknown error: Code ${error.code}, Message: ${error.message}`);
  }
}
```

### 步骤6：降级处理

**缓存机制示例**：

```typescript
let cachedMinorsMode: boolean = false;
let cachedAgeGroup: minorsProtection.AgeGroup | null = null;

function getMinorsModeWithCache(): void {
  if (cachedMinorsMode !== null && cachedAgeGroup !== null) {
    // 使用缓存数据
    applyAgeRestriction(cachedMinorsMode, cachedAgeGroup);
    return;
  }
  
  // 缓存不存在，查询最新状态
  try {
    if (minorsProtection.supportMinorsMode()) {
      const info = minorsProtection.getMinorsProtectionInfoSync();
      cachedMinorsMode = info.minorsProtectionMode;
      cachedAgeGroup = info.ageGroup || null;
      applyAgeRestriction(cachedMinorsMode, cachedAgeGroup);
    }
  } catch (error) {
    hilog.error(0x0000, 'testTag', 'Failed to query, using default settings');
    // 降级：使用默认设置（不限制内容）
    applyAgeRestriction(false, null);
  }
}

function applyAgeRestriction(mode: boolean, ageGroup: minorsProtection.AgeGroup | null): void {
  if (mode && ageGroup) {
    // 根据年龄段限制内容
    const minAge = ageGroup.lowerAge;
    const maxAge = ageGroup.upperAge;
    // 实现内容分级逻辑
  } else {
    // 不限制内容
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1001502009 | Internal error | 检查系统状态，稍后重试 |
| 1009900002 | MINORS_MODE_NOT_ENABLED | 未成年人模式未开启，无需处理 |
| 1009900003 | USER_CANCELED | 用户取消操作，无需处理 |
| 1009900005 | MINORS_MODE_ALREADY_ON | 未成年人模式已开启，无需处理 |
| 1009900006 | MINORS_MODE_ALREADY_OFF | 未成年人模式已关闭，无需处理 |
| 1009900007 | UNSUPPORTED_ACCOUNT | 不支持的账号类型，提示用户 |
| 1009900011 | SERVICE_NOT_AVAILABLE | 服务不可用，稍后重试 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AccountKit": "^5.0.0",
    "@kit.PerformanceAnalysisKit": "^5.0.0",
    "@kit.BasicServicesKit": "^5.0.0"
  }
}
```

### 环境要求
- HarmonyOS API版本：5.0.0(12)及以上
- 运行环境：Stage模型
- 设备要求：支持SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection

### 常见编译问题

**问题1：导入模块失败**
```
Module '@kit.AccountKit' not found
```
**解决方法**：确保DevEco Studio版本支持HarmonyOS 5.0.0(12)，更新SDK版本

**问题2：系统能力检查失败**
```
canIUse is not defined
```
**解决方法**：确保在正确的上下文中调用，或使用try-catch包裹API调用

**问题3：订阅事件回调不生效**
```
Common event subscription callback not triggered
```
**解决方法**：确保subscriber对象已正确创建和暂存，不要直接在createSubscriber回调中使用临时对象

## 常见问题与解决方法

### Q1：未成年人模式开启时开发者调试被禁用怎么办？
**原因**：未成年人模式会禁用开发者调试模式以保护未成年人
**解决方法**：
- 进入设置-系统-开发者选项
- 点击USB调试开关
- 校验健康使用设备密码
- 校验成功后可解除限制

### Q2：hilog日志无法完全展示怎么办？
**原因**：重新开启USB调试后，hilog日志缓存区可能未恢复
**解决方法**：
- 执行`hdc shell hilog -G 16M`扩大日志缓存区
- 或取出hilog日志本地查看

### Q3：设备开机未解锁时返回什么状态？
**原因**：安全机制，未解锁时不返回真实状态
**解决方法**：
- 设备解锁后再查询未成年人模式状态
- 或使用缓存的状态信息

### Q4：如何避免频繁调用API的性能损耗？
**原因**：每次调用API都涉及系统资源消耗
**解决方法**：
- 在获取结果后缓存未成年人模式状态和年龄段信息
- 通过订阅公共事件来刷新缓存
- 避免重复调用getMinorsProtectionInfoSync/getMinorsProtectionInfo

### Q5：年龄段信息的取值范围是什么？
**原因**：系统根据账号类型和年龄返回不同年龄段
**解决方法**：
- lowerAge取值：0、3、8、12或16
- upperAge取值：3、8、12、16或18
- 年龄段为区间[lowerAge, upperAge)，包含下限不包含上限

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "minorsProtectionMode": true/false,
  "ageGroup": {
    "lowerAge": 0/3/8/12/16,
    "upperAge": 3/8/12/16/18
  },
  "apiUsed": [
    "supportMinorsMode",
    "getMinorsProtectionInfoSync",
    "getMinorsProtectionInfo"
  ],
  "eventsSubscribed": [
    "COMMON_EVENT_MINORSMODE_ON",
    "COMMON_EVENT_MINORSMODE_OFF"
  ]
}
```

## 参考文档

- [应用与系统联动切换未成年人模式开发指南](references/account-system-minorsprotection-guide.md)
- [minorsProtection API参考](references/account-api-minorsprotection.md)
- [系统公共事件定义](references/commoneventmanager-definitions.md)

## 完整示例代码

- [ArkTS完整示例（同步方式）](assets/example_sync.ets)
- [ArkTS完整示例（异步方式）](assets/example_async.ets)
- [订阅事件完整示例](assets/example_subscribe.ets)

## 测试用例

### 正向测试用例
- [查询未成年人模式状态](tests/test_query_status.py)：设备支持未成年人模式，查询成功
- [订阅未成年人模式事件](tests/test_subscribe_event.py)：订阅事件成功，回调触发正常
- [获取年龄段信息](tests/test_get_age_group.py)：未成年人模式开启，正确获取年龄段

### 边界测试用例
- [设备不支持未成年人模式](tests/test_device_not_support.py)：设备不支持，正确提示用户
- [未成年人模式未开启](tests/test_mode_not_enabled.py)：模式未开启，返回minorsProtectionMode=false
- [开机未解锁状态](tests/test_device_locked.py)：设备未解锁，返回默认状态

### 异常测试用例
- [服务不可用](tests/test_service_unavailable.py)：服务不可用，正确处理错误码
- [内部错误](tests/test_internal_error.py)：发生内部错误，降级处理
- [订阅事件失败](tests/test_subscribe_failed.py)：订阅失败，正确处理异常