# 测试提示词

## 基础功能测试

### 测试场景 1：悬停态机制咨询与接入

**提示词**：
```
折叠屏上把手机半折叠架起来（笔记本形态）的时候，我的应用想上半屏播视频、下半屏放控制条，需要监听什么接口？要新加权限吗？
```

**预期输出**：
- 解释悬停态机制：设备半折叠（HALF_FOLD）且折痕横向、应用全屏窗口满足系统判定条件时，窗口进入 `WindowPostureMode.DESKTOP_MODE` 姿态模式，无需新增权限
- 给出核心接入三件套：`win.onWindowPostureModeChange(WindowPostureMode.DESKTOP_MODE, callback)` 注册监听、`win.isInWindowPostureMode` 进页面初始查询、`@State isInHover` 单状态源驱动布局
- 强调这是 window 实例方法而非泛型 on 事件，注册时必须传 `WindowPostureMode.DESKTOP_MODE`
- 提醒先核验目标 SDK 的 `@ohos.window.d.ts` 是否声明该组 API，未声明走降级方案

### 测试场景 2：视频播放器悬停布局

**提示词**：
```
我的视频播放页想在折叠屏悬停态做适配：上半屏播放视频，下半屏放播放控制，折痕处不要放按钮也不要被视频压住，怎么设计布局？
```

**预期输出**：
- 给出三段式几何：视频高度封顶折痕区域上沿（`contentHeight = creaseTop`，严格不进折痕区域）、避让带 `max(creaseHeight / 2 + 16, 16)`vp（带内不放交互/文字）、操作区占剩余高度
- 下半屏做固定操作坞：控制元素一次全部呈现、不做上下滚动，仅选集等卡片横向滚动，底部 padding 叠加导航条高度
- 折痕区域用 `display.getDefaultDisplaySync().getLiveCreaseRegion()`（API 20+）优先、`getCurrentFoldCreaseRegion()`（API 10+）降级、屏幕中线兜底
- px 转 vp 是除以 `densityPixels`

### 测试场景 3：相机悬停拍摄

**提示词**：
```
做悬停拍照功能：手机半折叠架着自拍，上半屏取景器，下半屏快门和模式切换，进入悬停的时候怎么切换布局才不会导致预览黑屏？
```

**预期输出**：
- 取景器 XComponent/Surface 不放进悬停 if/else 分支重建，同一渲染节点仅改布局参数（高度/权重），避免销毁重建导致闪黑
- 快门等主按钮在下半屏加大（近水平视角人机工学），交互元素避开折痕区域
- 进入悬停可提示"设备已放稳，触控或定时拍摄"；回调内只切状态不做重活

### 测试场景 4：存量页面适配悬停态

**提示词**：
```
我有一个已经上线的播放页，现在要适配悬停态，直接在 build 里加 if(isInHover) 分支可以吗？要注意什么？
```

**预期输出**：
- 先审计再动手：结构切分点（内容区/操作区边界）、不可重建节点（Video/XComponent 不进 if/else 分支）、既有布局状态融合（`isHoverLayout()` 作为唯一出口函数）、生命周期合并（监听并入已有 aboutToAppear/Disappear，不整体覆盖）、系统栏回归（加 expandSafeArea 后必须补手动避让）
- 悬停是叠加态：适配后原有形态行为必须不变，悬停进出不影响用户已有偏好（如全屏状态位）

## 边界条件测试

### 测试场景 5：横屏窗口下的悬停

**提示词**：
```
书本型折叠屏（Mate X 那种）半折叠悬停的时候窗口是横屏的，我的悬停布局要不要加 isLandscape 判断？旋转和悬停谁优先？
```

**预期输出**：
- 明确悬停布局优先级最高且与窗口方向无关：书本型设备悬停通常出现在横屏窗口（DESKTOP_MODE 要求折痕横向），用 `isInHover && !isLandscape` 守卫会导致横屏悬停布局永不切换（真机反模式）
- 悬停布局由折痕坐标锚定（crease.top 在任何窗口方向下都是折痕上沿），上下分区适用任意方向
- 组合状态（isInHover × isLandscape）只用于选择布局形态，不得用于否定系统悬停状态

