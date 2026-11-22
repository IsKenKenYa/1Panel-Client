# 方案二：图片资源内存优化

**适用场景**：native heap 占比过高（>50%）、UI 树中存在大量 Image 组件、图片解码内存占用大。

**方案原理**：图片是 native heap 内存的主要消耗源。通过纹理压缩（ASTC/SUT）、预压缩到 UI 尺寸、CDN 裁剪、webp 格式转换、图片缓存分档等手段，可大幅降低图片内存占用。

## 效果参考（华为最佳实践数据）

| 优化手段 | 优化前内存 | 优化后内存 | 降幅 |
|----------|-----------|-----------|------|
| ASTC 纹理压缩（预设图片） | 598,965 KB | 165,015 KB | -72.4% |
| 预压缩到 UI 尺寸（非预设图片） | 90,224 KB | 21,230 KB | -76.5% |

## 设备分档策略

### 纹理压缩格式选择（预设图片）

| 设备分档 | 推荐格式 | 说明 |
|---------|---------|------|
| low | ASTC 4x4 | 高压缩比，低内存，解码快 |
| medium | ASTC 6x6 | 平衡压缩比与质量 |
| high | ASTC 6x6 或原图 | 高端设备可用更高质量 |

### autoResize 阈值（非预设图片）

| 设备分档 | autoResize 策略 | 说明 |
|---------|----------------|------|
| low | 启用，限制最大分辨率 720p | 严格限制解码尺寸 |
| medium | 启用，限制最大分辨率 1080p | 适度限制 |
| high | 启用，限制最大分辨率 1440p | 宽松限制 |

### 图片缓存分档

| 设备分档 | 解码后缓存数量 | 解码前缓存大小 | 磁盘缓存大小 | 说明 |
|---------|--------------|--------------|------------|------|
| low | 0（不缓存） | 0（不缓存） | 50MB | 低内存设备不开启内存缓存，降低磁盘缓存 |
| medium | 50 | 50MB | 100MB | 适度内存缓存 |
| high | 100 | 100MB | 200MB | 完整缓存提升加载速度 |

## 优化手段详解

### 1. 预设图片 → 纹理压缩（ASTC/SUT）

将 png/jpg 等格式转换为 ASTC 或 SUT 格式，显著降低内存和解码时间：

- ASTC（Adaptive Scalable Texture Compression）：块状纹理压缩，支持多种压缩比
- SUT（SUper compression for Texture）：超压缩纹理格式
- 优势：解码时间从 ~62ms 降至 ~15ms，内存降低 70%+

### 2. 非预设图片 → 预压缩到 UI 尺寸

对网络图片/动态图片，在解码前预压缩到实际显示尺寸：

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范
import { DeviceLevelDecisionCenter, DeviceLevel } from '../../utils/DeviceLevelDecisionCenter';
import { image } from '@kit.ImageKit';

