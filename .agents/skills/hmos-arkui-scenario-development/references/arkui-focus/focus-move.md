# 焦点移动场景

## SCENE-01 Snackbar 常驻通知弹窗 Tab 走焦闭环

**适用场景：** 应用需要弹出一个常驻的提示条（不会自动消失），用户能用键盘 Tab 键从触发按钮走焦进入 Snackbar 的文本按钮，触发动作后焦点能回到原触发按钮。常见于关注/收藏/保存成功后的提示、网络断开提示、文件上传进度提示等需要持续展示并允许交互的场景。

**核心机制：**

1. **`duration: -1` 声明常驻**：在 `SnackBarStyleOptions` 中设置 `duration` 为 -1，Snackbar 不会自动消失
2. **`textButtonId` 标识 Snackbar 文本按钮**：在 `SnackBarOperationOptions.operationType = SnackBarOperationType.TEXT_WITH_CLOSE` 时，通过 `textButtonId: 'snackBarTextButton'` 给 Snackbar 内部的文本按钮设置唯一标识
3. **宿主按钮 `.nextFocus({ forward })`**：触发 Snackbar 显示的按钮（如"关注"按钮）通过 `.nextFocus({ forward: 'snackBarTextButton' })` 声明 Tab 键进入 Snackbar 的走焦规则
4. **`nextFocusId` 配置回归组件**：在 `SnackBarStyleOptions` 中设置 `nextFocusId: 'button'`，声明 Snackbar 关闭后回到 id 为 `button` 的组件

**关键链路三件套：** HdsSnackBar 在 `SnackBarOperationOptions` 中暴露 `textButtonId`、在 `SnackBarStyleOptions` 中暴露 `nextFocusId`，宿主组件则用 ArkUI 原生的 `.nextFocus({ forward })` 与之对齐。三者通过 `id` 字符串互通。

**走焦链路示意：**

```
[宿主"关注"按钮]  ──Tab──▶  [Snackbar 文本按钮(textButtonId)]
       ▲                              │
       │                              │ (Snackbar 关闭/消失)
       │                              ▼
       └──── nextFocusId 指定的组件 ◀──┘
```

**实现步骤：**

1. **导入 HdsSnackBar 相关模块**：从 `@kit.UIDesignKit` 导入 `HdsSnackBar`、`SnackBarIconOptions`、`SnackBarMessageOptions`、`SnackBarOperationOptions`、`SnackBarStyleOptions`、`SnackBarOperationType`
2. **创建 HdsSnackBar 实例**：传入 `UIContext` 构造，作为调用 `show` 方法的基础
3. **配置 operation.textButtonId**：右侧操作区类型设为 `TEXT_WITH_CLOSE`，并指定 `textButtonId: 'snackBarTextButton'`
4. **配置 style.nextFocusId 与 duration**：`nextFocusId: 'button'` 指定 Snackbar 关闭后回归的组件 id，`duration: -1` 表示常驻
5. **宿主"关注"按钮设置 nextFocus**：`forward` 必须与 `textButtonId` 严格一致
6. **触发按钮调用 show**：点击触发按钮调用 `hdsSnackBar.show(icon, message, operation, style)`

```typescript
import {
  HdsSnackBar,
  SnackBarIconOptions,
  SnackBarMessageOptions,
  SnackBarOperationOptions,
  SnackBarStyleOptions,
  SnackBarOperationType
} from '@kit.UIDesignKit';

@Entry
@ComponentV2
struct TestSnackBar {
  uiContext: UIContext = this.getUIContext();
  hdsSnackBar: HdsSnackBar = new HdsSnackBar(this.uiContext);

  // ① 左侧图标
  icon: SnackBarIconOptions = {
    icon: $r('sys.symbol.checkmark_circle')
  }

  // ② 中间文本
  message: SnackBarMessageOptions = {
    title: $r('sys.string.ohos_id_text_location_button_description_current_position'),
    content: $r('sys.string.ohos_id_text_save_button_description_save')
  }

  // ③ 关键：右侧操作区设置 textButtonId，作为 Tab 走焦进入 Snackbar 的目标标识
  operation: SnackBarOperationOptions = {
    operationType: SnackBarOperationType.TEXT_WITH_CLOSE,
    content: $r('sys.string.ohos_id_text_save_button_description_save_image'),
    textButtonId: 'snackBarTextButton'
  }

  // ④ 关键：style 中设置 nextFocusId（Snackbar 关闭后回归组件）和 duration（-1 表示常驻）
  style: SnackBarStyleOptions = {
    nextFocusId: 'button',
    duration: -1
  }

  build() {
    Column() {
      Blank().height(400)

      // 触发 Snackbar 显示的按钮，id 为 'button'，与 nextFocusId 对齐
      Button('右侧操作区是文字按钮和关闭按钮的SnackBar弹窗，常驻')
        .onClick(() => {
          this.hdsSnackBar.show(this.icon, this.message, this.operation, this.style);
        })
        .id("button")

      // ⑤ 关键：宿主"关注"按钮配置 nextFocus.forward，值必须与 textButtonId 完全相同
      Button('关注')
        .nextFocus({
          // forward 的 id 必须和 SnackBarOperationOptions 接口中传入的 textButtonId 相同
          forward: 'snackBarTextButton'
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(0xF1F3F5)
  }
}
```

