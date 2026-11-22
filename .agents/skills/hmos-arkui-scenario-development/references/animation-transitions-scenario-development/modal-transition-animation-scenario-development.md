# 模态转场动画案例集

## 适用场景

| 场景 | 推荐方案 | 选型理由 |
|---|---|---|
| 分享面板/城市选择 | `bindSheet` 半模态 | 系统自动处理弹出动画；`dragBar: true` 支持拖拽关闭 |
| 全屏登录/详情覆盖 | `bindContentCover` + `TransitionEffect` | 全屏覆盖 + 自定义转场效果复用 |
| 文件操作菜单 | `bindMenu` + `MenuElement[]` | 最简方案，无需管理显隐状态 |
| 长按图标/图片菜单 | `bindContextMenu` + `@Builder` | 系统自动处理长按触发；自定义 Builder 灵活定制 |
| 深色下拉菜单 | `bindPopup` 自定义 Builder | 需要精确控制箭头位置和背景色 |
| 登录↔注册交叉切换 | `if` 条件渲染 + `TransitionEffect` + `setTimeout` | 内部切换时保持模态，仅内容交叉淡入淡出 |

## 核心动画 API 枚举值参考

### ModalTransition 模态转场枚举值

| 枚举值 | 说明 | 典型场景 |
|---|---|---|
| `ModalTransition.DEFAULT` | 系统默认转场（上滑进入/下滑退出） | 常规模态弹窗 |
| `ModalTransition.NONE` | 禁用系统模态动画 | 共享元素一镜到底（仅保留 `geometryTransition`） |
| `ModalTransition.ALPHA` | 透明度淡入淡出 | 纯淡入淡出模态 |

### TransitionEffect 静态方法（模态转场常用）

| 方法 | 说明 | 典型场景 |
|---|---|---|
| `TransitionEffect.OPACITY` | 透明度转场 | 全屏模态登录淡入淡出 |
| `TransitionEffect.opacity(value)` | 自定义透明度起始值 | 模态从 0.4 透明度过渡 |
| `TransitionEffect.translate(offset)` | 平移转场 | 登录页从底部滑入、注册页从右侧滑入 |
| `TransitionEffect.scale(scale)` | 缩放转场 | 注册页 0.95 放大到 1 增加纵深 |
| `.combine(effect)` | 组合转场效果 | OPACITY + translate + scale 联动 |
| `.animation(params)` | 附加动画参数 | 设置 duration/curve/delay |
| `TransitionEffect.asymmetric(enter, exit)` | 非对称转场 | 进入有 delay，退出无 delay |

### bindSheet 常用参数

| 参数 | 类型 | 说明 |
|---|---|---|
| `height` | number | 半模态面板高度（vp） |
| `dragBar` | boolean | 是否显示拖拽条 |
| `showClose` | boolean | 是否显示关闭按钮 |
| `onDisappear` | () => void | 面板消失回调 |

### bindContentCover 常用参数

| 参数 | 类型 | 说明 |
|---|---|---|
| `modalTransition` | ModalTransition | 模态转场动画类型 |
| `onDisappear` | () => void | 全屏覆盖消失回调 |

---

## 场景1：分享面板

**场景描述：** 仿社交分享面板，点击按钮后从底部弹出包含微信/朋友圈/QQ 等分享渠道的半模态面板，支持拖拽关闭。

**解决方案：** 使用 **`bindSheet` 半模态** + **Grid 4 列布局**

```ts
Button('打开分享面板')
  .bindSheet($$this.isPresent, this.ShareSheetBuilder(), {
    height: 360,
    dragBar: true,
    showClose: false,
    onDisappear: () => { this.isPresent = false }
  })

@Builder
ShareSheetBuilder() {
  Column() {
    Text('分享到').fontSize(16)
    Grid() {
      ForEach(shareItems, (item) => {
        GridItem() {
          Column() { Image(item.icon).width(40); Text(item.name) }
        }
      })
    }.columnsTemplate('1fr 1fr 1fr 1fr')
    Button('取消').onClick(() => { this.isPresent = false })
  }
}
```

