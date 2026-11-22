# 自定义组件（FrameNode）案例集

## 功能点典型使用场景对比

| 自定义能力 | 典型使用场景 | 核心能力 | 不适用场景 |
|-----------|------------|---------|-----------|
| DrawModifier（绘制） | 设计类 App 渐变边框按钮、外发光效果、霓虹灯、棋盘格图案背景 | drawBehind/drawFront 在背景层和前景层自定义绘制 | 修改已有属性、替换内容区 |
| AttributeModifier（属性） | 企业级 App 统一按钮样式规范（主/次/危险/禁用四态） | 封装多态样式跨文件复用，一个实例多组件复用 | 自定义绘制、动态手势 |
| GestureModifier（手势） | 设计工具 App 拖拽/缩放/旋转模式动态切换手势 | applyGesture 运行时动态切换手势类型 | 静态手势绑定 |
| ContentModifier（内容） | 组件库全局定制 Button 图标+文字、Checkbox 收藏切换 | applyContent 替换系统组件内容区 | 仅修改属性、叠加绘制 |
| FrameNode（组件） | JSON 驱动动态表单，运行时动态添加/删除表单项 | typeNode.createNode 动态创建/删除节点 | 编译期确定的结构 |
| RenderNode（渲染） | 电子合同签署/快递签收手写签名，支持撤销/清除 | 重写 draw 方法，invalidate() 逐帧重绘 | 低频静态绘制 |
| BuilderNode（混合） | 新闻/商品信息流穿插广告，占位先行内容后填 | BuilderNode.build 动态构建组件树，rebuild() 上树 | 编译期确定结构的列表 |
| XComponent（Surface） | 自定义绘制 App 在 Surface 上用画布对象绘制图形 | SURFACE 类型 + lockCanvas/unlockCanvasAndPost | 静态图片展示 |

---

## 场景一：设计类 App 按钮需要渐变边框+外发光等自定义外观

**场景示例描述**：设计类 App 中，按钮需要绘制独特的渐变边框+内部图标+外发光效果的自定义外观，系统 Button 组件无法满足的视觉效果。

**解决方案**：使用 DrawModifier 的 drawBehind/drawFront 方法，通过 Canvas 接口（drawing.Brush + canvas.drawRect/drawCircle）在组件背景层和前景层进行自定义绘制。drawBehind 绘制渐变边框和图案背景，drawFront 绘制外发光和霓虹光晕。

| 备选方案 | 不适合的理由 |
|---------|------------|
| AttributeModifier | 只能修改已有属性（颜色/圆角等），无法进行 Canvas 自定义绘制 |
| ContentModifier | 是替换组件内容区，而非在原有组件基础上叠加自定义绘制 |

```typescript
import { drawing } from '@kit.ArkGraphics2D';

// 渐变边框 + 外发光 Modifier
class GradientBorderModifier extends DrawModifier {
  colors: number[][] = [
    [255, 255, 107, 107],  // #FF6B6B
    [255, 78, 205, 196],   // #4ECDC4
    [255, 85, 98, 112],    // #556270
  ];
  uiContext: UIContext;
  constructor(uiContext: UIContext) { super(); this.uiContext = uiContext; }

  // drawBehind：背景层绘制渐变边框
  // 注意：context.size 返回 vp，canvas 绘制需 px，用 vp2px 转换
  drawBehind(context: DrawContext): void {
    const wPx = this.uiContext.vp2px(context.size.width);
    const hPx = this.uiContext.vp2px(context.size.height);
    const borderW = this.uiContext.vp2px(3);
    const segW = context.size.width / this.colors.length;
    // 顶部、底部渐变带
    for (let i = 0; i < this.colors.length; i++) {
      const brush = new drawing.Brush();
      brush.setColor({ alpha: this.colors[i][0], red: this.colors[i][1],
        green: this.colors[i][2], blue: this.colors[i][3] });
      context.canvas.attachBrush(brush);
      const leftPx = this.uiContext.vp2px(i * segW);
      const rightPx = this.uiContext.vp2px((i + 1) * segW);
      context.canvas.drawRect({ left: leftPx, top: 0, right: rightPx, bottom: borderW });
      context.canvas.drawRect({ left: leftPx, top: hPx - borderW, right: rightPx, bottom: hPx });
      context.canvas.detachBrush();
    }
    // ...左右边框用中间色绘制
  }

  // drawFront：前景层绘制外发光（多层半透明圆形向外扩散）
  drawFront(context: DrawContext): void {
    const cx = this.uiContext.vp2px(context.size.width / 2);
    const cy = this.uiContext.vp2px(context.size.height / 2);
    const glowBrush = new drawing.Brush();
    for (let i = 5; i > 0; i--) {
      glowBrush.setColor({ alpha: 20, red: 78, green: 205, blue: 196 });
      context.canvas.attachBrush(glowBrush);
      context.canvas.drawCircle(cx, cy, this.uiContext.vp2px(30 + i * 6));
      context.canvas.detachBrush();
    }
  }
}

// 使用：通过 .drawModifier() 绑定到组件
Button('渐变边框按钮')
  .width(220).height(56).backgroundColor(Color.White)
  .drawModifier(new GradientBorderModifier(this.getUIContext()))
```

