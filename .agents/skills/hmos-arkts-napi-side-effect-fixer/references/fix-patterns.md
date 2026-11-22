# 整改模式手册（fix-patterns）

> 本手册是 `hmos-arkts-napi-side-effect-fixer` 的规则唯一来源。
> 实现权威 = `scripts/parse_scan_report.py`（输入解析）、`scripts/apply_lazy_init.py`（引擎 L：
> 类别2 惰性访问器）、`scripts/apply_init_extraction.py`（引擎 E：类别1 显式 init 导出）、
> `scripts/verify_fix.py`（回归验证）；手册与脚本不一致时，以脚本行为为准并回改手册。

---

## 1. 技能定位、术语对齐与形态定义

### 1.1 技能定位（端到端：扫描 → 整改 → 回归）

本技能是**端到端技能**（原扫描端 v2.3.0 与整改端 v3.1.x 合并）。
阶段 1（扫描）由 `scripts/prescan.py` 完成问题发现与定级，阶段 2（整改）
消费阶段 1 产出并落地代码整改，阶段 3（回归）由 `scripts/verify_fix.py` 验证：

```
阶段 1 扫描产出（prescan.py，R-01/R-02 最终报告 / --deep 深析底稿）
    │  其中两类问题：
    │    · 类别1：注册函数违规业务逻辑（耗时）——Init 回调内业务动作
    │    · 类别2：加载期重初始化——全局单例 so 加载即创建
    ▼
parse_scan_report.py     解析阶段 1 产出 → 整改工作清单（问题编号 #n 保留、
    │                    按类别路由引擎 L/E、AUTO/MANUAL 分流）
    ▼
apply_lazy_init.py       引擎 L（类别2）：按变量名在当前源码重定位 → 形态判定 →
    │                    闸门 G1–G8 → 惰性初始化（惰性访问器改写）（默认 dry-run；--apply 写入）
    │
apply_init_extraction.py 引擎 E（类别1）：注册回调定位 → 语句级分类 →
    │                    闸门 H1–H7 → 业务语句迁显式 init() 导出
    │                    （执行顺序：先 L 后 E，见 §8.6）
    ▼
verify_fix.py            回归验证：类别2 残留候选 + 类别1 残留 MOVE 语句，
                         全部清零（exit 0）→ 编译/运行验证
```

### 1.2 术语对齐（阶段 1 扫描 ↔ 阶段 2 整改）

| 阶段 1 扫描术语 | 阶段 2 整改术语 | 含义（详证见下节） |
|---|---|---|
| 类别2：加载期重初始化 | **整改对象（引擎 L）** | so 加载（dlopen）/注册链上执行的业务对象创建（与构建 exports 无关） |
| 形态A 候选（P1/P2/P3/P1ns/P2ns 信号，经排除管道） | **形态A**：文件作用域动态初始化器 | 全局/命名空间作用域变量带动态初始化器（§1.4） |
| 全局赋值候选（词法表路由 R1/R2/R2h/R4） | **形态B**：注册回调内全局赋值 | 空初始化全局变量在注册链函数内被赋值（§1.5） |
| 深析可判：注册链内创建且不落全局变量 | **形态C**（MANUAL） | 如 `SomeRegistry::Register(std::make_shared<X>(…))`——引擎不自动改写 |
| 类别1：注册函数违规业务逻辑（耗时） | **整改对象（引擎 E）** | `nm_register_func` 的 Init 回调内业务动作（信号注册/线程/进程级注册/IPC 等，S-02 动作族）——业务初始化迁显式 `init()` 导出（§8） |
| 类别1 信号命中（M-19 信号表，`--deep` 深析） | 引擎 E 输入锚点 | `- [信号类[/exports]] <文件>:<行> <片段>`（§2.2） |
| R-01/R-02 最终报告（rulebook §3.10 模板） | 输入格式一 | 【类别1】/【类别2】段 + 问题 #n + 📍 定位（§2.1） |
| prescan.py `--deep` 深析底稿 | 输入格式二 | 形态A 候选段 + 全局赋值候选行 + 类别1 信号命中行（§2.2） |

### 1.3 问题定义：注册链执行模型

NAPI 模块（.so）被 dlopen 后立即执行的代码路径（**注册链**）：

```
ArkTS: import xxx from 'libentry.so'
  → 引擎 NativeModuleManager::LoadModule → LoadModuleLibrary
  → dlopen("libentry.so", RTLD_LAZY)
      ① 文件/命名空间作用域变量的动态初始化器（形态A 执行点）
      ② __attribute__((constructor)) 函数
          → napi_module_register(&module)（把模块登记进模块管理器）
  → import 处理时引擎调用 nm_register_func 回调（Init，形态B 执行点）
```

注册链上的**业务对象构造**（数据库连接、网络客户端、订阅注册等）在应用启动路径上
执行——即使应用从未调用该模块的任何接口。

**整改目标**：把业务对象构造从注册链移到**首次业务调用**，且工程整改后可正确编译运行。

### 1.4 形态A：文件作用域动态初始化器

变量声明在文件/命名空间作用域（含匿名命名空间），初始化器含动态行为：

| 子形态 | 示例 | 处理 |
|---|---|---|
| A-ptr | `static Database* g_db = new Database("/db");` | 可自动改写 |
| A-unique | `std::unique_ptr<M> g_m = std::make_unique<M>();` | 可自动改写 |
| A-shared | `std::shared_ptr<M> g_m = std::make_shared<M>();` | 可自动改写 |
| A-auto | `auto g_ctx = new PacketCallbackCtx();` | 可自动改写（类型推导） |
| A-direct | `Manager g_mgr(args);`（直接初始化） | **仅报告，人工确认**（与函数原型无法机械区分） |
| A-member | `Manager* Manager::g_inst = new Manager();`（类静态成员） | 人工整改（§5.4） |

### 1.5 形态B：注册回调内全局赋值

文件作用域变量空初始化（`= nullptr`），赋值发生在注册链函数内
（`nm_register_func` 回调 / `__attribute__((constructor))` / 被二者直接调用的函数）：

```cpp
static std::shared_ptr<BundleMonitorCallback> g_bundleMonitor = nullptr;

static napi_value BundleMonitorExport(napi_env env, napi_value exports)
{
    ...
    if (g_bundleMonitor == nullptr) {                       // 保护块
        ... 构建 subscribeInfo ...                           // ← 初始化体（整块搬迁）
        g_bundleMonitor = std::make_shared<BundleMonitorCallback>(subscribeInfo);
        EventFwk::CommonEventManager::SubscribeCommonEvent(g_bundleMonitor);  // ← 依赖动作
    }
    return exports;
}
```

**关键**：`if (g_x == nullptr) { … }` 保护块内的**全部语句**（构建参数 + 创建 + 订阅/
注册等后继动作）是初始化体的最小完整单元，必须整体迁入访问器。只迁赋值语句会导致：

- 加载期残留 `SubscribeCommonEvent(nullptr)` 类半块（行为异常/崩溃）；
- 使用点判空恒为真（初始化不再发生），功能失效。

无保护块的裸赋值（`g_x = new X(...);` 直接在回调体内）同样按语句整块处理。

### 1.6 豁免（不计整改目标）

