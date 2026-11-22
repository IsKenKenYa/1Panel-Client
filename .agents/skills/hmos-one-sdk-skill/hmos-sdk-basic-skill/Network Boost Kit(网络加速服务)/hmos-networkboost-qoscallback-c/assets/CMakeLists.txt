cmake_minimum_required(VERSION 3.4.1)
project(network_qos_monitor)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(network_qos_monitor 
    network_qos_monitor.cpp
)

target_include_directories(network_qos_monitor PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/include
)

target_link_directories(network_qos_monitor PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos
)

target_link_libraries(network_qos_monitor PUBLIC 
    libnetwork_boost.so
    libc++.so
    libhilog.so
)

target_compile_options(network_qos_monitor PRIVATE 
    -Wall
    -Wextra
    -Werror
    -fPIC
)

set_target_properties(network_qos_monitor PROPERTIES 
    OUTPUT_NAME "network_qos_monitor"
)