### DrawModifier 方法枚举

| 方法 | 绘制层级 | 说明 |
|------|---------|------|
| `drawBehind(context)` | 背景层 | 在组件背景层绘制，组件内容之下 |
| `drawFront(context)` | 前景层 | 在组件前景层绘制，组件内容之上 |

### drawing 核心对象枚举

| 对象 | 作用 | 关键方法 |
|------|------|---------|
| `drawing.Brush` | 画刷（填充） | `setColor({alpha, red, green, blue})` |
| `drawing.Pen` | 画笔（描边） | `setStrokeWidth()`, `setColor()` |
| `drawing.Path` | 路径 | `moveTo()`, `lineTo()`, `arcTo()` |

### 实现原理

| 效果 | 实现方式 |
|------|---------|
| 渐变边框 | drawBehind 中分段 drawRect 绘制多色边框 |
| 外发光 | drawFront 中多层半透明 drawCircle 向外扩散 |
| 霓虹灯 | drawBehind 深色背景 + drawFront 多层发光圆环 |
| 棋盘格 | drawBehind 中交替颜色 drawRect 绘制方格 |

---

## 场景二：企业级 App 封装统一按钮样式规范，支持四态切换

**场景示例描述**：企业级 App 中，需要封装一套统一的按钮样式规范（主按钮/次按钮/危险按钮/禁用态），每种按钮在正常态、按压态、焦点态、禁用态下有不同样式，且样式定义需要跨文件复用和参数化配置。

**解决方案**：使用 AttributeModifier\<ButtonAttribute\> 封装多态样式，实现 applyNormalAttribute/applyPressedAttribute/applyFocusedAttribute/applyDisabledAttribute 四个方法，每种状态设置对应的颜色/圆角/阴影等属性。一个 Modifier 实例可在多个 Button 上复用，支持跨文件导出。

| 备选方案 | 不适合的理由 |
|---------|------------|
| @Styles | 不支持参数传递、不支持跨文件导出、不支持多态样式切换 |
| @Extend | 仅支持扩展特定组件类型，灵活度不如 AttributeModifier |

```typescript
// 主按钮 Modifier —— 蓝色填充，实现四态样式
class PrimaryButtonModifier implements AttributeModifier<ButtonAttribute> {
  applyNormalAttribute(instance: ButtonAttribute): void {
    instance.backgroundColor('#4A90D9')
      .fontColor(Color.White).borderRadius(24).border({ width: 0 })
      .shadow({ radius: 8, color: 'rgba(74, 144, 217, 0.3)', offsetY: 3 });
  }
  applyPressedAttribute(instance: ButtonAttribute): void {
    instance.backgroundColor('#357ABD')
      .fontColor(Color.White).borderRadius(24)
      .shadow({ radius: 2, color: 'rgba(74, 144, 217, 0.2)', offsetY: 1 })
      .scale({ x: 0.96, y: 0.96 });
  }
  applyFocusedAttribute(instance: ButtonAttribute): void {
    instance.backgroundColor('#4A90D9')
      .fontColor(Color.White).borderRadius(24)
      .border({ width: 2, color: '#1A5FB4' })
      .shadow({ radius: 12, color: 'rgba(74, 144, 217, 0.5)', offsetY: 3 });
  }
  applyDisabledAttribute(instance: ButtonAttribute): void {
    instance.backgroundColor('#B0C4DE')
      .fontColor('rgba(255, 255, 255, 0.7)').borderRadius(24)
      .shadow({ radius: 0, color: 'rgba(0, 0, 0, 0)' }).opacity(0.6);
  }
}
```

### 跨文件导出与主题色参数化

> 企业级场景需将 Modifier 跨文件复用,且不同业务线(主/危险/成功)复用同一四态逻辑仅换主题色。以下为参数化导出版本,与上方硬编码版本二选一。

