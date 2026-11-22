#  真实 demo 采样清单

> 选型原则（design）：开源 OH 应用工程（含 @ohos.*/@hms.* 与 Native 混合引用），固化入 fixture 清单；
> 通过标准：unknown 占比 ≤20% 且逐项可归因（超出则补规则条目后复测）。

| # | 采样工程 | 形态 | 固化位置 | 说明 |
|---|----------|------|----------|------|
| 1 | OpenHarmony 应用样例（applications_app_samples 画廊典型新闻/健康类应用形态） | @ohos.* + @hms.* + Native 混合 | `benchmark/fixture-demo-project/` | 离线最小化固化快照：保留真实应用常见的路由/通知/定位/闭源 Kit/NDK XComponent 引用形态（文件内容为脱敏最小重构，引用集与原形态一致） |

## unknown 占比口径（固化）

- 占比 = adaptation.unknown 条目数 ÷ adaptation 全部条目数（七桶合计）
- 逐项归因：每条 unknown 标注归因（规则表未覆盖 / 双源冲突）
- 阈值：≤20%；超出时补规则条目并复测（规则表 rules_version 递增）
