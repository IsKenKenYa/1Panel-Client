### 测试用例：FUNC-001

**skill**：hmos-window-immersive（必填）
**类型**：functional（功能验证）

#### 输入

页面顶部蓝色、底部颜色不同，想分别延伸到状态栏和导航条

#### 预期输出

**验证标准**：

- 推荐使用 `.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])` 和 `.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])` 方案（方案 B）
- 顶部组件设置 `SafeAreaEdge.TOP`，底部组件设置 `SafeAreaEdge.BOTTOM`
- 代码示例使用 `SafeAreaType.SYSTEM` 和 `SafeAreaEdge` 枚举

**应包含**：expandSafeArea, SafeAreaType.SYSTEM, SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM
**格式**：markdown

---

### 测试用例：FUNC-002

**skill**：hmos-window-immersive（必填）
**类型**：functional（功能验证）

#### 输入

我的应用所有页面都需要沉浸式效果，怎么统一设置？

#### 预期输出

**验证标准**：

- 推荐使用 `setWindowLayoutFullScreen(true)` 方案（方案 C，窗口级，全局生效）
- 说明该方案需配合 `getWindowAvoidArea()` + `on('avoidAreaChange')` 手动避让
- 说明 `setWindowLayoutFullScreen` 不改变窗口模式和大小，仅改变布局是否避让系统栏
- 代码示例在 `onWindowStageCreate` 中 `loadContent` 回调后调用

**应包含**：setWindowLayoutFullScreen, getWindowAvoidArea, on('avoidAreaChange')
**格式**：markdown

---

### 测试用例：FUNC-003

**skill**：hmos-window-immersive（必填）
**类型**：functional（功能验证）

#### 输入

做一个视频播放页面，进入全屏播放时隐藏状态栏和导航条，退出时恢复显示

#### 预期输出

**验证标准**：

- 使用 `setSpecificSystemBarEnabled('status', false)` 隐藏状态栏
- 使用 `setSpecificSystemBarEnabled('navigationIndicator', false)` 隐藏导航条
- 无需 `setWindowLayoutFullScreen`（视频全屏场景只需隐藏系统栏）
- 退出时恢复：`setSpecificSystemBarEnabled('status', true)` + `setSpecificSystemBarEnabled('navigationIndicator', true)`
- 代码包含 Promise 错误处理（catch / try-catch）

**应包含**：setSpecificSystemBarEnabled, status, navigationIndicator
**不应包含**：setWindowLayoutFullScreen
**格式**：markdown

---

### 测试用例：FUNC-004

**skill**：hmos-window-immersive（必填）
**类型**：functional（功能验证）

#### 输入

我的页面是滚动列表，想实现沉浸式效果让背景延伸到状态栏和导航条

#### 预期输出

**验证标准**：

- 提到父容器是滚动容器时子组件 expandSafeArea 无效
- 提供两种解决方案：父容器设 `expandSafeArea` 或父容器设 `clipContent(ContentClipMode.SAFE_AREA)`
- 代码示例中父容器（Scroll）设置了相同背景色

**应包含**：expandSafeArea, clipContent, ContentClipMode.SAFE_AREA
**格式**：markdown

---

### 测试用例：FUNC-005

**skill**：hmos-window-immersive（必填）
**类型**：functional（功能验证）

#### 输入

如何获取状态栏和导航条的高度做避让处理？需要支持窗口旋转后动态更新

#### 预期输出

**验证标准**：

- 使用 `getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)` 获取状态栏高度
- 使用 `getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)` 获取底部导航区域高度
- 使用 `on('avoidAreaChange')` 监听避让区变化
- 避让区值使用 `px2vp()` 转换后再用于布局 padding
- 提到 `on/off` 需成对调用

**应包含**：getWindowAvoidArea, AvoidAreaType.TYPE_SYSTEM, AvoidAreaType.TYPE_NAVIGATION_INDICATOR, on('avoidAreaChange'), px2vp
**格式**：markdown

---

### 测试用例：FUNC-006

**skill**：hmos-window-immersive（必填）
**类型**：functional（功能验证）

#### 输入

平板自由多窗模式下，如何隐藏窗口标题栏但保留三键（关闭、最小化、最大化）？

#### 预期输出

**验证标准**：

- 使用 `setWindowDecorVisible(false)` 隐藏标题栏
- 使用 `setWindowDecorHeight()` 设置标题栏高度
- 提到使用 `getTitleButtonRect()` 获取三键区位置做避让
- 提到使用 `on('windowTitleButtonRectChange')` 监听三键区变化
- 说明此方案仅适用于自由多窗模式

**应包含**：setWindowDecorVisible, setWindowDecorHeight, getTitleButtonRect, windowTitleButtonRectChange
**格式**：markdown

---

### 测试用例：FUNC-007

**skill**：hmos-window-immersive（必填）
**类型**：functional（功能验证）

#### 输入

我的应用有挖孔屏，页面内容被挖孔挡住了，需要对挖孔区域做避让处理

#### 预期输出

**验证标准**：

- 使用 `AvoidAreaType.TYPE_CUTOUT` 获取挖孔区域
- 提到挖孔方位可能随设备旋转变化（顶部/左侧/右侧/底部）
- 提供挖孔方位计算的逻辑（如顶部挖孔 = topRect.height + topRect.top）
- 使用 `on('avoidAreaChange')` 动态监听挖孔区变化
- 使用 padding 进行避让

**应包含**：TYPE_CUTOUT, avoidAreaChange, topRect, leftRect, rightRect, bottomRect
**格式**：markdown

---

### 测试用例：FUNC-008

**skill**：hmos-window-immersive（必填）
**类型**：functional（功能验证）

#### 输入

帮我列出鸿蒙应用沉浸式的几种方案以及各自的优缺点

#### 预期输出

**验证标准**：

- 列出 3 种方案：组件页面沉浸、安全区域拓展、窗口沉浸式显示
- 提到方案 A 核心是 `.ignoreLayoutSafeArea()`，方案 B 核心是 `.expandSafeArea()`，方案 C 核心是 `setWindowLayoutFullScreen()`
- 提到组件级方案需每个页面单独配置，窗口级方案全局生效
- 提到方案 A 和 C 需手动避让，方案 B 内容在安全区无需避让

**应包含**：ignoreLayoutSafeArea, expandSafeArea, setWindowLayoutFullScreen
**格式**：markdown
