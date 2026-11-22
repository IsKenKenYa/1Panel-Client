/**
 * 资源泄漏事件订阅完整示例 - onReceive模式
 * 使用HiAppEvent C/C++接口订阅系统资源泄漏事件
 */

#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"
#include <string.h>

#undef LOG_TAG
#define LOG_TAG "ResourceLeakWatcher"

static HiAppEvent_Watcher *systemEventWatcher = nullptr;

static void OnReceive(const char *domain, const struct HiAppEvent_AppEventGroup *appEventGroups, uint32_t groupLen) {
    for (int i = 0; i < groupLen; ++i) {
        for (int j = 0; j < appEventGroups[i].infoLen; ++j) {
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", appEventGroups[i].appEventInfos[j].domain);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", appEventGroups[i].appEventInfos[j].name);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d", appEventGroups[i].appEventInfos[j].type);
            
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) == 0 &&
                strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_RESOURCE_OVERLIMIT) == 0) {
                Json::Value params;
                Json::Reader reader(Json::Features::strictMode());
                Json::FastWriter writer;
                
                if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
                    auto time = params["time"].asInt64();
                    auto pid = params["pid"].asInt();
                    auto uid = params["uid"].asInt();
                    auto resourceType = params["resourceType"].asString();
                    auto bundleName = params["bundle_name"].asString();
                    auto appRunningUniqueId = params["app_running_unique_id"].asString();
                    auto bundleVersion = params["bundle_version"].asString();
                    auto memory = writer.write(params["memory"]);
                    auto externalLog = writer.write(params["external_log"]);
                    std::string logOverLimit = params["log_over_limit"].asBool() ? "true":"false";
                    
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld", time);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.pid=%{public}d", pid);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.uid=%{public}d", uid);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.resource_type=%{public}s", resourceType.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_name=%{public}s", bundleName.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.app_running_unique_id=%{public}s", appRunningUniqueId.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_version=%{public}s", bundleVersion.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.memory=%{public}s", memory.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.external_log=%{public}s", externalLog.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.log_over_limit=%{public}s", logOverLimit.c_str());
                }
            }
        }
    }
}

static napi_value RegisterWatcher(napi_env env, napi_callback_info info) {
    systemEventWatcher = OH_HiAppEvent_CreateWatcher("onReceiverWatcher");
    
    if (systemEventWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    const char *names[] = {EVENT_RESOURCE_OVERLIMIT};
    int result = OH_HiAppEvent_SetAppEventFilter(systemEventWatcher, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        return {};
    }
    
    OH_HiAppEvent_SetWatcherOnReceive(systemEventWatcher, OnReceive);
    
    result = OH_HiAppEvent_AddWatcher(systemEventWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
    } else {
        OH_LOG_INFO(LogType::LOG_APP, "Watcher added successfully");
    }
    
    return {};
}

static napi_value RemoveWatcher(napi_env env, napi_callback_info info) {
    if (systemEventWatcher != nullptr) {
        int result = OH_HiAppEvent_RemoveWatcher(systemEventWatcher);
        if (result != 0) {
            OH_LOG_ERROR(LogType::LOG_APP, "Failed to remove watcher: %{public}d", result);
        } else {
            OH_LOG_INFO(LogType::LOG_APP, "Watcher removed successfully");
        }
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

EXTERN_C_START
NAPI_MODULE_AUTO_EXPORT(entry, Init)
EXTERN_C_END