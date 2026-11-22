# 功能性测试用例

---

### 测试用例：FUNC-001

**skill**：hmos-arkts-napi-side-effect-fixer
**类型**：functional（功能验证）

#### 输入

请检查以下 NAPI 模块 C++ 代码的 import（dlopen）时副作用，给出判定结论与整改方向：

```cpp
#include "napi/native_api.h"
#include <pthread.h>

static void* CollectThread(void* /*arg*/) { return nullptr; }

void init_monitor_thread() {
  pthread_t tid;
  pthread_create(&tid, nullptr, CollectThread, nullptr);  // 拉起采集线程
}

static napi_value Init(napi_env env, napi_value exports) {
  init_monitor_thread();
  return exports;
}

static napi_module demoModule = {
  .nm_version = 1,
  .nm_register_func = Init,
  .nm_modname = "monitor",
};

extern "C" __attribute__((constructor)) void RegisterEntryModule() {
  napi_module_register(&demoModule);
}
```

#### 预期输出

**验证标准**：

- 识别 so 被 dlopen 即执行的代码范围：constructor（RegisterEntryModule）→ napi_module_register → 注册回调 Init → 被调函数 init_monitor_thread（回调名从 .nm_register_func 字段解析，非命名惯例）
- 判定：init_monitor_thread() 与 exports 构建无关 → 类别1 候选；定位动作实现可见且耗时（pthread_create 线程创建属天然耗时类）→ 需整改
- 输出问题位置与耗时依据（线程创建）
- 整改方向：移至业务首次初始化（如应用初始化入口或显式 init 导出函数）

**应包含**：pthread_create, 需整改

---

### 测试用例：FUNC-002

**skill**：hmos-arkts-napi-side-effect-fixer
**类型**：functional（功能验证）

#### 输入

请检查以下 NAPI 模块 C++ 代码的 import（dlopen）时副作用，给出判定结论：

```cpp
#include "napi/native_api.h"

static void DefaultNoopHook() {}
static void (*g_event_hook)() = nullptr;

void attach_to_ark_event_handler() {
  g_event_hook = &DefaultNoopHook;   // 仅函数指针赋值
}

static napi_value Init(napi_env env, napi_value exports) {
  attach_to_ark_event_handler();
  napi_value undefined = nullptr;
  napi_get_undefined(env, &undefined);
  return exports;
}

static napi_module lightModule = {
  .nm_version = 1,
  .nm_register_func = Init,
  .nm_modname = "lightdemo",
};

extern "C" __attribute__((constructor)) void RegisterEntryModule() {
  napi_module_register(&lightModule);
}
```

#### 预期输出

**验证标准**：

- 识别 attach_to_ark_event_handler() 位于注册链、与 exports 构建无关 → 类别1 候选
- 定位动作实现：仅函数指针赋值，无连接/无 IO/无线程 → 实现可见且轻量 → 不计为问题（轻量动作不作问题输出）
- napi_get_undefined 属 exports 构建，排除复核
- 模块结论：NAPI OK（import 无副作用）

**应包含**：轻量, NAPI OK

---

### 测试用例：FUNC-003

**skill**：hmos-arkts-napi-side-effect-fixer
**类型**：functional（功能验证）

#### 输入

请检查以下 NAPI 模块 C++ 代码的 import（dlopen）时副作用，给出判定结论：

```cpp
#include "napi/native_api.h"

// 实现位于另一个构建单元，不在本文件内
void create_native_global_singleton();

static napi_value Init(napi_env env, napi_value exports) {
  create_native_global_singleton();
  return exports;
}

static napi_module invisModule = {
  .nm_version = 1,
  .nm_register_func = Init,
  .nm_modname = "invisdemo",
};

extern "C" __attribute__((constructor)) void RegisterEntryModule() {
  napi_module_register(&invisModule);
}
```

#### 预期输出

**验证标准**：

- 识别 create_native_global_singleton() 位于注册链、与 exports 构建无关 → 类别1 候选
- 动作实现不可见（仅外部声明，定义不在检查范围）→ 成本不可判定 → 列入待人工确认，禁止静默判 OK
- 模块结论为需确认（既非需整改，也非 NAPI OK）
- 给出人工复核建议：定位实现函数体后按耗时定级

**应包含**：人工确认

---

### 测试用例：FUNC-004

**skill**：hmos-arkts-napi-side-effect-fixer
**类型**：functional（功能验证）

#### 输入

请检查以下 NAPI 模块 C++ 代码的 import（dlopen）时副作用，给出判定结论与整改方向：

```cpp
#include "napi/native_api.h"

class Database {
 public:
  explicit Database(const char* path);  // 构造时打开数据库连接
};

static Database* g_db = new Database("/data/db");  // 文件作用域动态初始化

static napi_value Init(napi_env env, napi_value exports) {
  napi_value undefined = nullptr;
  napi_get_undefined(env, &undefined);
  return exports;
}

static napi_module dbModule = {
  .nm_version = 1,
  .nm_register_func = Init,
  .nm_modname = "dbdemo",
};

extern "C" __attribute__((constructor)) void RegisterEntryModule() {
  napi_module_register(&dbModule);
}
```

#### 预期输出

