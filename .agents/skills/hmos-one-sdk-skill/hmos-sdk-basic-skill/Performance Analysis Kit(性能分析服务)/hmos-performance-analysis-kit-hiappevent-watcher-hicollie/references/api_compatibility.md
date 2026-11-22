# API版本和兼容性说明

本文档说明订阅任务执行超时事件技能的API版本要求和兼容性信息。

## API版本要求

### ArkTS API
- **最低版本**：API version 21
- **支持接口**：
  - hiAppEvent.addWatcher：API 9+，订阅APP_HICOLLIE需API 21+
  - hiAppEvent.removeWatcher：API 9+
  - hiAppEvent.domain.OS：API 9+
  - hiAppEvent.event.APP_HICOLLIE：API 21+

### C API
- **最低版本**：API version 12
- **支持接口**：
  - OH_HiCollie_SetTimer：API 12+（需libohhicollie.so）
  - OH_HiCollie_CancelTimer：API 12+
  - HiCollie_ErrorCode：API 12+
  - HiCollie_Flag：API 12+

### Kit支持
- **PerformanceAnalysisKit**：API 9+
- **HiAppEvent模块**：API 9+
- **HiCollie模块**：API 12+

## 设备兼容性

### 支持设备类型
- **手机**：完全支持
- **平板**：完全支持
- **手表**：部分支持（需验证）
- **智慧屏**：部分支持（需验证）

### 系统要求
- HarmonyOS 4.0及以上
- DevEco Studio 3.1及以上
- HarmonyOS SDK API 21及以上

## 元服务支持

- **hiAppEvent.addWatcher**：API 11+支持元服务
- **hiAppEvent.removeWatcher**：API 11+支持元服务
- **OH_HiCollie_SetTimer**：不支持元服务（仅应用）

## 系统能力要求

### ArkTS API
- **系统能力**：SystemCapability.HiviewDFX.HiAppEvent
- **权限要求**：无特殊权限要求
- **依赖库**：无外部依赖

### C API
- **系统能力**：SystemCapability.HiviewDFX.HiCollie
- **依赖库**：libohhicollie.so（必需）
- **头文件**：hicollie/hicollie.h（必需）

## 版本变更记录

### API 21变更
- 新增APP_HICOLLIE事件订阅支持
- 新增任务执行超时检测功能

### API 12变更
- 新增OH_HiCollie_SetTimer C API
- 新增OH_HiCollie_CancelTimer C API
- 新增HiCollie模块

### API 9变更
- 新增HiAppEvent模块
- 新增addWatcher、removeWatcher接口

## 已停止维护接口

- **js-apis-hiappevent（旧版）**：已停止维护，不建议使用
- 建议使用js-apis-hiviewdfx-hiappevent（新版）

## 开发环境兼容性

### DevEco Studio版本
- **推荐版本**：DevEco Studio 4.0+
- **最低版本**：DevEco Studio 3.1
- **Native C++支持**：DevEco Studio 3.1+

### SDK版本
- **HarmonyOS SDK**：API 21+
- **Native Development Kit**：需包含libohhicollie.so

### CMake版本
- **最低版本**：CMake 3.4.1
- **推荐版本**：CMake 3.10+

## 运行时兼容性

### 线程要求
- **addWatcher**：可在主线程或子线程调用（建议子线程）
- **removeWatcher**：可在主线程或子线程调用
- **OH_HiCollie_SetTimer**：可在主线程调用（与文档说明不同，本场景主线程可用）
- **OH_HiCollie_CancelTimer**：可在主线程调用

### 进程要求
- **不支持进程**：appspawn、nativespawn进程不可调用HiCollie API
- **支持进程**：应用主进程、子进程

### 内存要求
- **观察者数量限制**：建议不超过20个并发观察者
- **事件数据缓存**：由系统管理，开发者无需关注

## 向后兼容性

### API稳定性
- 所有接口保持向后兼容
- 新增参数使用可选形式，不影响现有代码

### 数据格式
- APP_HICOLLIE事件参数格式稳定，新增字段向后兼容
- 使用可选链访问新字段，避免兼容性问题

## 测试兼容性

### 单元测试
- 使用@ohos/hypium测试框架
- 支持正向、边界、异常测试用例

### 集成测试
- 需完整Native C++工程
- 需DevEco Studio运行环境

## 注意事项

1. **API版本检查**：开发前确认设备API版本>=21
2. **SDK配置**：确保HarmonyOS SDK包含Native头文件和库文件
3. **工程类型**：必须使用Native C++模板，不支持纯ArkTS工程
4. **库链接**：CMakeLists.txt必须链接libohhicollie.so
5. **线程安全**：回调函数避免耗时操作，确保线程安全
6. **错误处理**：使用try-catch和可选链，增强代码健壮性