| 豁免 | 原因 |
|---|---|
| 常量初始化（`nullptr`/`0`/`NULL`/`true`/字面量/`{}`/全大写常量名/constexpr/constinit） | 静态初始化，加载期零成本（不进动态初始化链） |
| `thread_local` 空初始化 + 使用点判空创建 | 每线程首次使用时初始化，加载期不执行——已是目标形态（正例见 real-cases.md §4） |
| 挂到 exports 的对象（`napi_wrap` / 属性挂载） | 导出面构建一部分，注册期必须存在 |
| `using`/`typedef`/`extern` 声明行 | 非变量定义 |

---

## 2. 扫描产出解析格式（输入端 parse_scan_report.py）

解析器自动识别两类输入（可多文件混合），另支持 `--target` 直连；**只消费、不扫描**。

### 2.1 输入格式一：阶段 1 最终报告（R-01/R-02）

rulebook §3.10 报告模板中的【类别2：加载期重初始化】段。解析锚点：

- 段标题 `【类别2：加载期重初始化】`（中英文冒号均可）；
- 问题编号 `问题 #n`——整改报告原样保留（回溯依据）；
- 定位行 `📍 <文件路径>:<行号或行号范围>`；
- 缩进代码片段（📍 与 ⚠️/💡 之间、以 3 空格缩进的行）；
- ⚠️ 判定原因 / 💡 整改建议（保留供整改报告引用）。

实测样例（按 rulebook §3.10 模板构造）：

```markdown
【类别2：加载期重初始化】
问题 #1
📍 /path/to/bundle_monitor.cpp:151-159
   if (g_bundleMonitor == nullptr) {
       EventFwk::MatchingSkills matchingSkills;
       ...
       g_bundleMonitor = std::make_shared<BundleMonitorCallback>(subscribeInfo);
       EventFwk::CommonEventManager::SubscribeCommonEvent(g_bundleMonitor);
   }
⚠️ 判定原因：该全局变量在模块注册（加载）阶段执行了与模块导出功能无关的业务动作，
   内部含跨进程调用（SubscribeCommonEvent），会真实增加应用启动时间
💡 整改建议：把创建与订阅整体移到首次调用时执行（惰性初始化，通过惰性访问器实现）
```

解析结果：问题 #1 → 文件 bundle_monitor.cpp、定位 L151 → 片段首行
`if (g_bundleMonitor == nullptr) {` 判空式命中变量 `g_bundleMonitor` → AUTO。

### 2.2 输入格式二：prescan.py 输出（初筛/深析底稿）

三类行锚点。**注意：形态B 的全局赋值候选行与类别1 的信号命中行只在
`--deep` 深析底稿中出现**——非 `--deep` 输出（仅漏斗第 1-2 级 + 注册点解析）
没有这些锚点，解析结果为空（E-2 / E-8）。

（a）形态A 候选行——`## 形态A 候选…` 段内，`### <文件>` 为换文件锚点：

```markdown
## 形态A 候选（P1/P2/P3 列首 + P1ns/P2ns 命名空间区域缩进，经排除管道；深析做成本判定）

### foundation/window/window_manager/interfaces/kits/napi/window_runtime/window_stage_napi/js_window_stage.cpp
- L94 [P1] std::unique_ptr<JsWindowRegisterManager> g_listenerManager = std::make_unique<JsWindowRegisterManager>();
```

解析：`- L<行> [P1] <原始行文本>` → 声明式命中变量名（上例 `g_listenerManager`）。
`--deep` 底稿后半段的「形态A 候选工作包」段会重复同一批行——解析器按
（文件、变量、行）去重，不产生重复条目。

（b）全局赋值候选行（形态B）——`## 深析工作包` 各「链：」节点下：

```markdown
- 全局赋值候选（词法表路由 R1限定名/R2本文件/R2h头文件/R4表外；待宿主确认与成本判定——R2/R2h 附定义行可跳转核对；/exports 标记行按导出面构建排除复核）:
  - [R2表命中(本文件L38)] /path/to/code/foundation/.../bundle_monitor.cpp:157 matchingSkills); g_bundleMonitor = std::make_shared<BundleMonitorCallback>(subscribeInfo); EventFwk::CommonEventManager:
```

解析：`- [R<路由>(…)] <文件>:<行> <片段文本>` → 赋值式命中 `g_bundleMonitor`；
路由标注（R1/R2/R2h/R4）原样保留在清单「形态/信号」列——R2/R2h 附定义行，
可直接跳转核对声明。

（c）类别1 信号命中行——`## 深析工作包` 各「链：」节点下（M-19 信号表）：

```markdown
- ⚠️ 信号命中 ×11（**待语义复核**——…）：
  - [进程级回调注册/exports] /path/to/js_error_manager.cpp:1883 <JsErrorManager>(); jsErrorManager->SetRejectionCallback(env); napi_wrap(env, exportObj, jsEr…
  - [call_once块] /path/to/js_error_manager.cpp:1886 std::call_once(registerCallbackFlag, []() {
```

解析：`- [<信号类[/exports]>] <文件>:<行> <片段>`（方括号内容**不以 R+数字
开头**——与形态B 的路由行区分）→ 类别1 条目（引擎 E）。同文件多条信号行
去重为一条工作清单条目，**全部行号保留**传给引擎 `--at-line` 逐个尝试定位
回调（行可能落在辅助函数体内，如上例文件另有 L963/985 在
`SetRejectionCallback` 函数体内——均定位不到回调时 H6 转人工）。
`/exports` 标记仅提示导出面构建可能（rulebook S-03：行段混叠，不得据此
静默排除），引擎 E 靠语句级分类判定，不依赖该标记。

**路径形态与解析**：形态A 候选段的文件路径沿用扫描时的输入形态（对仓库相对目录
扫描 → 相对路径）；全局赋值候选行为绝对路径。相对路径条目需**在仓库根运行**解析器，
或加 `--root <仓库根>` 解析（实测：无 `--root` 且不在仓库根时，相对路径条目因
「文件不存在」转 MANUAL 提示人工核对；加 `--root` 后解析为绝对路径并恢复 AUTO）。

实测（真实阶段 1 扫描产出）：`prescan.py <bundle_monitor目录> --deep` 与
`prescan.py <window_stage_napi目录> --deep` 两文件输入解析器（`--root <仓库根>`），
得到 AUTO × 2（`g_bundleMonitor` 形态B / `g_listenerManager` 形态A），与人工核对一致。

### 2.3 输入格式三：`--target` 直连（无报告时的手工入口）

```
--target <文件>:<行号>[:<变量名>]
```

给变量名则直通 AUTO；不给则读该行源码文本，按 §2.4 规则解析变量名。
用途：扫描报告未覆盖的目标（含 §6 盲区目标）经 `verify_fix.py` 复扫定位后补入清单。

### 2.4 变量名解析与 AUTO/MANUAL 分流

对片段行序列逐行尝试，先命中先得（实现 = parse_scan_report.py 三个正则）：

| 顺序 | 模式 | 匹配要点 | 命中示例 |
|---|---|---|---|
| 1 | 赋值式 | `name =` + `new` / `make_xxx` / `X::GetInstance(` | `g_bundleMonitor = std::make_shared<…>` |
| 2 | 声明式 | `TYPE … name =` + 同上初始化动作 | `std::unique_ptr<M> g_m = std::make_unique<M>()` |
| 3 | 判空式 | `if (name == nullptr)`（类别2 报告条目常见首行） | `if (g_bundleMonitor == nullptr) {` |

