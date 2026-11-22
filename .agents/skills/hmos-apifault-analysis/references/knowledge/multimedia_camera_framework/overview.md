# multimedia_camera_framework 知识库概览

## 模块职责

multimedia_camera_framework（相机组件）是  multimedia 子系统下的核心部件，提供相机业务开发能力。通过开放的 JS/NAPI 接口（`@ohos.multimedia.camera`）、Native API C 接口（`libohcamera.so`）和内部 C++ API，实现相机硬件访问，支持预览（Preview）、拍照（Photo/Capture）、录像（Video）、元数据采集（Metadata，如人脸/人体检测）、多摄切换（Multi-Camera）、延迟处理（Deferred Processing）、手电筒（Torch）、平滑变焦（Smooth Zoom）等功能。开发者通过 CameraManager 获取相机列表和能力，创建 CameraInput 和会话（CaptureSession/PhotoSession/VideoSession），配置输入输出流后提交并启动，实现完整的相机业务流程。

- **子系统**：multimedia
- **部件名**：`@ohos/camera_framework`
- **SysCap**：`SystemCapability.Multimedia.Camera.Core`
- **权限**：`ohos.permission.CAMERA`（录像场景还需麦克风权限）
- **NAPI 模块名**：`multimedia.camera`
- **SDK 声明文件**：`@ohos.multimedia.camera.d.ts`、`@ohos.multimedia.cameraPicker.d.ts`
- **Native API 库**：`libohcamera.so`（since 11）

## 目录结构（简化，3 层）

```
multimedia_camera_framework/
├── interfaces/                          # 接口定义
│   ├── inner_api/native/camera/include/ # C++ 内部 API 头文件
│   │   ├── camera_error_code.h          # 错误码定义（核心）
│   │   ├── input/                       # CameraManager/CameraInput/CaptureInput
│   │   ├── output/                      # PhotoOutput/PreviewOutput/VideoOutput/MetadataOutput
│   │   ├── session/                     # CaptureSession/PhotoSession/VideoSession/...
│   │   └── deferred_proc_session/       # 延迟处理会话
│   └── kits/
│       ├── js/camera_napi/              # JS .d.ts 声明 + NAPI 公共头
│       │   ├── @ohos.multimedia.camera.d.ts
│       │   └── @ohos.multimedia.cameraPicker.d.ts
│       └── native/include/camera/       # Native API C 头文件（camera.h/camera_manager.h/...）
├── frameworks/
│   ├── js/camera_napi/                  # NAPI 主实现（multimedia.camera 模块）
│   │   └── src/
│   │       ├── native_module_ohos_camera.cpp  # 模块注册入口
│   │       ├── input/                   # CameraManagerNapi/CameraInputNapi/CameraNapi
│   │       ├── output/                  # PhotoOutputNapi/PreviewOutputNapi/VideoOutputNapi/...
│   │       ├── session/                 # CameraSessionNapi/ControlCenterSessionNapi
│   │       ├── mode/                    # PhotoSessionNapi/VideoSessionNapi/SecureCameraSessionNapi
│   │       └── picker/                  # CameraPickerNapi
│   ├── js/camera_napi_for_sys/          # 系统扩展 NAPI（系统应用专用）
│   ├── native/
│   │   ├── camera/                      # C++ 实现
│   │   │   ├── base/src/                # 核心：input/output/session/utils/deferred_proc_session/ability
│   │   │   └── extension/               # 系统扩展会话（Night/Portrait/Profession/...）
│   │   └── xxx/impl/                    # Native API 实现（ohcamera）
│   ├── taihe/                           # ANI/ArkTS 静态化层
│   └── cj/                              # Cangjie 语言 FFI（camera/camera_picker）
├── services/
│   ├── camera_service/                  # 相机服务（SA 进程，IPC + HDF）
│   │   ├── include/                     # HCameraService/HCameraDeviceManager/HCaptureSession/...
│   │   ├── binder/ + idls/              # IPC 接口
│   │   └── src/
│   └── deferred_processing_service/     # 延迟处理服务（照片/视频后处理）
├── common/                              # 公共工具（task_manager/timer/utils）
├── dynamic_libs/                        # 动态依赖封装（av_codec/image_framework/media_library/...）
├── mediastream/                         # 媒体流（pipeline/filter/buffer）
├── moviefile/                           # MovieFile 封装（pipeline）
├── sa_profile/                          # SA 配置文件
├── test/                                # fuzz 测试 + 模块测试
└── bundle.json
```

## 核心文件清单（按子模块组织）

### interfaces（接口定义层）

