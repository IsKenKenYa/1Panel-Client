/**
 * HiAppEvent订阅应用终止事件完整示例
 * 
 * 本示例展示如何使用HiAppEvent API订阅应用终止事件（APP_KILLED）
 * 包括：
 * 1. 创建事件观察者
 * 2. 设置事件过滤器
 * 3. 实现回调函数处理事件
 * 4. 添加观察者开始监听
 * 5. 移除和销毁观察者
 * 
 * 编译要求：
 * - HarmonyOS SDK API version >= 20
 * - C++17标准
 * - jsoncpp库
 * - libhiappevent_ndk.z.so
 * - libhilog_ndk.z.so
 */

#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"
#include "hiappevent/hiappevent_event.h"
#include <thread>
#include <string>
#include <mutex>

#undef LOG_TAG
#define LOG_TAG "AppKilledEventWatcher"

// 观察者指针，用于缓存创建的观察者
static HiAppEvent_Watcher *systemEventWatcher = nullptr;

// 线程安全的日志记录器
static std::mutex logMutex;

/**
 * 记录事件日志（线程安全）
 * 
 * @param level 日志级别
 * @param message 日志消息
 */
static void LogEvent(int level, const std::string& message) {
    std::lock_guard<std::mutex> lock(logMutex);
    switch (level) {
        case 0:
            OH_LOG_INFO(LogType::LOG_APP, "%{public}s", message.c_str());
            break;
        case 1:
            OH_LOG_WARN(LogType::LOG_APP, "%{public}s", message.c_str());
            break;
        case 2:
            OH_LOG_ERROR(LogType::LOG_APP, "%{public}s", message.c_str());
            break;
        default:
            OH_LOG_INFO(LogType::LOG_APP, "%{public}s", message.c_str());
    }
}

/**
 * 处理终止原因
 * 根据终止原因类型进行不同的处理
 * 
 * @param reason 终止原因字符串
 */
static void HandleKillReason(const std::string& reason) {
    // 内存相关终止原因
    if (reason.find("Memory") != std::string::npos || 
        reason.find("Leak") != std::string::npos ||
        reason.find("OOM") != std::string::npos ||
        reason.find("Killer") != std::string::npos) {
        LogEvent(2, "Memory-related termination detected: " + reason);
        // TODO: 上报内存泄漏告警
        // TODO: 记录内存使用情况
    }
    // CPU相关终止原因
    else if (reason.find("CPU") != std::string::npos ||
             reason.find("Highload") != std::string::npos) {
        LogEvent(2, "CPU-related termination detected: " + reason);
        // TODO: 上报CPU高负载告警
    }
    // 资源泄漏相关终止原因
    else if (reason.find("ResourceLeak") != std::string::npos) {
        LogEvent(2, "Resource leak detected: " + reason);
        // TODO: 上报资源泄漏告警
        // TODO: 记录泄漏类型和资源使用情况
    }
    // 用户主动终止
    else if (reason == "UserRequest" || reason == "KillApplication") {
        LogEvent(0, "User-initiated termination: " + reason);
        // 用户主动终止，无需告警
    }
    // 其他终止原因
    else {
        LogEvent(1, "Other termination reason: " + reason);
        // TODO: 记录其他终止原因
    }
}

/**
 * OnReceive回调函数
 * 接收事件组数据，解析应用终止事件参数
 * 
 * @param domain 事件领域
 * @param appEventGroups 事件组数组
 * @param groupLen 事件组数组长度
 */
static void OnReceive(const char *domain, 
                      const struct HiAppEvent_AppEventGroup *appEventGroups, 
                      uint32_t groupLen) {
    LogEvent(0, "OnReceive callback triggered, groupLen=" + std::to_string(groupLen));
    
    for (uint32_t i = 0; i < groupLen; ++i) {
        for (uint32_t j = 0; j < appEventGroups[i].infoLen; ++j) {
            // 输出事件基本信息
            std::string eventDomain = appEventGroups[i].appEventInfos[j].domain;
            std::string eventName = appEventGroups[i].appEventInfos[j].name;
            int eventType = appEventGroups[i].appEventInfos[j].type;
            
            LogEvent(0, "Event received: domain=" + eventDomain + 
                     ", name=" + eventName + ", type=" + std::to_string(eventType));
            
            // 检查是否为应用终止事件
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) == 0 &&
                strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_APP_KILLED) == 0) {
                
                LogEvent(0, "APP_KILLED event detected, parsing params...");
                
                // 解析事件参数JSON字符串
                Json::Value params;
                Json::Reader reader(Json::Features::strictMode());
                
                std::string paramsStr = appEventGroups[i].appEventInfos[j].params;
                
                if (paramsStr.empty()) {
                    LogEvent(1, "Event params string is empty");
                    continue;
                }
                
                if (reader.parse(paramsStr, params)) {
                    // 提取事件参数
                    try {
                        int64_t time = params["time"].asInt64();
                        std::string reason = params["reason"].asString();
                        std::string foreground = params["foreground"].asString();
                        std::string appRunningUniqueId = params["app_running_unique_id"].asString();
                        std::string bundleVersion = params["bundle_version"].asString();
                        
                        // 输出事件参数
                        LogEvent(0, "Event params:");
                        LogEvent(0, "  time=" + std::to_string(time));
                        LogEvent(0, "  reason=" + reason);
                        LogEvent(0, "  foreground=" + foreground);
                        LogEvent(0, "  app_running_unique_id=" + appRunningUniqueId);
                        LogEvent(0, "  bundle_version=" + bundleVersion);
                        
                        // 处理终止原因
                        HandleKillReason(reason);
                        
                        // TODO: 开发者可以在此处添加自定义业务处理逻辑
                        // 例如：
                        // 1. 上报事件到服务器
                        // 2. 记录事件到本地文件
                        // 3. 触发告警通知
                        // 4. 统计分析终止原因
                        
                    } catch (const std::exception& e) {
                        LogEvent(2, "Exception while parsing params: " + std::string(e.what()));
                    }
                } else {
                    LogEvent(2, "Failed to parse event params JSON: " + reader.getFormattedErrorMessages());
                }
            }
        }
    }
}

