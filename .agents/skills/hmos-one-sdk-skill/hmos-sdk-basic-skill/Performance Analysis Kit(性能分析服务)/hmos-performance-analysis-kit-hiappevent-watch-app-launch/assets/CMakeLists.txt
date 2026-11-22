cmake_minimum_required(VERSION 3.4.1)
project(AppLaunchWatcher)

set(CMAKE_CXX_STANDARD 17)

add_library(entry SHARED
    napi_init.cpp
    jsoncpp.cpp
)

target_include_directories(entry PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/json
)

target_link_libraries(entry PUBLIC
    libace_napi.z.so
    libhilog_ndk.z.so
    libhiappevent_ndk.z.so
)