| 文件 | 说明 |
|------|------|
| `interfaces/inner_api/native/camera/include/camera_error_code.h` | **错误码定义**（CameraErrorCode 枚举 + errorCodeMap 映射 + GetCameraErrorCode） |
| `interfaces/inner_api/native/camera/include/camera_common_struct.h` | 相机公共结构体（Profile/CameraDevice/SceneMode 等） |
| `interfaces/inner_api/native/camera/include/input/camera_manager.h` | **CameraManager 内部 API**（GetInstance/GetSupportedCameras/CreateCameraInput/CreateCaptureSession） |
| `interfaces/inner_api/native/camera/include/input/camera_input.h` | CameraInput 内部 API（Open/Release/SetErrorCallback） |
| `interfaces/inner_api/native/camera/include/input/capture_input.h` | CaptureInput 抽象基类 |
| `interfaces/inner_api/native/camera/include/session/capture_session.h` | **CaptureSession 内部 API**（BeginConfig/AddInput/AddOutput/CommitConfig/Start/Stop/Release + Flash/Exposure/Focus/Zoom 等设置方法） |
| `interfaces/inner_api/native/camera/include/session/photo_session.h` | PhotoSession（继承 CaptureSession，拍照专用） |
| `interfaces/inner_api/native/camera/include/session/video_session.h` | VideoSession（继承 CaptureSession，录像专用） |
| `interfaces/inner_api/native/camera/include/session/secure_camera_session.h` | SecureCameraSession（安全相机） |
| `interfaces/inner_api/native/camera/include/session/control_center_session.h` | ControlCenterSession（控制中心会话） |
| `interfaces/inner_api/native/camera/include/output/photo_output.h` | PhotoOutput 内部 API（Capture/ConfirmCapture/CancelCapture） |
| `interfaces/inner_api/native/camera/include/output/preview_output.h` | PreviewOutput 内部 API（Start/Stop） |
| `interfaces/inner_api/native/camera/include/output/video_output.h` | VideoOutput 内部 API（Start/Stop） |
| `interfaces/inner_api/native/camera/include/output/metadata_output.h` | MetadataOutput 内部 API |
| `interfaces/inner_api/native/camera/include/output/capture_output.h` | CaptureOutput 抽象基类 |
| `interfaces/inner_api/native/camera/include/deferred_proc_session/deferred_photo_proc_session.h` | 延迟照片处理会话 |
| `interfaces/kits/js/camera_napi/@ohos.multimedia.camera.d.ts` | **JS 公开 API 声明**（CameraManager/CameraInput/CaptureSession/PhotoSession/VideoSession/各 Output） |
| `interfaces/kits/js/camera_napi/@ohos.multimedia.cameraPicker.d.ts` | CameraPicker 声明 |
| `interfaces/kits/native/include/camera/camera.h` | **Native API 基础定义**（Camera_ErrorCode 枚举 + 枚举/结构体） |
| `interfaces/kits/native/include/camera/camera_manager.h` | Native API CameraManager 接口（OH_CameraManager_*） |
| `interfaces/kits/native/include/camera/capture_session.h` | Native API CaptureSession 接口 |
| `interfaces/kits/native/include/camera/camera_input.h` | Native API CameraInput 接口 |
| `interfaces/kits/native/include/camera/photo_output.h` | Native API PhotoOutput 接口 |
| `interfaces/kits/native/include/camera/preview_output.h` | Native API PreviewOutput 接口 |
| `interfaces/kits/native/include/camera/video_output.h` | Native API VideoOutput 接口 |
| `interfaces/kits/native/include/camera/metadata_output.h` | Native API MetadataOutput 接口 |

### frameworks/js/camera_napi（NAPI 主实现）

