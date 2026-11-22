# 通过分享面板发起分享
---
# 通过分享面板发起分享
#### 接口说明
**表1** 宿主应用发起分享接口功能介绍
| 类名 | 接口名 | 描述 |
| --- | --- | --- |
| SharedData | [constructor](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Share Kit（分享服务）/ArkTS API/share-system-share)(record:[SharedRecord](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Share Kit（分享服务）/ArkTS API/share-system-share)) | SharedData构造函数 |
| SharedData | [addRecord](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Share Kit（分享服务）/ArkTS API/share-system-share)(record:[SharedRecord](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Share Kit（分享服务）/ArkTS API/share-system-share)): void | 添加分享记录 |
| SharedData | [getRecords](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Share Kit（分享服务）/ArkTS API/share-system-share)(): Array<[SharedRecord](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Share Kit（分享服务）/ArkTS API/share-system-share)> | 获取分享记录 |
| ShareController | [constructor](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Share Kit（分享服务）/ArkTS API/share-system-share)(data:[SharedData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Share Kit（分享服务）/ArkTS API/share-system-share)) | ShareController构造函数 |
| ShareController | [show](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Share Kit（分享服务）/ArkTS API/share-system-share)(context:[common.UIAbilityContext](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/js-apis-inner-application-uiabilitycontext), options:[ShareControllerOptions](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Share Kit（分享服务）/ArkTS API/share-system-share)): Promise<void> | 显示分享面板 |
| ShareController | [on](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Share Kit（分享服务）/ArkTS API/share-system-share)(event: 'dismiss', callback: () => void): void | 注册分享面板关闭事件监听 |
| ShareController | [off](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Share Kit（分享服务）/ArkTS API/share-system-share)(event: 'dismiss', callback: () => void): void | 取消分享面板关闭事件监听 |
#### 开发步骤
根据不同的分享场景，参考下表：
| 分享场景 | 参考链接 |
| --- | --- |
| 分享App Linking直达应用 | [分享App Linking直达应用](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/share-utd-link) |
| 分享图片 | [分享图片](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/share-utd-image) |
| 分享视频 | [分享视频](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/share-utd-video) |
| 分享普通链接直达浏览器 | [分享普通链接直达浏览器](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/share-utd-link) |
| 分享文本 | [分享文本](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/share-utd-text) |
**2in1设备可通过配置的方式决定分享面板的显示位置。** 参考如下：
1.
导入相关模块。
```typescript
import { common } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
```
2.
构造分享数据，可添加多条分享记录。
```typescript
// 构造ShareData，需配置一条有效数据信息
let data: systemShare.SharedData = new systemShare.SharedData({
  utd: utd.UniformDataType.PLAIN_TEXT,
  content: 'Hello HarmonyOS'
});
```
3.
启动分享面板时，配置分享面板显示的位置信息或关联的组件ID，面板将以Popup形式展示。
```typescript
// 构建ShareController
let controller: systemShare.ShareController = new systemShare.ShareController(data);
// 获取UIAbility上下文对象
let uiContext: UIContext = this.getUIContext();
let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
// 注册分享面板关闭监听
controller.on('dismiss', () => {
  console.info('Share panel closed');
  // 分享结束，可处理其他业务。
});
// 进行分享面板显示
// 方法一：配置分享面板关联的控件ID
controller.show(context, {
  anchor: 'shareButtonId'
});
// 方法二：配置分享面板显示的坐标
controller.show(context, {
  anchor: {
    // 必选 相对锚点的窗体偏移值
    windowOffset: { x: 100, y: 100 },
    // 可选 组件的宽高 配置后会综合计算组件的大小
    size: { width: 0, height: 0 }
  }
});
```