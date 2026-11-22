---
name: hmos-form-kit-js-widget-development
description: 开发JS卡片提供方（Stage模型），支持卡片生命周期管理、数据持久化、数据交互、页面开发（HML+CSS+JSON）及事件处理，适用于卡片创建、更新、删除场景，最大支持10秒生命周期
---

# JS卡片开发指导（Stage模型）技能

## 功能描述

本技能提供基于Stage模型的JS卡片提供方开发能力，实现完整的卡片生命周期管理。主要功能包括：

- **生命周期管理**：实现FormExtensionAbility的生命周期回调（创建、更新、删除、可见性变更、事件处理）
- **数据持久化**：卡片信息的存储与管理，支持常态卡片和临时卡片的数据维护
- **数据交互**：通过formBindingData创建卡片数据，使用formProvider更新卡片显示
- **页面开发**：使用类Web范式（HML+CSS+JSON）开发卡片页面布局和样式
- **事件处理**：支持router事件（跳转UIAbility）和message事件（自定义点击事件）

**适用范围**：
- 卡片提供方应用开发
- Stage模型（API version 9及以上）
- 支持多种卡片尺寸（1×1、1×2、2×2、2×4、2×3、3×3、4×4、6×4）
- 最大生命周期限制：创建后10秒内无操作将被清理

**典型场景**：
- 创建桌面卡片应用
- 开发天气、日程、音乐播放器等卡片
- 实现卡片定时/定点刷新
- 处理卡片点击事件跳转

## 使用场景

### 触发词
- "开发JS卡片" - 创建JS卡片提供方应用
- "卡片生命周期" - 实现FormExtensionAbility生命周期接口
- "卡片数据更新" - 使用formProvider更新卡片显示内容
- "卡片事件处理" - 实现卡片点击事件（router/message）
- "卡片持久化" - 存储和管理卡片实例数据
- "Stage模型卡片" - 基于Stage模型的卡片开发

### 能做
- 创建和配置FormExtensionAbility卡片扩展类
- 实现卡片生命周期回调（onAddForm、onUpdateForm、onRemoveForm等）
- 持久化卡片信息（使用preferences轻量级数据存储）
- 创建FormBindingData对象并更新卡片数据
- 开发HML+CSS+JSON卡片页面布局
- 实现卡片router和message事件处理
- 配置卡片profile文件（尺寸、刷新策略等）
- 处理卡片可见性变更和临时卡片转换

### 绝不做
- 不支持FA模型卡片开发（仅支持Stage模型）
- 不实现卡片使用方功能（仅提供卡片提供方开发）
- 不处理超出10秒生命周期限制的长时间任务（FormExtensionAbility不能常驻后台）
- 不引用不支持模块（@ohos.ability.particleAbility、音频、相机、媒体、后台任务管理等）
- 不处理超过限制的图片资源（API version 20：最多20张图片/10MB数据；API version 19：最多5张图片/每张2MB）

### 补充
- FormExtensionAbility创建后10秒内无操作将被清理，无法处理长时间任务
- 卡片数据必须按照卡片ID进行持久化管理，支持多实例
- 临时卡片需要特殊处理（清理长时间未删除数据、转换为常态卡片）
- 卡片页面使用类Web范式（HML+CSS+JSON），不支持ArkTS语法
- 卡片事件分为router事件（跳转UIAbility）和message事件（自定义处理）
- 卡片配置文件必须在module.json5中声明metadata元信息

## 调用规范和规则

### 输入约束
- **API版本**：最低API version 9
- **模型约束**：仅支持Stage模型
- **卡片尺寸**：支持1×1、1×2、2×2、2×4、2×3、3×3、4×4、6×4（2×3和3×3仅支持手表设备，1×1仅支持锁屏）
- **数据大小**：
  - API version 20+：刷新数据总大小不超过10MB，图片不超过20张
  - API version 19：图片最多5张，每张限制2MB
