
# 手势绑定场景

## SCENE-01 priorityGesture 覆盖子组件手势/系统组件内置手势

**适用场景：** 当自定义手势需要优先于子组件手势/系统组件内置手势响应时使用。例如 List、Grid 等组件内置了滑动手势，如果需要长按触发弹窗而非触发组件默认行为，应使用 `priorityGesture` 将自定义手势优先级提升到组件内置手势之上。

**与 parallelGesture 的区别：** `parallelGesture` 不改变优先级，自定义手势与组件内置手势并行竞争；`priorityGesture` 确保自定义手势优先响应。

### 应用场景：长按图片显示菜单

**实现步骤：**

1. **声明弹窗显隐状态**：`@State showMenu: boolean = false`,在 `bindPopup` 的 `onStateChange` 中同步重置
2. **绑定 bindPopup**：`.bindPopup(this.showMenu, { builder: this.popUpBuilder, onStateChange: ... })`,内容用 `@Builder` 提供
3. **挂载 priorityGesture**：`.priorityGesture(GestureGroup(GestureMode.Exclusive, LongPressGesture().onAction(() => { this.showMenu = true })))`,让长按优先于子组件/内置手势

```typescript
@Component
struct GridImageView {
  @State blogItem: BlogData = new BlogData();
  @State showMenu: boolean = false;    // 控制弹窗显隐
  @State flowHeight: Length = 0;
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

  // 可复用组件必须通过 aboutToReuse 更新数据
  aboutToReuse(params: ESObject): void {
    this.blogItem = params.blogItem;
  }

  build() {
    Stack() {
      Image(this.blogItem.images[0])
        .sourceSize({ width: 100, height: 100 })
        .width(CommonConstants.FULL_WIDTH)
        .aspectRatio(1)
        .objectFit(ImageFit.Cover)
    }
    .borderRadius(12)
    .clip(true)
    // ① 气泡弹窗：由 showMenu 状态驱动
    .bindPopup(this.showMenu, {
      builder: this.popUpBuilder,       // 弹窗内容构建器
      placement: Placement.Top,         // 弹窗出现在组件上方
      mask: { color: '#33000000' },     // 半透明遮罩
      popupColor: Color.Yellow,         // 黄色背景
      enableArrow: true,                // 显示箭头指向
      showInSubWindow: false,           // 不在子窗口中显示
      onStateChange: (e) => {
        if (!e.isVisible) {
          this.showMenu = false;        // 弹窗消失时同步状态
        }
      }
    })
    // ② 优先手势：长按触发弹窗
    .priorityGesture(
      GestureGroup(GestureMode.Exclusive,
        LongPressGesture().onAction(() => {
          this.showMenu = true;
        })
      )
    )
  }

  // ③ 弹窗内容：不感兴趣按钮
  @Builder
  popUpBuilder() {
    Row({ space: 2 }) {
      Text($r('app.string.not_interested_button_text'))
    }
    .width(100)
    .height(50)
    .padding(5)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      // 通过 eventHub 通知页面删除该条目
      this.context.eventHub.emit(CommonConstants.EVENT_REMOVE_ITEM, this.blogItem)
      this.showMenu = false;
    })
  }
}
```

---

## SCENE-02 parallelGesture 与子组件手势/系统组件内置手势并行处理

**适用场景：** 当父组件自定义手势需要与子组件（或系统组件内置）手势同时响应时使用。例如弹窗/面板组件内部包含可滚动列表，父组件需通过拖拽手势调整弹窗高度（下拉关闭、上拉恢复），同时子列表仍需正常滚动，两者不互斥。

**与 priorityGesture 的区别：** `priorityGesture` 会拦截子组件手势，子组件无法响应；`parallelGesture` 让父组件手势与子组件手势并行触发，通过状态标志位在回调中协调各自行为。

### 应用场景：评论弹窗高度与商品内容高度放缩联动

**实现步骤：**

1. **拆分拖拽区域**：上方蒙版用 `.gesture(PanGesture(...))`,弹窗主体用 `.parallelGesture(PanGesture(...), GestureMask.Normal)`
2. **父子状态联动**：`@State isGesture` 通过 `@Link` 传给子列表,子列表到顶时回写 `true`;父手势 `onActionUpdate` 首行 `if (!this.isGesture) return;`
3. **计算目标高度并夹紧**:`curDialogHeight = initDialogHeight - event.offsetY`,小于 0 取 0,大于初始值取初始值
4. **`onActionEnd` 决定终态**:高度小于 `COMMENT_DIALOG_MIN_HEIGHT` 调 `closeDialog()`,否则 `recoveryDialog()` 吸附

