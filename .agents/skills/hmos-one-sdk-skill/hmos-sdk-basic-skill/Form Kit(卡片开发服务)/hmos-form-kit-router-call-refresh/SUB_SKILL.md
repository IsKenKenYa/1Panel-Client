---
name: hmos-form-kit-router-call-refresh
description: 通过router或call事件实现ArkTS卡片内容刷新，支持前台跳转和后台运行两种模式，需要配置对应权限和UIAbility，适用于卡片交互和数据更新场景
---

# 通过router或call事件刷新卡片内容技能

## 功能描述

本技能实现ArkTS卡片通过router或call事件触发UIAbility并刷新卡片内容的功能。提供两种交互模式：
- **router事件**：点击卡片拉起UIAbility至前台，用户可见应用界面，适用于需要用户交互的场景
- **call事件**：点击卡片在后台拉起UIAbility，不显示应用界面，适用于后台数据更新场景

核心能力包括：
- 使用postCardAction接口触发router或call事件
- 在UIAbility中接收事件参数并处理
- 使用formProvider.updateForm接口刷新卡片内容
- 配置必要权限和UIAbility启动模式

## 使用场景

### 触发词
- "卡片刷新" - 通过事件刷新卡片内容
- "router刷新卡片" - 使用router事件刷新卡片
- "call刷新卡片" - 使用call事件后台刷新卡片
- "卡片交互" - 卡片点击事件处理
- "postCardAction" - 触发卡片事件
- "updateForm" - 更新卡片数据

### 能做
- 实现卡片点击触发UIAbility的router事件（前台跳转）
- 实现卡片点击触发UIAbility的call事件（后台运行）
- 在UIAbility中获取卡片formId和传递的参数
- 使用formProvider.updateForm更新卡片显示内容
- 处理onCreate和onNewWant生命周期中的router事件
- 处理callee监听的call事件
- 配置ohos.permission.KEEP_BACKGROUND_RUNNING权限

### 绝不做
- 不处理静态卡片的事件（静态卡片使用FormLink组件）
- 不处理message事件（message事件触发onFormEvent回调）
- 不支持多实例UIAbility的call事件（仅支持singleton模式）
- 不直接操作卡片UI（仅通过updateForm接口刷新）
- 不在卡片页面中处理业务逻辑（业务逻辑在UIAbility中处理）

### 补充
- router事件只能在点击事件中触发
- call事件需要UIAbility具备后台运行权限
- call事件仅支持launchType为singleton的UIAbility
- 从API version 9开始支持postCardAction接口
- 从API version 20开始，卡片刷新数据总大小不超过10MB，图片不超过20张

## 调用规范和规则

### 输入约束
- 卡片formId：必须为有效的字符串格式卡片标识
- abilityName：必须为当前应用下的UIAbility名称
- action参数：只能是"router"或"call"
- params参数：JSON格式的键值对，call类型必须包含method字段
- 刷新数据：formBindingData数据结构，API version 20+总大小不超过10MB

### 执行约束
- router事件：必须由用户点击触发，不能自动调用
- call事件：需要配置ohos.permission.KEEP_BACKGROUND_RUNNING权限
- UIAbility启动模式：call事件仅支持singleton模式
- 刷新时机：在UIAbility的onCreate/onNewWant或callee回调中调用updateForm
- 最大耗时：建议在3秒内完成卡片刷新，避免用户等待

### 内容约束
- 禁止在卡片页面中直接调用updateForm
- 禁止传递敏感信息（密码、token等）通过params
- 禁止在params中传递卡片内部状态变量
- 禁止使用多实例UIAbility处理call事件
- 禁止在call事件中执行耗时超过5秒的操作

### 降级约束
- 权限不足：提示用户授予后台运行权限，改用router事件
- UIAbility不存在：记录错误日志，不执行刷新
- formId无效：捕获16501001错误码，不执行操作
- 数据过大：分批更新或减少图片数量，提示数据限制
- IPC连接失败：捕获16500050错误码，延迟重试或提示网络问题

## 调用流程和步骤

### 步骤1：准备阶段 - 配置权限和UIAbility

