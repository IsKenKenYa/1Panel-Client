# 手势事件响应控制与冲突处理


## 手势竞争控制 API 速查与对比

上述各场景用到了多个"干预手势竞争"的回调，它们的关键区别在于**控制的手势竞争范围（覆盖哪些节点）与触发时机**。下表汇总对比，便于按需选型：

| API | 配置节点 | 控制的手势竞争范围 | 触发时机 | 干预方式                                                                       | 关联场景 |
|-----|---------|------------------|---------|----------------------------------------------------------------------------|---------|
| `onChildTouchTest` | 父组件 | **子组件**：决定触摸事件转发给哪个子节点参与竞争 | 触摸测试阶段，子节点触摸测试时 | 返回 `TouchResult`（`id` + `TouchTestStrategy`）                               | SCENE-05 |
| `onGestureCollectIntercept` | 当前组件 | **当前节点及更高优先级节点**：响应链上将被收集的全部识别器 | 手势收集阶段，收集**之前** | 返回 `GestureCollectIntervention`（如 `DISCARD_LOWER_PRIORITY_SIBLINGS`）       | SCENE-06 |
| `shouldBuiltInRecognizerParallelWith` | 当前组件（需具备内置手势） | **当前节点内置手势 与 子组件（响应链上同类型）手势** 的并行关系 | 手势收集阶段，识别器构建时 | 回调 `(current, others)` 返回需并行的识别器（或 `undefined`）                            | SCENE-10 |
| `onTouchTestDone` | 当前组件 | **指定手势识别器**：可按类型 / 组件 `id` / `isBuiltIn()` 筛选，覆盖整条响应链 | 触摸测试**完成后**、识别开始前 | 遍历 `recognizers` 调用 `recognizer.preventBegin()` | SCENE-11 |
| `onGestureRecognizerJudgeBegin` | 当前组件 | **当前节点（自身）** 是否参与手势处理 | 手势识别**判定前** | 返回 `GestureJudgeResult`                         | SCENE-10 |

### 选型要点

1. **先看"要管谁的竞争"**：
   - 只想决定事件**转发给哪个子节点**参与竞争 → `onChildTouchTest`（父配子，按子节点 `id` 定位）。
   - 想按**响应链范围**（当前节点/兄弟节点/高优先级节点/低优先级节点层面）整体筛选手势 → `onGestureCollectIntercept`。
   - 想让**当前节点内置手势与子组件同类型手势并行**（典型为嵌套 Scroll 联动滚动）→ `shouldBuiltInRecognizerParallelWith`, 一般与`onGestureRecognizerJudgeBegin`配合使用。
   - 想从外部**禁用某个/某类识别器**（如禁用子组件 PdfView 的 Pinch 缩放）→ `onTouchTestDone` + `preventBegin()`。
   - 想在识别判定前**控制当前节点自身是否参与**手势处理（可结合偏移量、滚动位置等手势状态动态决策）→ `onGestureRecognizerJudgeBegin`。

2. **再看"在哪一阶段介入"**：
   - `onChildTouchTest` / `onGestureCollectIntercept` / `shouldBuiltInRecognizerParallelWith` 都处于**收集前/收集中**——影响"哪些手势进入竞争"。
   - `onTouchTestDone` 处于**收集后、识别前**——剔除"已收集但不想让其识别"的识别器。
   - `onGestureRecognizerJudgeBegin` 处于**识别判定时**——控制识别器开闭并给出最终判定。

> 注意：`onTouchTestDone` + `preventBegin()` 从 API version 20 起支持；`onChildTouchTest` 从 API version 11 起支持；`onGestureCollectIntercept` 从 API version 26 起支持。使用前请确认目标设备 API 版本。

### preventBegin() 与 setEnabled() 的识别器级控制对比

`onTouchTestDone` 与 `onGestureRecognizerJudgeBegin` 都会拿到 `GestureRecognizer`，但其上两个「禁用识别器」的方法 `preventBegin()` 与 `setEnabled()` **作用阶段与效果完全不同**，混用会导致失效，按下表选型：

| 方法 | 生效阶段 | 效果 | 适用手势类型 |
|------|---------|------|-------------|
| `recognizer.preventBegin()` | **触摸测试完成后、识别开始前**（即 `onTouchTestDone` 中调用） | **阻止该手势参与识别**：识别器被剔除出竞争，不会进入识别流程 | 所有手势类型 |
| `recognizer.setEnabled(boolean)` | 手势**识别判定阶段**（典型为 `onGestureRecognizerJudgeBegin` 内调用） | **不阻止手势参与识别**，仅控制识别成功后**手势回调函数是否执行** | **仅适用于滚动手势** |

> ⚠ **`preventBegin()` 在手势识别开始后调用无效**：`onGestureRecognizerJudgeBegin` 已处于识别判定阶段，识别器已进入识别流程，此时再调用 `preventBegin()` 无法将其从识别中剔除。若要"让某手势彻底不参与识别"，必须在更早的 `onTouchTestDone` 阶段调用。

**选型速判：**
- 想在收集后**彻底剔除某手势不参与识别**（如禁用 PdfView 的 Pinch 缩放）→ `onTouchTestDone` + `preventBegin()`（见 SCENE-11）。
- 想在识别判定时**控制滚动手势回调是否执行**（如内外层 Scroll 嵌套滚动分流）→ `onGestureRecognizerJudgeBegin` + `setEnabled()`（见 SCENE-10）。

### onTouchIntercept / hitTestBehavior / onGestureCollectIntercept 三者选型

这三者都常用于「浮层/覆盖层与底层的手势冲突」，但适用边界不同。结合**开发者语义与代码上下文**按以下两条规则判断：

**规则一｜只需"按区域位置"判断，还是要"按指定手势类型的组件"判断？** ——区分 `onTouchIntercept` 与 `onGestureCollectIntercept`

- 冲突解决方案**只取决于触摸点落在哪个区域/位置**（如"交互区内不透传、区外透传"），无需关心是哪种手势、命中哪个组件 → `onTouchIntercept`，在触摸测试最早期按坐标返回 `HitTestMode`（见 SCENE-04）。
- 冲突解决方案**需要识别"该位置是否存在绑定了指定手势类型的组件"**（如"仅当浮层按钮——它绑定了点击手势——处于该位置时才独占，否则放行"），需遍历识别器按 `getType()` + 组件归属判断 → `onGestureCollectIntercept`（见 SCENE-06）。

