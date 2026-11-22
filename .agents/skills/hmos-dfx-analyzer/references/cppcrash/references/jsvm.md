# JSVM API使用不规范问题知识库

---

## 一、JS引擎销毁后仍然调用JSVM接口

### 前置：典型cppcrash相关栈

**案例**

示例堆栈1：

```text
#00 pc 00000000022765c/system/lib64/libv8_shared.so(Builtins_InterpreterEntryTrampoline+284)
#01 pc 000000000224ff0/system/lib64/libv8_shared.so(Builtins_JSEntryTrampoline+176)
#02 pc 000000000224c38/system/lib64/libv8_shared.so(Builtins_JSEntry+184)
#03 pc 00000000059775c/system/lib64/libv8_shared.so(v8::internal::(anonymous namespace)::Invoke(v8::iternal::Isolate*,v8::internal::(anonymous namespace)::InvokeParams const&)+792)
#04 pc 00000000059740c/system/lib64/libv8_shared.so(v8::internal::Execution::Call(v8::internal::isolate*,v8::internal::Handle<v8::internal::Object>,v8::internal::Handle<v8::internal::Object>,int,v8::internal::Handle<v8::internal::Object>*)+120)
```

示例堆栈2：

```text
#00 pc 00000000068f670/system/lib64/libv8_shared.so(v8::internal::PagedSpaceBase::RelinkFreeListCategories(v8::internal::PageMetadata*)+80)
#01 pc 0000000006608bc/system/lib64/libv8_shared.so(v8::internal::MarkCompactCollector::StartSweepSpace(v8::internal::PageSpace*)+132)
#02 pc 000000000649de8/system/lib64/libv8_shared.so(v8::internal::MarkCompactCollector::Sweep()+576)
#03 pc 000000000647344/system/lib64/libv8_shared.so(v8::internal::MarkCompactCollector::CollectGarbage()+212)
#04 pc 00000000062bc1c/system/lib64/libv8_shared.so(v8::internal::Heap::MarkCompact()+396)
```

示例堆栈3：

```text
Device Memory(kB): Total 11712624, Free 793088, Available 2834432
Reason:Signal:SIGSEGV(SEGV_ACCERR)@0x0000005d86d80000
Fault thread info:
Tid:56152, Name:.whitenoise.app
#00 pc 000000000042ee5c /system/lib64/libv8_shared.so(Builtins_StaContextSlotNoCellHandler+156)(526548cedc841e47a5a57ff82e92f1e83c11ef0e)
#01 pc 000000000029e600 /system/lib64/libv8_shared.so(Builtins_InterpreterEntryTrampoline+320)(526548cedc841e47a5a57ff82e92f1e83c11ef0e)
#02 pc 000000000029e600 /system/lib64/libv8_shared.so(Builtins_InterpreterEntryTrampoline+320)(526548cedc841e47a5a57ff82e92f1e83c11ef0e)
#03 pc 000000000029b78c /system/lib64/libv8_shared.so(Builtins_JSEntryTrampoline+172)(526548cedc841e47a5a57ff82e92f1e83c11ef0e)
#04 pc 000000000029b3dc /system/lib64/libv8_shared.so(Builtins_JSEntry+188)(526548cedc841e47a5a57ff82e92f1e83c11ef0e)
#05 pc 0000000000658c38 /system/lib64/libv8_shared.so(v8::internal::(anonymous namespace)::Invoke(v8::internal::Isolate*, v8::internal::(anonymous namespace)::InvokeParams const&)+2140)(526548cedc841e47a5a57ff82e92f1e83c11ef0e)
#06 pc 00000000006583a4 /system/lib64/libv8_shared.so(v8::internal::Execution::Call(v8::internal::Isolate*, v8::internal::DirectHandle<v8::internal::Object>, v8::internal::DirectHandle<v8::internal::Object>, v8::base::Vector<v8::internal::DirectHandle<v8::internal::Object> const>)+140)(526548cedc841e47a5a57ff82e92f1e83c11ef0e)
#07 pc 0000000000546758 /system/lib64/libv8_shared.so(v8::Function::Call(v8::Isolate*, v8::Local<v8::Context>, v8::Local<v8::Value>, int, v8::Local<v8::Value>*)+484)(526548cedc841e47a5a57ff82e92f1e83c11ef0e)
#08 pc 0000000000044290 /system/lib64/ndk/libjsvm.so(OH_JSVM_CallFunction+224)(dab2c1922d46712491ebb514153f8597)
#09 pc 000000000005bd04 /data/storage/el1/bundle/libs/arm64/libjsruntime.so(46e9b1ad2dc0e6bc9ac3141e13d23814917ae61f)
```

示例堆栈4：

