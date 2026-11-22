---
name: hmos-localization-kit-multilingual-resources
description: 实现应用多语言适配，支持国际化接口调用和多语言资源配置，适用于面向不同国家和地区用户的本地化定制场景
---

# 多语言适配技能

## 功能描述

本技能提供HarmonyOS应用多语言适配的完整解决方案，包括国际化接口使用和多语言资源配置。通过i18n和intl模块的系统区域管理、语言识别能力，结合多语言资源目录配置，实现应用加载和显示符合所在地域使用习惯的内容。

**核心能力**：
- 获取系统区域信息和语言识别
- 国际化接口调用（时间日期、数字单位等）
- 多语言资源目录配置和匹配
- 应用偏好语言设置

**适用范围**：
- 语言和地区名称适配
- 时间日期、数字单位格式化
- 文本字符、图片、音频、视频等多语言资源管理

**限制条件**：
- 需要遵循HarmonyOS资源分类与访问规范
- 国际化接口返回值仅适用于界面展示，不建议硬编码或假设性判断
- 资源文件配置需符合系统匹配规则

**典型场景**：
- 为不同国家和地区的用户提供本地化内容
- 实现多语言应用界面切换
- 根据系统语言自动加载匹配资源

## 使用场景

### 触发词
- "多语言适配"
- "本地化定制"
- "国际化接口"
- "多语言资源配置"
- "语言区域适配"
- "i18n模块"
- "intl模块"
- "获取系统语言"
- "设置应用偏好语言"

### 能做
- 获取系统区域对象和系统区域ID
- 识别系统语言并进行语言匹配
- 调用国际化接口进行时间日期、数字格式化
- 配置多语言资源目录
- 设置和获取应用偏好语言
- 实现应用多语言自动切换

### 绝不做
- 不对国际化接口返回值进行硬编码处理
- 不直接比较语言码进行语言识别（应使用getBestMatchLocale）
- 不处理超出Localization Kit范围的请求
- 不实现自定义的国际化逻辑（应使用系统提供的i18n/intl接口）

### 补充
- 国际化接口基于CLDR标准，返回值可能随标准迭代调整
- 区域使用习惯可能发生变化，建议使用国际化接口而非自定义处理
- 资源匹配规则遵循系统默认策略，应用偏好语言优先级高于系统语言

## 调用规范和规则

### 输入约束
- 区域ID格式：必须符合合法的区域ID规范（如zh-Hans-CN）
- 语言ID格式：必须符合合法的语言ID规范（如zh-Hans）
- 资源文件路径：必须符合HarmonyOS资源目录结构规范
- 代码文件格式：必须使用ArkTS语言编写

### 执行约束
- 最大耗时：国际化接口调用应在100ms内完成
- 最大迭代次数：语言匹配循环不超过10次
- API调用频次：避免频繁调用系统区域获取接口

### 内容约束
- 禁止生成：硬编码的语言码比较逻辑、自定义国际化处理函数
- 禁止使用高危函数：eval、exec等动态执行函数
- 禁止操作：直接修改系统语言设置（应通过系统设置界面）

### 降级约束
- 区域ID无效：使用默认区域或提示用户设置正确的区域
- 语言匹配失败：返回默认语言或提示用户选择支持的语言
- 资源文件缺失：加载默认资源或显示占位内容

## 调用流程和步骤

### 步骤1：获取系统区域信息

**前置校验**：
1. 检查系统区域是否已设置
2. 验证应用是否已导入LocalizationKit模块
3. 确认应用是否有获取系统信息的权限

**参数准备**：
```typescript
import { i18n } from '@kit.LocalizationKit';

const systemLocale = i18n.System.getSystemLocaleInstance();
const systemLocaleId = systemLocale.toString();
```

