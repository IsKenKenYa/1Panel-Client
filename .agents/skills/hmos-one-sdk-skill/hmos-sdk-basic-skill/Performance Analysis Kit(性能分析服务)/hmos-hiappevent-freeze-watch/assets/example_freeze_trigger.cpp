// example_freeze_trigger.cpp
// 完整的冻屏事件订阅示例（onTrigger触发回调模式）

#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"

#undef LOG_TAG
#define LOG_TAG "FreezeEventTrigger"

// 缓存观察者指针
static HiAppEvent_Watcher *freezeTriggerWatcher = nullptr;

// OnTake回调函数（获取保存的事件数据）
static void OnTake(const char *const *events, uint32_t eventLen) {
    OH_LOG_INFO(LogType::LOG_APP, "OnTake callback triggered with %{public}u events", eventLen);
    
    Json::Reader reader(Json::Features::strictMode());
    Json::FastWriter writer;
    
    for (uint32_t i = 0; i < eventLen; ++i) {
        Json::Value eventInfo;
        
        if (reader.parse(events[i], eventInfo)) {
            // 提取事件基本信息
            auto domain = eventInfo["domain_"].asString();
            auto name = eventInfo["name_"].asString();
            auto type = eventInfo["type_"].asInt();
            
            OH_LOG_INFO(LogType::LOG_APP, "Event %{public}d: domain=%{public}s, name=%{public}s, type=%{public}d",
                        i + 1, domain.c_str(), name.c_str(), type);
            
            // 检查是否为冻屏事件
            if (domain == DOMAIN_OS && name == EVENT_APP_FREEZE) {
                // 提取冻屏事件参数
                try {
                    auto time = eventInfo["time"].asInt64();
                    auto foreground = eventInfo["foreground"].asBool();
                    auto appRunningUniqueId = eventInfo["app_running_unique_id"].asString();
                    auto bundleVersion = eventInfo["bundle_version"].asString();
                    auto bundleName = eventInfo["bundle_name"].asString();
                    auto processName = eventInfo["process_name"].asString();
                    auto pid = eventInfo["pid"].asInt();
                    auto uid = eventInfo["uid"].asInt();
                    auto uuid = eventInfo["uuid"].asString();
                    
                    // 解析异常信息
                    auto exceptionType = eventInfo["exception"]["name"].asString();
                    auto exceptionMessage = eventInfo["exception"]["message"].asString();
                    auto exceptionJson = writer.write(eventInfo["exception"]);
                    
                    // 解析其他参数
                    auto hilogSize = eventInfo["hilog"].size();
                    auto handlerSize = eventInfo["event_handler"].size();
                    auto handlerSize3s = eventInfo["event_handler_size_3s"].asString();
                    auto handlerSize6s = eventInfo["event_handler_size_6s"].asString();
                    auto peerBinderSize = eventInfo["peer_binder"].size();
                    auto threadsSize = eventInfo["threads"].size();
                    auto memoryJson = writer.write(eventInfo["memory"]);
                    auto externalLogJson = writer.write(eventInfo["external_log"]);
                    auto logOverLimit = eventInfo["log_over_limit"].asBool();
                    auto processLifeTime = eventInfo["process_life_time"].asString();
                    auto externalCallbackLog = eventInfo["external_callback_log"].asString();
                    
                    // 打印详细的冻屏信息
                    OH_LOG_INFO(LogType::LOG_APP, "========================================");
                    OH_LOG_INFO(LogType::LOG_APP, "Application Freeze Event Details");
                    OH_LOG_INFO(LogType::LOG_APP, "========================================");
                    OH_LOG_INFO(LogType::LOG_APP, "Time: %{public}lld", time);
                    OH_LOG_INFO(LogType::LOG_APP, "Foreground: %{public}d", foreground);
                    OH_LOG_INFO(LogType::LOG_APP, "App Running Unique ID: %{public}s", appRunningUniqueId.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "Bundle: %{public}s v%{public}s", bundleName.c_str(), bundleVersion.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "Process: %{public}s (PID: %{public}d, UID: %{public}d)", 
                                processName.c_str(), pid, uid);
                    OH_LOG_INFO(LogType::LOG_APP, "UUID: %{public}s", uuid.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "Exception Type: %{public}s", exceptionType.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "Exception Message: %{public}s", exceptionMessage.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "Exception JSON: %{public}s", exceptionJson.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "Hilog Size: %{public}d", hilogSize);
                    OH_LOG_INFO(LogType::LOG_APP, "Event Handler Size: %{public}d", handlerSize);
                    OH_LOG_INFO(LogType::LOG_APP, "Handler 3s: %{public}s, 6s: %{public}s", 
                                handlerSize3s.c_str(), handlerSize6s.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "Peer Binder Size: %{public}d", peerBinderSize);
                    OH_LOG_INFO(LogType::LOG_APP, "Thread Count: %{public}d", threadsSize);
                    OH_LOG_INFO(LogType::LOG_APP, "Memory: %{public}s", memoryJson.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "External Log: %{public}s", externalLogJson.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "Log Over Limit: %{public}d", logOverLimit);
                    OH_LOG_INFO(LogType::LOG_APP, "Process Life Time: %{public}s", processLifeTime.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "External Callback Log: %{public}s", externalCallbackLog.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "========================================");
                    
                } catch (const std::exception& e) {
                    OH_LOG_ERROR(LogType::LOG_APP, "Failed to parse freeze params: %{public}s", e.what());
                    OH_LOG_WARN(LogType::LOG_APP, "Raw event JSON: %{public}s", events[i]);
                }
            }
        } else {
            OH_LOG_ERROR(LogType::LOG_APP, "Failed to parse event %{public}d JSON", i + 1);
            OH_LOG_WARN(LogType::LOG_APP, "Raw event string: %{public}s", events[i]);
        }
    }
}

