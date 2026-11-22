// 场景：v1.3.0 C-API 跨平台清单命中 + v1.3.0 撤下条目落 unknown（宁缺毋错）
#include <arkui/native_node.h>
#include <arkui/native_dialog.h>
#include <ace/xcomponent/native_interface_xcomponent.h>
#include "rawfile/raw_file_manager.h"

void LoadRaw(NativeResourceManager* mgr) {
  OH_ResourceManager_OpenRawFile(mgr, "cfg.json");
}

#include <napi/native_api.h>
#include <node_api.h>
#include "plugin_utils.h"

// 撤下条目（无 docs 佐证，rules v1.3.0 已移除）→ unknown 待人工
#include "native_drawing/native_drawing.h"
#include "ohos_init.h"
// 注释中的符号/动态加载不得计数或提示（审计增补场景）：
// OH_ResourceManager_OpenRawFile(m, "x");
// void* hc = dlopen("libghost.z.so", 2);
// void* hv = dlopen(p, 2);
