cmake_minimum_required(VERSION 3.4.1)
project(NetworkSceneCallbackDemo)

set(CMAKE_CXX_STANDARD 11)

if(DEFINED ENV{HMOS_SDK_NATIVE})
    set(HMOS_SDK_NATIVE $ENV{HMOS_SDK_NATIVE})
else()
    message(FATAL_ERROR "HMOS_SDK_NATIVE environment variable is not set")
endif()

add_executable(network_scene_demo 
    network_scene_callback_demo.cpp
)

target_include_directories(network_scene_demo PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/include
)

target_link_directories(network_scene_demo PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos
)

target_link_libraries(network_scene_demo PUBLIC 
    libnetwork_boost.so
    libhilog.so
)

message(STATUS "HMOS SDK Native Path: ${HMOS_SDK_NATIVE}")
message(STATUS "Target: network_scene_demo")
message(STATUS "Linked libraries: libnetwork_boost.so, libhilog.so")