```typescript
// 跨文件导出:构造函数接收主题色,四态颜色由主题色派生
export class ThemeButtonModifier implements AttributeModifier<ButtonAttribute> {
  private themeColor: ResourceColor;
  constructor(themeColor: ResourceColor = '#4A90D9') {
    this.themeColor = themeColor;
  }

  applyNormalAttribute(instance: ButtonAttribute): void {
    instance.backgroundColor(this.themeColor)
      .fontColor(Color.White).borderRadius(24).border({ width: 0 })
      .shadow({ radius: 8, color: this.themeColor, offsetY: 3 });
  }
  applyPressedAttribute(instance: ButtonAttribute): void {
    instance.backgroundColor(this.themeColor).opacity(0.85)
      .fontColor(Color.White).borderRadius(24)
      .shadow({ radius: 2, offsetY: 1 })
      .scale({ x: 0.96, y: 0.96 });
  }
  applyFocusedAttribute(instance: ButtonAttribute): void {
    instance.backgroundColor(this.themeColor)
      .fontColor(Color.White).borderRadius(24)
      .border({ width: 2, color: this.themeColor })
      .shadow({ radius: 12, color: this.themeColor, offsetY: 3 });
  }
  applyDisabledAttribute(instance: ButtonAttribute): void {
    instance.backgroundColor(this.themeColor).opacity(0.6)
      .fontColor('rgba(255, 255, 255, 0.7)').borderRadius(24);
  }
}

// 跨文件导入后,不同主题色复用同一 Modifier 类
import { ThemeButtonModifier } from './buttonModifiers';
private primaryModifier = new ThemeButtonModifier('#4A90D9');   // 主按钮
private dangerModifier = new ThemeButtonModifier('#E74C3C');    // 危险按钮
```

| 要点 | 说明 |
|------|------|
| `export class` | 类定义加 export 关键字,支持其他文件 import 复用 |
| 构造函数接收 `themeColor` | 四态颜色统一引用 `this.themeColor`,不同业务线传入不同色值即可复用 |

```typescript
// 使用：一个 Modifier 实例复用到多个 Button
private primaryModifier: PrimaryButtonModifier = new PrimaryButtonModifier();

Button('提交表单')
  .width(220).height(48)
  .attributeModifier(this.primaryModifier)

Button('禁用态')
  .width(220).height(48).enabled(false)
  .attributeModifier(this.primaryModifier)  // 同一实例复用
```

### AttributeModifier 四态方法枚举

| 方法 | 触发时机 | 典型样式变化 |
|------|---------|------------|
| `applyNormalAttribute` | 正常态 | 背景色/文字色/圆角/阴影 |
| `applyPressedAttribute` | 按压态 | 加深背景色 + scale(0.96) 缩小 + 减弱阴影 |
| `applyFocusedAttribute` | 焦点态 | 添加 border 边框 + 增强阴影 |
| `applyDisabledAttribute` | 禁用态 | 变灰 + 降低透明度 + 移除阴影 |

---

## 场景三：设计工具 App 画布元素根据编辑模式动态切换手势

**场景示例描述**：设计工具 App 中，画布上的图形元素需要根据当前编辑模式动态切换手势行为——选择模式下绑定拖拽手势，缩放模式下绑定捏合手势，旋转模式下绑定旋转手势，手势类型随模式变化而动态变化。

**解决方案**：使用 GestureModifier 接口的 applyGesture 方法，根据当前编辑模式（EditMode）动态添加不同类型的手势处理器（PanGestureHandler/PinchGestureHandler/RotationGestureHandler）。手势切换在当次手势结束后的下一次操作中生效。

| 备选方案 | 不适合的理由 |
|---------|------------|
| 静态 .gesture() | 直接绑定的手势属性是静态的，无法在运行时动态切换 |
| AttributeModifier | AttributeModifier 中不支持调用手势设置方法 |

```typescript
enum EditMode { Drag, Scale, Rotate }

class ShapeGestureModifier implements GestureModifier {
  mode: EditMode = EditMode.Drag;
  // 回调函数由外部绑定
  onDragUpdate: (offsetX: number, offsetY: number) => void = () => {};
  onScaleUpdate: (scale: number) => void = () => {};
  onRotateUpdate: (angle: number) => void = () => {};
  // ...其他回调

  applyGesture(event: UIGestureEvent): void {
    if (this.mode === EditMode.Drag) {
      event.addGesture(new PanGestureHandler()
        .onActionUpdate((e: GestureEvent) => { this.onDragUpdate(e.offsetX, e.offsetY); })
        .onActionEnd((e: GestureEvent) => { /* ... */ }));
    } else if (this.mode === EditMode.Scale) {
      event.addGesture(new PinchGestureHandler()
        .onActionUpdate((e: GestureEvent) => { this.onScaleUpdate(e.scale); })
        .onActionEnd((e: GestureEvent) => { /* ... */ }));
    } else if (this.mode === EditMode.Rotate) {
      event.addGesture(new RotationGestureHandler()
        .onActionUpdate((e: GestureEvent) => { this.onRotateUpdate(e.angle); })
        .onActionEnd((e: GestureEvent) => { /* ... */ }));
    }
  }
}

// 使用：通过 .gestureModifier() 绑定，切换模式时更新 modifier.mode
private shapeGestureModifier: ShapeGestureModifier = new ShapeGestureModifier();

Stack() {
  Column() { /* 图形内容 */ }
}
.translate({ x: this.shapeX, y: this.shapeY })
.scale({ x: this.shapeScale, y: this.shapeScale })
.rotate({ angle: this.shapeRotate })
.gestureModifier(this.shapeGestureModifier)

// 模式切换
this.shapeGestureModifier.mode = EditMode.Scale;
```

### EditMode 枚举

