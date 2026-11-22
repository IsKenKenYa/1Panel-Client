/**
 * HiAppEvent订阅任务执行超时事件完整示例代码
 * 
 * 本示例演示如何:
 * 1. 使用HiAppEvent观察者订阅APP_HICOLLIE系统事件
 * 2. 实现onReceive和onTrigger两种事件接收模式
 * 3. 使用HiCollie定时器检测任务执行超时
 * 4. 解析和处理超时事件的详细参数
 * 5. 注册Native C++接口供ArkTS调用
 */

#include "napi/native_api.h"
#include "../../../build/jsoncpp-1.9.6/include/json/json.h"
#include "hiappevent/hiappevent.h"
#include "hilog/log.h"
#include <unistd.h>
#include "hicollie/hicollie.h"
#include <string.h>

#undef LOG_TAG
#define LOG_TAG "HiAppEventDemo"

// 定义观察者指针缓存变量
static HiAppEvent_Watcher *appHicollieWatcherR = nullptr;  // onReceive类型观察者
static HiAppEvent_Watcher *appHicollieWatcherT = nullptr;  // onTrigger类型观察者

/**
 * 处理APP_HICOLLIE事件的详细参数
 * 从事件参数中提取并打印所有关键信息
 */
static void OnReceiveAppHicollie(const struct HiAppEvent_AppEventGroup *appEventGroups, int i, int j)
{
    // 校验事件domain和name
    if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) == 0 &&
        strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_APP_HICOLLIE) == 0) {
        
        Json::Value params;
        Json::Reader reader(Json::Features::strictMode());
        Json::FastWriter writer;
        
        // 解析JSON参数字符串
        if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
            // 提取事件参数
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
            
            // 打印事件信息到日志
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld", time);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.foreground=%{public}d", foreground);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_version=%{public}s",
                bundleVersion.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.process_name=%{public}s", 
                processName.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.pid=%{public}d", pid);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.uid=%{public}d", uid);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.uuid=%{public}s", uuid.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.exception=%{public}s", exception.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.hilog.size=%{public}d", hilogSize);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.peer_binder.size=%{public}d", peerBindSize);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.memory=%{public}s", memory.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.external_log=%{public}s", 
                externalLog.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.log_over_limit=%{public}d", logOverLimit);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.external_callback_log=%{public}s", 
                externalCallbackLog.c_str());
        } else {
            OH_LOG_ERROR(LogType::LOG_APP, "Failed to parse params JSON");
        }
    }
}

/**
 * onReceive回调函数
 * 监听器接收到事件后立即触发该回调
 * 注意:回调中的指针生命周期仅限该回调函数内
 */
static void AppHicollieOnReceive(const char *domain, 
    const struct HiAppEvent_AppEventGroup *appEventGroups, uint32_t groupLen)
{
    OH_LOG_INFO(LogType::LOG_APP, "AppHicollieOnReceive triggered, groupLen=%{public}d", groupLen);
    
    for (uint32_t i = 0; i < groupLen; ++i) {
        for (uint32_t j = 0; j < appEventGroups[i].infoLen; ++j) {
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s",
                appEventGroups[i].appEventInfos[j].domain);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s",
                appEventGroups[i].appEventInfos[j].name);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d",
                appEventGroups[i].appEventInfos[j].type);
            
            // 处理具体事件参数
            OnReceiveAppHicollie(appEventGroups, i, j);
        }
    }
}

/**
 * 注册onReceive类型观察者
 * 实时接收事件,事件发生后立即触发回调
 */
static napi_value RegisterAppHicollieWatcherR(napi_env env, napi_callback_info info)
{
    OH_LOG_INFO(LogType::LOG_APP, "RegisterAppHicollieWatcherR start");
    
    // 创建观察者
    appHicollieWatcherR = OH_HiAppEvent_CreateWatcher("appHicollieWatcherR");
    if (appHicollieWatcherR == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Create watcher failed");
        return {};
    }
    
    // 设置事件过滤规则:订阅DOMAIN_OS领域的APP_HICOLLIE事件
    const char *names[] = {EVENT_APP_HICOLLIE};
    int result = OH_HiAppEvent_SetAppEventFilter(appHicollieWatcherR, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Set filter failed: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(appHicollieWatcherR);
        appHicollieWatcherR = nullptr;
        return {};
    }
    
    // 设置onReceive回调函数
    result = OH_HiAppEvent_SetWatcherOnReceive(appHicollieWatcherR, AppHicollieOnReceive);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Set onReceive failed: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(appHicollieWatcherR);
        appHicollieWatcherR = nullptr;
        return {};
    }
    
    // 添加观察者开始监听事件
    result = OH_HiAppEvent_AddWatcher(appHicollieWatcherR);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Add watcher failed: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(appHicollieWatcherR);
        appHicollieWatcherR = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Register onReceive watcher success");
    return {};
}

