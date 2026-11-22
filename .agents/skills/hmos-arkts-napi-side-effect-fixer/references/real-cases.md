# 仓内实测案例（real-cases）

> 基于 openharmony master（2026-09-14 快照）与本技能阶段 1 扫描真实产出实测。
> 本技能是端到端技能：§1–§2 记录「扫描产出 → 解析 → 引擎 → 回归验证」的端到端链路
> （真实 prescan 深析底稿与 R-02 格式报告驱动），§3 是引擎对仓内候选的直驱改写记录，
> §4 正例，§5 验证矩阵；§6–§9 是场景2（类别1：注册函数违规业务逻辑 →
> 显式 init() 导出）的端到端链路、引擎改写记录与合成端到端验证。
> 所有改写均在 /tmp 副本上验证，原仓未做任何修改。

---

## 1. 端到端整改链 ①：prescan 深析底稿驱动（bundle_monitor，形态B）

**目标**：`foundation/bundlemanager/bundle_framework/interfaces/kits/js/bundle_monitor/bundle_monitor.cpp`
（变量声明 L38；初始化块 L151–L159，位于 `nm_register_func` 回调 `BundleMonitorExport` 内）
——与需求示例（Init 内 `g_db = new Database(...)`）完全同构。

### 1.1 阶段 1：扫描产出（本技能 prescan.py）

```bash
python3 scripts/prescan.py \
    foundation/bundlemanager/bundle_framework/interfaces/kits/js/bundle_monitor --deep
```

深析底稿（`--deep`）中的形态B 锚点行（链节点下「全局赋值候选」）：

```markdown
- 全局赋值候选（词法表路由 R1限定名/R2本文件/R2h头文件/R4表外；…）:
  - [R2表命中(本文件L38)] …/bundle_monitor.cpp:157 matchingSkills); g_bundleMonitor = std::make_shared<BundleMonitorCallback>(subscribeInfo); EventFwk::CommonEventManager:
```

### 1.2 解析为工作清单（parse_scan_report.py）

```bash
python3 scripts/parse_scan_report.py prescan_bundle.txt
```

```markdown
## 全局单例惰性初始化 — 整改工作清单（来自本技能阶段 1 扫描产出）

- 输入：prescan_bundle.txt
- 条目：AUTO（可引擎整改）× 1、MANUAL（人工整改）× 0

| # | 扫描问题 | 文件 | 行 | 变量 | 形态/信号 | 分流 | 说明 |
|---|---|---|---|---|---|---|---|
| 1 | — | …/bundle_monitor.cpp | 157 | `g_bundleMonitor` | R2表命中(本文件L38) | AUTO | matchingSkills); g_bundleMonitor = std::make_shared<…> |
```

赋值式（模式1）命中 `g_bundleMonitor`。prescan 底稿不携带问题编号（为 —）；
R-02 报告输入时编号保留（见 §2.1）。

### 1.3 引擎整改：dry-run 闸门 → G3 正确拒绝 → 补 --root 通过

```bash
python3 scripts/parse_scan_report.py prescan_bundle.txt --fix          # dry-run
```

首轮（无 `--root`）闸门输出：形态B 判定成功（初始化块 L151–L159）、
G1/G2/G4–G8 全过，G3 拒绝——`g_bundleMonitor` 声明无 `static`（外部链接）：

```text
❌ G3 变量未加 static（外部链接）且未提供 --root 交叉检查 → 提供 --root 或人工确认无跨文件引用
❌ 安全闸门未通过（1 项）——拒绝改写。
```

补 `--root` 后复跑（`--apply` 写入）：

```text
✔ G3 链接性：外部链接（需交叉检查）
✔ G3 全仓无其他同名引用
策略：auto → meyers（模块 BUILD.gn 不含 -fno-threadsafe-statics）
改写形态：B | 策略：call_once | 访问器：`GetBundleMonitor()`
✅ 已写入：…（形态B → 惰性访问器 `GetBundleMonitor()`，策略 call_once）
```

（策略说明：auto 从 BUILD.gn 判得 meyers，但**形态B 固定 call_once**——最终生效
call_once，见 fix-patterns.md §3.3。）

### 1.4 改写前后（节选）

改写前：

```cpp
std::mutex g_monitorLock;
std::shared_ptr<BundleMonitorCallback> g_bundleMonitor = nullptr;      // L38

static napi_value BundleMonitorExport(napi_env env, napi_value exports)   // 注册回调
{
    ...
    if (g_bundleMonitor == nullptr) {                                    // L151
        EventFwk::MatchingSkills matchingSkills;
        matchingSkills.AddEvent(EventFwk::CommonEventSupport::COMMON_EVENT_PACKAGE_ADDED);
        matchingSkills.AddEvent(EventFwk::CommonEventSupport::COMMON_EVENT_PACKAGE_CHANGED);
        matchingSkills.AddEvent(EventFwk::CommonEventSupport::COMMON_EVENT_PACKAGE_REMOVED);
        EventFwk::CommonEventSubscribeInfo subscribeInfo(matchingSkills);
        g_bundleMonitor = std::make_shared<BundleMonitorCallback>(subscribeInfo);   // L157
        EventFwk::CommonEventManager::SubscribeCommonEvent(g_bundleMonitor);        // L158 依赖动作
    }
    return exports;
}
```

