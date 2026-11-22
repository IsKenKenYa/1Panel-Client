---
name: hmos-one-sdk-skill
description: ⚠️ MUST LOAD before writing first .ets file that imports from @kit.*. This skill provides verified API signatures, import paths, error codes, permission requirements, and example code for 25 Kits (AccountKit, MediaKit, NetworkKit, ScanKit, LocationKit, PushKit etc.). Even if you have partial API info from other sources, this skill covers complete error codes and permission requirements they lack. Load when — (1) writing ANY @kit.* import; (2) calling Kit APIs like vibrator, Bluetooth, location, scan, account, push, network, health, wear, map, IAP, accessibility, i18n, form, widget, card, cross-device collaboration; (3) @kit.* compile errors (wrong namespace, missing exported member, type mismatch) — load BEFORE attempting fixes;
---


# HarmonyOS SDK Documentation Skill

This skill manages the retrieval and routing of HarmonyOS development documentation. Documents are stored locally in a Kit-level hierarchy, with each Kit directory containing multiple functional skills (SUB_SKILL.md) along with official reference documents, test cases, and example code.

Why this skill is needed: HarmonyOS documentation is distributed across 25 Kit directories, each with multiple functional modules. Direct search is highly inefficient; you need to quickly locate the correct Kit and functional directory based on the user's needs, then use BM25 retrieval for precise matching.

## Document Repository Structure

All documents are located under the `hmos-sdk-basic-skill/` directory, with 339 skill definition files (SUB_SKILL.md / SKILL.md) organized by 25 Kits:

| Kit | 目录 | 功能领域 |
|-----|------|---------|
| Accessibility Kit（无障碍服务） | `hmos-sdk-basic-skill/Accessibility Kit(无障碍服务)/` | 应用框架 |
| Account Kit（华为账号服务） | `hmos-sdk-basic-skill/Account Kit(华为账号服务)/` | 应用服务 |
| AppGallery Kit（应用市场服务） | `hmos-sdk-basic-skill/AppGallery Kit(应用市场服务)/` | 应用服务 |
| Call Service Kit（通话服务） | `hmos-sdk-basic-skill/Call Service Kit(通话服务)/` | 网络通信 |
| Connectivity Kit（短距通信服务） | `hmos-sdk-basic-skill/Connectivity Kit(短距通信服务)/` | 网络通信 |
| Device Security Kit（设备安全服务） | `hmos-sdk-basic-skill/Device Security Kit(设备安全服务)/` | 安全认证 |
| Form Kit（卡片开发服务） | `hmos-sdk-basic-skill/Form Kit(卡片开发服务)/` | 应用框架 |
| Health Service Kit（运动健康服务） | `hmos-sdk-basic-skill/Health Service Kit(运动健康服务)/` | 设备硬件 |
| IAP Kit（应用内支付服务） | `hmos-sdk-basic-skill/IAP Kit(应用内支付服务)/` | 应用服务 |
| Live View Kit（实况窗服务） | `hmos-sdk-basic-skill/Live View Kit(实况窗服务)/` | 应用服务 |
| Localization Kit（本地化开发服务） | `hmos-sdk-basic-skill/Localization Kit(本地化开发服务)/` | 应用框架 |
| Location Kit（位置服务） | `hmos-sdk-basic-skill/Location Kit(位置服务)/` | 位置与地图 |
| Map Kit（地图服务） | `hmos-sdk-basic-skill/Map Kit(地图服务)/` | 位置与地图 |
| Multimodal Awareness Kit（多模态融合感知服务） | `hmos-sdk-basic-skill/Multimodal Awareness Kit(多模态融合感知服务)/` | AI 能力 |
| Network Boost Kit（网络加速服务） | `hmos-sdk-basic-skill/Network Boost Kit(网络加速服务)/` | 网络通信 |
| Network Kit（网络服务） | `hmos-sdk-basic-skill/Network Kit(网络服务)/` | 网络通信 |
| Online Authentication Kit（在线认证服务） | `hmos-sdk-basic-skill/Online Authentication Kit(在线认证服务)/` | 安全认证 |
| Performance Analysis Kit（性能分析服务） | `hmos-sdk-basic-skill/Performance Analysis Kit(性能分析服务)/` | 系统调优 |
| Push Kit（推送服务） | `hmos-sdk-basic-skill/Push Kit(推送服务)/` | 应用服务 |
| Remote Communication Kit（远场通信服务） | `hmos-sdk-basic-skill/Remote Communication Kit(远场通信服务)/` | 网络通信 |
| Scan Kit（统一扫码服务） | `hmos-sdk-basic-skill/Scan Kit(统一扫码服务)/` | 媒体 |
| Service Collaboration Kit（协同服务） | `hmos-sdk-basic-skill/Service Collaboration Kit(协同服务)/` | 应用服务 |
| Share Kit（分享服务） | `hmos-sdk-basic-skill/Share Kit(分享服务)/` | 应用服务 |
| UI Design Kit（UI设计套件） | `hmos-sdk-basic-skill/UI Design Kit(UI设计套件)/` | UI 设计 |
| Wear Engine Kit（穿戴服务） | `hmos-sdk-basic-skill/Wear Engine Kit(穿戴服务)/` | 设备硬件 |

