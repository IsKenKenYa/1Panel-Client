---
name: hmos-form-kit-js-widget-fa
description: 实现FA模型JS卡片的生命周期管理、数据绑定和页面开发，支持FormAbility生命周期接口、FormProvider数据更新、FormBindingData数据绑定，FA模型从API version 7开始支持已不再主推，适用于桌面卡片开发、服务卡片数据展示场景
---

# JS卡片开发指导（FA模型）技能

## 功能描述

本技能提供FA模型JS卡片开发的完整实现方案，包括卡片生命周期管理、数据绑定、页面开发和事件处理。FA模型通过导出匿名对象、固定入口文件的方式指定应用组件，开发者无法进行派生，不利于扩展能力。

**核心能力**：
- 实现FormAbility生命周期接口（onCreate、onUpdate、onEvent等）
- 使用FormProvider更新卡片数据
- 使用FormBindingData创建数据绑定对象
- 开发JS卡片页面（HML+CSS+JSON）
- 实现卡片事件（router事件和message事件）

**技术特点**：
- FA模型从API version 7开始支持
- 使用类Web范式（HML+CSS+JSON）开发卡片页面
- 支持卡片信息持久化管理
- 支持定时更新和定点更新

**重要提示**：
FA模型已不再主推，建议使用新的Stage模型进行开发。

## 使用场景

### 触发词
- "开发FA模型JS卡片"
- "实现FormAbility生命周期"
- "JS卡片开发"
- "FA卡片数据更新"
- "卡片页面开发"
- "卡片事件处理"

### 能做
- 实现FA模型的FormAbility生命周期接口
- 使用FormProvider API更新卡片数据
- 创建FormBindingData数据绑定对象
- 开发HML+CSS+JSON卡片页面
- 实现router事件和message事件
- 配置卡片配置文件（config.json）
- 持久化管理卡片信息

### 绝不做
- 不适用于Stage模型卡片开发（应使用FormExtensionAbility）
- 不处理ArkTS卡片开发（应使用声明式范式）
- 不支持常驻后台任务（FormAbility不能常驻后台）
- 不处理超过刷新限制的图片数据（API version 19及之前：图片文件数量上限5张，每张限制2MB；API version 20：数据总大小不超过10MB，图片数量不超过20张）

### 补充
- FA模型已不再主推，仅适用于已有FA模型项目的维护
- FormAbility不能常驻后台，在生命周期回调函数中无法处理长时间任务
- 临时卡片需要自行清理长时间未删除的数据
- 建议新项目使用Stage模型开发

## 调用规范和规则

### 输入约束
- 卡片ID（formId）：必须为有效的字符串标识
- 卡片数据：支持Object或JSON字符串格式
- 更新时间：minute参数必须大于等于5分钟
- 图片数据：API version 19及之前最多5张图片，每张不超过2MB；API version 20最多20张图片，总大小不超过10MB
- 页面文件：HML、CSS、JSON文件必须符合类Web范式规范

### 执行约束
- 最大刷新时间间隔：最短5分钟
- FormAbility生命周期回调：无法处理长时间任务
- 图片刷新限制：遵守版本对应的图片数量和大小限制
- 持久化操作：必须在onCreate时存储卡片信息，onDestroy时删除卡片信息

### 内容约束
- 禁止在生命周期回调中执行长时间任务
- 禁止使用不支持的API（Stage模型API）
- 禁止使用高危函数（eval、exec等）
- 禁止超过图片刷新限制
- 卡片页面必须使用类Web范式（HML+CSS+JSON），不支持声明式范式

### 降级约束
- 数据更新失败：记录错误日志，保留上次数据
- 图片加载失败：显示占位图或隐藏图片组件
- 持久化失败：使用临时存储或提示用户重新添加卡片
- 生命周期回调失败：记录错误日志，不影响其他卡片实例

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认项目使用FA模型（config.json配置）
2. 确认已安装必要的依赖模块（@ohos.app.form.formProvider、@ohos.app.form.formBindingData等）
3. 确认卡片配置文件已正确配置（forms字段）
4. 确认JS模块已正确配置（type为"form"）

**导入模块**：
```typescript
import type featureAbility from '@ohos.ability.featureAbility';
import type Want from '@ohos.app.ability.Want';
import formBindingData from '@ohos.app.form.formBindingData';
import formInfo from '@ohos.app.form.formInfo';
import formProvider from '@ohos.app.form.formProvider';
import dataPreferences from '@ohos.data.preferences';
import hilog from '@ohos.hilog';
```

