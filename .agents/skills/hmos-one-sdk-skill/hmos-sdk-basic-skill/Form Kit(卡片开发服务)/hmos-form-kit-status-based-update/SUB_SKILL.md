---
name: hmos-form-kit-status-based-update
description: 根据卡片状态选择性地刷新卡片内容，支持多状态管理和差异化刷新，适用于实现多功能卡片（如不同城市的天气、不同账号的信息），最大支持256个卡片实例
---

# 根据卡片状态刷新不同内容技能

## 功能描述

本技能实现ArkTS卡片根据状态选择性地刷新不同内容的能力。允许开发者为同一个卡片配置不同的功能状态（如不同城市的天气、不同账号的信息），在卡片刷新时根据当前状态动态选择需要更新的内容。通过本地数据库持久化卡片状态，确保状态数据不会因卡片销毁而丢失。

**核心能力**：
- 状态管理：支持多卡片实例的状态存储和管理
- 差异化刷新：根据状态选择性刷新卡片内容
- 状态持久化：使用preferences本地数据库存储状态
- 状态变化通知：卡片页面通过postCardAction通知FormAbility状态变化

## 使用场景

### 触发词
- "根据状态刷新卡片"
- "状态卡片刷新"
- "多功能卡片"
- "差异化刷新"
- "卡片状态管理"

### 能做
- 实现多功能卡片（如不同城市天气、不同账号信息）
- 根据用户选择的状态刷新不同内容
- 持久化卡片状态数据，避免卡片销毁时数据丢失
- 监听卡片状态变化并通知FormAbility
- 在卡片刷新时根据状态选择更新内容

### 绝不做
- 不支持跨卡片实例的状态共享（每个卡片实例状态独立）
- 不支持复杂的状态逻辑判断（仅支持简单的布尔状态）
- 不支持动态状态切换（状态需在卡片页面预先定义）
- 不支持状态数据加密（状态数据以明文存储）
- 不支持多进程并发访问状态数据

### 补充
- 状态数据存储在preferences本地数据库中，建议在onAddForm时初始化
- 卡片销毁时需在onRemoveForm清理状态数据，避免数据库文件持续增大
- 状态变化通过postCardAction的message类型通知FormAbility
- 刷新频率通过form_config.json配置，最小间隔30分钟
- FormExtensionAbility创建后10秒内无操作将会被清理

## 调用规范和规则

### 输入约束
- 卡片状态数量：建议不超过5个状态（避免UI过于复杂）
- 状态值类型：仅支持布尔值（true/false）或字符串
- 卡片实例数量：最大256个卡片实例
- 状态数据大小：每个状态数据不超过16MB（preferences限制）
- 状态名称长度：不超过1024字节（preferences key限制）

### 执行约束
- 状态存储耗时：不超过100ms
- 卡片刷新耗时：不超过1s
- postCardAction调用：仅在卡片页面事件中触发（如onClick、onChange）
- preferences操作：必须在FormExtensionAbility生命周期回调中执行
- 最大迭代次数：单次刷新不超过3次API调用（getPreferences + put/update + flush）

### 内容约束
- 禁止生成：不支持在FormExtensionAbility中使用音频、相机、媒体服务模块
- 禁止使用高危函数：不允许使用@ohos.ability.particleAbility、@ohos.multimedia.audio等模块
- 禁止操作：不允许在卡片页面直接修改状态数据（必须通过postCardAction通知）
- 禁止跨进程：不允许在多进程场景下使用preferences（会导致文件损坏）

### 降级约束
- 状态存储失败：使用默认状态值，记录错误日志，下次刷新时重新初始化
- 卡片刷新失败：保持上次刷新内容不变，记录错误日志，等待下次刷新周期
- preferences获取失败：使用内存缓存临时存储状态，提示用户重新添加卡片
- postCardAction调用失败：保持当前状态不变，提示用户重新选择状态

## 调用流程和步骤

### 步骤1：配置卡片自动刷新

**前置校验**：
1. 验证form_config.json文件存在
2. 验证updateEnabled配置为true
3. 验证scheduledUpdateTime配置正确（格式"HH:MM"）

**参数准备**：
```json
{
  "forms": [
    {
      "name": "WidgetUpdateByStatus",
      "description": "$string:UpdateByStatusFormAbility_desc",
      "src": "./ets/widgetupdatebystatus/pages/WidgetUpdateByStatusCard.ets",
      "uiSyntax": "arkts",
      "window": {
        "designWidth": 720,
        "autoDesignWidth": true
      },
      "isDefault": true,
      "updateEnabled": true,
      "scheduledUpdateTime": "10:30",
      "updateDuration": 1,
      "defaultDimension": "2*2",
      "supportDimensions": ["2*2"]
    }
  ]
}
```

