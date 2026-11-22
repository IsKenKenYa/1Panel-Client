#include <arkui/native_interface.h>
#include <arkui/native_node_napi.h>
#include <arkui/native_node.h>
#include <arkui/native_type.h>
#include <napi/native_api.h>

// 节点 API 接口表：ArkUI_NativeNodeAPI_1（在 <arkui/native_node.h> 中按符号名检索）
// 通过 OH_ArkUI_GetModuleInterface 宏获取（在 <arkui/native_interface.h> 中按符号名检索）
// 完整签名与定位方式详见 references/api-facts.md
static ArkUI_NativeNodeAPI_1* nodeApi = nullptr;

// 保存 createNode 产物，供 dispose 时释放（防泄漏）
static ArkUI_NodeHandle parentNode = nullptr;

// 持有 ArkTS ComponentContent 的 napi_ref（防 GC 回收，须与 delete 成对）
static napi_ref arktsComponentRef = nullptr;

// 接收 NodeContent 和 ComponentContent，创建 Native 父节点并挂载 ArkTS 组件
static napi_value MountArktsComponent(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2] = {};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (argc < 2) {
        return nullptr;
    }

    // 1. 从 ArkTS NodeContent 获取 Native NodeContentHandle（用于挂载 Native 父节点）
    //    函数 OH_ArkUI_GetNodeContentFromNapiValue（<arkui/native_node_napi.h>，按符号名检索）
    ArkUI_NodeContentHandle contentHandle = nullptr;
    int32_t ret = OH_ArkUI_GetNodeContentFromNapiValue(env, args[0], &contentHandle);
    if (ret != 0 || contentHandle == nullptr) {
        return nullptr;
    }

    // 2. 创建 napi_ref 持有 ArkTS ComponentContent 引用（防 GC 回收）
    //    必须与 napi_delete_reference 成对（参见 references/napi-ref-pair.md）
    if (arktsComponentRef != nullptr) {
        napi_delete_reference(env, arktsComponentRef);
    }
    napi_create_reference(env, args[1], 1, &arktsComponentRef);

    // 3. 从 ArkTS 组件 napi_value 获取 Native ArkUI_NodeHandle
    //    函数 OH_ArkUI_GetNodeHandleFromNapiValue（<arkui/native_node_napi.h>，按符号名检索）
    //    注意：该 handle 仅可作 addChild 第二参数，不可用于 setAttribute（参见 references/handle-limit.md）
    ArkUI_NodeHandle childHandle = nullptr;
    ret = OH_ArkUI_GetNodeHandleFromNapiValue(env, args[1], &childHandle);
    if (ret != 0 || childHandle == nullptr) {
        return nullptr;
    }

    // 4. 获取节点 API 接口表 ArkUI_NativeNodeAPI_1
    if (nodeApi == nullptr) {
        OH_ArkUI_GetModuleInterface(ARKUI_NATIVE_NODE, ArkUI_NativeNodeAPI_1, nodeApi);
    }

    // 5. 创建 Native 父节点并挂到 NodeContent
    //    函数 createNode（ArkUI_NativeNodeAPI_1 成员，<arkui/native_node.h>）
    if (parentNode == nullptr) {
        parentNode = nodeApi->createNode(ARKUI_NODE_STACK);
        ArkUI_AttributeItem widthItem = { .string = "100%" };
        // 函数 setAttribute（ArkUI_NativeNodeAPI_1 成员，<arkui/native_node.h>）
        nodeApi->setAttribute(parentNode, NODE_WIDTH, &widthItem);
        // 函数 OH_ArkUI_NodeContent_AddNode（<arkui/native_node.h>，按符号名检索）
        OH_ArkUI_NodeContent_AddNode(contentHandle, parentNode);
    }

    // 6. 将 ArkTS 组件 handle 作为 child 挂到 Native 父节点
    //    handle 仅作 addChild 第二参数，不可用于 setAttribute（参见 references/handle-limit.md）
    //    函数 addChild（ArkUI_NativeNodeAPI_1 成员，<arkui/native_node.h>）
    nodeApi->addChild(parentNode, childHandle);

    // 注意：childHandle 的生命周期由 ArkTS 侧 ComponentContent 管理，
    //       不应调用 disposeNode(childHandle)（参见 references/node-dispose.md）

    return nullptr;
}

// 清理：释放 napi_ref 和 Native 节点（防泄漏）
// 函数 disposeNode（ArkUI_NativeNodeAPI_1 成员，<arkui/native_node.h>）
static napi_value Dispose(napi_env env, napi_callback_info info) {
    // 1. 释放 napi_ref（必须与 create 成对，参见 references/napi-ref-pair.md）
    if (arktsComponentRef != nullptr) {
        napi_delete_reference(env, arktsComponentRef);
        arktsComponentRef = nullptr;
    }
    // 2. dispose Native 父节点（createNode 产物须 dispose，参见 references/node-dispose.md）
    if (nodeApi != nullptr && parentNode != nullptr) {
        nodeApi->disposeNode(parentNode);
        parentNode = nullptr;
    }
    return nullptr;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        // 回调须在 field 3（method），不得落入 field 4（getter）（参见 references/napi-descriptor-field-order.md）
        { "mountArktsComponent", nullptr, MountArktsComponent, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "dispose", nullptr, Dispose, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

// NAPI 模块注册：nm_modname 必须与产物 lib<modname>.so 匹配
// ArkTS 侧: import nativeModule from 'libarkui_ndk_p2.so';
static napi_module arkuiNdkP2Module = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "arkui_ndk_p2",
    .nm_priv = nullptr,
    .reserved = { 0 },
};

extern "C" __attribute__((constructor)) void NAPI_arkui_ndk_p2_AutoRegistration() {
    napi_module_register(&arkuiNdkP2Module);
}
