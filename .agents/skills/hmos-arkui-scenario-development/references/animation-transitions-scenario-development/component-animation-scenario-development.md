# 组件动画案例集

## 适用场景

| 场景 | 推荐方案 | 选型理由 |
|---|---|---|
| 列表批量入场 | `TransitionEffect.OPACITY.combine(translate)` + `delay: index * 80` | delay 递增产生瀑布交错，`springMotion` 增加弹性 |
| 列表项拖拽交换 + 侧滑删除 | `AttributeModifier` + `GestureGroup(Sequence)` + `ListItem.swipeAction` | 需要同时控制多个项的 scale/translate/shadow/opacity，Modifier 模式最清晰；侧滑删除通过 swipeAction + 两段 animateTo 实现 |
| 网格项删除补位 + 添加回位 | `Grid.supportAnimation(true)` + `AttributeModifier` + `AttributeUpdater` + `componentUtils` | 删除用 Modifier 手动驱动淡出+滑移；添加回位用 AttributeUpdater + componentUtils 计算屏幕坐标实现跨区域飞入 |

## 核心动画 API 枚举值参考

### TransitionEffect 静态属性与方法

| 属性/方法 | 说明 | 典型场景 |
|---|---|---|
| `TransitionEffect.OPACITY` | 透明度转场（1→0→1） | 列表项入场/退场淡入淡出 |
| `TransitionEffect.IDENTITY` | 无转场效果 | 不需要转场时使用 |
| `TransitionEffect.opacity(value)` | 自定义透明度起始值 | 模态登录 0.4 透明度过渡 |
| `TransitionEffect.translate(offset)` | 平移转场 | 列表从底部弹入、侧边滑入 |
| `TransitionEffect.scale(scale)` | 缩放转场 | 注册页从 0.95 放大到 1 |
| `TransitionEffect.rotate(angle)` | 旋转转场 | 卡片翻转效果 |
| `TransitionEffect.move(edge)` | 从指定边缘滑入/滑出 | 页面 B 从右侧滑入 |
| `.combine(effect)` | 组合两个转场效果 | OPACITY + translate 联动 |
| `.animation(params)` | 为转场附加动画参数 | 设置 duration/curve/delay |

### curves 模块弹簧曲线函数（组件动画常用）

| 函数 | 参数 | 说明 | 典型场景 |
|---|---|---|---|
| `curves.springMotion()` | `(response?, dampingFraction?)` | 弹簧运动曲线 | 列表入场弹性弹入 |
| `curves.interpolatingSpring()` | `(velocity, mass, stiffness, damping)` | 插值弹簧曲线 | 松手两段弹性归位（大阻尼 + 小阻尼） |
| `curves.initCurve()` | `(curve: Curve)` | 初始化曲线 | `interpolate()` 计算邻居收缩比例 |

### componentUtils 模块（跨区域坐标计算）

| 函数 | 参数 | 说明 | 典型场景 |
|---|---|---|---|
| `componentUtils.getRectangleById(id)` | `(id: string)` | 通过组件 id 获取屏幕坐标和尺寸 | 网格项飞入动画：计算推荐列表到主网格的位移差值 |
| 返回值 `.screenOffset` | `{ x: number, y: number }` | 组件左上角的屏幕坐标（px） | 计算两个组件之间的屏幕坐标差 |
| 返回值 `.size` | `{ width: number, height: number }` | 组件的宽高尺寸 | 计算末尾项高度偏移 |

### Curve 枚举值（组件动画常用）

| 枚举值 | 说明 | 典型场景 |
|---|---|---|
| `Curve.Friction` | 阻尼摩擦曲线 | 长按浮起、拖拽交换、删除淡出、网格项滑移填补 |
| `Curve.Sharp` | 急剧变化曲线 | 邻居项收缩进度映射 |
| `Curve.ExtremeDeceleration` | 极度减速曲线 | 网格项飞入动画（先快后慢减速着陆） |

---

## 场景1：列表入场

**场景描述：** 仿社交 App 首页刷新，点击按钮后 12 条列表项从底部依次弹入，每项间隔 80ms 产生瀑布式交错入场效果。

**解决方案：** 使用 **`TransitionEffect.OPACITY.combine(translate({y:80}))`** + **`delay: index * 80` 交错** + **`curves.springMotion()` 弹性曲线**

```ts
@State items: number[] = []

playStaggerAnimation() {
  this.items = []
  setTimeout(() => {
    this.items = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
  }, 50)
}

List() {
  ForEach(this.items, (item, index) => {
    ListItem() {
      Row() { /* 列表项内容 */ }
    }
    .transition(
      TransitionEffect.OPACITY
        .combine(TransitionEffect.translate({ y: 80 }))
        .animation({ duration: 400, curve: curves.springMotion(), delay: index * 80 })
    )
  })
}
```

关键点：先清空再填充触发 `if` 条件渲染的进入转场，`delay: index * 80` 产生 80ms 递增的瀑布效果。

---

## 场景2：列表项交换

**场景描述：** 仿支付宝银行卡管理/快捷支付排序，长按列表项后卡片浮起（阴影+放大），跟随手指上下拖拽，拖拽过程中邻居项根据距离动态收缩让位，超过相邻项一半高度时自动交换位置，松手后两段弹簧动画弹性归位。同时支持侧滑露出删除按钮，点击后列表项向右滑出并淡出消失。

