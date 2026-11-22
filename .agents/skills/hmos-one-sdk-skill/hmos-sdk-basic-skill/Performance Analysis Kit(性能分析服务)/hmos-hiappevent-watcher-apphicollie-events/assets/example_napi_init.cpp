#include "napi/native_api.h"
#include "hicollie/hicollie.h"
#include "hilog/log.h"
#include <unistd.h>

#undef LOG_TAG
#define LOG_TAG "HiCollieTest"

static napi_value TriggerTimeoutEvent(napi_env env, napi_callback_info exports)
{
    int timerId;
    
    HiCollie_SetTimerParam timerParam = {
        "testTimeout",
        1,
        nullptr,
        nullptr,
        HiCollie_Flag::HICOLLIE_FLAG_LOG
    };
    
    HiCollie_ErrorCode errorCode = OH_HiCollie_SetTimer(timerParam, &timerId);
    
    if (errorCode == HICOLLIE_SUCCESS) {
        OH_LOG_INFO(LogType::LOG_APP, "Timer created successfully, ID: %{public}d", timerId);
        
        sleep(2);
        
        OH_HiCollie_CancelTimer(timerId);
        OH_LOG_INFO(LogType::LOG_APP, "Timer cancelled");
    } else {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create timer, error code: %{public}d", errorCode);
    }
    
    return nullptr;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "TriggerTimeoutEvent", nullptr, TriggerTimeoutEvent, nullptr, nullptr, nullptr, napi_default, nullptr }
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

extern "C" __attribute__((constructor)) void RegisterEntryModule(void)
{
    napi_module_register(&demoModule);
}