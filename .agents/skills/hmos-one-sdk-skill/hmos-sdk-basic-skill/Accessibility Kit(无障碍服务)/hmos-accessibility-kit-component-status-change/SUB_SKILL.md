---
name: hmos-accessibility-kit-component-status-change
description: 实现控件状态变化时的无障碍文本实时更新功能，支持状态切换时动态播报无障碍信息，适用于播放暂停按钮、开关切换等状态变化场景
---

# 控件状态变化无障碍文本更新技能

## 功能描述

本技能用于实现控件状态变化时的无障碍文本实时更新功能。当控件状态发生变化时(如播放/暂停按钮的状态切换),通过accessibilityText API动态设置无障碍文本,确保屏幕朗读服务能够准确播报控件当前状态,提升应用的无障碍体验。

核心功能:
- 状态变化时实时更新无障碍文本
- 支持多种状态切换场景(播放/暂停、开关等)
- 确保屏幕朗读准确播报当前状态
- 提升视障用户的使用体验

## 使用场景

### 触发词
- "控件状态变化"
- "播放暂停按钮状态切换"
- "无障碍文本动态更新"
- "屏幕朗读状态播报"
- "accessibilityText状态变化"

### 能做
- 为状态变化控件设置动态无障碍文本
- 实现播放/暂停按钮的状态切换播报
- 为开关类控件提供状态播报
- 确保状态变化后立即播报新状态
- 提升控件的无障碍可访问性

### 绝不做
- 不适用于静态文本控件
- 不处理无状态变化的场景
- 不替代控件本身的文本属性
- 不用于一次性设置的场景

### 补充
- 需结合控件状态变量(如isPlaying)使用
- 建议为状态变化提供明确的播报文本
- 可与onClick事件同步使用
- 确保状态文本简洁明确

## 调用规范和规则

### 输入约束
- 状态变量: 必须有明确的状态标志变量(如boolean类型的isPlaying)
- 无障碍文本: 必须提供状态对应的无障碍文本内容
- 文件格式: ArkTS(.ets)格式
- 状态数量: 建议不超过3个状态(避免播报复杂)

### 执行约束
- 状态切换耗时: 最大100ms
- 文本更新频次: 每次状态变化时更新
- 必须同步状态变量和无障碍文本

### 内容约束
- 禁止使用空字符串作为无障碍文本
- 禁止使用过长的文本(建议不超过10字符)
- 禁止状态文本不明确(如"状态变化")

### 降级约束
- 状态变量不存在: 提示用户添加状态变量
- 无障碍文本未设置: 使用控件文本属性作为降级
- API不支持: 使用静态文本替代

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 确认控件有状态变量(如isPlaying)
2. 确认状态变量为boolean或枚举类型
3. 准备状态对应的无障碍文本内容

**参数准备**:
```typescript
// 定义状态变量
@State isPlaying: boolean = true;

// 准备无障碍文本
const accessibilityText = isPlaying ? '暂停' : '播放';
```

### 步骤2: 调用API

**示例代码**:
```typescript
import { PromptAction } from "@kit.ArkUI"

@Entry
@Component
export struct StatusChangeComponent {
  @State isPlaying: boolean = true;
  uiContext: UIContext = this.getUIContext();
  promptAction: PromptAction = this.uiContext.getPromptAction();
  
  play() {
    console.info('play audio file');
  }
  
  pause() {
    console.info('pause playing of audio file');
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
            Image(this.isPlaying ? $r('sys.media.ohos_ic_public_pause') : $r('sys.media.ohos_ic_public_play'))
              .width(50)
              .height(50)
              .onClick(() => {
                // 显示状态变化提示
                this.promptAction.showToast({
                  message: this.isPlaying ? 'Play' : 'Pause'
                })
                // 切换状态
                this.isPlaying = !this.isPlaying;
                // 执行对应操作
                if (this.isPlaying) {
                  this.play();
                } else {
                  this.pause();
                }
              })
              // 设置无障碍文本,根据状态动态变化
              .accessibilityText(this.isPlaying ? '暂停' : '播放')
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.White)
      }
    }.title('控件状态变化')
  }
}
```

### 步骤3: 错误处理

```typescript
// 错误处理代码
try {
  // 确保UIContext和PromptAction正确初始化
  if (!this.uiContext) {
    console.error('UIContext is not initialized');
    return;
  }
  
  const promptAction = this.uiContext.getPromptAction();
  if (!promptAction) {
    console.error('PromptAction is not available');
    return;
  }
  
  // 执行状态切换和文本更新
  this.isPlaying = !this.isPlaying;
  
} catch (error) {
  console.error('状态切换失败:', error.message);
  // 降级处理: 使用静态文本
  .accessibilityText('播放暂停按钮');
}
```