---

## 场景2：聊天列表弹出菜单

**场景描述：** 仿微信聊天列表，顶部标题栏含"+"按钮，点击弹出深色下拉菜单（发起群聊/添加朋友/扫一扫/收付款），列表项包含头像、名称、消息摘要和时间。

**解决方案：** 使用 **`bindPopup` 自定义深色弹出菜单** + **`placement: Placement.Bottom`** + **`enableArrow` 箭头指向**

> **注意事项：**
> 1. `bindPopup` 在手机端默认使用 `COMPONENT_ULTRA_THICK` 模糊背景，会覆盖 `popupColor` 导致深色背景失效。若需自定义背景色，**必须显式设置 `backgroundBlurStyle: BlurStyle.NONE`** 关闭默认模糊。
> 2. `@Builder` 内的 Column 需设置固定宽度（如 `.width(160)`），否则弹窗宽度会随内容撑开过大。

```ts
Text('+')
  .fontSize(24)
  .onClick(() => { this.showMenu = !this.showMenu })
  .bindPopup(this.showMenu, {
    builder: this.wechatMenu,
    placement: Placement.Bottom,
    arrowPointPosition: ArrowPointPosition.END,
    maskColor: 'rgba(0,0,0,0)',
    popupColor: '#4C4C4C',
    backgroundBlurStyle: BlurStyle.NONE,
    enableArrow: true,
    onStateChange: (state) => {
      if (!state.isVisible) { this.showMenu = false }
    }
  })

@Builder
wechatMenu() {
  Column() {
    ForEach(menuItems, (item) => {
      Row() { Image(item.icon); Text(item.name).fontColor(Color.White) }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    })
  }
  .width(160)
  .borderRadius(8)
}
```

---

## 场景3：滑动选择器

**场景描述：** 仿城市/日期选择器，点击按钮后从底部弹出选择面板，顶部有取消/确定按钮，中间为可滚动城市列表，选中项字体放大加粗高亮。

**解决方案：** 使用 **`bindSheet` 380px 面板** + **List 可滚动选择** + **选中项高亮**

```ts
Button('选择城市')
  .bindSheet(this.isPresent, this.pickerBuilder(), {
    height: 380,
    dragBar: false,
    showClose: false
  })

@Builder
pickerBuilder() {
  Column() {
    Row() {
      Text('取消').onClick(() => { this.isPresent = false })
      Text('选择城市').fontWeight(FontWeight.Bold)
      Text('确定').onClick(() => { this.isPresent = false })
    }
    List() {
      ForEach(cities, (city, index) => {
        ListItem() {
          Text(city)
            .fontSize(this.selectedIndex === index ? 20 : 16)
            .fontWeight(this.selectedIndex === index ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.selectedIndex === index ? '#333' : '#999')
        }
        .onClick(() => { this.selectedIndex = index })
      })
    }
  }
}
```

---

## 场景4：全屏模态登录

**场景描述：** 仿全屏登录弹窗，点击按钮后全屏覆盖弹出登录页，默认显示一键登录（手机号+协议勾选），切换到其他登录方式时界面淡入淡出过渡，返回按钮根据当前页面执行不同操作。

**解决方案：** 使用 **`bindContentCover` 全屏模态** + **预定义 `TransitionEffect` 变量复用** + **Stack 叠加返回按钮** + **`expandSafeArea` 延伸安全区**

### 步骤 1：定义转场效果与状态

```ts
const EFFECT_DURATION = 800;
const EFFECT_OPACITY = 0.4;

@State isPresent: boolean = false;
@State isDefaultLogin: boolean = true;

private effect: TransitionEffect = TransitionEffect.OPACITY
  .animation({ duration: EFFECT_DURATION })
  .combine(TransitionEffect.opacity(EFFECT_OPACITY))
```