改写后（注册回调内初始化块整体删除；声明位置替换为访问器）：

```cpp
std::mutex g_monitorLock;
static std::shared_ptr<BundleMonitorCallback>& GetBundleMonitor()
{
    static std::shared_ptr<BundleMonitorCallback> instance = nullptr;
    static std::once_flag onceFlag;
    std::call_once(onceFlag, [] {
        EventFwk::MatchingSkills matchingSkills;
        matchingSkills.AddEvent(EventFwk::CommonEventSupport::COMMON_EVENT_PACKAGE_ADDED);
        matchingSkills.AddEvent(EventFwk::CommonEventSupport::COMMON_EVENT_PACKAGE_CHANGED);
        matchingSkills.AddEvent(EventFwk::CommonEventSupport::COMMON_EVENT_PACKAGE_REMOVED);
        EventFwk::CommonEventSubscribeInfo subscribeInfo(matchingSkills);
        instance = std::make_shared<BundleMonitorCallback>(subscribeInfo);
        EventFwk::CommonEventManager::SubscribeCommonEvent(instance);
    });
    return instance;
}

static napi_value BundleMonitorExport(napi_env env, napi_value exports)   // 仅剩 exports 构建
{
    ...
}
```

`Register`/`Unregister` 中使用点全部改经 `GetBundleMonitor()`（实测 6 处调用、
`g_bundleMonitor` 残留 0）。原判空短路（`if (GetBundleMonitor() == nullptr)`）
保留为不可达安全分支（可后续清理）。

### 1.5 回归验证（verify_fix.py）

整改前后同文件双向验证：

```text
整改前：残留候选：1 个（形态A × 0、形态B × 1）  →  ❌ 回归未通过   exit 1
整改后：残留候选：0 个（形态A × 0、形态B × 0）  →  ✅ 回归通过     exit 0
```

exit 码可直接作 CI 门禁。

### 1.6 整改记录

闸门 G1–G8 全过（G3 经 `--root` 交叉检查）；策略 call_once；残留引用 0；
括号配平一致；`clang++ -fsyntax-only` 仅头文件缺失错误（环境限制）。

---

## 2. 端到端整改链 ②：R-02 报告输入（问题编号回溯）与混合输入行为

### 2.1 R-02 报告格式：问题编号 #n 贯穿全链

按 rulebook §3.10 模板构造含【类别2】段的最终报告输入，
解析输出（判空式模式3 从保护块首行命中变量名）：

```markdown
| # | 扫描问题 | 文件 | 行 | 变量 | 形态/信号 | 分流 | 说明 |
|---|---|---|---|---|---|---|---|
| 1 | #1 | …/bundle_monitor_r02.cpp | 151 | `g_bundleMonitor` | report | AUTO | if (g_bundleMonitor == nullptr) { |
```

`--fix` 驱动时编号带入执行段标题：

```markdown
### …/bundle_monitor_r02.cpp — `g_bundleMonitor`（扫描问题 1）
```

整改报告可逐条回溯扫描问题编号。整改链与 §1.3 相同（无 `--root` 被 G3 拒绝 →
`--root` 后写入；实测 6 处 `GetBundleMonitor()`、残留 0、复验清零）。

### 2.2 双 prescan 混合输入：一次成单两个模块

```bash
python3 scripts/parse_scan_report.py prescan_bundle.txt prescan_window.txt --root <仓库根>
```

```markdown
- 条目：AUTO（可引擎整改）× 2、MANUAL（人工整改）× 0

| 1 | — | …/bundle_monitor.cpp | 157 | `g_bundleMonitor` | R2表命中(本文件L38) | AUTO | … |
| 2 | — | …/js_window_stage.cpp | 94 | `g_listenerManager` | P1 | AUTO | … |
```

bundle（形态B，R2 路由）+ window（形态A，P1 信号）跨目录两模块合并成单；
window 底稿中「形态A 候选」与「形态A 候选工作包」的重复 L94 行被按
（文件、变量、行）去重。

### 2.3 非 `--deep` 输出：空清单（E-2）

