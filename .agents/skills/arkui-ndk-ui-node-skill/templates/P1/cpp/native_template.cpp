#include <arkui/native_interface.h>
#include <arkui/native_node_napi.h>
#include <arkui/native_node.h>
#include <arkui/native_type.h>
#include <napi/native_api.h>

// 节点 API 接口表：ArkUI_NativeNodeAPI_1（在 <arkui/native_node.h> 中按符号名检索）
// 通过 OH_ArkUI_GetModuleInterface 宏获取（在 <arkui/native_interface.h> 中按符号名检索）
// 完整签名与定位方式详见 references/api-facts.md
static ArkUI_NativeNodeAPI_1* nodeApi = nullptr;

// 保存 createNode 产物，供 aboutToDisappear 时 dispose 释放（防泄漏）
static ArkUI_NodeHandle g_stackNode = nullptr;
static ArkUI_NodeHandle g_textNode = nullptr;

static napi_value MountNativeNodes(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = {};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (argc < 1) {
        return nullptr;
    }

    // 1. 从 ArkTS NodeContent 获取 Native NodeContentHandle
    //    函数 OH_ArkUI_GetNodeContentFromNapiValue（<arkui/native_node_napi.h>，按符号名检索）
    ArkUI_NodeContentHandle contentHandle = nullptr;
    int32_t ret = OH_ArkUI_GetNodeContentFromNapiValue(env, args[0], &contentHandle);
    if (ret != 0 || contentHandle == nullptr) {
        return nullptr;
    }

    // 2. 获取节点 API 接口表 ArkUI_NativeNodeAPI_1
    if (nodeApi == nullptr) {
        OH_ArkUI_GetModuleInterface(ARKUI_NATIVE_NODE, ArkUI_NativeNodeAPI_1, nodeApi);
    }

    // 3. 创建 Native 节点树（Stack 容器 + Text 子节点）
    //    函数 createNode（ArkUI_NativeNodeAPI_1 成员，<arkui/native_node.h>）
    g_stackNode = nodeApi->createNode(ARKUI_NODE_STACK);
    g_textNode = nodeApi->createNode(ARKUI_NODE_TEXT);

    // 4. 设置 Text 节点内容（ArkUI_AttributeItem 在 <arkui/common_type.h> 中按符号名检索）
    //    函数 setAttribute（ArkUI_NativeNodeAPI_1 成员，<arkui/native_node.h>）
    ArkUI_AttributeItem textItem = { .string = "Hello from Native!" };
    nodeApi->setAttribute(g_textNode, NODE_TEXT_CONTENT, &textItem);

    // 5. 将 Text 挂到 Stack 下
    //    函数 addChild（ArkUI_NativeNodeAPI_1 成员，<arkui/native_node.h>）
    nodeApi->addChild(g_stackNode, g_textNode);

    // 6. 将 Stack 挂到 NodeContent
    //    函数 OH_ArkUI_NodeContent_AddNode（<arkui/native_node.h>，按符号名检索）
    OH_ArkUI_NodeContent_AddNode(contentHandle, g_stackNode);

    return nullptr;
}

// 清理：组件销毁时 dispose 节点（防泄漏，参见 references/node-dispose.md）
// 先 dispose 子节点再 dispose 父节点，避免父节点持有悬垂指针
// 函数 disposeNode（ArkUI_NativeNodeAPI_1 成员，<arkui/native_node.h>）
static napi_value DisposeNodes(napi_env env, napi_callback_info info) {
    if (nodeApi != nullptr) {
        if (g_textNode != nullptr) {
            nodeApi->disposeNode(g_textNode);
            g_textNode = nullptr;
        }
        if (g_stackNode != nullptr) {
            nodeApi->disposeNode(g_stackNode);
            g_stackNode = nullptr;
        }
    }
    return nullptr;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "mountNativeNodes", nullptr, MountNativeNodes, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "disposeNodes", nullptr, DisposeNodes, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

// NAPI 模块注册：nm_modname 必须与产物 lib<modname>.so 匹配
// ArkTS 侧: import nativeModule from 'libarkui_ndk_p1.so';
static napi_module arkuiNdkP1Module = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "arkui_ndk_p1",
    .nm_priv = nullptr,
    .reserved = { 0 },
};

extern "C" __attribute__((constructor)) void NAPI_arkui_ndk_p1_AutoRegistration() {
    napi_module_register(&arkuiNdkP1Module);
}
