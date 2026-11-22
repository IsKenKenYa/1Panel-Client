cmake_minimum_required(VERSION 3.4.1)
project(entry)

# 新增jsoncpp.cpp源文件(解析订阅事件中的json字符串)
add_library(entry SHARED 
    napi_init.cpp 
    jsoncpp.cpp
)

# 新增动态库依赖libhiappevent_ndk.z.so和libhilog_ndk.z.so(日志输出)
target_link_libraries(entry PUBLIC 
    libace_napi.z.so 
    libhilog_ndk.z.so 
    libhiappevent_ndk.z.so
)