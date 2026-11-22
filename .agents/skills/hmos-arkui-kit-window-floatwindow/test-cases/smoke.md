## 冒烟测试用例

> 路由问答。输入已要求只输出一行能力 id，避免子进程读文件超时。

---

### 测试用例：SMOKE-001

**skill**：hmos-arkui-kit-window-floatwindow  
**类型**：smoke（路由验证）

#### 输入

不要读任何文件。只输出一行：`能力=pip` 或 `能力=float_view` 或 `能力=floating_ball` 或 `能力=out_of_scope`。问题：视频播放页要系统画中画小窗继续播，选哪个？

#### 预期输出

**应命中场景**：pip  
**禁止命中场景**：TYPE_FLOAT, createSubWindow

---

### 测试用例：SMOKE-002

**skill**：hmos-arkui-kit-window-floatwindow  
**类型**：smoke（路由验证）

#### 输入

不要读任何文件。只输出一行：`能力=pip` 或 `能力=float_view` 或 `能力=floating_ball` 或 `能力=out_of_scope`。问题：退后台还要展示自定义页面内容的小窗（不要系统 PiP 控制条），选哪个？

#### 预期输出

**应命中场景**：float_view  
**禁止命中场景**：TYPE_FLOAT, createSubWindow

---

### 测试用例：SMOKE-003

**skill**：hmos-arkui-kit-window-floatwindow  
**类型**：smoke（路由验证）

#### 输入

不要读任何文件。只输出一行：`能力=pip` 或 `能力=float_view` 或 `能力=floating_ball` 或 `能力=out_of_scope`。问题：贴边小球、不要自定义 UI，选哪个？

#### 预期输出

**应命中场景**：floating_ball  
**禁止命中场景**：TYPE_FLOAT, createSubWindow
