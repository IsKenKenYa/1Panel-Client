# 文本组件文字展示案例集

## 功能点典型使用场景对比

| 文本组件 | 典型使用场景 | 核心能力 | 不适用场景 |
|---------|------------|---------|-----------|
| Text | 文章正文展示、商品名称、说明文字 | 多样式只读文本展示 | 用户输入、富文本编辑 |
| TextInput | 注册表单、搜索框、登录输入 | 单行文本输入+类型键盘 | 多行输入、富文本编辑 |
| RichEditor | 论坛发帖、文档编辑器 | 富文本编辑（样式+图片） | 只读展示 |
| SymbolGlyph | 系统设置图标、状态图标 | 系统级图标+动效 | 自定义图标、普通图片 |
| MutableStyledString | 搜索结果关键字高亮 | 动态文本高亮/分段样式 | 只读展示（需配合Text） |
| Text + Span + ImageSpan | 促销文案、商品标签、图文混排 | 文字+图片同行混排 | 编辑场景 |

---

## 场景一：新闻文章正文展示，支持自定义样式和超长省略

**场景示例描述**：新闻阅读 App 中，文章正文以多段落形式展示，支持自定义字体大小/行间距/字间距，文本超长时自动折行并在末尾显示省略号，支持展开/收起全文。

**解决方案**：使用 Text 组件，通过 fontSize 设置字体大小、lineHeight 设置行间距、letterSpacing 设置字间距，textOverflow 配合 maxLines 设置超出时显示省略号。

| 备选组件 | 不适合的理由 |
|---------|------------|
| TextInput | 是输入组件，仅用于用户输入文本 |
| RichEditor | 是可编辑组件，文章正文仅需只读展示 |

```typescript
// 展开/收起状态必须用 @State 声明,否则点击按钮后 maxLines 与按钮文案不会响应式刷新
@State isExpanded: boolean = false;

// 标题：大字体 + 加粗 + 自定义行高
Text(this.articleTitle)
  .fontSize(22).fontWeight(FontWeight.Bold)
  .lineHeight(32).letterSpacing(1)

// 正文：超长省略号 + 展开/收起
Text(this.articleContent)
  .fontSize(16).lineHeight(28).letterSpacing(0.5)
  .maxLines(this.isExpanded ? 100 : 3)
  .textOverflow({ overflow: TextOverflow.Ellipsis })

Button(this.isExpanded ? '收起 ↑' : '展开全文 ↓')
  .onClick(() => { this.isExpanded = !this.isExpanded; })

// 装饰线样式
Text('删除线文本')
  .decoration({ type: TextDecorationType.LineThrough, color: '#e74c3c' })
```

### Text 关键 API

| 属性 | 作用 | 示例 |
|------|-----|------|
| `fontSize` | 字体大小 | `.fontSize(16)` |
| `fontWeight` | 字体粗细 | `Normal` / `Medium` / `Bold` |
| `fontStyle` | 字体风格 | `Normal` / `Italic` |
| `lineHeight` | 行高 | `.lineHeight(28)` |
| `letterSpacing` | 字间距 | `.letterSpacing(0.5)` |
| `maxLines` | 最大行数 | `.maxLines(3)` |
| `textOverflow` | 溢出处理 | `Ellipsis` / `Clip` |
| `textAlign` | 对齐方式 | `Start` / `Center` / `End` |

### textOverflow 枚举

| 枚举值 | 行为 |
|--------|------|
| `TextOverflow.Ellipsis` | 超出部分以省略号显示 |
| `TextOverflow.Clip` | 超出部分直接裁剪不可见 |
| `TextOverflow.None` | 不处理溢出 |

### TextDecorationType 枚举

| 枚举值 | 效果 |
|--------|------|
| `Underline` | 下划线 |
| `LineThrough` | 删除线 |
| `Overline` | 上划线 |
| `None` | 无装饰线 |

---

## 场景二：用户注册表单多种输入类型，每种拉起对应键盘

**场景示例描述**：用户注册页面，包含用户名（单行文本）、密码（密码模式遮蔽显示）、邮箱（邮箱键盘）、手机号（数字键盘）等多种输入框，每种输入框拉起对应类型键盘，并实现实时表单验证。

**解决方案**：使用 TextInput 组件，通过 type 设置不同的输入类型，通过 placeholder 设置占位提示文本，onChange 回调实现实时验证。

| 备选组件 | 不适合的理由 |
|---------|------------|
| TextArea | 注册表单各项均为单行输入，TextArea 是多行输入框 |
| RichEditor | 用于富文本编辑，表单输入仅需纯文本 |

```typescript
// 用户名：普通输入
TextInput({ text: this.username, placeholder: '请输入用户名' })
  .type(InputType.Normal).maxLength(20)
  .onChange((value: string) => { this.username = value; })

// 密码：密码模式遮蔽
TextInput({ text: this.password, placeholder: '请输入密码' })
  .type(InputType.Password)
  .onChange((value: string) => { this.password = value; })

// 邮箱：邮箱键盘
TextInput({ text: this.email, placeholder: '请输入邮箱' })
  .type(InputType.Email)
  .onChange((value: string) => { this.email = value; })

// 手机号：数字键盘
TextInput({ text: this.phone, placeholder: '请输入手机号' })
  .type(InputType.Number).maxLength(11)
  .onChange((value: string) => { this.phone = value; })
```

