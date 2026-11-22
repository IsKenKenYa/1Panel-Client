---
name: hmos-account-kit-minors-protection-turn-on
description: 引导用户在应用内开启系统未成年人模式，支持检查设备是否支持未成年人模式、获取未成年人模式状态、订阅未成年人模式状态变化事件，仅支持中国境内账号，适用于应用内未成年人模式开启入口、应用与系统未成年人模式联动场景
---

# 应用内开启未成年人模式技能

## 功能描述

本技能提供在应用内开启系统未成年人模式的完整实现方案。通过调用 HarmonyOS Account Kit 的未成年人模式相关 API，应用可以引导用户开启系统未成年人模式，并与系统未成年人模式状态联动，自动切换应用的未成年人模式。

主要功能包括：
- 检查设备是否支持未成年人模式
- 获取系统未成年人模式的开启状态和年龄段信息
- 引导用户开启系统未成年人模式
- 订阅系统未成年人模式开启/关闭事件
- 根据年龄段信息进行内容分级

## 使用场景

### 触发词
- "开启未成年人模式"
- "引导开启未成年人模式"
- "应用内未成年人模式"
- "未成年人保护"
- "应用与系统未成年人模式联动"

### 能做
- 检查当前设备环境是否支持未成年人模式
- 获取系统未成年人模式的开启状态（开启/关闭）
- 获取未成年人模式的年龄段信息（[0,3)、[3,8)、[8,12)、[12,16)、[16,18)）
- 引导用户开启系统未成年人模式（拉起系统设置页面）
- 订阅系统未成年人模式开启/关闭事件，自动同步状态
- 根据年龄段信息调整应用内容展示

### 绝不做
- 不支持海外账号开启未成年人模式（返回错误码 1009900007）
- 不支持在隐私空间中开启未成年人模式（返回错误码 1009900011）
- 不支持在半模态、弹出框、子窗口等非全页面组件中调用
- 不支持在页面或自定义组件生命周期外调用
- 不支持在设备开机未解锁状态下获取真实的未成年人模式状态

### 补充
- 未成年人模式开启时，设备开发者调试模式会被禁用，需在设置中验证健康使用设备密码后解除
- 开启未成年人模式后，如需弹出 toast 或弹框提示用户，必须在接口执行完成后的 then 方法中处理
- 建议缓存未成年人模式状态和年龄段信息，避免频繁调用接口造成性能损耗
- 通过订阅系统公共事件刷新缓存状态

## 调用规范和规则

### 输入约束
- Context 类型：必须是有效的 UIAbilityContext 或 UIExtensionContext
- 调用时机：必须在页面或自定义组件生命周期内调用
- 设备状态：设备必须已解锁
- 账号类型：必须是中国境内账号（香港特别行政区、澳门特别行政区、中国台湾除外）

### 执行约束
- 最大耗时：leadToTurnOnMinorsMode 接口调用无超时限制，等待用户完成操作
- 系统能力检查：必须先使用 canIUse 检查系统能力是否支持
- 设备支持检查：必须先调用 supportMinorsMode 检查设备环境是否支持
- 状态检查：开启前建议先调用 getMinorsProtectionInfoSync 或 getMinorsProtectionInfo 检查当前状态

### 内容约束
- 禁止在非全页面组件（半模态、弹出框、子窗口）中调用
- 禁止绕过设备支持检查直接调用开启接口
- 禁止在设备未解锁状态下依赖 getMinorsProtectionInfoSync 返回的状态
- 禁止在海外账号环境下强制调用（会返回错误码 1009900007）

### 降级约束
- 设备不支持未成年人模式：提示用户当前设备环境不支持，建议用户手动设置
- 海外账号登录：提示用户需登录中国境内账号，或构建应用自己的未成年人模式
- 隐私空间环境：提示用户退出隐私空间，或构建应用自己的未成年人模式
- 用户取消操作：应用无需特殊处理，保持当前状态

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 使用 canIUse 检查当前设备是否支持系统能力 SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection
2. 调用 supportMinorsMode 检查当前设备环境是否支持未成年人模式
3. 调用 getMinorsProtectionInfoSync 或 getMinorsProtectionInfo 检查当前未成年人模式状态

