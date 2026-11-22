#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"

#undef LOG_TAG
#define LOG_TAG "AppFreezeTrigger"

static HiAppEvent_Watcher *systemEventWatcher = nullptr;

static void OnTake(const char* const *events, uint32_t eventLen) {
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
            
            if (domain == DOMAIN_OS && name == OH_EVENT_APP_FREEZE_WARNING) {
                auto time = eventInfo["time"].asInt64();
                auto foreground = eventInfo["foreground"].asBool();
                auto appRunningUniqueId = eventInfo["app_running_unique_id"].asString();
                auto bundleVersion = eventInfo["bundle_version"].asString();
                auto bundle_version_code = eventInfo["bundle_version_code"].asInt();
                auto bundleName = eventInfo["bundle_name"].asString();
                auto processName = eventInfo["process_name"].asString();
                auto pid = eventInfo["pid"].asInt();
                auto uid = eventInfo["uid"].asInt();
                auto exception = writer.write(eventInfo["exception"]);
                auto hilogSize = eventInfo["hilog"].size();
                auto handleSize = eventInfo["event_handler"].size();
                auto peerBindSize = eventInfo["peer_binder"].size();
                auto threadSize = eventInfo["threads"].size();
                auto memory = writer.write(eventInfo["memory"]);
                auto process_life_time = eventInfo["process_life_time"].asString();
                
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld", time);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.foreground=%{public}d", foreground);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.app_running_unique_id=%{public}s", appRunningUniqueId.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_version=%{public}s", bundleVersion.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_version_code=%{public}d", bundle_version_code);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_name=%{public}s", bundleName.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.process_name=%{public}s", processName.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.pid=%{public}d", pid);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.uid=%{public}d", uid);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.exception=%{public}s", exception.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.hilog.size=%{public}d", hilogSize);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.event_handler.size=%{public}d", handleSize);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.peer_binder.size=%{public}d", peerBindSize);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.threads.size=%{public}d", threadSize);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.memory=%{public}s", memory.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.process_life_time=%{public}s", process_life_time.c_str());
            }
        } else {
            OH_LOG_ERROR(LogType::LOG_APP, "Failed to parse event info");
        }
    }
}

static void OnTrigger(int row, int size) {
    OH_LOG_INFO(LogType::LOG_APP, "OnTrigger called, row=%{public}d, size=%{public}d", row, size);
    OH_HiAppEvent_TakeWatcherData(systemEventWatcher, row, OnTake);
}

static napi_value RegisterWatcher(napi_env env, napi_callback_info info) {
    if (systemEventWatcher != nullptr) {
        OH_LOG_WARN(LogType::LOG_APP, "Watcher already exists, removing old watcher");
        OH_HiAppEvent_RemoveWatcher(systemEventWatcher);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
    }
    
    systemEventWatcher = OH_HiAppEvent_CreateWatcher("onTriggerWatcher");
    if (systemEventWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    const char *names[] = {OH_EVENT_APP_FREEZE_WARNING};
    int result = OH_HiAppEvent_SetAppEventFilter(systemEventWatcher, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "SetAppEventFilter failed: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        return {};
    }
    
    OH_HiAppEvent_SetWatcherOnTrigger(systemEventWatcher, OnTrigger);
    OH_HiAppEvent_SetTriggerCondition(systemEventWatcher, 1, 0, 0);
    
    result = OH_HiAppEvent_AddWatcher(systemEventWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "AddWatcher failed: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Watcher registered successfully");
    return {};
}

static napi_value RemoveWatcher(napi_env env, napi_callback_info info) {
    if (systemEventWatcher != nullptr) {
        OH_HiAppEvent_RemoveWatcher(systemEventWatcher);
        OH_LOG_INFO(LogType::LOG_APP, "Watcher removed successfully");
    }
    return {};
}

static napi_value DestroyWatcher(napi_env env, napi_callback_info info) {
    if (systemEventWatcher != nullptr) {
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        OH_LOG_INFO(LogType::LOG_APP, "Watcher destroyed successfully");
    }
    return {};
}

static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "registerWatcher", nullptr, RegisterWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removeWatcher", nullptr, RemoveWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "destroyWatcher", nullptr, DestroyWatcher, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

extern "C" __attribute__((visibility("default"))) napi_value NAPI_GetAbstractExport(napi_env env, napi_value exports) {
    return Init(env, exports);
}