- 解析出变量名 → **AUTO**（交引擎整改）；
- 解析不出 → **MANUAL**：典型为形态C（注册链内创建、不落全局变量，
  如 `SomeRegistry::Register(std::make_shared<X>(…))`），或报告条目文件定位失败
  （相对路径按仓库根/报告所在目录回退解析，仍失败转 MANUAL）。

### 2.5 为什么按变量名重定位、不依赖报告行号

- 报告产出与代码可能有时差（扫描后代码被改动，行号漂移）；
- 引擎拿到变量名后在**当前源码**中搜索声明 → 判定形态 → 定位全部使用点，
  报告行号仅作交叉校验；
- 该设计同时覆盖扫描正则的已知盲区（§6）——只要变量名能进入清单（报告命中或
  `--target` 补入），改写即不受扫描信号形态影响。

---

## 3. 访问器模板

### 3.1 形态A + meyers（默认；BUILD.gn 无 `-fno-threadsafe-statics`）

```cpp
// 改写前
static Database* g_db = new Database("/sandbox/db");

// 改写后（访问器原位替代声明）
static Database* GetDb()
{
    static Database* instance = new Database("/sandbox/db");
    return instance;
}
// 所有 g_db 使用点 → GetDb()
```

智能指针返回引用（保持"同一对象"语义与原全局变量一致）：

```cpp
static std::unique_ptr<JsWindowRegisterManager>& GetListenerManager()
{
    static std::unique_ptr<JsWindowRegisterManager> instance = std::make_unique<JsWindowRegisterManager>();
    return instance;
}
```

C++11 起函数局部 static 的并发初始化由实现保证（magic statics）。

### 3.2 形态A + call_once（BUILD.gn 含 `-fno-threadsafe-statics` 时自动选择）

```cpp
static Database* GetDb()
{
    static Database* instance = nullptr;   // 零初始化——不受 -fno-threadsafe-statics 影响
    static std::once_flag onceFlag;        // constexpr 构造——同上
    std::call_once(onceFlag, [] { instance = new Database("/sandbox/db"); });
    return instance;
}
```

**实测依据**（16 线程并发首次调用，20 轮）：

| 策略 | `-fno-threadsafe-statics -fno-exceptions` 下失败次数 |
|---|---|
| meyers | 14/20（实例数 >1，竞态） |
| call_once | **0/20** |

### 3.3 形态B（固定 call_once）

```cpp
// 改写后
static std::shared_ptr<BundleMonitorCallback>& GetBundleMonitor()
{
    static std::shared_ptr<BundleMonitorCallback> instance = nullptr;
    static std::once_flag onceFlag;
    std::call_once(onceFlag, [] {
        EventFwk::MatchingSkills matchingSkills;
        ...（初始化体整块，原变量名 → instance）
        instance = std::make_shared<BundleMonitorCallback>(subscribeInfo);
        EventFwk::CommonEventManager::SubscribeCommonEvent(instance);
    });
    return instance;
}
```

- 注册回调中初始化块整体删除，回调只保留 exports 构建；
- 初始化体内的 `g_x` 全部替换为 `instance`（mask-aware：字符串/注释内同名文本不动）；
- `#include <mutex>` 不存在时自动插入（编译必需）。

### 3.4 备选：首业务入口创建（方案二，人工适用）

当初始化参数依赖运行时上下文（如接口参数、ability context）时，访问器无法承载
（见 G4）——此时把"创建"移到**第一个业务接口**内部，用 `std::lock_guard` +
判空（或 `std::call_once`）保证幂等与并发首调安全——**先加锁后判，禁止裸判空**
（无锁的 `if (p == nullptr)` 在并发首调下会重复创建/竞态）：

```cpp
napi_value Register(napi_env env, napi_callback_info info)
{
    ...
    std::lock_guard<std::mutex> lock(g_monitorLock);
    if (g_bundleMonitor == nullptr) {
        g_bundleMonitor = std::make_shared<BundleMonitorCallback>(BuildSubscribeInfo(env));
        EventFwk::CommonEventManager::SubscribeCommonEvent(g_bundleMonitor);
    }
    ...
}
```

适用条件：所有使用点已判空短路、**判空均在锁内**（或改用 call_once）、初始化数据
可从首个调用获取。
默认不采用（需求原文指定"所有调用处改惰性初始化"）；G4 拒绝时向用户提示此方案。

---

## 4. 安全闸门（G1–G8）

任一失败 → 拒绝改写并列出人工指引（`--force` 例外，输出持续警示）。

| 闸门 | 检查 | 失败后果（若强行改写） |
|---|---|---|
| G1 | 除检测到的初始化外无其他写入点（`g_x =`/`++`/`+=`） | 访问器无法承载重置/重建语义，状态机破坏 |
| G2 | 函数内无同名局部声明（遮蔽） | 局部/全局引用错乱，改写后语义漂移 |
| G3 | 声明非 `extern`；无 `static` 的外部链接变量须 `--root` 交叉检查无跨文件引用 | 删掉外部符号导致其他 TU 链接失败 |
| G4 | 形态B 初始化体不引用回调参数/局部变量（env/exports/局部对象）、不含 return/break/continue | 初始化体无法搬迁（环境不可复现 / 控制流改变） |
| G5 | 裸指针 / unique_ptr / shared_ptr；非 thread_local、非类静态成员、非数组 | 模板不适用，改写后类型/语义错误 |
| G6 | 无取变量地址（`&var` 不接 `->`/`.`）、无 `delete var` | `&GetX()` 取临时地址——编译失败；delete 语义无法保留 |
| G7 | 访问器名无冲突；使用点均在声明之后 | 重定义冲突 / 使用先于定义——编译失败 |
| G8 | 形态A 初始化为单一语句 | 多语句初始化无法内联进访问器 |

**`&var` 与 `&var->member` 的区别**：`&g_db->source` 是成员地址，改写为
`&GetDb()->source` 合法；`&g_db`（取指针变量自身地址）改写为 `&GetDb()`
是取函数返回值临时对象的地址——编译失败。G6 仅拦截后者。

**改写后自校验**（脚本内置）：

1. 旧变量名残留引用 = 0（访问器外不得出现）；
2. 括号配平与改写前一致；
3. `--check`：`clang++`/`g++ -fsyntax-only`（缺系统头文件的 "file not found" 视为环境限制）。

---

## 5. 人工整改指引（MANUAL 条目与闸门拒绝项）

### 5.1 形态C：注册链内创建、不落全局变量（解析不出变量名）

扫描深析判定的「注册链内创建且不落全局变量」（如
`SomeRegistry::Register(std::make_shared<X>(…))`）——引擎无变量可改写：

- 创建语句整体移到**首个业务导出函数**内部，用 `std::call_once` 或
  `std::lock_guard`+判空（双检锁）保证幂等与并发首调安全——**禁止裸判空**
  （同 §3.4 方案二）；
- 或改挂到**显式 init 导出接口**（`xxx.init()` 由 ArkTS 侧显式调用），适合需要
  传参/上下文的场景；
