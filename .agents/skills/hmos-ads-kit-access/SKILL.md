---
name: hmos-ads-kit-access
description: HarmonyOS Ads Kit 广告服务开发指南 — 涵盖6种广告形式(横幅/原生/激励/插屏/开屏/贴片)的完整接入文档、代码模板、自动化场景识别与植入决策引擎。触发关键词：广告接入, Ads Kit, 流量变现, 横幅广告, 原生广告, 激励广告, 插屏广告, 开屏广告, 贴片广告, OAID, 广告自动化接入, 广告植入, RTB, 广告错误排查
---

# HarmonyOS Ads Kit (广告服务) 开发指南

## 描述

本 Skill 包含华为鸿蒙（HarmonyOS）Ads Kit（广告服务）的完整开发文档，涵盖流量变现服务、广告形式（横幅、原生、激励、插屏、开屏、贴片）、OAID（开放匿名设备标识符）、实时竞价、常见问题等所有核心内容，并包含完整的示例工程结构参考和自动化广告接入决策引擎。

## 触发条件

当用户需要以下帮助时，自动加载本 Skill：
- 鸿蒙/HarmonyOS 广告接入相关的问题
- Ads Kit（广告服务）的 API 使用
- 流量变现服务开发
- 各种广告形式的实现（横幅广告、原生广告、激励广告、插屏广告、开屏广告、贴片广告）
- 实时竞价（RTB）集成
- OAID 获取与使用
- 广告相关错误排查
- Web 组件广告过滤
- 为已有应用自动识别广告植入位置和类型

## 文档索引

本 Skill 包含 **32 篇**鸿蒙广告相关文档，分为开发指南（19篇）和 API 参考（13篇）：

- 开发指南: `reference/*.md`（19篇）
- API 参考: `reference/api/*.md`（13篇）

---

## 快速接入指南

### 1. 开发环境与权限配置

详细步骤参见 `reference/development-preparation.md`，核心要点：

**module.json5 权限配置**（必须）：

```json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.APP_TRACKING_CONSENT",
        "reason": "$string:app_tracking_permission_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}
```

**SDK 版本要求**：compatibleSdkVersion ≥ 5.0.5(17)，targetSdkVersion ≥ 6.0.0(20)

### 2. 广告类型枚举速查

| 广告类型 | adType值 | 测试广告位ID | 展示形式 | 推广类型 |
| -------- | -------- | ------------ | -------- | -------- |
| 开屏(Splash) | 1 | g3tl51sqih / r145sz31dp | 图片/视频 | 应用促活 |
| 原生(Native) | 3 | h8asowxwhq / k94abyn2z4 / o7dj7qsbvy / s7moc0jc6m | 大图/小图/三图/视频 | 应用下载/促活 |
| 激励(Reward) | 7 | j14rx3xtac / j2mh81xmqs | 图片/视频 | 应用下载/网页推广 |
| 横幅(Banner) | 8 | h5xkz3mbr2 / f9enfij16h / u8fqe1ru81 | 图片 | 应用下载/促活 |
| 插屏(Interstitial) | 12 | p540739a8w / v1rknehtfa | 图片/视频 | 网页推广/元服务推广 |
| 贴片(Roll) | 60 | o2e960bnfz | 视频 | 应用下载 |

> 注意：以上为华为官方文档中的测试广告位ID，仅用于功能调试，不可用于变现。正式发布前需在鲸鸿动能媒体服务平台申请正式广告位ID。
> Demo工程中使用的是另一套测试广告位ID（如 testw6vs28auh3 等），两套均可用于调测。

### 3. 广告展示模式选型指南

HarmonyOS Ads Kit 提供 **三种广告展示模式**，根据广告类型选择：

