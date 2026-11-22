# @ohos.app.form.LiveFormExtensionAbility (LiveFormExtensionAbility)
---
# @ohos.app.form.LiveFormExtensionAbility (LiveFormExtensionAbility)
LiveFormExtensionAbility模块提供互动卡片功能，包括创建、销毁互动卡片等，继承自 [ExtensionAbility](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-extensionability.md) 。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/6e/v3/VYKX_vV7Qb2ell5u5xk-Zw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093143Z&HW-CC-Expire=86400&HW-CC-Sign=F2FC04181798C617CE19FC377FC74E228E20AE05F601EA8BC0F7BDF986439655)
本模块首批接口从API version 20开始支持。后续版本的新增接口，采用上角标单独标记接口的起始版本。
本模块接口仅可在Stage模型下使用。
本模块设置了不允许调用的API名单，调用名单中的API将导致功能异常，详情请参见 [附录](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-liveformextensionability.md) 。
#### 导入模块
```
import { LiveFormExtensionAbility } from '@kit.FormKit';
```
#### LiveFormExtensionAbility
互动卡片扩展类。包含互动卡片提供方接收创建和销毁互动卡片的通知接口。
#### 属性
**模型约束：** 此接口仅可在Stage模型下使用。
**系统能力：** SystemCapability.Ability.Form
**元服务API：** 从API version 20开始，该接口支持在元服务中使用。
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| context | [LiveFormExtensionContext](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/application/js-apis-application-liveformextensioncontext.md) | 否 | 否 | LiveFormExtensionAbility的上下文环境，继承自[ExtensionContext](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/js-apis-inner-application-extensioncontext.md)。 |
#### onLiveFormCreate
onLiveFormCreate(liveFormInfo: LiveFormInfo, session: UIExtensionContentSession): void
LiveFormExtensionAbility界面内容对象创建后调用。
**模型约束：** 此接口仅可在Stage模型下使用。
**系统能力** ：SystemCapability.Ability.Form
**元服务API：** 从API version 20开始，该接口支持在元服务中使用。
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| liveFormInfo | [LiveFormInfo](#liveforminfo) | 是 | 互动卡片信息，包括卡片id等信息。 |
| session | [UIExtensionContentSession](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-uiextensioncontentsession.md) | 是 | LiveFormExtensionAbility界面内容相关信息。 |
**示例：**
```
import { UIExtensionContentSession } from '@kit.AbilityKit';
import { LiveFormExtensionAbility, LiveFormInfo } from '@kit.FormKit';
const TAG: string = '[testTag] LiveFormExtAbility';
export default class LiveFormExtAbility extends LiveFormExtensionAbility {
  onLiveFormCreate(liveFormInfo: LiveFormInfo, session: UIExtensionContentSession) {
    console.info(TAG, `onLiveFormCreate, formId: ${liveFormInfo.formId}`);
  }
}
```
#### onLiveFormDestroy
onLiveFormDestroy(liveFormInfo: LiveFormInfo): void
LiveFormExtensionAbility生命周期回调，在销毁时回调，执行资源清理等操作。
**模型约束：** 此接口仅可在Stage模型下使用。
**系统能力** ：SystemCapability.Ability.Form
**元服务API：** 从API version 20开始，该接口支持在元服务中使用。
**参数：**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| liveFormInfo | [LiveFormInfo](#liveforminfo) | 是 | 互动卡片信息，包括卡片id等信息。 |
**示例：**
```
import { LiveFormExtensionAbility, LiveFormInfo } from '@kit.FormKit';
const TAG: string = '[testTag] LiveFormExtAbility';
export default class LiveFormExtAbility extends LiveFormExtensionAbility {
  onLiveFormDestroy(liveFormInfo: LiveFormInfo) {
    console.info(TAG, `onLiveFormDestroy, liveFormInfo: ${liveFormInfo.formId}`);
  }
}
```
#### LiveFormInfo
互动卡片信息。
**模型约束：** 此接口仅可在Stage模型下使用。
**系统能力：** SystemCapability.Ability.Form
**元服务API：** 从API version 20开始，该接口支持在元服务中使用。
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| formId | string | 否 | 否 | 卡片id。 |
| rect | [formInfo.Rect](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Form Kit（卡片开发服务）/ArkTS API/js-apis-app-form-forminfo.md) | 否 | 否 | 卡片位置和大小信息。 |
| borderRadius | number | 否 | 否 | 卡片圆角半径信息。取值大于0，单位vp。 |
#### 附录
本模块不允许调用的API名单如下。
| Kit名称 | 模块名称 |
| --- | --- |
| AbilityKit | [@ohos.ability.featureAbility (FeatureAbility模块)](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/FA模型能力的接口/js-apis-ability-featureability.md)[@ohos.ability.particleAbility (ParticleAbility模块)](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/FA模型能力的接口/js-apis-ability-particleability.md)[@ohos.bundle.launcherBundleManager (launcherBundleManager模块)](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/通用能力的接口(推荐)/js-apis-launcherbundlemanager.md)[@ohos.continuation.continuationManager (流转/协同管理)](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-continuation-continuationmanager.md) |
| BasicServicesKit | [@ohos.account.appAccount (应用账号管理)](D:/code/APIDevice/output/md_output/harmonyos-references/系统/基础功能/Basic Services Kit（基础服务）/ArkTS API/账号管理/js-apis-appaccount.md)[@ohos.account.distributedAccount (分布式账号管理)](D:/code/APIDevice/output/md_output/harmonyos-references/系统/基础功能/Basic Services Kit（基础服务）/ArkTS API/账号管理/js-apis-distributed-account.md)[@ohos.account.osAccount (系统账号管理)](D:/code/APIDevice/output/md_output/harmonyos-references/系统/基础功能/Basic Services Kit（基础服务）/ArkTS API/账号管理/js-apis-osaccount.md)[@ohos.pasteboard (剪贴板)](D:/code/APIDevice/output/md_output/harmonyos-references/系统/基础功能/Basic Services Kit（基础服务）/ArkTS API/数据文件处理/js-apis-pasteboard.md)[@ohos.request (上传下载)](D:/code/APIDevice/output/md_output/harmonyos-references/系统/基础功能/Basic Services Kit（基础服务）/ArkTS API/数据文件处理/js-apis-request.md)[@ohos.wallpaper (壁纸)](D:/code/APIDevice/output/md_output/harmonyos-references/系统/基础功能/Basic Services Kit（基础服务）/ArkTS API/其他/js-apis-wallpaper.md) |
| BackgroundTasksKit | [@ohos.backgroundTaskManager (后台任务管理)](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Background Tasks Kit（后台任务开发服务）/ArkTS API/已停止维护的接口/js-apis-backgroundtaskmanager.md)[@ohos.resourceschedule.backgroundTaskManager (后台任务管理)](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Background Tasks Kit（后台任务开发服务）/ArkTS API/js-apis-resourceschedule-backgroundtaskmanager.md)[@ohos.reminderAgent (后台代理提醒)](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Background Tasks Kit（后台任务开发服务）/ArkTS API/已停止维护的接口/js-apis-reminderagent.md)[@ohos.reminderAgentManager (后台代理提醒)](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Background Tasks Kit（后台任务开发服务）/ArkTS API/js-apis-reminderagentmanager.md) |
| CalendarKit | [@ohos.calendarManager (日程管理能力)](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Calendar Kit（日历服务）/ArkTS API/js-apis-calendarmanager.md) |
| ConnectivityKit | [@ohos.connectedTag (有源标签)](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Connectivity Kit（短距通信服务）/ArkTS API/js-apis-connectedtag.md)[@ohos.nfc.cardEmulation (标准NFC-cardEmulation)](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Connectivity Kit（短距通信服务）/ArkTS API/js-apis-cardemulation.md)[@ohos.nfc.controller (标准NFC)](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Connectivity Kit（短距通信服务）/ArkTS API/js-apis-nfccontroller.md)[@ohos.nfc.tag (标准NFC-Tag)](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Connectivity Kit（短距通信服务）/ArkTS API/js-apis-nfctag.md)[nfctech (标准NFC-Tag Nfc 技术)](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Connectivity Kit（短距通信服务）/ArkTS API/tag/js-apis-nfctech.md)[tagSession (标准NFC-Tag TagSession)](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Connectivity Kit（短距通信服务）/ArkTS API/tag/js-apis-tagsession.md) |
| ContactsKit | [@ohos.contact (联系人)](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Contacts Kit（联系人服务）/ArkTS API/js-apis-contact.md) |
| ArkData | [@ohos.data.distributedData (分布式数据管理)](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkData（方舟数据管理）/ArkTS API/已停止维护的接口/js-apis-distributed-data.md)[@ohos.data.distributedDataObject (分布式数据对象)](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkData（方舟数据管理）/ArkTS API/js-apis-data-distributedobject.md)[@ohos.data.distributedKVStore (分布式键值数据库)](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkData（方舟数据管理）/ArkTS API/js-apis-distributedkvstore.md) |
| MDMKit | [@ohos.enterprise.adminManager (admin权限管理)](D:/code/APIDevice/output/md_output/harmonyos-references/系统/基础功能/MDM Kit（企业设备管理服务）/ArkTS API/js-apis-enterprise-adminmanager.md)[@ohos.enterprise.deviceInfo（设备信息管理）](D:/code/APIDevice/output/md_output/harmonyos-references/系统/基础功能/MDM Kit（企业设备管理服务）/ArkTS API/js-apis-enterprise-deviceinfo.md) |
| CoreFileKit | [@ohos.file.picker (选择器)](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Core File Kit（文件基础服务）/ArkTS API/js-apis-file-picker.md) |
| MediaLibraryKit | [@ohos.file.sendablePhotoAccessHelper (基于Sendable对象的相册管理模块)](D:/code/APIDevice/output/md_output/harmonyos-references/媒体/Media Library Kit（媒体文件管理服务）/ArkTS API/js-apis-sendablephotoaccesshelper.md)[@ohos.file.AlbumPickerComponent (Album Picker组件)](D:/code/APIDevice/output/md_output/harmonyos-references/媒体/Media Library Kit（媒体文件管理服务）/ArkTS组件/ohos-file-albumpickercomponent.md)[@ohos.file.PhotoPickerComponent (PhotoPicker组件)](D:/code/APIDevice/output/md_output/harmonyos-references/媒体/Media Library Kit（媒体文件管理服务）/ArkTS组件/ohos-file-photopickercomponent.md)[@ohos.file.RecentPhotoComponent (最近图片组件)](D:/code/APIDevice/output/md_output/harmonyos-references/媒体/Media Library Kit（媒体文件管理服务）/ArkTS组件/ohos-file-recentphotocomponent.md)[@ohos.multimedia.movingphotoview (动态照片)](D:/code/APIDevice/output/md_output/harmonyos-references/媒体/Media Library Kit（媒体文件管理服务）/ArkTS组件/ohos-multimedia-movingphotoview.md) |
| PerformanceAnalysisKit | [@ohos.hidebug (Debug调试)](D:/code/APIDevice/output/md_output/harmonyos-references/系统/调测调优/Performance Analysis Kit（性能分析服务）/ArkTS API/js-apis-hidebug.md) |
| AudioKit | [@ohos.multimedia.audio (音频管理)](D:/code/APIDevice/output/md_output/harmonyos-references/媒体/Audio Kit（音频服务）/ArkTS API/@ohos.multimedia.audio (音频管理)/arkts-apis-audio.md) |
| CameraKit | [@ohos.multimedia.cameraPicker (相机选择器)](D:/code/APIDevice/output/md_output/harmonyos-references/媒体/Camera Kit（相机服务）/ArkTS API/js-apis-camerapicker.md)[@ohos.multimedia.camera (相机管理)](D:/code/APIDevice/output/md_output/harmonyos-references/媒体/Camera Kit（相机服务）/ArkTS API/@ohos.multimedia.camera (相机管理)/arkts-apis-camera.md) |
| AVSessionKit | [@ohos.multimedia.avCastPicker (投播组件)](D:/code/APIDevice/output/md_output/harmonyos-references/媒体/AVSession Kit（音视频播控服务）/ArkTS组件/ohos-multimedia-avcastpicker.md)[@ohos.multimedia.avsession (媒体会话管理)](D:/code/APIDevice/output/md_output/harmonyos-references/媒体/AVSession Kit（音视频播控服务）/ArkTS API/@ohos.multimedia.avsession (媒体会话管理)/arkts-apis-avsession.md) |
| MediaKit | [@ohos.multimedia.media (媒体服务)](D:/code/APIDevice/output/md_output/harmonyos-references/媒体/Media Kit（媒体服务）/ArkTS API/@ohos.multimedia.media (媒体服务)/arkts-apis-media.md) |
| NotificationKit | [@ohos.notification (Notification模块)](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Notification Kit（用户通知服务）/ArkTS API/已停止维护的接口/js-apis-notification.md)[@ohos.notificationManager (NotificationManager模块)](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Notification Kit（用户通知服务）/ArkTS API/js-apis-notificationmanager.md) |
| TelephonyKit | [@ohos.telephony.call (拨打电话)](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Telephony Kit（蜂窝通信服务）/ArkTS API/js-apis-call.md)[@ohos.telephony.data (蜂窝数据)](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Telephony Kit（蜂窝通信服务）/ArkTS API/js-apis-telephony-data.md)[@ohos.telephony.observer (observer)](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Telephony Kit（蜂窝通信服务）/ArkTS API/js-apis-observer.md)[@ohos.telephony.radio (网络搜索)](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Telephony Kit（蜂窝通信服务）/ArkTS API/js-apis-radio.md)[@ohos.telephony.sim (SIM卡管理)](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Telephony Kit（蜂窝通信服务）/ArkTS API/js-apis-sim.md)[@ohos.telephony.sms (短信服务)](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Telephony Kit（蜂窝通信服务）/ArkTS API/js-apis-sms.md) |
| UserAuthenticationKit | [@ohos.userIAM.userAuth (用户认证)](D:/code/APIDevice/output/md_output/harmonyos-references/系统/安全/User Authentication Kit（用户认证服务）/ArkTS API/js-apis-useriam-userauth.md) |
| ArkUI | [@ohos.window (窗口)](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS API/窗口管理/@ohos.window (窗口)/arkts-apis-window.md) |
| MapKit | [sceneMap（场景化控件）](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-scenemap.md) |
| PaymentKit | [paymentService (鸿蒙支付服务)](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Payment Kit（鸿蒙支付服务）/ArkTS API/payment-paymentservice.md) |
| ServiceCollaborationKit | [devicePicker (设备选择控制器)](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/ArkTS 组件/servicecollaboration-devicepicker.md)[CollaborationDevicePicker (流转控件)](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/ArkTS 组件/servicecollaboration-collaborationdevicepicker.md) |
| ShareKit | [systemShare（分享）](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Share Kit（分享服务）/ArkTS API/share-system-share.md)[harmonyShare（华为分享）](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Share Kit（分享服务）/ArkTS API/share-harmony-share.md) |
| VisionKit | [CardRecognition（卡证识别控件）](D:/code/APIDevice/output/md_output/harmonyos-references/AI/Vision Kit（场景化视觉服务）/ArkTS组件/vision-card-recognition.md)[DocumentScanner（文档扫描控件）](D:/code/APIDevice/output/md_output/harmonyos-references/AI/Vision Kit（场景化视觉服务）/ArkTS组件/vision-document-scanner.md) |
| ScanKit | [Scan Kit（统一扫码服务）](D:/code/APIDevice/output/md_output/harmonyos-references/scan-api.md) |