### 步骤2：卡片页面监听状态变化

**示例代码**：
```typescript
let storageUpdateByStatus = new LocalStorage();
@Entry(storageUpdateByStatus)
@Component
struct WidgetUpdateByStatusCard {
  @LocalStorageProp('textA') textA: Resource = $r('app.string.to_be_refreshed');
  @LocalStorageProp('textB') textB: Resource = $r('app.string.to_be_refreshed');
  @State selectA: boolean = false;
  @State selectB: boolean = false;

  build() {
    Column() {
      Column() {
        Row() {
          Checkbox({ name: 'checkbox1', group: 'checkboxGroup' })
            .padding(0)
            .select(false)
            .margin({ left: 26 })
            .onChange((value: boolean) => {
              this.selectA = value;
              postCardAction(this, {
                action: 'message',
                params: {
                  selectA: JSON.stringify(value)
                }
              });
            })
          Text($r('app.string.status_a'))
            .fontColor('#000000')
            .opacity(0.9)
            .fontSize(14)
            .margin({ left: 8 })
        }
        .width('100%')
        .padding(0)
        .justifyContent(FlexAlign.Start)

        Row() {
          Checkbox({ name: 'checkbox2', group: 'checkboxGroup' })
            .padding(0)
            .select(false)
            .margin({ left: 26 })
            .onChange((value: boolean) => {
              this.selectB = value;
              postCardAction(this, {
                action: 'message',
                params: {
                  selectB: JSON.stringify(value)
                }
              });
            })
          Text($r('app.string.status_b'))
            .fontColor('#000000')
            .opacity(0.9)
            .fontSize(14)
            .margin({ left: 8 })
        }
        .width('100%')
        .position({ y: 32 })
        .padding(0)
        .justifyContent(FlexAlign.Start)
      }
      .position({ y: 12 })

      Column() {
        Row() {
          Text($r('app.string.status_a'))
            .fontColor('#000000')
            .opacity(0.4)
            .fontSize(12)
          Text(this.textA)
            .fontColor('#000000')
            .opacity(0.4)
            .fontSize(12)
        }
        .margin({ top: '12px', left: 26, right: '26px' })

        Row() {
          Text($r('app.string.status_b'))
            .fontColor('#000000')
            .opacity(0.4)
            .fontSize(12)
          Text(this.textB)
            .fontColor('#000000')
            .opacity(0.4)
            .fontSize(12)
        }
        .margin({
          top: '12px',
          bottom: '21px',
          left: 26,
          right: '26px'
        })
      }
      .margin({ top: 80 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundImage($r('app.media.CardUpdateByStatus'))
    .backgroundImageSize(ImageSize.Cover)
  }
}
```

### 步骤3：FormAbility初始化状态存储

**示例代码**：
```typescript
import { Want } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'UpdateByStatusFormAbility';
const DOMAIN_NUMBER: number = 0xFF00;

export default class UpdateByStatusFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    let formId: string = '';
    if (want.parameters) {
      formId = want.parameters[formInfo.FormParam.IDENTITY_KEY].toString();
      let promise: Promise<preferences.Preferences> = preferences.getPreferences(this.context, 'myStore');
      promise.then(async (storeDB: preferences.Preferences) => {
        hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded to get preferences.');
        await storeDB.put('A' + formId, 'false');
        await storeDB.put('B' + formId, 'false');
        await storeDB.flush();
      }).catch((err: BusinessError) => {
        hilog.info(DOMAIN_NUMBER, TAG, `Failed to get preferences. ${JSON.stringify(err)}`);
      });
    }
    let formData: Record<string, Object | string> = {};
    return formBindingData.createFormBindingData(formData);
  }

  onRemoveForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, 'onRemoveForm, formId:' + formId);
    let promise = preferences.getPreferences(this.context, 'myStore');
    promise.then(async (storeDB) => {
      hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded to get preferences.');
      await storeDB.delete('A' + formId);
      await storeDB.delete('B' + formId);
    }).catch((err: BusinessError) => {
      hilog.info(DOMAIN_NUMBER, TAG, `Failed to get preferences. ${JSON.stringify(err)}`);
    });
  }

  onCastToNormalForm(formId: string): void {
  }

  onUpdateForm(formId: string): void {
    let promise: Promise<preferences.Preferences> = preferences.getPreferences(this.context, 'myStore');
    promise.then(async (storeDB: preferences.Preferences) => {
      hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded to get preferences from onUpdateForm.');
      let stateA = await storeDB.get('A' + formId, 'false');
      let stateB = await storeDB.get('B' + formId, 'false');
      
      if (stateA === 'true') {
        let param: Record<string, string> = {
          'textA': 'AAA'
        };
        let formInfo: formBindingData.FormBindingData = formBindingData.createFormBindingData(param);
        await formProvider.updateForm(formId, formInfo);
      }
      
      if (stateB === 'true') {
        let param: Record<string, string> = {
          'textB': 'BBB'
        };
        let formInfo: formBindingData.FormBindingData = formBindingData.createFormBindingData(param);
        await formProvider.updateForm(formId, formInfo);
      }
      
      hilog.info(DOMAIN_NUMBER, TAG, `Update form success stateA:${stateA} stateB:${stateB}.`);
    }).catch((err: BusinessError) => {
      hilog.info(DOMAIN_NUMBER, TAG, `Failed to get preferences. ${JSON.stringify(err)}`);
    });
  }

  onFormEvent(formId: string, message: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, 'onFormEvent formId:' + formId + 'msg:' + message);
    let promise: Promise<preferences.Preferences> = preferences.getPreferences(this.context, 'myStore');
    promise.then(async (storeDB: preferences.Preferences) => {
      hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded to get preferences.');
      let msg: Record<string, string> = JSON.parse(message);
      if (msg.selectA !== undefined) {
        hilog.info(DOMAIN_NUMBER, TAG, 'onFormEvent selectA info:' + msg.selectA);
        await storeDB.put('A' + formId, msg.selectA);
      }
      if (msg.selectB !== undefined) {
        hilog.info(DOMAIN_NUMBER, TAG, 'onFormEvent selectB info:' + msg.selectB);
        await storeDB.put('B' + formId, msg.selectB);
      }
      await storeDB.flush();
    }).catch((err: BusinessError) => {
      hilog.info(DOMAIN_NUMBER, TAG, `Failed to get preferences. ${JSON.stringify(err)}`);
    });
  }
}
```

