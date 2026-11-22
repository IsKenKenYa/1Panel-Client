// 订阅应用冻屏事件示例代码 (onTrigger模式)
// 文件: napi_init.cpp

#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"

#undef LOG_TAG
#define LOG_TAG "FreezeWatcher"

// 定义观察者指针变量
static HiAppEvent_Watcher *freezeWatcher = nullptr;

// OnTake回调函数 - 用于获取事件数据
static void OnTake(const char* const *events, uint32_t eventLen) {
    Json::Reader reader(Json::Features::strictMode());
    Json::FastWriter writer;
    
    for (uint32_t i = 0; i < eventLen; ++i) {
        Json::Value eventInfo;
        try {
            if (reader.parse(events[i], eventInfo)) {
                auto domain = eventInfo["domain_"].asString();
                auto name = eventInfo["name_"].asString();
                auto type = eventInfo["type_"].asInt();
                
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", domain.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", name.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d", type);
                
                // 检查是否为应用冻屏事件
                if (domain == DOMAIN_OS && name == EVENT_APP_FREEZE) {
                    auto time = eventInfo["time"].asInt64();
                    auto foreground = eventInfo["foreground"].asBool();
                    auto appRunningUniqueId = eventInfo["app_running_unique_id"].asString();
                    auto bundleVersion = eventInfo["bundle_version"].asString();
                    auto bundleName = eventInfo["bundle_name"].asString();
                    auto processName = eventInfo["process_name"].asString();
                    auto pid = eventInfo["pid"].asInt();
                    auto uid = eventInfo["uid"].asInt();
                    auto uuid = eventInfo["uuid"].asString();
                    auto exception = writer.write(eventInfo["exception"]);
                    auto hilogSize = eventInfo["hilog"].size();
                    auto handleSize = eventInfo["event_handler"].size();
                    auto handleSize3s = eventInfo["event_handler_size_3s"].asString();
                    auto handleSize6s = eventInfo["event_handler_size_6s"].asString();
                    auto peerBindSize = eventInfo["peer_binder"].size();
                    auto threadSize = eventInfo["threads"].size();
                    auto memory = writer.write(eventInfo["memory"]);
                    auto externalLog = writer.write(eventInfo["external_log"]);
                    auto logOverLimit = eventInfo["log_over_limit"].asBool();
                    auto processLifeTime = eventInfo["process_life_time"].asString();
                    auto externalCallbackLog = eventInfo["external_callback_log"].asString();
                    
                    // 记录冻屏详细信息
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld", time);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.foreground=%{public}d", foreground);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.app_running_unique_id=%{public}s", 
                                appRunningUniqueId.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_version=%{public}s", 
                                bundleVersion.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_name=%{public}s", 
                                bundleName.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.process_name=%{public}s", 
                                processName.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.pid=%{public}d", pid);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.uid=%{public}d", uid);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.uuid=%{public}s", uuid.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.exception=%{public}s", 
                                exception.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.hilog.size=%{public}d", hilogSize);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.event_handler.size=%{public}d", 
                                handleSize);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.event_handler_3s.size=%{public}s", 
                                handleSize3s.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.event_handler_6s.size=%{public}s", 
                                handleSize6s.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.peer_binder.size=%{public}d", 
                                peerBindSize);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.threads.size=%{public}d", threadSize);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.memory=%{public}s", memory.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.external_log=%{public}s", 
                                externalLog.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.log_over_limit=%{public}d", 
                                logOverLimit);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.process_life_time=%{public}s", 
                                processLifeTime.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.external_callback_log=%{public}s", 
                                externalCallbackLog.c_str());
                }
            }
        } catch (const std::exception& e) {
            OH_LOG_ERROR(LogType::LOG_APP, "JSON parse error: %{public}s", e.what());
        }
    }
}

// OnTrigger回调函数 - 批量接收冻屏事件
static void OnTrigger(int row, int size) {
    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent OnTrigger: row=%{public}d, size=%{public}d", row, size);
    
    // 获取事件数据
    int result = OH_HiAppEvent_TakeWatcherData(freezeWatcher, row, OnTake);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to take watcher data: %{public}d", result);
    }
}

// 注册观察者函数
static napi_value RegisterWatcher(napi_env env, napi_callback_info info) {
    // 1. 创建观察者
    freezeWatcher = OH_HiAppEvent_CreateWatcher("freezeTriggerWatcher");
    if (freezeWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    // 2. 设置事件过滤
    const char *names[] = {EVENT_APP_FREEZE};
    int result = OH_HiAppEvent_SetAppEventFilter(freezeWatcher, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(freezeWatcher);
        freezeWatcher = nullptr;
        return {};
    }
    
    // 3. 设置onTrigger回调
    result = OH_HiAppEvent_SetWatcherOnTrigger(freezeWatcher, OnTrigger);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set onTrigger: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(freezeWatcher);
        freezeWatcher = nullptr;
        return {};
    }
    
    // 4. 设置触发条件 - 新增1个事件时触发
    result = OH_HiAppEvent_SetTriggerCondition(freezeWatcher, 1, 0, 0);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set trigger condition: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(freezeWatcher);
        freezeWatcher = nullptr;
        return {};
    }
    
    // 5. 添加观察者
    result = OH_HiAppEvent_AddWatcher(freezeWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(freezeWatcher);
        freezeWatcher = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Freeze watcher registered successfully (onTrigger mode)");
    return {};
}

// 移除观察者函数
static napi_value RemoveWatcher(napi_env env, napi_callback_info info) {
    if (freezeWatcher != nullptr) {
        int result = OH_HiAppEvent_RemoveWatcher(freezeWatcher);
        if (result != 0) {
            OH_LOG_ERROR(LogType::LOG_APP, "Failed to remove watcher: %{public}d", result);
        } else {
            OH_LOG_INFO(LogType::LOG_APP, "Freeze watcher removed successfully");
        }
    }
    return {};
}

// 销毁观察者函数
static napi_value DestroyWatcher(napi_env env, napi_callback_info info) {
    if (freezeWatcher != nullptr) {
        OH_HiAppEvent_RemoveWatcher(freezeWatcher);
        OH_HiAppEvent_DestroyWatcher(freezeWatcher);
        freezeWatcher = nullptr;
        OH_LOG_INFO(LogType::LOG_APP, "Freeze watcher destroyed successfully");
    }
    return {};
}

// 注册NAPI接口
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "registerWatcher", nullptr, RegisterWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removeWatcher", nullptr, RemoveWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "destroyWatcher", nullptr, DestroyWatcher, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

extern "C" {
    napi_value NAPI_GetInstance(napi_env env, napi_value exports) {
        return Init(env, exports);
    }
}