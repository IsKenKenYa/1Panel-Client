---
name: hmos-account-kit-verify-minors-protection-credential
description: 验证未成年人模式密码以调整应用内未成年人模式设置+支持同步/异步查询未成年人模式状态+需在未成年人模式开启状态下调用+适用于应用内调整内容偏好、使用时长等设置场景
---

# 应用内调整未成年人模式设置技能

## 功能描述

本技能用于验证家长身份以调整应用内未成年人模式设置。当系统未成年人模式已开启且用户需要在应用内调整内容偏好、使用时长等设置时，通过验证未成年人模式密码来确认家长身份。支持同步和异步两种方式查询未成年人模式开启状态和年龄段信息，应用可根据年龄段展示适龄内容。

**核心能力**：
- 验证未成年人模式密码（家长身份验证）
- 查询系统未成年人模式开启状态
- 获取年龄段信息以展示适龄内容
- 订阅未成年人模式开启/关闭事件

**适用范围**：
- 应用内调整未成年人模式设置（内容偏好、使用时长等）
- 应用与系统未成年人模式联动切换
- 根据年龄段展示适龄内容

**限制条件**：
- 需在未成年人模式已开启状态下调用验证接口
- 必须在页面或自定义组件生命周期内调用
- 仅支持Stage模型
- 仅支持中国境内（香港特别行政区、澳门特别行政区、中国台湾除外）账号

**典型场景**：
- 用户调整应用内未成年人模式设置时验证家长身份
- 应用跟随系统未成年人模式切换
- 根据年龄段展示适龄内容

## 使用场景

### 触发词
- "调整未成年人模式设置"
- "验证未成年人模式密码"
- "验证家长身份"
- "修改未成年人模式配置"
- "调整内容偏好"
- "调整使用时长"

### 能做
- 验证未成年人模式密码以确认家长身份
- 查询系统未成年人模式开启状态（同步/异步）
- 获取年龄段信息（lowerAge/upperAge）
- 订阅系统未成年人模式开启/关闭事件
- 根据年龄段展示适龄内容

### 绝不做
- 在未成年人模式未开启状态下调用验证接口
- 在非页面或自定义组件生命周期内调用验证接口
- 在半模态、弹出框、子窗口等非全页面组件中使用UIExtensionContext调用
- 对海外账号或隐私空间账号调用接口

### 补充
- 如需频繁使用未成年人模式状态或年龄段信息，建议缓存结果并订阅公共事件刷新，避免重复调用
- 当设备处于开机未解锁状态时，getMinorsProtectionInfoSync返回的minorsProtectionMode字段为false
- 未成年人模式开启时，开发者调试模式会被禁用，需验证健康使用设备密码才能开启USB调试

## 调用规范和规则

### 输入约束
- Context类型：仅支持UIAbilityContext或UIExtensionContext（不支持在非全页面组件中使用UIExtensionContext）
- 调用位置：必须在页面或自定义组件生命周期内调用
- 系统状态：未成年人模式必须已开启（否则返回错误码1009900002）
- 设备支持：需先通过supportMinorsMode()判断设备是否支持未成年人模式

### 执行约束
- 最大验证等待时间：用户操作超时时间由系统控制（通常30秒）
- API调用频次：建议缓存状态信息，避免频繁调用getMinorsProtectionInfo接口
- 异步操作：verifyMinorsProtectionCredential和getMinorsProtectionInfo为异步接口，需使用Promise处理

### 内容约束
- 禁止在未成年人模式未开启时调用验证接口
- 禁止绕过验证直接修改未成年人模式设置
- 禁止在非生命周期内调用接口
- 禁止使用高危操作（如eval、动态代码执行）

### 降级约束
- 未成年人模式未开启：提示用户先开启未成年人模式或引导用户开启
- 设备不支持：提示用户当前设备环境不支持或构建自己的未成年人模式
- 用户取消验证：应用无需特殊处理，可提示用户稍后再试
- 服务不可用：提示用户退出隐私空间或稍后重试

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查设备是否支持未成年人模式功能（调用supportMinorsMode）
2. 检查系统未成年人模式是否已开启（调用getMinorsProtectionInfoSync或getMinorsProtectionInfo）
3. 验证Context上下文是否有效（必须在页面或自定义组件生命周期内）
4. 检查系统能力是否支持（使用canIUse判断SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection）

