# ArkUI V1/V2 触发验证

覆盖 V1 → V2 迁移的触发正例和纯 V2 新功能的不触发反例。按 hmos-skill-test-runner 的逐条隔离调用流程判断是否体现迁移 skill 的能力。

---

### 测试用例：TRIGGER-001

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：trigger

#### 输入

把现有 ArkUI V1 页面及其子组件迁移到状态管理 V2，请先分析迁移范围、输入输出与共享状态，再给出改造方案。

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-002

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：trigger

#### 输入

用 ArkUI @ComponentV2 和 @Local 从零写一个加减计数器，只需要纯 V2 新功能，没有既有 V1 代码需要迁移。

#### 预期输出

**应触发**：否
