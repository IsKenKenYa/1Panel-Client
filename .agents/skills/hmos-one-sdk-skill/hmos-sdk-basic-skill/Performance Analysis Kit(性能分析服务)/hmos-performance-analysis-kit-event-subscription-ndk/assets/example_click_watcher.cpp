/**
 * @file example_click_watcher.cpp
 * @brief 完整示例:订阅按钮点击事件(C/C++)
 * 
 * 本示例演示如何使用HiAppEvent C API订阅应用自定义事件(button click)
 */

#include "napi/native_api.h"
#include "../../../build/jsoncpp-1.9.6/include/json/json.h"
#include "hiappevent/hiappevent.h"
#include "hilog/log.h"
#include <cstring>
#include <cstdlib>
#include <ctime>

#undef LOG_TAG
#define LOG_TAG "ClickWatcher"

// 定义全局观察者指针
static HiAppEvent_Watcher* clickWatcher = nullptr;

/**
 * OnTake回调函数:用于获取保存的事件数据
 * 
 * @param events JSON格式的事件数组
 * @param eventLen 事件数量
 */
static void OnClickTake(const char* const* events, uint32_t eventLen) {
    OH_LOG_INFO(LogType::LOG_APP, "Taking %{public}u click events", eventLen);
    
    Json::Reader reader(Json::Features::strictMode());
    
    for (uint32_t i = 0; i < eventLen; ++i) {
        // 深拷贝事件JSON字符串
        char* eventCopy = strdup(events[i]);
        
        Json::Value eventInfo;
        if (reader.parse(eventCopy, eventInfo)) {
            // 解析事件信息
            std::string domain = eventInfo["domain_"].asString();
            std::string name = eventInfo["name_"].asString();
            int type = eventInfo["type_"].asInt();
            
            OH_LOG_INFO(LogType::LOG_APP, 
                       "Event: domain=%{public}s, name=%{public}s, type=%{public}d",
                       domain.c_str(), name.c_str(), type);
            
            // 检查是否为按钮点击事件
            if (domain == "button" && name == "click") {
                // 获取点击时间戳
                int64_t clickTime = eventInfo["clickTime"].asInt64();
                OH_LOG_INFO(LogType::LOG_APP, "Click time: %{public}lld", clickTime);
                
                // 处理点击事件(可添加自定义逻辑)
                ProcessClickEvent(clickTime);
            }
        }
        
        // 释放深拷贝的内存
        free(eventCopy);
    }
}

/**
 * OnTrigger回调函数:条件触发模式
 * 当满足触发条件(新增事件数量>=1)时触发
 * 
 * @param row 新接收事件数量
 * @param size 新接收事件总大小
 */
static void OnClickTrigger(int row, int size) {
    OH_LOG_INFO(LogType::LOG_APP, 
               "Triggered with row=%{public}d, size=%{public}d", row, size);
    
    // 获取指定数量的已保存事件
    OH_HiAppEvent_TakeWatcherData(clickWatcher, row, OnClickTake);
}

/**
 * 处理点击事件的业务逻辑
 * 
 * @param clickTime 点击时间戳
 */
static void ProcessClickEvent(int64_t clickTime) {
    OH_LOG_INFO(LogType::LOG_APP, "Processing click event at %{public}lld", clickTime);
    
    // 可添加自定义点击处理逻辑:
    // 1. 统计按钮点击次数
    // 2. 分析用户行为模式
    // 3. 上报点击数据到服务器
    // 4. 记录点击日志到本地文件
}

/**
 * 注册按钮点击事件观察者
 */
static napi_value RegisterClickWatcher(napi_env env, napi_callback_info info) {
    // 创建观察者
    clickWatcher = OH_HiAppEvent_CreateWatcher("ButtonClickWatcher");
    if (clickWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create click watcher");
        return nullptr;
    }
    
    // 设置事件过滤:订阅按钮点击事件
    const char* names[] = {"click"};
    int result = OH_HiAppEvent_SetAppEventFilter(clickWatcher, "button", 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(clickWatcher);
        clickWatcher = nullptr;
        return nullptr;
    }
    
    // 设置OnTrigger回调
    result = OH_HiAppEvent_SetWatcherOnTrigger(clickWatcher, OnClickTrigger);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set OnTrigger: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(clickWatcher);
        clickWatcher = nullptr;
        return nullptr;
    }
    
    // 设置触发条件:新增1个事件触发
    result = OH_HiAppEvent_SetTriggerCondition(clickWatcher, 1, 0, 0);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set trigger condition: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(clickWatcher);
        clickWatcher = nullptr;
        return nullptr;
    }
    
    // 添加观察者开始监听
    result = OH_HiAppEvent_AddWatcher(clickWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(clickWatcher);
        clickWatcher = nullptr;
        return nullptr;
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Click watcher registered successfully");
    return nullptr;
}

/**
 * 写入按钮点击事件(事件打点)
 */
static napi_value WriteClickEvent(napi_env env, napi_callback_info info) {
    // 创建参数列表
    ParamList params = OH_HiAppEvent_CreateParamList();
    if (params == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create param list");
        return nullptr;
    }
    
    // 添加点击时间参数
    params = OH_HiAppEvent_AddInt64Param(params, "clickTime", time(nullptr));
    
    // 写入事件(事件领域="button",事件名称="click",事件类型=BEHAVIOR)
    int result = OH_HiAppEvent_Write("button", "click", EventType::BEHAVIOR, params);
    if (result < 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to write event: %{public}d", result);
    } else if (result > 0) {
        OH_LOG_WARN(LogType::LOG_APP, "Event written with invalid params: %{public}d", result);
    } else {
        OH_LOG_INFO(LogType::LOG_APP, "Click event written successfully");
    }
    
    // 销毁参数列表
    OH_HiAppEvent_DestroyParamList(params);
    
    return nullptr;
}

/**
 * 移除按钮点击事件观察者
 */
static napi_value RemoveClickWatcher(napi_env env, napi_callback_info info) {
    if (clickWatcher == nullptr) {
        OH_LOG_WARN(LogType::LOG_APP, "Click watcher is already null");
        return nullptr;
    }
    
    // 移除观察者停止监听
    int result = OH_HiAppEvent_RemoveWatcher(clickWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to remove watcher: %{public}d", result);
    } else {
        OH_LOG_INFO(LogType::LOG_APP, "Click watcher removed successfully");
    }
    
    return nullptr;
}

/**
 * 销毁按钮点击事件观察者
 */
static napi_value DestroyClickWatcher(napi_env env, napi_callback_info info) {
    if (clickWatcher == nullptr) {
        OH_LOG_WARN(LogType::LOG_APP, "Click watcher is already null");
        return nullptr;
    }
    
    // 先移除观察者
    OH_HiAppEvent_RemoveWatcher(clickWatcher);
    
    // 销毁观察者释放内存
    OH_HiAppEvent_DestroyWatcher(clickWatcher);
    clickWatcher = nullptr;
    
    OH_LOG_INFO(LogType::LOG_APP, "Click watcher destroyed successfully");
    return nullptr;
}

/**
 * 初始化模块导出
 */
EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "registerClickWatcher", nullptr, RegisterClickWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "writeClickEvent", nullptr, WriteClickEvent, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removeClickWatcher", nullptr, RemoveClickWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "destroyClickWatcher", nullptr, DestroyClickWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
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