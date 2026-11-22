# 冒烟测试用例（路由验证）

场景 ID 对应 SKILL.md 任务路由表：ROT-01 智感旋转机制、ROT-02 策略选型、ROT-03 接口编码、ROT-04 实战案例、ROT-05 扫描改造。

---

### 测试用例：SMOKE-ROT-001

**skill**：hmos-window-smart-orientation
**类型**：smoke（路由验证）

#### 输入

智感旋转是什么原理？我的应用要满足什么条件才能用上智感旋转？

#### 预期输出

**应命中场景**：ROT-01
**禁止命中场景**：ROT-03, ROT-04, ROT-05

---

### 测试用例：SMOKE-ROT-002

**skill**：hmos-window-smart-orientation
**类型**：smoke（路由验证）

#### 输入

直板机上自动旋转又要能锁定当前方向（包括横屏），应该选哪个 Orientation 枚举？

#### 预期输出

**应命中场景**：ROT-02
**禁止命中场景**：ROT-01, ROT-05

---

### 测试用例：SMOKE-ROT-003

**skill**：hmos-window-smart-orientation
**类型**：smoke（路由验证）

#### 输入

module.json5 里 orientation 字段有哪些合法取值？和 setPreferredOrientation 的枚举怎么对应？

#### 预期输出

**应命中场景**：ROT-03
**禁止命中场景**：ROT-01, ROT-04, ROT-05

---

### 测试用例：SMOKE-ROT-004

**skill**：hmos-window-smart-orientation
**类型**：smoke（路由验证）

#### 输入

视频详情页竖屏，点全屏要立刻转横屏，退出再恢复，给我实现代码。

#### 预期输出

**应命中场景**：ROT-04
**禁止命中场景**：ROT-01, ROT-02, ROT-05
