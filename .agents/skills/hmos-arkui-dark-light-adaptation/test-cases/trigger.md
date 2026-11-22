# 触发验证

覆盖 ArkUI 深浅色适配的触发正例和普通网站 CSS 深浅色的不触发反例。

---

### 测试用例：TRIGGER-001

**skill**：hmos-arkui-dark-light-adaptation
**类型**：trigger（触发验证）

#### 输入

我的 HarmonyOS ArkUI 应用想适配深色模式。请只判断是否属于本 Skill，简短说明。

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-002

**skill**：hmos-arkui-dark-light-adaptation
**类型**：trigger（触发验证）

#### 输入

我要给普通浏览器网站写 CSS prefers-color-scheme，项目没有 HarmonyOS 或 ArkUI。请只判断是否属于本 Skill，不提供实现。

#### 预期输出

**应触发**：否