**解决方案：** 使用 **`AttributeModifier<ListItemAttribute>` 封装动画属性（scale/translate/opacity/shadow）** + **`GestureGroup(Sequence, LongPress + Pan)` 组合手势** + **`curves.initCurve(Curve.Sharp).interpolate()` 计算邻居收缩比例** + **`curves.interpolatingSpring` 两段弹性归位** + **`ListItem.swipeAction` 侧滑删除** + **两段 `animateTo` 删除动画（滑出淡出 → 移除数据）**

### 步骤 0：控制器类定义 + 常量 + 状态管理前提 [辅助]

> 纯数据结构定义和控制器完整类定义，为后续步骤提供类型基础。**此步骤不可省略**——缺少 `@Observed` 装饰器或使用 `private` 访问修饰符会导致 `animateTo` 修改控制器属性时 UI 不重渲染，拖拽交换动画完全失效。

```ts
const ITEM_HEIGHT: number = 50;
const ANIMATE_DURATION: number = 300;

enum OperationStatus {
  IDLE,
  PRESSING,
  MOVING,
  DROPPING,
  DELETE
}

@Observed
export class ListExchangeCtrl<T> {
  private deductionData: Array<T> = [];
  private modifier: Array<ListItemModifier> = [];
  state: OperationStatus = OperationStatus.IDLE;   // ⚠️ 必须 public：@Observed 仅观察 public 属性变更
  private dragRefOffset: number = 0;
  offsetY: number = 0;                              // ⚠️ 必须 public：同上

  initData(deductionData: Array<T>) {
    this.deductionData = deductionData;
    deductionData.forEach(() => {
      this.modifier.push(new ListItemModifier());
    })
  }

  getModifier(item: T): ListItemModifier {
    const index: number = this.deductionData.indexOf(item);
    return this.modifier[index];
  }

  // onLongPress / onMove / handleDrop / changeItem 见步骤3~5
}

// ⚠️ 初始化必须在 aboutToAppear 中调用 initData，不能在构造器中传参：
// 正确：
//   @State listExchangeCtrl: ListExchangeCtrl<ListInfo> = new ListExchangeCtrl();
//   aboutToAppear(): void { this.listExchangeCtrl.initData(this.appInfoList); }
// 错误：
//   @State listExchangeCtrl = new ListExchangeCtrl(this.appInfoList);
// 原因：构造器执行时 @State 尚未完成组件树绑定，@Observed 观察链未建立，
//       后续 animateTo 修改 ctrl 属性无法触发 UI 重渲染。
```

关键点：
- **`@Observed` 装饰器不可省略**：`@State`/`@Link` 仅对 `@Observed` 类实例做深度属性观察。缺少此装饰器时，`animateTo` 修改 ctrl 内部的 `offsetY`、`modifier[].scale` 等属性不会触发 UI 重渲染，导致拖拽交换动画完全失效——卡片浮起后无法跟随手指移动、邻居不收缩、交换不发生
- **`state` 和 `offsetY` 必须 public**：`@Observed` 仅观察 public 属性变更，private 属性变更不会触发重渲染
- **初始化使用 `initData()` 方法**：在 `aboutToAppear` 中调用，而非构造器传参。`aboutToAppear` 时组件树已挂载，`@State`/`@Link` 观察链已建立，确保后续 `animateTo` 修改 ctrl 属性能正确触发 UI 重渲染
- **`@Link` 绑定模式**：父组件通过 `@State` 持有 ctrl 实例，子 `ListExchange` 组件通过 `@Link` 接收。`@Link` 将 ctrl 绑定到父组件的 `@State`，与 `@Observed` 配合形成跨组件的深度观察链，保障 ctrl 属性变更触发 UI 重渲染
- `ITEM_HEIGHT` 必须与列表项实际高度一致，影响交换阈值计算和邻居收缩比例映射

### 步骤 1：ListItemModifier — 将动画属性封装为响应式对象

每个列表项对应一个 `ListItemModifier` 实例，通过 `applyNormalAttribute` 将属性映射到组件样式。控制器在 `animateTo` 中修改属性值即触发动画。Modifier 需覆盖拖拽交换和侧滑删除两种场景的全部动画属性。

```ts
export class ListItemModifier implements AttributeModifier<ListItemAttribute> {
  public hasShadow: boolean = false;
  public scale: number = 1;
  public offsetY: number = 0;
  public offsetX: number = 0;
  public opacity: number = 1;
  public isDeleted: boolean = false;

  applyNormalAttribute(instance: ListItemAttribute): void {
    if (this.hasShadow) {
      instance.shadow({
        radius: $r('app.integer.list_exchange_shadow_radius'),
        color: $r('app.color.list_exchange_box_shadow')
      });
      instance.zIndex(1);
      instance.opacity(0.5);
    } else {
      instance.opacity(this.opacity);
    }
    instance.translate({ x: this.offsetX, y: this.offsetY });
    instance.scale({ x: this.scale, y: this.scale });
  }
}
```

关键点：
- `hasShadow` 为 `true` 时同时设置 shadow + zIndex + opacity（半透明悬浮态）；`opacity` 在非阴影态下独立驱动删除淡出
- `offsetY` 驱动拖拽纵向位移；`offsetX` 驱动侧滑删除横向位移
- `scale` 驱动长按放大和邻居收缩；`isDeleted` 标记删除状态供控制器判断
- shadow 的 radius/color 使用 `$r()` 资源引用，便于主题适配与多语言维护

### 步骤 2：列表绑定 Modifier + GestureGroup 组合手势 + 侧滑删除

