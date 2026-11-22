---
name: hmos-account-kit-minorsprotection-app-turnoff
description: 关闭应用的未成年人模式，验证家长身份后单独关闭应用未成年人模式，系统未成年人模式保持开启，适用于应用内单独关闭未成年人模式场景
---

# 关闭应用的未成年人模式技能

## 功能描述

本技能提供在应用内单独关闭未成年人模式的功能。当系统未成年人模式已开启时，用户可通过验证家长身份（未成年人模式密码）后，单独关闭应用的未成年人模式，系统的未成年人模式仍保持开启状态。开发者需要在应用侧记录单独关闭状态（如userTurnOffFlag），便于后续与系统重新联动。

相较于关闭系统的未成年人模式，单独关闭应用的未成年人模式更为灵活，且符合用户体验预期。建议开发者在界面上告知用户，当前仅关闭应用的未成年人模式，但系统的未成年人模式仍保持开启，避免用户误解。

## 使用场景

### 触发词
- "关闭应用的未成年人模式"
- "单独关闭未成年人模式"
- "应用内关闭未成年人模式"
- "关闭未成年人模式（推荐）"
- "验证未成年人模式密码"

### 能做
- 获取系统未成年人模式的开启状态和年龄段信息
- 查询当前设备是否支持未成年人模式
- 验证未成年人模式密码（家长身份验证）
- 单独关闭应用的未成年人模式
- 记录和缓存应用侧的关闭状态标记

### 绝不做
- 不关闭系统的未成年人模式（仅关闭应用侧）
- 不在未成年人模式未开启时调用验证密码接口
- 不在非全页面组件（半模态、弹出框、子窗口）中调用验证接口
- 不使用海外账号或隐私空间账号调用相关接口
- 不在未成年人模式关闭状态下重复调用关闭接口

### 补充
- 验证接口必须在页面或自定义组件生命周期内调用
- 未成年人模式开启时，设备的开发者调试模式会被禁用
- 当设备处于开机未解锁状态时，getMinorsProtectionInfoSync返回的minorsProtectionMode字段为false
- 建议缓存未成年人模式开启状态和年龄段信息，避免重复调用接口
- 需要订阅系统未成年人模式开启或关闭事件来刷新状态
- 此接口无需配置公钥指纹、Client ID，也无需申请账号权限

## 调用规范和规则

### 输入约束
- 未成年人模式必须已开启（调用验证接口前需检查）
- 必须提供有效的Context上下文对象（UIAbilityContext或UIExtensionContext）
- Context必须在页面或自定义组件实例中获取
- 不支持在非全页面组件中使用UIExtensionContext调用

### 执行约束
- 验证接口调用必须在页面或自定义组件生命周期内执行
- 最大验证等待时间：用户输入密码时间不确定，需提供超时或取消机制
- 系统未成年人模式状态查询建议使用缓存机制，避免频繁调用
- 必须订阅系统未成年人模式事件（COMMON_EVENT_MINORSMODE_ON/OFF）

### 内容约束
- 禁止绕过验证直接关闭应用未成年人模式
- 禁止使用虚假或错误的Context对象
- 禁止在未成年人模式未开启状态下调用验证接口
- 禁止不记录关闭状态标记导致后续无法与系统联动

### 降级约束
- 未成年人模式未开启：提示用户需要先开启未成年人模式
- 设备不支持未成年人模式：提示用户当前设备环境不支持
- 用户取消验证：正常处理取消逻辑，应用无需特殊处理
- 服务不可用（隐私空间）：提醒用户退出隐私空间或构建自己的未成年人模式
- 网络错误：检查网络连接，提示用户网络异常

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查当前设备是否支持未成年人模式：调用`supportMinorsMode()`
2. 检查系统能力：使用`canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')`
3. 检查系统未成年人模式是否已开启：调用`getMinorsProtectionInfoSync()`或`getMinorsProtectionInfo()`
4. 确认Context对象有效：在自定义组件实例中获取UIContext

**参数准备**：
```typescript
import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const userTurnOffFlag: boolean = false;
```

### 步骤2：获取未成年人模式状态

