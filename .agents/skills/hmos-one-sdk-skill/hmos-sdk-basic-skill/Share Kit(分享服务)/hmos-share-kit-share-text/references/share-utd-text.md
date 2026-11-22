# 分享文本
---
# 分享文本
纯文本类型分享支持将一段文字分享到目标设备/目标应用。
-
目标设备接收时，文本会转化为.txt文件保存在文件管理中。
-
目标应用接收时，可便捷地处理文本内容。例如：将文字分享给备忘录，可新增一条备忘录内容。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/fe/v3/_0n78FdcQOaHJcU_O5KzwQ/zh-cn_image_0000002659221171.png?HW-CC-KV=V1&HW-CC-Date=20260701T105318Z&HW-CC-Expire=86400&HW-CC-Sign=02AD7D1ECA3CB3F8A940323402AFEF2A8471CC42F6140F3ABD4514841064620A)
#### 开发步骤
1.
导入相关模块。
```typescript
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
```
2.
构造分享数据。
```typescript
// 构造ShareData，需配置一条有效数据信息
let shareData: systemShare.SharedData = new systemShare.SharedData({
  utd: utd.UniformDataType.TEXT,
  content: '这是一段文本内容',
  title: '文本内容', // 不传title字段时,显示content
  description: '文本描述',
  // thumbnail: new Uint8Array() // 推荐传入适合的缩略图 不传则显示默认text图标
});
```
3.
额外增加一条数据。
```typescript
shareData.addRecord({
  utd: utd.UniformDataType.TEXT,
  content: '这是一段文本内容',
  title: '文本内容', // 不传title字段时,显示content
  description: '文本描述'
});
```
4.
启动分享面板。
```typescript
// 进行分享面板显示
let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
let uiContext: UIContext = this.getUIContext();
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
完整示例代码请参见： [samplecode-分享文本](https://gitcode.com/harmonyos_samples/share-kit_-sample-code_-clientdemo_-arkts/blob/master/entry/src/main/ets/scenario/TextScenario.ets) 。