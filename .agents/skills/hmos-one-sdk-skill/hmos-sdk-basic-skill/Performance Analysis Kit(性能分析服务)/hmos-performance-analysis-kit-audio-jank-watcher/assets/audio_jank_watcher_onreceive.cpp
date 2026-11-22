#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"
#include "hiappevent/hiappevent_event.h"

#undef LOG_TAG
#define LOG_TAG "AudioJankWatcher"

static HiAppEvent_Watcher *audioJankWatcher = nullptr;

static void OnAudioJankEvent(const char *domain, const struct HiAppEvent_AppEventGroup *appEventGroups, uint32_t groupLen) {
    for (uint32_t i = 0; i < groupLen; ++i) {
        for (uint32_t j = 0; j < appEventGroups[i].infoLen; ++j) {
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) == 0 &&
                strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_AUDIO_JANK_FRAME) == 0) {
                
                Json::Value params;
                Json::Reader reader(Json::Features::strictMode());
                
                if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
                    OH_LOG_INFO(LogType::LOG_APP, "Audio Jank Event Detected:");
                    OH_LOG_INFO(LogType::LOG_APP, "  time: %{public}ld", params["time"].asInt64());
                    OH_LOG_INFO(LogType::LOG_APP, "  bundle_version: %{public}s", params["bundle_version"].asString().c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "  bundle_name: %{public}s", params["bundle_name"].asString().c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "  fault_type: %{public}s", params["fault_type"].asString().c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "  happen_time: %{public}ld", params["happen_time"].asInt64());
                    OH_LOG_INFO(LogType::LOG_APP, "  max_frame_time: %{public}ld", params["max_frame_time"].asInt64());
                } else {
                    OH_LOG_ERROR(LogType::LOG_APP, "Failed to parse audio jank event params");
                }
            }
        }
    }
}

static napi_value RegisterAudioJankWatcher(napi_env env, napi_callback_info info) {
    if (audioJankWatcher != nullptr) {
        OH_LOG_WARN(LogType::LOG_APP, "Audio jank watcher already registered");
        return {};
    }
    
    audioJankWatcher = OH_HiAppEvent_CreateWatcher("AudioJankReceiver");
    if (audioJankWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create audio jank watcher");
        return {};
    }
    
    const char *eventNames[] = {EVENT_AUDIO_JANK_FRAME};
    int result = OH_HiAppEvent_SetAppEventFilter(audioJankWatcher, DOMAIN_OS, 0, eventNames, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set event filter, error: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(audioJankWatcher);
        audioJankWatcher = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_SetWatcherOnReceive(audioJankWatcher, OnAudioJankEvent);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set onReceive callback, error: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(audioJankWatcher);
        audioJankWatcher = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_AddWatcher(audioJankWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher, error: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(audioJankWatcher);
        audioJankWatcher = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Audio jank watcher registered successfully");
    return {};
}

static napi_value UnregisterAudioJankWatcher(napi_env env, napi_callback_info info) {
    if (audioJankWatcher != nullptr) {
        OH_HiAppEvent_RemoveWatcher(audioJankWatcher);
        OH_HiAppEvent_DestroyWatcher(audioJankWatcher);
        audioJankWatcher = nullptr;
        OH_LOG_INFO(LogType::LOG_APP, "Audio jank watcher unregistered successfully");
    }
    return {};
}

static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        {"registerAudioJankWatcher", nullptr, RegisterAudioJankWatcher, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"unregisterAudioJankWatcher", nullptr, UnregisterAudioJankWatcher, nullptr, nullptr, nullptr, napi_default, nullptr}
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

EXTERN_C_START
static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "entry",
    .nm_priv = ((void*)0),
    .reserved = { 0 },
};
EXTERN_C_END

static void __attribute__((constructor)) RegisterModule(void) {
    napi_register_module(&demoModule);
}