// 根据设备分档设置最大解码分辨率
function getMaxDecodeSize(): number {
  let level: string = DeviceLevelDecisionCenter.getDeviceLevel();
  if (level === DeviceLevel.TIER_LOW) {
    return 720;
  } else if (level === DeviceLevel.TIER_MEDIUM) {
    return 1080;
  }
  return 1440;
}
```

### 3. CDN 裁剪 + webp 格式

- 服务端按 UI 尺寸裁剪图片，避免传输和解码过大的图片
- 使用 webp 格式替代 png/jpg，减少传输量和内存占用

### 4. autoResize 属性

Image 组件设置 `.autoResize(true)` 可自动将图片缩放到组件尺寸，但高端设备可保持更高质量。

### 5. 图片缓存分档（setImageCacheCount / setImageRawDataCacheSize / setImageFileCacheSize）

Image 组件提供三级缓存机制：解码后内存缓存、解码前内存缓存、磁盘缓存。默认仅磁盘缓存开启（100MB），内存缓存默认关闭。开启内存缓存可加速同源图片加载，但会占用额外内存。需根据设备档次决定是否开启及缓存上限。

**三级缓存说明：**

| 缓存类型 | API | 默认值 | 存储位置 | 说明 |
|---------|-----|--------|---------|------|
| 解码后内存缓存 | `app.setImageCacheCount(n)` | 0（不缓存） | 内存 | 缓存解码后的图片对象，LRU 策略 |
| 解码前内存缓存 | `app.setImageRawDataCacheSize(bytes)` | 0（不缓存） | 内存 | 缓存解码前的原始图片数据 |

**⚠️ 调用时机**：`setImageCacheCount` 和 `setImageRawDataCacheSize` 需在 `@Entry` 页面的 `onPageShow` 或 `aboutToAppear` 中调用才生效。

## 代码修改模板

### autoResize + 最大分辨率限制

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范
import { DeviceLevelDecisionCenter, DeviceLevel } from '../../utils/DeviceLevelDecisionCenter';

@State imageAutoResize: boolean = true;
@State imageMaxSize: number = 1080;

aboutToAppear() {
  let level: string = DeviceLevelDecisionCenter.getDeviceLevel();
  if (level === DeviceLevel.TIER_LOW) {
    this.imageMaxSize = 720;
  } else if (level === DeviceLevel.TIER_MEDIUM) {
    this.imageMaxSize = 1080;
  } else {
    this.imageMaxSize = 1440;
  }
}

// Image 组件使用
Image(item.avatarUrl)
  .width(48)
  .height(48)
  .autoResize(this.imageAutoResize)
```

### 图片缓存分档配置

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范
// 在 @Entry 页面的 onPageShow 或 aboutToAppear 中调用
import app from '@system.app';
import { DeviceLevelDecisionCenter, DeviceLevel } from '../../utils/DeviceLevelDecisionCenter';

@Entry
@Component
struct Index {
  onPageShow(): void {
    let level: string = DeviceLevelDecisionCenter.getDeviceLevel();
    if (level === DeviceLevel.TIER_LOW) {
      // 低端机：不开启内存缓存，减少磁盘缓存
      app.setImageCacheCount(0);
      app.setImageRawDataCacheSize(0);
    } else if (level === DeviceLevel.TIER_MEDIUM) {
      // 中端机：适度内存缓存
      app.setImageCacheCount(50);
      app.setImageRawDataCacheSize(50 * 1024 * 1024); // 50MB
    } else {
      // 高端机：完整缓存
      app.setImageCacheCount(100);
      app.setImageRawDataCacheSize(100 * 1024 * 1024); // 100MB
    }
  }

  build() {
    // ...
  }
}
```

## 配套最佳实践：PixelMap 降采样

对于需要精确控制解码分辨率的场景（如列表缩略图、头像等），可通过 PixelMap + DecodingOptions 在解码时直接降采样，避免加载原图后再缩放。

### 原理

```
图片内存占用 = 宽度 × 高度 × 每像素字节数（ARGB_8888 = 4 字节）
降采样后: 内存节省 = 1 - (1/采样率)²
```

| 原始分辨率 | 显示区域 | 采样率 | 内存占用 | 节省 |
|-----------|---------|--------|---------|------|
| 4000×3000 | 400×300 | 8 | 0.75MB | 99% |
| 4000×3000 | 800×600 | 4 | 3MB | 96% |
| 4000×3000 | 2000×1500 | 2 | 12MB | 75% |

### 降采样工具类

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范
import { image } from '@kit.ImageKit';

export class ImageDownsampling {
  /**
   * 带降采样的图片加载
   */
  static async loadWithDownsampling(
    filePath: string,
    targetWidth: number,
    targetHeight: number
  ): Promise<image.PixelMap> {
    let imageSource: image.ImageSource = image.createImageSource(filePath);
    let imageInfo: image.ImageInfo = await imageSource.getImageInfo();

    let inSampleSize: number = ImageDownsampling.calculateInSampleSize(
      imageInfo.size.width, imageInfo.size.height,
      targetWidth, targetHeight
    );

    let decodingOptions: image.DecodingOptions = {
      desiredSize: {
        width: Math.floor(imageInfo.size.width / inSampleSize),
        height: Math.floor(imageInfo.size.height / inSampleSize)
      },
      desiredPixelFormat: image.PixelMapFormat.RGBA_8888
    };

    let pixelMap: image.PixelMap = await imageSource.createPixelMap(decodingOptions);
    return pixelMap;
  }

  /**
   * 计算采样率（2 的幂次）
   */
  private static calculateInSampleSize(
    srcWidth: number, srcHeight: number,
    reqWidth: number, reqHeight: number
  ): number {
    let inSampleSize: number = 1;
    if (srcHeight > reqHeight || srcWidth > reqWidth) {
      let halfHeight: number = srcWidth / 2;
      let halfWidth: number = srcHeight / 2;
      while ((halfHeight / inSampleSize) >= reqHeight &&
             (halfWidth / inSampleSize) >= reqWidth) {
        inSampleSize *= 2;
      }
    }
    return inSampleSize;
  }
}
```

