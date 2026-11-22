---
name: hmos-form-kit-active-refresh
description: 实现ArkTS卡片主动刷新功能，支持单个卡片刷新(updateForm)和批量卡片刷新(reloadForms/reloadAllForms)，API version 22+支持批量刷新，适用于卡片数据更新、定时刷新、事件触发刷新场景
---

# ArkTS卡片主动刷新技能

## 功能描述

本技能提供ArkTS卡片主动刷新的完整实现方案，支持卡片提供方主动刷新卡片内容。包含两种刷新模式：

1. **单个卡片主动刷新**：使用`formProvider.updateForm`接口刷新指定卡片，通过卡片生命周期回调`onFormEvent`、`onUpdateForm`、`onAddForm`搭配使用
2. **批量卡片刷新**（API version 22+）：使用`formProvider.reloadForms`和`formProvider.reloadAllForms`接口批量刷新多个卡片，仅支持在UIAbility中调用

**核心能力**：
- 卡片数据实时更新和刷新
- 卡片事件触发刷新（点击按钮触发）
- 批量卡片管理刷新
- 卡片生命周期回调处理

**适用范围**：
- ArkTS卡片开发（Stage模型）
- Form Kit卡片开发服务
- 卡片提供方开发

**限制条件**：
- 单个卡片刷新：API version 9+
- 批量刷新：API version 22+
- 仅支持Stage模型
- 批量刷新仅支持在UIAbility中调用
- FormExtensionAbility创建后10秒内无操作将会被清理
- 图片文件限制：API version 19及之前每张限制2MB、上限5张；API version 20+总大小不超过10MB、不超过20张

**典型场景**：
- 卡片数据定时更新（天气、股票等）
- 卡片按钮点击刷新
- 应用主进程批量更新多个卡片
- 卡片事件触发数据更新

## 使用场景

### 触发词
- "卡片刷新" - 卡片数据主动更新
- "卡片主动刷新" - 卡片提供方主动触发刷新
- "updateForm" - 更新单个卡片
- "reloadForms" - 批量刷新指定卡片
- "reloadAllForms" - 批量刷新所有卡片
- "卡片事件刷新" - 通过卡片事件触发刷新
- "FormExtensionAbility" - 卡片生命周期回调

### 能做
- 实现卡片单个刷新和批量刷新功能
- 配置卡片生命周期回调（onAddForm、onUpdateForm、onFormEvent）
- 卡片事件触发刷新（通过postCardAction）
- 批量刷新指定moduleName/abilityName/formName的卡片
- 批量刷新应用所有卡片
- 处理卡片数据绑定和更新

### 绝不做
- 不支持在JS卡片中使用（仅支持ArkTS卡片）
- 不支持在FA模型中使用（仅支持Stage模型）
- 批量刷新不支持在FormExtensionAbility中调用（仅支持UIAbility）
- 不处理卡片使用方的刷新请求（仅处理卡片提供方主动刷新）
- 不实现卡片定时刷新（请使用setFormNextRefreshTime）

### 补充
- API version 22+支持批量刷新功能，之前版本仅支持单个卡片刷新
- FormExtensionAbility创建后10秒内无操作将会被清理，需要在回调中及时处理
- 批量刷新通过在UIAbility中调用，通知FormExtension进程执行onUpdateForm回调
- 卡片图片资源有内存限制，超出限制会显示异常

## 调用规范和规则

### 输入约束
- formId：必须为有效的卡片标识字符串
- formBindingData：必须使用formBindingData.createFormBindingData创建
- moduleName/abilityName/formName：批量刷新时必须为有效的字符串
- context：批量刷新时必须为UIAbilityContext类型
- 卡片数据大小：API version 20+总大小不超过10MB，图片不超过20张

### 执行约束
- 最大耗时：单个卡片刷新建议<5秒，批量刷新建议<10秒
- 最大迭代次数：批量刷新一次处理所有目标卡片
- API调用频次：建议每分钟不超过60次刷新请求
- FormExtensionAbility存活时间：创建后10秒内无操作将会被清理

