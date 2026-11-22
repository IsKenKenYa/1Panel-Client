# HarmonyOS 基本手势及手势响应规则指南

## 一、基本手势及特点

当用户的操作符合某个手势的特征时，系统会将其识别为该手势，这一过程称为**手势识别**。为了响应某一个手势，需在组件上添加对应的手势对象，以便系统可以收集并进行处理。

| 手势 | 操作特征 | 触发方式举例 |
| --- | --- | --- |
| **TapGesture** | 点击（按下在较短时间内抬起，默认300ms） | 手指或触控笔点击触屏；按下鼠标左键并松开、单指点击触控板 |
| **LongPressGesture** | 长按（按下后维持一段时间） | 手指或触控笔长按触屏、长按鼠标左键、单指长按触控板 |
| **PanGesture** | 滑动（按下后开始移动） | 手指或触控笔点击触屏后移动、按下鼠标左键后移动、单指点击触控板后移动、鼠标指针指向可滑动组件后滚动鼠标滚轮、双指并拢在触控板上滑动 |
| **PinchGesture** | 捏合（双指按下后向内捏合或向外扩大） | 双指在触屏上捏合、双指在触控板上捏合、鼠标指针指向可响应捏合手势的组件时，按下物理键盘Ctrl键的同时，滚动鼠标滚轮 |
| **RotationGesture** | 旋转（双指按下后旋转双指） | 双指在触屏上旋转 |
| **SwipeGesture** | 快滑（与Pan的区别：swipe是以离手时的速度为判定条件；pan是以位移距离为判定条件，跟手触发） | 单指在触屏上快速滑动、双指在触控板上快速滑动、快速滑动鼠标滚轮 |

### TapGesture 识别约束

| 约束 | 说明 |
|------|------|
| 双击与单击冲突 | 组件同时绑定双击和单击手势时（双击先绑定），单击会有 **300ms 延迟**。GestureGroup 中同时添加时，**双击必须在前，单击在后** |

### LongPressGesture 识别约束

| 约束 | 说明 |
|------|------|
| 与拖拽冲突 | Text、TextInput、TextArea、HyperLink、Image、RichEditor 等默认可拖拽组件上，**duration < 500ms** 时优先响应长按，**≥ 500ms** 时优先响应拖拽 |
| 系统手势冲突 | API 18+ 部分设备会优先响应系统的双指长按手势，导致应用的双指长按手势不生效 |

### PanGesture 识别约束

| 约束 | 说明 |
|------|------|
| scale 变换影响 | 组件应用 scale 缩放变换时，distance 的实际识别距离按 scale 比例缩放 |
| Tabs 组件冲突 | Tabs 组件滑动与 PanGesture 同时存在时，可将 distance 设为 **1** 使滑动更灵敏 |

### RotationGesture 识别约束

| 约束 | 说明 |
|------|------|
| 触控板限制 | 触控板双指旋转操作**无法触发**此手势 |

---

## 二、手势响应规则

### 基本规则

1. **基于触摸测试**: 以按下那一刻的位置所命中的控件上收集到的手势为基础。
2. **子组件优先**: 同等条件的手势，子组件优先于父组件得到响应。
3. **先成功先响应**: 不同条件的手势，先成功（条件达成）的先响应。
4. **互斥竞争**: 如果不存在并行手势，则当有一个手势成功时，其他手势在本次操作过程中都不会再有成功的机会。
5. **并行传递**: 并行的手势在子组件上的同类型手势成功时，父组件上的同类型手势也会成功。
6. **内置优先**: 组件内置手势（系统默认绑定）的响应优先级高于开发者绑定的同类型手势，除非开发者使用 `priority` 绑定方式。

---

## 三、事件交互流程

事件交互流程是指当 ArkUI 接收上游发送的 Touch 类触控事件或 Mouse 类触控事件后，根据开发者设定的各类参数，收集事件响应链并分发至各组件以触发回调的整个过程。分为三个步骤：

1. **事件产生** — 硬件输入设备通过驱动、多模等模块，将事件上报至目标的 ArkUI 实例。
2. **收集事件响应链并分发事件** — 核心步骤：
   - (1) **触摸测试**: 管线接收起始触控事件后，根据坐标和组件位置进行触摸测试，建立事件响应链
   - (2) **分发至Touch事件响应链**: 触控事件根据响应链分发至目标组件
   - (3) **分发至手势响应链**: 各组件上的手势通过触摸测试后形成手势响应链，事件组合产生手势，手势竞争后触发回调
   - (4) **事件拦截**: 开发者可配置触摸测试属性影响响应链形成，或设置事件拦截改变分发流程
3. **触发回调** — 完成事件响应链的收集及事件分发后，符合触发条件的回调函数将被触发

