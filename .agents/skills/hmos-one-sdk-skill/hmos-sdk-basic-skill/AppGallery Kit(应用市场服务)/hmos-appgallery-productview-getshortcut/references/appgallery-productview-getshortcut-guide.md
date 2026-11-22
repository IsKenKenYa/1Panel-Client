# 查询应用内快捷方式
---
# 查询应用内快捷方式
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/62/v3/tqOBYdzMSRu-z36rhvI_cg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105134Z&HW-CC-Expire=86400&HW-CC-Sign=416AEE13F1E01176A16DCEE4DFA35E2C08E24B7DEAD8BCBFEAF410FA70B05EB7)
6.1.1(24)版本开始，新增查询桌面快捷方式接口，支持用户查询桌面快捷方式。
#### 场景介绍
查询应用内快捷方式用于获取当前应用已固定在桌面上的所有快捷方式列表。用户可以在应用内查看已添加到桌面的快捷方式列表，快速找到特定的快捷方式。也可通过定期查看和管理这些快捷方式，确保桌面的整洁和高效。
#### 业务流程
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/9e/v3/CiRWCBKHRGah5_Q1SzdmpQ/zh-cn_image_0000002659100797.png?HW-CC-KV=V1&HW-CC-Date=20260701T105134Z&HW-CC-Expire=86400&HW-CC-Sign=390D591C551961CE33496C2941289CF39BD0E3148C8C1571AC1CD59814B79F3C)
1.
用户需要查询当前应用的快捷方式。
2.
应用调用 [getPinShortcutInfos](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/AppGallery Kit（应用市场服务）/ArkTS API/store-productviewmanager.md) 接口获取快捷方式信息。
3.
AppGallery Kit返回查询结果信息给应用。
4.
应用将查询结果返回给用户。
#### 约束与限制
-
应用市场推荐服务不支持模拟器，请使用真机调试。在模拟器中使用该服务将会提示：无法获取内容，请点击屏幕重试。
-
应用市场推荐服务支持Phone、Tablet、PC/2in1设备。并且从6.0.2(22)版本开始，新增支持TV设备。
#### 接口说明
详细接口说明可参考 [接口文档](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/AppGallery Kit（应用市场服务）/ArkTS API/store-productviewmanager.md) 。
| 接口名 | 描述 |
| --- | --- |
| [getPinShortcutInfos](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/AppGallery Kit（应用市场服务）/ArkTS API/store-productviewmanager.md)(): Promise<[PinShortcutInfo](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/AppGallery Kit（应用市场服务）/ArkTS API/store-productviewmanager.md)[]> | 查询桌面快捷方式列表。 |
#### 开发步骤
1.
```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { productViewManager } from '@kit.AppGalleryKit';
```
2.
[getPinShortcutInfos](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/AppGallery Kit（应用市场服务）/ArkTS API/store-productviewmanager.md)
```typescript
const TAG: string = 'GetPinShortcutInfos';
@Entry
@Component
struct GetPinShortcutInfos {
  build() {
    Column() {
      Button("GetPinShortcutInfos")
        .onClick(() => {
          try {
         // 通过getPinShortcutInfos接口获取桌面快捷方式列表信息
            productViewManager.getPinShortcutInfos()
              .then(() => {
                hilog.info(0x0001, TAG, `getPinShortcutInfos success.`);
              }).catch((error: BusinessError) => {
              hilog.error(0x0001, TAG, `getPinShortcutInfos error. code is ${error.code}, message is ${error.message}`);
             })
          } catch (err) {
            hilog.error(0x0001, TAG, `getPinShortcutInfos failed, code is ${err.code}, message is ${err.message}`);
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