`ListExchangeCtrl` 为每个数据项维护一个 `ListItemModifier`（数据数组与 Modifier 数组 1:1 映射），并用 `OperationStatus` 枚举跟踪交互状态（IDLE/PRESSING/MOVING/DROPPING/DELETE）。`ListItem` 通过 `.attributeModifier()` 绑定对应 Modifier，通过 `GestureGroup(Sequence)` 实现"先长按再拖拽"的串行手势，同时通过 `.swipeAction()` 支持侧滑露出删除按钮。

```ts
@Component
export struct ListExchange {
  @Link appInfoList: Object[];
  @Link listExchangeCtrl: ListExchangeCtrl<Object>;
  @BuilderParam deductionView: (listInfo: Object) => void;
  @State currentListItem: Object | undefined = undefined;
  @State isLongPress: boolean = false;

  build() {
    Column() {
      List() {
        ForEach(this.appInfoList, (item: Object, index: number) => {
          ListItem() {
            this.deductionView(item)
          }
          .id('list_exchange_' + index)
          .zIndex(this.currentListItem === item ? 2 : 1)
          .swipeAction({ end: this.defaultDeleteBuilder(item) })
          .transition(TransitionEffect.OPACITY)
          .attributeModifier(this.listExchangeCtrl.getModifier(item))
          .gesture(
            GestureGroup(GestureMode.Sequence,
              LongPressGesture()
                .onAction((event: GestureEvent) => {
                  this.currentListItem = item;
                  this.isLongPress = true;
                  this.listExchangeCtrl.onLongPress(item);
                }),
              PanGesture()
                .onActionUpdate((event: GestureEvent) => {
                  this.listExchangeCtrl.onMove(item, event.offsetY);
                })
                .onActionEnd((event: GestureEvent) => {
                  this.listExchangeCtrl.handleDrop(item);
                  this.isLongPress = false;
                })
            ).onCancel(() => {
              if (!this.isLongPress) {
                return;
              }
              this.listExchangeCtrl.handleDrop(item);
            }))
        }, (item: Object) => JSON.stringify(item))
      }
      .divider({ strokeWidth: '1px', color: 0xeaf0ef })
      .scrollBar(BarState.Off)
      .width('100%')
    }
  }

  @Builder
  defaultDeleteBuilder(item: Object) {
    Image($r("app.media.list_exchange_icon_delete"))
      .width($r('app.integer.list_exchange_icon_size'))
      .height($r('app.integer.list_exchange_icon_size'))
      .onClick(() => {
        this.listExchangeCtrl.deleteItem(item);
      })
  }
}
```

关键点：
- `GestureGroup(Sequence, LongPress, Pan)` 串行组合：必须先触发长按，成功后才进入拖拽阶段，避免误触
- `.onCancel()` 处理手势中断：长按未触发时（`isLongPress === false`）直接返回；已进入拖拽时调用 `handleDrop` 归位，防止拖拽项停留在中间状态
- `isLongPress` 标志位区分"未触发长按"与"已进入拖拽"两种取消场景
- `zIndex` 动态切换：被拖拽项 `zIndex(2)` 浮于其他项之上
- `transition(TransitionEffect.OPACITY)` 为数组增删时提供淡入淡出效果
- `.swipeAction({ end })` 侧滑露出删除按钮，点击后调用 `deleteItem` 执行删除动画
- `.id('list_exchange_' + index)` 为每个列表项设置唯一标识，便于 UI 测试与无障碍访问
- ForEach 的 keyGenerator 使用 `JSON.stringify(item)` 确保交换后正确跟踪

### 步骤 3：长按浮起 — animateTo 驱动 shadow + scale

长按触发后，通过 `animateTo` 修改 Modifier 的 `hasShadow` 和 `scale` 属性，卡片浮起产生悬浮感。

```ts
onLongPress(item: T): void {
  const index: number = this.deductionData.indexOf(item);
  this.dragRefOffset = 0;
  animateTo({ curve: Curve.Friction, duration: commonConstants.ANIMATE_DURATION }, () => {
    this.state = OperationStatus.PRESSING;
    this.modifier[index].hasShadow = true;
    this.modifier[index].scale = 1.04;
  })
}
```

关键点：
- 使用 `commonConstants.ANIMATE_DURATION`（300ms）替代硬编码时长，便于全局统一调整
- `OperationStatus.PRESSING` 状态标记供后续逻辑判断当前交互阶段

### 步骤 4：拖拽偏移 + 邻居收缩 + 超半交换

拖拽过程中三个关键逻辑：直接位移、邻居收缩、超半交换。`onMove` 使用 try/catch 包裹防止拖拽过程中异常导致动画卡死。

```ts
onMove(item: T, offsetY: number): void {
  try {
    const index: number = this.deductionData.indexOf(item);
    // 1. 直接更新位移（无动画，跟随手指）
    this.offsetY = offsetY - this.dragRefOffset;
    this.modifier[index].offsetY = this.offsetY;

    // 2. 邻居收缩：根据拖拽距离计算收缩比例
    const direction: number = this.offsetY > 0 ? 1 : -1;
    const curveValue: ICurve = curves.initCurve(Curve.Sharp);
    const value: number = curveValue.interpolate(Math.abs(this.offsetY) / ITEM_HEIGHT);
    const shrinkScale: number = 1 - value / 10;
    if (index < this.modifier.length - 1) {
      this.modifier[index + 1].scale = direction > 0 ? shrinkScale : 1;
    }
    if (index > 0) {
      this.modifier[index - 1].scale = direction > 0 ? 1 : shrinkScale;
    }

    // 3. 超过半项高度 → animateTo 交换位置
    if (Math.abs(this.offsetY) > ITEM_HEIGHT / 2) {
      if (index === 0 && direction === -1) { return; }
      if (index === this.deductionData.length - 1 && direction === 1) { return; }
      animateTo({ curve: Curve.Friction, duration: commonConstants.ANIMATE_DURATION }, () => {
        this.offsetY -= direction * ITEM_HEIGHT;
        this.dragRefOffset += direction * ITEM_HEIGHT;
        this.modifier[index].offsetY = this.offsetY;
        const target = index + direction;
        if (target !== -1 && target <= this.modifier.length) {
          this.changeItem(index, target);
        }
      })
    }
  } catch (err) {
    logger.error(`onMove err:${JSON.stringify(err)}`);
  }
}

// 数据数组和 Modifier 数组同步交换
changeItem(index: number, newIndex: number): void {
  const tmpData = this.deductionData.splice(index, 1);
  this.deductionData.splice(newIndex, 0, tmpData[0]);
  const tmpModifier = this.modifier.splice(index, 1);
  this.modifier.splice(newIndex, 0, tmpModifier[0]);
}
```

