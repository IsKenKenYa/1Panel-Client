# 测试用例 3：视频类应用横竖屏切换

## 场景描述
视频类应用播放页默认竖屏显示，用户点击全屏按钮需立即切换到横屏，退出全屏后恢复竖屏方向跟随，需给出完整实现方案。

## 前置条件
- 应用主窗口已加载视频播放页
- 播放页有全屏/退出全屏按钮触发点

## 执行步骤
1. AI 代理识别"视频全屏横竖屏切换"需求，路由至场景 ROT-04
2. 进入全屏：调用 mainWindow.setPreferredOrientation(window.Orientation.USER_ROTATION_LANDSCAPE)，立即临时旋转到横屏，之后跟随传感器自动旋转（OH 7.0.0+ 参与智感旋转）
3. 退出全屏：调用 mainWindow.setPreferredOrientation(window.Orientation.AUTO_ROTATION_PORTRAIT_RESTRICTED)（或 PORTRAIT），恢复竖向跟随
4. AI 代理说明 USER_ROTATION 系列与 AUTO_ROTATION_RESTRICTED 的区别：前者调用时立即临时旋转到指定方向
5. AI 代理提示：仅主窗口支持；若应用处于分屏/悬浮窗等场景策略被忽略属预期

## 预期结果
- 进入全屏使用 USER_ROTATION_LANDSCAPE（而非 LANDSCAPE 锁死方向）
- 退出全屏恢复自动旋转类策略
- 说明两种方式备选：运行时设置接口（推荐）或页面跳转配置不同方向
- 代码包含错误处理，且仅对主窗口调用

## 验证方法
- 检查输出是否包含 USER_ROTATION_LANDSCAPE 与 setPreferredOrientation
- 检查退出全屏是否恢复 AUTO_ROTATION_PORTRAIT_RESTRICTED 或 PORTRAIT
- 检查是否说明 USER_ROTATION 的"临时旋转后自动跟随"语义
- 检查是否说明 OH 7.0.0+ 设备上该策略参与智感旋转

## 备注
用 LANDSCAPE 固定横屏实现全屏是常见错误做法：会丧失传感器跟随能力，也无法体验智感旋转。若开发者初版方案使用 LANDSCAPE，AI 代理应主动纠正。
