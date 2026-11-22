---
name: hmos-form-kit-widget-router-event
description: 实现动态卡片跳转到应用指定UIAbility页面，支持postCardAction接口router能力，仅支持onClick事件触发，适用于多UIAbility应用一键直达场景
---

# 卡片跳转到应用页面（router事件）技能

## 功能描述

本技能实现动态卡片使用postCardAction接口的router能力，从卡片跳转到应用提供方指定的UIAbility页面。通过在卡片上设置不同的跳转按钮，可以快速拉起应用的不同页面，实现一键直达的效果，提升用户体验。

**核心功能**：
- 在动态卡片中使用postCardAction接口发送router事件
- 在UIAbility中接收router事件并获取传递的参数
- 根据参数内容拉起不同的应用页面

**适用范围**：
- 仅支持动态卡片（ArkTS卡片）
- 仅支持router事件类型
- 需要在onClick事件中触发
- 支持API version 9及以上版本

**技术特点**：
- 实现卡片与应用间的交互
- 支持参数传递和数据共享
- 支持多UIAbility场景路由

## 使用场景

### 触发词
- "卡片跳转应用"
- "动态卡片router事件"
- "postCardAction router"
- "卡片一键直达"
- "卡片跳转UIAbility"

### 能做
- 实现从动态卡片跳转到指定的UIAbility页面
- 在卡片按钮点击时发送router事件
- 在UIAbility中接收和处理router事件参数
- 根据参数动态选择加载不同的页面
- 支持传递自定义参数到目标页面

### 绝不做
- 不支持静态卡片（静态卡片请使用FormLink组件）
- 不支持在非onClick事件中触发router事件
- 不支持message和call事件类型（请参考对应技能）
- 不直接修改UIAbility的生命周期逻辑
- 不处理卡片数据更新相关操作

### 补充
- 对于静态卡片，请使用FormLink组件实现类似功能
- UIAbility需要在onCreate和onNewWant中处理参数接收
- 需要在main_pages.json中配置跳转页面的路由
- 如果UIAbility已在后台运行，会触发onNewWant回调

## 调用规范和规则

### 输入约束
- 卡片文件路径：必须在entry模块中创建
- UIAbility名称：必须是有效的UIAbility组件名
- 参数格式：必须使用JSON格式的键值对
- 页面路由：必须在main_pages.json中正确配置

### 执行约束
- 触发方式：仅在onClick事件中调用postCardAction
- 参数传递：params必须是可JSON序列化的对象
- 页面加载：使用windowStage.loadContent加载目标页面
- 最大参数长度：建议不超过1000字符

### 内容约束
- 禁止使用eval、Function等动态执行函数
- 禁止在params中传递敏感信息
- 禁止修改系统级UIAbility配置
- 禁止使用未在main_pages.json中配置的页面路径

### 降级约束
- UIAbility不存在：提示用户检查配置
- 页面加载失败：回退到默认首页（pages/Index）
- 参数解析失败：使用默认参数值
- 网络异常：不处理网络相关问题（本功能不依赖网络）

## 调用流程和步骤

### 步骤1：创建动态卡片

**前置校验**：
1. 确认项目已创建entry模块
2. 确认已配置卡片元数据（form_config.json）
3. 确认已创建卡片提供方FormExtensionAbility

**创建卡片文件**：
```
在entry模块中创建ArkTS卡片：
位置：src/main/ets/widgeteventrouter/pages/WidgetEventRouterCard.ets
```

### 步骤2：构建卡片页面布局

