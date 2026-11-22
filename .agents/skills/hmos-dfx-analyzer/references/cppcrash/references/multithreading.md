# 多线程问题常见问题分析参考手册

---

## 一、跨线程访问env触发CheckThread崩溃

### 前置：典型cppcrash相关栈

**案例**

```text
Reason:Signal:SIGABRT(SI_TKILL)@0x01317b3400000c75 from:3189:20020020
LastFatalMessage:[default] [CheckThread] Fatal: ecma_vm cannot run in multi-thread! thread:3189 currentThread:4252
Fault thread info:
Tid:4252, Name:WorkerThread_Sy
#00 pc 00000000001c68c0 /system/lib/ld-musl-aarch64.so.1(raise+216)(d0012f55c5b689c060d2cf0d0007b050)
#01 pc 000000000017242c /system/lib/ld-musl-aarch64.so.1(abort+24)(d0012f55c5b689c060d2cf0d0007b050)
#02 pc 00000000002e585c /system/lib64/platformsdk/libark_jsruntime.so(common::HiLog<(LogLevel)7, (Component)1>::~HiLog()+120)(f44b896daac2f4306295f47784024248)
#03 pc 000000000026bf2c /system/lib64/platformsdk/libark_jsruntime.so(panda::ecmascript::EcmaVM::CheckThread() const+528)(f44b896daac2f4306295f47784024248)
#04 pc 000000000099bb90 /system/lib64/platformsdk/libark_jsruntime.so(panda::JSNApi::GetHandleAddr(panda::ecmascript::EcmaVM const*, unsigned long)+448)(f44b896daac2f4306295f47784024248)
#05 pc 00000000000490d8 /system/lib64/platformsdk/libace_napi.z.so(ArkNativeReference::Get(NativeEngine*)+88)(2bb688074496ae6c793849fd371650b1)
#06 pc 000000000007fb90 /system/lib64/platformsdk/libace_napi.z.so(napi_get_reference_value+48)(2bb688074496ae6c793849fd371650b1)
#07 pc 00000000000078d4 /system/lib64/module/multimodalawareness/libmotion_napi.z.so(OHOS::Msdp::MotionEventNapi::InsertRef(std::__h::shared_ptr<OHOS::Msdp::MotionEventListener>, napi_value__* const&, int, napi_env__*)+168)(086fd31f43a81204b5df0ca69e51ff90)
#08 pc 000000000000bb94 /system/lib64/module/multimodalawareness/libmotion_napi.z.so(OHOS::Msdp::MotionNapi::SubscribeMotion(napi_env__*, napi_callback_info__*) (.cfi)+4084)(086fd31f43a81204b5df0ca69e51ff90)
```

### 规则

1. `LastFatalMessage` 明确包含 `CheckThread` 和 `ecma_vm cannot run in multi-thread`。
2. 日志同时给出env所属线程 `thread:3189` 和当前调用线程 `currentThread:4252`，两个线程不一致。
3. 调用栈中存在 `EcmaVM::CheckThread`、`napi_get_reference_value`。
4. 跳过 `libark_jsruntime.so` 和 `libace_napi.z.so` 后，第一个实际调用方为 `libmotion_napi.z.so`。

### 结论

该日志是跨线程访问env问题的第一现场。`libmotion_napi.z.so` 在错误线程调用 `napi_get_reference_value` 操作env上的对象，触发EcmaVM线程检查并主动Abort。

### 原因

env与创建它的JS线程绑定，不能在其他线程直接访问。出现该类明确的CheckThread日志时，应沿N-API调用栈定位第一个实际调用方，并整改其线程切换逻辑。

---

## 二、TaskPool线程跨线程调用JS函数导致空指针崩溃

### 前置：典型cppcrash相关栈

**案例**