The structure within each Kit directory is:
```
{Kit名}/
├── {功能分类}/
│   └── {功能子类}/
│       ├── SUB_SKILL.md          # Skill definition (with name/description frontmatter)
│       ├── references/           # Official HarmonyOS documentation (.md)
│       ├── tests/                # Test cases (.ets/.py/.ts)
│       └── assets/               # Example code (.ets/.cpp/.json5)
```


## Retrieval Workflow

Retrieve documents based on user needs, following this priority order:

### Step 1: Determine the Request Type

| User Intent | Retrieval Strategy |
|---------|---------|
| "XXX API", "XXX 接口", "XXX 方法" | BM25 retrieval (exact keyword) |
| "怎么做XXX", "如何实现XXX" | BM25 retrieval + consult kit-routing.md |
| "XXX 报错", "XXX 不工作" | BM25 retrieval + read SUB_SKILL.md error code descriptions |
| Mentions a Kit name | Consult `hmos-sdk-basic-skill/kit-routing.md` to locate the Kit directory |
| Unsure | Use `node scripts/search.js "<关键词>"` for full BM25 retrieval |

### Step 2: Locate the Kit Directory

There are two ways to locate a Kit:

**Method A: User mentions a Kit name** — Consult `hmos-sdk-basic-skill/kit-routing.md`, which contains the complete routing mapping and functional module paths for all 25 Kits.

Quick routing for common Kits (no need to consult the reference file):

| Kit | 路径 |
|-----|------|
| Account Kit | `hmos-sdk-basic-skill/Account Kit(华为账号服务)/` |
| Push Kit | `hmos-sdk-basic-skill/Push Kit(推送服务)/` |
| Scan Kit | `hmos-sdk-basic-skill/Scan Kit(统一扫码服务)/` |
| Network Kit | `hmos-sdk-basic-skill/Network Kit(网络服务)/` |
| Connectivity Kit | `hmos-sdk-basic-skill/Connectivity Kit(短距通信服务)/` |
| Map Kit | `hmos-sdk-basic-skill/Map Kit(地图服务)/` |
| IAP Kit | `hmos-sdk-basic-skill/IAP Kit(应用内支付服务)/` |
| Wear Engine Kit | `hmos-sdk-basic-skill/Wear Engine Kit(穿戴服务)/` |
| Accessibility Kit | `hmos-sdk-basic-skill/Accessibility Kit(无障碍服务)/` |
| Localization Kit | `hmos-sdk-basic-skill/Localization Kit(本地化开发服务)/` |
| Form Kit | `hmos-sdk-basic-skill/Form Kit(卡片开发服务)/` |

For more Kits (Location Kit, Share Kit, Device Security Kit, etc.), see `hmos-sdk-basic-skill/kit-routing.md`.

**Method B: User only describes functional requirements** — Consult the "功能路由速查" table at the bottom of `hmos-sdk-basic-skill/kit-routing.md`, which routes from "what the user wants to do" to the corresponding Kit. For example, if the user says "我想实现扫码", find the Scan Kit path in the lookup table.

### Step 3: Retrieve and Read

