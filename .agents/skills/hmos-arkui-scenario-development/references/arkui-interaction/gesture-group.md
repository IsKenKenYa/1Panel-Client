
# 手势组合场景（GestureGroup）

## SCENE-01 Sequence 顺序手势：手势间存在先后依赖

**适用场景：** 当多个手势之间存在明确的先后调用顺序，前一个手势成功后后一个手势才应生效时使用。例如长按确认意图后再拖动（图标排序、卡片移动）、点击选中后再缩放（图片编辑器）、长按后再双击（快捷操作）等。

**核心机制：** `GestureGroup(GestureMode.Sequence, GestureA, GestureB)` 按顺序串联手势。GestureA 成功后 GestureB 才开始识别。如果 GestureA 未触发或被取消，GestureB 不会生效。仅最后一个手势的onActionEnd能响应。

### 应用场景：长按后拖动图片

用户先长按卡片确认操作意图，手指不松开即可拖动卡片移动位置，松手后卡片动画归位。

**实现步骤：**

1. **优先级绑定**：使用 `priorityGesture` 绑定手势组，优先于 Image 等组件的内置长按手势
2. **先序手势（LongPress）**：设置合理 `duration` 作为长按阈值，`onAction` 中激活拖动模式（放大 + 半透明视觉反馈）
3. **后序手势（Pan）**：设置 `distance: 0` 确保即使不拖动也能进入识别，从而作为最后一个手势能触发 `onActionEnd` 完成状态重置
4. **兜底重置（onCancel）**：当手势被系统中断时，序列中断走 `onCancel` 重置状态

```typescript
@Entry
@Component
struct LongPressDragDemo {
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State isDragging: boolean = false;
  @State cardScale: number = 1.0;
  @State cardOpacity: number = 1.0;

  build() {
    Column() {
      Column() {
        Image($r('app.media.startIcon'))
          .width(160)
          .height(160)
          .objectFit(ImageFit.Cover)
          .borderRadius(12)

        Text('长按拖动我')
          .fontSize(16)
          .fontColor(Color.White)
          .margin({ top: 12 })
      }
      .width(200)
      .height(240)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#FF2D73FF')
      .borderRadius(16)
      .shadow(this.isDragging
        ? { radius: 24, color: '#40000000', offsetX: 0, offsetY: 8 }
        : { radius: 0, color: Color.Transparent, offsetX: 0, offsetY: 0 })
      .scale({ x: this.cardScale, y: this.cardScale })
      .opacity(this.cardOpacity)
      .translate({ x: this.offsetX, y: this.offsetY })
      // 步骤 1：priorityGesture 优先于 Image 内置长按动画
      .priorityGesture(
        GestureGroup(GestureMode.Sequence,
          // 步骤 2：先序手势 - 长按进入拖动模式
          LongPressGesture({ fingers: 1, repeat: false, duration: 300 })
            .onAction(() => {
              this.isDragging = true;
              this.getUIContext().animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
                this.cardScale = 1.15;
                this.cardOpacity = 0.85;
              });
            }),
          // 步骤 3：后序手势 - distance: 0 确保进入识别，
          //         作为最后一个手势通过 onActionEnd 重置状态
          PanGesture({ fingers: 1, direction: PanDirection.All, distance: 0 })
            .onActionUpdate((event: GestureEvent) => {
              if (!this.isDragging) return;
              this.offsetX = event.offsetX;
              this.offsetY = event.offsetY;
            })
            .onActionEnd(() => {
              this.resetDrag();
            })
        )
        // 步骤 4：兜底 - 序列中断时重置状态
        .onCancel(() => {
          this.resetDrag();
        })
      )
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F1F3F5')
  }

  private resetDrag() {
    this.isDragging = false;
    this.getUIContext().animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
      this.offsetX = 0;
      this.offsetY = 0;
      this.cardScale = 1.0;
      this.cardOpacity = 1.0;
    });
  }
}
```

---

## SCENE-02 Parallel 并行手势：多手势同时识别，不同情况触发不同效果

**适用场景：** 当多个手势需要同时识别、并行触发时使用。例如不同时长的长按手势在同一组件上并行生效——短按触发收藏、中等时长触发分享、长按触发删除，用户按住时间越久，触发的操作等级越高。

**核心机制：** `GestureGroup(GestureMode.Parallel, GestureA, GestureB, GestureC)` 让组内所有手势同时参与识别，互不阻塞。每个手势独立触发各自的 `onAction` 回调，所有触发的手势都会执行 `onActionEnd` 。

### 应用场景：不同时长长按实现不同效果

用户长按一个按钮，随着按压时长增加依次触发不同等级的操作：0.5 秒收藏、1.5 秒分享、3.0 秒删除。

**实现步骤：**

1. **并行组合**：使用 `GestureGroup(GestureMode.Parallel, ...)` 将三个不同 `duration` 的 `LongPressGesture` 组合，它们同时开始识别
2. **分级触发**：最短时长（500ms）的手势最先触发 `onAction`，中等时长（1500ms）和最长时长（3000ms）的手势随时间推移依次触发
3. **状态递进**：每个手势的 `onAction` 通过 `if (this.pressLevel < N)` 保证等级只升不降
4. **松手重置**：在最短时长手势的 `onActionEnd`（松手）中将 `pressLevel` 归零，确保下一轮按压从零开始

