# @ohos.app.ability.common (Ability公共模块)
---
# @ohos.app.ability.common (Ability公共模块)
本模块提供Ability Kit中常用公共能力的纯类型定义，包含各类上下文对象、回调接口和数据结构。本模块仅导出类型声明，不包含具体实现逻辑或可执行代码。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/74/v3/fNgEviiIQI6fLA9Psel0pA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T092702Z&HW-CC-Expire=86400&HW-CC-Sign=AF293E637CCB1F0CB2A8376EFAD19BE19772CEB876E6510A907B983AC2478D13)
本模块首批接口从API version 9开始支持。后续版本的新增接口，采用上角标单独标记接口的起始版本。
#### 导入模块
```
import { common } from '@kit.AbilityKit';
```
#### UIAbilityContext
type UIAbilityContext = _UIAbilityContext.default
[UIAbility](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-uiability.md) 组件上下文，继承自Context。
**元服务API** ：从API version 11开始，该接口支持在元服务中使用。
**系统能力** ：SystemCapability.Ability.AbilityRuntime.Core
**模型约束** ：此接口仅可在Stage模型下使用。
| 类型 | 说明 |
| --- | --- |
| [_UIAbilityContext.default](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/js-apis-inner-application-uiabilitycontext.md) | UIAbilityContext组件上下文。 |
#### AbilityStageContext
type AbilityStageContext = _AbilityStageContext.default
[AbilityStage](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-abilitystage.md) 组件上下文，继承自Context。
**元服务API** ：从API version 11开始，该接口支持在元服务中使用。
**系统能力** ：SystemCapability.Ability.AbilityRuntime.Core
**模型约束** ：此接口仅可在Stage模型下使用。
| 类型 | 说明 |
| --- | --- |
| [_AbilityStageContext.default](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/js-apis-inner-application-abilitystagecontext.md) | AbilityStage组件上下文。 |
#### ApplicationContext
type ApplicationContext = _ApplicationContext.default
应用上下文，继承自Context。
**元服务API** ：从API version 11开始，该接口支持在元服务中使用。
**系统能力** ：SystemCapability.Ability.AbilityRuntime.Core
**模型约束** ：此接口仅可在Stage模型下使用。
| 类型 | 说明 |
| --- | --- |
| [_ApplicationContext.default](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/js-apis-inner-application-applicationcontext.md) | 应用上下文。 |
#### BaseContext
type BaseContext = _BaseContext.default
所有Context类型的父类。
**元服务API** ：从API version 11开始，该接口支持在元服务中使用。
**系统能力** ：SystemCapability.Ability.AbilityRuntime.Core
**模型约束** ：此接口仅可在Stage模型下使用。
| 类型 | 说明 |
| --- | --- |
| [_BaseContext.default](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/js-apis-inner-application-basecontext.md) | 所有Context的父类。 |
#### Context
type Context = _Context.default
[Stage模型](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/Ability Kit（程序框架服务）/Ability Kit术语/ability-terminology.md) 的上下文基类。
**元服务API** ：从API version 11开始，该接口支持在元服务中使用。
**系统能力** ：SystemCapability.Ability.AbilityRuntime.Core
**模型约束** ：此接口仅可在Stage模型下使用。
| 类型 | 说明 |
| --- | --- |
| [_Context.default](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/js-apis-inner-application-context.md) | Stage模型的上下文基类。 |
#### ExtensionContext
type ExtensionContext = _ExtensionContext.default
[ExtensionAbility](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-extensionability.md) 组件上下文，继承自Context。
**元服务API** ：从API version 11开始，该接口支持在元服务中使用。
**系统能力** ：SystemCapability.Ability.AbilityRuntime.Core
**模型约束** ：此接口仅可在Stage模型下使用。
| 类型 | 说明 |
| --- | --- |
| [_ExtensionContext.default](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/js-apis-inner-application-extensioncontext.md) | ExtensionAbility组件上下文。 |
#### FormExtensionContext
type FormExtensionContext = _FormExtensionContext.default
[FormExtensionAbility](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-formextensionability.md) 组件上下文，继承自 [ExtensionContext](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/js-apis-inner-application-extensioncontext.md) 。
**元服务API** ：从API version 11开始，该接口支持在元服务中使用。
**系统能力** ：SystemCapability.Ability.AbilityRuntime.Core
**模型约束** ：此接口仅可在Stage模型下使用。
| 类型 | 说明 |
| --- | --- |
| [_FormExtensionContext.default](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/application/js-apis-inner-application-formextensioncontext.md) | FormExtensionAbility组件上下文。 |
#### VpnExtensionContext11+
type VpnExtensionContext = _VpnExtensionContext.default
[VpnExtensionAbility](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/ArkTS API/js-apis-vpnextensionability.md) 组件上下文，继承自Context。
**系统能力** ：SystemCapability.Ability.AbilityRuntime.Core
**模型约束** ：此接口仅可在Stage模型下使用。
| 类型 | 说明 |
| --- | --- |
| [_VpnExtensionContext.default](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Kit（网络服务）/ArkTS API/js-apis-inner-application-vpnextensioncontext.md) | VpnExtensionAbility组件上下文。 |
#### EventHub
type EventHub = _EventHub.default
EventHub是系统提供的基于发布-订阅模式实现的事件通信机制。
**元服务API** ：从API version 11开始，该接口支持在元服务中使用。
**系统能力** ：SystemCapability.Ability.AbilityRuntime.Core
**模型约束** ：此接口仅可在Stage模型下使用。
| 类型 | 说明 |
| --- | --- |
| [_EventHub.default](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/js-apis-inner-application-eventhub.md) | 系统提供的基于发布-订阅模式实现的事件通信机制。 |
#### PacMap
type PacMap = _PacMap
存储基础数据类型的容器。
**元服务API** ：从API version 11开始，该接口支持在元服务中使用。
**系统能力** ：SystemCapability.Ability.AbilityRuntime.Core
| 类型 | 说明 |
| --- | --- |
| [_PacMap](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/ability/js-apis-inner-ability-dataabilityhelper.md) | 存储基础数据类型的容器。 |
#### AbilityResult
type AbilityResult = _AbilityResult
定义Ability被拉起并退出后返回的结果码和数据。
**元服务API** ：从API version 11开始，该接口支持在元服务中使用。
**系统能力** ：SystemCapability.Ability.AbilityRuntime.Core
**模型约束** ：此接口仅可在Stage模型下使用。
| 类型 | 说明 |
| --- | --- |
| [_AbilityResult](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/ability/js-apis-inner-ability-abilityresult.md) | 定义Ability被拉起并退出后返回的结果码和数据。 |
#### AbilityStartCallback11+
type AbilityStartCallback = _AbilityStartCallback
定义了拉起UIExtensionAbility的回调结果，通常作为 [UIAbilityContext.startAbilityByType](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/js-apis-inner-application-uiabilitycontext.md) / [UIExtensionContext.startAbilityByType](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-uiextensioncontentsession.md) 的入参传入。
**元服务API** ：从API version 11开始，该接口支持在元服务中使用。
**系统能力** ：SystemCapability.Ability.AbilityRuntime.Core
**模型约束** ：此接口仅可在Stage模型下使用。
| 类型 | 说明 |
| --- | --- |
| [_AbilityStartCallback](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/js-apis-inner-application-abilitystartcallback.md) | 定义拉起UIExtensionAbility的回调结果。 |
#### ConnectOptions
type ConnectOptions = _ConnectOptions
在连接指定的后台服务时作为入参，用于接收与后台服务的连接状态。
**系统能力** ：SystemCapability.Ability.AbilityRuntime.Core
**模型约束** ：此接口仅可在Stage模型下使用。
| 类型 | 说明 |
| --- | --- |
| [_ConnectOptions](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/ability/js-apis-inner-ability-connectoptions.md) | 在连接指定的后台服务时作为入参，用于接收与后台服务的连接状态。 |
#### UIExtensionContext10+
type UIExtensionContext = _UIExtensionContext.default
[UIExtensionAbility](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-uiextensionability.md) 组件上下文，继承自Context。
**系统能力** ：SystemCapability.Ability.AbilityRuntime.Core
**模型约束** ：此接口仅可在Stage模型下使用。
| 类型 | 说明 |
| --- | --- |
| [_UIExtensionContext.default](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/js-apis-inner-application-uiextensioncontext.md) | UIExtensionAbility组件上下文。 |
#### EmbeddableUIAbilityContext12+
type EmbeddableUIAbilityContext = _EmbeddableUIAbilityContext.default
[EmbeddableUIAbility](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-embeddableuiability.md) 组件上下文，继承自Context。
**元服务API** ：从API version 12开始，该接口支持在元服务中使用。
**系统能力** ：SystemCapability.Ability.AbilityRuntime.Core
**模型约束** ：此接口仅可在Stage模型下使用。
| 类型 | 说明 |
| --- | --- |
| [_EmbeddableUIAbilityContext.default](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/-apis-inner-application-embeddableuiabilitycontext.md) | EmbeddableUIAbility组件上下文。 |
#### PhotoEditorExtensionContext12+
type PhotoEditorExtensionContext = _PhotoEditorExtensionContext.default
[PhotoEditorExtensionAbility](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-photoeditorextensionability.md) 组件上下文，继承自Context。
**系统能力** ：SystemCapability.Ability.AppExtension.PhotoEditorExtension
**模型约束** ：此接口仅可在Stage模型下使用。
| 类型 | 说明 |
| --- | --- |
| [_PhotoEditorExtensionContext.default](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/js-apis-app-ability-photoeditorextensioncontext.md) | PhotoEditorExtensionAbility组件上下文。 |
#### UIServiceProxy14+
type UIServiceProxy = _UIServiceProxy.default
UIServiceProxy提供了与UIServiceExtensionAbility服务端数据通信的能力。UIServiceExtensionAbility是一类特殊的ExtensionAbility组件，这类组件由系统提供，通常用于提供浮窗组件相关扩展能力。
**元服务API** ：从API version 14开始，该接口支持在元服务中使用。
**系统能力** ：SystemCapability.Ability.AbilityRuntime.Core
**模型约束** ：此接口仅可在Stage模型下使用。
| 类型 | 说明 |
| --- | --- |
| [_UIServiceProxy.default](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/js-apis-inner-application-uiserviceproxy.md) | 提供与UIServiceExtensionAbility服务端数据通信的能力。 |
#### UIServiceExtensionConnectCallback14+
type UIServiceExtensionConnectCallback = _UIServiceExtensionConnectCallback.default
在连接指定的UIServiceExtensionAbility服务时作为入参，用于提供UIServiceExtensionAbility连接回调数据能力。
**元服务API** ：从API version 14开始，该接口支持在元服务中使用。
**系统能力** ：SystemCapability.Ability.AbilityRuntime.Core
**模型约束** ：此接口仅可在Stage模型下使用。
| 类型 | 说明 |
| --- | --- |
| [_UIServiceExtensionConnectCallback.default](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/nner-application-uiserviceextensionconnectcallback.md) | 提供UIServiceExtensionAbility连接回调数据能力。 |
#### AppServiceExtensionContext20+
type AppServiceExtensionContext = _AppServiceExtensionContext.default
[AppServiceExtensionAbility](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-appserviceextensionability.md) 组件上下文，继承自Context。
**系统能力** ：SystemCapability.Ability.AbilityRuntime.Core
**模型约束** ：此接口仅可在Stage模型下使用。
| 类型 | 说明 |
| --- | --- |
| [_AppServiceExtensionContext.default](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/-apis-inner-application-appserviceextensioncontext.md) | AppServiceExtensionAbility组件上下文。 |
#### FormEditExtensionContext22+
type FormEditExtensionContext = _FormEditExtensionContext.default
[FormEditExtensionAbility](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-formeditextensionability.md) 组件上下文，继承自 [UIExtensionContext](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/js-apis-inner-application-uiextensioncontext.md) 。
**元服务API** ：从API version 22开始，该接口支持在元服务中使用。
**系统能力** ：SystemCapability.Ability.Form
**模型约束** ：此接口仅可在Stage模型下使用。
| 类型 | 说明 |
| --- | --- |
| [_FormEditExtensionContext.default](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/application/js-apis-inner-application-formeditextensioncontext.md) | FormEditExtensionAbility组件上下文。 |
#### LiveFormExtensionContext22+
type LiveFormExtensionContext = _LiveFormExtensionContext.default
[LiveFormExtensionAbility](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-liveformextensionability.md) 组件上下文，继承自 [ExtensionContext](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/js-apis-inner-application-extensioncontext.md) 。
**元服务API** ：从API version 22开始，该接口支持在元服务中使用。
**系统能力** ：SystemCapability.Ability.Form
**模型约束** ：此接口仅可在Stage模型下使用。
| 类型 | 说明 |
| --- | --- |
| [_LiveFormExtensionContext.default](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/application/js-apis-application-liveformextensioncontext.md) | LiveFormExtensionAbility组件上下文。 |
**示例：**
```
import { common } from '@kit.AbilityKit';
let uiAbilityContext: common.UIAbilityContext;
let abilityStageContext: common.AbilityStageContext;
let applicationContext: common.ApplicationContext;
let baseContext: common.BaseContext;
let context: common.Context;
let uiExtensionContext: common.UIExtensionContext;
let extensionContext: common.ExtensionContext;
let formExtensionContext: common.FormExtensionContext;
let vpnExtensionContext: common.VpnExtensionContext;
let eventHub: common.EventHub;
let pacMap: common.PacMap;
let abilityResult: common.AbilityResult;
let abilityStartCallback: common.AbilityStartCallback;
let connectOptions: common.ConnectOptions;
let embeddableUIAbilityContext: common.EmbeddableUIAbilityContext;
let photoEditorExtensionContext: common.PhotoEditorExtensionContext;
let uiServiceProxy : common.UIServiceProxy;
let uiServiceExtensionConnectCallback : common.UIServiceExtensionConnectCallback;
let appServiceExtensionContext : common.AppServiceExtensionContext;
let formEditExtensionContext : common.FormEditExtensionContext;
let liveFormExtensionContext : common.LiveFormExtensionContext;
```