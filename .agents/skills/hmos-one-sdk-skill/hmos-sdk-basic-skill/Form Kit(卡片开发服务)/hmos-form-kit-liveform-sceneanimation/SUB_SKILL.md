---
name: hmos-form-kit-liveform-sceneanimation
description: 开发场景动效类型互动卡片，支持卡片非激活态和激活态UI界面开发、动效请求和取消，仅支持API version 20+，适用于卡片破框动效、场景化卡片交互场景
---

# 场景动效类型互动卡片开发技能

## 功能描述

本技能提供场景动效类型互动卡片的完整开发能力，包括卡片非激活态和激活态UI界面开发、卡片配置文件开发、互动卡片动效请求和取消等功能。场景动效类型互动卡片是指卡片在特定场景下能够突破卡片边界，展示超出卡片原有尺寸范围的动效内容，提供更丰富的交互体验。

**核心能力**：
- 创建LiveFormExtensionAbility，实现互动卡片生命周期管理
- 开发卡片激活态和非激活态UI界面
- 配置form_config.json文件中的sceneAnimationParams参数
- 触发和取消互动卡片动效
- 查询卡片位置和尺寸信息
- 拉起卡片提供方应用页面

**技术特点**：
- 基于LiveFormExtensionAbility实现卡片扩展能力
- 支持系统默认切换动效或自定义动效
- 动效持续时间最长3500ms
- 动效区域可超出卡片边界
- 仅支持API version 20及以上版本

## 使用场景

### 触发词
- "开发场景动效互动卡片"
- "实现卡片破框动效"
- "互动卡片动效开发"
- "LiveFormExtensionAbility"
- "requestOverflow"
- "cancelOverflow"
- "卡片超范围显示"

### 能做
- 创建LiveFormExtensionAbility扩展能力类
- 实现onLiveFormCreate和onLiveFormDestroy生命周期回调
- 开发卡片激活态UI页面（超出卡片边界的动效界面）
- 开发卡片非激活态UI页面（正常卡片界面）
- 配置form_config.json的sceneAnimationParams参数
- 通过formProvider.requestOverflow发起动效请求
- 通过formProvider.cancelOverflow取消动效请求
- 通过formProvider.getFormRect获取卡片位置和尺寸
- 通过startAbilityByLiveForm拉起应用页面
- 实现卡片点击触发动效的交互逻辑
- 实现动效过程中的动画效果

### 绝不做
- 不支持API version 20以下版本的卡片开发
- 不支持非场景动效类型的普通卡片开发
- 不处理JS卡片的开发（仅支持ArkTS卡片）
- 不提供卡片数据更新相关功能（使用formProvider.updateForm）
- 不处理卡片管理相关功能（使用formProvider.openFormManager）
- 不处理静态卡片开发

### 补充
- **API版本要求**：仅支持API version 20及以上版本，元服务从API version 20开始支持
- **模型约束**：仅可在Stage模型下使用
- **系统能力**：需要SystemCapability.Ability.Form系统能力
- **热档位限制**：在省电模式和设备过热场景下，动效请求可能失败（错误码16501000）
- **权限限制**：只能拉起卡片提供方应用页面，不能拉起其他应用页面
- **调用时机**：startAbilityByLiveForm必须在点击事件回调中直接调用，不支持延时调用
- **动效约束**：动效持续时间不超过3500ms，动效区域需要合理计算

## 调用规范和规则

### 输入约束
- **API版本**：必须使用API version 20及以上版本
- **卡片尺寸**：仅支持已添加到桌面的卡片，不支持临时卡片
- **动效时长**：duration参数必须大于0且不超过3500ms
- **动效区域**：overflowInfo.area参数必须合理计算，避免过大或负值
- **formId**：必须是有效的卡片标识符（字符串格式）
- **Want参数**：startAbilityByLiveForm仅支持显式Want，必须提供bundleName和abilityName

### 执行约束
- **动效触发**：必须在点击事件回调中触发动效，不支持其他手势事件或非手势事件
- **调用时机**：startAbilityByLiveForm必须在点击事件回调中直接调用，不支持延时调用（setTimeout等）
- **动效持续时间**：单次动效最长3500ms
- **并发限制**：同一卡片同时只能有一个动效在进行
- **热档位限制**：设备进入OVERHEATED热档位时，动效请求会失败
- **省电模式限制**：省电模式下动效请求会失败