### 在 Image 组件中使用

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范
@Component
struct DownsampledImageItem {
  @State pixelMap: image.PixelMap | undefined = undefined;
  private imageUrl: string = '';
  private targetWidth: number = 200;
  private targetHeight: number = 200;

  async aboutToAppear(): Promise<void> {
    this.pixelMap = await ImageDownsampling.loadWithDownsampling(
      this.imageUrl, this.targetWidth, this.targetHeight
    );
  }

  build() {
    if (this.pixelMap) {
      Image(this.pixelMap)
        .width(this.targetWidth)
        .height(this.targetHeight)
        .objectFit(ImageFit.Cover)
    }
  }
}
```

### 设备分档策略

| 设备分档 | 降采样策略 | 说明 |
|---------|-----------|------|
| low | 采样率 ≥ 4，缩略图 ≥ 8 | 激进降采样，节省内存 |
| medium | 采样率 ≥ 2，缩略图 ≥ 4 | 适度降采样 |
| high | 采样率 ≥ 2，缩略图 ≥ 4 | 平衡质量与内存 |

## 配套最佳实践：ImageKnifePro 缓存分档

若项目使用 ImageKnifePro 图片加载库，可通过 `setCacheLimit` 按设备分档控制内存缓存上限（LRU 策略自动清理）。

### 设备分档策略

| 设备分档 | 内存缓存上限 | 说明 |
|---------|------------|------|
| low | 32MB | 严格限制，频繁清理 |
| medium | 64MB | 适度缓存 |
| high | 128MB | 充分缓存提升加载速度 |

### 代码模板

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范
import { ImageKnifePro } from '@ohos/imageknife';
import { DeviceLevelDecisionCenter, DeviceLevel } from './DeviceLevelDecisionCenter';

export class ImageKnifeCacheConfig {
  static configure(): void {
    let level: string = DeviceLevelDecisionCenter.getDeviceLevel();
    let cacheSize: number = 64 * 1024 * 1024; // 默认 64MB
    if (level === DeviceLevel.TIER_LOW) {
      cacheSize = 32 * 1024 * 1024; // 32MB
    } else if (level === DeviceLevel.TIER_MEDIUM) {
      cacheSize = 64 * 1024 * 1024; // 64MB
    } else {
      cacheSize = 128 * 1024 * 1024; // 128MB
    }
    ImageKnifePro.getInstance().setCacheLimit(cacheSize);
  }
}
```

**效果参考**：默认缓存 256MB → 低端机 32MB，内存占用降低 52.8%-60%，OOM 崩溃率降低 95%。

## C-API 代码修改模板（NDK 接口）

适用于使用 ArkUI NDK C-API 开发的场景。C-API 通过 `ARKUI_NODE_IMAGE` 创建图片节点，通过属性设置图片源、尺寸、自动缩放等。

### 核心概念对照

