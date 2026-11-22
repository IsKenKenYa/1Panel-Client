---
name: hmos-account-kit-verify-minorsprotection-credential
description: 验证未成年人模式密码以调整应用内设置，需未成年人模式已开启，适用于家长身份验证场景
---

# 应用内调整未成年人模式设置技能

## 功能描述

本技能提供在未成年人模式已开启的情况下，验证家长身份以调整应用内未成年人模式设置的能力。当系统未成年人模式已开启，用户需要在应用内调整内容偏好、使用时长等设置时，需通过验证未成年人模式密码来确认家长身份。验证成功后，应用才可修改当前应用的未成年人模式设置。

主要功能包括：
- 判断当前设备环境是否支持未成年人模式
- 获取系统未成年人模式的开启状态和年龄段信息
- 拉起验证未成年人模式密码页面，验证家长身份
- 处理验证结果并执行后续设置调整流程

## 使用场景

### 触发词
- "验证未成年人模式密码"
- "调整未成年人模式设置"
- "家长身份验证"
- "修改未成年人模式内容偏好"
- "调整未成年人模式使用时长"

### 能做
- 验证未成年人模式密码，确认家长身份
- 在未成年人模式已开启状态下，允许调整应用内设置
- 获取系统未成年人模式状态和年龄段信息
- 判断设备是否支持未成年人模式功能
- 订阅未成年人模式开启/关闭事件

### 绝不做
- 在未成年人模式未开启时调用验证密码接口（会返回错误码1009900002）
- 在非页面或自定义组件生命周期内调用验证接口
- 在半模态、弹出框、子窗口等非全页面组件中使用UIExtensionContext调用验证接口
- 未经家长身份验证直接修改未成年人模式设置
- 在隐私空间或海外账号环境下强制调用验证接口

### 补充
- 该接口需要在页面或自定义组件生命周期内调用，需传入有效的Context上下文对象
- 未成年人模式开启时，设备的开发者调试模式会被禁用，需验证健康使用设备密码后才能解除限制
- 建议缓存未成年人模式开启状态和年龄段信息，避免重复调用接口造成性能损耗
- 当设备处于开机未解锁状态下，调用getMinorsProtectionInfoSync接口返回的minorsProtectionMode字段为false

## 调用规范和规则

### 输入约束
- Context上下文：必须传入有效的UIAbilityContext或UIExtensionContext（不支持在半模态、弹出框、子窗口中使用）
- 未成年人模式状态：调用验证接口前，必须确认系统未成年人模式已开启
- 设备环境：当前设备必须支持未成年人模式（通过supportMinorsMode判断）

### 执行约束
- 调用时机：必须在页面或自定义组件生命周期内调用
- 最大耗时：验证页面等待用户输入密码，无固定超时限制
- API调用频次：建议缓存状态信息，避免频繁调用getMinorsProtectionInfo接口

### 内容约束
- 禁止绕过验证：不允许未经家长身份验证直接修改未成年人模式设置
- 禁止高危函数：禁止使用eval、exec等高危函数处理验证结果
- 禁止硬编码：禁止在代码中硬编码密码或敏感信息

### 降级约束
- 设备不支持未成年人模式：提示用户当前设备环境不支持此功能
- 未成年人模式未开启：引导用户先开启未成年人模式或直接修改设置（无需验证）
- 用户取消验证：处理用户取消逻辑，不执行后续设置修改
- 网络错误：提示用户检查网络连接，稍后重试

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查当前设备是否支持未成年人模式功能
2. 获取系统未成年人模式的开启状态
3. 确认用户有修改应用内设置的需求

**参数准备**：
```typescript
import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'MinorsProtectionVerify';
const DOMAIN = 0x0000;
```

### 步骤2：判断设备支持和未成年人模式状态

**示例代码**：
```typescript
if (canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
  try {
    const supportMinorsMode: boolean = minorsProtection.supportMinorsMode();
    if (!supportMinorsMode) {
      hilog.info(DOMAIN, TAG, 
        'The current device environment does not support minors mode.');
      return;
    }
    
    const minorsProtectionInfo = minorsProtection.getMinorsProtectionInfoSync();
    const minorsProtectionMode = minorsProtectionInfo.minorsProtectionMode;
    
    if (!minorsProtectionMode) {
      hilog.info(DOMAIN, TAG, 'Minors mode is not enabled.');
      return;
    }
    
    hilog.info(DOMAIN, TAG, 
      `Minors mode is enabled. Age group: ${JSON.stringify(minorsProtectionInfo.ageGroup)}`);
  } catch (error) {
    hilog.error(DOMAIN, TAG, 
      `Failed to check minors mode status. Code: ${error.code}, Message: ${error.message}`);
  }
} else {
  hilog.info(DOMAIN, TAG, 
    'The current device does not support minors protection APIs.');
}
```

### 步骤3：调用验证密码接口

