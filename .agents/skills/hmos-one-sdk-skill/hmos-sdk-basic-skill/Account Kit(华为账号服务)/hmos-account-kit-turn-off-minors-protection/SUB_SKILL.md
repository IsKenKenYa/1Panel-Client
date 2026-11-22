---
name: hmos-account-kit-turn-off-minors-protection
description: 关闭系统未成年人模式，支持Stage模型应用通过leadToTurnOffMinorsMode接口引导用户关闭系统未成年人模式，验证家长密码后关闭整个系统的未成年人模式，适用于应用内关闭未成年人模式场景
---

# 关闭系统的未成年人模式技能

## 功能描述

本技能提供关闭系统未成年人模式的完整实现方案。当系统未成年人模式已开启时，应用可调用系统的未成年人模式关闭接口leadToTurnOffMinorsMode，验证家长密码后关闭系统的未成年人模式。

**核心能力**：
- 检测当前设备是否支持未成年人模式
- 获取系统未成年人模式的当前状态
- 引导用户关闭系统未成年人模式（验证家长密码）
- 订阅系统未成年人模式状态变化事件

**技术特点**：
- 支持Stage模型应用和元服务
- Promise异步回调模式
- 需在页面或自定义组件生命周期内调用
- 无需配置公钥指纹、Client ID和账号权限

## 使用场景

### 触发词
- "关闭系统未成年人模式"
- "关闭未成年人保护模式"
- "应用内关闭未成年人模式"
- "关闭整个系统的未成年人模式"
- "关闭家长控制模式"

### 能做
- 在系统未成年人模式已开启状态下，引导用户关闭系统未成年人模式
- 验证家长密码后关闭整个系统的未成年人模式（包括其他应用/元服务的未成年人模式）
- 获取系统未成年人模式的开启状态和年龄段信息
- 订阅未成年人模式开启/关闭的公共事件
- 提供完整的错误处理和用户提示机制

### 绝不做
- 不在非全页面组件（半模态、弹出框、子窗口等）中调用leadToTurnOffMinorsMode接口
- 不在未成年人模式未开启时调用关闭接口
- 不在不支持未成年人模式的设备上调用接口
- 不在隐私空间或海外账号登录状态下调用接口
- 不绕过UIExtensionContext限制调用接口

### 补充
- 该接口需在页面或自定义组件生命周期内调用，传入有效的Context上下文对象
- 关闭系统未成年人模式会影响整个设备的所有应用和元服务
- 建议在界面上明确告知用户即将关闭系统的未成年人模式
- 如需弹出toast或弹框告知用户，须在接口执行完成后的then方法里面弹出
- 设备处于开机未解锁状态时，getMinorsProtectionInfoSync返回的minorsProtectionMode字段为false

## 调用规范和规则

### 输入约束
- Context类型：应用支持UIAbilityContext和UIExtensionContext，元服务仅支持UIAbilityContext
- 调用位置：必须在页面或自定义组件生命周期内调用
- 系统状态：系统未成年人模式必须为开启状态
- 设备支持：当前设备环境必须支持未成年人模式
- 账号类型：必须登录中国境内（香港特别行政区、澳门特别行政区、中国台湾除外）的华为账号

### 执行约束
- 调用时机：在自定义组件实例中使用，传入有效的Context上下文对象
- 最大耗时：依赖用户操作完成验证，通常10-60秒
- 调用频次：无频次限制，但避免重复调用关闭接口
- 异步处理：使用Promise异步回调，需正确处理then和catch
- 状态检测：调用前必须使用getMinorsProtectionInfoSync或getMinorsProtectionInfo检测未成年人模式状态

### 内容约束
- 禁止在半模态、弹出框、子窗口等非全页面组件中使用UIExtensionContext调用
- 禁止绕过设备支持性检测直接调用接口
- 禁止在未成年人模式已关闭状态下调用关闭接口
- 禁止使用UIExtensionContext在非全页面组件中调用
- Toast提示必须在接口执行完成后的then方法里面弹出，避免系统页面未完全关闭导致toast无法展示

