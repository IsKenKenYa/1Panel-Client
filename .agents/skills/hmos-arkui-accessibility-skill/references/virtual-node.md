# 自绘组件与虚拟节点（accessibilityVirtualNode，API 11+）

## 适用（F 类诉求）

Canvas/自绘内容**整块区域绘制**，没有单个节点可以承载语义，读屏完全读不到（如折线图、仪表盘、棋盘）。

## 方案（基线：单个 Text 直述）

用 `accessibilityVirtualNode` 在自绘组件上挂**虚拟子节点**承载无障碍语义；辅助工具读取的是
**虚拟节点的语义**，而不是实际绘制内容。builder 内容基线：**一个 @Builder 函数 + 单个 Text
组件直接描述现状**，Text 的默认播报能力即可满足，无需叠加任何无障碍属性：

```ts
@Builder
customAccessibilityNode() {
  Text('仪表盘：当前转速 2450 转每分钟')   // 单个 Text 直述，默认播报即可
}

Canvas(this.context)
  .onReady(() => {
    // ...原有绘制逻辑，保持不变
  })
  .accessibilityVirtualNode(this.customAccessibilityNode)
```

## 约束（源码级 + SDK/真机实测）

- value **直传 @Builder 方法引用**（正确写法）：

  ```ts
  .accessibilityVirtualNode(this.customAccessibilityNode)
  ```

  两种包裹写法均**禁止**：

  错误写法 ① lambda 包裹——编辑器飘红 "UI component syntax cannot be written here"
  （2026-10 评测 Accessibility-eval 实测，vod-4）：

  ```ts
  // 禁止：lambda 包裹
  .accessibilityVirtualNode(() => {
    this.customAccessibilityNode();
  })
  ```

  错误写法 ② 对象包裹——编译报错 `'builder' does not exist in type '() => any'`
  （DevEco 260 API 26 SDK 首编实测，2026-10 评测 vod-3）：

  ```ts
  // 禁止：对象包裹
  .accessibilityVirtualNode({
    builder: () => {
      this.customAccessibilityNode();
    }
  })
  ```
- **builder 内容基线（vod-5）**：单个 Text 直接描述即可；**禁止**"容器 `accessibilityGroup(true)`
  + 子 Text 叠 `accessibilityText`"组合——父组件启用分组且自身无通用文本、未设
  accessibilityText 时，合并文本默认**拼接子组件的通用文本**，**不使用子组件的无障碍文本**
  （播报只剩'仪表盘'而非'仪表盘：当前转速 2450 转每分钟'，2026-10 评测实测）。确需分组且
  要保留子无障碍文本：`.accessibilityGroup(true, { accessibilityPreferred: true })`（深度遍历
  子节点时优先取其无障碍文本；较新参数，下限版本以官方文档为准，输出前核对）；
- 虚拟节点内的组件**有显示文本时默认播报即可**，不冗余叠加 accessibilityText；仅**无文本**
  组件（纯图标等）按基础属性规则补 accessibilityText；
- 下限 API 11：build-profile 三字段任一 < 11 → 阻断并给提升建议（如
  `compatibleSdkVersion: 10 → 11`），**不输出任何 virtualNode 相关代码——含"方案示意"
  "仅供参考"形式的代码块**，仅给阻断说明与提升建议；字段缺失 → 请求补充，不臆测。

## 粒度建议

| 自绘内容 | 虚拟节点组织 |
|----------|--------------|
| 单一整体（装饰图/仪表盘） | 1 个虚拟节点 + 1 个 Text 直述（基线，不套容器/不加属性） |
| 有结构的数据（折线图） | 总览 Text + 可选分粒度 Text（容器仅做布局，各自聚焦、默认播报，不加 group） |
| 可交互区域（棋盘） | 按交互区域拆分 Text，节点内可加自定义动作（accessibilityCustomActions） |

来源：注册 `frameworks/bridge/declarative_frontend/jsview/js_view_abstract.cpp:10453`；
解析 `js_accessibility.cpp:175-193`；下限 API 官方文档（中可信）；
builder 内容基线与组合并文本行为经 2026-10 评测 virtualNode 问题汇总实测（vod-5）。
