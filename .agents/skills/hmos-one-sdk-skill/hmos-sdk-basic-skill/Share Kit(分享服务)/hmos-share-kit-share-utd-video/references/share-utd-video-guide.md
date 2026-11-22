# 分享视频开发指南

本文档来源于HarmonyOS官方开发指南，介绍如何使用Share Kit实现视频分享功能。

## 功能概述

视频类型分享支持将一个或多个视频分享到目标设备/目标应用。

- 目标设备接收时，视频会保存到图库中。
- 目标应用接收时，可便捷地处理视频内容。例如：将一个视频分享给畅连，发送给畅连好友。

## 开发步骤

### 1. 导入相关模块

```typescript
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { fileUri } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 2. 生成视频封面图（推荐）

```typescript
let uiContext: UIContext = this.getUIContext();
let contextFaker: Context = uiContext.getHostContext() as Context;
let thumbnailPath = contextFaker.filesDir + '/exampleImage.jpg';
let imageSource: image.ImageSource = image.createImageSource(thumbnailPath);
let imagePacker: image.ImagePacker = image.createImagePacker();
let buffer: ArrayBuffer = await imagePacker.packToData(imageSource, {
  format: 'image/jpeg',
  quality: 30
});
```

**注意事项**：
- 当前只支持'image/jpeg','image/webp'和'image/png'类型图片
- JPEG编码质量参数取值范围为0-100
- 建议适当压缩，图片过大无法拉起分享

### 3. 构造分享数据

```typescript
let filePath = contextFaker.filesDir + '/exampleVideo.mp4';
let utdTypeId = utd.getUniformDataTypeByFilenameExtension('.mp4', utd.UniformDataType.VIDEO);
let shareData: systemShare.SharedData = new systemShare.SharedData({
  utd: utdTypeId,
  uri: fileUri.getUriFromPath(filePath),
  title: '视频标题',
  description: '视频描述',
  thumbnail: new Uint8Array(buffer)
});
```

**字段说明**：
- 不传title字段时，显示视频文件名
- 不传description字段时，显示视频大小
- 不传thumbnail字段时，默认使用视频第一帧画面做预览图

**重要提示**：沙箱路径可通过fileUri.getUriFromPath方法获取文件URI。

### 4. 额外增加一条数据（可选）

```typescript
shareData.addRecord({
  utd: utdTypeId,
  uri: fileUri.getUriFromPath(filePath),
  title: '视频标题',
  description: '视频描述'
});
```

### 5. 启动分享面板

```typescript
let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
controller.show(context, {
  selectionMode: systemShare.SelectionMode.SINGLE,
  previewMode: systemShare.SharePreviewMode.DETAIL
}).then(() => {
  console.info('ShareController show success.');
}).catch((error: BusinessError) => {
  console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
});
```

## 完整示例

完整示例代码请参见：[samplecode-分享视频](https://gitcode.com/harmonyos_samples/share-kit_-sample-code_-clientdemo_-arkts/blob/master/entry/src/main/ets/scenario/VideoScenario.ets)

## 参考文档

- [systemShare API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-system-share)
- [fileUri API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-file-fileuri)
- [ImageKit API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-image-imagepacker)