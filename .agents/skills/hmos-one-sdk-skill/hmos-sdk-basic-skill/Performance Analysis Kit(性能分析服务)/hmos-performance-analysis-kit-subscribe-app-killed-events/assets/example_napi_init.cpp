#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"
#include "hiappevent/hiappevent_event.h"
#include <thread>
#include <cstring>

#undef LOG_TAG
#define LOG_TAG "AppKilledEvent"

static HiAppEvent_Watcher *systemEventWatcher = nullptr;

static void OnReceive(const char *domain, 
                      const struct HiAppEvent_AppEventGroup *appEventGroups, 
                      uint32_t groupLen) {
    for (uint32_t i = 0; i < groupLen; ++i) {
        for (uint32_t j = 0; j < appEventGroups[i].infoLen; ++j) {
            OH_LOG_INFO(LogType::LOG_APP, 
                "Event received: domain=%{public}s, name=%{public}s, type=%{public}d",
                appEventGroups[i].appEventInfos[j].domain,
                appEventGroups[i].appEventInfos[j].name,
                appEventGroups[i].appEventInfos[j].type);
            
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) == 0 &&
                strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_APP_KILLED) == 0) {
                
                Json::Value params;
                Json::Reader reader(Json::Features::strictMode());
                
                try {
                    if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
                        int64_t time = params["time"].asInt64();
                        std::string reason = params["reason"].asString();
                        std::string foreground = params["foreground"].asString();
                        std::string appRunningUniqueId = params["app_running_unique_id"].asString();
                        std::string bundleVersion = params["bundle_version"].asString();
                        
                        OH_LOG_INFO(LogType::LOG_APP, 
                            "App killed event params:");
                        OH_LOG_INFO(LogType::LOG_APP, 
                            "  time=%{public}lld", time);
                        OH_LOG_INFO(LogType::LOG_APP, 
                            "  reason=%{public}s", reason.c_str());
                        OH_LOG_INFO(LogType::LOG_APP, 
                            "  foreground=%{public}s", foreground.c_str());
                        OH_LOG_INFO(LogType::LOG_APP, 
                            "  app_running_unique_id=%{public}s", appRunningUniqueId.c_str());
                        OH_LOG_INFO(LogType::LOG_APP, 
                            "  bundle_version=%{public}s", bundleVersion.c_str());
                        
                        if (reason.find("ResourceLeak") != std::string::npos) {
                            OH_LOG_ERROR(LogType::LOG_APP, 
                                "Resource leak detected: %{public}s", reason.c_str());
                        } else if (reason == "RssThresholdKiller") {
                            OH_LOG_ERROR(LogType::LOG_APP, 
                                "RSS memory exceeded threshold");
                        } else if (reason == "ThreadBlock6S") {
                            OH_LOG_ERROR(LogType::LOG_APP, 
                                "Main thread blocked for 6 seconds");
                        }
                    } else {
                        OH_LOG_ERROR(LogType::LOG_APP, 
                            "JSON parse failed: %{public}s", 
                            reader.getFormattedErrorMessages().c_str());
                    }
                } catch (const std::exception& e) {
                    OH_LOG_ERROR(LogType::LOG_APP, 
                        "Exception in JSON parsing: %{public}s", e.what());
                }
            }
        }
    }
}

static napi_value RegisterWatcher(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LogType::LOG_APP, "RegisterWatcher start");
    
    if (systemEventWatcher != nullptr) {
        OH_LOG_WARN(LogType::LOG_APP, "Watcher already registered");
        return {};
    }
    
    systemEventWatcher = OH_HiAppEvent_CreateWatcher("AppKilledWatcher");
    if (systemEventWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "CreateWatcher failed: returned nullptr");
        return {};
    }
    
    const char *names[] = {EVENT_APP_KILLED};
    int result = OH_HiAppEvent_SetAppEventFilter(
        systemEventWatcher, 
        DOMAIN_OS, 
        0,
        names, 
        1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, 
            "SetAppEventFilter failed: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_SetWatcherOnReceive(systemEventWatcher, OnReceive);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, 
            "SetWatcherOnReceive failed: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_AddWatcher(systemEventWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, 
            "AddWatcher failed: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "RegisterWatcher success");
    return {};
}

static napi_value RemoveWatcher(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LogType::LOG_APP, "RemoveWatcher start");
    
    if (systemEventWatcher != nullptr) {
        int result = OH_HiAppEvent_RemoveWatcher(systemEventWatcher);
        if (result == 0) {
            OH_LOG_INFO(LogType::LOG_APP, "RemoveWatcher success");
        } else {
            OH_LOG_ERROR(LogType::LOG_APP, 
                "RemoveWatcher failed: %{public}d", result);
        }
    } else {
        OH_LOG_WARN(LogType::LOG_APP, "Watcher is nullptr");
    }
    
    return {};
}

static napi_value DestroyWatcher(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LogType::LOG_APP, "DestroyWatcher start");
    
    if (systemEventWatcher != nullptr) {
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        OH_LOG_INFO(LogType::LOG_APP, "DestroyWatcher success");
    } else {
        OH_LOG_WARN(LogType::LOG_APP, "Watcher is nullptr");
    }
    
    return {};
}

static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "registerWatcher", nullptr, RegisterWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removeWatcher", nullptr, RemoveWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "destroyWatcher", nullptr, DestroyWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

NAPI_MODULE(entry, Init)