### 降级约束
- 设备不支持：提示用户"当前设备环境不支持未成年人模式"
- 未成年人模式已关闭：无需调用关闭接口，直接关闭应用未成年人模式
- 用户取消操作：处理用户取消逻辑，不强制重试
- 服务不可用：提示用户退出隐私空间，或引导用户构建自己的未成年人模式
- 账号不支持：引导用户登录中国境内账号
- 网络错误：提示用户检查网络连接后重试
- 内部错误：重启设备后重试，或引导用户提交在线反馈

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查当前设备是否支持SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection系统能力
2. 使用canIUse判断当前设备是否支持调用接口
3. 检查当前设备环境是否支持未成年人模式（supportMinorsMode）
4. 获取当前系统未成年人模式状态（getMinorsProtectionInfoSync或getMinorsProtectionInfo）
5. 确认系统未成年人模式为开启状态

**参数准备**：
```typescript
// 导入必要模块
import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 准备Context上下文对象（需要在自定义组件实例中获取）
const context = this.getUIContext().getHostContext();
```

### 步骤2：检测设备支持和状态

**示例代码**：
```typescript
// 检查系统能力
if (canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
  try {
    // 检查设备是否支持未成年人模式
    if (minorsProtection.supportMinorsMode()) {
      // 获取系统未成年人模式状态
      const minorsProtectionInfo = minorsProtection.getMinorsProtectionInfoSync();
      const minorsProtectionMode = minorsProtectionInfo.minorsProtectionMode;
      
      // 确认系统未成年人模式已开启
      if (minorsProtectionMode) {
        // 继续执行关闭流程
        console.log('系统未成年人模式已开启，可以执行关闭操作');
      } else {
        // 未成年人模式未开启，无需关闭
        console.log('系统未成年人模式未开启');
      }
    } else {
      hilog.info(0x0000, 'testTag',
        'The current device environment does not support the minors mode, please check the current device environment.');
    }
  } catch (error) {
    hilog.error(0x0000, 'testTag',
      `Failed to check minors mode status. errCode: ${error.code}, errMessage: ${error.message}`);
  }
} else {
  hilog.info(0x0000, 'testTag',
    'The current device does not support the calling of the leadToTurnOffMinorsMode interface.');
}
```

### 步骤3：调用关闭接口

**示例代码**：
```typescript
// 引导用户关闭系统未成年人模式
minorsProtection.leadToTurnOffMinorsMode(this.getUIContext().getHostContext())
  .then(() => {
    // 接口调用完成，如需显示弹窗，请在此处处理
    console.log('系统未成年人模式已关闭');
    // 此处可以弹出toast或弹框告知用户"未成年人模式已关闭"
  })
  .catch((error: BusinessError<Object>) => {
    // 错误处理
    dealTurnOffAllError(error);
  });
```

### 步骤4：错误处理

**错误处理代码**：
```typescript
function dealTurnOffAllError(error: BusinessError<Object>): void {
  hilog.error(0x0000, 'testTag', 
    `Failed to leadToTurnOffMinorsMode. Code: ${error.code}, message: ${error.message}`);
  
  // 根据错误码进行针对性处理
  switch (error.code) {
    case 1009900003:
      // 用户取消操作
      console.log('用户取消了关闭未成年人模式操作');
      // 处理用户取消的逻辑，无需强制重试
      break;
    case 1009900006:
      // 未成年人模式已经关闭
      console.log('未成年人模式已经关闭，无需重复调用');
      break;
    case 1009900011:
      // 服务不可用（可能进入隐私空间）
      console.log('服务不可用，请退出隐私空间后重试');
      // 提示用户退出隐私空间，或构建自己的未成年人模式
      break;
    case 401:
      // 参数错误
      console.log('参数错误，请检查Context参数是否正确');
      break;
    case 1001502009:
      // 内部错误
      console.log('内部错误，请重启设备后重试');
      break;
    default:
      console.log(`未知错误: ${error.message}`);
      // 引导用户提交在线反馈
      break;
  }
}
```

### 步骤5：订阅状态变化事件

