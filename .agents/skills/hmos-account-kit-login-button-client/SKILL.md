---
name: hmos-account-kit-login-button-client
description: 为尚未接入华为账号登录功能的原生 ArkTS HarmonyOS 应用接入华为 Account Kit"华为账号登录"/"华为按钮登录"功能，提供登录按钮入口、账号登录页面和用户协议页面，在获得授权码后请求应用服务端获取 Union ID，并支持根据 Prompt 配置服务端域名、登录按钮样式、颜色及应用图标。**当用户需要为 HarmonyOS 应用接入华为账号标准按钮登录（使用华为提供的标准登录按钮组件，而非自定义按钮）时使用；纯图标按钮不适用。**
license: MIT
metadata:
  author: Huawei Account Kit Team
  version: "1.0.0"
---

## Skill 选择指南

| 开发场景 | 一键登录 | 按钮登录（当前Skill） | 自定义按钮登录 |
|---|---|---|---|
| **Skill** | `hmos-account-kit-quicklogin-client` | `hmos-account-kit-login-button-client` | `hmos-account-kit-login-api-client` |
| 需要获取用户手机号 | ✅ | ❌ | ❌ |
| 使用华为标准按钮（仅可选模式和配色） | ✅ | ✅ | ❌ |
| 需要在现有登录页嵌入华为登录按钮 | ❌ | ❌ | ✅ |
| 需要自定义按钮外观（符合华为 UX 规范） | ❌ | ❌ | ✅ |
| **支持的开发者类型** | 企业开发者 | 企业开发者、个人开发者 | 企业开发者、个人开发者  |

# 华为 Account Kit "华为账号登录"功能接入

## 全局规范

1. **任务边界**：首次接入"华为账号登录"入口和登录页面。工程已存在可执行的"华为账号登录"或自定义按钮登录实现时不适用；检测到已接入**华为账号一键登录**时，停止并提供选择分支（推荐停止接入，或继续接入并自行处理业务衔接）；预取号、匿名手机号和元服务不适用；服务端接口实现、登录后业务跳转、应用登录状态管理和退出账号不适用；无关的 UI 重做、导航改造或工程重构不适用。开发者使用"普通账号登录"等表述时按"华为账号登录"继续。
2. **核心目标**：自动定位现有登录入口或新增按钮；复制固定的 `HuaweiIDLoginPage.ets` 和 `ProtocolWebView.ets`，识别 Navigation 或 Router 并接入；取得非空 `authorizationCode` 后提示登录成功并调用 `getIDInfo()`；`deveco-cli` 可用时完成编译验证。
3. **自主且单分支执行**：自行确定导航模式和入口，不询问开发者；只执行一个导航分支，不覆盖未被 Prompt 指定的既有业务逻辑。
4. **导航边界固定**：Router 打开 `HuaweiIDLoginPage`；Navigation 使用根 `NavPathStack` 打开 `HuaweiIDLoginRoot`。两种模式都保留 `HuaweiIDLoginPage` 到 `ProtocolWebView` 的内部 Router 跳转。
5. **Router 证据限定**：`loadContent()`、`@Entry` 和 `main_pages.json` 不能作为 Router 证据。只有 ets 文件中出现 `router`、`getRouter(`、`pushUrl(` 或 `replaceUrl(` 才可判定为 Router。
6. **模板受控修改**：`ProtocolWebView.ets` 不变；`HuaweiIDLoginPage.ets` 仅允许修改 `SERVICE_DOMAIN`、按钮参数、图标资源标识和 `privacyText` 数组中各项的 `tag` 字段，Navigation 分支可额外移除 `@Entry` 并导出组件。不得改写 `getIDInfo()`、固定请求路径、授权码调用和客户端成功判定。
7. **保守写入**：固定 ets 同路径冲突即停止；资源 JSON 保留既有字段和值，只补缺失项。模板与资源只能由复制脚本写入，不手工重建、猜测或绕过失败。
8. **不扩展范围**：不伪造包名、客户端 ID、签名、协议地址或服务端域名；不增加登录后跳转、状态管理、退出账号或无关重构；新增入口不得遮挡已有组件。
9. **需求确认**：当用户仅提及"华为账号登录"而未提供具体接入需求时，**停止执行**，简要介绍本 Skill 功能，并请用户确认或补充需求后再继续。