### 步骤2：实现FormAbility生命周期接口

**生命周期接口**：
```typescript
const TAG: string = '[Sample_FAModelAbilityDevelop]';
const domain: number = 0xFF00;
const DATA_STORAGE_PATH: string = 'form_store';

// 持久化卡片信息
let storeFormInfo = async (formId: string, formName: string, tempFlag: boolean, context: featureAbility.Context): Promise<void> => {
  let formInfo: Record<string, string | number | boolean> = {
    'formName': 'formName',
    'tempFlag': 'tempFlag',
    'updateCount': 0
  };
  try {
    const storage = await dataPreferences.getPreferences(context, DATA_STORAGE_PATH);
    await storage.put(formId, JSON.stringify(formInfo));
    hilog.info(domain, TAG, `storeFormInfo, put form info successfully, formId: ${formId}`);
    await storage.flush();
  } catch (err) {
    hilog.error(domain, TAG, `failed to storeFormInfo, err: ${JSON.stringify(err as Error)}`);
  }
};

// 删除卡片信息
let deleteFormInfo = async (formId: string, context: featureAbility.Context) => {
  try {
    const storage = await dataPreferences.getPreferences(context, DATA_STORAGE_PATH);
    await storage.delete(formId);
    hilog.info(domain, TAG, `deleteFormInfo, del form info successfully, formId: ${formId}`);
    await storage.flush();
  } catch (err) {
    hilog.error(domain, TAG, `failed to deleteFormInfo, err: ${JSON.stringify(err)}`);
  }
}

// FormAbility生命周期对象
let obj: LifeCycle = {
  onCreate(want: Want) {
    hilog.info(domain, TAG, 'FormAbility onCreate');
    if (want.parameters) {
      let formId = String(want.parameters['ohos.extra.param.key.form_identity']);
      let formName = String(want.parameters['ohos.extra.param.key.form_name']);
      let tempFlag = Boolean(want.parameters['ohos.extra.param.key.form_temporary']);
      storeFormInfo(formId, formName, tempFlag, this.context);
    }
    let obj: Record<string, string> = {
      'title': 'titleOnCreate',
      'detail': 'detailOnCreate'
    };
    let formData: formBindingData.FormBindingData = formBindingData.createFormBindingData(obj);
    return formData;
  },
  
  onUpdate(formId: string) {
    hilog.info(domain, TAG, 'FormAbility onUpdate');
    let obj: Record<string, string> = {
      'title': 'titleOnUpdate',
      'detail': 'detailOnUpdate'
    };
    let formData: formBindingData.FormBindingData = formBindingData.createFormBindingData(obj);
    formProvider.updateForm(formId, formData).catch((error: Error) => {
      hilog.error(domain, TAG, 'FormAbility updateForm, error:' + JSON.stringify(error));
    });
  },
  
  onEvent(formId: string, message: string) {
    let obj: Record<string, string> = {
      'title': 'titleOnEvent',
      'detail': 'detailOnEvent'
    };
    let formData: formBindingData.FormBindingData = formBindingData.createFormBindingData(obj);
    formProvider.updateForm(formId, formData).catch((error: Error) => {
      hilog.error(domain, TAG, 'FormAbility updateForm, error:' + JSON.stringify(error));
    });
    hilog.info(domain, TAG, 'FormAbility onEvent');
  },
  
  onDestroy(formId: string) {
    hilog.info(domain, TAG, 'FormAbility onDestroy');
    deleteFormInfo(formId, this.context);
  }
};

export default obj;
```

### 步骤3：配置卡片配置文件

**config.json配置**：
```json
{
  "js": [
    {
      "name": "widget",
      "pages": [
        "pages/index/index"
      ],
      "window": {
        "designWidth": 720,
        "autoDesignWidth": true
      },
      "type": "form"
    }
  ],
  "abilities": [
    {
      "name": ".FormAbility",
      "srcPath": "FormAbility",
      "description": "$string:FormAbility_desc",
      "icon": "$media:icon",
      "label": "$string:FormAbility_label",
      "type": "service",
      "formsEnabled": true,
      "srcLanguage": "ets",
      "forms": [
        {
          "jsComponentName": "widget",
          "isDefault": true,
          "scheduledUpdateTime": "10:30",
          "defaultDimension": "2*2",
          "name": "widget",
          "description": "This is a service widget.",
          "type": "JS",
          "formVisibleNotify": true,
          "supportDimensions": [
            "2*2"
          ],
          "updateEnabled": true,
          "updateDuration": 1
        }
      ]
    }
  ]
}
```

