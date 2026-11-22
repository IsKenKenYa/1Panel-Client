---
name: hmos-accessibility-kit-media-grouping
description: 将插画、视频、动画等媒体元素与描述文本组合为一个焦点进行屏幕朗读，支持图片+文本、列表项等多元素组合，适用于提升无障碍体验场景
---

# 插画/视频/动画的播报场景技能

## 功能描述

本技能用于实现媒体内容（插画、视频、动画）的无障碍播报功能。通过`accessibilityGroup(true)`属性将媒体元素与其描述文本组合为一个整体，使屏幕朗读服务能够以单个焦点播报完整信息，提升视障用户的使用体验。

核心能力包括：
- 图片与功能描述的组合播报
- 列表/网格项的多元素组合播报  
- 自动拼接子组件文本信息
- 支持自定义无障碍文本覆盖

## 使用场景

### 触发词
- "插画播报"
- "视频播报"
- "动画播报"
- "媒体内容朗读"
- "图片无障碍"
- "组合焦点朗读"
- "accessibilityGroup"

### 能做
- 将图片、视频、动画等媒体组件与描述文本组合为单个焦点
- 为列表项的多元素内容（标题、副标题、时间、图标等）提供组合播报
- 自动拼接子组件的通用文本属性作为合并文本
- 通过无障碍文本属性自定义播报内容
- 提升视障用户对媒体内容的理解能力

### 绝不做
- 不处理纯文本组件的无障碍设置
- 不替代`accessibilityText`单独设置的场景
- 不处理超出ArkUI组件范围的UI元素
- 不修改组件的视觉呈现效果

### 补充
- 使用`accessibilityGroup(true)`后，无障碍服务不再单独关注子组件
- 子组件`accessibilityLevel`设为"yes"时可突破分组约束
- 适用于API version 10及以上版本
- 卡片支持：API version 12+
- 元服务支持：API version 11+

## 调用规范和规则

### 输入约束
- 组合元素数量：建议1-5个子组件
- 文本长度：无障碍文本建议不超过50字符
- 图片格式：支持所有ArkUI支持的图片格式
- 组件类型：仅支持ArkUI基础组件的组合

### 执行约束
- 设置位置：必须在父容器组件上设置`accessibilityGroup(true)`
- 子组件要求：子组件应包含文本属性或设置无障碍文本
- 调用顺序：先设置组件布局属性，再设置无障碍属性
- 测试验证：必须通过屏幕朗读测试验证播报效果

### 内容约束
- 禁止生成：不包含文本的纯图片组合（需设置`accessibilityText`）
- 禁止使用高危函数：无
- 禁止操作：不修改组件的可见性和交互属性

### 降级约束
- 文本缺失：手动设置`accessibilityText`替代拼接
- 子组件过多：拆分为多个分组或简化布局
- API版本不支持：提示用户升级API版本

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认目标组件为容器组件（Column、Row、Flex等）
2. 确认子组件包含文本信息或图片资源
3. 确认API版本>=10

**参数准备**：
```typescript
// 组合元素结构定义
interface MediaGroupConfig {
  imageResource: Resource;      // 图片资源
  descriptionText: string;       // 描述文本
  fontSize?: number;             // 文本字号
  fontColor?: ResourceColor;     // 文本颜色
}
```

### 步骤2：设置无障碍分组

**示例代码1 - 图片+文本组合**：
```typescript
@Entry
@Component
struct ImageTextGroup {
  private imageResource: Resource = $r("app.media.example_image");
  private description: string = "示例图片描述";
  
  build() {
    Column() {
      Image(this.imageResource)
        .width(200)
        .height(180)
        .objectFit(ImageFit.Contain)
      
      Text(this.description)
        .fontSize(22)
        .fontColor(Color.Black)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
    }
    .accessibilityGroup(true) // 关键设置：将图片和文本组合为一个焦点
    .accessibilityLevel("yes") // 确保可被屏幕朗读识别
    .width('100%')
    .padding(10)
  }
}
```

**示例代码2 - 列表项组合**：
```typescript
@Component
struct ListItemGroup {
  @Prop title: string = "视频标题";
  @Prop subtitle: string = "视频描述";
  @Prop duration: string = "10:30";
  
  build() {
    Flex({
      direction: FlexDirection.Row,
      alignItems: ItemAlign.Center,
      justifyContent: FlexAlign.SpaceBetween,
    }) {
      Column() {
        Text(this.title)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .padding({ left: 20 })
        
        Text(this.subtitle)
          .fontSize(14)
          .fontColor(Color.Gray)
          .padding({ left: 20 })
      }
      
      Column() {
        Text(this.duration)
          .fontSize(20)
          .padding({ left: 10, right: 10 })
      }
      
      Column() {
        Image($r("sys.media.ohos_ic_public_arrow_right"))
          .width(28)
          .height(28)
          .fillColor(Color.Gray)
      }
    }
    .accessibilityGroup(true) // 组合标题、描述、时长、图标为一个焦点
    .width('90%')
    .height(75)
    .borderRadius(8)
    .backgroundColor(Color.White)
  }
}
```

### 步骤3：设置自定义无障碍文本（可选）

当组合元素不包含文本或需要自定义播报内容时：

```typescript
Column() {
  Image($r("app.media.gesture_icon"))
    .width(100)
    .height(100)
}
.accessibilityGroup(true)
.accessibilityText("手势图标：向左然后向上滑动") // 自定义播报文本
.accessibilityDescription("该图标表示执行向左然后向上滑动操作")
```

### 步骤4：处理特殊场景

