# CMakeLists.txt配置示例
# 资源泄漏事件订阅项目

cmake_minimum_required(VERSION 3.4.1)
project(entry)

# 设置C++标准
set(CMAKE_CXX_STANDARD 17)

# 添加源文件
# 新增jsoncpp.cpp(解析订阅事件中的json字符串)源文件
add_library(entry SHARED 
    napi_init.cpp 
    jsoncpp.cpp
)

# 添加头文件路径
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/json
)

# 新增动态库依赖libhiappevent_ndk.z.so和libhilog_ndk.z.so(日志输出)
target_link_libraries(entry PUBLIC 
    libace_napi.z.so 
    libhilog_ndk.z.so 
    libhiappevent_ndk.z.so
)

# 设置编译选项
target_compile_options(entry PRIVATE 
    -Wall
    -Wextra
    -Werror
)