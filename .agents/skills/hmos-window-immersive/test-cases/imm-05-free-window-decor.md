# 测试用例 5：自由窗口标题栏沉浸

## 场景描述
平板/折叠屏设备在自由多窗模式下运行应用，开发者需要隐藏默认窗口标题栏（应用图标、应用名称），仅保留右上角三键区（关闭、最小化、最大化），使页面延伸至原标题栏区域，并对三键区做布局避让。

## 前置条件
- 应用运行在 PC 设备或平板/折叠屏的自由多窗模式下
- 应用主窗口已获取（windowStage.getMainWindowSync()）
- 非全屏模式（自由窗口模式）

## 执行步骤
1. AI 代理识别"自由窗口标题栏""隐藏标题栏"需求，路由至场景 IMM-05，读取 imm-05-practical-cases.md
2. 隐藏标题栏：AI 代理给出 setWindowDecorVisible(false) 隐藏标题栏，仅保留三键区
3. 设置标题栏高度：AI 代理给出 setWindowDecorHeight(56) 控制三键区显示高度
4. 设置三键样式：AI 代理给出 setDecorButtonStyle({ buttonIconSize: 24 }) 调整样式
5. 获取三键区位置：AI 代理给出 getTitleButtonRect() 获取三键区位置和大小
6. 监听三键区变化：AI 代理给出 on('windowTitleButtonRectChange') 监听
7. 布局避让：AI 代理给出 padding 代码，右侧 padding 避让三键区宽度

## 预期结果
- 使用 setWindowDecorVisible(false) 隐藏标题栏（而非 setWindowLayoutFullScreen）
- 使用 setWindowDecorHeight() 设置标题栏高度
- 使用 getTitleButtonRect() 或 on('windowTitleButtonRectChange') 获取三键区位置
- 布局中使用 padding 避让三键区宽度
- 明确说明此方案仅适用于自由多窗模式，不适用于手机全屏模式
- 明确说明组件沉浸策略（expandSafeArea 等）不适用于此场景

## 验证方法
- 检查输出是否包含 setWindowDecorVisible(false)
- 检查是否使用 setWindowDecorHeight 设置标题栏高度
- 检查是否使用 getTitleButtonRect 或 on('windowTitleButtonRectChange') 获取三键区位置
- 检查布局是否对三键区做 padding 避让
- 检查是否说明仅适用于自由多窗模式
- 检查是否说明组件沉浸策略不适用此场景

## 备注
常见错误：在自由窗口标题栏场景使用 expandSafeArea 或 setWindowLayoutFullScreen，这些组件级/窗口级沉浸策略不适用于自由窗口标题栏，需使用 setWindowDecorVisible 等专用接口单独适配。