关键点：
- `dragRefOffset` 累计已交换的偏移量，确保连续多次交换时位移计算正确（每次交换后 `offsetY` 修正 `ITEM_HEIGHT`）
- 邻居收缩使用 `curves.initCurve(Curve.Sharp).interpolate()` 将拖拽进度（0~1）映射为非线性收缩比例，`Curve.Sharp` 使收缩前期变化较快
- 交换时通过 `splice` 同步操作数据数组和 Modifier 数组，保持 1:1 映射关系
- try/catch 包裹整个 `onMove`，防止拖拽过程中边界异常导致动画卡死；`logger.error` 记录异常便于调试
- 交换目标 `target = index + direction` 增加 `target !== -1 && target <= this.modifier.length` 双重边界校验

### 步骤 5：松手弹性归位 — 两段弹簧动画

松手后依次执行两段 `interpolatingSpring` 弹簧动画：先复位邻居，再复位拖拽项自身。使用 try/catch 包裹防止归位异常，`logger` 记录关键节点便于调试。

```ts
handleDrop(item: T): void {
  logger.info(`handleDrop start`);
  try {
    const index: number = this.deductionData.indexOf(item);
    this.dragRefOffset = 0;
    this.offsetY = 0;

    // 第一段：复位邻居 scale（较大的阻尼弹簧）
    animateTo({ curve: curves.interpolatingSpring(0, 1, 400, 38) }, () => {
      this.state = OperationStatus.DROPPING;
      if (index < this.modifier.length - 1) {
        this.modifier[index + 1].scale = 1;
      }
      if (index > 0) {
        this.modifier[index - 1].scale = 1;
      }
    })

    // 第二段：复位拖拽项 shadow/scale/offsetY（较小的阻尼弹簧）
    animateTo({ curve: curves.interpolatingSpring(14, 1, 170, 17) }, () => {
      this.state = OperationStatus.IDLE;
      this.modifier[index].hasShadow = false;
      this.modifier[index].scale = 1;
      this.modifier[index].offsetY = 0;
    })
    logger.info(`handleDrop end`);
  } catch (err) {
    logger.error(`handleDrop err:${JSON.stringify(err)}`);
  }
}
```

关键点：
- 两段弹簧使用不同参数：`interpolatingSpring(0, 1, 400, 38)` 阻尼大、回弹少，适合邻居的平滑复位；`interpolatingSpring(14, 1, 170, 17)` 阻尼小、回弹明显，适合拖拽项自身的弹性归位
- 两段 `animateTo` 同时触发但作用于不同 Modifier 属性，视觉上形成"邻居先让位、拖拽项再落下"的层次感
- `OperationStatus` 状态流转：PRESSING → DROPPING → IDLE，每段动画分别设置不同状态，配合 `state` 字段可扩展防重入逻辑
- `logger.info` 记录 `handleDrop start/end` 关键节点，便于追踪动画生命周期与排查时序问题

### 步骤 6：侧滑删除 — 两段 animateTo 滑出淡出 + 移除数据

通过 `ListItem.swipeAction({ end })` 侧滑露出删除按钮，点击后调用 `deleteItem`。删除动画分两段：第一段驱动 offsetX + opacity（向右滑出并淡出），第二段在 `onFinish` 中从数据/Modifier 数组中移除该项，配合 `TransitionEffect.OPACITY` 实现列表项淡出退场。

```ts
deleteItem(item: T): void {
  try {
    const index: number = this.deductionData.indexOf(item);
    this.dragRefOffset = 0;
    // 第一段：滑出淡出动画
    animateTo({
      curve: Curve.Friction, duration: commonConstants.ANIMATE_DURATION, onFinish: () => {
        // 第二段：移除数据 + Modifier 数组
        animateTo({
          curve: Curve.Friction, duration: 500, onFinish: () => {
            this.state = OperationStatus.IDLE;
          }
        }, () => {
          this.modifier.splice(index, 1);
          this.deductionData.splice(index, 1);
        })
      }
    }, () => {
      this.state = OperationStatus.DELETE;
      this.modifier[index].offsetX = 150;    // 向右滑出
      this.modifier[index].opacity = 0;      // 淡出
    })
  } catch (err) {
    logger.error(`delete err:${JSON.stringify(err)}`);
  }
}
```