- 注册链上仅保留 registry 结构本身（如确需注册框架钩子，评估轻量豁免）。

### 5.2 多写入点（G1）

存在显式重置/重建逻辑（`g_x = nullptr;`、`g_x = new X;` 二次赋值）：

- 保留全局变量与全部写入点，只把**加载期那次**初始化移除（形态B：删除回调内赋值；
  形态A：初始化器置 `nullptr`）；
- 在每个业务入口用 `std::lock_guard` + 判空（或 `std::call_once`）惰性创建
  （方案二，**禁止裸判空**——并发首调会重复创建/竞态），或按业务语义设计状态机；
- 判空检查保留原语义（创建可能失败的路径仍需要短路——失败路径见 §8.11 失败契约）。

### 5.3 外部链接共享变量（G3）

其他 TU 引用同一变量（典型：头文件 `extern` 声明）：

- 把全局变量改为**头文件内 `inline` 访问函数** + .cpp 内函数局部 static：

```cpp
// xxx.h
inline Database* GetDb()   // C++17 inline 函数，多 TU 共享同一实例
{
    static Database* instance = new Database("/db");
    return instance;
}
```

- 删除原 `extern` 声明与定义，所有 TU 的使用点改经访问器（与自动模板同法）。

### 5.4 类静态成员（G5）

```cpp
// 改写前：CameraManager::g_cameraManager 在类外/成员处加载期创建
// 改写后：私有静态访问器成员（保持类内封装）
class CameraManager {
public:
    static CameraManager* GetInstance()
    {
        static CameraManager* instance = new CameraManager();
        return instance;
    }
private:
    CameraManager() = default;
};
```

### 5.5 引用型 / 数组 / thread_local（G5）

- 引用型（`T& g = T::GetInstance();`）：改写为函数内 `static T& instance = T::GetInstance();`
  并评估 GetInstance 本身是否加载期重操作（是 → 该工厂本身需要惰性化，转人工）；
- 数组：逐元素评估，通常转容器 + 访问器；
- thread_local：确认初始化是否已发生在每线程首用（多数已是目标形态，无需整改）。

### 5.6 初始化体引用回调环境（G4）

初始化依赖 `env`/`exports`/回调局部对象 → 访问器无法在业务调用点复现环境 →
采用方案二（首业务入口创建，参数来自首调）。

---

## 6. 输入盲区与补充定位（阶段 1 prescan P1 已知盲区）

prescan 的 P1 正则对类型-变量分隔符只接受「星号紧贴类型」（`Type* name`）
或「纯空格」（`Type name`）；**`Type *name`（空格+星号，星号紧贴变量名）不匹配**：

```cpp
static ImagePictureNative *g_thisPicture = new ImagePictureNative();   // P1 不命中 → prescan 报 0 候选
static ImagePictureNative* g_thisPicture = new ImagePictureNative();   // P1 命中
```

实测（openharmony master 快照）：

| 文件 | 声明风格 | prescan 形态A 候选 | verify_fix.py 复扫 |
|---|---|---|---|
| applications/…/photomodify/src/main/cpp/Image.cpp:46 | `ImagePictureNative *g_thisPicture` | 0 个（链干净） | 命中 1 个（形态A） |

**影响**：仅扫描报告/prescan 输入可能缺此类目标；不影响引擎改写能力
（§2.5——按变量名重定位）。

**补充定位流程**（扫描报告疑似不全时）：

```bash
# 1. 用本技能验证端对该模块目录复扫（独立实现，覆盖 Type *name 风格）
python3 scripts/verify_fix.py <模块目录>          # 输出候选（含盲区目标）

# 2. 把复扫命中的目标补入整改清单（文件:行:变量名）
python3 scripts/parse_scan_report.py <扫描产出> --target <文件>:<行>:<变量名> [--fix …]
```

注意：`verify_fix.py` 在此仅作补充定位；**问题发现的主责仍在阶段 1 扫描**（回归验证
是它的主用途——整改后复扫确认清零）。

---

## 7. 语义等价论证（整改正确性依据）

| 维度 | 改写前 | 改写后 | 结论 |
|---|---|---|---|
| 分配次数 | 加载时 1 次 | 首用时 1 次 | 等价 |
| 地址稳定性 | 全局变量地址 | 函数局部 static 地址（首次确定后不变） | 等价 |
| 裸指针生命周期 | 永不 delete（原样） | 永不 delete | 等价 |
| 智能指针生命周期 | 进程静态析构期释放 | 进程静态析构期释放 | 等价 |
| 首用线程安全 | 加载期单线程（loader 锁） | magic statics / call_once 串行化 | **增强** |
| 创建时机 | import（启动路径） | 首次业务调用 | **目标变更** |
| 注册回调内行为 | 创建+订阅 | 仅 exports 构建 | 目标变更（依赖动作随初始化体迁移，首次调用时执行） |

**已知影响（如实向用户说明）**：

1. 注册回调中初始化失败日志/分支不再在加载期出现——首用路径必然执行初始化
   （原"环境未就绪"短路分支成为不可达代码，可保留或后续清理）；
2. 订阅类动作（如 SubscribeCommonEvent）从"import 时生效"变为"首次调用接口时生效"
   ——业务上等价（无接口调用则无事件消费），需在验证清单确认；
3. 单例仍是进程级单例：页面间可变状态残留不属于本项解决范围（需移除可变状态，另行设计）；
4. **构造抛异常的时点改变**（引擎 L 对同文件构造体含 `throw` 的类型输出行为差异
   警示）：原 import 即抛（进程启动失败），整改后首次业务调用才抛——崩溃时点与
   表现不同；首调点若需承接异常，按 §8.11 失败契约补 napi_throw_error 上抛；
5. **析构时点后移**（引擎 L 对析构体含 `napi_*` 的类型输出生命周期警示）：整改后
   实例为函数级静态，析构由 `__cxa_atexit` 在进程退出时触发，可能晚于 napi env
   死亡（`DeconstructCtxEnv → SetDead`）——env 死亡后调用 `napi_*` 即悬空使用，
   见 §10 生命周期警示。

---

## 8. 类别1整改模式（注册回调业务初始化 → 显式 init() 导出）

### 8.1 问题定义与判定口径（对齐 rulebook）

**规范原文**：`nm_register_func` 的 Init 函数尽量只做函数映射，不要做业务初始化；
业务初始化挪到显式导出 `init()` 接口，由 ArkTS 侧在首次使用本模块其他接口前
调用一次。

判定口径（rulebook）：

| 规则 | 内容 | 引擎 E 落地 |
|---|---|---|
| S-01 锚点 | 与构建 exports 无关——删除后 exports 构建不受影响 → 类别1 候选 | 分类阶段逐语句判定 |
| S-02 动作族 | 信号/事件注册、线程操作、进程级注册、外部服务/IPC、其他业务动作 | MOVE 信号与动词族 |
| S-03 排除 | `napi_property_descriptor` 声明与挂载、`napi_create_function`/`napi_define_class`/`napi_set_named_property`/`napi_wrap`/`napi_get_cb_info`/`napi_create_object`、挂到 exports 的对象创建、`return exports` | KEEP |
| M-19 信号表 | 线程创建/动态库加载/文件IO/环境变量/连接/信号处理器/事件循环 attach/进程级回调注册/call_once 块/OHOS 域（SAMGR/IPC 等） | MOVE 首要证据 |
| M-23 | /exports 标记行（导出面构建） | KEEP（但行段混叠时不得静默排除——靠语句级分类而非行标记） |
| S-08 轻量 | 轻量动作不计问题 | 分类未命中的语句保守保留（不算 MOVE） |