---

## 文件资源

```text
assets/HuaweiIDLogin/
├── AppScope/resources/
├── entry/src/main/resources/
├── entry/src/main/ets/HuaweiIDLogin/HuaweiIDLoginPage.ets
└── entry/src/main/ets/HuaweiIDLogin/ProtocolWebView.ets
references/
├── account-api-component-manager.md
└── huawei-account-login-button.md
scripts/
└── copy-huawei-id-login-assets.mjs
```

### assets/HuaweiIDLogin/ — 固定资源库

- `HuaweiIDLoginPage.ets`：华为账号登录页面，包含登录组件、授权码获取、服务端请求框架和按钮参数配置。
- `ProtocolWebView.ets`：用户协议 WebView 页面，由登录页面通过 Router 跳转打开。
- `AppScope/resources/`：应用级资源（rawfile 等）。
- `entry/src/main/resources/`：模块级资源（颜色、字符串、媒体图片等）。

资源目录中的实际文件由脚本运行时递归发现，不在 Skill 或脚本中维护资源名称清单。不得从目标工程、网络或模型生成内容补齐资源库，不得伪造字符串、图片或协议地址。

### references/ — API 参考文档

- `account-api-component-manager.md`：华为官网 `loginComponentManager` API，是按钮参数名、类型、枚举和组合约束的唯一依据。文件缺失或不可读时停止定制，不使用模型记忆或网络内容补全。
- `huawei-account-login-button.md`：华为账号登录按钮样式知识，包含纯文本/图文混合按钮的样式规则、选型规则和代码审查清单。全局默认配色：华为红 `BUTTON_RED`。

不得通读整个 API reference，应使用文本搜索工具定位所需符号，只读取匹配位置及其直接相邻的类型定义和约束。

### scripts/ — 复制脚本

- `copy-huawei-id-login-assets.mjs`：固定 ets、资源、JSON 合并和初始页面注册的唯一写入通道，负责失败回滚与结果校验。

仅当 `status: copied`、`verified_files === planned_files` 且 `failed_files` 为空时才继续；其他状态均停止。不得手工补复制、创建占位资源、重建 ets 或猜测文案与协议地址。

---

## 决策树

本 Skill 涉及多个分支判断，以下决策树系统化各判断逻辑。执行时按顺序自上而下匹配，命中即停止。

### 导航模式选择

```
Prompt 是否明确要求 Navigation 或 Router？
├── 是 → 直接采用 Prompt 指定的模式
└── 否 → 枚举 entry/src/main/ets 中的 .ets 源文件（排除模板文件）
           │
           ├── 出现 Navigation( / NavDestination( / .navDestination(
           │   └── → Navigation
           │
           ├── 出现 router / getRouter( / pushUrl( / replaceUrl(
           │   └── → Router（记录命中关键词、文件路径、代码位置）
           │
           └── 均未出现
               └── → 默认 Navigation
```

### 一键登录并存处理

```
Step1 是否检测到华为账号一键登录？
├── 否 → 继续正常流程
└── 是 → 停止执行，向开发者提供选择
           │
           ├── 开发者选择 (1) 停止接入
           │   └── → 终止，不再执行后续步骤
           │
           └── 开发者选择 (2) 继续接入
               └── → 继续执行，华为账号登录按钮放置在一键登录按钮下方
                      输出阶段列出四项业务衔接建议
```

### 入口确定逻辑