> **CRITICAL — Pre-search Kit verification**: Before running `search.ts`, you MUST verify that the user's query relates to one of the 25 supported Kits listed in the table above (lines 17-43). If the user mentions a Kit name that is NOT in that table, DO NOT run the search — it will return irrelevant noise results. Instead, inform the user that this Kit is not in the current documentation corpus and suggest checking the supported Kit list.

**Verification rules**:

1. **User mentions a Kit name** (e.g., "SpeechKit", "AudioKit", "MediaKit") → Check the Kit table (lines 17-43). If the Kit is NOT listed, stop and inform the user. Do NOT search.
2. **User mentions an API/class name** (e.g., "AICaptionController", "PhotoViewPicker") → You may run the search, but if the results are irrelevant or scores are low, inform the user that this API may not have dedicated documentation in the corpus.
3. **User describes a feature/need** (e.g., "怎么扫码", "蓝牙连接") → Proceed with search, the BM25 retrieval will find relevant docs.

**Precedence**: Rule 1 takes precedence over rule 2. If an API/class name can be attributed to a Kit that is NOT in the 25-Kit table (e.g., `AICaptionController` → SpeechKit, `AudioRenderer` → AudioKit), treat it per rule 1 — stop and inform the user, do NOT search. Rule 2 only applies when you cannot determine which Kit the API belongs to.

**Examples**:
- ✅ "Account Kit 一键登录" → Account Kit is in the 25 Kits → proceed to search
- ✅ "蓝牙扫描" → describes a feature → proceed to search
- ❌ "SpeechKit 字幕" → SpeechKit is NOT in the 25 Kits → **do NOT search**, inform user
- ❌ "AICaptionController" → not a known Kit API → search may return noise, inform user if results are irrelevant

Use the built-in **BM25 retrieval tool** to precisely locate the Top N most relevant documents across all skill definition files (339), then read the full text to provide a comprehensive answer.

#### Tool Locations

- BM25 index builder: [scripts/build_index.js](scripts/build_index.js)
- BM25 retrieval entry point: [scripts/search.js](scripts/search.js)
- Index artifacts: `scripts/index/` (contains docs.json.gz, inverted.json.gz, meta.json)

#### Retrieval Commands

```bash
# Keyword retrieval (recommended)
node scripts/search.js "蓝牙连接" --category "Connectivity Kit" --top 8 --snippet

# Filter by Kit category (supports full name/English short name/Chinese)
node scripts/search.js "AAID" --category "push" --top 5
node scripts/search.js "Token" --category "Push Kit" --top 5
node scripts/search.js "推送" --category "推送服务" --top 5

# Exact API name/class name matching
node scripts/search.js "liveViewManager startLiveView" --category "Live View Kit"  --top 5 --snippet


# Machine-readable JSON output
node scripts/search.js "自定义界面扫码" --category "Scan Kit" --top 5 --json

# Without --category (only if you don't know which Kit — strongly recommended to include it)
node scripts/search.js "启动WiFi扫描" --top 5 --json
```

> **First run**: If the index does not exist, `search.ts` will automatically call `build_index.ts` to build it (about 2 seconds). If updates to `hmos-sdk-basic-skill/` are detected, it will also rebuild automatically. Queries typically return in under 1ms (after index loading), with no model dependencies.

#### Standard Retrieval Workflow

1. **Construct the query** — Extract core keywords from the user's question. Exact queries such as API names, class names, and error codes work best; you can also use Chinese keywords to describe functional requirements (e.g., "蓝牙连接").
2. **Execute retrieval** — Run `node scripts/search.js "<查询>" --top 8 --snippet` to get a list of candidate documents sorted by BM25 score (including path, title, category, score, and context snippet).
3. **Read top documents** — Based on scores and summaries, use the Read tool to read the full text of the top 1–3 `.md` documents (paths are relative to the `hmos-sdk-basic-skill/` directory and need to be converted to absolute paths). Prioritize reading SUB_SKILL.md (which contains complete invocation specifications, error codes, and example code).
4. **Filter by category** — If the user explicitly mentions a specific Kit, use `--category` to narrow the search scope to that Kit for improved precision.
5. **Fallback strategy** — If Top N results are poor: try splitting/combining keywords, use the Kit's English name, or consult `hmos-sdk-basic-skill/kit-routing.md` for functional routing.

