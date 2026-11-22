# 图形组件图像展示案例集

## 功能点典型使用场景对比

| 图形组件 | 典型使用场景 | 核心能力 | 不适用场景 |
|---------|------------|---------|-----------|
| Image | 商品主图、用户头像、背景图、列表缩略图 | 多数据源+多种填充方式+占位图 | 帧动画播放、视频流渲染 |
| ImageAnimator | 直播礼物特效、动画表情、引导动画 | 序列帧逐帧播放+状态控制 | 静态图片展示、GIF动图 |

---

## 场景一：电商商品列表展示商品主图，支持多种数据源和加载失败占位

**场景示例描述**：电商商品列表页，每个商品卡片展示商品主图，图片来源可能是本地资源、网络 URL 或 PixelMap，图片加载失败时显示默认占位图。

**解决方案**：使用 Image 组件，支持多种数据源，通过 objectFit 设置图片填充方式，alt 属性设置加载失败时的占位图，onError 处理加载失败回调。

| 备选组件 | 不适合的理由 |
|---------|------------|
| XComponent | 用于自定义渲染 Surface，普通图片展示无需如此复杂 |
| ImageAnimator | 用于帧动画播放，静态图片不需要逐帧播放 |

```typescript
// 本地资源
Image($r('app.media.startIcon'))
  .objectFit(ImageFit.Cover)
  .alt($r('app.media.placeholder'))  // 加载失败占位图

// 网络 URL
Image(product.imageUrl)
  .objectFit(ImageFit.Cover)
  .width(80).height(80).borderRadius(8)
  .alt($r('app.media.startIcon'))  // 加载失败兜底
  .onError(() => { /* 加载失败处理 */ })
  .onComplete((event) => {
    // event.width / event.height 为图片实际宽高(px),用于布局计算
    console.info(`loaded: ${event.width}x${event.height}`)
  })
```

### Image 关键 API

| 属性 | 作用 | 示例 |
|------|-----|------|
| `src` | 图片数据源 | `$r('app.media.icon')` / `'https://...'` / `pixelMap` |
| `objectFit` | 填充方式 | `Cover` / `Contain` / `Fill` |
| `alt` | 加载失败占位图 | `.alt($r('app.media.placeholder'))` |
| `onError` | 加载失败回调 | `.onError(() => { ... })` |
| `onComplete` | 加载完成回调 | `.onComplete((event) => { ... })` |

### 列表场景性能约束

商品列表使用 Image 加载网络 URL 图片时,Image 组件内部异步解码,不阻塞列表滚动:

- 网络 URL 图片由 Image 异步加载与解码,主线程不阻塞,LazyForEach/List 列表可正常滚动
- 禁止在 build 或列表项构建逻辑中同步等待图片解码完成(如同步创建 PixelMap 再赋给 src),否则会卡顿滚动
- 如需基于网络图片做 PixelMap 后处理(裁剪/滤镜),应在 onComplete 回调中异步获取,不要阻塞 build

### onComplete 回调与图片实际宽高

`onComplete` 在图片加载完成时触发,event 参数包含图片实际尺寸,可用于布局计算:

```typescript
// 网络 URL - 绑定 onError 与 onComplete,获取实际宽高用于布局计算
Image(product.imageUrl)
  .objectFit(ImageFit.Cover)
  .width(80).height(80).borderRadius(8)
  .alt($r('app.media.startIcon'))  // 加载失败兜底
  .onError(() => { /* 加载失败日志/埋点上报 */ })
  .onComplete((event) => {
    // event.width / event.height 为图片实际宽高(px),用于布局计算
    console.info(`loaded: ${event.width}x${event.height}`)
  })
```

> 注意:onComplete 的 event.width/event.height 是图片解码后的实际尺寸,区别于 width(80)/height(80) 设定的组件显示尺寸,可用于按宽高比动态调整布局。

### ImageFit 枚举