**参数准备**：
```typescript
import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2：检查设备支持状态

**示例代码**：
```typescript
// 检查系统能力是否支持
if (canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
  try {
    // 检查设备环境是否支持未成年人模式
    const supportMinorsMode: boolean = minorsProtection.supportMinorsMode();
    if (!supportMinorsMode) {
      hilog.info(0x0000, 'testTag',
        '当前设备环境不支持未成年人模式，请检查设备环境（可能为海外账号或隐私空间）');
      // 提供降级方案：引导用户手动设置或构建应用自己的未成年人模式
      return;
    }
    
    // 设备支持，继续后续流程
    proceedToCheckMinorsModeStatus();
  } catch (error) {
    hilog.error(0x0000, 'testTag',
      `调用 supportMinorsMode 失败。错误码: ${error.code}, 错误信息: ${error.message}`);
    // 处理内部错误（错误码 1001502009）
    handleInternalError(error);
  }
} else {
  hilog.info(0x0000, 'testTag',
    '当前设备不支持未成年人模式相关接口调用');
  // 提供降级方案
  provideFallbackSolution();
}
```

### 步骤3：检查未成年人模式状态

**示例代码**：
```typescript
function proceedToCheckMinorsModeStatus(): void {
  try {
    // 使用同步接口获取未成年人模式状态
    const minorsProtectionInfo: minorsProtection.MinorsProtectionInfo =
      minorsProtection.getMinorsProtectionInfoSync();
    
    // 获取未成年人模式开启状态
    const minorsProtectionMode: boolean = minorsProtectionInfo.minorsProtectionMode;
    
    // 建议缓存状态，避免频繁调用
    cacheMinorsModeStatus(minorsProtectionMode);
    
    hilog.info(0x0000, 'testTag',
      `未成年人模式状态: ${minorsProtectionMode ? '已开启' : '未开启'}`);
    
    if (minorsProtectionMode) {
      // 未成年人模式已开启，获取年龄段信息
      const ageGroup: minorsProtection.AgeGroup | undefined = minorsProtectionInfo.ageGroup;
      if (ageGroup) {
        hilog.info(0x0000, 'testTag',
          `年龄段信息: [${ageGroup.lowerAge}, ${ageGroup.upperAge})`);
        // 缓存年龄段信息
        cacheAgeGroupInfo(ageGroup);
        // 根据年龄段调整内容展示
        adjustContentByAgeGroup(ageGroup);
      }
      // 应用已开启自身未成年人模式，无需再次开启
    } else {
      // 未成年人模式未开启，可以引导用户开启
      guideUserToTurnOnMinorsMode();
    }
  } catch (error) {
    hilog.error(0x0000, 'testTag',
      `获取未成年人模式状态失败。错误码: ${error.code}, 错误信息: ${error.message}`);
    // 处理内部错误（错误码 1001502009）
    handleInternalError(error);
  }
}
```

### 步骤4：引导用户开启未成年人模式

**示例代码**：
```typescript
function guideUserToTurnOnMinorsMode(): void {
  try {
    // 此示例为代码片段，实际需在自定义组件实例中使用，并传入有效的 Context
    // 引导用户开启未成年人模式
    minorsProtection.leadToTurnOnMinorsMode(this.getUIContext().getHostContext())
      .then(() => {
        hilog.info(0x0000, 'testTag', '引导开启未成年人模式流程已完成');
        // 接口调用完成，如需显示弹窗提示用户，必须在此处处理
        showSuccessToast('未成年人模式已开启');
        
        // 此时应用会订阅到未成年人模式开启事件，在事件处理中更新应用状态
      })
      .catch((error: BusinessError<Object>) => {
        handleTurnOnError(error);
      });
  } catch (error) {
    hilog.error(0x0000, 'testTag',
      `调用 leadToTurnOnMinorsMode 失败。错误码: ${error.code}, 错误信息: ${error.message}`);
  }
}
```

### 步骤5：错误处理

**示例代码**：
```typescript
function handleTurnOnError(error: BusinessError<Object>): void {
  hilog.error(0x0000, 'testTag',
    `引导开启未成年人模式失败。错误码: ${error.code}, 错误信息: ${error.message}`);
  
  switch (error.code) {
    case 401:
      // 参数错误，检查 Context 是否有效
      hilog.error(0x0000, 'testTag', '参数错误：Context 无效或类型不正确');
      break;
    case 1001502009:
      // 内部错误
      hilog.error(0x0000, 'testTag', '内部错误，建议重启设备后重试');
      handleInternalError(error);
      break;
    case 1009900003:
      // 用户取消操作
      hilog.info(0x0000, 'testTag', '用户取消了开启未成年人模式操作');
      // 应用无需特殊处理
      break;
    case 1009900005:
      // 未成年人模式已经开启
      hilog.info(0x0000, 'testTag', '未成年人模式已经开启，无需重复开启');
      // 更新应用状态
      updateAppMinorsModeStatus(true);
      break;
    case 1009900007:
      // 不支持的账号（海外账号）
      hilog.error(0x0000, 'testTag',
        '当前账号不支持未成年人模式，请登录中国境内账号');
      // 提供降级方案：引导用户登录中国境内账号或构建应用自己的未成年人模式
      provideFallbackForUnsupportedAccount();
      break;
    case 1009900011:
      // 服务不可用（隐私空间）
      hilog.error(0x0000, 'testTag',
        '服务不可用，当前可能处于隐私空间，请退出隐私空间');
      // 提供降级方案
      provideFallbackForPrivacySpace();
      break;
    default:
      hilog.error(0x0000, 'testTag', `未知错误: ${error.code}`);
      break;
  }
}
```

### 步骤6：订阅未成年人模式事件

**示例代码**：
```typescript
import { commonEventManager } from '@kit.BasicServicesKit';