预定义 `effect` 变量：基于 `OPACITY` 转场，叠加 `opacity(0.4)` 起始透明度，持续 800ms。后续通过 `.transition(this.effect)` 绑定到需要转场的条件渲染内容上。

### 步骤 2：触发全屏模态

```ts
Button('全屏模态登录')
  .onClick(() => { this.isPresent = true })

// 父容器绑定全屏模态
.bindContentCover($$this.isPresent, this.fullCoverContent())
```

### 步骤 3：全屏模态内容 — 条件渲染 + Stack 叠加返回按钮

```ts
@Builder
fullCoverContent() {
  Stack({ alignContent: Alignment.TopStart }) {
    if (this.isDefaultLogin) {
      this.defaultLoginPage()
    } else {
      this.otherWaysToLogin()
    }
    Text('←')
      .fontSize(24)
      .width(50)
      .height(50)
      .textAlign(TextAlign.Center)
      .padding({ top: 15 })
      .onClick(() => {
        if (this.isDefaultLogin) {
          this.isPresent = false;       // 默认登录页 → 关闭模态
        } else {
          this.isDefaultLogin = true;   // 其他登录页 → 返回默认登录
        }
      })
  }
  .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  .size({ width: '100%', height: '100%' })
  .padding({ top: 10, left: 10, right: 10 })
  .backgroundColor(Color.White)
}
```

Stack 布局将返回按钮叠加在条件渲染内容顶层，根据 `isDefaultLogin` 判断当前处于哪个页面，执行不同的返回逻辑。

### 步骤 4：默认登录页 — 一键登录

```ts
@Builder
defaultLoginPage() {
  Column({ space: 10 }) {
    // ... 头像、欢迎标题、手机号展示等布局

    Row() {
      Checkbox({ name: 'checkbox1' })
        .select(this.isConfirmed)
        .onChange((value: boolean) => { this.isConfirmed = value; })
      Text() {
        Span('阅读并同意').fontColor('#999999')
        Span('《服务协议及个人信息处理规则》').fontColor(Color.Orange)
      }
    }

    Button('本机号码一键登录')
      .onClick(() => {
        if (this.isConfirmed) {
          promptAction.showToast({ message: '登录成功' });
        } else {
          promptAction.showToast({ message: '请先阅读并同意协议' });
        }
      })

    Row() {
      Text('其他方式登录')
        .onClick(() => { this.isDefaultLogin = false; })  // ← 切换到其他登录页
      Blank()
      Text('遇到问题')
    }
  }
  .width('100%')
  .height('100%')
  .backgroundColor(Color.White)
  .justifyContent(FlexAlign.Center)
}
```

注意：`defaultLoginPage` 不绑定 `.transition(this.effect)`，因此切换回默认登录页时无淡入淡出效果；转场效果仅在 `otherWaysToLogin` 上生效。

### 步骤 5：其他登录方式 — 绑定 transition 实现淡入淡出

```ts
@Builder
otherWaysToLogin() {
  Column({ space: 20 }) {
    // ... 标题栏、手机号输入框、验证码按钮、协议勾选、三方登录图标等布局

    Row() {
      Checkbox({ name: 'agreement' })
        .select(this.isAgree)
        .onChange((value: boolean) => { this.isAgree = value; })
      Text() {
        Span('阅读并同意').fontColor('#999999')
        Span('《服务协议及个人信息处理规则》').fontColor(Color.Orange)
      }
    }.width('100%')

    // ... 三方登录图标
  }
  .width('100%')
  .height('100%')
  .backgroundColor(Color.White)
  .padding({ bottom: 30, top: 60 })
  .transition(this.effect)   // ← 绑定预定义转场效果，实现淡入淡出
}
```

