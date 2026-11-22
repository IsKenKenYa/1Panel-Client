cmake_minimum_required(VERSION 3.4.1)
project(entry)

set(NATIVERENDER_ROOT_DIR ${CMAKE_CURRENT_SOURCE_DIR})

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

include_directories(
    ${NATIVERENDER_ROOT_DIR}
    ${NATIVERENDER_ROOT_DIR}/include
)

# Network Boost Kit C API 配置
# 设置头文件路径
target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)

# 设置动态库路径
target_link_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos)

# 链接libnetwork_boost.so及其他依赖的so
target_link_libraries(entry PUBLIC libnetwork_boost.so)

add_library(entry SHARED
    ./src/main/cpp/napi_init.cpp
    ./src/main/cpp/network_boost_wrapper.cpp
)

target_link_libraries(entry PUBLIC
    libace_napi.z.so
    libnetwork_boost.so
    libhilog_ndk.z.so
)