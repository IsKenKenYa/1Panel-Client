---
name: hmos-account-kit-login-api-client
description: 基于 HarmonyOS Account Kit 提供华为自定义按钮登录客户端接入指引。提供自定义登录按钮（纯图标/纯文本/图文三种模式）、Authorization Code 获取及 Union ID 服务端请求框架。**当用户需要在现有登录页嵌入华为登录自定义按钮（非标准按钮，需自定义按钮外观）时使用。**
license: MIT
metadata:
  author: Huawei Account Kit Team
  version: "1.0.0"
---

## Skill 选择指南

| 开发场景 | 一键登录 | 按钮登录 | 自定义按钮登录（当前Skill） |
|---|---|---|---|
| **Skill** | `hmos-account-kit-quicklogin-client` | `hmos-account-kit-login-button-client` | `hmos-account-kit-login-api-client` |
| 需要获取用户手机号 | ✅ | ❌ | ❌ |
| 使用华为标准按钮（仅可选模式和配色） | ✅ | ✅ | ❌ |
| 需要在现有登录页嵌入华为登录按钮 | ❌ | ❌ | ✅|
| 需要自定义按钮外观（符合华为 UX 规范） | ❌ | ❌ | ✅ |
| **支持的开发者类型** | 企业开发者 | 企业开发者、个人开发者 | 企业开发者、个人开发者 |

# 华为 Account Kit 自定义按钮登录·客户端开发助手

## 全局规范

1. **任务边界**：首次接入"华为账号登录"自定义按钮。工程已存在可执行的"华为账号登录"或自定义按钮登录实现时不适用；检测到已接入华为账号一键登录时，停止并提供选择分支（推荐停止接入，或继续接入并自行处理业务衔接）；预取号、匿名手机号和元服务不适用；服务端接口实现、登录后业务跳转、应用登录状态管理和退出账号不适用；无关的 UI 重做、导航改造或工程重构不适用。
2. **UX设计原则**：按 Prompt 或工程结构确定新增按钮的位置。复制固定组件和两个华为标志 SVG，新增纯图标、纯文本或图标和文本按钮。
3. **任务边界约束**：调用 Account Kit 登录 API；取得非空 `authorizationCode` 即表示客户端登录成功。应用服务端的部署与实际响应不在本 Skill 职责范围内。
4. **交付检查与编译报错处理（重要）**：交付前，务必使用 `deveco-cli` 的 `build_project` 命令对工程进行编译；如果有编译报错，请使用 `deveco-cli` 的 `check_ets_files` 命令对ets文件进行语法检查并修复，直至编译通过；
5. **需求确认**：当用户仅提及"自定义按钮登录"而未提供具体接入需求时，**停止执行**，简要介绍本 Skill 功能，并请用户确认或补充需求后再继续。

## 决策树

本 Skill 涉及多个分支判断，以下决策树系统化各判断逻辑。执行时按顺序自上而下匹配，命中即停止。

### 工程类型判断

```
读取 AppScope/app.json5 的 bundleType
├── atomicService（元服务）
│   └── → 元服务不适用，停止执行
└── 其他（普通应用）
    └── → 继续后续判断
```

### 已有登录实现检测

```
在 entry/src/main/ets 中搜索华为账号登录关键词
├── 发现可执行的"华为账号登录"或自定义按钮登录实现
│   └── → 已接入，停止执行
├── 检测到已接入华为账号一键登录
│   └── → 停止执行，向开发者提供选择
│         ├── (1) 停止接入（推荐）→ 终止，不再执行后续步骤
│         └── (2) 继续接入 → 继续执行，自定义按钮放置在一键登录按钮下方
│                          输出阶段列出四项业务衔接建议
├── 仅出现注释、资源、按钮文字或未连接样例
│   └── → 不能据此判定已接入，继续核实
└── 未发现任何登录实现
    └── → 继续正常流程
```

### UX 规范违规判定