| 展示模式 | 适用广告类型 | 核心组件/接口 | 特点 |
| -------- | ------------ | ------------- | ---- |
| **AutoAdComponent 模式** | 横幅广告 | `AutoAdComponent` | 声明式组件，自动请求+展示+轮播，一行代码完成广告接入 |
| **AdComponent 模式** | 原生广告、开屏广告、贴片广告 | `AdLoader.loadAd()` + `AdComponent` | 手动请求广告，通过 AdComponent 自定义展示布局 |
| **showAd 模式** | 激励广告、插屏广告 | `AdLoader.loadAd()` + `advertising.showAd()` | 手动请求广告，系统全屏展示，需订阅公共事件监听状态 |

**选型流程**：
1. 横幅广告 → 直接用 `AutoAdComponent`，最简接入
2. 需要自定义广告UI布局 → 用 `AdComponent`
3. 全屏类广告（激励/插屏） → 用 `showAd` + 公共事件订阅

### 4. 示例工程结构参考

基于华为官方 Demo 工程（bundleName: com.huawei.ads.clientdemo）整理：

```
entry/src/main/
├── ets/
│   ├── constant/
│   │   ├── AdType.ets              # 广告类型枚举（SPLASH=1, NATIVE=3, REWARD=7, BANNER=8, INTERSTITIAL=12, ROLL=60）
│   │   └── AdStatus.ets            # 广告状态枚举（onAdOpen/onAdClose/onAdClick/onAdFail/onAdReward 等）
│   ├── entryability/
│   │   └── EntryAbility.ets        # 应用入口 Ability
│   ├── event/
│   │   ├── InterstitialAdStatusHandler.ets  # 插屏广告公共事件订阅
│   │   ├── RewardAdStatusHandler.ets        # 激励广告公共事件订阅
│   │   └── TimeOutHandler.ets              # 开屏广告超时处理
│   ├── pages/
│   │   ├── Index.ets               # 主页面：OAID获取 + 广告请求入口
│   │   └── ads/
│   │       ├── BannerAdPage.ets     # 横幅广告页（AutoAdComponent模式）
│   │       ├── NativeAdPage.ets     # 原生广告页（AdComponent模式）
│   │       ├── SplashAdPage.ets     # 开屏广告页（AdComponent模式 + 超时处理）
│   │       └── RollAdPage.ets       # 贴片广告页（AdComponent模式 + 横竖屏切换）
│   └── viewmodel/
│       └── AdsViewModel.ets        # 广告请求/展示统一ViewModel（@ObservedV2）
├── module.json5                    # 权限配置 + Ability声明
└── resources/
    ├── base/
    │   ├── element/string.json     # 权限说明文案
    │   ├── media/slogan.png        # 开屏默认Slogan图
    │   └── profile/main_pages.json # 页面路由
    └── rawfile/videoTest.mp4       # 贴片广告正片视频
```

### 5. ArkTS 语法合规规范（必须遵守）

完整规范（含正误代码示例）见 `reference/arkts-code-compliance.md`，核心要点：

1. **禁止对象字面量作类型**（arkts-no-obj-literals-as-types）：回调/构造参数必须先声明 `interface` 再引用
2. **Context 必须为 UIAbilityContext**：`getHostContext()` 返回值传给 `AdLoader`/`showAd` 时须 `as common.UIAbilityContext`
3. **系统资源名必须存在**：`$r('sys.color.xxx')` 需确认资源存在，避免使用如 `comp_background_quaternary` 等不存在资源
4. **必须导入 common**：使用 `common.UIAbilityContext` 的文件必须 `import { common } from '@kit.AbilityKit'`
5. **系统接口可直接赋值对象字面量**：`advertising.AdLoadListener`/`AdInteractionListener` 是系统定义接口，合规
6. **广告加载失败不得阻塞流程**：所有接入必须处理 `onAdLoadFailure` 回调（开屏跳主页、Banner/Native 隐藏组件、激励/插屏取消订阅）

> **接入完成提示**：测试广告位 ID 可能因设备/网络/区域等因素加载失败，属于正常现象。正式发布前需在鲸鸿动能媒体服务平台申请正式广告位 ID。

