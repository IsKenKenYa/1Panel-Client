---
name: hmos-accessibility-kit-multilingual-screen-reader
description: 处理屏幕朗读中的多语种内容标注和拼接，支持多语言翻译适配，避免拼接朗读错误（如阿拉伯语从右到左），适用于国际化应用的无障碍场景
---

# 多语种场景屏幕朗读技能

## 功能描述

本技能提供屏幕朗读中多语种内容的处理能力，包括：
- 对朗读内容进行多语种翻译标注
- 处理多语言字符串拼接时的朗读顺序问题
- 支持不同语言方向的正确朗读（如阿拉伯语从右到左）
- 确保无障碍文本与应用本身界面支持的语种保持一致

通过合理使用ArkUI的无障碍属性（accessibilityText、accessibilityDescription）和多语言资源管理，实现国际化的屏幕朗读无障碍体验。

## 使用场景

### 触发词
- "多语种屏幕朗读"
- "国际化无障碍"
- "多语言朗读标注"
- "屏幕朗读多语言"
- "accessibilityText多语种"
- "阿拉伯语朗读"

### 能做
- 为组件设置多语言的无障碍文本（accessibilityText）
- 处理多字符串拼接时的朗读顺序和正确性
- 使用Resource资源引用实现多语言支持
- 解决从右到左（RTL）语言的朗读问题
- 配置accessibilityDescription提供详细的多语言说明

### 绝不做
- 不处理非屏幕朗读相关的多语言问题
- 不处理纯视觉界面的多语言显示（仅关注无障碍朗读）
- 不替代应用的多语言资源管理系统
- 不处理超出Accessibility Kit范围的请求

### 补充
- 多语种翻译需与应用本身界面支持的语种保持一致
- 字符串拼接需考虑语言方向，避免朗读错误
- 使用Resource引用可更好地支持多语言资源管理
- accessibilityText优先级高于组件文本属性

## 调用规范和规则

### 输入约束
- 无障碍文本内容：支持string或Resource类型
- 字符串长度：建议不超过200字符，避免朗读过长
- 语言方向：需明确标注LTR或RTL语言
- 拼接字符串数量：建议不超过3个字符串拼接

### 执行约束
- 最大耗时：设置单个组件无障碍属性不超过1秒
- 参数校验：必须验证Resource资源的有效性
- 语言一致性：必须与应用界面语言保持同步

### 内容约束
- 禁止拼接时忽略语言方向差异
- 禁止使用硬编码的多语言字符串（应使用Resource）
- 禁止accessibilityText与accessibilityDescription内容重复
- 禁止在accessibilityText中包含特殊字符（如控制符）

### 降级约束
- Resource资源失效：使用默认语言fallback字符串
- 语言方向处理失败：提示用户避免拼接，使用单一语言文本
- 多语言支持不完整：优先保证主要语言的正确朗读

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认应用支持的多语言列表
2. 验证Resource多语言资源文件是否存在
3. 确认目标语言的文本方向（LTR/RTL）
4. 检查组件是否已有文本属性

**参数准备**：
```typescript
// ArkTS示例 - 定义多语言Resource
const multilingualText: Resource = {
  bundleName: 'com.example.myapp',
  moduleName: 'entry',
  id: 0x01000001  // 多语言资源ID
};

// 或直接定义包含多语言的字符串（用于测试）
const testMultilingual: string = 'It is convenient: 屏幕朗读已开启 and use';
```

### 步骤2：设置无障碍文本

**示例代码**：
```typescript
// 导入必要模块
import { Resource } from '@ohos.arkui';

// 方式1：使用Resource引用多语言资源
Text($r('app.string.multilingual_text'))
  .fontSize(30)
  .fontColor(Color.Blue)
  .accessibilityText($r('app.string.accessibility_multilingual'))
  .accessibilityDescription($r('app.string.accessibility_desc_multilingual'));

// 方式2：直接设置字符串（适合固定内容）
Text('It is convenient: 屏幕朗读已开启 and use')
  .fontSize(30)
  .fontColor(Color.Blue)
  .accessibilityText('多语种示例：屏幕朗读支持中英文混合')
  .accessibilityDescription('这是一个展示多语种屏幕朗读功能的示例');

// 方式3：处理拼接字符串（避免RTL语言错误）
@Entry
@Component
export struct MultilingualAccessibility {
  @State message: string = '';
  
  build() {
    NavDestination() {
      Column() {
        // 正确的多语言拼接方式
        Text(this.getLocalizedText())
          .fontSize(30)
          .accessibilityText(this.getLocalizedAccessibilityText())
          
        // 避免直接拼接可能RTL语言的字符串
        Text($r('app.string.concat_example'))
          .fontSize(20)
          .accessibilityText($r('app.string.concat_accessibility'))
      }
    }.title('多语种无障碍')
  }
  
  // 使用资源引用而非硬拼接
  private getLocalizedText(): Resource {
    return $r('app.string.display_text');
  }
  
  private getLocalizedAccessibilityText(): Resource {
    return $r('app.string.accessibility_text');
  }
}
```

