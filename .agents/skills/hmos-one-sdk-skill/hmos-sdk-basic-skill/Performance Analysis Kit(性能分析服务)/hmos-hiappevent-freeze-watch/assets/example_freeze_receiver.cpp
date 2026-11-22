// example_freeze_receiver.cpp
// 完整的冻屏事件订阅示例（onReceive实时接收模式）

#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"

#undef LOG_TAG
#define LOG_TAG "FreezeEventReceiver"

// 缓存观察者指针
static HiAppEvent_Watcher *freezeReceiverWatcher = nullptr;

// 定义冻屏事件参数结构
struct FreezeEventParams {
    int64_t time;
    bool foreground;
    std::string appRunningUniqueId;
    std::string bundleVersion;
    std::string bundleName;
    std::string processName;
    int32_t pid;
    int32_t uid;
    std::string uuid;
    std::string exceptionType;
    std::string exceptionMessage;
    int32_t hilogSize;
    int32_t handlerSize;
    std::string handlerSize3s;
    std::string handlerSize6s;
    int32_t peerBinderSize;
    int32_t threadsSize;
    std::string memoryInfo;
    std::string externalLog;
    bool logOverLimit;
    std::string externalCallbackLog;
};

// 解析冻屏事件参数
static FreezeEventParams ParseFreezeParams(const Json::Value& params) {
    FreezeEventParams result;
    
    try {
        result.time = params["time"].asInt64();
        result.foreground = params["foreground"].asBool();
        result.appRunningUniqueId = params["app_running_unique_id"].asString();
        result.bundleVersion = params["bundle_version"].asString();
        result.bundleName = params["bundle_name"].asString();
        result.processName = params["process_name"].asString();
        result.pid = params["pid"].asInt();
        result.uid = params["uid"].asInt();
        result.uuid = params["uuid"].asString();
        
        // 解析异常信息
        Json::FastWriter writer;
        result.exceptionType = params["exception"]["name"].asString();
        result.exceptionMessage = params["exception"]["message"].asString();
        
        // 解析日志和线程信息
        result.hilogSize = params["hilog"].size();
        result.handlerSize = params["event_handler"].size();
        result.handlerSize3s = params["event_handler_size_3s"].asString();
        result.handlerSize6s = params["event_handler_size_6s"].asString();
        result.peerBinderSize = params["peer_binder"].size();
        result.threadsSize = params["threads"].size();
        
        // 解析内存和日志文件
        result.memoryInfo = writer.write(params["memory"]);
        result.externalLog = writer.write(params["external_log"]);
        result.logOverLimit = params["log_over_limit"].asBool();
        result.externalCallbackLog = params["external_callback_log"].asString();
        
    } catch (const std::exception& e) {
        OH_LOG_ERROR(LogType::LOG_APP, "Parse params failed: %{public}s", e.what());
    }
    
    return result;
}

// 处理冻屏事件
static void ProcessFreezeEvent(const FreezeEventParams& params) {
    OH_LOG_INFO(LogType::LOG_APP, "========================================");
    OH_LOG_INFO(LogType::LOG_APP, "Application Freeze Event Detected");
    OH_LOG_INFO(LogType::LOG_APP, "========================================");
    OH_LOG_INFO(LogType::LOG_APP, "Time: %{public}lld", params.time);
    OH_LOG_INFO(LogType::LOG_APP, "Foreground: %{public}d", params.foreground);
    OH_LOG_INFO(LogType::LOG_APP, "Process: %{public}s (PID: %{public}d, UID: %{public}d)", 
                params.processName.c_str(), params.pid, params.uid);
    OH_LOG_INFO(LogType::LOG_APP, "Bundle: %{public}s v%{public}s", 
                params.bundleName.c_str(), params.bundleVersion.c_str());
    OH_LOG_INFO(LogType::LOG_APP, "UUID: %{public}s", params.uuid.c_str());
    OH_LOG_INFO(LogType::LOG_APP, "Exception Type: %{public}s", params.exceptionType.c_str());
    OH_LOG_INFO(LogType::LOG_APP, "Exception Message: %{public}s", params.exceptionMessage.c_str());
    OH_LOG_INFO(LogType::LOG_APP, "Hilog Entries: %{public}d", params.hilogSize);
    OH_LOG_INFO(LogType::LOG_APP, "Event Handler Size: %{public}d (3s: %{public}s, 6s: %{public}s)", 
                params.handlerSize, params.handlerSize3s.c_str(), params.handlerSize6s.c_str());
    OH_LOG_INFO(LogType::LOG_APP, "Peer Binder Size: %{public}d", params.peerBinderSize);
    OH_LOG_INFO(LogType::LOG_APP, "Thread Count: %{public}d", params.threadsSize);
    OH_LOG_INFO(LogType::LOG_APP, "Memory Info: %{public}s", params.memoryInfo.c_str());
    OH_LOG_INFO(LogType::LOG_APP, "External Log: %{public}s", params.externalLog.c_str());
    OH_LOG_INFO(LogType::LOG_APP, "Log Over Limit: %{public}d", params.logOverLimit);
    OH_LOG_INFO(LogType::LOG_APP, "Callback Log: %{public}s", params.externalCallbackLog.c_str());
    OH_LOG_INFO(LogType::LOG_APP, "========================================");
}

