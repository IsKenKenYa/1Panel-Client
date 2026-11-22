#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"

#undef LOG_TAG
#define LOG_TAG "AudioJankWatcher"

static HiAppEvent_Watcher *systemEventWatcher;

static void OnReceive(const char *domain, const struct HiAppEvent_AppEventGroup *appEventGroups, uint32_t groupLen) {
    try {
        for (int i = 0; i < groupLen; ++i) {
            for (int j = 0; j < appEventGroups[i].infoLen; ++j) {
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", appEventGroups[i].appEventInfos[j].domain);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", appEventGroups[i].appEventInfos[j].name);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d", appEventGroups[i].appEventInfos[j].type);
                
                if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) == 0 &&
                    strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_AUDIO_JANK_FRAME) == 0) {
                    Json::Value params;
                    Json::Reader reader(Json::Features::strictMode());
                    Json::FastWriter writer;
                    
                    if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
                        auto time = params["time"].asInt64();
                        auto bundleVersion = params["bundle_version"].asString();
                        auto bundleName = params["bundle_name"].asString();
                        auto faultType = params["fault_type"].asString();
                        auto happenTime = params["happen_time"].asInt64();
                        auto maxFrameTime = params["max_frame_time"].asInt64();
                        
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}ld", time);
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_version=%{public}s", bundleVersion.c_str());
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_name=%{public}s", bundleName.c_str());
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.fault_type=%{public}s", faultType.c_str());
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.happen_time=%{public}ld", happenTime);
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.max_frame_time=%{public}ld", maxFrameTime);
                    } else {
                        OH_LOG_WARN(LogType::LOG_APP, "Failed to parse event params JSON");
                    }
                }
            }
        }
    } catch (const std::exception& e) {
        OH_LOG_ERROR(LogType::LOG_APP, "Exception in OnReceive: %{public}s", e.what());
    }
}

static void OnTake(const char *const *events, uint32_t eventLen) {
    Json::Reader reader(Json::Features::strictMode());
    Json::FastWriter writer;
    
    for (int i = 0; i < eventLen; ++i) {
        Json::Value eventInfo;
        if (reader.parse(events[i], eventInfo)) {
            auto domain = eventInfo["domain_"].asString();
            auto name = eventInfo["name_"].asString();
            auto type = eventInfo["type_"].asInt();
            
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", domain.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", name.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d", type);
            
            if (domain == DOMAIN_OS && name == EVENT_AUDIO_JANK_FRAME) {
                auto time = eventInfo["time"].asInt64();
                auto bundleVersion = eventInfo["bundle_version"].asString();
                auto bundleName = eventInfo["bundle_name"].asString();
                auto faultType = eventInfo["fault_type"].asString();
                auto happenTime = eventInfo["happen_time"].asInt64();
                auto maxFrameTime = eventInfo["max_frame_time"].asInt64();
                
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}ld", time);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_version=%{public}s", bundleVersion.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_name=%{public}s", bundleName.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.fault_type=%{public}s", faultType.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.happen_time=%{public}ld", happenTime);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.max_frame_time=%{public}ld", maxFrameTime);
            }
        } else {
            OH_LOG_WARN(LogType::LOG_APP, "Failed to parse event JSON");
        }
    }
}

static void OnTrigger(int row, int size) {
    OH_HiAppEvent_TakeWatcherData(systemEventWatcher, row, OnTake);
}

static napi_value RegisterOnReceiveWatcher(napi_env env, napi_callback_info info) {
    systemEventWatcher = OH_HiAppEvent_CreateWatcher("onReceiverWatcher");
    if (systemEventWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    const char *names[] = {EVENT_AUDIO_JANK_FRAME};
    int result = OH_HiAppEvent_SetAppEventFilter(systemEventWatcher, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        return {};
    }
    
    OH_HiAppEvent_SetWatcherOnReceive(systemEventWatcher, OnReceive);
    
    result = OH_HiAppEvent_AddWatcher(systemEventWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Watcher registered successfully (onReceive mode)");
    return {};
}

static napi_value RegisterOnTriggerWatcher(napi_env env, napi_callback_info info) {
    systemEventWatcher = OH_HiAppEvent_CreateWatcher("onTriggerWatcher");
    if (systemEventWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    const char *names[] = {EVENT_AUDIO_JANK_FRAME};
    int result = OH_HiAppEvent_SetAppEventFilter(systemEventWatcher, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        return {};
    }
    
    OH_HiAppEvent_SetWatcherOnTrigger(systemEventWatcher, OnTrigger);
    OH_HiAppEvent_SetTriggerCondition(systemEventWatcher, 1, 0, 0);
    
    result = OH_HiAppEvent_AddWatcher(systemEventWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Watcher registered successfully (onTrigger mode)");
    return {};
}

static napi_value UnregisterWatcher(napi_env env, napi_callback_info info) {
    if (systemEventWatcher != nullptr) {
        int result = OH_HiAppEvent_RemoveWatcher(systemEventWatcher);
        if (result != 0) {
            OH_LOG_ERROR(LogType::LOG_APP, "Failed to remove watcher: %{public}d", result);
        } else {
            OH_LOG_INFO(LogType::LOG_APP, "Watcher removed successfully");
        }
        
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
    }
    return {};
}

static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "registerOnReceiveWatcher", nullptr, RegisterOnReceiveWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "registerOnTriggerWatcher", nullptr, RegisterOnTriggerWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "unregisterWatcher", nullptr, UnregisterWatcher, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

extern "C" {
    NAPI_MODULE(entry, Init)
}