### 内容约束
- **禁止使用**：不允许调用FormKit的废弃接口（如getPublishedFormInfoById）
- **禁止操作**：不允许在动效过程中修改卡片配置或删除卡片
- **禁止拉起**：不允许通过startAbilityByLiveForm拉起其他应用的页面
- **禁止延时**：不允许在setTimeout或异步回调中调用startAbilityByLiveForm
- **界面一致性**：useDefaultAnimation=false时，非激活态和激活态UI必须完全一致

### 降级约束
- **动效失败**：动效请求失败时（热档位、省电模式等），应降级为普通卡片点击行为
- **API版本低**：API version低于20时，提示用户升级系统版本
- **权限不足**：拉起页面失败时（错误码16501011），提示用户操作不支持
- **IPC错误**：IPC连接错误时（错误码16500050），建议用户稍后重试
- **卡片不存在**：卡片不存在时（错误码16501001），建议用户重新添加卡片

## 调用流程和步骤

### 步骤1：准备阶段（创建LiveFormExtensionAbility）

**前置校验**：
1. 确认项目API版本不低于20
2. 确认使用Stage模型开发
3. 确认已导入必要的Kit：@kit.FormKit、@kit.AbilityKit

**创建LiveFormExtensionAbility**：
```arkts
import { formInfo, LiveFormInfo, LiveFormExtensionAbility } from '@kit.FormKit';
import { UIExtensionContentSession } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'LiveFormExtAbility';

export default class MyLiveFormExtensionAbility extends LiveFormExtensionAbility {
  onLiveFormCreate(liveFormInfo: LiveFormInfo, session: UIExtensionContentSession) {
    hilog.info(DOMAIN, TAG, `onLiveFormCreate, formId: ${liveFormInfo.formId}`);
    
    let storage: LocalStorage = new LocalStorage();
    storage.setOrCreate('context', this.context);
    storage.setOrCreate('session', session);
    storage.setOrCreate('formId', liveFormInfo.formId);
    storage.setOrCreate('borderRadius', liveFormInfo.borderRadius);
    storage.setOrCreate('formRect', liveFormInfo.rect);
    
    session.loadContent('myliveformextensionability/pages/MyLiveFormPage', storage);
  }
  
  onLiveFormDestroy(liveFormInfo: LiveFormInfo) {
    hilog.info(DOMAIN, TAG, `onLiveFormDestroy, formId: ${liveFormInfo.formId}`);
  }
}
```

### 步骤2：开发卡片激活态UI页面

**参数准备**：
```arkts
import { formInfo, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'MyLiveFormPage';

@Entry
@Component
struct MyLiveFormPage {
  @State columnScale: number = 1.0;
  @State columnTranslate: number = 0.0;
  private uiContext: UIContext | undefined = undefined;
  private storageForMyLiveFormPage: LocalStorage | undefined = undefined;
  private formId: string | undefined = undefined;
  private formRect: formInfo.Rect | undefined = undefined;
  private formBorderRadius: number | undefined = undefined;
  private liveFormContext: common.LiveFormExtensionContext | undefined = undefined;
  
  aboutToAppear(): void {
    this.uiContext = this.getUIContext();
    if (!this.uiContext) {
      hilog.error(DOMAIN, TAG, 'no uiContext');
      return;
    }
    this.initParams();
  }
  
  private initParams(): void {
    this.storageForMyLiveFormPage = this.uiContext?.getSharedLocalStorage();
    this.formId = this.storageForMyLiveFormPage?.get<string>('formId');
    this.formRect = this.storageForMyLiveFormPage?.get<formInfo.Rect>('formRect');
    this.formBorderRadius = this.storageForMyLiveFormPage?.get<number>('borderRadius');
    this.liveFormContext = this.storageForMyLiveFormPage?.get<common.LiveFormExtensionContext>('context');
  }
}
```

**执行动效**：
```arkts
private runAnimation(): void {
  this.uiContext?.animateTo({
    duration: 3500,
    curve: Curve.Ease
  }, () => {
    this.columnScale = 1.5;
    this.columnTranslate = -300;
  });
}
```

**拉起应用页面**：
```arkts
private startAbilityByLiveForm(): void {
  try {
    this.liveFormContext?.startAbilityByLiveForm({
      bundleName: 'com.samples.formlivedemo',
      abilityName: 'EntryAbility',
    })
      .then(() => {
        hilog.info(DOMAIN, TAG, 'startAbilityByLiveForm succeed');
      })
      .catch((err: BusinessError) => {
        hilog.error(DOMAIN, TAG, 
          `startAbilityByLiveForm failed, code: ${err?.code}, message: ${err?.message}`);
      });
  } catch (e) {
    hilog.error(DOMAIN, TAG, 
      `startAbilityByLiveForm failed, code: ${e?.code}, message: ${e?.message}`);
  }
}
```