| 枚举值 | 对应手势处理器 | 适用场景 |
|--------|-------------|---------|
| `Drag` | PanGestureHandler | 单指拖动移动 |
| `Scale` | PinchGestureHandler | 双指捏合缩放 |
| `Rotate` | RotationGestureHandler | 双指旋转 |

### GestureHandler 类型枚举

| 手势处理器 | 触发条件 | 回调参数 |
|-----------|---------|---------|
| `PanGestureHandler` | 单指拖拽 | offsetX, offsetY |
| `PinchGestureHandler` | 双指捏合 | scale |
| `RotationGestureHandler` | 双指旋转 | angle |

---

## 场景四：组件库全局定制 Button 内容区为图标+文字组合

**场景示例描述**：组件库中需要对系统 Button 组件的内容区进行全局定制——将所有 Button 的默认文字替换为"图标+文字"的组合样式，或为 Checkbox 添加自定义的收藏切换内容。

**解决方案**：使用 ContentModifier\<T\> 的 applyContent 方法，返回 WrappedBuilder\<[T]\>，@Builder 函数接收 ButtonConfiguration 或 CheckBoxConfiguration 等配置类型，通过 config.label/config.pressed/config.selected/config.triggerChange 访问组件状态。

| 备选方案 | 不适合的理由 |
|---------|------------|
| DrawModifier | 是叠加自定义绘制，不替换原有内容 |
| @Builder | 需逐个手动替换，ContentModifier 可全局统一修改 |

```typescript
// Button 内容定制：图标+文字组合
class IconButtonModifier implements ContentModifier<ButtonConfiguration> {
  icon: string;
  iconColor: ResourceColor;
  constructor(icon: string, iconColor: ResourceColor) { this.icon = icon; this.iconColor = iconColor; }
  applyContent(): WrappedBuilder<[ButtonConfiguration]> {
    return wrapBuilder(buildIconButton);
  }
}

@Builder
function buildIconButton(config: ButtonConfiguration) {
  Row({ space: 8 }) {
    Text((config.contentModifier as IconButtonModifier).icon)
      .fontSize(18)
      .fontColor((config.contentModifier as IconButtonModifier).iconColor)
    Text(config.label)  // config.label 获取按钮文字
      .fontSize(16)
      .fontColor(config.pressed ? '#357ABD' : Color.Black)  // config.pressed 获取按压状态
  }.justifyContent(FlexAlign.Center)
}

// Checkbox 内容定制：收藏切换
// 注意：Modifier 自定义属性不触发刷新，需用 config.selected 驱动 UI 更新
@Builder
function buildFavoriteCheckbox(config: CheckBoxConfiguration) {
  Row({ space: 6 }) {
    Text(config.selected ? '★' : '☆')  // config.selected 获取选中状态
      .fontColor(config.selected ? '#F39C12' : '#999')
    Text('收藏').fontSize(14)
  }.onClick(() => {
    config.triggerChange(!config.selected);  // config.triggerChange 触发切换
  })
}

// Checkbox 收藏切换 Modifier:实现 ContentModifier<CheckBoxConfiguration>
// applyContent 返回 wrapBuilder(buildFavoriteCheckbox),与 IconButtonModifier 结构对称
class FavoriteCheckboxModifier implements ContentModifier<CheckBoxConfiguration> {
  applyContent(): WrappedBuilder<[CheckBoxConfiguration]> {
    return wrapBuilder(buildFavoriteCheckbox);
  }
}

// 使用：通过 .contentModifier() 绑定
Button('下载文件')
  .width(220).height(48).borderRadius(24)
  .contentModifier(new IconButtonModifier('⬇', Color.White))

Checkbox({ name: '收藏', group: 'favoriteGroup' })
  .select(this.favoriteOn)
  .contentModifier(new FavoriteCheckboxModifier())
```

### Configuration 配置类型枚举

| 配置类型 | 适用组件 | 关键属性/方法 |
|---------|---------|------------|
| `ButtonConfiguration` | Button | `label`（文字）、`pressed`（是否按下）、`contentModifier`（访问自定义属性） |
| `CheckBoxConfiguration` | Checkbox | `selected`（选中状态）、`triggerChange(bool)`（触发切换）、`contentModifier` |

### ContentModifier 关键约束

| 约束 | 说明 |
|------|------|
| Modifier 自定义属性不触发刷新 | 如 `isFavorited` 不会驱动 UI 更新，需用 `config.selected` 驱动 |
| `config.contentModifier as XxxModifier` | 在 @Builder 中通过类型断言访问 Modifier 自定义属性 |
| 一个实例可复用 | 同一 Modifier 实例可绑定到多个同类型组件 |

---

## 场景五：动态表单根据 JSON 配置运行时生成/删除表单项

**场景示例描述**：动态表单页面，需要根据后端返回的 JSON 配置动态生成表单组件（如输入框、开关、按钮），并在运行时动态添加或删除表单项。