/**
 * 创建并注册事件观察者
 * 
 * @param env napi环境
 * @param info napi回调信息
 * @return napi_value
 */
static napi_value RegisterWatcher(napi_env env, napi_callback_info info) {
    LogEvent(0, "RegisterWatcher called");
    
    // 检查观察者是否已存在
    if (systemEventWatcher != nullptr) {
        LogEvent(1, "Watcher already exists, removing old watcher first");
        OH_HiAppEvent_RemoveWatcher(systemEventWatcher);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
    }
    
    // 1. 创建观察者
    systemEventWatcher = OH_HiAppEvent_CreateWatcher("AppKilledEventWatcher");
    if (systemEventWatcher == nullptr) {
        LogEvent(2, "Failed to create watcher, name parameter might be invalid");
        return {};
    }
    LogEvent(0, "Watcher created successfully");
    
    // 2. 设置事件过滤器
    const char *names[] = {EVENT_APP_KILLED};
    int ret = OH_HiAppEvent_SetAppEventFilter(systemEventWatcher, DOMAIN_OS, 0, names, 1);
    if (ret != 0) {
        LogEvent(2, "Failed to set app event filter, error=" + std::to_string(ret));
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        return {};
    }
    LogEvent(0, "Event filter set successfully, domain=DOMAIN_OS, event=EVENT_APP_KILLED");
    
    // 3. 设置回调函数
    ret = OH_HiAppEvent_SetWatcherOnReceive(systemEventWatcher, OnReceive);
    if (ret != 0) {
        LogEvent(2, "Failed to set watcher on receive, error=" + std::to_string(ret));
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        return {};
    }
    LogEvent(0, "OnReceive callback set successfully");
    
    // 4. 添加观察者，开始监听
    ret = OH_HiAppEvent_AddWatcher(systemEventWatcher);
    if (ret != 0) {
        LogEvent(2, "Failed to add watcher, error=" + std::to_string(ret));
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        return {};
    }
    LogEvent(0, "Watcher added successfully, now listening for APP_KILLED events");
    
    return {};
}

/**
 * 移除事件观察者
 * 仅停止监听，观察者仍常驻内存
 * 
 * @param env napi环境
 * @param info napi回调信息
 * @return napi_value
 */
static napi_value RemoveWatcher(napi_env env, napi_callback_info info) {
    LogEvent(0, "RemoveWatcher called");
    
    if (systemEventWatcher == nullptr) {
        LogEvent(1, "Watcher is already null, nothing to remove");
        return {};
    }
    
    int ret = OH_HiAppEvent_RemoveWatcher(systemEventWatcher);
    if (ret != 0) {
        LogEvent(2, "Failed to remove watcher, error=" + std::to_string(ret));
    } else {
        LogEvent(0, "Watcher removed successfully, stopped listening for events");
    }
    
    return {};
}

/**
 * 销毁事件观察者
 * 释放内存，防止内存泄漏
 * 销毁后需将指针置为nullptr
 * 
 * @param env napi环境
 * @param info napi回调信息
 * @return napi_value
 */
static napi_value DestroyWatcher(napi_env env, napi_callback_info info) {
    LogEvent(0, "DestroyWatcher called");
    
    if (systemEventWatcher == nullptr) {
        LogEvent(1, "Watcher is already null, nothing to destroy");
        return {};
    }
    
    // 销毁创建的观察者，并置systemEventWatcher为nullptr
    OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
    systemEventWatcher = nullptr;
    
    LogEvent(0, "Watcher destroyed successfully, memory released");
    
    return {};
}

/**
 * 获取观察者状态
 * 
 * @param env napi环境
 * @param info napi回调信息
 * @return napi_value 返回观察者状态信息
 */
static napi_value GetWatcherStatus(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_object(env, &result);
    
    napi_value isNull;
    napi_get_boolean(env, systemEventWatcher == nullptr, &isNull);
    napi_set_named_property(env, result, "isNull", isNull);
    
    napi_value message;
    std::string statusMsg = systemEventWatcher ? "Watcher is active" : "Watcher is null";
    napi_create_string_utf8(env, statusMsg.c_str(), NAPI_AUTO_LENGTH, &message);
    napi_set_named_property(env, result, "message", message);
    
    LogEvent(0, "GetWatcherStatus: " + statusMsg);
    
    return result;
}

/**
 * 初始化模块，注册ArkTS接口
 */
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "registerWatcher", nullptr, RegisterWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removeWatcher", nullptr, RemoveWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "destroyWatcher", nullptr, DestroyWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getWatcherStatus", nullptr, GetWatcherStatus, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    
    LogEvent(0, "HiAppEvent AppKilledEventWatcher module initialized");
    
    return exports;
}

// 模块注册
NAPI_MODULE(entry, Init)