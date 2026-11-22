# 跨设备互通开发指导
---
# 跨设备互通开发指导
跨设备互通提供相机、扫描以及图库（图片和视频）的跨设备调用能力，例如：Tablet或PC/2in1设备可以调用Phone的相机、扫描、图库等功能。从API 6.1.0(23)开始，TV、Phone、Tablet或PC/2in1设备可调用具备如下能力的远程设备：支持拍照、扫描及图库（图片与视频）能力的Phone和Tablet，支持图库（图片与视频）能力的PC/2in1设备。
#### 场景介绍
您通过此能力实现跨设备交互，可以使用其他设备的相机、扫描和图库功能。
#### 约束与限制
需同时满足以下条件，才能使用该功能：
-
**设备限制**
- 本端设备：HarmonyOS版本为HarmonyOS 5及以上的Tablet或PC/2in1设备，从API 6.1.0(23)开始，支持HarmonyOS版本为HarmonyOS 5及以上的TV、Phone、Tablet或PC/2in1设备。
- 远端设备：HarmonyOS版本为HarmonyOS 5及以上、具有相机能力的Phone或Tablet设备，从API 6.1.0(23)开始，支持HarmonyOS版本为HarmonyOS 5及以上的Phone、Tablet或PC/2in1设备。
-
**使用限制**
- 双端设备需要登录同一华为账号。
- 跨设备互通API支持根据特定调用策略调用设备。调用策略：PC/2in1设备可以调用Tablet和Phone，Tablet可以调用Phone，并且从API 6.1.0(23)开始支持TV、Phone、Tablet或PC/2in1设备调用支持拍照、扫描、选择图库中图片与视频能力的Phone，支持拍照、扫描、选择图库中图片与视频能力的Tablet，以及支持选择图库中图片与视频能力的PC/2in1设备。
- 本端和远端设备需要打开WLAN和蓝牙开关。条件允许时，推荐本端和远端设备接入同一个局域网，可提升唤醒相机的速度。
- 若在跨设备调用视频选择器时遇到资源加载异常，建议在调用前确认本端和远端的设备调用能力是否匹配、系统状态是否正常，并在稳定环境下重试操作。
#### 接口说明
在开发具体功能前，请先查阅 [参考文档](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/ArkTS 组件/servicecollaboration-collaborationservice.md) 。
| 接口名 | 描述 |
| --- | --- |
| [createCollaborationServiceMenuItems](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/ArkTS 组件/servicecollaboration-collaborationservice.md) | 设备列表选择器，用于获取组网内具有对应跨设备互通能力的设备列表。 |
| [CollaborationServiceStateDialog](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/ArkTS 组件/servicecollaboration-collaborationservice.md) | 弹窗组件，用于提示对端业务状态。 |
#### 开发步骤
1.
导入模块。
```typescript
import { createCollaborationServiceMenuItems, CollaborationServiceStateDialog, CollaborationServiceFilter } from '@kit.ServiceCollaborationKit';
```
[createCollaborationServiceMenuItems](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/ArkTS 组件/servicecollaboration-collaborationservice.md) 是设备列表菜单项模块，传入 [CollaborationServiceFilter](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/ArkTS 组件/servicecollaboration-collaborationservice.md) 的能力枚举值； [CollaborationServiceStateDialog](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/ArkTS 组件/servicecollaboration-collaborationservice.md) 是状态提示框模块。
2.
在Menu中调用createCollaborationServiceMenuItems添加设备列表选择器，在菜单项内显示设备列表。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/5e/v3/8UAp4ZnBQJesW7-oSGwD9g/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T104905Z&HW-CC-Expire=86400&HW-CC-Sign=C40ADABE4CD8EC30649B440C1765A05F6FAABDA3FD2C413DAD46AE7B83DE2B9E)
在调用 [createCollaborationServiceMenuItems](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/ArkTS 组件/servicecollaboration-collaborationservice.md) 前，需了解：
-
该方法需要在 [Menu](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/菜单/ts-basic-components-menu.md) 组件内调用。
-
该方法是自定义构建函数，您在使用前需要先了解 [@Builder](D:/code/APIDevice/output/md_output/harmonyos-guides/应用框架/ArkUI（方舟UI框架）/UI开发 (ArkTS声明式开发范式)/学习UI范式基本语法/组件扩展/@Builder装饰器：自定义构建函数/arkts-builder.md) 。
3.
传入Array类型的 [CollaborationServiceFilter](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/ArkTS 组件/servicecollaboration-collaborationservice.md) 枚举值即可使用对应能力，目前支持ALL、TAKE_PHOTO、SCAN_DOCUMENT、IMAGE_PICKER、VIDEO_PICKER和IMAGE_VIDEO_PICKER。
ALL为预留值，匹配跨端拍照、文档扫描和图库选择器，功能将在后续拓展，TAKE_PHOTO匹配跨设备拍照能力，SCAN_DOCUMENT匹配跨设备扫描能力，IMAGE_PICKER匹配跨设备图库能力，VIDEO_PICKER匹配视频选择器，IMAGE_VIDEO_PICKER匹配图片和视频选择器。
```typescript
@Builder
myTestMenu() {
  Menu() {
    createCollaborationServiceMenuItems([CollaborationServiceFilter.ALL]);
  }
}
```
4.
在build方法中添加弹窗组件 [CollaborationServiceStateDialog](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/ArkTS 组件/servicecollaboration-collaborationservice.md) ，用于提示远端相机拍摄状态和回传数据，需要实现其中的 [onState](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/ArkTS 组件/servicecollaboration-collaborationservice.md) 方法。 [CollaborationServiceStateDialog](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/ArkTS 组件/servicecollaboration-collaborationservice.md) 是全局的提示框，不会对原有布局产生影响。
5.
为弹窗组件绑定和实现 [onState](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/ArkTS 组件/servicecollaboration-collaborationservice.md) 方法，用于接收和处理照片数据。
回调函数的传入参数stateCode是完成状态，buffer是回传的数据内容，可通过状态和数据内容结合自身的业务逻辑实现 [onState](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Service Collaboration Kit（协同服务）/ArkTS 组件/servicecollaboration-collaborationservice.md) 方法。
```typescript
CollaborationServiceStateDialog({
  onState: (stateCode: number, bufferType: string, buffer: ArrayBuffer):void => this.doInsertPicture(stateCode, bufferType, buffer)
})
```
#### 跨设备互通完整示例
通过以下示例，您可以完成一次调用对端相机拍摄的操作。
```typescript
import {
  createCollaborationServiceMenuItems,
  CollaborationServiceStateDialog,
  CollaborationServiceFilter
} from '@kit.ServiceCollaborationKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
@Entry
@Component
struct Index {
  @State picture: PixelMap | undefined = undefined;
  @Builder
  myTestMenu() {
    Menu() {
      createCollaborationServiceMenuItems([CollaborationServiceFilter.ALL]);
    }
  }
  build() {
    Column({ space: 20 }) {
      CollaborationServiceStateDialog({
        onState: (stateCode: number, bufferType: string, buffer: ArrayBuffer): void => this.doInsertPicture(stateCode,
          bufferType, buffer)
      })
      Button('使用远端设备进行拍照')
        .type(ButtonType.Normal)
        .borderRadius(10)
        .bindMenu(this.myTestMenu)
      if (this.picture) {
        Image(this.picture)
          .borderStyle(BorderStyle.Dotted)
          .borderWidth(1)
          .objectFit(ImageFit.Contain)
          .height('80%')
          .onComplete((event) => {
            if (event != undefined) {
              hilog.info(0, 'MEMOMOCK', 'onComplete ' + event.loadingStatus);
            }
          })
      }
    }
    .padding(20)
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
  doInsertPicture(stateCode: number, bufferType: string, buffer: ArrayBuffer): void {
    if (stateCode != 0) {
      return;
    }
    if (bufferType == 'general.image') {
      let imageSource = image.createImageSource(buffer);
      imageSource.createPixelMap().then((pixelMap) => {
        this.picture = pixelMap;
      }).catch((error: Error) => {
        hilog.info(0, 'MEMOMOCK', 'Create pixel map failed: ' + error);
      }).finally(() => {
        imageSource.release();
      });
    }
  }
}
```
#### 示例代码
[跨设备互通](https://gitcode.com/harmonyos_samples/service-collaboration-kit-sample-code-arkts)