- **刷新时间**：setFormNextRefreshTime最小值5分钟
- **文件格式**：卡片页面必须使用HML+CSS+JSON格式

### 执行约束
- **生命周期限制**：FormExtensionAbility创建后10秒内无操作将被清理
- **操作频次**：避免频繁更新卡片（遵循配置的刷新策略）
- **持久化路径**：使用/el2/base/haps/目录存储卡片信息
- **异步操作**：所有formProvider接口必须使用Promise或AsyncCallback异步调用
- **错误处理**：必须捕获BusinessError并处理错误码

### 内容约束
- **禁止引用模块**：
  - @ohos.ability.particleAbility
  - @ohos.multimedia.audio
  - @ohos.multimedia.camera
  - @ohos.multimedia.media
  - @ohos.resourceschedule.backgroundTaskManager
- **禁止高危操作**：
  - FormExtensionAbility中执行长时间任务
  - 硬编码敏感信息（卡片ID、formName等）
  - 直接操作文件系统（使用preferences进行数据持久化）
- **禁止遗漏处理**：
  - 临时卡片清理逻辑
  - 卡片数据完整性校验
  - 错误码处理（16500050、16500060、16500100、16501000等）

### 降级约束
- **生命周期超时**：10秒内无法完成操作时，记录日志并返回默认数据
- **持久化失败**：preferences操作失败时，使用内存临时存储并记录错误
- **更新失败**：formProvider.updateForm失败时，记录错误码并尝试重试（最多3次）
- **图片加载失败**：图片资源超出限制时，显示占位图或降级为纯文本卡片
- **网络请求失败**：无法获取最新数据时，使用本地缓存数据更新卡片

## 调用流程和步骤

### 步骤1：准备阶段（创建FormExtensionAbility）

**前置校验**：
1. 确认项目使用Stage模型（检查module.json5中type字段）
2. 确认API版本≥9（检查build-profile.json5中compatibleSdkVersion）
3. 确认已安装必要依赖（@kit.FormKit、@kit.AbilityKit、@kit.ArkData）

**导入模块**：
```typescript
// entry/src/main/ets/jscardformability/JsCardFormAbility.ets
import { common, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { formBindingData, FormExtensionAbility, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';
```

**参数准备**：
```typescript
const TAG: string = 'JsCardFormAbility';
const DATA_STORAGE_PATH: string = '/data/storage/el2/base/haps/form_store';
const DOMAIN_NUMBER: number = 0xFF00;
```

### 步骤2：实现卡片生命周期回调

