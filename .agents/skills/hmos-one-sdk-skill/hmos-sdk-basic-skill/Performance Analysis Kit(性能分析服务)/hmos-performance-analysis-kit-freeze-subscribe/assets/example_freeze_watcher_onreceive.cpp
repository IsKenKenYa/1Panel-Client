// 订阅应用冻屏事件示例代码 (onReceive模式)
// 文件: napi_init.cpp

#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"

#undef LOG_TAG
#define LOG_TAG "FreezeWatcher"

// 定义观察者指针变量
static HiAppEvent_Watcher *freezeWatcher = nullptr;

// onReceive回调函数 - 实时接收冻屏事件
static void OnReceive(const char *domain, 
                      const struct HiAppEvent_AppEventGroup *appEventGroups, 
                      uint32_t groupLen) {
    for (uint32_t i = 0; i < groupLen; ++i) {
        for (uint32_t j = 0; j < appEventGroups[i].infoLen; ++j) {
            // 记录事件基本信息
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", 
                        appEventGroups[i].appEventInfos[j].domain);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", 
                        appEventGroups[i].appEventInfos[j].name);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d", 
                        appEventGroups[i].appEventInfos[j].type);
            
            // 检查是否为应用冻屏事件
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) == 0 &&
                strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_APP_FREEZE) == 0) {
                
                // 解析事件参数(JSON格式)
                Json::Value params;
                Json::Reader reader(Json::Features::strictMode());
                Json::FastWriter writer;
                
                try {
                    if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
                        // 提取冻屏事件关键参数
                        auto time = params["time"].asInt64();
                        auto foreground = params["foreground"].asBool();
                        auto appRunningUniqueId = params["app_running_unique_id"].asString();
                        auto bundleVersion = params["bundle_version"].asString();
                        auto bundleName = params["bundle_name"].asString();
                        auto processName = params["process_name"].asString();
                        auto pid = params["pid"].asInt();
                        auto uid = params["uid"].asInt();
                        auto uuid = params["uuid"].asString();
                        auto exception = writer.write(params["exception"]);
                        auto hilogSize = params["hilog"].size();
                        auto handleSize = params["event_handler"].size();
                        auto handleSize3s = params["event_handler_size_3s"].asString();
                        auto handleSize6s = params["event_handler_size_6s"].asString();
                        auto peerBindSize = params["peer_binder"].size();
                        auto threadSize = params["threads"].size();
                        auto memory = writer.write(params["memory"]);
                        auto externalLog = writer.write(params["external_log"]);
                        auto logOverLimit = params["log_over_limit"].asBool();
                        auto externalCallbackLog = params["external_callback_log"].asString();
                        
                        // 记录冻屏详细信息
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld", time);
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.foreground=%{public}d", foreground);
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.app_running_unique_id=%{public}s", 
                                    appRunningUniqueId.c_str());
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_version=%{public}s", 
                                    bundleVersion.c_str());
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_name=%{public}s", 
                                    bundleName.c_str());
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.process_name=%{public}s", 
                                    processName.c_str());
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.pid=%{public}d", pid);
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.uid=%{public}d", uid);
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.uuid=%{public}s", uuid.c_str());
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.exception=%{public}s", 
                                    exception.c_str());
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.hilog.size=%{public}d", hilogSize);
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.event_handler.size=%{public}d", 
                                    handleSize);
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.event_handler_3s.size=%{public}s", 
                                    handleSize3s.c_str());
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.event_handler_6s.size=%{public}s", 
                                    handleSize6s.c_str());
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.peer_binder.size=%{public}d", 
                                    peerBindSize);
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.threads.size=%{public}d", threadSize);
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.memory=%{public}s", memory.c_str());
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.external_log=%{public}s", 
                                    externalLog.c_str());
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.log_over_limit=%{public}d", 
                                    logOverLimit);
                        OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.external_callback_log=%{public}s", 
                                    externalCallbackLog.c_str());
                    }
                } catch (const std::exception& e) {
                    OH_LOG_ERROR(LogType::LOG_APP, "JSON parse error: %{public}s", e.what());
                }
            }
        }
    }
}

// 注册观察者函数
static napi_value RegisterWatcher(napi_env env, napi_callback_info info) {
    // 1. 创建观察者
    freezeWatcher = OH_HiAppEvent_CreateWatcher("freezeReceiverWatcher");
    if (freezeWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    // 2. 设置事件过滤
    const char *names[] = {EVENT_APP_FREEZE};
    int result = OH_HiAppEvent_SetAppEventFilter(freezeWatcher, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(freezeWatcher);
        freezeWatcher = nullptr;
        return {};
    }
    
    // 3. 设置onReceive回调
    result = OH_HiAppEvent_SetWatcherOnReceive(freezeWatcher, OnReceive);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set onReceive: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(freezeWatcher);
        freezeWatcher = nullptr;
        return {};
    }
    
    // 4. 添加观察者
    result = OH_HiAppEvent_AddWatcher(freezeWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(freezeWatcher);
        freezeWatcher = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Freeze watcher registered successfully");
    return {};
}

// 移除观察者函数
static napi_value RemoveWatcher(napi_env env, napi_callback_info info) {
    if (freezeWatcher != nullptr) {
        int result = OH_HiAppEvent_RemoveWatcher(freezeWatcher);
        if (result != 0) {
            OH_LOG_ERROR(LogType::LOG_APP, "Failed to remove watcher: %{public}d", result);
        } else {
            OH_LOG_INFO(LogType::LOG_APP, "Freeze watcher removed successfully");
        }
    }
    return {};
}

// 销毁观察者函数
static napi_value DestroyWatcher(napi_env env, napi_callback_info info) {
    if (freezeWatcher != nullptr) {
        OH_HiAppEvent_RemoveWatcher(freezeWatcher);
        OH_HiAppEvent_DestroyWatcher(freezeWatcher);
        freezeWatcher = nullptr;
        OH_LOG_INFO(LogType::LOG_APP, "Freeze watcher destroyed successfully");
    }
    return {};
}

// 注册NAPI接口
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "registerWatcher", nullptr, RegisterWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removeWatcher", nullptr, RemoveWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "destroyWatcher", nullptr, DestroyWatcher, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

extern "C" {
    napi_value NAPI_GetInstance(napi_env env, napi_value exports) {
        return Init(env, exports);
    }
}