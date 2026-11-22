#include <iostream>
#include <fstream>
#include <sstream>
#include <thread>
#include <vector>
#include <napi/native_api.h>

static int GetCurrentProcessPss()
{
    std::ifstream smapsFile("/proc/self/smaps_rollup");
    if (!smapsFile.is_open()) {
        std::cerr << "Failed to open /proc/self/smaps_rollup" << std::endl;
        return 0;
    }
    
    std::string line;
    int totalPss = 0;
    while (std::getline(smapsFile, line)) {
        if (line.find("Pss:") == 0) {
            std::istringstream iss(line);
            std::string label;
            int pss;
            iss >> label >> pss;
            totalPss += pss;
        }
    }
    
    smapsFile.close();
    std::cout << "Current pss: " << totalPss << " KB\r";
    std::cout.flush();
    return totalPss;
}

static int GetCurrentFd()
{
    std::ifstream fdFile("/proc/self/fd_num");
    if (!fdFile.is_open()) {
        std::cerr << "Failed to open /proc/self/fd_num" << std::endl;
        return 0;
    }
    
    std::string line;
    std::getline(fdFile, line);
    fdFile.close();
    std::cout << "Current fd: " << line << std::endl;
    std::cout.flush();
    return std::stoi(line);
}

static bool InjectNativeLeakMallocWithSize(int size, char *p)
{
    const size_t maxSafe = 1073741824;
    if (size < 0 || size > maxSafe) {
        printf("InjectNativeLeakMallocWithSize invalid size\n");
        return false;
    }
    
    p = (char *)malloc(size + 1);
    if (!p) {
        printf("InjectNativeLeakMallocWithSize malloc failed\n");
        return false;
    }
    
    void* err = memset(p, 'a', size);
    if (err == nullptr) {
        printf("InjectNativeLeakMallocWithSize memset failed\n");
        return false;
    }
    
    return true;
}

static void InjectNativeLeakMallocUntil(int target)
{
    constexpr int leakSizePerTime = 5000000;
    std::vector<char *> mems;
    int curPss = GetCurrentProcessPss();
    
    while (curPss != 0) {
        char *p = nullptr;
        if (curPss < target) {
            if (!InjectNativeLeakMallocWithSize(leakSizePerTime, p)) {
                printf("InjectNativeLeakMallocUntil target = %d failed\n", target);
            }
            mems.push_back(p);
            std::cout << "Inject size: " << leakSizePerTime 
                      << ", currentSize: " << mems.size() << std::endl;
        } else {
            if (mems.size() > 0) {
                char *dst = mems[0];
                mems.erase(mems.begin());
                free(dst);
            }
            std::cout << "Free size: " << leakSizePerTime 
                      << ", currentSize: " << mems.size() << std::endl;
        }
        curPss = GetCurrentProcessPss();
    }
    
    std::cout << std::endl;
    printf("InjectNativeLeakMallocUntil target = %d success\n", target);
}

static void StartNativeLeak(int leakSize)
{
    std::cout << "Start inject malloc until " << leakSize << " KB" << std::endl;
    std::thread t1(InjectNativeLeakMallocUntil, leakSize);
    t1.detach();
    std::cout << "Inject finished." << std::endl;
}

static napi_value LeakMB(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        napi_throw_type_error(env, nullptr, "Expected 1 argument");
        return nullptr;
    }
    
    double x = 0;
    if (napi_get_value_double(env, args[0], &x) != napi_ok) {
        napi_throw_type_error(env, nullptr, "Argument must be a number");
        return nullptr;
    }
    
    const size_t kilobyte = 1024;
    StartNativeLeak(static_cast<size_t>(x * kilobyte));
    
    napi_value rtn;
    napi_get_undefined(env, &rtn);
    return rtn;
}

static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "leakMB", nullptr, LeakMB, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

NAPI_MODULE(testNapi, Init)