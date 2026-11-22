/**
 * @file example_crash_watcher.cpp
 * @brief 完整示例:订阅崩溃事件(C/C++)
 * 
 * 本示例演示如何使用HiAppEvent C API订阅系统崩溃事件(APP_CRASH)
 */

#include "napi/native_api.h"
#include "../../../build/jsoncpp-1.9.6/include/json/json.h"
#include "hiappevent/hiappevent.h"
#include "hilog/log.h"
#include <cstring>
#include <cstdlib>

#undef LOG_TAG
#define LOG_TAG "CrashWatcher"

// 定义全局观察者指针
static HiAppEvent_Watcher* crashWatcher = nullptr;

/**
 * OnReceive回调函数:立即触发模式
 * 接收到崩溃事件后立即触发此回调
 * 
 * @param domain 事件领域
 * @param appEventGroups 事件组数组
 * @param groupLen 事件组数量
 */
static void OnCrashReceive(const char* domain, 
                           const struct HiAppEvent_AppEventGroup* appEventGroups, 
                           uint32_t groupLen) {
    OH_LOG_INFO(LogType::LOG_APP, "Received crash events with OnReceive callback");
    
    for (uint32_t i = 0; i < groupLen; ++i) {
        for (uint32_t j = 0; j < appEventGroups[i].infoLen; ++j) {
            // 检查是否为崩溃事件
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) != 0 ||
                strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_APP_CRASH) != 0) {
                continue;
            }
            
            // 深拷贝事件参数JSON字符串
            char* paramsCopy = strdup(appEventGroups[i].appEventInfos[j].params);
            
            // 解析JSON参数
            Json::Value params;
            Json::Reader reader(Json::Features::strictMode());
            Json::FastWriter writer;
            
            if (reader.parse(paramsCopy, params)) {
                // 获取崩溃时间戳
                int64_t crashTime = params["time"].asInt64();
                OH_LOG_INFO(LogType::LOG_APP, "Crash time: %{public}lld", crashTime);
                
                // 获取崩溃应用包名
                std::string bundleName = params["bundle_name"].asString();
                OH_LOG_INFO(LogType::LOG_APP, "Bundle name: %{public}s", bundleName.c_str());
                
                // 获取故障日志文件路径
                std::string externalLog = writer.write(params["external_log"]);
                OH_LOG_INFO(LogType::LOG_APP, "External log: %{public}s", externalLog.c_str());
                
                // 处理崩溃事件(可添加自定义逻辑)
                ProcessCrashEvent(crashTime, bundleName, externalLog);
            }
            
            // 释放深拷贝的内存
            free(paramsCopy);
        }
    }
}

/**
 * 处理崩溃事件的业务逻辑
 * 
 * @param crashTime 崩溃时间戳
 * @param bundleName 应用包名
 * @param externalLog 故障日志路径
 */
static void ProcessCrashEvent(int64_t crashTime, 
                              const std::string& bundleName, 
                              const std::string& externalLog) {
    OH_LOG_INFO(LogType::LOG_APP, "Processing crash event for app: %{public}s", bundleName.c_str());
    
    // 可添加自定义崩溃处理逻辑:
    // 1. 上报崩溃信息到服务器
    // 2. 记录崩溃日志到本地文件
    // 3. 发送崩溃通知给用户
    // 4. 重启应用或执行恢复操作
}

/**
 * 注册崩溃事件观察者
 * 
 * @return 0成功,其他值失败
 */
static napi_value RegisterCrashWatcher(napi_env env, napi_callback_info info) {
    // 创建观察者
    crashWatcher = OH_HiAppEvent_CreateWatcher("AppCrashWatcher");
    if (crashWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create crash watcher");
        return nullptr;
    }
    
    // 设置事件过滤:订阅系统崩溃事件
    const char* names[] = {EVENT_APP_CRASH};
    int result = OH_HiAppEvent_SetAppEventFilter(crashWatcher, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(crashWatcher);
        crashWatcher = nullptr;
        return nullptr;
    }
    
    // 设置OnReceive回调
    result = OH_HiAppEvent_SetWatcherOnReceive(crashWatcher, OnCrashReceive);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set OnReceive: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(crashWatcher);
        crashWatcher = nullptr;
        return nullptr;
    }
    
    // 添加观察者开始监听
    result = OH_HiAppEvent_AddWatcher(crashWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(crashWatcher);
        crashWatcher = nullptr;
        return nullptr;
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Crash watcher registered successfully");
    return nullptr;
}

/**
 * 移除崩溃事件观察者
 */
static napi_value RemoveCrashWatcher(napi_env env, napi_callback_info info) {
    if (crashWatcher == nullptr) {
        OH_LOG_WARN(LogType::LOG_APP, "Crash watcher is already null");
        return nullptr;
    }
    
    // 移除观察者停止监听
    int result = OH_HiAppEvent_RemoveWatcher(crashWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to remove watcher: %{public}d", result);
    } else {
        OH_LOG_INFO(LogType::LOG_APP, "Crash watcher removed successfully");
    }
    
    return nullptr;
}

/**
 * 销毁崩溃事件观察者
 */
static napi_value DestroyCrashWatcher(napi_env env, napi_callback_info info) {
    if (crashWatcher == nullptr) {
        OH_LOG_WARN(LogType::LOG_APP, "Crash watcher is already null");
        return nullptr;
    }
    
    // 先移除观察者
    OH_HiAppEvent_RemoveWatcher(crashWatcher);
    
    // 销毁观察者释放内存
    OH_HiAppEvent_DestroyWatcher(crashWatcher);
    crashWatcher = nullptr;
    
    OH_LOG_INFO(LogType::LOG_APP, "Crash watcher destroyed successfully");
    return nullptr;
}

/**
 * 初始化模块导出
 */
EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "registerCrashWatcher", nullptr, RegisterCrashWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removeCrashWatcher", nullptr, RemoveCrashWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "destroyCrashWatcher", nullptr, DestroyCrashWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
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