关键点：
- 第一段 `animateTo` 使用 `Curve.Friction` 300ms：Modifier 的 `offsetX = 150` 驱动横向滑出，`opacity = 0` 驱动淡出，两者同时触发形成"滑出并消失"的视觉效果
- 第二段 `animateTo` 在第一段 `onFinish` 中执行：先从 Modifier 数组和数据数组中 `splice` 移除该项，此时 `TransitionEffect.OPACITY` 自动为列表退场提供淡出过渡
- `onFinish` 链式调用确保时序正确：先完成滑出淡出 → 再移除数据触发退场 → 最后将 `OperationStatus` 恢复为 IDLE
- `this.dragRefOffset = 0` 重置拖拽基准偏移，防止删除后再次拖拽时位移基准残留

---

## 场景3：网格元素交换

**场景描述：** 仿桌面快捷方式管理，进入编辑模式后图标右上角出现红色删除按钮，点击删除后相邻图标滑移填补空位（同行左移、行尾跳到下一行首位），同时支持长按拖拽重新排序。下方推荐列表中的图标点击后飞入主网格末尾空位，飞入动画基于 `componentUtils` 计算屏幕坐标实现跨区域位移。

**解决方案：** 使用 **`Grid.editMode` + `supportAnimation(true)`** + **`AttributeModifier<GridItemAttribute>` 驱动删除位移** + **`AttributeUpdater<ColumnAttribute>` 驱动添加飞入位移** + **`componentUtils.getRectangleById` 计算跨区域屏幕坐标** + **`AppStorage.setOrCreate` 同步删除/添加状态防重入**

### 步骤 1：数据模型 + 两套 Modifier + 常量定义

数据项使用 `@Observed` 装饰，包含 `visible` 属性控制可见性。删除场景使用 `GridItemModifier implements AttributeModifier`，添加回场景使用 `TranslateItemModifier extends AttributeUpdater`（可访问 `attribute` 属性直接设置样式）。常量集中定义便于全局调整。

```ts
const DELETE_ANIMATION_DURATION: number = 200;
const ADD_ANIMATION_DURATION: number = 1000;
const GRID_ITEM_SIZE: number = 72;
const COLUMN_COUNT: number = 5;

@Observed
export class AppInfo {
  icon: ResourceStr = '';
  name: ResourceStr = '';
  visible: boolean = true;
  constructor(icon: ResourceStr = '', name: ResourceStr = '', visible: boolean = true) {
    this.icon = icon; this.name = name; this.visible = visible;
  }
}

@Observed
export class GridItemModifier implements AttributeModifier<GridItemAttribute> {
  public offsetX: number = 0;
  public offsetY: number = 0;
  public opacity: number = 1;

  applyNormalAttribute(instance: GridItemAttribute): void {
    instance.translate({ x: this.offsetX, y: this.offsetY });
    instance.opacity(this.opacity);
  }
}

@Observed
export class TranslateItemModifier extends AttributeUpdater<ColumnAttribute> {
  initializeModifier(instance: ColumnAttribute): void {
    instance.translate({ x: 0, y: 0 })
      .visibility(Visibility.Visible);
  }
}
```

关键点：
- 删除用 `AttributeModifier`：通过 `applyNormalAttribute` 响应式映射属性，`animateTo` 修改属性值自动触发动画
- 添加用 `AttributeUpdater`：通过 `attribute` 属性可直接在 `animateTo` 回调中调用 `.translate()` / `.visibility()` 一次性设置样式，无需等待 `applyNormalAttribute` 重新调用，适合需要精确屏幕坐标计算的飞入动画
- `AppInfo.visible` 可用于控制推荐列表中已添加项的显示/隐藏
- 常量集中定义：`DELETE_ANIMATION_DURATION`、`ADD_ANIMATION_DURATION`、`GRID_ITEM_SIZE`、`COLUMN_COUNT` 避免硬编码散落各处

### 步骤 2：删除动画 — 被删项淡出 + 邻居滑移填补 + 状态同步

`GridItemDeletionCtrl` 为每个网格项持有一个 `GridItemModifier`，用 `DeletionStatus` 枚举（IDLE/START/FINISH）跟踪删除状态。删除时通过 `animateTo` 同时驱动被删项淡出和后续项位移，动画结束后重置 Modifier 偏移 → 从数据/Modifier 数组移除 → 通过 `AppStorage.setOrCreate` 通知其他组件状态完成。

```ts
export enum DeletionStatus { IDLE, START, FINISH }

export class GridItemDeletionCtrl<T> {
  private modifier: GridItemModifier[] = [];
  private gridData: T[] = [];
  private status: DeletionStatus = DeletionStatus.IDLE;

  constructor(data: T[]) {
    this.gridData = data;
    data.forEach(() => { this.modifier.push(new GridItemModifier()); })
  }

  getModifier(item: T): GridItemModifier {
    const index: number = this.gridData.indexOf(item);
    if (index === -1) {
      return new GridItemModifier();
    }
    return this.modifier[index];
  }

  deleteGridItem(item: T, itemAreaWidth: number): void {
    const index: number = this.gridData.indexOf(item);
    animateTo({
      curve: Curve.Friction, duration: DELETE_ANIMATION_DURATION, onFinish: () => {
        this.modifier.forEach((item) => {
          item.offsetX = 0;
          item.offsetY = 0;
        })
        this.gridData.splice(index, 1);
        this.modifier.splice(index, 1);
        this.status = DeletionStatus.FINISH;
        AppStorage.setOrCreate('deletionStatus', this.status);
      }
    }, () => {
      this.modifier[index].opacity = 0;
      this.modifier.forEach((item: GridItemModifier, ind: number) => {
        if (index === this.gridData.length - 1) {
          this.status = DeletionStatus.START;
          return;
        }
        if (ind > index && ind % COLUMN_COUNT !== 0) {
          item.offsetX = -itemAreaWidth;
        } else if (ind > index && ind % COLUMN_COUNT === 0) {
          item.offsetX = itemAreaWidth * 4;
          item.offsetY = -GRID_ITEM_SIZE;
        }
      })
      this.status = DeletionStatus.START;
    })
  }
}
```

