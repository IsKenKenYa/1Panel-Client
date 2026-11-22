---
name: hmos-accessibility-kit-button-annotation
description: 为非文本按钮提供无障碍标注信息,支持accessibilityText和accessibilityRole设置,适用于图片按钮、图标按钮等无障碍场景,提升屏幕朗读体验
---

# 按钮标注技能

## 功能描述

本技能为非文本类型的按钮组件提供无障碍标注能力,通过设置accessibilityText和accessibilityRole属性,确保屏幕朗读用户能够正确识别和操作按钮。适用于所有不含文本属性的可点击组件,包括Image、图标、自定义控件中的虚拟按钮区域等。

**核心能力**:
- 设置无障碍文本(accessibilityText),为非文本按钮提供朗读内容
- 设置无障碍角色(accessibilityRole),明确组件类型为按钮
- 动态更新无障碍文本,适应按钮状态变化(如播放/暂停切换)

**适用范围**:
- Image组件作为按钮
- 图标按钮(SymbolGlyph)
- 自定义绘制组件中的可点击区域
- 任何不含文本属性的可交互组件

**限制条件**:
- 标注文本不应包含控件类型(如"按钮")
- 标注文本不应包含操作提示(如"单指双击即可打开")
- 必须同时设置accessibilityLevel为"yes"才能生效

**典型场景**:
- 播放/暂停按钮标注
- 设置图标按钮标注
- 导航按钮标注
- 操作工具栏按钮标注

## 使用场景

### 触发词
- "按钮无障碍标注"
- "图片按钮标注"
- "图标按钮标注"
- "非文本按钮标注"
- "accessibilityText设置"
- "按钮accessibilityRole"

### 能做
- 为Image组件设置无障碍文本和角色类型
- 为图标按钮添加屏幕朗读支持
- 动态更新按钮的无障碍文本内容
- 为自定义控件中的虚拟按钮区域提供标注
- 设置按钮的无障碍重要性级别

### 绝不做
- 不为已包含文本的Button组件设置accessibilityText(会覆盖原有文本)
- 不在标注文本中添加控件类型描述
- 不在标注文本中添加操作指引文本
- 不处理纯文本组件的无障碍标注
- 不处理不可交互组件的无障碍标注

### 补充
- accessibilityText会覆盖组件原有的文本属性播报
- accessibilityRole影响屏幕朗读的播报方式和内容
- 标注文本应简洁明了,直接描述按钮功能
- 对于状态切换按钮,应根据当前状态动态更新标注文本

## 调用规范和规则

### 输入约束
- 组件类型: 必须为可交互组件(Image、SymbolGlyph等非文本组件)
- 标注文本: 长度建议不超过20字符,简洁明了
- 角色类型: 必须使用AccessibilityRoleType.BUTTON
- 无障碍级别: 必须设置accessibilityLevel为"yes"

### 执行约束
- API调用顺序: 先设置accessibilityLevel,再设置accessibilityRole和accessibilityText
- 最大文本长度: 建议不超过50字符(避免播报过长)
- 状态更新频率: 状态切换按钮需在状态改变时立即更新accessibilityText
- 必须调用: accessibilityLevel("yes")

### 内容约束
- 禁止添加: 控件类型描述(如"按钮")
- 禁止添加: 操作指引(如"单指双击即可打开")
- 禁止使用: 空字符串或undefined作为标注文本
- 禁止覆盖: 已有文本的Button组件不应设置accessibilityText

### 降级约束
- 组件不支持: 提示用户该组件不支持无障碍属性
- 文本过长: 建议用户缩短文本至20字符以内
- 角色类型错误: 提示用户使用正确的AccessibilityRoleType枚举值
- API版本不匹配: 提示用户检查API version兼容性(accessibilityRole需要API 18+)

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 检查组件是否为非文本类型(Image、SymbolGlyph等)
2. 检查组件是否支持点击事件(onClick)
3. 检查API版本兼容性(accessibilityRole需要API 18+)
4. 检查标注文本是否符合规范(不含控件类型和操作指引)

**参数准备**:
```typescript
// ArkTS示例
interface ButtonAnnotationParams {
  accessibilityText: string;  // 标注文本,如"播放"、"暂停"
  accessibilityRole: AccessibilityRoleType.BUTTON;  // 固定为BUTTON类型
  accessibilityLevel: 'yes';  // 固定为"yes"
  isStateChange?: boolean;    // 是否为状态切换按钮
}
```

### 步骤2: 设置无障碍属性