### 内容约束
- 禁止生成：不支持在卡片中使用高危函数（eval、exec等）
- 禁止使用高危函数：卡片代码禁止使用@ohos.multimedia.audio、camera、media等模块
- 禁止操作：禁止在FormExtensionAbility中引用ParticleAbility模块
- 数据限制：卡片数据必须是可序列化的JSON格式

### 降级约束
- 网络失败：建议本地缓存数据，使用上次成功数据刷新
- formId不存在：记录错误日志，跳过该卡片继续处理其他卡片
- 权限不足：提示用户检查应用权限配置
- FormExtensionAbility被清理：重新启动FormExtensionAbility进程
- 批量刷新失败：降级为单个卡片逐个刷新

## 调用流程和步骤

### 步骤1：准备阶段 - 创建卡片和数据绑定

**前置校验**：
1. 确认卡片已正确创建和配置（form_config.json）
2. 确认FormExtensionAbility已实现
3. 确认卡片布局文件已创建
4. 确认API version满足要求（批量刷新需要API 22+）

**参数准备**：
```typescript
// 卡片数据绑定对象
import { formBindingData } from '@kit.FormKit';

// 创建卡片数据
let formData: Record<string, string> = {
  'title': 'Title default.',
  'detail': 'Description default.',
  'temperature': '22c',
  'time': '22:00'
};

// 创建FormBindingData对象
let formBindingDataObj: formBindingData.FormBindingData = 
  formBindingData.createFormBindingData(formData);
```

### 步骤2：实现卡片生命周期回调

**示例代码**：
```typescript
// entry/src/main/ets/entryformability/EntryFormAbility.ets
import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'EntryFormAbility';
const DOMAIN_NUMBER: number = 0xFF00;

export default class EntryFormAbility extends FormExtensionAbility {
  // 卡片添加时触发
  onAddForm(want: Want): formBindingData.FormBindingData {
    hilog.info(DOMAIN_NUMBER, TAG, '[EntryFormAbility] onAddForm');
    
    // 返回卡片初始数据
    let obj: Record<string, string> = {
      'title': 'titleOnAddForm',
      'detail': 'detailOnAddForm'
    };
    let formData: formBindingData.FormBindingData = formBindingData.createFormBindingData(obj);
    return formData;
  }

  // 卡片更新时触发（定时更新/定点更新/使用方请求更新）
  onUpdateForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, '[EntryFormAbility] onUpdateForm');
    
    // 准备更新数据
    let obj: Record<string, string> = {
      'title': 'titleOnUpdateForm',
      'detail': 'detailOnUpdateForm'
    };
    let formData: formBindingData.FormBindingData = formBindingData.createFormBindingData(obj);
    
    // 调用updateForm刷新卡片
    formProvider.updateForm(formId, formData).catch((error: BusinessError) => {
      hilog.error(DOMAIN_NUMBER, TAG, `[EntryFormAbility] updateForm failed, code: ${error.code}, message: ${error.message}`);
    });
  }

  // 卡片事件触发时调用（通过postCardAction触发）
  onFormEvent(formId: string, message: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `FormAbility onFormEvent, formId = ${formId}, message: ${message}`);
    
    // 定义更新数据类
    class FormDataClass {
      title: string = 'Title Update.';
      detail: string = 'Description update success.';
    }
    
    // 创建更新数据
    let formData = new FormDataClass();
    let formInfo: formBindingData.FormBindingData = formBindingData.createFormBindingData(formData);
    
    // 更新卡片
    formProvider.updateForm(formId, formInfo).then(() => {
      hilog.info(DOMAIN_NUMBER, TAG, 'FormAbility updateForm success.');
    }).catch((error: BusinessError) => {
      hilog.error(DOMAIN_NUMBER, TAG, `Operation updateForm failed. Cause: ${JSON.stringify(error)}`);
    });
  }
}
```

