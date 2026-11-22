# 识别本地图片
---
# 识别本地图片
图片识码能力支持对图库中的码图进行扫描识别，并获取信息。
#### 场景介绍
图片识码能力支持对图库中的条形码、二维码、MULTIFUNCTIONAL CODE进行识别，并获得码类型、码值、码位置等信息。该能力可用于一图单码和一图多码的识别，比如条形码、付款码等。
#### 业务流程
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/05/v3/OBRMWp0pTKGykL4cxtrtpw/zh-cn_image_0000002628861268.png?HW-CC-KV=V1&HW-CC-Date=20260701T105042Z&HW-CC-Expire=86400&HW-CC-Sign=2F6B34D00416400EAAE1B9009859066B6C887FBB9E76C99C5D61DCE68670C161)
1.
用户向开发者的应用发起图片识码请求。
2.
应用通过调用Scan Kit的decode接口启动图片识码。
3.
Scan Kit通过回调返回图片识码结果。
4.
应用向用户返回扫码结果。
#### 接口说明
接口返回值有两种返回形式：Callback和Promise回调。下表中为启动图片识码Callback和Promise形式接口，Callback和Promise只是返回值方式不一样，功能相同。具体API说明详见 [接口文档](D:/code/APIDevice/output/md_output/harmonyos-references/媒体/Scan Kit（统一扫码服务）/ArkTS API/scan-imagedecode.md) 。
| 接口名 | 描述 |
| --- | --- |
| [decode](D:/code/APIDevice/output/md_output/harmonyos-references/媒体/Scan Kit（统一扫码服务）/ArkTS API/scan-imagedecode.md)(inputImage:[InputImage](D:/code/APIDevice/output/md_output/harmonyos-references/媒体/Scan Kit（统一扫码服务）/ArkTS API/scan-imagedecode.md), options?: scanBarcode.[ScanOptions](D:/code/APIDevice/output/md_output/harmonyos-references/媒体/Scan Kit（统一扫码服务）/ArkTS API/scan-scanbarcode-api.md)): Promise<Array<scanBarcode.[ScanResult](D:/code/APIDevice/output/md_output/harmonyos-references/媒体/Scan Kit（统一扫码服务）/ArkTS API/scan-scanbarcode-api.md)>> | 启动图片识码，通过InputImage传入图片信息，通过ScanOptions进行识码参数设置（options为可选参数），使用Promise异步回调返回识码结果。 |
| [decode](D:/code/APIDevice/output/md_output/harmonyos-references/媒体/Scan Kit（统一扫码服务）/ArkTS API/scan-imagedecode.md)(inputImage: InputImage, options: scanBarcode.ScanOptions, callback: AsyncCallback<Array<scanBarcode.ScanResult>>): void | 启动图片识码，通过InputImage传入图片信息，通过ScanOptions进行识码参数设置，使用Callback异步回调返回识码结果。 |
| [decode](D:/code/APIDevice/output/md_output/harmonyos-references/媒体/Scan Kit（统一扫码服务）/ArkTS API/scan-imagedecode.md)(inputImage: InputImage, callback: AsyncCallback<Array<scanBarcode.ScanResult>>): void | 启动图片识码，通过InputImage传入图片信息，使用Callback异步回调返回识码结果。 |
#### 开发步骤
图片识码接口支持识别图库中的条形码，二维码以及MULTIFUNCTIONAL CODE，并返回图片中码类型，码值、码位置（码图最小外接矩形左上角和右下角的坐标）等信息。
为了方便开发者接入，我们提供了详细的样例工程供参考，推荐参考 [示例工程](https://gitcode.com/HarmonyOS_Samples/scankit-samplecode-clientdemo-arkts) 接入。
以下示例为调用图片识码的detectBarcode.decode接口获取码图信息。
1.
导入图片识码接口和相关接口模块，该接口提供了图片识码参数和方法，导入方法如下。
```typescript
// 导入图片识码需要的日志和picker模块
import { scanCore, scanBarcode, detectBarcode } from '@kit.ScanKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
```
2.
调用detectBarcode.decode接口解析码图。
-
[picker](D:/code/APIDevice/output/md_output/harmonyos-guides/媒体/Media Library Kit（媒体文件管理服务）/使用Picker选择媒体库资源/photoaccesshelper-photoviewpicker.md)
```typescript
@Entry
@Component
struct DetectPage {
  build() {
    Column() {
      Button('Promise with options')
        .backgroundColor('#0D9FFB')
        .fontSize(20)
        .fontColor($r('sys.color.comp_background_list_card'))
        .fontWeight(FontWeight.Normal)
        .align(Alignment.Center)
        .type(ButtonType.Capsule)
        .width('90%')
        .height(40)
        .margin({ top: 5, bottom: 5 })
        .onClick(() => {
          // 定义识码参数options
          let options: scanBarcode.ScanOptions = {
            scanTypes: [scanCore.ScanType.ALL],
            enableMultiMode: true
          };
          // 通过picker拉起图库的图片
          let photoOption = new photoAccessHelper.PhotoSelectOptions();
          photoOption.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
          photoOption.maxSelectNumber = 1;
          let photoPicker = new photoAccessHelper.PhotoViewPicker();
          photoPicker.select(photoOption).then((data) => {
            // 定义识码参数inputImage，其中uri为picker选择图片
            let inputImage: detectBarcode.InputImage = { uri: data.photoUris[0] };
            try {
              // 调用图片识码接口
              detectBarcode.decode(inputImage, options).then((data: Array<scanBarcode.ScanResult>) => {
                hilog.info(0x0001, '[Scan Sample]',
                  `Succeeded in getting ScanResult by promise with options, result is ${JSON.stringify(data)}`);
              }).catch((err: BusinessError) => {
                hilog.error(0x0001, '[Scan Sample]',
                  `Failed to get ScanResult by promise with options. Code: ${err.code}, message: ${err.message}`);
              });
            } catch (err) {
              hilog.error(0x0001, '[Scan Sample]',
                `Failed to detectBarcode. Code: ${err.code}, message: ${err.message}`);
            }
          }).catch((err: BusinessError) => {
            hilog.error(0x0001, '[Scan Sample]',
              `Failed to select a photo. Code: ${err.code}, message: ${err.message}`);
          });
        })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
```
-
[picker](D:/code/APIDevice/output/md_output/harmonyos-guides/媒体/Media Library Kit（媒体文件管理服务）/使用Picker选择媒体库资源/photoaccesshelper-photoviewpicker.md)
```typescript
@Entry
@Component
struct DetectPage {
  build() {
    Column() {
      Button('Callback with options')
        .backgroundColor('#0D9FFB')
        .fontSize(20)
        .fontColor($r('sys.color.comp_background_list_card'))
        .fontWeight(FontWeight.Normal)
        .align(Alignment.Center)
        .type(ButtonType.Capsule)
        .width('90%')
        .height(40)
        .margin({ top: 5, bottom: 5 })
        .onClick(() => {
          // 定义识码参数options
          let options: scanBarcode.ScanOptions = {
            scanTypes: [scanCore.ScanType.ALL],
            enableMultiMode: true,
            enableAlbum: true
          };
          // 通过选择模式拉起photoPicker界面，用户可以选择一个图片
          let photoOption = new photoAccessHelper.PhotoSelectOptions();
          photoOption.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
          photoOption.maxSelectNumber = 1;
          let photoPicker = new photoAccessHelper.PhotoViewPicker();
          photoPicker.select(photoOption).then((data) => {
            // 定义识码参数inputImage，其中uri为picker选择图片
            let inputImage: detectBarcode.InputImage = { uri: data.photoUris[0] };
            try {
              // 调用图片识码接口
              detectBarcode.decode(inputImage, options,
                (err: BusinessError, data: Array<scanBarcode.ScanResult>) => {
                  if (err && err.code) {
                    hilog.error(0x0001, '[Scan Sample]',
                      `Failed to get ScanResult by callback with options. Code: ${err.code}, message: ${err.message}`);
                    return;
                  }
                  hilog.info(0x0001, '[Scan Sample]',
                    `Succeeded in getting ScanResult by callback with options, result is ${JSON.stringify(data)}`);
                });
            } catch (err) {
              hilog.error(0x0001, '[Scan Sample]',
                `Failed to detectBarcode. Code: ${err.code}, message: ${err.message}`);
            }
          }).catch((err: BusinessError) => {
            hilog.error(0x0001, '[Scan Sample]',
              `Failed to select a photo. Code: ${err.code}, message: ${err.message}`);
          });
        })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
```
#### 模拟器开发
支持模拟器开发，模拟器使用指导请参见 [使用模拟器运行应用](D:/code/APIDevice/output/md_output/harmonyos-guides/编写与调试应用/使用模拟器运行应用/ide-run-emulator.md) 。