```text
Reason:Signal:SIGSEGV(SEGV_MAPERR)@0x0000000000000048 probably caused by NULL pointer dereference
Fault thread info:
Tid:34784, Name:OS_TaskWorker
#00 pc 0000005d3ea44d90 Not mapped
#01 pc 0000000000e121a8 /system/lib64/module/arkcompiler/stub.an(RTStub_JSFastCallWithArgV+212)
#04 pc 00000000007e7f64 /system/lib64/platformsdk/libark_jsruntime.so(EcmaVM::FastCallAot)
#05 pc 00000000001e47a8 /system/lib64/platformsdk/libark_jsruntime.so(JSFunction::Call)
#06 pc 00000000005feae0 /system/lib64/platformsdk/libark_jsruntime.so(BuiltinsFunction::FunctionPrototypeCall)
#09 at processBlock (dcar|@ohos/crypto-js|2.0.5|src/main/js/crypto-js.js:2518:1)
#16 at decrypt (dcar|@dcar/utils|1.0.0|src/main/ets/x14/z14.ts:18:1)
#32 pc 00000000004414dc /system/lib64/platformsdk/libark_jsruntime.so(PromiseCapabilityRef::Resolve)
#33 pc 00000000000527fc /system/lib64/platformsdk/libace_napi.z.so(napi_resolve_deferred+140)
#35 pc 000000000007b9fc /system/lib64/platformsdk/libace_napi.z.so(NativeAsyncWork::AsyncAfterWorkCallback)
#40 pc 0000000000040b8c /system/lib64/module/libtaskpool.z.so(TaskPoolModule::Worker::ExecuteInThread)
#41 pc 0000000000038808 /system/lib64/module/libtaskpool.z.so(TaskPoolModule::TaskRunner::TaskInnerRunner::Run)
```

### 规则

1. 崩溃线程为TaskPool工作线程 `OS_TaskWorker`。
2. 故障地址为NULL小偏移 `0x48`。
3. 栈中同时存在JS函数调用、`napi_resolve_deferred`、`NativeAsyncWork::AsyncAfterWorkCallback` 和TaskPool执行路径。
4. 表面崩溃位置位于 `crypto-js` 解密函数，但该栈不是跨线程操作env的第一现场。

### 结论

TaskPool线程跨线程操作env上的JS对象，导致对象内部指针被破坏；后续调用该对象上的JS函数时，以NULL为基址访问偏移 `0x48`，最终触发空指针崩溃。

### 原因

TaskPool异步任务通过 `napi_resolve_deferred` 处理JS结果时，错误地跨线程使用env或关联JS对象。对象先被破坏，Crash延迟发生在后续JS函数调用阶段。

---

## 三、ShowToast回调跨线程操作env导致JSON序列化崩溃

### 前置：典型cppcrash相关栈

**案例**

```text
Reason:Signal:SIGSEGV(SEGV_MAPERR)@0x0070697263736564
Fault thread info:
Tid:38858, Name:nologydsmhelper
#00 pc 0000000000a34b30 /system/lib64/platformsdk/libark_jsruntime.so(JsonStringifier::SerializeJSONObject)
#03 pc 00000000003ee624 /system/lib64/platformsdk/libark_jsruntime.so(BuiltinsJson::StringifyWithTransformType)
#06 at upload entry (entry/src/main/ets/common/Transfertask.ets:406:52)
#19 pc 0000000000943368 /system/lib64/platformsdk/libark_jsruntime.so(PromiseCapabilityRef::Resolve)
#20 pc 0000000000081c2c /system/lib64/platformsdk/libace_napi.z.so(napi_resolve_deferred+140)
#21 pc 00000000000218fc /system/lib64/module/libpromptaction.z.so
#22 pc 00000000029355e4 /system/lib64/platformsdk/libace_compatible.z.so(OverlayManager::ShowToast)
```

### 规则

1. 故障地址 `0x0070697263736564` 按字节解析后包含连续可打印ASCII字符，说明对象字段可能被字符串数据覆盖。
2. 崩溃发生在 `JsonStringifier::SerializeJSONObject` 遍历JS对象阶段。
3. 栈中存在 `ShowToast`、`libpromptaction.z.so` 和 `napi_resolve_deferred` 回调路径。
4. JSON序列化位置是被踩坏对象的最终访问点，不是跨线程操作env的第一现场。

### 结论

ShowToast回调路径跨线程调用 `napi_resolve_deferred`，导致env上的JS对象内存被破坏；后续 `JSON.stringify` 遍历该对象时访问到被覆盖的字段并崩溃。

### 原因

跨线程操作env破坏了JS对象内存布局。故障地址中的ASCII字符串特征说明本应保存指针或对象字段的位置已经被其他数据覆盖。

---

## 四、跨线程访问env踩坏XComponent控制器对象

### 前置：典型cppcrash相关栈

**案例**

