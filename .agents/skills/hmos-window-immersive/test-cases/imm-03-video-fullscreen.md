# 测试用例 3：视频全屏沉浸（隐藏系统栏与恢复）

## 场景描述
视频类应用播放页默认显示状态栏和导航条，用户点击全屏按钮需隐藏状态栏和导航条进入沉浸式全屏播放，退出全屏后恢复显示。需给出完整实现方案。

## 前置条件
- 应用主窗口已加载视频播放页
- 播放页有全屏/退出全屏按钮触发点
- 应用已获取主窗口实例（windowStage.getMainWindowSync()）

## 执行步骤
1. AI 代理识别"视频全屏""隐藏状态栏"需求，路由至场景 IMM-03，读取 imm-03-window-immersive.md
2. 进入全屏：AI 代理给出 `setSpecificSystemBarEnabled('status', false)` + `setSpecificSystemBarEnabled('navigationIndicator', false)`（无需 setWindowLayoutFullScreen）
3. 退出全屏：AI 代理给出恢复代码 `setSpecificSystemBarEnabled('status', true)` + `setSpecificSystemBarEnabled('navigationIndicator', true)`
4. AI 代理说明用户可通过从底部上滑唤出导航条或三键导航
5. AI 代理提示代码需包含 Promise 错误处理（catch / try-catch），捕获 BusinessError

## 预期结果
- 进入全屏仅使用 setSpecificSystemBarEnabled 隐藏系统栏，无需 setWindowLayoutFullScreen
- 隐藏系统栏使用 setSpecificSystemBarEnabled，参数名正确（'status'、'navigationIndicator'）
- 退出全屏恢复显示的代码完整
- 代码包含 Promise 错误处理（catch 或 try-catch）
- 说明用户可通过底部上滑唤出系统栏

## 验证方法
- 检查输出不包含 setWindowLayoutFullScreen（视频全屏场景无需调用）
- 检查 setSpecificSystemBarEnabled 参数是否为 'status' 和 'navigationIndicator'（非 'navigation'）
- 检查退出全屏是否恢复 setSpecificSystemBarEnabled(..., true)
- 检查代码是否包含 BusinessError 捕获
- 检查是否提到用户可上滑唤出系统栏

## 备注
常见错误：使用 setWindowSystemBarEnable([]) 批量隐藏而非 setSpecificSystemBarEnabled 精细控制。两种方式均可，但 setSpecificSystemBarEnabled（API 11+）更精细，推荐用于需独立控制状态栏和导航条的场景。
