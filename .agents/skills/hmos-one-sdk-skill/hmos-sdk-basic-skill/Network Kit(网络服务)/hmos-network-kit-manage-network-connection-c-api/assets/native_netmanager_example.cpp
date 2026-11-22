#include "napi/native_api.h"
#include "network/netmanager/net_connection.h"
#include "network/netmanager/net_connection_type.h"
#include <hilog/log.h>

#define LOG_TAG "NetManager"
#define LOG_DOMAIN 0x0000

enum ReturnCode {
    SUCCESS = 0,
    MISSING_PERMISSION = 201,
    PARAMETER_ERROR = 401,
    OPERATION_FAILED = 2100002,
    INTERNAL_ERROR = 2100003
};

static napi_value GetDefaultNet(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    int32_t param;
    napi_get_value_int32(env, args[0], &param);
    
    NetConn_NetHandle netHandle;
    int32_t result;
    
    if (param == 0) {
        result = OH_NetConn_GetDefaultNet(nullptr);
    } else {
        result = OH_NetConn_GetDefaultNet(&netHandle);
    }
    
    napi_value returnValue;
    napi_create_int32(env, result, &returnValue);
    return returnValue;
}

static napi_value NetId(napi_env env, napi_callback_info info)
{
    NetConn_NetHandle netHandle;
    int32_t result = OH_NetConn_GetDefaultNet(&netHandle);
    
    if (result != SUCCESS) {
        OH_LOG_Print(LOG_DOMAIN, LOG_ERROR, LOG_TAG, "GetDefaultNet failed: %{public}d", result);
        napi_value errorValue;
        napi_create_int32(env, result, &errorValue);
        return errorValue;
    }
    
    int32_t defaultNetId = netHandle.netId;
    OH_LOG_Print(LOG_DOMAIN, LOG_INFO, LOG_TAG, "Default netId: %{public}d", defaultNetId);
    
    napi_value netIdValue;
    napi_create_int32(env, defaultNetId, &netIdValue);
    return netIdValue;
}

static napi_value HasDefaultNet(napi_env env, napi_callback_info info)
{
    int32_t hasDefaultNet = 0;
    int32_t result = OH_NetConn_HasDefaultNet(&hasDefaultNet);
    
    if (result != SUCCESS) {
        OH_LOG_Print(LOG_DOMAIN, LOG_ERROR, LOG_TAG, "HasDefaultNet failed: %{public}d", result);
        napi_value errorValue;
        napi_create_int32(env, result, &errorValue);
        return errorValue;
    }
    
    OH_LOG_Print(LOG_DOMAIN, LOG_INFO, LOG_TAG, "HasDefaultNet: %{public}d", hasDefaultNet);
    
    napi_value hasDefaultNetValue;
    napi_create_int32(env, hasDefaultNet, &hasDefaultNetValue);
    return hasDefaultNetValue;
}

static napi_value IsDefaultNetMetered(napi_env env, napi_callback_info info)
{
    int32_t isMetered = 0;
    int32_t result = OH_NetConn_IsDefaultNetMetered(&isMetered);
    
    if (result != SUCCESS) {
        OH_LOG_Print(LOG_DOMAIN, LOG_ERROR, LOG_TAG, "IsDefaultNetMetered failed: %{public}d", result);
        napi_value errorValue;
        napi_create_int32(env, result, &errorValue);
        return errorValue;
    }
    
    OH_LOG_Print(LOG_DOMAIN, LOG_INFO, LOG_TAG, "IsMetered: %{public}d", isMetered);
    
    napi_value isMeteredValue;
    napi_create_int32(env, isMetered, &isMeteredValue);
    return isMeteredValue;
}

static napi_value GetNetCapabilities(napi_env env, napi_callback_info info)
{
    NetConn_NetHandle netHandle;
    int32_t result = OH_NetConn_GetDefaultNet(&netHandle);
    
    if (result != SUCCESS) {
        OH_LOG_Print(LOG_DOMAIN, LOG_ERROR, LOG_TAG, "GetDefaultNet failed: %{public}d", result);
        napi_value errorValue;
        napi_create_int32(env, result, &errorValue);
        return errorValue;
    }
    
    NetConn_NetCapabilities netCapabilities;
    result = OH_NetConn_GetNetCapabilities(&netHandle, &netCapabilities);
    
    if (result != SUCCESS) {
        OH_LOG_Print(LOG_DOMAIN, LOG_ERROR, LOG_TAG, "GetNetCapabilities failed: %{public}d", result);
        napi_value errorValue;
        napi_create_int32(env, result, &errorValue);
        return errorValue;
    }
    
    napi_value capabilitiesObj;
    napi_create_object(env, &capabilitiesObj);
    
    napi_value bearerTypesValue;
    napi_create_int32(env, netCapabilities.bearerTypes, &bearerTypesValue);
    napi_set_named_property(env, capabilitiesObj, "bearerTypes", bearerTypesValue);
    
    return capabilitiesObj;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        {"GetDefaultNet", nullptr, GetDefaultNet, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"NetId", nullptr, NetId, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"HasDefaultNet", nullptr, HasDefaultNet, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"IsDefaultNetMetered", nullptr, IsDefaultNetMetered, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"GetNetCapabilities", nullptr, GetNetCapabilities, nullptr, nullptr, nullptr, napi_default, nullptr},
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
    .nm_priv = ((void *)0),
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterEntryModule(void)
{
    napi_module_register(&demoModule);
}