```
检查用户 Prompt 是否违反华为账号登录 UX 不可自定义项
├── 违反任意一条（文字内容/居中/颜色/标志/宽高比/按钮顺序）
│   └── → 立即停止执行，输出违规项和原因，提示重新输入
└── 全部合规
    └── → 继续确定按钮位置、模式和样式
```

### 按钮模式与配色选择

```
Prompt 指定的按钮模式？
├── 纯图标/仅图标 → ICON_ONLY
│   └── colorStyle 从固定选项中选择（RED/WHITE/WHITE_BORDERED/GRAY/BLACK）
│       └── 配色对比度检查：页面背景为白色或浅色时避免 WHITE，改用 RED/BLACK/WHITE_BORDERED
├── 纯文本/仅文字 → TEXT_ONLY
│   └── 使用 textOnlyBackgroundColor + textOnlyFontColor，不传 colorStyle
│       └── 配色对比度检查：确保与页面背景有足够对比度
├── 图标和文本/图文混合 → ICON_TEXT
│   └── colorStyle 从固定选项中选择
│       └── 配色对比度检查：同 ICON_ONLY
└── 未指定 → TEXT_ONLY（默认）
    └── 默认华为红背景 + 白色文字
```

### 按钮位置确定

```
Prompt 是否明确指定位置（页面路径/组件名/id/相对位置）？
├── 是 → 读取对应代码确认锚点
│       ├── 锚点存在且唯一 → 在锚点之前插入
│       ├── 锚点不存在 → 请开发者确认
│       └── 匹配不唯一 → 请开发者确认
└── 否 → 按优先级选择
         ├── 已有登录区域 → 个人中心/我的/账号页面 → loadContent() 启动页 → Index.ets → 唯一 @Entry 页面
         └── 记录选择依据
```

---

## 文件资源

三个登录资源直接位于 `assets/`，不使用子目录：

```text
assets/
├── HuaweiIDCustomLoginButton.ets
├── huaweilogo_red_black.svg
└── huaweilogo_white.svg
```

- `HuaweiIDCustomLoginButton.ets`：三种按钮 UI、登录请求和应用服务端请求框架。
- `huaweilogo_red_black.svg`：红色标志和黑色 HUAWEI 字样，适合白色或浅色背景。
- `huaweilogo_white.svg`：白色标志，适合华为红、黑色或其他深色背景。

**三个固定资源只能通过 `scripts/copy-huawei-id-custom-login.mjs` 写入目标工程；目标冲突、复制失败或校验失败时停止。**

---

## 执行流程

### Step1：工程感知

读取 `AppScope/app.json5`、`entry/src/main/module.json5` 和 `entry/src/main/ets`，不扫描构建产物与依赖目录。在 ets 中搜索：

- `HuaweiIDProvider`
- `createLoginWithHuaweiIDRequest`
- `AuthenticationController`
- `LoginWithHuaweiIDButton`
- `authorizationCode`

读取匹配代码后，按「决策树 - 工程类型判断」和「决策树 - 已有登录实现检测」执行判定。

检测到已接入华为账号一键登录且开发者选择继续接入时，需自行处理以下业务衔接：
1. **用户标识统一**：两种登录方式均可获取 `UnionID` 和 `OpenID`，推荐使用 `UnionID` 作为用户唯一标识，确保两种登录方式识别为同一用户。一键登录额外获取手机号，需将手机号与 `UnionID` 关联存储。
2. **服务端接口区分**：一键登录的授权码需调用 `/oauth2/v6/quickLogin/getPhoneNumber` 获取手机号和 `UnionID`/`OpenID`；自定义按钮获取的授权码同样需由服务端换取 `UnionID`/`OpenID`，但获取的是 Authorization Code 而非一键登录的专用凭证，服务端换取流程不同，需分别实现。
3. **登录态同步**：监听华为账号登录/登出事件，任一登录方式成功后统一更新应用登录状态，登出时清除所有登录态并跳转到登录页面。
4. **协议同意处理**：一键登录通过 `LoginWithHuaweiIDButtonController.setAgreementStatus` 管理协议状态；自定义按钮不经过 `LoginWithHuaweiIDButton`，需开发者在自定义 UI 中自行实现协议勾选和同意逻辑，两种方式的协议处理机制独立。

