# 属性字符串（StyledString / MutableStyledString）

属性字符串 StyledString / MutableStyledString（MutableStyledString 继承自 StyledString）用于在**字符或段落级别**上设置文本样式。支持调整字号、添加字体颜色、使文本具备可点击性、自定义方式绘制文本等。

## 创建并应用

通过 `TextController.setStyledString()` 方法将属性字符串绑定到 Text 组件。

**推荐时机**：在 `onPageShow` 或 Text 组件的 `onAppear` 回调中触发绑定。

> API 15+：支持在 `aboutToAppear` 中调用。

```typescript
@Entry
@Component
struct styled_string_demo {
  styledString1: StyledString = new StyledString('运动45分钟');
  mutableStyledString1: MutableStyledString = new MutableStyledString('运动35分钟');
  controller1: TextController = new TextController();
  controller2: TextController = new TextController();

  async onPageShow() {
    this.controller1.setStyledString(this.styledString1);
  }

  build() {
    Column() {
      Text(undefined, { controller: this.controller1 })
      Text(undefined, { controller: this.controller2 })
        .onAppear(() => {
          this.controller2.setStyledString(this.mutableStyledString1);
        })
    }
  }
}
```

### 创建语法
```typescript
new MutableStyledString(text, [
  {
    start: 0,        // 起始位置
    length: 5,       // 长度
    styledKey: StyledStringKey.FONT,  // 样式类型
    styledValue: textStyleAttrs       // 样式值
  }
])
```

## 文本样式对象

### TextStyle（字体样式）
```typescript
import { LengthMetrics } from '@kit.ArkUI';

textStyleAttrs: TextStyle = new TextStyle({
  fontWeight: FontWeight.Bolder,
  fontSize: LengthMetrics.vp(24),
  fontStyle: FontStyle.Italic,
  strokeWidth: LengthMetrics.px(5),
  strokeColor: Color.Green
});

mutableStyledString: MutableStyledString = new MutableStyledString('这是一段文本', [
  {
    start: 2, length: 2,
    styledKey: StyledStringKey.FONT,
    styledValue: this.textStyleAttrs
  },
  {
    start: 7, length: 4,
    styledKey: StyledStringKey.FONT,
    styledValue: new TextStyle({
      fontColor: Color.Orange,
      fontSize: LengthMetrics.vp(12),
      superscript: SuperscriptStyle.SUPERSCRIPT
    })
  }
]);
```

### TextShadowStyle（文本阴影）
```typescript
new MutableStyledString('运动35分钟', [{
  start: 0, length: 3,
  styledKey: StyledStringKey.TEXT_SHADOW,
  styledValue: new TextShadowStyle({
    radius: 5,
    type: ShadowType.COLOR,
    color: Color.Red,
    offsetX: 10,
    offsetY: 10
  })
}]);
```

### DecorationStyle（装饰线）
```typescript
// 单装饰线
new DecorationStyle({
  type: TextDecorationType.LineThrough,
  color: Color.Red,
  thicknessScale: 3
})

// 多装饰线（需 enableMultiType）
new DecorationStyle(
  { type: TextDecorationType.Underline },
  { enableMultiType: true }
)
new DecorationStyle(
  { type: TextDecorationType.LineThrough },
  { enableMultiType: true }
)
```

### BaselineOffsetStyle（基线偏移）
```typescript
import { LengthMetrics } from '@kit.ArkUI';

new BaselineOffsetStyle(LengthMetrics.px(20))
```

### LineHeightStyle（行高）
```typescript
import { LengthMetrics } from '@kit.ArkUI';

new LineHeightStyle(LengthMetrics.vp(50))
```

### LetterSpacingStyle（字符间距）
```typescript
import { LengthMetrics, LengthUnit } from '@kit.ArkUI';

new LetterSpacingStyle(new LengthMetrics(20, LengthUnit.VP))
```

### CustomSpan（自定义样式）
可创建 CustomSpan 以应用自定义样式。

## 段落样式（ParagraphStyle）

段落以换行符 `\n` 结尾。如果将 ParagraphStyle 附加到段落开头、末尾或之间任何位置，均会应用样式；非段落区间内不会应用。

