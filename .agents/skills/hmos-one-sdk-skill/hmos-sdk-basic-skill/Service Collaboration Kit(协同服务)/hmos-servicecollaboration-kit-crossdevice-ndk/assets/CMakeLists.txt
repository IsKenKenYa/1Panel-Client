cmake_minimum_required(VERSION 3.4.1)
project(service_collaboration_example)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_library(
    service_collaboration-lib
    libservice_collaboration_ndk.z.so
)

if(NOT service_collaboration-lib)
    message(FATAL_ERROR "Could not find libservice_collaboration_ndk.z.so")
endif()

add_executable(entry example_crossdevice_collaboration.cpp)

target_link_libraries(entry PUBLIC
    ${service_collaboration-lib}
)

message(STATUS "Service Collaboration library found: ${service_collaboration-lib}")
message(STATUS "Build configuration completed successfully")