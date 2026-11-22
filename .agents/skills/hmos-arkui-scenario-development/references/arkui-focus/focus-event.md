# 焦点事件场景

## SCENE-01 响应获焦失焦事件

**适用场景：** 需要根据组件的获焦 / 失焦状态变化作出响应的场景，包含两类诉求：①驱动 UI 切换——获焦 / 失焦时改变样式或显隐辅助元素（如浮动标签、输入框高亮、提示文案、联动其他组件）；②执行指定回调——在获焦 / 失焦时机触发业务逻辑（如失焦校验输入、提交 / 暂存数据、埋点上报、弹出搜索联想等）。常见于表单输入、搜索框、可编辑卡片等需要焦点反馈或焦点联动业务的交互。

**核心机制：** 在 `onFocus` / `onBlur`（必要时配合 `onChange`）事件回调中响应焦点变化，常见两条路径：①改状态变量（如 `@State` 的缩放比例、样式开关）驱动 UI 重绘，失焦时常结合内容判断是否回退（内容为空才恢复），可配 `.animation()` 平滑过渡；②直接执行指定业务回调（校验、提交、埋点、联想请求等），不经过 UI 重绘。两者可在同一回调中并存。

### 应用场景：地址详情表单浮动标签

地址详情页面包含姓名、电话、地址、详细地址四个输入项，用 `Stack` 把 `Text` 标签叠放在 `TextInput` 上：未输入且未聚焦时标签以原始大小显示在输入框内，`onFocus` 时缩小并上浮、`onBlur` 时若内容为空再恢复。这是用获焦 / 失焦事件驱动标签缩放上浮的典型用法，同样的「监听 `onFocus` / `onBlur` 改变样式」写法可平移到输入框高亮、提示显隐等其他焦点反馈场景。

**实现步骤：**

1. **Stack 叠放 TextInput 和 Text 标签**：标签覆盖在输入框上方，设置 `hitTestBehavior(Transparent)` 不拦截触摸
2. **onFocus 缩小标签**：输入框获焦时设置 `scaleTimes = 0.75`，记录焦点索引
3. **onBlur 恢复标签**：失焦时若内容为空则恢复 `scaleTimes = 1`，有内容则保持缩小
4. **onChange 联动**：内容变化时同步更新 `scaleTimes`，清空时恢复、有内容时缩小
5. **animation 动画**：标签添加 `.animation()` 使缩放平滑过渡

```typescript
@Component
struct UserInfoTextInput {
  componentId: string = '';
  @Link text: string;
  contentType: ContentType | undefined = undefined;
  label: ResourceStr | undefined = undefined;
  index: number = -1;
  @State scaleTimes: number = 1;
  @State currentIndex: number = -1;

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // ① TextInput 输入框
      TextInput({ text: this.text })
        .id(this.componentId)
        .width('100%')
        .backgroundColor(Color.White)
        .contentType(this.contentType)
        .padding({ left: 12, top: 0, bottom: 0 })
        .selectionMenuHidden(true)
        // ③ 内容变化联动标签
        .onChange((value: string) => {
          this.text = value;
          this.scaleTimes = value === '' ? 1 : 0.75;
        })
        // ④ 获焦：缩小标签，记录焦点索引
        .onFocus(() => {
          this.scaleTimes = 0.75;
          this.currentIndex = this.index;
        })
        // ⑤ 失焦：内容为空则恢复标签
        .onBlur(() => {
          if (this.text === '') {
            this.scaleTimes = 1;
          }
        })

      // ② 浮动标签 Text
      Text() {
        Span('*').fontColor('#ff5000')
        Span(this.label)
      }
      .scale(this.index === this.currentIndex || this.text !== '' ? {
        x: this.scaleTimes,
        y: this.scaleTimes,
        centerX: 0,
        centerY: -80
      } : { x: 1, y: 1, centerX: 0, centerY: -80 })
      .animation({ duration: CommonConstants.ANIMATION_DURATION })
      .height(this.index === this.currentIndex ? 24 : undefined)
      .width('100%')
      .hitTestBehavior(HitTestMode.Transparent)
      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      .padding({ left: 12 })
    }
    .height(72)
  }
}
```