---

## SCENE-02 List 循环走焦

**适用场景：** TV 应用、车机、平板外接键盘等使用**方向键/Tab 键**在 List 列表项之间导航的场景。用户按方向键（上/下或左/右）到达列表**末尾项**后期望焦点循环回到**首项**，到达**首项**按反向方向键后期望焦点跳到**末尾项**，形成环形导航。常见于设置项列表、菜单列表、影视分集、Tab 标签条、数字键盘等。

**核心机制：** `List` + `ListItem` 容器内，系统默认走焦在到达边界时会"卡住"（线性走焦算法拒绝与当前焦点方向相反的方向键走焦请求）。要实现循环走焦，需通过 `nextFocus` 在每个 `ListItem` 的内部可获焦组件上**显式声明首尾互相指向**：

- 方向键循环（`up` / `down` / `left` / `right`）：在**首项**配置反向键指向**末项 id**，在**末项**配置正向键指向**首项 id**
- Tab 键循环（`forward` / `backward`）：在**末项**配置 `forward` 指向**首项 id**，在**首项**配置 `backward` 指向**末项 id**

**实现步骤：**

1. **List + ForEach 渲染 ListItem**：每个 ListItem 内部放置一个可获焦组件（Button / Text + focusable）
2. **为每个可获焦组件设置唯一 id**：使用 `item_${index}` 形式，便于在 nextFocus 中引用相邻索引
3. **首项配置反向方向键指向末项**：例如首项 `.nextFocus({ up: 'item_${last}' })`，让方向键上跳到末项
4. **末项配置正向方向键指向首项**：例如末项 `.nextFocus({ down: 'item_0' })`，让方向键下跳回首项
5. **可选 Tab 循环**：首项 `.nextFocus({ backward: 'item_${last}' })`、末项 `.nextFocus({ forward: 'item_0' })`
6. **可选焦点视觉反馈**：通过 `onFocus` / `onBlur` 切换背景色或边框，让用户清晰看到当前获焦项

```typescript
interface SettingItem {
  id: string
  title: string
}

@Entry
@Component
struct LoopFocusListDemo {
  private items: SettingItem[] = [
    { id: 'wifi', title: 'WLAN' },
    { id: 'bt', title: '蓝牙' },
    { id: 'display', title: '显示与亮度' },
    { id: 'sound', title: '声音' },
    { id: 'storage', title: '存储' },
  ]

  @State focusedIndex: number = -1

  build() {
    Column() {
      Text('设置（方向键循环走焦）')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 })

      List({ space: 8 }) {
        ForEach(this.items, (item: SettingItem, index: number) => {
          ListItem() {
            Row() {
              Text(item.title)
                .fontSize(16)
                .fontColor(this.focusedIndex === index ? '#007DFF' : '#333333')
              Blank()
              Text('›')
                .fontSize(20)
                .fontColor('#999999')
            }
            .width('100%')
            .height(56)
            .padding({ left: 16, right: 16 })
            .borderRadius(8)
            .backgroundColor(this.focusedIndex === index ? '#E6F0FF' : '#FFFFFF')
            // ① 关键：每个 ListItem 内部组件设置唯一 id
            .id(`item_${index}`)
            .onClick(() => { /* 点击进入对应设置项 */ })
            .focusable(true)
            // ② 关键：方向键循环 —— 首项按"上"跳到末项，末项按"下"跳回首项
            .nextFocus({
              // 中间项：正常指向相邻索引；首项（index === 0）按"上"跳到末项
              up: index > 0 ? `item_${index - 1}` : `item_${this.items.length - 1}`,
              // 中间项：正常指向相邻索引；末项按"下"跳回首项
              down: index < this.items.length - 1 ? `item_${index + 1}` : `item_0`
            })
            // ⑥ 焦点视觉反馈
            .onFocus(() => { this.focusedIndex = index })
          }
        }, (item: SettingItem) => item.id)
      }
      .width('90%')
      .height('70%')
      .padding(12)
      .backgroundColor('#F5F5F5')
      .borderRadius(12)
    }
    .width('100%')
    .height('100%')
    .padding({ top: 24 })
  }
}
```

```typescript
// 进阶：同时支持方向键循环 + Tab 键循环
// 适合键盘用户既可用方向键、也可用 Tab 键的场景
ListItem() {
  Row() { /* 同上 */ }
    .id(`item_${index}`)
    .focusable(true)
    .nextFocus({
      // 方向键循环
      up: index > 0 ? `item_${index - 1}` : `item_${this.items.length - 1}`,
      down: index < this.items.length - 1 ? `item_${index + 1}` : `item_0`,
      // Tab 键循环：末项按 Tab 跳回首项
      forward: index < this.items.length - 1 ? `item_${index + 1}` : `item_0`,
      // Shift+Tab 循环：首项按 Shift+Tab 跳到末项
      backward: index > 0 ? `item_${index - 1}` : `item_${this.items.length - 1}`
    })
}
```
