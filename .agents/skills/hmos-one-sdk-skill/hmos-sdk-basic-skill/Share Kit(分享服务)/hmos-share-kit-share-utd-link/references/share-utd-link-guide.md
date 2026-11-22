# 分享链接

## 分享App Linking直达应用

使用App Linking分享应用,目标设备接收后可直达应用,参见: [使用App Linking实现应用间跳转](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-linking-startup)。

![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/13/v3/mqHaL3yFQZmuL8xBEKY0yw/zh-cn_image_0000002628701980.png?HW-CC-KV=V1&HW-CC-Date=20260701T105318Z&HW-CC-Expire=86400&HW-CC-Sign=D464C47ABB8CD9BEAB8B6D2AEC4B2156DCB142100548A0E5A1F33DC37CE552E2)

### 开发步骤

1. 开通App Linking服务,并完成相关配置,App Linking需经过调试。参见: [调试App Linking](https://developer.huawei.com/consumer/cn/doc/AppGallery-connect-Guides/agc-applinking-debug-0000001059139667)。

2. 在应用配置文件(src/main/module.json5)的 [skills](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/module-configuration-file) 配置中增加关联配置。参见: [声明应用关联的网站域名](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-linking-startupapp)。

3. 使用App Linking发起系统分享。

```typescript
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Component
export default struct Index {
  private async share() {
    // 生成应用图标缩略图
    let uiContext: UIContext = this.getUIContext();
    let contextFaker: Context = uiContext.getHostContext() as Context;
    let thumbnailPath = contextFaker.filesDir + '/exampleImage.jpg';
    let imageSource: image.ImageSource = image.createImageSource(thumbnailPath);
    let imagePacker: image.ImagePacker = image.createImagePacker();
    let buffer: ArrayBuffer = await imagePacker.packToData(imageSource, {
      format: 'image/jpeg',
      quality: 30
    });
    
    // 构造ShareData,需配置一条有效数据信息
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.HYPERLINK,
      content: 'https://sharekitdemo.drcn.agconnect.link/ZB3p',
      title: '应用名称',
      description: '应用描述',
      thumbnail: new Uint8Array(buffer)
    });
    
    // 进行分享面板显示
    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
    controller.show(context, {
      previewMode: systemShare.SharePreviewMode.DEFAULT,
      selectionMode: systemShare.SelectionMode.SINGLE
    }).then(() => {
      console.info('ShareController show success.');
    }).catch((error: BusinessError) => {
      console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
    });
  }
  
  build() {
    Button('分享')
      .onClick(() => this.share())
  }
}
```

4. 目标应用处理App Linking。参见: [拉起方实现跳转指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-linking-startupapp)。

```typescript
import { common, OpenLinkOptions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct Index {
  build() {
    Button('start link', { type: ButtonType.Capsule, stateEffect: true })
      .width('87%')
      .height('5%')
      .margin({ bottom: '12vp' })
      .onClick(() => {
        let uiContext: UIContext = this.getUIContext();
        let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
        let link: string = "https://www.example.com/programs?action=showall";
        let openLinkOptions: OpenLinkOptions = {
          appLinkingOnly: false
        };
        context.openLink(link, openLinkOptions)
          .then(() => {
            console.info('openlink success.');
          })
          .catch((error: BusinessError) => {
            console.error(`openlink failed. code: ${error.code}, message: ${error.message}`);
          });
      })
  }
}
```

完整示例代码请参见: [samplecode-分享App Linking直达应用](https://gitcode.com/harmonyos_samples/share-kit_-sample-code_-clientdemo_-arkts/blob/master/entry/src/main/ets/scenario/AppLinkingScenario.ets)。

## 分享普通链接直达浏览器

普通链接分享支持将网页链接到目标设备/目标应用。
- 目标设备接收时,通过浏览器直接打开链接。
- 目标应用接收时,可便捷地处理链接内容。例如:将一个链接分享给畅连,发送给畅连好友。

### 开发步骤

1. 导入相关模块。

```typescript
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

2. 构造分享数据。

```typescript
let shareData: systemShare.SharedData = new systemShare.SharedData({
  utd: utd.UniformDataType.HYPERLINK,
  content: 'https://www.vmall.com/index.html?cid=128688',
  title: '华为商城',
  description: '华为手机'
});
```

3. 额外增加一条数据。

```typescript
shareData.addRecord({
  utd: utd.UniformDataType.HYPERLINK,
  content: 'https://www.vmall.com/index.html?cid=128688',
  title: '测试链接',
  description: '测试描述'
});
```

4. 启动分享面板。

```typescript
let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
let uiContext: UIContext = this.getUIContext();
let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
controller.show(context, {
  selectionMode: systemShare.SelectionMode.SINGLE,
  previewMode: systemShare.SharePreviewMode.DEFAULT
}).then(() => {
  console.info('ShareController show success.');
}).catch((error: BusinessError) => {
  console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
});
```

完整示例代码请参见: [samplecode-分享普通链接直达浏览器](https://gitcode.com/harmonyos_samples/share-kit_-sample-code_-clientdemo_-arkts/blob/master/entry/src/main/ets/scenario/LinkScenario.ets)。