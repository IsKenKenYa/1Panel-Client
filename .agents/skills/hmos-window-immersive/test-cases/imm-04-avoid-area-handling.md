# 测试用例 4：安全区域避让处理（avoidArea 查询/监听/挖孔避让）

## 场景描述
开发者使用窗口级沉浸式方案（setWindowLayoutFullScreen）后，页面内容与状态栏/底部导航区域重叠，需查询避让区高度并动态监听变化做 padding 避让。同时设备有挖孔屏，需对挖孔区域做避让处理。

## 前置条件
- 应用已调用 setWindowLayoutFullScreen(true) 设置沉浸式布局
- 设备有挖孔/刘海屏
- 页面内容需避让状态栏、底部导航区域和挖孔区

## 执行步骤
1. AI 代理识别"避让""avoidArea""挖孔"需求，路由至场景 IMM-04，读取 imm-04-avoid-area-handling.md
2. 查询避让区：AI 代理给出 getWindowAvoidArea(AvoidAreaType.TYPE_SYSTEM) 和 getWindowAvoidArea(AvoidAreaType.TYPE_NAVIGATION_INDICATOR) 获取状态栏和底部导航区域高度
3. 监听变化：AI 代理给出 on('avoidAreaChange') 监听代码，并说明 off 需成对调用
4. 挖孔避让：AI 代理给出 getWindowAvoidArea(AvoidAreaType.TYPE_CUTOUT) 获取挖孔区，并根据挖孔方位（顶部/左侧/右侧/底部）计算 padding
5. 布局避让：AI 代理给出 padding 代码，避让区值通过 getUIContext().px2vp() 转换为 vp

## 预期结果
- 使用 getWindowAvoidArea 查询避让区，传入正确的 AvoidAreaType 枚举
- 使用 on('avoidAreaChange') 动态监听，并提到 off 成对注销
- 避让区返回值为 px，布局中使用 px2vp() 转换
- 挖孔避让根据方位（topRect/leftRect/rightRect/bottomRect）计算 padding
- 提到避让区可能为 0，需针对性处理

## 验证方法
- 检查输出是否包含 getWindowAvoidArea 和 AvoidAreaType.TYPE_SYSTEM / TYPE_NAVIGATION_INDICATOR / TYPE_CUTOUT
- 检查是否使用 on('avoidAreaChange') 监听并提到 off 成对调用
- 检查避让区值是否通过 px2vp() 转换后再用于布局
- 检查挖孔方位计算是否区分 topRect/leftRect/rightRect/bottomRect
- 检查是否提到避让区可能为 0 的情况

## 备注
常见错误：直接使用 avoidArea 返回的 px 值用于 padding 而不经过 px2vp 转换，导致避让距离不正确。另一个常见错误是忘记 on/off 成对调用导致内存泄漏。