> 注：S-02 动作族与 M-19 信号表是**候选线索**，不是成本结论。本技能阶段 1 扫描将"纯 `signal`/`sigaction` 注册（仅函数指针/POD/系统调用）"判为轻量（S-08 口径① + S-09 速查表），此类项**不会出现在扫描报告的问题清单中**——模块结论为 `✅ NAPI OK`。§8.2 的 MOVE 默认与 E-15 的保留信号分流仅在**直接 `--target` 定向整改**时生效，属保守安全策略，不代表扫描阶段认定其为问题。

**与类别2（形态B）的分界**：回调内**全局变量赋值**（`g_xxx = …`）归类别2
（引擎 L 惰性化该守卫块）；回调内**其余业务动作**（函数调用/注册/线程/IPC）
归类别1（引擎 E 迁 init()）。

### 8.2 语句级分类规则（引擎 E 核心）

对注册回调函数体**逐语句**分类（语句含其前导注释；块语句
（if/for/call_once 块）整体为一个单元）：

| 分类 | 判定（按序，先命中先得） | 处置 |
|---|---|---|
| KEEP | ① 空/注释/return ② env/exports 判空守卫 ③ napi 导出面 API（S-03 全集 + `DECLARE_NAPI_*`/`NAPI_CALL`/`BindNativeFunction`/`GET_CB_INFO_AND_CALL`）④ 实参含 exports 的调用（`XxxProxy::Init(env, exports)` 惯用法）⑤ 日志（`*_LOG*`/`HILOG`/`OH_LOG_Print`）⑥ 含 return/break/continue（H3）⑦ 引用 KEEP 声明的局部变量（exports 数据流——枚举对象等）⑧ 被调函数体（同文件可解析）只含 napi 面 API 且无业务信号（如 `Register*JSClass` 内部是 `napi_define_class`） | 保留原位 |
| MOVE | 命中 M-19 信号或业务动词族（Init/Create/Register/Subscribe/Attach/Start/Setup/Load/Connect/Prepare/Warm/Preload/Enable/Open），且被调体（同文件可解析时）含业务信号/无导出面 API，且无 KEEP 依赖 | 迁入 init()（verbatim 原样搬迁） |
| SKIP_FORMB | 全局赋值语句/块（`g_xxx = …`） | 分流引擎 L（§3.3 模板） |
| 纠缠 | MOVE 候选引用了 KEEP 声明的局部变量（如 `napi_wrap` 对象的成员方法调用）；或 MOVE 声明的局部变量被回调内其他语句引用（纠缠簇） | 保留原位 + §9 人工指引 |
| 未命中（?） | 以上全不中（S-08 轻量口径） | 保守保留 + 待复核提示 |

**两个真实判定修正**（全仓 23953 文件扫描实测得出）：

1. `XxxProxy::Init(env, exports)` / `Create*Type(env, local)` 这类**带 exports
   或 exports 数据流实参**的调用是导出面构建惯用法（S-03 豁免）——初版按
   动词族误判 MOVE，修正后 97 个误报收敛到 16 个真实案例；
2. 被调函数体必须**检查内容**：nfc 的 `RegisterNfcAJSClass(env)` 名字带
   Register，但内部是 `napi_define_class`（导出面构建）→ KEEP；
   ImageEffect 的 `RegisterCustomBrightness()` 内部是业务注册 → MOVE。

### 8.3 init() 导出模板（三种注册风格自动挂载）

**风格一：描述符数组**（`napi_property_descriptor desc[] = { … }`，
`napi_define_properties` 挂载）——挂载行插入数组收尾 `};` 前：

```cpp
napi_property_descriptor desc[] = {
    {"PixelMapFilterStart", nullptr, ImageEdit::PixelMapFilterStart, …},
    …
    DECLARE_NAPI_FUNCTION("init", ExplicitInit),   // ← 自动插入
};
napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
```

**风格二：BindNativeFunction**（js_runtime_utils 惯用法）——挂载行插入
最后一个 BindNativeFunction 完整语句后：

```cpp
const char *moduleName = "JsErrorManager";
BindNativeFunction(env, exportObj, "on", moduleName, JsErrorManager::On);
BindNativeFunction(env, exportObj, "off", moduleName, JsErrorManager::Off);
BindNativeFunction(env, exportObj, "init", moduleName, ExplicitInit);  // ← 自动插入
```

**风格三：napi_create_function + napi_set_named_property**——挂载块插入
`return` 行前：

```cpp
napi_value initFn = nullptr;                                          // ← 自动插入
napi_create_function(env, "init", NAPI_AUTO_LENGTH, ExplicitInit,
    nullptr, &initFn);                                                // ← 自动插入
napi_set_named_property(env, exports, "init", initFn);                // ← 自动插入
return exports;
```

**新函数模板**（默认；`--no-once` 去掉 call_once 包装）：

```cpp
// 业务初始化（原位于注册回调 Init L24——类别1：注册函数违规业务逻辑）。
// 由 ArkTS 侧在首次调用本模块其他接口前显式调用一次 init()。
static napi_value ExplicitInit(napi_env env, napi_callback_info info)
{
    static std::once_flag onceFlag;
    std::call_once(onceFlag, [&] {
        // ← 迁移语句（verbatim 原样搬迁，整体缩进 4 空格）
    });
    napi_value result = nullptr;
    napi_get_undefined(env, &result);
    return result;
}
```

要点：

- **verbatim 原样搬迁**：迁移语句不做语义改写（模板/调用/参数一字不动），
  保证编译正确性与行为等价；仅整体缩进一级；
- **call_once 包装**：原语句在加载期恰好执行一次；迁为显式接口后调用方可能
  调多次/并发首调——`std::once_flag`（函数级 static）保持「恰好一次」
  （幂等 + 并发安全）；`#include <mutex>` 自动补齐；
- 原本就在 `std::call_once` 内的语句（如 js_error_manager 的注册块）会形成
  双层 call_once——语义不变；介意可用 `--no-once` 关掉外层；
- 函数名默认 `ExplicitInit`（冲突自动加序号）；导出名默认 `init`
  （冲突自动重试 initModule/moduleInit/lazyInit）。

### 8.4 安全闸门（H1–H7；任一失败拒绝改写）

| 闸门 | 检查 | 失败行为 |
|---|---|---|
| H1 | 存在至少一条 MOVE 语句 | 「回调已是仅函数映射」——幂等重跑的正常输出，不改写 |
| H2 | 迁移语句不引用 exports 参数/KEEP 局部变量 | 分类阶段已把引用项分流为纠缠保留 |
| H3 | 迁移语句不含 return/break/continue | 该语句降级 KEEP |
| H4 | `init` 导出名/C++ 函数名无冲突 | 自动换名；全冲突拒绝 |
| H5 | 注册风格可识别（三种之一） | 人工挂载指引 |
| H6 | 回调可定位（--callback/--at-line/nm_register_func）且函数体可完整提取 | 退出码 2，转人工（如信号行落在辅助函数体内） |
| H7 | 改写自校验：花括号配平、迁移语句零丢失（全部进新函数）、回调区零残留、init 挂载就位、call_once 包装就位、`<mutex>` 包含 | 退出码 5，拒绝写入 |