修改工程前，必须读取并记录以下配置状态；这些检查不影响 Skill 继续执行：

1. 读取 `AppScope/app.json5`，记录 `bundleName` 的实际值或"未配置"。
2. 读取 `entry/src/main/module.json5`，记录 `client_id` 的实际值或"未配置"。
3. 定位同时包含 `AppScope/` 和 `entry/` 的项目根目录，使用文件读取工具直接读取根目录下的 `build-profile.json5`。可用 `rg`、`grep` 或 `Select-String` 定位 `signingConfigs`，但必须继续读取完整的 `app.signingConfigs` 数组。记录检查使用的准确文件路径；不得读取模块级 `build-profile.json5`、构建产物或其他同名文件。
4. 按完整数组记录签名状态：
   - `configured`：`app.signingConfigs` 数组非空。
   - `unconfigured`：字段不存在或数组为空。
   - `unreadable`：项目根目录或工程级 `build-profile.json5` 无法读取。

### Step2：确定 UX 规范

#### 2.1 UX 规范检查

判定逻辑见「决策树 - UX 规范违规判定」。

| 检查项 | 规范要求 | 常见违规示例 |
|---|---|---|
| 文字内容 | "华为账号登录"需清晰呈现，不可更改 | "改为华为登录"、"文字改为登录" |
| 文字/内容居中 | 文字、标志和文字内容组、标志分别整体居中 | "文字靠左"、"Logo 右对齐" |
| 按钮颜色 | 只能使用固定颜色组合（RED/WHITE/WHITE_BORDERED/GRAY/BLACK） | "用黄色按钮"、"背景改为蓝色" |
| 标志使用 | 不得单独使用、不得裁剪、不得添加垂直内边距 | "去掉按钮背景只留 Logo"、"裁剪 Logo" |
| ICON_ONLY 宽高比 | 固定 1:1 | "图标按钮宽 60vp 高 40vp" |
| 按钮顺序 | 必须位于同一登录区域内其他登录按钮之前 | "放在微信登录后面" |