### InputType 枚举

| 枚举值 | 键盘类型 | 适用场景 |
|--------|---------|---------|
| `Normal` | 普通文本键盘 | 用户名、昵称、地址 |
| `Password` | 密码键盘（遮蔽显示） | 密码、验证码 |
| `Email` | 邮箱键盘（含@符号） | 邮箱地址 |
| `Number` | 数字键盘 | 手机号、金额、验证码 |
| `PhoneNumber` | 电话号码键盘 | 电话号码 |

---

## 场景三：论坛发帖页面支持加粗、斜体、颜色等富文本编辑

**场景示例描述**：社区论坛 App 的发帖/评论页面，用户需要输入文字并插入表情图片，支持对选中文本设置加粗、斜体、颜色等样式，实现图文混合编辑。

**解决方案**：使用 RichEditor 组件，通过 RichEditorController 的 setTypingStyle 设置后续输入样式（加粗/斜体/颜色/字号），支持撤销/重做等编辑操作。

| 备选组件 | 不适合的理由 |
|---------|------------|
| Text + Span | 只能展示图文混排，不支持用户交互式编辑 |
| TextArea | 仅支持纯文本输入，无法插入图片和设置样式 |

```typescript
// 工具栏样式状态必须用 @State 管理,确保按钮切换与后续输入样式同步
@State isBold: boolean = false;
@State isItalic: boolean = false;
@State currentColor: string = '#000000';

controller: RichEditorController = new RichEditorController();

private applyTypingStyle(): void {
  this.controller.setTypingStyle({
    fontWeight: this.isBold ? FontWeight.Bold : FontWeight.Normal,
    fontStyle: this.isItalic ? FontStyle.Italic : FontStyle.Normal,
    decoration: { type: this.isUnderline ? TextDecorationType.Underline : TextDecorationType.None },
    fontColor: this.currentColor
  });
}

// 工具栏按钮
Button('B').onClick(() => { this.isBold = !this.isBold; this.applyTypingStyle(); })
Button('I').onClick(() => { this.isItalic = !this.isItalic; this.applyTypingStyle(); })

// 颜色选择
ForEach(this.colors, (color: string) => {
  Circle().width(28).height(28).fill(color)
    .onClick(() => { this.currentColor = color; this.applyTypingStyle(); })
})

// 富文本编辑区
RichEditor({ controller: this.controller })
  .placeholder('在这里输入文本...')
  .width('100%').height(240)
```

---

## 场景四：系统设置页WiFi/蓝牙等开关使用系统图标并带动效

**场景示例描述**：系统设置页面中，WiFi/蓝牙/飞行模式/定位等开关按钮使用系统预置的 Symbol 图标，点击切换时图标带有系统级动效过渡。

**解决方案**：使用 SymbolGlyph 组件，引用系统预置 symbol 资源，通过 fontColor 设置颜色，renderingStrategy 设置渲染策略，symbolEffect 设置系统级动效。

| 备选组件 | 不适合的理由 |
|---------|------------|
| Image | 不具备 Symbol 图标的系统级动效和多色渲染能力 |
| 图标字体 | SymbolGlyph 与系统符号库深度集成，支持多层颜色配置 |

```typescript
// 开关状态数组与动效触发值(@State 确保颜色和动效响应式更新)
@State items: Array<{ symbol: ResourceStr, enabled: boolean }> = [
  { symbol: $r('sys.symbol.ohos_wifi'), enabled: true },
  { symbol: $r('sys.symbol.bluetooth'), enabled: true },
  { symbol: $r('sys.symbol.airplane'), enabled: false },
  { symbol: $r('sys.symbol.location_north_up_right'), enabled: true }
];
@State triggerValues: number[] = [0, 0, 0, 0];

ForEach(this.items, (item: { symbol: ResourceStr, enabled: boolean }, index: number) => {
  SymbolGlyph(item.symbol)
    .fontSize(28)
    .fontColor(item.enabled ? ['#1890ff'] : ['#999999'])
    .renderingStrategy(SymbolRenderingStrategy.SINGLE)
    .symbolEffect(new BounceSymbolEffect(EffectScope.LAYER), this.triggerValues[index])
    .onClick(() => {
      this.items[index].enabled = !this.items[index].enabled;
      this.triggerValues[index]++;  // 递增触发值驱动 Bounce 动效
    })
}, (item: { symbol: ResourceStr, enabled: boolean }, index: number) => index.toString())
```

### SymbolGlyph 关键枚举

| 枚举类型 | 枚举值 | 说明 |
|---------|--------|------|
| SymbolRenderingStrategy | `SINGLE` / `MULTIPLE_OPACITY` / `MULTIPLE_PALETTE` | 渲染策略 |
| SymbolEffectStrategy | `NONE` / `HIERARCHICAL` | 动效策略 |
| EffectScope | `LAYER` / `WHOLE` | 动效范围 |

