# integration_state 状态绑定

任务全程维护**唯一一份** `integration_state`，不使用散落占位符；下游环节**只消费该状态，不重新推断**。状态属内部记账，仅用于推理与报告摘要；面向开发者的呈现遵守硬约束 7。

## 目录

- 结构
- 产出 / 消费环节
- 兜底

## 结构

```yaml
integration_state:
  mode: first | homogeneous | heterogeneous   # 接入形态（前置步骤 Step 2 赋值）
  share_type: file | link | both              # 分享类型（工作流程 Step 0 Q1）
  mode_switch: fixed | tab | dynamic          # 模式切换时机（工作流程 Step 0 Q5，仅 share_type = both）
  compat_low:       # compatibleSdkVersion < 6.0.0(20) → true（前置步骤 Step 1 赋值）
  mount:
    module:         # 挂载模块（前置步骤 Step 3）
    page:           # 挂载页路径（工作流程 Step 0 Q2）
    dir:            # Manager/Provider 落盘目录（工作流程 Step 1）
    lifecycle:      # enable/disable 接线结果（工作流程 Step 2）
    entry_ability:  # 入口 Ability 检测结果（工作流程 Step 3）：ok / patched / mismatch / unavailable
  file:             # 仅 share_type ∈ {file, both}（工作流程 Step 0 Q3）
    scope:          # 可分享范围与勾选字段
    multi:          # 是否可能多文件
    uri_source:     # uri 来源与转换方式
  link:             # 仅 share_type ∈ {link, both}（工作流程 Step 0 Q4）
    domain:         # 域名
    verified:       # 域名是否已验证（true / false）
    path_query:     # 链接 path 与业务 query（构造 content 用）
    landing_page:   # 落地页路由
  validation:       # 验证结果（工作流程 Step 5 赋值）
    static_check:   # 静态检查：pass / fail / skipped
    build:          # 编译：pass / fail / skipped
```

## 产出 / 消费环节

| 字段 | 产出环节 | 消费环节 |
|------|----------|----------|
| mode | 前置步骤 Step 2 | 工作流程 Step 1、工作流程 Step 6 |
| share_type | 工作流程 Step 0 Q1 | 工作流程 Step 1、工作流程 Step 4 |
| mode_switch | 工作流程 Step 0 Q5 | 工作流程 Step 2 enable 传参 |
| compat_low | 前置步骤 Step 1 | 工作流程 Step 6 已知限制 |
| mount.module | 前置步骤 Step 3 | 工作流程 Step 1 |
| mount.page | 工作流程 Step 0 Q2 | 工作流程 Step 1、工作流程 Step 2、工作流程 Step 6 |
| mount.dir | 工作流程 Step 1 | 工作流程 Step 6 修改摘要 |
| mount.lifecycle | 工作流程 Step 2 | 退出自查 |
| mount.entry_ability | 工作流程 Step 3 | 工作流程 Step 6 修改摘要、退出自查 |
| file.scope / file.multi / file.uri_source | 工作流程 Step 0 Q3 | 工作流程 Step 1 Provider 实现（含 addRecord 判定） |
| link.domain / link.verified / link.path_query / link.landing_page | 工作流程 Step 0 Q4 | 工作流程 Step 4 |
| validation.static_check / validation.build | 工作流程 Step 5 | 工作流程 Step 6 验证结果 |

## 兜底

未获赋值且无默认值的字段 → 回到产出环节追问或按错误处置表 E5 中止该项接入。
