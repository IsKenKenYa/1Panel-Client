---
name: hmos-localization-kit-system-language-region
description: 获取系统语言、地区、区域信息并监听系统语言地区变化，支持读取系统当前语言地区设置及响应系统语言地区切换事件，适用于国际化应用开发、多语言适配、系统语言切换响应场景
---

# 系统语言与区域技能

## 功能描述

本技能提供系统语言与区域信息的获取和监听能力，包括：
- 获取系统当前语言、地区、区域信息
- 监听系统语言、地区、区域的变化事件
- 提供系统语言地区的实时查询接口
- 支持应用国际化场景下的语言地区适配

本技能基于HarmonyOS Localization Kit的i18n模块实现，为开发者提供便捷的系统语言地区信息获取方式，帮助应用实现国际化和本地化功能。

## 使用场景

### 触发词
- "获取系统语言"
- "获取系统地区"
- "获取系统区域"
- "监听系统语言变化"
- "监听语言地区切换"
- "系统语言地区信息"
- "国际化语言获取"

### 能做
- 获取系统当前设置的语言（如中文、英文等）
- 获取系统当前设置的地区（如CN、US等）
- 获取系统当前的区域对象（包含语言、地区等信息）
- 监听系统语言、地区、区域的变化事件，实时响应用户切换
- 在应用启动时获取系统语言地区信息，用于初始化国际化配置
- 在系统语言切换时自动调整应用语言和资源

### 绝不做
- 不修改系统语言地区设置（仅读取，不写入）
- 不处理应用内部的语言切换逻辑（仅关注系统级别的语言地区）
- 不提供语言地区翻译功能（仅提供获取接口）
- 不处理超出Localization Kit范围的国际化需求

### 补充
- 系统语言地区变化监听需要通过公共事件机制实现
- 从API version 21开始，开发者模式下可通过param工具获取系统语言
- 系统语言切换时会自动清理不匹配的扩展参数（如本地数字设置）
- 本技能适用于需要在应用启动或运行时感知系统语言地区变化的场景

## 调用规范和规则

### 输入约束
- 无必需的输入参数（系统语言地区信息由系统提供）
- 监听事件时需要提供事件订阅配置，事件类型为COMMON_EVENT_LOCALE_CHANGED
- 不接受自定义语言地区参数（仅读取系统设置）

### 执行约束
- API调用为同步调用，无耗时限制
- 监听事件订阅建议在应用启动时完成
- 事件监听需要在应用退出时主动取消订阅
- 最大并发监听订阅数量：无限制

### 内容约束
- 禁止修改系统语言地区设置
- 禁止在监听回调中执行耗时超过5秒的操作
- 禁止在监听回调中阻塞主线程
- 必须在应用退出时取消事件订阅，避免内存泄漏

### 降级约束
- 监听事件订阅失败时，提供定时轮询方案（建议间隔30秒）
- 获取系统语言地区失败时，提供默认值降级方案（默认语言：zh-Hans，默认地区：CN）
- 公共事件订阅异常时，提供日志记录并建议开发者检查系统权限

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查是否导入必要的模块：@kit.LocalizationKit和@kit.BasicServicesKit
2. 检查应用是否有订阅公共事件的权限
3. 验证运行环境是否支持i18n.System API（API version ≥ 9）

**参数准备**：
```typescript
// 导入必要模块
import { i18n } from '@kit.LocalizationKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';
```

### 步骤2：获取系统语言地区信息

**示例代码**：
```typescript
// 获取系统语言
let systemLanguage: string = i18n.System.getSystemLanguage();  // systemLanguage为当前系统语言
console.info(`当前系统语言: ${systemLanguage}`); // 例如: 'zh-Hans'

// 获取系统地区
let systemRegion: string = i18n.System.getSystemRegion();  // systemRegion为当前系统地区
console.info(`当前系统地区: ${systemRegion}`); // 例如: 'CN'

// 获取系统区域对象
let systemLocale: Intl.Locale = i18n.System.getSystemLocaleInstance();  // systemLocale为当前系统区域
console.info(`当前系统区域: ${systemLocale.toString()}`); // 例如: 'zh-Hans-CN'
```

### 步骤3：监听系统语言地区变化