| 文件 | 说明 |
|------|------|
| `frameworks/js/camera_napi/src/native_module_ohos_camera.cpp` | **模块注册入口**（Export() 注册所有 Napi 类，模块名 `multimedia.camera`） |
| `frameworks/js/camera_napi/src/native_module_ohos_camerapicker.cpp` | CameraPicker 模块注册 |
| `frameworks/js/camera_napi/src/input/camera_manager_napi.cpp` | **CameraManagerNapi**（getSupportedCameras/createCameraInput/createCaptureSession/createSession/createPreviewOutput/createPhotoOutput/createVideoOutput/createMetadataOutput） |
| `frameworks/js/camera_napi/src/input/camera_input_napi.cpp` | **CameraInputNapi**（open/close/release/on） |
| `frameworks/js/camera_napi/src/input/camera_napi.cpp` | CameraNapi（getCameraManager 静态方法） |
| `frameworks/js/camera_napi/src/session/camera_session_napi.cpp` | **CameraSessionNapi**（beginConfig/addInput/addOutput/commitConfig/start/stop/release + Flash/Exposure/Focus/Zoom/Beauty/Filter/ColorSpace 等设置方法，共 200+ 方法注册） |
| `frameworks/js/camera_napi/src/session/control_center_session_napi.cpp` | ControlCenterSessionNapi |
| `frameworks/js/camera_napi/src/mode/photo_session_napi.cpp` | **PhotoSessionNapi**（继承 CameraSessionNapi，CreateCameraSession 创建 PhotoSession） |
| `frameworks/js/camera_napi/src/mode/video_session_napi.cpp` | **VideoSessionNapi**（继承 CameraSessionNapi，CreateCameraSession 创建 VideoSession） |
| `frameworks/js/camera_napi/src/mode/secure_camera_session_napi.cpp` | SecureCameraSessionNapi |
| `frameworks/js/camera_napi/src/output/photo_output_napi.cpp` | **PhotoOutputNapi**（capture/burstCapture/release/on/isMirrorSupported/enableMirror/deferImageDelivery） |
| `frameworks/js/camera_napi/src/output/preview_output_napi.cpp` | **PreviewOutputNapi**（start/stop/release/on/addDeferredSurface） |
| `frameworks/js/camera_napi/src/output/video_output_napi.cpp` | **VideoOutputNapi**（start/stop/release/on/setFrameRate/enableMirror） |
| `frameworks/js/camera_napi/src/output/metadata_output_napi.cpp` | **MetadataOutputNapi**（start/stop/release/on/addMetadataObjectTypes） |
| `frameworks/js/camera_napi/src/output/photo_napi.cpp` | PhotoNapi（Photo 对象封装） |
| `frameworks/js/camera_napi/src/output/capture_photo_napi.cpp` | CapturePhotoNapi |
| `frameworks/js/camera_napi/src/output/quick_thumbnail_napi.cpp` | QuickThumbnailNapi（快速缩略图） |
| `frameworks/js/camera_napi/src/output/unify_movie_file_output_napi.cpp` | UnifyMovieFileOutputNapi |
| `frameworks/js/camera_napi/src/output/deferred_photo_proxy_napi.cpp` | DeferredPhotoProxyNapi（延迟照片代理） |
| `frameworks/js/camera_napi/src/output/video_capability_napi.cpp` | VideoCapabilityNapi |
| `frameworks/js/camera_napi/src/picker/camera_picker_napi.cpp` | **CameraPickerNapi**（pick 静态方法，拉起系统选择器 UI） |
| `frameworks/js/camera_napi/src/listener_base.cpp` | 事件监听基础设施 |
| `frameworks/js/camera_napi/src/camera_napi_utils.cpp` | NAPI 工具函数 |
| `frameworks/js/camera_napi/src/camera_napi_security_utils.cpp` | 权限校验工具 |
| `frameworks/js/camera_napi/src/camera_napi_metadata_utils.cpp` | 元数据工具 |
| `frameworks/js/camera_napi/src/dynamic_loader/camera_napi_ex_proxy.cpp` | 系统扩展 NAPI 代理（动态加载） |

### frameworks/native（C++ 实现层）