```
Prompt 是否明确指定入口？
├── 是 → 采用 Prompt 指定的页面/组件/位置
└── 否 → 搜索现有入口（登录/账号语义的可点击组件）
           │
           ├── 找到匹配入口
           │   └── → 输出选择结果，请用户确认
           │          ├── 用户确认 → 使用该入口
           │          └── 用户指定其他 → 使用用户指定的入口
           │
           └── 未找到匹配入口
               └── → 按优先级新增按钮：
                      个人中心/我的页面 > loadContent() 启动页 > Index.ets > 唯一 @Entry 页面
```

### 按钮类型与颜色配置

```
Prompt 是否指定按钮配置？
├── 仅指定颜色 → 纯文本 + 指定颜色
├── 仅指定类型 → 指定类型 + 华为红 BUTTON_RED
├── 同时指定类型和颜色 → 按指定组合（图文混合自定义颜色不支持）
├── 要求纯图标 → 说明不支持，停止
└── 均未指定 → 保留默认值（纯文本、华为红 BUTTON_RED）
```

---

## 执行流程

### Step1：工程感知

只检查以下范围，不扫描 `build/`、依赖缓存或整个工程：

- `AppScope/app.json5`、`build-profile.json5`、`entry/src/main/module.json5`、`entry/src/main/ets`、`entry/src/main/resources/base/profile/main_pages.json`

使用文本搜索工具在 `entry/src/main/ets` 中搜索华为账号登录接口、`authorizationCode`、登录页面、协议页和已连接入口。搜索结果只是候选证据，必须读取匹配代码后再判断。

读取匹配代码后，按「决策树 - 一键登录并存处理」执行判定。

检测到已接入华为账号一键登录且开发者选择继续接入时，需自行处理以下业务衔接：
1. **用户标识统一**：两种登录方式均可获取 `UnionID` 和 `OpenID`，推荐使用 `UnionID` 作为用户唯一标识，确保两种登录方式识别为同一用户。一键登录额外获取手机号，需将手机号与 `UnionID` 关联存储。
2. **服务端接口区分**：一键登录的授权码需调用 `/oauth2/v6/quickLogin/getPhoneNumber` 获取手机号和 `UnionID`/`OpenID`；华为账号登录的授权码需调用 `/oauth2/v6/token` 换取 `access_token` 后获取 `UnionID`/`OpenID`。两个接口路径和返回数据不同，需分别实现。
3. **登录态同步**：监听华为账号登录/登出事件，任一登录方式成功后统一更新应用登录状态，登出时清除所有登录态并跳转到登录页面。
4. **协议状态管理**：两种登录方式均需用户同意协议，但协议状态独立管理，需分别设置 `AgreementStatus`。

请开发者选择 (1) 或 (2)。选择 (1) 时停止执行；选择 (2) 时继续执行后续步骤。

**记录运行前配置**：读取并记录 `AppScope/app.json5` 的 `bundleName`、`entry/src/main/module.json5` 的 `client_id`、工程级 `build-profile.json5` 的 `app.signingConfigs` 数组（非空为 `configured`，不存在或空为 `unconfigured`，无法读取为 `unreadable`）。配置缺失不影响 Skill 继续执行。

### Step2：确定入口按钮

入口确定的分支逻辑见「决策树 - 入口确定逻辑」。

**搜索现有入口**：Prompt 未指定时，在 `entry/src/main/ets` 中搜索具有登录或账号语义的可点击组件（华为账号登录、账号登录、登录、账号管理、个人账号、用户中心）。同时检查个人中心/我的页面中的**用户信息区**（头像+昵称区域，通常含 `Image` + `Text` + 箭头图标，未登录时点击进入登录是常见交互模式）。按 Prompt 语义接近度 > "华为账号登录" > "账号登录" > "登录" > "账号管理" > 用户信息区（头像/昵称）的顺序选择；并列时启动页可达 > 个人中心/我的页面 > 路径更浅且字典序靠前。

**一键登录按钮并存**：Step1 检测到已接入华为账号一键登录且开发者选择继续接入时，华为账号登录入口按钮放置在已有一键登录按钮**下方**，保持与一键登录按钮一致的间距和宽度风格。