```text
Reason:Signal:SIGSEGV(SEGV_MAPERR)@0x0000000000000018 probably caused by NULL pointer dereference
Fault thread info:
Tid:44681, Name:.cars.guazi.ohs
#00 pc 00000000014995c8 /system/lib64/platformsdk/libace_compatible.z.so(JSXComponentController::GetXComponentSurfaceRect)
#01 pc 0000000001499e18 /system/lib64/platformsdk/libace_compatible.z.so(JsiClass<JSXComponentController>::InternalJSMemberFunctionCallback)
#05 at func_main_0 [anon:ArkTS Code]
#18 at anonymous chd_vod_player (chd_vod_player/src/main/ets/tencent/TxVodPlayer.ets:602:22)
#25 pc 0000000000fabfbc /system/lib64/platformsdk/libace_compatible.z.so(XComponentEventHub::FireLoadEvent)
#26 pc 0000000000fabca0 /system/lib64/platformsdk/libace_compatible.z.so(XComponentPattern::XComponentSizeInit)
```

### 规则

1. 故障地址为NULL小偏移 `0x18`。
2. 崩溃发生在 `JSXComponentController::GetXComponentSurfaceRect` 访问对象成员时。
3. 调用链位于XComponent加载事件回调和应用播放器业务路径。
4. 正常使用控制器对象的位置不是跨线程踩内存的第一现场。

### 结论

跨线程使用env导致XComponentController对象被踩坏，对象内部指针变为NULL或非法值；主线程后续正常调用控制器接口时触发 `0x18` 偏移访问并崩溃。

### 原因

XComponentController关联JS对象被其他线程非法操作后，控制器内部状态已经失效。Crash延迟发生在后续查询SurfaceRect的正常业务路径。

---

## 五、跨线程踩坏对象导致GC并发标记崩溃

### 前置：典型cppcrash相关栈

**案例**

```text
Reason:Signal:SIGSEGV(SEGV_MAPERR)@0x0000001bcff26308
Fault thread info:
Tid:28713, Name:OS_GC_Thread
#00 pc 0000000000649368 /system/lib64/platformsdk/libark_jsruntime.so(NonMovableMarker::ProcessYoungGCMarkStack)
#01 pc 00000000005e5584 /system/lib64/platformsdk/libark_jsruntime.so(ConcurrentMarker::ProcessConcurrentMarkTask)
#02 pc 0000000000604ee8 /system/lib64/platformsdk/libark_jsruntime.so(Heap::ParallelGCTask::Run)
```

### 规则

1. 故障线程为 `OS_GC_Thread`。
2. 调用栈只有GC相关帧，没有业务代码。
3. 崩溃发生在 `NonMovableMarker`、`ConcurrentMarker` 并发标记阶段。
4. GC遍历对象图时访问了非法地址 `0x0000001bcff26308`。

### 结论

该日志是跨线程踩坏JS对象后的延迟爆炸表现。cppcrash堆栈不是第一现场；仅看到GC帧时，应优先通过多线程检测定位更早的跨线程env访问位置，而不是直接把GC作为根因。

### 原因

业务代码跨线程使用env，提前破坏了JS对象的内存布局。GC线程按照正常对象结构遍历该对象时，将损坏字段解释为地址并访问，最终在并发标记阶段Crash。

---

## 六、跨线程踩坏对象类型字段导致GC搬迁崩溃

### 前置：典型cppcrash相关栈

**案例**

```text
Reason:Signal:SIGABRT(SI_TKILL)@0x01317b3e0000375a from:14170:20020030
LastFatalMessage:[ecmascript] this branch is unreachable, type: 167
Fault thread info:
Tid:14263, Name:OS_GC_Thread
#04 pc 0000000000999fe8 /system/lib64/platformsdk/libark_jsruntime.so(FullGCRunner::EvacuateObject)
#05 pc 0000000000999e4c /system/lib64/platformsdk/libark_jsruntime.so(FullGCRunner::HandleMarkingSlotObject)
#07 pc 00000000009c46f4 /system/lib64/platformsdk/libark_jsruntime.so(CompressGCMarker::ProcessMarkStack)
#08 pc 00000000005f53ec /system/lib64/platformsdk/libark_jsruntime.so(Heap::ParallelGCTask::Run)
```

### 规则

1. 故障线程为 `OS_GC_Thread`，调用栈只有GC相关帧。
2. GC位于 `FullGCRunner::EvacuateObject` 对象搬迁阶段。
3. `LastFatalMessage` 包含 `this branch is unreachable, type: 167`。
4. 非法类型值说明对象头或类型字段已经被踩坏。

### 结论

该日志是跨线程踩坏JS对象后的延迟爆炸表现。对象类型字段被破坏后，FullGC搬迁对象时读取到非法类型并进入不可达分支，最终主动Abort。

### 原因