/**
 * OnTake回调函数
 * 获取已保存的事件数据
 * 注意:回调中的指针生命周期仅限该回调函数内
 */
static void AppHicollieOnTake(const char* const *events, uint32_t eventLen)
{
    OH_LOG_INFO(LogType::LOG_APP, "AppHicollieOnTake triggered, eventLen=%{public}d", eventLen);
    
    Json::Reader reader(Json::Features::strictMode());
    Json::FastWriter writer;
    
    for (uint32_t i = 0; i < eventLen; ++i) {
        Json::Value eventInfo;
        if (reader.parse(events[i], eventInfo)) {
            auto domain = eventInfo["domain_"].asString();
            auto name = eventInfo["name_"].asString();
            auto type = eventInfo["type_"].asInt();
            
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", domain.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", name.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d", type);
            
            if (domain == DOMAIN_OS && name == EVENT_APP_HICOLLIE) {
                auto time = eventInfo["time"].asInt64();
                auto foreground = eventInfo["foreground"].asBool();
                auto bundleVersion = eventInfo["bundle_version"].asString();
                auto processName = eventInfo["process_name"].asString();
                auto pid = eventInfo["pid"].asInt();
                auto uid = eventInfo["uid"].asInt();
                auto uuid = eventInfo["uuid"].asString();
                auto exception = writer.write(eventInfo["exception"]);
                auto hilogSize = eventInfo["hilog"].size();
                auto peerBindSize = eventInfo["peer_binder"].size();
                auto memory = writer.write(eventInfo["memory"]);
                auto externalLog = writer.write(eventInfo["external_log"]);
                auto logOverLimit = eventInfo["log_over_limit"].asBool();
                auto externalCallbackLog = eventInfo["external_callback_log"].asString();
                
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld", time);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.foreground=%{public}d", foreground);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_version=%{public}s",
                    bundleVersion.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.process_name=%{public}s", 
                    processName.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.pid=%{public}d", pid);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.uid=%{public}d", uid);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.uuid=%{public}s", uuid.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.exception=%{public}s", 
                    exception.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.hilog.size=%{public}d", hilogSize);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.peer_binder.size=%{public}d", 
                    peerBindSize);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.memory=%{public}s", memory.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.external_log=%{public}s", 
                    externalLog.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.log_over_limit=%{public}d", 
                    logOverLimit);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.external_callback_log=%{public}s", 
                    externalCallbackLog.c_str());
            }
        } else {
            OH_LOG_ERROR(LogType::LOG_APP, "Failed to parse event JSON");
        }
    }
}

/**
 * OnTrigger回调函数
 * 当保存的事件满足触发条件后批量处理
 */
static void AppHicollieOnTrigger(int row, int size)
{
    OH_LOG_INFO(LogType::LOG_APP, "AppHicollieOnTrigger triggered, row=%{public}d, size=%{public}d", 
        row, size);
    
    // 获取已保存的事件数据
    OH_HiAppEvent_TakeWatcherData(appHicollieWatcherT, row, AppHicollieOnTake);
}

/**
 * 注册onTrigger类型观察者
 * 缓存事件,满足触发条件后批量处理
 */
static napi_value RegisterAppHicollieWatcherT(napi_env env, napi_callback_info info)
{
    OH_LOG_INFO(LogType::LOG_APP, "RegisterAppHicollieWatcherT start");
    
    // 创建观察者
    appHicollieWatcherT = OH_HiAppEvent_CreateWatcher("appHicollieWatcherT");
    if (appHicollieWatcherT == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Create watcher failed");
        return {};
    }
    
    // 设置事件过滤规则
    const char *names[] = {EVENT_APP_HICOLLIE};
    int result = OH_HiAppEvent_SetAppEventFilter(appHicollieWatcherT, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Set filter failed: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(appHicollieWatcherT);
        appHicollieWatcherT = nullptr;
        return {};
    }
    
    // 设置onTrigger回调函数
    result = OH_HiAppEvent_SetWatcherOnTrigger(appHicollieWatcherT, AppHicollieOnTrigger);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Set onTrigger failed: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(appHicollieWatcherT);
        appHicollieWatcherT = nullptr;
        return {};
    }
    
    // 设置触发条件:新增1个事件时触发回调
    result = OH_HiAppEvent_SetTriggerCondition(appHicollieWatcherT, 1, 0, 0);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Set trigger condition failed: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(appHicollieWatcherT);
        appHicollieWatcherT = nullptr;
        return {};
    }
    
    // 添加观察者开始监听事件
    result = OH_HiAppEvent_AddWatcher(appHicollieWatcherT);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Add watcher failed: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(appHicollieWatcherT);
        appHicollieWatcherT = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Register onTrigger watcher success");
    return {};
}

