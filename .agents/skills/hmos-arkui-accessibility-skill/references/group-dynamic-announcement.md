# 聚合播报与动态播报

## 聚合播报（accessibilityGroup，API 12+）

### 适用（C 类诉求）

多个子组件在语义上属于同一功能单元（如"年/月/日"三个 Text），逐个聚焦造成信息冗余。

### 用法

在**父容器**上设置：

```ts
Column() {
  Text('2026').fontSize(20)
  Text('9').fontSize(20)
  Text('14').fontSize(20)
}
.accessibilityGroup(true)
```

### 行为语义

- 容器成为单一聚焦单元，读屏一次播报聚合内容；
- 子 Text 不再分别聚焦；
- **组播报文本优先级**：用户设置文本（accessibilityText）优先，否则取组内文本聚合
  （源码 `frameworks/core/accessibility/utils/accessibility_property_utils.cpp:43` GetContent）。
- **合并文本陷阱（vod-5，必检）**：父组件设 `accessibilityGroup(true)` 且自身**无通用文本、
  未设 accessibilityText** 时，合并文本默认**拼接子组件的通用文本**（显示文本），**不使用
  子组件的 accessibilityText**。如 `Column { Text('仪表盘').accessibilityText('仪表盘：当前转速 2450 转每分钟') }.accessibilityGroup(true)`
  只播报'仪表盘'，无障碍文本被丢弃（2026-10 评测实测）。规避三选一：
  1. 子组件**通用文本**直接承载完整描述（Text('仪表盘：当前转速 2450 转每分钟')）；
  2. 容器上设 `accessibilityText` 直接指定合并文本（注意覆盖语义提示）；
  3. `.accessibilityGroup(true, { accessibilityPreferred: true })`——深度遍历子节点时优先取
     其无障碍文本（较新参数，下限版本以官方文档为准，输出前核对）。

### 常见错误

| 错误 | 正解 |
|------|------|
| 给组内每个 Text 单独加 accessibilityText 作为"聚合"方案 | 聚合在容器上 group(true)，不是逐个加 text |
| group 容器无自身文本，靠子组件 accessibilityText 承载合并语义（合并文本只拼子组件通用文本，无障碍文本被丢弃，vod-5） | 子组件通用文本直述完整描述 / 容器设 accessibilityText / group(true, { accessibilityPreferred: true }) |
| group 后某组件还需单独聚焦却无解 | 该组件 `.accessibilityLevel('yes')`（反 group） |
| 聚合后播报顺序/内容不合预期 | 检查是否同时设置了组文本与子文本（优先级：用户文本 > 组内聚合） |

## 动态播报（accessibility.sendAccessibilityEvent）

### 适用

界面内容动态更新时，辅助服务**不会自动识别变化**（如倒计时、比分刷新、异步结果到达），需主动发送事件通知。

### 用法（仓内真实用法，treeviewv2.ets:1384）

```ts
import { accessibility } from '@kit.AccessibilityKit';

// 请求读屏聚焦某节点并播报（如抢焦点提醒）
let eventInfo: accessibility.EventInfo = {
  type: 'requestFocusForAccessibility',
  bundleName: (getContext() as common.UIAbilityContext)?.abilityInfo?.bundleName,
  triggerAction: 'common',
  customId: 'resultPanel'
};
accessibility.sendAccessibilityEvent(eventInfo).then(() => {
  // 发送成功后的业务处理
});
```

### 要点

- EventInfo 常用字段：`type`（事件类型）、`bundleName`、`triggerAction`、`customId`；
- 事件类型枚举（如 `requestFocusForAccessibility`）以公开官方文档为准（中可信，外部模块契约）；
- 常与聚合播报组合：先 group 聚合语义，再在内容变化时 sendAccessibilityEvent 触发播报。

### 动态更新组件内的播报文本

组件内状态变化（如 `@State` 文本）会随属性更新自动反映到无障碍树；
**主动提醒类**播报（变化即播、抢焦点）才需要 sendAccessibilityEvent。

来源：仓内用法 `advanced_ui_component/treeviewv2/source/treeviewv2.ets:1384`（导入 `:20`）；
优先级事实 `frameworks/core/accessibility/utils/accessibility_property_utils.cpp:43`。
