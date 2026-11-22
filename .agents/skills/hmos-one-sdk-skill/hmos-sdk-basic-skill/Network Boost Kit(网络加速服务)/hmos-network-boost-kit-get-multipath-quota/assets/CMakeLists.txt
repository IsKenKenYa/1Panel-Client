cmake_minimum_required(VERSION 3.4.1)
project(entry)

# 设置C++标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 设置HarmonyOS SDK路径（需要根据实际环境配置）
# set(HMOS_SDK_NATIVE "/path/to/harmonyos/sdk/native")

# 添加头文件路径
target_include_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/include
)

# 添加动态库路径
target_link_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos
)

# 链接动态库
target_link_libraries(entry PUBLIC 
    libnetwork_boost.so
    # 其他依赖库
    # libhilog_ndk.z.so
    # libace_napi.z.so
)

# 设置编译选项
target_compile_options(entry PRIVATE
    -Wall
    -Wextra
    -Werror
    -O2
)

# 设置链接选项
target_link_options(entry PRIVATE
    -Wl,--gc-sections
    -Wl,-z,noexecstack
    -Wl,-z,relro
    -Wl,-z,now
)