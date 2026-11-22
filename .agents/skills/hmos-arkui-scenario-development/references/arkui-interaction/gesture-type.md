# 手势类型场景

## SCENE-01 TapGesture 双击缩放图片

**适用场景：** 当需要通过多次快速点击同一组件触发特定功能时使用。例如图片查看器中双击放大/缩小图片，或双击收藏、双击点赞等交互场景。`TapGesture` 通过 `count` 参数指定连续点击次数，`count: 2` 即为双击响应。

### 实现步骤

1. **声明缩放状态**：`@State imageScaleInfo: ScaleModel` 保存当前缩放值与默认缩放值
2. **绑定双击手势**：在 Image 容器(如 Stack)上 `.gesture(TapGesture({ count: 2 }).onAction(...))`
3. **判断当前缩放态**：在 `onAction` 中比较 `scaleValue` 与 `defaultScaleValue` 决定本次执行放大或还原
4. **包裹动画切换状态**：用 `runWithAnimation(() => { ... })` 包裹 `scaleValue` 赋值与 `matrix` 矩阵更新,避免突变

```typescript
@Component
@Reusable
export struct ImageItemView {
  @Link isEnableSwipe: boolean;
  @State imageScaleInfo: ScaleModel = new ScaleModel(1.0, 1.0, 1.5, 0.3);
  @State matrix: matrix4.Matrix4Transit = matrix4.identity().copy();
  @State imagePixelMap: image.PixelMap | null = null;
  @State fitWH: "width" | "height" | undefined = undefined;
  @State imageDefaultSize: image.Size = { width: 0, height: 0 };
  imageUri: string = "";
  imageWHRatio: number = 0;

  build() {
    Stack() {
      Image(this.imagePixelMap)
        .width(this.fitWH === "width" ? "100%" : undefined)
        .height(this.fitWH === "height" ? "100%" : undefined)
        .aspectRatio(this.imageWHRatio)
        .objectFit(ImageFit.Cover)
        .autoResize(false)
        .transform(this.matrix)
    }
    .gesture(
      // 双击切换图片缩放状态
      TapGesture({ count: 2 })
        .onAction(() => {
          if (this.imageScaleInfo.scaleValue > this.imageScaleInfo.defaultScaleValue) {
            // 已放大 → 双击还原
            runWithAnimation(() => {
              this.isEnableSwipe = true;
              this.imageScaleInfo.reset();
              this.matrix = matrix4.identity().copy();
            });
          } else {
            // 默认大小 → 双击放大适配屏幕
            runWithAnimation(() => {
              this.isEnableSwipe = false;
              const ratio = this.calcFitScaleRatio(this.imageDefaultSize, windowSizeManager.get());
              this.imageScaleInfo.scaleValue = ratio;
              this.matrix = matrix4.identity().scale({ x: ratio, y: ratio }).copy();
              this.imageScaleInfo.stash();
            });
          }
        })
    )
  }
}
```

---

## SCENE-02 PanGesture 惯性滑动

**适用场景：** 当自定义组件需要实现离手后继续滑动并逐渐减速的惯性效果时使用。例如自定义可拖拽面板、悬浮球、画布平移等场景，系统容器组件（List、Scroll 等）自带惯性滚动，但自定义组件需要通过 `PanGesture` 手动实现。

**实现原理：** 在 `onActionEnd` 回调中获取离手时的滑动速度（`velocityY`/`velocityX`），以此速度乘以衰减系数计算惯性距离，再通过 `animateTo` 配合减速曲线（`Curve.LinearOutSlowIn`）驱动组件位移到目标位置，模拟物理惯性。

### 实现步骤

1. **声明位置与偏移状态**：`@State offsetX/offsetY` 表示当前位移,`@State positionX/positionY` 记录上次停留位置
2. **配置 PanGestureOptions**：`new PanGestureOptions({ direction: PanDirection.Up | PanDirection.Down })` 限定方向
3. **绑定 PanGesture**：组件上 `.gesture(PanGesture(this.panOption).onActionStart(...).onActionUpdate(...).onActionEnd(...))`
4. **update 阶段以历史位置为基准**：`this.offsetX = this.positionX + event.offsetX`
5. **end 阶段保存最终位置**：把当前偏移写入 `positionX/positionY` 作为下次手势基准
6. **驱动惯性动画**：`this.getUIContext().animateTo({ duration: 1000, curve: Curve.LinearOutSlowIn }, () => { this.offsetY += event.velocityY * 0.2 })`

