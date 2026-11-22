# 触发验证用例

> 简短判断启动、转场性能诉求与非性能需求是否适用本 Skill。具体诊断能力由 functional.md 验证。

---

### 测试用例：TRIGGER-001

**skill**：hmos-arkui-performance-analysis
**类型**：trigger（触发验证）

#### 输入

我的 ArkUI 应用首页冷启动首帧慢。请只判断是否属于本 Skill 的分析范围，简短说明，不展开分析。

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-002

**skill**：hmos-arkui-performance-analysis
**类型**：trigger（触发验证）

#### 输入

帮我在设置页加一个开关，把用户选择保存到 Preferences，下次启动自动恢复。请只判断是否属于本 Skill 的处理范围，简短说明，不提供实现代码。

#### 预期输出

**应触发**：否

---

### 测试用例：TRIGGER-003

**skill**：hmos-arkui-performance-analysis
**类型**：trigger（触发验证）

#### 输入

我的 ArkUI 应用在 Swiper 翻页和页签切换时卡顿，进入新页会重新创建很多相同卡片。请只判断是否属于本 Skill 的分析范围，简短说明，不展开分析。

#### 预期输出

**应触发**：是