> 代码上下文速判：方案里只用 `displayX/displayY` 与区域坐标做比较 → `onTouchIntercept`；需要用到 `recognizers`、`getType()`、`.id()`/`isHostBelongsTo()` → `onGestureCollectIntercept`。

**规则二｜从上层统一提供方案，还是改动子组件来解决？** ——区分 `onGestureCollectIntercept` 与 `hitTestBehavior`

- 希望**只在外层一处统一提供冲突解决方案、不改动底层或子组件**（底层为三方/系统组件，或不便逐个配置）→ `onGestureCollectIntercept`，在外层注册一次即可统观整条响应链（见 SCENE-06）。
- **可以、也愿意逐个改动子组件**（容器设 `HitTestMode.None` 穿透 + 交互子组件设 `HitTestMode.BLOCK_HIERARCHY` 拦截），且对所有手势一刀切即可 → `hitTestBehavior`（见 SCENE-02、SCENE-03）。

> 开发者语义速判：语义是"在外层统一管、子组件保持原样" → `onGestureCollectIntercept`；语义是"给某个子组件/容器设个命中模式"且能直接改目标组件 → `hitTestBehavior`。

---

## SCENE-01 边缘按钮扩大响应热区

**适用场景：** 当可交互组件位于屏幕边缘或靠近屏幕边缘时使用。在移动设备上，用户手指触碰屏幕边缘往往不够精准，容易导致点击失效。通过 `responseRegion` 将响应区域向屏幕外方向扩展，在不改变视觉布局的前提下提升边缘组件的点击成功率。例如侧边栏切换按钮、悬浮在页面边缘的返回按钮、侧滑菜单的操作按钮等。

**核心机制：** `responseRegion({ x, y, width, height })` 以组件左上角为坐标原点定义响应矩形。将 `x` 设为负值可将响应区域向左延伸，将 `width` 设为大于组件实际宽度可将响应区域向右延伸。这样视觉上组件大小不变，但实际可点击区域被扩大。

### 应用场景：侧边栏切换按钮扩大热区

侧边栏切换按钮紧贴屏幕右边缘，按钮本身尺寸较小（24×48vp），用户在手机上点击边缘区域时容易失误。通过 `responseRegion` 将热区向四周扩展，保证用户点击按钮附近区域即可触发切换。

**实现步骤：**

1. **声明位移状态**：声明 `@State sideBarBtnOffset: number = 0` 驱动按钮位移,与 `isShowSideBar` 分开
2. **包裹动画闭包**：在切换方法内用 `animateTo({ duration: 300, curve: Curve.Friction }, () => { ... })` 包裹 `sideBarBtnOffset` 赋值
3. **绑定视觉位移**：Image 链式调用 `.offset({ x: this.sideBarBtnOffset })`
4. **扩大命中热区**：Image 链式调用 `.responseRegion({ x: -12, y: -12, width: 48, height: 72 })`(`x`/`y` 负值向外扩,`width`/`height` 为热区总尺寸)

```typescript
@Component
export struct SideBarContentView {
  @Link isShowSideBar: boolean;
  @State sideBarBtnOffset: number = 0;

  switchTabBar() {
    animateTo({ duration: 300, curve: Curve.Friction }, () => {
      this.isShowSideBar = !this.isShowSideBar;
      if (this.isShowSideBar) {
        this.sideBarBtnOffset = -240;   // 侧边栏宽度
      } else {
        this.sideBarBtnOffset = 0;
      }
    })
  }

  build() {
    Stack() {
      // ... 侧边栏内容省略

      // ① 侧边栏切换按钮：箭头图标，紧贴屏幕右边缘
      Image(this.isShowSideBar
        ? $r("sys.media.ohos_ic_public_arrow_right")
        : $r("sys.media.ohos_ic_public_arrow_left"))
        .objectFit(ImageFit.Cover)
        .onClick(() => {
          this.switchTabBar();
        })
        .height(48)
        .width(24)
        .borderRadius({ topLeft: 12, bottomLeft: 12 })
        .offset({ x: this.sideBarBtnOffset })
        // ② responseRegion：扩大边缘按钮的响应热区
        .responseRegion({
          x: -12,       // 向左扩展 12vp
          y: -12,       // 向上扩展 12vp
          width: 48,    // 向右扩展至 48vp（原宽 24 + 左扩 12 + 右扩 12）
          height: 72    // 向下扩展至 72vp（原高 48 + 上扩 12 + 下扩 12）
        })
        .backgroundColor($r("sys.color.ohos_id_color_sub_background"))
    }
    .width('100%')
    .alignContent(Alignment.End)
  }
}
```

---

## SCENE-02 容器选择性事件穿透

**适用场景：** 当一个**含子组件的容器覆盖在「可点击底层」之上**，且要求「子组件（按钮/输入框等）上的所有手势只被子组件响应、不穿透到底层；点容器空白区域则穿透到底层」时使用。典型包括：弹窗遮罩层、新手引导蒙层、悬浮操作面板等均优先归入本场景。

**核心机制：** 给父容器设置 `hitTestBehavior(HitTestMode.None)` 使其自身不参与触摸测试，点击事件传递到下方组件；同时给容器内需要交互的子组件设置 `hitTestBehavior(HitTestMode.BLOCK_HIERARCHY)` 阻止事件继续向蒙层下方传递。

### 实现步骤

1. **分层叠加**：`Stack` 内先放底层业务 `Column`,再放蒙层 `Column`
2. **蒙层穿透**：蒙层 `Column` 链式调用 `.hitTestBehavior(HitTestMode.None)`
3. **子组件独占**：蒙层内交互组件(如 Button)链式调用 `.hitTestBehavior(HitTestMode.BLOCK_HIERARCHY)`
4. **扩展安全区**：蒙层 `Column` 链式调用 `.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])`
5. **设置遮罩样式**：蒙层 `Column` 链式调用 `.backgroundColor('rgba(0, 0, 0, 0.3)')`

```typescript
@Entry
@Component
struct BlockHierarchy {
  build() {
    Stack() {
      // ① 蒙层下方组件：接收穿透的触摸事件
      Column()
        .onTouch(() => {
          console.info('蒙层下方组件被点击');
        })
        .height('100%')
        .width('100%');

      // ② 全屏蒙层
      Column() {
        // ③ 蒙层内子组件：阻止事件穿透
        Button('蒙层内按钮')
          .hitTestBehavior(HitTestMode.BLOCK_HIERARCHY)
          .onTouch(() => {
            console.info('蒙层内子组件被点击');
          });
      }
      .justifyContent(FlexAlign.Center)
      .hitTestBehavior(HitTestMode.None)   // 蒙层自身不拦截事件
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .backgroundColor('rgba(0, 0, 0, 0.3)')
      .height('100%')
      .width('100%');
    }
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .height('100%')
    .width('100%');
  }
}
```