```typescript
@Entry
@Component
struct InertialScrollExample {
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State positionX: number = 0;
  @State positionY: number = 0;
  private panOption: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Up | PanDirection.Down });

  build() {
    Column() {
      Text('PanGesture offset: \nX: ' + this.offsetX + '\n' + 'Y: ' + this.offsetY)
    }
    .height(200)
    .width(200)
    .padding(20)
    .border({ width: 3 })
    .margin(30)
    // 以组件左上角为坐标原点进行移动
    .translate({
      x: this.offsetX,
      y: this.offsetY,
      z: 0
    })
    .gesture(
      PanGesture(this.panOption)
        .onActionStart(() => {
          console.info('Pan start');
        })
        .onActionUpdate((event?: GestureEvent) => {
          if (event) {
            // ① 拖动过程中：当前位置 = 上次停留位置 + 本次拖动偏移
            this.offsetX = this.positionX + event.offsetX;
            this.offsetY = this.positionY + event.offsetY;
          }
        })
        .onActionEnd((event) => {
          // ② 记录松手时的最终位置
          this.offsetX = this.positionX + event.offsetX;
          this.offsetY = this.positionY + event.offsetY;
          this.positionX = this.positionX + event.offsetX;
          this.positionY = this.positionY + event.offsetY;
          // ③ 取离手速度，乘以衰减系数得到惯性距离
          let ySpeed = event.velocityY;
          // ④ animateTo + 减速曲线驱动惯性动画
          this.getUIContext().animateTo({
            duration: 1000,
            curve: Curve.LinearOutSlowIn,    // 先快后慢，模拟物理减速
            iterations: 1,
            playMode: PlayMode.Normal,
            onFinish: () => {
              console.info('play end');
            }
          }, () => {
            this.offsetY = this.offsetY + ySpeed * 0.2;    // 0.2 为衰减系数，控制惯性距离
            this.positionY = this.positionY + ySpeed * 0.2;
          })
        })
    )
  }
}
```

---

## SCENE-03 PinchGesture 捏合缩放图片

**适用场景：** 当需要实现图片预览器的双指捏合缩放功能时使用。例如相册查看大图、聊天图片预览、朋友圈图片浏览等场景，用户通过双指捏合/张开对图片进行缩放，图片以双指中心点为基准进行放大或缩小（即"跟手"缩放）。

**实现原理：** 缩放通过 `matrix4.identity().scale()` 矩阵变换实现，平移通过 `translate()` 属性实现。核心在于计算缩放中心的百分比位置，以及在缩放中心不在图片正中间时产生的额外偏移量。

**偏移量计算公式（"跟手"原理）：**

```
scale'    = lastScale * scale
offsetX'  = (lastOffsetX + offX) + (0.5 - centerX) * imageWidth * (1 - scale) * lastScale
offsetY'  = (lastOffsetY + offY) + (0.5 - centerY) * imageHeight * (1 - scale) * lastScale
```

- `scale`：本次手势的相对缩放比（从 1.0 开始）
- `lastScale`/`lastOffsetX`/`lastOffsetY`：上次手势结束时的状态
- `offX`/`offY`：本次手势的平移偏移
- `centerX`/`centerY`：缩放中心相对于图片的百分比位置（`1 - evaluateCenter()`）

### 实现步骤

