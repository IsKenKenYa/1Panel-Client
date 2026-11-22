/**
 * @file example_write_event.cpp
 * @brief 完整示例:事件打点功能(C/C++)
 * 
 * 本示例演示如何使用HiAppEvent C API实现应用事件打点
 */

#include "napi/native_api.h"
#include "hiappevent/hiappevent.h"
#include "hilog/log.h"
#include <ctime>
#include <cstring>

#undef LOG_TAG
#define LOG_TAG "EventWriter"

/**
 * 写入用户行为事件
 * 
 * @param userId 用户ID
 * @param action 用户行为描述
 * @param timestamp 行为发生时间戳
 */
static napi_value WriteUserBehaviorEvent(napi_env env, napi_callback_info info) {
    // 创建参数列表
    ParamList params = OH_HiAppEvent_CreateParamList();
    if (params == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create param list");
        return nullptr;
    }
    
    // 添加用户行为参数
    params = OH_HiAppEvent_AddStringParam(params, "userId", "user_12345");
    params = OH_HiAppEvent_AddStringParam(params, "action", "click_button");
    params = OH_HiAppEvent_AddInt64Param(params, "timestamp", time(nullptr));
    params = OH_HiAppEvent_AddBoolParam(params, "success", true);
    
    // 写入行为事件(事件领域="user",事件名称="behavior",事件类型=BEHAVIOR)
    int result = OH_HiAppEvent_Write("user", "behavior", EventType::BEHAVIOR, params);
    if (result < 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to write behavior event: %{public}d", result);
    } else if (result > 0) {
        OH_LOG_WARN(LogType::LOG_APP, "Event written with invalid params: %{public}d", result);
    } else {
        OH_LOG_INFO(LogType::LOG_APP, "User behavior event written successfully");
    }
    
    // 销毁参数列表
    OH_HiAppEvent_DestroyParamList(params);
    
    return nullptr;
}

/**
 * 写入性能统计事件
 * 
 * @param operation 操作名称
 * @param duration 耗时(毫秒)
 * @param success 是否成功
 */
static napi_value WritePerformanceEvent(napi_env env, napi_callback_info info) {
    // 创建参数列表
    ParamList params = OH_HiAppEvent_CreateParamList();
    if (params == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create param list");
        return nullptr;
    }
    
    // 添加性能参数
    params = OH_HiAppEvent_AddStringParam(params, "operation", "load_page");
    params = OH_HiAppEvent_AddInt64Param(params, "duration", 150);
    params = OH_HiAppEvent_AddBoolParam(params, "success", true);
    params = OH_HiAppEvent_AddFloatParam(params, "cpuUsage", 25.5f);
    params = OH_HiAppEvent_AddInt32Param(params, "memoryUsage", 1024);
    
    // 写入统计事件(事件领域="performance",事件名称="stats",事件类型=STATISTIC)
    int result = OH_HiAppEvent_Write("performance", "stats", EventType::STATISTIC, params);
    if (result < 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to write performance event: %{public}d", result);
    } else if (result > 0) {
        OH_LOG_WARN(LogType::LOG_APP, "Event written with invalid params: %{public}d", result);
    } else {
        OH_LOG_INFO(LogType::LOG_APP, "Performance event written successfully");
    }
    
    // 销毁参数列表
    OH_HiAppEvent_DestroyParamList(params);
    
    return nullptr;
}

/**
 * 写入故障事件
 * 
 * @param errorType 错误类型
 * @param errorMsg 错误消息
 * @param stackTrace 调用栈
 */
