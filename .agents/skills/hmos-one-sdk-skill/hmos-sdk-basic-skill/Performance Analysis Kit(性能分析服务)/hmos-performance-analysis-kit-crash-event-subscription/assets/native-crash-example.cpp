#include <napi/native_api.h>

static napi_value TestNullptr(napi_env env, napi_callback_info info) {
    int *p = nullptr;
    int a = *p; // 空指针解引用，程序会在此处崩溃
    return {};
}

static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "testNullptr", nullptr, TestNullptr, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

extern "C" __attribute__((visibility("default"))) napi_value NAPI_get_Example(napi_env env, napi_value exports) {
    return Init(env, exports);
}