### 常用系统 Symbol 资源

| 资源名 | 图标 |
|--------|------|
| `sys.symbol.ohos_wifi` | WiFi |
| `sys.symbol.bluetooth` | 蓝牙 |
| `sys.symbol.airplane` | 飞行模式 |
| `sys.symbol.location_north_up_right` | 定位 |
| `sys.symbol.sound` | 声音 |
| `sys.symbol.brightness` | 亮度 |
| `sys.symbol.battery` | 电池 |
| `sys.symbol.bell` | 通知 |
| `sys.symbol.moon` | 勿扰 |

---

## 场景五：搜索结果列表中匹配关键字高亮显示

**场景示例描述**：搜索结果列表中，商品名称里匹配搜索关键字的部分需要高亮显示（如搜索"手机"，结果中"手机"二字变色），且同一段文本中不同关键词可能使用不同高亮颜色。

**解决方案**：使用 MutableStyledString 构建属性字符串，对匹配关键词的文本范围使用 replaceStyle 设置不同颜色和粗体，通过 TextController.setStyledString 设置到 Text 组件。

| 备选组件 | 不适合的理由 |
|---------|------------|
| Span 子组件 | 动态拼接多个 Span 在复杂高亮场景下代码冗长且不易维护 |
| RichEditor | 搜索结果是只读展示，不需要编辑能力 |

```typescript
// 预定义关键词颜色
const KEYWORD_STYLES = [
  { keyword: '手机', color: '#e74c3c' },
  { keyword: '华为', color: '#2980b9' },
  // ...
];

// 构建高亮属性字符串
private buildHighlight(text: string): MutableStyledString {
  const styled = new MutableStyledString(text);
  // ...查找关键词位置，建立字符位置→关键词映射
  // 对匹配范围设置高亮样式
  styled.replaceStyle({
    start: rangeStart, length: length,
    styledKey: StyledStringKey.FONT,
    styledValue: new TextStyle({ fontColor: color, fontWeight: FontWeight.Bold })
  });
  return styled;
}

// 必须调用 controller.setStyledString() 将 MutableStyledString 设置到 TextController,
// 否则属性字符串无法渲染到 Text 组件(禁止跳过此步直接使用 MutableStyledString)
private updateHighlight(text: string): void {
  this.controller.setStyledString(this.buildHighlight(text));
}

// 在 aboutToAppear 或搜索结果数据更新时调用
// aboutToAppear(): void { this.updateHighlight(this.searchText); }

// 使用 TextController 设置属性字符串
Text(undefined, { controller: this.controller })
  .fontSize(16).fontWeight(FontWeight.Medium)
```

### StyledStringKey 枚举

| 枚举值 | 可设置属性 |
|--------|----------|
| `FONT` | fontColor, fontWeight, fontSize, fontStyle |
| `BACKGROUND_COLOR` | 背景颜色 |
| `DECORATION` | 装饰线类型和颜色 |
| `LINE_HEIGHT` | 行高 |
| `FONT_FAMILY` | 字体族 |

---

## 场景六：商品详情页促销文案中嵌入图标和图片

**场景示例描述**：商品详情页中，促销文案"限时特惠 立减50元 今日下单送赠品"需要在文字中间嵌入促销图标、赠品小图片，图片和文字在同一行内混合排列。

**解决方案**：使用 Text 组件，子组件中使用 Span 显示文本片段，ImageSpan 插入行内图片，通过 verticalAlign 设置图片与文字的垂直对齐方式。

| 备选组件 | 不适合的理由 |
|---------|------------|
| Image | 是独立图片组件，无法嵌入文本流中与文字混排 |
| RichEditor | 商品详情页是只读展示，不需要编辑功能 |

```typescript
// 核心促销文案：图文混排
Text() {
  ImageSpan($r('sys.media.ohos_ic_public_clock'))
    .width(18).height(18)
    .verticalAlign(ImageSpanAlignment.CENTER)
  Span(' 限时特惠')
    .fontSize(16).fontWeight(FontWeight.Bold).fontColor(Color.White)
  Span('  立减50元')
    .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#FFE066')
  // ...更多图文混排内容
}
.backgroundColor('#E74C3C').borderRadius(8).padding(12)

// 促销标签行：多个图标+文字混排
Text() {
  ImageSpan($r('sys.media.ohos_ic_public_sound'))
    .width(14).height(14).verticalAlign(ImageSpanAlignment.CENTER)
  Span(' 满减').fontSize(12).fontColor('#E74C3C')
    .backgroundColor('#FDEAEA').borderRadius(4)
  // ...更多标签
}
```

### ImageSpanAlignment 枚举

| 枚举值 | 对齐方式 |
|--------|---------|
| `TOP` | 图片顶部与文字顶部对齐 |
| `CENTER` | 图片垂直居中对齐 |
| `BOTTOM` | 图片底部与文字底部对齐 |
| `BASELINE` | 图片与文字基线对齐 |