参考：[华为账号开放登录体验设计规范](https://developer.huawei.com/consumer/cn/doc/design-guides/id-0000001880001344)

#### 2.2 按钮位置

**核心约束：** 始终新增 `HuaweiIDCustomLoginButton`，不替换或复用现有组件。按钮必须位于同一登录区域内其他登录按钮之前：`ICON_ONLY` 水平排列位于最左侧，`TEXT_ONLY`/`ICON_TEXT` 垂直排列位于最上方。

位置判定的分支逻辑见「决策树 - 按钮位置确定」。

**一键登录按钮并存**：Step1 检测到已接入华为账号一键登录且开发者选择继续接入时，直接将华为账号登录自定义按钮放置在已有一键登录按钮**下方**，复用同一页面和布局容器，保持与一键登录按钮一致的间距和宽度风格。

确定位置后立即锁定插入文件：`<PROJECT_ROOT>`（工程绝对路径）、`<INSERT_FILE>`（ETS 文件绝对路径）、`<INSERT_FILE_RELATIVE>`（相对路径）。确认文件位于 `entry/src/main/ets` 下且包含锚点及父容器，此后只修改该文件。

#### 2.3 模式与配色

模式与配色的分支逻辑见「决策树 - 按钮模式与配色选择」。

未指定颜色时使用华为红背景：文本为白色，含图标模式使用 `huaweilogo_white`。

含图标模式（`ICON_TEXT` 和 `ICON_ONLY`）只能完整使用以下 `colorStyle`，不得单独覆盖背景、文字、Loading、Logo 或描边：

**配色对比度检查：** 选定 `colorStyle` 前必须读取页面背景色，确保按钮与背景有足够对比度。页面背景为白色或浅色时，避免使用 `WHITE`（白色背景无描边），改用 `RED`、`BLACK` 或 `WHITE_BORDERED`（带描边）。

| `colorStyle`     | 背景        | 文字/Loading | Logo                       | 描边            |
| ---------------- | --------- | ---------- | -------------------------- | ------------- |
| `RED`            | `#CE0E2D` | 白色         | `huaweilogo_white.svg`     | 无             |
| `WHITE`          | 白色        | 黑色         | `huaweilogo_red_black.svg` | 无             |
| `WHITE_BORDERED` | 白色        | 黑色         | `huaweilogo_red_black.svg` | `#F2F2F2`、1vp |
| `GRAY`           | `#F2F2F2` | 黑色         | `huaweilogo_red_black.svg` | 无             |
| `BLACK`          | 黑色        | 白色         | `huaweilogo_white.svg`     | 无             |

`TEXT_ONLY` 不传 `colorStyle`，只使用 `textOnlyBackgroundColor` 和 `textOnlyFontColor`，并保证与页面背景有足够对比度。

#### 2.4 样式参数

组件调用必须来自固定模板，只调整 Prompt 指定且 UX 规范允许的参数。页面左右安全边距由登录区域容器统一承担，不得因修改按钮参数而删除或重复添加。当 Prompt 要求参照现有按钮样式时，只参照尺寸、圆角、间距等可定制项；`colorStyle` 必须独立从 2.3 节固定选项中选择并确保对比度，不得照搬第三方配色。

可配置参数（按顺序记录，不添加当前模式不使用的参数）：

| 顺序 | 参数 | 适用模式 |
|---|---|---|
| 1 | `mode`、`colorStyle` | `colorStyle` 仅含图标模式 |
| 2 | `buttonWidth`、`buttonHeight`、`borderRadiusValue` | `buttonWidth` 仅 `TEXT_ONLY`/`ICON_TEXT` |
| 3 | `textFontSize`、`textOnlyFontWeight`、`textOnlyFontFamily`、`textOnlyBackgroundColor`、`textOnlyFontColor` | `textOnly*` 仅 `TEXT_ONLY` |
| 4 | `iconTextSpace`、`iconOnlyLogoScale` | 分别仅 `ICON_TEXT`/`ICON_ONLY` |

**共同规则：** 按钮高度 28–60vp；页面左右安全边距不小于 16vp；边距优先级：开发者指定值 → 其他登录按钮的合规边距 → 默认 16vp；圆角只使用 `buttonHeight/2`（全圆角）、`buttonHeight/4`（半圆角）或 `0`（直角）。

三种模式：

- `TEXT_ONLY`：宽度不小于 150vp，字号为高度的 30%–50%（取整 12–30fp），只通过 `textOnly*` 参数定制。
- `ICON_TEXT`：宽度不小于 150vp，字号规则同纯文本，字重固定 `FontWeight.Medium`，Logo 为字号 1.5 倍，`iconTextSpace` 4–16vp。
- `ICON_ONLY`：宽高等比 1:1，`iconOnlyLogoScale` 40%–64%（Logo 不小于 16vp），Logo 居中无垂直内边距，保留"华为账号登录"访问性语义。

### Step3：功能开发

#### 3.1 配置 INTERNET 权限

在 `entry/src/main/module.json5` 的 `module.requestPermissions` 中补充并去重：

```json
{ "name": "ohos.permission.INTERNET" }
```

保留其他权限；写入后重新读取确认。

#### 3.2 复制固定资源

将 `<SKILL_DIR>` 解析为本 `SKILL.md` 所在目录，沿用 2.2 节记录的 `<PROJECT_ROOT>`。

```bash
node "<SKILL_DIR>/scripts/copy-huawei-id-custom-login.mjs" \
  --project "<PROJECT_ROOT>" --dry-run
```

仅当输出 `status: ready` 时执行：

```bash
node "<SKILL_DIR>/scripts/copy-huawei-id-custom-login.mjs" \
  --project "<PROJECT_ROOT>"
```

脚本将组件复制到 `entry/src/main/ets/HuaweiIDCustomLogin/`，将两个 SVG 复制到 `entry/src/main/resources/base/media/`。只有 `status: copied`、`verifiedFiles === plannedFiles === 3` 且 `failedFiles` 为空时继续。

#### 3.3 新增组件

**导入与相对路径：**

使用 2.2 节锁定的文件先确定：

```text
<INSERT_DIR> = <INSERT_FILE> 的父目录
<COMPONENT_FILE> = <PROJECT_ROOT>/entry/src/main/ets/HuaweiIDCustomLogin/HuaweiIDCustomLoginButton.ets
<IMPORT_PATH> = 从 <INSERT_DIR> 到 <COMPONENT_FILE> 的相对路径
```

将 `<IMPORT_PATH>` 的分隔符统一为 `/`，去掉 `.ets`；路径不以 `.` 开头时补 `./`。不得从工程根目录、页面路由或组件名计算。写入后从 `<INSERT_DIR>` 反向解析 import，必须精确命中 `<COMPONENT_FILE>`；否则停止并修正路径。

```ArkTS
import {
  HuaweiIDButtonColorStyle,
  HuaweiIDButtonMode,
  HuaweiIDCustomLoginButton
} from '<IMPORT_PATH>';
```

**固定按钮调用模板：**

直接复制对应模板，只使用 2.4 节确认的最终参数替换模板值，并保持可配置参数与顺序表的参数顺序。不自行重写调用。模板只包含按钮参数，不包含页面安全边距；完整插入必须继续执行容器排列部分。修改按钮参数时不得删除容器排列部分确定的容器水平 `padding`。

纯文本：

```ArkTS
HuaweiIDCustomLoginButton({
  mode: HuaweiIDButtonMode.TEXT_ONLY,
  buttonWidth: '100%',
  buttonHeight: 40,
  borderRadiusValue: 20,
  textFontSize: 16,
  textOnlyFontWeight: FontWeight.Medium,
  textOnlyFontFamily: 'sans-serif',
  textOnlyBackgroundColor: '#CE0E2D',
  textOnlyFontColor: Color.White
})
```

图标和文本：

```ArkTS
HuaweiIDCustomLoginButton({
  mode: HuaweiIDButtonMode.ICON_TEXT,
  colorStyle: HuaweiIDButtonColorStyle.RED,
  buttonWidth: '100%',
  buttonHeight: 40,
  borderRadiusValue: 20,
  textFontSize: 16,
  iconTextSpace: 8
})
```

纯图标：

```ArkTS
HuaweiIDCustomLoginButton({
  mode: HuaweiIDButtonMode.ICON_ONLY,
  colorStyle: HuaweiIDButtonColorStyle.WHITE,
  buttonHeight: 40,
  borderRadiusValue: 20,
  iconOnlyLogoScale: 0.5
})
```

**容器排列与页面边距：**

插入前读取父容器及相邻组件。优先使用正常布局流，不使用 `position`、`offset` 或 `translate` 排开组件。页面左右安全边距只由最近的登录区域容器通过水平 `padding` 提供一次，按钮调用不添加水平 `margin`。以下示例使用默认 16vp；已有容器提供合规边距时直接复用。

| 按钮模式 | 排列方式 |
|---|---|
| `TEXT_ONLY`/`ICON_TEXT` | 与其他登录按钮垂直排列，放在最前面 |
| `ICON_ONLY` | 与其他图标登录入口水平排列，放在最前面 |

`Column`（`TEXT_ONLY`/`ICON_TEXT`）和 `Row`（`ICON_ONLY`）是两种基本排列方式，其余容器类型（`Stack`/`Scroll`/`List`/`RelativeContainer`）在此基础上适配：

```ArkTS
// TEXT_ONLY / ICON_TEXT
Column({ space: 12 }) {
  HuaweiIDCustomLoginButton({ /* 固定按钮调用模板完整参数 */ })
  OtherLoginButton()
}
.width('100%')
.padding({ left: 16, right: 16 })
```

```ArkTS
// ICON_ONLY
Row({ space: 12 }) {
  HuaweiIDCustomLoginButton({ /* 固定按钮调用模板纯图标完整参数 */ })
  OtherIconLoginButton()
}
.width('100%')
.padding({ left: 16, right: 16 })
```

`Stack`/`Scroll`：将上述 `Column` 或 `Row` 作为内容层，保留背景层，不在内容之上增加第二层。

`List`：`TEXT_ONLY`/`ICON_TEXT` 放入独立 `ListItem` 并排在其他登录项之前；`ICON_ONLY` 插入同一 `ListItem` 内的 `Row` 首位。

`RelativeContainer`：为新增分组和锚点设置唯一 `id`，使用 `alignRules` 定位。**`center` 是垂直键必须搭配 `VerticalAlign`，`middle` 是水平键必须搭配 `HorizontalAlign`，严禁混用。**

```ArkTS
RelativeContainer() {
  PositionAnchorComponent()
    .id('positionAnchor')
  Column() {
    HuaweiIDCustomLoginButton({ /* 固定按钮调用模板完整参数 */ })
  }
  .id('huaweiLoginArea')
  .padding({ left: 16, right: 16, top: 12 })
  .alignRules({
    left: { anchor: '__container__', align: HorizontalAlign.Start },
    right: { anchor: '__container__', align: HorizontalAlign.End },
    top: { anchor: 'positionAnchor', align: VerticalAlign.Bottom }
  })
}
```

保留锚点的 UI、`id`、`onClick` 和 `alignRules`。确认没有重叠、越界或裁剪。只修改目标工程中的组件调用，不修改 Skill 内固定模板。

#### 3.4 配置服务端接口框架

Prompt 未提供时保留：

- `SERVICE_DOMAIN = 'http://localhost:8080'`
- `GET_ID_INFO_PATH = '/huawei/Login/getIDInfo'`

Prompt 提供时，只修改项目副本中的这两个常量。`SERVICE_DOMAIN` 只填写服务端基础地址，例如 `https://api.example.com:8443`，不要包含接口路径；`GET_ID_INFO_PATH` 单独填写接口路径并以 `/` 开头。最终请求地址由两者拼接。

### Step4：代码审查

任一项不符合时，必须根据对应章节重新配置并修复，重复"检查—修复—复检"直到全部通过。无法修复时停止并说明未通过项，不得进入 Step5 或声明验证通过。

**检查清单**：
- [ ] 三个目标文件存在且与复制凭据一致，两个 `$r('app.media...')` 均可解析
- [ ] 页面新增且仅新增一个登录组件，位于同一区域其他登录按钮之前，位置锚点及其点击逻辑未改变
- [ ] 页面左右安全边距不小于 16vp，只由一个登录区域容器承担，按钮调用没有水平 `margin`，父子容器没有重复叠加边距
- [ ] `TEXT_ONLY`/`ICON_TEXT` 纵向排列、`ICON_ONLY` 横向排列，按钮与相邻组件无重叠、越界或裁剪
- [ ] `alignRules` 水平键搭配 `HorizontalAlign`、垂直键搭配 `VerticalAlign`，不得将 `center` 与 `HorizontalAlign` 搭配
- [ ] import 从 `<INSERT_FILE>` 父目录解析后精确命中固定组件，调用符合模板且无当前模式不使用的参数
- [ ] 模式、配色符合 2.3 节，按钮与页面背景有足够对比度，圆角只使用 `buttonHeight/2`、`buttonHeight/4` 或 `0`
- [ ] INTERNET 权限存在且无重复，登录请求、成功判定和服务端请求框架完整

### Step5：项目编译

必须使用 `deveco-cli` 的 `build_project` 命令对工程进行编译；如果有编译报错，请使用 `deveco-cli` 的 `check_ets_files` 命令对 ets 文件进行语法检查并修复，修复后仍需使用 `deveco-cli` 的 `build_project` 命令对工程进行编译，直至编译通过，修复过程中如果对鸿蒙相关知识不理解，可以使用 `deveco-cli` 的 `harmonyos_knowledge_search` 命令进行查询。只有编译无 error 且构建成功，才能声明整体验证通过；命令失败或未执行时必须如实说明。

| 命令  | 主要功能  |
|---|---|
|`deveco-cli harmonyos_knowledge_search`|查询鸿蒙云端知识库|
|`deveco-cli check_ets_files`|对ets文件进行语法检查|
|`deveco-cli build_project`|进行项目构建|

---

## 输出模板

> `[AI约束]` 为 AI 内部行为约束，不得打印给开发者；其余内容为开发者可见输出。

1. 接入是否完成。
2. `<INSERT_FILE_RELATIVE>`、位置依据和按钮模式。
3. 新增/修改文件、最终服务端配置、按钮样式，以及页面左右边距的数值、来源和承担容器。
4. 代码审查、项目编译结果。
5. **运行前配置**：`[AI约束]` 只使用 Step1 记录的结果，不得重新推测；不得自行生成或替换 `bundleName`、`client ID`、签名配置、服务端接口实现和响应处理逻辑。
   - 输出实际 `bundleName`、`client ID`、签名状态及签名检查文件路径。
   - **未配置项引导**：`bundleName` 或 `client ID` 未配置时，说明可前往 AppGallery Connect 的"开发与服务"，选择对应项目和应用，在"项目设置 > 常规 > 应用"中查找并配置。
   - **签名状态说明**：`[AI约束]` 说明文字和网址分两行输出，不得使用 Markdown 链接或输出签名密码。

     | 签名状态 | 说明文字 | 网址 |
     |---|---|---|
     | `unconfigured` | 暂未配置签名信息，请参考调试签名的生成过程。 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-signing |
     | `configured` | 已有签名配置，当发布时需要参考发布应用过程重新配置签名。 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-publish-app |
     | `unreadable` | 无法完成签名状态检查 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-signing |

   - 提醒开发者继续完成服务端接口及 Open ID、Union ID 的业务处理。
   - **一键登录并存**：[AI约束] 仅当 Step1 检测到已接入一键登录且开发者选择继续接入时输出此项。当前工程已接入华为账号一键登录，两种登录方式并存。一键登录按钮（`LoginWithHuaweiIDButton`）和自定义按钮（`HuaweiIDCustomLoginButton`）是两个独立按钮，开发者需完成以下业务衔接：
     1. 使用 `UnionID` 作为统一用户标识，一键登录的手机号与 `UnionID` 关联存储
     2. 服务端分别实现一键登录（`/oauth2/v6/quickLogin/getPhoneNumber`）和自定义按钮 Authorization Code 的换取接口，两者获取的凭证类型和服务端换取流程不同
     3. 监听华为账号登录/登出事件，任一方式成功后统一更新登录态
     4. 一键登录通过 `setAgreementStatus` 管理协议状态，自定义按钮需开发者自行实现协议同意逻辑，两种方式独立处理
6. **UX 规范违规**（仅当 2.1 检查到违规时输出，此时不输出 1-5 项）：
   - 逐项列出违规信息，格式如下：
     - 违规项：XXX
     - 规范要求：XXX
     - Prompt 中的原始描述：XXX
   - 输出完成后提示："请修改 Prompt 后重新执行。"

---