static napi_value WriteFaultEvent(napi_env env, napi_callback_info info) {
    // 创建参数列表
    ParamList params = OH_HiAppEvent_CreateParamList();
    if (params == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create param list");
        return nullptr;
    }
    
    // 添加故障参数
    params = OH_HiAppEvent_AddStringParam(params, "errorType", "NullPointerException");
    params = OH_HiAppEvent_AddStringParam(params, "errorMsg", "Object reference not set");
    params = OH_HiAppEvent_AddStringParam(params, "stackTrace", "at line 123 in file main.cpp");
    params = OH_HiAppEvent_AddInt64Param(params, "timestamp", time(nullptr));
    
    // 写入故障事件(事件领域="fault",事件名称="error",事件类型=FAULT)
    int result = OH_HiAppEvent_Write("fault", "error", EventType::FAULT, params);
    if (result < 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to write fault event: %{public}d", result);
    } else if (result > 0) {
        OH_LOG_WARN(LogType::LOG_APP, "Event written with invalid params: %{public}d", result);
    } else {
        OH_LOG_INFO(LogType::LOG_APP, "Fault event written successfully");
    }
    
    // 销毁参数列表
    OH_HiAppEvent_DestroyParamList(params);
    
    return nullptr;
}

/**
 * 写入安全事件
 * 
 * @param eventType 安全事件类型
 * @param riskLevel 风险等级
 * @param details 详细信息
 */
static napi_value WriteSecurityEvent(napi_env env, napi_callback_info info) {
    // 创建参数列表
    ParamList params = OH_HiAppEvent_CreateParamList();
    if (params == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create param list");
        return nullptr;
    }
    
    // 添加安全参数
    params = OH_HiAppEvent_AddStringParam(params, "eventType", "permission_denied");
    params = OH_HiAppEvent_AddInt32Param(params, "riskLevel", 2);
    params = OH_HiAppEvent_AddStringParam(params, "details", "Camera permission denied by user");
    params = OH_HiAppEvent_AddInt64Param(params, "timestamp", time(nullptr));
    
    // 写入安全事件(事件领域="security",事件名称="alert",事件类型=SECURITY)
    int result = OH_HiAppEvent_Write("security", "alert", EventType::SECURITY, params);
    if (result < 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to write security event: %{public}d", result);
    } else if (result > 0) {
        OH_LOG_WARN(LogType::LOG_APP, "Event written with invalid params: %{public}d", result);
    } else {
        OH_LOG_INFO(LogType::LOG_APP, "Security event written successfully");
    }
    
    // 销毁参数列表
    OH_HiAppEvent_DestroyParamList(params);
    
    return nullptr;
}

/**
 * 写入数组参数事件
 * 
 * @param userIds 用户ID数组
 * @param scores 分数数组
 */
static napi_value WriteArrayParamEvent(napi_env env, napi_callback_info info) {
    // 创建参数列表
    ParamList params = OH_HiAppEvent_CreateParamList();
    if (params == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create param list");
        return nullptr;
    }
    
    // 准备数组参数
    const char* userIds[] = {"user1", "user2", "user3"};
    int64_t scores[] = {100, 95, 88};
    int userIdsSize = 3;
    int scoresSize = 3;
    
    // 添加数组参数
    params = OH_HiAppEvent_AddStringArrayParam(params, "userIds", userIds, userIdsSize);
    params = OH_HiAppEvent_AddInt64ArrayParam(params, "scores", scores, scoresSize);
    
    // 写入事件
    int result = OH_HiAppEvent_Write("game", "ranking", EventType::STATISTIC, params);
    if (result < 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to write array event: %{public}d", result);
    } else if (result > 0) {
        OH_LOG_WARN(LogType::LOG_APP, "Event written with invalid params: %{public}d", result);
    } else {
        OH_LOG_INFO(LogType::LOG_APP, "Array param event written successfully");
    }
    
    // 销毁参数列表
    OH_HiAppEvent_DestroyParamList(params);
    
    return nullptr;
}

/**
 * 初始化模块导出
 */
EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "writeUserBehaviorEvent", nullptr, WriteUserBehaviorEvent, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "writePerformanceEvent", nullptr, WritePerformanceEvent, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "writeFaultEvent", nullptr, WriteFaultEvent, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "writeSecurityEvent", nullptr, WriteSecurityEvent, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "writeArrayParamEvent", nullptr, WriteArrayParamEvent, nullptr, nullptr, nullptr, napi_default, nullptr },
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

extern napi_module* NAPI_GetModuleName(void) {
    return &demoModule;
}