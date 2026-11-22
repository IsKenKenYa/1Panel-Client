# @correctness — 正确性规则

检查特定场景下的 API 使用是否符合 HarmonyOS 规范，涵盖音频、AVSession、图像、无障碍、网络、V1 状态管理等。

## 规则集

- `plugin:@correctness/all` — 14 条
- **无 `recommended` 粒度**

> 另有 2 条规则（`listen-default-network-change`、`listen-multi-network-concurrent`）不在任何预设中，可通过 `rules` 字段启用。

## 全部规则列表（19 条）

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@correctness/audio-interrupt-check` | all | error | 监听音频焦点变化并处理 |
| `@correctness/audio-pause-or-mute-check` | all | warn | 音频设备不可用时自动暂停 |
| `@correctness/avsession-metadata-check` | all | warn | AVSession 需提供元数据和播放状态 |
| `@correctness/avsession-buttons-check` | all | warn | AVSession 需监听按键事件 |
| `@correctness/multimedia-use-stride-in-image-receiver` | all | warn | ImageReceiver 回调需读取 rowStride |
| `@correctness/image-interpolation-check` | all | warn | ImageInterpolation.None 可能导致锯齿 |
| `@correctness/image-pixel-format-check` | all | warn | RGB_565 可能导致色阶问题 |
| `@correctness/listen-default-network-change` | — | suggestion | 监听默认网络变化并重新建立连接 |
| `@correctness/listen-multi-network-concurrent` | — | suggestion | 订阅 Wi-Fi/蜂窝网络切换通知 |
| `@correctness/v1-nested-object-property-change-format-check` | all | warn | V1 深层嵌套属性修改不触发 UI 刷新 |
| `@correctness/v1-state-object-member-used-in-function-parameter-check` | all | warn | a.b(this.object) 形式不触发 UI 刷新 |
| `@correctness/accessibility-label-check` | all | suggestion | 焦点朗读不允许"未加标签"或乱码 |
| `@correctness/accessibility-focus-redundancy-check` | all | suggestion | 界面焦点顺序中无冗余焦点 |
| `@correctness/accessibility-type-redundancy-check` | all | suggestion | 控件不应有多个控件类型 |
| `@correctness/accessibility-status-missing-check` | all | suggestion | 需添加无障碍控件类型 |
| `@correctness/reasons-for-user-grant-check` | all† | suggestion | 用户授权时需说明理由 |
| `@correctness/request-user-authorization-second-time-check` | all† | suggestion | 二次请求用户授权的规范检查 |
| `@correctness/paste-board-for-user-grant-check` | all† | suggestion | 剪贴板访问需用户授权检查 |
| `@correctness/redundant-dependency-check` | all | suggestion | 检测冗余依赖 |

> **†** 标注的规则存在于 shipped ruleSet.json 中但部分版本的 schema 未收录。使用前可通过 `extract-schema.js` 确认当前版本是否支持。

## 示例

```json
{
  "ruleSet": ["plugin:@correctness/all"]
}
```