**前置校验**：
1. 检查module.json5配置文件是否存在
2. 检查是否配置了必要的UIAbility
3. 检查call事件是否配置了ohos.permission.KEEP_BACKGROUND_RUNNING权限
4. 检查UIAbility的launchType是否为singleton（call事件）

**权限配置**：
```json
// src/main/module.json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.KEEP_BACKGROUND_RUNNING"
      }
    ],
    "abilities": [
      {
        "name": "WidgetEventRouterEntryAbility",
        "launchType": "standard"
      },
      {
        "name": "WidgetCalleeEntryAbility",
        "launchType": "singleton"
      }
    ]
  }
}
```

### 步骤2：卡片页面实现 - 触发router事件

**示例代码 - Router事件**：
```typescript
// entry/src/main/ets/widgetupdaterouter/pages/WidgetUpdateRouterCard.ets
let storageUpdateRouter = new LocalStorage();
@Entry(storageUpdateRouter)
@Component
struct WidgetUpdateRouterCard {
  @LocalStorageProp('routerDetail') routerDetail: ResourceStr = $r('app.string.init');
  
  build() {
    Column() {
      Column() {
        Text(this.routerDetail)
          .fontColor('#FFFFFF')
          .opacity(0.9)
          .fontSize(14)
          .margin({ top: '8%', left: '10%', right: '10%' })
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(2)
      }.width('100%').height('50%')
      .alignItems(HorizontalAlign.Start)
      
      Row() {
        Button() {
          Text($r('app.string.JumpLabel'))
            .fontColor('#45A6F4')
            .fontSize(12)
        }
        .width(120)
        .height(32)
        .margin({ top: '30%', bottom: '10%' })
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .onClick(() => {
          postCardAction(this, {
            action: 'router',
            abilityName: 'WidgetEventRouterEntryAbility',
            params: {
              routerDetail: 'RouterFromCard'
            }
          });
        })
      }.width('100%').height('40%')
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

### 步骤3：UIAbility处理Router事件

**示例代码 - Router事件处理**：
```typescript
// entry/src/main/ets/widgetevententryability/WidgetEventRouterEntryAbility.ts
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { formBindingData, formInfo, formProvider } from '@kit.FormKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'WidgetEventRouterEntryAbility';
const DOMAIN_NUMBER: number = 0xFF00;

export default class WidgetEventRouterEntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.handleFormRouterEvent(want, 'onCreate');
  }

  handleFormRouterEvent(want: Want, source: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `handleFormRouterEvent ${source}, Want: ${JSON.stringify(want)}`);
    
    if (want.parameters && want.parameters[formInfo.FormParam.IDENTITY_KEY] !== undefined) {
      let curFormId = want.parameters[formInfo.FormParam.IDENTITY_KEY].toString();
      let message: string = (JSON.parse(want.parameters?.params as string))?.routerDetail;
      
      hilog.info(DOMAIN_NUMBER, TAG, `UpdateForm formId: ${curFormId}, message: ${message}`);
      
      let formData: Record<string, string> = {
        'routerDetail': message + ' ' + source + ' UIAbility'
      };
      
      let formMsg = formBindingData.createFormBindingData(formData);
      
      formProvider.updateForm(curFormId, formMsg).then((data) => {
        hilog.info(DOMAIN_NUMBER, TAG, 'updateForm success.', JSON.stringify(data));
      }).catch((error: BusinessError) => {
        hilog.info(DOMAIN_NUMBER, TAG, 'updateForm failed.', JSON.stringify(error));
      });
    }
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN_NUMBER, TAG, 'onNewWant Want:', JSON.stringify(want));
    this.handleFormRouterEvent(want, 'onNewWant');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN_NUMBER, TAG, '%{public}s', 'Ability onWindowStageCreate');
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        hilog.error(DOMAIN_NUMBER, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
    });
  }
}
```

### 步骤4：卡片页面实现 - 触发Call事件

**示例代码 - Call事件**：
```typescript
// entry/src/main/ets/widgetupdatecall/pages/WidgetUpdateCallCard.ets
let storageUpdateCall = new LocalStorage();
@Entry(storageUpdateCall)
@Component
struct WidgetUpdateCallCard {
  @LocalStorageProp('formId') formId: string = '12400633174999288';
  @LocalStorageProp('calleeDetail') calleeDetail: ResourceStr = $r('app.string.init');
  