**示例代码**：
```typescript
async function verifyMinorsProtectionCredential(context: common.Context): Promise<boolean> {
  try {
    const result = await minorsProtection.verifyMinorsProtectionCredential(context);
    hilog.info(DOMAIN, TAG, `Verification result: ${result}`);
    return result;
  } catch (error) {
    const businessError = error as BusinessError<Object>;
    handleVerifyError(businessError);
    return false;
  }
}

function handleVerifyError(error: BusinessError<Object>): void {
  switch (error.code) {
    case 1009900002:
      hilog.error(DOMAIN, TAG, 'Minors mode is not enabled.');
      break;
    case 1009900003:
      hilog.error(DOMAIN, TAG, 'User canceled the operation.');
      break;
    case 1001502009:
      hilog.error(DOMAIN, TAG, 'Internal error occurred.');
      break;
    case 401:
      hilog.error(DOMAIN, TAG, 'Parameter error. Check context parameter.');
      break;
    default:
      hilog.error(DOMAIN, TAG, 
        `Unknown error. Code: ${error.code}, Message: ${error.message}`);
  }
}
```

### 步骤4：处理验证结果并执行后续流程

**示例代码**：
```typescript
async function adjustMinorsProtectionSettings(context: common.Context): Promise<void> {
  const verifyResult = await verifyMinorsProtectionCredential(context);
  
  if (verifyResult) {
    hilog.info(DOMAIN, TAG, 'Password verification succeeded. Proceeding with settings adjustment.');
    await modifyAppMinorsProtectionSettings();
  } else {
    hilog.info(DOMAIN, TAG, 'Password verification failed or user canceled. Cannot adjust settings.');
  }
}

async function modifyAppMinorsProtectionSettings(): Promise<void> {
  try {
    hilog.info(DOMAIN, TAG, 'Modifying app minors protection settings...');
  } catch (error) {
    hilog.error(DOMAIN, TAG, 
      `Failed to modify settings. Code: ${error.code}, Message: ${error.message}`);
  }
}
```

### 步骤5：订阅未成年人模式事件（可选）

**示例代码**：
```typescript
import { commonEventManager } from '@kit.BasicServicesKit';

function subscribeMinorsModeEvents(): void {
  const subscribers: commonEventManager.CommonEventSubscriber[] = [];
  
  const onSubscriber = commonEventManager.createCommonEventSubscriber(
    { event: 'usual.event.MINORSMODE_ON' }
  );
  const offSubscriber = commonEventManager.createCommonEventSubscriber(
    { event: 'usual.event.MINORSMODE_OFF' }
  );
  
  commonEventManager.subscribeCommonEvent(onSubscriber, (err, data) => {
    if (!err) {
      hilog.info(DOMAIN, TAG, 'Minors mode turned on event received.');
      refreshMinorsModeStatus();
    }
  });
  
  commonEventManager.subscribeCommonEvent(offSubscriber, (err, data) => {
    if (!err) {
      hilog.info(DOMAIN, TAG, 'Minors mode turned off event received.');
      refreshMinorsModeStatus();
    }
  });
  
  subscribers.push(onSubscriber, offSubscriber);
}

function refreshMinorsModeStatus(): void {
  try {
    const minorsProtectionInfo = minorsProtection.getMinorsProtectionInfoSync();
    const minorsProtectionMode = minorsProtectionInfo.minorsProtectionMode;
    hilog.info(DOMAIN, TAG, `Refreshed minors mode status: ${minorsProtectionMode}`);
  } catch (error) {
    hilog.error(DOMAIN, TAG, 'Failed to refresh minors mode status.');
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1009900002 | 未成年人模式未开启 | 调用getMinorsProtectionInfoSync()检查状态，确认未成年人模式已开启后再调用验证接口 |
| 1009900003 | 用户取消操作 | 处理用户取消逻辑，不执行后续设置修改 |
| 1001502009 | 内部错误 | 重启设备后重试，或通过在线提单提交问题 |
| 401 | 参数错误 | 检查context参数是否正确传入，确保为有效的UIAbilityContext或UIExtensionContext |
| 801 | 该设备不支持此API | 通过canIUse()判断设备是否支持该API，在不支持的设备上避免调用 |
| 1009900007 | 不支持的账号 | 登录中国境内（香港特别行政区、澳门特别行政区、中国台湾除外）账号 |
| 1009900011 | 服务不可用 | 提醒用户退出隐私空间，或构建自己的未成年人模式 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AccountKit": "^5.0.0",
    "@kit.PerformanceAnalysisKit": "^5.0.0",
    "@kit.BasicServicesKit": "^5.0.0",
    "@kit.AbilityKit": "^5.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK：最低版本 5.0.0(12)
- 设备类型：支持SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection的设备
- 账号要求：中国境内（香港特别行政区、澳门特别行政区、中国台湾除外）华为账号

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.AccountKit'
```
**解决方法**：确保HarmonyOS SDK版本不低于5.0.0(12)，并在oh-package.json5中正确配置依赖

