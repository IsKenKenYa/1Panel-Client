---
name: hmos-form-kit-message-event
description: 实现ArkTS卡片通过message事件传递消息给应用的能力，支持卡片与应用间交互通信，适用于卡片点击事件触发应用逻辑处理场景
---

# 卡片传递消息给应用（message事件）技能

## 功能描述

本技能实现ArkTS卡片通过message事件向应用传递消息的能力。卡片页面中使用postCardAction接口触发message事件，拉起FormExtensionAbility，通过onFormEvent回调接收消息并刷新卡片内容。适用于卡片点击控件后触发应用逻辑处理、卡片数据动态更新等场景。

**核心流程**：
1. 卡片页面注册onClick事件，调用postCardAction触发message事件
2. FormExtensionAbility接收onFormEvent回调，获取卡片ID和消息内容
3. 在onFormEvent中调用formProvider.updateForm刷新卡片数据

**关键特性**：
- 仅支持ArkTS动态卡片，静态卡片需使用FormLink组件
- 需在卡片页面使用LocalStorageProp装饰器绑定数据
- FormExtensionAbility创建后10秒内无操作会被清理
- 支持自定义消息参数传递

## 使用场景

### 触发词
- "卡片传递消息给应用"
- "卡片点击事件通信"
- "postCardAction message事件"
- "FormExtensionAbility onFormEvent"
- "卡片刷新应用数据"

### 能做
- 实现卡片点击按钮触发应用逻辑处理
- 通过message事件传递自定义参数给应用
- 在FormExtensionAbility中接收卡片消息并刷新卡片内容
- 使用LocalStorageProp实现卡片数据动态绑定
- 处理卡片与应用间的双向交互通信

### 绝不做
- 不支持静态卡片（静态卡片需使用FormLink）
- 不处理router和call类型事件（本技能仅专注message事件）
- 不直接在卡片页面执行复杂业务逻辑
- 不在FormExtensionAbility中引用音频、相机、媒体等不支持模块
- 不超过FormExtensionAbility生命周期限制（10秒无操作清理）

### 补充
- 本技能仅适用于Stage模型
- API version 9开始支持，元服务从API version 11支持
- FormExtensionAbility不支持引用@ohos.multimedia.audio等模块
- 卡片刷新数据从API version 20起支持共享内存更新，最大10MB、20张图片

## 调用规范和规则

### 输入约束
- 消息参数：使用JSON格式键值对，支持字符串类型参数
- 卡片组件实例：必须传入this作为component参数
- action类型：必须设置为'message'
- 数据绑定：必须使用LocalStorageProp装饰器绑定卡片显示数据

### 执行约束
- FormExtensionAbility生命周期：创建后10秒内无操作将被清理
- 更新卡片数据：必须在onFormEvent回调中调用formProvider.updateForm
- 数据格式：formBindingData.createFormBindingData参数需与卡片页面LocalStorageProp字段对应
- 图片限制：API version 19及之前版本最多5张图片，每张最大2MB；API version 20起最多20张图片，总大小最大10MB

### 内容约束
- 禁止在FormExtensionAbility中引用：@ohos.ability.particleAbility、@ohos.multimedia.audio、@ohos.multimedia.camera、@ohos.multimedia.media、@ohos.resourceschedule.backgroundTaskManager
- 禁止使用高危函数：eval、exec等动态执行代码
- 禁止硬编码敏感信息：API密钥、用户密码等
- 禁止跳过错误处理：必须捕获BusinessError并记录日志

### 降级约束
- FormExtensionAbility清理：如生命周期超时，应用需重新拉起FormExtensionAbility
- 更新失败：捕获错误码，根据错误类型提供友好提示或重试机制
- 消息传递失败：记录日志并提示用户重新操作

## 调用流程和步骤

### 步骤1：准备卡片页面（ArkTS卡片）

**前置校验**：
1. 确认使用ArkTS动态卡片（非静态卡片）
2. 确认已配置form_config.json卡片配置文件
3. 确认卡片页面使用LocalStorageProp装饰器绑定数据

**参数准备**：
```typescript
// 创建LocalStorage实例
let storageUpdateByMsg = new LocalStorage();

// 使用LocalStorageProp装饰器绑定数据字段
@LocalStorageProp('title') title: ResourceStr = $r('app.string.default_title');
@LocalStorageProp('detail') detail: ResourceStr = $r('app.string.DescriptionDefault');
```

