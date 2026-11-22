// benchmark fixture：Native C-API 引用样例（v1.2 TASK-6：C-API 扫描与判定）
// 头文件包含（NDK 头）/ OH_* 符号 / dlopen 字面量与变量形式（R-1）
#include <vector>
#include <hilog/log.h>
#include "ace/xcomponent/native_interface_xcomponent.h"

static void OnSurfaceCreated(OH_NativeXComponent* component, void* window) {
  OH_NativeXComponent_GetXComponentSize(component, window, nullptr, nullptr);
}

extern "C" void NapiOnSurface(OH_NativeXComponent* component) {
  OH_NativeXComponent_RegisterCallback(component, nullptr);
}

// 未覆盖头文件（规则表无条目 → unknown）
#include "native_media/avcodec.h"

void TryEncode() {
  OH_AVEncoder_Create(nullptr);
}

// 动态加载：字面量计入（module=so 库名）；变量形式仅提示（R-1）
void LoadDynamic(void* handle, const char* path) {
  handle = dlopen("libblend.z.so", 2);
  handle = dlopen(path, 2);
}
