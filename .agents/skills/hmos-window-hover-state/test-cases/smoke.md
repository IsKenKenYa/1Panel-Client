# 冒烟测试用例（路由验证）

场景 ID 对应 SKILL.md 任务路由表：HVS-01 触发机制、HVS-02 接口编码、HVS-03 布局设计、HVS-04 验证、HVS-05 存量改造。

---

### 测试用例：SMOKE-HVS-001

**skill**：hmos-window-hover-state
**类型**：smoke（路由验证）

#### 输入

折叠屏半折叠悬停的时候窗口为什么不进入悬停态？系统是怎么判定的？

#### 预期输出

**应命中场景**：HVS-01
**禁止命中场景**：HVS-02, HVS-04, HVS-05

---

### 测试用例：SMOKE-HVS-002

**skill**：hmos-window-hover-state
**类型**：smoke（路由验证）

#### 输入

onWindowPostureModeChange 怎么注册？isInWindowPostureMode 初始查询怎么写？给我完整的监听代码。

#### 预期输出

**应命中场景**：HVS-02
**禁止命中场景**：HVS-01, HVS-04, HVS-05

---

### 测试用例：SMOKE-HVS-003

**skill**：hmos-window-hover-state
**类型**：smoke（路由验证）

#### 输入

悬停态下视频上半屏播放、下半屏放控制条，折痕要避开，布局怎么设计？

#### 预期输出

**应命中场景**：HVS-03
**禁止命中场景**：HVS-01, HVS-05

---

### 测试用例：SMOKE-HVS-004

**skill**：hmos-window-hover-state
**类型**：smoke（路由验证）

#### 输入

悬停适配代码写完了，怎么在真机上验证悬停态触发和布局切换？

#### 预期输出

**应命中场景**：HVS-04
**禁止命中场景**：HVS-02, HVS-03, HVS-05

---

### 测试用例：SMOKE-HVS-005

**skill**：hmos-window-hover-state
**类型**：smoke（路由验证）

#### 输入

我的播放页已经上线了，现在要加悬停态适配，直接改 build 会有什么坑？

#### 预期输出

**应命中场景**：HVS-05
**禁止命中场景**：HVS-01, HVS-04
