---
name: hmos-form-kit-widget-lifecycle
description: 管理ArkTS卡片生命周期+实现FormExtensionAbility接口+支持卡片创建更新删除+适用于卡片开发场景
---

# 管理ArkTS卡片生命周期技能

## 功能描述

本技能用于管理ArkTS卡片的生命周期，通过实现FormExtensionAbility的生命周期回调接口，处理卡片的创建、更新、删除、可见性变化、事件触发等场景。提供完整的卡片数据绑定和刷新机制，支持定时更新、定点更新和主动请求更新功能。

核心能力包括：
- 卡片创建时数据绑定（onAddForm）
- 卡片更新时数据刷新（onUpdateForm）
- 卡片销毁时资源清理（onRemoveForm）
- 卡片可见性变化处理（onChangeFormVisibility）
- 卡片事件触发处理（onFormEvent）
- 系统配置更新响应（onConfigurationUpdate）

## 使用场景

### 触发词
- "管理ArkTS卡片生命周期"
- "实现FormExtensionAbility"
- "卡片生命周期回调"
- "卡片创建更新删除"
- "ArkTS卡片开发"
- "卡片数据绑定"

### 能做
- 实现FormExtensionAbility的所有生命周期回调接口
- 处理卡片创建、更新、删除的完整流程
- 使用formBindingData创建和更新卡片数据
- 使用formProvider主动刷新卡片内容
- 获取卡片参数信息（formId、卡片名称、尺寸等）
- 响应系统配置变化和卡片可见性变化
- 处理卡片自定义事件

### 绝不做
- 不在FormExtensionAbility中处理长时间任务（超过10秒）
- 不在FormExtensionAbility中使用音频、相机、媒体服务等不支持模块
- 不直接在卡片生命周期中进行复杂的业务逻辑处理
- 不在onAddForm中返回空数据或无效数据

### 补充
- FormExtensionAbility创建后10秒内无操作将会被清理
- 卡片生命周期回调函数中无法处理长时间任务，建议拉起主应用处理
- 卡片使用方不会使用临时卡片，onCastToNormalForm当前无需实现
- 需将卡片信息（formId等）作为持久数据进行管理，以便后续更新和删除

## 调用规范和规则

### 输入约束
- 卡片数据：必须是包含若干键值对的Object或json格式字符串
- 图片数据：通过'formImages'标识，API version 20+总大小不超过10MB，图片数量不超过20张；API version 19及之前版本，图片数量上限为5张，每张限制内存2MB
- Want参数：必须包含卡片参数信息（formId、卡片名称、尺寸等）
- 数据类型：支持字符串、数字、布尔、对象、数组和文件描述符

### 执行约束
- 最大耗时：生命周期回调函数执行时间不超过10秒
- 进程存活：FormExtensionAbility进程在回调完成后10秒内自动退出
- API调用频次：卡片更新频率受updateDuration配置限制
- 图片刷新限制：从API version 20开始，刷新数据总大小不超过10MB，刷新图片数量不超过20张

### 内容约束
- 禁止使用不支持模块：@ohos.ability.particleAbility、@ohos.multimedia.audio、@ohos.multimedia.camera、@ohos.multimedia.media、@ohos.resourceschedule.backgroundTaskManager
- 禁止在生命周期回调中进行长时间阻塞操作
- 禁止直接处理复杂业务逻辑
- 禁止返回无效的FormBindingData对象

### 降级约束
- 长时间任务：拉起主应用UIAbility进行处理，处理完成后使用updateForm通知卡片刷新
- 数据获取失败：返回默认数据或错误提示信息
- 图片加载异常：使用占位图片或隐藏图片组件
- 进程被清理：重新创建FormExtensionAbility实例

## 调用流程和步骤

### 步骤1：准备阶段

**导入模块**：
```typescript
import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Configuration, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
```

**定义常量**：
```typescript
const TAG: string = 'EntryFormAbility';
const DOMAIN_NUMBER: number = 0xFF00;
```