`prescan.py <目录>`（无 `--deep`）输出仅含漏斗统计与注册点解析，无形态A 候选行、
无全局赋值候选行（实测 bundle_monitor 目录非 `--deep` 输出 52 行，解析 0 条目）
→ 解析器输出空清单（E-2）。**形态B 输入必须用 `--deep` 底稿**。

### 2.4 实操提示：条目路径与测试副本

prescan 深析底稿中的文件路径沿用扫描时的形态（形态A 候选段多为相对路径、全局赋值
候选行为绝对路径）——`--fix --apply` 会直接驱动引擎改写这些路径指向的文件（即真实
工程源码，这正是技能用途）。**相对路径条目需在仓库根运行解析器，或加
`--root <仓库根>`**（实测：从其他目录、无 `--root` 运行时，相对路径条目因
「文件不存在」转 MANUAL；加 `--root` 后恢复 AUTO 并解析为绝对路径）。若要在
**副本上先验证**，需把产出文件中的路径重写到副本（如 `sed` 替换），或让 prescan.py
直接对副本目录运行。实例：对真实仓路径的条目误用指向沙箱的 `--root` 交叉检查时，
G3 因「其他文件存在同名引用」（沙箱内的同变量副本）拒绝——闸门对路径/根不匹配
同样安全兜底，仓文件未被写入。

---

## 3. 引擎直驱改写记录（apply_lazy_init.py，仓内候选）

### 3.1 形态A 智能指针：js_window_stage.cpp（非注册 TU）

**定位**：`foundation/window/window_manager/interfaces/kits/napi/window_runtime/window_stage_napi/js_window_stage.cpp:94`
（该文件自身无注册要素——与 `window_stage_module.cpp` 同 .so，形态A 在任意 TU 都于加载期执行；
prescan 扫描目录即覆盖）

```cpp
// 改写前
std::unique_ptr<JsWindowRegisterManager> g_listenerManager = std::make_unique<JsWindowRegisterManager>();
// 改写后
static std::unique_ptr<JsWindowRegisterManager>& GetListenerManager()
{
    static std::unique_ptr<JsWindowRegisterManager> instance = std::make_unique<JsWindowRegisterManager>();
    return instance;
}
```

L440/L486/L490/L493 共 4 处 `g_listenerManager->…` → `GetListenerManager()->…`。

**记录**：G3 外部链接（无 `static`）→ `--root` 交叉检查确认 `g_listenerManager`
全仓仅此文件引用 → 通过（改写后收窄为 `static`，封装性提升）；策略 meyers；
残留引用 0；语法检查仅头文件缺失。

### 3.2 形态A 匿名命名空间：napi_fusion_ranging.cpp（非 g_ 命名）

**定位**：`foundation/communication/fusion_connectivity/fusion_ranging/frameworks/napi/src/napi_fusion_ranging.cpp:37`

```cpp
namespace {
std::shared_ptr<NapiFusionRangingObserver> napiCallback_ = std::make_shared<NapiFusionRangingObserver>();
}
// → namespace { static std::shared_ptr<NapiFusionRangingObserver>& GetNapiCallback() { … } }
```

L141–L208 共 17 处 `napiCallback_->…` → `GetNapiCallback()->…`（访问器保持原
匿名命名空间作用域）。

**记录**：变量名不带 `g_` 前缀（命名不是判定依据，作用域才是）；`--root` 交叉检查
命中同名**类成员** `napi_fusion_ranging_callback.h:40`（`NapiCallback` 类的成员，
不同符号）——人工核实为非冲突；策略 meyers；残留引用 0。

### 3.3 形态A 工厂创建：input_event_client js_register_module.cpp

**定位**：`foundation/multimodalinput/input/frameworks/napi/input_event_client/src/js_register_module.cpp:131`

```cpp
static std::shared_ptr<KeyEvent> g_injectKeyState = KeyEvent::Create();
// → static std::shared_ptr<KeyEvent>& GetInjectKeyState() { static … instance = KeyEvent::Create(); … }
```

L172–L180 多处 `g_injectKeyState->…` → `GetInjectKeyState()->…`。

**记录**：`KeyEvent::Create()` 为平台 API 工厂（内部实现不在本 TU）——成本档位
按 rulebook S-09 属"待确认"类；从**状态一致性**维度（按键注入状态在模块加载时
即建立）仍属本优化项范围。闸门通过后可自动改写；改写后工厂调用推迟到首次
`InjectEvent` 类接口调用。

### 3.4 形态A 裸指针：photomodify Image.cpp（P1 盲区实录）

**定位**：`applications/standard/app_samples/code/BasicFeature/Media/Image/photomodify/src/main/cpp/Image.cpp:46`

```cpp
static ImagePictureNative *g_thisPicture  = new ImagePictureNative();
// → static ImagePictureNative* GetThisPicture() { static ImagePictureNative* instance = new ImagePictureNative(); … }
```

