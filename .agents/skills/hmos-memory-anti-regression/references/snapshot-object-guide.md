# Snapshot 对象与属性速查

## 目录
- [对象类型分类](#对象类型分类)
- [常见对象介绍](#常见对象介绍)
- [常见属性介绍](#常见属性介绍)
- [DevEco Snapshot 操作流程(官方)](#deveco-snapshot-操作流程官方)
- [分析方法](#分析方法)

## 对象类型分类

Snapshot 里的对象分两类(决定要不要细看):

- **ArkTS 代码层可见**(分析重点):**JSArray / JSObject / JSFunction**。
- **ArkTS 代码层不可见**(VM 内部,分析时**跳过**):**TaggedDict / TaggedArray / COWArray / ArkInternalConstantPool / InternalAccessor**。

> 判定原则:看到 `TaggedDict / TaggedArray / COWArray / ArkInternalConstantPool / InternalAccessor` 直接忽略,它们是虚拟机内部结构,不是泄漏源。逐项含义见下节 [常见对象介绍](#常见对象介绍)。

## 常见对象介绍

**JSArray** —— JS 数组。展开后是数组里的各个元素;属性有 `__proto__`(原型对象,**所有数组的 `__proto__` 应一致**)和 `length`(内置属性访问器,访问数组长度)。

**TaggedDict** —— 位于 `(array)` 标签中,虚拟机内部创建的字典,ArkTS 代码层**不可见**。

**TaggedArray** —— 位于 `(array)` 标签中,虚拟机内部创建的数组,ArkTS 代码层**不可见**。

**COWArray** —— 位于 `(array)` 标签中,虚拟机内部创建的数组(Copy-On-Write),ArkTS 代码层**不可见**。

**JSObject** —— JS 对象。展开后是内部各属性。分析的核心是**实例化对象 / 声明对象 / 构造函数**三者的关系:
```
实例化对象(new 出来的,可多个)
   └─ __proto__ ──► 声明对象(class 定义,全局唯一)
                       └─ constructor ──► 构造函数(全局唯一)
```
- 实例化对象**可有多个**;声明对象和构造函数**全局只有一个**。
- 实例化对象的 `__proto__` 指向声明对象 → 声明对象里有 `constructor` → 据此确定对象名称。
- 继承:继续展开 `__proto__` 可见继承链(如 `Man` 的 `__proto__` 是 `People` → Man 继承 People)。

**JSFunction** —— 函数,都在 `(closure)` 标签下,展开即可看到所有 JSFunction;每个函数展开后是函数内的各个属性(见 [常见属性介绍](#常见属性介绍))。
- **特殊函数名**(名字不可见时,靠引用反查):`anonymous()` = 匿名函数;`JSFunction()` = 框架层函数(创建时未设函数名)。这两种都可**通过查看其引用**间接确认名称。

**ArkInternalConstantPool** —— 虚拟机创建的常量池,ArkTS 代码层**不可见**;涉及的字符串常量会在 `(array)` 标签中展示。

**LexicalEnv** —— 闭包变量上下文,是一个**链状结构**(数组):
- `[0]` 号元素 = 调用者(或更上层调用者,以此类推)的闭包。
- `[1]` 号元素 = 调试信息。
- `[2]` 及以后 = 闭包传递的变量。

> 解读泄漏时,如果嫌疑对象被闭包链持有,顺着 LexicalEnv 的 `[0]` 往上找最终持有者。

**InternalAccessor** —— 内置属性访问器,会有 `getter`/`setter` 方法,通过它们可以获取、设置该属性。

### 实际快照中其他常见对象

> 上面 9 种是官方《常见对象介绍》列出的基础类型。真实 ArkTS 快照里还会**高频**出现下面这些(括号内为一份典型快照的计数,仅示意量级),分析时按类别处理:

**持有 / Native 绑定相关**(常作 GC Root 或紧贴 root,泄漏高发区):
- **SourceTextModule**(模块记录)—— 应用用 `export` 暴露的对象被它**长期持有**,常见为 `distance=1` 的 GC Root。export 对象无法主动释放,只能断开它对其他对象的引用(见 `arkts-leak-cases-and-faq.md` 案例 1.1 / FAQ 9)。
- **PropertyBox**(属性盒子)—— 框架基础设施,常挂在 `GlobalEnv`/`ArkInternalDict` 下。大量 PropertyBox 属正常框架基线,不要当泄漏。
- **JSNativePointer**(×1万+)—— Native 指针对象。napi_wrap 系列接口绑定的 native 实例地址记录在其 `ExternalPointer` 属性上(见 FAQ 15)。多与 native 泄漏相关。
- **JSWrappedNapiObject / JSXRefObject / JSSharedObject** —— napi 包装 / 跨实例引用 / Sendable 共享对象;出现说明涉及 NAPI 或跨线程共享。

**业务可见的集合 / 内置对象**(可对应到源码用法):
- **Method** —— 绑定方法(this 已绑定的方法对象)。
- **ClassLiteral** —— 类字面量(类定义的运行时表示)。
- **Map / Set / WeakMap / WeakRef** —— JS 集合 / 弱引用对象。
- **Promise** —— Promise 实例。
- **Symbol** —— Symbol 值。

**访问器 / 代理相关**(类似 InternalAccessor,VM 自动生成):
- **AccessorData / getter / setter / gettersetter** —— 属性访问器数据 / 方法。
- **PrototypeHandler / TransWithProtoHandler** —— 原型 / 代理(Proxy)处理器。

**VM / 框架内部结构**(分析时**直接跳过**,同 TaggedDict):
- **ProfileTypeInfoCell**、**ArkInternalFunctionTemplate**、**ProtoChangeDetails**、**ProtoChangeMarker**、**CellRecord**、**LocalExportEntry**、**Iterator** 等——虚拟机/模块系统内部结构,ArkTS 代码层不可见,不是泄漏源。

## 常见属性介绍

> 源自官方对象说明里对各属性的描述,汇总成一张速查表。展开对象/函数时遇到这些属性按此解读。

| 属性 | 出现在 | 含义 |
|---|---|---|
| `__proto__` | JSArray / JSObject / JSFunction | 原型对象。实例化对象的 `__proto__` 指向声明对象;所有数组的 `__proto__` 应一致。沿 `__proto__` 展开可见继承链。 |
| `constructor` | JSObject(声明对象) | 构造函数。**据此确定对象名称**:声明对象直接看 `constructor`;实例化对象无 `constructor`,展开 `__proto__` 找。 |
| `HomeObject` | JSFunction | 父类对象,即该方法属于哪个对象。 |
| `LexicalEnv` | JSFunction | 该函数的闭包上下文(链状结构,见 [LexicalEnv](#常见对象介绍))。 |
| `name` | JSFunction | 内置属性访问器,获取函数名。 |
| `FunctionExtraInfo` | JSFunction | 额外信息,如一些 napi 接口会在这里记录函数地址。 |
| `ProtoOrHClass` | JSFunction | 原型或隐藏类(Hidden Class)。 |
| `length` | JSArray | 内置属性访问器,访问数组长度。 |
| `getter` / `setter` | InternalAccessor | 内置属性访问器,获取/设置该属性。 |

> 若对象有**标志性属性**(独有的属性名/属性值),可在源码里搜属性名反查它是哪个对象。