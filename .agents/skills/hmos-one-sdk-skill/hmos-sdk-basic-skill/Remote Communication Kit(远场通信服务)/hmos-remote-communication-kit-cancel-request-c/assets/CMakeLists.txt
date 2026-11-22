cmake_minimum_required(VERSION 3.16)
project(remote_communication_cancel CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 设置编译选项
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Werror")

# 添加可执行文件
add_executable(cancel_request_example 
    cancel_request_complete.cpp
)

# 链接Remote Communication Kit C库
target_link_libraries(cancel_request_example 
    librcp_c.so
)

# 添加头文件路径(根据实际SDK路径调整)
target_include_directories(cancel_request_example PRIVATE 
    ${HARMONYOS_SDK_ROOT}/native/sysroot/usr/include
)

# 添加库文件路径(根据实际SDK路径调整)
target_link_directories(cancel_request_example PRIVATE 
    ${HARMONYOS_SDK_ROOT}/native/sysroot/usr/lib
)

# 设置输出目录
set_target_properties(cancel_request_example PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

# 添加测试可执行文件
option(BUILD_TESTS "Build test executables" ON)

if(BUILD_TESTS)
    add_executable(test_cancel_single_request 
        tests/test_cancel_single_request.cpp
    )
    target_link_libraries(test_cancel_single_request librcp_c.so)
    
    add_executable(test_cancel_session 
        tests/test_cancel_session.cpp
    )
    target_link_libraries(test_cancel_session librcp_c.so)
    
    add_executable(test_error_handling 
        tests/test_error_handling.cpp
    )
    target_link_libraries(test_error_handling librcp_c.so)
endif()

# 安装规则
install(TARGETS cancel_request_example
    RUNTIME DESTINATION bin
)

install(FILES cancel_request_complete.cpp
    DESTINATION src
)