跨线程操作env提前改坏了对象类型字段。真正的Crash发生在GC搬迁阶段，因此GC栈不是踩内存发生时的第一现场。

---

## 七、ThreadSafeCallback中跨线程napi_wrap踩坏对象属性表

### 前置：典型cppcrash相关栈

**案例**

```text
Reason:Signal:SIGSEGV(SEGV_ACCERR)@0x00000024fe43c238
Fault thread info:
Tid:32859, Name:com.tencent.hqq
#00 pc 0000000000267fdc /system/lib64/platformsdk/libark_jsruntime.so
#01 pc 000000000022c794 /system/lib64/platformsdk/libark_jsruntime.so(ObjectOperator::AddProperty)
#03 pc 000000000022a338 /system/lib64/platformsdk/libark_jsruntime.so(ObjectRef::DefineProperty)
#04 pc 0000000000058948 /system/lib64/platformsdk/libace_napi.z.so(napi_wrap+472)
#05 pc 0000000000429cd8 /data/storage/el1/bundle/libs/arm64/libharmonyrtc.so
#10 at addVideoStream @qq/qqrtc (QQRtcDavRepo.ets:607:26)
#11 at OnUserVideoUpdate @qq/qqrtc (QQRtcDavRepo.ets:347:16)
#15 pc 000000000007a480 /system/lib64/platformsdk/libace_napi.z.so(napi_call_function+208)
#16 pc 00000000000084cc /system/lib64/libemitter_interops.z.so(ThreadSafeCallback)
#17 pc 00000000000416ec /system/lib64/platformsdk/libace_napi.z.so(NativeSafeAsyncWork::ProcessAsyncHandle)
```

### 规则

1. 崩溃发生在 `napi_wrap` 调用 `ObjectRef::DefineProperty`、`ObjectOperator::AddProperty` 时。
2. 故障地址为不可访问地址，说明对象属性表内存已经损坏。
3. 栈中包含 `libharmonyrtc.so`、`napi_wrap`、`napi_call_function` 和 `ThreadSafeCallback`。
4. ThreadSafeCallback支持跨线程投递，不代表回调中可以使用错误env或已被其他线程踩坏的目标对象。

### 结论

`libharmonyrtc.so` 在ThreadSafeCallback回调中调用 `napi_wrap` 时访问了已被踩坏的对象属性表。cppcrash堆栈不是跨线程操作env的第一现场，需要通过多线程检测继续定位对象最早被破坏的位置。

### 原因

回调使用了错误env，或目标对象此前已被其他线程的跨线程操作破坏。后续 `napi_wrap` 向对象添加属性时访问非法属性表地址并崩溃。

---

## 八、综合结论

以上7个案例均为跨线程使用env导致的踩内存问题，但Crash表现不同，可归纳为以下四类：

| Crash表现 | 案例 | 特征 |
|---|---|---|
| 有明确的多线程日志 | 案例1 | `LastFatalMessage` 包含 `CheckThread` 和 `ecma_vm cannot run in multi-thread` |
| 主线程或工作线程空指针、非法地址访问 | 案例2、3、4、7 | 堆栈包含业务代码和N-API调用，故障地址为NULL小偏移、ASCII字符串或其他非法地址 |
| GC并发标记阶段访问非法地址 | 案例5 | 堆栈只有GC帧，崩溃在 `ConcurrentMarker`、`NonMovableMarker` 中 |
| GC搬迁对象遇到非法类型Abort | 案例6 | 堆栈只有GC帧，`LastFatalMessage` 报 `unreachable type` |

关键判断依据：

1. 当Crash堆栈只有GC帧且没有业务代码时，大概率是跨线程踩内存的延迟爆炸，而不是GC自身问题。
2. 当故障地址包含ASCII字符串，例如案例3的 `0x0070697263736564`，说明JS对象内存已被跨线程操作踩坏。
3. 当故障地址为 `0x48`、`0x18` 等小偏移值时，说明对象本身或内部指针已经变为NULL。
4. 除案例1外，其余cppcrash堆栈均不是跨线程操作env的第一现场，需要开启多线程检测定位最早的违规访问位置。

解决建议：

1. 不在非Env所属线程直接调用N-API或访问 `napi_env`、`napi_ref`、`napi_value`。
2. 将JS操作投递到Env所属线程，并在目标线程重新获取和校验对象。
3. 对TaskPool、NativeAsyncWork、ThreadSafeCallback和组件回调增加线程归属检查。
4. 使用多线程检测捕获跨线程访问发生时的第一现场，再根据对应崩溃日志定位实际调用模块。