```text
Device Memory(kB): Total 11712644, Free 808232, Available 3828736
Reason:Signal:SIGSEGV(SEGV_MAPERR)@0xa897e98ab8e46930
Fault thread info:
Tid:18290, Name:isensemobile_hm
#00 pc 000000000036c19c /system/lib64/libv8_shared.so(Builtins_ArrayIsArray+92)(6ed26a8a283f54c54426ccdcd6a5ad440cbb19de)
#01 pc 000000000029e600 /system/lib64/libv8_shared.so(Builtins_InterpreterEntryTrampoline+320)(6ed26a8a283f54c54426ccdcd6a5ad440cbb19de)
#02 pc 000000000029e600 /system/lib64/libv8_shared.so(Builtins_InterpreterEntryTrampoline+320)(6ed26a8a283f54c54426ccdcd6a5ad440cbb19de)
#03 pc 000000000029e600 /system/lib64/libv8_shared.so(Builtins_InterpreterEntryTrampoline+320)(6ed26a8a283f54c54426ccdcd6a5ad440cbb19de)
#04 pc 000000000029e600 /system/lib64/libv8_shared.so(Builtins_InterpreterEntryTrampoline+320)(6ed26a8a283f54c54426ccdcd6a5ad440cbb19de)
#05 pc 000000000029e600 /system/lib64/libv8_shared.so(Builtins_InterpreterEntryTrampoline+320)(6ed26a8a283f54c54426ccdcd6a5ad440cbb19de)
#06 pc 000000000029e600 /system/lib64/libv8_shared.so(Builtins_InterpreterEntryTrampoline+320)(6ed26a8a283f54c54426ccdcd6a5ad440cbb19de)
#07 pc 00000000003c2f5c /system/lib64/libv8_shared.so(Builtins_PromiseConstructor+1628)(6ed26a8a283f54c54426ccdcd6a5ad440cbb19de)
#08 pc 000000000029f01c /system/lib64/libv8_shared.so(Builtins_InterpreterPushArgsThenFastConstructFunction+764)(6ed26a8a283f54c54426ccdcd6a5ad440cbb19de)
#09 pc 000000000044203c /system/lib64/libv8_shared.so(Builtins_ConstructHandler+924)(6ed26a8a283f54c54426ccdcd6a5ad440cbb19de)
#10 pc 000000000029e600 /system/lib64/libv8_shared.so(Builtins_InterpreterEntryTrampoline+320)(6ed26a8a283f54c54426ccdcd6a5ad440cbb19de)
#11 pc 000000000029e600 /system/lib64/libv8_shared.so(Builtins_InterpreterEntryTrampoline+320)(6ed26a8a283f54c54426ccdcd6a5ad440cbb19de)
#12 pc 000000000029e600 /system/lib64/libv8_shared.so(Builtins_InterpreterEntryTrampoline+320)(6ed26a8a283f54c54426ccdcd6a5ad440cbb19de)
#13 pc 000000000029e600 /system/lib64/libv8_shared.so(Builtins_InterpreterEntryTrampoline+320)(6ed26a8a283f54c54426ccdcd6a5ad440cbb19de)
#14 pc 000000000029e600 /system/lib64/libv8_shared.so(Builtins_InterpreterEntryTrampoline+320)(6ed26a8a283f54c54426ccdcd6a5ad440cbb19de)
#15 pc 000000000029e600 /system/lib64/libv8_shared.so(Builtins_InterpreterEntryTrampoline+320)(6ed26a8a283f54c54426ccdcd6a5ad440cbb19de)
#16 pc 000000000029e600 /system/lib64/libv8_shared.so(Builtins_InterpreterEntryTrampoline+320)(6ed26a8a283f54c54426ccdcd6a5ad440cbb19de)
```

示例堆栈5：

```text
Reason:Signal:SIGSEGV(SEGV_MAPERR)@0x00020fd800140774
Fault thread info:
Tid:39094, Name:RNJS_2
#00 pc 0000000000878550 /system/lib64/ndk/libv8_shared.so(v8::internal::Heap::UsedGlobalHandlesSize()+28)(5b2ac1695b5376e6271d4d967cc3bda2dc6d7772)
#01 pc 0000000000735c38 /system/lib64/ndk/libv8_shared.so(v8::Isolate::GetHeapStatistics(v8::HeapStatistics*)+44)(5b2ac1695b5376e6271d4d967cc3bda2dc6d7772)
#02 pc 0000000000a630ec /system/lib64/ndk/libjsvm.so(OH_JSVM_GetHeapStatistics+60)
#03 pc 0000000000039938 /data/storage/el1/bundle/libs/arm64/libreactexecutor.so(rnjsvm::JSVMRuntime::getHeapStatistics() const+60)(828d21aed19b615560e15ee9a39c2fa21a2f6211)
#04 pc 000000000005fd64 /data/storage/el1/bundle/libs/arm64/libreactnativeaki.so(a48ef7e425ea21e5e6acf0c36fd909eedc8f2e0a)
#05 pc 000000000007e998 /data/storage/el1/bundle/libs/arm64/libreactnativeaki.so(facebook::react::ThreadTaskRunner::runLoop()+676)(a48ef7e425ea21e5e6acf0c36fd909eedc8f2e0a)
#06 pc 000000000007e560 /data/storage/el1/bundle/libs/arm64/libreactnativeaki.so(a48ef7e425ea21e5e6acf0c36fd909eedc8f2e0a)
#07 pc 00000000001c05c0 /system/lib/ld-musl-aarch64.so.1(start+236)(2f7a9f748ba8bc9fcab1f8187eab86da)
```