342–533 行共 46 处使用点全部替换（`g_thisPicture->source` → `GetThisPicture()->source`、
`&g_thisPicture->source` → `&GetThisPicture()->source` 等）。

**扫描盲区实录**（fix-patterns.md §6 的实测依据）：

| 检查 | 结果 |
|---|---|
| 阶段 1 `prescan.py <photomodify cpp目录> --deep` | 形态A 候选 **0 个**（P1 正则不匹配 `Type *name` 空格+星号风格；链干净） |
| 本技能 `verify_fix.py Image.cpp` 复扫 | **命中 1 个**（形态A，L46 `g_thisPicture`） |
| `--target Image.cpp:46:g_thisPicture` 补入后引擎改写 | 闸门全过，46 处替换完成 |

**记录**：G6 注意 `&g_thisPicture->source` 是成员地址（合法替换）；`ImagePictureNative`
持有 `source/picture/options/packerOptions/imagePacker/errorCode`——**页面间状态残留
的真实载体**（页面 A 解码后，页面 B 首调读到的仍是 A 的 picture/errorCode）。
本项整改解决初始化时机；状态残留需另行把可变字段移入每次调用的局部对象（超范围附注）。
策略 meyers；残留引用 0；语法检查仅头文件缺失。

### 3.5 形态A：NdkPicture napi_init.cpp（成员命名风格全局）

**定位**：`applications/standard/app_samples/code/DocsSample/Media/Image/NdkPicture/entry/src/main/cpp/napi_init.cpp:86`

```cpp
static ImagePictureNative *ndkPicture_ = new ImagePictureNative();
// → static ImagePictureNative* GetNdkPicture() { … }
```

与案例 3.4 同源（同一示例模板复制）。`_` 后缀成员命名风格的全局变量——作用域判定
不受命名风格影响。同属 P1 盲区风格（`Type *name`），prescan 不报、verify_fix 可复扫定位。

### 3.6 形态A：AudioSessionSampleC audiosession.cpp（外部链接裸指针）

**定位**：`applications/standard/app_samples/code/DocsSample/Media/Audio/AudioSessionSampleC/entry/src/main/cpp/audiosession.cpp:45`

```cpp
Var *g_audioSessionVariable = new Var();          // 注意：无 static——外部链接
// → static Var* GetAudioSessionVariable() { static Var* instance = new Var(); … }   // 收窄为内部链接
```

6 处 `g_audioSessionVariable->globalResmgr` → `GetAudioSessionVariable()->globalResmgr`。

**记录**：G3 因无 `static` 触发外部链接检查 → `--root` 确认全仓无其他引用 → 通过。
`Var` 结构持有 `globalResmgr`（资源管理器）——`OH_ResourceManager` 获取发生在 so
加载期是典型加载期重操作。同属 P1 盲区风格。

### 3.7 形态A：TrafficFilter_Packet napi_init.cpp（auto 推导）

**定位**：`applications/standard/app_samples/code/DocsSample/NetWork_Kit/NetManager_Kit/NetManagerKit_NetManager/TrafficFilter_Packet_case/entry/src/main/cpp/napi_init.cpp:74`

```cpp
auto g_asyncContext = new PacketCallbackCtx();
// → static PacketCallbackCtx* GetAsyncContext() { static PacketCallbackCtx* instance = new PacketCallbackCtx(); … }
```

**记录**：auto 声明的类型推导由引擎完成（`new T(...)` → `T*`）。同文件 L36
`std::shared_ptr<std::atomic<bool>> isReport = std::make_shared<std::atomic<bool>>(false)`
为同模式的轻量变体（成本轻，可一并改写或保留——按 rulebook S-08 轻量即结案）。

---

## 4. 正例（已是目标形态，无需整改）

### 4.1 media_library ANI 模块：thread_local + 判空惰性创建

`foundation/multimedia/media_library/frameworks/ani/src/cpp/media_library_ani.cpp:129,2001-2004`

```cpp
thread_local unique_ptr<ChangeListenerAni> g_listObj = nullptr;   // 空初始化——加载期零成本
...
if (g_listObj == nullptr) {                                       // 首次业务调用时创建
    ani_vm *vm = nullptr;
    CHECK_COND_RET(env->GetVM(&vm) == ANI_OK, result, "GetVM failed");
    g_listObj = std::make_unique<ChangeListenerAni>(vm);
}
```

首用创建 + 判空 + 依赖运行时环境（vm）——正是 fix-patterns.md §3.4 方案二的形态。

### 4.2 官方懒单例模板：c_utils DelayedSingleton / DelayedRefSingleton

`commonlibrary/c_utils/base/include/singleton.h`——`OHOS::DelayedSingleton<T>::GetInstance()`
（双检锁 + atomic_load），`DECLARE_DELAYED_SINGLETON(MyClass)` 宏声明。系统服务侧
通用；NAPI 模块内文件级访问器与该模板语义一致（前者更轻，无需改类声明）。