**取消动效**：
```arkts
Button($r('app.string.button_cancel'))
  .backgroundColor(Color.Grey)
  .onClick(() => {
    if (!this.formId) {
      hilog.info(DOMAIN, TAG, 'formId is empty, cancel overflow failed');
      return;
    }
    hilog.info(DOMAIN, TAG, 'cancel overflow animation');
    formProvider.cancelOverflow(this.formId);
  })
```

### 步骤3：开发卡片非激活态UI页面

**非激活态卡片页面**：
```arkts
@Entry
@Component
struct WidgetCard {
  build() {
    Row() {
      Column() {
        Text($r('app.string.liveform_click1'))
          .fontSize($r('app.float.font_size'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
      .width('100%')
    }
    .height('100%')
    .onClick(() => {
      postCardAction(this, {
        action: 'message',
        abilityName: 'EntryFormAbility',
        params: {
          message: 'requestOverflow'
        }
      });
    })
  }
}
```

### 步骤4：配置form_config.json

**配置sceneAnimationParams**：
```json
{
  "forms": [
    {
      "name": "widget",
      "displayName": "$string:widget_display_name",
      "description": "$string:widget_desc",
      "src": "./ets/widget/pages/WidgetCard.ets",
      "uiSyntax": "arkts",
      "window": {
        "designWidth": 720,
        "autoDesignWidth": true
      },
      "colorMode": "auto",
      "isDefault": true,
      "updateEnabled": true,
      "scheduledUpdateTime": "10:30",
      "updateDuration": 1,
      "defaultDimension": "2*2",
      "supportDimensions": ["2*2"],
      "formConfigAbility": "ability://EntryAbility",
      "dataProxyEnabled": false,
      "isDynamic": true,
      "transparencyEnabled": false,
      "metadata": [],
      "sceneAnimationParams": {
        "abilityName": "MyLiveFormExtensionAbility"
      }
    }
  ]
}
```

### 步骤5：触发互动卡片动效

**获取卡片位置和尺寸**：
```arkts
import { FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'EntryFormAbility';
const DOMAIN_NUMBER = 0xFF00;

export default class EntryFormAbility extends FormExtensionAbility {
  async onFormEvent(formId: string, message: string) {
    let shortMessage: string = JSON.parse(message)['message'];
    
    if (shortMessage === 'requestOverflow') {
      try {
        let formRect: formInfo.Rect = await formProvider.getFormRect(formId);
        this.requestOverflow(formId, formRect.width, formRect.height);
      } catch (error) {
        hilog.error(DOMAIN_NUMBER, TAG, 
          `getFormRect failed, code: ${(error as BusinessError).code}`);
      }
    }
  }
  
  private requestOverflow(formId: string, formWidth: number, formHeight: number): void {
    if (formWidth <= 0 || formHeight <= 0) {
      hilog.info(DOMAIN_NUMBER, TAG, 'form size is not correct.');
      return;
    }
    
    let left: number = -0.1 * formWidth;
    let top: number = -0.15 * formHeight;
    let width: number = 1.2 * formWidth;
    let height: number = 1.3 * formHeight;
    let duration: number = 3500;
    
    try {
      formProvider.requestOverflow(formId, {
        area: {
          left: left,
          top: top,
          width: width,
          height: height
        },
        duration: duration,
        useDefaultAnimation: true,
      }).then(() => {
        hilog.info(DOMAIN_NUMBER, TAG, 'requestOverflow succeed');
      }).catch((error: BusinessError) => {
        hilog.error(DOMAIN_NUMBER, TAG, 
          `requestOverflow failed, code: ${error.code}, message: ${error.message}`);
      });
    } catch (e) {
      hilog.error(DOMAIN_NUMBER, TAG, 
        `requestOverflow failed, code: ${e.code}, message: ${e.message}`);
    }
  }
}
```

### 步骤6：配置module.json5

**声明LiveFormExtensionAbility**：
```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": ["default", "tablet"],
    "deliveryWithInstall": true,
    "installationFree": false,
    "virtualMachine": "ark",
    "extensionAbilities": [
      {
        "name": "MyLiveFormExtensionAbility",
        "srcEntry": "./ets/myliveformextensionability/MyLiveFormExtensionAbility.ets",
        "description": "MyLiveFormExtensionAbility",
        "type": "liveForm"
      }
    ]
  }
}
```