### 步骤4：错误处理

```typescript
try {
  await formProvider.updateForm(formId, formInfo);
  hilog.info(DOMAIN_NUMBER, TAG, 'Update form success');
} catch (error) {
  const err = error as BusinessError;
  hilog.error(DOMAIN_NUMBER, TAG, `Update form failed. Code: ${err.code}, Message: ${err.message}`);
  
  switch (err.code) {
    case 16501000:
      hilog.error(DOMAIN_NUMBER, TAG, 'Internal functional error occurred');
      break;
    case 16501001:
      hilog.error(DOMAIN_NUMBER, TAG, 'Form ID does not exist');
      break;
    case 16501002:
      hilog.error(DOMAIN_NUMBER, TAG, 'Number of forms exceeds maximum allowed');
      break;
    case 16501003:
      hilog.error(DOMAIN_NUMBER, TAG, 'Form cannot be operated by current application');
      break;
    default:
      hilog.error(DOMAIN_NUMBER, TAG, 'Unknown error');
  }
}
```

### 步骤5：降级处理

```typescript
async function fallbackRefresh(formId: string): Promise<void> {
  try {
    let param: Record<string, string> = {
      'textA': 'Default Value A',
      'textB': 'Default Value B'
    };
    let formInfo: formBindingData.FormBindingData = formBindingData.createFormBindingData(param);
    await formProvider.updateForm(formId, formInfo);
    hilog.warn(DOMAIN_NUMBER, TAG, 'Fallback refresh applied');
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN_NUMBER, TAG, `Fallback refresh failed. Code: ${err.code}, Message: ${err.message}`);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：必填参数未指定、参数类型错误、参数校验失败 | 检查参数类型和取值范围 |
| 15500000 | 内部错误 | 检查preferences文件是否存在，权限是否正确 |
| 15501001 | 仅在Stage模型下支持该操作 | 确保使用Stage模型开发 |
| 15501002 | 无效的数据组ID | 检查dataGroupId配置 |
| 16500050 | IPC连接错误 | 检查系统服务是否正常运行 |
| 16500060 | 服务连接错误 | 检查FormKit服务是否可用 |
| 16500100 | 获取配置信息失败 | 检查form_config.json配置是否正确 |
| 16501000 | 内部功能错误 | 检查API调用参数，查看日志详情 |
| 16501001 | 要操作的卡片ID不存在 | 检查formId是否正确，卡片是否已销毁 |
| 16501002 | 卡片数量超过最大限制 | 减少卡片实例数量，不超过256个 |
| 16501003 | 当前应用无法操作该卡片 | 检查应用权限和卡片所属应用 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.FormKit": "HarmonyOS API",
    "@kit.ArkData": "HarmonyOS API",
    "@kit.AbilityKit": "HarmonyOS API",
    "@kit.PerformanceAnalysisKit": "HarmonyOS API",
    "@kit.BasicServicesKit": "HarmonyOS API"
  }
}
```