### 步骤2：实现FormExtensionAbility类

**创建类并继承FormExtensionAbility**：
```typescript
export default class EntryFormAbility extends FormExtensionAbility {
  // 实现各个生命周期回调方法
}
```

### 步骤3：实现onAddForm回调

**卡片创建时触发，返回初始数据**：
```typescript
onAddForm(want: Want): formBindingData.FormBindingData {
  hilog.info(DOMAIN_NUMBER, TAG, '[EntryFormAbility] onAddForm');
  
  // 从want参数中获取卡片信息
  hilog.info(DOMAIN_NUMBER, TAG, want.parameters?.[formInfo.FormParam.NAME_KEY] as string);
  
  // 创建卡片初始数据
  let obj: Record<string, string> = {
    'title': 'titleOnAddForm',
    'detail': 'detailOnAddForm'
  };
  
  // 创建FormBindingData对象并返回
  let formData: formBindingData.FormBindingData = formBindingData.createFormBindingData(obj);
  return formData;
}
```

**说明**：
- want参数包含卡片信息：formId（IDENTITY_KEY）、卡片名称（NAME_KEY）、卡片尺寸（DIMENSION_KEY）、模块名称（MODULE_NAME_KEY）等
- 必须返回FormBindingData对象，卡片要显示的数据

### 步骤4：实现onUpdateForm回调

**卡片更新时触发，刷新卡片数据**：
```typescript
onUpdateForm(formId: string): void {
  hilog.info(DOMAIN_NUMBER, TAG, '[EntryFormAbility] onUpdateForm');
  
  // 创建更新数据
  let obj: Record<string, string> = {
    'title': 'titleOnUpdateForm',
    'detail': 'detailOnUpdateForm'
  };
  
  let formData: formBindingData.FormBindingData = formBindingData.createFormBindingData(obj);
  
  // 使用formProvider.updateForm主动刷新卡片
  formProvider.updateForm(formId, formData).catch((error: BusinessError) => {
    hilog.info(DOMAIN_NUMBER, TAG, '[EntryFormAbility] updateForm, error:' + JSON.stringify(error));
  });
}
```

**说明**：
- 若卡片支持定时更新/定点更新/卡片使用方主动请求更新功能，需重写该方法
- 使用formProvider.updateForm接口刷新卡片数据

### 步骤5：实现onRemoveForm回调

**卡片销毁时触发，清理资源**：
```typescript
onRemoveForm(formId: string): void {
  hilog.info(DOMAIN_NUMBER, TAG, '[EntryFormAbility] onRemoveForm');
  
  // 删除之前持久化的卡片实例数据
  // 此接口请根据实际情况实现，具体请参考：FormExtAbility Stage模型卡片实例
}
```

**说明**：
- 需删除持久化的卡片实例数据（formId等）
- 清理卡片相关的资源文件

### 步骤6：实现其他生命周期回调

**onCastToNormalForm**（临时卡片转常态卡片）：
```typescript
onCastToNormalForm(formId: string): void {
  // 当前卡片使用方不会涉及该场景，无需实现该回调函数
  hilog.info(DOMAIN_NUMBER, TAG, '[EntryFormAbility] onCastToNormalForm');
}
```

**onChangeFormVisibility**（卡片可见性变化）：
```typescript
onChangeFormVisibility(newStatus: Record<string, number>): void {
  // 卡片使用方发起可见或者不可见通知触发，提供方需要做相应的处理，仅系统应用生效
  hilog.info(DOMAIN_NUMBER, TAG, '[EntryFormAbility] onChangeFormVisibility');
}
```

**onFormEvent**（卡片事件触发）：
```typescript
onFormEvent(formId: string, message: string): void {
  // 若卡片支持触发事件，则需要重写该方法并实现对事件的触发
  hilog.info(DOMAIN_NUMBER, TAG, `FormAbility onFormEvent, formId = ${formId}, message: ${message}`);
}
```

