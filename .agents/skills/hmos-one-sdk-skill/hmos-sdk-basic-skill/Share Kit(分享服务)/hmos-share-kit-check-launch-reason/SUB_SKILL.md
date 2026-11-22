---
name: hmos-share-kit-check-launch-reason
description: 判断应用是否被系统分享拉起，支持UIAbility和UIExtensionAbility两种场景，从API version 5.1.0(18)开始支持，适用于分享目标应用检测启动来源场景
---

# 判断应用是否被系统分享拉起技能

## 功能描述

本技能提供判断应用是否被系统分享拉起的能力。通过检查`LaunchParam.launchReasonMessage`字段是否为`'ReasonMessage_SystemShare'`，开发者可以准确识别应用启动原因是否为系统分享，从而在目标应用接入系统分享时进行相应的业务处理。

**核心能力**：
- 检测UIAbility组件是否被系统分享拉起
- 检测UIExtensionAbility组件（如ShareExtensionAbility）是否被系统分享拉起
- 在onCreate和onNewWant生命周期回调中进行判断

**适用范围**：
- 仅适用于Stage模型
- API version 5.1.0(18)及以上
- 仅用于判断系统分享启动场景

## 使用场景

### 触发词
- "判断应用是否被系统分享拉起"
- "系统分享启动检测"
- "分享目标应用启动判断"
- "检测分享启动原因"
- "ReasonMessage_SystemShare"

### 能做
- 在UIAbility的onCreate生命周期中判断是否被系统分享拉起
- 在UIAbility的onNewWant生命周期中判断是否被系统分享拉起  
- 在UIExtensionAbility的onCreate生命周期中判断是否被系统分享拉起
- 在ShareExtensionAbility的onCreate生命周期中判断是否被系统分享拉起
- 根据启动原因执行相应的业务逻辑

### 绝不做
- 不处理非系统分享启动的场景判断
- 不替代其他启动原因的判断逻辑
- 不执行分享内容的实际处理（仅判断启动原因）
- 不支持FA模型应用
- 不支持API version 5.1.0(18)以下版本

### 补充
- launchReasonMessage字段从API version 18开始支持
- 需配合Share Kit相关能力使用
- 判断完成后，分享内容处理需要额外的业务代码实现

## 调用规范和规则

### 输入约束
- 应用必须为Stage模型
- 目标API版本必须≥5.1.0(18)
- 必须正确实现UIAbility或UIExtensionAbility组件
- launchParam参数必须由系统传递，不可手动构造

### 执行约束
- 判断逻辑必须在onCreate或onNewWant生命周期回调中执行
- 最大执行时间：同步判断，无耗时限制
- 不涉及异步操作

### 内容约束
- 禁止修改launchParam参数内容
- 禁止在判断逻辑中执行耗时操作
- 禁止依赖全局变量存储启动原因

### 降级约束
- API版本不支持时：提示用户升级系统或使用传统判断方式（LaunchReason.SHARE）
- launchParam为undefined时：记录日志并跳过判断逻辑
- 字段值异常时：当作非系统分享启动处理

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认应用使用Stage模型
2. 确认目标API版本≥5.1.0(18)
3. 确认已正确导入相关模块

**参数准备**：
```typescript
// 确保导入了必要的模块
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
```

### 步骤2：在UIAbility中判断系统分享启动

**场景1：在onCreate中判断**

**示例代码**：
```typescript
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

export default class ShareUIAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 判断是否被系统分享拉起
    if (launchParam.launchReasonMessage === 'ReasonMessage_SystemShare') {
      // 识别为被系统分享拉起
      hilog.info(0x0000, 'ShareUIAbility', '应用被拉起原因：系统分享');
      
      // 执行分享相关的业务逻辑
      // 例如：初始化分享处理模块、准备UI等
      this.handleSystemShareLaunch(want);
    } else {
      hilog.info(0x0000, 'ShareUIAbility', 
        `应用被拉起原因：${launchParam.launchReasonMessage || '未知'}`);
    }
  }
  
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 判断是否被系统分享拉起（热启动场景）
    if (launchParam.launchReasonMessage === 'ReasonMessage_SystemShare') {
      hilog.info(0x0000, 'ShareUIAbility', '应用被拉起原因：系统分享');
      this.handleSystemShareLaunch(want);
    }
  }
  
  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 加载主页面
    windowStage.loadContent('pages/ShareUIPage', (err, data) => {
      if (err.code) {
        hilog.error(0x0000, 'ShareUIAbility', 
          `Failed to load the content. Cause: ${JSON.stringify(err)}`);
        return;
      }
      hilog.info(0x0000, 'ShareUIAbility', 
        `Succeeded in loading the content. Data: ${JSON.stringify(data)}`);
    });
  }
  
  // 处理系统分享启动的业务逻辑
  private handleSystemShareLaunch(want: Want): void {
    // 从want中获取分享数据
    // 实现分享内容处理逻辑
    hilog.info(0x0000, 'ShareUIAbility', 
      `开始处理分享内容，want: ${JSON.stringify(want)}`);
  }
}
```