### 规则

1. 报错类型通常为 `Signal:SIGSEGV(SEGV_MAPERR)`，也可能表现为 `SEGV_ACCERR`。
2. 堆栈中包含以下一个或多个符号：
   - `Builtins_InterpreterEntryTrampoline`
   - `Builtins_JSEntryTrampoline`
   - `Builtins_JSEntry`
   - `RelinkFreeListCategories`
   - `v8::internal::Invoke`
   - `UsedGlobalHandlesSize`
   - `GetHeapStatistics`
   - `Builtins_StaContextSlotNoCellHandler`
3. 部分日志可看到 `OH_JSVM_CallFunction`、`OH_JSVM_GetHeapStatistics` 以及应用侧JSVM封装模块。
4. 此类问题会形成UAF表现，因此最终报错位置可能位于JS执行、GC、对象访问或堆统计接口中。

### 结论

此Faultlog报错栈帧说明应用侧执行 `OH_JSVM_DestroyEnv()` 释放JSVM环境后，仍在执行业务逻辑并尝试调用JSVM API，最终触发崩溃。

常见场景：

1. 回调函数中包含JSVM API调用，回调触发时应用已经执行完 `OH_JSVM_DestroyEnv()`。
2. 当前线程已经销毁Env，其他线程仍在尝试调用JSVM API。
3. 使用任务队列执行JS任务时，先执行DestroyEnv任务，随后又执行普通JS任务。

处理建议：

1. 保证所有JSVM C API在同一个JS线程调用。
2. 在JS线程为每个JSVM实例维护对应状态标记，例如 `thread_local_flag`。
3. 执行 `OH_JSVM_DestroyEnv()` 后将状态标记设置为已销毁。
4. 非JS线程需要调用JSVM API时，将任务投递到JS线程后重新检查状态再执行。
5. 任务取出时如果Env已经销毁，队列中剩余的普通JS任务全部跳过。

### 原因

应用没有在销毁JSVM环境前停止回调、跨线程调用和队列任务。Env销毁后，其内部对象、Handle和堆状态已经失效，后续JSVM API继续访问这些资源时产生UAF并崩溃。

---

## 二、HandleScope使用不正确

### 前置：典型cppcrash相关栈

**案例**

示例堆栈1：

```text
#00 pc 0000000001328fd0 /system/lib64/libv8_shared.so(v8::base::OS::Abort()+64)(6e56d6ca0f2f9ac7201183b0a6919309782a12c9)
#01 pc 00000000004860c8 /system/lib64/libv8_shared.so(v8::Utils::ReportApiFailure(char const*, char const*)+140)(6e56d6ca0f2f9ac7201183b0a6919309782a12c9)
#02 pc 00000000004860c8 /system/lib64/libv8_shared.so(v8::Utils::ReportApiFailure(char const*, char const*)+140)(6e56d6ca0f2f9ac7201183b0a6919309782a12c9)
#03 pc 00000000005d4064 /system/lib64/libv8_shared.so(v8::internal::HandleScope::Extend(v8::internal::Isolate*)+372)(6e56d6ca0f2f9ac7201183b0a6919309782a12c9)
#04 pc 00000000004866a4 /system/lib64/libv8_shared.so(v8::HandleScope::CreateHandle(v8::internal::Isolate*, unsigned long)+72)(6e56d6ca0f2f9ac7201183b0a6919309782a12c9)
#05 pc 0000000000051714 /system/lib64/ndk/libjsvm.so(v8impl::FinalizerTracker::CallFinalizer()+112)
#06 pc 00000000000517b0 /system/lib64/ndk/libjsvm.so(v8impl::FinalizerTracker::Finalize()+20)
#07 pc 000000000005123c /system/lib64/ndk/libjsvm.so(v8impl::RefTracker::FinalizeAll(v8impl::RefTracker*)+36)
#08 pc 0000000000050d88 /system/lib64/ndk/libjsvm.so(JSVM_Env__::DeleteMe()+28)
#09 pc 0000000000035358 /system/lib64/ndk/libjsvm.so(OH_JSVM_DestroyEnv+40)
```

