#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"

#undef LOG_TAG
#define LOG_TAG "ScrollJankWatcher"

static HiAppEvent_Watcher *systemEventWatcherR = nullptr;
static HiAppEvent_Watcher *systemEventWatcherT = nullptr;

static void OnReceive(const char *domain, const struct HiAppEvent_AppEventGroup *appEventGroups, uint32_t groupLen)
{
    for (int i = 0; i < groupLen; ++i) {
        for (int j = 0; j < appEventGroups[i].infoLen; ++j) {
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.WatcherType=OnReceive");
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", appEventGroups[i].appEventInfos[j].domain);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", appEventGroups[i].appEventInfos[j].name);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d", appEventGroups[i].appEventInfos[j].type);
            
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) != 0 || 
                strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_SCROLL_JANK) != 0) {
                continue;
            }
            
            Json::Value params;
            Json::Reader reader(Json::Features::strictMode());
            Json::FastWriter writer;
            
            if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld", params["time"].asInt64());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_version=%{public}s", params["bundle_version"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_name=%{public}s", params["bundle_name"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.process_name=%{public}s", params["process_name"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.ability_name=%{public}s", params["ability_name"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.begin_time=%{public}lld", params["begin_time"].asInt64());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.duration=%{public}d", params["duration"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.total_app_frames=%{public}d", params["total_app_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.total_app_missed_frames=%{public}d", params["total_app_missed_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.max_app_frametime=%{public}d", params["max_app_frametime"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.max_app_seq_frames=%{public}d", params["max_app_seq_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.total_render_frames=%{public}d", params["total_render_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.total_render_missed_frames=%{public}d", params["total_render_missed_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.max_render_frametime=%{public}d", params["max_render_frametime"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.max_render_seq_frames=%{public}d", params["max_render_seq_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.external_log=%{public}s", writer.write(params["external_log"]).c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.log_over_limit=%{public}d", params["log_over_limit"].asBool());
            }
        }
    }
}

static napi_value RegisterWatcherReceive(napi_env env, napi_callback_info info)
{
    systemEventWatcherR = OH_HiAppEvent_CreateWatcher("ScrollJankWatcherR");
    if (systemEventWatcherR == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    const char *names[] = {EVENT_SCROLL_JANK};
    int result = OH_HiAppEvent_SetAppEventFilter(systemEventWatcherR, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter, error=%{public}d", result);
        return {};
    }
    
    result = OH_HiAppEvent_SetWatcherOnReceive(systemEventWatcherR, OnReceive);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set onReceive, error=%{public}d", result);
        return {};
    }
    
    result = OH_HiAppEvent_AddWatcher(systemEventWatcherR);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher, error=%{public}d", result);
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "ScrollJankWatcherR registered successfully");
    return {};
}

static void OnTake(const char* const *events, uint32_t eventLen)
{
    Json::Reader reader(Json::Features::strictMode());
    Json::FastWriter writer;
    
    for (int i = 0; i < eventLen; ++i) {
        Json::Value eventInfo;
        if (reader.parse(events[i], eventInfo)) {
            auto domain = eventInfo["domain_"].asString();
            auto name = eventInfo["name_"].asString();
            auto type = eventInfo["type_"].asInt();
            
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.WatcherType=OnTrigger");
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", domain.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", name.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d", type);
            
            if (domain == DOMAIN_OS && name == EVENT_SCROLL_JANK) {
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld", eventInfo["time"].asInt64());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_version=%{public}s", eventInfo["bundle_version"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_name=%{public}s", eventInfo["bundle_name"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.total_app_frames=%{public}d", eventInfo["total_app_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.total_app_missed_frames=%{public}d", eventInfo["total_app_missed_frames"].asInt());
            }
        }
    }
}

static void OnTrigger(int row, int size)
{
    OH_HiAppEvent_TakeWatcherData(systemEventWatcherT, row, OnTake);
}

static napi_value RegisterWatcherTrigger(napi_env env, napi_callback_info info)
{
    systemEventWatcherT = OH_HiAppEvent_CreateWatcher("ScrollJankWatcherT");
    if (systemEventWatcherT == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    const char *names[] = {EVENT_SCROLL_JANK};
    int result = OH_HiAppEvent_SetAppEventFilter(systemEventWatcherT, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter, error=%{public}d", result);
        return {};
    }
    
    result = OH_HiAppEvent_SetWatcherOnTrigger(systemEventWatcherT, OnTrigger);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set onTrigger, error=%{public}d", result);
        return {};
    }
    
    result = OH_HiAppEvent_SetTriggerCondition(systemEventWatcherT, 1, 0, 0);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set trigger condition, error=%{public}d", result);
        return {};
    }
    
    result = OH_HiAppEvent_AddWatcher(systemEventWatcherT);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher, error=%{public}d", result);
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "ScrollJankWatcherT registered successfully");
    return {};
}

static napi_value UnregisterWatcher(napi_env env, napi_callback_info info)
{
    if (systemEventWatcherR != nullptr) {
        OH_HiAppEvent_RemoveWatcher(systemEventWatcherR);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherR);
        systemEventWatcherR = nullptr;
        OH_LOG_INFO(LogType::LOG_APP, "ScrollJankWatcherR unregistered and destroyed");
    }
    
    if (systemEventWatcherT != nullptr) {
        OH_HiAppEvent_RemoveWatcher(systemEventWatcherT);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherT);
        systemEventWatcherT = nullptr;
        OH_LOG_INFO(LogType::LOG_APP, "ScrollJankWatcherT unregistered and destroyed");
    }
    
    return {};
}

static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "registerWatcherReceive", nullptr, RegisterWatcherReceive, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "registerWatcherTrigger", nullptr, RegisterWatcherTrigger, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "unregisterWatcher", nullptr, UnregisterWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

NAPI_MODULE(entry, Init)