  build() {
    Column() {
      Column() {
        Text(this.calleeDetail)
          .fontColor('#FFFFFF')
          .opacity(0.9)
          .fontSize(14)
          .margin({ top: '8%', left: '10%' })
      }.width('100%').height('50%')
      .alignItems(HorizontalAlign.Start)
      
      Row() {
        Button() {
          Text($r('app.string.CalleeJumpLabel'))
            .fontColor('#45A6F4')
            .fontSize(12)
        }
        .width(120)
        .height(32)
        .margin({ top: '30%', bottom: '10%' })
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .onClick(() => {
          postCardAction(this, {
            action: 'call',
            abilityName: 'WidgetCalleeEntryAbility',
            params: {
              method: 'funA',
              formId: this.formId,
              calleeDetail: 'CallFrom'
            }
          });
        })
      }.width('100%').height('40%')
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

### 步骤5：UIAbility处理Call事件

**示例代码 - Call事件处理**：
```typescript
// entry/src/main/ets/widgetcalleeentryability/WidgetCalleeEntryAbility.ts
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { formBindingData, formProvider } from '@kit.FormKit';
import { rpc } from '@kit.IPCKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'WidgetCalleeEntryAbility';
const DOMAIN_NUMBER: number = 0xFF00;
const MSG_SEND_METHOD: string = 'funA';
const CONST_NUMBER_1: number = 1;

class MyParcelable implements rpc.Parcelable {
  num: number;
  str: string;
  
  constructor(num: number, str: string) {
    this.num = num;
    this.str = str;
  };
  
  marshalling(messageSequence: rpc.MessageSequence): boolean {
    messageSequence.writeInt(this.num);
    messageSequence.writeString(this.str);
    return true;
  };
  
  unmarshalling(messageSequence: rpc.MessageSequence): boolean {
    this.num = messageSequence.readInt();
    this.str = messageSequence.readString();
    return true;
  };
}

let funACall = (data: rpc.MessageSequence): MyParcelable => {
  let params: Record<string, string> = JSON.parse(data.readString());
  
  if (params.formId !== undefined) {
    let curFormId: string = params.formId;
    let message: string = params.calleeDetail;
    
    hilog.info(DOMAIN_NUMBER, TAG, `UpdateForm formId: ${curFormId}, message: ${message}`);
    
    let formData: Record<string, string> = {
      'calleeDetail': message
    };
    
    let formMsg: formBindingData.FormBindingData = formBindingData.createFormBindingData(formData);
    
    formProvider.updateForm(curFormId, formMsg).then((data) => {
      hilog.info(DOMAIN_NUMBER, TAG, `updateForm success. ${JSON.stringify(data)}`);
    }).catch((error: BusinessError) => {
      hilog.error(DOMAIN_NUMBER, TAG, `updateForm failed: ${JSON.stringify(error)}`);
    });
  }
  
  return new MyParcelable(CONST_NUMBER_1, 'aaa');
};

export default class WidgetCalleeEntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.callee.on(MSG_SEND_METHOD, funACall);
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `${MSG_SEND_METHOD} register failed with error ${JSON.stringify(error)}`);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN_NUMBER, TAG, '%{public}s', 'Ability onWindowStageCreate');
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        hilog.error(DOMAIN_NUMBER, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
    });
  }
}
```

### 步骤6：错误处理

**错误处理代码**：
```typescript
import { BusinessError } from '@kit.BasicServicesKit';

async function updateFormWithErrorHandling(formId: string, formData: Record<string, string>): Promise<void> {
  try {
    let formMsg = formBindingData.createFormBindingData(formData);
    await formProvider.updateForm(formId, formMsg);
    console.info('updateForm success');
  } catch (error) {
    const businessError = error as BusinessError;
    switch (businessError.code) {
      case 16501001:
        console.error('The ID of the form to be operated does not exist');
        break;
      case 16501003:
        console.error('The form cannot be operated by the current application');
        break;
      case 16500050:
        console.error('IPC connection error, retry later');
        break;
      case 16500060:
        console.error('Service connection error');
        break;
      case 401:
        console.error('Parameter error, check formId and formData');
        break;
      default:
        console.error(`Unknown error: ${businessError.code}, message: ${businessError.message}`);
    }
  }
}
```

### 步骤7：降级处理

**降级处理代码**：
```typescript
async function handleFormEventWithFallback(want: Want): Promise<void> {
  const formId = want.parameters?.[formInfo.FormParam.IDENTITY_KEY]?.toString();
  
  if (!formId) {
    console.warn('No formId found in want parameters');
    return;
  }
  
  try {
    const params = JSON.parse(want.parameters?.params as string);
    const formData = processData(params);
    await updateFormWithErrorHandling(formId, formData);
  } catch (error) {
    console.error('Failed to process form event, using fallback strategy');
    
    // 降级方案：使用默认数据更新卡片
    const fallbackData = {
      'status': 'Update Failed',
      'timestamp': new Date().toLocaleTimeString()
    };
    
    try {
      await formProvider.updateForm(formId, formBindingData.createFormBindingData(fallbackData));
    } catch (fallbackError) {
      console.error('Fallback update also failed:', (fallbackError as BusinessError).message);
    }
  }
}

function processData(params: Record<string, string>): Record<string, string> {
  // 数据处理逻辑
  return {
    'data': params.message || 'Default Message',
    'updateTime': new Date().toLocaleTimeString()
  };
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误：必填参数未指定、参数类型错误或参数校验失败 | 检查formId是否为字符串、formData是否为有效对象、params是否为JSON格式 |
| 16500050 | IPC连接错误 | 检查系统服务状态，延迟重试或重启应用 |
| 16500060 | 服务连接错误 | 检查FormKit服务是否正常运行，重启设备 |
| 16500100 | 获取配置信息失败 | 检查form_config.json配置文件是否正确 |
| 16501000 | 内部功能错误 | 检查代码逻辑，捕获异常并记录日志 |
| 16501001 | 卡片ID不存在 | 验证formId是否有效，检查卡片是否已删除 |
| 16501002 | 卡片数量超过最大限制 | 减少加桌卡片数量，清理不需要的卡片 |
| 16501003 | 当前应用无法操作该卡片 | 检查卡片是否属于当前应用，确认包名匹配 |
| 16501011 | 卡片不支持此操作 | 检查卡片类型是否支持该操作，确认API版本 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AbilityKit": "latest",
    "@kit.ArkUI": "latest",
    "@kit.FormKit": "latest",
    "@kit.BasicServicesKit": "latest",
    "@kit.IPCKit": "latest",
    "@kit.PerformanceAnalysisKit": "latest"
  }
}
```

### 环境要求
- DevEco Studio：3.1及以上版本
- HarmonyOS SDK：API version 9及以上
- ArkTS：支持Stage模型
- 设备：支持卡片功能的HarmonyOS设备

### 常见编译问题

**问题1：postCardAction未定义**
```
Error: 'postCardAction' is not defined
```
**解决方法**：postCardAction是全局接口，无需导入，直接调用即可。确保在卡片页面中使用。

**问题2：formProvider导入错误**
```
Error: Cannot find module '@kit.FormKit'
```
**解决方法**：检查项目SDK版本是否支持FormKit，更新SDK或检查导入路径。

**问题3：权限未配置**
```
Error: Permission denied for call event
```
**解决方法**：在module.json5中添加ohos.permission.KEEP_BACKGROUND_RUNNING权限。

**问题4：UIAbility启动模式错误**
```
Error: Call event only supports singleton UIAbility
```
**解决方法**：将处理call事件的UIAbility的launchType设置为"singleton"。

**问题5：卡片数据超过限制**
```
Error: Form data exceeds size limit
```
**解决方法**：API version 20+数据总大小不超过10MB，图片不超过20张。减少数据量或图片数量。

## 常见问题与解决方法

### Q1：router事件无法拉起UIAbility
**原因**：UIAbility未正确配置或abilityName错误
**解决方法**：
- 检查module.json5中UIAbility配置
- 确认abilityName与配置文件一致
- 检查UIAbility是否在当前应用中定义
- 确认bundleName和moduleName正确

### Q2：call事件不触发回调方法
**原因**：callee监听未注册或method参数错误
**解决方法**：
- 确保在onCreate中注册callee监听
- 检查method参数与注册的方法名一致
- 确认UIAbility的launchType为singleton
- 检查权限配置是否正确

### Q3：updateForm更新失败
**原因**：formId无效或数据格式错误
**解决方法**：
- 验证formId是否为有效字符串
- 检查formData是否符合FormBindingData格式
- 确认卡片未被删除或销毁
- 检查数据大小是否超过限制

### Q4：卡片点击无响应
**原因**：onClick事件未正确触发postCardAction
**解决方法**：
- 检查onClick回调是否正确实现
- 确认postCardAction参数完整（action、abilityName、params）
- 检查卡片页面组件是否正确绑定事件
- 验证卡片是否正常运行状态

### Q5：后台运行权限被拒绝
**原因**：系统权限管理限制
**解决方法**：
- 检查权限是否在module.json5中声明
- 确认应用类型是否支持后台运行
- 考虑使用router事件替代call事件
- 引导用户手动授予权限

### Q6：卡片刷新延迟过长
**原因**：UIAbility处理耗时操作
**解决方法**：
- 将耗时操作移至异步任务
- 减少数据处理逻辑复杂度
- 使用缓存数据快速刷新
- 避免在call事件中执行超过5秒的操作

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "eventType": "router | call",
  "formId": "卡片标识",
  "abilityName": "UIAbility名称",
  "updateResult": {
    "formData": "更新的数据内容",
    "updateTime": "刷新时间戳"
  },
  "apiUsed": [
    "postCardAction",
    "formBindingData.createFormBindingData",
    "formProvider.updateForm"
  ],
  "permissions": ["ohos.permission.KEEP_BACKGROUND_RUNNING"],
  "constraints": {
    "dataSize": "不超过10MB (API version 20+)",
    "imageCount": "不超过20张 (API version 20+)",
    "uiabilityMode": "singleton for call event"
  }
}
```

## 参考文档

- [通过router或call事件刷新卡片内容开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-event-uiability)
- [postCardAction API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-postcardaction)
- [formProvider.updateForm API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formprovider)
- [formBindingData API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formbindingdata)
- [UIAbility组件启动模式](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/uiability-launch-type)
- [应用权限列表](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/permissions-for-all)

## 完整示例代码

- [Router事件卡片示例](assets/widget_update_router_card.ets)
- [Router事件UIAbility示例](assets/widget_event_router_entry_ability.ts)
- [Call事件卡片示例](assets/widget_update_call_card.ets)
- [Call事件UIAbility示例](assets/widget_callee_entry_ability.ts)
- [权限配置示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [Router事件触发并刷新卡片](tests/test_router_event_positive.ts)：验证router事件正常触发UIAbility并更新卡片
- [Call事件触发并刷新卡片](tests/test_call_event_positive.ts)：验证call事件在后台正常处理并更新卡片
- [参数传递验证](tests/test_params_passing.ts)：验证params参数正确传递到UIAbility

### 边界测试用例
- [大数据刷新测试](tests/test_large_data.ts)：测试接近10MB数据限制的刷新
- [最大图片数量测试](tests/test_max_images.ts)：测试20张图片的刷新限制
- [多卡片并发刷新](tests/test_concurrent_forms.ts)：测试同时刷新多个卡片

### 异常测试用例
- [无效formId测试](tests/test_invalid_formid.ts)：测试formId不存在时的错误处理
- [权限缺失测试](tests/test_missing_permission.ts)：测试缺少后台运行权限时的处理
- [参数错误测试](tests/test_invalid_params.ts)：测试params格式错误时的处理
- [UIAbility不存在测试](tests/test_missing_ability.ts)：测试abilityName错误时的处理