示例堆栈2：

```text
LastFatalMessage:JSVM Fatal Error Message : (openHandleScopes) == (openHandleScopesBefore)
Fault thread info:
Tid:52502, Name:__88.huawei.com
#00 pc 00000000001c2bf4 /system/lib/ld-musl-aarch64.so.1(raise+216)(4246509192596535a89208c7cce9641a)
#01 pc 000000000016b688 /system/lib/ld-musl-aarch64.so.1(abort+24)(4246509192596535a89208c7cce9641a)
#02 pc 0000000000032cf4 /system/lib64/ndk/libjsvm.so(platform::OS::Abort()+12)(fd8c2dfc370b972c4fa851458a82f009)
#03 pc 0000000000059f80 /system/lib64/ndk/libjsvm.so(jsvm::OnFatalError(char const*, char const*)+144)(fd8c2dfc370b972c4fa851458a82f009)
#04 pc 000000000004f430 /system/lib64/ndk/libjsvm.so(v8impl::(anonymous namespace)::FunctionCallbackWrapper::Invoke(v8::FunctionCallbackInfo<v8::Value> const&)+316)(fd8c2dfc370b972c4fa851458a82f009)
#05 pc 00000000002a05f0 /system/lib64/libv8_shared.so(Builtins_CallApiCallbackGeneric+176)(526548cedc841e47a5a57ff82e92f1e83c11ef0e)
#06 pc 000000000029e600 /system/lib64/libv8_shared.so(Builtins_InterpreterEntryTrampoline+320)(526548cedc841e47a5a57ff82e92f1e83c11ef0e)
#07 pc 000000000029e600 /system/lib64/libv8_shared.so(Builtins_InterpreterEntryTrampoline+320)(526548cedc841e47a5a57ff82e92f1e83c11ef0e)
#08 pc 000000000029e600 /system/lib64/libv8_shared.so(Builtins_InterpreterEntryTrampoline+320)(526548cedc841e47a5a57ff82e92f1e83c11ef0e)
#09 pc 000000000029e600 /system/lib64/libv8_shared.so(Builtins_InterpreterEntryTrampoline+320)(526548cedc841e47a5a57ff82e92f1e83c11ef0e)
#10 pc 000000000029e600 /system/lib64/libv8_shared.so(Builtins_InterpreterEntryTrampoline+320)(526548cedc841e47a5a57ff82e92f1e83c11ef0e)
#11 pc 000000000029e600 /system/lib64/libv8_shared.so(Builtins_InterpreterEntryTrampoline+320)(526548cedc841e47a5a57ff82e92f1e83c11ef0e)
#12 pc 000000000029e600 /system/lib64/libv8_shared.so(Builtins_InterpreterEntryTrampoline+320)(526548cedc841e47a5a57ff82e92f1e83c11ef0e)
#13 pc 000000000029b78c /system/lib64/libv8_shared.so(Builtins_JSEntryTrampoline+172)(526548cedc841e47a5a57ff82e92f1e83c11ef0e)
#14 pc 000000000029b3dc /system/lib64/libv8_shared.so(Builtins_JSEntry+188)(526548cedc841e47a5a57ff82e92f1e83c11ef0e)
```

### 规则

1. 优先判断DFX Check机制拦截。
2. `LastFatalMessage` 包含：

   ```text
   JSVM Fatal Error Message : (openHandleScopes) == (openHandleScopesBefore)
   ```

   说明执行用户callback函数后返回JSVM时，系统主动检查发现HandleScope层数发生变化。
3. 调用栈前几帧包含 `HandleScope::Extend`、`HandleScope::CreateHandle`、`OH_JSVM_DestroyEnv` 等符号。
4. 调用栈包含 `HandleScope`、`FinalizerTracker`、`RefTracker::FinalizeAll`、`JSVM_Env__::DeleteMe` 等生命周期处理符号。
5. 以上特征通常指向HandleScope打开、关闭或销毁阶段的生命周期管理不正确。

### 结论

此Faultlog报错栈帧说明应用侧即将执行 `OH_JSVM_DestroyEnv()` 释放JSVM环境时，业务逻辑中存在未处理的Exception对象，而此时HandleScope已经关闭，导致处理Handle Exception时触发HandleScope Check失败。

处理建议：

1. HandleScope必须成对打开和关闭。
2. 用户callback执行完成前处理并清理Exception。
3. 不在HandleScope关闭后继续创建或访问Handle。
4. 销毁Env前确认不存在未关闭的HandleScope、活动回调和待处理Exception。
5. Finalizer阶段不再执行会重新进入JS或创建Handle的业务逻辑。

### 原因

应用调用JSVM API时未遵循使用规范正确管理HandleScope生命周期，或在Env销毁阶段仍处理未清理的Exception对象，导致HandleScope层数检查失败并主动Abort。
