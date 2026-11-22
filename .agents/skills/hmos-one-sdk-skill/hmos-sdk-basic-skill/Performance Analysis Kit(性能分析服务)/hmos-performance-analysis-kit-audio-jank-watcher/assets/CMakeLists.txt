cmake_minimum_required(VERSION 3.4.1)
project(entry)

set(CMAKE_CXX_STANDARD 17)

add_library(entry SHARED napi_init.cpp jsoncpp.cpp)

target_link_libraries(entry PUBLIC 
    libace_napi.z.so 
    libhilog_ndk.z.so 
    libhiappevent_ndk.z.so
)

target_include_directories(entry PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}/json
)

set_target_properties(entry PROPERTIES
    OUTPUT_NAME "entry"
    CXX_VISIBILITY_PRESET hidden
)