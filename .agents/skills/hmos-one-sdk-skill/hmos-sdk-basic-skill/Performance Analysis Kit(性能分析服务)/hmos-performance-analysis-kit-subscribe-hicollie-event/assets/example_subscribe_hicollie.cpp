#include "napi/native_api.h"
#include "../../../build/jsoncpp-1.9.6/include/json/json.h"
#include "hiappevent/hiappevent.h"
#include "hicollie/hicollie.h"
#include "hilog/log.h"
#include <unistd.h>

#undef LOG_TAG
#define LOG_TAG "HiCollieEventWatcher"

static HiAppEvent_Watcher *appHicollieWatcherR = nullptr;
static HiAppEvent_Watcher *appHicollieWatcherT = nullptr;

void OnReceiveAppHicollie(const struct HiAppEvent_AppEventGroup *appEventGroups, int i, int j)
{
    if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) != 0 ||
        strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_APP_HICOLLIE) != 0) {
        return;
    }

    Json::Value params;
    Json::Reader reader(Json::Features::strictMode());
    Json::FastWriter writer;
    
    if (!reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
        OH_LOG_ERROR(LogType::LOG_APP, "JSON parse failed");
        return;
    }

    auto time = params["time"].asInt64();
    auto foreground = params["foreground"].asBool();
    auto bundleVersion = params["bundle_version"].asString();
    auto processName = params["process_name"].asString();
    auto pid = params["pid"].asInt();
    auto uid = params["uid"].asInt();
    auto uuid = params["uuid"].asString();
    auto exception = writer.write(params["exception"]);
    auto hilogSize = params["hilog"].size();
    auto peerBindSize = params["peer_binder"].size();
    auto memory = writer.write(params["memory"]);
    auto externalLog = writer.write(params["external_log"]);
    auto logOverLimit = params["log_over_limit"].asBool();
    auto externalCallbackLog = params["external_callback_log"].asString();

    OH_LOG_INFO(LogType::LOG_APP, "Event received: domain=%{public}s, name=%{public}s",
        appEventGroups[i].appEventInfos[j].domain,
        appEventGroups[i].appEventInfos[j].name);
    OH_LOG_INFO(LogType::LOG_APP, "time=%{public}lld, foreground=%{public}d, pid=%{public}d",
        time, foreground, pid);
    OH_LOG_INFO(LogType::LOG_APP, "bundle_version=%{public}s, process_name=%{public}s",
        bundleVersion.c_str(), processName.c_str());
}

void AppHicollieOnReceive(const char *domain, 
    const struct HiAppEvent_AppEventGroup *appEventGroups,
    uint32_t groupLen)
{
    for (int i = 0; i < groupLen; ++i) {
        for (int j = 0; j < appEventGroups[i].infoLen; ++j) {
            OnReceiveAppHicollie(appEventGroups, i, j);
        }
    }
}

void AppHicollieOnTake(const char* const *events, uint32_t eventLen)
{
    Json::Reader reader(Json::Features::strictMode());
    Json::FastWriter writer;
    
    for (int i = 0; i < eventLen; ++i) {
        Json::Value eventInfo;
        if (!reader.parse(events[i], eventInfo)) {
            OH_LOG_ERROR(LogType::LOG_APP, "JSON parse failed");
            continue;
        }

        auto domain = eventInfo["domain_"].asString();
        auto name = eventInfo["name_"].asString();
        
        if (domain == DOMAIN_OS && name == EVENT_APP_HICOLLIE) {
            auto time = eventInfo["time"].asInt64();
            auto foreground = eventInfo["foreground"].asBool();
            auto pid = eventInfo["pid"].asInt();
            auto uid = eventInfo["uid"].asInt();
            
            OH_LOG_INFO(LogType::LOG_APP, "Event taken: time=%{public}lld, pid=%{public}d, uid=%{public}d",
                time, pid, uid);
        }
    }
}

void AppHicollieOnTrigger(int row, int size)
{
    OH_HiAppEvent_TakeWatcherData(appHicollieWatcherT, row, AppHicollieOnTake);
}

void HiCollieTimerCallback(void* arg)
{
    OH_LOG_INFO(LogType::LOG_APP, "HiCollie timer timeout callback executed");
}

napi_value RegisterAppHicollieWatcherR(napi_env env, napi_callback_info info)
{
    appHicollieWatcherR = OH_HiAppEvent_CreateWatcher("appHicollieWatcherR");
    if (appHicollieWatcherR == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return nullptr;
    }

    const char *names[] = {EVENT_APP_HICOLLIE};
    int result = OH_HiAppEvent_SetAppEventFilter(appHicollieWatcherR, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "SetAppEventFilter failed: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(appHicollieWatcherR);
        appHicollieWatcherR = nullptr;
        return nullptr;
    }

    result = OH_HiAppEvent_SetWatcherOnReceive(appHicollieWatcherR, AppHicollieOnReceive);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "SetWatcherOnReceive failed: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(appHicollieWatcherR);
        appHicollieWatcherR = nullptr;
        return nullptr;
    }

    result = OH_HiAppEvent_AddWatcher(appHicollieWatcherR);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "AddWatcher failed: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(appHicollieWatcherR);
        appHicollieWatcherR = nullptr;
        return nullptr;
    }

    OH_LOG_INFO(LogType::LOG_APP, "WatcherR added successfully");
    return nullptr;
}

