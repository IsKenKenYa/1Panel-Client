# React Native 知识库
---

## 案例一：RNOH JsCrash — "Failed to retrieve property from object"（ArkTS TurboModule 返回值非 Promise）

### 前置

JsCrash 堆栈

### 规则

```
Reason:Error
Error name:Error
Error message:Failed to retrieve property from object
Stacktrace:
#06 pc 0000000000056adc /system/lib64/platformsdk/libace_napi.z.so(napi_throw_error+188)
#07 pc 000000000026d570 /data/storage/el1/bundle/libs/arm64/librnoh.so(...)                 ← ArkJS::getObjectProperty 失败路径（无符号）
#08 pc 000000000026f818 .../librnoh.so(RNOHNapiObject::call(...)+148)
#09 pc 000000000026e878 .../librnoh.so(Promise::then(...)+144)
#10 pc 000000000028f600 .../librnoh.so(...)                                                 ← callAsync 任务 lambda（无符号）
#11 pc 00000000002a71a0 .../librnoh.so(rnoh::EventLoopTaskRunner::executeTask()+80)
#12 pc 00000000002a6380 .../librnoh.so(rnoh::NapiTaskRunner::executeTask()+116)
（其余为 libuv/eventhandler 主线程帧）
```

在日志中查找 Error message 为 **Failed to retrieve property from object** 则满足条件。且堆栈中有 **Promise::then → RNOHNapiObject::call → napi_throw_error → EventLoopTaskRunner/NapiTaskRunner::executeTask** 类似的流程（0.72 为 librnoh.so，0.77/0.82 为 librnoh_core.so）。全栈无业务 JS 帧（异常由 Native 侧 napi_throw_error 抛出）。

再在崩溃时间点前的 HiLog 中查找 **#RNOH::ArkTSTurboModule::callAsync (模块名::方法名) failed.**，存在则可直接确定触发的 TurboModule 与方法（callAsync 入口必伴随该日志）。

### 结论

在对应时间点的 2026-07-08 09:52:17.699 去查找对应进程 com.sf.harmonynext 的日志，发现有

```
07-08 09:52:17.699 46461 46461 E A0BEEF/.../#RNOH_CPP: █____ ArkTSTurboModule.cpp:215> #RNOH::ArkTSTurboModule::callAsync (TurboInvokerModule::callAsync) failed.
（连续 10 条，09:52:17.699 ~ 09:52:17.702）
07-08 09:52:17.878 46461 46461 E A00000/.../testTag: UnhandledException: Error name:Error
07-08 09:52:17.878 46461 46461 E A00000/.../testTag: Error message:Failed to retrieve property from object
```

**报错原因**：JS 调用 codegen 声明为 Promise 返回的 ArkTS TurboModule 方法（本例 TurboInvokerModule::callAsync，并发 10 次），ArkTS 侧实现实际返回了非 Promise 值（某分支漏 return / 方法缺失 / 实例未就绪返回 undefined）。RNOH（0.72/0.77/0.82 均存在，ArkJS::isPromise 从未被使用）的 ArkTSTurboModule::callAsync 不校验返回值，直接 Promise(env, 返回值).then(...)，内部 napi_get_property(返回值, "then") 失败后 maybeThrowFromStatus 调 napi_throw_error("Failed to retrieve property from object") 向 NAPI 环境抛出 JS Error。C++ catch 虽已捕获并打印 "callAsync (...) failed" 且 reject 了对应 JS Promise，但该 JS Error 一直挂在主线程 NAPI 环境中无人清除，事件循环收尾时以 UnhandledException 上报 → JsCrash。即使业务 JS 侧 catch 了 Promise rejection 也无法避免该崩溃。本例伴随特征：崩溃前 6 秒应用加载新业务 bundle（getFhdInfo fhdApp、runJSBundle STOP 1182ms）并伴随大量 "Couldn't provide turbo module"、"instanceHandle is null, event will be dropped"，属 RNInstance 启动/切换窗口期调用 TurboModule 的典型场景。

**排查措施**：

1. 用 HiLog `ArkTSTurboModule::callAsync (模块名::方法名) failed.` 定位具体模块（本例 TurboInvokerModule::callAsync）；
2. 审查该 ArkTS TurboModule 实现：方法是否存在、所有分支（含 catch/提前 return）是否都 return Promise。最简单的应用侧修复是给方法加 async：async 函数任何路径都必然返回 Promise（漏 return 变为 resolve(undefined)，同步异常自动变为 reject），可直接避免本案例崩溃；
3. 结合 RNInstance 生命周期日志（runJSBundle、"Couldn't provide turbo module"）确认是否为实例启动/重建窗口期的调用，业务侧应在实例未就绪时暂缓该调用；

**责任归属**：应用问题