**示例代码**：
```typescript
// entry/src/main/ets/jscardformability/JsCardFormAbility.ets

// 持久化卡片信息
let storeFormInfo = async (formId: string, formName: string, tempFlag: boolean, context: common.FormExtensionContext): Promise<void> => {
  let formInfo: Record<string, string | boolean | number> = {
    'formName': formName,
    'tempFlag': tempFlag,
    'updateCount': 0
  };
  try {
    const storage: preferences.Preferences = await preferences.getPreferences(context, DATA_STORAGE_PATH);
    await storage.put(formId, JSON.stringify(formInfo));
    hilog.info(DOMAIN_NUMBER, TAG, `storeFormInfo success, formId: ${formId}`);
    await storage.flush();
  } catch (err) {
    hilog.error(DOMAIN_NUMBER, TAG, `storeFormInfo failed, err: ${JSON.stringify(err as BusinessError)}`);
  }
}

// 删除卡片信息
let deleteFormInfo = async (formId: string, context: common.FormExtensionContext): Promise<void> => {
  try {
    const storage: preferences.Preferences = await preferences.getPreferences(context, DATA_STORAGE_PATH);
    await storage.delete(formId);
    hilog.info(DOMAIN_NUMBER, TAG, `deleteFormInfo success, formId: ${formId}`);
    await storage.flush();
  } catch (err) {
    hilog.error(DOMAIN_NUMBER, TAG, `deleteFormInfo failed, err: ${JSON.stringify(err as BusinessError)}`);
  }
};

export default class JsCardFormAbility extends FormExtensionAbility {
  // 创建卡片回调
  onAddForm(want: Want): formBindingData.FormBindingData {
    hilog.info(DOMAIN_NUMBER, TAG, '[JsCardFormAbility] onAddForm');
    if (want.parameters) {
      let formId = JSON.stringify(want.parameters['ohos.extra.param.key.form_identity']);
      let formName = JSON.stringify(want.parameters['ohos.extra.param.key.form_name']);
      let tempFlag = want.parameters['ohos.extra.param.key.form_temporary'] as boolean;
      storeFormInfo(formId, formName, tempFlag, this.context);
    }
    let obj: Record<string, string> = {
      'title': 'titleOnCreate',
      'detail': 'detailOnCreate'
    };
    let formData: formBindingData.FormBindingData = formBindingData.createFormBindingData(obj);
    return formData;
  }

  // 删除卡片回调
  onRemoveForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, '[JsCardFormAbility] onRemoveForm');
    deleteFormInfo(formId, this.context);
  }

  // 更新卡片回调
  onUpdateForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, '[JsCardFormAbility] onUpdateForm');
    let obj: Record<string, string> = {
      'title': 'titleOnUpdate',
      'detail': 'detailOnUpdate'
    };
    let formData: formBindingData.FormBindingData = formBindingData.createFormBindingData(obj);
    formProvider.updateForm(formId, formData).catch((error: BusinessError) => {
      hilog.info(DOMAIN_NUMBER, TAG, `updateForm error: ${JSON.stringify(error)}`);
    });
  }

  // 卡片事件回调
  onFormEvent(formId: string, message: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, '[JsCardFormAbility] onFormEvent');
    let msg: Record<string, string> = JSON.parse(message);
    if (msg.detail === 'message detail') {
      hilog.info(DOMAIN_NUMBER, TAG, `message info: ${msg.detail}`);
    }
  }
}
```

### 步骤3：配置卡片配置文件

**module.json5配置**：
```json
{
  "module": {
    "extensionAbilities": [
      {
        "name": "JsCardFormAbility",
        "srcEntry": "./ets/jscardformability/JsCardFormAbility.ets",
        "description": "$string:JSCardFormAbility_desc",
        "label": "$string:JSCardFormAbility_label",
        "type": "form",
        "metadata": [
          {
            "name": "ohos.extension.form",
            "resource": "$profile:form_jscard_config"
          }
        ]
      }
    ]
  }
}
```

**卡片profile配置文件（form_jscard_config.json）**：
```json
{
  "forms": [
    {
      "name": "WidgetJS",
      "description": "$string:JSCardEntryAbility_desc",
      "src": "./js/WidgetJS/pages/index/index",
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

### 步骤4：开发卡片页面（HML+CSS+JSON）

**HML文件（index.hml）**：
```html
<div class="container">
  <stack>
    <div class="container-img">
      <image src="/common/widget.png" class="bg-img"></image>
    </div>
    <div class="container-inner">
      <text class="title">{{title}}</text>
      <text class="detail_text" onclick="routerEvent">{{detail}}</text>
    </div>
  </stack>