### 5. 核心代码模板

完整代码模板（AdType/AdStatus 枚举、OAID 获取、统一 ViewModel、公共事件订阅、超时处理）见 `reference/code-templates.md`。

- **AdType 枚举**：SPLASH=1 / NATIVE=3 / REWARD=7 / BANNER=8 / INTERSTITIAL=12 / ROLL=60
- **AdStatus 枚举**：onAdOpen / onAdClose / onAdClick / onAdFail / onAdReward / onMediaComplete 等
- **OAID 获取**：所有广告通用前置步骤（申请 `APP_TRACKING_CONSENT` → `identifier.getOAID()`）
- **统一 ViewModel**：`AdsViewModel` 封装请求/展示逻辑，按 adType 分流到 showAd 或 AdComponent
- **公共事件订阅**：激励广告 `PPS_REWARD_STATUS_CHANGED`、插屏广告 `PPS_INTERSTITIAL_STATUS_CHANGED`
- **开屏超时**：`TimeOutHandler` 防止开屏广告加载超时阻塞流程

---

## 自动化广告接入决策引擎

当需要为已有应用工程自动接入广告时，按以下流程进行场景识别、用户确认、然后实施。

### 第一步：场景识别

扫描应用的页面代码，根据 UI 结构特征匹配最佳广告类型：

| UI结构特征 | 匹配的广告类型 | 识别关键词/组件 | 植入位置 |
| ---------- | -------------- | --------------- | -------- |
| 应用启动入口页面（首个加载的页面） | **开屏广告** | `@Entry` + `aboutToAppear` + 页面路由为首页 | 原页面之前插入开屏页，展示后跳转回原页面 |
| 滚动列表（信息流/瀑布流） | **原生广告** | `List` / `WaterFlow` / `LazyForEach` / `Repeat` / `Grid` | 列表项之间间隔插入（每N项插一条） |
| 页面底部固定区域 | **横幅广告** | `Tabs`(底部tab) / `Stack({alignContent: Alignment.Bottom})` / 页面最外层底部 | 底部区域上方追加 AutoAdComponent |
| 视频播放器页面 | **贴片广告** | `Video` 组件 | 播放前/中/后，替换Video为AdComponent+Video切换逻辑 |
| 按钮触发奖励/解锁/续命场景 | **激励广告** | 按钮文案含"领取/解锁/续命/翻倍/奖励" + 点击后需等待 | 按钮点击 → loadAd+showAd → onAdReward后发放奖励 |
| 页面切换/暂停/返回场景 | **插屏广告** | `onPageHide` / `onBackground` / `router.back` / 页面间跳转 | 在页面生命周期切换时触发 |

### 第二步：向用户确认广告位方案（必须）

扫描完成后，**必须**使用 `AskUserQuestion` 工具向用户展示识别结果并确认，格式如下：

```
问题："以下是为该应用识别到的广告接入位置，请选择要接入的广告位："
选项：multiSelect=true，每个选项对应一个识别到的广告位

选项格式：
- label: "页面名 - 广告类型"
  description: "植入位置描述 + 展示模式"
```

**示例输出**：

> 以下是为该应用识别到的广告接入位置，请选择要接入的广告位：
>
> | # | 页面 | 广告类型 | 植入位置 | 展示模式 |
> | - | ---- | -------- | -------- | -------- |
> | 1 | HomePage | 横幅广告 | 底部Tab栏上方 | AutoAdComponent |
> | 2 | HomePage | 原生广告 | 工具列表Grid末尾 | AdComponent |
> | 3 | ScreenRecordPage | 贴片广告 | 视频播放前 | AdComponent |
>
> 请选择要接入的广告位（可多选），或补充其他位置。

**规则**：
- 用户可以多选，也可以一个都不选
- 用户可能补充未识别到的位置（如"在设置页底部也加一个横幅"），此时应纳入方案
- 如果用户选择的广告位涉及禁止场景（支付页/登录页等），应警告用户并建议移除
- 只有用户确认后，才进入准备和植入阶段