### 步骤3：卡片布局和事件触发

**卡片布局示例**：
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
          // 触发message事件，调用onFormEvent回调
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

### 步骤4：批量刷新卡片（API version 22+）

**UIAbility中调用批量刷新**：
```typescript
// entry/src/main/ets/pages/index.ets
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { formProvider } from '@kit.FormKit';

@Entry
@Component
struct Index {
  build() {
    Column({ space: 20 }) {
      // 批量刷新指定卡片
      Button('reloadForms')
        .onClick(() => {
          try {
            let context: common.UIAbilityContext = 
              this.getUIContext().getHostContext() as common.UIAbilityContext;
            
            let moduleName: string = 'entry';
            let abilityName: string = 'EntryFormAbility';
            let formName: string = 'reloadByUIAbilityCard';
            
            formProvider.reloadForms(context, moduleName, abilityName, formName)
              .then((reloadNum: number) => {
                console.info(`reloadForms success, reload number: ${reloadNum}`);
              }).catch((error: BusinessError) => {
                console.error(`promise error, code: ${error.code}, message: ${error.message}`);
              });
          } catch (error) {
            console.error(`catch error, code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message}`);
          }
        })

      // 批量刷新所有卡片
      Button('reloadAllForms')
        .onClick(() => {
          try {
            let context: common.UIAbilityContext = 
              this.getUIContext().getHostContext() as common.UIAbilityContext;
            
            formProvider.reloadAllForms(context)
              .then((reloadNum: number) => {
                console.info(`reloadAllForms success, reload number: ${reloadNum}`);
              }).catch((error: BusinessError) => {
                console.error(`promise error, code: ${error.code}, message: ${error.message}`);
              });
          } catch (error) {
            console.error(`catch error, code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message}`);
          }
        })
    }
    .height('100%')
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

### 步骤5：错误处理

**错误处理代码**：
```typescript
import { formBindingData, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function updateCardWithErrorHandling(formId: string, formData: formBindingData.FormBindingData): Promise<void> {
  try {
    await formProvider.updateForm(formId, formData);
    console.info('updateForm success');
  } catch (error) {
    const businessError = error as BusinessError;
    
    switch (businessError.code) {
      case 401:
        console.error('Parameter error. Check formId and formData.');
        break;
      case 16500050:
        console.error('IPC connection error. Retry later.');
        break;
      case 16500060:
        console.error('Service connection error. Check form service.');
        break;
      case 16500100:
        console.error('Failed to obtain configuration. Check form_config.json.');
        break;
      case 16501000:
        console.error('Internal functional error. Retry or restart app.');
        break;
      case 16501001:
        console.error('Form ID does not exist. Check formId validity.');
        break;
      case 16501003:
        console.error('Form cannot be operated by current app. Check permissions.');
        break;
      default:
        console.error(`Unknown error: code ${businessError.code}, message ${businessError.message}`);
    }
    
    // 降级处理：使用缓存数据或默认数据
    throw error;
  }
}
```

### 步骤6：降级处理

**降级处理代码**：
```typescript
async function fallbackRefreshStrategy(formId: string): Promise<void> {
  try {
    // 优先尝试正常刷新
    const latestData = await fetchLatestData();
    const formData = formBindingData.createFormBindingData(latestData);
    await formProvider.updateForm(formId, formData);
  } catch (error) {
    console.warn('Primary refresh failed, using fallback strategy');
    
    try {
      // 降级方案1：使用本地缓存数据
      const cachedData = getCachedFormData(formId);
      if (cachedData) {
        const formData = formBindingData.createFormBindingData(cachedData);
        await formProvider.updateForm(formId, formData);
        console.info('Used cached data for refresh');
      } else {
        // 降级方案2：使用默认数据
        const defaultData = { 'title': 'Loading...', 'detail': 'Data unavailable' };
        const formData = formBindingData.createFormBindingData(defaultData);
        await formProvider.updateForm(formId, formData);
        console.warn('Used default data as last resort');
      }
    } catch (fallbackError) {
      console.error('All fallback strategies failed');
      // 记录失败日志，等待下次刷新机会
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误，可能原因：1.必填参数未指定；2.参数类型错误；3.参数验证失败 | 检查formId是否为有效字符串，检查formData是否通过createFormBindingData创建 |
| 16500050 | IPC连接错误 | 等待片刻后重试，或检查IPC服务状态 |
| 16500060 | 服务连接错误 | 检查FormKit服务是否正常运行 |
| 16500100 | 无法获取配置信息 | 检查form_config.json配置文件是否正确 |
| 16501000 | 内部功能错误 | 重试刷新操作，或重启应用 |
| 16501001 | 要操作的卡片ID不存在 | 检查formId是否正确，确认卡片是否已添加 |
| 16501002 | 卡片数量超过最大限制 | 减少卡片数量，或联系系统管理员 |
| 16501003 | 当前应用无法操作该卡片 | 检查应用权限配置，确认卡片归属 |
| 16501011 | 卡片不支持此操作 | 检查API version要求，确认卡片类型 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.FormKit": "系统Kit，无需显式声明",
    "@kit.AbilityKit": "系统Kit，无需显式声明",
    "@kit.BasicServicesKit": "系统Kit，无需显式声明"
  }
}
```

### 环境要求
- HarmonyOS SDK：API version 9+（基础功能），API version 22+（批量刷新）
- 开发环境：DevEco Studio 3.1+
- 运行环境：HarmonyOS设备或模拟器
- 模型约束：仅支持Stage模型

### 常见编译问题

**问题1：FormExtensionAbility导入失败**
```
Error: Cannot find module '@kit.FormKit'
```
**解决方法**：
- 确认使用DevEco Studio 3.1+
- 确认项目配置为Stage模型
- 确认SDK版本满足要求

**问题2：postCardAction未定义**
```
Error: 'postCardAction' is not defined
```
**解决方法**：
- postCardAction为全局函数，无需导入
- 确认在卡片页面（.ets文件）中使用
- 确认在onClick事件中调用

**问题3：reloadForms接口不存在**
```
Error: Property 'reloadForms' does not exist on type 'formProvider'
```
**解决方法**：
- 检查API version，reloadForms需要API 22+
- 在module.json5中声明minAPIVersion为22
- 使用条件编译处理不同API版本

**问题4：FormExtensionAbility被系统清理**
```
Warning: FormExtensionAbility process cleaned after 10s
```
**解决方法**：
- FormExtensionAbility创建后10秒内无操作会被清理
- 在回调中及时处理刷新请求
- 避免长时间阻塞操作

## 常见问题与解决方法

### Q1：卡片刷新后数据未更新
**原因**：
- formData数据结构与卡片布局不匹配
- LocalStorageProp属性名称错误
- updateForm调用失败但未捕获错误

**解决方法**：
- 检查formData键名与卡片@LocalStorageProp装饰器属性名一致
- 添加错误处理代码捕获updateForm异常
- 使用hilog记录刷新过程日志

### Q2：批量刷新时部分卡片未更新
**原因**：
- 指定的moduleName/abilityName/formName不匹配
- 某些卡片formId无效
- FormExtensionAbility进程未启动

**解决方法**：
- 确认moduleName/abilityName/formName参数正确
- 检查form_config.json配置
- 先调用getPublishedRunningFormInfos获取有效卡片列表

### Q3：onFormEvent回调未触发
**原因**：
- postCardAction参数配置错误
- action类型不正确
- 卡片未正确注册FormExtensionAbility

**解决方法**：
- 确认postCardAction的action参数为'message'
- 确认params参数为JSON对象
- 检查module.json5中FormExtensionAbility配置

### Q4：卡片图片显示异常
**原因**：
- 图片大小超过限制（API 19：每张2MB，上限5张；API 20+：总大小10MB，上限20张）
- 图片路径错误
- 图片格式不支持

**解决方法**：
- 检查图片大小，压缩或裁剪图片
- 确认图片路径正确（使用$r('app.media.xxx')）
- 使用支持的图片格式（PNG、JPG等）

### Q5：批量刷新返回reloadNum为0
**原因**：
- 无符合条件的卡片
- moduleName/abilityName/formName参数错误
- 应用未添加任何卡片到桌面

**解决方法**：
- 先添加卡片到桌面
- 使用getPublishedRunningFormInfos检查已加桌卡片
- 确认参数与form_config.json配置一致

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "refreshType": "single | batch",
  "formId": "卡片标识（单个刷新）",
  "reloadNum": "刷新卡片数量（批量刷新）",
  "updateSuccess": true,
  "formData": {
    "title": "更新后的标题",
    "detail": "更新后的详情"
  },
  "apiUsed": [
    "formProvider.updateForm",
    "formBindingData.createFormBindingData",
    "postCardAction",
    "FormExtensionAbility.onFormEvent",
    "formProvider.reloadForms",
    "formProvider.reloadAllForms"
  ],
  "errors": [],
  "timestamp": "2024-01-01T12:00:00Z"
}
```

## 参考文档

- [ArkTS卡片主动刷新开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-active-refresh)
- [主动刷新概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-interaction-overview)
- [创建ArkTS卡片](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-creation)
- [formProvider API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formprovider)
- [FormExtensionAbility API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formextensionability)
- [postCardAction API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-postcardaction)
- [formBindingData API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formbindingdata)
- [UIAbility API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-uiability)
- [卡片错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-form)
- [通用错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-universal)

## 完整示例代码

- [单个卡片主动刷新完整示例](assets/example_single_refresh.ets)
- [批量卡片刷新完整示例](assets/example_batch_refresh.ets)
- [FormExtensionAbility完整实现](assets/example_form_extension_ability.ets)
- [卡片布局完整示例](assets/example_card_layout.ets)
- [错误处理和降级示例](assets/example_error_handling.ets)
- [配置文件示例](assets/form_config.json)

## 测试用例

### 正向测试用例
- [单个卡片刷新成功测试](tests/test_single_refresh_positive.ets)：验证单个卡片刷新功能正常工作
- [批量刷新指定卡片测试](tests/test_batch_reload_forms_positive.ets)：验证批量刷新指定卡片功能
- [批量刷新所有卡片测试](tests/test_batch_reload_all_forms_positive.ets)：验证批量刷新所有卡片功能
- [卡片事件触发刷新测试](tests/test_form_event_positive.ets)：验证postCardAction触发onFormEvent正常

### 边界测试用例
- [最大图片数量测试](tests/test_max_images_boundary.ets)：验证图片数量限制（API 20+: 20张）
- [最大数据大小测试](tests/test_max_data_size_boundary.ets)：验证数据大小限制（API 20+: 10MB）
- [FormExtensionAbility存活时间测试](tests/test_form_extension_lifetime_boundary.ets)：验证10秒清理机制
- [批量刷新最大数量测试](tests/test_batch_reload_max_boundary.ets)：验证批量刷新数量限制

### 异常测试用例
- [无效formId测试](tests/test_invalid_formid_exception.ets)：验证formId不存在时的错误处理
- [参数类型错误测试](tests/test_invalid_params_exception.ets)：验证参数类型错误的处理
- [权限不足测试](tests/test_permission_denied_exception.ets)：验证权限不足时的处理
- [IPC连接错误测试](tests/test_ipc_error_exception.ets)：验证IPC连接错误的降级处理
- [FormExtensionAbility未启动测试](tests/test_form_extension_not_started_exception.ets)：验证FormExtensionAbility未启动时的处理