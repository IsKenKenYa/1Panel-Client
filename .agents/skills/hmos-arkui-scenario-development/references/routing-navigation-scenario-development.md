# 路由/导航案例集

## 目录

### [一、Navigation生命周期管理](#一navigation生命周期管理)
1. [前后台切换自动刷新列表数据](#场景1前后台切换自动刷新列表数据)
2. [编辑页未保存内容返回确认](#场景2编辑页未保存内容返回确认)
3. [Tab首页 onNewParam 单例刷新数据](#场景3tab首页-onnewparam-单例刷新数据)

### [二、通过push、pop、replace对子页面进行路由操作](#二通过pushpopreplace对子页面进行路由操作)
1. [闪屏页（启动页）](#场景1闪屏页启动页)
2. [页面路由重定向（页面下线/AB测试）](#场景2页面路由重定向页面下线ab测试)
3. [复杂参数传参与返回值](#场景3复杂参数传参与返回值)
4. [三分栏邮箱场景（SideBarContainer + Navigation 多端适配）](#场景4三分栏邮箱场景sidebarcontainer--navigation-多端适配)
5. [二分栏聊天应用场景（Navigation Split 多端适配）](#场景5二分栏聊天应用场景navigation-split-多端适配)

### [三、构建子页面，配置，使能Navigation路由表](#三构建子页面配置使能navigation路由表)
1. [路由拦截权限校验（声明式权限 + 集中式拦截）](#场景1路由拦截权限校验声明式权限--集中式拦截)
2. [NavDestination 页面级方向控制](#场景2navdestination-页面级方向控制)
3. [多模块统一动态路由](#场景3多模块统一动态路由)

### [四、Navigation组件的无感监听](#四navigation组件的无感监听)
1. [NavDestinationSwitch 实现页面查看访问次数统计埋点](#场景1navdestinationswitch-实现页面查看访问次数统计埋点)
2. [queryNavDestinationInfo 获取当前页面信息](#场景2querynavdestinationinfo-获取当前页面信息)

### [五、Navigation路由动画](#五navigation路由动画)
1. [系统转场类型配置](#场景1系统转场类型配置)
2. [单页面自定义转场动画](#场景2单页面自定义转场动画)
3. [Navigation全局自定义转场动画](#场景3navigation全局自定义转场动画)
4. [可交互手势返回转场](#场景4可交互手势返回转场)
5. [共享元素一镜到底转场](#场景5共享元素一镜到底转场)
6. [Dialog蒙层渐隐退出动画](#场景6dialog蒙层渐隐退出动画)

---

## 一、Navigation生命周期管理

### 场景1：前后台切换自动刷新列表数据

**场景描述：** 应用切换到后台一段时间后回到前台，列表数据可能已过期（如新消息、新订单、价格变动）。需要在 NavDestination 页面重新可见时自动刷新数据。

**解决方案：** 使用 NavDestination 的 **`onShown` 回调** 监听页面重新显示。`onShown` 在 Pop 返回到当前页、应用从后台切回前台、被覆盖的标准页面重新显示时均会触发——而 `onWillShow` 在前后台切换时**不会**触发，因此刷新场景应使用 `onShown`。

> ❌ **常见错误：用 `onPageShow` / `onPageHide`（根页面回调）替代 `onShown`**
> `onPageShow` 是 `@Entry` 根页面的生命周期回调，感知的是整个 Ability 页面，**感知不到 NavDestination 子页面的 push / pop**——从详情页 Pop 返回列表页时它不会触发。要监听 NavDestination 子页面“重新可见”，必须用 NavDestination 自己的 `onShown`（同时覆盖 Pop 返回 + 前后台切换）。

#### 关键生命周期回调对比

| 回调 | Pop 回来触发 | 前后台切换触发 | 起始版本 | 适用场景 |
|------|:----------:|:-----------:|:------:|---------|
| `onWillShow` | ✅ | ❌ | API 12 | 页面即将显示前的初始化 |
| `onShown` | ✅ | ✅ | API 10 | **前后台刷新、Pop 回来刷新** |
| `onActive` | ✅ | ❌ | API 17 | overlay/Sheet 等遮挡后恢复（**不因 DIALOG 触发**） |

> 💡 **`onActive` 与 DIALOG 的关系**：DIALOG 类型的 NavDestination 透明叠加，其显示/消失**不影响**下层标准页的生命周期，因此不会触发下层页的 `onActive`/`onInactive`。`onActive`/`onInactive` 真正响应的是 overlay（`OverlayManager`）、`bindSheet`/`bindMenu`/`bindContentCover` 等会遮挡栈顶页的组件。Pop 回到栈顶时 `onActive` 也会触发（页面从非激活恢复为激活），但做"前后台刷新"仍应首选覆盖面更广的 `onShown`。

#### 步骤 1：简单刷新（onShown + 最小刷新间隔）

在 `onShown` 中检查刷新间隔，避免短时间内重复刷新：

```typescript
// OrderListPage.ets
@Component
struct OrderListPage {
  navStack: NavPathStack = new NavPathStack();
  @State orderList: Order[] = [];
  @State isRefreshing: boolean = false;
  private lastRefreshTime: number = 0;
  private readonly REFRESH_INTERVAL = 30_000; // 30秒内不重复刷新

  build() {
    NavDestination() {
      Column() {
        Refresh({ refreshing: $$this.isRefreshing }) {
          List() {
            ForEach(this.orderList, (order: Order) => {
              ListItem() {
                Text(`订单 ${order.id} - ${order.status}`)
              }
            })
          }
        }
        .onRefreshing(() => { this.loadData(); })
      }
    }
    .title('订单列表')
    .onShown(() => {
      // 每次页面可见时检查是否需要刷新
      const now = Date.now();
      if (now - this.lastRefreshTime > this.REFRESH_INTERVAL) {
        this.loadData();
      }
    })
    .onReady((ctx) => {
      this.navStack = ctx.pathStack;
      this.loadData(); // 首次加载数据
    })
  }

  private async loadData(): Promise<void> {
    this.lastRefreshTime = Date.now();
    // this.orderList = await OrderService.getList();
  }
}
```

#### 步骤 2：结合 UIAbility 生命周期（精确控制）

通过 `AppStorage` 将应用前后台切换事件传递到页面层，实现更精确的刷新控制：

```typescript
// entryability/EntryAbility.ets — 通知应用切回前台
export default class EntryAbility extends UIAbility {
  onForeground(): void {
    // 应用切回前台时设置标记
    AppStorage.setOrCreate('appForegroundTime', Date.now());
  }
}
```

```typescript
// 在页面中监听 AppStorage 变化
@StorageProp('appForegroundTime') @Watch('onForegroundTimeChange')
appForegroundTime: number = 0;

onForegroundTimeChange(): void {
  // 前后台切换时刷新
  this.loadData();
}
```

#### 推荐的刷新策略

| 场景 | 策略 |
|------|------|
| 即时通讯消息列表 | `onShown` + 始终刷新 |
| 订单列表 | `onShown` + 最小刷新间隔（30s） |
| 商品详情 | `onShown` + 仅刷新价格/库存等关键数据 |
| 设置页 | `onShown` + 不自动刷新（手动下拉） |

#### 关键 API 说明

| API | 说明 |
|-----|------|
| `NavDestination.onShown()` | 页面可见时触发，包括 Pop 返回和前后台切换 |
| `NavDestination.onWillShow()` | 页面即将显示前触发，前后台切换**不触发** |
| `NavDestination.onActive()`（API 17） | 页面恢复激活态时触发（overlay/Sheet 关闭、Pop 回到栈顶）；**DIALOG 的显示/消失不触发** |
| `NavDestination.onReady()` | 页面首次创建完成时触发，适合做首次数据加载 |
| `AppStorage.setOrCreate()` | 全局状态存储，用于跨组件（跨 UIAbility）传递前后台事件 |

#### 注意事项

1. **防抖处理**：前后台切换可能短时间多次触发，设置最小刷新间隔（如 30 秒）避免频繁请求。

2. **首次加载区分**：`onReady` 做首次加载，`onShown` 做后续刷新，两者职责分离。

3. **`onWillShow` 不适合前后台刷新**：前后台切换不触发 `onWillShow`，只有 `onShown` 能同时覆盖 Pop 返回和前后台切换两种场景。

4. **Loading 状态**：刷新时展示 Loading 或静默刷新，避免数据突然变化导致 UI 闪烁。

---

### 场景2：编辑页未保存内容返回确认

**场景描述：** 用户在编辑页面（表单、评论、个人资料编辑）输入了内容但未保存时，按返回键或点击返回按钮应弹出确认对话框，而非直接丢弃数据。

**解决方案：** 使用 NavDestination 的 **`onBackPressed()` 回调** 拦截系统返回键，返回 `true` 消费事件阻止默认 pop；通过对比初始快照判断是否有未保存修改，有则弹出 **`AlertDialog`** 确认对话框，确认后手动调用 `navStack.pop()`。

#### 步骤 1：实现编辑页（拦截返回 + 确认弹窗）

在 `onReady` 中记录表单初始值作为快照，`onBackPressed` 中对比当前值判断是否有修改：

```typescript
// EditProfilePage.ets
// 注意：AlertDialog 是全局 API，无需 import

@Component
struct EditProfilePage {
  navStack: NavPathStack = new NavPathStack();
  @State nickname: string = '';
  @State bio: string = '';

  /** 初始快照（用于判断是否有修改） */
  private originalNickname: string = '';
  private originalBio: string = '';

  /** 是否有未保存的修改 */
  private hasUnsavedChanges(): boolean {
    return this.nickname !== this.originalNickname || this.bio !== this.originalBio;
  }

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        TextInput({ text: $$this.nickname, placeholder: '昵称' }).width('80%')
        TextArea({ text: $$this.bio, placeholder: '个人简介' }).width('80%').height(120)

        Row({ space: 16 }) {
          Button('保存').onClick(() => {
            this.saveProfile();
          })
          Button('取消').onClick(() => {
            this.handleBack();
          })
        }
      }
      .padding(20)
    }
    .title('编辑资料')
    // ✅ 核心：拦截系统返回键
    .onBackPressed(() => {
      if (this.hasUnsavedChanges()) {
        this.showConfirmDialog();
        return true;  // 消费返回事件，阻止默认 pop
      }
      return false; // 无修改，允许默认返回
    })
    .onReady((ctx) => {
      this.navStack = ctx.pathStack;
      const p = ctx.pathInfo.param as Record<string, string>;
      this.nickname = p?.nickname ?? '';
      this.bio = p?.bio ?? '';
      // 记录初始快照
      this.originalNickname = this.nickname;
      this.originalBio = this.bio;
    })
  }

  /** 弹出确认对话框 */
  private showConfirmDialog(): void {
    AlertDialog.show({
      title: '提示',
      message: '您有未保存的修改，确定要离开吗？',
      primaryButton: {
        value: '继续编辑',
        action: () => {} // 不做任何操作，留在当前页
      },
      secondaryButton: {
        value: '放弃修改',
        action: () => {
          this.navStack.pop(); // 确认后手动 pop
        }
      }
    });
  }

  /** 通用返回处理（点击取消按钮时也走这个逻辑） */
  private handleBack(): void {
    if (this.hasUnsavedChanges()) {
      this.showConfirmDialog();
    } else {
      this.navStack.pop();
    }
  }

  /** 保存资料 */
  private async saveProfile(): Promise<void> {
    // await ProfileService.update({ nickname: this.nickname, bio: this.bio });
    this.navStack.pop({ saved: true }); // 保存成功后返回，携带结果
  }
}
```

#### 关键 API 说明

| API | 说明 |
|-----|------|
| `NavDestination.onBackPressed()` | 拦截系统返回键，返回 `true` 消费事件阻止默认 pop，返回 `false` 执行默认返回 |
| `AlertDialog.show()` | 弹出确认对话框，提供"继续编辑"和"放弃修改"两个选项 |
| `navStack.pop()` | 确认放弃修改后手动执行 pop 返回上一页 |
| `navStack.pop(result)` | 保存成功后携带返回结果 pop |

#### 注意事项

> ❌ **常见错误：在 `aboutToAppear` 中保存初始快照**
> `aboutToAppear` 触发早于 `onReady`，此时路由参数（`ctx.pathInfo.param`）可能还未传入，快照会取到空值，“是否有未保存修改”的判断永远为 false，返回拦截彻底失效。**初始快照必须在 `onReady` 中保存**，此时参数已就绪。

1. **返回 `true` 才能拦截**：`onBackPressed` 返回 `true` 表示消费事件（阻止默认 pop），返回 `false` 执行默认返回行为。

2. **页面返回按钮也需处理**：页面上的"取消"按钮需要调用 `handleBack()` 做相同的未保存判断，与系统返回键行为保持一致。

3. **初始快照**：在 `onReady` 中保存初始值，用于对比判断是否有修改。避免在 `aboutToAppear` 中保存，因为此时参数可能还未就绪。

4. **保存后直接 pop**：保存成功后无需弹确认，直接 `pop(result)` 返回，携带保存结果供上一页使用。

---

### 场景3：Tab首页 onNewParam 单例刷新数据

**场景描述：** 底部 Tab 首页（消息 / 推荐 / 我的）作为一个 `NavDestination` 单例来管理（避免重复创建）。当用户从其他页面回到首页时，需要刷新首页数据并切到指定 Tab——例如新消息到达时切到「消息」Tab 并更新未读数。单例模式下页面不会重新创建，因此无法通过 `onReady` 再次初始化，需要使用 `onNewParam` 回调接收新参数、刷新数据并切换 Tab。

**解决方案：** 用 **`Tabs`** 组织首页多 Tab 内容 + 用 `@State` 绑定 `Tabs.index` 控制激活 Tab + **`LaunchMode.MOVE_TO_TOP_SINGLETON`** 将栈中同名页面移到栈顶（不重建） + **`NavDestination.onNewParam()`** 在单例页面被重新移到栈顶时接收新参数，刷新数据并改写 `@State` 切换 Tab。

#### 与 onReady 的区别

| 回调 | 触发次数 | 触发时机 |
|------|---------|---------|
| `onReady` | 仅一次 | 页面首次创建 |
| `onNewParam` | 每次收到新参数 | 单例模式下被重新移到栈顶 |

#### 步骤 1：首页（支持单例 + onNewParam 刷新）

```typescript
// HomePage.ets — 底部 Tab 首页（单例 + onNewParam 刷新）
@Builder
export function HomePageBuilder(name: string, param: Object) {
  HomePage();
}

@Component
struct HomePage {
  navStack: NavPathStack = new NavPathStack();
  @State currentIndex: number = 0;   // 当前激活 Tab，绑定到 Tabs.index
  @State unreadCount: number = 0;    // 消息未读数（显示在「消息」Tab）
  @State feedList: Feed[] = [];      // 「推荐」信息流

  build() {
    NavDestination() {
      // ★ 首页内容用 Tabs 组织多 Tab；index 绑定 @State，可被 onNewParam 切换
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        // Tab1：消息
        TabContent() {
          Column({ space: 8 }) {
            if (this.unreadCount > 0) {
              Text(`您有 ${this.unreadCount} 条未读消息`).fontSize(14).fontColor('#FF6B35')
            }
            Text('消息列表内容…').fontSize(16)
          }.width('100%').height('100%').padding(12)
        }.tabBar('消息')

        // Tab2：推荐
        TabContent() {
          Column() {
            List({ space: 8 }) {
              ForEach(this.feedList, (item: Feed) => {
                ListItem() { Text(item.title).fontSize(16) }
              })
            }.layoutWeight(1).width('100%')

            // 从推荐 Tab 进详情页（普通 push，返回走 pop→onShown，不走 onNewParam）
            Button('进入详情').onClick(() => {
              this.navStack.pushPathByName('DetailPage', null);
            })
          }.width('100%').height('100%')
        }.tabBar('推荐')

        // Tab3：我的
        TabContent() {
          Column() { Text('我的').fontSize(16) }
            .width('100%').height('100%').padding(12)
        }.tabBar('我的')
      }
      .scrollable(true)                       // 允许左右滑动切换 Tab
      .onChange((index: number) => {          // 用户滑动/点击 Tab 时回写索引
        this.currentIndex = index;
      })
    }
    .title('首页')

    // 首次创建时初始化数据（单例下仅触发一次）
    .onReady((ctx) => {
      this.navStack = ctx.pathStack;
      this.loadHomeData();
    })

    // ✅ 核心：单例页面被重新移到栈顶时接收新参数 → 刷新数据 + 切换 Tab
    .onNewParam((param: Object) => {
      console.info('HomePage onNewParam:', JSON.stringify(param));
      const p = param as Record<string, Object>;
      // 1) 根据参数切换到指定 Tab（改 @State 即驱动 Tabs.index 切换）
      const tab = p?.['tab'] as string;
      if (tab === 'messages') this.currentIndex = 0;
      else if (tab === 'feed') this.currentIndex = 1;
      else if (tab === 'mine') this.currentIndex = 2;
      // 2) 更新消息未读数
      if (p?.['unreadCount']) this.unreadCount = p['unreadCount'] as number;
      // 3) 携带刷新标记时重新拉取数据
      if (p?.['action'] === 'refresh') this.loadHomeData();
    })
  }

  private async loadHomeData(): Promise<void> {
    // this.feedList = await HomeService.getFeed();
    // this.unreadCount = await MessageService.getUnreadCount();
  }
}
```

#### 步骤 2：从其他页面回到首页（触发 onNewParam + 切 Tab）

通过 `pushPathByName` 携带新参数（含目标 Tab、未读数、刷新标记），配合 `MOVE_TO_TOP_SINGLETON` 将栈中已有的首页实例移到栈顶，`onNewParam` 随即触发：

```typescript
// NotificationPage.ets — 点击通知回到首页：切到「消息」Tab 并刷新未读数
Button('查看新消息').onClick(() => {
  this.navStack.pushPathByName('HomePage',
    { action: 'refresh', tab: 'messages', unreadCount: 5 },
    { launchMode: LaunchMode.MOVE_TO_TOP_SINGLETON }  // ★ 第三参 launchMode 不可省略：省略则 push 新实例、onNewParam 不触发
  );
})
```

首页收到参数后：`tab:'messages'` → `currentIndex=0`（切到消息 Tab），`unreadCount:5` → 更新未读数提示，`action:'refresh'` → 重新拉取数据。

#### 两种 LaunchMode 对比

```
栈状态: [NavBar, HomePage, DetailA, DetailB]

MOVE_TO_TOP_SINGLETON('HomePage'):
→ [NavBar, DetailA, DetailB, HomePage]  // HomePage 移到栈顶，上方页面保留

POP_TO_SINGLETON('HomePage'):
→ [NavBar, HomePage]                    // HomePage 上方所有页面被移除
```

#### 关键 API 说明

| API | 说明 | 起始版本 |
|-----|------|---------|
| `LaunchMode.MOVE_TO_TOP_SINGLETON` | 查找栈中同名页面移到栈顶，不重新创建 | API 12+ |
| `LaunchMode.POP_TO_SINGLETON` | 查找栈中同名页面并移除其上方所有页面 | API 12+ |
| `NavDestination.onNewParam()` | 单例页面收到新参数时的回调，在单例模式下被重新移到栈顶时触发 | API 19+ |

#### 注意事项

> ❌ **常见错误①：注释里写了 `MOVE_TO_TOP_SINGLETON` 但代码没传**
> 仅在注释 / 文档里提到 `launchMode` 是无效的，**必须实际传参** `pushPathByName(name, param, { launchMode: LaunchMode.MOVE_TO_TOP_SINGLETON })`。省略第三参会 push 一个新实例而不是复用栈中已有的单例，`onNewParam` 不会触发，切 Tab / 刷新逻辑全部失效。

> ❌ **常见错误②：把首页放成 `Navigation` 的 NavBar，却指望 `onNewParam` 触发**
> NavBar 是常驻根节点、**不是 `NavDestination`**，不进入路由栈，单例机制与 `onNewParam` 对它都不生效。若 Tabs 必须放在 NavBar，则返回刷新只能用 NavBar 的 `onShown` / 组件级 `onAppear`。**本场景要求首页是一个 `NavDestination` 单例**（注册在路由表、作为可被 push 的目的页），`onNewParam` 才会触发。

1. **切换 Tab 靠 `@State`，不靠 controller**：`Tabs.index` 绑定 `@State currentIndex`，在 `onNewParam` 里改 `currentIndex` 即可驱动 Tab 切换；不要绕开状态去调用 `TabsController.changeIndex()`，否则与 `onChange` 回写的索引会冲突。

2. **`onNewParam` 仅在单例模式下触发**：普通的 push 新实例不会触发 `onNewParam`，只有 `MOVE_TO_TOP_SINGLETON` 或 `POP_TO_SINGLETON` 命中已存在的同名页面时才会触发。从首页 push 进详情页再 `pop` 返回走的是 `onShown`，不是 `onNewParam`。

3. **`MOVE_TO_TOP_SINGLETON` 不清除上方页面**：如果需要清除首页上方的所有页面（如从深层页面直接回首页），使用 `POP_TO_SINGLETON`。

4. **参数可以传任意对象**：可用于传递目标 Tab、未读数、刷新标记、滚动位置等，在 `onNewParam` 回调中根据参数内容决定切换哪个 Tab 与刷新策略。

5. **`onReady` 只触发一次**：页面首次创建时触发，后续单例移到栈顶只触发 `onNewParam`，两个回调职责分离。

---

## 二、通过push、pop、replace对子页面进行路由操作

### 场景1：闪屏页（启动页）

**场景描述：** 应用冷启动时，系统先显示启动窗口（由 `module.json5` 中的 `startWindowIcon` 和 `startWindowBackground` 配置），随后加载 UIAbility 并渲染首帧内容。闪屏页在此期间承担品牌展示、开屏广告、初始化缓冲和平滑过渡的职责。倒计时结束或用户点击跳过后，通过状态切换无缝过渡到主页内容。

**解决方案：** 使用 **`module.json5` 系统启动窗口消除白屏** + **Navigation 内嵌闪屏页（`showSplash` 状态驱动切换）** + **倒计时期间并行预加载数据**。整个应用只有一个 Navigation 容器，闪屏页和主页共享同一个 NavPathStack，无需页面跳转，过渡无缝。

#### 步骤 1：配置系统启动窗口（消除白屏）

在 `entry/src/main/module.json5` 的 `abilities` 中配置启动窗口图标和背景色：

```json
{
  "module": {
    "abilities": [{
      "name": "EntryAbility",
      "startWindowIcon": "$media:start_window_icon",
      "startWindowBackground": "$color:start_window_background",
      "exported": true
    }]
  }
}
```

> **关键**：启动窗口背景色（如 `#FFFFFF`）应与闪屏页背景色一致，这样系统启动窗口消失时不会出现视觉闪烁。

#### 步骤 2：实现带广告的闪屏页（Index.ets）

将闪屏页作为 Navigation 的 NavBar 首屏内容。以下代码包含广告能力，广告加载期间显示品牌页，加载成功后切换为广告图。如不需要广告功能，删除 `showAd`/`adImageUrl` 相关逻辑即可：

```typescript
// pages/Index.ets — Navigation 主页 + 闪屏页内嵌
@Entry
@Component
struct Index {
  navStack: NavPathStack = new NavPathStack();
  @State showSplash: boolean = true;
  @State countdown: number = 5;
  @State adImageUrl: string = '';  // 广告图 URL，不需要广告则删除此行及 showAd
  @State showAd: boolean = false;
  private timer: number = -1;

  aboutToAppear(): void { this.loadAdAndStart(); }
  aboutToDisappear(): void { this.clearTimer(); }

  private async loadAdAndStart(): Promise<void> {
    this.preloadData(); // 并行预加载数据（SDK初始化、登录态检查、首页数据）
    try {
      // const adData = await AdService.getSplashAd(); // 从服务端获取广告
      this.adImageUrl = 'https://xxx/ad/splash.jpg';
      this.countdown = 5;
      this.showAd = true;
    } catch (error) {
      this.showSplash = false; // 广告加载失败，直接进入主页
      return;
    }
    this.timer = setInterval(() => {
      this.countdown--;
      if (this.countdown <= 0) { this.clearTimer(); this.showSplash = false; }
    }, 1000);
  }

  private clearTimer(): void {
    if (this.timer !== -1) { clearInterval(this.timer); this.timer = -1; }
  }

  private async preloadData(): Promise<void> {
    // 在闪屏期间预加载：SDK 初始化、登录态检查、首页数据
  }

  build() {
    Navigation(this.navStack) {
      if (this.showSplash) {
        Stack({ alignContent: Alignment.TopEnd }) {
          if (this.showAd) {
            Image(this.adImageUrl).width('100%').height('100%').objectFit(ImageFit.Cover)
              .onClick(() => { /* 点击广告跳转到详情页 */ })
          } else {
            Column({ space: 16 }) {
              Image($r('app.media.start_window_icon')).width(120).height(120).borderRadius(24)
              Text('MyApp').fontSize(28).fontWeight(FontWeight.Bold)
            }.width('100%').height('100%').justifyContent(FlexAlign.Center)
          }
          Button(`跳过 ${this.countdown}s`)
            .onClick(() => { this.clearTimer(); this.showSplash = false; })
        }.width('100%').height('100%').backgroundColor('#FFFFFF') // 与 startWindowBackground 一致
      } else {
        Column({ space: 20 }) {
          Text('首页').fontSize(28).fontWeight(FontWeight.Bold)
          Button('进入商品列表').onClick(() => {
            this.navStack.pushPathByName('ProductList', null);
          })
        }.width('100%').height('100%').justifyContent(FlexAlign.Center)
      }
    }
    .title(this.showSplash ? '' : '首页')
    .hideTitleBar(this.showSplash)
    .mode(NavigationMode.Stack)
  }
}
```

在 `EntryAbility.ets` 的 `onWindowStageCreate` 中加载此页面即可：

```typescript
// entryability/EntryAbility.ets（关键代码）
onWindowStageCreate(windowStage: window.WindowStage): void {
  windowStage.loadContent('pages/Index', (err) => { /* 错误处理 */ });
}
```

#### 关键 API 说明

| API / 配置 | 说明 | 位置 |
|-----------|------|------|
| `startWindowIcon` / `startWindowBackground` | 系统启动窗口图标和背景色 | `module.json5` → `abilities` |
| `windowStage.loadContent()` | 加载首个页面内容 | `EntryAbility.ets` → `onWindowStageCreate` |
| `NavPathStack` | Navigation 页面路由栈，管理子页面跳转 | `Index.ets` |
| `hideTitleBar()` | 闪屏期间隐藏标题栏，主页恢复显示 | `Index.ets` → Navigation |
| `aboutToDisappear` | 组件销毁时清理定时器，防止内存泄漏 | `Index.ets` |

#### 注意事项

> ❌ **常见错误：startWindowBackground 与闪屏页 backgroundColor 颜色不同**
> 两者必须完全一致（如都是 `#FFFFFF` 或都是 `#000000`），否则冷启动会出现颜色闪烁。**不要为了“好看”把闪屏页设成黑色、启动窗口设成白色**——AI 生成时常自作主张改色，务必逐字核对两者一致。

1. **`startWindowBackground` 必须与闪屏页 `backgroundColor` 完全一致（硬约束）**：两者颜色不同会导致系统启动窗口消失时出现冷启动闪烁。`module.json5` 的 `startWindowBackground` 必须与闪屏页 `.backgroundColor(...)` 逐字符相同。

2. **闪屏页通过状态切换而非页面跳转**：`showSplash` 状态控制闪屏与主页的切换，用户按返回键不会回到闪屏页，同时避免了页面切换动画带来的视觉断裂。

3. **定时器必须在 `aboutToDisappear` 中清理**：否则造成内存泄漏。

4. **闪屏页应尽可能轻量**：数据预加载应使用异步操作，不阻塞 UI。

5. **热启动通常不显示闪屏页**：闪屏页在冷启动时通过 `loadContent` 加载。热启动若 Ability 实例仍存活，走 `onForeground` 回调、`showSplash` 保持 `false` 不再显示；但若 Ability 已被系统回收后重建，会重新走 `loadContent`，`showSplash` 重置为 `true` 仍会显示闪屏。

---

### 场景2：页面路由重定向（页面下线/AB测试）

**场景描述：** 在页面路由过程中，需要根据业务规则拦截目标页面并重定向到其他页面。典型场景包括：旧页面下线后自动跳转到替代页面或维护公告页、A/B 测试中根据用户分组路由到不同版本页面、功能迁移后将旧入口重定向到新页面。

**解决方案：** 使用 **`NavPathStack.setInterception()` 的 `willShow` 回调** 拦截页面显示，在回调中根据目标页面名称匹配重定向规则，通过 `pop` 移除原目标页、`pushPathByName` 导航到新页面，并保留原始参数。

#### 步骤 1：定义重定向规则

配置静态重定向映射表（页面下线/迁移）和动态重定向逻辑（A/B 测试）：

```typescript
// RouteRedirector.ets

/**
 * 页面重定向规则配置
 * 页面左边为源页面，右边为重定向的目标页面
 */
const REDIRECT_RULES: Record<string, string> = {
  'OldProductDetail': 'ProductDetail',       // 旧页面 → 新页面
  'DeprecatedFeature': 'MaintenancePage',    // 已下线 → 维护公告
};

/**
 * 动态重定向逻辑（A/B测试示例）
 */
function getABTestPage(originalPage: string): string {
  const userGroup = 'B'; // 仅示例，实际业务场景应从服务端或本地缓存获取
  if (originalPage === 'HomePage' && userGroup === 'B') {
    return 'HomePageV2';
  }
  return originalPage;
}
```

#### 步骤 2：注册路由拦截器

在 Navigation 初始化时，通过 `setInterception` 的 `willShow` 回调实现重定向：

```typescript
// RouteRedirector.ets（续）

export function setupRedirectInterceptor(pageStack: NavPathStack): void {
  pageStack.setInterception({
    willShow: (from, to, operation, animated) => {
      if (typeof to === 'string') return;

      const target = to as NavDestinationContext;
      const pageName = target.pathInfo.name;

      // 规则 1：静态重定向（页面下线/迁移）
      if (REDIRECT_RULES[pageName]) {
        const newPage = REDIRECT_RULES[pageName];
        console.info(`Redirect: ${pageName} → ${newPage}`);
        target.pathStack.pop();
        target.pathStack.pushPathByName(newPage, target.pathInfo.param);
        return;
      }

      // 规则 2：AB 测试动态重定向
      const abPage = getABTestPage(pageName);
      if (abPage !== pageName) {
        target.pathStack.pop();
        target.pathStack.pushPathByName(abPage, target.pathInfo.param);
      }
    }
  });
}
```

#### 步骤 3：在 Navigation 页面中启用拦截

在创建 NavPathStack 后调用拦截器注册函数：

```typescript
// pages/Index.ets
// RouteRedirector 的完整代码见步骤1（重定向规则）和步骤2（拦截器注册）
import { setupRedirectInterceptor } from '../common/RouteRedirector';

@Entry
@Component
struct Index {
  navStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    // 注册路由重定向拦截器
    setupRedirectInterceptor(this.navStack);
  }

  build() {
    Navigation(this.navStack) {
      // 主页内容...
      Column({ space: 20 }) {
        Text('首页')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)

        // 点击后触发路由，如果 OldProductDetail 在重定向规则中
        // 将自动重定向到 ProductDetail
        Button('查看商品（旧入口）')
          .onClick(() => {
            this.navStack.pushPathByName('OldProductDetail', { id: '123' });
          })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .title('首页')
    .mode(NavigationMode.Stack)
  }
}
```

#### 关键 API 说明

| API | 说明 |
|-----|------|
| `setInterception({ willShow })` | 页面显示前拦截回调，可在其中修改路由栈 |
| `target.pathInfo.name` | 获取目标页面名称，用于匹配重定向规则 |
| `target.pathInfo.param` | 获取目标页面参数，重定向时应传递给新页面 |
| `target.pathStack.pop()` | 移除已入栈的原目标页 |
| `target.pathStack.pushPathByName(name, param)` | 重定向到新页面并保留原始参数 |

#### 注意事项

1. **`willShow` 触发时机**：`willShow` 回调触发时目标页面**已被创建**（但随后销毁），比 `interception` 回调稍晚。

2. **保留原始参数**：重定向时务必通过 `target.pathInfo.param` 将原始参数传递给新页面，避免数据丢失。

3. **避免循环重定向**：确保重定向链有终点（如 A → B → A 的循环会导致无限循环），建议在规则配置中做闭环检测。

4. **重定向规则集中管理**：建议将重定向规则统一维护在 `RouteRedirector` 中，避免散落在各处导致难以维护。

---

### 场景3：复杂参数传参与返回值

**场景描述：** 多页面跳转中，页面间需要携带复杂参数并接收返回结果。典型场景如：商品列表页携带商品 ID 跳转商品详情页，详情页再跳转购物车页，购物车返回时需要携带选中的商品信息回到列表页。类似的还有地址选择页返回选中地址、筛选页返回筛选条件、日期选择页返回选定日期等。

**解决方案：** 使用 **`pushPathByName(name, param, onPop)` 的第三个参数注册返回回调** + **`pop(result)` 携带结果返回**。传参链路：push 时传入参数 → 目标页 `onReady` 中通过 `ctx.pathInfo.param` 接收 → 返回时 `pop(result)` → 发起页的 `onPop` 回调接收结果。

#### 步骤 1：定义参数类

将入参和返回值的类型定义集中管理，确保各页面可引用：

```typescript
// model/ShoppingParams.ets

/** 商品详情页入参 */
export class ProductDetailParam {
  productId: string = '';
  fromPage: string = '';
}

/** 购物车返回结果 */
export class CartResult {
  addedItems: CartItem[] = [];
  totalCount: number = 0;
  totalPrice: number = 0;
}

export class CartItem {
  productId: string = '';
  name: string = '';
  price: number = 0;
  quantity: number = 1;
}
```

> 💡 **类型检查用 `instanceof`，不要用 `typeof` 或字段嗅探**：`onPop` 回调里拿到的 `popInfo.result` 类型是 `Object`，必须先用 `instanceof` 判断真实类型、再访问字段。这正是步骤 1 把参数类集中定义在 `model/` 目录的原因——`instanceof` 要求类定义在调用方和回调方都可见。

```typescript
// 发送页的 onPop 回调中用 instanceof 做类型检查（类型确定后才访问字段）
this.navStack.pushPathByName('ProductDetail',
  { productId: item.id } as ProductDetailParam,
  (popInfo: PopInfo) => {
    // ★ 用 instanceof 判断返回结果的真实类型
    if (popInfo.result instanceof CartResult) {
      const result = popInfo.result as CartResult;
      this.cartCount += result.totalCount;
    }
    // result 不是 CartResult（如 undefined / 其他类型）时不进入分支，避免访问不存在字段崩溃
  }
);
```

#### 步骤 2：发送页（商品列表 → 商品详情）

通过 `pushPathByName` 的第三个参数注册 `onPop` 回调，接收目标页返回的结果：

```typescript
// ProductList.ets
// ShoppingParams 类型定义见步骤1（ProductDetailParam、CartResult、CartItem）
import { ProductDetailParam, CartResult } from '../model/ShoppingParams';

@Component
struct ProductList {
  navStack: NavPathStack = new NavPathStack();
  @State cartCount: number = 0;

  build() {
    NavDestination() {
      List() {
        ForEach(this.products, (item: Product) => {
          ListItem() {
            Row() { Text(item.name); Text(`¥${item.price}`) }
            .onClick(() => {
              // ★ 关键：第三个参数是 onPop 回调，接收目标页返回结果
              this.navStack.pushPathByName('ProductDetail',
                { productId: item.id } as ProductDetailParam,
                (popInfo: PopInfo) => {
                  const result = popInfo.result as CartResult;
                  if (result) { this.cartCount += result.totalCount; }
                }
              );
            })
          }
        })
      }
    }
    .onReady((ctx) => { this.navStack = ctx.pathStack; })
  }
}
```

#### 步骤 3：中间页（商品详情 → 跳转购物车）

在 `onReady` 中通过 `ctx.pathInfo.param` 接收上一个页面传入的参数：

```typescript
// ProductDetail.ets
// ShoppingParams 类型定义见步骤1
import { ProductDetailParam } from '../model/ShoppingParams';

@Component
struct ProductDetail {
  navStack: NavPathStack = new NavPathStack();
  private productId: string = '';

  build() {
    NavDestination() {
      Column() {
        Text(`商品详情 ${this.productId}`)
        Button('加入购物车').onClick(() => {
          this.navStack.pushPathByName('ShoppingCart',
            { productId: this.productId });
        })
      }
    }
    .onReady((ctx) => {
      this.navStack = ctx.pathStack;
      const p = ctx.pathInfo.param as ProductDetailParam;
      this.productId = p?.productId ?? '';
    })
  }
}
```

#### 步骤 4：返回页（购物车 → 携带结果返回）

通过 `pop(result)` 将结果携带回发送页，发送页的 `onPop` 回调自动触发：

```typescript
// ShoppingCart.ets
// ShoppingParams 类型定义见步骤1
import { CartResult, CartItem } from '../model/ShoppingParams';

@Component
struct ShoppingCart {
  navStack: NavPathStack = new NavPathStack();
  @State selectedItems: CartItem[] = [];

  build() {
    NavDestination() {
      Column() {
        Text('购物车')
        Button('确认选择').onClick(() => {
          // ★ 关键：pop 时携带返回结果，触发发起页的 onPop 回调
          const result = new CartResult();
          result.addedItems = this.selectedItems;
          result.totalCount = this.selectedItems.length;
          result.totalPrice = this.selectedItems.reduce((s, i) => s + i.price * i.quantity, 0);
          this.navStack.pop(result);
        })
      }
    }
    .onReady((ctx) => { this.navStack = ctx.pathStack; })
  }
}
```

#### 关键 API 说明

| API | 说明 |
|-----|------|
| `pushPathByName(name, param, onPop)` | 跳转并传参，`onPop` 回调接收目标页返回的结果 |
| `ctx.pathInfo.param` | 目标页在 `onReady` 中接收上一个页面传入的参数 |
| `navStack.pop(result)` | 返回上一层并携带结果，触发发起页的 `onPop` 回调 |
| `PopInfo.result` | `onPop` 回调中获取返回页携带的结果对象 |
| `onReady((ctx) => {})` | NavDestination 生命周期回调，用于接收参数和获取 pathStack |

#### 注意事项

1. **参数类需在同一模块可访问**：`instanceof` 类型检查要求类定义（如 `ProductDetailParam`、`CartResult`）在目标页面可引用的位置，建议集中定义在 `model/` 目录下。

2. **参数必须可序列化**：不能传递函数、Symbol 等不可序列化的值，只能传递基本类型和可序列化的对象。

3. **不建议传递过大对象**：大图片、长列表等应通过全局状态管理（AppStorage、PersistentStorage）共享，参数仅传递索引或 ID。

4. **`onPop` 回调链**：A push B（注册 onPop）→ B push C → C pop(result) → B 收到结果 → B pop(result) → A 的 onPop 收到。多层跳转时注意结果是否需要逐层透传。

---

### 场景4：三分栏邮箱场景（SideBarContainer + Navigation 多端适配）

**场景描述：** 邮箱类应用需要在不同设备上呈现不同栏数：手机单栏（列表→详情），折叠屏双栏（列表+详情），平板/PC 三栏（侧边栏+列表+详情）。核心路由痛点：分栏下每次点击邮件都 `push` 导致路由栈无限增长；断点切换时路由栈残留；右侧无默认内容留白。

**解决方案：** 使用 **`SideBarContainer` 包裹 `Navigation`**。分栏下邮件切换用 **`replacePathByName`**（避免路由栈爆炸），单栏下用 `pushPathByName`。通过断点检测驱动 Navigation 的 Stack/Split 模式切换，`onNavigationModeChange` 同步路由策略。

#### 各断点下的路由策略

| 设备 | 断点 | Navigation 模式 | 邮件切换 API | hideBackButton |
|------|------|----------------|-------------|---------------|
| 手机竖屏 | sm | Stack 单栏 | `pushPathByName` | false |
| 折叠屏展开 | md | Split 双栏 | `replacePathByName` | true |
| 平板 | lg | Split 分栏 | `replacePathByName` | true |
| PC/2in1 | xl | Split 分栏 | `replacePathByName` | true |

#### 步骤 1：路由辅助类（分栏 replace / 单栏 push）

三分栏开发中**最关键**的封装——根据 Navigation 模式自动选择 push 或 replace：

```typescript
// common/RouterHelper.ets
export class RouterHelper {
  private navPathStack: NavPathStack;
  private isSplitMode: boolean = false;

  constructor(navPathStack: NavPathStack) {
    this.navPathStack = navPathStack;
  }

  setMode(mode: NavigationMode): void {
    this.isSplitMode = (mode === NavigationMode.Split);
  }

  /**
   * 跳转到详情页
   * - 单栏：push 新页面（有返回按钮）
   * - 分栏：replace 替换右侧内容（避免路由栈无限增长）
   */
  navigateToDetail(name: string, param?: Object, animated: boolean = true): void {
    if (this.isSplitMode) {
      if (this.navPathStack.size() > 0) {
        this.navPathStack.replacePathByName(name, param, animated);
      } else {
        this.navPathStack.pushPathByName(name, param, animated);
      }
    } else {
      this.navPathStack.pushPathByName(name, param, animated);
    }
  }

  /** 从详情跳子页面（查看附件等），始终 push */
  navigateToSubPage(name: string, param?: Object): void {
    this.navPathStack.pushPathByName(name, param);
  }

  goBack(result?: Object): void {
    if (this.navPathStack.size() > 0) {
      this.navPathStack.pop(result, true);
    }
  }
}
```

#### 步骤 2a：断点驱动 Stack/Split 模式切换（必须用断点驱动，禁止 NavigationMode.Auto）

嵌套顺序：`SideBarContainer > Column > Navigation`。**最关键的一行**是根据断点切换 Navigation 的 `mode`——`sm` 单栏用 `Stack`，其余用 `Split`。**必须用断点驱动，不要用 `NavigationMode.Auto`**（手机横屏会误触分栏）。

> 📌 步骤 2a → 2b → 2c 是**同一个 `Index` 组件的顺序片段**，按顺序拼接才是完整可编译代码，三块都不可省略。

```typescript
// pages/Index.ets — 步骤 2a：Navigation 容器 + 断点驱动（续步骤 1 的 RouterHelper）
@Entry
@Component
struct Index {
  @Provide('navPathStack') navPathStack: NavPathStack = new NavPathStack()
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'
  private routerHelper: RouterHelper = new RouterHelper(this.navPathStack)

  build() {
    SideBarContainer(/* 断点决定 Overlay/Embed */) {
      Column() { /* 第一栏：侧边栏（账户/文件夹），点击时 clear() 路由栈 */ }
      Column() {
        Navigation(this.navPathStack) {
          // 第二栏：邮件列表（NavBar）
          // 点击邮件 → this.routerHelper.navigateToDetail('MailDetail', mail)
        }
        // 🔑 核心：断点驱动 Stack/Split 切换（不要用 NavigationMode.Auto）
        .mode(this.currentBreakpoint === 'sm'
          ? NavigationMode.Stack : NavigationMode.Split)
        .navBarWidth(this.currentBreakpoint === 'md' ? '50%' : '40%')
        .navDestination(this.PageMap)   // PageMap 定义在步骤 2c
        // ↓↓↓ 步骤 2b：splitPlaceholder / onNavigationModeChange 接在这条 Navigation 链上 ↓↓↓
```

#### 步骤 2b：splitPlaceholder + onNavigationModeChange（必须实现，同步路由策略）

分栏下右侧默认是空的，用 `splitPlaceholder` 提供占位内容；`onNavigationModeChange` 在单/分栏切换时同步 `RouterHelper` 模式，并在首次进入分栏时静默 `push` 占位页。**两者都必须实现**（续 2a 的 Navigation 链，然后闭合 build）：

```typescript
        // 🔑 分栏空栈占位页（API 20+，不占路由栈位）
        .splitPlaceholder(() => {
          Column() { Text('请选择一封邮件查看详情') }
        })
        // 🔑 模式切换回调：同步路由策略 + 处理路由栈
        .onNavigationModeChange((mode: NavigationMode) => {
          this.routerHelper.setMode(mode);              // 同步步骤 1 的 RouterHelper
          if (mode === NavigationMode.Split && this.navPathStack.size() === 0) {
            this.navPathStack.pushPathByName('MailEmpty', null, false);  // 分栏首次进入补占位页
          }
        })
      }   // 闭合 Column（第二栏 + 第三栏）
    }   // 闭合 SideBarContainer
  }   // 闭合 build()
```

#### 步骤 2c：路由页面映射 PageMap（必须实现，闭合 struct）

`navDestination` 回调按页面名称分发到对应 NavDestination 组件。`PageMap` 是 `Index` 的 `@Builder` 成员，接在 `build()` 之后并闭合 struct：

```typescript
  // 🔑 路由页面映射（struct 成员，接 build() 之后）
  @Builder
  PageMap(name: string) {
    if (name === 'MailDetail') { MailDetailPage() }     // 见步骤 3
    else if (name === 'MailEmpty') { MailEmptyPage() }
  }
}   // 闭合 struct Index
```

#### 步骤 3：邮件详情页（分栏路由适配）

分栏模式下：隐藏返回按钮 + `onNewParam` 接收 replace 传入的新参数：

```typescript
// pages/MailDetailPage.ets（路由相关核心代码）
@Component
struct MailDetailPage {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'
  @State mail: MailItem | null = null

  build() {
    NavDestination() {
      // ... 邮件详情 UI 内容
    }
    .title(this.mail?.subject ?? '邮件详情')
    .hideBackButton(this.currentBreakpoint !== 'sm') // 🔑 分栏隐藏返回按钮（列表始终可见）
    .onNewParam((newParam: Object) => { this.mail = newParam as MailItem; }) // 🔑 replace 不重建页面，触发 onNewParam
    .onReady((ctx: NavDestinationContext) => {
      this.navPathStack = ctx.pathStack;
      this.mail = ctx.pathInfo.param as MailItem;
    })
  }
}
```

#### 进阶：断点变化时的路由栈同步

折叠屏折叠/展开时，自动处理路由栈状态（通过 `@Watch` 监听断点变化）：

```typescript
@Watch('onBreakpointChange')
@StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'

onBreakpointChange(): void {
  if (this.currentBreakpoint === 'sm') {
    // 折叠到手机态：栈中只有占位页时，清空回到纯列表
    if (this.navPathStack.size() === 1) {
      let names = this.navPathStack.getAllPathName();
      if (names.length > 0 && names[0] === 'MailEmpty') {
        this.navPathStack.clear();
      }
    }
  } else {
    // 展开到分栏态：栈为空时加载占位页
    if (this.navPathStack.size() === 0) {
      this.navPathStack.pushPathByName('MailEmpty', null, false);
    }
  }
}
```

#### 路由操作速查

| 操作 | 单栏（Stack） | 分栏（Split） | 原因 |
|------|--------------|--------------|------|
| 点击邮件进详情 | `pushPathByName` | `replacePathByName` | 分栏用 push 会导致路由栈无限增长 |
| 详情跳子页面 | `pushPathByName` | `pushPathByName` | 子页面需要独立栈位 |
| 返回上一页 | `pop` | `pop`（仅子页面） | 分栏下邮件列表始终在左侧 |
| 切换账户/文件夹 | `clear()` | `clear()` | 清空旧数据，避免显示旧详情 |

#### 关键 API 说明

| API | 说明 | 起始版本 |
|-----|------|---------|
| `NavigationMode.Stack / Split` | 单栏/分栏模式，断点驱动切换 | API 9+ |
| `onNavigationModeChange` | 模式切换回调，同步路由策略 | API 11+ |
| `replacePathByName` | 替换栈顶页面（分栏切换详情的核心 API） | API 11+ |
| `splitPlaceholder` | 分栏空栈占位页（不占路由栈位） | API 20+ |
| `NavDestination.onNewParam` | 页面被 replace 时接收新参数 | API 19+ |
| `NavDestination.hideBackButton` | 分栏模式隐藏返回按钮 | API 15+ |
| `navBarWidth` | NavBar 宽度（分栏时控制列表栏宽度） | API 9+ |

#### 注意事项

1. **嵌套顺序不可颠倒**：必须是 `SideBarContainer > Column > Navigation`，不能反过来。

2. **分栏邮件切换必须用 `replacePathByName`**：用 `push` 会导致路由栈无限增长。

3. **切换账户/文件夹时必须 `clear()` 路由栈**：否则右侧仍显示旧账户的邮件详情。

4. **`onNavigationModeChange` 是关键回调**：必须在此同步 `RouterHelper` 的模式状态。

5. **`onNewParam` 处理 replace 参数更新**：分栏下 `replacePathByName` 不重建 NavDestination，而是触发 `onNewParam`，必须在此更新数据。

6. **不要用 `NavigationMode.Auto`**：手机横屏可能误触分栏，建议断点驱动手动切换。

7. **不要在 Split 模式下 `hideNavBar(true)`**：会导致分栏退化为单栏。

8. **`splitPlaceholder` 与 push 占位页的关系**：`splitPlaceholder`（API 20+）是分栏空栈时系统自动展示的占位 UI，**不占路由栈位、不可获焦**；而 `onNavigationModeChange` 里 push 的 `MailEmpty` 是进入路由栈的真实页面，作用是让 `RouterHelper` 在分栏下始终有页面可 `replace`。两者职责不同：若最低支持 API 20 且不需对占位页做路由操作，可只用 `splitPlaceholder`、省去 push 占位页；本示例两者并存是为兼容更早版本并保证 `replace` 逻辑成立。

---

### 场景5：二分栏聊天应用场景（Navigation Split 多端适配）

**场景描述：** 聊天类应用（微信、钉钉）需要适配手机（单栏列表→详情）和平板/折叠屏展开态（左右分栏，列表+详情）。与三分栏邮箱场景不同，二分栏不需要 SideBarContainer，只需 Navigation 的 Stack/Split 模式切换即可。核心路由痛点相同：分栏下列表切换必须用 `replacePathByName` 避免路由栈爆炸。

**解决方案：** 使用 **Navigation 的 Split 模式**，NavBar 放会话列表，NavDestination 放聊天详情。路由策略与三分栏场景一致（RouterHelper 封装分栏 replace / 单栏 push）。本场景额外覆盖 **Navigation + Tabs 单栈方案**（底部 Tab 栏应用的全局路由管理）。

> 路由辅助类 `RouterHelper` 与三分栏场景完全相同，此处不再重复。参见[场景4：步骤 1](#步骤-1路由辅助类分栏-replace--单栏-push)。

#### 步骤 1a：Navigation 骨架 + 断点驱动 Stack/Split（必须用断点驱动，禁止 NavigationMode.Auto）

无需 SideBarContainer，直接用 Navigation 的 NavBar（会话列表）/ NavDestination（聊天详情）左右分栏。**最关键的一行**是根据断点切换 `mode`——`sm` 用 `Stack`，其余用 `Split`。**必须用断点驱动，不要用 `NavigationMode.Auto`**。

> 📌 步骤 1a → 1b → 1c 是**同一个 `Index` 组件的顺序片段**，按顺序拼接才是完整可编译代码，三块都不可省略。

```typescript
// pages/Index.ets — 步骤 1a：Navigation 容器 + 断点驱动（复用三分栏场景4步骤1 的 RouterHelper）
@Entry
@Component
struct Index {
  @Provide('navPathStack') navPathStack: NavPathStack = new NavPathStack()
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'
  @State selectedConvId: string = ''
  private routerHelper: RouterHelper = new RouterHelper(this.navPathStack)

  build() {
    Navigation(this.navPathStack) {
      // NavBar：会话列表
      Column() {
        List({ space: 0 }) {
          ForEach(this.conversations, (conv: Conversation) => {
            ListItem() { /* 会话列表项 */ }
            .onClick(() => {
              this.selectedConvId = conv.id;
              // 🔑 核心：分栏用 replace，单栏用 push（由 RouterHelper 自动选择）
              this.routerHelper.navigateToDetail('ChatDetail', conv);
            })
          })
        }
      }
    }
    // 🔑 核心：断点驱动 Stack/Split 切换（不要用 NavigationMode.Auto）
    .mode(this.currentBreakpoint === 'sm' ? NavigationMode.Stack : NavigationMode.Split)
    .navBarWidth(this.currentBreakpoint === 'lg' ? '44.5%' : '50%')
    .navDestination(this.buildNavDestination)   // 定义在步骤 1c
    // ↓↓↓ 步骤 1b：onNavigationModeChange 接在这条 Navigation 链上 ↓↓↓
```

#### 步骤 1b：onNavigationModeChange 模式切换回调（必须实现，同步路由策略）

分栏首次进入时右侧为空，需在模式切换回调里同步 `RouterHelper` 模式并静默 `push` 占位页。**必须实现**（续 1a 的 Navigation 链，然后闭合 build）：

```typescript
    // 🔑 模式切换回调：同步路由策略 + 分栏空栈处理
    .onNavigationModeChange((mode: NavigationMode) => {
      this.routerHelper.setMode(mode);              // 同步 RouterHelper 的模式状态
      if (mode === NavigationMode.Split && this.navPathStack.size() === 0) {
        this.navPathStack.pushPathByName('ChatEmpty', null, false);  // 分栏首次进入补占位页
      }
    })
  }   // 闭合 build()
```

#### 步骤 1c：路由页面映射 buildNavDestination（必须实现，闭合 struct）

`navDestination` 回调按页面名称分发到对应 NavDestination 组件，接在 `build()` 之后并闭合 struct：

```typescript
  // 🔑 路由页面映射（struct 成员，接 build() 之后）
  @Builder
  buildNavDestination(name: string, param: Object) {
    if (name === 'ChatDetail') { ChatDetailPage({ contact: param as Conversation }) }
    else if (name === 'ChatEmpty') { ChatEmptyPage() }
  }
}   // 闭合 struct Index
```

#### 步骤 2：聊天详情页（分栏路由适配）

与三分栏详情页路由逻辑相同：`hideBackButton` + `onNewParam`：

```typescript
// pages/ChatDetailPage.ets（路由相关核心代码）
@Component
struct ChatDetailPage {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'
  @State contact: Conversation | null = null

  build() {
    NavDestination() {
      // ... 聊天内容 UI
    }
    .title(this.contact?.name ?? '')
    .hideBackButton(this.currentBreakpoint !== 'sm') // 🔑 分栏隐藏返回按钮
    .onNewParam((newParam: Object) => { this.contact = newParam as Conversation; }) // 🔑 replace 参数刷新
    .onReady((ctx: NavDestinationContext) => {
      this.navPathStack = ctx.pathStack;
      this.contact = ctx.pathInfo.param as Conversation;
    })
  }
}
```

#### 进阶：Navigation + Tabs 单栈方案

当应用有底部 Tab 栏（如微信：消息/通讯录/发现/我），可用 **Navigation 嵌套 Tabs，单一 NavPathStack 管理整个应用路由**：

```typescript
// Navigation + Tabs 单栈方案
@Entry
@Component
struct Index {
  @Provide('pageInfo') pageInfo: NavPathStack = new NavPathStack()
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'
  @State currentPageIndex: number = 0

  build() {
    Navigation(this.pageInfo) {
      Tabs({ index: this.currentPageIndex,
        barPosition: this.currentBreakpoint === 'lg' ? BarPosition.Start : BarPosition.End
      }) {
        TabContent() { MessagesPage() }.tabBar('消息')
        // ... 其他 TabContent
      }
      .vertical(this.currentBreakpoint === 'lg') // 大屏侧边 Tab，小屏底部 Tab
      .onChange((index: number) => {
        this.currentPageIndex = index;
        this.pageInfo.clear(); // 🔑 切换 Tab 时清空路由栈
        if (this.currentBreakpoint !== 'sm') {
          this.pageInfo.pushPath({ name: 'ConversationDetailNone' });
        }
      })
    }
    .hideTitleBar(true)
    .mode(this.currentBreakpoint === 'sm' ? NavigationMode.Stack : NavigationMode.Split)
    .navBarWidth(this.currentBreakpoint === 'lg' ? '44.5%' : '50%')
    .navDestination(this.PageMap)
  }
}
```

单栈 vs 每 Tab 独立栈对比：

| 维度 | 每 Tab 独立栈 | Navigation + Tabs 单栈 |
|------|-------------|----------------------|
| 路由隔离 | ✅ Tab 间完全独立 | ❌ 共享路由栈 |
| 管理复杂度 | 高（多个 NavPathStack） | 低（单一 NavPathStack） |
| Tab 切换 | 栈状态自动保留 | 需手动清栈/恢复 |
| 适用场景 | 各 Tab 路由逻辑差异大 | 各 Tab 结构相似（IM 场景） |

#### 进阶：折叠屏断点变化处理

```typescript
@Watch('onBreakpointChange')
currentBreakpoint: string = 'sm'

onBreakpointChange() {
  if (this.currentBreakpoint !== 'sm') {
    if (this.pageInfo.size() === 0) this.pageInfo.pushPath({ name: 'ConversationDetailNone' });
  } else {
    if (this.pageInfo.size() === 1) this.pageInfo.pop(); // 只有占位页时清空回到列表
  }
}
```

#### 路由操作速查

| 操作 | 单栏（Stack） | 分栏（Split） | 原因 |
|------|--------------|--------------|------|
| 点击会话进详情 | `pushPathByName` | `replacePathByName` | 分栏用 push 会导致路由栈无限增长 |
| 详情跳子页面 | `pushPathByName` | `pushPathByName` | 子页面需要独立栈位 |
| 返回上一页 | `pop` | `pop`（仅子页面） | 分栏下列表始终在左侧 |
| 切换 Tab | `clear()` + 按需 push | `clear()` + push 占位页 | 清空旧栈，加载新 Tab 默认页 |

#### 注意事项

1. **分栏列表切换必须用 `replacePathByName`**：与三分栏场景一致，用 `push` 会导致路由栈无限增长。

2. **分栏下 NavBar 不受路由栈控制**：`push`/`pop`/`replace` 只影响右侧内容区，左侧 NavBar 无法通过路由 API 操作。

3. **`onNavigationModeChange` 是关键回调**：必须在此同步路由策略，并确保分栏时右侧有内容（否则右侧留白）。

4. **不要在 Split 模式下 `hideNavBar(true)`**：会导致分栏退化为单栏。

5. **手机横屏防误入分栏**：`NavigationMode.Auto` 断点为 600vp，手机横屏可能触发。建议用断点驱动手动切换。

6. **占位页策略同三分栏场景**：`onNavigationModeChange` 里 push 的 `ChatEmpty` 是占位用的真实路由页（让分栏下有页面可 `replace`），与三分栏场景的 `MailEmpty` 作用一致；若最低支持 API 20，也可改用 `splitPlaceholder`（空栈自动占位、不占栈位）省去 push 占位页。

---

## 三、构建子页面，配置，使能Navigation路由表

### 场景1：路由拦截权限校验（声明式权限 + 集中式拦截）

**场景描述：** 应用中并非所有页面都需要登录才能访问（如首页、商品列表是公开的，而个人中心、订单列表需要登录）。如果在每个页面的 `onReady` 中单独写登录判断逻辑，会导致代码重复、容易遗漏、维护困难。最佳实践是在系统路由表（`router_map.json`）的 `data` 字段中声明式标记页面权限属性，通过 `NavPathStack.setInterception` 路由拦截器在 `willShow` 回调中统一读取并校验，实现**声明式权限 + 集中式拦截**。

**解决方案：** 使用 **`router_map.json` 的 `data` 字段声明式标记权限**（`requireAuth`、`requireVIP` 等） + **`setInterception` 的 `willShow` 回调集中拦截** + **`NavDestinationContext.getConfigInRouteMap()` 运行时读取 data**。页面代码无需关心权限逻辑，拦截器统一处理鉴权、跳转登录页、登录后回跳。

#### 拦截回调选择：为什么用 willShow

`setInterception()` 的 `NavigationInterception` 对象有 4 个回调：

| 回调 | API 版本 | 触发时机 | 页面是否已创建 | 能否读 `getConfigInRouteMap()` |
|------|----------|----------|---------------|-------------------------------|
| `interception` | **22** | 页面创建前 | ❌ 未创建 | ❌ 不能（参数是 `NavPathInfo`） |
| `willShow` | **12** | 页面创建后、显示前 | ✅ 已创建 | ✅ 能（参数是 `NavDestinationContext`） |
| `didShow` | **12** | 页面显示后 | ✅ 已创建 | ✅ 能 |
| `modeChange` | **12** | 单双栏切换时 | — | — |

本方案使用 `willShow`，原因：
1. 需要通过 `getConfigInRouteMap()` 读取路由表 `data` 字段——`interception` 的参数是 `NavPathInfo`（只有 name/param），拿不到这个方法
2. `willShow` 从 API 12 就可用，兼容性最好
3. `interception`（API 22+）适合纯名称级别的硬编码重定向（如 A/B 测试 pageA → pageA'），不适合需要读 data 的权限校验场景

#### 步骤 1：在路由表中声明 data 权限标记

在 `resources/base/profile/router_map.json` 中为每个页面配置 `data` 字段：

```json
{
  "routerMap": [
    {
      "name": "HomePage",
      "pageSourceFile": "src/main/ets/pages/HomePage.ets",
      "buildFunction": "HomePageBuilder",
      "data": { "requireAuth": false, "title": "首页", "trackId": "page_home" }
    },
    {
      "name": "LoginPage",
      "pageSourceFile": "src/main/ets/pages/LoginPage.ets",
      "buildFunction": "LoginPageBuilder",
      "data": { "requireAuth": false, "title": "登录" }
    },
    {
      "name": "OrderList",
      "pageSourceFile": "src/main/ets/pages/OrderList.ets",
      "buildFunction": "OrderListBuilder",
      "data": { "requireAuth": true, "title": "订单列表", "trackId": "page_order_list" }
    },
    {
      "name": "Settings",
      "pageSourceFile": "src/main/ets/pages/Settings.ets",
      "buildFunction": "SettingsBuilder",
      "data": { "requireAuth": true, "requireVIP": true, "title": "VIP 设置" }
    }
  ]
}
```

`data` 字段说明：

| 字段 | 类型 | 说明 |
|------|------|------|
| `requireAuth` | boolean | 是否需要登录才能访问 |
| `requireVIP` | boolean | 是否需要 VIP 权限 |
| `title` | string | 页面标题（可用于统一标题栏配置） |
| `trackId` | string | 埋点 ID（可用于统一页面访问统计） |

> 💡 `data` 字段是完全自定义的键值对，开发者可以根据业务需要自由扩展（如 `role`、`minVersion`、`orientation` 等）。

#### 步骤 2：在 module.json5 中注册路由表

```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "routerMap": "$profile:router_map"
  }
}
```

#### 步骤 3：实现统一路由拦截器

在 `willShow` 回调中通过 `getConfigInRouteMap()` 读取路由表 `data` 配置，统一检查权限：

```typescript
// AuthInterceptor.ets
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'AuthInterceptor';

/**
 * 路由表 data 字段中的权限配置结构
 */
interface RouteAuthConfig {
  requireAuth?: boolean;
  requireVIP?: boolean;
  title?: string;
  trackId?: string;
  [key: string]: Object | undefined;
}

/**
 * 登录状态管理（示例，实际项目中替换为真实的账号模块）
 */
export class AuthManager {
  private static isLoggedIn: boolean = false;
  private static isVIP: boolean = false;

  static setLoginStatus(loggedIn: boolean): void {
    AuthManager.isLoggedIn = loggedIn;
  }

  static setVIPStatus(isVIP: boolean): void {
    AuthManager.isVIP = isVIP;
  }

  static checkLoggedIn(): boolean {
    return AuthManager.isLoggedIn;
  }

  static checkIsVIP(): boolean {
    return AuthManager.isVIP;
  }
}

/**
 * 注册路由鉴权拦截器
 * 在 willShow 回调中统一检查页面权限
 */
export function setupAuthInterceptor(pageStack: NavPathStack): void {
  pageStack.setInterception({
    willShow: (from: NavDestinationContext | 'navBar',
               to: NavDestinationContext | 'navBar',
               operation: NavigationOperation,
               animated: boolean) => {
      // 目标是 navBar（首页导航栏），直接放行
      if (typeof to === 'string') {
        hilog.info(DOMAIN, TAG, 'Target is navBar, allow.');
        return;
      }

      const target = to as NavDestinationContext;
      const pageName = target.pathInfo.name;

      // 读取路由表中的 data 配置
      const config = target.getConfigInRouteMap();
      if (!config || !config.data) {
        hilog.info(DOMAIN, TAG, `Page [${pageName}] has no data config, allow.`);
        return;
      }

      const routeData = config.data as Record<string, Object>;
      hilog.info(DOMAIN, TAG, `Page [${pageName}] route data: ${JSON.stringify(routeData)}`);

      // 检查是否需要登录
      const requireAuth = routeData['requireAuth'];
      if (requireAuth === true && !AuthManager.checkLoggedIn()) {
        hilog.warn(DOMAIN, TAG, `Page [${pageName}] requires auth, redirecting to LoginPage.`);
        // 拦截：先 pop 刚入栈的目标页面，再 push 到登录页
        target.pathStack.pop();
        // 将原始目标页面名称作为参数传给登录页，登录成功后可自动跳回
        target.pathStack.pushPathByName('LoginPage', { targetPage: pageName });
        return;
      }

      // 检查是否需要 VIP
      const requireVIP = routeData['requireVIP'];
      if (requireVIP === true && !AuthManager.checkIsVIP()) {
        hilog.warn(DOMAIN, TAG, `Page [${pageName}] requires VIP, redirecting to VIP page.`);
        target.pathStack.pop();
        target.pathStack.pushPathByName('LoginPage', {
          targetPage: pageName,
          reason: 'vip_required'
        });
        return;
      }

      // 埋点：统一记录页面访问
      const trackId = routeData['trackId'];
      if (trackId) {
        hilog.info(DOMAIN, TAG, `Page track: ${trackId}`);
        // TODO: 调用实际的埋点 SDK
      }

      hilog.info(DOMAIN, TAG, `Page [${pageName}] auth check passed.`);
    }
  });
}
```

#### 步骤 4：Navigation 主页接入拦截器

```typescript
// Index.ets
// AuthInterceptor 的完整代码见上方步骤3（同项目内模块）
import { setupAuthInterceptor, AuthManager } from '../common/AuthInterceptor';

@Entry
@Component
struct Index {
  pageStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    // 注册路由鉴权拦截器
    setupAuthInterceptor(this.pageStack);
  }

  build() {
    Navigation(this.pageStack) {
      Column({ space: 20 }) {
        // 无需登录 — 直接跳转
        Button('首页').onClick(() => this.pageStack.pushPathByName('HomePage', null))
        // 需要登录 — 未登录时自动拦截到登录页
        Button('订单列表').onClick(() => this.pageStack.pushPathByName('OrderList', null))
        // 需要 VIP
        Button('VIP 设置').onClick(() => this.pageStack.pushPathByName('Settings', null))
        Divider()
        // 模拟登录/退出（仅演示用）
        Button('模拟登录').onClick(() => AuthManager.setLoginStatus(true))
        Button('模拟退出').onClick(() => AuthManager.setLoginStatus(false))
      }
      .width('100%').height('100%')
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    }
    .title('首页')
    .mode(NavigationMode.Stack)
  }
}
```

#### 步骤 5：登录页实现（登录成功后跳回目标页）

```typescript
// LoginPage.ets
// AuthManager 定义在步骤3的 AuthInterceptor.ets 中（同项目内模块）
import { AuthManager } from '../common/AuthInterceptor';

interface LoginParam {
  targetPage?: string;
  reason?: string;
}

@Builder
export function LoginPageBuilder(name: string, param: Object) {
  LoginPage({ param: param as LoginParam });
}

@Component
struct LoginPage {
  navPathStack: NavPathStack = new NavPathStack();
  private param: LoginParam = {};

  build() {
    NavDestination() {
      Column({ space: 20 }) {
        if (this.param.reason === 'vip_required') {
          Text('该功能需要 VIP 权限，请先开通 VIP')
        }
        // ... 用户名/密码输入框

        Button('登录').onClick(() => {
          AuthManager.setLoginStatus(true);  // 模拟登录
          if (this.param.targetPage) {
            // ★ 登录成功后 replace 到原始目标页，用户按返回不会回到登录页
            this.navPathStack.replacePathByName(this.param.targetPage, null);
          } else {
            this.navPathStack.pop();
          }
        })
        Button('返回').onClick(() => this.navPathStack.pop())
      }
      .width('100%').height('100%')
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    }
    .title('登录')
    .onReady((ctx: NavDestinationContext) => {
      this.navPathStack = ctx.pathStack;
      const p = ctx.pathInfo.param as LoginParam;
      if (p) { this.param = p; }
    })
  }
}
```


#### 进阶：data 字段的更多用途

路由表 `data` 字段是通用键值对，除了登录校验，还可以标记其他元数据，在拦截器中统一处理：

```json
{
  "name": "VideoPlayer",
  "pageSourceFile": "src/main/ets/pages/VideoPlayer.ets",
  "buildFunction": "VideoPlayerBuilder",
  "data": {
    "requireAuth": true, "requireVIP": false,
    "orientation": "landscape", "trackId": "page_video_player",
    "enableGesture": true, "keepAlive": false
  }
}
```

拦截器中按需扩展处理逻辑（登录/VIP 校验代码同步骤3，此处省略）：

```typescript
// 在 willShow 回调中继续添加：
// 3. 页面方向控制
if (data['orientation'] === 'landscape') {
  // target.getUIContext()?.setPreferredOrientation(WindowOrientation.LANDSCAPE);
}
// 4. 统一埋点
if (data['trackId']) {
  // AnalyticsService.trackPageView(data['trackId'] as string);
}
```

页面自身也可以在 `onReady` 中读取 data：

```typescript
.onReady((ctx: NavDestinationContext) => {
  const config = ctx.getConfigInRouteMap();
  if (config?.data) {
    const data = config.data as Record<string, Object>;
    console.info('Title:', data['title'], 'TrackId:', data['trackId']);
  }
})
```

#### 关键 API 说明

| API | 说明 | 起始版本 |
|-----|------|---------|
| `router_map.json` → `data` | 路由表中的自定义键值对元数据 | API 12+ |
| `NavDestinationContext.getConfigInRouteMap()` | 在页面上下文中获取路由表配置（含 data） | API 12+ |
| `NavPathStack.setInterception()` | 设置路由拦截回调 | API 12+ |
| `NavigationInterception.willShow` | 页面显示前拦截（此时页面已创建，可读 data） | API 12+ |
| `NavigationInterception.interception` | 页面创建前拦截（参数是 NavPathInfo，无法读 data） | API 22+ |
| `NavPathStack.pop()` | 弹出栈顶页面（拦截时先移除已入栈的目标页） | API 11+ |
| `NavPathStack.pushPathByName()` | 按名称 push 页面 | API 10+ |
| `NavPathStack.replacePathByName()` | 按名称替换栈顶页面（登录成功后用） | API 11+ |

#### 注意事项

1. **为什么不用 `interception`**：`interception`（API 22+）触发时页面尚未创建，参数是 `NavPathInfo`（只有 name/param），无法调用 `getConfigInRouteMap()` 读取 data 字段。`willShow`（API 12+）触发时页面已创建，参数是 `NavDestinationContext`，可直接读取 data，兼容性更好。

2. **拦截时路由栈已变化**：无论是哪个回调，进入回调时路由栈都已经发生了变化。所以在拦截时需要先 `pop` 掉刚入栈的目标页面，再 `push` 登录页。

3. **登录页自身不要标记 `requireAuth: true`**：否则会陷入无限拦截循环（登录页 → 拦截 → 又跳登录页）。

4. **登录成功后的跳转使用 `replacePathByName`**：这样登录页会被替换为目标页面，用户按返回键时不会回到登录页。

5. **data 字段是自由格式的 Object**：可以放任意键值对，系统不做校验。开发者需要自行约定字段含义并在拦截器中正确解析。

6. **跨模块场景**：HAP/HSP/HAR 各模块独立配置 `router_map.json`，`getConfigInRouteMap()` 只能读取当前页面所在模块的路由表配置。

---

### 场景2：NavDestination 页面级方向控制

**场景描述：** 短视频应用中，视频列表页**竖屏**浏览，点击视频进入全屏播放页后**横屏**沉浸观看，返回时自动恢复竖屏。需要不同 NavDestination 页面拥有不同的屏幕方向，且方向随路由栈自动管理。

**解决方案：** 使用 NavDestination 的 **`.preferredOrientation()`** 声明式设置页面方向，配合 **`.enableStatusBar(false)`** 隐藏状态栏、**`.enableNavigationIndicator(false)`** 隐藏导航条、**`.ignoreLayoutSafeArea()`** 铺满安全区域，实现沉浸式全屏。pop 时系统自动恢复上一页方向，无需手动管理。

#### 相比 window.setPreferredOrientation 的优势

| | `window.setPreferredOrientation()` | `NavDestination.preferredOrientation()` |
|---|---|---|
| 方向恢复 | 必须在 `aboutToDisappear` 手动恢复，忘了就卡在横屏 | pop 时系统**自动恢复**上一页方向 |
| 状态管理 | 需要 isLandscape 状态 + windowSizeChange 监听 | **无状态管理**，不需要任何监听 |
| 返回键 | 必须在 `onBackPressed` 中拦截并手动恢复 | **无需拦截** |
| 代码量 | ~400 行 | **~10 行** |
| 出错风险 | 高——忘记恢复、忘记注销、生命周期时序问题 | 低——声明式，系统保证正确性 |

> 一句话：需要跳转到新页面就横屏 → 用 `preferredOrientation`；需要在同一个页面内动态切换 → 用 `window.setPreferredOrientation`。

#### 步骤 1：配置应用默认方向和路由表

在 `module.json5` 中设置应用默认竖屏：

```json5
// module.json5
{
  "module": {
    "abilities": [{
      "name": "EntryAbility",
      "orientation": "portrait"  // 应用默认竖屏
    }]
  }
}
```

在路由表中注册视频列表页和播放页：

```json
// resources/base/profile/route_map.json
{
  "routerMap": [
    { "name": "VideoList", "pageSourceFile": "src/main/ets/pages/Index.ets" },
    { "name": "VideoPlayer", "pageSourceFile": "src/main/ets/video/VideoPlayerPage.ets" }
  ]
}
```

#### 步骤 2：竖屏列表页

Navigation 必须 `.width('100%').height('100%')` 铺满，否则 `preferredOrientation` 静默不生效：

```typescript
// entry/src/main/ets/pages/Index.ets
@Entry
@Component
struct Index {
  private stack: NavPathStack = new NavPathStack();

  build() {
    Navigation(this.stack) {
      List({ space: 12 }) {
        ForEach(['视频1', '视频2', '视频3'], (item: string) => {
          ListItem() {
            Text(item)
              .width('100%').height(200).textAlign(TextAlign.Center)
              .onClick(() => {
                this.stack.pushPath({ name: 'VideoPlayer', param: { title: item } });
              })
          }
        }, (item: string) => item)
      }
    }
    .width('100%')
    .height('100%')          // ★ Navigation 必须铺满，否则 preferredOrientation 不生效
    .mode(NavigationMode.Stack)
    .hideNavBar(true)
    .navDestination(this.pageMap)
  }

  @Builder
  pageMap(name: string) {
    if (name === 'VideoPlayer') {
      VideoPlayerPage();
    }
  }
}
```

#### 步骤 3：横屏全屏播放页

在 NavDestination 上声明横屏方向 + 沉浸式配置，只需几行代码：

```typescript
// entry/src/main/ets/video/VideoPlayerPage.ets
import { window } from '@kit.ArkUI';  // 系统标准 Kit，无需额外创建

@Component
struct VideoPlayerPage {
  private stack: NavPathStack | undefined = undefined;

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Center }) {
        // ... 横屏播放内容
        Button('返回').onClick(() => {
          this.stack?.pop();  // ★ pop 后系统自动恢复竖屏，无需手动处理
        })
      }
      .width('100%').height('100%')
    }
    .hideTitleBar(true)
    .preferredOrientation(window.Orientation.LANDSCAPE)      // ★ 核心：声明横屏
    .enableStatusBar(false)                                   // 隐藏状态栏（沉浸式）
    .enableNavigationIndicator(false)                         // 隐藏导航条
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM],
      [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])   // 铺满安全区域
    .onReady((ctx: NavDestinationContext) => {
      this.stack = ctx.pathStack;
    })
  }
}
```

#### 多级页面的方向恢复

路由栈中每一页都可以独立声明方向，系统按栈顶方向自动切换：

```
A(竖屏) → push B(横屏) → push C(竖屏)

栈状态          系统窗口方向
─────────────────────────
A              竖屏
A → B          横屏（自动切换）
A → B → C      竖屏（自动切换）
A → B          横屏（pop C，自动恢复 B 的方向）
A              竖屏（pop B，自动恢复 A 的方向）
```

如果某一页没有设置 `preferredOrientation`，则恢复到 `module.json5` 中的默认方向。

#### 关键 API 说明

| API | 说明 | 起始版本 |
|-----|------|---------|
| `.preferredOrientation(orientation)` | 声明该页面方向。进入时系统自动旋转，离开时自动恢复上一页方向 | API 19+ |
| `.enableStatusBar(enabled, animated?)` | 进入该页面时显示/隐藏状态栏 | API 19+ |
| `.enableNavigationIndicator(enabled)` | 进入该页面时显示/隐藏底部导航条 | API 19+ |
| `.ignoreLayoutSafeArea(types, edges)` | 内容铺满安全区域（横屏全屏时配合使用，否则有黑边） | API 12+ |

**生效条件**（三个必须同时满足）：
1. NavDestination 属于应用主窗口页面，且主窗口为全屏窗口
2. Navigation 大小占满整个应用页面（`.width('100%').height('100%')`）
3. NavDestination 类型为 `NavDestinationMode.STANDARD`（非 DIALOG）

#### 注意事项

1. **API 19+ 才有此接口**：兼容低版本需要在页面的 `onShown`/`onHidden` 中手动调用 `window.setPreferredOrientation()` 降级。

2. **Navigation 必须铺满**：外层不能包其他容器导致 Navigation 尺寸不足，否则 `preferredOrientation` 静默不生效。

3. **不需要手动恢复方向**：pop 时系统自动恢复，不要在 `onBackPressed` 或 `aboutToDisappear` 中再调 `setPreferredOrientation()`。

4. **`ignoreLayoutSafeArea` 配合使用**：隐藏状态栏和导航条后，必须让内容铺满安全区域，否则上下会有黑边。

5. **转场闪烁**：如果页面转场动画过程中发生旋转导致闪烁，可用 `.systemTransition(NavigationSystemTransitionType.FADE)` 改为淡入淡出。

---

### 场景3：多模块统一动态路由

**场景描述：** 多模块应用中，主模块（HAP）和多个业务模块（HAR/HSP）各自拥有页面，页面之间需要自由跳转——harA 的页面跳到 harB 的页面，harB 再跳到 harC。但模块之间不能有编译期依赖，否则静态 `import` 会导致编译耦合、启动变慢、循环依赖风险。

**解决方案：** 使用 **RouterModule（共享 HAR）+ 动态 `import()` 三层分发**。RouterModule 维护全局 `builderMap`（页面注册表）和 `routerMap`（路由栈引用），跳转时通过 `dynamic import` 按需加载目标 HAR 模块和页面文件，模块间零编译依赖。

#### 与系统路由表的对比

| | 系统路由表 | 自定义路由表（本方案） |
|---|---|---|
| 怎么做 | 每个模块配 `router_map.json`，系统自动管理 | 自己写 RouterModule 维护路由注册表 |
| 动态加载 | 系统自动按需加载 | 手动 `import()` 三层分发 |
| 适用场景 | 标准跨包跳转，不需要自定义逻辑 | 需要路由拦截、鉴权、参数预处理等扩展 |
| API 版本 | API 12+ | API 9+ |

> 如果你的场景只是简单的跨包跳转，不需要自定义逻辑，**系统路由表更简单**——在每个模块的 `resources/base/profile/router_map.json` 中配置路由，然后用 `pushPathByName()` 跳转即可。本方案适用于需要在跳转前做拦截（如登录检查）、统一处理路由参数、或对路由行为做高度定制的场景。

#### 模块架构

```
                    RouterModule (共享 HAR)
                   ┌──────────────────────┐
                   │ builderMap: 页面注册表 │
                   │ routerMap:  路由栈引用  │
                   │ push/pop/clear/register│
                   └─────────┬────────────┘
                             │ 被所有模块依赖
              ┌──────────────┼──────────────┐
              │              │              │
          entry (HAP)     harA (HAR)     harB (HAR)
          ┌─────────┐   ┌─────────┐   ┌─────────┐
          │Navigation│   │ A1, A2  │   │B1, B2, B3│
          │NavPathStack│  │harInit()│   │harInit() │
          └─────────┘   └─────────┘   └─────────┘
```

#### 三层动态加载

```
第1层：push 时   dynamic import(harName)     → 加载 HAR 模块入口
第2层：harInit() dynamic import("./page")     → 加载具体页面文件
第3层：页面文件   wrapBuilder + registerBuilder → 注册 @Builder 到 builderMap
```

之后 `Navigation` 的 `navDestination` 回调从 builderMap 中查找并渲染页面。

#### 步骤 1：RouterModule —— 路由基础设施

RouterModule 是独立的 HAR，被所有业务模块和 entry 共同依赖。维护两个全局 Map：

```typescript
// RouterModule/src/main/ets/utils/RouterModule.ets
// RouterModel 定义在步骤2（同 RouterModule 内模块）
import { RouterModel } from '../model/RouterModel';

export class RouterModule {
  // 页面注册表：name → @Builder 包装对象
  static builderMap: Map<string, WrappedBuilder<[object]>> = new Map();
  // 路由栈引用：name → NavPathStack
  static routerMap: Map<string, NavPathStack> = new Map();

  // ★ 核心：构造路由信息 → 动态 import → pushPath
  public static async push(router: RouterModel): Promise<void> {
    const harName = router.builderName.split('_')[0];  // '@ohos/hara'
    // 第1层：动态 import 整个 HAR 模块
    await import(harName).then((ns: ESObject): Promise<void> =>
      ns.harInit(router.builderName)  // 第2层：调用 HAR 的初始化函数
    );
    // 第3层完成后，builder 已注册到 builderMap，执行 pushPath
    RouterModule.getRouter(router.routerName)
      .pushPath({ name: router.builderName, param: router.param });
  }

  public static registerBuilder(builderName: string, builder: WrappedBuilder<[object]>): void {
    RouterModule.builderMap.set(builderName, builder);
  }

  public static getBuilder(builderName: string): WrappedBuilder<[object]> {
    return RouterModule.builderMap.get(builderName) as WrappedBuilder<[object]>;
  }

  public static createRouter(routerName: string, router: NavPathStack): void {
    RouterModule.routerMap.set(routerName, router);
  }

  public static getRouter(routerName: string): NavPathStack {
    return RouterModule.routerMap.get(routerName) as NavPathStack;
  }

  public static pop(routerName: string): void {
    RouterModule.getRouter(routerName).pop();
  }

  public static clear(routerName: string): void {
    RouterModule.getRouter(routerName).clear();
  }
}
```

#### 步骤 2：RouterModel + 路由名称常量

构造路由信息模型和统一的路由名称常量：

```typescript
// RouterModule/src/main/ets/model/RouterModel.ets
// RouterModule 定义在步骤1（同 RouterModule 内模块）
import { RouterModule } from '../utils/RouterModule';

export class RouterModel {
  builderName: string = "";    // 页面名称，格式 '@ohos/hara_A1'
  routerName: string = "";     // 路由栈名称，如 'EntryHap_Router'
  param?: object = new Object();
}

// ★ 便捷方法：构造路由信息并立即 push
export function buildRouterModel(routerName: string, builderName: string, param?: object) {
  let router = new RouterModel();
  router.builderName = builderName;
  router.routerName = routerName;
  router.param = param;
  RouterModule.push(router);
}
```

```typescript
// RouterModule/src/main/ets/constants/RouterConstants.ets
export class BuilderNameConstants {
  static readonly HARA_A1: string = '@ohos/hara_A1';
  static readonly HARA_A2: string = '@ohos/hara_A2';
  static readonly HARB_B1: string = '@ohos/harb_B1';
  // ... 按需添加更多页面常量
}

export class RouterNameConstants {
  static readonly ENTRY_HAP: string = 'EntryHap_Router';
}
```

命名规则：`@ohos/{har模块名}_{页面名}`，保证 `push()` 中 `split('_')[0]` 能正确解析出 HAR 模块名。

#### 步骤 3：HAR 模块入口 —— harInit 分发

每个业务 HAR 模块在根目录有一个 `Index.ets`，导出 `harInit()` 函数：

```typescript
// harA/Index.ets
// @ohos/routermodule 是本项目中自定义的共享 HAR 模块（RouterModule），代码见步骤1-2
import { BuilderNameConstants } from '@ohos/routermodule';

export function harInit(builderName: string): void {
  switch (builderName) {
    case BuilderNameConstants.HARA_A1:
      import("./src/main/ets/components/mainpage/A1");  // ★ 第2层：按需加载页面
      break;
    case BuilderNameConstants.HARA_A2:
      import("./src/main/ets/components/mainpage/A2");
      break;
    default:
      break;
  }
}
```

switch 分发确保只加载需要的页面文件，不会一次性加载 HAR 内所有页面。

#### 步骤 4：页面文件 —— @Builder + 自动注册

每个页面文件定义 `@Builder`、构建 NavDestination UI，并在模块顶层自动注册到 builderMap：

```typescript
// harA/src/main/ets/components/mainpage/A1.ets
// @ohos/routermodule 是本项目中自定义的共享 HAR 模块（RouterModule），代码见步骤1-2
import { BuilderNameConstants, buildRouterModel, RouterModule, RouterNameConstants } from '@ohos/routermodule';

// ① 定义 @Builder，接收参数，构建 NavDestination
@Builder
export function harBuilder(value: object) {
  NavDestination() {
    Column() {
      Text(JSON.stringify(value))

      Button('返回首页').onClick(() => {
        RouterModule.clear(RouterNameConstants.ENTRY_HAP);
      })

      Button('跳到 A2（同模块）').onClick(() => {
        buildRouterModel(RouterNameConstants.ENTRY_HAP, BuilderNameConstants.HARA_A2);
      })

      Button('跳到 B1（跨模块）').onClick(() => {
        buildRouterModel(RouterNameConstants.ENTRY_HAP, BuilderNameConstants.HARB_B1);
      })
    }
  }
  .title('A1Page')
  .onBackPressed(() => {
    RouterModule.pop(RouterNameConstants.ENTRY_HAP);
    return true;
  })
}

// ② ★ 模块顶层代码：文件被 import 时自动执行注册
const builderName = BuilderNameConstants.HARA_A1;
if (!RouterModule.getBuilder(builderName)) {
  const builder: WrappedBuilder<[object]> = wrapBuilder(harBuilder);
  RouterModule.registerBuilder(builderName, builder);
}
```

`wrapBuilder(harBuilder)` 将 `@Builder` 函数包装成 `WrappedBuilder<[object]>` 对象，存入 builderMap。

#### 步骤 5：HAP 主页 —— Navigation + navDestination

```typescript
// entry/src/main/ets/pages/Index.ets
// @ohos/routermodule 是本项目中自定义的共享 HAR 模块（RouterModule），代码见步骤1-2
import { BuilderNameConstants, buildRouterModel, RouterModule, RouterNameConstants } from '@ohos/routermodule';

@Entry
@Component
struct EntryHap {
  @State entryHapRouter: NavPathStack = new NavPathStack();

  aboutToAppear() {
    // ★ 将 NavPathStack 注册到 RouterModule，供所有模块使用
    RouterModule.createRouter(RouterNameConstants.ENTRY_HAP, this.entryHapRouter);
  }

  // ★ navDestination 回调：按名称从 builderMap 查找 @Builder 并渲染
  @Builder
  routerMap(builderName: string, param: object) {
    RouterModule.getBuilder(builderName).builder(param);
  }

  build() {
    Navigation(this.entryHapRouter) {
      Column() {
        Button('跳到 A1').onClick(() => {
          buildRouterModel(RouterNameConstants.ENTRY_HAP, BuilderNameConstants.HARA_A1, { origin: 'Entry' });
        })
        Button('跳到 B2').onClick(() => {
          buildRouterModel(RouterNameConstants.ENTRY_HAP, BuilderNameConstants.HARB_B2);
        })
      }
    }
    .navDestination(this.routerMap);  // ★ 绑定路由分发回调
  }
}
```

#### 关键 API 说明

| API | 说明 |
|-----|------|
| `RouterModule.builderMap` | 页面注册表，name → `WrappedBuilder<[object]>` |
| `RouterModule.routerMap` | 路由栈引用，name → `NavPathStack` |
| `wrapBuilder(builder)` | 将 `@Builder` 包装成可存入 Map 的 `WrappedBuilder` 对象 |
| `dynamic import(harName)` | 第1层：动态加载 HAR 模块入口 |
| `harInit(builderName)` | 第2层：HAR 模块内分发到具体页面文件 |
| `Navigation.navDestination()` | 渲染入口：从 builderMap 取出已注册的 builder 并调用 |

#### 注意事项

1. **`wrapBuilder` 是必须的**：`@Builder` 函数不能直接存入 Map 传递给 `navDestination`，必须用 `wrapBuilder()` 包装成 `WrappedBuilder<[object]>` 对象。

2. **页面顶层注册代码是自动执行的**：`import("./B1")` 加载页面文件后，文件中的顶层代码会立即执行，无需手动调用。

3. **`if (!getBuilder(builderName))` 防重复注册**：同一个页面可能被多次 import，注册前先检查是否已存在。

4. **builderName 命名规则**：`@ohos/{har模块名}_{页面名}`，`push()` 中用 `split('_')[0]` 提取 HAR 模块名。如果模块命名包含下划线，需要调整解析逻辑。

5. **所有模块共享同一个 NavPathStack**：`RouterModule.routerMap` 中存储的是 NavPathStack 引用，跨模块跳转用的是同一个路由栈，`pop()` 会正常返回到上一页。

6. **系统路由表是更简单的替代**：如果只是标准跨包跳转，用 `router_map.json` 配置 + `pushPathByName()` 即可，无需这套 RouterModule。

---

## 四、Navigation组件的无感监听

### 场景1：NavDestinationSwitch 实现页面查看访问次数统计埋点

**场景描述：** 使用 `UIObserver` 的 `navDestinationSwitch` 事件实现无侵入式页面埋点，统计 PV（页面查看次数）、UV（去重后的独立访问数）和用户在每个页面的停留时长。无需在每个页面中手动添加埋点代码，通过全局监听即可自动采集所有 NavDestination 页面的访问数据。

**解决方案：** 使用 **`UIObserver.on('navDestinationSwitch')`** 全局监听页面切换事件 + **单例 `PageTracker`** 管理埋点数据的采集与统计。通过 `NavDestinationSwitchInfo` 的 `from`/`to` 获取来源页和目标页信息，`navDestinationId` 跟踪每个页面实例的进入/离开时间。

#### 步骤 1：实现页面埋点管理器

通过单例模式管理访问栈和 PV/UV 统计，核心是 `handleSwitch` 方法：

```typescript
// PageTracker.ets — 页面埋点管理器（完整代码见步骤 1）

/** 页面埋点统计 */
interface PageStats {
  pageName: string;
  pv: number;
  uv: number;         // 去重后的独立访问数
  totalDuration: number;
  avgDuration: number;
}

export class PageTracker {
  private static instance: PageTracker | null = null;
  private visitStack: Map<string, number> = new Map(); // navDestinationId → enterTime
  private stats: Map<string, PageStats> = new Map();

  static getInstance(): PageTracker {
    if (!PageTracker.instance) {
      PageTracker.instance = new PageTracker();
    }
    return PageTracker.instance;
  }

  /** 处理页面切换事件 — 核心方法 */
  handleSwitch(info: NavDestinationSwitchInfo): void {
    const fromName = typeof info.from === 'string' ? 'NavBar' : info.from.name;
    const fromId = typeof info.from === 'string' ? '' : info.from.navDestinationId;
    const toName = typeof info.to === 'string' ? 'NavBar' : info.to.name;
    const toId = typeof info.to === 'string' ? '' : info.to.navDestinationId;
    const opMap: Record<number, string> = { 0: 'PUSH', 1: 'POP', 2: 'REPLACE' };
    const op = opMap[info.operation] ?? 'UNKNOWN';
    const now = Date.now();

    // 来源页：记录离开时间和停留时长
    if (fromId && this.visitStack.has(fromId)) {
      const enterTime = this.visitStack.get(fromId)!;
      const duration = now - enterTime;
      this.updateDuration(fromName, duration);
      this.visitStack.delete(fromId);
    }

    // 目标页：记录进入时间并 PV +1（NavBar 不记录）
    if (toId) {
      this.visitStack.set(toId, now);
      this.incrementPV(toName);
      // UV 去重逻辑：实际项目中用 sessionId/userId 去重，此处省略
    }

    console.info(`[Tracker] ${op}: ${fromName} → ${toName}`);
  }

  private getOrCreateStats(pageName: string): PageStats {
    let stat = this.stats.get(pageName);
    if (!stat) {
      stat = { pageName, pv: 0, uv: 0, totalDuration: 0, avgDuration: 0 };
      this.stats.set(pageName, stat);
    }
    return stat;
  }

  private incrementPV(pageName: string): void {
    this.getOrCreateStats(pageName).pv++;
  }

  private updateDuration(pageName: string, duration: number): void {
    const stat = this.getOrCreateStats(pageName);
    stat.totalDuration += duration;
    stat.avgDuration = Math.round(stat.totalDuration / stat.pv);
  }

  /** 获取所有页面统计 */
  getStats(): PageStats[] {
    return Array.from(this.stats.values());
  }
}
```

#### 步骤 2：在 EntryAbility 中注册监听

在 `onWindowStageCreate` 中获取 `UIContext`，注册全局页面切换监听：

```typescript
// entryability/EntryAbility.ets
// PageTracker 类的完整实现见步骤 1
import { PageTracker } from '../common/PageTracker';

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      const uiContext = windowStage.getMainWindowSync().getUIContext();
      const tracker = PageTracker.getInstance();

      // 注册页面切换监听
      uiContext.getUIObserver().on('navDestinationSwitch', (info) => {
        tracker.handleSwitch(info);
      });
    });
  }

  onWindowStageDestroy(): void {
    const uiContext = this.context.getMainWindowSync().getUIContext();
    // 注销监听，防止内存泄漏
    uiContext.getUIObserver().off('navDestinationSwitch');
  }
}
```

#### 关键 API 说明

| API | 说明 | 起始版本 |
|-----|------|---------|
| `UIObserver.on('navDestinationSwitch')` | 监听 NavDestination 页面切换事件 | API 12+ |
| `NavDestinationSwitchInfo.from / to` | 来源页和目标页信息（含 `name`、`navDestinationId`） | API 12+ |
| `NavDestinationSwitchInfo.operation` | 路由操作类型：`PUSH(0)` / `POP(1)` / `REPLACE(2)` | API 12+ |
| `UIObserver.off('navDestinationSwitch')` | 注销页面切换监听 | API 12+ |

#### 注意事项

> ❌ **常见错误：在组件 `aboutToDisappear` 中注销监听**
> `off('navDestinationSwitch')` 注销的是 `UIContext` / `UIObserver` 级别的全局监听，页面组件的 `aboutToDisappear` 根本触及不到它，放这里会导致监听永不注销、内存泄漏。**必须在 `EntryAbility.onWindowStageDestroy` 中注销**。

1. **使用 `UIContext` 级别注册**：单 Navigation 应用直接注册即可，多 Navigation 应用可通过 `navigationId` 参数指定监听某个 Navigation。

2. **注销时机**：在 `onWindowStageDestroy` 中调用 `off('navDestinationSwitch')` 注销监听，防止内存泄漏。

3. **PV 计算逻辑**：每次页面从不可见变为可见计一次 PV（包括 POP 回来），同一个页面实例被 PUSH 和 POP 回来各计一次。

4. **UV 去重**：使用 sessionId 或 userId 去重，同一用户多次访问同一页面只算一次 UV。

5. **停留时长精度**：使用 `navDestinationId`（而非页面名称）跟踪每个实例的进入/离开时间，确保同名页面的多个实例能正确计算停留时长。

---

### 场景2：queryNavDestinationInfo 获取当前页面信息

**场景描述：** 在深层嵌套的自定义子组件中，需要知道当前组件属于哪个 NavDestination 子页面、页面名称是什么、路由栈位置等。`queryNavDestinationInfo` 允许任意子组件（不限于 NavDestination 根级别）直接查询当前页面信息，典型用途包括：判断组件在哪个子页面中、获取当前页面的路由参数、调试和日志中标记页面上下文。

**解决方案：** 使用 **`this.queryNavDestinationInfo()`** 在 NavDestination 内的任意子组件中查询当前页面信息（名称、ID、索引、参数、模式），配合 **`this.queryNavigationInfo()`** 获取 Navigation 信息（pathStack）。无需逐层传递 NavPathStack 或页面参数。

#### 步骤 1：实现通用页面上下文感知组件

通过 `queryNavDestinationInfo` 在任意子组件中自动感知所在页面：

```typescript
// PageContextTag.ets — 可放在任意子组件中，自动感知所在页面
@Component
export struct PageContextTag {
  @State pageName: string = '未知页面';
  @State pageId: string = '';
  @State stackIndex: number = -1;
  @State navMode: string = '';
  private navStack?: NavPathStack;

  aboutToAppear(): void {
    // ✅ 核心：在任意子组件中查询当前页面信息
    const destInfo = this.queryNavDestinationInfo();
    if (destInfo) {
      this.pageName = destInfo.name;
      this.pageId = destInfo.navDestinationId;
      this.stackIndex = destInfo.index;
      this.navMode = destInfo.mode === NavDestinationMode.DIALOG ? 'DIALOG' : 'STANDARD';
    }

    // 还可以查询 Navigation 信息
    const navInfo = this.queryNavigationInfo();
    if (navInfo) {
      this.navStack = navInfo.pathStack;
    }
  }

  build() {
    Text(`[${this.pageName}] #${this.pageId} @${this.stackIndex} (${this.navMode})`)
      .fontSize(10)
      .fontColor('#999999')
      .padding(4)
      .backgroundColor('#F5F5F5')
      .borderRadius(4)
  }
}
```

#### 步骤 2：在页面和深层子组件中使用

即使嵌套多层的子组件，也能直接调用 `queryNavDestinationInfo` 获取页面信息：

```typescript
// ProductDetail.ets
@Component
struct ProductDetail {
  build() {
    NavDestination() {
      Column() {
        // 深层子组件中也能感知页面上下文
        ProductInfoCard()  // 内部可以用 queryNavDestinationInfo()
        RecommendSection() // 内部也可以
      }
    }
  }
}

// 深层子组件中也能感知页面上下文
@Component
struct ProductInfoCard {
  private currentPageName: string = '';

  aboutToAppear(): void {
    // 即使在深层嵌套的子组件中，也能获取页面信息
    const info = this.queryNavDestinationInfo();
    if (info) {
      this.currentPageName = info.name;
      console.info(`当前组件位于页面: ${info.name}, ID: ${info.navDestinationId}`);
    }
  }

  build() {
    Column() {
      PageContextTag() // 自动显示页面上下文信息
    }
  }
}
```

#### 典型应用场景

```typescript
// 场景 A：全局埋点组件自动获取页面名
@Component
struct TrackableButton {
  @Prop actionName: string = '';
  build() {
    Button(this.actionName)
      .onClick(() => {
        const info = this.queryNavDestinationInfo();
        const pageName = info?.name ?? 'unknown';
        console.info(`[Track] page=${pageName}, action=${this.actionName}`);
      })
  }
}
```

**其他典型用法（要点）：**

- **调试浮层**：读取 `info.name`、`info.navDestinationId`、`info.index`、`info.mode` 显示当前页面上下文信息
- **条件功能**：根据 `info?.name === 'PageName'` 判断当前所在页面，仅在特定页面启用某功能（如 `if (info?.name === 'HomePage') { /* 启用首页专属功能 */ }`）

#### 关键 API 说明

| API | 说明 | 起始版本 |
|-----|------|---------|
| `this.queryNavDestinationInfo()` | NavDestination 内任意子组件查询当前页面信息 | API 12+ |
| `this.queryNavigationInfo()` | Navigation 内任意子组件查询 Navigation 信息（pathStack、mode） | API 12+ |
| `NavDestinationInfo.name` | 页面名称 | — |
| `NavDestinationInfo.index` | 路由栈索引 | — |
| `NavDestinationInfo.navDestinationId` | 页面实例唯一 ID | — |
| `NavDestinationInfo.param` | 页面参数 | — |
| `NavDestinationInfo.mode` | 页面模式：STANDARD / DIALOG | — |

#### 获取方式对比

| 方式 | 调用位置 | 返回内容 | 适用场景 |
|------|---------|---------|---------|
| `queryNavDestinationInfo()` | NavDestination 内任意子组件 | 页面名称、ID、索引、参数、模式 | 子组件感知页面上下文 |
| `queryNavigationInfo()` | Navigation 内任意子组件 | pathStack、mode | 子组件获取导航控制器 |
| `onReady(ctx)` | NavDestination 根组件 | pathStack、param、navDestinationId | 页面级初始化 |

#### 注意事项

1. **只能在 NavDestination 内调用**：在 Navigation 的 NavBar 区域调用返回 `undefined`，调用前需要做空值检查。

2. **返回 `undefined` 表示不在 NavDestination 中**：始终对返回值做空值判断，避免访问 `undefined` 的属性导致崩溃。

3. **多实例页面**：同名页面的不同实例有不同的 `navDestinationId`，可用于区分不同的页面实例。

4. **与 `onReady` 互补**：`onReady` 用于页面级初始化（只触发一次），`queryNavDestinationInfo` 用于任意子组件随时查询当前页面信息。

---

## 五、Navigation路由动画

### 场景1：系统转场类型配置

**场景描述：** 设置类应用中不同页面需要不同的转场风格：主列表 → 二级页使用右滑进入，关于页使用渐变，底部弹窗使用上滑，而某些静默跳转不需要任何动画。通过 `NavDestination.systemTransition` 为每个页面配置合适的系统转场类型。

**解决方案：** 使用 **`NavDestination.systemTransition(type)`** 为每个 NavDestination 声明系统转场类型，通过 **`NavigationSystemTransitionType`** 枚举选择效果（FADE/EXPLODE/SLIDE_RIGHT/SLIDE_BOTTOM 等），无需自定义动画即可实现不同转场风格。

#### 系统转场类型一览

| 枚举值 | 效果 | 典型场景 |
|--------|------|----------|
| DEFAULT | 标题栏 + 内容区默认动画 | 常规页面 |
| NONE | 无动画 | 静默跳转、初始化 |
| TITLE | 仅标题栏动画 | 标题切换、内容不变的页面 |
| CONTENT | 仅内容区动画 | 标题不变的详情页 |
| FADE | 渐入渐出 | 关于页、设置子页 |
| EXPLODE | 中心缩放 | 照片查看、卡片展开 |
| SLIDE_RIGHT | 右侧平移 | 标准推入（设置列表→详情） |
| SLIDE_BOTTOM | 底部上滑 | 底部面板、筛选页 |

#### 示例：配置不同系统转场类型

各页面只需在 NavDestination 上通过 `.systemTransition(类型)` 指定，参照上方表格选择即可：

```typescript
@Component
struct AboutPage {
  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Text('HarmonyOS 5.0').fontSize(24).fontWeight(FontWeight.Bold)
        // ... 其他信息
      }.width('100%').padding(20)
    }
    .title('关于本机')
    // ★ 渐变转场
    .systemTransition(NavigationSystemTransitionType.FADE)
  }
}

@Component
struct PhotoViewer {
  build() {
    NavDestination() {
      Stack() {
        Image($r('app.media.profile_avatar')).width('90%').objectFit(ImageFit.Contain)
      }.width('100%').height('100%').backgroundColor(Color.Black)
    }
    .hideTitleBar(true)
    // ★ 中心缩放转场
    .systemTransition(NavigationSystemTransitionType.EXPLODE)
  }
}

// 筛选面板 — .systemTransition(NavigationSystemTransitionType.SLIDE_BOTTOM)
// 标准推入页 — .systemTransition(NavigationSystemTransitionType.SLIDE_RIGHT)
```

#### 步骤 A：全局关闭动画（disableAnimation）

影响该 `NavPathStack` 上的**所有后续跳转**，是“开关”性质——设为 `true` 后，需要动画时记得设回 `false`：

```typescript
// 全局关闭：此后该 navStack 的 push/pop/replace 都无转场动画
this.navStack.disableAnimation(true);
// ... 一系列静默跳转 ...
this.navStack.disableAnimation(false);  // 需要动画时再打开
```

#### 步骤 B：单次关闭动画（push/pop 的 animated 参数）

只影响**当前这一次**操作、不改全局状态，是最常用的静默跳转方式。`pushPath` / `pushPathByName` / `pop` 的最后一个参数 `animated` 传 `false`：

```typescript
// 单次关闭：仅本次跳转无动画，后续跳转不受影响
this.navStack.pushPath({ name: 'SilentPage' }, false);
// pushPathByName 的第三参同样支持 animated
this.navStack.pushPathByName('SilentPage', null, false);
// pop 也可单次关闭
this.navStack.pop(false);
```

#### 步骤 C：初始化时静默 push（避免 Router + Navigation 动画冲突）

应用首帧加载、或从 Router 迁移到 Navigation 时，首次 `push` 若带动画会与系统启动动画 / Router 动画叠加闪烁，应在 `aboutToAppear` 中以 `animated=false` 静默 push 初始页：

```typescript
@Entry
@Component
struct Index {
  navStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    // 初始化静默 push：避免首帧动画叠加 / 闪烁
    this.navStack.pushPath({ name: 'SettingsHome' }, false);
  }

  build() {
    // Navigation(this.navStack) { ... }
  }
}
```

#### 关键 API 说明

| API | 说明 | 起始版本 |
|-----|------|---------|
| `NavDestination.systemTransition(type)` | 设置 NavDestination 系统转场动画类型 | API 14+ |
| `NavigationSystemTransitionType` | 系统转场枚举（DEFAULT/NONE/TITLE/CONTENT/FADE/EXPLODE/SLIDE_RIGHT/SLIDE_BOTTOM） | API 14+ |
| `NavPathStack.disableAnimation(true)` | 全局关闭所有转场动画 | API 11+ |
| `pushPath({ name }, animated)` | 单次关闭/开启转场动画，`animated` 为 `false` 时无动画 | API 10+ |

#### 注意事项

1. **默认转场使用弹簧曲线**：时长与物理参数相关，不同设备表现不同，不建议与业务逻辑耦合。
2. **TITLE/CONTENT 可单独控制**：TITLE 仅标题栏动画、CONTENT 仅内容区动画，设置 NONE 或 TITLE 时无内容区转场。
3. **关闭动画的两种方式**：`disableAnimation` 全局关闭影响所有跳转；`animated` 参数单次关闭只影响当前操作。
4. **与 customTransition 同时设置时，后设置的生效**。

---

### 场景2：单页面自定义转场动画

**场景描述：** 底部弹出面板（BottomSheet 风格）需要从底部滑入，背景渐显；退出时向下滑出，背景渐隐。该效果只应用于特定页面，其他页面仍使用系统默认转场。

**解决方案：** 使用 **`NavDestination.customTransition(delegate)`** 实现单页面级别的自定义转场。代理函数根据 `operation`（PUSH/POP）和 `isEnter`（入场/退场）返回不同的动画配置，返回 `undefined` 时使用系统默认转场。

#### 实现代码：底部弹出面板页面

```typescript
// BottomSheetPage.ets

@Component
export struct BottomSheetPage {
  navStack: NavPathStack = new NavPathStack();
  @State panelOffset: string = '100%';  // 初始在屏幕底部外
  @State bgOpacity: number = 0;         // 背景初始透明

  build() {
    NavDestination() {
      Stack() {
        // 背景蒙层
        Column()
          .width('100%').height('100%')
          .backgroundColor(Color.Black)
          .opacity(this.bgOpacity)

        // 内容面板（从底部滑入）
        Column({ space: 16 }) {
          // ... 选项列表 UI
        }
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius({ topLeft: 16, topRight: 16 })
        .padding({ left: 16, right: 16, bottom: 32 })
        .translate({ y: this.panelOffset })
      }
      .width('100%').height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor(Color.Transparent)
    .onReady((ctx: NavDestinationContext) => {
      this.navStack = ctx.pathStack;
    })
    // ★ 核心：设置单页面自定义转场
    .customTransition(
      (operation: NavigationOperation, isEnter: boolean)
        : Array<NavDestinationTransition> | undefined => {

        if (operation === NavigationOperation.PUSH) {
          if (isEnter) {
            // ★ PUSH 入场：面板从底部滑入 + 背景渐显
            return [{
              duration: 350,
              curve: Curve.EaseOut,
              event: () => {
                this.panelOffset = '100%';  // 起始位置：屏幕外底部
                this.bgOpacity = 0;
                this.getUIContext().animateTo({ duration: 350, curve: Curve.EaseOut }, () => {
                  this.panelOffset = '0%';   // 结束位置：原位
                  this.bgOpacity = 0.5;
                });
              }
            }];
          }
          return undefined; // PUSH 时退场页面使用系统默认
        }

        if (operation === NavigationOperation.POP) {
          if (isEnter) {
            return undefined; // POP 时恢复页面使用系统默认
          }
          // ★ POP 退场：面板向下滑出 + 背景渐隐
          return [{
            duration: 300,
            curve: Curve.EaseIn,
            event: () => {
              this.getUIContext().animateTo({ duration: 300, curve: Curve.EaseIn }, () => {
                this.panelOffset = '100%';
                this.bgOpacity = 0;
              });
            }
          }];
        }

        return undefined;
      }
    )
  }
}
```

**本示例的“四象限”配置策略**：`customTransition` 代理按 `operation`（PUSH / POP）× `isEnter`（入场 / 退场）共有 4 种组合。本底部弹出面板示例**只自定义了 2 个象限**，另外 2 个返回 `undefined` 走系统默认：

| operation | isEnter | 处理 | 原因 |
|-----------|---------|------|------|
| PUSH | true（入场） | ✅ 自定义：面板从底部滑入 + 背景渐显 | 弹出效果是本页核心 |
| PUSH | false（退场） | ❌ `undefined`：走系统默认 | PUSH 时退场的是上一个页面，系统默认即可 |
| POP | true（入场） | ❌ `undefined`：走系统默认 | POP 时恢复的是上一个页面，系统默认即可 |
| POP | false（退场） | ✅ 自定义：面板向下滑出 + 背景渐隐 | 收起效果是本页核心 |

如果你的页面四个方向都要专属动画（如卡片翻转），把另外两个 `return undefined` 替换成对应的 `NavDestinationTransition` 配置即可，结构不变。

#### 关键 API 说明

| API | 说明 | 起始版本 |
|-----|------|---------|
| `NavDestination.customTransition(delegate)` | 单页面自定义转场属性，接收代理函数 | API 15+ |
| `NavDestinationTransition` | 转场协议对象；`event` 回调在 animateTo 上下文中执行，直接设置目标状态即可驱动动画 | API 15+ |
| `NavigationOperation` | 操作枚举（PUSH/POP/REPLACE） | API 11+ |

代理函数签名：`(operation: NavigationOperation, isEnter: boolean) → Array<NavDestinationTransition> | undefined`。返回 `undefined` 使用系统默认转场；返回多个 `NavDestinationTransition` 动画效果逐层叠加。

#### 注意事项

1. **优先级低于 Navigation 级别**：同时设置了 `customNavContentTransition` 和 `customTransition` 时，Navigation 级别优先。

2. **返回 undefined 使用系统默认**：某些操作/方向不需要自定义动画时，返回 `undefined` 即可。

3. **多动画叠加**：返回数组中多个协议对象的动画效果会同时播放、逐层叠加。

4. **NavDestination 建议用 STANDARD 模式**：DIALOG 模式本身透明叠加，转场动画效果不同。

---

### 场景3：Navigation全局自定义转场动画

**场景描述：** 应用需要统一的品牌化转场动画效果：所有页面跳转时执行自定义的缩放+渐变动画，并在动画完成后执行回调（如埋点）。通过 `customNavContentTransition` 在 Navigation 级别统一管理所有页面的转场。

**解决方案：** 使用 **`Navigation.customNavContentTransition(handler)`** 在 Navigation 级别统一拦截转场事件 + **单例工具类管理各页面的动画回调**（在 `onReady` 注册、`aboutToDisappear` 注销）。页面只需注册动画回调，不感知转场调度逻辑。

#### 步骤 1：自定义转场动画工具类

```typescript
// CustomNavigationUtils.ets — 单例工具类，管理各页面的转场动画回调

interface AnimateCallback {
  timeout: number;
  animation: (isPush: boolean, isExit: boolean, transitionProxy: NavigationTransitionProxy) => void;
}

export class CustomNavigationUtils {
  private static instance: CustomNavigationUtils = new CustomNavigationUtils();
  private customTransitionMap: Map<string, AnimateCallback> = new Map();

  static getInstance(): CustomNavigationUtils {
    return CustomNavigationUtils.instance;
  }

  /** 页面创建时注册；已存在则更新 */
  registerNavParam(name: string,
    animationCallback: (isPush: boolean, isExit: boolean, transitionProxy: NavigationTransitionProxy) => void,
    timeout: number): void {
    this.customTransitionMap.set(name, { timeout, animation: animationCallback });
  }

  /** 页面销毁时注销 */
  unRegisterNavParam(name: string): void {
    this.customTransitionMap.delete(name);
  }

  getAnimateParam(name: string): AnimateCallback | undefined {
    return this.customTransitionMap.get(name);
  }
}
```

#### 步骤 2：NavDestination 页面（注册动画回调）

```typescript
// SamplePage.ets — 各 NavDestination 页面按此模式注册动画回调
@Component
struct SamplePage {
  navStack: NavPathStack = new NavPathStack();
  @State pageScale: number = 1;
  @State pageOpacity: number = 1;
  private pageId: string = '';

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Text('示例页面').fontSize(24)
        Button('push next').onClick(() => {
          this.navStack.pushPathByName('SamplePage', null);
        })
      }.width('100%').padding(20)
    }
    .title('示例页')
    .scale({ x: this.pageScale, y: this.pageScale })
    .opacity(this.pageOpacity)
    .onReady((ctx: NavDestinationContext) => {
      this.navStack = ctx.pathStack;
      this.pageId = ctx.navDestinationId ?? '';
      // ★ 注册当前页面的动画回调
      CustomNavigationUtils.getInstance().registerNavParam(
        this.pageId,
        (isPush, isExit, transitionProxy) => {
          this.runTransitionAnimation(isPush, isExit, transitionProxy);
        },
        800 // 超时时间(ms)
      );
    })
  }

  /** 缩放+渐变动画 — PUSH/POP × 入场/退场 四种场景 */
  private runTransitionAnimation(isPush: boolean, isExit: boolean,
    transitionProxy: NavigationTransitionProxy): void {
    // PUSH入场：从小放大+渐显；PUSH退场：缩小+渐隐
    // POP退场：缩小+渐隐；POP恢复：放大还原+渐显
    let targetScale = (isPush && !isExit) || (!isPush && isExit) ? 1 : 0.9;
    let startOpacity = (isPush && !isExit) ? 0 : (!isPush && !isExit) ? 0.5 : 1;
    let endOpacity = isExit ? 0 : 1;
    if (!isExit) {
      this.pageScale = 0.9;
      this.pageOpacity = startOpacity;
    }
    this.getUIContext().animateTo({ duration: 400, curve: Curve.EaseInOut }, () => {
      this.pageScale = targetScale;
      this.pageOpacity = endOpacity;
    });
    // ★ 必须调用：通知系统转场完成
    transitionProxy.finishTransition();
  }
}
```

#### 步骤 3：Navigation 主页（绑定自定义转场）

```typescript
// Index.ets — Navigation 主页绑定自定义转场
// import 工具类定义见步骤1

@Entry
@Component
struct Index {
  navStack: NavPathStack = new NavPathStack();

  @Builder
  pageMap(name: string) {
    if (name === 'SamplePage') {
      SamplePage();
    }
  }

  build() {
    Navigation(this.navStack) {
      Column({ space: 16 }) {
        Button('跳转').onClick(() => this.navStack.pushPathByName('SamplePage', null))
      }.width('100%').height('100%').justifyContent(FlexAlign.Center)
    }
    .hideNavBar(true)
    .navDestination(this.pageMap)
    // ★ 绑定自定义转场动画
    .customNavContentTransition((from: NavContentInfo, to: NavContentInfo,
      operation: NavigationOperation) => {
      // 首页（NavBar，index=-1）不参与自定义转场
      if (from.index === -1 || to.index === -1) return undefined;

      let fromParam = CustomNavigationUtils.getInstance().getAnimateParam(from.navDestinationId);
      let toParam = CustomNavigationUtils.getInstance().getAnimateParam(to.navDestinationId);
      if (!fromParam?.animation || !toParam?.animation) return undefined;

      return {
        timeout: Math.max(fromParam.timeout, toParam.timeout),
        onTransitionEnd: (success: boolean) => console.info(`Transition end: ${success}`),
        transition: (proxy: NavigationTransitionProxy) => {
          fromParam!.animation!(operation === NavigationOperation.PUSH, true, proxy);
          toParam!.animation!(operation === NavigationOperation.PUSH, false, proxy);
        }
      } as NavigationAnimatedTransition;
    })
  }
}
```

#### 关键 API 说明

| API | 说明 | 起始版本 |
|-----|------|---------|
| `Navigation.customNavContentTransition(handler)` | Navigation 级别自定义转场事件 | API 11+ |
| `NavigationAnimatedTransition` | 转场协议对象（transition/timeout/onTransitionEnd） | API 11+ |
| `NavigationTransitionProxy` | 可交互转场代理，`finishTransition()` 通知系统转场完成 | API 11+ |

#### 注意事项

> ❌ **常见错误：动画函数里忘记调用 `transitionProxy.finishTransition()`**
> 不调用的话，系统会一直等到 `timeout` 才结束转场，**页面卡住几百毫秒到数秒**——这是本场景最高频的 bug。`finishTransition()` 必须在页面注册的 animation 回调里、动画结束后立即调用。其次易错：`onReady` 里注册了回调却忘了在 `aboutToDisappear` 中 `unRegisterNavParam` 注销，导致内存泄漏。

1. **优先级**：`customNavContentTransition` 优先级高于 `NavDestination.customTransition`，同时使用时 Navigation 级别生效。

2. **finishTransition 必须调用**：否则系统会等 timeout 后才完成转场，造成页面卡住。此回调在页面注册的 animation 函数中调用。

3. **注册/注销时机**：在 `onReady` 中注册，在 `aboutToDisappear` 中注销，防止内存泄漏。首页 NavBar 的 `from.index` 为 -1，需跳过。

---

### 场景4：可交互手势返回转场

> ⚠️ **本场景使用 `Navigation.customNavContentTransition()`（Navigation 全局级转场），不是 `NavDestination.customTransition()`（页面级转场）。** 场景 2 的 `customTransition` 挂在单个 NavDestination 上，**无法配合 `NavigationTransitionProxy` 实现手势驱动的可交互转场**；可交互转场必须在 Navigation 上用 `customNavContentTransition` 统一接管，并通过 `NavigationTransitionProxy.finishTransition()` 控制完成时机。两者的区别：前者在 Navigation 上设置、可控制转场完成时机；后者在 NavDestination 上设置、无法控制完成时机。手势返回场景必须用前者。本场景与场景 3 共用同一套 `CustomNavigationUtils` 注册机制。

**场景描述：** 社交类应用中，用户点击聊天中的图片进入全屏图片查看器。查看器支持手势下滑关闭：用户按住图片向下滑动时，图片跟随手指实时缩小并下移，背景逐渐变透明；松手后根据下滑距离决定是完成关闭还是回弹到原位。实现的关键是分工：`PanGesture` 实时驱动图片的视觉状态（scale / 位移 / opacity），`NavigationTransitionProxy` 负责控制转场的**完成时机**——PUSH 入场动画结束、POP 手势退场后调用 `finishTransition()` 收尾，避免转场挂起到 timeout。

**解决方案：** 使用 **`Navigation.customNavContentTransition()`** 全局自定义转场 + **`PanGesture` 手势驱动**实时更新图片状态（scale/translate/opacity） + **`NavigationTransitionProxy`** 控制转场完成时机。手势下滑超过阈值时调用 `navStack.pop(false)` 触发退场动画，未超过阈值时弹簧动画回弹。

#### 步骤 1：图片查看器页面（核心手势驱动逻辑）

```typescript
// PhotoViewerPage.ets
// 复用场景3中定义的 CustomNavigationUtils（见场景3步骤1）

@Component
struct PhotoViewerPage {
  navStack: NavPathStack = new NavPathStack();
  @State imgScale: number = 1;
  @State imgOffsetY: number = 0;
  @State bgOpacity: number = 1;
  private pageId: string = '';
  private panOffsetY: number = 0;

  build() {
    NavDestination() {
      Stack() {
        // 背景蒙层
        Column().width('100%').height('100%').backgroundColor(Color.Black).opacity(this.bgOpacity)
        // 图片
        Image($r('app.media.photo_placeholder'))
          .objectFit(ImageFit.Contain).width('90%').height('70%')
          .scale({ x: this.imgScale, y: this.imgScale })
          .translate({ y: this.imgOffsetY })
          // ★ 绑定平移手势 — 驱动可交互转场
          .gesture(
            PanGesture({ fingers: 1, direction: PanDirection.Vertical })
              .onActionStart(() => { this.panOffsetY = 0; })
              .onActionUpdate((event: GestureEvent) => {
                this.panOffsetY += event.offsetY;
                let ratio = Math.min(Math.abs(this.panOffsetY) / 300, 1);
                this.imgOffsetY = this.panOffsetY;
                this.imgScale = 1 - ratio * 0.3;
                this.bgOpacity = 1 - ratio * 0.8;
              })
              .onActionEnd(() => {
                // ★ 松手判断：下滑 > 100vp 关闭，否则回弹
                this.panOffsetY > 100 ? this.dismissViewer() : this.snapBack();
              })
          )
      }.width('100%').height('100%')
    }
    .hideTitleBar(true).backgroundColor(Color.Black)
    .onReady((ctx: NavDestinationContext) => {
      this.navStack = ctx.pathStack;
      this.pageId = ctx.navDestinationId ?? '';
      // ★ 注册转场回调（复用场景3的 CustomNavigationUtils）
      CustomNavigationUtils.getInstance().registerNavParam(
        this.pageId,
        (isPush, isExit, transitionProxy) => { this.runTransition(isPush, isExit, transitionProxy); },
        3000 // 手势场景需较长超时
      );
    })
  }

  // ★ transitionProxy 是本场景的核心：用它控制转场「完成时机」。
  //   - PUSH 入场是一次性动画 → 动画结束(onFinish)即 finishTransition；
  //   - POP 退场视觉已由手势 dismissViewer() 处理 → 立即 finishTransition 收尾。
  //   两条路径都必须调用 finishTransition()，否则转场挂起直到 timeout(3s)页面假死。
  private runTransition(isPush: boolean, isExit: boolean, transitionProxy: NavigationTransitionProxy): void {
    if (isPush && !isExit) {
      // PUSH 入场：图片放大 + 蒙层淡入
      this.imgScale = 0.5; this.bgOpacity = 0;
      this.getUIContext().animateTo({
        duration: 400, curve: Curve.Spring,
        // ★ 动画结束后通知系统转场完成（不调用会卡到 timeout）
        onFinish: () => { transitionProxy.finishTransition(); }
      }, () => {
        this.imgScale = 1; this.bgOpacity = 1;
      });
      return;
    }
    // POP 退场（isExit=true）：图片视觉已由 dismissViewer() 的手势动画收尾，
    // 此处无需再做动画，但 ★ 仍必须调用 finishTransition() 通知系统转场结束。
    transitionProxy.finishTransition();
  }

  /** 手势确认关闭 */
  private dismissViewer(): void {
    this.getUIContext().animateTo({ duration: 300, curve: Curve.EaseIn }, () => {
      this.imgScale = 0.3; this.imgOffsetY = 500; this.bgOpacity = 0;
    });
    setTimeout(() => { this.navStack.pop(false); }, 300);
  }

  /** 手势取消 → 回弹 */
  private snapBack(): void {
    this.getUIContext().animateTo({ duration: 300, curve: Curve.Spring }, () => {
      this.imgScale = 1; this.imgOffsetY = 0; this.bgOpacity = 1;
    });
  }
}
```

#### 关键 API 说明

| API | 说明 | 起始版本 |
|-----|------|---------|
| `NavigationTransitionProxy` | 可交互转场代理，`finishTransition()` 通知系统转场完成 | API 11+ |
| `PanGesture` | 平移手势，驱动转场进度 | — |
| `Navigation.customNavContentTransition()` | Navigation 自定义转场事件 | API 11+ |

#### 补充说明

1. **finishTransition 必须调用**：不调用则系统等待 timeout 后才完成转场，页面会卡住。本场景两条路径都要调：PUSH 入场在 `animateTo` 的 `onFinish` 回调里调（入场动画结束即完成）；POP 退场视觉已由手势处理，在 `runTransition` 里**立即**调（不再做动画也要收尾）。

2. **手势场景需较大 timeout**：交互式转场中用户可能犹豫或慢速滑动，建议 timeout 设为 2000~3000ms。

3. **系统默认动画无结束回调**：如需监听动画结束，必须使用自定义转场并实现 `onTransitionEnd`。

4. **Router 冲突**：router 页面转场和 Navigation push 动画可能同时播放，初始化 push 时关闭动画：`this.navStack.pushPath({ name: 'HomePage' }, false)`。

5. **Pop+Push 同帧执行时**：以操作前的栈顶页面为判断基准——栈顶仍在栈中则执行 push 动画，否则执行 pop 动画。如需 pop 后 push 并执行 push 动画，使用 `LaunchMode.NEW_INSTANCE`。

---

### 场景5：共享元素一镜到底转场

**场景描述：** 商品列表页点击商品图片后，图片平滑过渡到商品详情页的大图区域，实现"一镜到底"的 Hero 动画效果。用户视觉上感觉图片从列表位置"飞"到了详情页，过渡自然流畅。

**解决方案：** 使用 **`geometryTransition(id)`** 在起始页和目的页的相同组件上标记一致的共享元素 ID + **`animateTo` 闭包内执行路由跳转**（`pushPath` 的 `animated` 设为 `false` 关闭默认转场）。系统自动计算共享元素的位置和大小差异并执行过渡动画。

#### 关键约束（6 条必须全部满足，缺一不可）

> ❌ **常见错误清单（逐条自查，任一不满足则动画异常 / 不生效）**：
> 1. ✗ 起始页用 NavBar / Navigation 根内容 → ✓ 起始页和目的页**都必须是 NavDestination**（NavBar → NavDestination 不支持）
> 2. ✗ `pushPath` 不传 `animated: false` → ✓ **必须传 `false`**，否则默认转场与共享元素动画叠加异常
> 3. ✗ `pop()` 不传 `false` → ✓ 返回时 `pop(false)` **必须传 `false`** 才有反向动画
> 4. ✗ `geometryTransition` 设在 NavDestination 上 → ✓ **设在内容组件上**（如 `Image`），不要设在 NavDestination
> 5. ✗ 给 NavDestination 设了 `zIndex` → ✓ **禁止设置 zIndex**（会覆盖系统层级导致动画异常）
> 6. ✗ 路由跳转写在 `animateTo` 闭包外 → ✓ push / pop **必须在 `animateTo` 闭包内**

#### 步骤 1：商品列表页（起始页）

```typescript
// ProductListPage.ets
@Component
struct ProductListPage {
  navStack: NavPathStack = new NavPathStack();

  private products = [
    { id: '1', name: '无线蓝牙耳机', price: 299 },
    { id: '2', name: '智能手表', price: 1299 },
    { id: '3', name: '便携充电宝', price: 99 },
  ];

  build() {
    NavDestination() {
      List({ space: 12 }) {
        ForEach(this.products, (product) => {
          ListItem() {
            Row({ space: 12 }) {
              // ★ 商品图片：标记为共享元素
              Image($r('app.media.product_1'))
                .geometryTransition(`product_${product.id}`)
                .width(100)
                .height(100)
                .borderRadius(8)
                .objectFit(ImageFit.Cover)

              Column({ space: 4 }) {
                Text(product.name).fontSize(16).fontWeight(FontWeight.Bold)
                Text(`¥${product.price}`).fontSize(14).fontColor(Color.Red)
              }
              .layoutWeight(1)
            }
            .width('100%')
            .padding(12)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .onClick(() => {
              // ★ 核心：在 animateTo 闭包内执行跳转 + 关闭默认转场
              this.getUIContext().animateTo({ duration: 500, curve: Curve.EaseInOut }, () => {
                this.navStack.pushPath(
                  { name: 'ProductDetailPage', param: { productId: product.id } },
                  false  // ★ 关闭默认转场
                );
              });
            })
          }
        }, (product) => product.id)
      }
      .width('100%')
      .padding(12)
    }
    .title('商品列表')
    .onReady((ctx: NavDestinationContext) => {
      this.navStack = ctx.pathStack;
    })
  }
}
```

#### 步骤 2：商品详情页（目的页）

```typescript
// ProductDetailPage.ets
@Component
struct ProductDetailPage {
  navStack: NavPathStack = new NavPathStack();
  @State productId: string = '';

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 16 }) {
          // ★ 详情页大图：使用相同的共享元素 id
          Image($r('app.media.product_placeholder'))
            .geometryTransition(`product_${this.productId}`)
            .width('100%')
            .height(300)
            .objectFit(ImageFit.Cover)

          Text('商品详情').fontSize(24).fontWeight(FontWeight.Bold)
          Text(`商品编号: ${this.productId}`).fontSize(14).fontColor(Color.Gray)

          Button('返回').onClick(() => {
            // ★ 返回时同样在 animateTo 闭包内执行
            this.getUIContext().animateTo({ duration: 500, curve: Curve.EaseInOut }, () => {
              this.navStack.pop(false);
            });
          })
        }
      }
    }
    .title('商品详情')
    .onReady((ctx: NavDestinationContext) => {
      this.navStack = ctx.pathStack;
      const param = ctx.pathInfo.param as Record<string, string>;
      this.productId = param?.productId ?? '';
    })
  }
}
```

#### 关键 API 说明

| API | 说明 | 起始版本 |
|-----|------|---------|
| `geometryTransition(id)` | 标记组件为共享元素，id 一致则自动过渡 | API 11+ |
| `animateTo(options, callback)` | 闭包内触发路由跳转，系统自动计算共享元素过渡 | — |
| `pushPath(name, animated)` | 路由跳转，`animated` 设为 `false` 关闭默认转场 | API 10+ |

#### 注意事项

1. **id 必须一致**：起始页和目的页的 `geometryTransition` 参数必须完全相同且不为空字符串。

2. **必须关闭默认转场**：否则两段动画叠加效果异常。

3. **必须在 animateTo 闭包内**：路由操作放在 `animateTo` 回调中，系统才能正确计算动画范围。

4. **设内容组件不设 NavDestination**：`geometryTransition` 加在 `Image` 等内容组件上，不要加在 `NavDestination` 上。

5. **NavDestination 不要设置 zIndex**：会覆盖系统层级导致动画异常。

6. **Pop 返回同样需要 animateTo**：返回时也需要在 `animateTo` 闭包内执行 `pop(false)` 才能触发反向共享元素动画。

---

### 场景6：Dialog蒙层渐隐退出动画

**场景描述：** 使用 `NavDestinationMode.DIALOG` 实现底部弹窗时，默认转场动画下 pop 退出存在体验问题：蒙层没有渐隐效果，而是随内容一起向下滑出。期望的效果是退出时蒙层渐隐 + 内容下滑同时进行。

**解决方案：** 将 NavDestination 的 **`backgroundColor` 绑定到状态变量**，在 **`onWillAppear`** 中通过 `animateTo` 驱动蒙层从透明渐变到半透明（入场），在 **`onWillDisappear`** 中驱动蒙层从半透明渐变回透明（退场）。系统 DIALOG 退出动画（内容下滑）与手动的蒙层渐隐动画叠加，产生组合效果。

#### 实现代码：带蒙层渐隐的 Dialog 弹窗

```typescript
// DialogSheetPage.ets

@Builder
export function DialogSheetPageBuilder() {
  DialogSheetPage();
}

@Component
export struct DialogSheetPage {
  navStack: NavPathStack = AppStorage.get<NavPathStack>('navStack')!;
  // ★ 核心：蒙层背景色作为状态变量，通过动画驱动渐变
  @State backColor: ResourceColor = '#00000000';
  @State contentOffset: number = 0;

  build() {
    NavDestination() {
      Stack() {
        // 弹窗内容
        Column({ space: 16 }) {
          // 拖拽指示条
          Row() {
            Row().width(36).height(4).borderRadius(2).backgroundColor('#e0e0e0')
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 8 })

          Text('确认操作').fontSize(20).fontWeight(FontWeight.Bold)
          Text('此操作不可撤销，请确认是否继续？')
            .fontSize(14)
            .fontColor('#666666')

          Row({ space: 12 }) {
            Button('取消')
              .layoutWeight(1)
              .backgroundColor('#f5f5f5')
              .fontColor('#333333')
              .onClick(() => {
                this.navStack.pop();
              })

            Button('确认')
              .layoutWeight(1)
              .onClick(() => {
                this.navStack.pop({ confirmed: true });
              })
          }
          .width('100%')
        }
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius({ topLeft: 16, topRight: 16 })
        .padding({ left: 20, right: 20, top: 12, bottom: 28 })
        .translate({ y: this.contentOffset })
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor(this.backColor)  // ★ 蒙层背景色绑定到状态变量
    .mode(NavDestinationMode.DIALOG)
    // ★ 入场时蒙层渐现
    .onWillAppear(() => {
      this.backColor = '#00000000';  // 初始透明
      this.getUIContext().animateTo({ duration: 450, curve: Curve.EaseOut }, () => {
        this.backColor = '#66000000';  // 渐变到半透明黑
      });
    })
    // ★ 退场时蒙层渐隐
    .onWillDisappear(() => {
      this.getUIContext().animateTo({ duration: 450, curve: Curve.EaseIn }, () => {
        this.backColor = '#00000000';  // 渐变回全透明
      });
    })
  }
}
```

#### 关键 API 说明

| API | 说明 | 起始版本 |
|-----|------|---------|
| `NavDestinationMode.DIALOG` | DIALOG 模式，透明叠加 | API 11+ |
| `NavDestination.onWillAppear()` | 页面挂载前回调，用于启动入场动画 | API 12+ |
| `NavDestination.onWillDisappear()` | 页面卸载前回调，用于启动退场动画 | API 12+ |

#### 注意事项

1. **背景色设在 NavDestination 上**：`backgroundColor` 绑定到状态变量，动画驱动整个页面（包括蒙层区域）的背景色变化。不要设在内容面板上，否则 pop 时蒙层会随内容一起退出。

2. **onWillAppear vs onWillDisappear**：入场在 `onWillAppear`（页面挂载前）启动动画，退场在 `onWillDisappear`（页面卸载前）启动动画，时机正确才能看到效果。

3. **DIALOG 默认动画**：API 13 起存在系统转场动画（内容区下滑），手动蒙层动画与之叠加产生组合效果。

4. **duration 匹配**：建议入场/退场动画时长与系统 DIALOG 转场时长接近，视觉上更协调。

