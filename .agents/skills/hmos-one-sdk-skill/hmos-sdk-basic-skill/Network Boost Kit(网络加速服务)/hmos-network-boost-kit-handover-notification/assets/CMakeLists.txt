cmake_minimum_required(VERSION 3.10)
project(NetworkBoostHandover)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT DEFINED HMOS_SDK_NATIVE)
    message(FATAL_ERROR "HMOS_SDK_NATIVE environment variable is not set")
endif()

target_include_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/include
)

target_link_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos
)

target_link_libraries(entry PUBLIC 
    libnetwork_boost.so
    libhilog.so
)

add_executable(network_boost_handover_example assets/example_handover.cpp)

target_link_libraries(network_boost_handover_example 
    libnetwork_boost.so
    libhilog.so
)

install(TARGETS network_boost_handover_example DESTINATION bin)