#### Output Example

```
Top 5 results for "扫码" (searched 339 docs in 0.001s)

[1] score=13.16  Scan Kit  Scan Kit(统一扫码服务)/默认界面扫码/scan-scanbarcode/SUB_SKILL.md
    Title: hmos-scan-kit-default-scan
    Breadcrumb: 提供系统级默认界面扫码能力+支持单码和多码识别+无需申请相机权限+适用于应用内扫码场景
    Snippet: 本技能提供HarmonyOS默认界面扫码能力的完整实现方案...
[2] score=13.15  Scan Kit  Scan Kit(统一扫码服务)/默认界面扫码/SUB_SKILL.md
    Title: hmos-scan-kit-default-scan
    Breadcrumb: 启动系统默认扫码界面进行二维码/条形码扫描，支持多种码类型识别和相册扫码...
    ...
```

#### Why BM25

- **Strong exact matching**: Highly sensitive to literal queries like API names, class names, and error codes, making it ideal for technical document retrieval.
- **Zero dependencies**: Implemented purely with Node.js standard library (zlib built-in compression), no third-party libraries required.
- **Blazing fast**: Index build ~2 seconds, query <1ms, no model loading overhead.
- **Field-weighted scoring**: Title 5x, description 3x, breadcrumb 2x, body 1x, emphasizing skill name and description match weights.
- **Mixed Chinese-English tokenization**: English CamelCase splitting + Chinese unigram and bigram, no jieba or other tokenization libraries needed.

#### Model & Dependencies