### 识别决策树

```
扫描应用页面代码
│
├─ 是否为应用首页(首个@Entry页面)？
│   └─ 是 → 推荐开屏广告（在首页前插入SplashAdPage）
│
├─ 页面是否包含 List/WaterFlow/Grid？
│   ├─ 是 → 推荐原生广告（列表项间插入AdComponent）
│   └─ 否 → 继续判断
│
├─ 页面是否包含 Video 组件？
│   └─ 是 → 推荐贴片广告（Video播放前插入广告）
│
├─ 页面是否有底部固定区域(Tabs/底部栏)？
│   └─ 是 → 推荐横幅广告（底部区域上方插入AutoAdComponent）
│
├─ 页面中是否有"领取/解锁/奖励"类按钮？
│   └─ 是 → 推荐激励广告（按钮点击触发showAd）
│
└─ 页面是否有频繁切换/跳转场景？
    └─ 是 → 推荐插屏广告（页面切换时触发showAd）
```

### 代码植入模式

#### 模式1：列表页植入原生广告（最常见场景）

**识别信号**：页面中存在 `List` / `WaterFlow` + `ListItem` / `FlowItem`

**植入方式**：在列表数据源中每隔 N 项插入广告占位

```typescript
// 原始代码：
List() {
  Repeat<DataItem>(this.dataList).each((repeatItem) => {
    ListItem() {
      DataItemCard({ item: repeatItem.item })
    }
  })
}

// 植入后代码：
// 注意：需导入 import { advertising, AdComponent } from '@kit.AdsKit';
List() {
  Repeat<ListItemData>(this.mixedList).each((repeatItem) => {
    ListItem() {
      if (repeatItem.item.type === 'ad') {
        // 原生广告 ads 参数必须传 [单条广告]，不能传整个数组
        AdComponent({
          ads: [repeatItem.item.ad!],
          displayOptions: this.adDisplayOptions,
          interactionListener: { onStatusChanged: (status, ad, data) => { /* ... */ } }
        }).width('100%')
      } else {
        DataItemCard({ item: repeatItem.item.data! })
      }
    }
  })
}

// 数据混合逻辑：每5条内容插入1条广告
private mixAdsIntoList(data: DataItem[], ads: advertising.Advertisement[]): ListItemData[] {
  const result: ListItemData[] = [];
  let adIndex = 0;
  const interval = 5;
  data.forEach((item, index) => {
    result.push({ type: 'content', data: item });
    if ((index + 1) % interval === 0 && adIndex < ads.length) {
      result.push({ type: 'ad', ad: ads[adIndex++] });
    }
  });
  return result;
}
```

#### 模式2：页面底部植入横幅广告

**识别信号**：页面底部有 `Tabs` / 固定底栏 / `Column` 底部区域

**植入方式**：在页面最外层布局底部追加 AutoAdComponent

```typescript
// 原始代码：
Column() {
  // ...页面内容
  BottomBar()  // 底部导航栏
}

// 植入后代码：
// 注意：需导入 import { advertising, AutoAdComponent, AdComponent } from '@kit.AdsKit';
Column() {
  // ...页面内容（需减少高度或添加Scroll）
  Scroll() {
    Column() {
      // ...原有页面内容
    }
  }.layoutWeight(1)

  // 横幅广告插在内容和底栏之间
  AutoAdComponent({
    adParam: { adId: 'testw6vs28auh3', adType: 8, adWidth: 360, adHeight: 57, oaid: this.oaid },
    adOptions: {},
    displayOptions: { refreshTime: 30000 },
    interactionListener: { onStatusChanged: (status, ad, data) => { /* ... */ } }
  }).width('100%').height(57)

  BottomBar()  // 底部导航栏
}
```

#### 模式3：开屏广告植入