**确认入口**：确定入口后，输出选定的入口页面、组件名称、代码位置和选择依据，请用户确认或指定其他入口。**不得跳过此确认步骤。**

**没有入口时新增按钮**：经用户确认无现有入口可复用后，按个人中心/我的页面 > `loadContent()` 启动页 > `Index.ets` > 唯一 `@Entry` 页面的顺序选择。遵循原页面间距、宽度、颜色和组件风格，只做最小布局修改。现有按钮已有重要 `onClick` 逻辑时，Prompt 指定则在保持原逻辑前提下接入，未指定则在同一功能区新增按钮。

**布局安全**：`Column`/`Row`/`Flex` 可安全插入时加入正常布局流；其他情况使用外层 `Column`，原页面容器 `.layoutWeight(1)`，按钮放下方。原根容器有 `.height('100%')` 时改用 `.layoutWeight(1)`，不得同时保留。自动新增的按钮不得使用 `position()`、`offset()`、`translate()` 或 `alignRules()`。

```ArkTS
build() {
  Column() {
    RelativeContainer() { /* 保留原页面内容 */ }
      .width('100%').layoutWeight(1)
    Button('华为账号登录')
      .width('80%').height(40)
      .margin({ top: 16, bottom: 24 })
      .onClick(() => { /* 按后续步骤配置跳转 */ })
  }.width('100%').height('100%')
}
```

### Step3：功能开发

#### 3.1 配置 INTERNET 权限

读取 `entry/src/main/module.json5` 的 `module.requestPermissions`：数组不存在时创建；已存在时按 `name` 补充并去重 `{ "name": "ohos.permission.INTERNET" }`。写入后重新读取确认。不得覆盖整个 `module.json5` 或修改 `oh-package.json5`。

#### 3.2 识别导航模式

在复制前，递归枚举 `entry/src/main/ets` 中的 `.ets` 源文件（排除 `HuaweiIDLoginPage.ets`、`ProtocolWebView.ets`、`HuaweiIDLoginRoot.ets` 三个模板文件），按「决策树 - 导航模式选择」确定模式。

判定为 Router 时必须记录命中的具体关键词、文件路径和代码位置；无法提供证据时改用 Navigation。

#### 3.3 预检并复制固定资源

将 `<SKILL_DIR>` 解析为本 `SKILL.md` 所在目录，`<PROJECT_ROOT>` 解析为目标工程根目录。Navigation 模式先确认 `HuaweiIDLoginRoot.ets` 不存在。

**只读预检**：

```bash
node "<SKILL_DIR>/scripts/copy-huawei-id-login-assets.mjs" --project "<PROJECT_ROOT>" --dry-run
```

`status` 为 `ready` 时继续；其他状态停止。

**正式复制**：

```bash
node "<SKILL_DIR>/scripts/copy-huawei-id-login-assets.mjs" --project "<PROJECT_ROOT>"
```

`status: copied`、`verified_files === planned_files` 且 `failed_files` 为空时继续；其他状态停止。

#### 3.4 执行导航分支

严格锁定 Step3.2 的结果，只执行对应分支。

**Router 分支**：只修改 Step2 确定的页面和按钮，跳转代码统一为：

```ArkTS
this.getUIContext().getRouter().pushUrl({ url: 'HuaweiIDLogin/HuaweiIDLoginPage' });
```

保持两个登录页面的 `@Entry`，保留复制脚本写入的 `HuaweiIDLogin/HuaweiIDLoginPage` 和 `HuaweiIDLogin/ProtocolWebView` 注册。不得将登录页面加入 `PageMap` 或添加 `Navigation`/`NavPathStack`。

**Navigation 分支**：

**(1) 创建 HuaweiIDLoginRoot**：确认不存在后创建：

```ArkTS
import { HuaweiIDLoginPage } from './HuaweiIDLoginPage';
@Component
export struct HuaweiIDLoginRoot {
  build() {
    NavDestination() { HuaweiIDLoginPage() }.hideTitleBar(true)
  }
}
```

