# 功能性测试用例

---

### 测试用例：FUNC-001

**skill**：hmos-window-smart-orientation
**类型**：functional（功能验证）

#### 输入

什么是智感旋转？我的鸿蒙应用想支持智感旋转，需要怎么接入？要新加权限或者接口吗？

#### 预期输出

**验证标准**：

- 说明智感旋转机制：OpenHarmony 7.0.0 及以上版本且支持智感传感器的设备，用户通过「设置 > 系统 > 智感旋转」开启开关，应用最终显示方向由重力传感器和智感传感器共同作用决定
- 明确零新增 API、零新增权限，自动旋转类策略（AUTO_ROTATION 系列 / USER_ROTATION 系列）、FOLLOW_DESKTOP 或默认 UNSPECIFIED 均可参与智感旋转
- 明确固定方向策略（PORTRAIT/LANDSCAPE/PORTRAIT_INVERTED/LANDSCAPE_INVERTED）不参与智感旋转
- 给出至少一种设置示例（setPreferredOrientation 运行时调用或 module.json5 orientation 静态配置）
- 说明设备/系统不支持或开关未开启时自动回退为纯重力传感器旋转

**应包含**：智感旋转, 智感传感器, AUTO_ROTATION

---

### 测试用例：FUNC-002

**skill**：hmos-window-smart-orientation
**类型**：functional（功能验证）

#### 输入

我不想写代码，能不能在 module.json5 里直接配置应用启动就是自动旋转？

#### 预期输出

**验证标准**：

- 指出在 module.json5 的 abilities 标签配置 "orientation" 字段
- 示例取值正确（如 "auto_rotation_restricted"），说明取值与 window.Orientation 枚举一一对应、小写蛇形命名、默认 "unspecified"

**应包含**：abilities, orientation, auto_rotation_restricted

---

### 测试用例：FUNC-003

**skill**：hmos-window-smart-orientation
**类型**：functional（功能验证）

#### 输入

视频应用详情页竖屏显示，点击全屏按钮要立刻转横屏，退出全屏恢复竖屏跟随，怎么实现？

#### 预期输出

**验证标准**：

- 进全屏使用 USER_ROTATION_LANDSCAPE（调用时立即临时旋转到横屏，之后跟随传感器，OH 7.0.0+ 参与智感旋转），而非 LANDSCAPE 锁死方向
- 退出全屏恢复 AUTO_ROTATION_PORTRAIT_RESTRICTED 或 PORTRAIT
- 说明 USER_ROTATION 系列与 AUTO_ROTATION_RESTRICTED 的区别（调用时立即临时旋转）
- 代码仅对主窗口调用，包含 BusinessError 错误处理

**应包含**：USER_ROTATION_LANDSCAPE, setPreferredOrientation

---

### 测试用例：FUNC-004

**skill**：hmos-window-smart-orientation
**类型**：functional（功能验证）

#### 输入

视频播放页想锁定当前实际显示的方向，直接用 display.orientation 判断可以吗？

#### 预期输出

**验证标准**：

- 明确指出不能直接用 display.orientation / display.rotation 判断窗口方向（与窗口 orientation 是不同概念，多设备形态下并非一一对应）
- 使用 convertOrientationAndRotation(DISPLAY_ORIENTATION, WINDOW_ORIENTATION, ...) 完成屏幕方向到窗口方向的换算
- 数字到枚举映射正确：0→PORTRAIT、1→LANDSCAPE_INVERTED、2→PORTRAIT_INVERTED、3→LANDSCAPE
- 最终通过 setPreferredOrientation 锁定方向
- 提示窗口方向数字编码与 Orientation 枚举值不同

**应包含**：convertOrientationAndRotation, DISPLAY_ORIENTATION, WINDOW_ORIENTATION

---

### 测试用例：FUNC-005

**skill**：hmos-window-smart-orientation
**类型**：functional（功能验证）

#### 输入

扫描我的项目，把固定横竖屏配置全部改成支持智感旋转的策略，并输出改造清单。

#### 预期输出

**验证标准**：

- 扫描覆盖两个来源：module.json5 的 "orientation" 字段与 *.ets/*.ts 中的 setPreferredOrientation 调用
- 输出扫描清单报告，包含每项的位置（文件:行号）、当前策略、分类、改造建议
- 改造映射符合 migrate-to-smart-rotation.md 映射表：portrait → auto_rotation_portrait_restricted（竖向跟随；评估为不限方向时可选 auto_rotation_restricted）、landscape → auto_rotation_landscape_restricted、视频全屏 landscape → USER_ROTATION_LANDSCAPE
- 包含评估环节：必须固定方向的场景（游戏/取景器）保持不变；提醒布局需响应式适配
- 给出验证清单：智感设备、回退设备、旋转锁定开关、分屏等特殊场景

**应包含**：auto_rotation_portrait_restricted, USER_ROTATION_LANDSCAPE
**格式**：markdown

---

### 测试用例：FUNC-006

**skill**：hmos-window-smart-orientation
**类型**：functional（功能验证）

#### 输入

直板机上应用想自动旋转，用户开旋转锁定后要能锁住当前方向（含横屏），选哪个策略？

#### 预期输出

**验证标准**：

- 推荐 USER_ROTATION 系列（USER_ROTATION_PORTRAIT / USER_ROTATION_LANDSCAPE 等）
- 解释 AUTO_ROTATION_RESTRICTED 与 AUTO_ROTATION_UNSPECIFIED 在直板机/类直板机形态不支持锁定横屏，开启旋转锁定时会被强制旋转回竖屏
- 说明 USER_ROTATION_PORTRAIT_INVERTED 在直板机上无法临时旋转为反向竖屏

**应包含**：USER_ROTATION