**示例代码**:
```typescript
// 导入必要枚举
import { AccessibilityRoleType } from '@kit.ArkUI';

// 基础按钮标注示例
@Entry
@Component
struct BasicButtonAnnotation {
  build() {
    Column() {
      // 示例1: 图片按钮标注
      Image($r('sys.media.ohos_ic_public_play'))
        .width(50)
        .height(50)
        .onClick(() => {
          console.info('播放按钮点击');
        })
        .accessibilityLevel('yes')  // 设置无障碍重要性为可识别
        .accessibilityRole(AccessibilityRoleType.BUTTON)  // 设置为按钮类型
        .accessibilityText('播放')  // 设置标注文本
        
      // 示例2: 状态切换按钮标注
      Image(this.isPlaying ? $r('sys.media.ohos_ic_public_pause') : $r('sys.media.ohos_ic_public_play'))
        .width(50)
        .height(50)
        .onClick(() => {
          this.isPlaying = !this.isPlaying;
        })
        .accessibilityLevel('yes')
        .accessibilityRole(AccessibilityRoleType.BUTTON)
        .accessibilityText(this.isPlaying ? '暂停' : '播放')  // 根据状态动态更新
    }
  }
  
  @State isPlaying: boolean = false;
}
```

### 步骤3: 动态状态更新

**示例代码**:
```typescript
// 状态切换按钮的完整实现
@Entry
@Component
struct StatefulButtonAnnotation {
  @State isPlaying: boolean = false;
  
  play() {
    console.info('开始播放');
  }
  
  pause() {
    console.info('暂停播放');
  }
  
  build() {
    NavDestination() {
      Column() {
        Flex({
          direction: FlexDirection.Column,
          alignItems: ItemAlign.Center,
          justifyContent: FlexAlign.Center,
        }) {
          Row() {
            // 播放/暂停按钮
            Image(this.isPlaying ? $r('sys.media.ohos_ic_public_pause') : $r('sys.media.ohos_ic_public_play'))
              .width(50)
              .height(50)
              .onClick(() => {
                this.isPlaying = !this.isPlaying;
                if (this.isPlaying) {
                  this.play();
                } else {
                  this.pause();
                }
              })
              .accessibilityLevel('yes')
              .accessibilityRole(AccessibilityRoleType.BUTTON)
              .accessibilityText(this.isPlaying ? '暂停' : '播放')  // 根据状态动态更新标注
            
            Text('Good_morning.mp3')
              .margin({ left: 10 })
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.White)
      }
    }
    .title('播放器示例')
  }
}
```

### 步骤4: 错误处理

```typescript
// 错误处理示例
@Entry
@Component
struct ButtonAnnotationWithErrorHandling {
  build() {
    Column() {
      try {
        Image($r('sys.media.ohos_ic_public_play'))
          .width(50)
          .height(50)
          .onClick(() => {
            console.info('播放按钮点击');
          })
          .accessibilityLevel('yes')
          .accessibilityRole(AccessibilityRoleType.BUTTON)
          .accessibilityText('播放')
      } catch (error) {
        console.error('无障碍属性设置失败:', error.message);
        // 降级处理: 仅设置基础属性
        Image($r('sys.media.ohos_ic_public_play'))
          .width(50)
          .height(50)
          .onClick(() => {
            console.info('播放按钮点击');
          })
      }
    }
  }
}
```

### 步骤5: 降级处理

```typescript
// 降级处理方案
@Entry
@Component
struct ButtonAnnotationFallback {
  @State hasAccessibilitySupport: boolean = true;
  
  build() {
    Column() {
      if (this.hasAccessibilitySupport) {
        // 正常方案: 完整无障碍属性
        Image($r('sys.media.ohos_ic_public_play'))
          .width(50)
          .height(50)
          .onClick(() => {
            console.info('播放按钮点击');
          })
          .accessibilityLevel('yes')
          .accessibilityRole(AccessibilityRoleType.BUTTON)
          .accessibilityText('播放')
      } else {
        // 降级方案: 仅保留基本功能
        Image($r('sys.media.ohos_ic_public_play'))
          .width(50)
          .height(50)
          .onClick(() => {
            console.info('播放按钮点击');
          })
        // 添加视觉提示标签
        Text('播放')
          .fontSize(12)
          .margin({ top: 5 })
      }
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| INVALID_COMPONENT_TYPE | 组件类型不支持无障碍属性 | 使用Image、SymbolGlyph等支持无障碍属性的组件 |
| ACCESSIBILITY_TEXT_EMPTY | 标注文本为空字符串或undefined | 设置有效的标注文本内容 |
| INVALID_ROLE_TYPE | accessibilityRole类型错误 | 使用AccessibilityRoleType.BUTTON枚举值 |
| API_VERSION_MISMATCH | API版本不兼容 | accessibilityRole需要API version 18+ |
| TEXT_CONTAINS_CONTROL_TYPE | 标注文本包含控件类型描述 | 移除"按钮"等控件类型描述 |
| TEXT_CONTAINS_OPERATION_HINT | 标注文本包含操作指引 | 移除"单指双击即可打开"等操作指引 |
| ACCESSIBILITY_LEVEL_NOT_SET | 未设置accessibilityLevel | 必须设置accessibilityLevel('yes') |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ArkUI": "^1.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK: API version 10+ (accessibilityText)
- HarmonyOS SDK: API version 18+ (accessibilityRole)
- DevEco Studio: 3.1+

### 常见编译问题

**问题1: AccessibilityRoleType未定义**
```
Error: 'AccessibilityRoleType' is not defined
```
**解决方法**: 导入ArkUIKit
```typescript
import { AccessibilityRoleType } from '@kit.ArkUI';
```

**问题2: accessibilityRole API版本不兼容**
```
Error: Property 'accessibilityRole' does not exist on type 'ImageAttribute'
```
**解决方法**: 检查API版本,accessibilityRole需要API version 18+
```typescript
// 在build-profile.json5中设置minAPIVersion
{
  "app": {
    "minAPIVersion": 18
  }
}
```

**问题3: 标注文本包含控件类型**
```
Warning: 标注文本不应包含控件类型描述
```
**解决方法**: 移除控件类型描述
```typescript
// 错误示例
.accessibilityText('播放按钮')

