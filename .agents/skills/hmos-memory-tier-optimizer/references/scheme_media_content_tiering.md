# 方案五：多媒体内容分档降级优化

**适用场景**：滚动列表（List/Grid/WaterFlow）中混合展示图片、视频、直播间等多媒体内容，native heap 占用过高。

**方案原理**：电商类应用首页通常在一个滚动列表中混合展示多种内容类型（商品图片、短视频、直播间入口），它们的内存开销差异巨大：

| 内容类型 | 内存开销 | CPU 开销 | 说明 |
|---------|---------|---------|------|
| 静态图片 | 中 | 低 | 解码后常驻内存，受分辨率影响 |
| 视频 | 高 | 高 | 持续解码+渲染，autoPlay 时 GPU 也参与 |
| 直播间 | 最高 | 最高 | 直播流持续解码，编解码器常驻 |

在低端设备上，视频和直播间是 native heap 飙升的主要因素。通过按设备分档对多媒体内容进行降级（视频→静态封面图、直播间→静态封面图），可在不损失核心功能的前提下大幅降低内存。

## 分档策略

### 内容渲染策略矩阵

| 内容类型 | high（高端机） | medium（中端机） | low（低端机） |
|---------|-------------|--------------|------------|
| 图片 | 原图 / ASTC 6x6 | 压缩图 / ASTC 4x4 | 低分辨率 / webp |
| 视频 | 自动播放 1080p | 手动播放 720p | 静态封面图替代 |
| 直播间 | 实时直播流 | 低分辨率直播流 | 静态封面图替代 |

### 视频配置分档

| 配置项 | high | medium | low |
|-------|------|--------|-----|
| 渲染方式 | Video 组件 | Video 组件 | Image 封面图 |
| autoPlay | true | false | N/A（不渲染 Video） |
| 分辨率 | 1080p | 720p | N/A |
| muted | false | true（节省音频解码） | N/A |

### 直播间配置分档

| 配置项 | high | medium | low |
|-------|------|--------|-----|
| 渲染方式 | 直播播放器 | 直播播放器（低分辨率） | Image 封面图 |
| 分辨率 | 原始流分辨率 | 480p | N/A |
| 预加载 | 预连接直播流 | 不预加载 | 不预加载 |

## 代码修改模板

### 1. 多媒体内容分档策略配置类

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范
// MediaContentTier.ets
import { DeviceLevelDecisionCenter, DeviceLevel } from './DeviceLevelDecisionCenter';

export class MediaContentLevel {
  static readonly ORIGINAL: string = 'original';   // 原始内容
  static readonly COMPRESSED: string = 'compressed'; // 压缩内容
  static readonly STATIC: string = 'static';        // 静态封面图
}

export class MediaContentTier {
  /**
   * 获取视频渲染策略
   * 返回 'original'（Video 组件自动播放）、'compressed'（Video 组件手动播放）、'static'（Image 封面图）
   */
  static getVideoRenderStrategy(): string {
    let level: string = DeviceLevelDecisionCenter.getDeviceLevel();
    if (level === DeviceLevel.TIER_LOW) {
      return MediaContentLevel.STATIC;
    } else if (level === DeviceLevel.TIER_MEDIUM) {
      return MediaContentLevel.COMPRESSED;
    }
    return MediaContentLevel.ORIGINAL;
  }

  /**
   * 获取直播间渲染策略
   */
  static getLiveStreamRenderStrategy(): string {
    let level: string = DeviceLevelDecisionCenter.getDeviceLevel();
    if (level === DeviceLevel.TIER_LOW) {
      return MediaContentLevel.STATIC;
    } else if (level === DeviceLevel.TIER_MEDIUM) {
      return MediaContentLevel.COMPRESSED;
    }
    return MediaContentLevel.ORIGINAL;
  }

  /**
   * 视频是否自动播放
   */
  static shouldVideoAutoPlay(): boolean {
    let level: string = DeviceLevelDecisionCenter.getDeviceLevel();
    if (level === DeviceLevel.TIER_LOW) {
      return false;  // 低端机不渲染 Video，不会调用
    } else if (level === DeviceLevel.TIER_MEDIUM) {
      return false;  // 中端机不自动播放
    }
    return true;     // 高端机自动播放
  }

  /**
   * 获取视频目标分辨率高度 (px)
   */
  static getVideoTargetHeight(): number {
    let level: string = DeviceLevelDecisionCenter.getDeviceLevel();
    if (level === DeviceLevel.TIER_LOW) {
      return 0;      // 不渲染 Video
    } else if (level === DeviceLevel.TIER_MEDIUM) {
      return 720;
    }
    return 1080;
  }

