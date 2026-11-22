# 测试提示词

## 基础功能测试

### 测试场景 1：智感旋转机制咨询与接入指引

**提示词**：
```
什么是智感旋转？我的鸿蒙应用想支持智感旋转，需要怎么接入？要新加权限或者接口吗？
```

**预期输出**：
- 解释智感旋转机制：OpenHarmony 7.0.0 及以上版本且支持智感传感器的设备，用户通过「设置 > 系统 > 智感旋转」开启开关后，应用最终显示方向由重力传感器和智感传感器共同作用决定
- 明确零新增 API、零新增权限：设置自动旋转类策略（AUTO_ROTATION 系列 7 种 / USER_ROTATION 系列 4 种）、FOLLOW_DESKTOP 或默认 UNSPECIFIED 即可参与智感旋转
- 指出固定方向策略（PORTRAIT/LANDSCAPE 等）不参与智感旋转
- 给出至少一种设置示例（运行时 setPreferredOrientation 或 module.json5 orientation 静态配置）
- 说明设备/系统不支持或开关关闭时自动回退为纯重力传感器旋转

### 测试场景 2：运行时设置自动旋转策略

**提示词**：
```
帮我在 Ability 创建窗口的时候把主窗口设置成跟随传感器自动旋转，要能受控制中心旋转锁定开关控制。
```

**预期输出**：
- 在 onWindowStageCreate 中通过 windowStage.getMainWindowSync() 获取主窗口
- 调用 setPreferredOrientation(window.Orientation.AUTO_ROTATION_RESTRICTED)
- 说明仅主窗口支持旋转策略
- 包含 try-catch 或 Promise catch 捕获 BusinessError 的错误处理

### 测试场景 3：module.json5 静态配置旋转策略

**提示词**：
```
我不想写代码，能不能在配置文件里直接让应用启动就是自动旋转？
```

**预期输出**：
- 在 module.json5 的 abilities 标签配置 "orientation": "auto_rotation_restricted"
- 说明取值与 window.Orientation 枚举一一对应（小写蛇形命名），默认 "unspecified"
- 说明运行时 setPreferredOrientation 可覆盖静态配置
- 说明静态配置同样受行为限制约束（仅主窗口、特殊场景被忽略）

### 测试场景 4：视频应用横竖屏切换

**提示词**：
```
视频类应用，详情页竖屏显示，点击全屏按钮要立刻转横屏，退出全屏恢复竖屏跟随，怎么实现？
```

**预期输出**：
- 进全屏：setPreferredOrientation(window.Orientation.USER_ROTATION_LANDSCAPE)，调用时立即临时旋转到横屏，之后跟随传感器自动旋转（OH 7.0.0+ 参与智感旋转）
- 退出全屏：恢复 AUTO_ROTATION_PORTRAIT_RESTRICTED（或 PORTRAIT）
- 说明 USER_ROTATION 系列与 AUTO_ROTATION_RESTRICTED 的区别（调用时立即临时旋转）

## 边界条件测试

### 测试场景 5：直板机自动旋转且可锁定当前方向

**提示词**：
```
直板机上我的应用想自动旋转，但用户下拉开启旋转锁定后要能锁在当前方向，包括横屏。用哪个策略？
```

**预期输出**：
- 推荐 USER_ROTATION 系列（USER_ROTATION_PORTRAIT / USER_ROTATION_LANDSCAPE 等）
- 解释 AUTO_ROTATION_RESTRICTED 和 AUTO_ROTATION_UNSPECIFIED 在直板机/类直板机形态不支持锁定横屏，开启旋转锁定时会被强制旋转回竖屏
- 说明 USER_ROTATION_PORTRAIT_INVERTED 在直板机上无法临时旋转为反向竖屏

### 测试场景 6：锁定当前显示方向（屏幕方向与窗口方向互转）

**提示词**：
```
视频播放页想锁定当前实际显示的方向，听说不能直接用 display.orientation 判断，正确做法是什么？
```

**预期输出**：
- 说明屏幕 orientation/rotation 与窗口 orientation 是不同概念，多设备形态下并非一一对应，不能直接判断
- 给出四步法：display.getDefaultDisplaySync() 获取屏幕方向 → convertOrientationAndRotation(DISPLAY_ORIENTATION, WINDOW_ORIENTATION, ...) 转为窗口方向数字 → 数字映射 window.Orientation 枚举（0 竖屏 / 1 反向横屏 / 2 反向竖屏 / 3 横屏）→ setPreferredOrientation 锁定
- 提示窗口方向数字编码与 Orientation 枚举值不同（枚举值 1 竖 / 2 横 / 3 反竖 / 4 反横）

### 测试场景 7：特殊场景下策略不生效

**提示词**：
```
我在分屏里调用 setPreferredOrientation(window.Orientation.LANDSCAPE)，接口调用成功但方向没变，也没报错，为什么？
```

**预期输出**：
- 解释分屏、智慧多窗悬浮窗、自由多窗、多任务、后台等场景系统忽略旋转策略，接口正常调用但方向不变
- 提及 setPreferredOrientationWithResult（API 26+）返回 ORIENTATION_IGNORED 可确认被忽略
- 说明退出该场景后系统按应用设置的策略重新调整显示布局

## 错误处理测试

### 测试场景 8：智感旋转不生效排查

**提示词**：
```
我设置了 AUTO_ROTATION_RESTRICTED，但在设备上智感旋转没生效，帮我排查一下。
```

**预期输出**：
- 输出排查清单：系统版本是否 OpenHarmony 7.0.0+、设备是否支持智感传感器、「设置 > 系统 > 智感旋转」开关是否开启、应用策略是否为自动旋转类、是否处于分屏/悬浮窗/自由多窗/后台等被忽略场景、设备是否有重力传感器（TV 等不生效）
- 说明旋转锁定开关打开时 RESTRICTED 类策略不跟随传感器属预期行为
- 说明开关关闭或设备不支持时回退纯重力传感器旋转，功能正常不算故障

### 测试场景 9：接口错误码处理

**提示词**：
```
setPreferredOrientation 报 1300002 错误，convertOrientationAndRotation 传 4 报 401，分别是什么问题？
```

**预期输出**：
- 1300002：窗口状态异常（窗口未创建或已销毁），检查窗口生命周期
- 401：参数错误，convertOrientationAndRotation 的 value 取值范围 [0, 3]，越界抛 401
- 建议统一用 try-catch / Promise catch 捕获 BusinessError 并记录 code 与 message

### 测试场景 10：扫描项目并改造固定策略

**提示词**：
```
扫描我的项目，把所有固定横竖屏的配置改成能支持智感旋转的策略，改完告诉我改了哪些。
```

**预期输出**：
- 执行扫描：module.json5 的 "orientation" 字段 + *.ets/*.ts 中 setPreferredOrientation 调用
- 输出扫描清单报告（文件位置、当前策略、分类、改造建议）
- 按映射表改造：portrait → auto_rotation_portrait_restricted（或评估后选 auto_rotation_restricted 四方向）、landscape → auto_rotation_landscape_restricted、视频全屏 landscape → USER_ROTATION_LANDSCAPE 等
- 评估提醒：游戏等必须固定方向的保持不变；改造后方向会动态变化，布局需响应式适配
- 给出验证清单（智感设备、回退设备、旋转锁定开关、特殊场景）