```typescript
@Component
export struct CommentDialog {
  @LocalStorageProp('ndPageHeight') ndPageHeight: number = 0;
  @Link ndDialogHeight: number;
  private initDialogHeight: number = 0;
  /** 是否允许父组件手势响应，列表未在顶部滚动时禁用 */
  @State isGesture: boolean = true;
  @State listScrollAble: boolean = true;

  build() {
    Column() {
      // ① 弹窗上方蒙版，独立绑定普通 gesture，与弹窗区域互不影响
      Column()
        .width('100%')
        .height(this.ndPageHeight - this.ndDialogHeight)
        .backgroundColor(Color.Transparent)
        .gesture(PanGesture({ direction: PanDirection.Vertical })
          .onActionUpdate((event) => {
            if (this.ndDialogHeight <= 0) { return; }
            const curDialogHeight = this.initDialogHeight - event.offsetY;
            if (curDialogHeight < 0) {
              this.ndDialogHeight = 0;
            } else if (curDialogHeight <= this.initDialogHeight) {
              this.ndDialogHeight = curDialogHeight;
            }
          })
          .onActionEnd(() => {
            if (this.ndDialogHeight < COMMENT_DIALOG_MIN_HEIGHT) {
              this.closeDialog();
            } else {
              this.recoveryDialog();
            }
          }))

      // ② 弹窗主体：包含可滚动的评论列表子组件
      Column() {
        Comment({
          isGesture: this.isGesture,          // 子组件通过 @Link 回写状态
          listScrollAble: this.listScrollAble,
        })
      }
      .width('100%')
      .height(this.ndDialogHeight)
      .backgroundColor(Color.White)
      // ③ parallelGesture：与子列表内置滚动手势并行响应
      .parallelGesture(
        PanGesture({ direction: PanDirection.Vertical })
          .onActionUpdate((event) => {
            // 通过 isGesture 标志位判断：列表滚动到顶部时才允许父手势处理拖拽
            if (!this.isGesture || this.ndDialogHeight <= 0) { return; }
            const curDialogHeight = this.initDialogHeight - event.offsetY;
            if (curDialogHeight < 0) {
              this.ndDialogHeight = 0;
            } else if (curDialogHeight <= this.initDialogHeight) {
              this.ndDialogHeight = curDialogHeight;
            }
          })
          .onActionEnd(() => {
            if (!this.isGesture && this.ndDialogHeight === this.initDialogHeight) {
              return;
            }
            if (this.ndDialogHeight < COMMENT_DIALOG_MIN_HEIGHT) {
              this.closeDialog();
            } else {
              this.recoveryDialog();
            }
            this.listScrollAble = true;
          }),
        GestureMask.Normal   // ④ 使用 Normal 掩码，不忽略任何子组件手势
      )
    }
    .width('100%')
    .height('100%')
  }
}
```

---

## 内置手势组件列表

ArkUI 部分组件内置了系统手势（如滚动、点击、拖拽等），当开发者通过 `gesture` API 为这些组件绑定自定义手势时，自定义手势可能与内置手势产生冲突。以下列出所有具有内置手势的组件，以及各组件内置的手势类型和冲突场景说明。

### 滚动容器类组件（内置 Pan/Swipe 滑动手势）

此类组件内置纵向或横向滑动手势，是手势冲突的高发场景。组件提供了 `nestedScroll` 属性解决嵌套滚动冲突。

| 组件 | 内置手势 | 冲突场景 | 组件提供的控制属性 |
|------|---------|---------|------------------|
| **List** | 纵向滑动手势 | 自定义长按/拖拽被滑动拦截；嵌套List时内层优先 | `nestedScroll`、`enableScrollInteraction` |
| **Grid** | 纵向/横向滑动手势 | 同List，自定义手势被滑动拦截 | `nestedScroll`、`enableScrollInteraction` |
| **Scroll** | 纵向/横向滑动手势 | 嵌套滚动容器时与子组件滑动手势冲突 | `nestedScroll`、`enableScrollInteraction` |
| **Swiper** | 左右滑动手势 | 自定义左右滑动与翻页手势冲突 | `disableSwipe`（禁用滑动切换） |
| **WaterFlow** | 纵向滑动手势 | 瀑布流滚动与自定义手势冲突 | `nestedScroll`、`enableScrollInteraction` |
| **Tabs** | 左右滑动手势 | 自定义左右滑动与标签页切换冲突 | `scrollable`（禁用手势切换） |

### 媒体类组件（内置点击/长按/缩放手势）

| 组件 | 内置手势 | 冲突场景 |
|------|---------|---------|
| **Image** | 长按动画（长按后放大效果） | 自定义 `LongPressGesture` 被内置长按动画拦截，导致长按回调不触发 |
| **Video** | 点击（播放/暂停）、滑动（进度拖拽）、双指缩放 | 自定义手势与播放控制手势冲突 |
| **Web** | 滚动、长按（文本选择）、点击、双指缩放 | 自定义手势与网页内置交互冲突；嵌套滚动容器时需 `nestedScroll` 联动 |

### 表单交互类组件（内置点击/拖拽手势）

| 组件 | 内置手势 | 冲突场景 |
|------|---------|---------|
| **Slider** | 拖动手势（滑块拖拽）、点击手势（点击轨道跳转） | 自定义拖拽/点击与滑块调节冲突 |
| **Rating** | 点击手势（点击选星）、滑动手势（滑动选星） | 自定义点击/滑动与星级选择冲突 |
| **Toggle** | 点击手势（点击切换开关） | 自定义 `TapGesture` / `onClick` 与开关切换冲突 |
| **Checkbox** | 点击手势（点击切换选中） | 自定义 `TapGesture` / `onClick` 与选中切换冲突 |
| **Radio** | 点击手势（点击选择） | 自定义点击手势与单选切换冲突 |
| **Select** | 点击手势（点击展开下拉菜单） | 自定义点击与菜单展开冲突 |
| **Search** | 点击手势（点击搜索框聚焦） | 自定义点击与输入聚焦冲突 |

### 选择器类组件（内置滚动手势）

| 组件 | 内置手势 | 冲突场景 |
|------|---------|---------|
| **DatePicker** | 滚动手势（年/月/日滚轮选择） | 自定义纵向滑动与滚轮滚动冲突 |
| **TimePicker** | 滚动手势（时/分滚轮选择） | 自定义纵向滑动与滚轮滚动冲突 |
| **TextPicker** | 滚动手势（文本滚轮选择） | 自定义纵向滑动与滚轮滚动冲突 |

### 导航类组件（内置滑动手势）

| 组件 | 内置手势 | 冲突场景 |
|------|---------|---------|
| **Navigation** | 边缘右滑返回手势 | 自定义左/右滑动手势与系统返回手势冲突 |