**场景2：在UIExtensionAbility中判断**

**示例代码**：
```typescript
import { AbilityConstant, ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

export default class ShareExtAbility extends ShareExtensionAbility {
  onCreate(launchParam: AbilityConstant.LaunchParam): void {
    // 判断是否被系统分享拉起
    if (launchParam.launchReasonMessage === 'ReasonMessage_SystemShare') {
      // 识别为被系统分享拉起
      hilog.info(0x0000, 'ShareExtAbility', 'Extension被拉起原因：系统分享');
      
      // 执行分享相关的初始化逻辑
      // 例如：初始化UI资源、准备数据接收等
    } else {
      hilog.info(0x0000, 'ShareExtAbility', 
        `Extension被拉起原因：${launchParam.launchReasonMessage || '未知'}`);
    }
  }
  
  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    // 加载分享页面
    session.loadContent('pages/ShareExtDialog', (err, data) => {
      if (err.code) {
        hilog.error(0x0000, 'ShareExtAbility', 
          `Failed to load content. Code: ${err.code}, Message: ${err.message}`);
        return;
      }
      hilog.info(0x0000, 'ShareExtAbility', 
        `Succeeded in loading content. Data: ${JSON.stringify(data)}`);
    });
    
    // 处理分享内容
    this.processShareContent(want, session);
  }
  
  // 处理分享内容
  private processShareContent(want: Want, session: UIExtensionContentSession): void {
    // 从want中提取分享数据
    // 实现具体的分享内容处理逻辑
    hilog.info(0x0000, 'ShareExtAbility', 
      `处理分享内容，want: ${JSON.stringify(want)}`);
  }
}
```

### 步骤3：错误处理

```typescript
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

export default class ShareUIAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      // 安全校验：检查launchParam是否存在
      if (!launchParam) {
        hilog.error(0x0000, 'ShareUIAbility', 'launchParam is undefined');
        return;
      }
      
      // 安全校验：检查launchReasonMessage字段是否存在
      if (typeof launchParam.launchReasonMessage === 'undefined') {
        hilog.warn(0x0000, 'ShareUIAbility', 
          'launchReasonMessage field not supported, current API version may be too low');
        // 降级方案：使用传统判断方式
        this.handleFallbackLaunchCheck(want, launchParam);
        return;
      }
      
      // 正常判断逻辑
      if (launchParam.launchReasonMessage === 'ReasonMessage_SystemShare') {
        hilog.info(0x0000, 'ShareUIAbility', '应用被系统分享拉起');
        this.handleSystemShareLaunch(want);
      } else {
        hilog.info(0x0000, 'ShareUIAbility', 
          `应用启动原因：${launchParam.launchReasonMessage}`);
      }
      
    } catch (error) {
      hilog.error(0x0000, 'ShareUIAbility', 
        `Error checking launch reason: ${JSON.stringify(error)}`);
    }
  }
  
  // 降级方案：使用传统LaunchReason判断
  private handleFallbackLaunchCheck(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    if (launchParam.launchReason === AbilityConstant.LaunchReason.SHARE) {
      hilog.info(0x0000, 'ShareUIAbility', 
        '应用被分享拉起（使用LaunchReason.SHARE判断）');
      this.handleSystemShareLaunch(want);
    }
  }
  
  private handleSystemShareLaunch(want: Want): void {
    // 处理分享启动逻辑
  }
}
```

### 步骤4：降级处理