  /**
   * 视频是否静音（节省音频解码开销）
   */
  static shouldVideoMuted(): boolean {
    let level: string = DeviceLevelDecisionCenter.getDeviceLevel();
    if (level === DeviceLevel.TIER_MEDIUM) {
      return true;   // 中端机静音，减少 CPU 开销
    }
    return false;
  }
}
```

### 2. 在 ListItem 中条件渲染视频/直播间

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范
import { MediaContentTier, MediaContentLevel } from '../../utils/MediaContentTier';
import { DeviceLevelDecisionCenter } from '../../utils/DeviceLevelDecisionCenter';

@Component
struct MediaListItem {
  @Prop item: MediaItem;
  @State videoStrategy: string = MediaContentLevel.ORIGINAL;
  @State liveStrategy: string = MediaContentLevel.ORIGINAL;

  aboutToAppear(): void {
    this.videoStrategy = MediaContentTier.getVideoRenderStrategy();
    this.liveStrategy = MediaContentTier.getLiveStreamRenderStrategy();
  }

  build() {
    Row() {
      // 视频类型内容：条件渲染
      if (this.item.type === 'video') {
        if (this.videoStrategy === MediaContentLevel.STATIC) {
          // 低端机：用封面图替代视频
          Image(this.item.coverUrl)
            .width('100%')
            .height(200)
            .autoResize(true)
            .objectFit(ImageFit.Cover)
        } else {
          // 中高端机：渲染视频组件
          Video({ src: this.item.videoUrl, previewUri: this.item.coverUrl })
            .width('100%')
            .height(200)
            .autoPlay(MediaContentTier.shouldVideoAutoPlay())
            .muted(MediaContentTier.shouldVideoMuted())
            .objectFit(ImageFit.Cover)
        }
      }

      // 直播间类型内容：条件渲染
      if (this.item.type === 'live') {
        if (this.liveStrategy === MediaContentLevel.STATIC) {
          // 低端机：用封面图替代直播间
          Stack() {
            Image(this.item.coverUrl)
              .width('100%')
              .height(200)
              .autoResize(true)
              .objectFit(ImageFit.Cover)
            // 可选：叠加"直播中"标签，提示用户点击可查看
            Text('直播中')
              .fontSize(12)
              .fontColor(Color.White)
              .backgroundColor('#FF000080')
              .borderRadius(4)
              .padding({ left: 4, right: 4, top: 2, bottom: 2 })
          }
          .width('100%')
          .height(200)
        } else if (this.liveStrategy === MediaContentLevel.COMPRESSED) {
          // 中端机：低分辨率直播流
          Video({ src: this.item.liveStreamUrl, previewUri: this.item.coverUrl })
            .width('100%')
            .height(200)
            .autoPlay(false) // 中端机不自动播放直播流
            .muted(true)
            .objectFit(ImageFit.Cover)
        } else {
          // 高端机：完整直播体验
          Video({ src: this.item.liveStreamUrl, previewUri: this.item.coverUrl })
            .width('100%')
            .height(200)
            .autoPlay(true)
            .muted(false)
            .objectFit(ImageFit.Cover)
        }
      }
    }
  }
}
```

## 检测规则

```
规则: 多媒体内容未按设备分档降级
检测条件（满足以下任一组即触发）:

  组 A - 视频分档问题:
  - UI 树中存在 Video 组件（type 包含 "Video"）
  - 代码中 Video() 组件设置了 .autoPlay(true) 但无设备分档条件
  - native heap PSS 占比 > 40% 且滚动列表中存在视频类型 Item

  组 B - 直播间分档问题:
  - 代码中存在直播流 URL 加载（live:// / rtmp:// / 直播相关 API）
  - 滚动列表内渲染直播组件但无条件降级逻辑

  组 C - 列表内混合多媒体:
  - 滚动容器（List/Grid/WaterFlow）内同时存在图片+视频+直播 Item
  - 所有 Item 类型使用相同渲染策略（无分档）
  - native heap PSS > 45%

定位方法:
  → UI 树 JSON: 递归查找 type 包含 "Video" 的节点，统计数量
  → 代码搜索: "Video(" → 定位视频组件文件
  → 代码搜索: ".autoPlay(" → 检查是否有设备分档条件
  → 代码搜索: "live://" / "rtmp://" → 检查直播流加载
  → 检查 ListItem 渲染逻辑：是否有 if/else 基于设备分档的条件渲染
  → 结合 meminfo native heap 占比评估影响程度
级别: High (已有优化方案)
```

## 预期效果

| 场景 | 优化前（低端机） | 优化后（低端机） | 说明 |
|------|-------------|-------------|------|
| 首页混合列表 | 渲染 3 个视频 + 2 个直播间 | 全部降级为封面图 | Video 组件解码器内存释放 |
| 视频自动播放 | 全部自动播放 | 不自动播放 / 不渲染 | GPU 内存大幅降低 |
| 直播间 | 直播流持续解码 | 静态封面图 | 解码器 CPU/内存释放 |

**内存降幅预估（低端机）**：
- 每个 Video 组件约占 20-50MB native heap
- 每个直播流约占 30-80MB native heap
- 降级为静态封面图后，单 Item 可节省 20-80MB

## 注意事项

- 本方案与方案二（图片资源内存优化）互补：方案二优化图片本身，本方案优化内容类型选择
- 封面图也应遵循方案二的 autoResize 和缓存分档策略
- 用户点击静态封面图时，可按需跳转到详情页播放视频/直播（不影响体验）
- 条件渲染的 if/else 逻辑确保低端机根本不创建 Video 组件，而非仅隐藏