**验证标准**：

- 识别 g_db 的文件作用域动态初始化在 so 加载时立即执行 → 类别2 候选（形态A）
- 成本判定：new Database("/data/db") 打开数据库连接，属天然耗时类（IO/连接）→ 重初始化 → 需整改
- 整改方向：改为惰性初始化（首次使用时，如函数内 static 局部）
- Init 内 napi_get_undefined 属 exports 构建，排除复核

**应包含**：惰性初始化, 形态A

---

### 测试用例：FUNC-005

**skill**：hmos-arkts-napi-side-effect-fixer
**类型**：functional（功能验证）

#### 输入

NAPI 模块（.so）被 dlopen 时，哪些 C++ 代码会立即执行？这类代码的副作用判定标准是什么？

#### 预期输出

**验证标准**：

- 说明立即执行的代码范围：__attribute__((constructor)) 修饰函数（如 RegisterEntryModule）、其调用的 napi_module_register、模块注册回调 nm_register_func（含 NAPI_MODULE 宏封装）、C++ 全局静态对象构造函数
- 说明判定模型：与 exports 构建无关的业务动作（类别1）与加载期初始化（类别2）两类候选，共用统一成本判定（成本 × 归属二维）——实现可见且耗时（线程创建/文件 IO/连接建立/IPC 等天然耗时类）且归属确认在 import 路径（模块自注册/构建依赖实证）→ 需整改；耗时但归属待核 → 需确认（归属优先，确认在路径后升级）；实现可见且轻量 → 不计问题；实现不可见 → 待人工确认（公开通用 API 如 std::chrono/POSIX 原语按速查表直接定级，平台/厂商 API 维持待确认）
- 说明 exports 构建代码（napi_create_function/napi_wrap/napi_set_named_property 等）不算副作用

**应包含**：dlopen, nm_register_func

---

### 测试用例：FUNC-006

**skill**：hmos-arkts-napi-side-effect-fixer
**类型**：functional（功能验证）

#### 输入

请检查以下 NAPI 模块 C++ 代码的 import（dlopen）时副作用，给出判定结论：

```cpp
#include "napi/native_api.h"

class MonitorState {
 public:
  MonitorState() {}   // 纯内存记账，轻量构造
};

static MonitorState* g_state = nullptr;
static Database* g_db = nullptr;   // Database 构造时打开连接（外部定义）

static napi_value Query(napi_env env, napi_callback_info info) {
  g_db = OpenDb();   // 普通导出函数内，首次调用才执行
  return nullptr;
}

static napi_value Init(napi_env env, napi_value exports) {
  g_state = new MonitorState();
  napi_wrap(env, exports, g_state, nullptr, nullptr, nullptr);  // 挂到 exports
  return exports;
}

static napi_module wrapModule = {
  .nm_version = 1,
  .nm_register_func = Init,
  .nm_modname = "wrapdemo",
};

extern "C" __attribute__((constructor)) void RegisterEntryModule() {
  napi_module_register(&wrapModule);
}
```

#### 预期输出

**验证标准**：

- g_state 经 napi_wrap 挂到 exports → 属导出面构建一部分，注册期必须存在，不计为问题（不能移到业务初始化）
- g_db = OpenDb() 的宿主是普通导出函数 Query（非注册链）→ 首次调用才执行，不算 import 副作用
- 上述均为排除项 → 模块结论：NAPI OK

**应包含**：napi_wrap, NAPI OK

---

### 测试用例：FUNC-007

**skill**：hmos-arkts-napi-side-effect-fixer
**类型**：functional（功能验证）

#### 输入

请检查以下 NAPI 模块 C++ 代码的 import（dlopen）时副作用，给出判定结论：

```cpp
#include "napi/native_api.h"
#include <csignal>

static void CrashHandler(int) {}

static napi_value Test1(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_string_utf8(env, "sigdemo [test1]", NAPI_AUTO_LENGTH, &result);
    return result;
}

static void register_crash_handler() {
    struct sigaction sa;
    sa.sa_handler = CrashHandler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = 0;
    sigaction(SIGSEGV, &sa, nullptr);
    sigaction(SIGABRT, &sa, nullptr);
}

static napi_value Init(napi_env env, napi_value exports) {
    register_crash_handler();
    napi_property_descriptor desc[] = {
        { "test1", nullptr, Test1, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

static napi_module demoModule = {
    .nm_version = 1,
    .nm_register_func = Init,
    .nm_modname = "sigdemo",
};

extern "C" __attribute__((constructor)) void RegisterEntryModule() {
    napi_module_register(&demoModule);
}
```

#### 预期输出

**验证标准**：

- `sigaction` 命中“信号处理器注册”只是**候选线索**，不得据此直接判重
- 跟进实现：仅 `struct sigaction` 栈上 POD + `sa_handler` 函数指针赋值 + `sigemptyset` + 系统调用，无文件 IO/线程/IPC/大内存 → 按 S-08 定档口径① + S-09 速查表判**轻量** → 不计为问题
- 不得以“改变进程行为/影响面大”为由判重（成本轴是加载耗时）
- 模块结论：NAPI OK（import 无耗时副作用）

**应包含**：轻量, NAPI OK