**识别信号**：应用首页 `@Entry` 组件（`main_pages.json` 中的第一个页面）

**植入方式**：创建独立开屏页，修改路由使应用先进入开屏页

```typescript
// 1. 创建 SplashAdPage.ets（参见核心代码模板 5.6 + 示例工程 SplashAdPage）
// 2. 在 main_pages.json 中将开屏页设为首页：
//    "src": ["pages/SplashAdPage", "pages/Index"]
// 3. 开屏广告展示结束后跳转到原首页：navPathStack.replacePathByName('Index', null)
```

#### 模式4：激励广告植入

**识别信号**：按钮文案/语义含"领取/解锁/续命/加倍"等，且需要用户主动触发

**植入方式**：替换按钮点击逻辑为"加载激励广告 → 观看完成发放奖励"

```typescript
// 原始代码：
Button('领取金币')
  .onClick(() => { this.addCoins(100); })

// 植入后代码：
Button('看广告领金币')
  .onClick(() => {
    new RewardAdStatusHandler().registerPPSReceiver();
    // loadAd → onAdLoadSuccess → showAd
    // onAdReward 回调中: this.addCoins(100);
  })
```

#### 模式5：插屏广告植入

**识别信号**：页面切换、关卡过渡、返回操作等场景

**植入方式**：在页面切换逻辑前加载并展示插屏广告

```typescript
// 原始代码：
Button('下一关')
  .onClick(() => { router.pushUrl({ url: 'pages/Level2' }); })

// 植入后代码：
Button('下一关')
  .onClick(async () => {
    new InterstitialAdStatusHandler().registerPPSReceiver();
    // loadAd → onAdLoadSuccess → showAd
    // onAdClose 回调中: router.pushUrl({ url: 'pages/Level2' });
  })
```

#### 模式6：贴片广告植入

**识别信号**：页面包含 `Video` 组件

**植入方式**：视频播放前展示贴片广告，广告完成后自动播放正片

```typescript
// 参见示例工程 RollAdPage.ets 的 isPlayVideo 切换逻辑
// AdComponent(广告) 和 Video(正片) 通过 isPlayVideo 状态切换显示
```

### 广告密度与频控规则

| 规则 | 说明 |
| ---- | ---- |
| 原生广告间隔 | 信息流中每 5-8 条内容插入1条广告，首条广告不早于第3条 |
| 横幅广告 | 单页面仅1个横幅广告位，轮播间隔 30-120 秒 |
| 开屏广告 | 应用冷启动展示1次，短时间内不重复展示 |
| 激励广告 | 用户主动触发，不自动弹出；同一场景需间隔 >60 秒 |
| 插屏广告 | 页面切换时展示，同一用户每分钟最多1次 |
| 贴片广告 | 视频前/中/后各1次，总时长 ≤30 秒 |

### 禁止植入广告的场景

| 禁止场景 | 原因 |
| -------- | ---- |
| 支付/交易页面 | 误触广告会导致用户流失和资损 |
| 表单填写/输入页面 | 广告弹出打断用户输入 |
| 登录/注册页面 | 阻碍核心流程 |
| 弹窗/对话框中 | 体验极差 |
| 广告叠加（同页多类型同时展示） | 除非有明确设计意图 |

### 自动化接入执行清单

对目标应用工程执行以下步骤：

