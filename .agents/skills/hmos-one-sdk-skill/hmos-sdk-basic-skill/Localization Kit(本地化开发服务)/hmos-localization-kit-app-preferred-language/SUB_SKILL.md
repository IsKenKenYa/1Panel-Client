---
name: hmos-localization-kit-app-preferred-language
description: 管理应用偏好语言，支持获取、设置和清除应用偏好语言，实现应用级别的语言设置，应用语言与系统语言独立管理，适用于多语言应用的语言切换场景
---

# 应用偏好语言管理技能

## 功能描述

本技能提供HarmonyOS应用偏好语言的管理能力，支持获取当前应用偏好语言、设置应用偏好语言、清除应用偏好语言（跟随系统语言）。通过应用偏好语言设置，可以实现应用级别的语言切换，不影响系统语言设置，适用于多语言应用的个性化语言配置场景。

## 使用场景

### 触发词
- "应用偏好语言"
- "获取应用语言"
- "设置应用语言"
- "切换应用语言"
- "应用语言设置"
- "应用独立语言"

### 能做
- 获取应用当前偏好语言设置
- 设置应用偏好语言为目标语言（如zh-Hans、en-US等）
- 清除应用偏好语言，使应用语言跟随系统语言
- 实现应用级别的语言切换功能
- 支持多语言应用的个性化语言配置

### 绝不做
- 修改系统语言设置（仅影响应用本身）
- 处理与语言无关的国际化功能
- 提供语言资源管理能力
- 处理时区、日期格式等其他本地化设置

### 补充
- 应用偏好语言设置后立即生效，但清除偏好语言需要应用冷启动后才生效
- 应用仅支持设置一种偏好语言
- 设置为'default'表示清除偏好语言，应用将跟随系统语言
- 需要配合应用的资源文件实现多语言支持

## 调用规范和规则

### 输入约束
- 语言标识必须为合法的语言ID（如zh-Hans、en-US）或'default'
- 语言ID需符合BCP 47规范
- 语言参数类型必须为string
- 不得传入空字符串、null或undefined作为语言参数

### 执行约束
- API调用为同步操作，无需异步等待
- 设置偏好语言立即生效，不需要应用重启
- 清除偏好语言（设置为'default'）需要应用冷启动后生效
- 最大调用频次：无限制

### 内容约束
- 禁止使用非合法的语言ID
- 禁止设置多个偏好语言
- 禁止在未获取应用偏好语言前直接操作相关资源
- 禁止假设应用语言与系统语言一致

### 降级约束
- 语言ID验证失败：捕获异常并提示用户使用合法的语言ID
- 参数类型错误：捕获异常并提示参数类型错误
- 设置失败：记录日志并提示用户重试

## 调用流程和步骤

### 步骤1：导入模块

**导入必要的模块**：
```typescript
import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2：获取应用偏好语言

**功能说明**：获取应用当前设置的偏好语言。

**示例代码**：
```typescript
// 获取应用偏好语言
let appPreferredLanguage: string = i18n.System.getAppPreferredLanguage();
console.log(`当前应用偏好语言: ${appPreferredLanguage}`);
```

**返回值说明**：
- 返回类型：string
- 返回值：应用偏好语言ID，如'zh-Hans'、'en-US'等
- 如果未设置偏好语言，返回系统语言

### 步骤3：设置应用偏好语言

**功能说明**：将应用偏好语言设置为目标语言，应用界面会切换为目标语言，仅影响应用本身，不影响系统语言。

**示例代码**：
```typescript
try {
  // 设置应用偏好语言为简体中文
  i18n.System.setAppPreferredLanguage('zh-Hans');
  console.log('应用偏好语言设置成功');
  
  // 验证设置结果
  let currentLanguage = i18n.System.getAppPreferredLanguage();
  console.log(`设置后的应用偏好语言: ${currentLanguage}`);
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`设置应用偏好语言失败，错误码: ${err.code}, 错误信息: ${err.message}`);
  
  // 错误处理
  if (err.code === 401) {
    console.error('参数错误：请检查语言ID是否合法');
  } else if (err.code === 890001) {
    console.error('参数验证失败：语言ID格式不正确');
  }
}
```

**参数说明**：
- 参数名：language
- 类型：string
- 必填：是
- 说明：合法的语言ID（如zh-Hans、en-US）或'default'

**常用语言ID**：
- zh-Hans：简体中文
- zh-Hant：繁体中文
- en-US：美式英语
- en-GB：英式英语
- ja-JP：日语
- ko-KR：韩语

### 步骤4：清除应用偏好语言

**功能说明**：将应用偏好语言设置为'default'，应用语言将跟随系统语言，该设置在应用冷启动后生效。

**示例代码**：
```typescript
try {
  // 清除应用偏好语言，设置为'default'
  i18n.System.setAppPreferredLanguage('default');
  console.log('应用偏好语言已清除，将在应用重启后跟随系统语言');
  
  // 提示用户重启应用
  console.log('请重启应用以使设置生效');
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`清除应用偏好语言失败，错误码: ${err.code}, 错误信息: ${err.message}`);
}
```

### 步骤5：完整示例 - 语言切换功能

**功能说明**：实现应用内语言切换的完整流程，包括获取当前语言、设置新语言、验证结果。

**示例代码**：
```typescript
import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

