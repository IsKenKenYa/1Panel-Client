---
name: hmos-localization-kit-language-region-display
description: 获取语言和地区名称的本地化翻译，支持200+种语言和地区，需传入合法的语言ID和国家地区码，适用于应用国际化展示场景
---

# 本地化语言与地区名称技能

## 功能描述

本技能用于获取语言名称和国家/地区名称在不同语言环境下的本地化翻译。通过调用HarmonyOS i18n模块的API，可以将语言代码和国家/地区代码转换为对应语言环境下的可读名称，确保用户可识别，主要在展示语言与地区名称的场景下使用。

例如：
- 在简体中文环境下，简体中文显示为"简体中文"，英文显示为"英文"
- 在英文环境下，简体中文显示为"Simplified Chinese"，英文显示为"English"

## 使用场景

### 触发词
- "获取语言名称翻译"
- "获取国家名称翻译"
- "获取地区名称翻译"
- "本地化语言名称"
- "本地化地区名称"
- "语言名称国际化"
- "地区名称国际化"

### 能做
- 获取语言名称在指定语言环境下的翻译（如：'de'在'zh-Hans-CN'下显示为'德文'）
- 获取国家/地区名称在指定语言环境下的翻译（如：'SA'在'en-GB'下显示为'Saudi Arabia'）
- 控制返回名称的首字母大小写格式
- 支持全球200+种语言和地区的翻译

### 绝不做
- 不支持非法的语言ID或国家地区码
- 不用于翻译普通文本内容（仅用于语言和地区名称）
- 不支持自定义翻译内容
- 不提供语音朗读功能

### 补充
- 输入参数必须符合语言ID和国家地区码规范
- 支持API version 9及以上版本
- getDisplayLanguage接口从API version 11开始支持在元服务中使用
- getDisplayCountry接口从API version 12开始支持在元服务中使用

## 调用规范和规则

### 输入约束
- **语言ID（language）**：必须是合法的语言ID，如'zh'、'en'、'de'、'fr'等
- **国家地区码（country）**：必须是合法的国家地区码，如'CN'、'US'、'DE'、'SA'等
- **区域ID（locale）**：必须是合法的区域ID字符串，由语言、脚本、国家地区组成，如'en-GB'、'zh-Hans-CN'
- **sentenceCase**：可选参数，布尔值，控制首字母大写格式
- **字符长度**：语言ID和国家地区码长度不超过10个字符

### 执行约束
- 最大耗时：1秒
- API调用频次：无限制
- 系统能力要求：SystemCapability.Global.I18n

### 内容约束
- 禁止使用非法的语言ID和国家地区码
- 禁止传入空字符串或null值
- 禁止使用已废弃的API（i18n.getDisplayLanguage和i18n.getDisplayCountry）

### 降级约束
- 参数错误：返回错误码401或890001，提示用户检查参数格式
- 参数验证失败：返回错误码890001，提示用户使用合法的语言ID或国家地区码
- 系统能力不支持：提示用户设备不支持该功能

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查是否导入必要的模块（@kit.LocalizationKit和@kit.BasicServicesKit）
2. 验证语言ID或国家地区码是否为合法格式
3. 验证区域ID（locale）是否符合规范

**参数准备**：
```typescript
// ArkTS示例
import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

// 准备语言名称翻译参数
const language: string = 'de';  // 德语
const locale: string = 'zh-Hans-CN';  // 简体中文环境
const sentenceCase: boolean = true;  // 首字母大写

// 准备国家/地区名称翻译参数
const country: string = 'SA';  // 沙特阿拉伯
const localeForCountry: string = 'en-GB';  // 英文环境
```

### 步骤2：调用API

**获取语言名称翻译**：
```typescript
// 导入必要模块
import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

/**
 * 获取语言名称在指定语言环境下的翻译
 * @param language 语言ID，如'zh'、'de'、'fr'
 * @param locale 区域ID，如'en-GB'、'zh-Hans-CN'
 * @param sentenceCase 是否首字母大写，默认true
 * @returns 语言名称的翻译
 */
function getLanguageDisplayName(
  language: string,
  locale: string,
  sentenceCase: boolean = true
): string {
  try {
    // 调用系统API获取语言名称翻译
    const displayLanguage: string = i18n.System.getDisplayLanguage(language, locale, sentenceCase);
    console.log(`语言 ${language} 在 ${locale} 环境下显示为: ${displayLanguage}`);
    return displayLanguage;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`获取语言名称失败，错误码: ${err.code}, 错误信息: ${err.message}`);
    throw error;
  }
}

// 示例：获取德语在简体中文环境下的名称
const germanInChinese = getLanguageDisplayName('de', 'zh-Hans-CN');  // 返回: '德文'
const germanInEnglish = getLanguageDisplayName('de', 'en-GB');  // 返回: 'German'
```