### 步骤3：处理RTL语言场景

**示例代码**：
```typescript
// 处理阿拉伯语等RTL语言
@Component
export struct RTLLanguageHandler {
  // 标识当前语言方向
  @State isRTL: boolean = false;
  @State currentLanguage: string = 'zh-CN';
  
  aboutToAppear() {
    // 根据当前系统语言设置判断方向
    this.isRTL = this.checkLanguageDirection(this.currentLanguage);
  }
  
  build() {
    Column() {
      // RTL语言特殊处理
      if (this.isRTL) {
        // 对于RTL语言，避免左右拼接，使用单一资源
        Text($r('app.string.rtl_message'))
          .accessibilityText($r('app.string.rtl_accessibility'))
          .accessibilityDescription($r('app.string.rtl_description'))
      } else {
        // LTR语言可以正常拼接（但仍建议使用Resource）
        Text($r('app.string.ltr_message'))
          .accessibilityText($r('app.string.ltr_accessibility'))
      }
    }
  }
  
  // 检查语言方向
  private checkLanguageDirection(language: string): boolean {
    const rtlLanguages = ['ar', 'he', 'fa', 'ur'];
    const langCode = language.split('-')[0];
    return rtlLanguages.includes(langCode);
  }
}
```

### 步骤4：错误处理

```typescript
// 错误处理代码
@Component
export struct AccessibilityWithErrorHandling {
  @State accessibilityTextReady: boolean = false;
  
  build() {
    Column() {
      Text('示例文本')
        .accessibilityText(this.getSafeAccessibilityText())
        .accessibilityDescription(this.getSafeDescription())
    }
  }
  
  private getSafeAccessibilityText(): string {
    try {
      // 尝试获取Resource
      const resourceText = $r('app.string.accessibility_text');
      this.accessibilityTextReady = true;
      return resourceText;
    } catch (error) {
      console.error('Resource加载失败:', error.message);
      // 降级方案：使用默认文本
      this.accessibilityTextReady = false;
      return '屏幕朗读示例文本';
    }
  }
  
  private getSafeDescription(): string {
    if (!this.accessibilityTextReady) {
      // Resource加载失败时的降级说明
      return '由于多语言资源加载失败，使用默认语言朗读';
    }
    return $r('app.string.accessibility_description');
  }
}
```

### 步骤5：降级处理

```typescript
// 降级处理代码 - 避免拼接导致RTL错误
@Component
export struct FallbackAccessibility {
  @State primaryLanguage: string = 'zh-CN';
  
  build() {
    Column() {
      // 检测拼接可能导致问题的场景
      if (this.shouldAvoidConcat()) {
        // 降级方案：使用单一Resource而非拼接
        Text($r('app.string.safe_single_text'))
          .accessibilityText($r('app.string.safe_single_accessibility'))
      } else {
        // 正常场景
        Text(this.getConcatText())
          .accessibilityText(this.getConcatAccessibility())
      }
    }
  }
  
  private shouldAvoidConcat(): boolean {
    // 检查是否包含RTL语言拼接LTR语言的场景
    return this.isRTL(this.primaryLanguage);
  }
  
  private isRTL(lang: string): boolean {
    const rtlLanguages = ['ar', 'he', 'fa', 'ur'];
    return rtlLanguages.some(rtl => lang.startsWith(rtl));
  }
  
  private getConcatText(): string {
    // LTR场景下可以安全拼接
    return '屏幕朗读已开启，欢迎使用';
  }
  
  private getConcatAccessibility(): string {
    return '屏幕朗读功能已激活，应用已准备就绪';
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| RESOURCE_NOT_FOUND | 多语言Resource资源文件不存在 | 检查resources目录下对应语言的string.json文件 |
| INVALID_RESOURCE_ID | Resource ID格式错误 | 使用正确的资源ID格式（如0x01000001） |
| RTL_CONCAT_ERROR | RTL语言拼接导致朗读顺序错误 | 使用单一Resource而非字符串拼接 |
| LANGUAGE_MISMATCH | accessibilityText语言与应用界面语言不一致 | 确保无障碍文本语言与应用语言同步 |
| DUPLICATE_CONTENT | accessibilityText与accessibilityDescription内容重复 | 为description提供更详细的说明内容 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@ohos.arkui": "^1.0.0"
  }
}
```