**示例代码**：
```typescript
// 定义订阅者对象用于后续退订
let subscriber: commonEventManager.CommonEventSubscriber | null = null;

// 创建订阅配置
let subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
  events: [commonEventManager.Support.COMMON_EVENT_LOCALE_CHANGED]
};

// 创建订阅者并订阅事件
commonEventManager.createSubscriber(subscribeInfo)
  .then((commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
    console.info('成功创建订阅者');
    subscriber = commonEventSubscriber;
    
    // 订阅系统语言地区变化事件
    commonEventManager.subscribe(subscriber, (err, data) => {
      if (err) {
        console.error(`订阅事件失败，错误码: ${err.code}, 错误信息: ${err.message}`);
        return;
      }
      console.info('系统语言、系统地区或系统区域发生变化');
      
      // 在回调中重新获取系统语言地区信息
      let newSystemLanguage = i18n.System.getSystemLanguage();
      let newSystemRegion = i18n.System.getSystemRegion();
      let newSystemLocale = i18n.System.getSystemLocaleInstance();
      
      console.info(`新系统语言: ${newSystemLanguage}`);
      console.info(`新系统地区: ${newSystemRegion}`);
      console.info(`新系统区域: ${newSystemLocale.toString()}`);
      
      // 在此处执行应用语言切换逻辑
      // 例如：重新加载资源文件、更新UI显示等
    });
  })
  .catch((err: BusinessError) => {
    console.error(`创建订阅者失败，错误码: ${err.code}, 错误信息: ${err.message}`);
  });
```

### 步骤4：取消事件订阅（应用退出时）

**示例代码**：
```typescript
// 在应用退出时取消订阅，避免内存泄漏
if (subscriber) {
  commonEventManager.unsubscribe(subscriber)
    .then(() => {
      console.info('成功取消订阅');
      subscriber = null;
    })
    .catch((err: BusinessError) => {
      console.error(`取消订阅失败，错误码: ${err.code}, 错误信息: ${err.message}`);
    });
}
```

### 步骤5：错误处理

```typescript
// 错误处理代码
try {
  let systemLanguage = i18n.System.getSystemLanguage();
  console.info(`系统语言: ${systemLanguage}`);
} catch (error) {
  let err: BusinessError = error as BusinessError;
  switch (err.code) {
    case 401:
      console.error('参数错误，请检查API调用参数');
      break;
    case 890001:
      console.error('无效参数，参数验证失败');
      break;
    default:
      console.error(`未知错误，错误码: ${err.code}, 错误信息: ${err.message}`);
      // 使用降级方案
      console.warn('使用默认语言地区设置');
      break;
  }
}
```

### 步骤6：降级处理（定时轮询方案）

```typescript
// 降级处理：定时轮询系统语言地区变化
let pollTimer: number | null = null;
let lastSystemLanguage: string = i18n.System.getSystemLanguage();

function startPolling(): void {
  // 每30秒轮询一次系统语言地区信息
  pollTimer = setInterval(() => {
    let currentSystemLanguage = i18n.System.getSystemLanguage();
    if (currentSystemLanguage !== lastSystemLanguage) {
      console.info(`系统语言发生变化: ${lastSystemLanguage} -> ${currentSystemLanguage}`);
      lastSystemLanguage = currentSystemLanguage;
      
      // 执行语言切换逻辑
      // 例如：重新加载资源文件、更新UI显示等
    }
  }, 30000);
}

function stopPolling(): void {
  if (pollTimer) {
    clearInterval(pollTimer);
    pollTimer = null;
  }
}

// 在监听事件订阅失败时启动轮询方案
if (!subscriber) {
  console.warn('监听订阅失败，启动定时轮询方案');
  startPolling();
}

// 应用退出时停止轮询
stopPolling();
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：1.必需参数未指定；2.参数类型不正确 | 检查API调用参数，确保参数类型正确 |
| 890001 | 无效参数。可能原因：参数验证失败 | 验证参数是否符合规范，如语言ID、地区码格式 |
| 1500007 | 公共事件订阅失败。可能原因：订阅者创建失败 | 检查订阅配置是否正确，确认应用权限 |
| 1500008 | 公共事件发布失败。可能原因：事件类型不支持 | 检查事件类型是否在支持列表中 |
| 1500010 | 公共事件取消订阅失败。可能原因：订阅者不存在 | 确保订阅者对象有效，先订阅后取消 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.LocalizationKit": "API version ≥ 9",
    "@kit.BasicServicesKit": "API version ≥ 9"
  }
}
```