napi_value RegisterAppHicollieWatcherT(napi_env env, napi_callback_info info)
{
    appHicollieWatcherT = OH_HiAppEvent_CreateWatcher("appHicollieWatcherT");
    if (appHicollieWatcherT == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return nullptr;
    }

    const char *names[] = {EVENT_APP_HICOLLIE};
    int result = OH_HiAppEvent_SetAppEventFilter(appHicollieWatcherT, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "SetAppEventFilter failed: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(appHicollieWatcherT);
        appHicollieWatcherT = nullptr;
        return nullptr;
    }

    result = OH_HiAppEvent_SetTriggerCondition(appHicollieWatcherT, 1, 0, 0);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "SetTriggerCondition failed: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(appHicollieWatcherT);
        appHicollieWatcherT = nullptr;
        return nullptr;
    }

    result = OH_HiAppEvent_SetWatcherOnTrigger(appHicollieWatcherT, AppHicollieOnTrigger);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "SetWatcherOnTrigger failed: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(appHicollieWatcherT);
        appHicollieWatcherT = nullptr;
        return nullptr;
    }

    result = OH_HiAppEvent_AddWatcher(appHicollieWatcherT);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "AddWatcher failed: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(appHicollieWatcherT);
        appHicollieWatcherT = nullptr;
        return nullptr;
    }

    OH_LOG_INFO(LogType::LOG_APP, "WatcherT added successfully");
    return nullptr;
}

napi_value TestHiCollieTimerNdk(napi_env env, napi_callback_info info)
{
    int timerId = 0;
    
    HiCollie_SetTimerParam param = {
        "testTimer",
        1,
        HiCollieTimerCallback,
        nullptr,
        HiCollie_Flag::HICOLLIE_FLAG_LOG
    };
    
    HiCollie_ErrorCode errorCode = OH_HiCollie_SetTimer(param, &timerId);
    
    if (errorCode == HICOLLIE_SUCCESS) {
        OH_LOG_INFO(LogType::LOG_APP, "Timer set successfully, id=%{public}d", timerId);
        sleep(2);
        OH_HiCollie_CancelTimer(timerId);
        OH_LOG_INFO(LogType::LOG_APP, "Timer canceled");
    } else {
        OH_LOG_ERROR(LogType::LOG_APP, "SetTimer failed: %{public}d", errorCode);
    }
    
    return nullptr;
}

napi_value RemoveWatcher(napi_env env, napi_callback_info info)
{
    if (appHicollieWatcherR != nullptr) {
        int result = OH_HiAppEvent_RemoveWatcher(appHicollieWatcherR);
        OH_LOG_INFO(LogType::LOG_APP, "RemoveWatcherR: %{public}d", result);
    }
    
    if (appHicollieWatcherT != nullptr) {
        int result = OH_HiAppEvent_RemoveWatcher(appHicollieWatcherT);
        OH_LOG_INFO(LogType::LOG_APP, "RemoveWatcherT: %{public}d", result);
    }
    
    return nullptr;
}

napi_value DestroyWatcher(napi_env env, napi_callback_info info)
{
    if (appHicollieWatcherR != nullptr) {
        OH_HiAppEvent_DestroyWatcher(appHicollieWatcherR);
        appHicollieWatcherR = nullptr;
    }
    
    if (appHicollieWatcherT != nullptr) {
        OH_HiAppEvent_DestroyWatcher(appHicollieWatcherT);
        appHicollieWatcherT = nullptr;
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Watchers destroyed");
    return nullptr;
}

static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "RegisterAppHicollieWatcherR", nullptr, RegisterAppHicollieWatcherR, 
          nullptr, nullptr, nullptr, napi_default, nullptr },
        { "RegisterAppHicollieWatcherT", nullptr, RegisterAppHicollieWatcherT, 
          nullptr, nullptr, nullptr, napi_default, nullptr },
        { "TestHiCollieTimerNdk", nullptr, TestHiCollieTimerNdk, 
          nullptr, nullptr, nullptr, napi_default, nullptr },
        { "RemoveWatcher", nullptr, RemoveWatcher, 
          nullptr, nullptr, nullptr, napi_default, nullptr },
        { "DestroyWatcher", nullptr, DestroyWatcher, 
          nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

extern "C" __attribute__((visibility("default"))) napi_value NAPI_GetModule(napi_env env, napi_value exports)
{
    return Init(env, exports);
}