关键点：
- 预定义 `TransitionEffect` 变量 `effect`，通过 `.transition(this.effect)` 绑定到 `otherWaysToLogin`，实现从默认登录切换到其他登录方式时的淡入淡出过渡（从 0.4 透明度渐变到 1.0，持续 800ms）
- `isDefaultLogin` 控制条件渲染，`$$this.isPresent` 双向绑定驱动全屏模态显隐；点击"其他方式登录"将 `isDefaultLogin` 置为 `false`，触发 `otherWaysToLogin` 带转场效果进入
- Stack 布局将返回按钮叠加在顶层：默认登录页点击返回关闭模态（`isPresent = false`），其他登录页点击返回切回默认登录（`isDefaultLogin = true`）
- 使用常量 `EFFECT_DURATION` / `EFFECT_OPACITY` 提取转场参数，便于统一调整
- `expandSafeArea` 延伸安全区，避免底部被系统导航栏遮挡

---

## 场景5：更多操作菜单

**场景描述：** 仿文件管理器列表，每个文件项右侧有"⋮"按钮，点击后弹出系统级操作菜单（复制/移动/重命名/分享/删除），菜单项点击后执行对应操作并自动关闭。

**解决方案：** 使用 **`bindMenu` 绑定菜单数组** + **`MenuElement` 菜单项配置** + **`action` 回调处理点击**

### 步骤 1：文件列表数据

```ts
private fileItems: Record<string, string>[] = [
  { title: '项目计划书.docx', size: '2.3 MB', icon: '📄' },
  { title: '会议纪要.pdf', size: '1.1 MB', icon: '📑' },
  { title: '设计稿v3.fig', size: '15.7 MB', icon: '🎨' },
]
```

### 步骤 2：bindMenu 绑定操作菜单

```ts
List({ space: 8 }) {
  ForEach(this.fileItems, (item: Record<string, string>) => {
    ListItem() {
      Row() {
        Text(item.icon).fontSize(28).width(44).height(44)
          .backgroundColor('#f0f0f0').borderRadius(8)
        Column() {
          Text(item.title).fontSize(15).fontColor('#333')
          Text(item.size).fontSize(12).fontColor('#999').margin({ top: 4 })
        }.layoutWeight(1)
        Text('⋮')
          .fontSize(22).fontColor('#666').width(36).height(36)
          .textAlign(TextAlign.Center).borderRadius(18)
          .bindMenu([
            { value: '复制', action: () => { /* 复制操作 */ } },
            { value: '移动', action: () => { /* 移动操作 */ } },
            { value: '重命名', action: () => { /* 重命名操作 */ } },
            { value: '分享', action: () => { /* 分享操作 */ } },
            { value: '删除', action: () => { /* 删除操作 */ } },
          ])
      }
      .width('100%').padding(12).backgroundColor(Color.White).borderRadius(8)
    }
  })
}
```

关键点：
- `bindMenu` 接收 `MenuElement[]` 数组，每项包含 `value`（显示文本）和 `action`（点击回调）
- 菜单自动定位在绑定组件上方/下方，点击菜单项后自动关闭
- 无需手动管理菜单显隐状态，`bindMenu` 由系统自动处理

---

## 场景6：长按菜单

**场景描述：** 仿桌面图标和图片长按操作。长按桌面应用图标弹出快捷操作菜单（分享/应用信息/卸载），长按图片弹出图片操作菜单（保存图片/收藏/识图搜索/复制链接/转发），两个场景通过 Tab 切换展示。

**解决方案：** 使用 **`bindContextMenu` + `ResponseType.LongPress`** + **`@Builder` 自定义菜单布局** + **Tab 切换两种场景**

### 步骤 1：定义自定义菜单 Builder