**解决方案**：使用 NodeController + FrameNode + typeNode.createNode 实现动态节点管理。根容器使用 typeNode.createNode(ctx, 'Column') 获得垂直流式布局，通过 appendChild/removeChild 动态增删节点。新增/删除字段直接操作单节点，不调用 rebuild()，保留其余节点输入状态。

| 备选方案 | 不适合的理由 |
|---------|------------|
| @Builder | 需要在编译期确定组件结构，无法运行时根据 JSON 动态生成不同组件类型 |
| 条件渲染 if/else | 适合固定结构的动态显示，不适合完全动态的节点树构建 |

```typescript
import { FrameNode, typeNode, NodeController, UIContext } from '@kit.ArkUI';

interface FormFieldConfig {
  type: 'TextInput' | 'Toggle' | 'Button';
  label: string;
  placeholder?: string;
}

class FormNodeController extends NodeController {
  private rootNode: FrameNode | null = null;
  private uiContext: UIContext | null = null;
  private fieldNodes: FrameNode[] = [];  // 缓存节点用于删除定位
  fields: FormFieldConfig[] = [];

  makeNode(uiContext: UIContext): FrameNode {
    this.uiContext = uiContext;
    // 根容器用 Column 类型节点：自带垂直流式布局，动态增删时自动重排
    const root = typeNode.createNode(uiContext, 'Column');
    root.attribute.width('100%');
    this.rootNode = root;
    this.buildForm();
    return this.rootNode;
  }

  // 根据配置创建对应类型的节点
  createFieldNode(config: FormFieldConfig): FrameNode {
    if (config.type === 'Button') {
      const buttonNode = typeNode.createNode(this.uiContext!, 'Button');
      buttonNode.initialize(config.label);  // initialize 设置初始值
      buttonNode.attribute.backgroundColor('#4A90D9').borderRadius(8).height(40);
      return buttonNode;
    }
    // 容器节点
    const container = typeNode.createNode(this.uiContext!, 'Row');
    container.attribute.width('100%').padding({ /* ... */ });
    // 标签节点
    const labelNode = typeNode.createNode(this.uiContext!, 'Text');
    labelNode.initialize(config.label);
    container.appendChild(labelNode);
    // 输入节点
    if (config.type === 'TextInput') {
      const inputNode = typeNode.createNode(this.uiContext!, 'TextInput');
      inputNode.initialize({ placeholder: config.placeholder || '' });
      inputNode.attribute.backgroundColor('#F5F5F5').height(44).layoutWeight(1);
      container.appendChild(inputNode);
    } else if (config.type === 'Toggle') {
      const toggleNode = typeNode.createNode(this.uiContext!, 'Toggle');
      toggleNode.attribute.selectedColor('#4A90D9').width(48).height(24);
      container.appendChild(toggleNode);
    }
    return container;
  }

  // 添加字段：仅 appendChild 新节点，不调用 rebuild，保留已有输入
  addField(config: FormFieldConfig) {
    this.fields.push(config);
    if (this.rootNode) {
      const fieldNode = this.createFieldNode(config);
      this.rootNode.appendChild(fieldNode);
      this.fieldNodes.push(fieldNode);
    }
  }

  // 删除最后一个字段：仅 removeChild 末尾节点
  removeLastField() {
    this.fields.pop();
    if (this.rootNode) {
      const lastNode = this.fieldNodes.pop();
      if (lastNode) { this.rootNode.removeChild(lastNode); }
    }
  }
}

// 使用：NodeContainer 挂载 FrameNode 树
NodeContainer(this.formController).width('100%')
```

### typeNode.createNode 节点类型枚举

| 节点类型 | 说明 | initialize 参数 | attribute 关键方法 |
|---------|------|----------------|-------------------|
| `Column` | 垂直布局容器 | 无 | width, padding, backgroundColor |
| `Row` | 水平布局容器 | 无 | width, padding, alignItems |
| `Text` | 文本组件 | 文字内容 | fontSize, fontColor, fontWeight |
| `TextInput` | 输入框 | { placeholder } | backgroundColor, height, layoutWeight |
| `Toggle` | 开关组件 | 无 | selectedColor, width, height |
| `Button` | 按钮组件 | 按钮文字 | backgroundColor, fontColor, borderRadius |

### FrameNode 节点操作方法枚举

| 方法 | 说明 | 是否触发 rebuild |
|------|------|----------------|
| `appendChild(node)` | 在最后一个子节点后添加新节点 | 否，保留其余节点 |
| `removeChild(node)` | 删除指定子节点 | 否，保留其余节点 |
| `clearChildren()` | 清空所有子节点 | 否 |

### 关键约束

| 约束 | 说明 |
|------|------|
| 根容器必须用 typeNode.createNode(ctx, 'Column') | 普通 new FrameNode 无布局策略，动态增删时子节点会堆叠重叠 |
| 新增/删除直接 appendChild/removeChild | 不调用 rebuild()，避免重建整树丢失输入状态 |
| TypedFrameNode 使用 .attribute.xxx() | 设置属性；initialize() 设置初始值 |

