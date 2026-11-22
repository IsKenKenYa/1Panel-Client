// demo 采样：Native 插件形态（NDK C-API 引用）
#include <hilog/log.h>
#include "ace/xcomponent/native_interface_xcomponent.h"

extern "C" void PluginOnSurface(OH_NativeXComponent* component) {
  OH_NativeXComponent_RegisterCallback(component, nullptr);
}

// 未覆盖头文件（规则表待补 → unknown，VM-16 归因项）
#include "native_media/avcodec.h"
