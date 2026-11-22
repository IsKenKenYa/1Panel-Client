#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"
#include "hiappevent/hiappevent_event.h"

#undef LOG_TAG
#define LOG_TAG "AudioJankTriggerWatcher"

static HiAppEvent_Watcher *triggerWatcher = nullptr;

static void OnTakeAudioJankEvents(const char* const *events, uint32_t eventLen) {
    Json::Reader reader(Json::Features::strictMode());
    
    for (uint32_t i = 0; i < eventLen; ++i) {
        Json::Value eventInfo;
        if (reader.parse(events[i], eventInfo)) {
            auto domain = eventInfo["domain_"].asString();
            auto name = eventInfo["name_"].asString();
            
            if (domain == DOMAIN_OS && name == EVENT_AUDIO_JANK_FRAME) {
                OH_LOG_INFO(LogType::LOG_APP, "Audio Jank Event (Trigger Mode):");
                OH_LOG_INFO(LogType::LOG_APP, "  time: %{public}ld", eventInfo["time"].asInt64());
                OH_LOG_INFO(LogType::LOG_APP, "  bundle_version: %{public}s", eventInfo["bundle_version"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "  bundle_name: %{public}s", eventInfo["bundle_name"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "  fault_type: %{public}s", eventInfo["fault_type"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "  happen_time: %{public}ld", eventInfo["happen_time"].asInt64());
                OH_LOG_INFO(LogType::LOG_APP, "  max_frame_time: %{public}ld", eventInfo["max_frame_time"].asInt64());
            }
        }
    }
}

static void OnAudioJankTrigger(int row, int size) {
    OH_LOG_INFO(LogType::LOG_APP, "Audio jank trigger fired, row=%{public}d, size=%{public}d", row, size);
    OH_HiAppEvent_TakeWatcherData(triggerWatcher, row, OnTakeAudioJankEvents);
}

static napi_value RegisterTriggerWatcher(napi_env env, napi_callback_info info) {
    if (triggerWatcher != nullptr) {
        OH_LOG_WARN(LogType::LOG_APP, "Trigger watcher already registered");
        return {};
    }
    
    triggerWatcher = OH_HiAppEvent_CreateWatcher("AudioJankTrigger");
    if (triggerWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create trigger watcher");
        return {};
    }
    
    const char *eventNames[] = {EVENT_AUDIO_JANK_FRAME};
    int result = OH_HiAppEvent_SetAppEventFilter(triggerWatcher, DOMAIN_OS, 0, eventNames, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter, error: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(triggerWatcher);
        triggerWatcher = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_SetWatcherOnTrigger(triggerWatcher, OnAudioJankTrigger);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set trigger callback, error: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(triggerWatcher);
        triggerWatcher = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_SetTriggerCondition(triggerWatcher, 1, 0, 0);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set trigger condition, error: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(triggerWatcher);
        triggerWatcher = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_AddWatcher(triggerWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher, error: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(triggerWatcher);
        triggerWatcher = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Trigger watcher registered successfully");
    return {};
}

static napi_value UnregisterTriggerWatcher(napi_env env, napi_callback_info info) {
    if (triggerWatcher != nullptr) {
        OH_HiAppEvent_RemoveWatcher(triggerWatcher);
        OH_HiAppEvent_DestroyWatcher(triggerWatcher);
        triggerWatcher = nullptr;
        OH_LOG_INFO(LogType::LOG_APP, "Trigger watcher unregistered successfully");
    }
    return {};
}

static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        {"registerTriggerWatcher", nullptr, RegisterTriggerWatcher, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"unregisterTriggerWatcher", nullptr, UnregisterTriggerWatcher, nullptr, nullptr, nullptr, napi_default, nullptr}
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