### 步骤4：开发卡片页面（HML+CSS+JSON）

**HML文件**：
```html
<div class="container">
    <stack>
        <div class="container-img">
            <image src="/common/widget.png" class="bg-img"></image>
            <image src="/common/rect.png" class="bottom-img"></image>
        </div>
        <div class="container-inner">
            <text class="title" onclick="routerEvent">{{title}}</text>
            <text class="detail_text" onclick="messageEvent">{{detail}}</text>
        </div>
    </stack>
</div>
```

**CSS文件**：
```css
.container {
    flex-direction: column;
    justify-content: center;
    align-items: center;
}
.bg-img {
    flex-shrink: 0;
    height: 100%;
    z-index: 1;
}
.bottom-img {
    position: absolute;
    width: 150px;
    height: 56px;
    top: 63%;
    background-color: rgba(216, 216, 216, 0.15);
    filter: blur(20px);
    z-index: 2;
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
    font-family: HarmonyHeiTi-Medium;
    font-size: 14px;
    color: rgba(255,255,255,0.90);
    letter-spacing: 0.6px;
}
.detail_text {
    font-family: HarmonyHeiTi;
    font-size: 12px;
    color: rgba(255,255,255,0.60);
    letter-spacing: 0.51px;
    text-overflow: ellipsis;
    max-lines: 1;
    margin-top: 6px;
}
```

**JSON文件**：
```json
{
  "data": {
    "title": "TitleDefault",
    "detail": "TextDefault"
  },
  "actions": {
    "routerEvent": {
      "action": "router",
      "abilityName": "com.samples.famodelabilitydevelop.MainAbility",
      "params": {
        "message": "add detail"
      }
    },
    "messageEvent": {
      "action": "message",
      "params": {
        "message": "add detail"
      }
    }
  }
}
```

### 步骤5：错误处理

**错误处理代码**：
```typescript
try {
  formProvider.updateForm(formId, formData).then(() => {
    hilog.info(domain, TAG, 'formProvider updateForm success');
  }).catch((error: BusinessError) => {
    hilog.error(domain, TAG, `promise error, code: ${error.code}, message: ${error.message})`);
    // 根据错误码进行处理
    switch (error.code) {
      case 16501000:
        hilog.error(domain, TAG, 'An internal functional error occurred');
        break;
      case 16501001:
        hilog.error(domain, TAG, 'The ID of the form to be operated does not exist');
        break;
      case 16501003:
        hilog.error(domain, TAG, 'The form cannot be operated by the current application');
        break;
      default:
        hilog.error(domain, TAG, 'Unknown error occurred');
    }
  });
} catch (error) {
  hilog.error(domain, TAG, `catch error, code: ${(error as BusinessError).code}, message: ${(error as BusinessError).message})`);
}
```

### 步骤6：降级处理

**降级方案**：
```typescript
// 持久化失败降级方案
let storeFormInfoFallback = (formId: string, formName: string, tempFlag: boolean): void => {
  try {
    // 使用临时存储方案
    let tempStorage: Record<string, string | number | boolean> = {};
    tempStorage[formId] = JSON.stringify({
      'formName': formName,
      'tempFlag': tempFlag,
      'updateCount': 0
    });
    hilog.warn(domain, TAG, 'Using fallback storage for form info');
  } catch (error) {
    hilog.error(domain, TAG, 'Fallback storage also failed');
  }
};

// 数据更新失败降级方案
let updateFormFallback = async (formId: string): Promise<void> => {
  try {
    // 使用上次保存的数据
    hilog.warn(domain, TAG, 'Update failed, retaining last data');
  } catch (error) {
    hilog.error(domain, TAG, 'Fallback update failed');
  }
};
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：1.必填参数未指定；2.参数类型不正确；3.参数验证失败 | 检查参数类型和取值范围，确保必填参数已正确填写 |
| 16500050 | IPC连接错误 | 检查IPC连接状态，重启应用或设备 |
| 16500060 | 服务连接错误 | 检查服务连接状态，确认卡片管理服务是否正常运行 |
| 16500100 | 无法获取配置信息 | 检查config.json配置文件是否正确配置了forms字段 |
| 16501000 | 内部功能错误 | 检查FormAbility生命周期实现，确保逻辑正确 |
| 16501001 | 操作的卡片ID不存在 | 确认formId是否正确，检查卡片是否已被删除 |
| 16501002 | 卡片数量超过最大允许数量 | 减少卡片实例数量，清理不必要的卡片 |
| 16501003 | 当前应用无法操作该卡片 | 确认卡片归属，只能操作当前应用的卡片 |
| 16501011 | 卡片不支持此操作 | 确认卡片配置，检查是否支持该功能 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.FormKit": "latest",
    "@kit.AbilityKit": "latest",
    "@kit.BasicServicesKit": "latest",
    "@kit.CoreFileKit": "latest"
  }
}
```