---

## SCENE-03 阻止子组件触发父容器滚动

**适用场景：** 当 Scroll、List 等可滚动容器中存在特定子组件，希望触摸该子组件时不会触发父容器的滚动行为，触摸其余区域时父容器正常滚动。例如滚动列表中的地图卡片、可拖拽滑块、画布区域等。

**核心机制：** 给需要阻止滚动的子组件设置 `hitTestBehavior(HitTestMode.Block)`，该组件会阻塞其父组件的触摸测试，使父容器的滚动手势无法被触发。

### 实现步骤

1. **搭建滚动结构**：父容器用 `Scroll() { Column() { ... } }` 结构
2. **阻塞父容器滚动**：在需要阻止滚动的子组件上链式调用 `.hitTestBehavior(HitTestMode.Block)`

```typescript
@Entry
@Component
struct Block {
  build() {
    Scroll() {
      Column({ space: 16 }) {
        Column()
          .height(400)
          .width('100%')
        // ② 该区域触摸不会触发 Scroll 滚动
        Column()
          .height(56)
          .width('100%')
          .backgroundColor('#F1F3F5')
          .hitTestBehavior(HitTestMode.Block)
        Column()
          .height(400)
          .width('100%')
      };
    }
    .width('100%')
    .height('100%');
  }
}
```

---

## SCENE-04 触摸时动态决定事件透传

**适用场景：** 当需要在触摸发生后再根据触摸点位置动态决定是否透传事件时使用。例如一个容器组件内部有特定交互区域，点击该区域时不透传到下层，点击空白区域时透传到下层；或者同一组件在不同位置/状态下需要不同的触摸行为。

**核心机制：** 使用 `onTouchIntercept` 回调，在触摸测试最早期根据触摸点坐标、输入源等信息动态返回不同的 `HitTestMode` 值，实现运行时决定事件是否透传。核心能力即「按触摸点动态返回 `HitTestMode`」，交互区坐标的获取方式留给业务方按场景决定。

### 实现步骤

1. **Stack 分层叠加**：底层放业务组件（如 TextArea），上层放覆盖容器
2. **绑定 onTouchIntercept**：在上层容器上注册回调，读取 `event.touches[0].displayX/displayY`（相对应用窗口坐标）
3. **判定触摸点是否落在交互区**：交互区坐标范围按业务场景传入（见代码注释），与 `displayX/displayY` 同基准可直接比较
4. **按区域返回 HitTestMode**：交互区内返回 `HitTestMode.Default`（不透传，上层处理），区域外返回 `HitTestMode.Transparent`（透传到下层）

```typescript
@Entry
@Component
struct HitTestModeDemo {
  // 交互区坐标范围：由业务场景赋值（赋值方式见 onTouchIntercept 内注释）
  private areaX: number = 0;
  private areaY: number = 0;
  private areaW: number = 0;
  private areaH: number = 0;

  build() {
    Stack() {
      // ① 下层业务组件：接收区域外穿透下来的触摸
      TextArea({ placeholder: '点击空白区域可输入；点击交互区由上层处理' })
        .width('100%')
        .height('100%')
        .backgroundColor('#F1F3F5');

      // ② 上层覆盖容器：onTouchIntercept 动态决定是否透传
      Column() {
        // 交互区域：上层希望自行处理触摸的子组件
        Column() {
          Text('交互区域').fontSize(16)
        }
        .width(160)
        .height(80)
        .backgroundColor('#C7C7CC')
        .hitTestBehavior(HitTestMode.Block)        // 交互区消费触摸，阻止事件冒泡
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .onTouchIntercept((event: TouchEvent) => {
        const touchX: number = event.touches[0].displayX;
        const touchY: number = event.touches[0].displayY;
        // ⚠ 交互区坐标（this.areaX/areaY/areaW/areaH）请根据业务场景赋值，常见方式：
        //   · onAreaChange 缓存交互区的 globalPosition.x/y 与 width/height（动态布局推荐）；
        //   · 布局固定时直接使用坐标常量；
        //   · 多个交互区可改为数组，遍历判定命中任一即可。
        // 注意：displayX/displayY 与 globalPosition 同为「相对应用窗口」坐标，可直接比较，无需换算。
        const inside: boolean =
          this.areaX <= touchX && touchX <= this.areaX + this.areaW &&
          this.areaY <= touchY && touchY <= this.areaY + this.areaH;
        return inside
          ? HitTestMode.Default        // 区域内：上层处理，不透传
          : HitTestMode.Transparent;   // 区域外：透传到下层 TextArea
      });
    }
    .height('100%')
    .width('100%');
  }
}
```

---

## SCENE-05 自定义 Slider 支持点击滑轨定位 + 无缝拖动滑块

**适用场景：** 当自定义 Slider 既需要点击滑轨任意位置快速定位到对应值，又希望用户不抬起手指就能继续拖动滑块进行精调时使用。常见于音量/亮度调节、进度条跳转、取色器色相滑块、自定义正负向 Slider（零点在中间，左右双向调节）等"先点后拖"型交互。该模式也可推广到任何"父容器响应按下 + 同一手势接力拖动指定子组件"的场景，如可拖拽标签轴、地图缩放条等。

**核心机制：** 通过 `contentModifier` 完全自定义 Slider 内容区后，原生滑块的触摸逻辑被替换，需要自行重建交互链路。在内容区根容器（Stack）上注册 `onChildTouchTest` 回调，返回一个 `TouchResult` 对象，通过 `id` 指定滑块子组件（需提前通过 `.id('xxx')` 声明 ID），并通过 `strategy: TouchTestStrategy.FORWARD_COMPETITION` 告诉系统将本次触摸测试**转发（Forward）**给滑块参与竞争。这样根容器的 `onTouch`（处理 Down 计算并提交初值）与滑块的 `PanGesture`（处理后续拖动）可以在同一次手势中接力执行，无需用户抬起手指重新按下。

**实现思路：** 滑轨用 `linearGradient` 渲染（中间为零点，左右两段表示正负值），滑块是一个带 `PanGesture` 的 `Circle`。根容器 `Stack` 的 `onTouch` 处理点击滑轨定位的逻辑，`onChildTouchTest` 则把后续拖动事件转发给滑块，实现"点一下定位、继续拖精调"的连续操作。