```typescript
import { AbilityConstant, ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

export default class ShareExtAbility extends ShareExtensionAbility {
  onCreate(launchParam: AbilityConstant.LaunchParam): void {
    try {
      // 检查API版本兼容性
      const isLaunchReasonMessageSupported = this.checkAPIVersion();
      
      if (!isLaunchReasonMessageSupported) {
        hilog.warn(0x0000, 'ShareExtAbility', 
          '当前系统版本不支持launchReasonMessage，使用降级方案');
        // 降级方案：不判断启动原因，直接作为分享处理
        // 或使用其他判断方式
        return;
      }
      
      // 正常判断流程
      if (launchParam?.launchReasonMessage === 'ReasonMessage_SystemShare') {
        hilog.info(0x0000, 'ShareExtAbility', 'Extension被系统分享拉起');
        // 执行分享相关初始化
      } else {
        hilog.info(0x0000, 'ShareExtAbility', 
          `Extension启动原因：${launchParam?.launchReasonMessage || '未知'}`);
      }
      
    } catch (error) {
      hilog.error(0x0000, 'ShareExtAbility', 
        `Error in onCreate: ${JSON.stringify(error)}`);
      // 容错处理：继续执行后续逻辑，避免影响应用启动
    }
  }
  
  // 检查API版本是否支持
  private checkAPIVersion(): boolean {
    // 实际项目中应从设备获取API版本
    // 这里仅为示例，假设支持
    return true;
  }
  
  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    session.loadContent('pages/ShareExtDialog');
  }
}
```

## 错误码说明

本技能主要涉及字段判断，无特定错误码。常见异常情况如下：

| 异常情况 | 说明 | 解决方法 |
|---------|------|---------|
| launchParam为undefined | 系统未传递启动参数 | 检查生命周期回调签名是否正确，添加参数校验 |
| launchReasonMessage为undefined | API版本过低不支持 | 使用传统LaunchReason判断方式降级处理 |
| 字段值非字符串 | 系统异常 | 添加类型检查，进行容错处理 |
| 判断结果不准确 | 多种启动原因叠加 | 结合LaunchReason枚举值进行综合判断 |

## 编译和修复问题

### 依赖声明

**module.json5配置**：
```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "deviceTypes": ["default", "tablet"],
    "deliveryWithInstall": true,
    "installationFree": false,
    "pages": "$profile:main_pages",
    "abilities": [
      {
        "name": "ShareUIAbility",
        "srcEntry": "./ets/shareability/ShareUIAbility.ets",
        "description": "$string:ShareUIAbility_desc",
        "icon": "$media:icon",
        "label": "$string:ShareUIAbility_label",
        "startWindowIcon": "$media:startIcon",
        "startWindowBackground": "$color:start_window_background",
        "exported": true,
        "skills": [
          {
            "entities": ["entity.system.home"],
            "actions": ["ohos.want.action.home"]
          }
        ]
      }
    ]
  }
}
```

**ExtensionAbility配置（ShareExtensionAbility）**：
```json
{
  "module": {
    "extensionAbilities": [
      {
        "name": "ShareExtAbility",
        "srcEntry": "./ets/shareextability/ShareExtAbility.ets",
        "type": "share",
        "description": "$string:ShareExtAbility_desc",
        "label": "$string:ShareExtAbility_label",
        "exported": true
      }
    ]
  }
}
```

### 环境要求
- HarmonyOS SDK: API version 18 (5.1.0) 及以上
- DevEco Studio: 4.0及以上
- 编译模式: Stage模型

### 常见编译问题

**问题1：导入模块报错**
```
Error: Cannot find module '@kit.AbilityKit' or its corresponding type declarations.
```
**解决方法**：
- 检查`build-profile.json5`中的`compileSdkVersion`是否≥18
- 确认项目使用Stage模型而非FA模型
- 同步项目依赖：执行`ohpm install`

**问题2：类型不匹配错误**
```
Error: Property 'launchReasonMessage' does not exist on type 'LaunchParam'.
```
**解决方法**：
- 更新HarmonyOS SDK到API version 18及以上
- 检查`@kit.AbilityKit`版本是否符合要求
- 添加类型声明或使用可选链操作符

**问题3：生命周期回调签名错误**
```
Error: Property 'onCreate' has incompatible signature.
```
**解决方法**：
- 确保onCreate和onNewWant方法签名正确
- 检查参数类型是否为`Want`和`AbilityConstant.LaunchParam`
- 确认返回值类型为`void`

## 常见问题与解决方法

### Q1：如何区分系统分享启动和普通启动？

**原因**：应用可能有多种启动方式，需要准确识别系统分享启动

**解决方法**：
- 在onCreate和onNewWant中检查`launchParam.launchReasonMessage`
- 值为`'ReasonMessage_SystemShare'`时为系统分享启动
- 结合`launchParam.launchReason`进行双重确认（可选）
```typescript
if (launchParam.launchReasonMessage === 'ReasonMessage_SystemShare') {
  // 确认为系统分享启动
  hilog.info(0x0000, TAG, 'System share launch confirmed');
}
```