</div>
```

**CSS文件（index.css）**：
```css
.container {
  flex-direction: column;
  justify-content: center;
  align-items: center;
}
.bg-img {
  flex-shrink: 0;
  height: 100%;
}
.container-inner {
  flex-direction: column;
  justify-content: flex-end;
  align-items: flex-start;
  height: 100%;
  width: 100%;
  padding: 12px;
}
.title {
  font-size: 19px;
  font-weight: bold;
  color: white;
  text-overflow: ellipsis;
  max-lines: 1;
}
.detail_text {
  font-size: 16px;
  color: white;
  opacity: 0.66;
  text-overflow: ellipsis;
  max-lines: 1;
  margin-top: 6px;
}
```

**JSON文件（index.json）**：
```json
{
  "data": {
    "title": "TitleDefault",
    "detail": "TextDefault"
  },
  "actions": {
    "routerEvent": {
      "action": "router",
      "abilityName": "EntryAbility",
      "params": {
        "message": "add detail"
      }
    }
  }
}
```

### 步骤5：处理卡片事件

**router事件（跳转UIAbility）**：
```typescript
// 在UIAbility中接收router事件参数
// entry/src/main/ets/entryability/EntryAbility.ets
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'EntryAbility';
const DOMAIN_NUMBER: number = 0xFF00;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    if (want?.parameters?.params) {
      let params: Record<string, Object> = JSON.parse(JSON.stringify(want.parameters.params));
      if (params.info === 'router info') {
        hilog.info(DOMAIN_NUMBER, TAG, `router info: ${params.info}`);
      }
      if (params.message === 'router message') {
        hilog.info(DOMAIN_NUMBER, TAG, `router message: ${params.message}`);
      }
    }
  }
}
```

**message事件（自定义处理）**：
```typescript
// 在FormExtensionAbility中接收message事件
onFormEvent(formId: string, message: string): void {
  let msg: Record<string, string> = JSON.parse(message);
  if (msg.detail === 'message detail') {
    hilog.info(DOMAIN_NUMBER, TAG, `message info: ${msg.detail}`);
  }
}
```

### 步骤6：错误处理

```typescript
// 捕获BusinessError并处理错误码
try {
  await formProvider.updateForm(formId, formData);
} catch (error) {
  const businessError = error as BusinessError;
  switch (businessError.code) {
    case 16500050:
      hilog.error(DOMAIN_NUMBER, TAG, 'IPC connection error');
      break;
    case 16500060:
      hilog.error(DOMAIN_NUMBER, TAG, 'Service connection error');
      break;
    case 16500100:
      hilog.error(DOMAIN_NUMBER, TAG, 'Failed to obtain configuration information');
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
      hilog.error(DOMAIN_NUMBER, TAG, `Unknown error: ${businessError.message}`);
  }
}
```

### 步骤7：降级处理

```typescript
// 数据持久化失败的降级处理
let fallbackStorage: Map<string, string> = new Map();

let storeFormInfoWithFallback = async (formId: string, formName: string, tempFlag: boolean, context: common.FormExtensionContext): Promise<void> => {
  try {
    const storage: preferences.Preferences = await preferences.getPreferences(context, DATA_STORAGE_PATH);
    await storage.put(formId, JSON.stringify({ formName, tempFlag, updateCount: 0 }));
    await storage.flush();
  } catch (err) {
    hilog.error(DOMAIN_NUMBER, TAG, `Preferences failed, using memory fallback`);
    fallbackStorage.set(formId, JSON.stringify({ formName, tempFlag, updateCount: 0 }));
  }
}

