#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"

#undef LOG_TAG
#define LOG_TAG "AppLaunchWatcher"

static HiAppEvent_Watcher *systemEventWatcherR = nullptr;
static HiAppEvent_Watcher *systemEventWatcherT = nullptr;

static void OnReceive(const char *domain, const struct HiAppEvent_AppEventGroup *appEventGroups, uint32_t groupLen)
{
    for (uint32_t i = 0; i < groupLen; ++i) {
        for (uint32_t j = 0; j < appEventGroups[i].infoLen; ++j) {
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.WatcherType=OnReceive");
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", 
                        appEventGroups[i].appEventInfos[j].domain);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", 
                        appEventGroups[i].appEventInfos[j].name);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d", 
                        appEventGroups[i].appEventInfos[j].type);
            
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) != 0 || 
                strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_APP_LAUNCH) != 0) {
                continue;
            }
            
            Json::Value params;
            Json::Reader reader(Json::Features::strictMode());
            if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld", 
                            params["time"].asInt64());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_version=%{public}s", 
                            params["bundle_version"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_name=%{public}s", 
                            params["bundle_name"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.process_name=%{public}s", 
                            params["process_name"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.start_type=%{public}d", 
                            params["start_type"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.response_latency=%{public}d", 
                            params["response_latency"].asInt());
            } else {
                OH_LOG_ERROR(LogType::LOG_APP, "Failed to parse event params JSON");
            }
        }
    }
}

static void OnTake(const char *const *events, uint32_t eventLen)
{
    Json::Reader reader(Json::Features::strictMode());
    for (uint32_t i = 0; i < eventLen; ++i) {
        Json::Value eventInfo;
        if (reader.parse(events[i], eventInfo)) {
            auto domain = eventInfo["domain_"].asString();
            auto name = eventInfo["name_"].asString();
            
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.WatcherType=OnTrigger");
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", domain.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", name.c_str());
            
            if (domain == DOMAIN_OS && name == EVENT_APP_LAUNCH) {
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld", 
                            eventInfo["time"].asInt64());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_name=%{public}s", 
                            eventInfo["bundle_name"].asString().c_str());
            }
        }
    }
}

static void OnTrigger(int row, int size)
{
    OH_HiAppEvent_TakeWatcherData(systemEventWatcherT, row, OnTake);
}

static napi_value RegisterWatcherReceive(napi_env env, napi_callback_info info)
{
    systemEventWatcherR = OH_HiAppEvent_CreateWatcher("AppLaunchWatcherR");
    if (systemEventWatcherR == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    const char *names[] = {EVENT_APP_LAUNCH};
    int result = OH_HiAppEvent_SetAppEventFilter(systemEventWatcherR, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherR);
        systemEventWatcherR = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_SetWatcherOnReceive(systemEventWatcherR, OnReceive);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set callback, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherR);
        systemEventWatcherR = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_AddWatcher(systemEventWatcherR);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherR);
        systemEventWatcherR = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Watcher registered successfully");
    return {};
}

static napi_value RegisterWatcherTrigger(napi_env env, napi_callback_info info)
{
    systemEventWatcherT = OH_HiAppEvent_CreateWatcher("AppLaunchWatcherT");
    if (systemEventWatcherT == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    const char *names[] = {EVENT_APP_LAUNCH};
    int result = OH_HiAppEvent_SetAppEventFilter(systemEventWatcherT, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherT);
        systemEventWatcherT = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_SetWatcherOnTrigger(systemEventWatcherT, OnTrigger);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set callback, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherT);
        systemEventWatcherT = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_SetTriggerCondition(systemEventWatcherT, 1, 0, 0);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set condition, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherT);
        systemEventWatcherT = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_AddWatcher(systemEventWatcherT);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherT);
        systemEventWatcherT = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Watcher registered successfully");
    return {};
}

static napi_value CleanupWatchers(napi_env env, napi_callback_info info)
{
    if (systemEventWatcherR != nullptr) {
        OH_HiAppEvent_RemoveWatcher(systemEventWatcherR);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherR);
        systemEventWatcherR = nullptr;
    }
    
    if (systemEventWatcherT != nullptr) {
        OH_HiAppEvent_RemoveWatcher(systemEventWatcherT);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherT);
        systemEventWatcherT = nullptr;
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Watchers cleaned up");
    return {};
}

static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        {"registerWatcherReceive", nullptr, RegisterWatcherReceive, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"registerWatcherTrigger", nullptr, RegisterWatcherTrigger, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"cleanupWatchers", nullptr, CleanupWatchers, nullptr, nullptr, nullptr, napi_default, nullptr},
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

extern "C" __attribute__((visibility("default"))) void NAPI_get_AppLaunchWatcher(napi_env env, napi_value exports)
{
    Init(env, exports);
}