| 文件 | 说明 |
|------|------|
| `frameworks/native/camera/base/src/input/camera_manager.cpp` | **CameraManager C++ 实现**（GetSupportedCameras:2572 / CreateCameraInput:2721 / CreateCaptureSession） |
| `frameworks/native/camera/base/src/input/camera_input.cpp` | **CameraInput 实现**（Open:238 / Release） |
| `frameworks/native/camera/base/src/input/camera_device.cpp` | CameraDevice 实现 |
| `frameworks/native/camera/base/src/input/camera_info.cpp` | CameraInfo/CameraDevice 实现 |
| `frameworks/native/camera/base/src/session/capture_session.cpp` | **CaptureSession 实现**（BeginConfig:472 / CommitConfig:504 / Start:1655 / Stop:1677 / Release + Flash/Exposure/Focus/Zoom） |
| `frameworks/native/camera/base/src/session/photo_session.cpp` | PhotoSession 实现 |
| `frameworks/native/camera/base/src/session/video_session.cpp` | VideoSession 实现 |
| `frameworks/native/camera/base/src/session/secure_camera_session.cpp` | SecureCameraSession 实现 |
| `frameworks/native/camera/base/src/session/control_center_session.cpp` | ControlCenterSession 实现 |
| `frameworks/native/camera/base/src/output/photo_output.cpp` | **PhotoOutput 实现**（Capture:813） |
| `frameworks/native/camera/base/src/output/preview_output.cpp` | **PreviewOutput 实现**（Start:269） |
| `frameworks/native/camera/base/src/output/video_output.cpp` | **VideoOutput 实现**（Start:146） |
| `frameworks/native/camera/base/src/output/metadata_output.cpp` | MetadataOutput 实现 |
| `frameworks/native/camera/base/src/output/camera_output_capability.cpp` | CameraOutputCapability 实现 |
| `frameworks/native/camera/base/src/output/movie_file_output.cpp` | MovieFileOutput 实现 |
| `frameworks/native/camera/base/src/deferred_proc_session/` | 延迟处理会话实现 |
| `frameworks/native/camera/extension/include/session/` | 系统扩展会话头（Night/Portrait/Profession/SlowMotion/Cinematic/Macro/...） |
| `frameworks/native/xxx/impl/camera_manager_impl.cpp` | **Native API CameraManager 实现**（OH_CameraManager_*） |
| `frameworks/native/xxx/impl/capture_session_impl.cpp` | Native API CaptureSession 实现 |
| `frameworks/native/xxx/impl/camera_input_impl.cpp` | Native API CameraInput 实现 |
| `frameworks/native/xxx/impl/photo_output_impl.cpp` | xxx PhotoOutput 实现 |
| `frameworks/native/xxx/impl/preview_output_impl.cpp` | xxx PreviewOutput 实现 |
| `frameworks/native/xxx/impl/video_output_impl.cpp` | xxx VideoOutput 实现 |
| `frameworks/native/xxx/impl/camera_util.cpp` | **Native API 错误码映射**（FrameworkToxxxCameraError + frameworkToxxxErrorMap） |

### services（服务层，SA 进程）

| 文件 | 说明 |
|------|------|
| `services/camera_service/include/camera_util.h` | **CamServiceError 枚举**（服务内部错误码） + 工具函数 |
| `services/camera_service/include/hcamera_service.h` | HCameraService（SA 主服务） |
| `services/camera_service/include/hcamera_device_manager.h` | HCameraDeviceManager（设备管理，通过 HDF 访问硬件） |
| `services/camera_service/include/hcamera_device.h` | HCameraDevice（设备操作） |
| `services/camera_service/include/hcapture_session.h` | HCaptureSession（会话服务端实现） |
| `services/camera_service/include/hstream_capture.h` | HStreamCapture（拍照流） |
| `services/camera_service/include/hstream_repeat.h` | HStreamRepeat（预览/录像重复流） |
| `services/camera_service/include/hstream_metadata.h` | HStreamMetadata（元数据流） |
| `services/camera_service/include/hstream_operator.h` | HStreamOperator（流操作器） |
| `services/camera_service/binder/ + idls/` | IPC 接口定义（proxy/stub） |
| `services/deferred_processing_service/include/base/basic_definitions.h` | **DpsError 枚举**（延迟处理专用错误码） |

### common / dynamic_libs / mediastream / moviefile（支撑代码）

| 文件/目录 | 说明 |
|-----------|------|
| `common/include/` | 公共头文件（task_manager/timer） |
| `common/utils/` | 工具类（camera_notification/media_manager/media_stream/movie_file/moving_photo/watermark_exif_metadata/xcomponent_controller/camera_extend） |
| `dynamic_libs/` | 动态库封装层（av_codec/image_framework/image_effect/media_library/media_manager/moving_photo/watermark_exif_metadata/xcomponent_controller/camera_notification/dfx） |
| `mediastream/include/ + src/` | 媒体流框架（buffer/filter/pipeline/util） |
| `moviefile/include/ + src/` | MovieFile 封装与 pipeline |

## 分层调用关系

```
JS 应用层 (@ohos.multimedia.camera)
    ↓ napi
NAPI 层 (frameworks/js/camera_napi) — CameraManagerNapi/CameraSessionNapi/PhotoOutputNapi/...
    ↓ 直接持有 inner API 对象引用
内部 C++ API 层 (interfaces/inner_api) — CameraManager/CaptureSession/PhotoOutput/...
    ↓ 调用实现
C++ 实现层 (frameworks/native/camera/base) — CameraManager::/CaptureSession::/PhotoOutput::
    ↓ IPC (binder proxy)
相机服务层 (services/camera_service) — HCameraService/HCameraDeviceManager/HCaptureSession
    ↓ HDF IPC
HAL 层 (drivers_interface_camera) — Camera Device HAL
```

xxx 路径：`C API (interfaces/kits/native) → xxx 实现 (frameworks/native/xxx/impl) → 内部 C++ API → C++ 实现 → IPC → 服务`
