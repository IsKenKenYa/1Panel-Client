/**
 * HiCollie定时器示例 - 构造任务执行超时事件
 * API: OH_HiCollie_SetTimer, OH_HiCollie_CancelTimer
 * 用途: 用于开发阶段测试APP_HICOLLIE事件订阅
 */

#include "napi/native_api.h"
#include "hicollie/hicollie.h"
#include "hilog/log.h"
#include <unistd.h>

#undef LOG_TAG
#define LOG_TAG "HiCollieTimer"

/**
 * 测试用例1：基本超时触发
 * 设置1秒超时阈值，实际执行2秒，触发超时事件
 */
static napi_value TestHiCollieTimerNdk(napi_env env, napi_callback_info exports)
{
    OH_LOG_INFO(LogType::LOG_APP, "TestHiCollieTimerNdk: Start");
    
    int timerId = -1;
    
    // 配置定时器参数
    HiCollie_SetTimerParam param = {
        "testTimer",                              // 定时器名称（标识）
        1,                                        // 超时阈值：1秒
        nullptr,                                  // 回调函数（可选）
        nullptr,                                  // 回调参数（可选）
        HiCollie_Flag::HICOLLIE_FLAG_LOG          // 动作：生成日志
    };
    
    // 设置定时器开始检测
    HiCollie_ErrorCode errorCode = OH_HiCollie_SetTimer(param, &timerId);
    
    if (errorCode != HICOLLIE_SUCCESS) {
        OH_LOG_ERROR(LogType::LOG_APP, 
            "OH_HiCollie_SetTimer failed: %{public}d", errorCode);
        return nullptr;
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Timer set successfully, ID: %{public}d", timerId);
    
    // 模拟任务执行超时（sleep 2秒超过阈值）
    OH_LOG_INFO(LogType::LOG_APP, "Task executing, will timeout in 2s...");
    sleep(2);
    
    // 取消定时器（若未在超时阈值内取消，将触发APP_HICOLLIE事件）
    OH_HiCollie_CancelTimer(timerId);
    OH_LOG_INFO(LogType::LOG_APP, "Timer cancelled");
    
    return nullptr;
}

/**
 * 测试用例2：正常执行（未超时）
 * 设置2秒超时阈值，实际执行1秒，不触发超时
 */
static napi_value TestNormalExecution(napi_env env, napi_callback_info exports)
{
    OH_LOG_INFO(LogType::LOG_APP, "TestNormalExecution: Start");
    
    int timerId = -1;
    
    HiCollie_SetTimerParam param = {
        "normalTimer",
        2,                                        // 超时阈值：2秒
        nullptr,
        nullptr,
        HiCollie_Flag::HICOLLIE_FLAG_LOG
    };
    
    HiCollie_ErrorCode errorCode = OH_HiCollie_SetTimer(param, &timerId);
    
    if (errorCode != HICOLLIE_SUCCESS) {
        OH_LOG_ERROR(LogType::LOG_APP, "SetTimer failed: %{public}d", errorCode);
        return nullptr;
    }
    
    // 模拟正常执行（1秒内完成）
    OH_LOG_INFO(LogType::LOG_APP, "Task executing normally (1s)...");
    sleep(1);
    
    // 及时取消定时器，不触发超时
    OH_HiCollie_CancelTimer(timerId);
    OH_LOG_INFO(LogType::LOG_APP, "Task completed, timer cancelled");
    
    return nullptr;
}

/**
 * 测试用例3：带回调的超时检测
 * 设置超时回调函数，自定义超时处理逻辑
 */
static void OnTimeoutCallback(void* userData)
{
    OH_LOG_WARN(LogType::LOG_APP, "Timeout callback triggered!");
    OH_LOG_WARN(LogType::LOG_APP, "User data: %{public}s", 
        userData ? (const char*)userData : "NULL");
    
    // 可执行自定义超时处理：
    // 1. 记录超时信息到日志
    // 2. 通知应用层
    // 3. 执行恢复逻辑
}

static napi_value TestHiCollieWithCallback(napi_env env, napi_callback_info exports)
{
    OH_LOG_INFO(LogType::LOG_APP, "TestHiCollieWithCallback: Start");
    
    int timerId = -1;
    const char* userData = "TestCallbackData";
    
    HiCollie_SetTimerParam param = {
        "callbackTimer",
        1,
        OnTimeoutCallback,                       // 超时回调函数
        (void*)userData,                         // 回调参数
        HiCollie_Flag::HICOLLIE_FLAG_LOG
    };
    
    HiCollie_ErrorCode errorCode = OH_HiCollie_SetTimer(param, &timerId);
    
    if (errorCode != HICOLLIE_SUCCESS) {
        OH_LOG_ERROR(LogType::LOG_APP, "SetTimer failed: %{public}d", errorCode);
        return nullptr;
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Timer with callback set, ID: %{public}d", timerId);
    
    // 模拟超时
    sleep(2);
    
    // 超时后取消（回调将被触发）
    OH_HiCollie_CancelTimer(timerId);
    OH_LOG_INFO(LogType::LOG_APP, "Timer cancelled after timeout");
    
    return nullptr;
}

/**
 * 测试用例4：错误场景演示
 * 演示各种错误码场景
 */
static napi_value TestErrorCases(napi_env env, napi_callback_info exports)
{
    OH_LOG_INFO(LogType::LOG_APP, "TestErrorCases: Start");
    
    int timerId = -1;
    
    // 错误1：空定时器名称
    HiCollie_SetTimerParam param1 = {
        "",                                      // 错误：空名称
        1,
        nullptr,
        nullptr,
        HiCollie_Flag::HICOLLIE_FLAG_LOG
    };
    
    HiCollie_ErrorCode error1 = OH_HiCollie_SetTimer(param1, &timerId);
    if (error1 == HICOLLIE_INVALID_TIMER_NAME) {
        OH_LOG_ERROR(LogType::LOG_APP, "Test case 1: Invalid timer name - PASS");
    }
    
    // 错误2：无效超时阈值（负数）
    HiCollie_SetTimerParam param2 = {
        "testTimer",
        -1,                                      // 错误：负数超时
        nullptr,
        nullptr,
        HiCollie_Flag::HICOLLIE_FLAG_LOG
    };
    
    HiCollie_ErrorCode error2 = OH_HiCollie_SetTimer(param2, &timerId);
    if (error2 == HICOLLIE_INVALID_TIMEOUT_VALUE) {
        OH_LOG_ERROR(LogType::LOG_APP, "Test case 2: Invalid timeout value - PASS");
    }
    
    // 错误3：NULL计时器ID指针
    HiCollie_SetTimerParam param3 = {
        "testTimer",
        1,
        nullptr,
        nullptr,
        HiCollie_Flag::HICOLLIE_FLAG_LOG
    };
    
    HiCollie_ErrorCode error3 = OH_HiCollie_SetTimer(param3, nullptr); // 错误：NULL指针
    if (error3 == HICOLLIE_WRONG_TIMER_ID_OUTPUT_PARAM) {
        OH_LOG_ERROR(LogType::LOG_APP, "Test case 3: NULL timer ID pointer - PASS");
    }
    
    return nullptr;
}

/**
 * 测试用例5：连续多次超时检测
 * 模拟多个任务的超时场景
 */
static napi_value TestMultipleTimeouts(napi_env env, napi_callback_info exports)
{
    OH_LOG_INFO(LogType::LOG_APP, "TestMultipleTimeouts: Start");
    
    // 任务1：正常执行
    int id1 = -1;
    HiCollie_SetTimerParam param1 = {
        "task1",
        2,
        nullptr,
        nullptr,
        HiCollie_Flag::HICOLLIE_FLAG_LOG
    };
    
    if (OH_HiCollie_SetTimer(param1, &id1) == HICOLLIE_SUCCESS) {
        OH_LOG_INFO(LogType::LOG_APP, "Task 1 started");
        sleep(1); // 正常完成
        OH_HiCollie_CancelTimer(id1);
        OH_LOG_INFO(LogType::LOG_APP, "Task 1 completed");
    }
    
    // 任务2：超时执行
    int id2 = -1;
    HiCollie_SetTimerParam param2 = {
        "task2",
        1,
        nullptr,
        nullptr,
        HiCollie_Flag::HICOLLIE_FLAG_LOG
    };
    
    if (OH_HiCollie_SetTimer(param2, &id2) == HICOLLIE_SUCCESS) {
        OH_LOG_INFO(LogType::LOG_APP, "Task 2 started");
        sleep(2); // 超时
        OH_HiCollie_CancelTimer(id2);
        OH_LOG_INFO(LogType::LOG_APP, "Task 2 timeout detected");
    }
    
    // 任务3：超时执行
    int id3 = -1;
    HiCollie_SetTimerParam param3 = {
        "task3",
        1,
        nullptr,
        nullptr,
        HiCollie_Flag::HICOLLIE_FLAG_LOG
    };
    
    if (OH_HiCollie_SetTimer(param3, &id3) == HICOLLIE_SUCCESS) {
        OH_LOG_INFO(LogType::LOG_APP, "Task 3 started");
        sleep(2); // 超时
        OH_HiCollie_CancelTimer(id3);
        OH_LOG_INFO(LogType::LOG_APP, "Task 3 timeout detected");
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "All tasks finished");
    
    return nullptr;
}

/**
 * 注册NAPI接口
 */
EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "TestHiCollieTimerNdk", nullptr, TestHiCollieTimerNdk, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "TestNormalExecution", nullptr, TestNormalExecution, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "TestHiCollieWithCallback", nullptr, TestHiCollieWithCallback, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "TestErrorCases", nullptr, TestErrorCases, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "TestMultipleTimeouts", nullptr, TestMultipleTimeouts, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "entry",
    .nm_priv = ((void*)0),
    .reserved = { 0 },
};

extern "C" __attribute__((constructor)) void RegisterEntryModule(void)
{
    napi_module_register(&demoModule);
}