### 步骤7：配置main_pages.json

**声明互动卡片页面**：
```json
{
  "src": [
    "pages/Index",
    "myliveformextensionability/pages/MyLiveFormPage"
  ]
}
```

### 步骤8：错误处理

**错误码处理**：
```arkts
try {
  await formProvider.requestOverflow(formId, overflowInfo);
} catch (error) {
  const err = error as BusinessError;
  switch (err.code) {
    case 16501000:
      hilog.error(DOMAIN, TAG, 'Internal error or power saving mode');
      break;
    case 16501001:
      hilog.error(DOMAIN, TAG, 'Form does not exist');
      break;
    case 16501011:
      hilog.error(DOMAIN, TAG, 'Operation not supported');
      break;
    case 16500050:
      hilog.error(DOMAIN, TAG, 'IPC connection error');
      break;
    default:
      hilog.error(DOMAIN, TAG, `Unknown error: ${err.code}`);
  }
}
```

### 步骤9：降级处理

**动效失败降级**：
```arkts
private requestOverflowWithFallback(formId: string, formWidth: number, formHeight: number): void {
  formProvider.requestOverflow(formId, {
    area: { left: -10, top: -10, width: 180, height: 180 },
    duration: 1000,
    useDefaultAnimation: true,
  }).then(() => {
    hilog.info(DOMAIN, TAG, 'requestOverflow succeed');
  }).catch((error: BusinessError) => {
    hilog.warn(DOMAIN, TAG, 'Animation request failed, fallback to normal click');
    this.fallbackToNormalClick();
  });
}

private fallbackToNormalClick(): void {
  hilog.info(DOMAIN, TAG, 'Using normal click behavior without animation');
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 801 | 设备能力不支持 | 检查设备是否支持场景动效功能，提示用户更换设备 |
| 401 | 参数错误 | 检查参数类型和取值范围，确保参数正确 |
| 16500050 | IPC连接错误 | 建议用户稍后重试，检查系统服务是否正常 |
| 16500060 | 服务连接错误 | 检查FormKit服务是否正常运行 |
| 16500100 | 获取配置信息失败 | 检查form_config.json配置是否正确 |
| 16501000 | 内部功能错误或省电模式限制 | 检查设备是否在省电模式，或设备热档位是否过高 |
| 16501001 | 卡片不存在 | 提示用户重新添加卡片到桌面 |
| 16501003 | 当前应用无法操作卡片 | 检查卡片是否属于当前应用 |
| 16501011 | 操作不支持 | 检查是否在正确的事件回调中调用接口，或是否尝试拉起其他应用 |
| 16501007 | 卡片不可信 | 检查卡片签名和权限配置 |

**特殊错误处理**：
- **省电模式**：错误码16501000，动效请求会失败，需降级为普通点击行为
- **热档位OVERHEATED**：错误码16501000，任何情况下都会失败
- **热档位HOT（无点击事件）**：错误码16501000，会失败
- **延时调用startAbilityByLiveForm**：错误码16501011，必须在点击回调中直接调用
- **拉起其他应用**：错误码16501011，只能拉起卡片提供方应用

## 编译和修复问题

### 依赖声明

**oh-package.json5**：
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
- **DevEco Studio**：建议使用最新版本
- **HarmonyOS SDK**：API version 20及以上
- **编译模式**：Stage模型
- **目标设备**：支持Form Kit的设备（手机、平板等）

### 常见编译问题

**问题1：导入模块错误**
```
Error: Cannot find module '@kit.FormKit'
```
**解决方法**：
1. 确认HarmonyOS SDK版本不低于API 20
2. 在DevEco Studio中重新下载SDK
3. 检查oh-package.json5中的依赖声明

**问题2：LiveFormExtensionAbility找不到**
```
Error: 'LiveFormExtensionAbility' is not defined
```
**解决方法**：
1. 确认导入语句：`import { LiveFormExtensionAbility } from '@kit.FormKit';`
2. 确认API版本不低于20
3. 确认使用Stage模型

**问题3：module.json5配置错误**
```
Error: extensionAbility type 'liveForm' is not supported
```
**解决方法**：
1. 确认API版本不低于20
2. 确认module.json5中extensionAbilities配置正确
3. 确认type字段值为"liveForm"

**问题4：form_config.json配置错误**
```
Error: 'sceneAnimationParams' field is not recognized
```
**解决方法**：
1. 确认API版本不低于20
2. 确认form_config.json格式正确
3. 确认sceneAnimationParams字段位置正确（在forms数组内）

**问题5：页面路径错误**
```
Error: Cannot find page 'myliveformextensionability/pages/MyLiveFormPage'
```
**解决方法**：
1. 确认页面文件存在且路径正确
2. 确认main_pages.json中已声明该页面路径
3. 确认文件名和路径大小写一致

**问题6：LocalStorage获取失败**
```
Error: getSharedLocalStorage() returns undefined
```
**解决方法**：
1. 确认使用this.getUIContext().getSharedLocalStorage()
2. 确认在aboutToAppear中调用
3. 确认UIContext已正确初始化

## 常见问题与解决方法

### Q1：动效请求总是失败（错误码16501000）
**原因**：
1. 设备处于省电模式
2. 设备热档位过高（OVERHEATED或HOT且无点击事件）
3. formId无效或卡片已被删除

**解决方法**：
- 检查设备是否在省电模式，提示用户关闭省电模式
- 检查设备热档位，等待设备降温后重试
- 通过formProvider.getFormRect验证卡片是否存在
- 实现降级方案：动效失败时使用普通点击行为

### Q2：startAbilityByLiveForm调用失败（错误码16501011）
**原因**：
1. 在非点击事件回调中调用
2. 在setTimeout或异步回调中延时调用
3. 尝试拉起其他应用的页面
4. LiveFormExtensionContext未正确初始化

**解决方法**：
- 确保在onClick等点击事件回调中直接调用
- 不要使用setTimeout延时调用
- 只拉起卡片提供方应用的页面（bundleName和abilityName必须是当前应用）
- 在aboutToAppear中正确初始化LiveFormExtensionContext

### Q3：卡片点击后没有触发动效
**原因**：
1. postCardAction消息未正确发送
2. EntryFormAbility的onFormEvent未正确处理消息
3. formProvider.requestOverflow参数错误
4. 卡片未配置sceneAnimationParams

**解决方法**：
- 检查postCardAction参数：action、abilityName、params
- 确认EntryFormAbility中onFormEvent正确解析message
- 确认requestOverflow参数：area、duration、useDefaultAnimation
- 检查form_config.json中sceneAnimationParams配置

### Q4：动效区域计算错误
**原因**：
1. 动效区域超出卡片边界过多
2. left、top参数为正值（应在卡片左上角为原点的坐标系中）
3. width、height参数过大或为负值
4. 未正确获取卡片尺寸信息

**解决方法**：
- 使用formProvider.getFormRect获取准确的卡片尺寸
- 合理计算动效区域：left和top应为负值或小正值
- 遵循动效参数约束：宽度不超过卡片宽度的2倍，高度不超过卡片高度的2倍
- 参考示例中的比例计算方法

### Q5：激活态UI和非激活态UI不一致导致切换异常
**原因**：
1. useDefaultAnimation=false时，UI界面不一致
2. 背景组件尺寸不匹配
3. 动效过程中UI元素位置错乱

**解决方法**：
- 当useDefaultAnimation=false时，确保非激活态和激活态UI完全一致
- 使用formRect参数正确设置背景组件尺寸和位置
- 在动效过程中使用scale和translate等变换保持UI一致性
- 参考示例中的背景组件实现方法

### Q6：编译时提示API version不支持
**原因**：
1. 项目配置的API version低于20
2. DevEco Studio SDK版本过低
3. module.json5中未正确配置API version

**解决方法**：
- 在build-profile.json5中设置compileSdkVersion和compatibleSdkVersion不低于20
- 在DevEco Studio中下载API 20及以上版本的SDK
- 在module.json5中确认无API version限制

### Q7：页面加载失败或显示异常
**原因**：
1. LocalStorage未正确传递参数
2. 页面路径未在main_pages.json中声明
3. 资源文件缺失（string.json等）
4. borderRadius或formRect参数错误

**解决方法**：
- 在onLiveFormCreate中正确设置LocalStorage参数
- 确认main_pages.json中已声明页面路径
- 在resources/base/element/string.json中定义必要的字符串资源
- 确认liveFormInfo参数正确传递（formId、rect、borderRadius）

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "skillName": "hmos-form-kit-liveform-sceneanimation",
  "apiVersion": "20+",
  "moduleType": "Stage",
  "systemCapability": "SystemCapability.Ability.Form",
  "featuresImplemented": [
    "LiveFormExtensionAbility创建和生命周期管理",
    "卡片激活态UI开发",
    "卡片非激活态UI开发",
    "动效请求(requestOverflow)",
    "动效取消(cancelOverflow)",
    "卡片位置查询(getFormRect)",
    "应用页面拉起(startAbilityByLiveForm)"
  ],
  "apiUsed": [
    "LiveFormExtensionAbility",
    "onLiveFormCreate",
    "onLiveFormDestroy",
    "LiveFormInfo",
    "LiveFormExtensionContext",
    "startAbilityByLiveForm",
    "formProvider.requestOverflow",
    "formProvider.cancelOverflow",
    "formProvider.getFormRect",
    "formInfo.OverflowInfo",
    "formInfo.Rect",
    "UIExtensionContentSession"
  ],
  "configFiles": [
    "form_config.json",
    "module.json5",
    "main_pages.json"
  ],
  "constraints": {
    "apiVersion": "API 20+",
    "model": "Stage model only",
    "maxDuration": "3500ms",
    "powerSavingMode": "Not supported",
    "thermalState": "Limited in HOT/OVERHEATED"
  },
  "errorCodesHandled": [
    "801",
    "401",
    "16500050",
    "16500060",
    "16500100",
    "16501000",
    "16501001",
    "16501003",
    "16501011",
    "16501007"
  ]
}
```

