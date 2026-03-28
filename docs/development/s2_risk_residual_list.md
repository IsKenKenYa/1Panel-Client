# S2-6 风险残留清单（已批准）

更新日期: 2026-03-28  
适用分支: 模块适配-阶段2

## 1. 处理原则

- 本清单只记录不阻塞 Phase 2 Final 的已批准残留。
- 所有残留项必须标注去向（Phase 3）与处理建议。
- 不在 Phase 2 硬范围内的 tail 能力按范围边界归档。

## 2. 已批准残留（阻塞等级: 否）

| 模块 | 残留项 | 原因 | 去向 |
| --- | --- | --- | --- |
| Database | 用户管理细节、更多写操作表单、细分状态展示 | 主链路闭环已完成，细节深化超出本轮收口窗口 | Phase 3 |
| Firewall | forward / filter advance / chain status | 当前 hard scope 以 status/rules/ip/ports 为主 | Phase 3 |

## 3. 范围边界残留（按计划排除）

| 工作流 | 项目 | 说明 |
| --- | --- | --- |
| S2-2 Website Core | proxy cache / load balance / real ip / stream | 计划明确为 tail，不纳入 Phase 2 主交付 |
| S2-3 Security & Gateway | CA / ACME / DNS account 深化能力 | 仅收口证书中心与站点绑定主流程 |
| S2-4 Orchestration + AI | image repo / compose template | 计划明确为 tail，不纳入 Phase 2 主交付 |
| S2-3 OpenResty | 高级配置长尾能力 | 当前收口目标是结构化中心主链路 |

## 4. 风险控制建议

- 在 Phase 3 建立独立残留看板，按模块拆分 owner 与目标版本。
- 优先处理涉及写操作安全性的残留（Database、Firewall）。
- 对 tail 项维持范围锁定，避免反向侵入 Phase 2 已完成口径。
