#include <thread>
#include <condition_variable>
#include <csignal>
#include <unistd.h>
#include <sys/syscall.h>
#include "hidebug/hidebug.h"
#include "hilog/log.h"

#define MAX_FRAME_SIZE 256

namespace {
    constexpr auto LOG_PRINT_DOMAIN = 0xFF00;
}

class BackTraceObject {
public:
    static BackTraceObject& GetInstance() {
        static BackTraceObject instance;
        return instance;
    }
    
    BackTraceObject(const BackTraceObject&) = delete;
    BackTraceObject& operator=(const BackTraceObject&) = delete;
    BackTraceObject(BackTraceObject&&) = delete;
    BackTraceObject& operator=(BackTraceObject&&) = delete;
    
    bool Init(uint32_t size) {
        backtraceObject_ = OH_HiDebug_CreateBacktraceObject();
        if (backtraceObject_ == nullptr || size > MAX_FRAME_SIZE) {
            return false;
        }
        
        pcs_ = new (std::nothrow) void* [size]{nullptr};
        if (pcs_ == nullptr) {
            OH_HiDebug_DestroyBacktraceObject(backtraceObject_);
            backtraceObject_ = nullptr;
            return false;
        }
        
        return true;
    }
    
    void Release() {
        if (backtraceObject_ != nullptr) {
            OH_HiDebug_DestroyBacktraceObject(backtraceObject_);
            backtraceObject_ = nullptr;
        }
        if (pcs_ != nullptr) {
            delete[] pcs_;
            pcs_ = nullptr;
        }
    }
    
    int BackTraceFromFp(void* startFp, int size) {
        if (size <= MAX_FRAME_SIZE) {
            return OH_HiDebug_BacktraceFromFp(backtraceObject_, startFp, pcs_, size);
        }
        return 0;
    }
    
    void SymbolicAddress(int index) {
        if (index < 0 || index >= MAX_FRAME_SIZE || pcs_ == nullptr) {
            return;
        }
        
        OH_HiDebug_SymbolicAddress(backtraceObject_, pcs_[index], this,
            [] (void* pc, void* arg, const HiDebug_StackFrame* frame) {
                reinterpret_cast<BackTraceObject*>(arg)->PrintStackFrame(pc, *frame);
            });
    }
    
    void PrintStackFrame(void* pc, const HiDebug_StackFrame& frame) {
        if (frame.type == HIDEBUG_STACK_FRAME_TYPE_JS) {
            OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, "HiDebug",
                "JS stack frame: pc=%{public}p, relativePc=%{public}p, "
                "line=%{public}d, column=%{public}d, "
                "mapName=%{public}s, functionName=%{public}s, "
                "url=%{public}s, packageName=%{public}s",
                pc,
                reinterpret_cast<void*>(frame.frame.js.relativePc),
                frame.frame.js.line,
                frame.frame.js.column,
                frame.frame.js.mapName,
                frame.frame.js.functionName,
                frame.frame.js.url,
                frame.frame.js.packageName);
        } else {
            OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, "HiDebug",
                "Native stack frame: pc=%{public}p, relativePc=%{public}p, "
                "funcOffset=%{public}p, mapName=%{public}s, "
                "functionName=%{public}s, buildId=%{public}s",
                pc,
                reinterpret_cast<void*>(frame.frame.native.relativePc),
                reinterpret_cast<void*>(frame.frame.native.funcOffset),
                frame.frame.native.mapName,
                frame.frame.native.functionName,
                frame.frame.native.buildId);
        }
    }

private:
    BackTraceObject() = default;
    ~BackTraceObject() = default;
    HiDebug_Backtrace_Object backtraceObject_ = nullptr;
    void** pcs_ = nullptr;
};

void BacktraceCurrentThread() {
    if (!BackTraceObject::GetInstance().Init(MAX_FRAME_SIZE)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_PRINT_DOMAIN, "HiDebug",
            "Failed to init backtrace object");
        BackTraceObject::GetInstance().Release();
        return;
    }
    
    int pcSize = BackTraceObject::GetInstance().BackTraceFromFp(
        __builtin_frame_address(0), MAX_FRAME_SIZE);
    
    if (pcSize == 0) {
        OH_LOG_Print(LOG_APP, LOG_WARN, LOG_PRINT_DOMAIN, "HiDebug",
            "No stack frames captured");
        BackTraceObject::GetInstance().Release();
        return;
    }
    
    OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, "HiDebug",
        "Captured %{public}d stack frames", pcSize);
    
    for (int i = 0; i < pcSize; i++) {
        BackTraceObject::GetInstance().SymbolicAddress(i);
    }
    
    BackTraceObject::GetInstance().Release();
}

void GetThreadCpuUsage() {
    HiDebug_ThreadCpuUsagePtr cpuUsage = OH_HiDebug_GetAppThreadCpuUsage();
    
    if (cpuUsage == nullptr) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_PRINT_DOMAIN, "HiDebug",
            "Failed to get thread CPU usage");
        return;
    }
    
    int threadCount = 0;
    double totalUsage = 0.0;
    
    HiDebug_ThreadCpuUsagePtr current = cpuUsage;
    while (current != nullptr) {
        threadCount++;
        totalUsage += current->cpuUsage;
        
        OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, "HiDebug",
            "Thread %{public}d: CPU usage = %{public}f%%",
            current->threadId, current->cpuUsage * 100);
        
        current = current->next;
    }
    
    OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, "HiDebug",
        "Total %{public}d threads, average CPU usage = %{public}f%%",
        threadCount, (totalUsage / threadCount) * 100);
    
    OH_HiDebug_FreeThreadCpuUsage(&cpuUsage);
}

__attribute((noinline)) __attribute((optnone)) void TestNativeFrames(int i) {
    if (i > 0) {
        TestNativeFrames(i - 1);
        return;
    }
    BacktraceCurrentThread();
}

int main() {
    OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, "HiDebug",
        "=== HiDebug NDK Example ===");
    
    OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, "HiDebug",
        "Test 1: Thread stack backtrace");
    TestNativeFrames(5);
    
    OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, "HiDebug",
        "Test 2: Thread CPU usage");
    GetThreadCpuUsage();
    
    OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, "HiDebug",
        "=== Test completed ===");
    
    return 0;
}