**子组件突破分组约束**：
```typescript
Column() {
  Image($r("app.media.main_image"))
    .width(200)
  
  Text("主要图片描述")
  
  Button("详情")
    .accessibilityLevel("yes") // 该按钮可独立聚焦，不受分组约束
}
.accessibilityGroup(true)
```

**优先使用无障碍文本朗读（API version 14+）**：
```typescript
Column() {
  Text("显示文本")
    .accessibilityText("播报文本") // 无障碍文本
  
  Text("另一个文本")
}
.accessibilityGroup(true, { accessibilityPreferred: true }) // 优先朗读无障碍文本
```

### 步骤5：错误处理

```typescript
// 校验组件是否支持无障碍分组
function checkAccessibilitySupport(component: CommonAttribute): boolean {
  try {
    // 检查API版本
    if (!isApiVersionSupported(10)) {
      console.warn('accessibilityGroup需要API version 10+');
      return false;
    }
    
    // 检查组件类型
    if (!isContainerComponent(component)) {
      console.error('仅容器组件支持accessibilityGroup');
      return false;
    }
    
    return true;
  } catch (error) {
    console.error('无障碍分组校验失败:', error.message);
    return false;
  }
}
```

## 错误码说明

| 错误场景 | 说明 | 解决方法 |
|---------|------|---------|
| API版本不兼容 | 当前API版本低于10 | 升级项目API版本至10或以上 |
| 组件类型错误 | 非容器组件设置分组属性 | 仅在Column、Row、Flex等容器组件上设置 |
| 文本缺失 | 组合元素不包含任何文本信息 | 添加文本子组件或设置`accessibilityText` |
| 属性冲突 | 同时设置多选和单选状态 | 仅使用一种选择模式（accessibilityChecked或accessibilitySelected） |
| 子组件过多 | 组合元素超过合理数量 | 简化布局或拆分为多个分组 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@ohos/hypium": "1.0.6"
  }
}
```

### 环境要求
- DevEco Studio: 3.1+
- HarmonyOS SDK: API 10+
- ArkUI框架: 已包含在SDK中

### 常见编译问题

**问题1：accessibilityGroup属性不存在**
```
ERROR: Property 'accessibilityGroup' does not exist on type 'CommonAttribute'
```
**解决方法**：检查项目API版本配置，确保`compileSdkVersion`>=10

**问题2：accessibilityPreferred参数错误**
```
ERROR: Expected 1 arguments, but got 2
```
**解决方法**：`accessibilityGroup(isGroup, options)`接口需要API version 14+，检查版本兼容性

**问题3：Resource类型错误**
```
ERROR: Type 'Resource' is not assignable to type 'string'
```
**解决方法**：使用`accessibilityText12+`接口支持Resource类型，需API version 12+

## 常见问题与解决方法

### Q1：组合后播报内容不完整
**原因**：子组件缺少文本属性或未设置无障碍文本
**解决方法**：
- 确认所有需要播报的子组件包含文本内容
- 为图片等非文本组件设置`accessibilityText`
- 检查子组件的`accessibilityLevel`设置

### Q2：部分子组件无法独立聚焦
**原因**：父组件设置了`accessibilityGroup(true)`
**解决方法**：
- 为需要独立聚焦的子组件设置`accessibilityLevel("yes")`
- 评估是否需要拆分组合结构

### Q3：无障碍文本与显示文本冲突
**原因**：组件同时设置了文本属性和无障碍文本
**解决方法**：
- 了解播报优先级：无障碍文本优先于显示文本
- 如需播报显示文本，不设置`accessibilityText`即可

### Q4：列表项播报效果不佳
**原因**：组合元素过多或文本过长
**解决方法**：
- 简化组合元素，保留核心信息（标题+关键描述）
- 使用`accessibilityText`自定义精简播报内容
- 添加`accessibilityDescription`提供补充说明

### Q5：卡片或元服务中使用报错
**原因**：API版本不满足卡片/元服务要求
**解决方法**：
- 卡片支持：需要API version 12+
- 元服务支持：需要API version 11+
- 检查项目配置文件中的API版本声明

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "implementationType": "accessibilityGroup",
  "groupedComponents": ["Image", "Text"],
  "accessibilityText": "自动拼接或自定义文本",
  "apiUsed": [
    "accessibilityGroup",
    "accessibilityLevel",
    "accessibilityText"
  ],
  "testRecommendation": "使用屏幕朗读功能验证播报效果"
}
```

## 参考文档

- [开发指南：插画/视频/动画的播报场景](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scenario-media-reading)
- [API参考：无障碍属性](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-accessibility)

## 完整示例代码

- [图片+文本组合示例](assets/example-image-text-group.ets)
- [列表项组合示例](assets/example-list-item-group.ets)
- [自定义无障碍文本示例](assets/example-custom-accessibility-text.ets)

## 测试用例

### 正向测试用例
- [图片与文本组合播报](tests/test_positive.py)：验证图片+文本组合后播报完整性
- [列表项多元素组合](tests/test_positive.py)：验证标题、描述、时长组合播报

### 边界测试用例
- [仅图片组合](tests/test_boundary.py)：测试无文本组件的组合处理
- [多子组件组合](tests/test_boundary.py)：测试超过5个子组件的播报效果
- [长文本播报](tests/test_boundary.py)：测试超过50字符的播报处理

### 异常测试用例
- [API版本不兼容](tests/test_exception.py)：测试低于API 10版本的错误处理
- [非容器组件设置](tests/test_exception.py)：测试在非容器组件上设置的错误提示
- [属性冲突处理](tests/test_exception.py)：测试同时设置多选和单选状态的冲突检测