不持有 `Navigation` 或 `NavPathStack`，不注册到 `main_pages.json`。

**(2) 调整页面和注册**：`HuaweiIDLoginPage.ets` 移除 `@Entry`，`struct` 改为 `export struct`；从 `main_pages.json` 移除 `HuaweiIDLogin/HuaweiIDLoginPage`，保留 `HuaweiIDLogin/ProtocolWebView`。`ProtocolWebView.ets` 不变。

**(3) 接入现有 Navigation 根容器**：在 `.navDestination(this.<PAGE_MAP>)` 绑定的 Builder 中：
- 导入 `HuaweiIDLoginRoot`，相对路径从 Builder 实现文件目录起算，逐级 `../` 回到 `entry/src/main/ets` 再拼接 `HuaweiIDLogin/HuaweiIDLoginRoot`（如 `ets/pages/HomePage.ets` → `../HuaweiIDLogin/HuaweiIDLoginRoot`）。
- 在 `<PAGE_MAP>` 中增加 `HuaweiIDLoginRoot()` 分支，保留原有名称、参数和已有分支。多个根容器依次选择管理按钮页面、启动路径、路径最浅且字典序最前者。

**(4) 工程没有 Navigation 根容器**：依次选择 `loadContent()` 启动页、实际启动的 `@Entry`、唯一 `@Entry`、`Index`/`HomePage`/`MainPage` 等中第一个真实可达页面，建立 Navigation 根容器：

```ArkTS
@Entry
@Component
struct <ENTRY_COMPONENT> {
  @Provide('huaweiIDLoginStack') huaweiIDLoginStack: NavPathStack = new NavPathStack();
  @Builder
  PageMap(name: string, params?: Record<string, Object>) {
    if (name === 'HuaweiIDLoginRoot') { HuaweiIDLoginRoot() }
  }
  build() {
    Navigation(this.huaweiIDLoginStack) { /* 保留原 build() 内容 */ }
      .hideTitleBar(true)
      .navDestination(this.PageMap)
  }
}
```

保留原 `@Entry`、组件名和 `main_pages.json` 注册。使用 `@ComponentV2` 时沿用工程已有的 `@Provider/@Consumer`，不得混用两套状态管理装饰器。

**(5) 配置入口跳转**：确定按钮组件使用的页面栈及传递方式（已有 `NavPathStack` 直接用；PageMap 参数传递沿用现有方式；`@Provide/@Consume` 传递确认标识一致；新建根容器时增加 `@Consume('huaweiIDLoginStack')`）。在按钮 `onClick` 中执行：

```ArkTS
this.<STACK>.pushPathByName('HuaweiIDLoginRoot', null, true);
```

`<STACK>` 替换为实际栈变量名。不得用 Router 打开 `HuaweiIDLoginPage`，不得注册 `HuaweiIDLoginRoot` 或 `HuaweiIDLoginPage`。

#### 3.5 配置服务端域名

Prompt 未提及服务端域名时，保留模板默认值 `SERVICE_DOMAIN = 'http://localhost:8080'`，不修改代码，在输出"待开发者完成项"中提示可修改。Prompt 明确给出域名时：完整的 `http://` 或 `https://` origin 直接校验；普通主机名默认补 `https://`，`localhost` 默认补 `http://`。只允许 scheme、host 和可选 port。只修改 `HuaweiIDLoginPage.ets` 中 `SERVICE_DOMAIN` 的值，保留其他不变。

#### 3.6 配置登录页应用图标

Prompt 未提及时保留默认 `Image($r('app.media.appmarket'))`，并在输出"待开发者完成项"中提示可更换。要求更换时：`$r('app.media.<name>')` 必须能在目标工程资源中唯一命中；只接受 `.png`/`.jpg`/`.jpeg`/`.webp`/`.svg`；只替换 `Image()` 中的媒体资源标识，保留 `Image`、`$r` 结构和全部修饰器。

#### 3.7 配置登录按钮类型与颜色

Prompt 未提及按钮类型与颜色时，保留模板默认值（纯文本、华为红 `BUTTON_RED`）。

