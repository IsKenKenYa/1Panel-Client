#include "napi/native_api.h"
#include "../../../build/jsoncpp-1.9.6/include/json/json.h"
#include "hiappevent/hiappevent.h"
#include "hilog/log.h"
#include <ctime>
#include <cstring>

#undef LOG_TAG
#define LOG_TAG "HiAppEventExample"

static HiAppEvent_Watcher *crashWatcher = nullptr;
static HiAppEvent_Watcher *clickWatcher = nullptr;

static void OnReceiveCrash(const char *domain, const struct HiAppEvent_AppEventGroup *appEventGroups, uint32_t groupLen)
{
    OH_LOG_INFO(LogType::LOG_APP, "OnReceive callback triggered, groupLen=%{public}u", groupLen);
    
    for (uint32_t i = 0; i < groupLen; ++i) {
        for (uint32_t j = 0; j < appEventGroups[i].infoLen; ++j) {
            OH_LOG_INFO(LogType::LOG_APP, "eventInfo.domain=%{public}s", appEventGroups[i].appEventInfos[j].domain);
            OH_LOG_INFO(LogType::LOG_APP, "eventInfo.name=%{public}s", appEventGroups[i].appEventInfos[j].name);
            OH_LOG_INFO(LogType::LOG_APP, "eventInfo.eventType=%{public}d", appEventGroups[i].appEventInfos[j].type);
            
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) != 0 ||
                strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_APP_CRASH) != 0) {
                continue;
            }
            
            Json::Value params;
            Json::Reader reader(Json::Features::strictMode());
            Json::FastWriter writer;
            
            if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
                int64_t crashTime = params["time"].asInt64();
                OH_LOG_INFO(LogType::LOG_APP, "crashTime=%{public}lld", crashTime);
                
                std::string bundleName = params["bundle_name"].asString();
                OH_LOG_INFO(LogType::LOG_APP, "bundleName=%{public}s", bundleName.c_str());
                
                std::string externalLog = writer.write(params["external_log"]);
                OH_LOG_INFO(LogType::LOG_APP, "externalLog=%{public}s", externalLog.c_str());
            }
        }
    }
}

static napi_value RegisterCrashWatcher(napi_env env, napi_callback_info info)
{
    crashWatcher = OH_HiAppEvent_CreateWatcher("CrashWatcherExample001");
    if (crashWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "CreateWatcher failed, name invalid");
        return {};
    }
    
    const char *names[] = {EVENT_APP_CRASH};
    int result = OH_HiAppEvent_SetAppEventFilter(crashWatcher, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "SetAppEventFilter failed, result=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(crashWatcher);
        crashWatcher = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_SetWatcherOnReceive(crashWatcher, OnReceiveCrash);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "SetWatcherOnReceive failed, result=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(crashWatcher);
        crashWatcher = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_AddWatcher(crashWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "AddWatcher failed, result=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(crashWatcher);
        crashWatcher = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "CrashWatcher registered successfully");
    return {};
}

static void OnTakeClickEvents(const char* const *events, uint32_t eventLen)
{
    Json::Reader reader(Json::Features::strictMode());
    OH_LOG_INFO(LogType::LOG_APP, "OnTake callback, eventLen=%{public}u", eventLen);
    
    for (uint32_t i = 0; i < eventLen; ++i) {
        Json::Value eventInfo;
        if (reader.parse(events[i], eventInfo)) {
            std::string domain = eventInfo["domain_"].asString();
            std::string name = eventInfo["name_"].asString();
            int type = eventInfo["type_"].asInt();
            
            OH_LOG_INFO(LogType::LOG_APP, "event.domain=%{public}s", domain.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "event.name=%{public}s", name.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "event.type=%{public}d", type);
            
            if (domain == "button" && name == "click") {
                int64_t clickTime = eventInfo["clickTime"].asInt64();
                OH_LOG_INFO(LogType::LOG_APP, "clickTime=%{public}lld", clickTime);
            }
        }
    }
}

static void OnTriggerClick(int row, int size)
{
    OH_LOG_INFO(LogType::LOG_APP, "OnTrigger callback, row=%{public}d, size=%{public}d", row, size);
    OH_HiAppEvent_TakeWatcherData(clickWatcher, row, OnTakeClickEvents);
}

