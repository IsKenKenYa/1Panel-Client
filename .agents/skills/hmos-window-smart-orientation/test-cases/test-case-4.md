# 测试用例 4：锁定当前显示方向（屏幕方向与窗口方向互转）

## 场景描述
视频播放页等场景需要锁定窗口当前实际显示方向，开发者尝试直接用 display.orientation 判断方向，需验证技能能否纠正概念混淆并给出 convertOrientationAndRotation 四步法。

## 前置条件
- 应用主窗口已获取（windowStage.getMainWindowSync()）
- 已 import { display, window } from '@kit.ArkUI'

## 执行步骤
1. AI 代理识别"锁定当前方向"需求，路由至场景 ROT-04（方向互转）
2. AI 代理纠正概念：屏幕 orientation（逻辑横竖状态）、屏幕 rotation（物理角度）、窗口 orientation 是三个不同概念，多设备形态（折叠屏、平板、外接显示器）下并非一一对应，直接用 display.orientation/rotation 判断窗口方向会导致显示方向错位
3. AI 代理给出四步法：
   - display.getDefaultDisplaySync().orientation 获取屏幕方向
   - mainWindow.convertOrientationAndRotation(window.RotationInfoType.DISPLAY_ORIENTATION, window.RotationInfoType.WINDOW_ORIENTATION, displayOrientation) 转为窗口方向数字
   - 数字映射 window.Orientation 枚举：0→PORTRAIT、1→LANDSCAPE_INVERTED、2→PORTRAIT_INVERTED、3→LANDSCAPE
   - mainWindow.setPreferredOrientation(orientation) 锁定
4. AI 代理提示数字编码与枚举值不同（枚举值 1 竖 / 2 横 / 3 反竖 / 4 反横）

## 预期结果
- 明确指出不能直接用 display.orientation/rotation 判断窗口方向
- 使用 convertOrientationAndRotation 接口（API 23+）完成换算
- 数字到枚举的映射关系正确（重点验证 1→LANDSCAPE_INVERTED、3→LANDSCAPE，与直觉相反）
- 最终通过 setPreferredOrientation 锁定方向

## 验证方法
- 检查输出是否包含 convertOrientationAndRotation、DISPLAY_ORIENTATION、WINDOW_ORIENTATION
- 检查映射表是否正确：0 竖屏 / 1 反向横屏 / 2 反向竖屏 / 3 横屏
- 检查是否包含直板机屏幕角度/屏幕方向/窗口方向对应关系说明（0/PORTRAIT/PORTRAIT、90/LANDSCAPE/LANDSCAPE_INVERTED 等）
- 检查是否提示旋转后布局适配应基于 on('windowSizeChange') 而非屏幕 Orientation

## 备注
数字编码与枚举值混淆是最常见的接入错误（窗口方向数字 1 是反向横屏，而 Orientation 枚举值 1 是竖屏），本用例重点验证这一易错点。