**获取国家/地区名称翻译**：
```typescript
// 导入必要模块
import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

/**
 * 获取国家/地区名称在指定语言环境下的翻译
 * @param country 国家地区码，如'CN'、'US'、'SA'
 * @param locale 区域ID，如'en-GB'、'zh-Hans-CN'
 * @param sentenceCase 是否首字母大写，默认true
 * @returns 国家/地区名称的翻译
 */
function getCountryDisplayName(
  country: string,
  locale: string,
  sentenceCase: boolean = true
): string {
  try {
    // 调用系统API获取国家/地区名称翻译
    const displayCountry: string = i18n.System.getDisplayCountry(country, locale, sentenceCase);
    console.log(`国家/地区 ${country} 在 ${locale} 环境下显示为: ${displayCountry}`);
    return displayCountry;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`获取国家/地区名称失败，错误码: ${err.code}, 错误信息: ${err.message}`);
    throw error;
  }
}

// 示例：获取沙特阿拉伯在英文环境下的名称
const saInEnglish = getCountryDisplayName('SA', 'en-GB');  // 返回: 'Saudi Arabia'
const cnInChinese = getCountryDisplayName('CN', 'zh-Hans-CN');  // 返回: '中国'
```

### 步骤3：错误处理

```typescript
// 错误处理代码
import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

/**
 * 安全获取语言名称翻译（带错误处理）
 */
function safeGetLanguageDisplayName(
  language: string,
  locale: string,
  sentenceCase: boolean = true
): string | null {
  try {
    // 参数校验
    if (!language || !locale) {
      console.error('参数错误：语言ID和区域ID不能为空');
      return null;
    }
    
    // 调用API
    const displayLanguage = i18n.System.getDisplayLanguage(language, locale, sentenceCase);
    return displayLanguage;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    
    switch (err.code) {
      case 401:
        console.error('参数错误：必填参数未指定或参数类型错误');
        break;
      case 890001:
        console.error('参数无效：语言ID或区域ID格式不正确');
        break;
      default:
        console.error(`未知错误：错误码 ${err.code}, 错误信息: ${err.message}`);
    }
    
    return null;
  }
}

/**
 * 安全获取国家/地区名称翻译（带错误处理）
 */
function safeGetCountryDisplayName(
  country: string,
  locale: string,
  sentenceCase: boolean = true
): string | null {
  try {
    // 参数校验
    if (!country || !locale) {
      console.error('参数错误：国家地区码和区域ID不能为空');
      return null;
    }
    
    // 调用API
    const displayCountry = i18n.System.getDisplayCountry(country, locale, sentenceCase);
    return displayCountry;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    
    switch (err.code) {
      case 401:
        console.error('参数错误：必填参数未指定或参数类型错误');
        break;
      case 890001:
        console.error('参数无效：国家地区码或区域ID格式不正确');
        break;
      default:
        console.error(`未知错误：错误码 ${err.code}, 错误信息: ${err.message}`);
    }
    
    return null;
  }
}
```

### 步骤4：降级处理