| ArkTS 概念 | C-API 对应 | 说明 |
|-----------|-----------|------|
| `Image(src)` | `ARKUI_NODE_IMAGE` + `NODE_IMAGE_SRC` | 图片组件 |
| `.width(N)` | `NODE_WIDTH` / `NODE_WIDTH_PERCENT` | 宽度 |
| `.height(N)` | `NODE_HEIGHT` | 高度 |
| `.autoResize(true)` | `NODE_AUTO_RESIZE` | 自动缩放到组件尺寸 |
| `.objectFit(ImageFit.Cover)` | `NODE_IMAGE_OBJECT_FIT` | 缩放模式 |
| `.interpolation(ImageInterpolation.Low)` | `NODE_IMAGE_INTERPOLATION` | 插值质量 |
| `.alt(placeholder)` | `NODE_ALT` | 占位图 |
| `.fillColor(color)` | `NODE_IMAGE_FILL_COLOR` | 颜色填充（SVG） |

### 1. 创建 Image 节点并设置属性（C-API）

```cpp
// ImageNodeHelper.h
// C-API 图片节点创建与分档配置

#include <arkui/native_node.h>
#include <arkui/native_interface.h>

class ImageNodeHelper {
public:
    static ArkUI_NodeHandle CreateImageNode(
        ArkUI_NativeNodeAPI_1 *nodeApi,
        const char *src,
        float width, float height,
        bool autoResize = true
    ) {
        auto imageNode = nodeApi->createNode(ARKUI_NODE_IMAGE);

        // 设置图片源（等价于 Image(src)）
        ArkUI_AttributeItem srcItem{nullptr, 0, src};
        nodeApi->setAttribute(imageNode, NODE_IMAGE_SRC, &srcItem);

        // 设置尺寸
        ArkUI_NumberValue sizeVal[] = {{.f32 = width}};
        ArkUI_AttributeItem widthItem = {sizeVal, 1};
        nodeApi->setAttribute(imageNode, NODE_WIDTH, &widthItem);
        sizeVal[0] = {.f32 = height};
        ArkUI_AttributeItem heightItem = {sizeVal, 1};
        nodeApi->setAttribute(imageNode, NODE_HEIGHT, &heightItem);

        // autoResize（等价于 .autoResize(true)）
        ArkUI_NumberValue autoResizeVal[] = {{.i32 = autoResize ? 1 : 0}};
        ArkUI_AttributeItem autoResizeItem = {autoResizeVal, 1};
        nodeApi->setAttribute(imageNode, NODE_AUTO_RESIZE, &autoResizeItem);

        return imageNode;
    }
};
```

### 2. 图片插值质量分档（C-API）

```cpp
// 根据设备分档设置图片插值质量
// 低端设备使用低质量插值，减少渲染开销
void SetImageQualityByDeviceLevel(
    ArkUI_NativeNodeAPI_1 *nodeApi,
    ArkUI_NodeHandle imageNode,
    const std::string &deviceLevel  // "low" / "medium" / "high"
) {
    // NODE_IMAGE_INTERPOLATION:
    //   0 = None, 1 = Low, 2 = Medium, 3 = High
    int32_t interpolation = 1; // 默认 Low
    if (deviceLevel == "high") {
        interpolation = 3; // High
    } else if (deviceLevel == "medium") {
        interpolation = 2; // Medium
    }
    ArkUI_NumberValue val[] = {{.i32 = interpolation}};
    ArkUI_AttributeItem item = {val, 1};
    nodeApi->setAttribute(imageNode, NODE_IMAGE_INTERPOLATION, &item);
}
```

### 3. PixelMap 降采样（C-API）