/**
 * HiCollie超时回调函数
 * 当任务执行超过设定时间阈值时执行
 */
void HiCollieCallBack(void*)
{
    OH_LOG_INFO(LogType::LOG_APP, "HiCollieTimerNdk CallBack triggered");
}

/**
 * 测试HiCollie定时器
 * 模拟任务执行超时场景
 */
static napi_value TestHiCollieTimerNdk(napi_env env, napi_callback_info info)
{
    OH_LOG_INFO(LogType::LOG_APP, "TestHiCollieTimerNdk start");
    
    int id = 0;
    
    // 设置HiCollie定时器参数
    HiCollie_SetTimerParam param = {
        "testTimer",                    // timer任务名称
        1,                              // 超时时间阈值(秒)
        HiCollieCallBack,               // 超时回调函数
        nullptr,                        // 回调函数参数
        HiCollie_Flag::HICOLLIE_FLAG_LOG  // 超时动作:生成日志
    };
    
    // 注册定时器检测任务执行超时
    HiCollie_ErrorCode errorCode = OH_HiCollie_SetTimer(param, &id);
    
    if (errorCode == HICOLLIE_SUCCESS) {
        OH_LOG_INFO(LogType::LOG_APP, "HiCollieTimer registered, taskId=%{public}d", id);
        
        // 模拟执行耗时函数:阻塞2秒(超过1秒阈值)
        sleep(2);
        
        // 取消定时器(已超时,会触发回调并生成APP_HICOLLIE事件)
        OH_HiCollie_CancelTimer(id);
        
        OH_LOG_INFO(LogType::LOG_APP, "HiCollieTimer canceled");
    } else {
        OH_LOG_ERROR(LogType::LOG_APP, "HiCollie SetTimer failed, errorCode=%{public}d", errorCode);
    }
    
    return nullptr;
}

/**
 * 移除观察者
 * 使观察者停止监听系统消息
 */
static napi_value RemoveWatcher(napi_env env, napi_callback_info info)
{
    OH_LOG_INFO(LogType::LOG_APP, "RemoveWatcher start");
    
    if (appHicollieWatcherR != nullptr) {
        OH_HiAppEvent_RemoveWatcher(appHicollieWatcherR);
        OH_LOG_INFO(LogType::LOG_APP, "Remove watcherR success");
    }
    
    if (appHicollieWatcherT != nullptr) {
        OH_HiAppEvent_RemoveWatcher(appHicollieWatcherT);
        OH_LOG_INFO(LogType::LOG_APP, "Remove watcherT success");
    }
    
    return {};
}

/**
 * 销毁观察者
 * 释放观察者内存,防止内存泄漏
 */
static napi_value DestroyWatcher(napi_env env, napi_callback_info info)
{
    OH_LOG_INFO(LogType::LOG_APP, "DestroyWatcher start");
    
    if (appHicollieWatcherR != nullptr) {
        OH_HiAppEvent_DestroyWatcher(appHicollieWatcherR);
        appHicollieWatcherR = nullptr;
        OH_LOG_INFO(LogType::LOG_APP, "Destroy watcherR success");
    }
    
    if (appHicollieWatcherT != nullptr) {
        OH_HiAppEvent_DestroyWatcher(appHicollieWatcherT);
        appHicollieWatcherT = nullptr;
        OH_LOG_INFO(LogType::LOG_APP, "Destroy watcherT success");
    }
    
    return {};
}

/**
 * 模块初始化
 * 注册所有ArkTS接口
 */
EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "TestHiCollieTimerNdk", nullptr, TestHiCollieTimerNdk, nullptr, nullptr, nullptr, 
          napi_default, nullptr },
        { "RegisterAppHicollieWatcherR", nullptr, RegisterAppHicollieWatcherR, nullptr, nullptr, nullptr, 
          napi_default, nullptr },
        { "RegisterAppHicollieWatcherT", nullptr, RegisterAppHicollieWatcherT, nullptr, nullptr, nullptr, 
          napi_default, nullptr },
        { "RemoveWatcher", nullptr, RemoveWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "DestroyWatcher", nullptr, DestroyWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module module = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "entry",
    .nm_priv = ((void*)0),
    .reserved = { 0 },
};

extern __attribute__((constructor)) void RegisterModule(void)
{
    napi_module_register(&module);
}