**参数准备**：
```typescript
// 导入必要模块
import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

// 准备Context上下文（需在自定义组件实例中获取）
const context = this.getUIContext().getHostContext();
```

### 步骤2：查询未成年人模式状态

**同步查询示例**：
```typescript
function queryMinorsProtectionStatus(): void {
  if (canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
    try {
      // 检查设备是否支持未成年人模式
      if (minorsProtection.supportMinorsMode()) {
        // 同步查询未成年人模式状态
        const minorsProtectionInfo: minorsProtection.MinorsProtectionInfo =
          minorsProtection.getMinorsProtectionInfoSync();
        
        const minorsProtectionMode: boolean = minorsProtectionInfo.minorsProtectionMode;
        hilog.info(0x0000, 'MinorsProtectionTag', 
          `Minors protection mode status: ${minorsProtectionMode}`);
        
        // 如需频繁使用，建议缓存此状态
        if (minorsProtectionMode) {
          // 未成年人模式已开启，可获取年龄段信息
          const ageGroup: minorsProtection.AgeGroup | undefined = minorsProtectionInfo.ageGroup;
          if (ageGroup) {
            hilog.info(0x0000, 'MinorsProtectionTag', 
              `Age range: [${ageGroup.lowerAge}, ${ageGroup.upperAge})`);
          }
        }
      } else {
        hilog.warn(0x0000, 'MinorsProtectionTag', 
          'Current device does not support minors mode');
      }
    } catch (error) {
      hilog.error(0x0000, 'MinorsProtectionTag', 
        `Failed to query status. Code: ${error.code}, Message: ${error.message}`);
    }
  }
}
```

**异步查询示例**：
```typescript
async function queryMinorsProtectionStatusAsync(): Promise<void> {
  if (canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
    try {
      if (minorsProtection.supportMinorsMode()) {
        const minorsProtectionInfo = await minorsProtection.getMinorsProtectionInfo();
        const minorsProtectionMode = minorsProtectionInfo.minorsProtectionMode;
        
        if (minorsProtectionMode) {
          const ageGroup = minorsProtectionInfo.ageGroup;
          if (ageGroup) {
            hilog.info(0x0000, 'MinorsProtectionTag', 
              `Age range: [${ageGroup.lowerAge}, ${ageGroup.upperAge})`);
          }
        }
      }
    } catch (error) {
      hilog.error(0x0000, 'MinorsProtectionTag', 
        `Failed to query status. Code: ${error.code}, Message: ${error.message}`);
    }
  }
}
```

### 步骤3：验证未成年人模式密码

**核心调用示例**：
```typescript
async function verifyMinorsProtectionPassword(context: common.Context): Promise<boolean> {
  if (canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
    try {
      // 检查设备是否支持未成年人模式
      if (minorsProtection.supportMinorsMode()) {
        // 查询未成年人模式状态
        const minorsProtectionInfo = minorsProtection.getMinorsProtectionInfoSync();
        
        if (!minorsProtectionInfo.minorsProtectionMode) {
          hilog.warn(0x0000, 'MinorsProtectionTag', 
            'Minors mode is not enabled, cannot verify password');
          return false;
        }
        
        // 调用验证接口（必须在页面或自定义组件生命周期内）
        const verifyResult: boolean = await minorsProtection.verifyMinorsProtectionCredential(context);
        
        hilog.info(0x0000, 'MinorsProtectionTag', 
          `Password verification result: ${verifyResult}`);
        
        return verifyResult;
      } else {
        hilog.warn(0x0000, 'MinorsProtectionTag', 
          'Current device does not support minors mode');
        return false;
      }
    } catch (error) {
      const businessError = error as BusinessError<Object>;
      handleVerifyError(businessError);
      return false;
    }
  }
  return false;
}
```

### 步骤4：错误处理