**实现步骤：**

1. **根容器 `onTouch` 处理点击定位**：在 `TouchType.Down` 时根据触摸点 x 坐标计算对应的 value 并通过 `config.triggerChange(value, SliderChangeMode.Click)` 提交。
2. **滑块绑定 `PanGesture`**：滑块 `Circle` 通过 `.id('circle')` 声明 ID，并绑定水平方向的 `PanGesture`，在 `onActionStart`/`onActionUpdate`/`onActionEnd` 中分别提交 `Begin`/`Moving`/`End` 状态。
3. **根容器 `onChildTouchTest` 转发事件**：返回 `{ strategy: TouchTestStrategy.FORWARD_COMPETITION, id: 'circle' }`，让同一次手势的后续移动事件转发到滑块，使滑块的 `PanGesture` 能在不抬起手指的情况下接管拖动。

```typescript
@Component
export struct CustomSlider {
  @State sliderValue: number = 0;
  @State sliderWidth: number = 0;

  build() {
    Column({ space: 10 }) {
      // ① 用 contentModifier 自定义 Slider 内容区
      Slider({ value: $$this.sliderValue, min: -100, max: 100 })
        .contentModifier(new MySliderStyle(this.sliderWidth))
        .padding(20)
        .onSizeChange((oldSize, newSize) => {
          // 组件宽度 - padding*2 即为滑轨宽度
          this.sliderWidth = (newSize.width as number) - 40;
        });

      Text(`sliderValue:${this.sliderValue}`).fontSize(30);
    }
    .height('100%')
    .width('100%');
  }
}

class MySliderStyle implements ContentModifier<SliderConfiguration> {
  sliderWidth: number = 0;
  lastOffsetX: number = 0;
  constructor(sliderWidth: number) {
    this.sliderWidth = sliderWidth;
  }
  applyContent(): WrappedBuilder<[SliderConfiguration]> {
    return wrapBuilder(buildSlider);
  }
}

@Builder
function buildSlider(config: SliderConfiguration) {
  Stack() {
    // 自定义滑轨：通过渐变色实现「滑轨-已滑动部分-滑轨」，零点位于中间
    Row()
      .width('100%')
      .height(8)
      .borderRadius(4)
      .linearGradient({
        angle: 90,
        colors: [
          [$r('sys.color.ohos_id_color_component_normal'),
            config.value <= 0 ? (0.5 - config.value / config.min / 2) : 0.5],
          [$r('sys.color.ohos_id_color_emphasize'), config.value <= 0 ? (0.5 - config.value / config.min / 2) : 0.5],
          [$r('sys.color.ohos_id_color_emphasize'), config.value >= 0 ? (0.5 + config.value / config.max / 2) : 0.5],
          [$r('sys.color.ohos_id_color_component_normal'),
            config.value >= 0 ? (0.5 + config.value / config.max / 2) : 0.5]
        ]
      });

    // ② 自定义滑块：声明 id 并绑定水平 PanGesture
    Circle({ width: 20, height: 20 })
      .id('circle')
      .fill('#fff')
      .borderRadius('50%')
      .shadow({ radius: 10, color: Color.Gray })
      .offset({ x: config.value / config.max * ((config.contentModifier as MySliderStyle).sliderWidth / 2) })
      .gesture(
        PanGesture({ direction: PanDirection.Horizontal, distance: 1 })
          .onActionStart(() => {
            config.triggerChange(config.value, SliderChangeMode.Begin);
            (config.contentModifier as MySliderStyle).lastOffsetX = 0;
          })
          .onActionUpdate((even) => {
            config.value = config.value +
              Math.round((even.offsetX - (config.contentModifier as MySliderStyle).lastOffsetX) /
                (config.contentModifier as MySliderStyle).sliderWidth * 200);
            config.triggerChange(config.value, SliderChangeMode.Moving);
            (config.contentModifier as MySliderStyle).lastOffsetX = even.offsetX;
          })
          .onActionEnd(() => {
            config.triggerChange(config.value, SliderChangeMode.End);
          })
      );
  }
  // ① 父容器 onTouch：点击滑轨时根据 x 坐标计算并提交 value
  .onTouch((even) => {
    if (even.type === TouchType.Down) {
      config.value = Math.round(even.touches[0].x / (config.contentModifier as MySliderStyle).sliderWidth * 200) - 100;
      config.triggerChange(config.value, SliderChangeMode.Click);
    }
  })
  // ③ onChildTouchTest：把同一次手势的后续事件转发给滑块，实现「点完不松手继续拖」
  .onChildTouchTest(() => {
    return { strategy: TouchTestStrategy.FORWARD_COMPETITION, id: 'circle' };
  });
}
```

**关键要点：**

1. **`onChildTouchTest` 与 `onTouch` 各司其职**：父容器的 `onTouch` 处理"点击即定位"的瞬时逻辑（`TouchType.Down`），`onChildTouchTest` 处理"后续事件往哪走"的分发逻辑，二者在同一次手势中协同工作。
2. **`TouchTestStrategy.FORWARD_COMPETITION`**：表示将触摸测试**转发**给 `id` 指定的子节点参与竞争。子节点（滑块）的 `PanGesture` 因此能在用户不抬手的情况下被激活，承接拖动事件。
3. **目标子组件必须声明 `.id('xxx')`**：`onChildTouchTest` 返回的 `id` 字段需要与子组件通过 `.id()` 声明的 ID 完全一致，否则事件无法定位到目标子节点。
4. **与 SCENE-04 `onTouchIntercept` 的区别**：`onTouchIntercept` 返回的是 `HitTestMode`，决定的是"是否透传到下层"；`onChildTouchTest` 返回的是 `TouchResult`（含 `id` + `strategy`），决定的是"事件转发给哪个子节点"，适合"父子协作型"手势而非"上下层穿透型"手势。
5. **适配 `contentModifier` 自定义内容**：当 Slider 等系统组件通过 `contentModifier` 完全自定义内容区时，原生滑块的触摸逻辑被替换，必须自行通过 `onTouch` + `PanGesture` + `onChildTouchTest` 重建"点击定位 + 拖动精调"的完整交互链路。

---

## SCENE-06 短视频透明浮层点赞/收藏独占手势

> **版本要求：** `onGestureCollectIntercept` 从 API version 26 起支持，使用本方案前请确认目标设备不低于该版本；低版本设备请改用其他方案。