### 4.3 camera_manager：GetInstance 内判空创建

`foundation/multimedia/camera_framework/frameworks/native/camera/base/src/input/camera_manager.cpp:1660`
（`if (CameraManager::g_cameraManager == nullptr) { g_cameraManager = new CameraManager(); }`
在访问器内部——首用创建）。

### 4.4 hyper_graphic_manager：thread_local 引用绑定

`foundation/graphic/graphic_2d/interfaces/kits/napi/graphic/hyper_graphic_manager/src/hyper_graphic_manager_napi.cpp:32`
（`thread_local static RSInterfaces& interfaces = RSInterfaces::GetInstance();`——
每线程首次使用时绑定，加载期不执行）。

---

## 5. 实测验证矩阵

### 5.1 输入端与链路（parse_scan_report.py / verify_fix.py）

| 验证对象 | 结果 |
|---|---|
| 真实 prescan 深析底稿解析（bundle_monitor `--deep`） | AUTO × 1（`g_bundleMonitor`，R2 路由），与人工核对一致 |
| 双 prescan 混合输入（bundle + window） | AUTO × 2（形态B + 形态A），跨模块合并、重复行去重 |
| R-02 报告格式输入 | 问题 #1 保留贯穿；判空式从保护块首行解析变量 |
| 非 `--deep` 输出 | 0 条目 → 空清单（E-2） |
| `--fix` dry-run 无 `--root` | G3 正确拒绝（两种输入均复现），不写文件 |
| `--fix --apply --root` | 形态B → call_once 写入；6 处 `GetBundleMonitor()`、残留 0 |
| 交叉检查根不匹配（条目指真实仓、--root 指沙箱） | G3 拒绝「其他文件存在同名引用」——仓文件未被写入（安全兜底） |
| verify_fix 整改前/后同文件 | 前：形态B × 1 命中，exit 1；后：清零，exit 0 |

### 5.2 引擎改写与校验（apply_lazy_init.py，仓内真实文件）

| 案例 | 形态 | 闸门 | 残留引用 | 括号配平 | -fsyntax-only |
|---|---|---|---|---|---|
| bundle_monitor.cpp | B | 全过 | 0 | 一致 | 仅头文件缺失 |
| js_window_stage.cpp | A | 全过（G3 需 --root） | 0 | 一致 | 仅头文件缺失 |
| napi_fusion_ranging.cpp | A | 全过（G3 同名成员人工核实） | 0 | 一致 | 仅头文件缺失 |
| audiosession.cpp | A | 全过（G3 需 --root） | 0 | 一致 | 仅头文件缺失 |
| Image.cpp | A | 全过 | 0 | 一致 | 仅头文件缺失 |
| traffic_napi_init.cpp | A | 全过 | 0 | 一致 | 仅头文件缺失 |

（NdkPicture napi_init.cpp 与 Image.cpp 同源模板，改写同法。）

### 5.3 编译运行与并发（合成端到端用例，形态A + 形态B）

g++ / OHOS clang 12 默认参数、g++ `-fno-threadsafe-statics -fno-exceptions`：
编译通过 + 运行 8/8 断言通过——加载后零构造、注册回调零初始化、16 线程并发
首用实例唯一、业务功能与字符串状态完好。

策略对比（16 线程并发首次调用 × 20 轮，`-fno-threadsafe-statics -fno-exceptions`）：

| 策略 | 失败次数（构造出多实例） |
|---|---|
| meyers | 14/20 |
| call_once | 0/20 |

——策略自动选择（BUILD.gn 含 `-fno-threadsafe-statics` → call_once；形态B 恒 call_once）
的必要性依据。

---

## 6. 场景2 端到端整改链 ①：prescan 深析底稿驱动（js_error_manager，类别1）

**目标**：`foundation/ability/ability_runtime/frameworks/js/napi/app/error_manager/js_error_manager.cpp`
——系统 kit `app.ability.errorManager` 的实现文件；注册回调
`JsErrorManagerInit`（L1875–L1911）内含 call_once 进程级注册块 + 
`SetLeakObserver`，**且存在纠缠语句**（`napi_wrap` 对象成员调用）——
是仓内最复杂的类别1 案例。

### 6.1 阶段 1：扫描产出（本技能 prescan.py）

`prescan.py <error_manager目录> --deep` → 深析工作包「链」节点下
**信号命中 ×11**（M-19 信号表；格式 `- [信号类[/exports]] <文件>:<行> <片段>`）。
关键分布：L1883/1886/1887–1893/1907 落在注册回调 `JsErrorManagerInit` 体内；
L963/985 落在辅助函数 `SetRejectionCallback` 体内（回调经调用链触达）。