```typescript
function handleVerifyError(error: BusinessError<Object>): void {
  hilog.error(0x0000, 'MinorsProtectionTag', 
    `Verification failed. Code: ${error.code}, Message: ${error.message}`);
  
  switch (error.code) {
    case 401:
      hilog.error(0x0000, 'MinorsProtectionTag', 'Parameter error. Check context parameter.');
      break;
    case 1001502009:
      hilog.error(0x0000, 'MinorsProtectionTag', 'Internal error. Please retry or restart device.');
      break;
    case 1009900002:
      hilog.error(0x0000, 'MinorsProtectionTag', 'Minors mode is not enabled. Please enable it first.');
      break;
    case 1009900003:
      hilog.info(0x0000, 'MinorsProtectionTag', 'User canceled the operation.');
      break;
    default:
      hilog.error(0x0000, 'MinorsProtectionTag', 'Unknown error occurred.');
  }
}
```

### 步骤5：订阅未成年人模式事件

```typescript
import { commonEventManager } from '@kit.BasicServicesKit';

function subscribeMinorsModeEvent(): void {
  try {
    // 订阅未成年人模式开启事件
    commonEventManager.on('usual.event.MINORSMODE_ON', (event) => {
      hilog.info(0x0000, 'MinorsProtectionTag', 'Minors mode turned ON');
      // 更新应用状态，切换到未成年人模式
      updateAppMinorsMode(true);
    });
    
    // 订阅未成年人模式关闭事件
    commonEventManager.on('usual.event.MINORSMODE_OFF', (event) => {
      hilog.info(0x0000, 'MinorsProtectionTag', 'Minors mode turned OFF');
      // 更新应用状态，切换到正常模式
      updateAppMinorsMode(false);
    });
  } catch (error) {
    hilog.error(0x0000, 'MinorsProtectionTag', 
      `Failed to subscribe events. Code: ${error.code}, Message: ${error.message}`);
  }
}

function updateAppMinorsMode(enabled: boolean): void {
  // 根据未成年人模式状态更新应用内容展示
  if (enabled) {
    const info = minorsProtection.getMinorsProtectionInfoSync();
    const ageGroup = info.ageGroup;
    if (ageGroup) {
      // 根据年龄段调整内容展示
      adjustContentForAge(ageGroup.lowerAge, ageGroup.upperAge);
    }
  } else {
    // 展示正常内容
    showNormalContent();
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：1. 必填参数未指定；2. 参数类型不正确 | 检查Context参数是否正确传入，确保在页面或自定义组件生命周期内调用 |
| 1001502009 | 内部错误 | 重启设备后重试，或提交在线工单 |
| 1009900002 | 未成年人模式未开启 | 先开启未成年人模式或引导用户开启 |
| 1009900003 | 用户取消操作 | 应用无需特殊处理，用户主动取消 |
| 1009900005 | 未成年人模式已经开启 | 调用getMinorsProtectionInfoSync判断状态后再调用 |
| 1009900006 | 未成年人模式已经关闭 | 调用getMinorsProtectionInfoSync判断状态后再调用 |
| 1009900007 | 不支持的账号 | 登录中国境内（香港特别行政区、澳门特别行政区、中国台湾除外）账号 |
| 1009900011 | 服务不可用 | 提醒用户退出隐私空间或构建自己的未成年人模式 |

## 编译和修复问题

### 依赖声明

**module.json5配置**：
```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "abilities": [
      {
        "name": "MainAbility",
        "srcEntry": "./ets/mainability/MainAbility.ts",
        "description": "Main ability"
      }
    ]
  }
}
```

**无需特殊权限配置**：
- verifyMinorsProtectionCredential接口无需配置公钥指纹、Client ID
- 无需申请账号权限

### 环境要求
- HarmonyOS API版本：5.0.0(12)及以上
- 开发环境：DevEco Studio 5.0.0及以上
- 运行环境：支持SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection的设备
- 账号要求：中国境内（香港特别行政区、澳门特别行政区、中国台湾除外）华为账号

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.AccountKit'
```
**解决方法**：确保DevEco Studio版本支持HarmonyOS 5.0.0(12)，检查项目配置

**问题2：系统能力判断失败**
```
Error: canIUse is not defined
```
**解决方法**：在正确的文件位置使用canIUse，确保在ArkTS环境中

**问题3：Context获取失败**
```
Error: Cannot read property 'getUIContext' of undefined
```
**解决方法**：确保在自定义组件实例中调用，不要在非生命周期方法中使用

