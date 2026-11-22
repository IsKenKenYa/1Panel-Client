# 分享图片
---
# 分享图片
图片类型分享支持将一张或多张图片分享到目标设备/目标应用。
-
目标设备接收时，图片会保存到图库中。
-
目标应用接收时，可便捷的处理图片内容。例如：将一张图片分享给畅连，发送给畅连好友。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/9b/v3/98fGDmFvTf2c3Gfl3GfRBg/zh-cn_image_0000002659101209.png?HW-CC-KV=V1&HW-CC-Date=20260701T105318Z&HW-CC-Expire=86400&HW-CC-Sign=351C4C3FC537711E707EE2BAB502929058EB399DF488904C2BCCB90B2B5D2E2F)
#### 开发步骤
1.
导入相关模块。
```typescript
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { fileUri } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
```
2.
构造分享数据。
```typescript
// 构造ShareData，需配置一条有效数据信息
let uiContext: UIContext = this.getUIContext();
let contextFaker: Context = uiContext.getHostContext() as Context;
let filePath = contextFaker.filesDir + '/exampleImage.jpg'; // 仅为示例 请替换正确的文件路径
// 获取精准的utd类型
let utdTypeId = utd.getUniformDataTypeByFilenameExtension('.jpg', utd.UniformDataType.IMAGE);
let shareData: systemShare.SharedData = new systemShare.SharedData({
  utd: utdTypeId,
  uri: fileUri.getUriFromPath(filePath),
  title: '图片标题', // 不传title字段时,显示图片文件名
  description: '图片描述', // 不传description字段时,显示图片大小
  // thumbnail: new Uint8Array() // 优先使用传递的缩略图预览  不传则默认使用原图做预览图
});
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/35/v3/A8I2Iq_cQ6iGhQxl5y1yDA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105318Z&HW-CC-Expire=86400&HW-CC-Sign=01FBEEA2B0406E4D727A5CBC7A5284C31F89F78C256FA394C56AFAFE1923D370)
沙箱路径可通过 [fileUri.getUriFromPath](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Core File Kit（文件基础服务）/ArkTS API/js-apis-file-fileuri.md) 方法获取文件URI。
3.
额外增加一条数据。
```typescript
shareData.addRecord({
  utd: utdTypeId,
  uri: fileUri.getUriFromPath(filePath),
  title: '图片标题', // 不传title字段时,显示图片文件名
  description: '图片描述' // 不传description字段时,显示图片大小
});
```
4.
启动分享面板。
```typescript
// 进行分享面板显示
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
完整示例代码请参见： [samplecode-分享图片](https://gitcode.com/harmonyos_samples/share-kit_-sample-code_-clientdemo_-arkts/blob/master/entry/src/main/ets/scenario/ImageScenario.ets) 。