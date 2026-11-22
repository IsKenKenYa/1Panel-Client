cmake_minimum_required(VERSION 3.4.1)
project(NetworkBoostSceneCallback)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(network_boost_demo 
    example_network_scene.cpp
)

target_include_directories(network_boost_demo PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/include
)

target_link_directories(network_boost_demo PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos
)

target_link_libraries(network_boost_demo PUBLIC 
    libnetwork_boost.so
    libc.so
)

if (CMAKE_BUILD_TYPE MATCHES "Debug")
    target_compile_options(network_boost_demo PRIVATE -g -O0)
else()
    target_compile_options(network_boost_demo PRIVATE -O2)
endif()