**示例代码**：
```typescript
// src/main/ets/widgeteventrouter/pages/WidgetEventRouterCard.ets
@Entry
@Component
struct WidgetEventRouterCard {
  build() {
    Column() {
      Text($r('app.string.JumpLabel'))
        .fontColor('#FFFFFF')
        .opacity(0.9)
        .fontSize(14)
        .margin({ top: '8%', left: '10%' })
      
      Row() {
        Column() {
          Button() {
            Text($r('app.string.ButtonA_label'))
              .fontColor('#45A6F4')
              .fontSize(12)
          }
          .width(120)
          .height(32)
          .margin({ top: '20%' })
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .onClick(() => {
            postCardAction(this, {
              action: 'router',
              abilityName: 'EntryAbility',
              params: { targetPage: 'funA' }
            });
          })
          
          Button() {
            Text($r('app.string.ButtonB_label'))
              .fontColor('#45A6F4')
              .fontSize(12)
          }
          .width(120)
          .height(32)
          .margin({ top: '8%', bottom: '15vp' })
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .onClick(() => {
            postCardAction(this, {
              action: 'router',
              abilityName: 'EntryAbility',
              params: { targetPage: 'funB' }
            });
          })
        }
      }
      .width('100%')
      .height('80%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundImage($r('app.media.CardEvent'))
    .backgroundImageSize(ImageSize.Cover)
  }
}
```

**关键点说明**：
- postCardAction的第一个参数必须是this（当前组件实例）
- action必须设置为'router'
- abilityName必须指定目标UIAbility名称
- params用于传递自定义参数，必须是Object类型

### 步骤3：处理router事件