- **No model dependencies**: Pure BM25 keyword retrieval, no AI model required.
- **No third-party dependencies**: Uses Node.js standard library `zlib` for index compression (built-in), no `npm install` needed.
- **Windows long path support**: `hmos-sdk-basic-skill/` contains 339 skill files with some long Chinese directory names. Windows long path prefix handling (`\\?\`) is built-in, no additional configuration required.

#### Index Maintenance

- **Automatic maintenance**: `search.ts` automatically checks the latest mtime of `hmos-sdk-basic-skill/` on startup and rebuilds if stale.
- **Force rebuild**: `node scripts/build_index.js --force` (about 2 seconds).
- **Index size**: docs.json.gz + inverted.json.gz approximately 1.35 MB (gzip compressed).
- **Index coverage**: Only covers skill definition files (`SUB_SKILL.md` / `SKILL.md`) under `hmos-sdk-basic-skill/`, each containing complete invocation specifications, error codes, and example code.

## SUB_SKILL.md Document Structure

Each functional skill's SUB_SKILL.md follows a unified template, containing the following sections:

- **功能描述** — Capability overview and core features provided by the skill
- **使用场景** — Trigger words, what it can/cannot do, and supplementary notes
- **调用规范和规则** — Input constraints, invocation environment requirements
- **调用流程和步骤** — Complete implementation steps and code examples
- **错误码说明** — Common error codes and handling methods
- **编译和修复问题** — Common compilation issues and fixes
- **常见问题与解决方法** — FAQ
- **输出结果报告** — Description of return results after successful invocation
- **参考文档** — Related official documentation links
- **完整示例代码** — Ready-to-use example code
- **测试用例** — Accompanying test case descriptions

After retrieving a SUB_SKILL.md, it is recommended to read the full text to obtain invocation specifications, error codes, and example code.

## Kit Directory Index

### Application Framework Domain

- **Accessibility Kit（无障碍服务）** — 无障碍服务状态查询、屏幕朗读体验提升（页面变化通知/动态内容播报/列表项组合/卡片自动居中/弹窗走焦/按钮标注/控件状态变化/多语种朗读/操作错误播报/焦点位置设置）、长辈关怀功能（关怀模式同步/应用声明接入/状态获取）、无障碍功能测试
- **Localization Kit（本地化开发服务）** — 应用国际化（字符处理/数字与度量衡/时区与夏令时/本地化名称/电话号码格式化/日历历法/语言与用户偏好）、应用本地化（多语言适配/多语言资源配置）
- **Form Kit（卡片开发服务）** — ArkTS卡片开发（生命周期管理/配置文件/UI动效/页面交互(message/call/router事件)/页面刷新(主动/被动/图片/状态)/待机屏保卡片/背板透明卡片/锁屏卡片/应用内加桌）、互动卡片开发（场景动效）、JS卡片开发（FA模型/Stage模型）

### Application Services Domain

- **Account Kit（华为账号服务）** — 华为账号登录（一键登录/静默登录）、获取用户信息（手机号/头像昵称/收货地址/发票抬头/风险等级）、未成年人模式
- **AppGallery Kit（应用市场服务）** — 应用市场推荐、应用内快捷方式、应用市场更新、应用归因、图标管理
- **IAP Kit（应用内支付服务）** — 商品购买（消耗型/非消耗型/自动续期订阅/非续期订阅）、售后（退款/开票）、开发准备
- **Push Kit（推送服务）** — 获取 Push Token、获取 AAID、推送场景化消息（通知消息发送/撤回）
- **Live View Kit（实况窗服务）** — 申请实况窗权限、构建本地实况窗
- **Share Kit（分享服务）** — 系统分享（发起分享/处理分享内容）、碰一碰分享、隔空传送
- **Service Collaboration Kit（协同服务）** — 跨设备互通ArkTS（跨设备拍照/文档扫描/图库选择/视频选择）、跨设备互通RichEditor控件（右键菜单跨设备调用相机/扫描/图库）、跨设备互通NDK(C)（C API跨设备相机/扫描/图库）

### Network & Communication Domain

- **Network Kit（网络服务）** — 连接网络（管理网络连接）、访问网络（HTTP/Socket）
- **Network Boost Kit（网络加速服务）** — 连接迁移（多网切换/多网并发）、网络质量（场景识别/质量评估/传输体验反馈）
- **Remote Communication Kit（远场通信服务）** — HTTP 通信（请求/定制/流式传输）、文件上传下载
- **Connectivity Kit（短距通信服务）** — WLAN（STA/P2P/扫描）、蓝牙（传统蓝牙/低功耗蓝牙）
- **Call Service Kit（通话服务）** — 来电场景、去电场景

### Location & Map Domain

- **Location Kit（位置服务）** — 获取设备位置、正/逆地理编码
- **Map Kit（地图服务）** — 创建地图、地图交互（手势/控件/事件/截图）、在地图上绘制（标记/折线/多边形/热力图等）、位置搜索（POI/地理编码）

### Security & Authentication Domain

- **Device Security Kit（设备安全服务）** — 安全检测（URL/系统完整性/统一风控）、应用设备状态检测
- **Online Authentication Kit（在线认证服务）** — FIDO 免密认证、IFAA 免密认证

### System Tuning Domain

- **Performance Analysis Kit（性能分析服务）** — 事件订阅（HiAppEvent/FaultLog，含崩溃/冻屏/丢帧/资源泄漏等系统事件）、系统调试信息（HiDebug）

### Device Hardware Domain

- **Wear Engine Kit（穿戴服务）** — 手机侧应用开发（设备查询/传感器/消息通信/授权/通知）、穿戴侧应用开发
- **Health Service Kit（运动健康服务）** — Wearable 应用开发（用户授权/运动健康数据管理）
- **Multimodal Awareness Kit（多模态融合感知服务）** — 获取用户动作

### UI Design Domain

- **UI Design Kit（UI设计套件）** — 图标处理（分层图标/单层图标）

### Media Domain

- **Scan Kit（统一扫码服务）** — 默认界面扫码、自定义界面扫码、图像识码、码图生成

For detailed Kit-to-functional-module mappings, see `hmos-sdk-basic-skill/kit-routing.md`.

## Document Path Format

All document paths are relative to the `hmos-sdk-basic-skill/` directory:

```
hmos-sdk-basic-skill/
├── kit-routing.md                       # Kit routing index
├── {Kit名（中英文）}/                     # 25 Kit directories
│   └── {功能分类}/
│       └── {功能子类}/
│           ├── SUB_SKILL.md             # Skill definition (name/description frontmatter)
│           ├── references/              # Official documentation (.md)
│           │   └── {文档名}.md
│           ├── tests/                   # Test cases (.ets/.py/.ts)
│           └── assets/                  # Example code (.ets/.cpp/.json5)
```