**问题2：Context参数类型错误**
```
TypeError: context is not a valid UIAbilityContext or UIExtensionContext
```
**解决方法**：确保在页面或自定义组件实例中调用，并传入正确的Context对象，如`this.getUIContext().getHostContext()`

**问题3：未成年人模式未开启错误**
```
Error code: 1009900002 - The minors mode is not enabled
```
**解决方法**：调用getMinorsProtectionInfoSync()检查状态，仅在未成年人模式已开启时调用验证接口

**问题4：设备不支持未成年人模式**
```
Error: The current device environment does not support minors mode
```
**解决方法**：通过supportMinorsMode()判断设备环境，在不支持的设备上提供降级方案

## 常见问题与解决方法

### Q1：为什么调用验证接口返回错误码1009900002？
**原因**：未成年人模式未开启时调用验证接口会返回此错误码
**解决方法**：
- 调用getMinorsProtectionInfoSync()或getMinorsProtectionInfo()检查未成年人模式状态
- 确认未成年人模式已开启后再调用verifyMinorsProtectionCredential接口
- 如未成年人模式未开启，可引导用户先开启未成年人模式

### Q2：用户取消验证后如何处理？
**原因**：用户主动点击页面关闭按钮取消验证操作
**解决方法**：
- 接收到错误码1009900003时，不执行后续设置修改流程
- 可提示用户验证已取消，需要重新验证才能修改设置
- 应用无需特殊处理，正常结束流程即可

### Q3：如何获取有效的Context上下文对象？
**原因**：验证接口需要在页面或自定义组件生命周期内调用，传入正确的Context
**解决方法**：
- 在自定义组件实例中调用：`this.getUIContext().getHostContext()`
- 在UIAbility中调用：使用`this.context`（UIAbilityContext）
- 不支持在半模态、弹出框、子窗口等非全页面组件中使用UIExtensionContext调用

### Q4：隐私空间环境下为什么返回服务不可用错误？
**原因**：设备进入隐私空间后，未成年人模式服务不可用
**解决方法**：
- 提醒用户进入"设置">"隐私和安全">"隐私空间"退出隐私空间
- 或构建自己的未成年人模式功能作为降级方案

### Q5：如何避免频繁调用接口造成性能损耗？
**原因**：频繁调用getMinorsProtectionInfoSync()或getMinorsProtectionInfo()查询状态
**解决方法**：
- 在获取结果后进行缓存
- 通过订阅系统未成年人模式公共事件（COMMON_EVENT_MINORSMODE_ON和COMMON_EVENT_MINORSMODE_OFF）来刷新状态
- 避免每次需要时都重新调用接口

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "deviceSupport": true,
  "minorsModeEnabled": true,
  "verificationResult": true,
  "settingsModified": true,
  "apiUsed": [
    "supportMinorsMode",
    "getMinorsProtectionInfoSync",
    "verifyMinorsProtectionCredential"
  ],
  "ageGroup": {
    "lowerAge": 3,
    "upperAge": 8
  }
}
```

## 参考文档

- [API开发指南 - 应用内调整未成年人模式设置](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-password-minorsprotection)
- [API参考 - minorsProtection模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-minorsprotection)
- [错误码说明 - Account Kit错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-error-code)
- [通用错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-universal)
- [Context公共模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-common)

## 完整示例代码

- [ArkTS完整示例](assets/verify_minorsprotection_credential.ets)
- [订阅事件示例](assets/subscribe_minorsmode_events.ets)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [设备支持且未成年人模式已开启，验证成功](tests/test_positive_1.ets)：测试验证密码成功场景
- [设备支持且未成年人模式已开启，验证失败](tests/test_positive_2.ets)：测试密码验证失败但接口正常返回场景
- [获取年龄段信息成功](tests/test_positive_3.ets)：测试正确获取年龄段信息

### 边界测试用例
- [未成年人模式刚开启时调用验证](tests/test_boundary_1.ets)：测试未成年人模式状态变化后立即调用验证
- [开机未解锁状态调用getMinorsProtectionInfoSync](tests/test_boundary_2.ets)：测试特殊状态下接口返回值
- [年龄段边界值测试](tests/test_boundary_3.ets)：测试不同年龄段[0,3)、[3,8)、[8,12)、[12,16)、[16,18)的处理

### 异常测试用例
- [未成年人模式未开启调用验证](tests/test_exception_1.ets)：测试错误码1009900002处理
- [用户取消验证操作](tests/test_exception_2.ets)：测试错误码1009900003处理
- [设备不支持未成年人模式](tests/test_exception_3.ets)：测试supportMinorsMode返回false的降级处理
- [传入无效Context参数](tests/test_exception_4.ets)：测试错误码401处理
- [海外账号调用验证](tests/test_exception_5.ets)：测试不支持的账号场景
- [隐私空间环境下调用](tests/test_exception_6.ets)：测试服务不可用场景