```
1. 扫描阶段
   □ 读取 module.json5，检查权限配置（INTERNET + APP_TRACKING_CONSENT）
   □ 读取 main_pages.json，识别所有页面入口
   □ 逐页扫描 @Entry/@Component 代码，记录 UI 结构特征

2. 确认阶段（必须）
   □ 汇总识别到的广告位清单：页面路径 + 广告类型 + 植入位置 + 展示模式
   □ 使用 AskUserQuestion 展示清单，让用户选择要接入的广告位
   □ 用户补充的位置纳入方案；禁止场景的位置警告用户
   □ 仅按用户确认的广告位进入后续阶段

3. 准备阶段
   □ 创建 constant/AdType.ets 和 constant/AdStatus.ets
   □ 创建 viewmodel/AdsViewModel.ets
   □ 创建 event/RewardAdStatusHandler.ets（如有激励广告）
     - 回调参数必须使用 interface 声明（如 RewardAdCallbacks），禁止对象字面量作类型
   □ 创建 event/InterstitialAdStatusHandler.ets（如有插屏广告）
     - 回调参数必须使用 interface 声明（如 InterstitialAdCallbacks），禁止对象字面量作类型
   □ 创建 event/TimeOutHandler.ets（如有开屏广告）
   □ 在 module.json5 中补充权限配置
   □ 在 string.json 中补充权限说明文案

4. 植入阶段（必须遵守 ArkTS 语法规范）
   □ 按确认的广告位清单逐个植入广告代码
   □ 使用对应的代码植入模式（模式1-6）
   □ 更新页面路由（如需新增开屏页）
   □ 所有 getHostContext() 返回值传给广告API时，必须 as common.UIAbilityContext
   □ 使用 common.UIAbilityContext 的文件必须 import { common } from '@kit.AbilityKit'
   □ 自定义回调类型必须先声明 interface，不能在参数中用对象字面量类型
   □ 不得使用不存在的系统资源名（如 comp_background_quaternary）
   □ 广告加载失败时不得阻塞用户正常流程

5. 编译验证阶段（必须）
   □ 执行 hvigorw 编译：hvigorw --mode module -p module=entry@default --no-daemon -p product=default assembleHap
   □ 如有编译错误，按以下优先级逐个修复：
     a) arkts-no-obj-literals-as-types → 提取对象字面量为 interface
     b) arkts-no-untyped-obj-literals → 确保对象字面量赋值给已声明类型的变量
     c) Context vs UIAbilityContext → 添加 as common.UIAbilityContext 转换
     d) Cannot find namespace 'common' → 添加 import { common } from '@kit.AbilityKit'
     e) Unknown resource name → 替换为存在的系统资源名
   □ 循环编译直到 BUILD SUCCESSFUL
   □ 编译成功后，告知用户：测试广告位ID可能因设备/网络/区域等因素加载失败，正式发布前需替换为正式广告位ID
```

---

## 开发指南文档索引

### Ads Kit（广告服务）核心文档

| 文档ID | 标题 | 说明 |
| -------- | ------ | ------ |
| `ads-introduction` | Ads Kit简介 | 整体介绍、流量变现服务、OAID服务、场景介绍、约束和限制 |
| `ads-kit-glossary` | Ads Kit术语 | 广告相关的专业术语解释 |
| `ads-kit-guide` | Ads Kit（广告服务） | 功能列表与开发索引 |
| `ads-publisher-service-dev` | 流量变现服务开发 | 开发概述与所有广告形式汇总 |

### 广告形式开发指南

| 文档ID | 标题 | 说明 | 展示模式 |
| -------- | ------ | ------ | -------- |
| `ads-publisher-service-dev-overview` | 流量变现服务开发概述 | 开发前的准备工作和概述 | - |
| `ads-publisher-service-banner` | 横幅广告 | Banner广告的接入与开发 | AutoAdComponent |
| `ads-publisher-service-native` | 原生广告 | 原生广告的接入与开发 | AdComponent |
| `ads-publisher-service-reward` | 激励广告 | 激励视频广告的接入与开发 | showAd + 公共事件 |
| `ads-publisher-service-interstitial` | 插屏广告 | 插屏广告的接入与开发 | showAd + 公共事件 |
| `ads-publisher-service-splash` | 开屏广告 | 开屏广告的接入与开发 | AdComponent + 超时处理 |
| `ads-publisher-service-roll` | 贴片广告 | 贴片广告的接入与开发 | AdComponent + 横竖屏 |
| `ads-real-time-bidding` | 实时竞价 | 实时竞价的集成说明 | - |