关键点：
- `Curve.Friction` 200ms 产生自然减速的滑移感
- 被删项后面所有项（`ind > index`）参与位移：非行首项向左平移一个 `itemAreaWidth`；行首项（`ind % COLUMN_COUNT === 0`）向右移动 4 格 + 向上移动一格，实现换行回填
- `index === this.gridData.length - 1` 时为末尾项，无需邻居位移，仅淡出后直接移除
- `onFinish` 中先重置所有 modifier 偏移（`offsetX/offsetY = 0`），再从两个数组中 splice 移除该项，保证无残余状态
- `AppStorage.setOrCreate('deletionStatus', DeletionStatus.FINISH)` 将状态同步到全局，主组件通过 `@StorageLink` 监听变化实现防重入锁
- `getModifier` 中 `index === -1` 时返回新实例，防止数组交换后找不到对应 Modifier 导致崩溃

### 步骤 3：添加回动画 — 跨区域飞入 + componentUtils 计算屏幕坐标

推荐列表中的图标点击后飞入主网格末尾空位。飞入动画需要计算"从推荐列表图标到主网格末尾空位"的屏幕坐标差值，使用 `componentUtils.getRectangleById` 获取组件的 `screenOffset` 和 `size`，通过 `px2vp` 转换为 VP 坐标，驱动 `TranslateItemModifier.attribute.translate()` 实现跨区域位移。

```ts
export enum AddStatus { IDLE, START, FINISH }

export class GridItemAddCtrl<T> {
  private modifier: TranslateItemModifier[] = [];
  private sortAppData: T[] = [];
  private status: AddStatus = AddStatus.IDLE;

  constructor(data: T[]) {
    this.sortAppData = data;
    data.forEach(() => { this.modifier.push(new TranslateItemModifier()); })
  }

  getModifier(item: T): TranslateItemModifier {
    const index: number = this.sortAppData.indexOf(item);
    if (index === -1) {
      return new TranslateItemModifier();
    }
    return this.modifier[index];
  }

  addGridItem(item: T, appInfoList: AppInfo[]): void {
    const index: number = this.sortAppData.indexOf(item);
    const appId: string = (item as AppInfo).name.toString();
    animateTo({
      curve: Curve.ExtremeDeceleration, duration: ADD_ANIMATION_DURATION, onFinish: () => {
        this.modifier[index].attribute?.visibility(Visibility.Hidden);
        this.modifier.forEach((item) => {
          item.attribute?.visibility(Visibility.Hidden).translate({ x: 0, y: 0 });
        })
        this.status = AddStatus.FINISH;
        AppStorage.setOrCreate('addStatus', this.status);
      }
    }, () => {
      let offsetX: number = 0;
      let offsetY: number = 0;
      this.modifier[index].attribute?.visibility(Visibility.Visible);
      const gridItemNumber: number = appInfoList.length;
      const homeAppIndex: number = gridItemNumber % COLUMN_COUNT;
      const componentInfo: componentUtils.ComponentInfo =
        componentUtils.getRectangleById(appId);
      offsetX = (homeAppIndex - index) * GRID_ITEM_SIZE;
      if (appInfoList.length === 0) {
        offsetY = FIRST_APP_SCREEN_OFFSET_Y - componentInfo.screenOffset.y;
        this.modifier[index].attribute?.translate({ x: offsetX, y: px2vp(offsetY) });
        this.status = AddStatus.START;
        return;
      }
      const lastAppComponentInfo: componentUtils.ComponentInfo =
        componentUtils.getRectangleById(`${appInfoList[appInfoList.length - 1].name.toString()}InHome`);
      if (homeAppIndex === 0) {
        offsetY = lastAppComponentInfo.screenOffset.y - componentInfo.screenOffset.y
          + lastAppComponentInfo.size.height;
      } else {
        offsetY = lastAppComponentInfo.screenOffset.y - componentInfo.screenOffset.y;
      }
      this.modifier[index].attribute?.translate({ x: offsetX, y: px2vp(offsetY) });
      this.status = AddStatus.START;
    })
  }
}
```

关键点：
- `AttributeUpdater.attribute` 可在 `animateTo` 回调中直接调用 `.translate()` / `.visibility()`，一次性完成样式设置，无需等待 `applyNormalAttribute` 重新调度——这是 `AttributeUpdater` 相比 `AttributeModifier` 的关键优势
- `componentUtils.getRectangleById(appId)` 获取推荐列表图标的 `screenOffset.y`（屏幕 Y 坐标，单位 px）；主网格末尾项的坐标通过 `getRectangleById('xxxInHome')` 获取，两者的差值即为飞入位移量
- `px2vp(offsetY)` 将 px 屏幕坐标差值转换为 VP 单位，因为 `translate` 属性接受 VP 值
- `homeAppIndex = appInfoList.length % COLUMN_COUNT` 计算主网格末尾空位所在列索引；`offsetX = (homeAppIndex - index) * GRID_ITEM_SIZE` 计算横向位移
- 首次添加时（`appInfoList.length === 0`）使用固定偏移 `FIRST_APP_SCREEN_OFFSET_Y` 定位到主网格第一行第一列
- `Curve.ExtremeDeceleration` 1000ms 产生先快后慢的飞入减速效果，与删除的 `Curve.Friction` 200ms 急停形成对比
- `onFinish` 中将所有 modifier 置 `Visibility.Hidden` 并重置 `translate`，动画结束后推荐列表项隐藏，主网格新增项通过数据数组 `push` 正常渲染