// 订阅未成年人模式开启事件
function subscribeMinorsModeOnEvent(): void {
  const subscriber = commonEventManager.createSubscriber({
    events: ['usual.event.MINORSMODE_ON']
  });
  
  commonEventManager.subscribe(subscriber, (err, data) => {
    if (err) {
      hilog.error(0x0000, 'testTag', `订阅未成年人模式开启事件失败: ${err.code}`);
      return;
    }
    hilog.info(0x0000, 'testTag', '收到未成年人模式开启事件');
    // 更新应用状态，开启应用内未成年人模式
    updateAppMinorsModeStatus(true);
    // 刷新年龄段信息缓存
    refreshAgeGroupInfo();
  });
}

// 订阅未成年人模式关闭事件
function subscribeMinorsModeOffEvent(): void {
  const subscriber = commonEventManager.createSubscriber({
    events: ['usual.event.MINORSMODE_OFF']
  });
  
  commonEventManager.subscribe(subscriber, (err, data) => {
    if (err) {
      hilog.error(0x0000, 'testTag', `订阅未成年人模式关闭事件失败: ${err.code}`);
      return;
    }
    hilog.info(0x0000, 'testTag', '收到未成年人模式关闭事件');
    // 更新应用状态，关闭应用内未成年人模式
    updateAppMinorsModeStatus(false);
    // 清除年龄段信息缓存
    clearAgeGroupInfoCache();
  });
}
```

### 步骤7：降级处理

**示例代码**：
```typescript
// 设备不支持时的降级方案
function provideFallbackSolution(): void {
  hilog.info(0x0000, 'testTag',
    '当前设备不支持系统未成年人模式，建议构建应用自己的未成年人模式');
  // 提示用户
  showDialog('当前设备不支持系统未成年人模式，应用将使用自己的未成年人保护机制');
  // 构建应用自己的未成年人模式
  buildAppOwnMinorsMode();
}

// 海外账号不支持时的降级方案
function provideFallbackForUnsupportedAccount(): void {
  hilog.info(0x0000, 'testTag',
    '海外账号不支持未成年人模式，建议登录中国境内账号或使用应用自己的未成年人模式');
  // 提供选项：1) 引导登录中国境内账号  2) 使用应用自己的未成年人模式
  showDialogWithOptions(
    '当前账号不支持系统未成年人模式',
    [
      { text: '登录中国境内账号', action: guideToLoginChineseAccount },
      { text: '使用应用未成年人模式', action: buildAppOwnMinorsMode }
    ]
  );
}

// 隐私空间环境时的降级方案
function provideFallbackForPrivacySpace(): void {
  hilog.info(0x0000, 'testTag',
    '隐私空间不支持未成年人模式，建议退出隐私空间或使用应用自己的未成年人模式');
  // 提供选项
  showDialogWithOptions(
    '隐私空间不支持系统未成年人模式',
    [
      { text: '退出隐私空间', action: guideToExitPrivacySpace },
      { text: '使用应用未成年人模式', action: buildAppOwnMinorsMode }
    ]
  );
}