### Q2：onCreate和onNewWant都需要判断吗？

**原因**：应用启动有冷启动和热启动两种场景

**解决方法**：
- **onCreate**：应用冷启动时调用，必须判断
- **onNewWant**：应用热启动（已存在实例）时调用，建议也判断
- 两个回调中都添加判断逻辑以确保覆盖所有启动场景

### Q3：旧版本系统不支持launchReasonMessage怎么办？

**原因**：launchReasonMessage字段从API version 18才开始支持

**解决方法**：
- 使用可选链操作符检查字段是否存在
- 降级使用`LaunchReason.SHARE`枚举值判断
- 在代码中添加版本检查逻辑
```typescript
if (launchParam.launchReasonMessage) {
  // 新版本：使用launchReasonMessage
  if (launchParam.launchReasonMessage === 'ReasonMessage_SystemShare') {
    // 系统分享启动
  }
} else {
  // 旧版本：使用LaunchReason
  if (launchParam.launchReason === AbilityConstant.LaunchReason.SHARE) {
    // 分享启动
  }
}
```

### Q4：判断为系统分享启动后，如何获取分享内容？

**原因**：仅判断启动原因不够，还需要处理分享数据

**解决方法**：
- 从`onCreate(want, launchParam)`的`want`参数中提取分享数据
- 从`onNewWant(want, launchParam)`的`want`参数中提取分享数据
- 根据分享类型（文本、图片、文件等）进行相应处理
```typescript
onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  if (launchParam.launchReasonMessage === 'ReasonMessage_SystemShare') {
    // 提取分享数据
    const shareText = want.parameters?.['shareText'] as string;
    const shareUri = want.parameters?.['shareUri'] as string;
    // 处理分享数据...
  }
}
```

### Q5：UIAbility和ShareExtensionAbility有什么区别？

**原因**：两种组件都可用于分享场景，需要明确选择

**解决方法**：
- **UIAbility**：适用于作为独立应用接收分享，会在任务列表显示
- **ShareExtensionAbility**：专为分享设计，提供分享详情页，不会在任务列表显示
- 根据业务需求选择：
  - 需要独立任务→使用UIAbility
  - 仅处理分享内容→使用ShareExtensionAbility

## 输出结果报告

判断完成后，应用将识别启动原因并输出以下信息：

```json
{
  "status": "success",
  "launchReason": "ReasonMessage_SystemShare",
  "isSystemShare": true,
  "apiVersion": "18+",
  "componentType": "UIAbility | UIExtensionAbility",
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

## 参考文档

- [判断应用是否被系统分享拉起开发指南](references/share-launch-param.md)
- [@ohos.app.ability.UIAbility API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-uiability)
- [@ohos.app.ability.ShareExtensionAbility API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-shareextensionability)
- [@ohos.app.ability.AbilityConstant API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-abilityconstant)
- [@ohos.app.ability.UIExtensionAbility API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-uiextensionability)

## 完整示例代码

- [UIAbility判断系统分享启动示例](assets/uiability-share-launch-example.ets)
- [ShareExtensionAbility判断系统分享启动示例](assets/share-extension-ability-example.ets)
- [错误处理和降级方案示例](assets/error-handling-example.ets)

## 测试用例

### 正向测试用例
- [系统分享冷启动UIAbility判断测试](tests/test_uiability_cold_launch.ts)：验证UIAbility冷启动时正确识别系统分享启动
- [系统分享热启动UIAbility判断测试](tests/test_uiability_hot_launch.ts)：验证UIAbility热启动时正确识别系统分享启动
- [ShareExtensionAbility系统分享启动判断测试](tests/test_share_extension_launch.ts)：验证ShareExtensionAbility正确识别系统分享启动

### 边界测试用例
- [低API版本兼容性测试](tests/test_api_version_compatibility.ts)：验证API version < 18时的降级处理
- [launchParam为空的边界测试](tests/test_null_launchparam.ts)：验证参数为空时的容错处理
- [多场景混合启动测试](tests/test_mixed_launch_scenarios.ts)：验证多种启动原因叠加时的判断准确性

### 异常测试用例
- [异常启动参数测试](tests/test_invalid_launch_param.ts)：验证异常参数时的错误处理
- [类型不匹配测试](tests/test_type_mismatch.ts)：验证字段类型异常时的处理逻辑
- [系统异常场景测试](tests/test_system_exception.ts)：验证系统异常时的降级方案