---

## 场景六：电子合同签署页面手写签名实时绘制笔迹

**场景示例描述**：电子合同签署或快递签收页面，需要用户在屏幕上手写签名，手指或触控笔拖动时实时绘制平滑笔迹，并支持撤销上一步、清除画板。

**解决方案**：使用 RenderNode 重写 draw 方法，结合 drawing.Path 对象记录手指拖动轨迹（moveTo 起始点、lineTo 添加线段），canvas.attachPen + canvas.drawPath 绘制笔迹。invalidate() 触发逐帧重绘保证书写流畅。通过 FrameNode.getRenderNode().appendChild 挂载 RenderNode 到 NodeContainer。

| 备选方案 | 不适合的理由 |
|---------|------------|
| Canvas 组件 | 每次重绘参与完整测量布局流程，高频书写性能不如 RenderNode |
| Image | 只能显示静态图片，无法响应用户拖动实时绘制 |

```typescript
import { FrameNode, NodeController, RenderNode, DrawContext, UIContext } from '@kit.ArkUI';
import { drawing } from '@kit.ArkGraphics2D';

class SignatureRenderNode extends RenderNode {
  paths: drawing.Path[] = [];  // 已完成笔画
  currentPath: drawing.Path | null = null;  // 当前绘制中笔画

  draw(context: DrawContext) {
    const canvas = context.canvas;
    const pen = new drawing.Pen();
    pen.setStrokeWidth(3);
    pen.setColor({ alpha: 255, red: 33, green: 33, blue: 33 });
    canvas.attachPen(pen);
    for (const path of this.paths) { canvas.drawPath(path); }
    if (this.currentPath) { canvas.drawPath(this.currentPath); }
    canvas.detachPen();
  }

  startStroke(x: number, y: number) {
    this.currentPath = new drawing.Path();
    this.currentPath.moveTo(x, y);  // 起始点
    this.invalidate();  // 触发重绘
  }
  continueStroke(x: number, y: number) {
    if (this.currentPath) { this.currentPath.lineTo(x, y); this.invalidate(); }
  }
  endStroke() {
    if (this.currentPath) { this.paths.push(this.currentPath); this.currentPath = null; this.invalidate(); }
  }
  undo() { this.paths.pop(); this.invalidate(); }  // 撤销上一步
  clear() { this.paths = []; this.currentPath = null; this.invalidate(); }  // 清除画板
}

// NodeController 挂载 RenderNode
class SignatureNodeController extends NodeController {
  private rootNode: FrameNode | null = null;
  private renderNode: SignatureRenderNode | null = null;
  private uiContext: UIContext | null = null;

  makeNode(uiContext: UIContext): FrameNode {
    this.uiContext = uiContext;
    this.rootNode = new FrameNode(uiContext);
    this.renderNode = new SignatureRenderNode();
    this.renderNode.frame = { x: 0, y: 0, width: 300, height: 250 };  // 单位 vp
    // 通过 FrameNode.getRenderNode().appendChild 挂载
    this.rootNode.getRenderNode()?.appendChild(this.renderNode);
    return this.rootNode;
  }

  aboutToResize(size: Size): void {
    if (this.renderNode) { this.renderNode.frame = { x: 0, y: 0, width: size.width, height: size.height }; }
  }

  vp2px(value: number): number {
    return this.uiContext ? this.uiContext.vp2px(value) : value;
  }
}

// 使用：NodeContainer + onTouch 处理触摸事件
NodeContainer(this.signatureController)
  .width('100%').height(250)
  .onTouch((event: TouchEvent) => {
    const renderNode = this.signatureController.getSignatureRenderNode();
    if (!renderNode) return;
    const x = this.signatureController.vp2px(event.touches[0].x);  // Path 坐标用 px
    const y = this.signatureController.vp2px(event.touches[0].y);
    if (event.type === TouchType.Down) { renderNode.startStroke(x, y); }
    else if (event.type === TouchType.Move) { renderNode.continueStroke(x, y); }
    else if (event.type === TouchType.Up) { renderNode.endStroke(); }
  })
```

### drawing.Path 方法枚举

| 方法 | 说明 |
|------|------|
| `moveTo(x, y)` | 设置路径起始点 |
| `lineTo(x, y)` | 添加从最后点到目标点的线段 |
| `arcTo(...)` | 添加圆弧路径 |

### RenderNode 核心方法枚举

| 方法 | 说明 |
|------|------|
| `draw(context: DrawContext)` | 重写此方法进行自定义渲染 |
| `invalidate()` | 触发逐帧重绘 |
| `frame = { x, y, width, height }` | 设置位置和大小（单位 vp） |

### TouchType 枚举

| 枚举值 | 说明 | 对应操作 |
|--------|------|---------|
| `Down` | 手指按下 | startStroke 开始新笔画 |
| `Move` | 手指移动 | continueStroke 继续笔画 |
| `Up` | 手指抬起 | endStroke 结束笔画 |

