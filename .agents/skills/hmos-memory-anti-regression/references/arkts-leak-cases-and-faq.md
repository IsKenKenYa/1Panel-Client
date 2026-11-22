# ArkTS 内存泄漏案例与 FAQ 速查

## 目录

- [一、泄漏案例(按 GC Root 端分类)](#一泄漏案例按-gc-root-端分类)
  - [1.1 SourceTextModule 持有(export 对象)— 断引用](#11-sourcetextmodule-持有export-对象断引用)
  - [1.2 ArkTS 侧 on/off 回调未解注册](#12-arkts-侧-onoff-回调未解注册)
  - [1.3 Native 侧(napi)未加 scope / 未释放 reference](#13-native-侧napi未加-scope--未释放-reference)
- [二、FAQ](#二faq)
  - [OOM 相关(1–5)](#oom-相关15)
  - [Snapshot 字段解读(6–8、13)](#snapshot-字段解读6813)
  - [引用关系与对象类型(9–12、14–15)](#引用关系与对象类型91214-15)

---

## 一、泄漏案例(按 GC Root 端分类)

> 通用分析步骤(三个案例都遵循):① 拍两次 snapshot 做对比(IDE Comparison,按 **size Delta** 降序)→ ② 应用侧优先看**带路径的业务对象**,确认其生命周期是否已结束 → ③ 沿 `distance` 找到 `distance=1` 的 GC Root,判断根因 → ④ 改代码断开/释放。

### 1.1 SourceTextModule 持有(export 对象)— 断引用

- **现象**:某场景重复触发后 ArkTS 堆持续增长。对比快照看到业务对象(如 `NavigationPage`)重复创建,而另一个对象(如 `UrlCacheLogic`)未重复创建——前者生命周期已结束却没释放,即泄漏。
- **根因**:`distance=1` 的 GC Root 是 **`SourceTextModule`**(系统侧对象)。应用用 `export` 暴露对象后,`SourceTextModule` 会一直持有它(见 [FAQ 9](#9-当-distance1-的对象是-sourcetextmodule-时是什么原因))。
- **关键判据**:**不是所有泄漏都要释放 `distance=1` 的根节点。** 若两个 `SourceTextModule` 引用关系相同、且 `distance=1~4` 的对象 **nodeid 都相同**→ 这些对象**没有重复创建**(是复用对象,**不算泄漏**,可保留——"用极小空间换性能")。真正泄漏的是 **`distance` 更大、nodeid 不同(重复创建)** 的对象。
- **修法**:断开"**复用对象** ↔ **重复创建对象**"之间的引用。例:`NavPageRouter`(`distance=5`,重复创建)生命周期结束后,从持有它的 `map` 里删除,使后续对象可被 GC。
- **同型场景**:`distance=1` 的 GC Root 是**全局变量**(被 `global_env` 持有)、或生命周期很长且可复用的对象。

> ⚠️ 与本 skill 的呼应:`SourceTextModule` 持有 `[entry]` **类/方法定义**是正常存量;但**版本增量**出现在这里(新类/新方法)仍要核查是否死代码——别见"挂在 SourceTextModule 下"就判正常放过。

### 1.2 ArkTS 侧 on/off 回调未解注册

- **现象**:新建并关闭某窗口(如浏览器窗口)后,重复操作内存持续增长。
- **定位**:快照里搜关键词(如 `window`),`count` 最多的对象点开 references,沿 `distance` 找到 `distance=1` 的对象——这里是个 `anonymous`(匿名函数),其名称自带路径如 `.../PafWindow.ts#anonymous(line:204)`,即代码第 204 行的箭头函数。
- **根因**:`windowClass.on('xxx', (state)=>{...})` 直接传**箭头函数**;`off` 时再传一个新的箭头函数,**两个函数对象不是同一个**,导致 `off` 找不到、解注册失败。箭头函数捕获上下文 → 全局监听器持有箭头函数 → 持有页面上下文 → 页面无法释放。
- **修法**:把回调**提取成成员变量**,保证 `on`/`off` 传的是**同一个函数对象**:
  ```ts
  // 修改前:on/off 各传一个新箭头函数 → off 失败
  this.windowClass.on('windowHighlightChange', (state) => { ... });
  this.windowClass.off('windowHighlightChange', (state) => { ... }); // 不是同一个对象

  // 修改后:提取为成员,on/off 共用
  windowHighlightChangeCallback: Callback<boolean> = (state: boolean) => { ... };
  add()    { this.windowClass.on ('windowHighlightChange', this.windowHighlightChangeCallback); }
  remove() { this.windowClass.off('windowHighlightChange', this.windowHighlightChangeCallback); }
  ```
- **on/off 三大坑**:① 忘了 `off`;② 没提取函数、箭头函数直接传(不是同一对象);③ 提取了但是局部变量,`off` 时在另一个函数作用域里拿不到。**ArkTS 侧未调用/错误调用释放接口是泄漏最常见的原因。**

### 1.3 Native 侧(napi)未加 scope / 未释放 reference

**案例一:能看出具体泄露对象,顺着代码查**
- **现象**:ets 调一个 napi 方法,napi 回调 ets 的 Lambda;快照显示 Lambda 没释放,且 `distance=1`(没被任何 js 对象引用),ets 侧用法看不出错。
- **排查**(注释/替换接口逐步定位):`napi_create_reference` 创建的引用确实 `napi_reference_unref` + `napi_delete_reference` 释放了,排除;真正原因是 napi 回调线程里**没有用 `napi_handle_scope` 管控对象作用域**。
- **修法**:在 `CallJs` 里 `napi_open_handle_scope(env, &scope)` … `napi_close_handle_scope(env, &scope)` 包裹,泄漏解决。
- **判据**:**ArkTS 侧排查无误后,napi 泄漏最常见就是"没加 scope"**,优先怀疑。其次:`napi_create_reference` 后**没调用 `napi_delete_reference`** 释放。
  - [Scope/生命周期官方文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/napi-data-types-interfaces)

**案例二:LocalHandle 持有 → 用泄漏检测工具直接定位**
- **判据**:快照里某对象 `distance=1` 的 GC Root 是 **`LocalHandle`**。`LocalHandle` 本该是局部短生命周期句柄;快照里抓到**大量** `LocalHandle` 持有的 ArkTS 对象 → 基本**断定泄漏**。
- **工具**:[Allocation 模板](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/bpta-allocation-analysis)(基础内存 → Allocation 分析),复现泄漏操作后抓 Allocation 文件,选 **Created&Existing**,搜索栏搜 **`ArkLocalHandle`**:
  - `ArkLocalHandle` 标签的 Native 对象 = 持有 ArkTS 对象的 LocalHandle **创建调用栈**;对调用栈里的应用 `so` 反编译得到代码行 → 加 scope 管理。
  - 与 GlobalHandle 不同:**LocalHandle 检测工具扫出来的对象即可判为泄漏**(未用 scope 管理)。

---

## 二、FAQ

### OOM 相关(1–5)

1. **OOM 触发条件**:系统给 js 虚拟机内存堆设上限。每线程有 Local Heap,另有所有线程共用的 Shared Heap;堆按 Space 划分(NonMovableSpace / oldSpace / hugeSpace / SnapShotSpace / machineCodeSpace 等)。申请内存超上限 → 触发 GC;**GC 后仍超上限 → 触发 OOM**,自动录制 `rawheap` 并生成 crash 日志。堆结构参数:[GC 介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/gc-introduction#heap结构及其配置参数)。
2. **rawheap 很小/无法解析**:OOM 采样有 4–6 秒采样期,**进程被提前结束会中断采样**,文件不全。→ 重新触发 OOM 再分析。
3. **OOM 的 heapsnapshot 里 string 都是 `""`**:OOM 泄漏文件人人可取,字符串可能含敏感信息,**采样后做了屏蔽**;**在线抓取**的 snapshot 可显示真实 string。
4. **OOM heapsnapshot 大小不一**:各 Space 上限不同、触发 OOM 的 Space 不同、其它 Space 占用也不同;加之应用执行差异,**几 M 或几十 M 就 OOM 也合理**。
5. **crash 文件有什么用**:一般**无分析价值**,只有"报错信息"(如 `sharedheap 的 hugeSpace 到上限")有参考意义。调用栈只说明"在分内存",分 1 字节也会 OOM,**通常可忽略**。唯一例外:应用**高频 OOM 且每次调用栈相同** → 该调用栈可能是高频泄漏调用,这时才值得看调用链;其余情况直接分析 heapsnapshot。

### Snapshot 字段解读(6–8、13)

6. **`distance` 含义**:对象在引用树中到 native 的**最短距离**。`distance=1` = 被 native 侧或全局变量(全局变量被 `global_env` 持有)直接持有 = **GC Root**。一个对象被多个对象持有时,`distance` 只显示到 GC Root 的最短路径。分析泄漏时按 `distance-1` 沿最短路径回溯到 GC Root。
7. **`line` 含义**:ArkTS 创建的类对象/函数对象带行号,代表**该对象实现代码的第一行**。如 `anonymous(line:73)` = 未知函数,实现第一行在 73 行(对应 ArkTS 第 72 行的箭头函数)。
   - 本 skill 的 `--sourcemap` 正是把这个编译产物里的 `(line:N)` 还原成 `.ets` 源码行号。
8. **对象前的紫色字符(持有关系)**:表示两个对象间的引用关系——
   - `HomeObject`:父类对象(该方法属于哪个对象)
   - `__proto__`:原型对象
   - `LexicalEnv`:函数的闭包上下文
   - `name`:内置属性访问器,取函数名
   - `FunctionExtraInfo`:额外信息(如 napi 接口在这里记函数地址)
   - `ProtoOrHClass`:原型或隐藏类
   - 详见 [官方解读](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-arkts-memory-leak-analysis#section135057191135)。
13. **对象命名格式**:`BundleName/SelfModule@Version/FilePath/File#Class(line: xx)[RefModule]`
   - 例:`com.example.insight_test_stage/quickstart@1.0.0/src/main/ets/view/TutorialView.ts#Enablement(line: 10)[default]`
   - `BundleName` 包名 / `SelfModule` 所在模块 / `Version` 模块版本 / `FilePath/File` build 产物路径+文件名 / `Class` 对象名 / `line` 行号 / `RefModule` 在该模块被调用。

### 引用关系与对象类型(9–12、14–15)

9. **`distance=1` 是 `SourceTextModule` 的原因**:应用用 `export` 暴露对象时,系统侧 `SourceTextModule` 会**一直持有**该对象,无法主动释放。可断开 export 对象与其间接持有对象间的引用来释放后者,否则可能泄漏(案例见 [1.1](#11-sourcetextmodule-持有export-对象断引用))。
10. **ArkTS 循环引用会无法回收吗?——不会。** 方舟虚拟机用**标记-清除**算法,维护一棵以 **GC Root**(`distance=1` 节点)为根的树。只要对象挂在这棵树上(被 native 直接/间接持有)就是存活。`obj1↔obj2↔obj3` 循环引用,**只要它们都不被 root 持有**(断掉 root 到 obj1 的引用、或 root 被回收),整组循环引用就会被回收。
11. **引用链上出现 `LexicalEnv`**:函数用了**闭包变量**(持有上层对象)时出现。闭包让函数访问/操作外部变量并保持其在内存中。例:第 73 行 lambda 用了上层变量 `proxy` → 函数自身属性持有一个 `LexicalEnv` → `LexicalEnv` 持有闭包变量 `proxy` **和整个类对象**(数组第 3 个元素是上层类变量、第 4 个是 `proxy`,均作为闭包变量无法释放)。
12. **`distance=1` 是基本类型(jsproxy / jsarray 等)怎么分析**:较难,基本类型**没有代码路径**。靠**分析其存储的数据 + 上下引用关系**反推创建位置:
    - 应用侧创建经 native 接口传入 → 排查生命周期结束后释放接口是否已调、调用方式是否正确;确认无误则可能接口本身泄漏,联系接口人。
    - 不在应用侧创建(native/系统框架创建)→ 联系对应接口人。
14. **Snapshot 里 `handle` 类型节点**:仅当代码涉及 Native 才出现。
    - `napi_value` = **localHandle**(局部句柄);`napi_ref` = **globalHandle**(全局句柄)。二者都持有 ArkTS 对象,`distance=1`,即 GC Root;不被 handle 持有时才可回收。
    - 快照中 `handle` 节点下有两个虚拟子节点 **`LocalHandle` / `GlobalHandle`**,后跟数字 = 该类型对象数量。被 handle 持有的 GC Root 对象的引用关系里会标出 handle 类型 → 据此判断是 `napi_value` 还是 `napi_ref` 导致泄漏(案例见 [1.3 案例二](#13-native-侧napi未加-scope--未释放-reference))。
    - 生命周期管理:[Node-API 生命周期开发](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/napi-data-types-interfaces)。
15. **如何看 ArkTS 对象绑定的 Native 对象地址**:Native 侧常用 `napi_wrap` 系列接口在 ArkTS Object 上绑 native 实例,通常借 ArkTS Object 生命周期管理 native 实例;ArkTS Object 泄漏会连带 native 实例泄漏。快照里地址记录在 `JSNativePointer` 的 `ExternalPointer` 属性上:
    - `napi_wrap` 系列(`napi_wrap` / `napi_wrap_enhance` / `napi_wrap_async_finalizer` / `napi_wrap_with_size`):
      `ArkTS object → napiwrapper(JSWrappedNapiObject) → NativePointers(ArkInternalArray) → 0(JSNativePointer) → ExternalPointer`。为方便查看,对 `JSWrappedNapiObject` 新增了**虚拟属性 `NativeAddress`**(值同 ExternalPointer,仅展示用)。
    - `napi_wrap_sendable` 系列:位置随对象布局变化——多数场景 `JSNativePointer` 在 `Properties` 属性里:`myobj(JSSharedObject) → Properties(ArkInternalArray) → 0(JSNativePointer) → ExternalPointer`;属性很多时虚拟机优化布局,`JSNativePointer` 会放进 `HashField`:`myobj → HashField(ArkInternalArray) → 0(JSNativePointer) → ExternalPointer`。

---

## 与本 skill 的衔接

- **案例 1.1 的判据**(根节点 nodeid 相同=未重复创建=可保留)印证本 skill 的"**存量 vs 劣化**":挂在 `SourceTextModule`/模块作用域下的复用对象是正常常驻,**版本增量**才需核查。
- **FAQ 13 命名格式**解释了引用链里 `xxx.ts#Func(line:N)` 的结构,正是 `--sourcemap` / `arkts_top5.py --sourcemap` 还原行号的输入。
- **FAQ 14**(handle 节点)对应本 skill 责任侧分类里的 **Native** 侧(`GlobalHandleRoot`/`LocalHandleRoot`);案例 1.3 是 Native 侧泄漏的典型修法。
- 本文件聚焦"**怎么改**";"**A→B 涨没涨、该不该留**"的判定仍以 `SKILL.md` 第 4 步为准。