### 8.5 策略矩阵（显式 init() 的适用边界）

| 模块类型 | 判据 | 策略 E 适用性 | 理由 |
|---|---|---|---|
| 应用工程内模块 | `nm_modname == "entry"` / libentry.so | ✅ 安全推荐 | 调用方在同工程，JS 侧同步修改即可闭环 |
| 系统/公共 kit | `nm_modname` 含 `.`（如 `bundle.bundleManager`） | ⚠️ API 兼容性破坏 | 消费方为任意已发布应用，不会主动调 `init()` → 迁移后业务初始化永不执行。建议：① 改用策略 L（引擎 L，不改 API）；② 版本演进中引入 `init()` 且保留惰性兜底 |

引擎对系统 kit 输出兼容性警示后**可继续改写**（适用于工程内部消费/样例场景），
警示必须进入整改报告。

**场景1/2 分叉判定**（同一文件两类问题并存时选哪个）：若回调内的问题语句只是
**构造类**（`g_x = new X` / `if (g_x == nullptr) {…}` 守卫块）而没有其他进程级
动作，优先策略 L（类别2 → 惰性访问器）——零 API 变更、零 JS 改动、天然向后
兼容；仅当存在**非构造类进程级动作**（信号注册、事件挂接、异步任务提交等类别1
语句）或初始化需要调用方传参/选时机时，才需要策略 E（显式 init()）。两者可组合
（先 L 后 E，§8.6）。

### 8.6 组合规则：先 L 后 E

同一文件既有类别2（全局赋值守卫块）又有类别1（其余业务语句）时：

```
1. 引擎 L：守卫块 → call_once 惰性访问器（回调内 `if (g_xxx == nullptr) {…}`
   整块迁出，改写为 `Get*()` 访问器 + 首用创建）
2. 引擎 E：回调内剩余业务语句 → 迁 init() 导出
```

批量驱动（parse_scan_report.py --fix）固定按 L→E 顺序执行；手工执行也必须
先 L 后 E（引擎 E 的 SKIP_FORMB 分类会把全局赋值留给引擎 L；顺序颠倒时
引擎 E 可能把守卫块内部语句当业务动作迁走，破坏守卫结构）。

### 8.7 幂等性与语义等价

| 维度 | 改写前 | 改写后 | 结论 |
|---|---|---|---|
| 执行次数 | 加载期恰好 1 次 | `init()` 首调 1 次（call_once） | 等价 |
| 执行时机 | import（dlopen） | ArkTS 侧首次显式调用 | **目标变更**（JS 集成必做） |
| 重复调用 | 不可达（加载仅一次） | 幂等（call_once 短路） | **增强** |
| 并发首调 | 加载期单线程 | call_once 串行化 | **增强** |
| 语句内容 | — | verbatim 搬迁 | 等价（token 级不变） |
| 导出面 | 原接口集合 | 原接口 + `init` | **目标变更**（新增导出） |
| 加载期副作用 | 业务初始化执行 | 零（仅函数映射） | **目标达成** |

**幂等性验证**：对已整改文件重跑引擎 E → `H1 无可迁移语句`（不重复改写）；
重复调用 `init()` → 计数器不增（合成测试 25/25 断言之一，含 8 线程并发
首调恰好一次——F 组，real-cases.md §9）。

### 8.8 ArkTS 侧集成（必做人工步骤）

引擎 `--js-root <ArkTS目录>` 定位 import 点（`import xxx from 'libentry.so'`
/ `import … from '@ohos.<module>'`），输出「首次调用其他接口前补
`xxx.init()`」指引——**不自动改 JS 代码**（调用时序是业务决策：页面
onLoad / 首接口调用前 / 应用启动任务）。

集成模式：

```ts
import imageEffect from 'libentry.so';

// 模式一：页面/Ability 加载时（推荐——时序明确）
onPageShow() {
    imageEffect.init();          // 幂等，多个页面重复调用无害
}

// 模式二：首次业务调用前
imageEffect.init();
imageEffect.PixelMapFilterStart(…);
```

漏做的后果：**编译不受影响，运行期业务功能不初始化**（信号不注册/单例
不创建/事件不可达）——回归验证清单必须包含运行期 4 项检查（§步骤 4）。

**两族调用义务**（决定 `init()` 放哪个时机的判定依据，完整判定见 §8.11）：

- **时机敏感族（P1）**：存在业务接口，其首调若早于 init() 动作完成则功能失效
  （如信号处理器注册晚于信号到达）→ `init()` 必须放在**第一个依赖它的接口调用
  之前**；跨 worker 时每个使用方都要保证先 init；
- **迟到无害族（¬P1）**：任何顺序下最终状态一致（如缓存预热）→ 仍必须调用，
  但时序自由。拿不准按 P1 处理（更保守）。

**env 线程纪律**：`init()` 在模块首次 import 的同一线程调用（通常主线程），
勿从 worker 调用——迁移的 napi_* 语句跟随 init() 的调用线程，跨线程用 env 是
未定义行为（§10.3）。

### 8.9 引擎 E 输入定位（--callback / --at-line）

| 定位方式 | 适用 | 行为 |
|---|---|---|
| `--callback <名>` | 显式指定注册回调（跨文件注册必用：`nm_register_func` 在模块结构文件、回调定义在业务文件，如 js_error_manager.cpp 的 `JsErrorManagerInit`） | 按名定位 `(napi_env, napi_value)` 函数 |
| `--at-line <行[,行…]>` | 消费扫描产出（prescan 信号命中行/R-02 行号）；**可逗号分隔多个**——行可能落在辅助函数体内（如 js_error_manager 的 L963/985 在 `SetRejectionCallback` 体内），引擎逐个尝试定位包含该行的 `(napi_env, napi_value)` 函数 | 命中即用；全部失败 → H6 转人工 |
| 默认 | 文件内 `nm_register_func` 首个目标 | 常规单回调文件 |

### 8.10 保留信号第三出口（signal/sigaction 语句）

> **阶段边界（重要）**：本节分流仅在**阶段 2 整改**（`--target` 定向整改或 `--fix` 批量驱动引擎 E）时生效。阶段 1 扫描中，纯 `signal`/`sigaction` 注册（仅函数指针/POD/系统调用）按 S-08 口径① + S-09 速查表判**轻量 → 不计问题 → `✅ NAPI OK`**，不会进入整改流程。本节的信号号分流是对**已被判定需整改的语句**做安全迁移决策，不代表扫描阶段将其认定为问题。

**背景**：musl 在实时信号段划出保留段，ArkUI/ArkTS 运行时在框架层占用其中若干
信号（本快照实测证据）：