| 枚举值 | 行为 | 适用场景 |
|--------|------|---------|
| `Contain` | 保持宽高比，完全显示在容器内 | 需要完整显示整张图片 |
| `Cover` | 保持宽高比，完全覆盖容器（可能裁剪） | 商品卡片、头像（最常用） |
| `Fill` | 不保持宽高比，拉伸填满 | 背景图、装饰图 |
| `Auto` | 保持原始尺寸 | 小图标、精确尺寸控制 |
| `ScaleDown` | 大于容器时缩小，小于时不放大 | 不确定图片尺寸的通用场景 |
| `None` | 不缩放，按原始尺寸显示 | 需要精确控制尺寸的场景 |

---

## 场景二：直播App豪华礼物特效逐帧连续播放

**场景示例描述**：直播 App 中，用户送出豪华礼物时播放一套由几十张序列帧图片组成的礼物特效动画（如烟花绽放、火箭升空），动画逐帧连续播放，支持播放/暂停/停止控制。

**解决方案**：使用 ImageAnimator 组件，通过 images 属性设置每帧图片的路径、尺寸和播放时长，state 控制播放/暂停/停止状态。引用 rawfile 资源必须使用 `$rawfile('xxx.png')` 返回 Resource 类型。

| 备选组件 | 不适合的理由 |
|---------|------------|
| Image | 只能显示单张静态图或 GIF，无法精确控制每帧时长和播放状态 |
| Lottie/动画 API | 帧动画由序列帧图片组成，ImageAnimator 逐帧播放效果最精确 |

```typescript
// 构造帧数组，src 必须使用 $rawfile() 返回 Resource 类型
private getFrameImages(dirIndex: number): ImageFrameInfo[] {
  const images: ImageFrameInfo[] = [];
  for (let i = 0; i < this.totalFrames; i++) {
    const idx = i < 10 ? `0${i}` : `${i}`;
    images.push({
      src: $rawfile(`${dir}/frame_${idx}.png`),
      width: 240, height: 240,
      duration: this.perFrameDuration
    });
  }
  return images;
}

// ImageAnimator - images 不支持动态更新，切换礼物需条件渲染
ImageAnimator()
  .images(this.getFrameImages(0))
  .state(this.animState)    // 播放状态控制
  .iterations(this.iterations)  // -1 = 无限循环
  .reverse(false)
  .fillMode(FillMode.None)
  .width(240).height(240)

// 播放控制
Button('播放').onClick(() => { this.animState = AnimationStatus.Running; })
Button('暂停').onClick(() => { this.animState = AnimationStatus.Paused; })
Button('停止').onClick(() => { this.animState = AnimationStatus.Stopped; })
```

### AnimationStatus 枚举

| 枚举值 | 行为 |
|--------|------|
| `Running` | 播放中 |
| `Paused` | 暂停（可恢复） |
| `Stopped` | 停止（回到首帧，需重新播放） |
| `Initial` | 初始状态 |

### FillMode 枚举

| 枚举值 | 行为 |
|--------|------|
| `None` | 动画结束后不保持最后一帧 |
| `Forwards` | 动画结束后保持最后一帧 |
| `Backwards` | 动画开始前显示第一帧 |
| `Both` | 同时应用 Forwards 和 Backwards |

### 注意事项

1. **images 属性不支持动态更新**：切换不同礼物时需使用条件渲染（if/else）重建 ImageAnimator
2. **资源引用**：引用 rawfile 资源必须使用 `$rawfile('xxx.png')` 返回 Resource 类型
3. **序列帧命名规范**：建议使用零填充编号（frame_00.png, frame_01.png, ...）

---

## 图形组件选型速查对比表

| 组件 | 数据类型 | 核心能力 | 典型场景 | 关键限制 |
|------|---------|---------|---------|---------|
| **Image** | 静态图/网络图/PixelMap | 多数据源+多种填充方式+占位图 | 商品主图、头像、背景图 | 不支持帧动画播放 |
| **ImageAnimator** | 序列帧图片数组 | 逐帧播放+状态控制+循环控制 | 礼物特效、动画表情、引导动画 | images 不可动态更新，需条件渲染 |