// 处理内部错误
function handleInternalError(error: BusinessError<Object>): void {
  hilog.error(0x0000, 'testTag', `内部错误: ${error.code}`);
  // 建议：1) 重启设备后重试  2) 提交问题给华为支持
  showDialogWithOptions(
    '发生内部错误',
    [
      { text: '重启设备后重试', action: restartDevice },
      { text: '提交问题给华为支持', action: submitIssueToHuawei }
    ]
  );
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。Context 无效或类型不正确 | 确保 Context 为有效的 UIAbilityContext 或 UIExtensionContext，且在页面或自定义组件生命周期内调用 |
| 1001502009 | 内部错误 | 重启设备后重试，或提交问题给华为支持 |
| 1009900003 | 用户取消操作 | 应用无需特殊处理，保持当前状态 |
| 1009900005 | 未成年人模式已经开启 | 调用 getMinorsProtectionInfoSync 先检查状态，避免重复开启 |
| 1009900007 | 不支持的账号（海外账号） | 引导用户登录中国境内账号，或构建应用自己的未成年人模式 |
| 1009900011 | 服务不可用（隐私空间） | 引导用户退出隐私空间，或构建应用自己的未成年人模式 |

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
- HarmonyOS 版本：5.0.0(12) 及以上
- 设备类型：支持未成年人模式的 HarmonyOS 设备
- 账号类型：中国境内账号（香港特别行政区、澳门特别行政区、中国台湾除外）
- 设备状态：已解锁状态

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.AccountKit'
```
**解决方法**：确保项目已配置正确的 HarmonyOS SDK 版本（5.0.0(12) 及以上），并在 oh-package.json5 中添加依赖。

**问题2：Context 类型错误**
```
Error: Parameter error. Incorrect parameter types.
```
**解决方法**：确保在自定义组件实例中使用 this.getUIContext().getHostContext() 获取有效的 Context。

**问题3：系统能力不支持**
```
Error: The current device does not support this API.
```
**解决方法**：使用 canIUse 先检查系统能力，不支持时提供降级方案。

**问题4：开发者调试模式被禁用**
```
hilog 日志无法正常展示
```
**解决方法**：执行 `hdc shell hilog -G 16M` 扩大 hilog 日志缓存区，或取出 hilog 日志本地查看。

## 常见问题与解决方法

### Q1：海外账号无法开启未成年人模式
**原因**：未成年人模式仅支持中国境内账号（香港特别行政区、澳门特别行政区、中国台湾除外）
**解决方法**：
- 引导用户登录中国境内账号
- 构建应用自己的未成年人模式作为降级方案

### Q2：隐私空间无法使用未成年人模式
**原因**：隐私空间不支持未成年人模式服务
**解决方法**：
- 提示用户退出隐私空间
- 构建应用自己的未成年人模式作为降级方案

### Q3：设备开机未解锁状态下状态不准确
**原因**：设备开机未解锁时，getMinorsProtectionInfoSync 返回的 minorsProtectionMode 字段为 false
**解决方法**：
- 等待设备解锁后再获取状态
- 或通过订阅 COMMON_EVENT_SCREEN_UNLOCKED 事件，在解锁后刷新状态

### Q4：重复开启未成年人模式报错
**原因**：未成年人模式已开启时再次调用 leadToTurnOnMinorsMode 返回错误码 1009900005
**解决方法**：
- 开启前先调用 getMinorsProtectionInfoSync 检查当前状态
- 如果已开启，则直接更新应用状态，无需再次调用开启接口

### Q5：Toast 提示无法正常显示
**原因**：在接口调用过程中弹出 Toast，系统页面未完全关闭导致 Toast 无法展示
**解决方法**：
- 在接口的 then 方法中弹出 Toast 或弹框
- 确保系统页面完全关闭后再显示提示信息

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "minorsProtectionMode": true,
  "ageGroup": {
    "lowerAge": 3,
    "upperAge": 8
  },
  "apiUsed": [
    "supportMinorsMode",
    "getMinorsProtectionInfoSync",
    "leadToTurnOnMinorsMode"
  ],
  "eventsSubscribed": [
    "COMMON_EVENT_MINORSMODE_ON",
    "COMMON_EVENT_MINORSMODE_OFF"
  ]
}
```

## 参考文档

- [API开发指南 - 应用内开启未成年人模式](references/account-app-turn-on-minorsprotection.md)
- [API参考说明 - minorsProtection](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-minorsprotection)
- [API错误码说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-error-code)
- [系统公共事件定义](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/commoneventmanager-definitions)

## 完整示例代码

- [ArkTS 完整示例](assets/minors-protection-turn-on-example.ets)
- [订阅事件示例](assets/minors-protection-events-subscription.ets)
- [降级处理示例](assets/minors-protection-fallback.ets)

## 测试用例

### 正向测试用例
- [测试设备支持未成年人模式](tests/test_positive_support.py)：测试 supportMinorsMode 返回 true 的场景
- [测试获取未成年人模式状态](tests/test_positive_get_status.py)：测试成功获取未成年人模式开启状态和年龄段信息
- [测试引导开启未成年人模式](tests/test_positive_turn_on.py)：测试成功引导用户开启未成年人模式

### 边界测试用例
- [测试未成年人模式已开启](tests/test_boundary_already_on.py)：测试未成年人模式已开启时调用接口返回错误码 1009900005
- [测试设备开机未解锁状态](tests/test_boundary_locked_device.py)：测试设备未解锁时获取状态的准确性
- [测试年龄段边界值](tests/test_boundary_age_group.py)：测试年龄段信息为 [0,3)、[16,18) 等边界值

### 异常测试用例
- [测试海外账号](tests/test_exception_overseas_account.py)：测试海外账号调用返回错误码 1009900007
- [测试隐私空间](tests/test_exception_privacy_space.py)：测试隐私空间调用返回错误码 1009900011
- [测试参数错误](tests/test_exception_invalid_context.py)：测试无效 Context 调用返回错误码 401
- [测试用户取消操作](tests/test_exception_user_cancel.py)：测试用户取消操作返回错误码 1009900003