```
// 状态：pressLevel 记录当前已触发的最高等级
pressLevel = 0

// ① GestureGroup(Parallel)：三个不同时长的 LongPressGesture 同时识别
组件.gesture(
  GestureGroup(GestureMode.Parallel,
    // ② 500ms → 收藏（最先触发）
    LongPressGesture({ duration: 500 })
      .onAction(() => {
        pressLevel = 1
        触发收藏
      })
      // ⑤ 松手后重置，下一轮按压从零开始
      .onActionEnd(() => {
        pressLevel = 0
      }),

    // ③ 1500ms → 分享
    LongPressGesture({ duration: 1500 })
      .onAction(() => {
        if (pressLevel < 2) {   // ④ 状态递进：保证等级只升不降
          pressLevel = 2
          触发分享
        }
      }),

    // ④ 3000ms → 删除
    LongPressGesture({ duration: 3000 })
      .onAction(() => {
        if (pressLevel < 3) {
          pressLevel = 3
          触发删除
        }
      })
  )
)
```

---

## SCENE-03 Exclusive 互斥手势：手势之间互斥执行

**适用场景：** 当多个手势绑定在同一个组件上，但同一时刻只应响应其中一种手势时使用。例如单击与长按互斥（单击跳转、长按弹出操作菜单）、单击与双击互斥（单击选中、双击打开）等。

**核心机制：** `GestureGroup(GestureMode.Exclusive, GestureA, GestureB)` 让组内手势互斥识别。系统按参数顺序逐一尝试，一旦某个手势匹配成功，其余手势不再响应。

### 应用场景：商品卡片长按弹出操作菜单，单击关闭菜单

用户单击商品图片关闭已打开的操作菜单，长按商品图片弹出「不感兴趣」等操作菜单，两个手势互斥——同一时刻只响应其中一种。

**实现步骤：**

1. **互斥组合**：使用 `GestureGroup(GestureMode.Exclusive, TapGesture, LongPressGesture)` 将单击与长按组合为互斥手势
2. **parallelGesture 绑定**：使用 `parallelGesture` 而非 `gesture`，使自定义手势与组件内置手势并行识别，避免被系统内置手势拦截
3. **单击关闭**：`TapGesture({ count: 1, fingers: 1 })` 的 `onAction` 中将 `selectedProductId` 置 0，关闭操作菜单
4. **长按开启**：`LongPressGesture({ repeat: true })` 的 `onAction` 中将 `selectedProductId` 设为当前商品 id，触发菜单覆层显示

```typescript
@Component
export struct ProductCard {
  @Link itemList: Array<Product>;
  @Link selectedProductId: number;
  @State product: Product = /* ... */;

  build() {
    Stack() {
      Column() {
        Image(this.product.imageUrl)
          .width('100%')
          .aspectRatio(1)
          .objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: 12, topRight: 12, bottomLeft: 0, bottomRight: 0 })
          .draggable(false)
          // ① parallelGesture：与组件内置手势并行，不被拦截
          .parallelGesture(
            GestureGroup(GestureMode.Exclusive,
              // ② 单击 - 关闭操作菜单
              TapGesture({ count: 1, fingers: 1 })
                .onAction(() => {
                  this.selectedProductId = 0;
                }),
              // ③ 长按 - 弹出操作菜单（repeat: true 可持续触发）
              LongPressGesture({ repeat: true })
                .onAction(() => {
                  this.selectedProductId = this.product.id;
                })
            )
          )

        // ... 商品标题、价格等 UI 省略
      }
      .width('100%')
      .height(253)
      .backgroundColor(Color.White)
      .borderRadius(12)

      // ④ 长按覆层菜单，仅选中时显示
      if (this.selectedProductId === this.product.id) {
        Stack() {
          Column()
            .width('100%')
            .height(253)
            .backgroundColor('#80000000')
            .borderRadius(12)
          // ... 操作按钮列表省略
        }
        .onClick(() => {
          this.selectedProductId = 0;
        })
      }
    }
  }
}
```

### 注意事项：单击与双击互斥时的声明顺序问题

当单击与双击同时绑定在 `GestureMode.Exclusive` 组中时，**双击手势必须声明在单击手势之前**，否则双击手势无法响应。

**原因：** Exclusive 模式按参数顺序逐一尝试匹配。如果 `TapGesture({ count: 1 })` 写在前面，系统会在第一次按下时立即匹配单击手势成功，双击手势永远得不到识别机会。将 `TapGesture({ count: 2 })` 放在前面，系统会先等待判断是否为双击，如果不是才回落到单击。

```typescript
// ✅ 正确：双击在前，单击在后
GestureGroup(GestureMode.Exclusive,
  TapGesture({ count: 2 })   // 先尝试双击
    .onAction(() => { /* 双击逻辑 */ }),
  TapGesture({ count: 1 })   // 再尝试单击
    .onAction(() => { /* 单击逻辑 */ })
)

// ❌ 错误：单击在前，双击永远无法响应
GestureGroup(GestureMode.Exclusive,
  TapGesture({ count: 1 })   // 单击立即匹配，双击被跳过
    .onAction(() => { /* 单击逻辑 */ }),
  TapGesture({ count: 2 })   // 永远走不到
    .onAction(() => { /* 双击逻辑 */ })
)
```

**副作用：** 这种声明顺序会导致单击手势响应延迟约 300ms。因为系统必须等待一段时间（约 300ms）确认用户不会进行第二次点击，才能判定为单击并触发回调。这是单击/双击互斥场景下不可避免的取舍。

**替代方案：** 如果 300ms 延迟不可接受，可考虑：
- 仅使用单击，去掉双击手势，通过其他交互（如长按、按钮）替代双击功能
- 使用 `GestureMode.Parallel` 让单击和双击并行识别，手动保证单击双击互斥执行