---

## SCENE-02 指定默认焦点组件（defaultFocus）

**适用场景：** 在容器（页面、弹窗、半模态等）加载或激活时，希望某个组件自动获得焦点，省去用户手动点击的步骤。

**核心机制：** 在目标组件上设置 `.defaultFocus(true)`，声明该组件为所在焦点容器的默认焦点组件。当该容器（页面、弹窗、模态等）被加载或激活时，系统会自动将焦点赋予该组件，无需用户手动点击，也无需手动调用 `focusControl.requestFocus()`。

### 应用场景：自定义弹窗输入框自动获焦

评论输入弹窗（`CommentInputDialog`）使用 `@CustomDialog` 装饰器声明为一个自定义弹窗，内部包含一个 `TextInput` 输入框和一个"发布"按钮。弹窗打开后，`TextInput` 需要立即获得焦点，使输入法自动弹出，用户可直接开始输入评论。这是 `defaultFocus` 在弹窗容器下的典型用法，同样的写法可平移到页面、模态等其他容器中。

**实现步骤：**

1. **使用 @CustomDialog 声明弹窗组件**：通过 `@CustomDialog` 装饰器将组件声明为自定义弹窗
2. **在 TextInput 上设置 defaultFocus(true)**：声明输入框为弹窗的默认焦点组件
3. **配置弹窗布局**：通过 `RelativeContainer` 布局输入框和发布按钮，设置锚点对齐规则
4. **处理发布逻辑**：点击"发布"按钮时关闭弹窗并通过 `publish` 回调将内容传回主页面

```typescript
import promptAction from '@ohos.promptAction';

// 组件在相对布局中的锚点 ID
const ID_TEXT_INPUT: string = "id_text_input";
const ID_TEXT_PUSH: string = "id_text_publish";

@CustomDialog
export struct CommentInputDialog {
  @State selectedImages: string[] = [];
  @State text: string = "";
  @Link textInComment: string;
  @State placeholder: string = "";
  controller?: CustomDialogController;
  publish: () => void = (): void => {};

  build() {
    Column() {
      RelativeContainer() {
        TextInput({ placeholder: this.placeholder })
          .height($r('app.integer.text_flow_root_text_input_height'))
          .padding({
            left: $r('app.integer.text_flow_root_text_input_padding_left'),
            right: $r('app.integer.text_flow_root_text_input_padding_right'),
            top: $r('app.integer.text_flow_root_text_input_padding_top'),
            bottom: $r('app.integer.text_flow_root_text_input_padding_bottom')
          })
          .margin({ right: $r('app.integer.text_flow_root_text_input_margin_right') })
          .onChange((textInComment: string) => {
            this.text = textInComment;
          })
          // 关键：声明为弹窗的默认焦点组件，弹窗打开后输入框自动获焦并弹出输入法
          .defaultFocus(true)
          .alignRules({
            top: { anchor: "__container__", align: VerticalAlign.Top },
            bottom: { anchor: "__container__", align: VerticalAlign.Bottom },
            left: { anchor: "__container__", align: HorizontalAlign.Start },
            right: { anchor: ID_TEXT_PUSH, align: HorizontalAlign.Start }
          })
          .id(ID_TEXT_INPUT)

        Button($r("app.string.text_flow_publish"))
          .width($r('app.integer.text_flow_root_btn_width'))
          .height($r('app.integer.text_flow_root_btn_height'))
          .borderRadius(15)
          .backgroundColor($r('app.color.text_flow_color_red'))
          .fontColor(Color.White)
          .onClick(() => {
            if (this.controller) {
              this.textInComment = this.text;
              this.publish();
              this.controller.close();
              this.textInComment = "";
              promptAction.showToast({ message: $r('app.string.text_flow_reply_success') });
            }
          })
          .alignRules({
            top: { anchor: "__container__", align: VerticalAlign.Top },
            bottom: { anchor: "__container__", align: VerticalAlign.Bottom },
            right: { anchor: "__container__", align: HorizontalAlign.End }
          })
          .id(ID_TEXT_PUSH)
      }
      .height($r('app.integer.text_flow_relative_container_height'))
    }
    .padding($r('app.integer.text_flow_column_padding'))
    .backgroundColor(Color.White)
    .offset({ y: 20 }) // 添加 y 轴偏移量，否则弹窗和输入法间会有空白
  }
}
```