static napi_value RegisterClickWatcher(napi_env env, napi_callback_info info)
{
    clickWatcher = OH_HiAppEvent_CreateWatcher("ButtonClickWatcherExample001");
    if (clickWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "CreateWatcher failed, name invalid");
        return {};
    }
    
    const char *names[] = {"click"};
    int result = OH_HiAppEvent_SetAppEventFilter(clickWatcher, "button", 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "SetAppEventFilter failed, result=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(clickWatcher);
        clickWatcher = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_SetWatcherOnTrigger(clickWatcher, OnTriggerClick);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "SetWatcherOnTrigger failed, result=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(clickWatcher);
        clickWatcher = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_SetTriggerCondition(clickWatcher, 1, 0, 0);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "SetTriggerCondition failed, result=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(clickWatcher);
        clickWatcher = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_AddWatcher(clickWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "AddWatcher failed, result=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(clickWatcher);
        clickWatcher = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "ClickWatcher registered successfully");
    return {};
}

static napi_value WriteButtonClickEvent(napi_env env, napi_callback_info info)
{
    ParamList params = OH_HiAppEvent_CreateParamList();
    if (params == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "CreateParamList failed");
        return {};
    }
    
    params = OH_HiAppEvent_AddInt64Param(params, "clickTime", time(nullptr));
    
    int result = OH_HiAppEvent_Write("button", "click", EventType::BEHAVIOR, params);
    
    OH_HiAppEvent_DestroyParamList(params);
    
    if (result < 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Write event failed, result=%{public}d", result);
    } else if (result > 0) {
        OH_LOG_WARN(LogType::LOG_APP, "Write event success but discard invalid params, result=%{public}d", result);
    } else {
        OH_LOG_INFO(LogType::LOG_APP, "Write event success, result=0");
    }
    
    return {};
}

static napi_value RemoveAllWatchers(napi_env env, napi_callback_info info)
{
    if (crashWatcher != nullptr) {
        int result = OH_HiAppEvent_RemoveWatcher(crashWatcher);
        if (result != 0) {
            OH_LOG_ERROR(LogType::LOG_APP, "RemoveWatcher crashWatcher failed, result=%{public}d", result);
        } else {
            OH_LOG_INFO(LogType::LOG_APP, "RemoveWatcher crashWatcher success");
        }
    }
    
    if (clickWatcher != nullptr) {
        int result = OH_HiAppEvent_RemoveWatcher(clickWatcher);
        if (result != 0) {
            OH_LOG_ERROR(LogType::LOG_APP, "RemoveWatcher clickWatcher failed, result=%{public}d", result);
        } else {
            OH_LOG_INFO(LogType::LOG_APP, "RemoveWatcher clickWatcher success");
        }
    }
    
    return {};
}

static napi_value DestroyAllWatchers(napi_env env, napi_callback_info info)
{
    if (crashWatcher != nullptr) {
        OH_HiAppEvent_DestroyWatcher(crashWatcher);
        crashWatcher = nullptr;
        OH_LOG_INFO(LogType::LOG_APP, "DestroyWatcher crashWatcher success");
    }
    
    if (clickWatcher != nullptr) {
        OH_HiAppEvent_DestroyWatcher(clickWatcher);
        clickWatcher = nullptr;
        OH_LOG_INFO(LogType::LOG_APP, "DestroyWatcher clickWatcher success");
    }
    
    return {};
}

static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "registerCrashWatcher", nullptr, RegisterCrashWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "registerClickWatcher", nullptr, RegisterClickWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "writeButtonClickEvent", nullptr, WriteButtonClickEvent, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removeAllWatchers", nullptr, RemoveAllWatchers, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "destroyAllWatchers", nullptr, DestroyAllWatchers, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

EXTERN_C_START
static napi_value NapiExport(napi_env env, napi_value exports)
{
    return Init(env, exports);
}
EXTERN_C_END

static napi_module module = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = NapiExport,
    .nm_modname = "entry",
    .nm_priv = nullptr,
    .reserved = { 0 },
};

extern "C" __attribute__((constructor)) void RegisterModule(void)
{
    napi_module_register(&module);
}