**适用场景：** 希望**从外层（浮层）统一管控手势冲突、无需逐个修改底层或子组件**时使用。典型诉求：触摸浮层内的交互子组件（如按钮）时仅该子组件响应、不与底层重复触发；浮层空白区的触摸穿透到底层。这类需求若用 `hitTestBehavior`，需在容器和每个交互子组件上分别设 `HitTestMode`（要改子组件）；若用 `onTouchIntercept`，只能按触摸点粗粒度返回 `HitTestMode`。而 `onGestureCollectIntercept` 只在外层注册一次，即可统观整条响应链、按需选择冲突解决方案。典型场景：

- **短视频播放页**：底层是竖屏 `Swiper(vertical)`（上下滑切视频）+ item 点击切换播放/暂停，上层是右下角透明操作浮层（喜欢/收藏/评论按钮）。点按钮只触发按钮、不"双触发"视频层点击；点按钮外透明区穿透到视频层切换播放/暂停。
- **跨框架混合页面**：ArkUI 页面中嵌入 Flutter / WebView 渲染的 Surface（底层），其上叠加 ArkUI 透明操作栏（按钮、Tab 切换等），需要避免按钮点击"双触发"。
- **不宜改动底层/子组件的统一冲突管控**：底层是三方/系统组件（如 Flutter/WebView Surface）、不便逐个配置手势属性，希望在外层一处统一决定手势冲突如何解决。

**核心机制：** 在透明浮层容器上注册 `onGestureCollectIntercept`，**由外层统观整条响应链、统一选择手势冲突解决方案，无需改动底层或子组件**。关键在回调入参 `recognizers` 的语义：它是**该触摸位置响应链上"所有已绑定"的手势识别器**（一份"这里都绑了哪些手势"的快照），**而不是当前正在触发的那一个**。因此遍历 `recognizers` 时，用 `getType()` 读取每个识别器的手势类型、用 `isHostBelongsTo(uniqueId)`（宿主是否属于某节点子树）或 `getEventTargetInfo().getId()`（具体组件 id）判断**"这个位置上哪些组件绑定了哪些手势"**——这是**态势感知**，再**根据这份态势选择一个 `GestureCollectIntervention` 冲突解决方案**（如发现浮层按钮在此处绑定了点击手势 → 返回 `DISCARD_LOWER_PRIORITY_SIBLINGS`；否则返回 `CONTINUE`）。

> ⚠ **不能"为同一触摸点的不同手势类型"选择不同的手势冲突解决方案**：因为你拿到的是全部绑定的识别器、并非触发中的那一个，回调里无从得知"此刻触发的是点击还是滑动"。

**实现步骤：**

1. **底层全屏可交互容器（保持原样、不改它）**：正常绑定点击与滑动即可（如竖屏 `Swiper` 切视频 + item `onClick` 切播放/暂停；示例用 `Column` + `onClick` + 竖向 `PanGesture` 演示）。
2. **透明浮层容器**：设置 `hitTestBehavior(HitTestMode.Transparent)` 并通过 `.id('overlayNode')` 声明 ID；内部按钮**正常绑定手势**（如 `priorityGesture(TapGesture())`），**无需为冲突做任何额外配置**——这正是本方案"不改子组件"的体现。
3. **外层统一管控**：只在透明浮层容器上注册 `onGestureCollectIntercept`，遍历 `recognizers` 判断"该位置哪些组件绑定了哪些手势"，据此选择 `GestureCollectIntervention` 方案。

```typescript
@Entry
@Component
struct VideoFeedOverlay {
  build() {
    Stack() {
      // ① 底层全屏可交互容器：点击切播放/暂停，上下滑切视频（保持原样，不做冲突相关改动）
      Column() {}
        .width('100%').height('100%')
        .backgroundColor('#202020')
        .onClick(() => { /* 切换播放/暂停 */ })
        .gesture(
          PanGesture({ direction: PanDirection.Vertical, distance: 10 })
            .onAction(() => { /* 上下滑动切视频 */ })
        );

      // ② 透明操作浮层：仅在此处注册 onGestureCollectIntercept 统一管控
      Stack({ alignContent: Alignment.BottomEnd }) {
        Column({ space: 18 }) {
          // ③ 按钮正常绑定手势即可，无需为冲突额外配置
          Column() { Text('喜欢').fontSize(11).fontColor('#FFFFFF') }
            .width(56).height(72)
            .priorityGesture(TapGesture().onAction(() => { /* 点赞 */ }));
          Column() { Text('收藏').fontSize(11).fontColor('#FFFFFF') }
            .width(56).height(72)
            .priorityGesture(TapGesture().onAction(() => { /* 收藏 */ }));
        }
      }
      .id('overlayNode')                              // ★ onGestureCollectIntercept 依赖此 id 取 uniqueId
      .width('100%').height('100%')
      .padding({ right: 12, bottom: 96 })
      .hitTestBehavior(HitTestMode.Transparent)       // ★ 浮层全透明：空白处穿透到下层
      // ④ 外层统一管控：判断"该位置是否有浮层组件绑定了点击手势"，据此选择冲突解决方案
      .onGestureCollectIntercept((recognizers: Array<GestureRecognizer>) => {
        // recognizers 是该位置"所有已绑定"的识别器（非当前触发的），用于态势感知
        const overlayId: number | undefined =
          this.getUIContext().getFrameNodeById('overlayNode')?.getUniqueId();
        for (let i = 0; i < recognizers.length; i++) {
          const r: GestureRecognizer = recognizers[i];
          // 态势：该位置有浮层按钮绑定了点击手势 → 选择"丢弃低优先级兄弟"方案，让按钮的点击在此胜出
          if (overlayId !== undefined &&
            r.getType() === GestureControl.GestureType.TAP_GESTURE &&
            r.isHostBelongsTo(overlayId)) {
            return GestureCollectIntervention.DISCARD_LOWER_PRIORITY_SIBLINGS;
          }
        }
        // 态势：该位置无浮层按钮绑定点击手势（如空白透明区）→ 维持默认收集，事件交底层处理
        return GestureCollectIntervention.CONTINUE;
      });
    }
    .width('100%').height('100%');
  }
}
```

---

## SCENE-07 自定义手势与系统手势冲突

**适用场景：** 当组件的系统内置手势与开发者通过 `.gesture()` 绑定的自定义手势为同类型时，系统手势会优先响应，导致自定义手势无法触发。例如 Image 组件内置的长按预览动画与自定义 LongPressGesture 冲突、组件的 onClick 与自定义 TapGesture 冲突等。