---

## 场景七：新闻/商品信息流中穿插广告，占位先行内容后填

**场景示例描述**：新闻/商品信息流中穿插广告条目，广告的具体形态（图文、视频、轮播）在开发阶段无法确定，需要在运行时根据服务器下发的数据动态创建对应广告组件。

**解决方案**：使用 BuilderNode + NodeController + NodeContainer 实现组件预创建与动态挂载。在列表项中用 NodeContainer 占位，BuilderNode.build 根据 WrappedBuilder 动态构建图文/视频/轮播广告组件树，广告数据到达后调用 rebuild() 重新回调 makeNode 上树显示，实现占位先行、内容后填的动态创建。

| 备选方案 | 不适合的理由 |
|---------|------------|
| ForEach | 编译期需确定组件结构，无法运行时根据数据动态生成不同类型 |
| 条件渲染 | 分支在编译期固定，无法应对服务器下发任意类型的动态内容 |

```typescript
import { BuilderNode, NodeController, FrameNode, UIContext } from '@kit.ArkUI';

interface AdData {
  type: 'image-text' | 'video' | 'carousel';
  title: string; description: string; images: string[]; loaded: boolean;
}

// @Builder 函数定义不同广告形态
@Builder
function buildImageTextAd(params: AdData) {
  Column({ space: 8 }) {
    Row({ space: 12 }) {
      Column().width(80).height(80).backgroundColor('#E0E0E0')  // 图片占位
      Column({ space: 4 }) {
        Text(params.title).fontSize(14).fontWeight(FontWeight.Bold)
        Text(params.description).fontSize(12).fontColor('#999').maxLines(2)
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
    }
    // ...广告标签
  }.padding(12).backgroundColor('#FFFDE7').borderRadius(12)
}
// ...buildVideoAd、buildCarouselAd、buildLoadingAd 类似

class AdNodeController extends NodeController {
  private builderNode: BuilderNode<[AdData]> | null = null;
  private adData: AdData;
  constructor(adData: AdData) { super(); this.adData = adData; }

  makeNode(uiContext: UIContext): FrameNode {
    if (this.builderNode == null) {
      this.builderNode = new BuilderNode(uiContext);
      this.buildAd();
    }
    return this.builderNode!.getFrameNode()!;
  }

  private buildAd() {
    let wrappedBuilder: WrappedBuilder<[AdData]>;
    if (!this.adData.loaded) {
      wrappedBuilder = wrapBuilder(buildLoadingAd);  // 占位
    } else if (this.adData.type === 'image-text') {
      wrappedBuilder = wrapBuilder(buildImageTextAd);
    } else if (this.adData.type === 'video') {
      wrappedBuilder = wrapBuilder(buildVideoAd);
    } else {
      wrappedBuilder = wrapBuilder(buildCarouselAd);
    }
    this.builderNode!.build(wrappedBuilder, this.adData);  // 动态构建组件树
  }

  // 服务器数据到达后调用，rebuild() 重新回调 makeNode
  updateAdData(adData: AdData) {
    this.adData = adData;
    this.builderNode = null;  // 重置以重新构建
    this.rebuild();  // 通知 NodeContainer 重新回调 makeNode
  }
}

// 使用：NodeContainer 占位，数据到达后 updateAdData 上树
private adController: AdNodeController = new AdNodeController({ /* loaded: false */ });

// 新闻列表中穿插广告位
this.NewsCard(this.newsList[0])
NodeContainer(this.adController).width('100%')  // 占位先行
this.NewsCard(this.newsList[1])

// 模拟服务器数据到达
this.adController.updateAdData({ type: 'image-text', title: '限时特惠', /* loaded: true */ });
```

### BuilderNode 核心方法枚举

| 方法 | 说明 |
|------|------|
| `new BuilderNode(uiContext)` | 创建 BuilderNode 实例 |
| `build(wrappedBuilder, params)` | 根据 WrappedBuilder 动态构建组件树 |
| `getFrameNode()` | 获取构建后的 FrameNode 用于挂载 |

### NodeController 核心方法枚举

| 方法 | 说明 |
|------|------|
| `makeNode(uiContext)` | 返回 FrameNode 挂载到 NodeContainer，首次和 rebuild 时回调 |
| `rebuild()` | 通知 NodeContainer 重新回调 makeNode，实现动态更新 |

### AdData.type 枚举

| 枚举值 | 对应 @Builder | 适用场景 |
|--------|-------------|---------|
| `image-text` | buildImageTextAd | 图文广告 |
| `video` | buildVideoAd | 视频广告 |
| `carousel` | buildCarouselAd | 轮播广告 |

---

## 场景八：自定义绘制 App 在 XComponent Surface 上用画布对象绘制图形

**场景示例描述**：自定义绘制 App 中，需要在 XComponent 的 Surface 上使用画布对象直接绘制图形（如矩形），无需 Native 代码。

