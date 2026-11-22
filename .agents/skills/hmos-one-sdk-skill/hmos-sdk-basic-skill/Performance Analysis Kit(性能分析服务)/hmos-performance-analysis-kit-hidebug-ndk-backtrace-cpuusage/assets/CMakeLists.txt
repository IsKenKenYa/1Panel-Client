cmake_minimum_required(VERSION 3.4.1)
project(hidebug_ndk_example)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(hidebug_example SHARED hidebug_ndk_example.cpp)

target_include_directories(hidebug_example PRIVATE
    ${OHOS_INCLUDE_DIRS}/hidebug
    ${OHOS_INCLUDE_DIRS}/hilog
)

target_link_libraries(hidebug_example PUBLIC
    libohhidebug.so
    libhilog_ndk.z.so
    libace_napi.z.so
)

set_target_properties(hidebug_example PROPERTIES
    OUTPUT_NAME "hidebug_example"
    VERSION 1.0.0
    SOVERSION 1
)