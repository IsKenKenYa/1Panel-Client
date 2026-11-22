cmake_minimum_required(VERSION 3.4.1)
project(entry)

set(GZ_FILE "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/jsoncpp/src/jsoncpp-1.9.6.tar.gz")
set(DEST_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../build")

execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${DEST_DIR})
execute_process(COMMAND tar -xzf ${GZ_FILE} -C ${DEST_DIR} WORKING_DIRECTORY ${DEST_DIR})

add_library(entry SHARED napi_init.cpp)

target_link_libraries(entry PUBLIC 
    libace_napi.z.so 
    libhilog_ndk.z.so 
    libhiappevent_ndk.z.so
)

target_link_libraries(entry PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/jsoncpp/${OHOS_ARCH}/lib/libjsoncpp.so
)

target_include_directories(entry PRIVATE 
    ${DEST_DIR}/jsoncpp-1.9.6/include/json
)