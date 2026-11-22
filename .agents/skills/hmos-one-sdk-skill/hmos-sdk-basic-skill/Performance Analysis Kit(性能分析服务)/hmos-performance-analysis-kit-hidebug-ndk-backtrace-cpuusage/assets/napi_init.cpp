#include <thread>
#include "hidebug/hidebug.h"
#include "hilog/log.h"
#include "test_backtrace.h"

#undef LOG_TAG
#define LOG_TAG "testTag"

__attribute((noinline)) __attribute((optnone)) void TestNativeFrames(int i)
{
    if (i > 0) {
        TestNativeFrames(i - 1);
        return;
    }
    BacktraceCurrentThread();
}

__attribute((noinline)) __attribute((optnone)) napi_value TestBackTrace(napi_env env, napi_callback_info info)
{
    TestNativeFrames(1);
    return nullptr;
}

napi_value TestGetThreadCpuUsage(napi_env env, napi_callback_info info)
{
    HiDebug_ThreadCpuUsagePtr cpuUsage = OH_HiDebug_GetAppThreadCpuUsage();
    while (cpuUsage != nullptr) {
        OH_LOG_INFO(LogType::LOG_APP,
            "GetAppThreadCpuUsage: threadId %{public}d, cpuUsage: %{public}f", 
            cpuUsage->threadId, cpuUsage->cpuUsage);
        cpuUsage = cpuUsage->next; // 获取下一个线程的cpu使用率对象指针。
    }
    OH_HiDebug_FreeThreadCpuUsage(&cpuUsage); // 释放内存，防止内存泄露。
    return nullptr;
}

// 注册ArkTS接口
napi_property_descriptor desc[] = {
    { "testGetThreadCpuUsage", nullptr, TestGetThreadCpuUsage, nullptr, nullptr, nullptr, napi_default, nullptr },
    { "testBackTrace", nullptr, TestBackTrace, nullptr, nullptr, nullptr, napi_default, nullptr },
};