# 无障碍事件响应与自定义走焦

## 事件回调

### onAccessibilityFocus（API 18+）

读屏**聚焦/失焦**时回调（移入/移出）。适用：统计获焦次数、聚焦时展开详情等业务逻辑。

```ts
@State focusCount: number = 0;

Column() {
  Text(`获焦 ${this.focusCount} 次`)
}
.onAccessibilityFocus((isFocus: boolean) => {
  if (isFocus) {
    this.focusCount += 1;   // 仅移入时计数；移出 isFocus=false
  }
})
```

- 回调签名 `(isFocus: boolean) => void`（源码 `js_accessibility.cpp:260-277`）；
- 传 undefined 可取消注册；
- 版本注意：需 API 18+；对满足版本的工程做软提示即可，不阻断。

### onAccessibilityHover（API 12+）

开启无障碍后**单指触摸**组件时触发（悬停探测）。适用："读屏用户摸到卡片预览详情"这类触摸交互。
回调为**双参数** `(isHover: boolean, event: AccessibilityHoverEvent)`：isHover=触摸进入/离开，event=位置等事件信息。

```ts
Image($r('app.media.preview'))
  .onAccessibilityHover((isHover: boolean, event: AccessibilityHoverEvent) => {
    if (isHover) {
      // 触摸进入：预览/展开
    } else {
      // 触摸离开：收起
    }
  })
```

- 单参数 `(event)` 写法会编译报错（`boolean` 与 `AccessibilityHoverEvent` 参数不兼容，
  DevEco 260 API 26 SDK 首编实测，2026-10 评测 vod-3）；
- 与属性可叠加（属性+方法不冲突）；
- 与 focus 的区别：hover=触摸经过（12+），focus=焦点移入/移出（18+）——逐方法标注版本。

## 自定义走焦（G 类诉求，API 18+）

### 首焦点：accessibilityDefaultFocus

```ts
aboutToAppear() { /* ... */ }

build() {
  Column() {
    Button('确认')          // 页面首个读屏焦点
      .accessibilityDefaultFocus(true)
    Button('取消')
  }
}
```

页面进入后读屏**首次聚焦**到该组件（boolean，源码 `js_accessibility.cpp:279-288`）。

### 下一焦点：accessibilityNextFocusId

```ts
Column() {
  TextInput({ placeholder: '手机号' })
    .id('phone_input')                            // 仅目标组件需要 id
  TextInput({ placeholder: '验证码' })
    .accessibilityNextFocusId('phone_input')   // 验证码获焦后，下一个焦点回到手机号（源组件无需 id）
}
```

- 值为目标组件的 id（string）；**仅目标组件需要 `.id()`**——源组件（挂 nextFocusId 的组件）
  加 id 属无业务用途的冗余代码，禁止生成（2026-10 评测 redundant_id 实测，vod-6）；
- `options.isConsiderDescendants`（API 26+）控制下一焦点是否考虑**目标节点**的子节点，
  **默认 false**（下一焦点落到目标节点本身，不进入其子节点）：
  - 需要进入目标节点的**子节点**：显式传 `{ isConsiderDescendants: true }`（非默认值）；
  - 跳过目标子节点（**默认行为**）：**不传第二参数**——显式传 `{ isConsiderDescendants: false }`
    与默认值一致，属冗余代码，禁止生成（vod-6）。

### 语义区分（必同时说明）

| 属性 | 语义 |
|------|------|
| accessibilityDefaultFocus | 页面**默认/首个**读屏焦点 |
| accessibilityNextFocusId | 某组件获焦后**指定下一个**获焦节点 |

## 版本门禁提示模板

```
该能力需要 API 18+（accessibilityDefaultFocus/accessibilityNextFocusId/onAccessibilityFocus）。
当前工程 build-profile：compileSdkVersion=X / compatibleSdkVersion=Y / targetSdkVersion=Z。
- 任一字段 < 18 → 阻断：建议将三字段提升至 18+（给出具体字段修改示例），不输出该类属性/回调
  任何代码（含"方案示意"形式）。
- 全部 ≥ 18 → 软提示版本要求后正常输出。
```

来源：注册 `frameworks/bridge/declarative_frontend/jsview/js_view_abstract.cpp:10422`（hover）/`:10458`（focus）/`:10449`（nextFocusId）/`:10459`（defaultFocus）；解析实现 `js_accessibility.cpp:87-106/260-288`；下限 API 官方文档（中可信）。