**核心机制：** 同一组件绑定相同事件类型的系统手势和自定义手势时，系统手势优先响应。通过 `priorityGesture` 替代 `gesture` 绑定方式，可以使自定义手势优先于系统手势响应；通过 `parallelGesture` 绑定方式，可以让两者同时响应。

### 应用场景：Image 长按手势被内置动画抢占

在 Image 组件上添加 `.gesture(LongPressGesture())` 后，长按图片无法触发自定义回调，而是触发了图片放大的系统内置动画。这是因为 Image 组件内置的长按动画（系统手势）与自定义的 LongPressGesture（自定义手势）冲突，系统手势优先响应。

**实现步骤：**

1. **问题复现**：使用 `.gesture()` 绑定长按手势，发现被系统内置动画抢占
2. **优先响应自定义手势**：改用 `.priorityGesture()` 绑定，自定义手势优先于系统手势
3. **两者同时响应**（可选）：使用 `.parallelGesture()` 绑定，自定义手势和系统手势同时触发

```typescript
// ① 问题代码：使用 gesture 绑定，系统手势优先，自定义手势无法触发
@Entry
@Component
struct GestureConflictDemo {
  build() {
    Column() {
      Image($r('app.media.test_image'))
        .width(200)
        .height(200)
        .gesture(        // ❌ 被 Image 内置长按动画抢占
          LongPressGesture()
            .onAction(() => {
              console.info('长按手势触发');
            })
        )
    }
  }
}
```

```typescript
// ② 解决方案一：priorityGesture 让自定义手势优先
@Entry
@Component
struct PriorityGestureDemo {
  build() {
    Column() {
      Image($r('app.media.test_image'))
        .width(200)
        .height(200)
        .priorityGesture(  // ✅ 自定义手势优先于系统内置手势
          LongPressGesture()
            .onAction(() => {
              console.info('自定义长按手势触发');
            })
        )
    }
  }
}
```

```typescript
// ③ 解决方案二：parallelGesture 让两者同时触发
@Entry
@Component
struct ParallelGestureDemo {
  build() {
    Column() {
      Image($r('app.media.test_image'))
        .width(200)
        .height(200)
        .parallelGesture(  // ✅ 自定义手势和系统内置手势同时响应
          LongPressGesture()
            .onAction(() => {
              console.info('自定义长按手势触发');
            })
        )
    }
  }
}
```

---

## SCENE-08 多点触控场景下手势冲突

**适用场景：** 当一个页面中有多个可交互组件，在多指触控的情况下，多个组件可能同时响应手势事件，导致业务异常。例如一个页面中有多个按钮，用户同时用多根手指点击不同按钮时，所有按钮都会触发点击事件，可能产生意料之外的状态变化。

**核心机制：** 通过 `monopolizeEvents(true)` 属性设置组件独占事件响应。设置后，该组件上的事件如果首先响应，则本次交互只允许此组件上设置的事件响应，窗口内其他组件上的事件不会响应，直到手指离开屏幕。

### 应用场景：修图页面滑块与工具栏多点触控冲突

修图页面中，用户通过底部工具栏选择调节项（亮度、对比度等），选中后弹出 Slider 滑块进行参数调节。在多指触控情况下，用户可能同时触摸滑块和底部工具栏按钮，导致滑块拖动过程中误触发工具栏切换，或工具栏点击时误触滑块。需要确保 Slider 拖动时独占事件响应，防止与底部工具栏产生冲突。

**实现步骤：**

1. **识别需要独占的组件**：Slider 滑块在拖动调节参数时需要独占事件，避免与底部工具栏按钮产生多点触控冲突
2. **设置 monopolizeEvents**：给 Slider 组件添加 `.monopolizeEvents(true)`，拖动滑块时其他组件不响应
3. **验证行为**：手指触摸滑块后，底部工具栏按钮在手指离开前不响应点击事件

```typescript
@Entry
@Component
struct PhotoEditPage {
  @State currentTool: number = -1
  @State showSlider: boolean = false
  @State sliderValue: number = 50

  private tools: ToolItem[] = [
    { id: 0, name: '亮度', iconText: '☀' },
    { id: 1, name: '对比度', iconText: '◐' },
    { id: 2, name: '饱和度', iconText: '💧' },
    // ...
  ]

  @Builder
  SliderArea() {
    if (this.showSlider) {
      Column() {
        Row() {
          Text(this.tools[this.currentTool]?.name ?? '')
            .fontSize(14).fontColor(Color.White)
          Text(`${this.sliderValue}`)
            .fontSize(14).fontColor('#FFA500').margin({ left: 8 })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 12 })

        // ① Slider 设置 monopolizeEvents(true)
        // 拖动滑块时独占事件，防止底部工具栏被多指同时触发
        Slider({
          value: this.sliderValue,
          min: 0,
          max: 100,
          step: 1,
          style: SliderStyle.InSet
        })
          .monopolizeEvents(true)  // 独占事件：拖动滑块时工具栏按钮不响应
          .width('85%')
          .trackColor('#333333')
          .selectedColor('#FFA500')
          .blockColor('#FFFFFF')
          .onChange((value: number) => {
            this.sliderValue = Math.round(value)
          })
      }
      .width('100%')
      .padding({ top: 12, bottom: 8 })
      .backgroundColor('#1A1A1A')
    }
  }

  @Builder
  BottomToolBar() {
    Column() {
      Scroll() {
        Row({ space: 4 }) {
          // ② 底部工具栏按钮未设置 monopolizeEvents
          ForEach(this.tools, (tool: ToolItem) => {
            Column() {
              Text(tool.iconText).fontSize(22)
              Text(tool.name).fontSize(10)
            }
            .width(56)
            .onClick(() => {
              this.currentTool = tool.id
              this.showSlider = true
              this.sliderValue = 50
            })
          })
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .height(80)
    }
    .width('100%')
    .backgroundColor('#1A1A1A')
  }
}
```

---

## SCENE-09 动态控制自定义手势是否响应

**适用场景：** 在手势识别期间，开发者需要根据业务逻辑动态决定是否响应某个手势。例如悬浮球在禁用状态下需要拒绝点击手势，使点击事件能够向上传递给底层页面组件；根据用户权限控制特定手势是否生效；或者在特定交互阶段屏蔽某些手势。