### 6.2 解析为工作清单（parse_scan_report.py v2，类别感知）

11 条信号行 → 同文件去重为 **1 条类别1 AUTO 条目**（引擎 E），
**全部 11 个行号保留**传给引擎 `--at-line` 逐个尝试定位回调。
`nm_modname` 在本文件未定义（跨文件注册：模块结构在 error_manager_module.cpp）。

### 6.3 引擎 E 整改：多行定位 + 语句分类 + 纠缠分流

- 定位：963/985 不在任何 `(napi_env, napi_value)` 函数内（跳过）→
  1883 命中 `JsErrorManagerInit`（输出「本文件无 nm_register_func——跨文件
  注册，已按该函数处理」提示核对）；
- 语句分类（17 条语句）：**MOVE × 2**（`std::call_once(registerCallbackFlag,
  [](){…6 个进程级注册…})` 整块；`SetLeakObserver(LeakObserverFunc)`）、
  **KEEP × 15**（含纠缠保留：`jsErrorManager` 声明/`SetRejectionCallback`
  成员调用/`moduleName`——依赖 `napi_wrap` 挂载对象，见 §8 案例与
  fix-patterns.md §9）；
- 闸门 H1–H7 全过（H2* 纠缠 × 3 提示，不阻断）；
- 挂载：bind 风格——`BindNativeFunction(env, exportObj, "init", moduleName,
  ExplicitInit)` 插入最后一个 BindNativeFunction 完整语句后（多行语句收尾
  以 `;` 定位——初版插在语句中间导致编译失败，已修复并有 H7 防回归）；
- 迁移语句 call_once 包装（内层原 call_once → 双层，语义不变）+
  `#include <mutex>` 自动插入；
- `--apply --check`：容忍式语法检查通过（仅缺 OHOS 系统头文件，环境限制）；
- **系统 kit API 兼容性警示**输出（`app.ability.errorManager` 为公共 kit——
  见 fix-patterns.md §8.5 策略矩阵；本案例属能力验证，实际整改建议策略 L）。

### 6.4 回归验证（verify_fix.py 类别1 残留扫描）

跨文件注册回调用 `--all-tu --callback JsErrorManagerInit` 点名核查：
整改前类别1 残留 × 2（call_once 块 + SetLeakObserver）→ 整改后 **0**，exit 0。
幂等性：对已整改文件重跑引擎 E → `H1 无可迁移语句——回调已是仅函数映射`，
不改写。

## 7. 场景2 端到端整改链 ②：ImageEffect（类别1，干净案例 + ArkTS 集成）

**目标**：`applications/standard/app_samples/code/DocsSample/Media/Image/
ImageEffect/entry/src/main/cpp/napi_init.cpp`——应用工程内模块
（`nm_modname = "entry"`，libentry.so），**与需求2 示例完全同构**。

### 7.1 语句分类（引擎 E）

```cpp
static napi_value Init(napi_env env, napi_value exports)
{
    RegisterCustomBrightness();                 // MOVE：业务动词族（内部为业务注册）
    RegisterCustomCrop();                       // MOVE：同上

    napi_property_descriptor desc[] = { … };    // KEEP：导出面 API
    napi_define_properties(env, exports, …);    // KEEP：导出面 API
    return exports;                             // KEEP：return
}
```

MOVE × 2 / KEEP × 3，闸门 H1–H7 全过，注册风格 desc-array——
`DECLARE_NAPI_FUNCTION("init", ExplicitInit)` 插入数组收尾 `};` 前。

### 7.2 改写结果（--apply --check：容忍式语法检查通过）

新函数 `ExplicitInit`（call_once 包装 + `<mutex>` 补齐）插入回调前；
Init 只剩函数映射 + init 挂载。

### 7.3 ArkTS 侧集成（必做人工步骤；--js-root 定位）

`--js-root <ImageEffect/entry/src/main/ets>` 定位到调用点：

```
pages/ImageEditPage.ets:16 `import imageEffect from 'libentry.so';`
  → 首次调用其他接口前补 `imageEffect.init()`
```

（BasicFeature/Media/ImageEffect 同款样例同一集成点。）

### 7.4 回归验证

verify_fix.py：类别1 残留 0，exit 0。

## 8. 场景2 引擎分类实测（真实案例矩阵）

全仓 `foundation` + `applications` 23953 个 .cpp/.cc 扫描（nm_register_func
回调 + 语句分类）得到 16 个含业务语句回调，关键案例分类实测：