| 保留集 | 值 | 仓内证据 |
|---|---|---|
| musl 保留段 | `MUSL_SIGNAL_*` = SIGRTMIN+0..+10 | `third_party/musl/porting/linux/user/include/signal.h`（JSHEAP=+4、RECYCLE_JEMALLOC=+8、MEMCHECK=+9、FDTRACK=+10） |
| 框架占用（具名） | `sigaction(MUSL_SIGNAL_JSHEAP, …)` | `foundation/arkui/ace_engine/frameworks/core/common/ace_engine.cpp:113-120`（InitJsDumpHeadSignal，JS 堆转储） |
| 框架占用（字面量） | `constexpr int32_t SIGNAL_FOR_GC = 60` | `foundation/arkui/ace_engine/frameworks/core/common/watch_dog.cpp:41`（GC 看门狗） |
| Linux 实时信号段 | SIGRTMIN(34)..SIGRTMAX(64) | musl/Linux 通用约定，整段视为保留 |

**为什么不能机械迁移**：把 `signal(60, h)` 迁到 init() 会把注册时点从 import 推迟
到首调；若同进程框架（或另一业务模块）已/将注册同号信号，两者**静默互相覆盖**
（`signal()` 返回旧 handler、无任何报错）——这类冲突运行期极难排查。

**引擎分流**（v3.1.0 起，边界 E-15）：

| 信号号可解析性 | 判定 | 引擎行为 |
|---|---|---|
| 可解析且命中保留段（字面量 34..64 或 60；`SIGRTMIN+n`；`MUSL_SIGNAL_*`；同文件 `constexpr/#define X = 保留值`） | **保留信号** | 该语句降级 KEEP（不迁移），输出第三出口指引 |
| 可解析且非保留段（标准信号如 SIGPIPE/SIGUSR1/2、字面量 1..31） | 普通信号 | 保持 MOVE，附「确认无跨组件同信号注册」提示 |
| 不可静态解析（变量/宏/系统头定义） | 未知 | 保持 MOVE + 显著警示 + ArkTS 冲突核对义务 |

**第三出口的裁决问题**：保留信号语句不是"迁/不迁"的机械问题，而是设计问题——
**谁有权注册这个信号**？处置选项：

1. **保留在注册回调**（接受加载期注册——signal/sigaction 调用本身轻量，S-08
   口径下可豁免）；
2. **改注册时机**：与信号生产方约定握手顺序后再注册（需跨模块设计评审）；
3. **让渡给框架**：业务信号语义若与框架能力重叠，评估用框架接口替代私有信号。

选项 1/2 仍在本技能边界内（人工执行），选项 3 属框架演进。引擎不做选择，
把裁决权交给设计评审——这正是"第三出口"（第一出口＝迁 init()，第二出口＝
保留原位豁免，第三出口＝转设计评审）。

### 8.11 失败契约与两族（P1 时序谓词）

**引擎行为（如实声明）**：引擎 E 的迁移是 verbatim 的——原语句在注册回调里
**忽略返回值**（`RegisterXxx();`），迁移后同样忽略：

- 原代码：import 时执行，失败仅打日志（或完全静默）——注册回调**没有上抛通道**
  （不能向引擎抛异常）；
- 整改后：init() 首调时执行，失败同样静默返回 undefined——**失败契约与原来
  一致（都吞掉）：没有变差，也没有变好**。

**已知缺口**：调用方无法感知 init() 失败——重试、降级、报错都无从谈起。可以
人工升级（模板如下），但**引擎不做**（改写返回值处理会破坏 verbatim 保证）：

```cpp
// 失败契约升级模板（人工，可选）——把 void 动作包成可失败动作：
static bool EnsureBusinessInitActions()
{
    static std::once_flag once;
    static bool ok = false;
    std::call_once(once, [] { ok = RegisterXxx() && SetupYyy(); });
    return ok;
}
static napi_value ExplicitInit(napi_env env, napi_callback_info info)
{
    if (!EnsureBusinessInitActions()) {
        napi_throw_error(env, "ERR_INIT", "business init failed");  // 上抛调用方
        return nullptr;
    }
    napi_value result = nullptr;
    napi_get_undefined(env, &result);
    return result;
}
```

升级后 ArkTS 侧获得 try/catch 通道（失败可感知、可重试——重试语义归调用方）；
调用契约从「init() 必成功」变为「init() 可能抛，调用方处理」。

**两族（P1 时序谓词）**——判定 init() 动作对时序的敏感性：

| 族 | 定义 | init() 调用义务 |
|---|---|---|
| 时机敏感族（P1） | 存在业务接口，其首次调用若早于 init() 的动作完成，功能失效或行为不完整（信号处理器注册晚于信号到达、监听注册晚于事件发布） | 必须在第一个依赖接口之前调用；跨 worker 场景每个使用方都要先 init |
| 迟到无害族（¬P1） | 任何顺序下最终状态一致（动作只是「还没做」，如缓存预热、延迟订阅） | 仍必须调用（否则永不初始化），但时序自由 |

判定方法：逐个 init() 动作问「如果首个业务调用先于它发生会怎样」——出错/
丢事件 = P1；稍晚完成但结果一致 = ¬P1。**拿不准按 P1 处理**（更保守）。

### 8.12 napi_onLoad 划界（为什么不用它做 init）

模块管理器支持 .so 导出 `napi_onLoad` 符号，在 dlopen 后、注册回调
（nm_register_func）前被调用（`native_module_manager.cpp:1408` 查找并执行；
原型 `typedef void (*NapiOnLoadCallback)()`——**无参、无返回**，
`native_module_manager.h:56`）。它与注册回调一样在加载路径上执行，**同样不能
承载业务初始化**——官方规则「不要在 nm_register_func 中执行重初始化或阻塞操作」
（`foundation/arkui/napi/docs/knowledge/module-manager.md`）对 napi_onLoad 同样
适用。

| 候选载体 | 能否承载业务初始化 | 理由 |
|---|---|---|
| `napi_onLoad` | ❌ | 加载路径上执行（只是比注册回调早一步，冷启动成本一点没省）；无参无返回，接不到调用方上下文 |
| `nm_register_func`（注册回调） | ❌ | 本需求整改对象（类别1） |
| 显式 `init()` 导出 | ✅ | 调用方选时机、可传参、可感知失败（§8.11 升级模板）——需求指定的形态 |

常见误解：「把业务初始化从 Init 挪到 napi_onLoad 算不算整改？」——**不算**。
执行时点仍在 import 路径上，只是换了个函数装。真正的整改只有两条路：惰性访问器
（类别2/策略 L）或显式 init()（类别1/策略 E）。

---

## 9. 纠缠语句人工整改指引（引擎 E 保留原位的部分）

引擎 E 对**纠缠语句不自动迁移**（自动拆分会破坏编译正确性），输出定位与
指引后由人工整改。两种纠缠形态：

### 9.1 形态一：业务动作依赖 exports 挂载对象

**典型案例**（js_error_manager.cpp）：

```cpp
napi_value JsErrorManagerInit(napi_env env, napi_value exportObj)
{
    std::unique_ptr<JsErrorManager> jsErrorManager = std::make_unique<JsErrorManager>();
    jsErrorManager->SetRejectionCallback(env);        // ← 业务动作，但依赖上面
    napi_wrap(env, exportObj, jsErrorManager.release(), JsErrorManager::Finalizer, …);
    …
}
```

