# 测试提示词

## 基础功能测试
### 测试场景 1：沉浸式背景延伸（上下不同色）
**提示词**：页面顶部蓝色、底部颜色不同，想分别延伸到状态栏和导航条
**预期输出**：
- 推荐使用 `.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP/BOTTOM])` 方案
- 顶部和底部组件分别设置不同的 SafeAreaEdge

### 测试场景 2：视频全屏沉浸（隐藏系统栏）
**提示词**：做一个视频播放页面，进入全屏播放时隐藏状态栏和导航条，退出时恢复显示
**预期输出**：
- 使用 `setSpecificSystemBarEnabled` 隐藏系统栏（无需 `setWindowLayoutFullScreen`）
- 退出时恢复显示
- 包含错误处理

## 边界条件测试
### 测试场景 3：滚动容器沉浸
**提示词**：我的页面是滚动列表，想实现沉浸式效果让背景延伸到状态栏和导航条
**预期输出**：
- 提到滚动容器中子组件 expandSafeArea 无效
- 提供两种解决方案（父容器 expandSafeArea 或 clipContent）

### 测试场景 4：挖孔区避让
**提示词**：我的应用有挖孔屏，页面内容被挖孔挡住了，怎么避让？
**预期输出**：
- 使用 `AvoidAreaType.TYPE_CUTOUT` 获取挖孔区域
- 提供挖孔方位计算逻辑
- 使用动态监听和 padding 避让

## 错误处理测试
### 测试场景 5：避让区动态监听
**提示词**：如何获取状态栏和导航条的高度做避让处理？需要支持窗口旋转后动态更新
**预期输出**：
- 使用 `getWindowAvoidArea` 查询 + `on('avoidAreaChange')` 监听
- 避让区值用 `px2vp()` 转换
- on/off 成对调用

### 测试场景 6：自由窗口标题栏沉浸
**提示词**：平板自由多窗模式下，如何隐藏窗口标题栏只保留三键？
**预期输出**：
- 使用 `setWindowDecorVisible(false)` 隐藏标题栏
- 使用 `getTitleButtonRect()` 获取三键区做避让
- 说明仅适用于自由多窗模式
