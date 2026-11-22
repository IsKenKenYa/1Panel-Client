# ArkUI-X 接口迁移建议报告

| 项 | 值 |
|----|----|
| 工程模型 | {{PROJECT_MODEL}} |
| 判定 SDK | {{SDK_LINE}} |
| 引用总数 | {{INVENTORY_COUNT}} |
| 单平台占比 | {{PLATFORM_RATIO}} |

分类口径：①完整直用 / ②有损直用 / ③等价桥接 / ④降级桥接 / ⑤平台裁剪 / ⑥业务决策（@hms.* 默认）；unknown 为待人工确认兜底。③/④ 类将由 F3 桥接生成 Skill 处理。

---

{{SECTIONS}}

---

> 本报告由 arkuix-interface-scan 生成；结构化结论见同目录 `scan-report.json`（契约 schema_version=1，供 F1/F3/F4 消费）。全流程离线执行，产物不含源码正文。