### 测试场景 6：SDK 未声明悬停 API 的降级

**提示词**：
```
我的工程用的 SDK 里搜不到 onWindowPostureModeChange，是不是就没法做悬停适配了？
```

**预期输出**：
- 给出降级方案：`display.getFoldStatus() === FoldStatus.FOLD_STATUS_HALF_FOLDED` + 全屏自查（`windowSizeChange` 回调里复核窗口仍全屏，非全屏强制清除悬停状态）推断悬停态
- 说明降级路径差异：仅凭折叠状态可能误判（非全屏窗口误进、LS 态抑制感知不到），接受误差并告知用户风险
- 建议在 aboutToAppear 启动时用 `getFoldStatus()` 查询初始状态

### 测试场景 7：初始状态与回调时序

**提示词**：
```
应用启动的时候手机已经是半折叠悬停形态了，监听还没注册上，布局怎么知道当前在悬停态？还有回调会不会重复收到一样的值？
```

**预期输出**：
- 进页面先调 `isInWindowPostureMode(WindowPostureMode.DESKTOP_MODE)` 初始查询，再注册 onWindowPostureModeChange 监听，补齐"启动时已悬停"场景
- 回调做状态幂等（同值直接 return），不依赖系统去重
- 旋转与折叠同时发生时 windowSizeChange 与 postureModeChange 到达顺序不保证：状态各自独立更新、以终态组合渲染，不做中间态特判

## 错误处理测试

### 测试场景 8：悬停回调不触发排查

**提示词**：
```
真机上半折叠架起来了，但我的 onWindowPostureModeChange 回调一直没触发，帮我排查一下原因。
```

**预期输出**：
- 输出排查清单：窗口是否全屏（分屏/悬浮/自由窗口不进入悬停态）、设备是否折叠屏、折痕是否横向（书本型竖屏半折叠不触发，属预期行为）、是否分离架构（路径恒返回 false）、目标 SDK 是否声明该 API、注册时是否传了 `WindowPostureMode.DESKTOP_MODE`
- 明确竖屏半折叠（书本形态、折痕纵向）系统不进入悬停态是预期行为，应用侧不要自行推断"左右分区悬停"与系统判定打架
- 应用侧只消费状态，不要用 hidumper 等手段反向改系统判定来"凑"悬停态

### 测试场景 9：悬停操作区压折痕/压导航条

**提示词**：
```
悬停态下我的操作按钮有的压在折痕上，有的被导航条挡住一截，还有个状态徽标挡住了轮播图的手势，怎么修？
```

**预期输出**：
- 操作区严格从折痕中心线下方 16vp 开始（避让带公式 `max(折痕高/2 + 16, 16)`），固定操作坞内容做减法（砍冗余行）保证不溢出
- 指出固定高度 Column 子项溢出会穿过底部 padding 渲染到屏幕边缘（padding 不是裁剪边界），底部安全距离 = 内容不溢出 + padding 叠加 `getWindowAvoidArea(TYPE_NAVIGATION_INDICATOR)` 实测高度
- 避让高度必须随 `on('avoidAreaChange')` 动态刷新（旋转/折叠/悬停切换都会改变避让区，一次性查询会过期）
- HUD/徽标用 position 定位的小容器叠加，不要全高透明层（会拦截底下 Swiper/Video 的手势）

### 测试场景 10：监听泄漏与错误码处理

**提示词**：
```
悬停监听要怎么注销？接口报 401 和 1300002 分别是什么问题？
```

**预期输出**：
- `offWindowPostureModeChange` 与注册成对调用，在 aboutToDisappear 清理，页面栈返回复用时确认监听仍有效
- 401：参数错误（如注册时未传 mode 或传错枚举）；1300002：窗口状态异常（窗口未创建或已销毁，检查窗口生命周期与 getLastWindow 获取时机）
- 统一 try-catch / Promise catch 捕获 BusinessError 并记录 code 与 message；获取窗口须经 `this.getUIContext().getHostContext()` 上下文