```cpp
// 使用 Image Kit C-API 进行降采样解码
#include <multimedia/image_framework/image/image_pixelmap_mdk.h>
#include <multimedia/image_framework/image/image_source_mdk.h>

// 降采样解码：在解码时直接指定目标尺寸，避免加载原图后缩放
// 节省内存 = 原始尺寸图片内存 - 降采样后内存
OH_PixelmapNative *CreateDownsampledPixelMap(
    const char *filePath,
    int32_t targetWidth,
    int32_t targetHeight
) {
    // 创建 ImageSource
    OH_ImageSourceNative *source = nullptr;
    OH_ImageSourceNative_CreateFromUri(filePath, strlen(filePath), &source);

    // 设置解码参数（指定目标尺寸）
    OH_DecodingOptionsForMetadata *options = nullptr;
    OH_DecodingOptionsForMetadata_Create(&options);
    OH_DecodingOptionsForMetadata_SetDesiredSize(options, targetWidth, targetHeight);

    // 解码为 PixelMap（直接降采样）
    OH_PixelmapNative *pixelmap = nullptr;
    OH_ImageSourceNative_CreatePixelmap(source, options, &pixelmap);

    // 清理
    OH_DecodingOptionsForMetadata_Release(options);
    OH_ImageSourceNative_Release(source);

    return pixelmap;
}

// 在列表项中使用降采样 PixelMap
void SetImageWithPixelMap(
    ArkUI_NativeNodeAPI_1 *nodeApi,
    ArkUI_NodeHandle imageNode,
    OH_PixelmapNative *pixelmap
) {
    // 将 PixelMap 设置到 Image 组件
    ArkUI_AttributeItem item = {.object = pixelmap};
    nodeApi->setAttribute(imageNode, NODE_IMAGE_SRC, &item);
}
```

### C-API 关键属性映射

| C-API 属性名 | 说明 | 参数类型 |
|-------------|------|---------|
| `NODE_IMAGE_SRC` | 图片源（URL/资源路径/PixelMap） | `.string = "path"` 或 `.object = pixelmap` |
| `NODE_WIDTH` | 宽度（vp） | `.f32 = N` |
| `NODE_HEIGHT` | 高度（vp） | `.f32 = N` |
| `NODE_WIDTH_PERCENT` | 宽度百分比 | `.f32 = 0.5` (50%) |
| `NODE_AUTO_RESIZE` | 自动缩放到组件尺寸 | `.i32 = 1/0` |
| `NODE_IMAGE_OBJECT_FIT` | 缩放模式 | `.i32 = ArkUI_ImageFit` |
| `NODE_IMAGE_INTERPOLATION` | 插值质量 | `.i32 = 0-3` |
| `NODE_IMAGE_FILL_COLOR` | 颜色填充（SVG） | `.u32 = 0xAARRGGBB` |
| `NODE_ALT` | 占位图 | `.string = "placeholder_path"` |
| `NODE_BACKGROUND_COLOR` | 背景色 | `.u32 = 0xAARRGGBB` |

### C-API ImageFit 枚举值

| 枚举值 | 说明 |
|-------|------|
| `ARKUI_IMAGE_FIT_CONTAIN` (0) | 保持宽高比缩放到容器内 |
| `ARKUI_IMAGE_FIT_COVER` (1) | 保持宽高比缩放并裁剪填满 |
| `ARKUI_IMAGE_FIT_AUTO` (2) | 自动选择 |
| `ARKUI_IMAGE_FIT_Fill` (3) | 拉伸填满 |
| `ARKUI_IMAGE_FIT_SCALE_DOWN` (4) | 缩小不放大 |
| `ARKUI_IMAGE_FIT_NONE` (5) | 不缩放 |

## 注意事项

- 纹理压缩适用于预设图片（应用内置资源）
- 网络图片推荐 CDN 裁剪 + webp 格式
- autoResize 适用于 Image 组件尺寸固定的场景
- 图片缓存 API 调用时机必须正确（onPageShow 或 aboutToAppear）
- PixelMap 降采样适用于固定尺寸的图片（头像、缩略图），不适用于全屏大图
- ImageKnifePro 缓存与系统级 `setImageCacheCount` 可同时使用，但需注意总内存预算
- 降采样后 PixelMap 不再需要时应调用 `pixelMap.release()` 释放内存
- **C-API 注意**：C-API 中图片缓存分档（`setImageCacheCount` 等）仍需通过 ArkTS 层面配置，C-API 侧主要控制单个 Image 节点的属性
- **C-API 注意**：PixelMap 降采样使用 Image Kit C-API（`OH_ImageSourceNative_*`），解码完成后记得释放 ImageSource