**onConfigurationUpdate**（系统配置更新）：
```typescript
onConfigurationUpdate(config: Configuration) {
  // 当前formExtensionAbility存活时更新系统配置信息时触发的回调
  // 需注意：formExtensionAbility创建后10秒内无操作将会被清理
  hilog.info(DOMAIN_NUMBER, TAG, '[EntryFormAbility] onConfigurationUpdate:' + JSON.stringify(config));
}
```

**onAcquireFormState**（查询卡片状态）：
```typescript
onAcquireFormState(want: Want): formInfo.FormState {
  // 卡片提供方接收查询卡片状态通知接口，默认返回卡片初始状态
  return formInfo.FormState.READY;
}
```

### 步骤7：错误处理

**捕获并处理错误**：
```typescript
try {
  // 调用formProvider.updateForm等接口
  formProvider.updateForm(formId, formData).then(() => {
    hilog.info(DOMAIN_NUMBER, TAG, 'updateForm success');
  }).catch((error: BusinessError) => {
    hilog.error(DOMAIN_NUMBER, TAG, `updateForm failed, code: ${error.code}, message: ${error.message}`);
  });
} catch (error) {
  let businessError = error as BusinessError;
  hilog.error(DOMAIN_NUMBER, TAG, `catch error, code: ${businessError.code}, message: ${businessError.message}`);
}
```

### 步骤8：长时间任务降级处理

**拉起主应用处理长时间任务**：
```typescript
// 在onFormEvent或onUpdateForm中处理需要超过10秒的任务时
// 拉起主应用UIAbility进行处理
import { common } from '@kit.AbilityKit';

// 使用context.startAbility启动主应用
let want: Want = {
  bundleName: 'com.example.myapplication',
  abilityName: 'EntryAbility',
  parameters: {
    'formId': formId,
    'taskType': 'longRunningTask'
  }
};

this.context.startAbility(want).then(() => {
  hilog.info(DOMAIN_NUMBER, TAG, 'startAbility success');
}).catch((error: BusinessError) => {
  hilog.error(DOMAIN_NUMBER, TAG, `startAbility failed, code: ${error.code}`);
});

// 主应用处理完成后，使用formProvider.updateForm通知卡片刷新
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：必填参数未指定、参数类型错误、参数验证失败 | 检查参数类型和取值范围，确保必填参数已提供 |
| 16500050 | IPC连接错误 | 检查IPC通信是否正常，重试操作 |
| 16500060 | 服务连接错误 | 检查FormManagerService是否正常运行 |
| 16500100 | 获取配置信息失败 | 检查form_config.json配置文件是否正确 |
| 16501000 | 内部功能错误 | 检查卡片内部逻辑，查看日志定位问题 |
| 16501001 | 要操作的卡片ID不存在 | 确认formId是否正确，卡片是否已被删除 |
| 16501002 | 卡片数量超过最大限制 | 减少卡片数量或调整配置上限 |
| 16501003 | 当前应用无法操作该卡片 | 确认卡片归属，只有卡片提供方可以操作 |
| 16501011 | 卡片不支持此操作 | 检查卡片类型和配置，确认支持该功能 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.FormKit": "^1.0.0",
    "@kit.AbilityKit": "^1.0.0",
    "@kit.BasicServicesKit": "^1.0.0",
    "@kit.PerformanceAnalysisKit": "^1.0.0"
  }
}
```

### 环境要求
- HarmonyOS API version: 9+
- 开发环境: DevEco Studio
- 运行环境: Stage模型

### 常见编译问题

**问题1：FormExtensionAbility类导入失败**
```
Error: Cannot find module '@kit.FormKit'
```
**解决方法**：确保ohpm已安装依赖包，检查oh-package.json5配置

**问题2：Want类型定义错误**
```
Error: Property 'parameters' does not exist on type 'Want'
```
**解决方法**：导入Want类型时确保使用正确的接口定义，使用@kit.AbilityKit中的Want

