# 图文混排

图文混排是指图片与文字混合排列，文字可展示于图片四周。此排列方式能够直观呈现页面信息，增强视觉冲击力，使页面展示效果更加多样化。

## 方式一：Span + ImageSpan

通过设置 Text 组件 `textVerticalAlign` 属性和 [ImageSpan](ts-basic-components-imagespan.md) 组件 `verticalAlign` 为 `ImageSpanAlignment.FOLLOW_PARAGRAPH` 实现。

**适用场景**：商品价格优惠信息展示等简单混排。

```typescript
Text() {
  // 图片
  ImageSpan($r('app.media.hot_sale'))
    .width(50)
    .height(30)
    .borderRadius(5)
    .verticalAlign(ImageSpanAlignment.FOLLOW_PARAGRAPH)

  // 价格文本
  Span('惊喜价 ￥1299')
    .fontSize(25)
    .fontColor(Color.Red)

  // 原价（删除线）
  Span('1599')
    .decoration({
      type: TextDecorationType.LineThrough,
      color: Color.Grey,
      style: TextDecorationStyle.SOLID
    })
    .fontSize(16)
}
.textVerticalAlign(TextVerticalAlign.CENTER)
```

### 关键属性
| 属性 | 组件 | 说明 |
|------|------|------|
| `textVerticalAlign` | Text | 文本段落垂直方向对齐（API 20+） |
| `verticalAlign` | ImageSpan | 图片对齐方式，设为 `FOLLOW_PARAGRAPH` 跟随段落 |

## 方式二：属性字符串

通过 `ImageAttachment` 添加图片，`TextStyle` 设置多种文本样式，`ParagraphStyle` 设置段落样式。

**适用场景**：商品详情信息展示等复杂混排，需要多样化的样式效果。

```typescript
import { image } from '@kit.ImageKit';
import { LengthMetrics } from '@kit.ArkUI';

// 段落样式（前导边距 + 溢出处理）
leadingMarginValue: ParagraphStyle = new ParagraphStyle({
  leadingMargin: LengthMetrics.vp(5),
  maxLines: 2,
  overflow: TextOverflow.Ellipsis,
  textVerticalAlign: TextVerticalAlign.BASELINE
});

// 行高样式
lineHeightStyle1: LineHeightStyle = new LineHeightStyle(new LengthMetrics(24));

// 粗体样式
boldTextStyle: TextStyle = new TextStyle({ fontWeight: FontWeight.Bold });

// 商品描述段落
paragraphStyledString1: MutableStyledString = new MutableStyledString(
  '\n高质量冲洗照片，高清冲印3/4/5/6寸包邮塑封，品质保证，', [
    { start: 0, length: 28, styledKey: StyledStringKey.PARAGRAPH_STYLE, styledValue: this.leadingMarginValue },
    { start: 11, length: 4, styledKey: StyledStringKey.LINE_HEIGHT, styledValue: this.lineHeightStyle1 }
  ]
);

// 限时直降段落
paragraphStyledString2: MutableStyledString = new MutableStyledString(
  '\n限时直降5.15元 限量增送', [
    { start: 0, length: 5, styledKey: StyledStringKey.PARAGRAPH_STYLE, styledValue: this.leadingMarginValue },
    { start: 0, length: 4, styledKey: StyledStringKey.LINE_HEIGHT, styledValue: new LineHeightStyle(new LengthMetrics(40)) },
    { start: 0, length: 9, styledKey: StyledStringKey.FONT, styledValue: this.boldTextStyle },
    { start: 1, length: 9, styledKey: StyledStringKey.FONT, styledValue: new TextStyle({ fontSize: LengthMetrics.vp(20), fontColor: Color.Red }) },
    { start: 11, length: 4, styledKey: StyledStringKey.FONT, styledValue: new TextStyle({ fontColor: Color.Grey, fontSize: LengthMetrics.vp(14) }) }
  ]
);

// 价格销量段落
paragraphStyledString3: MutableStyledString = new MutableStyledString(
  '\n￥22.50 销量400万+', [
    { start: 0, length: 15, styledKey: StyledStringKey.PARAGRAPH_STYLE, styledValue: this.leadingMarginValue },
    { start: 0, length: 7, styledKey: StyledStringKey.LINE_HEIGHT, styledValue: new LineHeightStyle(new LengthMetrics(40)) },
    { start: 0, length: 7, styledKey: StyledStringKey.FONT, styledValue: this.boldTextStyle },
    { start: 1, length: 1, styledKey: StyledStringKey.FONT, styledValue: new TextStyle({ fontSize: LengthMetrics.vp(18), fontColor: Color.Red }) },
    { start: 2, length: 2, styledKey: StyledStringKey.FONT, styledValue: new TextStyle({ fontSize: LengthMetrics.vp(36), fontColor: Color.Red }) },
    { start: 4, length: 3, styledKey: StyledStringKey.FONT, styledValue: new TextStyle({ fontSize: LengthMetrics.vp(20), fontColor: Color.Red }) },
    { start: 7, length: 9, styledKey: StyledStringKey.FONT, styledValue: new TextStyle({ fontColor: Color.Grey, fontSize: LengthMetrics.vp(14) }) }
  ]
);

// 加载图片
async getPixmapFromMedia(resource: Resource) {
  let unit8Array = await resourceManager?.getMediaContent(resource.id);
  let imageSource = image.createImageSource(unit8Array?.buffer?.slice(0, unit8Array?.buffer?.byteLength));
  let pixelMap = await imageSource.createPixelMap({ desiredPixelFormat: image.PixelMapFormat.RGBA_8888 });
  await imageSource.release();
  return pixelMap;
}

// 点击按钮时组装完整内容
Button('点击查看商品详情').onClick(() => {
  // 创建图片附件
  this.mutableStr = new MutableStyledString(new ImageAttachment({
    value: this.imagePixelMap,
    size: { width: 210, height: 190 },
    verticalAlign: ImageSpanAlignment.BASELINE,
    objectFit: ImageFit.Fill,
    layoutStyle: { borderRadius: LengthMetrics.vp(5) }
  }));

  // 拼接多段属性字符串
  this.paragraphStyledString1.appendStyledString(this.paragraphStyledString2);
  this.paragraphStyledString1.appendStyledString(this.paragraphStyledString3);
  this.mutableStr.appendStyledString(this.paragraphStyledString1);

  // 绑定到 Text 组件
  this.controller.setStyledString(this.mutableStr);
})
```

### Text 组件配置
```typescript
Text(undefined, { controller: this.controller })
  .copyOption(CopyOptions.InApp)
  .draggable(true)
  .backgroundColor('#FFFFFF')
  .borderRadius(5)
  .width(210)
```

## 两种方式的对比

| 特性 | [Span](ts-basic-components-span.md) + [ImageSpan](ts-basic-components-imagespan.md) | [属性字符串](arkts-styled-string.md) |
|------|-----------------|------------|
| 复杂度 | 简单直观 | 灵活但代码量较多 |
| 样式控制 | 基础样式 | 字符/段落级别精细控制 |
| 图片支持 | ImageSpan 组件 | ImageAttachment 对象 |
| 段落控制 | 不支持 | ParagraphStyle |
| 适用场景 | 简单混排（标签+图标） | 复杂混排（商品卡片、文章内容） |
| 跨组件复用 | 不支持 | 支持 appendStyledString 拼接 |