class AppLanguageManager {
  // 获取当前应用偏好语言
  getCurrentLanguage(): string {
    try {
      let language = i18n.System.getAppPreferredLanguage();
      console.log(`当前应用语言: ${language}`);
      return language;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`获取应用语言失败: ${err.message}`);
      return '';
    }
  }
  
  // 设置应用偏好语言
  setLanguage(languageId: string): boolean {
    try {
      // 验证语言ID不为空
      if (!languageId || languageId.trim() === '') {
        console.error('语言ID不能为空');
        return false;
      }
      
      // 设置应用偏好语言
      i18n.System.setAppPreferredLanguage(languageId);
      
      // 验证设置是否成功
      let currentLanguage = i18n.System.getAppPreferredLanguage();
      if (currentLanguage === languageId) {
        console.log(`应用语言已切换为: ${languageId}`);
        return true;
      } else {
        console.warn(`语言设置可能未生效，期望: ${languageId}, 实际: ${currentLanguage}`);
        return false;
      }
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`设置应用语言失败，错误码: ${err.code}, 信息: ${err.message}`);
      return false;
    }
  }
  
  // 重置为系统语言
  resetToSystemLanguage(): boolean {
    try {
      i18n.System.setAppPreferredLanguage('default');
      console.log('已重置为系统语言，请重启应用生效');
      return true;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`重置语言失败: ${err.message}`);
      return false;
    }
  }
}

// 使用示例
let languageManager = new AppLanguageManager();

// 获取当前语言
let currentLang = languageManager.getCurrentLanguage();

// 切换为英语
if (languageManager.setLanguage('en-US')) {
  console.log('语言切换成功');
}

// 重置为系统语言
languageManager.resetToSystemLanguage();
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：1. 必填参数未指定；2. 参数类型错误 | 检查语言参数是否为string类型，是否已传值 |
| 890001 | 参数验证失败。可能原因：参数验证失败 | 确认语言ID格式正确，符合BCP 47规范 |