// 正确示例
.accessibilityText('播放')
```

## 常见问题与解决方法

### Q1: 标注文本播报时自动添加了"按钮"字样
**原因**: accessibilityRole设置为BUTTON后,屏幕朗读会自动添加控件类型描述
**解决方法**: 标注文本中不应手动添加"按钮"字样,屏幕朗读会自动播报"播放,按钮"

### Q2: 状态切换按钮播报内容不更新
**原因**: accessibilityText未根据状态动态更新
**解决方法**: 在状态变量改变时,同步更新accessibilityText
```typescript
@State isPlaying: boolean = false;
.accessibilityText(this.isPlaying ? '暂停' : '播放')
```

### Q3: 按钮未被屏幕朗读识别
**原因**: 未设置accessibilityLevel或设置为"auto"
**解决方法**: 明确设置accessibilityLevel为"yes"
```typescript
.accessibilityLevel('yes')
```

### Q4: 标注文本播报过长影响体验
**原因**: 标注文本过长,超过最佳长度
**解决方法**: 缩短标注文本至20字符以内
```typescript
// 错误示例
.accessibilityText('点击此按钮开始播放音频文件')

// 正确示例
.accessibilityText('播放')
```

### Q5: 已有文本的Button组件播报内容被覆盖
**原因**: Button组件设置accessibilityText会覆盖原有文本播报
**解决方法**: 对于已包含文本的Button组件,不应设置accessibilityText
```typescript
// 错误示例: 已有文本的Button不应设置accessibilityText
Button('播放')
  .accessibilityText('开始播放')  // 会覆盖"播放"文本

// 正确示例: 仅设置accessibilityLevel和accessibilityRole
Button('播放')
  .accessibilityLevel('yes')
  .accessibilityRole(AccessibilityRoleType.BUTTON)
```

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "buttonAnnotationApplied": true,
  "accessibilityTextSet": "播放",
  "accessibilityRoleSet": "BUTTON",
  "accessibilityLevelSet": "yes",
  "isStatefulButton": false,
  "apiUsed": [
    "accessibilityLevel",
    "accessibilityRole",
    "accessibilityText"
  ],
  "apiVersionRequirements": {
    "accessibilityText": "API 10+",
    "accessibilityRole": "API 18+"
  }
}
```

## 参考文档

- [按钮标注开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scenario-button-annotation)
- [无障碍属性API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-accessibility)

## 完整示例代码

- [基础按钮标注示例](assets/basic-button-annotation.ets)
- [状态切换按钮示例](assets/stateful-button-annotation.ets)
- [图标按钮标注示例](assets/icon-button-annotation.ets)

## 测试用例

### 正向测试用例
- [图片按钮标注测试](tests/test_image_button_annotation.py): 测试Image组件的无障碍标注设置
- [状态切换按钮测试](tests/test_stateful_button_annotation.py): 测试播放/暂停按钮的状态切换标注
- [图标按钮标注测试](tests/test_icon_button_annotation.py): 测试SymbolGlyph组件的无障碍标注

### 边界测试用例
- [最大文本长度测试](tests/test_max_text_length.py): 测试标注文本长度限制
- [API版本兼容性测试](tests/test_api_version_compatibility.py): 测试不同API版本的兼容性

### 异常测试用例
- [空标注文本测试](tests/test_empty_text.py): 测试空字符串标注文本的处理
- [错误角色类型测试](tests/test_invalid_role_type.py): 测试错误的AccessibilityRoleType值
- [组件类型不支持测试](tests/test_unsupported_component.py): 测试不支持无障碍属性的组件处理