**示例代码**：
```typescript
// entry/src/main/ets/updatebymessage/pages/UpdateByMessageCard.ets
let storageUpdateByMsg = new LocalStorage();
@Entry(storageUpdateByMsg)
@Component
struct UpdateByMessageCard {
  @LocalStorageProp('title') title: ResourceStr = $r('app.string.default_title');
  @LocalStorageProp('detail') detail: ResourceStr = $r('app.string.DescriptionDefault');
  
  build() {
    Column() {
      Column() {
        Text(this.title)
          .fontColor('#FFFFFF')
          .opacity(0.9)
          .fontSize(14)
          .margin({ top: '8%', left: '10%' })
        Text(this.detail)
          .fontColor('#FFFFFF')
          .opacity(0.6)
          .fontSize(12)
          .margin({ top: '5%', left: '10%' })
      }.width('100%').height('50%')
      .alignItems(HorizontalAlign.Start)
      
      Row() {
        Button() {
          Text($r('app.string.update'))
            .fontColor('#45A6F4')
            .fontSize(12)
        }
        .width(120)
        .height(32)
        .margin({ top: '30%', bottom: '10%' })
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .onClick(() => {
          // 触发message事件，传递自定义参数
          postCardAction(this, {
            action: 'message',
            params: { msgTest: 'messageEvent' }
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

### 步骤2：实现FormExtensionAbility

**导入模块**：
```typescript
// entry/src/main/ets/entryformability/EntryFormAbility.ts
import { formBindingData, FormExtensionAbility, formProvider } from '@kit.FormKit';
import { Configuration, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
```

**实现onFormEvent回调**：
```typescript
const TAG: string = 'EntryFormAbility';
const DOMAIN_NUMBER: number = 0xFF00;

export default class EntryFormAbility extends FormExtensionAbility {
  onFormEvent(formId: string, message: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `FormAbility onFormEvent, formId = ${formId}, message: ${message}`);
    
    // 定义更新数据类，字段需与卡片页面LocalStorageProp对应
    class FormDataClass {
      title: string = 'Title Update.';
      detail: string = 'Description update success.';
    }
    
    // 创建更新数据
    let formData = new FormDataClass();
    let formInfo: formBindingData.FormBindingData = formBindingData.createFormBindingData(formData);
    
    // 调用updateForm刷新卡片
    formProvider.updateForm(formId, formInfo).then(() => {
      hilog.info(DOMAIN_NUMBER, TAG, 'FormAbility updateForm success.');
    }).catch((error: BusinessError) => {
      hilog.error(DOMAIN_NUMBER, TAG, `Operation updateForm failed. Cause: ${JSON.stringify(error)}`);
    });
  }
}
```

### 步骤3：错误处理

**错误码处理**：
```typescript
formProvider.updateForm(formId, formInfo).then(() => {
  hilog.info(DOMAIN_NUMBER, TAG, 'FormAbility updateForm success.');
}).catch((error: BusinessError) => {
  switch (error.code) {
    case 401:
      hilog.error(DOMAIN_NUMBER, TAG, 'Parameter error: mandatory parameters missing or incorrect types');
      break;
    case 16500050:
      hilog.error(DOMAIN_NUMBER, TAG, 'IPC connection error');
      break;
    case 16500060:
      hilog.error(DOMAIN_NUMBER, TAG, 'Service connection error');
      break;
    case 16501000:
      hilog.error(DOMAIN_NUMBER, TAG, 'Internal functional error');
      break;
    case 16501001:
      hilog.error(DOMAIN_NUMBER, TAG, 'Form ID does not exist');
      break;
    case 16501003:
      hilog.error(DOMAIN_NUMBER, TAG, 'Form cannot be operated by current application');
      break;
    default:
      hilog.error(DOMAIN_NUMBER, TAG, `Unknown error: code ${error.code}, message ${error.message}`);
  }
});
```

### 步骤4：降级处理

**生命周期超时处理**：
```typescript
// 在onFormEvent中快速处理消息，避免超时
onFormEvent(formId: string, message: string): void {
  try {
    // 立即处理关键逻辑
    let formData = this.processMessage(message);
    let formInfo = formBindingData.createFormBindingData(formData);
    
    // 快速调用updateForm
    formProvider.updateForm(formId, formInfo).then(() => {
      hilog.info(DOMAIN_NUMBER, TAG, 'updateForm success');
    }).catch((error: BusinessError) => {
      // 失败时记录日志，下次卡片刷新时重试
      hilog.error(DOMAIN_NUMBER, TAG, 'updateForm failed, will retry on next refresh');
    });
  } catch (error) {
    hilog.error(DOMAIN_NUMBER, TAG, 'onFormEvent processing failed');
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误：必填参数缺失、参数类型错误或参数验证失败 | 检查postCardAction和updateForm参数是否正确 |
| 16500050 | IPC连接错误 | 检查系统服务连接状态，重启应用或设备 |
| 16500060 | 服务连接错误 | 检查FormKit服务是否正常运行 |
| 16500100 | 无法获取配置信息 | 检查form_config.json配置文件是否正确 |
| 16501000 | 内部功能错误 | 检查代码逻辑，确保符合API规范 |
| 16501001 | 要操作的卡片ID不存在 | 确认formId是否正确，卡片是否已添加 |
| 16501002 | 卡片数量超过最大限制 | 减少卡片数量或清理已销毁的卡片 |
| 16501003 | 当前应用无法操作该卡片 | 确认卡片归属，只有卡片提供方才能更新 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.FormKit": "最新版本",
    "@kit.AbilityKit": "最新版本",
    "@kit.BasicServicesKit": "最新版本",
    "@kit.PerformanceAnalysisKit": "最新版本"
  }
}
```

### 环境要求
- HarmonyOS SDK: API version 9及以上
- 开发工具: DevEco Studio 3.1及以上
- 运行环境: Stage模型应用

### 常见编译问题

**问题1：postCardAction未定义**
```
Error: Cannot find name 'postCardAction'
```
**解决方法**：确保在卡片页面正确导入postCardAction，或使用全局接口无需导入

**问题2：LocalStorageProp类型错误**
```
Error: Type 'string' is not assignable to type 'ResourceStr'
```
**解决方法**：使用$r()引用资源文件或直接使用字符串类型

**问题3：FormExtensionAbility导入失败**
```
Error: Module '@kit.FormKit' has no exported member 'FormExtensionAbility'
```
**解决方法**：确认SDK版本为API version 9及以上，检查module.json5配置

## 常见问题与解决方法

### Q1：卡片点击后没有触发onFormEvent回调
**原因**：FormExtensionAbility可能已超时清理或未正确配置
**解决方法**：
- 检查module.json5中是否正确配置FormExtensionAbility
- 确认postCardAction参数正确：action设置为'message'
- 检查应用是否有权限处理卡片事件

### Q2：卡片刷新后数据没有更新
**原因**：formBindingData字段与LocalStorageProp不匹配
**解决方法**：
- 确保FormDataClass字段名与LocalStorageProp装饰的属性名一致
- 检查updateForm是否成功调用
- 确认formId是否正确

### Q3：FormExtensionAbility被意外清理
**原因**：创建后10秒内无操作会被系统清理
**解决方法**：
- 在onFormEvent中快速处理逻辑
- 避免在FormExtensionAbility中执行耗时操作
- 使用hilog记录生命周期状态

### Q4：引用不支持模块导致程序退出
**原因**：FormExtensionAbility不支持引用音频、相机等模块
**解决方法**：
- 移除@ohos.multimedia.audio、@ohos.multimedia.camera等模块引用
- 将复杂业务逻辑移至主应用UIAbility中处理
- 仅在FormExtensionAbility中处理卡片生命周期回调

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "function": "卡片message事件通信",
  "card_updated": true,
  "message_delivered": true,
  "formId": "卡片ID",
  "messageContent": "传递的消息内容",
  "apiUsed": [
    "postCardAction",
    "FormExtensionAbility.onFormEvent",
    "formBindingData.createFormBindingData",
    "formProvider.updateForm"
  ]
}
```