**示例代码**：
```typescript
import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function getSystemLocaleInfo(): Promise<void> {
  try {
    const locale = i18n.System.getSystemLocaleInstance();
    const localeId = locale.toString();
    console.info(`System locale: ${localeId}`);
    
    const language = i18n.System.getSystemLanguage();
    console.info(`System language: ${language}`);
    
    const region = i18n.System.getSystemRegion();
    console.info(`System region: ${region}`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to get system locale, error code: ${err.code}, message: ${err.message}`);
  }
}
```

### 步骤2：识别系统语言

**参数准备**：
```typescript
import { i18n } from '@kit.LocalizationKit';

const systemLanguage = i18n.System.getSimplifiedLanguage();
const languagesList = ['zh-Hans', 'zh-Hant-HK', 'zh-Hant-TW', 'en'];
```

**示例代码**：
```typescript
import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

function matchSystemLanguage(): string {
  try {
    const systemLanguage = i18n.System.getSimplifiedLanguage();
    const languagesList = ['zh-Hans', 'zh-Hant-HK', 'zh-Hant-TW', 'en'];
    
    const matchedLanguage = i18n.I18NUtil.getBestMatchLocale(systemLanguage, languagesList);
    console.info(`Matched language: ${matchedLanguage}`);
    
    return matchedLanguage;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to match language, error code: ${err.code}, message: ${err.message}`);
    return 'default';
  }
}
```

### 步骤3：调用国际化接口

**示例代码**：
```typescript
import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function formatDateWithLocale(): Promise<void> {
  try {
    const locale = i18n.System.getSystemLocaleInstance();
    
    const dateTimeFormat = new Intl.DateTimeFormat(locale.toString());
    const now = new Date();
    const formattedDate = dateTimeFormat.format(now);
    console.info(`Formatted date: ${formattedDate}`);
    
    const simpleDateTimeFormat = i18n.getSimpleDateTimeFormatBySkeleton('yMd', locale);
    const simpleFormattedDate = simpleDateTimeFormat.format(now);
    console.info(`Simple formatted date: ${simpleFormattedDate}`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to format date, error code: ${err.code}, message: ${err.message}`);
  }
}
```

### 步骤4：设置应用偏好语言

**示例代码**：
```typescript
import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function setAppPreferredLanguage(language: string): Promise<void> {
  try {
    i18n.System.setAppPreferredLanguage(language);
    console.info(`App preferred language set to: ${language}`);
    
    const appLanguage = i18n.System.getAppPreferredLanguage();
    console.info(`Current app preferred language: ${appLanguage}`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to set app language, error code: ${err.code}, message: ${err.message}`);
  }
}
```

### 步骤5：错误处理

**错误处理代码**：
```typescript
import { BusinessError } from '@kit.BasicServicesKit';

function handleI18nError(error: BusinessError): void {
  switch (error.code) {
    case 401:
      console.error('Parameter error. Possible causes: 1.Mandatory parameters are left unspecified; 2.Incorrect parameter types.');
      break;
    case 890001:
      console.error('Invalid parameter. Possible causes: Parameter verification failed.');
      break;
    default:
      console.error(`Unknown error: ${error.message}`);
  }
}
```

### 步骤6：降级处理

**降级处理代码**：
```typescript
import { i18n } from '@kit.LocalizationKit';

function fallbackLanguageHandling(): string {
  try {
    const systemLanguage = i18n.System.getSimplifiedLanguage();
    const matchedLanguage = i18n.I18NUtil.getBestMatchLocale(systemLanguage, ['zh-Hans', 'en']);
    return matchedLanguage;
  } catch (error) {
    console.warn('Failed to get system language, using default');
    return 'zh-Hans';
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：必填参数未指定、参数类型错误 | 检查参数是否正确传入，确保类型匹配 |
| 890001 | 无效参数。可能原因：参数验证失败 | 确保区域ID、语言ID符合规范格式 |
| 3300100 | 系统服务异常 | 检查系统服务是否正常运行，重启应用 |
| 3301100 | 系统服务死亡 | 检查系统服务状态，重新启动设备 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.LocalizationKit": "^1.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK：最低版本 API 7
- DevEco Studio：最低版本 3.0
- ArkTS语言支持：必需

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.LocalizationKit'
```
**解决方法**：确保项目已正确配置HarmonyOS SDK，检查build-profile.json5中的依赖配置

**问题2：API接口未找到**
```
Error: Property 'getSystemLocaleInstance' does not exist on type 'System'
```
**解决方法**：确认使用的API版本是否符合要求，部分接口需要API version 20+

**问题3：类型错误**
```
Error: Type 'string' is not assignable to type 'Intl.Locale'
```
**解决方法**：使用正确的类型转换，如locale.toString()获取字符串形式的区域ID

## 常见问题与解决方法

### Q1：国际化接口返回值格式不符合预期
**原因**：CLDR标准迭代导致格式调整
**解决方法**：
- 不对返回值进行硬编码处理
- 仅用于界面展示，不用于逻辑判断
- 使用resolvedOptions获取实际配置

### Q2：语言匹配失败或匹配到错误的语言
**原因**：languagesList配置不完整或语言ID格式不正确
**解决方法**：
- 确保languagesList包含所有支持的语言变体
- 使用合法的语言ID格式
- 添加默认语言处理逻辑

### Q3：应用偏好语言设置后未生效
**原因**：应用需要冷启动才能生效
**解决方法**：
- 设置偏好语言为'default'可跟随系统语言
- 重启应用以使设置生效
- 确保设置了正确的语言ID

### Q4：资源文件匹配不正确
**原因**：资源目录结构不符合规范
**解决方法**：
- 遵循HarmonyOS资源分类与访问规范
- 确保资源文件放置在正确的目录下
- 检查资源文件命名是否符合要求

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "systemLocale": "zh-Hans-CN",
  "systemLanguage": "zh-Hans",
  "matchedLanguage": "zh-Hans",
  "appPreferredLanguage": "zh-Hans",
  "formattedDate": "2026/07/03",
  "apiUsed": [
    "i18n.System.getSystemLocaleInstance",
    "i18n.System.getSystemLanguage",
    "i18n.System.getSimplifiedLanguage",
    "i18n.I18NUtil.getBestMatchLocale",
    "Intl.DateTimeFormat",
    "i18n.getSimpleDateTimeFormatBySkeleton",
    "i18n.System.setAppPreferredLanguage",
    "i18n.System.getAppPreferredLanguage"
  ]
}
```

## 参考文档

- [多语言适配开发指南](references/l10n-multilingual-resources.md)
- [i18n模块API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-i18n)
- [intl模块API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-intl)
- [资源分类与访问](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/resource-categories-and-access)

## 完整示例代码

- [ArkTS示例：系统区域信息获取](assets/get_system_locale.ets)
- [ArkTS示例：语言匹配](assets/match_language.ets)
- [ArkTS示例：国际化接口调用](assets/internationalization_example.ets)
- [ArkTS示例：应用偏好语言设置](assets/app_preferred_language.ets)

## 测试用例

### 正向测试用例
- [获取系统区域信息测试](tests/test_get_system_locale.ets)：验证系统区域信息获取功能
- [语言匹配测试](tests/test_match_language.ets)：验证语言匹配功能正确性
- [国际化接口测试](tests/test_intl_interface.ets)：验证时间日期格式化功能
- [应用偏好语言测试](tests/test_app_language.ets)：验证应用偏好语言设置功能

### 边界测试用例
- [边界语言ID测试](tests/test_boundary_language.ets)：测试极端语言ID格式
- [空参数测试](tests/test_empty_params.ets)：测试空参数或无效参数处理

### 异常测试用例
- [无效区域ID测试](tests/test_invalid_locale.ets)：测试无效区域ID的错误处理
- [权限不足测试](tests/test_permission_denied.ets)：测试权限不足场景的降级处理
- [系统服务异常测试](tests/test_service_error.ets)：测试系统服务异常的处理