### 步骤 4：主网格 + 推荐列表 — 双区域绑定 Modifier

主网格使用 `Grid.editMode()` + `supportAnimation(true)` 实现拖拽排序；推荐列表使用 `Flex` + `TranslateItemModifier` 实现飞入动画。两区域通过 `@Provide`/`@Consume` 共享 `isEdit` 和 `appInfoList`，通过 `@StorageLink` 监听 `deletionStatus`/`addStatus` 实现防重入。

```ts
@Component
export struct GridExchangeComponent {
  @Provide isEdit: boolean = false;
  @Provide @Watch('monitoringData') appInfoList: AppInfo[] = APP_LIST_DATA;
  @Provide appNameList: Array<string> = [];
  @Provide GridItemDeletion: GridItemDeletionCtrl<AppInfo> =
    new GridItemDeletionCtrl<AppInfo>(this.appInfoList);
  @Provide FirstGridItemAdd: GridItemAddCtrl<AppInfo> =
    new GridItemAddCtrl<AppInfo>(this.firstAppInfoList);
  @StorageLink('addStatus') addStatus: AddStatus = AddStatus.FINISH;
  @StorageLink('deletionStatus') deletionStatus: DeletionStatus = DeletionStatus.FINISH;
  private itemAreaWidth: number = 0;

  @Builder pixelMapBuilder() {
    IconWithNameView({ app: this.movedItem })
  }

  build() {
    Column() {
      // 主网格：删除 + 拖拽排序
      Column() {
        Grid() {
          ForEach(this.appInfoList, (item: AppInfo, index: number) => {
            GridItem() {
              IconWithNameView({ app: item })
            }
            .id(`${item.name.toString()}InHome`)
            .onAreaChange((oldValue: Area, newValue: Area) => {
              this.itemAreaWidth = Number(newValue.width);
            })
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.movedItem = this.appInfoList[index];
              }
            })
            .attributeModifier(this.GridItemDeletion.getModifier(item))
            .onClick(() => {
              if (!this.isEdit) { return; }
              if (this.deletionStatus === DeletionStatus.FINISH) {
                this.deletionStatus = DeletionStatus.IDLE;
                this.GridItemDeletion.deleteGridItem(item, this.itemAreaWidth);
                this.appNameList.splice(
                  this.appNameList.indexOf(JSON.stringify(item.name)), 1
                );
              }
            })
          }, (item: AppInfo) => JSON.stringify(item))
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
        .supportAnimation(true)
        .editMode(this.isEdit)
        .onItemDragStart((event: ItemDragInfo, itemIndex: number) => {
          return this.pixelMapBuilder();
        })
        .onItemDrop((event: ItemDragInfo, itemIndex: number,
          insertIndex: number, isSuccess: boolean) => {
          if (isSuccess && insertIndex < this.appInfoList.length) {
            this.changeIndex(itemIndex, insertIndex);
          }
        })
      }
      .id('gridContainer')

      // 推荐列表：添加回飞入
      this.sortIconWithNameView({
        title: 'app.string.grid_exchange_first_title_message',
        appInfoList: this.firstAppInfoList,
        translateItemModifier: this.FirstGridItemAdd
      });
    }
  }

  @Builder sortIconWithNameView(data: SortIconWithNameView) {
    Column() {
      Text($r(data.title))
      Flex() {
        ForEach(data.appInfoList, (item: AppInfo) => {
          Stack() {
            // 隐藏的飞入动画层（TranslateItemModifier）
            this.translateIconWithNameView({
              app: item, homeAppNames: this.appNameList,
              translateItemModifier: data.translateItemModifier
            });
            // 显示的静态层（点击触发飞入）
            this.addedIconWithNameView({
              app: item, homeAppNames: this.appNameList
            });
          }
          .onClick(() => {
            if (!this.isEdit) { return; }
            if (this.appNameList.includes(JSON.stringify(item.name))) {
              promptAction.showToast({ message: $r('app.string.grid_exchange_repeat_app_message') });
              return;
            }
            if (this.addStatus === AddStatus.FINISH) {
              this.addStatus = AddStatus.IDLE;
              this.appNameList.push(JSON.stringify(item.name));
              data.translateItemModifier.addGridItem(item, this.appInfoList);
              setTimeout(() => { this.appInfoList.push(item); }, ADD_ANIMATION_DURATION);
            }
          })
        }, (item: AppInfo) => JSON.stringify(item))
      }
    }
  }

  @Builder translateIconWithNameView(data: TranslateItemWithNameViewMode) {
    Column() {
      this.appItemWithNameView({ app: data.app, homeAppNames: data.homeAppNames });
    }
    .attributeModifier(data.translateItemModifier.getModifier(data.app))
    .width($r('app.string.grid_exchange_grid_item_width'))
    .height($r('app.string.grid_exchange_grid_item_height'))
    .justifyContent(FlexAlign.Center)
  }

  changeIndex(itemIndex: number, insertIndex: number): void {
    this.appInfoList.splice(insertIndex, 0, this.appInfoList.splice(itemIndex, 1)[0]);
  }

  monitoringData(): void {
    this.GridItemDeletion = new GridItemDeletionCtrl<AppInfo>(this.appInfoList);
  }
}

@Component
struct IconWithNameView {
  private app: AppInfo = new AppInfo();
  @Consume isEdit: boolean;

  build() {
    Column() {
      Stack({ alignContent: Alignment.TopEnd }) {
        Image(this.app.icon)
          .width($r('app.string.grid_exchange_icon_size'))
          .height($r('app.string.grid_exchange_icon_size'))
          .draggable(false)
        if (this.isEdit) {
          Image($r('app.media.ic_public_remove_filled'))
            .width($r('app.string.grid_exchange_remove_icon_size'))
            .height($r('app.string.grid_exchange_remove_icon_size'))
            .markAnchor({ x: '-40%', y: '40%' })
            .draggable(false)
        }
      }
      Text(this.app.name)
        .width($r('app.string.grid_exchange_app_name_width'))
        .fontSize($r('app.string.grid_exchange_app_name_font_size'))
        .maxLines(1)
        .textAlign(TextAlign.Center)
    }
    .width($r('app.string.grid_exchange_grid_item_width'))
    .height($r('app.string.grid_exchange_grid_item_height'))
  }
}
```