### 步骤4: 降级处理

```typescript
// 降级处理代码
async function handleStatusChangeFallback(): Promise<void> {
  try {
    // 如果accessibilityText不支持,使用基础文本
    // 提供基本的播报功能
    console.warn('使用降级方案: 静态无障碍文本');
  } catch (error) {
    console.error('降级方案失败:', error.message);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| UI_CONTEXT_NOT_INIT | UIContext未初始化 | 确保在build方法中使用this.getUIContext()获取UIContext |
| PROMPT_ACTION_NOT_AVAILABLE | PromptAction不可用 | 检查UIContext是否正确,使用getPromptAction()方法获取 |
| STATE_VARIABLE_UNDEFINED | 状态变量未定义 | 使用@State装饰器定义状态变量 |
| ACCESSIBILITY_TEXT_EMPTY | 无障碍文本为空 | 提供明确的状态对应文本内容 |
| INVALID_STATE_TYPE | 状态变量类型错误 | 确保状态变量为boolean或枚举类型 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ArkUI": "最新版本"
  }
}
```

### 环境要求
- HarmonyOS API version 10及以上
- DevEco Studio 3.0及以上

### 常见编译问题

**问题1: UIContext未找到**
```
Property 'getUIContext' does not exist on type 'XXXComponent'
```
**解决方法**: 确保组件使用@Entry和@Component装饰器,在组件内部调用this.getUIContext()

**问题2: accessibilityText类型错误**
```
Type 'string' is not assignable to type 'ResourceStr'
```
**解决方法**: 确保传入字符串类型,或使用$r()引用资源

**问题3: PromptAction导入失败**
```
Cannot find module '@kit.ArkUI' or its corresponding type declarations
```
**解决方法**: 检查项目配置,确保已导入@kit.ArkUI模块

## 常见问题与解决方法

### Q1: 状态变化后无障碍文本不更新
**原因**: 状态变量未使用@State装饰器或未正确绑定
**解决方法**:
- 使用@State装饰器标记状态变量
- 确保accessibilityText使用三元表达式动态绑定
- 检查状态变量是否在onClick事件中正确更新

### Q2: 屏幕朗读播报内容不正确
**原因**: 无障碍文本内容设置不当
**解决方法**:
- 确保状态文本简洁明确(如"播放"而非"正在播放状态")
- 避免使用模糊文本(如"状态已变化")
- 提供状态对应的准确描述

### Q3: Toast提示和无障碍文本冲突
**原因**: Toast和accessibilityText同时使用导致播报混乱
**解决方法**:
- Toast用于视觉提示,accessibilityText用于无障碍播报
- 确保Toast文本和无障碍文本内容一致
- 建议Toast文本简短,无障碍文本更详细

### Q4: 状态变量过多导致播报复杂
**原因**: 使用了超过3个状态变量
**解决方法**:
- 简化状态管理,使用boolean类型
- 避免使用多个嵌套的状态判断
- 使用枚举类型管理多状态场景

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "componentType": "Image/Button等",
  "stateVariable": "isPlaying(boolean)",
  "accessibilityTextUsed": ["播放", "暂停"],
  "apiUsed": [
    "accessibilityText",
    "UIContext.getPromptAction",
    "PromptAction.showToast"
  ]
}
```

## 参考文档

- [控件状态变化场景开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scenario-component-status-change)
- [无障碍属性API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-accessibility)
- [UIContext API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-uicontext-uicontext)
- [PromptAction API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-uicontext-promptaction)

## 完整示例代码

- [ArkTS示例代码](assets/status_change_example.ets)
- [配置文件示例](assets/config.json)

## 测试用例

### 正向测试用例
- [播放暂停状态切换测试](tests/test_play_pause_switch.ets): 测试播放暂停按钮状态切换的无障碍文本更新
- [开关状态切换测试](tests/test_switch_status.ets): 测试开关类控件的状态切换播报

### 边界测试用例
- [多状态切换测试](tests/test_multiple_states.ets): 测试超过3个状态的场景处理
- [快速状态切换测试](tests/test_fast_switch.ets): 测试快速状态切换时的文本更新

### 异常测试用例
- [空文本测试](tests/test_empty_text.ets): 测试无障碍文本为空时的降级处理
- [状态变量错误测试](tests/test_invalid_state.ets): 测试状态变量类型错误时的处理