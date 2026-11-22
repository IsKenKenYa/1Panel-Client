/**
 * @file example_napi_init.cpp
 * @brief NAPI接口定义示例:完整事件订阅功能
 */

#include "napi/native_api.h"
#include "../../../build/jsoncpp-1.9.6/include/json/json.h"
#include "hiappevent/hiappevent.h"
#include "hilog/log.h"
#include <cstring>
#include <cstdlib>
#include <ctime>

#undef LOG_TAG
#define LOG_TAG "HiAppEventNAPI"

// ==================== 观察者管理 ====================

static HiAppEvent_Watcher* crashWatcher = nullptr;
static HiAppEvent_Watcher* clickWatcher = nullptr;

// ==================== 回调函数定义 ====================

static void OnCrashReceive(const char* domain, 
                           const struct HiAppEvent_AppEventGroup* appEventGroups, 
                           uint32_t groupLen) {
    for (uint32_t i = 0; i < groupLen; ++i) {
        for (uint32_t j = 0; j < appEventGroups[i].infoLen; ++j) {
            char* paramsCopy = strdup(appEventGroups[i].appEventInfos[j].params);
            Json::Value params;
            Json::Reader reader;
            
            if (reader.parse(paramsCopy, params)) {
                OH_LOG_INFO(LogType::LOG_APP, 
                           "Crash event: time=%lld, bundle=%s",
                           params["time"].asInt64(),
                           params["bundle_name"].asString().c_str());
            }
            free(paramsCopy);
        }
    }
}

static void OnClickTrigger(int row, int size) {
    OH_LOG_INFO(LogType::LOG_APP, "Click triggered: row=%d, size=%d", row, size);
    OH_HiAppEvent_TakeWatcherData(clickWatcher, row, [](const char* const* events, uint32_t len) {
        for (uint32_t i = 0; i < len; ++i) {
            char* eventCopy = strdup(events[i]);
            Json::Value eventInfo;
            Json::Reader reader;
            
            if (reader.parse(eventCopy, eventInfo)) {
                OH_LOG_INFO(LogType::LOG_APP, 
                           "Click event: domain=%s, name=%s, clickTime=%lld",
                           eventInfo["domain_"].asString().c_str(),
                           eventInfo["name_"].asString().c_str(),
                           eventInfo["clickTime"].asInt64());
            }
            free(eventCopy);
        }
    });
}

// ==================== NAPI接口实现 ====================

/**
 * 注册崩溃事件观察者
 */
static napi_value RegisterCrashWatcher(napi_env env, napi_callback_info info) {
    crashWatcher = OH_HiAppEvent_CreateWatcher("AppCrashWatcher");
    if (!crashWatcher) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create crash watcher");
        return nullptr;
    }
    
    const char* names[] = {EVENT_APP_CRASH};
    OH_HiAppEvent_SetAppEventFilter(crashWatcher, DOMAIN_OS, 0, names, 1);
    OH_HiAppEvent_SetWatcherOnReceive(crashWatcher, OnCrashReceive);
    OH_HiAppEvent_AddWatcher(crashWatcher);
    
    OH_LOG_INFO(LogType::LOG_APP, "Crash watcher registered");
    return nullptr;
}

/**
 * 注册按钮点击观察者
 */
static napi_value RegisterClickWatcher(napi_env env, napi_callback_info info) {
    clickWatcher = OH_HiAppEvent_CreateWatcher("ButtonClickWatcher");
    if (!clickWatcher) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create click watcher");
        return nullptr;
    }
    
    const char* names[] = {"click"};
    OH_HiAppEvent_SetAppEventFilter(clickWatcher, "button", 0, names, 1);
    OH_HiAppEvent_SetWatcherOnTrigger(clickWatcher, OnClickTrigger);
    OH_HiAppEvent_SetTriggerCondition(clickWatcher, 1, 0, 0);
    OH_HiAppEvent_AddWatcher(clickWatcher);
    
    OH_LOG_INFO(LogType::LOG_APP, "Click watcher registered");
    return nullptr;
}

/**
 * 写入按钮点击事件
 */
static napi_value WriteClickEvent(napi_env env, napi_callback_info info) {
    ParamList params = OH_HiAppEvent_CreateParamList();
    OH_HiAppEvent_AddInt64Param(params, "clickTime", time(nullptr));
    
    int result = OH_HiAppEvent_Write("button", "click", EventType::BEHAVIOR, params);
    if (result < 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to write click event: %d", result);
    } else {
        OH_LOG_INFO(LogType::LOG_APP, "Click event written successfully");
    }
    
    OH_HiAppEvent_DestroyParamList(params);
    return nullptr;
}

/**
 * 移除所有观察者
 */
static napi_value RemoveAllWatchers(napi_env env, napi_callback_info info) {
    if (crashWatcher) {
        OH_HiAppEvent_RemoveWatcher(crashWatcher);
        OH_LOG_INFO(LogType::LOG_APP, "Crash watcher removed");
    }
    
    if (clickWatcher) {
        OH_HiAppEvent_RemoveWatcher(clickWatcher);
        OH_LOG_INFO(LogType::LOG_APP, "Click watcher removed");
    }
    
    return nullptr;
}

/**
 * 销毁所有观察者
 */
static napi_value DestroyAllWatchers(napi_env env, napi_callback_info info) {
    if (crashWatcher) {
        OH_HiAppEvent_RemoveWatcher(crashWatcher);
        OH_HiAppEvent_DestroyWatcher(crashWatcher);
        crashWatcher = nullptr;
        OH_LOG_INFO(LogType::LOG_APP, "Crash watcher destroyed");
    }
    
    if (clickWatcher) {
        OH_HiAppEvent_RemoveWatcher(clickWatcher);
        OH_HiAppEvent_DestroyWatcher(clickWatcher);
        clickWatcher = nullptr;
        OH_LOG_INFO(LogType::LOG_APP, "Click watcher destroyed");
    }
    
    return nullptr;
}

/**
 * 清除所有观察者数据
 */
static napi_value ClearAllData(napi_env env, napi_callback_info info) {
    OH_HiAppEvent_ClearData();
    OH_LOG_INFO(LogType::LOG_APP, "All watcher data cleared");
    return nullptr;
}

// ==================== 模块初始化 ====================

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "registerCrashWatcher", nullptr, RegisterCrashWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "registerClickWatcher", nullptr, RegisterClickWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "writeClickEvent", nullptr, WriteClickEvent, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removeAllWatchers", nullptr, RemoveAllWatchers, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "destroyAllWatchers", nullptr, DestroyAllWatchers, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "clearAllData", nullptr, ClearAllData, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "entry",
    .nm_priv = ((void*)0),
    .reserved = { 0 },
};

extern napi_module* NAPI_GetModuleName(void) {
    return &demoModule;
}