关键点：
- **主网格（Grid）**：
  - `editMode(this.isEdit)` 开启后支持长按拖拽；`supportAnimation(true)` 使拖拽排序时非拖拽项自动产生位移动画
  - `.id(`${item.name}InHome`)` 为每个网格项设置唯一 id，供 `componentUtils.getRectangleById` 获取屏幕坐标
  - `onAreaChange` 获取 `itemAreaWidth` 用于删除时计算邻居位移距离
  - `onTouch` 记录 `movedItem` 供 `pixelMapBuilder` 构建拖拽浮层图标
  - `deletionStatus === FINISH` 作为防重入锁：只有上次删除动画完成后才允许新的删除
  - `onItemDragStart` 返回 `@Builder` 作为拖拽浮层；`onItemDrop` 中 splice 交换数组位置完成排序
  - 删除按钮通过 `@Consume isEdit` 条件渲染，编辑模式切换时自动出现/隐藏

- **推荐列表（Flex + Stack 双层）**：
  - `Stack` 内叠放两个子组件：底层 `translateIconWithNameView`（飞入动画层，绑定 `TranslateItemModifier`）+ 上层 `addedIconWithNameView`（静态显示层）
  - 点击时先检查 `appNameList` 防重复添加，再检查 `addStatus === FINISH` 防重入
  - `addGridItem` 触发飞入动画，`setTimeout(ADD_ANIMATION_DURATION)` 后将 item push 到 `appInfoList`——动画先飞入视觉占位，数据延迟入组保证主网格渲染时序正确
  - `@Watch('monitoringData')` 监听 `appInfoList` 变化，数据变更时重建 `GridItemDeletionCtrl` 保持数据/Modifier 映射同步

### 步骤 5：编辑模式状态管理 — @Provide/@Consume + @StorageLink + 防重入

编辑模式涉及多个组件间的状态同步：`isEdit` 控制删除按钮/添加按钮显示，`deletionStatus`/`addStatus` 控制删除/添加动画防重入，`appInfoList` 变化触发 Modifier 重建。

```ts
// 状态层级划分：
@Provide isEdit: boolean = false;              // 跨组件共享：控制编辑模式 UI
@Provide @Watch('monitoringData') appInfoList; // 跨组件共享 + 数据变更重建 Modifier
@StorageLink('deletionStatus') deletionStatus; // 全局共享：删除防重入锁
@StorageLink('addStatus') addStatus;           // 全局共享：添加防重入锁

// 编辑模式切换：
.onClick(() => {
  this.isEdit = !this.isEdit;
  this.originAppInfoList = [...this.appInfoList];   // 保存原始数据用于取消还原
  this.originalAppNameList = [...this.appNameList];
})

// 取消编辑：弹窗确认 → 还原数据 → 重建 Modifier
promptAction.showDialog({ /* ... */ })
  .then(data => {
    if (data.index === 0) {  // 取消
      this.appInfoList = [...this.originAppInfoList];
      this.appNameList = [...this.originalAppNameList];
      this.GridItemDeletion = new GridItemDeletionCtrl(this.appInfoList);
      this.isEdit = false;
      this.isChange = false;
    } else {  // 保存
      this.isEdit = false;
      this.isChange = false;
    }
  })

// monitoringData：数据变更 → 重建 Modifier 映射
monitoringData(): void {
  this.isChange = true;
  this.GridItemDeletion = new GridItemDeletionCtrl<AppInfo>(this.appInfoList);
}
```

关键点：
- **三级状态机制**：
  - `@Provide/@Consume`：组件树内共享 `isEdit`/`appInfoList`，子组件 `IconWithNameView` 通过 `@Consume isEdit` 控制删除按钮显示
  - `@StorageLink`：跨组件树全局共享 `deletionStatus`/`addStatus`，`GridItemDeletionCtrl` 在 `onFinish` 中通过 `AppStorage.setOrCreate` 更新状态，主组件通过 `@StorageLink` 监听变化实现防重入
  - `@Watch`：监听 `appInfoList` 变化自动重建 `GridItemDeletionCtrl`，保持数据/Modifier 1:1 映射
- **防重入锁**：`deletionStatus === FINISH` / `addStatus === FINISH` 作为前置校验，状态置 `IDLE` 后才允许执行动画，防止快速连续点击导致动画叠加
- **取消还原**：进入编辑模式时保存 `originAppInfoList`/`originalAppNameList`，取消时还原并重建 `GridItemDeletionCtrl`
- `this.isChange` 标记数据是否被修改，未修改时直接退出编辑模式，已修改时弹出确认对话框