**错误处理示例**：
```typescript
try {
  i18n.System.setAppPreferredLanguage('invalid-language-id');
} catch (error) {
  let err: BusinessError = error as BusinessError;
  
  switch (err.code) {
    case 401:
      console.error('参数错误：请检查参数类型和必填项');
      break;
    case 890001:
      console.error('无效的语言ID：请使用合法的语言ID，如zh-Hans、en-US');
      break;
    default:
      console.error(`未知错误: ${err.message}`);
  }
}
```

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.LocalizationKit": "最新版本",
    "@kit.BasicServicesKit": "最新版本"
  }
}
```

### 环境要求
- HarmonyOS SDK: API version 9及以上（getAppPreferredLanguage）
- HarmonyOS SDK: API version 11及以上（setAppPreferredLanguage）
- 开发环境: DevEco Studio 3.1及以上

### 常见编译问题

**问题1：模块导入失败**
```
Error: Cannot find module '@kit.LocalizationKit' or its corresponding type declarations.
```
**解决方法**：
- 确保HarmonyOS SDK版本不低于API version 9
- 在module.json5中添加必要权限
- 检查项目SDK配置是否正确

**问题2：API不存在错误**
```
Error: Property 'setAppPreferredLanguage' does not exist on type 'System'.
```
**解决方法**：
- setAppPreferredLanguage API从API version 11开始支持
- 检查并升级HarmonyOS SDK版本至API version 11或更高

**问题3：类型错误**
```
Error: Type 'string' is not assignable to type 'BusinessError'.
```
**解决方法**：
- 使用类型断言：`let err: BusinessError = error as BusinessError;`
- 确保正确导入BusinessError类型

## 常见问题与解决方法

### Q1：设置应用偏好语言后，界面语言未变化
**原因**：
- 应用资源文件中未包含对应语言的资源
- 资源文件命名或路径不正确
- 应用未正确加载资源

**解决方法**：
- 检查resources目录下是否包含对应语言的资源文件夹（如zh_Hans、en_US）
- 确认资源文件命名符合规范
- 重启应用验证设置是否生效

### Q2：清除偏好语言后，语言未跟随系统变化
**原因**：
- 清除偏好语言需要应用冷启动后才生效
- 应用仍在运行中，未完全退出

**解决方法**：
- 完全退出应用（杀进程）
- 重新启动应用
- 确认系统语言设置正确

### Q3：设置语言时提示参数错误
**原因**：
- 语言ID格式不正确
- 语言ID不符合BCP 47规范
- 参数类型错误（非string类型）

**解决方法**：
- 使用标准的语言ID格式，如'zh-Hans'、'en-US'
- 确保参数为string类型
- 参考BCP 47语言标签规范

### Q4：如何判断应用是否设置了偏好语言
**原因**：
- getAppPreferredLanguage返回的语言可能是系统语言
- 需要区分是应用设置的偏好语言还是系统语言

**解决方法**：
```typescript
// 获取应用偏好语言
let appLanguage = i18n.System.getAppPreferredLanguage();
let systemLanguage = i18n.System.getSystemLanguage();

if (appLanguage === systemLanguage) {
  console.log('应用使用系统语言，可能未设置偏好语言或设置为default');
} else {
  console.log(`应用设置了独立的偏好语言: ${appLanguage}`);
}
```

### Q5：元服务中如何使用应用偏好语言API
**原因**：
- 元服务API支持有版本限制

**解决方法**：
- getAppPreferredLanguage从API version 12开始支持元服务
- setAppPreferredLanguage从API version 12开始支持元服务
- 确保元服务的API版本不低于12

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "应用偏好语言管理",
  "currentLanguage": "zh-Hans",
  "action": "set|get|reset",
  "apiUsed": [
    "i18n.System.getAppPreferredLanguage",
    "i18n.System.setAppPreferredLanguage"
  ],
  "message": "应用偏好语言操作成功"
}
```

## 参考文档

- [应用偏好语言开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/i18n-preferred-language)
- [i18n API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-i18n)

## 完整示例代码

- [ArkTS示例代码](assets/app_preferred_language_example.ets)
- [TypeScript示例](assets/language_manager.ts)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [获取应用偏好语言](tests/test_positive.ets)：测试正常获取应用偏好语言
- [设置应用偏好语言](tests/test_positive.ets)：测试设置有效的语言ID
- [清除应用偏好语言](tests/test_positive.ets)：测试设置default清除偏好语言

### 边界测试用例
- [空字符串参数测试](tests/test_boundary.ets)：测试传入空字符串的处理
- [特殊语言ID测试](tests/test_boundary.ets)：测试特殊语言ID（如zh-Hans-CN）
- [连续设置测试](tests/test_boundary.ets)：测试连续多次设置不同语言

### 异常测试用例
- [无效语言ID测试](tests/test_exception.ets)：测试传入无效的语言ID
- [参数类型错误测试](tests/test_exception.ets)：测试传入非string类型参数
- [null参数测试](tests/test_exception.ets)：测试传入null值的处理