```typescript
import { LengthMetrics } from '@kit.ArkUI';

titleParagraphStyleAttr: ParagraphStyle = new ParagraphStyle({ textAlign: TextAlign.Center });
paragraphStyleAttr1: ParagraphStyle = new ParagraphStyle({ textIndent: LengthMetrics.vp(15) });
lineHeightStyle1: LineHeightStyle = new LineHeightStyle(new LengthMetrics(24));

paragraphStyledString: MutableStyledString = new MutableStyledString('段落标题\n正文第一段落...', [
  // 标题段落样式
  { start: 0, length: 4, styledKey: StyledStringKey.PARAGRAPH_STYLE, styledValue: this.titleParagraphStyleAttr },
  { start: 0, length: 4, styledKey: StyledStringKey.LINE_HEIGHT, styledValue: new LineHeightStyle(new LengthMetrics(50)) },
  { start: 0, length: 4, styledKey: StyledStringKey.FONT, styledValue: new TextStyle({ fontSize: LengthMetrics.vp(24), fontWeight: FontWeight.Bolder }) },
  // 正文段落首行缩进
  { start: 5, length: 3, styledKey: StyledStringKey.PARAGRAPH_STYLE, styledValue: this.paragraphStyleAttr1 },
  { start: 5, length: 20, styledKey: StyledStringKey.LINE_HEIGHT, styledValue: this.lineHeightStyle1 }
]);
```

### ParagraphStyle 属性

| 属性 | 说明 |
|------|------|
| `textAlign` | 段落对齐方式 |
| `textIndent` | 首行缩进 |
| `leadingMargin` | 前导边距 |
| `maxLines` | 段落最大行数 |
| `overflow` | 溢出处理方式 |
| `textVerticalAlign` | 垂直对齐方式 |

### replaceStyle（替换样式）
清空原样式并替换新样式，需在 controller 上主动触发更新：
```typescript
mutableStyledString.replaceStyle(start, length, styledKey, newStyledValue);
controller.setStyledString(mutableStyledString);
```

## 使用图片（ImageAttachment）

```typescript
import { image } from '@kit.ImageKit';
import { LengthMetrics } from '@kit.ArkUI';

imagePixelMap: image.PixelMap | undefined = undefined;

// 加载图片
let unit8Array = await resourceManager?.getMediaContent(resource.id);
let imageSource = image.createImageSource(unit8Array?.buffer);
let pixelMap = await imageSource.createPixelMap({
  desiredPixelFormat: image.PixelMapFormat.RGBA_8888
});

// 创建含图片的属性字符串
new MutableStyledString(new ImageAttachment({
  value: this.imagePixelMap,
  size: { width: 210, height: 190 },
  verticalAlign: ImageSpanAlignment.BASELINE,
  objectFit: ImageFit.Fill,
  layoutStyle: {
    borderRadius: LengthMetrics.vp(5)
  }
}));
```

## 追加操作

`appendStyledString` 方法可拼接多个属性字符串：
```typescript
this.paragraphStyledString1.appendStyledString(this.paragraphStyledString2);
this.paragraphStyledString1.appendStyledString(this.paragraphStyledString3);
this.mutableStr.appendStyledString(this.paragraphStyledString1);
this.controller.setStyledString(this.mutableStr);
```

## 支持的 StyledStringKey 类型

| Key | 对应 Style 对象 | 说明 |
|-----|----------------|------|
| `StyledStringKey.FONT` | TextStyle | 字体样式 |
| `StyledStringKey.TEXT_SHADOW` | TextShadowStyle | 文本阴影 |
| `StyledStringKey.DECORATION` | DecorationStyle | 装饰线 |
| `StyledStringKey.BASELINE_OFFSET` | BaselineOffsetStyle | 基线偏移 |
| `StyledStringKey.LINE_HEIGHT` | LineHeightStyle | 行高 |
| `StyledStringKey.LETTER_SPACING` | LetterSpacingStyle | 字符间距 |
| `StyledStringKey.PARAGRAPH_STYLE` | ParagraphStyle | 段落样式 |