// OnTrigger回调函数（触发条件满足时调用）
static void OnTrigger(int row, int size) {
    OH_LOG_INFO(LogType::LOG_APP, "OnTrigger fired: row=%{public}d, size=%{public}d bytes", row, size);
    
    // 获取保存的事件数据
    int result = OH_HiAppEvent_TakeWatcherData(freezeTriggerWatcher, row, OnTake);
    
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to take watcher data, error code: %{public}d", result);
        
        if (result == -5) {
            OH_LOG_ERROR(LogType::LOG_APP, "Watcher pointer is null");
        } else if (result == -6) {
            OH_LOG_ERROR(LogType::LOG_APP, "Watcher not added yet - call AddWatcher first");
        } else {
            OH_LOG_ERROR(LogType::LOG_APP, "Unknown error occurred");
        }
    } else {
        OH_LOG_INFO(LogType::LOG_APP, "Watcher data retrieved successfully");
    }
}

// 注册冻屏事件观察者（onTrigger模式）
static napi_value RegisterFreezeTriggerWatcher(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LogType::LOG_APP, "Registering freeze event watcher (Trigger mode)...");
    
    // 步骤1：创建观察者
    freezeTriggerWatcher = OH_HiAppEvent_CreateWatcher("freezeTriggerWatcher");
    if (freezeTriggerWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    OH_LOG_INFO(LogType::LOG_APP, "Watcher created: freezeTriggerWatcher");
    
    // 步骤2：设置事件过滤器
    const char *names[] = {EVENT_APP_FREEZE};
    int result = OH_HiAppEvent_SetAppEventFilter(freezeTriggerWatcher, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "SetAppEventFilter failed, error: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(freezeTriggerWatcher);
        freezeTriggerWatcher = nullptr;
        return {};
    }
    OH_LOG_INFO(LogType::LOG_APP, "Event filter configured: DOMAIN_OS/EVENT_APP_FREEZE");
    
    // 步骤3：设置OnTrigger回调
    result = OH_HiAppEvent_SetWatcherOnTrigger(freezeTriggerWatcher, OnTrigger);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "SetWatcherOnTrigger failed, error: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(freezeTriggerWatcher);
        freezeTriggerWatcher = nullptr;
        return {};
    }
    OH_LOG_INFO(LogType::LOG_APP, "OnTrigger callback configured");
    
    // 步骤4：设置触发条件（新增1个事件时触发）
    // 参数说明：
    // - row=1: 新接收事件数量≥1时触发
    // - size=0: 不以事件大小为触发条件
    // - timeOut=0: 不以超时时间为触发条件
    result = OH_HiAppEvent_SetTriggerCondition(freezeTriggerWatcher, 1, 0, 0);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "SetTriggerCondition failed, error: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(freezeTriggerWatcher);
        freezeTriggerWatcher = nullptr;
        return {};
    }
    OH_LOG_INFO(LogType::LOG_APP, "Trigger condition set: row=1, size=0, timeout=0");
    
    // 步骤5：添加观察者（开始监听）
    result = OH_HiAppEvent_AddWatcher(freezeTriggerWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "AddWatcher failed, error: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(freezeTriggerWatcher);
        freezeTriggerWatcher = nullptr;
        return {};
    }
    OH_LOG_INFO(LogType::LOG_APP, "Watcher added successfully - listening for freeze events");
    
    return {};
}

// 移除冻屏事件观察者
static napi_value RemoveFreezeTriggerWatcher(napi_env env, napi_callback_info info) {
    if (freezeTriggerWatcher != nullptr) {
        int result = OH_HiAppEvent_RemoveWatcher(freezeTriggerWatcher);
        if (result == 0) {
            OH_LOG_INFO(LogType::LOG_APP, "Watcher removed - stopped listening");
        } else {
            OH_LOG_ERROR(LogType::LOG_APP, "RemoveWatcher failed, error: %{public}d", result);
        }
    } else {
        OH_LOG_WARN(LogType::LOG_APP, "Watcher not created");
    }
    return {};
}

// 销毁冻屏事件观察者
static napi_value DestroyFreezeTriggerWatcher(napi_env env, napi_callback_info info) {
    if (freezeTriggerWatcher != nullptr) {
        OH_HiAppEvent_DestroyWatcher(freezeTriggerWatcher);
        freezeTriggerWatcher = nullptr;
        OH_LOG_INFO(LogType::LOG_APP, "Watcher destroyed - memory released");
    } else {
        OH_LOG_WARN(LogType::LOG_APP, "Watcher not created");
    }
    return {};
}

// 注册接口到ArkTS
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "registerFreezeTriggerWatcher", nullptr, RegisterFreezeTriggerWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removeFreezeTriggerWatcher", nullptr, RemoveFreezeTriggerWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "destroyFreezeTriggerWatcher", nullptr, DestroyFreezeTriggerWatcher, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

// NAPI模块定义
extern "C" __attribute__((visibility("default"))) napi_module napi_module_info = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_modname = "entry",
    .nm_priv = reinterpret_cast<void*>(Init),
    .reserved = { 0 },
};