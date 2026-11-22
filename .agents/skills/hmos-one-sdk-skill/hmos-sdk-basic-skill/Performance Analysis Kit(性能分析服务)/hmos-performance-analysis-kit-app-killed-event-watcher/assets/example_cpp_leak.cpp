#include <thread>
#include <napi/native_api.h>

static void NativeLeak()
{
    constexpr int leak_size_per_time = 500000;
    while (true) {
        char *p = (char *)malloc(leak_size_per_time + 1);
        if (!p) {
            break;
        }
        memset(p, 'a', leak_size_per_time);
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
}

static napi_value Leak(napi_env env, napi_callback_info info) {
    std::thread t1(NativeLeak);
    t1.detach();
    return nullptr;
}

static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "leak", nullptr, Leak, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

extern "C" __attribute__((visibility("default"))) napi_value NAPI_get_arkts_napi_Module(napi_env env, napi_value exports)
{
    return Init(env, exports);
}