**问题4：hilog日志级别问题**
```
Error: hilog parameter error
```
**解决方法**：检查hilog参数格式，使用正确的日志域和标签

### 开发者调试模式限制

**问题描述**：未成年人模式开启时，开发者调试模式被禁用

**解决方法**：
1. 进入设置 > 系统 > 开发者选项
2. 点击USB调试开关
3. 系统会校验健康使用设备密码
4. 校验成功后可解除开发者调试模式限制

**hilog日志恢复**：
如DevEco Studio工具上hilog日志未恢复，执行：
```bash
hdc shell hilog -G 16M
```
扩大hilog日志缓存区，若仍无法完全展示，可取出hilog日志本地查看。

## 常见问题与解决方法

### Q1：未成年人模式未开启时调用验证接口返回错误

**原因**：verifyMinorsProtectionCredential接口要求未成年人模式必须已开启

**解决方法**：
- 调用getMinorsProtectionInfoSync先查询状态
- 如果未开启，引导用户开启未成年人模式或调用leadToTurnOnMinorsMode接口

### Q2：设备不支持未成年人模式

**原因**：设备为海外账号、隐私空间或其他不支持的环境

**解决方法**：
- 调用supportMinorsMode判断设备是否支持
- 如果不支持，提示用户当前设备环境不支持
- 可考虑构建自己的未成年人模式功能

### Q3：验证密码页面无法拉起

**原因**：Context参数错误或不在页面生命周期内调用

**解决方法**：
- 确保在自定义组件实例中使用this.getUIContext().getHostContext()
- 确保在页面或组件的生命周期方法内调用
- 不要在半模态、弹出框、子窗口中使用UIExtensionContext

### Q4：用户取消验证后如何处理

**原因**：用户主动点击关闭按钮取消验证

**解决方法**：
- 应用无需特殊处理
- 可提示用户稍后再试
- 不要强制再次拉起验证页面

### Q5：如何缓存未成年人模式状态避免频繁调用

**原因**：频繁调用接口会产生性能损耗

**解决方法**：
- 在获取结果后缓存minorsProtectionMode和ageGroup
- 订阅系统未成年人模式公共事件刷新缓存
- 只在需要验证时调用verifyMinorsProtectionCredential

### Q6：开机未解锁状态下调用getMinorsProtectionInfoSync返回false

**原因**：设备处于开机未解锁状态时，未成年人模式状态不可用

**解决方法**：
- 等待用户解锁设备后再调用
- 或使用异步接口getMinorsProtectionInfo在解锁后获取状态

## 输出结果报告

执行验证完成后输出以下信息：

```json
{
  "status": "success|failed",
  "verifyResult": true|false,
  "minorsProtectionMode": true|false,
  "ageGroup": {
    "lowerAge": 0|3|8|12|16,
    "upperAge": 3|8|12|16|18
  },
  "apiUsed": [
    "supportMinorsMode",
    "getMinorsProtectionInfoSync",
    "verifyMinorsProtectionCredential"
  ],
  "errorCode": "错误码（如有）",
  "errorMessage": "错误信息（如有）"
}
```

## 参考文档

- [应用内调整未成年人模式设置开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-password-minorsprotection)
- [minorsProtection API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-minorsprotection)
- [Account Kit错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-error-code)
- [配置签名和指纹](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-sign-fingerprints)

## 完整示例代码

- [ArkTS完整示例](assets/verify_minors_protection_example.ets)
- [订阅事件示例](assets/subscribe_minors_mode_event.ets)
- [错误处理示例](assets/error_handling_example.ets)

## 测试用例

### 正向测试用例
- [未成年人模式已开启时验证密码成功](tests/test_verify_success.py)
- [正确获取年龄段信息](tests/test_get_age_group.py)
- [订阅未成年人模式事件成功](tests/test_subscribe_event.py)

### 边界测试用例
- [未成年人模式未开启时验证失败](tests/test_minors_mode_off.py)
- [设备不支持未成年人模式](tests/test_device_not_support.py)
- [开机未解锁状态查询](tests/test_device_locked.py)

### 异常测试用例
- [参数错误（Context为null）](tests/test_invalid_context.py)
- [用户取消验证](tests/test_user_cancel.py)
- [服务不可用（隐私空间）](tests/test_service_unavailable.py)