1. **封装缩放模型**：定义 `ImageZoomModel` 集中管理 `curScale/curOffsetX/curOffsetY/centerX/centerY` 等状态
2. **计算缩放中心**：`pinchGestureStart` 中调用 `evaluateCenter(pinchCenterX, pinchCenterY)` 得到百分比位置并取反存入 `centerX/centerY`
3. **跟手偏移公式**：在 `onScale()` 中按 `offsetX' = (lastOffsetX + offX) + (0.5 - centerX) * imageWidth * (1 - effectiveScale) * lastScale` 更新偏移
4. **钳制缩放比**：超出 `minScale/maxScale` 时用 `effectiveScale = maxScale / lastScale` 替代原始 `scale` 参与偏移计算,避免到达极限后漂移
5. **边界限制**：`pictureBoundaryRestriction()` 把偏移夹紧到 `[minOffset, maxOffset]`,图片小于屏幕时强制居中
6. **保存手势终态**：`gestureEnd()` 把 `cur*` 写入 `last*` 作为下次手势基准,缩放比 ≤ 默认值时调用 `reset()`
7. **组合互斥手势**：`GestureGroup(GestureMode.Exclusive, PinchGesture, PanGesture, TapGesture)` 串入三种手势
8. **同步模型到 UI**：每次回调后调用 `syncState()` 把模型的 `matrix/curOffsetX/curOffsetY` 写回 @State 触发渲染