---

## SCENE-03 覆盖原始获焦框样式（focusBox / stateStyles + outline）

**适用场景：** 任何需要覆盖系统默认获焦框视觉的场景。组件获焦时，系统会按默认规则绘制焦点边框（颜色、宽度、动画形态），但实际业务中往往需要按设计稿替换为自定义的纯色边框、虚线/点线边框、带圆角的描边，或者完全去除系统自带的获焦动画。常见诉求包括：去除 TV 设备/部分模拟器上的流光（发光）特效、修正系统焦点框颜色被覆盖、对齐卡片网格的统一焦点视觉、实现 Material 风格的柔和获焦描边等。

**核心机制：** `focusBox` 是 ArkUI 提供的获焦边框绘制能力，可配置 `margin` / `strokeColor` / `strokeWidth`。当默认效果不符合预期时，可以从两个方向覆盖：

- **方案 A（在 focusBox 内部调整）**：保留 `focusBox` 语义，通过参数覆盖默认绘制 —— 例如把 `strokeWidth` 设为 `LengthMetrics.px(0)` 隐藏默认描边或附带特效，或调整 `strokeColor` 改变边框颜色。适合只想去掉某些默认效果、不需要更换绘制机制的场景。
- **方案 B（stateStyles + outline 完全接管）**：用 `stateStyles` 的多态样式（`normal` / `focused`）配合外描边 `outline` 属性，绕开 `focusBox`，自行控制获焦视觉。`outline` 支持 `OutlineStyle.SOLID / DASHED / DOTTED`、`radius`、`color`、`width`，表达力更强。**注意：一旦设置了 `outline`，`focusBox` 将不再生效**，适合需要彻底替换默认效果的场景。

**实现步骤：**

1. **判断覆盖程度**：先明确是希望"微调默认框"（颜色/宽度）还是"完全替换为自定义边框"。前者走方案 A，后者走方案 B。
2. **方案 A — 调整 focusBox 参数**。
3. **方案 B — stateStyles + outline 接管**：使用 `stateStyles` 分别声明 `normal` 与 `focused` 两态的 `outline` 描边（`width` / `color` / `radius` / `style`），获焦时切换为自定义描边。
4. **互斥说明**：组件上若同时存在 `focusBox` 和 `outline`，`outline` 优先级更高，`focusBox` 失效 —— 选 B 时无需再配置 `focusBox`。

```typescript

// ===== 方案 A：保留 focusBox，仅去除流光特效（TV 场景最常用） =====
Button('Button1')
  .width(140)
  .height(45)
  .focusBox({ strokeWidth: LengthMetrics.px(0) }) // 将描边宽度置 0，去除流光特效

// ===== 方案 B：stateStyles + outline 完全自定义获焦样式 =====
// 适合需要虚线/点线/圆角描边、或希望彻底替换默认焦框的场景
Button('Button2')
  .width(140)
  .height(45)
  .stateStyles({
    normal: {
      // 未获焦：宽度 0，不显示描边
      .outline({
        width: 0,
        color: Color.Red,
        radius: 50,
        style: OutlineStyle.DASHED
      })
    },
    focused: {
      // 获焦：宽度 5 的红色虚线外描边
      .outline({
        width: 5,
        color: Color.Red,
        radius: 50,
        style: OutlineStyle.DASHED
      })
    }
  })
```

---

## SCENE-04 主动控制焦点

**适用场景：** 验证码输入、OTP（一次性密码）、支付密码、手机号分段输入等由多个独立输入框组成的场景。焦点流向取决于业务逻辑（输入长度、按键事件、点击位置），需要按条件在框与框之间**主动迁移**焦点，或在点击空白时**清除**焦点。

**核心机制：** `getUIContext().getFocusController()` 提供两个核心 API：