### 环境要求
- HarmonyOS API version 10+：accessibilityText基础支持
- HarmonyOS API version 12+：accessibilityText支持Resource引用
- HarmonyOS API version 14+：accessibilityGroup增强支持

### 常见编译问题

**问题1：Resource引用失败**
```
Error: Cannot find resource with id 0x01000001
```
**解决方法**：
- 检查`resources/{language}/element/string.json`文件是否存在
- 确认资源ID与string.json中的定义一致
- 使用`$r('app.string.xxx')`格式正确引用

**问题2：RTL语言朗读顺序错误**
```
阿拉伯语+英语拼接导致朗读顺序混乱
```
**解决方法**：
- 避免在RTL语言场景下进行字符串拼接
- 使用单一Resource定义完整文本
- 或使用占位符格式让系统处理方向

**问题3：多语言未生效**
```
accessibilityText未随应用语言切换而变化
```
**解决方法**：
- 使用Resource而非硬编码字符串
- 监听系统语言变化事件并更新状态
- 确保所有支持的语言都有对应的资源文件

## 常见问题与解决方法

### Q1：如何处理中英文混合的朗读？
**原因**：屏幕朗读引擎可以识别中英文，但需合理分隔。
**解决方法**：
- 在混合文本中使用标点或空格分隔不同语言
- 为accessibilityText提供更清晰的朗读提示
- 避免过长的混合文本，建议分段处理

### Q2：阿拉伯语拼接英语为何朗读错误？
**原因**：阿拉伯语RTL方向与英语LTR方向冲突，拼接会导致朗读顺序混乱。
**解决方法**：
- 使用单一Resource定义完整的多语言文本
- 或分别设置不同语言的组件，避免直接拼接
- 利用系统的文本方向处理能力

### Q3：Resource资源如何定义多语言？
**原因**：需在resources目录下为每种语言创建对应的string.json。
**解决方法**：
- 在`resources/zh/element/string.json`定义中文
- 在`resources/en/element/string.json`定义英文
- 在`resources/ar/element/string.json`定义阿拉伯语
- 使用相同的资源ID，系统自动选择对应语言

### Q4：如何监听语言切换并更新无障碍文本？
**原因**：应用语言切换时，accessibilityText需同步更新。
**解决方法**：
- 使用`@State`监听语言变化
- 通过`Configuration`监听系统配置变化
- 重新加载Resource资源更新UI和无障碍属性

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "accessibilityConfigured": true,
  "languagesSupported": ["zh-CN", "en-US", "ar-SA"],
  "rtlHandling": "enabled",
  "concatAvoided": true,
  "apiUsed": [
    "accessibilityText",
    "accessibilityDescription",
    "Resource"
  ],
  "recommendations": [
    "建议使用Resource而非硬编码字符串",
    "RTL语言场景避免拼接",
    "确保所有语言都有对应的无障碍文本资源"
  ]
}
```

## 参考文档

- [API开发指南：多语种场景](scenario-multilingual.md)
- [API参考说明：无障碍属性](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-accessibility)
- [API参考说明：辅助功能](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-accessibility)
- [ArkUI组件：Text组件](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-text)
- [公共定义：Resource类型](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-types)

## 完整示例代码

- [ArkTS示例：多语种无障碍处理](assets/multilingual_accessibility_example.ets)
- [ArkTS示例：RTL语言处理](assets/rtl_language_handler.ets)
- [配置示例：多语言资源文件](assets/string_resources.json)

## 测试用例

### 正向测试用例
- [中英文混合朗读测试](tests/test_multilingual_positive.py)：验证中英文混合文本的正确朗读
- [Resource多语言测试](tests/test_resource_positive.py)：验证Resource资源的多语言切换

### 边界测试用例
- [RTL语言拼接测试](tests/test_rtl_boundary.py)：验证RTL语言拼接场景的处理
- [长文本朗读测试](tests/test_longtext_boundary.py)：验证长文本的朗读效果

### 异常测试用例
- [Resource缺失测试](tests/test_resource_missing.py)：验证Resource资源缺失时的降级处理
- [语言不匹配测试](tests/test_language_mismatch.py)：验证语言不一致时的提示和解决