| 案例 | 回调 | 分类结果 | 引擎行为 | 说明 |
|---|---|---|---|---|
| ImageEffect napi_init.cpp | Init | MOVE×2（RegisterCustom*） | ✅ 迁移 | 干净案例（§7） |
| js_error_manager.cpp | JsErrorManagerInit | MOVE×2（call_once 块/SetLeakObserver）+ 纠缠×3（jsErrorManager/SetRejectionCallback/moduleName） | ✅ 部分迁移 + 人工指引 | 纠缠依赖 napi_wrap 对象（§6、fix-patterns.md §9.1） |
| bundle_manager native_module.cpp | BundleManagerExport | KEEP×64（Create*Type(env, local) 枚举对象全部 exports 数据流）+ MOVE×2（`auto task`+`ffrt::submit(task)` **整簇同迁**——簇规则防悬空引用）+ 轻量保留×2（`key`/`napi_add_env_cleanup_hook`，S-08 口径） | ✅ 簇整迁 | 只迁 lambda 声明会悬空引用（编译失败）；初版误判已修 |
| nfc nfc_napi_tag.cpp | InitJs | MOVE×0 | ✅ 无需整改（H1） | 负样本：`Register*JSClass(env)` 内部是 `napi_define_class`（被调体检查判 KEEP） |
| bundle_manager 同族 5 文件（app_control/bundle_resource/skill_manager/free_install/default_app） | *Export | Create*Object(env, local) 全 KEEP | 负样本 | exports 数据流（S-03 豁免）——初版按动词族误判 97 处，修正后收敛 |
| NdkNativeImage napi_init.cpp | Init | MOVE×0；SKIP_FORMB×1（全局赋值守卫块） | 分流引擎 L | 注册回调含全局赋值 → 类别2 口径（先 L 后 E 组合） |

**分类修正的两条实测教训**（fix-patterns.md §8.2）：

1. `Xxx::Init(env, exports)` / `Create*Type(env, local)` 带 exports/数据流
   实参 → 导出面构建（S-03），不迁；
2. 被调函数名带 Register 不等于业务——nfc `RegisterNfcAJSClass` 内部是
   `napi_define_class` → 保留；ImageEffect `RegisterCustomBrightness` 内部
   是业务注册 → 迁。

## 9. 场景2 合成端到端验证（25/25 断言，双编译器）

合成测试床 `/tmp/opencode/fixtest/cat1/`：mini napi 兼容层（napi_module 注册
表 + FakeValue 导出面对象 + SimulateLoadModule/CallExport 测试驱动）+
三种注册风格模块源（desc-array / BindNativeFunction / napi_set_named_property，
分别同构 ImageEffect / js_error_manager / 轻量模块）→ 引擎 E `--apply` 整改 →
编译 → 运行断言。

**断言矩阵（25 项全过，g++ 12.3 `-std=c++20` 与 OHOS clang 12
`-std=c++17` 双编译器）**：