```typescript
// 降级处理代码
import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

/**
 * 获取语言名称翻译（带降级处理）
 */
function getLanguageDisplayNameWithFallback(
  language: string,
  locale: string,
  sentenceCase: boolean = true
): string {
  try {
    // 尝试获取翻译
    const displayName = i18n.System.getDisplayLanguage(language, locale, sentenceCase);
    return displayName;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    
    // 降级方案1：尝试使用默认区域ID
    if (locale !== 'en-US') {
      try {
        console.warn(`使用区域ID ${locale} 失败，尝试使用 en-US 作为默认值`);
        const fallbackName = i18n.System.getDisplayLanguage(language, 'en-US', sentenceCase);
        return fallbackName;
      } catch (fallbackError) {
        console.warn('降级方案1失败');
      }
    }
    
    // 降级方案2：返回原始语言ID
    console.warn(`无法获取语言 ${language} 的翻译，返回原始语言ID`);
    return language.toUpperCase();
  }
}

/**
 * 获取国家/地区名称翻译（带降级处理）
 */
function getCountryDisplayNameWithFallback(
  country: string,
  locale: string,
  sentenceCase: boolean = true
): string {
  try {
    // 尝试获取翻译
    const displayName = i18n.System.getDisplayCountry(country, locale, sentenceCase);
    return displayName;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    
    // 降级方案1：尝试使用默认区域ID
    if (locale !== 'en-US') {
      try {
        console.warn(`使用区域ID ${locale} 失败，尝试使用 en-US 作为默认值`);
        const fallbackName = i18n.System.getDisplayCountry(country, 'en-US', sentenceCase);
        return fallbackName;
      } catch (fallbackError) {
        console.warn('降级方案1失败');
      }
    }
    
    // 降级方案2：返回原始国家地区码
    console.warn(`无法获取国家/地区 ${country} 的翻译，返回原始国家地区码`);
    return country.toUpperCase();
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Parameter error. Possible causes: 1.Mandatory parameters are left unspecified; 2.Incorrect parameter types. | 检查必填参数是否传入，参数类型是否正确（应为string或boolean） |
| 890001 | Invalid parameter. Possible causes: Parameter verification failed. | 检查语言ID、国家地区码或区域ID是否符合规范，使用合法的语言代码和国家代码 |

## 编译和修复问题

### 依赖声明
```json
{
  "module": {
    "dependencies": {
      "@kit.LocalizationKit": "^1.0.0",
      "@kit.BasicServicesKit": "^1.0.0"
    }
  }
}
```

### 环境要求
- **HarmonyOS SDK**：API version 9及以上
- **DevEco Studio**：3.0及以上版本
- **系统能力**：SystemCapability.Global.I18n

### 常见编译问题

**问题1：模块导入错误**
```
Error: Cannot find module '@kit.LocalizationKit' or its corresponding type declarations.
```
**解决方法**：确保在`build-profile.json5`或`oh-package.json5`中正确声明了依赖，并且HarmonyOS SDK版本不低于API version 9。

**问题2：系统能力不支持**
```
Error: SystemCapability.Global.I18n is not supported.
```
**解决方法**：检查设备是否支持该系统能力，确保运行环境为HarmonyOS API version 9及以上。

**问题3：API调用错误**
```
Error: i18n.getDisplayLanguage is not a function
```
**解决方法**：确保使用正确的API调用方式，应使用`i18n.System.getDisplayLanguage`而不是`i18n.getDisplayLanguage`（后者已废弃）。

## 常见问题与解决方法

### Q1：获取的语言名称或国家名称显示不正确
**原因**：传入的语言ID或国家地区码格式不正确
**解决方法**：
- 检查语言ID是否为标准的ISO 639-1语言代码（如'zh'、'en'、'de'）
- 检查国家地区码是否为标准的ISO 3166-1国家代码（如'CN'、'US'、'SA'）
- 确保区域ID格式正确（如'zh-Hans-CN'、'en-GB'）

### Q2：调用API时抛出401错误
**原因**：必填参数未指定或参数类型错误
**解决方法**：
- 确保language/country和locale参数已正确传入
- 检查参数类型，language、country、locale应为string类型，sentenceCase应为boolean类型
- 不要传入null或undefined值

### Q3：调用API时抛出890001错误
**原因**：参数验证失败，语言ID或国家地区码不合法
**解决方法**：
- 使用合法的语言ID（参考：区域ID与文化习惯划分文档）
- 使用合法的国家地区码
- 确保区域ID格式正确

### Q4：如何在元服务中使用这些API？
**原因**：元服务对API版本有特定要求
**解决方法**：
- getDisplayLanguage API从API version 11开始支持在元服务中使用
- getDisplayCountry API从API version 12开始支持在元服务中使用
- 确保元服务的API版本满足要求

### Q5：sentenceCase参数设置为false时，首字母仍然大写
**原因**：部分语言的默认格式本身就是首字母大写
**解决方法**：
- sentenceCase参数控制的是否按照首字母大写的格式显示文本
- 某些语言环境下，默认格式本身就是首字母大写，此时设置false可能不会改变显示结果
- 这取决于具体的语言和文化习惯

## 输出结果报告

执行完成后输出以下信息：

```typescript
{
  "status": "success",
  "displayName": "德文",  // 获取到的语言或地区名称翻译
  "language": "de",  // 原始语言ID
  "locale": "zh-Hans-CN",  // 目标区域ID
  "apiUsed": [
    "i18n.System.getDisplayLanguage",
    "i18n.System.getDisplayCountry"
  ]
}
```

## 参考文档

- [API开发指南：本地化语言与地区名称](references/i18n-language-region-display.md)
- [API参考说明：i18n模块](references/js-apis-i18n.md)

## 完整示例代码

- [ArkTS示例：获取语言名称翻译](assets/get_language_display_name.ets)
- [ArkTS示例：获取国家/地区名称翻译](assets/get_country_display_name.ets)
- [ArkTS示例：完整功能示例](assets/i18n_language_region_display_example.ets)

## 测试用例

### 正向测试用例
- [获取常见语言的翻译](tests/test_positive.ets)：测试获取中文、英文、德文等常见语言的翻译
- [获取常见国家/地区的翻译](tests/test_positive.ets)：测试获取中国、美国、德国等常见国家的翻译
- [不同区域环境下的翻译](tests/test_positive.ets)：测试同一语言在不同区域环境下的翻译效果

### 边界测试用例
- [sentenceCase参数测试](tests/test_boundary.ets)：测试sentenceCase为true和false时的显示差异
- [特殊字符处理](tests/test_boundary.ets)：测试包含特殊字符的语言ID和国家地区码
- [长字符串处理](tests/test_boundary.ets)：测试较长的区域ID字符串

### 异常测试用例
- [空参数测试](tests/test_exception.ets)：测试传入空字符串或null值时的错误处理
- [非法参数测试](tests/test_exception.ets)：测试传入非法的语言ID或国家地区码时的错误处理
- [类型错误测试](tests/test_exception.ets)：测试传入错误类型的参数时的错误处理