**问题3：hilog调用参数错误**
```
Error: Argument of type 'string' is not assignable to parameter of type 'number'
```
**解决方法**：hilog.info参数顺序为（domain, tag, message），domain为number类型

## 常见问题与解决方法

### Q1：FormExtensionAbility进程被意外清理
**原因**：FormExtensionAbility创建后10秒内无操作会被自动清理
**解决方法**：
- 避免在生命周期回调中执行耗时超过10秒的任务
- 对于长时间任务，拉起主应用UIAbility处理
- 使用formProvider.updateForm及时刷新卡片数据

### Q2：卡片数据刷新不及时
**原因**：卡片更新频率受updateDuration配置限制，或未正确调用updateForm
**解决方法**：
- 检查form_config.json中的updateDuration配置
- 在onUpdateForm中正确调用formProvider.updateForm
- 使用setFormNextRefreshTime设置下次更新时间（最小5分钟）

### Q3：卡片图片显示异常
**原因**：图片文件大小或数量超出限制
**解决方法**：
- API version 20+：确保刷新数据总大小不超过10MB，图片数量不超过20张
- API version 19及之前：确保图片数量不超过5张，每张不超过2MB
- 使用文件描述符传递图片，避免内存占用过大

### Q4：无法获取卡片参数信息
**原因**：want.parameters中未正确获取FormParam值
**解决方法**：
- 使用formInfo.FormParam常量获取参数，如formInfo.FormParam.IDENTITY_KEY
- 检查卡片创建时是否正确传递了参数
- 使用want.parameters?.[key]方式安全访问参数

### Q5：卡片事件无法触发
**原因**：未实现onFormEvent回调，或事件消息格式错误
**解决方法**：
- 在FormExtensionAbility中实现onFormEvent方法
- 确保卡片UI中使用postCardAction触发事件
- 检查message参数格式是否正确

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "formId": "卡片标识",
  "lifecycleCallback": "调用的生命周期回调方法",
  "formData": "卡片数据内容",
  "apiUsed": [
    "FormExtensionAbility",
    "formBindingData.createFormBindingData",
    "formProvider.updateForm",
    "formInfo.FormParam"
  ],
  "message": "卡片生命周期管理完成"
}
```

## 参考文档

- [管理ArkTS卡片生命周期](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-lifecycle) (原始开发指南)
- [FormExtensionAbility API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formextensionability)
- [formBindingData API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formbindingdata)
- [formProvider API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formprovider)
- [formInfo API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-forminfo)
- [Want API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-want)
- [ArkTS卡片页面交互概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-event-overview)

## 完整示例代码

- [ArkTS示例代码](assets/EntryFormAbility.ets) - 完整的FormExtensionAbility实现示例
- [配置文件示例](assets/form_config.json) - 卡片配置文件示例

## 测试用例

### 正向测试用例
- [卡片创建测试](tests/test_add_form.py) - 测试onAddForm回调，返回有效数据
- [卡片更新测试](tests/test_update_form.py) - 测试onUpdateForm回调，正确刷新数据
- [卡片删除测试](tests/test_remove_form.py) - 测试onRemoveForm回调，清理资源

### 边界测试用例
- [最大数据量测试](tests/test_max_data.py) - 测试卡片数据达到10MB上限的处理
- [图片数量上限测试](tests/test_max_images.py) - 测试图片数量达到20张上限的处理
- [并发更新测试](tests/test_concurrent_update.py) - 测试多个卡片同时更新的场景

### 异常测试用例
- [无效formId测试](tests/test_invalid_formid.py) - 测试使用不存在或无效的formId
- [空数据测试](tests/test_empty_data.py) - 测试返回空数据或无效FormBindingData
- [超时任务测试](tests/test_timeout_task.py) - 测试生命周期回调执行超过10秒的处理
- [不支持模块测试](tests/test_unsupported_module.py) - 测试在FormExtensionAbility中使用不支持模块