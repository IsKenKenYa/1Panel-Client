# P1 方向模板：ArkTS→C（ArkTS 页面挂 Native 节点树）

本模板演示 P1 方向：ArkTS 侧创建占位符（`NodeContent` + `ContentSlot`），Native 侧取得 `NodeContentHandle` 后挂载 Native 节点树。

## 文件结构

模板结构镜像真实 HarmonyOS 工程布局（`CMakeLists.txt` 与源码同处 `cpp/` 目录）：

```
P1/
├── README.md
├── ets/
│   └── pages/
│       └── Index.ets        # ArkTS：NodeContent + ContentSlot 占位符
└── cpp/
    ├── CMakeLists.txt       # Native 模块 CMake 配置（产物 libarkui_ndk_p1.so）
    ├── native_template.cpp  # Native：取 NodeContentHandle + 挂载节点树
    └── types/
        └── libarkui_ndk_p1/
            ├── Index.d.ts       # ArkTS 类型声明（export const，非 export interface）
            └── oh-package.json5 # 类型包元数据
```

对应到目标工程：
- `ets/pages/Index.ets` → `entry/src/main/ets/pages/Index.ets`
- `cpp/` → `entry/src/main/cpp/`（含 `types/libarkui_ndk_p1/` 子目录）

## 集成方式

1. 将 `ets/pages/Index.ets` 内容合并到目标工程页面
2. 将 `cpp/` 整目录放入 `entry/src/main/cpp/`
3. 在 `entry/build-profile.json5` 的 `buildOption` 中加入 `externalNativeOptions`：
   ```json5
   "externalNativeOptions": {
     "path": "./src/main/cpp/CMakeLists.txt",
     "arguments": "",
     "cppFlags": "",
     "abiFilters": ["arm64-v8a", "x86_64"]
   }
   ```
4. 在 `entry/oh-package.json5` 中声明 Native 模块依赖：`"libarkui_ndk_p1.so": "file:./src/main/cpp/types/libarkui_ndk_p1"`，并将模板 `cpp/types/libarkui_ndk_p1/` 整目录复制到目标工程 `entry/src/main/cpp/types/libarkui_ndk_p1/`（含 `Index.d.ts` + `oh-package.json5`），使 ArkTS `import nativeModule from 'libarkui_ndk_p1.so'` 可解析。**`Index.d.ts` 中方法必须用 `export const` 顶层声明**，不得改写为 `export interface` + `export default`（详见下方"重要约束"）
5. `CMakeLists.txt` 中源文件路径为 `native_template.cpp`（与 `CMakeLists.txt` 同目录，**不要**写成 `cpp/native_template.cpp`，否则解析为 `cpp/cpp/native_template.cpp`）

## 关键 API

头文件位于 `${OHOS_SDK_NATIVE}/sysroot/usr/include/arkui/` 下（由 OHOS CMake 工具链自动加入 include）。

P1 方向涉及的关键 C API（`OH_ArkUI_GetModuleInterface` / `OH_ArkUI_GetNodeContentFromNapiValue` / `OH_ArkUI_NodeContent_AddNode` / `createNode` / `setAttribute` / `disposeNode` 等）的完整签名、头文件符号定位与用途见 `../../references/api-facts.md`——该文件为本 skill 的 C/ArkTS API 唯一权威源，本模板不在本地复制表项以避免行号漂移与重复维护。

## 重要约束

骨架生成的六条工程约束（CMake 双库链接、ContentSlot 不支持通用属性、napi_property_descriptor 字段顺序、Index.d.ts 用 export const、ComponentContent 构造签名、Init 用 EXTERN_C 包裹）的完整正文见 `../../SKILL.md`「骨架生成工程约束」章节。C/ArkTS API 权威源见 `../../SKILL.md`「C/ArkTS API 权威源」章节及 `../../references/api-facts.md`。七类坑点检测规则见 `../../SKILL.md`「坑点检测规则」表。本模板不在此逐条重复，以避免多副本漂移。