- `requestFocus(key: string)`：根据组件 `.id()` 主动让指定组件获焦
- `clearFocus()`：清除当前页面的所有焦点

与 `defaultFocus`（被动声明）不同，`requestFocus` / `clearFocus` 是**运行时按条件主动调用**，焦点流向由业务逻辑决定。两种 API 可在同一个场景中并存使用。

### 应用场景：四位验证码连续输入（FourTextInput）

四个独立 `TextInput` 框，每个仅允许输入 1 个字符。涵盖 4 种焦点控制时机：

| 时机 | 触发事件 | 调用 API | 行为 |
|------|---------|---------|------|
| ① 页面加载 | `Row.onAppear` | `requestFocus('0')` | 自动聚焦首个输入框，弹出输入法 |
| ② 输入完成 | `TextInput.onChange` | `requestFocus((index + 1).toString())` | 当前框满 1 字符后跳到下一个框 |
| ③ 删除回退 | `TextInput.onDidDelete` | `requestFocus((index - 1).toString())` | 当前框已空时按删除键，清空上一框并聚焦 |
| ④ 点击空白 | `Column.onClick` | `clearFocus()` | 收起输入法并清除所有焦点 |

**实现步骤：**

1. **为每个 TextInput 设置唯一 id**：使用 `index.toString()` 作为 id，`requestFocus` 通过 id 定位目标组件
2. **onAppear 初始化焦点**：页面加载完成时调用 `requestFocus('0')`，让首个输入框自动获焦
3. **onChange 中跳焦**：判断输入长度为 1 且非末尾框时，调用 `requestFocus((index + 1).toString())`
4. **onDidDelete 中回退焦**：当前框内容**已经为空**时再次按删除键才触发，清空上一框内容并调用 `requestFocus((index - 1).toString())`
5. **外层容器 onClick 清焦**：调用 `clearFocus()` 让当前组件失焦并收起软键盘

```typescript
@Entry
@Component
struct FourTextInput {
  @State inputValue: string[] = ['', '', '', ''];
  @State inputEnable: boolean[] = [true, false, false, false];
  inputIndex: number[] = [0, 1, 2, 3];

  build() {
    Column() {
      Row() {
        ForEach(this.inputIndex, (index: number) => {
          RelativeContainer() {
            TextInput({ text: this.inputValue[index] })
              .fontSize('30vp')
              .textAlign(TextAlign.Center)
              .maxLength(1)
              .showPasswordIcon(false)
              .height(80)
              .border({
                width: 1,
                color: this.inputEnable[index] ? '#1b91e0' : '#999999',
                radius: 4,
                style: BorderStyle.Solid,
              })
              // ① 关键：为每个输入框设置唯一 id，requestFocus 通过 id 定位
              .id(index.toString())
              // ③ 删除回退：当前框已空时按删除键，清空上一框并聚焦上一框
              .onDidDelete(() => {
                if (this.inputValue[index].length === 0) {
                  if (index !== 0) {
                    this.inputValue[index - 1] = '';
                    this.inputEnable[index] = false;
                    this.inputEnable[index - 1] = true;
                    this.getUIContext().getFocusController().requestFocus((index - 1).toString());
                  } else {
                    this.inputValue[index] = '';
                  }
                }
              })
              // ② 输入完成跳焦：输入 1 个字符后自动聚焦下一个框
              .onChange((value: string) => {
                this.inputValue[index] = value;
                if (value.length !== 1) {
                  return;
                }
                if (index !== 3) {
                  this.inputEnable[index + 1] = true;
                  this.inputEnable[index] = false;
                  this.getUIContext().getFocusController().requestFocus((index + 1).toString());
                }
              })
          }.layoutWeight(1).margin({ right: 5, left: index === 0 ? 5 : 0 })
        })
      }
      // ① 页面加载时聚焦第一个输入框
      .onAppear(() => {
        this.getUIContext().getFocusController().requestFocus('0');
      })
    }
    .height('100%')
    .width('100%')
    // ④ 点击空白清除所有焦点（同时收起软键盘）
    .onClick(() => {
      this.getUIContext().getFocusController().clearFocus()
    })
  }
}
```
