# 宿主应用接入模式
---
# 宿主应用接入模式
为应对开发者接入系统分享能力时的不同诉求，Share Kit支持两种宿主应用接入模式。
| 接入模式 | 接入方式&适用应用类型 | 效果图 |
| --- | --- | --- |
| 全接模式 | **直接使用系统分享面板**适用于华为自研应用以及对分享方式区无商业诉求的开发者，可直接使用系统面板，降低开发成本。 | 直接使用系统分享面板 |
| 半接模式 | **开发者自行开发分享能力面板，并在分享面板中提供系统分享入口**适用于分享方式区有商业诉求，或有自己独有的业务逻辑的开发者 | 左侧为自开发分享面板，同时提供系统分享入口，用户点击时调用系统分享面板 |
#### 全接模式示例代码
[参考：手机应用发起系统分享开发步骤](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/share-mobilephone-app-share)
#### 半接模式示例代码片段
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/e3/v3/DsOA_sCxTu-2KuMegSMetA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105316Z&HW-CC-Expire=86400&HW-CC-Sign=82932D95F010AFACF55B65A841C709FA0E392E497944FB8383E96CD5C5E57A8C)
为了确保用户获得良好的分享体验，图标请使用HarmonyOS系统资源"$r('sys.symbol.share')"，文本使用"系统分享"，请勿自行更改。
```typescript
// 分享图标使用系统提供的Symbol格式图标
SymbolGlyph($r('sys.symbol.share'))
// 文本使用'系统分享'
Text('系统分享')
```
完整示例代码请参见： [samplecode-接入模式](https://gitcode.com/harmonyos_samples/share-kit_-sample-code_-clientdemo_-arkts/blob/master/entry/src/main/ets/components/AccessModel.ets) 。