### 环境要求
- HarmonyOS API version 7及以上
- DevEco Studio 3.0及以上
- ArkTS语言支持
- FA模型项目配置

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@ohos.app.form.formProvider'
```
**解决方法**：确保项目已正确配置HarmonyOS SDK，检查build-profile.json5中的compileSdkVersion

**问题2：config.json配置错误**
```
Error: Form configuration is invalid
```
**解决方法**：检查forms字段配置，确保jsComponentName与js模块name一致，type设置为"JS"

**问题3：卡片页面加载失败**
```
Error: Failed to load widget page
```
**解决方法**：检查HML、CSS、JSON文件路径是否正确，确保页面文件符合类Web范式规范

## 常见问题与解决方法

### Q1：FormAbility无法常驻后台怎么办？
**原因**：FormAbility生命周期回调函数无法处理长时间任务
**解决方法**：
- 将长时间任务分解为短时间任务
- 使用定时更新机制（updateDuration或scheduledUpdateTime）
- 在onUpdate回调中快速处理数据更新

### Q2：临时卡片数据如何清理？
**原因**：临时卡片在卡片管理服务中删除后，提供方不会收到通知
**解决方法**：
- 在onCreate时判断tempFlag参数
- 定期检查临时卡片数据的创建时间
- 清理超过一定时间未删除的临时卡片数据

### Q3：卡片图片加载异常怎么办？
**原因**：超出图片数量或大小限制
**解决方法**：
- API version 19及之前：图片数量不超过5张，每张不超过2MB
- API version 20：图片数量不超过20张，总大小不超过10MB
- 使用压缩图片或占位图替代

### Q4：如何处理卡片多实例问题？
**原因**：卡片管理服务支持多实例管理，每个卡片实例有独立的formId
**解决方法**：
- 在onCreate时根据formId持久化卡片信息
- 在onUpdate、onEvent等回调中根据formId区分不同实例
- 在onDestroy时删除对应的卡片实例数据

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "formId": "卡片ID",
  "formName": "卡片名称",
  "updateCount": "更新次数",
  "apiUsed": [
    "formBindingData.createFormBindingData",
    "formProvider.updateForm",
    "formProvider.setFormNextRefreshTime"
  ],
  "configuration": {
    "jsComponentName": "widget",
    "defaultDimension": "2*2",
    "supportDimensions": ["2*2"],
    "updateEnabled": true,
    "updateDuration": 1
  }
}
```

## 参考文档

- [JS卡片开发指导（FA模型）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/widget-development-fa)
- [@ohos.app.form.formProvider (formProvider)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formprovider)
- [@ohos.app.form.formBindingData (卡片数据绑定类)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formbindingdata)

## 完整示例代码

- [ArkTS示例代码](assets/form_ability_example.ets)
- [HML页面示例](assets/widget_page.hml)
- [CSS样式示例](assets/widget_style.css)
- [JSON数据示例](assets/widget_data.json)
- [config.json配置示例](assets/config_example.json)

## 测试用例

### 正向测试用例
- [创建JS卡片实例](tests/test_positive.py)：测试onCreate生命周期和数据绑定
- [更新卡片数据](tests/test_positive.py)：测试onUpdate生命周期和formProvider.updateForm
- [处理卡片事件](tests/test_positive.py)：测试onEvent生命周期和message事件处理

### 边界测试用例
- [最大图片数量测试](tests/test_boundary.py)：测试图片数量达到上限时的处理
- [最短刷新时间测试](tests/test_boundary.py)：测试setFormNextRefreshTime的minute参数为5分钟
- [卡片配置边界测试](tests/test_boundary.py)：测试config.json中各项配置的边界值

### 异常测试用例
- [无效卡片ID测试](tests/test_exception.py)：测试formId不存在时的错误处理
- [持久化失败测试](tests/test_exception.py)：测试dataPreferences存储失败时的降级方案
- [图片加载失败测试](tests/test_exception.py)：测试图片文件不存在或格式错误时的处理