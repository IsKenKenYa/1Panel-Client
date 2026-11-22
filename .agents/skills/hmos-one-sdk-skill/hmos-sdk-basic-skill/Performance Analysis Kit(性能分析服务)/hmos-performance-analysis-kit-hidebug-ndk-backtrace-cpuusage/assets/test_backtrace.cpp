#include "test_backtrace.h"
#include <condition_variable>
#include <csignal>
#include <unistd.h>
#include <sys/syscall.h>
#include "hidebug/hidebug.h"
#include "hilog/log.h"

#define MAX_FRAME_SIZE 256 // 最大栈回溯深度，应根据业务场景调整该值。

namespace {
    constexpr auto LOG_PRINT_DOMAIN = 0xFF00;
}

class BackTraceObject { // 封装了抓栈过程中需要使用的资源，在使用过程中请注意线程安全和异步信号安全。
public:
    static BackTraceObject& GetInstance();
    BackTraceObject(const BackTraceObject&) = delete;
    BackTraceObject& operator=(const BackTraceObject&) = delete;
    BackTraceObject(BackTraceObject&&) = delete;
    BackTraceObject& operator=(BackTraceObject&&) = delete;
    
    bool Init(uint32_t size);
    void Release();
    int BackTraceFromFp(void* startFp, int size); // 该函数异步信号安全。
    void SymbolicAddress(int index); // 该函数耗费性能，请避免频繁调用。
    void PrintStackFrame(void* pc, const HiDebug_StackFrame& frame);
    
private:
    BackTraceObject() = default;
    ~BackTraceObject() = default;
    HiDebug_Backtrace_Object backtraceObject_ = nullptr;
    void** pcs_ = nullptr;
};

BackTraceObject& BackTraceObject::GetInstance() // 单例模式，用于信号处理和请求抓栈线程的数据交互。注意该类非异步信号安全，业务逻辑应确保同一时刻仅单个线程访问。
{
    static BackTraceObject instance;
    return instance;
}

bool BackTraceObject::Init(uint32_t size) // 初始化资源。
{
    backtraceObject_ = OH_HiDebug_CreateBacktraceObject();
    if (backtraceObject_ == nullptr || size > MAX_FRAME_SIZE) {
        return false;
    }
    pcs_ = new (std::nothrow) void* [size]{nullptr};
    if (pcs_ == nullptr) {
        return false;
    }
    return true;
}

void BackTraceObject::Release() // 释放资源。
{
    OH_HiDebug_DestroyBacktraceObject(backtraceObject_);
    backtraceObject_ = nullptr;
    delete[] pcs_;
    pcs_ = nullptr;
}

int BackTraceObject::BackTraceFromFp(void* startFp, int size) // 栈回溯获取pc地址。
{
    if (size <= MAX_FRAME_SIZE) {
        return OH_HiDebug_BacktraceFromFp(backtraceObject_, startFp, pcs_, size); // OH_HiDebug_BacktraceFromFp接口调用示例。
    }
    return 0;
}

void BackTraceObject::PrintStackFrame(void* pc, const HiDebug_StackFrame& frame) // 输出栈内容。
{
    if (frame.type == HIDEBUG_STACK_FRAME_TYPE_JS) { // 根据栈帧的类型，区分不同的栈帧输出方式。
        OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, "testTag",
            "js stack frame info for pc: %{public}p is "
            "relativePc: %{public}p "
            "line: %{public}d "
            "column: %{public}d "
            "mapName: %{public}s "
            "functionName: %{public}s "
            "url: %{public}s "
            "packageName: %{public}s.",
            pc,
            reinterpret_cast<void*>(frame.frame.js.relativePc),
            frame.frame.js.line,
            frame.frame.js.column,
            frame.frame.js.mapName,
            frame.frame.js.functionName,
            frame.frame.js.url,
            frame.frame.js.packageName);
    } else {
        OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, "testTag",
            "native stack frame info for pc: %{public}p is "
            "relativePc: %{public}p "
            "funcOffset: %{public}p "
            "mapName: %{public}s "
            "functionName: %{public}s "
            "buildId: %{public}s "
            "reserved: %{public}s.",
            pc,
            reinterpret_cast<void*>(frame.frame.native.relativePc),
            reinterpret_cast<void*>(frame.frame.native.funcOffset),
            frame.frame.native.mapName,
            frame.frame.native.functionName,
            frame.frame.native.buildId,
            frame.frame.native.reserved);
    }
}

void BackTraceObject::SymbolicAddress(int index)  // 栈解析接口。
{
    if (index < 0 || index >= MAX_FRAME_SIZE) {
        return;
    }
    OH_HiDebug_SymbolicAddress(backtraceObject_, pcs_[index], this,
        [] (void* pc, void* arg, const HiDebug_StackFrame* frame) {
            reinterpret_cast<BackTraceObject*>(arg)->PrintStackFrame(pc, *frame);
        }); // 调用OH_HiDebug_SymbolicAddress接口解析栈。
}

void BacktraceCurrentThread() // 该接口非线程安全，同一时刻只能由一个线程使用。
{
    if (!BackTraceObject::GetInstance().Init(MAX_FRAME_SIZE)) { // 注意：在调用栈回溯函数之前，需申请资源，且不可重复初始化。
        BackTraceObject::GetInstance().Release();
        OH_LOG_Print(LOG_APP, LOG_WARN, LOG_PRINT_DOMAIN, "testTag", "failed init backtrace object.");
        return;
    }
    int pcSize = BackTraceObject::GetInstance().BackTraceFromFp(__builtin_frame_address(0), MAX_FRAME_SIZE);
    for (int i = 0; i < pcSize; i++) {
        BackTraceObject::GetInstance().SymbolicAddress(i); // 主线程获取pc后，对pc值进行栈解析。
    }
    BackTraceObject::GetInstance().Release(); // 栈回溯并且解析结束后，及时释放资源。
}