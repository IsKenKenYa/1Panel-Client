#include "napi/native_api.h"
#include "hiappevent/hiappevent.h"
#include "hiappevent/hiappevent_param.h"
#include "hilog/log.h"
#include "json/json.h"

#undef LOG_TAG
#define LOG_TAG "CrashEventWatcher"

static HiAppEvent_Watcher *systemEventWatcherT = nullptr;

static void OnTakeCrash(const char* const *events, uint32_t eventLen)
{
    Json::Reader reader(Json::Features::strictMode());
    Json::FastWriter writer;
    for (uint32_t i = 0; i < eventLen; ++i) {
        Json::Value eventInfo;
        if (reader.parse(events[i], eventInfo)) {
            auto domain = eventInfo["domain_"].asString();
            auto name = eventInfo["name_"].asString();
            auto type = eventInfo["type_"].asInt();
            
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.WatcherType=OnTrigger");
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", domain.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", name.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d", type);
            
            if (domain == DOMAIN_OS && name == EVENT_APP_CRASH) {
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld",
                    eventInfo["time"].asInt64());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.crash_type=%{public}s",
                    eventInfo["crash_type"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.foreground=%{public}d",
                    eventInfo["foreground"].asBool());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.app_running_unique_id=%{public}s",
                    eventInfo["app_running_unique_id"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_version=%{public}s",
                    eventInfo["bundle_version"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_name=%{public}s",
                    eventInfo["bundle_name"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.pid=%{public}d", eventInfo["pid"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.uid=%{public}d", eventInfo["uid"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.uuid=%{public}s",
                    eventInfo["uuid"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.exception=%{public}s",
                    writer.write(eventInfo["exception"]).c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.hilog.size=%{public}d",
                    eventInfo["hilog"].size());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.process_life_time=%{public}d",
                    eventInfo["process_life_time"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.memory=%{public}s",
                    writer.write(eventInfo["memory"]).c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.external_log=%{public}s",
                    writer.write(eventInfo["external_log"]).c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.log_over_limit=%{public}d",
                    eventInfo["log_over_limit"].asBool());
            }
        }
    }
}

static void OnTriggerCrash(int row, int size)
{
    OH_HiAppEvent_TakeWatcherData(systemEventWatcherT, row, OnTakeCrash);
}

static napi_value RegisterWatcherClickCrash(napi_env env, napi_callback_info info)
{
    systemEventWatcherT = OH_HiAppEvent_CreateWatcher("AppCrashWatcherT");
    if (systemEventWatcherT == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    const char *names[] = {EVENT_APP_CRASH};
    int result = OH_HiAppEvent_SetAppEventFilter(systemEventWatcherT, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set app event filter, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherT);
        systemEventWatcherT = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_SetWatcherOnTrigger(systemEventWatcherT, OnTriggerCrash);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set watcher onTrigger, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherT);
        systemEventWatcherT = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_SetTriggerCondition(systemEventWatcherT, 1, 0, 0);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set trigger condition, error=%{public}d", result);
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
    
    OH_LOG_INFO(LogType::LOG_APP, "Successfully registered crash event watcher with trigger");
    return {};
}

static napi_value RemoveWatcherCrash(napi_env env, napi_callback_info info)
{
    if (systemEventWatcherT != nullptr) {
        int result = OH_HiAppEvent_RemoveWatcher(systemEventWatcherT);
        if (result != 0) {
            OH_LOG_ERROR(LogType::LOG_APP, "Failed to remove watcher, error=%{public}d", result);
        }
    }
    return {};
}

static napi_value DestroyWatcherCrash(napi_env env, napi_callback_info info)
{
    if (systemEventWatcherT != nullptr) {
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherT);
        systemEventWatcherT = nullptr;
    }
    OH_LOG_INFO(LogType::LOG_APP, "Successfully destroyed crash event watcher");
    return {};
}

static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "registerWatcherClickCrash", nullptr, RegisterWatcherClickCrash, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removeWatcherCrash", nullptr, RemoveWatcherCrash, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "destroyWatcherCrash", nullptr, DestroyWatcherCrash, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

NAPI_MODULE(entry, Init)