// 卡片更新失败的降级处理
let updateFormWithRetry = async (formId: string, formData: formBindingData.FormBindingData, maxRetries: number = 3): Promise<void> => {
  for (let i = 0; i < maxRetries; i++) {
    try {
      await formProvider.updateForm(formId, formData);
      hilog.info(DOMAIN_NUMBER, TAG, `updateForm success on attempt ${i + 1}`);
      return;
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `updateForm failed on attempt ${i + 1}: ${JSON.stringify(error as BusinessError)}`);
      if (i === maxRetries - 1) {
        hilog.error(DOMAIN_NUMBER, TAG, 'Max retries reached, using cached data');
      }
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误（必填参数未指定、参数类型错误、参数校验失败） | 检查参数类型和取值范围，确保必填参数已提供 |
| 16500050 | IPC连接错误 | 检查FormExtensionAbility是否正常运行，避免引用不支持模块 |
| 16500060 | 服务连接错误 | 检查系统服务状态，重启应用或设备 |
| 16500100 | 无法获取配置信息 | 检查module.json5和form_config.json配置文件是否正确 |
| 16501000 | 内部功能错误 | 检查代码逻辑，避免在FormExtensionAbility中执行长时间任务 |
| 16501001 | 卡片ID不存在 | 检查formId是否正确，确保卡片实例已创建 |
| 16501002 | 卡片数量超过上限 | 减少卡片实例数量，清理已销毁的卡片数据 |
| 16501003 | 卡片无法被当前应用操作 | 检查应用权限和卡片归属关系 |
| 16501011 | 卡片不支持此操作 | 检查卡片类型和操作类型是否匹配 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.FormKit": "^9.0.0",
    "@kit.AbilityKit": "^9.0.0",
    "@kit.ArkData": "^9.0.0",
    "@kit.BasicServicesKit": "^9.0.0",
    "@kit.PerformanceAnalysisKit": "^9.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK：最低API version 9
- DevEco Studio：最新版本（推荐使用DevEco Studio服务卡片模板）
- 模型约束：仅支持Stage模型

### 常见编译问题

**问题1：FormExtensionAbility引用不支持模块**
```
Error: Cannot import '@ohos.multimedia.audio' in FormExtensionAbility
```
**解决方法**：移除不支持模块的引用，仅使用FormKit、AbilityKit、ArkData、BasicServicesKit、PerformanceAnalysisKit

**问题2：卡片配置文件路径错误**
```
Error: Failed to load form_config.json
```
**解决方法**：确保form_config.json放在resources/base/profile/目录下，metadata中resource字段格式为$profile:form_jscard_config

**问题3：卡片页面文件找不到**
```
Error: Cannot find './js/WidgetJS/pages/index/index'
```
**解决方法**：确保HML/CSS/JSON文件路径与form_config.json中src字段一致，使用相对路径

**问题4：生命周期超时**
```
Error: FormExtensionAbility cleaned after 10 seconds
```
**解决方法**：避免在生命周期回调中执行长时间任务，使用异步操作并快速返回结果

## 常见问题与解决方法

### Q1：如何正确持久化卡片信息？
**原因**：卡片提供方不是常驻服务，需要持久化卡片数据以便后续获取和更新
**解决方法**：
- 使用preferences轻量级数据存储
- 按照卡片ID（formId）进行数据存储
- 存储卡片名称（formName）、临时标记（tempFlag）、更新次数（updateCount）等关键信息
- 使用/el2/base/haps/目录作为存储路径

### Q2：如何处理临时卡片和常态卡片？
**原因**：临时卡片不会持久化，需要特殊处理清理逻辑和转换逻辑
**解决方法**：
- 在onAddForm中根据tempFlag字段区分临时卡片和常态卡片
- 实现临时卡片清理逻辑（定时清理长时间未删除的临时卡片数据）
- 在onCastToNormalForm中处理临时卡片转换为常态卡片的逻辑
- 防止已转换的临时卡片被误删

### Q3：如何实现卡片定时/定点刷新？
**原因**：卡片支持周期性刷新，需要配置刷新策略
**解决方法**：
- 在form_config.json中配置updateEnabled为true
- 配置scheduledUpdateTime（定点刷新，24小时制）或updateDuration（定时刷新，单位30分钟）
- updateDuration优先级高于scheduledUpdateTime
- 在onUpdateForm中实现数据获取和更新逻辑

### Q4：如何处理卡片点击事件？
**原因**：卡片需要响应用户点击操作，跳转UIAbility或执行自定义逻辑
**解决方法**：
- 在JSON文件中配置actions字段
- router事件：设置action为"router"，指定abilityName和params
- message事件：设置action为"message"，传递自定义参数
- 在UIAbility的onCreate中接收router事件参数（want.parameters.params）
- 在FormExtensionAbility的onFormEvent中接收message事件参数（message字段）

### Q5：如何处理卡片数据嵌套更新？
**原因**：FormBindingData支持多级嵌套数据，但更新时需要传递完整数据
**解决方法**：
- 在创建卡片时定义完整的数据结构（包含所有嵌套字段）
- 更新卡片时传递完整的嵌套数据，不能只传递单个字段
- 示例：更新teacher.name时，需要传递完整的teacher对象（name + course）

### Q6：FormExtensionAbility生命周期限制如何应对？
**原因**：FormExtensionAbility创建后10秒内无操作将被清理，无法执行长时间任务
**解决方法**：
- 避免在生命周期回调中执行网络请求、文件读写等长时间操作
- 使用异步操作快速返回结果
- 将长时间任务放在UIAbility或其他组件中执行
- 使用定时刷新机制（scheduledUpdateTime或updateDuration）定期更新卡片

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "cardType": "JS Widget (Stage Model)",
  "apiUsed": [
    "FormExtensionAbility.onAddForm",
    "FormExtensionAbility.onUpdateForm",
    "FormExtensionAbility.onRemoveForm",
    "FormExtensionAbility.onFormEvent",
    "formBindingData.createFormBindingData",
    "formProvider.updateForm",
    "preferences.getPreferences",
    "preferences.put",
    "preferences.delete"
  ],
  "cardConfig": {
    "formName": "WidgetJS",
    "defaultDimension": "2*2",
    "supportDimensions": ["2*2"],
    "updateEnabled": true,
    "scheduledUpdateTime": "10:30",
    "updateDuration": 1
  },
  "cardFeatures": [
    "卡片生命周期管理",
    "数据持久化",
    "数据交互",
    "HML+CSS+JSON页面开发",
    "router和message事件处理"
  ]
}
```

## 参考文档

- [JS卡片开发指导（Stage模型）](references/js-ui-widget-development.md)
- [FormExtensionAbility API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formextensionability)
- [formProvider API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formprovider)
- [formBindingData API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formbindingdata)
- [Stage模型概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/stage-model-development-overview)
- [配置module.json5](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/module-configuration-file)
- [应用数据持久化概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-data-persistence-overview)

## 完整示例代码

- [FormExtensionAbility完整示例](assets/JsCardFormAbility.ets)
- [卡片配置文件示例](assets/form_jscard_config.json)
- [module.json5配置示例](assets/module.json5)
- [卡片HML页面示例](assets/index.hml)
- [卡片CSS样式示例](assets/index.css)
- [卡片JSON数据示例](assets/index.json)
- [UIAbility接收事件示例](assets/EntryAbility.ets)

## 测试用例

### 正向测试用例
- [创建JS卡片成功](tests/test_positive.js)：验证onAddForm返回正确的FormBindingData
- [更新卡片数据成功](tests/test_positive.js)：验证onUpdateForm正确更新卡片显示
- [处理router事件成功](tests/test_positive.js)：验证点击卡片跳转UIAbility
- [处理message事件成功](tests/test_positive.js)：验证点击卡片触发自定义事件
- [持久化卡片数据成功](tests/test_positive.js)：验证preferences正确存储卡片信息

### 边界测试用例
- [卡片生命周期10秒限制](tests/test_boundary.js)：验证超过10秒FormExtensionAbility被清理
- [最大图片数量限制](tests/test_boundary.js)：验证超过20张图片（API version 20）或5张图片（API version 19）显示异常
- [最大数据大小限制](tests/test_boundary.js)：验证超过10MB数据（API version 20）刷新失败
- [最小刷新时间限制](tests/test_boundary.js)：验证setFormNextRefreshTime小于5分钟返回错误
- [多级嵌套数据更新](tests/test_boundary.js)：验证部分嵌套字段更新导致数据丢失

### 异常测试用例
- [引用不支持模块](tests/test_exception.js)：验证引用音频、相机等模块导致程序异常退出
- [卡片ID不存在](tests/test_exception.js)：验证使用无效formId返回16501001错误码
- [持久化路径错误](tests/test_exception.js)：验证使用错误路径导致preferences.getPreferences失败
- [卡片配置文件缺失](tests/test_exception.js)：验证form_config.json不存在返回16500100错误码
- [卡片数量超限](tests/test_exception.js)：验证超过最大卡片数量返回16501002错误码