```ts
@Builder
ImageContextMenu() {
  Column() {
    Row() {
      Text('💾').fontSize(20).margin({ right: 12 })
      Text('保存图片').fontSize(16).fontColor('#333')
    }.width('100%').height(48).padding({ left: 16, right: 16 })
    .onClick(() => { /* 保存图片 */ })

    Divider().color('#f0f0f0')

    Row() {
      Text('⭐').fontSize(20).margin({ right: 12 })
      Text('收藏').fontSize(16).fontColor('#333')
    }.width('100%').height(48).padding({ left: 16, right: 16 })

    Divider().color('#f0f0f0')

    Row() {
      Text('🔍').fontSize(20).margin({ right: 12 })
      Text('识图搜索').fontSize(16).fontColor('#333')
    }.width('100%').height(48).padding({ left: 16, right: 16 })

    Divider().color('#f0f0f0')

    Row() {
      Text('🔗').fontSize(20).margin({ right: 12 })
      Text('复制链接').fontSize(16).fontColor('#333')
    }.width('100%').height(48).padding({ left: 16, right: 16 })

    Divider().color('#f0f0f0')

    Row() {
      Text('📤').fontSize(20).margin({ right: 12 })
      Text('转发').fontSize(16).fontColor('#333')
    }.width('100%').height(48).padding({ left: 16, right: 16 })
  }
  .width(180)
  .backgroundColor(Color.White)
  .borderRadius(12)
}
```

### 步骤 2：绑定长按菜单

```ts
// 桌面图标场景
Column() {
  Text(app.icon).fontSize(32)
}
.width(56).height(56).borderRadius(14).backgroundColor(app.color)
.justifyContent(FlexAlign.Center)
.bindContextMenu(this.DesktopAppMenu, ResponseType.LongPress)

// 图片场景
Column() {
  Text('🌅').fontSize(60)
}
.width('100%').height(140).backgroundColor('#ff9500')
.justifyContent(FlexAlign.Center)
.bindContextMenu(this.ImageContextMenu, ResponseType.LongPress)
```

### 步骤 3：Tab 切换两种场景

```ts
@State currentTab: number = 0

Row() {
  ForEach(['桌面图标', '图片长按'], (tab: string, index: number) => {
    Column() {
      Text(tab)
        .fontColor(this.currentTab === index ? '#007dff' : '#666')
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
    }
    .layoutWeight(1).height(44).justifyContent(FlexAlign.Center)
    .onClick(() => { this.currentTab = index })
  })
}

if (this.currentTab === 0) {
  this.DesktopIconScene()
} else {
  this.ImageLongPressScene()
}
```

关键点：
- `bindContextMenu(Builder, ResponseType.LongPress)` 将自定义菜单绑定到长按手势，系统自动处理菜单的弹出和关闭
- `ResponseType.LongPress` 指定触发方式为长按，区别于 `bindMenu` 的点击触发
- 可为不同组件绑定不同的 `@Builder` 菜单（如桌面图标菜单 vs 图片菜单），实现场景化差异
- `@Builder` 内可自定义菜单布局和样式，支持图标+文字、分隔线等丰富内容

---

## 场景7：登录注册模态转场

**场景描述：** 仿登录注册流程，点击"登录"按钮后登录页从底部弹性滑入覆盖全屏，点击"注册"按钮后注册页从右侧弹性滑入；登录页内可切换手机号/密码登录方式，登录↔注册之间可互相跳转，切换时旧页面先淡出再新页面淡入。

**解决方案：** 使用 **`if` 条件渲染 + `TransitionEffect.OPACITY.combine(translate)`** + **`curves.springMotion(0.6, 0.9)` 弹性曲线** + **`setTimeout` 编排登录↔注册交叉转场**

### 步骤 1：状态与转场方法

```ts
@State showLogin: boolean = false
@State showRegister: boolean = false
@State isPhoneLogin: boolean = true

private toggleLogin(): void {
  this.getUIContext()?.animateTo({ duration: 400, curve: Curve.EaseInOut }, () => {
    this.showLogin = !this.showLogin
  })
}

private toggleRegister(): void {
  this.getUIContext()?.animateTo({ duration: 400, curve: Curve.EaseInOut }, () => {
    this.showRegister = !this.showRegister
  })
}
```

### 步骤 2：登录→注册交叉转场

