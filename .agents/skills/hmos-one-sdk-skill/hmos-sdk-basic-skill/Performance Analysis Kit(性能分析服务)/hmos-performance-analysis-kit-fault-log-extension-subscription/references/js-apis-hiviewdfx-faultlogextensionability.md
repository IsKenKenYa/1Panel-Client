# @ohos.hiviewdfx.FaultLogExtensionAbility (故障延迟通知)
---
# @ohos.hiviewdfx.FaultLogExtensionAbility (故障延迟通知)
本模块实现故障的延迟通知功能。
[HiAppEvent](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent) 订阅崩溃、应用冻屏事件时，只有当应用下次启动后才能接收上一次的事件。如果应用无法启动或长时间未打开，则存在故障无法及时上报的局限性。
本模块作为该场景的补充。在应用实现FaultLogExtensionAbility后，当应用发生崩溃或冻屏时，系统服务预计会在30分钟后拉起FaultLogExtensionAbility。
开发者可在 [onFaultReportReady](#onfaultreportready) 中订阅并处理故障事件。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/ed/v3/MdIyqTMMQ3yWkgQcyZYHlQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093449Z&HW-CC-Expire=86400&HW-CC-Sign=1DBB07791F41554A5AFC8B933CA0E6BC98EA452FBACF1B61C180373F9E516E3F)
- 本模块接口从API version 21开始支持。后续版本的新增接口，采用上角标单独标记接口的起始版本。
- 本模块接口仅可在Stage模型下使用。
- 本模块设置了不允许调用的API名单，调用名单中的API将导致功能异常，详情请参见[附录](#附录)。
#### 导入模块
```
import { FaultLogExtensionAbility } from '@kit.PerformanceAnalysisKit';
```
#### FaultLogExtensionAbility
应用接入故障延迟通知需要通过FaultLogExtensionAbility实现，开发者可以在 [onFaultReportReady](#onfaultreportready) 中订阅并处理故障事件。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/76/v3/180wWo-YQFyI0n36-i9SYA/caution_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093449Z&HW-CC-Expire=86400&HW-CC-Sign=C86E1E3A512DF93DB836B61E07AB47EB7CF867064AB85A7A0C1FA2149F0AC7D4)
- FaultLogExtensionAbility被拉起后只有很短的时间完成故障处理，建议处理时间不要超过10秒。超时没有处理完成可以在[onDisconnect](#ondisconnect)中保存状态。
- 从开机或上次拉起FaultLogExtensionAbility后，应用首次触发崩溃或冻屏开始计时。在拉起FaultLogExtensionAbility前反复触发崩溃或冻屏事件均不会重新计时。
- FaultLogExtensionAbility自身崩溃时，不会再次被系统服务拉起。
#### 属性
**系统能力** ：SystemCapability.HiviewDFX.Hiview.FaultLogger
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| context | [FaultLogExtensionContext](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-faultlogextensioncontext) | 否 | 否 | FaultLogExtensionAbility的上下文环境，继承自[ExtensionContext](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-inner-application-extensioncontext)。 |
#### onConnect
onConnect(): void
FaultLogExtensionAbility生命周期回调。当系统服务完成连接时调用此接口，用于执行初始化操作，该方法可选择性重写。
**系统能力** ：SystemCapability.HiviewDFX.Hiview.FaultLogger
**示例：**
```
export default class MyFaultLogExtension extends FaultLogExtensionAbility {
    onConnect() {
      console.info('onConnect');
    }
}
```
#### onDisconnect
onDisconnect(): void
FaultLogExtensionAbility生命周期回调。当系统服务完成断开连接时调用此接口，用于释放资源清理运行状态，该方法可选择性重写。
**系统能力** ：SystemCapability.HiviewDFX.Hiview.FaultLogger
**示例：**
```
export default class MyFaultLogExtension extends FaultLogExtensionAbility {
    onDisconnect() {
      console.info('onDisconnect');
    }
}
```
#### onFaultReportReady
onFaultReportReady(): void
FaultLogExtensionAbility回调。系统服务通知FaultLogExtensionAbility可以进行故障处理时，回调此接口，可以在该方法中订阅故障事件进行处理。
**系统能力** ：SystemCapability.HiviewDFX.Hiview.FaultLogger
**示例：**
```
import { hiAppEvent } from '@kit.PerformanceAnalysisKit';
export default class MyFaultLogExtension extends FaultLogExtensionAbility {
    onFaultReportReady() {
        hiAppEvent.addWatcher({
            name: "watcher",
            appEventFilters: [
                {
                    domain: hiAppEvent.domain.OS,
                    names: [hiAppEvent.event.APP_CRASH, hiAppEvent.event.APP_FREEZE]
                }
            ],
            onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
                // 进行故障事件处理
            }
        });
    }
}
```
#### 附录
本模块不允许调用的API名单如下。
| Kit名称 | 模块名称 |
| --- | --- |
| AVSessionKit | [@ohos.multimedia.avsession (媒体会话管理)](D:/code/APIDevice/output/md_output/harmonyos-references/媒体/AVSession Kit（音视频播控服务）/ArkTS API/@ohos.multimedia.avsession (媒体会话管理)/arkts-apis-avsession.md) |
| AbilityKit | [@ohos.UIAbilityContext](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-inner-application-uiabilitycontext) |
| ArkUI | [@ohos.window (窗口)](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS API/窗口管理/@ohos.window (窗口)/arkts-apis-window.md) |
| AudioKit | [@ohos.multimedia.audio (音频管理)](D:/code/APIDevice/output/md_output/harmonyos-references/媒体/Audio Kit（音频服务）/ArkTS API/@ohos.multimedia.audio (音频管理)/arkts-apis-audio.md) |
| BackgroundTasksKit | [@ohos.backgroundTaskManager (后台任务管理)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-backgroundtaskmanager) |
| BackgroundTasksKit | [@ohos.reminderAgent (后台代理提醒)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-reminderagent) |
| BackgroundTasksKit | [@ohos.reminderAgentManager (后台代理提醒)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-reminderagentmanager) |
| BackgroundTasksKit | [@ohos.resourceschedule.backgroundTaskManager (后台任务管理)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-resourceschedule-backgroundtaskmanager) |
| BasicServicesKit | [@ohos.power (系统电源管理)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-power) |
| BasicServicesKit | [@ohos.wallpaper (壁纸)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-wallpaper) |
| CameraKit | [@ohos.multimedia.camera (相机管理)](D:/code/APIDevice/output/md_output/harmonyos-references/媒体/Camera Kit（相机服务）/ArkTS API/@ohos.multimedia.camera (相机管理)/arkts-apis-camera.md) |
| CameraKit | [@ohos.multimedia.cameraPicker (相机选择器)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-camerapicker) |
| ConnectivityKit | [@ohos.wifiManager (WLAN)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-wifimanager) |
| ConnectivityKit | [@ohos.wifiManagerExt (WLAN扩展接口)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-wifimanagerext) |
| ConnectivityKit | [@ohos.wifiext (WLAN扩展接口)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-wifiext) |
| IMEKit | [@ohos.inputMethod (输入法框架)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-inputmethod) |
| MediaLibraryKit | [@ohos.multimedia.movingphotoview (动态照片)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ohos-multimedia-movingphotoview) |
| NotificationKit | [@ohos.notification (Notification模块)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-notification) |
| NotificationKit | [@ohos.notificationManager (NotificationManager模块)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-notificationmanager) |
| SensorServiceKit | [@ohos.vibrator (振动)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-vibrator) |
| TelephonyKit | [@ohos.telephony.call (拨打电话)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-call) |
| TelephonyKit | [@ohos.telephony.sim (SIM卡管理)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-sim) |
| TelephonyKit | [@ohos.telephony.sms (短信服务)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-sms) |
| UserAuthenticationKit | [@ohos.userIAM.userAuth (用户认证)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-useriam-userauth) |