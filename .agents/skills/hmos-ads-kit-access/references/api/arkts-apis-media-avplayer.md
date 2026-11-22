# AVPlayer错误码

> 文档ID: arkts-apis-media-avplayer
> 来源: arkts-apis-media-avplayer.md

---

# AVPlayer

媒体播放器，其on('error')错误码详细介绍了广告视频播放过程中的各种错误类型。

## 核心要点

- AVPlayer 是 HarmonyOS 媒体播放器，广告 SDK 的视频播放（激励视频、贴片、开屏视频）底层依赖该能力
- `on('error')` 回调携带 `BusinessError`，通过 `code` 判断错误类型（如 5400102 资源不可用、5400103 格式不支持等）
- 广告播放异常处理：在 `on('error')` 中做容错，避免影响广告展示主流程

详细文档请参见：[AVPlayer - 华为开发者文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-media-avplayer)