### 常见问题

| 文档ID | 标题 | 说明 |
| -------- | ------ | ------ |
| `ads-publisher-service-faq` | 流量变现服务常见问题 | FAQ总览 |
| `ads-publisher-service-faq-4` | 展示广告时显示白屏 | 白屏问题排查 |
| `ads-publisher-service-faq-6` | 鲸鸿动能媒体服务平台打开受限 | 平台受限问题 |
| `ads-publisher-service-faq-7` | PC设备请求或展示广告时返回了801错误码 | 801错误码排查 |

### 相关文档

| 文档ID | 标题 | 说明 |
| -------- | ------ | ------ |
| `development-preparation` | 开发准备 | 权限申请、环境配置 |
| `description-of-personal-data` | 鲸鸿动能Ads Kit个人数据处理说明 | 个人数据处理与隐私合规 |
| `ad-redirection` | 广告跳转 | 应用间广告跳转实现 |
| `web-adsblock` | 使用Web组件的广告过滤功能 | Web组件中的广告过滤 |
| `app-linking-startup` | App Linking启动 | 通过App Linking实现应用启动（[华为官方文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-linking-startup)） |
| `application-context-stage` | 各类Context的获取方式 | UIAbilityContext、ApplicationContext等获取方式 |
| `applinking-deferredlink` | App Linking延迟深度链接 | 延迟深度链接实现 |
| `applinking-direct-to-ag` | App Linking直达AppGallery | 直达应用市场场景 |
| `ide-emulator-specification` | 模拟器规格 | IDE模拟器规格说明 |
| `oaid-service` | OAID服务 | 开放匿名设备标识符服务 |
| `permissions-for-all` | 权限列表 | HarmonyOS全部权限说明 |
| `request-user-authorization` | 向用户申请授权 | 用户授权申请指导 |
| `social-sharing-redirection` | 社交分享跳转 | 社交分享链接跳转 |
| `arkts-code-compliance` | ArkTS语法合规规范 | ArkTS编译必须遵守的语法约束（含正误代码示例） |
| `code-templates` | 核心代码模板 | AdType/AdStatus枚举、OAID获取、ViewModel、公共事件订阅、超时处理 |

## 使用方式

参考文档位于: `reference/`

1. 当用户提问时，根据问题内容找到相关的文档
2. 使用 `read` 工具读取对应的 `reference/{文档ID}.md` 文件
3. 解析文档中的代码示例和 API 说明，帮用户解决问题

### 文档分类与路由

- **环境/权限** → `development-preparation.md`
- **ArkTS语法合规** → `arkts-code-compliance.md`
- **核心代码模板** → `code-templates.md`
- **概述/入门** → `ads-introduction.md`, `ads-kit-guide.md`
- **术语查询** → `ads-kit-glossary.md`
- **横幅广告** → `ads-publisher-service-banner.md`
- **原生广告** → `ads-publisher-service-native.md`
- **激励广告** → `ads-publisher-service-reward.md`
- **插屏广告** → `ads-publisher-service-interstitial.md`
- **开屏广告** → `ads-publisher-service-splash.md`
- **贴片广告** → `ads-publisher-service-roll.md`
- **实时竞价/RTB** → `ads-real-time-bidding.md`
- **错误排查** → `ads-publisher-service-faq*.md`
- **隐私合规** → `description-of-personal-data.md`
- **Web广告过滤** → `web-adsblock.md`
- **广告跳转** → `ad-redirection.md`
- **核心API/所有接口** → `api/js-apis-advertising.md`（广告服务框架全部API）
- **广告对象类型** → `api/js-apis-advertisement.md`
- **AutoAdComponent组件** → `api/js-apis-autoadcomponent.md`
- **AdComponent组件** → `api/js-apis-adcomponent.md`
- **广告扩展服务** → `api/js-apis-adsserviceextensionability.md`
- **OAID标识符** → `api/js-apis-oaid.md`
- **广告错误码** → `api/errorcode-ads.md`, `api/errorcode-oaid.md`

