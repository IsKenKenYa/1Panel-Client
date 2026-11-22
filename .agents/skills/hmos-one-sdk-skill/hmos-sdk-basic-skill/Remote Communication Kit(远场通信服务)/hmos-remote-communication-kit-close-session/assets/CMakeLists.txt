cmake_minimum_required(VERSION 3.4.1)
project(remote_communication_close_session)

set(CMAKE_CXX_STANDARD 17)

include_directories(
    ${OHOS_SDK_PATH}/native/sysroot/usr/include
    ${OHOS_SDK_PATH}/native/sysroot/usr/include/RemoteCommunicationKit
)

add_executable(close_session_example example_close_session.cpp)

target_link_libraries(close_session_example
    librcp_c.so
    hilog_ndk.z.so
)

set_target_properties(close_session_example PROPERTIES
    OUTPUT_NAME "close_session_example"
)