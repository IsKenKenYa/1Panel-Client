cmake_minimum_required(VERSION 3.4.1)
project(netmanager_demo)

set(CMAKE_CXX_STANDARD 17)

find_package(
    OHOS::Native
    REQUIRED
)

add_library(entry SHARED
    example_napi_wrapper.cpp
)

target_link_libraries(entry
    PUBLIC
        libace_napi.z.so
        libnet_connection.so
)

target_include_directories(entry PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${OHOS_INCLUDE_DIRS}
)

set_target_properties(entry PROPERTIES
    OUTPUT_NAME "entry"
    PREFIX ""
)

install(TARGETS entry
    LIBRARY DESTINATION lib
)