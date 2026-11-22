#include <thread>
#include <napi/native_api.h>
#include <string.h>

static void NativeLeak() {
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
    return {};
}

static napi_value CPUHighload(napi_env env, napi_callback_info info) {
    std::thread t2([]() {
        volatile int count = 0;
        while (true) {
            for (int i = 0; i < 1000000; i++) {
                count++;
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
    });
    t2.detach();
    return {};
}

static napi_value ThreadLeak(napi_env env, napi_callback_info info) {
    for (int i = 0; i < 500; i++) {
        std::thread t3([]() {
            while (true) {
                std::this_thread::sleep_for(std::chrono::seconds(10));
            }
        });
        t3.detach();
    }
    return {};
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "leak", nullptr, Leak, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "cpuHighload", nullptr, CPUHighload, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "threadLeak", nullptr, ThreadLeak, nullptr, nullptr, nullptr, napi_default, nullptr }
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

extern __attribute__((constructor)) void RegisterEntryModule(void) {
    napi_register_module(&demoModule);
}