## 参考文档

- [卡片传递消息给应用开发指南](arkts-ui-widget-event-formextensionability.md)
- [postCardAction API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-postcardaction)
- [FormExtensionAbility API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formextensionability)
- [formProvider.updateForm API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formprovider)

## 完整示例代码

- [卡片页面完整示例](assets/UpdateByMessageCard.ets)
- [FormExtensionAbility完整示例](assets/EntryFormAbility.ts)
- [配置文件示例](assets/form_config.json)

## 测试用例

### 正向测试用例
- [test_message_event_basic.ts](tests/test_message_event_basic.ts)：测试基本的message事件触发和接收
- [test_card_update_success.ts](tests/test_card_update_success.ts)：测试卡片数据成功更新

### 边界测试用例
- [test_large_message_params.ts](tests/test_large_message_params.ts)：测试大容量消息参数传递
- [test_multiple_cards.ts](tests/test_multiple_cards.ts)：测试多个卡片同时触发message事件

### 异常测试用例
- [test_invalid_formId.ts](tests/test_invalid_formId.ts)：测试无效卡片ID的错误处理
- [test_form_extension_timeout.ts](tests/test_form_extension_timeout.ts)：测试FormExtensionAbility超时清理
- [test_update_form_failure.ts](tests/test_update_form_failure.ts)：测试卡片更新失败的降级处理