## 参考文档

- [API开发指南](references/arkts-ui-liveform-sceneanimation-development.md)
- [LiveFormExtensionAbility API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-liveformextensionability)
- [LiveFormExtensionContext API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-application-liveformextensioncontext)
- [formProvider API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formprovider)
- [formInfo API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-forminfo)
- [module.json5配置文件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/module-configuration-file)
- [创建ArkTS卡片](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-creation)
- [ArkTS卡片配置文件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-configuration)
- [互动卡片请求参数约束](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-liveform-sceneanimation-overview)
- [卡片错误码](references/errorcode-form.md)
- [通用错误码](references/errorcode-universal.md)

## 完整示例代码

- [LiveFormExtensionAbility示例](assets/MyLiveFormExtensionAbility.ets)
- [卡片激活态UI示例](assets/MyLiveFormPage.ets)
- [卡片非激活态UI示例](assets/WidgetCard.ets)
- [FormExtensionAbility示例](assets/EntryFormAbility.ets)
- [动效工具函数示例](assets/Constants.ets)
- [form_config.json配置示例](assets/form_config.json)
- [module.json5配置示例](assets/module.json5)
- [main_pages.json配置示例](assets/main_pages.json)
- [string.json资源示例](assets/string.json)

## 测试用例

### 正向测试用例
- [创建LiveFormExtensionAbility](tests/test_positive_01.ets)：验证互动卡片扩展能力创建成功
- [触发动效请求](tests/test_positive_02.ets)：验证requestOverflow成功触发动效
- [取消动效](tests/test_positive_03.ets)：验证cancelOverflow成功取消动效
- [拉起应用页面](tests/test_positive_04.ets)：验证startAbilityByLiveForm成功拉起页面
- [查询卡片尺寸](tests/test_positive_05.ets)：验证getFormRect正确返回卡片信息

### 边界测试用例
- [动效时长最大值](tests/test_boundary_01.ets)：测试duration=3500ms的边界情况
- [动效区域边界](tests/test_boundary_02.ets)：测试动效区域超出卡片边界的边界值
- [并发动效请求](tests/test_boundary_03.ets)：测试同一卡片多次并发动效请求
- [卡片尺寸变化](tests/test_boundary_04.ets)：测试卡片调整尺寸后的动效表现

### 异常测试用例
- [API版本过低](tests/test_exception_01.ets)：测试API version<20时的错误处理
- [无效formId](tests/test_exception_02.ets)：测试formId不存在时的错误码16501001
- [省电模式](tests/test_exception_03.ets)：测试省电模式下动效失败（错误码16501000）
- [延时调用](tests/test_exception_04.ets)：测试setTimeout中调用startAbilityByLiveForm失败（错误码16501011）
- [拉起其他应用](tests/test_exception_05.ets)：测试拉起其他应用失败（错误码16501011）
- [IPC错误](tests/test_exception_06.ets)：测试IPC连接错误处理（错误码16500050）