**解决方案**：使用 XComponent 的 SURFACE 类型，在 onLoad 回调中通过 XComponentController 的 lockCanvas() 获取 DrawingCanvas 画布对象，使用 drawing.Brush 创建画刷设置颜色，调用 attachBrush/drawRect/detachBrush 绘制图形，最后通过 unlockCanvasAndPost 提交绘制结果到 Surface 显示。

| 备选方案 | 不适合的理由 |
|---------|------------|
| Canvas 组件 | 使用 CanvasRenderingContext2D 绘制，无法直接操作 Surface 缓冲区 |
| Image | 只能显示静态图片，无法提供 Surface 进行自定义绘制 |

```typescript
import { common2D, drawing } from '@kit.ArkGraphics2D';

@Entry
@Component
struct XComponentPage {
  private xcController: XComponentController = new XComponentController();
  private bgColor: common2D.Color = { alpha: 255, red: 30, green: 30, blue: 50 };

  // 绘制矩形：坐标为 px，需用 vp2px 转换
  private drawRect(r: number, g: number, b: number, a: number,
    left: number, right: number, top: number, bottom: number) {
    const canvas = this.xcController.lockCanvas();  // 获取画布对象
    if (canvas) {
      canvas.clear(this.bgColor);  // 每次绘制前清除上一帧
      const brush = new drawing.Brush();
      brush.setColor({ alpha: a, red: r, green: g, blue: b });
      canvas.attachBrush(brush);
      canvas.drawRect({ left, right, top, bottom });
      canvas.detachBrush();
      this.xcController.unlockCanvasAndPost(canvas);  // 提交到 Surface
    }
  }

  build() {
    XComponent({ type: XComponentType.SURFACE, controller: this.xcController })
      .onLoad(() => {
        const canvas = this.xcController.lockCanvas();
        if (canvas) { canvas.clear(this.bgColor); this.xcController.unlockCanvasAndPost(canvas); }
      })
      .onDestroy(() => { /* 清理资源 */ })
      .width('100%').height(350)
  }
}
```

### XComponentType 枚举

| 枚举值 | 说明 | 适用场景 |
|--------|------|---------|
| `SURFACE` | 提供 Surface 用于自定义绘制 | 自定义绘制、视频流渲染、相机预览 |
| `COMPONENT` | 提供 Native 组件嵌入 | 自定义 Native 组件 |
| `TEXTURE` | 提供 Texture 用于 GPU 渲染 | 3D 图形渲染、游戏画面 |

### XComponentController 画布操作方法枚举

| 方法 | 说明 |
|------|------|
| `lockCanvas()` | 获取 DrawingCanvas 画布对象（返回 null 表示失败） |
| `unlockCanvasAndPost(canvas)` | 提交绘制结果到 Surface 显示 |
| `getXComponentSurfaceId()` | 获取 Surface ID |

### DrawingCanvas 核心方法枚举

| 方法 | 说明 |
|------|------|
| `clear(common2D.Color)` | 清空画布（每次绘制前必须清除上一帧） |
| `attachBrush(brush)` | 绑定画刷 |
| `drawRect({ left, right, top, bottom })` | 绘制矩形（坐标为 px） |
| `detachBrush()` | 解绑画刷 |

### 关键约束

| 约束 | 说明 |
|------|------|
| DrawingCanvas 坐标系为 px | 需用 vp2px() 将 vp 坐标转换为 px |
| 每次绘制前必须 clear | 清除上一帧内容，避免残留 |
| clear 参数为 common2D.Color | alpha=255 完全不透明，彻底清除画布 |

---

## 自定义组件选型速查对比表

| 能力 | 核心作用 | 典型场景 | 关键限制 |
|------|---------|---------|---------|
| **DrawModifier** | drawBehind/drawFront 自定义绘制 | 渐变边框、外发光、霓虹灯、图案背景 | context.size 返回 vp，canvas 需 px |
| **AttributeModifier** | 封装多态四态样式 | 企业级按钮规范（主/次/危险/禁用） | @Styles 不支持参数和跨文件 |
| **GestureModifier** | applyGesture 动态切换手势 | 设计工具拖拽/缩放/旋转模式切换 | 手势切换在下一次操作生效 |
| **ContentModifier** | applyContent 替换内容区 | Button 图标+文字、Checkbox 收藏切换 | 自定义属性不触发刷新，用 config 驱动 |
| **FrameNode** | typeNode.createNode 动态节点 | JSON 驱动表单、运行时增删表单项 | 根容器须用 Column 类型节点 |
| **RenderNode** | 重写 draw 方法渲染 | 手写签名、实时绘制笔迹 | Path 坐标用 px，需 vp2px 转换 |
| **BuilderNode** | build 动态构建组件树 | 信息流穿插广告、占位先行内容后填 | rebuild() 重建整树，丢失状态 |
| **XComponent** | SURFACE + lockCanvas 绘制 | Surface 上用画布对象绘制图形 | 坐标系为 px，每次绘制前须 clear |
