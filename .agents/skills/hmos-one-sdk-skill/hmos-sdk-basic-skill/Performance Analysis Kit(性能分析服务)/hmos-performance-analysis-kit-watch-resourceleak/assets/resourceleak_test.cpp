/**
 * 资源泄漏测试示例
 * 构造内存泄漏场景触发资源泄漏事件
 */

#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"
#include <iostream>
#include <fstream>
#include <sstream>
#include <thread>
#include <vector>

#undef LOG_TAG
#define LOG_TAG "ResourceLeakTest"

// 读 /proc/self/smaps_rollup 中的 PSS 字段,统计当前进程的 PSS (单位 KB)
static int GetCurrentProcessPss() {
    std::ifstream smapsFile("/proc/self/smaps_rollup");
    if (!smapsFile.is_open()) {
        std::cerr << "Failed to open /proc/self/smaps_rollup" << std::endl;
        return 0;
    }
    
    std::string line;
    int totalPss = 0;
    while (std::getline(smapsFile, line)) {
        if (line.find("Pss:") == 0) {
            std::istringstream iss(line);
            std::string label;
            int pss;
            iss >> label >> pss;
            totalPss += pss;
        }
    }
    smapsFile.close();
    
    std::cout << "Current pss: " << totalPss << " KB" << std::endl;
    return totalPss;
}

// 读取当前进程的 FD 数量
static int GetCurrentFd() {
    std::ifstream fdFile("/proc/self/fd_num");
    if (!fdFile.is_open()) {
        std::cerr << "Failed to open /proc/self/fd_num" << std::endl;
        return 0;
    }
    
    std::string line;
    std::getline(fdFile, line);
    fdFile.close();
    
    std::cout << "Current fd: " << line << std::endl;
    return std::stoi(line);
}

// 申请 size 字节内存并写入数据(用 'a' 填充),制造 native 内存增长
static bool InjectNativeLeakMallocWithSize(int size, char *p) {
    const size_t maxSafe = 1073741824;
    if (size < 0 || size > maxSafe) {
        printf("InjectNativeLeakMallocWithSize invalid size\n");
        return false;
    }
    
    p = (char *) malloc(size + 1);
    if (!p) {
        printf("InjectNativeLeakMallocWithSize malloc failed\n");
        return false;
    }
    
    void* err = memset(p, 'a', size);
    if (err == nullptr) {
        printf("InjectNativeLeakMallocWithSize memset failed\n");
        return false;
    }
    
    return true;
}

// 循环申请/释放内存,使进程 PSS 持续接近 target
static void InjectNativeLeakMallocUntil(int target) {
    constexpr int leakSizePerTime = 5000000;
    std::vector<char *> mems;
    int curPss = GetCurrentProcessPss();
    
    while (curPss != 0) {
        char *p = nullptr;
        if (curPss < target) {
            if (!InjectNativeLeakMallocWithSize(leakSizePerTime, p)) {
                printf("InjectNativeLeakMallocUntil target = %d failed\n", target);
            }
            mems.push_back(p);
            std::cout << "Inject size: " << leakSizePerTime << ", currentSize: " << mems.size() << std::endl;
        } else {
            if (mems.size() > 0) {
                char *dst = mems[0];
                mems.erase(mems.begin());
                free(dst);
            }
            std::cout << "Free size: " << leakSizePerTime << ", currentSize: " << mems.size() << std::endl;
        }
        curPss = GetCurrentProcessPss();
    }
    
    std::cout << std::endl;
    printf("InjectNativeLeakMallocUntil target = %d success\n", target);
}

// 启动后台执行的 InjectNativeLeakMallocUntil 线程,使 native 内存占用接近 leakSize
static void StartNativeLeak(int leakSize) {
    std::cout << "Start inject malloc until " << leakSize << " KB" << std::endl;
    std::thread t1(InjectNativeLeakMallocUntil, leakSize);
    t1.detach();
    std::cout << "Inject finished." << std::endl;
}

// N-API 导出方法
static napi_value LeakMB(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        napi_throw_type_error(env, nullptr, "Expected 1 argument");
        return nullptr;
    }
    
    double x = 0;
    if (napi_get_value_double(env, args[0], &x) != napi_ok) {
        napi_throw_type_error(env, nullptr, "Argument must be a number");
        return nullptr;
    }
    
    const size_t kilobyte = 1024;
    StartNativeLeak(static_cast<size_t>(x * kilobyte));
    
    napi_value rtn;
    napi_get_undefined(env, &rtn);
    return rtn;
}

static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "leakMB", nullptr, LeakMB, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

EXTERN_C_START
NAPI_MODULE_AUTO_EXPORT(entry, Init)
EXTERN_C_END