**示例代码**：
```typescript
async function checkMinorsProtectionStatus(): Promise<boolean> {
  try {
    if (canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
      if (minorsProtection.supportMinorsMode()) {
        const minorsProtectionInfo: minorsProtection.MinorsProtectionInfo =
          minorsProtection.getMinorsProtectionInfoSync();
        const minorsProtectionMode: boolean = minorsProtectionInfo.minorsProtectionMode;
        hilog.info(0x0000, 'testTag',
          `Succeeded in getting minorsProtectionMode is: ${minorsProtectionMode.valueOf()}`);
        return minorsProtectionMode;
      } else {
        hilog.info(0x0000, 'testTag',
          'The current device environment does not support the minors mode.');
        return false;
      }
    } else {
      hilog.info(0x0000, 'testTag',
        'The current device does not support the minors protection capability.');
      return false;
    }
  } catch (error) {
    hilog.error(0x0000, 'testTag',
      `Failed to get minors protection status. errCode: ${error.code}, errMessage: ${error.message}`);
    return false;
  }
}
```

### 步骤3：验证未成年人模式密码

**示例代码**：
```typescript
async function verifyAndTurnOffMinorsProtection(context: common.Context): Promise<boolean> {
  try {
    const minorsModeEnabled: boolean = await checkMinorsProtectionStatus();
    if (!minorsModeEnabled) {
      hilog.warn(0x0000, 'testTag', 'Minors mode is not enabled, cannot verify.');
      return false;
    }

    const verifyResult: boolean = await minorsProtection.verifyMinorsProtectionCredential(context);
    hilog.info(0x0000, 'testTag', `Succeeded in getting verify result is: ${verifyResult.valueOf()}`);

    if (verifyResult) {
      userTurnOffFlag = true;
      hilog.info(0x0000, 'testTag', 'Application minors mode turned off successfully.');
      return true;
    } else {
      hilog.warn(0x0000, 'testTag', 'Verification failed, minors mode password incorrect.');
      return false;
    }
  } catch (error) {
    const businessError: BusinessError<Object> = error as BusinessError<Object>;
    dealVerifyAllError(businessError);
    return false;
  }
}
```

### 步骤4：错误处理

```typescript
function dealVerifyAllError(error: BusinessError<Object>): void {
  hilog.error(0x0000, 'testTag', `Failed to verify. Code: ${error.code}, message: ${error.message}`);
  switch (error.code) {
    case 1009900002:
      hilog.error(0x0000, 'testTag', 'Minors mode is not enabled.');
      break;
    case 1009900003:
      hilog.warn(0x0000, 'testTag', 'User canceled the operation.');
      break;
    case 1001502009:
      hilog.error(0x0000, 'testTag', 'Internal error occurred.');
      break;
    case 401:
      hilog.error(0x0000, 'testTag', 'Parameter error. Context is invalid.');
      break;
    default:
      hilog.error(0x0000, 'testTag', `Unknown error: ${error.message}`);
  }
}
```

### 步骤5：订阅系统事件

**示例代码**：
```typescript
import { commonEventManager } from '@kit.BasicServicesKit';

function subscribeMinorsModeEvents(): void {
  const subscriber = commonEventManager.createSubscriber({
    events: [
      commonEventManager.CommonEventSupport.COMMON_EVENT_MINORSMODE_ON,
      commonEventManager.CommonEventSupport.COMMON_EVENT_MINORSMODE_OFF
    ]
  });

  commonEventManager.subscribeCommonEvent(subscriber, (err, data) => {
    if (err) {
      hilog.error(0x0000, 'testTag', `Failed to subscribe event: ${err.message}`);
      return;
    }
    if (data.event === commonEventManager.CommonEventSupport.COMMON_EVENT_MINORSMODE_ON) {
      hilog.info(0x0000, 'testTag', 'Minors mode turned on.');
      if (!userTurnOffFlag) {
        const info = minorsProtection.getMinorsProtectionInfoSync();
        if (info.ageGroup) {
          hilog.info(0x0000, 'testTag',
            `Age group: [${info.ageGroup.lowerAge}, ${info.ageGroup.upperAge})`);
        }
      }
    } else if (data.event === commonEventManager.CommonEventSupport.COMMON_EVENT_MINORSMODE_OFF) {
      hilog.info(0x0000, 'testTag', 'Minors mode turned off.');
      userTurnOffFlag = false;
    }
  });
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1009900002 | 未成年人模式未开启 | 调用验证接口前先检查未成年人模式状态，如未开启则提示用户先开启 |
| 1009900003 | 用户取消操作 | 正常处理用户取消逻辑，应用无需特殊处理 |
| 1001502009 | 内部错误 | 重启设备后重试，若无法解决则通过在线提单提交问题 |
| 401 | 参数错误，Context无效或未传入 | 确保传入有效的Context对象，且在页面或自定义组件实例中获取 |
| 1009900007 | 不支持的账号 | 引导用户登录中国境内账号（香港、澳门、台湾除外） |
| 1009900011 | 服务不可用（隐私空间） | 提醒用户退出隐私空间或构建自己的未成年人模式 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AccountKit": "^5.0.0(12)",
    "@kit.PerformanceAnalysisKit": "^5.0.0(12)",
    "@kit.BasicServicesKit": "^5.0.0(12)"
  }
}
```