```typescript
import { matrix4 } from '@kit.ArkUI';

// ① 缩放模型：管理缩放状态与偏移计算
export class ImageZoomModel {
  componentWidth: number = 0;
  componentHeight: number = 0;
  imageWidth: number = 0;
  imageHeight: number = 0;
  readonly minScale: number = 1.0;
  readonly maxScale: number = 5.0;
  readonly defaultScale: number = 1.0;
  curScale: number = 1.0;
  lastScale: number = 1.0;
  curOffsetX: number = 0;
  curOffsetY: number = 0;
  lastOffsetX: number = 0;
  lastOffsetY: number = 0;
  centerX: number = 0.5;
  centerY: number = 0.5;
  maxOffsetX: number = 0;
  minOffsetX: number = 0;
  maxOffsetY: number = 0;
  minOffsetY: number = 0;
  matrix: object = matrix4.identity().copy();
  isArriveBoundary: boolean = false;

  // 核心偏移计算：缩放中心不在图片中间时产生额外偏移
  onScale(scale: number, offX: number, offY: number): void {
    this.curScale = this.lastScale * scale;
    let effectiveScale = scale;
    if (this.curScale < this.minScale) {
      effectiveScale = this.minScale / this.lastScale;
      this.curScale = this.minScale;
    } else if (this.curScale > this.maxScale) {
      effectiveScale = this.maxScale / this.lastScale;
      this.curScale = this.maxScale;
    }
    this.curOffsetX =
      (this.lastOffsetX + offX) + (0.5 - this.centerX) * this.imageWidth * (1 - effectiveScale) * this.lastScale;
    this.curOffsetY =
      (this.lastOffsetY + offY) + (0.5 - this.centerY) * this.imageHeight * (1 - effectiveScale) * this.lastScale;
    this.isArriveBoundary = false;
  }

  // 计算缩放中心相对于图片的百分比位置
  evaluateCenter(centerX: number, centerY: number): [number, number] {
    let imgW = this.imageWidth * this.lastScale;
    let imgH = this.imageHeight * this.lastScale;
    let imgX = (this.componentWidth - imgW) / 2 + this.lastOffsetX;
    let imgY = (this.componentHeight - imgH) / 2 + this.lastOffsetY;
    let cX = Math.max(0, Math.min(1, (centerX - imgX) / imgW));
    let cY = Math.max(0, Math.min(1, (centerY - imgY) / imgH));
    return [cX, cY];
  }

  pinchGestureStart(event: GestureEvent): void {
    let center = this.evaluateCenter(event.pinchCenterX, event.pinchCenterY);
    this.centerX = 1 - center[0];   // 注意取反，与偏移公式配合
    this.centerY = 1 - center[1];
  }

  pinchGestureUpdate(event: GestureEvent): void {
    this.onScale(event.scale, event.offsetX, event.offsetY);
    this.matrix = matrix4.identity().scale({ x: this.curScale, y: this.curScale }).copy();
    this.evaluateOffsetRange();
    this.pictureBoundaryRestriction();
  }

  panGestureUpdate(event: GestureEvent): void {
    this.onScale(1.0, event.offsetX, event.offsetY);
    this.evaluateOffsetRange();
    this.pictureBoundaryRestriction();
  }

  gestureEnd(): void {
    this.lastScale = this.curScale;
    this.lastOffsetX = this.curOffsetX;
    this.lastOffsetY = this.curOffsetY;
    if (this.curScale <= this.defaultScale) {
      this.reset();
    }
  }

  // 边界范围计算
  evaluateOffsetRange(): void {
    let sw = this.imageWidth * this.curScale;
    let sh = this.imageHeight * this.curScale;
    this.maxOffsetX = sw > this.componentWidth ? (sw - this.componentWidth) / 2 : 0;
    this.minOffsetX = -this.maxOffsetX;
    this.maxOffsetY = sh > this.componentHeight ? (sh - this.componentHeight) / 2 : 0;
    this.minOffsetY = -this.maxOffsetY;
  }

  // 边界限制：防止图片被拖出可视区域
  pictureBoundaryRestriction(): void {
    if (this.curOffsetX > this.maxOffsetX) { this.curOffsetX = this.maxOffsetX; this.isArriveBoundary = true; }
    else if (this.curOffsetX < this.minOffsetX) { this.curOffsetX = this.minOffsetX; this.isArriveBoundary = true; }
    if (this.curOffsetY > this.maxOffsetY) { this.curOffsetY = this.maxOffsetY; }
    else if (this.curOffsetY < this.minOffsetY) { this.curOffsetY = this.minOffsetY; }
    if (this.imageWidth * this.curScale <= this.componentWidth) { this.curOffsetX = 0; }
    if (this.imageHeight * this.curScale <= this.componentHeight) { this.curOffsetY = 0; }
  }

  reset(): void {
    this.curScale = this.defaultScale; this.lastScale = this.defaultScale;
    this.curOffsetX = 0; this.curOffsetY = 0;
    this.lastOffsetX = 0; this.lastOffsetY = 0;
    this.centerX = 0.5; this.centerY = 0.5;
    this.matrix = matrix4.identity().copy();
  }

  initImageSize(rawW: number, rawH: number): void {
    if (this.componentWidth <= 0 || this.componentHeight <= 0) return;
    let ratio = Math.min(this.componentWidth / rawW, this.componentHeight / rawH);
    this.imageWidth = rawW * ratio;
    this.imageHeight = rawH * ratio;
  }
}

// ② 页面：PinchGesture + PanGesture + TapGesture 组合
@Entry
@Component
struct ImageZoomPage {
  @State matrix: object = matrix4.identity().copy();
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State imageWidth: number = 0;
  @State imageHeight: number = 0;
  @State scaleValue: number = 1.0;
  private model: ImageZoomModel = new ImageZoomModel();

  build() {
    Column() {
      Stack() {
        Image($r('app.media.large_image'))
          .objectFit(ImageFit.Contain)
          .width('100%')
          .height('100%')
          .transform(this.matrix)                          // matrix4 矩阵缩放
          .translate({ x: this.offsetX, y: this.offsetY }) // 平移
          .onComplete((event) => {
            if (event) {
              this.imageWidth = event.width;
              this.imageHeight = event.height;
              this.model.initImageSize(event.width, event.height);
            }
          })
      }
      .width('100%')
      .layoutWeight(1)
      .alignContent(Alignment.Center)
      .onAreaChange((_old: Area, area: Area) => {
        this.model.componentWidth = Number(area.width);
        this.model.componentHeight = Number(area.height);
        if (this.imageWidth > 0 && this.imageHeight > 0) {
          this.model.initImageSize(this.imageWidth, this.imageHeight);
        }
      })
      .gesture(
        GestureGroup(GestureMode.Exclusive,
          // 双指捏合缩放
          PinchGesture({ fingers: 2, distance: 1 })
            .onActionStart((event: GestureEvent) => {
              this.model.pinchGestureStart(event);
            })
            .onActionUpdate((event: GestureEvent) => {
              this.model.pinchGestureUpdate(event);
              this.syncState();
            })
            .onActionEnd(() => {
              this.model.gestureEnd();
              this.syncState();
            }),
          // 单指平移
          PanGesture({ fingers: 1, distance: 5 })
            .onActionUpdate((event: GestureEvent) => {
              this.model.panGestureUpdate(event);
              this.syncState();
            })
            .onActionEnd(() => {
              this.model.gestureEnd();
              this.syncState();
            }),
          // 双击放大/恢复
          TapGesture({ count: 2 })
            .onAction((event: GestureEvent) => {
              if (event.fingerList && event.fingerList.length > 0) {
                this.model.doubleTap(event.fingerList[0].localX, event.fingerList[0].localY);
                this.syncState();
              }
            })
        )
      )
    }
    .width('100%')
    .height('100%')
  }

  private syncState(): void {
    this.matrix = this.model.matrix;
    this.offsetX = this.model.curOffsetX;
    this.offsetY = this.model.curOffsetY;
    this.scaleValue = this.model.curScale;
  }
}
```

