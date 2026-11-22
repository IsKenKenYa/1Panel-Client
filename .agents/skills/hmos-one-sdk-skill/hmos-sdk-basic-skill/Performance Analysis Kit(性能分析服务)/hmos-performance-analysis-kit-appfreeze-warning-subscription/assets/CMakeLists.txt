cmake_minimum_required(VERSION 3.4.1)
project(entry)

set(NATIVE_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

if(EXISTS "${NATIVE_ROOT_PATH}/json/jsoncpp.cpp")
    add_library(entry SHARED 
        napi_init.cpp
        jsoncpp.cpp
    )
else()
    message(FATAL_ERROR "jsoncpp.cpp not found. Please download from https://github.com/open-source-parsers/jsoncpp and generate amalgamated source.")
endif()

include_directories(${NATIVE_ROOT_PATH})
include_directories(${NATIVE_ROOT_PATH}/json)

target_link_libraries(entry PUBLIC 
    libace_napi.z.so
    libhilog_ndk.z.so
    libhiappevent_ndk.z.so
)