```ts
private switchToRegister(): void {
  this.getUIContext()?.animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
    this.showLogin = false
  })
  setTimeout(() => {
    this.getUIContext()?.animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
      this.showRegister = true
    })
  }, 200)
}

private switchToLogin(): void {
  this.getUIContext()?.animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
    this.showRegister = false
  })
  setTimeout(() => {
    this.getUIContext()?.animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
      this.showLogin = true
    })
  }, 200)
}
```

关键点：`setTimeout(200)` 让旧页面先淡出 200ms 后新页面才开始淡入，形成交叉转场而非同时切换。

### 步骤 3：登录页 — 从底部弹性滑入

```ts
if (this.showLogin) {
  Column() {
    // 顶部导航栏
    Row() {
      Text('<').onClick(() => this.toggleLogin())
      Text('登录').layoutWeight(1).textAlign(TextAlign.Center)
    }.width('100%').height(56).padding({ left: 16, right: 16 })

    // 登录表单（支持手机号/密码切换）
    Column() {
      Text('欢迎回来').fontSize(28).fontWeight(FontWeight.Bold)
      Text('登录您的账号继续使用').fontSize(14).fontColor('#999')

      Row() {
        Text(this.isPhoneLogin ? '手机号登录' : '密码登录').fontColor('#ff6b35')
        Text(this.isPhoneLogin ? '密码登录' : '手机号登录')
          .onClick(() => { this.isPhoneLogin = !this.isPhoneLogin })
      }

      if (this.isPhoneLogin) {
        TextInput({ placeholder: '请输入手机号' })
        // 验证码输入 + 获取验证码按钮
      } else {
        TextInput({ placeholder: '请输入手机号/邮箱' })
        TextInput({ placeholder: '请输入密码' }).type(InputType.Password)
      }

      Button('登录').onClick(() => this.toggleLogin())
      Text('立即注册').onClick(() => this.switchToRegister())
    }
  }
  .width('100%').height('100%').backgroundColor(Color.White)
  .transition(
    TransitionEffect.OPACITY
      .combine(TransitionEffect.translate({ y: 300 }))
      .animation({ duration: 400, curve: curves.springMotion(0.6, 0.9) })
  )
}
```

### 步骤 4：注册页 — 从右侧弹性滑入

```ts
if (this.showRegister) {
  Column() {
    // 顶部导航栏
    Row() {
      Text('<').onClick(() => this.toggleRegister())
      Text('注册').layoutWeight(1).textAlign(TextAlign.Center)
    }

    Scroll() {
      Column() {
        Text('创建新账号').fontSize(28).fontWeight(FontWeight.Bold)
        Text('注册后即可享受全部功能').fontSize(14).fontColor('#999')

        TextInput({ placeholder: '请输入手机号' })
        // 验证码 + 密码 + 确认密码
        Checkbox()  // 同意协议
        Button('注册').onClick(() => this.toggleRegister())
        Text('立即登录').onClick(() => this.switchToLogin())
      }
    }
  }
  .width('100%').height('100%').backgroundColor(Color.White)
  .transition(
    TransitionEffect.OPACITY
      .combine(TransitionEffect.translate({ x: '100%' }))
      .combine(TransitionEffect.scale({ x: 0.95, y: 0.95 }))
      .animation({ duration: 400, curve: curves.springMotion(0.6, 0.9) })
  )
}
```

关键点：
- 登录页使用 `translate({ y: 300 })` 从底部滑入，注册页使用 `translate({ x: '100%' })` 从右侧滑入，方向区分体现页面层级关系
- 注册页额外叠加 `scale({ x: 0.95, y: 0.95 })`，进入时从 0.95 倍放大到 1 倍，增加纵深感
- `curves.springMotion(0.6, 0.9)` 弹性曲线为滑入动画提供自然的回弹效果
- 登录↔注册交叉转场通过 `setTimeout(200)` 编排：先关闭当前页（300ms 动画），200ms 后打开目标页，形成 100ms 交叉

---
