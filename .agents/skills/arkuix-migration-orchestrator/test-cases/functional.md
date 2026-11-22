# 功能性测试用例

---

### 测试用例：FUNC-001

**skill**：arkuix-migration-orchestrator
**类型**：functional（功能验证）

#### 输入

把我的 OpenHarmony 工程端到端迁移到 ArkUI-X（全流程：扫描→骨架→桥接→报告）

#### 预期输出

**验证标准**：

四阶段按序调度（scan→skeleton→bridge→report）；MigrationState 落账（stages/decisions/checkpoints）；SDK 询问先行门（码4 呈报查找方法+候选）；⑥/unknown 决策不代答（缺预设=码4 一次列全）；N2-B 源码改写（编译保绿）；桥接落位 commons HAR；七段迁移报告（含适用版本与环境要求段）

**应包含**：MigrationState, scan-report, skeleton-result, bridge-artifact, migration-report, 七段

---

### 测试用例：FUNC-002

**skill**：arkuix-migration-orchestrator
**类型**：functional（功能验证）

#### 输入

用 new 模式迁移，Compile SDK 选 26.0.0，配置迁移选 yes

#### 预期输出

**验证标准**：

skeleton_mode=new 触发双强确认门（migrate_configs + compile_sdk）；缺预设=码4+专属指引；--answer 注入后全链完成；scaffold 落点事前打印；版本三元组保留+钳制（compatible ≤ target ≤ compile）

**应包含**：skeleton_mode, new, compile_sdk, migrate_configs, scaffold