**核心机制：** 使用 `onGestureRecognizerJudgeBegin` 回调方法，在手势识别阶段进行判定。回调参数中包含 `BaseGestureEvent` 和 `GestureRecognizer`，开发者可以返回 `GestureJudgeResult.REJECT` 拒绝手势响应、`GestureJudgeResult.ACCEPT` 直接允许手势响应、或 `GestureJudgeResult.CONTINUE` 继续默认手势识别流程。

### 应用场景：悬浮球禁用后点击事件透传

悬浮球组件绑定了 `GestureGroup(Exclusive)` 聚合拖拽（PanGesture）、长按（LongPressGesture）和点击（TapGesture）三种手势。用户长按悬浮球可切换禁用/启用状态。禁用后，需要拒绝悬浮球上的点击手势，使点击事件能够穿透悬浮球传递到底层页面内容。

**实现步骤：**

1. **绑定手势组**：使用 `GestureGroup(GestureMode.Exclusive, ...)` 聚合拖拽、长按、点击手势
2. **长按切换禁用状态**：通过长按手势回调翻转 `isDisable` 标志
3. **添加 onGestureRecognizerJudgeBegin**：在手势判定回调中根据 `isDisable` 状态和手势类型动态决定是否拒绝手势

```typescript
@Component
struct FloatingWindow {
  @State isDisable: boolean = false;

  build() {
    RelativeContainer() {
      Stack({ alignContent: Alignment.Center }) {
        // ... 工具栏子项 ...

        Column() {
          // 悬浮球 UI
        }
        .gesture(
          GestureGroup(GestureMode.Exclusive,
            PanGesture()
              .onActionStart(/* 拖拽开始 */)
              .onActionUpdate(/* 拖拽更新，控制悬浮球跟随手指移动 */)
              .onActionEnd(/* 拖拽结束，吸附到屏幕边缘 */),
            LongPressGesture()
              .onAction((event: GestureEvent) => {
                // 长按切换禁用/启用状态
                this.isDisable = !this.isDisable;
              }),
            TapGesture()
              .onAction((event: GestureEvent) => {
                // 点击展开/收起工具栏
              })
          )
        )
        // 知识点: 通过拒绝点击手势保证点击手势顺利向上传递
         .onGestureRecognizerJudgeBegin((event: BaseGestureEvent, current: GestureRecognizer, recognizers: Array<GestureRecognizer>) => {
            if (current.getType() === GestureControl.GestureType.TAP_GESTURE) {
               // 禁用时拒绝点击手势 → 组件不消费此次触摸 → 事件继续向下分发到底层页面
               return this.isDisable ? GestureJudgeResult.REJECT : GestureJudgeResult.CONTINUE;
            }
            // PAN / LONG_PRESS 继续 默认识别 → 拖拽与长按判定完全不受禁用影响
            return GestureJudgeResult.CONTINUE;
         })
      }
    }
  }
}
```

**关键要点：**

1. **ArkUI 手势「只消费一次」**：基础组件（如 `Column`/`Button` 的 `onClick`、List 的滚动、Image 的长按等内置手势）与自定义手势，在同一触摸序列中遵循「竞争者只有一个赢家」——某个识别器识别成功并消费该触摸后，链上其它**竞争**识别器即被置为失败/取消，因此一次触摸不会出现多个竞争节点同时响应（并行绑定的 `parallelGesture` 除外）。
2. **穿透要成立，底层页面须先「入链」**：仅 `onGestureRecognizerJudgeBegin` 返回 `REJECT` 让球不消费点击还不够——被拒绝的点击要落到底层页面，底层页面必须已在触摸测试链中。故悬浮球需设 `hitTestBehavior(HitTestMode.Transparent)` 把底层页面纳入链；再靠 `REJECT` 让球退出点击竞争，底层页面的点击识别器才能在「只消费一次」的竞争中胜出并消费（即穿透）。
3. **拖拽/长按为何不受影响**：底层页面通常只有点击类识别器、没有拖拽/长按识别器，这两类手势链上仅球有，球自然胜出并消费（`PAN`/`LONG_PRESS` 在回调恒返回 `CONTINUE`），不会穿透。

---

## SCENE-10 父组件管理子组件手势（手势拦截增强）

**适用场景：** 父子组件嵌套滚动发生手势冲突时，父组件需要干预子组件的手势响应。典型场景是嵌套的 Scroll 容器，需要根据滚动位置动态决定是内层还是外层容器滚动。例如外层 Scroll 嵌套内层 Scroll，内层滚动到顶部/底部后需要切换到外层滚动。

**核心机制：** 通过手势拦截增强机制，使用 `shouldBuiltInRecognizerParallelWith` 回调收集需要并行处理的手势识别器，再通过 `onGestureRecognizerJudgeBegin` 回调动态控制子组件和父组件的手势识别器是否可用。

### 应用场景：外层 Scroll 管理三方可滚动组件手势

**适用场景：** 原生 Scroll 容器内嵌套三方可滚动组件（如 Flutter/XComponent自定义 实现的可滚动列表，无法通过nestedScroll实现嵌套滚动），需要根据用户交互（如点击切换）动态控制外层 Scroll 是否响应滑动手势，避免与内层可滚动组件的滑动冲突。

**核心思路：**

1. **内层三方可滚动组件**：用 Column 模拟三方可滚动组件，绑定 `PanGesture` 提供手势识别器（供外层并行绑定），通过 `onClick` 切换 `consumePanGesture` 标志位控制是否需要消费滑动手势
2. **外层原生 Scroll**：通过 `shouldBuiltInRecognizerParallelWith` 找到内层 Column 的 Pan 手势识别器并形成并行，通过 `onGestureRecognizerJudgeBegin` 根据标志位控制内外层识别器的启用/禁用

**实现步骤：**

1. **内层 Column 绑定 PanGesture**：为内层 Column 添加 PanGesture 提供手势识别器，并添加 onClick 切换消费标志位
2. **外层 Scroll 并行绑定**：在 `shouldBuiltInRecognizerParallelWith` 中查找内层 Column 的 PanGesture 识别器（注意：不再检查 `isBuiltIn()`，因为 Column 的 PanGesture 是自定义手势）
3. **根据标志位控制手势路由**：在 `onGestureRecognizerJudgeBegin` 中根据 `consumePanGesture` 状态决定内外层识别器的启用/禁用

