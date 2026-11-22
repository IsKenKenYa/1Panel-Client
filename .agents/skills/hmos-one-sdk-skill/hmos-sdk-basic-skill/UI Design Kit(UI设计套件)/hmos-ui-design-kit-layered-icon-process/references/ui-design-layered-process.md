# （推荐）分层图标处理
---
# （推荐）分层图标处理
#### 场景介绍
从5.0.0(12)版本开始， Hds支持分层图标处理能力。
适用于图标为分层资源，且图标展示风格要与华为HarmonyOS Design System设计风格一致的应用场景。以下是一些典型的应用场景：
-
展示带图标的应用列表：可调用UI Design Kit批量处理分层图标的接口获取处理后的应用图标。
-
展示应用详情：可调用UI Design Kit处理单个分层图标的接口获取处理后的应用图标。
-
展示跟随在线主题的应用图标：可调用UI Design Kit处理分层图标的接口获取主题换肤后的应用图标。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/c6/v3/qwW91ogXSMquD3tGcySQLg/zh-cn_image_0000002659100263.png?HW-CC-KV=V1&HW-CC-Date=20260701T104729Z&HW-CC-Expire=86400&HW-CC-Sign=1AB230B56EE05997EBD43D450AB786FC4E9BE575E0B12E3CBF44601C014584C3) ![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/d1/v3/k4AEQNjqSxuTkNxRWotnDQ/zh-cn_image_0000002628860914.png?HW-CC-KV=V1&HW-CC-Date=20260701T104729Z&HW-CC-Expire=86400&HW-CC-Sign=6D4D24B8FB8F4527A2FF09DEFCE163087443B7411C91C120D6CE80BD0840482D) ![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/b2/v3/hwpj5jd0QKCFu85fD33ukQ/zh-cn_image_0000002659220229.png?HW-CC-KV=V1&HW-CC-Date=20260701T104729Z&HW-CC-Expire=86400&HW-CC-Sign=BD243E686D5BA5ADD3E6C781B5845B118B8EFE6CFDAC1E43E3AD8651CC93FBC6)
#### 约束条件
分层图标处理支持Phone、Tablet、PC/2in1设备，并且从5.1.1(19)版本开始，新增支持TV设备。
#### 开发步骤
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/83/v3/_O7KC_cNQx6fJYLfN6oAYw/zh-cn_image_0000002628701036.png?HW-CC-KV=V1&HW-CC-Date=20260701T104729Z&HW-CC-Expire=86400&HW-CC-Sign=81A1D97C4DEBB298CAC90417F69744120FD218B1279571604262D2923D8825ED)
1.
设置分层图标，将前景资源和背景资源放至entry/src/main/resources/base/media文件中，并在该目录下创建一个json文件（例如：drawable.json）：
```typescript
{
  "layered-image":
  {
    "background" : "$media:background",
    "foreground" : "$media:foreground"
  }
}
```
2.
将图标处理的相关类添加至工程。
```typescript
import { LayeredDrawableDescriptor } from '@kit.ArkUI';
import { hdsDrawable } from '@kit.UIDesignKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { resourceManager } from '@kit.LocalizationKit';
import { common } from '@kit.AbilityKit';
```
3.
简单配置页面的布局，调用 [分层图标接口](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/UI Design Kit（UI设计套件）/ArkTS API/ui-design-hdsdrawable.md) 获取处理后的图标信息，也可以调用 [异步批量处理接口](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/UI Design Kit（UI设计套件）/ArkTS API/ui-design-hdsdrawable.md) 。
```typescript
@Entry
@Component
struct Index{
  bundleName: string = 'com.example.uidesignkit';
  resManager: resourceManager.ResourceManager | undefined = undefined;
  layeredDrawableDescriptor: LayeredDrawableDescriptor | undefined = undefined;
  @State layeredIconsResult: Array<hdsDrawable.ProcessedIcon> = [];
  build() {
    Column() {
      Column() {
        Text('getHdsLayeredIcon')
          .fontWeight(FontWeight.Bold)
          .fontSize(16)
          .margin(5)
        Image(this.getHdsLayeredIcon())
          .width(48)
          .height(48)
      }
      .margin(20)
      Text('getHdsLayeredIcons')
        .fontWeight(FontWeight.Bold)
        .fontSize(16)
        .margin(5)
      List() {
        ForEach(this.layeredIconsResult,
          (item: hdsDrawable.ProcessedIcon, index?: number) => {
            ListItem() {
              Column() {
                Text(item.bundleName)
                  .fontWeight(FontWeight.Medium)
                  .fontSize(16)
                  .margin(5)
                Image(item.pixelMap)
                  .width(48)
                  .height(48)
              }
              .margin(15)
            }
            .width('100%')
          }, (item: string) => item.toString())
      }
      .scrollBar(BarState.On)
      .height('60%')
    }
    .height('100%')
    .width('100%')
  }
  aboutToAppear(): void {
    // 获取资源管理器
    this.resManager = (this.getUIContext().getHostContext() as common.UIAbilityContext)?.resourceManager;
    if (!this.resManager) {
      return;
    }
    // 通过资源管理获取原始分层图标信息
    this.layeredDrawableDescriptor = (this.resManager.getDrawableDescriptor($r('app.media.drawable')
      .id)) as LayeredDrawableDescriptor;
    this.getHdsLayeredIcons();
  }
  private getHdsLayeredIcon(): image.PixelMap | null {
    try {
      // 调用HDS分层图标接口处理图标
      return hdsDrawable.getHdsLayeredIcon(this.bundleName, this.layeredDrawableDescriptor, 48, true);
    } catch (err) {
      let message = (err as BusinessError).message;
      let code = (err as BusinessError).code;
      console.error(`getHdsLayeredIcon failed, code: ${code}, message: ${message}`);
      return null;
    }
  }
  private getHdsLayeredIcons(): void {
    if (!this.layeredDrawableDescriptor) {
      console.error(`getHdsLayeredIcons layeredDrawableDescriptor is undefined.`);
      return;
    }
    // 构造批量接口传参
    let options: hdsDrawable.Options = {
      size: 48,
      hasBorder: true,
      parallelNumber: 4
    };
    let layeredIcons: Array<hdsDrawable.LayeredIcon> = [];
    for (let i = 0; i < 10; i++) {
      layeredIcons.push({
        bundleName: `${this.bundleName}-${i}`,
        layeredDrawableDescriptor: this.layeredDrawableDescriptor
      });
    }
    try {
      // 调用HDS批量分层接口处理图标
      hdsDrawable.getHdsLayeredIcons(layeredIcons, options)
        .then((data: Array<hdsDrawable.ProcessedIcon>) => {
          console.info(`getHdsLayeredIcons data size: ${data.length}`);
          this.layeredIconsResult = data;
        })
        .catch((err: BusinessError) => {
          console.error(`getHdsLayeredIcons return error, code: ${err.code}, msg: ${err.message}`);
        });
    } catch (err) {
      let message = (err as BusinessError).message;
      let code = (err as BusinessError).code;
      console.error(`getHdsLayeredIcons failed, code: ${code}, message: ${message}`);
    }
  }
}
```