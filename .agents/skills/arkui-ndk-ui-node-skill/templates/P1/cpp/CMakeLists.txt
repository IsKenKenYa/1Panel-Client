cmake_minimum_required(VERSION 3.5.0)
project(arkui_ndk_p1)

# ArkUI NDK 头文件由 OHOS CMake 工具链（hmos.toolchain.cmake）自动加入 sysroot include
# 头文件位于 ${OHOS_SDK_NATIVE}/sysroot/usr/include/arkui/ 下
set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/include)

# 本 CMakeLists.txt 与 native_template.cpp 同处 cpp/ 目录
# （对应工程中 entry/src/main/cpp/CMakeLists.txt）
add_library(arkui_ndk_p1 SHARED
    native_template.cpp
)

# ace_ndk.z.so 提供 ArkUI NDK 符号（OH_ArkUI_* / ArkUI_NativeNodeAPI_1 等）
# ace_napi.z.so 提供 NAPI 符号（napi_get_cb_info / napi_module_register / napi_define_properties 等）
target_link_libraries(arkui_ndk_p1 PUBLIC
    ace_ndk.z.so
    ace_napi.z.so
)