### 环境要求
- HarmonyOS API：API version 9及以上
- 开发环境：DevEco Studio 3.1及以上
- 运行环境：HarmonyOS 3.1及以上
- 模型约束：仅支持Stage模型

### 常见编译问题

**问题1：preferences模块导入失败**
```
Error: Cannot find module '@kit.ArkData' or its corresponding type declarations
```
**解决方法**：确保项目API version配置为9及以上，检查ohpm依赖配置

**问题2：postCardAction未定义**
```
Error: 'postCardAction' is not defined
```
**解决方法**：postCardAction是全局函数，无需导入，确保在卡片页面中使用（不是普通页面）

**问题3：FormExtensionAbility生命周期回调未触发**
```
Warning: onFormEvent callback not triggered
```
**解决方法**：检查postCardAction的action参数是否为'message'，确保params格式正确（JSON字符串）

**问题4：preferences数据丢失**
```
Error: Preferences data not found after form removed
```
**解决方法**：确保在onRemoveForm中删除卡片状态数据，避免数据库文件过大

## 常见问题与解决方法

### Q1：状态数据在卡片刷新时丢失
**原因**：preferences未执行flush操作，数据未持久化到文件
**解决方法**：
- 在put操作后立即执行flush()
- 确保flush()在异步回调中正确执行
- 检查preferences文件权限是否正确

### Q2：卡片状态不生效，总是显示默认内容
**原因**：状态数据未正确存储或读取
**解决方法**：
- 检查onAddForm中是否正确初始化状态（put操作）
- 检查onFormEvent中是否正确接收和存储状态变化
- 检查onUpdateForm中是否正确读取状态数据（get操作）
- 确保状态键名格式正确（如'A' + formId）

### Q3：多个卡片实例状态混淆
**原因**：状态键名未区分不同卡片实例
**解决方法**：
- 使用formId作为状态键名的一部分（如'A' + formId）
- 确保每个卡片实例状态独立存储
- 在onRemoveForm中清理对应卡片的状态数据

### Q4：卡片刷新频率不符合预期
**原因**：form_config.json配置错误或系统限制
**解决方法**：
- 检查updateEnabled配置是否为true
- 检查scheduledUpdateTime格式是否正确（"HH:MM"）
- 检查updateDuration配置（单位：小时）
- 注意系统最小刷新间隔为30分钟

### Q5：卡片销毁后数据库文件持续增大
**原因**：onRemoveForm未清理状态数据
**解决方法**：
- 在onRemoveForm中删除对应卡片的状态数据
- 使用delete操作清理所有相关键名
- 定期检查数据库文件大小，必要时清理无效数据

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "formId": "卡片实例ID",
  "stateData": {
    "stateA": "true",
    "stateB": "false"
  },
  "refreshedContent": {
    "textA": "更新内容A",
    "textB": "未更新"
  },
  "apiUsed": [
    "postCardAction",
    "preferences.getPreferences",
    "preferences.put",
    "preferences.get",
    "preferences.flush",
    "formBindingData.createFormBindingData",
    "formProvider.updateForm"
  ],
  "executionTime": "刷新耗时（毫秒）",
  "nextRefreshTime": "下次刷新时间"
}
```

## 参考文档

- [根据卡片状态刷新不同内容开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-update-by-status)
- [postCardAction API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-postcardaction)
- [FormExtensionAbility API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formextensionability)
- [formProvider API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formprovider)
- [formBindingData API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formbindingdata)
- [preferences API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-data-preferences)

## 完整示例代码

- [ArkTS卡片页面示例](assets/WidgetUpdateByStatusCard.ets)
- [FormAbility示例](assets/UpdateByStatusFormAbility.ts)
- [卡片配置文件示例](assets/form_config.json)

## 测试用例

### 正向测试用例
- [单状态卡片刷新](tests/test_single_state_refresh.py)：测试单个状态选中时的卡片刷新功能
- [多状态卡片刷新](tests/test_multi_state_refresh.py)：测试多个状态同时选中时的卡片刷新功能
- [状态变化通知](tests/test_state_change_notification.py)：测试状态变化后FormAbility接收通知

### 边界测试用例
- [最大卡片实例](tests/test_max_form_instances.py)：测试256个卡片实例的状态管理
- [最大状态数量](tests/test_max_state_count.py)：测试5个状态的管理和刷新
- [长状态名称](tests/test_long_state_name.py)：测试1024字节状态名称的存储

### 异常测试用例
- [preferences获取失败](tests/test_preferences_get_failure.py)：测试preferences获取失败时的降级处理
- [卡片刷新失败](tests/test_form_update_failure.py)：测试卡片刷新失败时的错误处理
- [状态存储失败](tests/test_state_storage_failure.py)：测试状态存储失败时的默认值处理