```typescript
@Entry
@Component
struct GesturesConflictScene8 {
  scroller: Scroller = new Scroller();
  private arr: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
  private childRecognizer: GestureRecognizer = new GestureRecognizer();
  private currentRecognizer: GestureRecognizer = new GestureRecognizer();
  @State consumePanGesture: boolean = false;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // ① 外层原生 Scroll 容器
      Scroll(this.scroller) {
        Column() {
          Text('Scroll Area')
            .width('100%')
            .height(150)
            .backgroundColor(0xFFFFFF)
            .borderRadius(15)
            .fontSize(16)
            .textAlign(TextAlign.Center)
            .margin({ top: 10 })

          // ② 内层 Column 模拟三方可滚动组件
          Column() {
            Text(this.consumePanGesture ? '消费滑动手势: 开' : '消费滑动手势: 关')
              .width('100%')
              .height(150)
              .backgroundColor(0xFFFFFF)
              .borderRadius(15)
              .fontSize(16)
              .textAlign(TextAlign.Center)
              .margin({ top: 10 })
            Column() {
              ForEach(this.arr, (item: number) => {
                Text(item.toString())
                  .width('100%')
                  .height(200)
                  .backgroundColor(0xFFFFFF)
                  .borderRadius(15)
                  .fontSize(20)
                  .textAlign(TextAlign.Center)
                  .margin({ top: 10 })
              }, (item: string) => item)
            }
            .width('100%')
          }
          .id('innerColumn')
          .width('100%')
          .height(800)
          // ③ 点击切换是否消费滑动手势
          .onClick(() => {
            this.consumePanGesture = !this.consumePanGesture;
          })
          // ④ 绑定 PanGesture 提供手势识别器，供外层并行绑定
          .gesture(
            PanGesture({ fingers: 1 })
              .onActionStart(() => {
              })
              .onActionEnd(() => {
              })
          )
        }.width('100%')
      }
      .id('outerScroll')
      .height(600)
      .scrollBar(BarState.Off)
      // ⑤ 收集内层 Column 的 PanGesture 识别器
      .shouldBuiltInRecognizerParallelWith((current: GestureRecognizer, others: Array<GestureRecognizer>) => {
        for (let i = 0; i < others.length; i++) {
          let target = others[i].getEventTargetInfo();
          if (target) {
            if (target.getId() === 'innerColumn' &&
              others[i].getType() === GestureControl.GestureType.PAN_GESTURE) {
              this.currentRecognizer = current;
              this.childRecognizer = others[i];
              return others[i];
            }
          }
        }
        return undefined;
      })
      // ⑥ 根据内层组件的标志位控制手势路由
      .onGestureRecognizerJudgeBegin((event: BaseGestureEvent, current: GestureRecognizer, recognizers: Array<GestureRecognizer>) => {
         if (this.consumePanGesture) {
            this.childRecognizer.setEnabled(true)   // 内层消费手势
            this.currentRecognizer.setEnabled(false)  // 外层 Scroll 不响应
         } else {
            this.childRecognizer.setEnabled(false)    // 内层不消费手势
            this.currentRecognizer.setEnabled(true)   // 外层 Scroll 正常滚动
         }
         return GestureJudgeResult.CONTINUE;
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(0xF1F3F5)
    .padding(12)
  }
}
```

---

## SCENE-11 阻止特定类型手势识别

**适用场景：** 需要完全阻止某个组件上的特定类型手势参与识别。例如 PdfView 组件内置了捏合缩放手势，业务上需要禁用缩放功能（仅允许阅读、不允许放大缩小）；又如需要阻止某些系统内置手势在特定条件下触发。

**核心机制：** 通过 `onTouchTestDone` 回调，在触摸测试完成后、手势识别开始前拦截。回调参数中包含 `TouchEvent` 和 `GestureRecognizer[]` 数组，开发者可以遍历识别器列表，通过 `recognizer.getType()` 判断手势类型，调用 `recognizer.preventBegin()` 阻止特定识别器进入识别状态。

### 应用场景：PdfView 禁用捏合缩放

PDF Kit 通过 PdfView 组件提供了 PDF 文档预览能力，其中页面缩放是通过内置的捏合手势（PinchGesture）实现的。业务场景中有时需要禁用缩放功能（如固定宽度的文档审阅模式），此时需要阻止 PdfView 上的捏合手势参与识别。

**实现步骤：**

1. **将 PdfView 包裹在容器中**：使用 Stack 等容器包裹 PdfView，在容器上设置 `onTouchTestDone` 回调
2. **遍历识别器列表**：在回调中遍历 `recognizers` 数组，通过 `getType()` 判断手势类型
3. **阻止目标手势**：调用 `recognizer.preventBegin()` 阻止捏合手势进入识别状态

```typescript
import { pdfService, pdfViewManager, PdfView } from '@kit.PDFKit';
import { fileIo } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'PDFView';

@Entry
@Component
struct PDFViewDemo {
  private controller: pdfViewManager.PdfController = new pdfViewManager.PdfController();

  aboutToAppear(): void {
    let context = this.getUIContext().getHostContext();
    if (!context) {
      hilog.error(0x0000, TAG, 'Get context failed');
      return;
    }

    let dir: string = context.filesDir;
    let filePath: string = dir + '/pdf_reference.pdf';
    try {
      fileIo.accessSync(filePath);
      let content: Uint8Array = context.resourceManager.getRawFileContentSync('rawfile/pdf_reference.pdf');
      let fdSand =
        fileIo.openSync(filePath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      fileIo.writeSync(fdSand.fd, content.buffer);
      fileIo.closeSync(fdSand.fd);
    } catch (e) {
      let err = e as BusinessError;
      hilog.error(0x0000, TAG, `fs operation failed, error code: ${err.code}, error message: ${err.message}`);
    }

    (async () => {
      let loadResult: pdfService.ParseResult = await this.controller.loadDocument(filePath);
      if (loadResult === pdfService.ParseResult.PARSE_SUCCESS) {
        hilog.info(0x0000, TAG, 'PDF load successfully');
      }
    })();
  }

  build() {
    Row() {
      Stack() {
        PdfView({
          controller: this.controller,
          pageFit: pdfService.PageFit.FIT_WIDTH,
          showScroll: true
        })
        .id('pdfview_app_view')
        .layoutWeight(1)
      }
      // ① 在父容器上设置 onTouchTestDone 回调
      .onTouchTestDone((event, recognizers) => {
        for (let i = 0; i < recognizers.length; i++) {
          let recognizer = recognizers[i];
          // ② 根据类型找到捏合手势识别器，调用 preventBegin() 阻止其识别
          if (recognizer.getType() == GestureControl.GestureType.PINCH_GESTURE) {
            recognizer.preventBegin();
          }
        }
      })
    }
    .width('100%')
    .height('100%')
  }
}
```