---

## 四、触摸测试（命中测试）

触摸测试（touch test / hit test）是在用户交互开始前，系统确定哪些组件上的事件或手势能够参与此次交互响应的过程。

### 实现原理

系统不会遍历所有组件节点，而是在首次事件发生时确定能够响应的组件范围：

- 系统依据**组件响应热区是否包含事件坐标**来判定是否被点击
- 自上而下、自右向左遍历组件树，收集绑定的手势和事件
- 信息逐级向上冒泡至父组件，最终构建完整的事件响应链
- 基础事件在响应链上先传递给叶子节点，再逐层向上传递（事件冒泡）

---

## 五、事件响应链

ArkUI 事件响应链通过触摸测试进行收集，遵循**右子树（按组件布局的先后层级）优先的后序遍历**。

---

## 六、事件冒泡

基础事件在响应链上的传递遵循冒泡机制：最内层组件优先处理，再逐层往父组件传递。

- `stopPropagation` 可终止冒泡，但**不会中断父组件对手势的响应处理**
- 调用 stopPropagation 后，上层节点不再接收该 Touch 事件，但上层的手势对象仍能接收和处理

> 注意: 对同一事件的不同类型（Down/Move/Up）应采用一致的冒泡规则，避免事件不闭环。

---

## 七、Cancel 事件

系统在特定场景下发送 Cancel 类型事件（如 TouchType.Cancel、MouseAction.CANCEL）：

- 拖拽操作中，达到位移阈值触发 onDragStart 后，系统发送 Cancel 事件告知普通基础事件已结束
- Cancel 的含义与 Up 相同，均表示事件处理结束
- 处理 Up/Release 的场景中，应同时处理 Cancel

---

## 八、触摸事件

触摸事件（onTouch事件）是所有手势组成的基础，包括Down、Move、Up、Cancel四种类型。手势均由触摸事件组成，例如，点击为Down和Up，滑动为Down和一系列Move及Up。触摸事件具有以下特殊性：
监听了onTouch事件的组件，在手指落下被触摸时均会收到onTouch事件的回调，被触摸受到触摸热区和触摸控制影响。
1. onTouch事件的回调是闭环的。若一个组件收到了手指Id为0的Down事件，后续也会收到手指Id为0的Move事件和Up事件。
2. onTouch事件的回调是一致的。若一个组件收到了手指Id为0的Down事件，但未收到手指Id为1的Down事件，则后续只会收到手指Id为0的touch事件，不会收到手指Id为1的后续touch事件。
3. onTouch事件在以下场景会触发Cancel类型事件：
- 手指按住屏幕同时点击Home键返回桌面，此时触发Cancel事件。
- 折叠屏手机，应用在按住屏幕的情况下折叠手机切换到外屏，此时触发Cancel事件。
- 手指触摸过程中存在手写笔操作，手指的触摸操作会收到Cancel事件。

---

## 九、同一组件上各交互 API 的执行顺序

当同一组件同时绑定了多个交互相关 API 时，它们在一次触摸交互过程中按以下顺序依次触发：

```
onTouchIntercept
  └─> onChildTouchTest
        └─> onGestureCollectIntercept
              └─> shouldBuiltInRecognizerParallelWith
                    └─> onTouchTestDone
                          └─> onTouch
                                └─> onGestureRecognizerJudgeBegin
                                      └─> gesture（手势回调）
```

| 阶段 | API | 作用 | 时机 |
|------|-----|------|------|
| 1 | `onTouchIntercept` | 自定义事件拦截，可决定是否拦截此次触摸测试 | 触摸测试**最早期**，早于手势收集 |
| 2 | `onChildTouchTest` | 配置在父组件上，自定义子节点的触摸测试方式，返回 `TouchTestStrategy` 控制事件如何向子节点分发 | 触摸测试阶段，子节点触摸测试时触发（早于手势收集） |
| 3 | `onGestureCollectIntercept` | 自定义手势收集拦截，可控制是否收集本组件上的手势 | 触摸测试阶段，手势收集**之前** |
| 4 | `shouldBuiltInRecognizerParallelWith` | 决定组件内置手势识别器是否与开发者绑定的手势**并行**识别 | 手势收集阶段，识别器构建时 |
| 5 | `onTouchTestDone` | 触摸测试完成回调，可获取响应链结果 | 触摸测试**完成后**、事件分发前 |
| 6 | `onTouch` | 接收 Down/Move/Up/Cancel 触摸事件 | 事件按响应链**分发时** |
| 7 | `onGestureRecognizerJudgeBegin` | 手势识别器开始判定前的回调，可干预识别结果 | 手势识别**判定前** |
| 8 | `gesture`（及各手势 `onAction` 等） | 手势识别成功后的业务回调 | 手势识别**成功后** |