## API 参考文档

| 文档ID | 标题 | 说明 |
| -------- | ------ | ------ |
| `api/js-apis-advertising` | @ohos.advertising (广告服务框架) | 核心API：导入模块、showAd、loadAd、AdRequestParams、AdOptions、AdDisplayOptions、AdLoadListener、AdInteractionListener、错误码等全部接口 |
| `api/js-apis-advertisement` | advertisement (广告内容) | 广告对象类型定义 |
| `api/js-apis-autoadcomponent` | @ohos.advertising.AutoAdComponent | 轮播广告展示组件属性与方法 |
| `api/js-apis-adcomponent` | @ohos.advertising.AdComponent | 广告展示组件属性与方法 |
| `api/js-apis-adsserviceextensionability` | @ohos.advertising.AdsServiceExtensionAbility | 广告扩展服务能力 |
| `api/js-apis-oaid` | @ohos.identifier.oaid (OAID) | 开放匿名设备标识符获取API |
| `api/ads-api` | Ads Kit API 总览 | API列表与导航 |
| `api/ads-arkts` | ArkTS API 目录 | ArkTS API索引 |
| `api/ads-advert` | advertisement 目录 | advertisement子模块导航 |
| `api/ads-comp` | ArkTS组件 目录 | 广告组件导航 |
| `api/errorcode-ads` | 广告服务框架错误码 | 21800001-21800005等错误码详解 |
| `api/errorcode-oaid` | OAID错误码 | 17300001, 17300002等错误码详解 |
| `api/ads-arkts-errcode` | 错误码 目录 | 错误码导航 |

## 关键API速查

### 广告请求核心流程

```
0. 导入模块 → import { advertising, AutoAdComponent, AdComponent } from '@kit.AdsKit'
1. 获取OAID → identifier.getOAID()（前置步骤，参见 api/js-apis-oaid.md）
2. 创建请求参数 → AdRequestParams { adId, adType, oaid }
3. 创建广告加载器 → new advertising.AdLoader(context)
4. 请求广告 → adLoader.loadAd(params, options, listener)
5. 展示广告:
   - 横幅: AutoAdComponent({ adParam, adOptions, displayOptions, interactionListener })
   - 原生/开屏/贴片: AdComponent({ ads: [单条广告], displayOptions, interactionListener })
     注意：原生广告的 ads 参数必须传 [单条广告]，不能传整个数组
   - 激励/插屏: advertising.showAd(ad, displayOptions, context)
```

### 常用错误码

| 错误码 | 说明 |
| ------ | ---- |
| 401 | 输入参数不合法。可能原因：1. 必选参数未指定。2. 参数类型错误。3. 参数校验失败。 |
| 801 | 设备不支持 |
| 21800001 | 系统内部错误 |
| 21800003 | 广告请求加载失败 |
| 21800004 | 广告展示失败 |
| 21800005 | 广告数据解析失败 |

### 权限要求

| 权限 | 类型 | 说明 |
| ---- | ---- | ---- |
| `ohos.permission.INTERNET` | system_grant | 网络访问权限 |
| `ohos.permission.APP_TRACKING_CONSENT` | user_grant | 个性化推荐权限（reason必填） |

### 各广告类型关键参数差异

| 参数 | 横幅 | 原生 | 激励 | 插屏 | 开屏 | 贴片 |
| ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| adType | 8 | 3 | 7 | 12 | 1 | 60 |
| adWidth/adHeight | 必填 | - | - | - | - | - |
| adCount | - | 可选 | - | - | 可选 | - |
| isPreload | - | - | - | - | - | 可选 |
| totalDuration | - | - | - | - | - | AdOptions中必填 |
| orientation | - | - | - | - | 可选(1竖0横) | - |
| enableDirectReturnVideoAd | - | 可选 | - | - | - | - |
