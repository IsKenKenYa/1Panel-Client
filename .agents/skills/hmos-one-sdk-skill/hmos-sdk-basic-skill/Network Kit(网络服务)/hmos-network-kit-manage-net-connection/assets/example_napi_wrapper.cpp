/**
 * @file example_napi_wrapper.cpp
 * @brief NAPI wrapper example for exposing NetConnection APIs to ArkTS
 * 
 * This example demonstrates how to wrap NetConnection C APIs using NAPI
 * so they can be called from ArkTS/JavaScript code.
 * 
 * @requirements:
 * - HarmonyOS API 11+
 * - NAPI knowledge
 * - Permission: ohos.permission.GET_NETWORK_INFO
 */

#include "napi/native_api.h"
#include "network/netmanager/net_connection.h"
#include "network/netmanager/net_connection_type.h"
#include <stdio.h>
#include <string.h>

enum ReturnCode {
    SUCCESS = 0,
    MISSING_PERMISSION = 201,
    PARAMETER_ERROR = 401,
    SERVICE_UNAVAILABLE = 2100002,
    INTERNAL_ERROR = 2100003
};

static napi_value HasDefaultNet(napi_env env, napi_callback_info info) {
    int32_t hasDefaultNet = 0;
    int32_t result = OH_NetConn_HasDefaultNet(&hasDefaultNet);
    
    napi_value return_value;
    napi_create_int32(env, result == 0 ? hasDefaultNet : -1, &return_value);
    return return_value;
}

static napi_value GetDefaultNet(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    int32_t param = 1;
    if (argc > 0) {
        napi_get_value_int32(env, args[0], &param);
    }
    
    NetConn_NetHandle netHandle;
    memset(&netHandle, 0, sizeof(NetConn_NetHandle));
    
    int32_t result;
    if (param == 0) {
        result = OH_NetConn_GetDefaultNet(NULL);
    } else {
        result = OH_NetConn_GetDefaultNet(&netHandle);
    }
    
    napi_value return_value;
    napi_create_int32(env, result, &return_value);
    return return_value;
}

static napi_value GetNetId(napi_env env, napi_callback_info info) {
    NetConn_NetHandle netHandle;
    memset(&netHandle, 0, sizeof(NetConn_NetHandle));
    
    int32_t result = OH_NetConn_GetDefaultNet(&netHandle);
    
    napi_value return_value;
    if (result == 0) {
        napi_create_int32(env, netHandle.netId, &return_value);
    } else {
        napi_create_int32(env, -1, &return_value);
    }
    return return_value;
}

static napi_value IsMetered(napi_env env, napi_callback_info info) {
    int32_t isMetered = 0;
    int32_t result = OH_NetConn_IsDefaultNetMetered(&isMetered);
    
    napi_value return_value;
    napi_create_int32(env, result == 0 ? isMetered : -1, &return_value);
    return return_value;
}

static napi_value GetAllNetsCount(napi_env env, napi_callback_info info) {
    NetConn_NetHandleList netHandleList;
    memset(&netHandleList, 0, sizeof(NetConn_NetHandleList));
    
    int32_t result = OH_NetConn_GetAllNets(&netHandleList);
    
    napi_value return_value;
    if (result == 0) {
        napi_create_int32(env, netHandleList.netHandleListSize, &return_value);
    } else {
        napi_create_int32(env, -1, &return_value);
    }
    return return_value;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        {"HasDefaultNet", nullptr, HasDefaultNet, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"GetDefaultNet", nullptr, GetDefaultNet, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"GetNetId", nullptr, GetNetId, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"IsMetered", nullptr, IsMetered, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"GetAllNetsCount", nullptr, GetAllNetsCount, nullptr, nullptr, nullptr, napi_default, nullptr},
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

extern "C" __attribute__((constructor)) void RegisterEntryModule(void) { 
    napi_module_register(&demoModule); 
}