Prompt 明确指定时按「决策树 - 按钮类型与颜色配置」处理。

将 `<API_REFERENCE>` 解析为 `<SKILL_DIR>/references/account-api-component-manager.md`，使用文本搜索定位 `LoginWithHuaweiIDButtonParams`、`Style`、`LoginType`、`textAndIconStyle`、`supportDarkMode`（自定义颜色另检索 `CustomButtonParams`、`ButtonStyle`、`FontColor`、`extraStyle`），只读取匹配片段。只有 API reference 明确支持对应组合时才生成参数。图文混合自定义颜色不支持。只修改 `LoginWithHuaweiIDButton.params`，保留其他参数、`controller`、回调和布局。

#### 3.8 配置用户协议与隐私协议链接

`privacyText` 数组中 `user_agreement` 和 `privacy_policy` 的 `tag` 默认为空，`huaweiId_user_authentication_protocol` 的 `tag` 由 `getProtocolUrl()` 读取无需修改。

1. Prompt 明确给出 URL：校验有效后填入对应 `tag`。
2. Prompt 要求复用工程现有协议：在 `entry/src/main/ets` 和 `entry/src/main/resources` 中搜索协议 URL（关键词：`agreement`、`privacy`、`protocol`、`用户协议`、`隐私`），找到后填入。
3. 未提及且未发现：保留空，在输出中提示需配置。

只修改两项 `tag` 值，不改变数组结构和其他字段。

### Step4：代码审查

逐项检查，不符合时按对应前置步骤修复并回读验证，直到全部通过。无法自行解决的阻塞项才停止。

**检查清单**：
- [ ] `ohos.permission.INTERNET` 已在 `module.json5` 中
- [ ] 复制脚本 `status: copied` 且校验一致
- [ ] Step1 已记录 `bundleName`、`client_id`、签名状态
- [ ] 只选择了一个导航模式，未把 `loadContent()`/`@Entry`/页面注册作为 Router 证据
- [ ] 页面注册和入口跳转符合 Step3.4 对应分支
- [ ] `HuaweiIDLoginPage` 到 `ProtocolWebView` 的 Router 调用未改变，`ProtocolWebView` 保留 `@Entry`
- [ ] `HuaweiIDLoginPage.ets` 只包含允许的修改项
- [ ] 取得非空 `authorizationCode` 后立即提示成功并调用 `getIDInfo()`
- [ ] 按钮参数和图标符合 Prompt
- [ ] `privacyText` 的 `tag` 已按 Step 3.8 配置，`huaweiId_user_authentication_protocol` 保持 `getProtocolUrl()` 不变
- [ ] 按钮在正常布局流中，未使用 `position()`/`offset()`/`translate()`/`alignRules()`
- [ ] 外层 `Column` 模板原容器用 `.layoutWeight(1)` 且未同时保留 `.height('100%')`
- [ ] 有可视化工具时检查默认窗口和较窄窗口，否则报告"未执行可视化布局验证"

### Step5：项目编译

必须使用 `deveco-cli` 的 `build_project` 命令对工程进行编译；如果有编译报错，请使用 `deveco-cli` 的 `check_ets_files` 命令对 ets 文件进行语法检查并修复，修复后仍需使用 `deveco-cli` 的 `build_project` 命令对工程进行编译，直至编译通过，修复过程中如果对鸿蒙相关知识不理解，可以使用 `deveco-cli` 的 `harmonyos_knowledge_search` 命令进行查询

| 命令  | 主要功能  |
|---|---|
|`deveco-cli harmonyos_knowledge_search`|查询鸿蒙云端知识库|
|`deveco-cli check_ets_files`|对ets文件进行语法检查|
|`deveco-cli build_project`|进行项目构建|

---

## 输出模板

`[AI约束]` 为 AI 内部行为约束，不得打印给开发者；其余内容为开发者可见输出。