**订阅系统未成年人模式事件**：
```typescript
import { commonEventManager } from '@kit.BasicServicesKit';

// 订阅未成年人模式开启事件
const subscribeMinorsModeOn = commonEventManager.subscribe(
  'usual.event.MINORSMODE_ON',
  (data) => {
    console.log('收到未成年人模式开启事件');
    // 刷新未成年人模式开启状态或年龄段信息
  }
);

// 订阅未成年人模式关闭事件
const subscribeMinorsModeOff = commonEventManager.subscribe(
  'usual.event.MINORSMODE_OFF',
  (data) => {
    console.log('收到未成年人模式关闭事件');
    // 刷新未成年人模式开启状态，关闭应用未成年人模式
  }
);
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：必填参数未指定；参数类型不正确 | 检查Context参数是否正确，确保传入有效的UIAbilityContext或UIExtensionContext |
| 1001502009 | 内部错误 | 重启设备后重试；若问题仍无法解决，通过在线提单提交问题 |
| 1009900003 | 用户取消操作 | 处理用户取消的逻辑，无需强制重试 |
| 1009900006 | 未成年人模式已经关闭 | 调用getMinorsProtectionInfoSync或getMinorsProtectionInfo判断当前状态，如已关闭无需重复调用 |
| 1009900011 | 服务不可用 | 提醒用户进入"设置">"隐私和安全">"隐私空间"退出隐私空间，或构建自己的未成年人模式 |

**错误处理建议**：
- 参数错误(401)：检查Context是否有效，确保在自定义组件实例中调用
- 用户取消(1009900003)：这是用户主动行为，应用无需特殊处理，可记录日志
- 已关闭(1009900006)：调用前先检查状态，避免重复调用
- 服务不可用(1009900011)：引导用户退出隐私空间或使用替代方案
- 内部错误(1001502009)：提供重试机制，记录错误信息便于排查

## 编译和修复问题

### 依赖声明

**package.json配置**：
```json
{
  "dependencies": {
    "@kit.AccountKit": "^5.0.0",
    "@kit.PerformanceAnalysisKit": "^5.0.0",
    "@kit.BasicServicesKit": "^5.0.0"
  }
}
```

**module.json5配置**：
```json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "deviceTypes": [
      "default",
      "tablet",
      "2in1"
    ],
    "abilities": [
      {
        "name": "MainAbility",
        "srcEntry": "./ets/mainability/MainAbility.ts",
        "description": "$string:mainability_description",
        "icon": "$media:icon",
        "label": "$string:mainability_label",
        "visible": true,
        "launchType": "standard"
      }
    ]
  }
}
```

### 环境要求
- HarmonyOS API版本：5.0.0(12)及以上
- 开发环境：DevEco Studio 5.0及以上
- 设备类型：手机、平板、PC/2in1
- 账号要求：中国境内（香港特别行政区、澳门特别行政区、中国台湾除外）华为账号

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.AccountKit'
```
**解决方法**：
- 确保HarmonyOS SDK版本为5.0.0(12)及以上
- 在DevEco Studio中检查SDK配置
- 确保package.json中正确声明依赖

**问题2：Context参数类型错误**
```
Error: Parameter error. Incorrect parameter types.
```
**解决方法**：
- 确保在自定义组件实例中调用，使用`this.getUIContext().getHostContext()`
- 不要使用半模态、弹出框、子窗口等非全页面组件的Context
- 检查Context类型是否符合要求

**问题3：系统能力不支持**
```
Error: The current device does not support this API.
```
**解决方法**：
- 使用`canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')`判断设备支持性
- 在不支持设备上提供替代方案或提示用户

**问题4：开发调试模式被禁用**
```
未成年人模式开启时，USB调试被禁用
```
**解决方法**：
- 进入设置-系统-开发者选项，点击USB调试开关
- 校验健康使用设备密码，校验成功后可解除开发者调试模式限制
- 如hilog日志未恢复，执行`hdc shell hilog -G 16M`扩大缓存区

## 常见问题与解决方法

### Q1：在非全页面组件中调用接口失败
**原因**：UIExtensionContext不支持在半模态、弹出框、子窗口等非全页面组件中使用
**解决方法**：
- 确保在页面或自定义组件生命周期内调用
- 使用UIAbilityContext或确保在全页面组件中使用UIExtensionContext
- 检查调用位置是否符合要求

