# 功能性测试用例

---

### 测试用例：FUNC-001

**skill**：hmos-window-hover-state
**类型**：functional（功能验证）

#### 输入

折叠屏上手机半折叠架起来的时候，我的应用想上半屏播视频、下半屏放控制条，需要监听什么接口？要新加权限吗？

#### 预期输出

**验证标准**：

- 说明悬停态机制：设备半折叠（HALF_FOLD）+ 折痕横向 + 全屏窗口满足系统判定条件时窗口进入 `WindowPostureMode.DESKTOP_MODE`，无需新增权限
- 给出接入三件套：`isInWindowPostureMode` 初始查询 + `onWindowPostureModeChange` 监听 + `@State isInHover` 单状态源驱动布局
- 强调是 window 实例方法（非泛型 on 事件），注册时传 `WindowPostureMode.DESKTOP_MODE`
- 提醒先核验目标 SDK 是否声明该组 API

**应包含**：WindowPostureMode.DESKTOP_MODE, onWindowPostureModeChange, isInWindowPostureMode

---

### 测试用例：FUNC-002

**skill**：hmos-window-hover-state
**类型**：functional（功能验证）

#### 输入

悬停态下上半屏播放视频，视频不能压到折痕，下半屏操作区要固定不能上下拖动，底部还要留安全距离，布局怎么算？

#### 预期输出

**验证标准**：

- 视频高度封顶折痕区域上沿（`contentHeight = creaseTop`），严格不进折痕区域
- 避让带公式 `max(creaseHeight / 2 + 16, 16)`vp，带内纯占位不放交互/文字
- 下半屏为固定操作坞：控制元素一次呈现不上下滚动，底部 padding 叠加导航条高度
- 折痕获取优先级：getLiveCreaseRegion（API 20+）→ getCurrentFoldCreaseRegion（API 10+）→ 屏幕中线兜底；px 除以 densityPixels 转 vp

**应包含**：creaseTop, densityPixels, getCurrentFoldCreaseRegion

---

### 测试用例：FUNC-003

**skill**：hmos-window-hover-state
**类型**：functional（功能验证）

#### 输入

做悬停自拍功能，上半屏取景器下半屏快门，进入悬停的时候预览黑屏了怎么办？

#### 预期输出

**验证标准**：

- 指出 XComponent/Surface 不得放进悬停 if/else 分支重建，同一渲染节点仅改布局参数（高度/权重）
- 快门等主按钮在下半屏加大（近水平视角人机工学），交互元素避开折痕区域
- 回调内只切状态不做重活，布局交给声明式 UI

**应包含**：XComponent, layoutWeight, isInHover

---

### 测试用例：FUNC-004

**skill**：hmos-window-hover-state
**类型**：functional（功能验证）

#### 输入

我的 SDK 里搜不到 onWindowPostureModeChange，是不是做不了悬停适配了？

#### 预期输出

**验证标准**：

- 给出降级方案：`display.getFoldStatus() === FoldStatus.FOLD_STATUS_HALF_FOLDED` + 全屏自查（windowSizeChange 回调复核窗口仍全屏）
- 说明降级行为差异与误差（非全屏误判、LS 态感知不到），不隐瞒风险
- 启动初始状态用 `getFoldStatus()` 查询
- 不虚构 SDK 中不存在的接口

**应包含**：FOLD_STATUS_HALF_FOLDED, getFoldStatus, windowSizeChange

---

### 测试用例：FUNC-005

**skill**：hmos-window-hover-state
**类型**：functional（功能验证）

#### 输入

书本型折叠屏悬停的时候窗口是横屏的，我的悬停布局加了 isInHover && !isLandscape 的判断，为什么横屏悬停布局一直不切换？

#### 预期输出

**验证标准**：

- 指出反模式：书本型设备悬停通常出现在横屏窗口（DESKTOP_MODE 要求折痕横向），`&& !isLandscape` 守卫导致横屏悬停布局永不切换
- 说明悬停布局由折痕坐标锚定、与窗口方向无关（crease.top 在任何窗口方向下都是折痕上沿）
- 布局状态优先级：悬停（系统回调）最高 > 全屏等其余布局状态
- 组合状态只用于选择布局形态，不得用于否定系统悬停状态

**应包含**：isLandscape, DESKTOP_MODE, 优先级

---

### 测试用例：FUNC-006

**skill**：hmos-window-hover-state
**类型**：functional（功能验证）

#### 输入

悬停态下操作按钮压到折痕上了，还有个返回按钮被导航条挡住，帮我修。

#### 预期输出

**验证标准**：

- 操作区从折痕中心线下方 16vp 开始（避让带 `max(折痕高/2 + 16, 16)`），固定坞内容做减法不溢出
- 指出固定高度 Column 子项溢出会穿过底部 padding 渲染到屏幕边缘（padding 不是裁剪边界）
- 底部避让用 `getWindowAvoidArea(TYPE_NAVIGATION_INDICATOR)` 实测高度且随 `avoidAreaChange` 动态刷新（一次性查询会过期）
- px 除以 densityPixels 转 vp

**应包含**：avoidAreaChange, getWindowAvoidArea, TYPE_NAVIGATION_INDICATOR
