# 删除应用内快捷方式
---
# 删除应用内快捷方式
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/bd/v3/uWV_AihxQbKuRkoGGSGomg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105134Z&HW-CC-Expire=86400&HW-CC-Sign=45A74A4B36E1DAAE4843BF3F0B074E6FBF079F0EEAA936E6895EFEDECF271FB2)
6.1.1(24)版本开始，新增删除桌面快捷方式接口，支持用户删除桌面快捷方式。
#### 场景介绍
当应用的桌面快捷方式功能发生变化或者用户希望删除不再使用的桌面快捷方式时，用户可以通过调用 [removePinShortcut](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/store-productviewmanager) 接口删除当前应用的桌面快捷方式。
#### 业务流程
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/57/v3/wch3uCrgQjuksaFakz39aQ/zh-cn_image_0000002628861448.png?HW-CC-KV=V1&HW-CC-Date=20260701T105134Z&HW-CC-Expire=86400&HW-CC-Sign=8FC0104947201214DAF1CA153F8A1D3135FB98890F38E68DEE1D5DA029948587)
1.
用户需要删除桌面快捷方式。
2.
应用调用 [removePinShortcut](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/store-productviewmanager) 接口删除快捷方式。
3.
AppGallery Kit向应用弹出快捷方式删除确认框。
4.
用户确认是否删除快捷方式。
#### 约束与限制
-
应用市场推荐服务不支持模拟器，请使用真机调试。在模拟器中使用该服务将会提示：无法获取内容，请点击屏幕重试。
-
应用市场推荐服务支持Phone、Tablet、PC/2in1设备。并且从6.0.2(22)版本开始，新增支持TV设备。
#### 接口说明
详细接口说明可参考 [接口文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/store-productviewmanager) 。
| 接口名 | 描述 |
| --- | --- |
| [removePinShortcut](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/store-productviewmanager)(context:[common.UIAbilityContext](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-inner-application-uiabilitycontext), shortcutId: string): Promise<void> | 删除桌面快捷方式。 |
#### 开发准备
#### （可选）静默删除桌面快捷方式开放能力申请
当应用已有自己的删除确认弹框并在弹框中提示用户删除桌面快捷方式时，开发者可以申请静默删除权限，实现在不显示系统确认弹框的情况下完成删除操作。
1.
登录AppGallery Connect，选择"开发与服务"。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/1c/v3/y2mI4WBRRIeLm3zFBhBfmg/zh-cn_image_0000002628701566.png?HW-CC-KV=V1&HW-CC-Date=20260701T105134Z&HW-CC-Expire=86400&HW-CC-Sign=8D8D8E90B8B2C57D1C051F12BDF5B0DC71C565281E694A165E727D08BE7814F0)
2.
在项目列表中找到您的项目，并点击选择需申请静默删除桌面快捷方式能力的应用。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/88/v3/ZoH7OcllS52r2NSBaNfJew/zh-cn_image_0000002659220761.png?HW-CC-KV=V1&HW-CC-Date=20260701T105134Z&HW-CC-Expire=86400&HW-CC-Sign=16C6647A20AED5132F5D4ADC2527B039BFAEE3085FF3B043AF69B79F43E899D1)
3.
在"开放能力管理"页面，点击静默删除桌面快捷方式对应的"申请"按钮。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/57/v3/wXCHcDtDT0-bB9nvwEztOw/zh-cn_image_0000002628701570.png?HW-CC-KV=V1&HW-CC-Date=20260701T105134Z&HW-CC-Expire=86400&HW-CC-Sign=3747BDA9D7B012B2F897EDB9DCB765FCBC030B98CE359567DFFDF0147AFF5F91)
4.
在"新建业务申请"窗口填写申请信息，然后点击"提交"。申请原因：必填，包括应用介绍、使用场景，不超过256个字符。上传附件：必填，提供应用的使用场景录屏，录屏中需要体现应用自己的弹框以及在弹框中显示提示用户删除桌面快捷方式，仅可上传1个附件，大小不超过500MB。支持文本、表格、图片、视频、压缩包格式。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/88/v3/NujbEjZRRz65G135qoh6TA/zh-cn_image_0000002659100799.png?HW-CC-KV=V1&HW-CC-Date=20260701T105134Z&HW-CC-Expire=86400&HW-CC-Sign=05DCFD9F3123B46BE71989ECD64AC3961C4DF5D847E2EC5666902B63CA94DFC9)
5.
返回"开放能力管理"页面，原"申请"按钮变为"申请中"，1-3个工作日反馈申请结果。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/4f/v3/wuxdBiA9ThyM5h2W1ci9-Q/zh-cn_image_0000002628861450.png?HW-CC-KV=V1&HW-CC-Date=20260701T105134Z&HW-CC-Expire=86400&HW-CC-Sign=7B871E9948CA3DAE5A5DDB3BF4B2931ADDCD6E3C7E92EE95B99E88B292E21DEA)
6.
申请审批通过后，互动中心会发送通知给您，同时"申请中"按钮会变为置灰显示的"申请"。
7.
能力申请通过后，勾选删除桌面快捷方式的能力开关，点击右上角"保存"。至此，您的应用已成功接入开放能力。
#### 开发步骤
1.
导入productViewManager模块及相关公共模块。
```typescript
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { productViewManager } from '@kit.AppGalleryKit';
```
2.
调用 [removePinShortcut](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/store-productviewmanager) 方法删除桌面快捷方式。
```typescript
const TAG: string = 'RemovePinShortcut';
@Entry
@Component
struct RemovePinShortcut {
build() {
  Column() {
    Button("RemovePinShortcut")
      .onClick(() => {
        try {
         const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
         const shortcutId = 'xxx'; // 通过checkPinShortcutPermitted接口获取
         productViewManager.removePinShortcut(uiContext, shortcutId)
           .then(() => {
             hilog.info(0x0001, TAG, `removePinShortcut success.`);
           }).catch((error: BusinessError) => {
           hilog.error(0x0001, TAG, `removePinShortcut error. code is ${error.code}, message is ${error.message}`);
         })
        } catch (err) {
          hilog.error(0x0001, TAG, `removePinShortcut failed, code is ${err.code}, message is ${err.message}`);
         }
         })
         .width('100%')
  }
  .margin(16)
  .height('100%')
  .justifyContent(FlexAlign.Center)
  }
}
```