### 关键约束

- **顺序不可调换**：上述顺序由系统在触摸测试与手势识别流程中固定，开发者无法改变各 API 之间的相对先后。
- **拦截点越靠前影响范围越大**：`onTouchIntercept` 和 `onGestureCollectIntercept` 在收集阶段即可阻断后续流程；`onGestureRecognizerJudgeBegin` 只能影响最终的手势判定，无法改变事件分发。
- **`onChildTouchTest` 作用于子节点分发**：配置在父组件上，触摸测试阶段对子节点生效，通过 `TouchTestStrategy`（DEFAULT / FORWARD / FORWARD_COMPETITION）改变事件向子节点的分发；FORWARD 类策略需返回目标子节点 `id`（仅命名节点有效），且 `onClick`、捏合、旋转手势经此分发后可能因未命中热区而不响应。
- **并行判定独立于拦截**：`shouldBuiltInRecognizerParallelWith` 仅作用于内置识别器与开发者手势的并行关系，不参与事件分发与拦截。
- **`shouldBuiltInRecognizerParallelWith` 触发需同时满足两个前提**：① 当前组件本身具备**内置手势识别器**（回调参数 `current` 即该内置识别器）；② 事件响应链上其他组件存在**同类型手势**（内置或开发者绑定均可，作为参数 `others`）。二者缺一则回调不会被调用，自然不会产生并行。
- **`onTouchTestDone` 与 `onGestureRecognizerJudgeBegin` 的 `event` 参数差异**：`onTouchTestDone(event: TouchEvent, recognizers: Array<GestureRecognizer>)` 的 `event` 是 **`TouchEvent`**，仅含**基础触摸信息**（Down/Move/Up/Cancel、触点坐标等），**不含具体手势类型数据**——要干预手势须遍历第二参 `recognizers`，按 `getType()` 筛选后调用 `preventBegin()`；而 `onGestureRecognizerJudgeBegin(event: BaseGestureEvent, current, others)` 的 `event` 虽声明为 `BaseGestureEvent`，运行时实际是其**继承子类**实例（如 `TapGestureEvent`、`PanGestureEvent`、`PinchGestureEvent`、`RotationGestureEvent`、`SwipeGestureEvent` 等），携带各手势的**特有数据**（如 `offsetX/offsetY`、`scale`、`angle`、`speed`），可通过 `event as PanGestureEvent` 类型断言读取。各事件对象详见 [ts-gesture-common](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-gesture-common#basegestureevent11)。
- **`onTouch` 与 `gesture` 互补**：`onTouch` 收到的是原始触摸事件，`gesture` 收到的是识别后的语义手势；二者可以同时触发，但 `gesture` 永远晚于对应 `onTouch` 事件。

---

## 十、事件注入坐标规则（postTouchEvent / postInputEvent）

向 `BuilderNode` 创建的节点子树转发输入事件时，`postTouchEvent` 与 `postInputEvent` 读取的坐标字段不同，需按各自接口回填坐标：

| 接口 | 坐标基准 | 读取字段 | 坐标含义 |
|------|----------|----------|----------|
| `postTouchEvent` | 局部坐标 | `x` / `y` | 触点相对 post 事件对端（目标节点）内的局部偏移 |
| `postInputEvent` | 窗口坐标 | `windowX` / `windowY` | 触点相对 post 事件对端（目标节点）内的窗口偏移 |

### 关键约束

- **两接口坐标含义一致，仅字段名不同**：`postTouchEvent` 的 `x/y` 与 `postInputEvent` 的 `windowX/windowY` 表达的是同一组坐标（触点相对父组件的偏移），不能因字段名不同而误以为是两套语义。
- **跨接口转发需做字段映射**：从某事件回调拿到的若是 `x/y` 坐标、却要用 `postInputEvent` 转发时，须把 `windowX/windowY` 赋值为该 `x/y`（反之用 `postTouchEvent` 时回填 `x/y`）。

### 典型示例（onNativeEmbedGestureEvent）

`onNativeEmbedGestureEvent` 回调返回的 event 中，`x/y` 表示触点**相对父组件**的偏移。若需要通过 `postInputEvent` 将该事件转发进 `BuilderNode`，须将 `windowX/windowY` 赋值为该 `x/y`：

```typescript
// event.x / event.y 为触点相对父组件偏移；postInputEvent 读取 windowX/windowY，需手动回填
event!.changedTouches[0].windowX = event!.changedTouches[0].x;
event!.changedTouches[0].windowY = event!.changedTouches[0].y;
builderNode.postInputEvent(event);
```