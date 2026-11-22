# Image 组件降采样指南

## 目录

1. [降采样概述](#降采样概述)
2. [autoResize 属性](#autoresize-属性)
3. [最佳清晰度配置](#最佳清晰度配置)
4. [完整使用示例](#完整使用示例)
5. [常见问题排查](#常见问题排查)

---

## 降采样概述

autoResize 适用于需要组件尺寸动态适配的场景。例如，在响应页面内容变化或设备形态差异（如不同屏幕尺寸、折叠屏展开/收起）时，图片需要根据父容器尺寸自动缩放，使用 autoResize 可避免图片溢出或留白，提升界面自适应能力。

通过给 Image 组件设置 autoResize 为 true 时，组件会根据显示区域的尺寸决定用于绘制的图源尺寸，有利于减少内存占用。

### 适用场景

- 原图尺寸远大于显示区域，需要减少内存占用。
- 图片需要根据父容器尺寸动态适配。
- 响应不同屏幕尺寸或折叠屏形态差异。

### 降采样原理

如原图大小为 800x1200，而显示区域大小为 200x200，则图片会降采样解码到 200x300 的尺寸（实际计算过程中会依赖缩放和填充类型的配置，从而得到的计算结果会有差异），从而大幅度节省图片占用的内存。

---

## autoResize 属性

### API 说明

```typescript
autoResize(value: boolean)
```

设置图片解码过程中是否对图源自动缩放。降采样解码时图片的部分信息丢失，因此可能会导致图片质量的下降（如：出现锯齿），这时可以选择把 autoResize 设为 false，按原图尺寸解码，提升显示效果，但会增加内存占用。

### 参数

| 参数名 | 类型 | 必填 | 说明 |
| :--- | :--- | :--- | :--- |
| value | boolean | 是 | 图片解码过程中是否对图源自动缩放。设置为 true 时，组件会根据显示区域的尺寸决定用于绘制的图源尺寸，有利于减少内存占用。默认值：false，false 表示关闭图源自动缩放，true 表示开启图源自动缩放。 |

### 限制说明

- 当组件的参数类型为 `AnimatedDrawableDescriptor` 和 SVG 时设置该属性不生效。
- **卡片能力：** 从 API version 9 开始，该接口支持在 ArkTS 卡片中使用。
- **元服务 API：** 从 API version 11 开始，该接口支持在元服务中使用。
- **系统能力：** SystemCapability.ArkUI.ArkUI.Full

### 基本用法

```typescript
Image(this.imageUrl)
    .width(300)
    .height(200)
    .autoResize(true)
```

---

## 最佳清晰度配置

原图尺寸和显示尺寸不匹配时，图片都会出现些许的失真、模糊。最佳清晰度配置建议：

### 图片缩小显示时

关闭 autoResize 按原图尺寸解码，并使用中等插值：

```typescript
Image(this.imageUrl)
    .width(300)
    .height(200)
    .autoResize(false)
    .interpolation(ImageInterpolation.Medium)
```

### 图片放大显示时

使用高插值提升放大效果：

```typescript
Image(this.imageUrl)
    .width(300)
    .height(200)
    .interpolation(ImageInterpolation.High)
```

---

## 完整使用示例

参考[Image组件降采样示例](../assets/ImageAutoSizeExample.ets)

---

## 常见问题排查

### 图片显示模糊或出现锯齿

**现象**：启用 autoResize 后图片质量下降，出现锯齿。

**原因**：降采样解码时图片的部分信息丢失。

**解决方案**：

1. 图片缩小显示时使用 `.autoResize(false) + .interpolation(.Medium)`。
2. 图片放大显示时使用 `.interpolation(.High)`。
3. 在内存允许的情况下，关闭 autoResize 按原图尺寸解码。

### autoResize 设置不生效

**现象**：设置了 `autoResize(true)` 但内存占用未减少。

**原因**：组件参数类型为 `AnimatedDrawableDescriptor` 或 SVG 时不生效。

**解决方案**：

1. 检查图片资源是否为 SVG 或动画格式。
2. 对于不支持的格式，考虑在解码阶段使用 `image.DecodingOptions` 的 `sampleSize` 或 `desiredSize` 进一步控制。

### 内存占用仍然过高

**现象**：启用 autoResize 后内存占用仍然偏高。

**原因**：显示区域设置过大，或图片原图尺寸过大。

**解决方案**：

1. 检查 Image 组件的 `width` 和 `height` 设置是否合理。
2. 确认 `autoResize(true)` 已正确设置。
3. 考虑在解码阶段使用 `image.DecodingOptions` 的 `sampleSize` 或 `desiredSize` 进一步控制解码尺寸。

## 核心约束

- 原图尺寸远大于显示区域时，应设置 `autoResize(true)` 进行降采样，减少内存占用。
- 降采样会导致图片部分信息丢失，对清晰度要求高的场景可关闭 autoResize 并配合 `interpolation` 使用。
- `autoResize` 对 `AnimatedDrawableDescriptor` 和 SVG 格式不生效，需在解码阶段使用 `DecodingOptions` 控制。