### 环境要求
- HarmonyOS API version：≥ 9（i18n.System接口）
- HarmonyOS API version：≥ 21（开发者模式param工具获取系统语言）
- 开发环境：DevEco Studio 3.1及以上版本
- 运行环境：HarmonyOS设备或模拟器

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.LocalizationKit'
```
**解决方法**：
- 确保项目依赖已正确配置
- 在oh-package.json5中添加LocalizationKit依赖
- 运行ohpm install安装依赖

**问题2：API不存在**
```
Error: Property 'getSystemLanguage' does not exist on type 'System'
```
**解决方法**：
- 检查API version是否≥ 9
- 在build-profile.json5中配置正确的compileSdkVersion
- 确认使用的是i18n.System而不是i18n.system（注意大小写）

**问题3：公共事件订阅权限不足**
```
Error: Permission denied for subscribing common event
```
**解决方法**：
- 检查module.json5中是否配置了必要的权限
- 确认COMMON_EVENT_LOCALE_CHANGED事件无需特殊权限
- 检查应用签名和证书配置

**问题4：监听回调阻塞主线程**
```
Warning: CommonEvent callback takes too long (>5s)
```
**解决方法**：
- 将耗时操作移至worker线程执行
- 使用异步API处理资源加载
- 优化回调逻辑，避免同步阻塞

## 常见问题与解决方法

### Q1：如何判断系统语言是否支持本地数字？
**原因**：系统语言切换时会自动清理不匹配的扩展参数
**解决方法**：
- 使用i18n.System.getUsingLocalDigit()判断是否使用本地数字
- 监听COMMON_EVENT_LOCALE_CHANGED事件，在语言切换后检查本地数字设置
- 参考[扩展参数](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/i18n-locale-culture)文档了解本地数字支持的 languages

### Q2：监听事件后如何更新应用语言？
**原因**：系统语言变化需要同步更新应用资源
**解决方法**：
- 在监听回调中获取新的系统语言地区信息
- 使用i18n.System.setAppPreferredLanguage()设置应用偏好语言
- 重新加载应用的国际化资源文件
- 更新UI显示，确保文本和布局正确显示

### Q3：如何获取系统支持的语言列表？
**原因**：需要判断应用是否支持系统语言
**解决方法**：
- 使用i18n.System.getSystemLanguages()获取系统支持的语言列表
- 使用i18n.System.getSystemCountries(language)获取指定语言下的地区列表
- 使用i18n.System.isSuggested(language, region)判断语言是否是地区的推荐语言

### Q4：开发者模式下如何通过命令获取系统语言？
**原因**：需要调试或验证系统语言设置
**解决方法**：
- 确保设备处于开发者模式
- 使用[param工具](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/param-tool)执行命令：
  ```
  param get persist.global.language
  ```
- 此功能需要API version ≥ 21

### Q5：如何处理系统区域对象的详细信息？
**原因**：Intl.Locale对象包含语言、地区、脚本等多维信息
**解决方法**：
- 使用i18n.System.getSystemLocaleInstance()获取Intl.Locale对象
- 通过Locale对象的方法获取详细信息：
  ```typescript
  let locale = i18n.System.getSystemLocaleInstance();
  console.info(`语言: ${locale.language}`);
  console.info(`地区: ${locale.region}`);
  console.info(`脚本: ${locale.script}`);
  console.info(`完整字符串: ${locale.toString()}`);
  ```
- 使用[Intl模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-intl)提供的ECMA 402标准接口进行进一步处理

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "systemLanguage": "zh-Hans",
  "systemRegion": "CN",
  "systemLocale": "zh-Hans-CN",
  "eventSubscription": "active",
  "apiUsed": [
    "i18n.System.getSystemLanguage()",
    "i18n.System.getSystemRegion()",
    "i18n.System.getSystemLocaleInstance()",
    "commonEventManager.createSubscriber()",
    "commonEventManager.subscribe()",
    "commonEventManager.unsubscribe()"
  ]
}
```

## 参考文档

- [API开发指南](references/i18n-system-language-region-guide.md)
- [API参考说明](references/js-apis-i18n-reference.md)
- [扩展参数说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/i18n-locale-culture)
- [param工具说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/param-tool)
- [公共事件定义](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/commoneventmanager-definitions)
- [Intl模块参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-intl)

## 完整示例代码

- [ArkTS示例](assets/system-language-region-example.ets)
- [监听事件完整示例](assets/locale-change-listener.ets)
- [降级处理示例](assets/polling-fallback.ets)
- [配置文件示例](assets/module-config.json)

## 测试用例

### 正向测试用例
- [获取系统语言地区信息](tests/test_positive.ts)：验证getSystemLanguage/getSystemRegion/getSystemLocaleInstance接口正确返回
- [监听系统语言变化](tests/test_event_listener.ts)：验证监听事件订阅和回调触发
- [取消事件订阅](tests/test_unsubscribe.ts)：验证取消订阅功能正常

### 边界测试用例
- [系统语言为空](tests/test_empty_language.ts)：验证系统语言未设置时的处理
- [特殊语言地区格式](tests/test_special_locale.ts)：验证特殊语言地区格式的解析（如阿拉伯语、希伯来语）
- [高频监听回调](tests/test_high_frequency.ts)：验证短时间内多次语言切换的监听处理

### 异常测试用例
- [API不存在](tests/test_api_not_exist.ts)：验证API version低于9时的错误处理
- [订阅失败](tests/test_subscribe_fail.ts)：验证公共事件订阅失败的降级处理
- [权限不足](tests/test_permission_denied.ts)：验证权限配置缺失时的错误提示
- [监听回调异常](tests/test_callback_error.ts)：验证监听回调中异常的处理