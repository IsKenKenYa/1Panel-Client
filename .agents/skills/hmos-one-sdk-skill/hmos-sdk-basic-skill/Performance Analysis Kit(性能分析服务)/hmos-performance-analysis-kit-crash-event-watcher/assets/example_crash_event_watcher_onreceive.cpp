#include "napi/native_api.h"
#include "hiappevent/hiappevent.h"
#include "hiappevent/hiappevent_param.h"
#include "hilog/log.h"
#include "json/json.h"

#undef LOG_TAG
#define LOG_TAG "CrashEventWatcher"

static HiAppEvent_Watcher *systemEventWatcherR = nullptr;

static void OnReceiveCrashEvent(const char *domain, const struct HiAppEvent_AppEventGroup *appEventGroups,
    uint32_t groupLen)
{
    try {
        for (uint32_t i = 0; i < groupLen; ++i) {
            for (uint32_t j = 0; j < appEventGroups[i].infoLen; ++j) {
                const struct HiAppEvent_AppEventInfo &appEventInfo = appEventGroups[i].appEventInfos[j];
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", appEventInfo.domain);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", appEventInfo.name);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d", appEventInfo.type);
                
                if (strcmp(appEventInfo.domain, DOMAIN_OS) != 0 || strcmp(appEventInfo.name, EVENT_APP_CRASH) != 0) {
                    continue;
                }
                
                Json::Value params;
                Json::Reader reader(Json::Features::strictMode());
                Json::FastWriter writer;
                if (reader.parse(appEventInfo.params, params)) {
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld",
                        params["time"].asInt64());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.crash_type=%{public}s",
                        params["crash_type"].asString().c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.foreground=%{public}d",
                        params["foreground"].asBool());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.release_type=%{public}s",
                        params["release_type"].asString().c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.cpu_abi=%{public}s",
                        params["cpu_abi"].asString().c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.app_running_unique_id=%{public}s",
                        params["app_running_unique_id"].asString().c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_version=%{public}s",
                        params["bundle_version"].asString().c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_name=%{public}s",
                        params["bundle_name"].asString().c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.pid=%{public}d", params["pid"].asInt());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.uid=%{public}d", params["uid"].asInt());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.uuid=%{public}s",
                        params["uuid"].asString().c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.exception=%{public}s",
                        writer.write(params["exception"]).c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.hilog.size=%{public}d",
                        params["hilog"].size());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.process_life_time=%{public}d",
                        params["process_life_time"].asInt());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.memory=%{public}s",
                        writer.write(params["memory"]).c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.external_log=%{public}s",
                        writer.write(params["external_log"]).c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.log_over_limit=%{public}d",
                        params["log_over_limit"].asBool());
                }
            }
        }
    } catch (const std::exception& e) {
        OH_LOG_ERROR(LogType::LOG_APP, "Exception in OnReceiveCrashEvent: %{public}s", e.what());
    }
}

static napi_value RegisterWatcherCrashEvent(napi_env env, napi_callback_info info)
{
    systemEventWatcherR = OH_HiAppEvent_CreateWatcher("AppCrashWatcherR");
    if (systemEventWatcherR == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    const char *names[] = {EVENT_APP_CRASH};
    int result = OH_HiAppEvent_SetAppEventFilter(systemEventWatcherR, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set app event filter, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherR);
        systemEventWatcherR = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_SetWatcherOnReceive(systemEventWatcherR, OnReceiveCrashEvent);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set watcher onReceive, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherR);
        systemEventWatcherR = nullptr;
        return {};
    }
    
    HiAppEvent_Config* config = OH_HiAppEvent_CreateConfig();
    if (config != nullptr) {
        OH_HiAppEvent_SetConfigItem(config, OH_APP_CRASH_PARAM_EXTEND_PC_LR_PRINTING, "true");
        OH_HiAppEvent_SetConfigItem(config, OH_APP_CRASH_PARAM_LOG_FILE_CUTOFF_SZ_BYTES, "2097152");
        OH_HiAppEvent_SetConfigItem(config, OH_APP_CRASH_PARAM_SIMPLIFY_VMA_PRINTING, "true");
        OH_HiAppEvent_SetConfigItem(config, OH_APP_CRASH_PARAM_MERGE_CPPCRASH_APP_LOG, "true");
        OH_HiAppEvent_SetConfigItem(config, OH_APP_CRASH_PARAM_COLLECT_MINIDUMP, "true");
        
        result = OH_HiAppEvent_SetEventConfig(EVENT_APP_CRASH, config);
        if (result == HIAPPEVENT_SUCCESS) {
            OH_LOG_INFO(LogType::LOG_APP, "Successfully set APP_CRASH event configurations.");
        } else {
            OH_LOG_ERROR(LogType::LOG_APP, "Failed to set event config, error=%{public}d", result);
        }
        
        OH_HiAppEvent_DestroyConfig(config);
    }
    
    result = OH_HiAppEvent_AddWatcher(systemEventWatcherR);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherR);
        systemEventWatcherR = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Successfully registered crash event watcher");
    return {};
}

static napi_value RemoveWatcherCrash(napi_env env, napi_callback_info info)
{
    if (systemEventWatcherR != nullptr) {
        int result = OH_HiAppEvent_RemoveWatcher(systemEventWatcherR);
        if (result != 0) {
            OH_LOG_ERROR(LogType::LOG_APP, "Failed to remove watcher, error=%{public}d", result);
        }
    }
    return {};
}

static napi_value DestroyWatcherCrash(napi_env env, napi_callback_info info)
{
    if (systemEventWatcherR != nullptr) {
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherR);
        systemEventWatcherR = nullptr;
    }
    OH_LOG_INFO(LogType::LOG_APP, "Successfully destroyed crash event watcher");
    return {};
}

static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "registerWatcherCrashEvent", nullptr, RegisterWatcherCrashEvent, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removeWatcherCrash", nullptr, RemoveWatcherCrash, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "destroyWatcherCrash", nullptr, DestroyWatcherCrash, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

NAPI_MODULE(entry, Init)