`SetRejectionCallback` 是业务动作（内部 `napi_set_promise_rejection_callback`，
M-19 信号），但它操作的是**挂到 exports 的 `napi_wrap` 对象**——迁走后
`init()` 里没有这个对象，编译可过但行为断裂（未初始化的包装对象）。

**人工处理方式 A（推荐）：移入首个业务导出函数**（`std::lock_guard` + 标志位，
先加锁后判；或 `std::call_once`——两者等价，**禁止裸判空**）：

```cpp
static std::mutex g_initMutex;
static bool g_rejectionInited = false;

static napi_value On(napi_env env, napi_callback_info info)
{
    std::lock_guard<std::mutex> lock(g_initMutex);
    if (!g_rejectionInited) {
        JsErrorManager* mgr = nullptr;
        napi_unwrap(env, <jsThis>, reinterpret_cast<void**>(&mgr));  // 取包装对象
        if (mgr != nullptr) {
            mgr->SetRejectionCallback(env);
        }
        g_rejectionInited = true;
    }
    …  // 原业务逻辑
}
```

**人工处理方式 B：移入 init() 实现内，以不依赖 exports 的方式重建**——
把 `SetRejectionCallback` 的逻辑改为静态/进程级实现（不经过 napi_wrap 对象），
再在 `ExplicitInit` 内调用。适用于该动作本不需要挂在对象上的场景。

### 9.2 形态二：纠缠簇（MOVE 声明的局部变量被回调内其他语句引用）

**典型案例**（bundle_manager native_module.cpp）：

```cpp
static napi_value BundleManagerExport(napi_env env, napi_value exports)
{
    …  // 导出面构建（KEEP）
    auto task = []() {
        RegisterClearCacheListener();                 // 业务动作（重活）
    };
    ffrt::submit(task);                               // 提交异步任务
    void* key = reinterpret_cast<void*>(ClearCacheListener::HandleCleanEnv);
    napi_add_env_cleanup_hook(env, ClearCacheListener::HandleCleanEnv, key);
    return exports;
}
```

`auto task = …` 命中信号（块内 `Register*Listener`）→ MOVE 候选；但 `task`
被 `ffrt::submit(task)` 引用——**只迁 lambda 声明会留下悬空引用（编译失败）**。
引擎的簇规则：引用方同为 MOVE（本例 `ffrt::submit` 命中 M-19 信号）时
**整簇一起迁**（task + ffrt::submit 两条 MOVE，实测 bundle_manager 即此路径，
自动完成）；引用方不是 MOVE（未命中信号/属 KEEP）时**整簇降级保留** +
本节指引——防止迁走声明后留下悬空引用。

**人工处理**（降级保留的簇）：把 `task` 声明、`ffrt::submit` 及其依赖整体
剪贴到 `ExplicitInit` 的 call_once 块内（保持语句顺序）；确认迁移后回调内
无残留引用（`task`/`key` 等）。

### 9.3 验证要点（纠缠语句人工整改后）

- [ ] 回调内被迁走的局部变量无残留引用（编译器会抓——悬空标识符）；
- [ ] exports 挂载对象的生命周期语义未变（napi_wrap/finalize 配对完整）；
- [ ] `verify_fix.py --callback <回调名>` 类别1 残留清零；
- [ ] 运行期：init() 调用后纠缠部分对应的业务功能生效（如 Promise 拒绝
      回调实际可达）。

---

## 10. 范围边界与警示（两个引擎共用，v3.1.0 新增）

### 10.1 框架实现路径黑名单（边界 E-14，硬拒改）

以下路径的加载期动作属**框架自身的生命周期设计**，不是业务初始化违规；两个引擎
命中即硬拒改（引擎 E 退出码 4 / 引擎 L 退出码 6），不做任何改写：

| 黑名单路径 | 框架角色 | 为什么不能按业务模型整改 |
|---|---|---|
| `ace_engine/advanced_ui_component/*/interfaces/` | ArkUI 高级组件接口 | 组件注册是框架启动序列的一部分（组件框架按需加载/注册 UI 组件） |
| `arkcompiler/ets_runtime/` | ArkTS 运行时 | 引擎全局状态的构造顺序是 VM 初始化设计约束 |
| `foundation/arkui/napi/native_engine/` | NAPI 引擎实现 | env 生命周期/清理钩子（DeconstructCtxEnv → RunCleanupHooks → SetDead，`ark_native_engine.cpp:716/719/733`）按引擎时序设计 |
| `foundation/arkui/napi/module_manager/` | 模块管理器 | 模块注册链本身（`napi_onLoad` 查找/调用即在此，§8.12）——整改对象的管理者 |

实证（本快照）：`ace_engine.cpp:113-120` 在加载期 `sigaction(MUSL_SIGNAL_JSHEAP)`
注册 JS 堆转储——这正是**框架有权在加载期做的事**；同一动作出现在业务模块里
就是类别1 问题（§8.10 第三出口降级它）。黑名单就是把这条界线编码进引擎。

框架路径如确需整改（如 ace_engine 自身启动优化），属框架演进，走框架负责人
评审——不适用本技能的业务整改模型（显式 init() 会破坏框架启动时序的隐含契约）。

### 10.2 生命周期警示（引擎 L，只警示不阻断）

引擎 L 在闸门通过后仍会输出两类启发式警示（同文件、按目标变量类型扫描），提示
**惰性化改变对象时序**的衍生风险，由人工核对（同时进入引擎 L 的已知影响 §7）：

| 警示 | 触发 | 风险机理 | 人工核对 |
|---|---|---|---|
| 生命周期警示 | 同类型析构函数体含 `napi_*` | 惰性化后实例为函数级静态，析构经 `__cxa_atexit` 在进程退出触发，**可能晚于 napi env 死亡**（`ark_native_engine.cpp:716` DeconstructCtxEnv → `:733` SetDead）——env 死亡后调 `napi_*` 即悬空使用 | 析构是否依赖 env/句柄；若是，析构改为不触 env，或用 `napi_add_env_cleanup_hook` 在 env 死亡前清理 |
| 行为差异警示 | 同类型构造函数体含 `throw` | 异常时点从 import（启动期失败，必现）移到首次业务调用（首调才崩） | 首调点异常契约：需承接则按 §8.11 失败契约模板上抛 `napi_throw_error` |

**为什么只警示不阻断**：两类风险都依赖语境（该析构是否真会在 env 死亡后运行、
抛出的异常原本是否有意义），引擎无法静态判定严重性；闸门拦截会把大量无害场景
一并拒绝。警示输出进整改报告，验证清单含对应核对项。

### 10.3 napi 环境线程纪律（两引擎共用提醒）

迁移后的 init() 可能在**任意 JS 线程**被调用（主线程/worker），而迁移语句
verbatim 保留原有调用形态：原本在加载期（env 所属线程）执行的 `napi_*` 调用，
迁移后跟随 init() 的调用线程执行。**跨线程使用 env 是未定义行为**——
`NativeEngine` 的 CROSS_THREAD_CHECK 开启时直接 `HILOG_FATAL`
（`native_api_internal.h:77`，仅校验调用线程 == env 所属线程，不校验跨 env）。

**ArkTS 侧义务**：`init()` 在模块首次 import 的同一线程调用（通常主线程），
勿从 worker 线程调用。