### Q2：Toast提示无法正常展示
**原因**：在接口执行完成前弹出toast，系统页面未完全关闭
**解决方法**：
- 在接口的then方法里面弹出toast或弹框
- 不要在调用接口的同时弹出提示
- 确保系统页面完全关闭后再显示提示

### Q3：未成年人模式状态检测不准确
**原因**：设备处于开机未解锁状态
**解决方法**：
- 设备解锁后再调用getMinorsProtectionInfoSync
- 理解在未解锁状态下minorsProtectionMode字段返回false的限制
- 建议缓存状态并通过订阅公共事件刷新状态

### Q4：频繁调用接口性能损耗
**原因**：重复调用状态查询接口
**解决方法**：
- 在获取结果后进行缓存
- 通过订阅系统未成年人模式公共事件来刷新状态
- 避免重复调用接口带来的性能损耗

### Q5：海外账号调用失败
**原因**：登录了海外华为账号
**解决方法**：
- 引导用户登录中国境内（香港特别行政区、澳门特别行政区、中国台湾除外）华为账号
- 或构建自己的未成年人模式实现方案
- 检查账号注册地是否符合要求

### Q6：隐私空间中无法调用
**原因**：设备进入隐私空间
**解决方法**：
- 提醒用户进入"设置">"隐私和安全">"隐私空间"退出隐私空间
- 或引导用户构建自己的未成年人模式
- 检查当前设备环境是否为隐私空间

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "关闭系统未成年人模式",
  "minorsProtectionMode": false,
  "apiUsed": [
    "supportMinorsMode",
    "getMinorsProtectionInfoSync",
    "leadToTurnOffMinorsMode"
  ],
  "contextType": "UIAbilityContext/UIExtensionContext",
  "deviceSupported": true,
  "userAction": "验证家长密码成功",
  "timestamp": "2026-07-03T12:00:00Z"
}
```

**输出字段说明**：
- `status`: 执行状态（success/failed/canceled）
- `operation`: 执行的操作类型
- `minorsProtectionMode`: 关闭后的未成年人模式状态（false）
- `apiUsed`: 调用的API列表
- `contextType`: 使用的Context类型
- `deviceSupported`: 设备是否支持未成年人模式
- `userAction`: 用户操作结果
- `timestamp`: 执行时间戳

## 参考文档

- [API开发指南](references/account-system-turn-off-minorsprotection.md)
- [API参考说明](references/account-api-minorsprotection.md)
- [错误码参考](references/account-api-error-code.md)
- [配置签名和指纹](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-sign-fingerprints)
- [系统未成年人模式公共事件](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/commoneventmanager-definitions)

## 完整示例代码

- [ArkTS完整示例](assets/turn_off_minors_protection_example.ets)
- [订阅事件示例](assets/subscribe_minors_mode_event.ets)
- [错误处理示例](assets/error_handler.ets)

## 测试用例

### 正向测试用例
- [正常关闭未成年人模式](tests/test_positive_normal_off.ts)：系统未成年人模式已开启，验证家长密码成功后关闭
- [检测设备支持](tests/test_positive_check_support.ts)：正确检测设备是否支持未成年人模式
- [获取状态信息](tests/test_positive_get_status.ts)：正确获取系统未成年人模式状态和年龄段信息

### 边界测试用例
- [未成年人模式已关闭](tests/test_boundary_already_off.ts)：系统未成年人模式已关闭状态下调用接口
- [设备不支持](tests/test_boundary_not_support.ts)：在不支持未成年人模式的设备上调用接口
- [隐私空间场景](tests/test_boundary_privacy_space.ts)：在隐私空间状态下调用接口

### 异常测试用例
- [参数错误](tests/test_exception_invalid_param.ts)：传入无效的Context参数
- [用户取消操作](tests/test_exception_user_cancel.ts)：用户主动取消关闭操作
- [网络错误](tests/test_exception_network_error.ts)：网络不可用时的错误处理
- [内部错误](tests/test_exception_internal_error.ts)：系统内部错误时的处理
- [海外账号场景](tests/test_exception_overseas_account.ts)：海外账号登录状态下调用接口

**测试说明**：
- 正向测试验证核心功能的正确性
- 边界测试验证极端场景的处理逻辑
- 异常测试验证错误处理和降级方案
- 所有测试用例需覆盖错误码和异常场景