### 环境要求
- HarmonyOS API版本：5.0.0(12)及以上
- 模型约束：仅可在Stage模型下使用
- 系统能力：SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection

### 常见编译问题

**问题1：Context对象无效**
```
Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types.
```
**解决方法**：确保在自定义组件实例中通过`this.getUIContext().getHostContext()`获取Context对象

**问题2：未成年人模式未开启调用验证接口**
```
The minors mode is not enabled. (1009900002)
```
**解决方法**：调用验证接口前，先使用`getMinorsProtectionInfoSync()`检查未成年人模式状态

**问题3：开发者调试模式被禁用**
```
hilog日志无法显示
```
**解决方法**：执行`hdc shell hilog -G 16M`扩大hilog日志缓存区，或在设置中重新开启USB调试

## 常见问题与解决方法

### Q1：验证接口返回1009900002错误码
**原因**：未成年人模式未开启就调用验证接口
**解决方法**：
- 调用`getMinorsProtectionInfoSync()`检查未成年人模式状态
- 如果未开启，提示用户需要先开启未成年人模式
- 参考[应用内开启未成年人模式](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-app-turn-on-minorsprotection)文档

### Q2：应用重启后如何处理关闭状态？
**原因**：应用重启时需要根据记录的关闭状态标记决定是否与系统联动
**解决方法**：
- 应用启动时查询`userTurnOffFlag`缓存状态
- 如果为true，保持应用的未成年人模式关闭状态
- 如果为false，与系统未成年人模式联动
- 订阅系统未成年人模式事件刷新状态

### Q3：如何处理用户取消验证？
**原因**：用户主动点击页面关闭按钮取消验证
**解决方法**：
- 错误码1009900003表示用户取消操作
- 应用无需特殊处理，正常响应取消逻辑
- 可提示用户验证已取消

### Q4：设备不支持未成年人模式怎么办？
**原因**：海外账号、隐私空间等场景不支持未成年人模式
**解决方法**：
- 调用`supportMinorsMode()`检查设备环境
- 如果返回false，提示用户当前设备环境不支持
- 可引导用户退出隐私空间或构建自己的未成年人模式

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "minorsProtectionMode": "boolean",
  "verificationResult": "boolean",
  "userTurnOffFlag": "boolean",
  "apiUsed": [
    "supportMinorsMode",
    "getMinorsProtectionInfoSync",
    "verifyMinorsProtectionCredential"
  ]
}
```

## 参考文档

- [API开发指南 - 关闭应用的未成年人模式（推荐）](references/account-appself-turn-off-minorsprotection.md)
- [API参考 - minorsProtection](references/account-api-minorsprotection.md)
- [错误码说明](references/account-api-error-code.md)
- [配置签名和指纹](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-sign-fingerprints)

## 完整示例代码

- [ArkTS示例 - 关闭应用未成年人模式](assets/minors_protection_turnoff_example.ets)

## 测试用例

### 正向测试用例
- [正常关闭应用未成年人模式](tests/test_positive.ts)：未成年人模式已开启，验证密码成功后关闭
- [查询未成年人模式状态](tests/test_positive.ts)：成功获取开启状态和年龄段信息
- [订阅系统事件](tests/test_positive.ts)：成功订阅未成年人模式开启/关闭事件

### 边界测试用例
- [设备不支持未成年人模式](tests/test_boundary.ts)：海外账号或隐私空间场景
- [开机未解锁状态查询](tests/test_boundary.ts)：设备未解锁时状态查询
- [重复关闭状态标记](tests/test_boundary.ts)：已关闭状态下再次尝试关闭

### 异常测试用例
- [未成年人模式未开启](tests/test_exception.ts)：调用验证接口返回1009900002错误
- [用户取消验证](tests/test_exception.ts)：用户主动取消验证操作
- [Context无效](tests/test_exception.ts)：传入无效Context对象返回401错误
- [网络错误](tests/test_exception.ts)：网络异常导致接口调用失败