// OnReceive回调函数（实时接收冻屏事件）
static void OnReceive(const char *domain, const struct HiAppEvent_AppEventGroup *appEventGroups, uint32_t groupLen) {
    for (uint32_t i = 0; i < groupLen; ++i) {
        for (uint32_t j = 0; j < appEventGroups[i].infoLen; ++j) {
            // 打印事件基本信息
            OH_LOG_INFO(LogType::LOG_APP, "Received event: domain=%{public}s, name=%{public}s, type=%{public}d",
                        appEventGroups[i].appEventInfos[j].domain,
                        appEventGroups[i].appEventInfos[j].name,
                        appEventGroups[i].appEventInfos[j].type);
            
            // 检查是否为冻屏事件
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) == 0 &&
                strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_APP_FREEZE) == 0) {
                
                // 解析事件参数JSON字符串
                Json::Value params;
                Json::Reader reader(Json::Features::strictMode());
                
                if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
                    FreezeEventParams freezeParams = ParseFreezeParams(params);
                    ProcessFreezeEvent(freezeParams);
                } else {
                    OH_LOG_ERROR(LogType::LOG_APP, "Failed to parse freeze event params JSON");
                    OH_LOG_WARN(LogType::LOG_APP, "Raw params: %{public}s", appEventGroups[i].appEventInfos[j].params);
                }
            }
        }
    }
}

// 注册冻屏事件观察者
static napi_value RegisterFreezeWatcher(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LogType::LOG_APP, "Registering freeze event watcher...");
    
    // 步骤1：创建观察者
    freezeReceiverWatcher = OH_HiAppEvent_CreateWatcher("freezeReceiverWatcher");
    if (freezeReceiverWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher - name may be invalid or memory exhausted");
        return {};
    }
    OH_LOG_INFO(LogType::LOG_APP, "Watcher created successfully");
    
    // 步骤2：设置事件过滤器（订阅冻屏事件）
    const char *names[] = {EVENT_APP_FREEZE};
    int result = OH_HiAppEvent_SetAppEventFilter(freezeReceiverWatcher, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set event filter, error code: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(freezeReceiverWatcher);
        freezeReceiverWatcher = nullptr;
        return {};
    }
    OH_LOG_INFO(LogType::LOG_APP, "Event filter set: domain=DOMAIN_OS, event=EVENT_APP_FREEZE");
    
    // 步骤3：设置OnReceive回调（实时接收）
    result = OH_HiAppEvent_SetWatcherOnReceive(freezeReceiverWatcher, OnReceive);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set onReceive callback, error code: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(freezeReceiverWatcher);
        freezeReceiverWatcher = nullptr;
        return {};
    }
    OH_LOG_INFO(LogType::LOG_APP, "OnReceive callback set successfully");
    
    // 步骤4：添加观察者（开始监听）
    result = OH_HiAppEvent_AddWatcher(freezeReceiverWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher, error code: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(freezeReceiverWatcher);
        freezeReceiverWatcher = nullptr;
        return {};
    }
    OH_LOG_INFO(LogType::LOG_APP, "Watcher added - now listening for freeze events");
    
    return {};
}

// 移除冻屏事件观察者
static napi_value RemoveFreezeWatcher(napi_env env, napi_callback_info info) {
    if (freezeReceiverWatcher != nullptr) {
        int result = OH_HiAppEvent_RemoveWatcher(freezeReceiverWatcher);
        if (result == 0) {
            OH_LOG_INFO(LogType::LOG_APP, "Watcher removed - stopped listening");
        } else {
            OH_LOG_ERROR(LogType::LOG_APP, "Remove watcher failed, error code: %{public}d", result);
        }
    } else {
        OH_LOG_WARN(LogType::LOG_APP, "Watcher not created, skip remove");
    }
    return {};
}

// 销毁冻屏事件观察者
static napi_value DestroyFreezeWatcher(napi_env env, napi_callback_info info) {
    if (freezeReceiverWatcher != nullptr) {
        OH_HiAppEvent_DestroyWatcher(freezeReceiverWatcher);
        freezeReceiverWatcher = nullptr;
        OH_LOG_INFO(LogType::LOG_APP, "Watcher destroyed and memory released");
    } else {
        OH_LOG_WARN(LogType::LOG_APP, "Watcher not created, skip destroy");
    }
    return {};
}

// 注册接口到ArkTS
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "registerFreezeWatcher", nullptr, RegisterFreezeWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removeFreezeWatcher", nullptr, RemoveFreezeWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "destroyFreezeWatcher", nullptr, DestroyFreezeWatcher, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

// NAPI模块定义
extern "C" __attribute__((visibility("default"))) napi_module napi_module_info = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_modname = "entry",
    .nm_priv = reinterpret_cast<void*>(Init),
    .reserved = { 0 },
};