| 组 | 断言 | 结果 |
|---|---|---|
| A. 模拟 dlopen 后 | 3 模块 constructor 注册生效；3 模块业务初始化均未执行（**零副作用**） | 5/5 |
| B. 注册回调执行后 | desc 模块业务仍未发生 + 导出面含 PixelMapFilterStart/getSurfaceId/**init**；bind 模块纠缠语句仍执行（文档化行为）+ 已迁移业务未发生 + 导出面含 on/off/**init**；setn 模块 Attach 未发生 + 导出面含 businessOne/**init** | 7/7 |
| C. 显式调用 init()（首次） | init() 返回 undefined；desc/bind 业务初始化各执行一次（setn 首调留给 F 组竞态） | 3/3 |
| D. init() 幂等（重复调用） | desc/bind 计数不增（call_once 包装生效） | 2/2 |
| E. 业务接口在 init() 后 | PixelMapFilterStart / on 正常工作 | 2/2 |
| F. 并发首调（8 线程竞态，v3.1.0） | setn 模块 8 线程并发首调全部正常返回且**恰好执行一次**（不是 1..8 次）；已初始化模块（desc/bind）并发重复调用计数不增；并发首调后再单次调用不增；业务函数并发 init 后可用 | 6/6 |

**覆盖的语义保证**：加载零副作用（目标达成）、导出面完整（原接口+init）、
迁移语句各执行一次（等价）、幂等（增强）、**并发首调恰好一次**（增强，
call_once 串行化——注册回调原本加载期单线程执行，迁入 init() 后新增的
竞态面由包装兜底）、业务功能可用（正确性）。

---

## 10. v3.1.0 增强（对照参考技能 gap 收敛，含实测）

对照引导式参考技能（hmos-arkts-napi-lazy-init-remediator，`/srv/workspace/skill`）
的边界设计，v3.1.0 收敛以下缺口；每项落地均经实测（本节案例），证据锚点全部在
本仓快照核验：

| 增强 | 落点 | 实测（本节） |
|---|---|---|
| 框架路径黑名单硬拒改（E-14） | 两引擎：`ace_engine/advanced_ui_component/*/interfaces/`、`arkcompiler/ets_runtime/`、`foundation/arkui/napi/native_engine\|module_manager/` 命中即拒（E 退出码 4 / L 退出码 6） | 对真实仓文件 `module_manager/native_module_manager.cpp` 直跑：E exit 4、L exit 6，零改写 |
| 保留信号第三出口（E-15） | 引擎 E 分类：`signal/sigaction` 语句按信号号分流——保留段（34..64/60/SIGRTMIN+n/MUSL_SIGNAL_*/同文件常量）降级保留转设计评审；不可解析保持 MOVE+警示+ArkTS 冲突核对义务 | 合成 6 例全过：`signal(60,…)`→KEEP+第三出口；`sigaction(MUSL_SIGNAL_JSHEAP,…)`→KEEP+第三出口；`signal(SIGRTMIN + 4,…)`→KEEP+第三出口；`constexpr SIGNAL_FOR_GC = 60` 同文件解析→KEEP+第三出口；`signal(gSigNum,…)`→MOVE+不可解析警示；`signal(SIGPIPE, SIG_IGN)`→MOVE+普通信号提示 |
| 引擎 L 生命周期警示（E-16） | 析构体含 `napi_*` → env 死亡后析构悬空警示（DeconstructCtxEnv→SetDead，ark_native_engine.cpp:716/733）；构造体含 `throw` → 异常时点移位警示 | 合成 1 例双警示齐发（析构 napi_delete_reference + 构造 throw） |
| 保留信号与残留扫描一致性 | verify_fix 复用引擎 E 分类器 | `signal(60)` 案例残留=1（仅 RegisterWatchdog）；纯保留信号案例残留=0（第三出口不计残留） |
| 真实案例回归 | — | ImageEffect（MOVE×2/KEEP×3）、js_error_manager（MOVE×2/KEEP×15）、bundle_manager（MOVE×2/KEEP×64/未命中×2）、nfc 负样本（MOVE×0）分类与 v3.0.0 完全一致——新通路零误伤 |
| 措辞修正（禁止裸判空） | 引擎 E `_manual_guidance`、parse_scan_report MANUAL 指引、fix-patterns §3.4/§5.1/§5.2/§9.1 | 全部改为「std::call_once 或双检锁（先加锁后判），禁止裸判空」 |
| 文档新增 | fix-patterns §8.10（保留信号第三出口+保留集表+裁决）、§8.11（失败契约+两族 P1）、§8.12（napi_onLoad 划界）、§8.5（场景1/2 分叉注）、§8.8（两族义务+env 纪律）、§7（已知影响+2 条）、§10（框架黑名单/生命周期警示/env 线程纪律）；SKILL.md E-14/15/16+检查清单 4 项+注意事项 4 条 | — |

**设计取舍（未采纳参考技能的一项）**：参考技能的场景2 流程会把业务动作重构为
返回 bool 的 `RunBusinessInitActions()`（失败上抛 napi_throw_error）。本引擎保持
**verbatim 迁移**（返回值处理一字不改）——失败契约升级作为可选人工模板提供
（fix-patterns.md §8.11），不进自动引擎：任何改写返回值/控制流的"顺手优化"都会
引入新的正确性风险，违背「整改后保证正确编译执行」的第一约束。

**保留集证据锚点**（本快照实测核验）：

- `third_party/musl/porting/linux/user/include/signal.h`：`MUSL_SIGNAL_*` =
  SIGRTMIN+0..+10（JSHEAP=+4、RECYCLE_JEMALLOC=+8〔USE_JEMALLOC_RECYCLE_FUNC〕、
  MEMCHECK=+9、FDTRACK=+10）；
- `foundation/arkui/ace_engine/frameworks/core/common/ace_engine.cpp:113-120`：
  `InitJsDumpHeadSignal()` 内 `sigaction(MUSL_SIGNAL_JSHEAP, &sigAct, NULL)`；
- `foundation/arkui/ace_engine/frameworks/core/common/watch_dog.cpp:41`：
  `constexpr int32_t SIGNAL_FOR_GC = 60`；
- `foundation/arkui/napi/native_engine/impl/ark/ark_native_engine.cpp:716/719/733`：
  `DeconstructCtxEnv()` → `RunCleanupHooks(false)` → `SetDead()`（env 死亡时序）；
- `foundation/arkui/napi/native_engine/native_api_internal.h:77`：CROSS_THREAD_CHECK
  （仅校验调用线程==env 所属线程）；
- `foundation/arkui/napi/module_manager/native_module_manager.cpp:1408` + `.h:56`：
  `napi_onLoad` 查找/调用与无参原型（fix-patterns.md §8.12 划界依据）。