---

## SCENE-04 RotationGesture 旋转图片

**适用场景：** 当需要通过双指旋转手势对组件进行角度旋转时使用。例如图片查看器中双指旋转图片、地图旋转等场景。`RotationGesture` 通过 `angle` 参数设置触发阈值，回调中通过 `event.angle` 获取实时旋转角度，配合 `matrix4` 矩阵变换实现旋转效果。

### 实现步骤

1. **声明旋转模型**：`@State imageRotateInfo: RotateModel` 保存 `currentRotate/lastRotate/startAngle`
2. **设置触发阈值**：`RotationGesture({ angle: this.imageRotateInfo.startAngle })` 设较大值(如 20°)避免手指抖动误触
3. **绑定 RotationGesture**：组件上 `.gesture(RotationGesture(...).onActionUpdate(...).onActionEnd(...))`
4. **update 阶段累加角度**：`angle = lastRotate + event.angle`,按 `event.angle` 正负减/加 `startAngle` 修正阈值,避免起始跳变
5. **应用 Z 轴旋转矩阵**：`matrix4.identity().rotate({ x: 0, y: 0, z: 1, angle }).copy()`,每次从单位矩阵重建避免累积误差
6. **end 阶段吸附 90° 倍数**：用 `simplestRotationQuarter(currentRotate)` 归整角度,在 `runWithAnimation` 内更新矩阵并调用 `stash()` 保存为下次基准

```typescript
@Component
export struct PicturePreviewImage {
  @State imageRotateInfo: RotateModel = new RotateModel();
  @State matrix: matrix4.Matrix4Transit = matrix4.identity().copy();

  build() {
    Stack() {
      Image(this.imageUrl)
        .objectFit(ImageFit.Cover)
        .transform(this.matrix)
    }
    .gesture(
      // ① RotationGesture：双指旋转图片
      RotationGesture({ angle: this.imageRotateInfo.startAngle })
        .onActionUpdate((event: GestureEvent) => {
          // 累加角度 = 上次停留角度 + 本次手势角度
          let angle = this.imageRotateInfo.lastRotate + event.angle;
          // 减去触发阈值角度，避免开始旋转时图片跳变
          if (event.angle > 0) {
            angle -= this.imageRotateInfo.startAngle;
          } else {
            angle += this.imageRotateInfo.startAngle;
          }
          // ② 通过 matrix4 绕 Z 轴旋转
          this.matrix = matrix4.identity()
            .rotate({ x: 0, y: 0, z: 1, angle: angle })
            .copy();
          this.imageRotateInfo.currentRotate = angle;
        })
        .onActionEnd(() => {
          // ③ 松手后吸附到最近的 90° 倍数
          let rotate = simplestRotationQuarter(this.imageRotateInfo.currentRotate);
          runWithAnimation(() => {
            this.imageRotateInfo.currentRotate = rotate;
            this.matrix = matrix4.identity()
              .rotate({ x: 0, y: 0, z: 1, angle: rotate })
              .copy();
            this.imageRotateInfo.stash();     // 保存当前角度作为下次基准
          });
        })
    )
  }
}
```
