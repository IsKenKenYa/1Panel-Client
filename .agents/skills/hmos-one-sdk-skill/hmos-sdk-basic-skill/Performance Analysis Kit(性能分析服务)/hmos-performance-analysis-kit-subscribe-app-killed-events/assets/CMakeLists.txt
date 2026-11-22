cmake_minimum_required(VERSION 3.4.1)
project(entry)

# 设置C++标准
set(CMAKE_CXX_STANDARD 17)

# 设置编译选项
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Werror")

# 添加源文件
add_library(entry SHARED 
    napi_init.cpp 
    jsoncpp.cpp
)

# 添加动态库依赖
target_link_libraries(entry PUBLIC 
    libace_napi.z.so        # NAPI基础库
    libhilog_ndk.z.so       # 日志库
    libhiappevent_ndk.z.so  # HiAppEvent事件订阅库
)

# 添加头文件路径
target_include_directories(entry PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/json
)

# 设置输出目录
set_target_properties(entry PROPERTIES 
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../libs"
)

# 编译说明
message(STATUS "HiAppEvent AppKilledEventWatcher Example")
message(STATUS "C++ Standard: C++17")
message(STATUS "Dependencies: libhiappevent_ndk.z.so, libhilog_ndk.z.so, libace_napi.z.so")
message(STATUS "Requirements: HarmonyOS API version >= 20")