**在UIAbility中接收参数**：
```typescript
// src/main/ets/entryability/EntryAbility.ts
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'EntryAbility';
const DOMAIN_NUMBER: number = 0xFF00;

export default class EntryAbility extends UIAbility {
  private selectPage: string = 'funA';
  private currentWindowStage: window.WindowStage | null = null;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN_NUMBER, TAG, `Ability onCreate, ${JSON.stringify(want)}`);
    
    if (want?.parameters?.params) {
      let params: Record<string, Object> = JSON.parse(want.parameters.params as string);
      this.selectPage = params.targetPage as string;
      hilog.info(DOMAIN_NUMBER, TAG, `onCreate selectPage: ${this.selectPage}`);
    }
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onNewWant Want: ${JSON.stringify(want)}`);
    
    if (want?.parameters?.params) {
      let params: Record<string, Object> = JSON.parse(want.parameters.params as string);
      this.selectPage = params.targetPage as string;
      hilog.info(DOMAIN_NUMBER, TAG, `onNewWant selectPage: ${this.selectPage}`);
    }
    
    if (this.currentWindowStage !== null) {
      this.onWindowStageCreate(this.currentWindowStage);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    let targetPage: string;
    
    switch (this.selectPage) {
      case 'funA':
        targetPage = 'funpages/FunA';
        break;
      case 'funB':
        targetPage = 'funpages/FunB';
        break;
      default:
        targetPage = 'pages/Index';
    }
    
    if (this.currentWindowStage === null) {
      this.currentWindowStage = windowStage;
    }
    
    windowStage.loadContent(targetPage, (err, data) => {
      if (err.code) {
        hilog.error(DOMAIN_NUMBER, TAG, 'Failed to load the content. Cause: %{public}s', 
          JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded in loading the content. Data: %{public}s', 
        JSON.stringify(data) ?? '');
    });
  }
}
```

**参数接收逻辑**：
- onCreate：首次启动UIAbility时接收参数
- onNewWant：UIAbility已在后台时接收参数
- want.parameters.params：对应postCardAction中的params内容
- 需要JSON.parse解析params字符串

### 步骤4：创建跳转页面

**创建FunA页面**：
```typescript
// src/main/ets/funpages/FunA.ets
@Entry
@Component
struct FunA {
  build() {
    Column() {
      Row() {
        Text(($r('app.string.ButtonA_label')))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Start)
          .margin({ top: 12, bottom: 11, right: 24, left: 24 })
      }
      .width('100%')
      .height(56)
      .justifyContent(FlexAlign.Start)
      
      Image($r('app.media.pic_empty'))
        .width(120)
        .height(120)
        .margin({ top: 224 })
      
      Text($r('app.string.NoContentAvailable'))
        .fontSize(14)
        .fontColor($r('app.color.text_color'))
        .opacity(0.4)
        .margin({ top: 8, bottom: 317, right: 152, left: 152 })
    }
    .width('100%')
    .height('100%')
  }
}
```

**创建FunB页面**：
```typescript
// src/main/ets/funpages/FunB.ets
@Entry
@Component
struct FunB {
  build() {
    Column() {
      Row() {
        Text(($r('app.string.ButtonB_label')))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Start)
          .margin({ top: 12, bottom: 11, right: 24, left: 24 })
      }
      .width('100%')
      .height(56)
      .justifyContent(FlexAlign.Start)
      
      Image($r('app.media.pic_empty'))
        .width(120)
        .height(120)
        .margin({ top: 224 })
      
      Text($r('app.string.NoContentAvailable'))
        .fontSize(14)
        .fontColor($r('app.color.text_color'))
        .opacity(0.4)
        .margin({ top: 8, bottom: 317, right: 152, left: 152 })
    }
    .width('100%')
    .height('100%')
  }
}
```

### 步骤5：配置页面路由

**配置main_pages.json**：
```json
// src/main/resources/base/profile/main_pages.json
{
  "src": [
    "pages/Index",
    "funpages/FunA",
    "funpages/FunB"
  ]
}
```

**配置要点**：
- 必须在main_pages.json中声明所有跳转页面
- 路径不需要添加.ets后缀
- 页面路径必须与windowStage.loadContent中的一致

### 步骤6：配置资源文件

**字符串资源配置**：
```json
// src/main/resources/zh_CN/element/string.json
{
  "string": [
    {
      "name": "ButtonA_label",
      "value": "FunA页面"
    },
    {
      "name": "ButtonB_label",
      "value": "FunB页面"
    },
    {
      "name": "JumpLabel",
      "value": "router事件跳转"
    },
    {
      "name": "NoContentAvailable",
      "value": "暂无内容"
    }
  ]
}
```

### 步骤7：错误处理

**参数解析异常处理**：
```typescript
try {
  if (want?.parameters?.params) {
    let params: Record<string, Object> = JSON.parse(want.parameters.params as string);
    this.selectPage = params.targetPage as string;
  }
} catch (error) {
  hilog.error(DOMAIN_NUMBER, TAG, 'Failed to parse params: %{public}s', 
    JSON.stringify(error) ?? '');
  this.selectPage = 'pages/Index';
}
```

**页面加载失败处理**：
```typescript
windowStage.loadContent(targetPage, (err, data) => {
  if (err.code) {
    hilog.error(DOMAIN_NUMBER, TAG, 'Failed to load the content. Cause: %{public}s', 
      JSON.stringify(err) ?? '');
    windowStage.loadContent('pages/Index', (fallbackErr, fallbackData) => {
      if (fallbackErr.code) {
        hilog.error(DOMAIN_NUMBER, TAG, 'Failed to load fallback page');
      }
    });
    return;
  }
  hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded in loading the content');
});
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| PAGE_NOT_FOUND | 页面路径未在main_pages.json中配置 | 在main_pages.json中添加页面路径 |
| ABILITY_NOT_FOUND | UIAbility名称不存在或配置错误 | 检查abilityName参数是否正确 |
| PARAM_PARSE_FAILED | params参数JSON解析失败 | 检查params格式是否正确，确保可序列化 |
| WINDOW_LOAD_FAILED | 页面加载失败 | 检查页面文件是否存在，路径是否正确 |
| PERMISSION_DENIED | 缺少必要权限 | 检查应用权限配置（通常不需要额外权限） |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AbilityKit": "系统内置",
    "@kit.ArkUI": "系统内置",
    "@kit.PerformanceAnalysisKit": "系统内置"
  }
}
```

### 环境要求
- HarmonyOS SDK：API version 9及以上
- DevEco Studio：3.1及以上版本
- Node.js：建议12.x及以上（用于编译）

### 常见编译问题

**问题1：postCardAction未定义**
```
Error: 'postCardAction' is not defined
```
**解决方法**：postCardAction是全局函数，无需导入，直接使用即可

**问题2：页面路由配置错误**
```
Error: Page path not found in main_pages.json
```
**解决方法**：在main_pages.json中添加页面路径，格式如："funpages/FunA"

**问题3：参数类型错误**
```
Error: Type 'string' is not assignable to type 'Object'
```
**解决方法**：params必须是Object类型，使用JSON.parse解析字符串参数

**问题4：UIAbility未正确配置**
```
Error: Ability 'EntryAbility' not found
```
**解决方法**：检查module.json5中abilities配置，确保UIAbility名称正确

## 常见问题与解决方法

### Q1：点击卡片按钮没有跳转
**原因**：
- postCardAction未在onClick事件中调用
- abilityName配置错误
- UIAbility未正确启动

**解决方法**：
- 确认postCardAction在onClick回调中调用
- 检查abilityName是否与module.json5配置一致
- 查看hilog日志确认事件是否触发

### Q2：UIAbility接收不到参数
**原因**：
- want.parameters.params格式错误
- JSON.parse解析失败
- onCreate和onNewWant未处理参数

**解决方法**：
- 检查postCardAction的params格式
- 确认UIAbility中正确解析params
- 在onCreate和onNewWant中添加参数处理逻辑

### Q3：页面加载失败
**原因**：
- 页面路径未在main_pages.json配置
- 页面文件不存在或路径错误
- windowStage.loadContent调用时机错误

**解决方法**：
- 在main_pages.json中添加页面路径
- 确认页面文件位置和路径正确
- 在onWindowStageCreate中正确调用loadContent

### Q4：静态卡片如何实现跳转
**原因**：静态卡片不支持postCardAction

**解决方法**：使用FormLink组件实现静态卡片的router事件，参考FormLink文档

### Q5：如何传递复杂参数
**原因**：params只支持简单JSON对象

**解决方法**：
- 使用JSON格式传递参数
- 复杂对象需要序列化为JSON字符串
- 避免传递过大的数据（建议<1000字符）

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "cardCreated": "WidgetEventRouterCard.ets",
  "pagesCreated": ["FunA.ets", "FunB.ets"],
  "routesConfigured": ["pages/Index", "funpages/FunA", "funpages/FunB"],
  "apiUsed": [
    "postCardAction",
    "UIAbility.onCreate",
    "UIAbility.onNewWant",
    "windowStage.loadContent"
  ],
  "featureImplemented": "动态卡片跳转到应用UIAbility页面"
}
```

## 参考文档

- [卡片跳转到应用页面开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-event-router)
- [postCardAction API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-postcardaction)
- [FormLink组件参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-container-formlink)

## 完整示例代码

- [完整示例代码](assets/widget_router_event_example.ets)：包含卡片、UIAbility和页面的完整实现
- [配置文件示例](assets/main_pages.json)：页面路由配置
- [资源文件示例](assets/string.json)：字符串资源配置

## 测试用例

### 正向测试用例
- [test_single_button_click](tests/test_positive.py)：单个按钮点击跳转测试
- [test_multi_button_click](tests/test_positive.py)：多个按钮分别跳转不同页面测试
- [test_param_passing](tests/test_positive.py)：参数传递和接收测试

### 边界测试用例
- [test_empty_params](tests/test_boundary.py)：空参数传递测试
- [test_large_params](tests/test_boundary.py)：大参数传递测试
- [test_special_chars](tests/test_boundary.py)：特殊字符参数测试

### 异常测试用例
- [test_invalid_ability](tests/test_exception.py)：无效UIAbility名称测试
- [test_page_not_configured](tests/test_exception.py)：页面未配置路由测试
- [test_json_parse_error](tests/test_exception.py)：JSON解析失败测试