1. **结论**：接入是否完成；未完成时说明真实阻塞。
2. **入口与导航**：入口页面、按钮标识与选择依据；最终导航模式及证据。Navigation 还需说明根容器、页面映射和 `NavPathStack`。
3. **变更**：新增和修改文件、页面注册、INTERNET 权限、复制脚本结果，以及最终服务端域名、按钮类型与颜色、应用图标、协议链接配置结果。
4. **验证**：Step4 检查结果、防遮挡与可视化情况、`deveco-cli` 版本、语法检查和构建结果；失败时列出错误文件、摘要及已尝试修复。
5. **运行前配置**：
   - **bundleName**：[AI约束] 只使用 Step1 已记录的结果，不得重新推测。输出实际值；未配置时说明前往 AppGallery Connect 查找并配置到 `app.json5`。
   - **client ID**：输出实际值；未配置时说明前往 AppGallery Connect 查找并配置到 `module.json5` 对应 metadata。
   - **签名**：根据 Step1 记录的签名状态输出对应提示（[AI约束] 说明文字与网址分两行，不得合并为链接）：
     - `unconfigured` → "暂未配置签名信息，请参考调试签名的生成过程。" + 换行 + `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-signing`
     - `configured` → "已有签名配置，当发布时需要参考发布应用过程重新配置签名。" + 换行 + `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-publish-app`
     - `unreadable` → "无法完成签名状态检查" + 换行 + `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-signing`
6. **待开发者完成项**：
   - **应用图标**：若使用默认图标，提示可在 `HuaweiIDLoginPage.ets` 中修改 `Image()` 的资源标识。
   - **按钮样式**：如当前使用默认值（纯文本、华为红 `BUTTON_RED`）。
   - **登录后跳转**：本 Skill 不提供登录成功后的路由跳转能力，需自行配置。
   - **用户协议与隐私协议**：[AI约束] 仅当 Step 3.8 未配置时输出此项。模板中协议链接为空，需在 `HuaweiIDLoginPage.ets` 的 `privacyText` 数组中为 `user_agreement` 和 `privacy_policy` 的 `tag` 配置实际协议 URL。
   - **协议名称**：模板中协议名称为占位符 `《XXXX用户协议》《XXXX隐私协议》`，需在 `entry/src/main/resources/zh_CN/element/string.json` 中将 `user_agreement` 和 `privacy_policy` 的 `value` 修改为应用实际名称（如 `《XX商城用户协议》`）。
   - **服务端域名**：[AI约束] 仅当 Prompt 未指定服务端域名时输出此项。当前使用默认值 `http://localhost:8080`，可在 `HuaweiIDLoginPage.ets` 中修改 `SERVICE_DOMAIN` 为实际服务端地址。
   - **服务端接口**：需继续完成服务端接口及 Open ID、Union ID 的业务处理。
   - **一键登录并存**：[AI约束] 仅当 Step1 检测到已接入一键登录且开发者选择继续接入时输出此项。当前工程已接入华为账号一键登录，两种登录方式并存。一键登录按钮和华为账号登录按钮是两个独立按钮，建议开发者完成后续业务衔接：
    1. 用户标识统一：两种登录方式均可获取 `UnionID` 和 `OpenID`，推荐使用 `UnionID` 作为用户唯一标识，确保两种登录方式识别为同一用户。一键登录额外获取手机号，需将手机号与 `UnionID` 关联存储。
    2. 服务端接口区分：一键登录的授权码需调用 `/oauth2/v6/quickLogin/getPhoneNumber` 获取手机号和 `UnionID`/`OpenID`；华为账号登录的授权码需调用 `/oauth2/v6/token` 换取 `access_token` 后获取 `UnionID`/`OpenID`。两个接口路径和返回数据不同，需分别实现。
    3. 登录态同步：监听华为账号登录/登出事件，任一登录方式成功后统一更新应用登录状态，登出时清除所有登录态并跳转到登录页面。
    4. 协议状态管理：两种登录方式均需用户同意协议，但协议状态独立管理，需分别设置 `AgreementStatus`。