# multimedia_camera_framework 常见问题模式

## 1. 权限问题

### 1.1 错误码 201 — CAMERA 权限被拒

- **现象**：调用任何相机 API（getCameraManager/getSupportedCameras/createCameraInput/open 等）时抛出 `BusinessError 201: Permission denied.`
- **原因**：
  - 应用未在 `module.json5` 的 `requestPermissions` 中声明 `ohos.permission.CAMERA`。
  - 声明了但用户未授权（`ohos.permission.CAMERA` 是 user_grant 级权限，需运行时弹窗授权）。
  - 录像场景还可能缺少 `ohos.permission.MICROPHONE`。
- **排查思路**：
  1. 检查 `module.json5` 中是否声明了 `ohos.permission.CAMERA`。
  2. 确认是否通过 `@ohos.abilityAccessCtrl`（`requestPermissionsFromUser`）在运行时请求授权。
  3. 在 DevEco Studio 的 Log 中搜索 `permission` 或 `201` 确认缺失的权限。
  4. xxx 侧：注意 Native API C 接口**不返回 201**，无相机权限时会返回 `CAMERA_SERVICE_FATAL_ERROR(7400201)`，需额外检查 `accessToken`。

### 1.2 错误码 202 — 非系统应用调用系统 API

- **现象**：调用标记了 `@systemapi` 的 API 时抛出 `BusinessError 202: Not System Application` 或 `Permission verification failed. A non-system application calls a system API.`
- **原因**：调用了仅供系统应用使用的 API（如 `CameraManager.setPrelaunchConfig`、`CameraManager.muteCamera`、部分 session 的扩展能力等）。
- **排查思路**：
  1. 查阅 d.ts 中该 API 是否标注 `@systemapi`。
  2. 确认应用是否为系统应用（签名级别 / `hasSystemApi` 权限）。
  3. xxx 侧：系统 API 限制在 xxx 中表现为 `CAMERA_OPERATION_NOT_ALLOWED(7400102)`。

---

## 2. 参数错误

### 2.1 错误码 401 — NAPI 层参数错误

- **现象**：抛出 `BusinessError 401: Parameter error.` 附带原因描述（参数验证失败/必填参数缺失/参数类型不正确）。
- **原因**：
  - 传入参数数量不匹配、类型不正确（如传字符串给期望 number 的参数）。
  - 必填参数为 undefined/null。
  - surfaceId 格式不正确（createPreviewOutput/createPhotoOutput/createVideoOutput 需要 XComponent 的 surfaceId）。
- **排查思路**：
  1. 对照 d.ts 中 API 签名检查参数类型和数量。
  2. 确认 surfaceId 来自 `XComponent.getXComponentSurfaceId()` 且不为空。
  3. 检查 Profile 对象是否从 `getSupportedOutputCapability` 获取（不要手搓）。

### 2.2 错误码 7400101 — INVALID_ARGUMENT

- **现象**：抛出 `BusinessError 7400101: Parameter missing or parameter type incorrect.`
- **原因**：
  - 传入的业务对象无效（如 CameraDevice 为 null、Profile 的 format/size 不被设备支持）。
  - CameraInput 对象已被 release 后仍传入 addInput。
  - 与 401 的区别：401 是 NAPI 解析阶段的参数验证，7400101 是 framework 层的业务对象有效性验证。
- **排查思路**：
  1. 确保传入的 Camera/Profile/CameraInput 等对象来自有效的 API 调用。
  2. 对照 `getSupportedOutputCapability` 返回的能力列表检查 Profile 是否在支持范围内。
  3. 确认对象生命周期未过期（未被 release）。

---

## 3. 会话状态错误

### 3.1 错误码 7400103 — SESSION_NOT_CONFIG（会话未配置）

- **现象**：调用 `session.start()` 或某些设置方法时抛出 `7400103: Session not config.`
- **原因**：会话未完成配置流程（beginConfig → addInput → addOutput → commitConfig）就尝试启动。
- **排查思路**：
  1. 确保遵循正确的流程：`beginConfig()` → `addInput(cameraInput)` → `addOutput(xxxOutput)` → `commitConfig()` → `start()`。
  2. 检查 `commitConfig()` 的 Promise/回调是否成功返回后再调 `start()`。
  3. 查看 `CaptureSession::Start()` 源码中的 `IsSessionCommited()` 检查（capture_session.cpp:1661）。

### 3.2 错误码 7400104 — SESSION_NOT_RUNNING（会话未运行）

- **现象**：调用 `photoOutput.capture()` 或某些操作时抛出 `7400104: Session not running.`
- **原因**：会话未 `start()` 或已 `stop()` 后尝试执行需要运行态的操作。
- **排查思路**：
  1. 确认 `session.start()` 已成功返回。
  2. 检查是否有错误回调导致会话被意外停止。
  3. 确认在 capture 前会话未被 `stop()` 或 `release()`。

### 3.3 错误码 7400105 — SESSION_CONFIG_LOCKED（配置已锁定）

- **现象**：调用 `addInput/addOutput` 时抛出 `7400105: Session config locked.`
- **原因**：`commitConfig()` 成功后会话进入锁定状态，修改输入/输出必须先重新 `beginConfig()`。
- **排查思路**：
  1. 修改会话配置前，先调用 `session.beginConfig()` 解锁。
  2. 修改完成后再次 `commitConfig()`。

### 3.4 错误码 7400106 — DEVICE_SETTING_LOCKED（设备设置已锁定）

- **现象**：设置闪光灯/曝光/对焦等参数时返回 `7400106: Device setting locked.`
- **原因**：未调用 `lockForControl()` 就直接设置参数，或参数设置后未 `unlockForControl()`。CaptureSession 使用 lockForControl/unlockForControl 包裹参数设置。
- **排查思路**：
  1. 设置参数前调用 `session.lockForControl()`。
  2. 设置完所有参数后调用 `session.unlockForControl()` 使设置生效。
  3. 注意：此码在 d.ts 枚举中存在但未在 @throws 中显式声明，实际可能以 7400102 形式返回。

---

## 4. 设备冲突与抢占

### 4.1 错误码 7400107 — CONFLICT_CAMERA（相机冲突）

- **现象**：创建 CameraInput/open/commitConfig/start 时抛出 `7400107: Can not use camera cause of conflict.`
- **原因**：
  - 另一个高优先级应用（如系统相机）正在使用同一相机。
  - 两个应用同时尝试打开同一相机。
  - 多摄场景中请求的相机组合存在冲突。
- **排查思路**：
  1. 确认无其它应用占用相机（检查是否有其它相机进程运行）。
  2. 确保上一次会话已正确 `release()`。
  3. 检查是否有僵尸会话未释放（camera_service 可能仍持有引用）。
  4. 多摄场景确认相机组合被设备支持。

### 4.2 错误码 7400108 — DEVICE_DISABLED（设备被禁用）

- **现象**：`7400108: Camera disabled cause of security reason.`
- **原因**：
  - 相机被系统策略禁用（安全模式/MDM 管理策略/企业限制）。
  - 相机被 `muteCamera(true)` 永久静音。
  - 设备处于特定安全场景（如安全桌面/安全键盘弹出）。
- **排查思路**：
  1. 检查是否有 MDM 策略限制相机。
  2. 确认设备未处于安全模式。
  3. 查询 `CameraManager.isCameraMuted()` 确认是否被静音。

### 4.3 错误码 7400109 — DEVICE_PREEMPTED（设备被抢占）

- **现象**：会话运行中突然收到 `7400109` 错误回调（通常通过 `CameraInput.on('error')` 或 session error 事件）。
- **原因**：
  - 运行中另一个更高优先级的客户端抢占了相机资源。
  - 系统相机（系统应用）启动导致低优先级应用被抢占。
- **排查思路**：
  1. 监听 CameraInput 的 error 事件，收到 7400109 时清理会话资源。
  2. 在应用重新获焦时尝试重新打开相机。
  3. 注意：此码在 d.ts 枚举中存在但未在 @throws 中显式声明，主要通过 error 回调传递。

### 4.4 错误码 7400111 — DEVICE_SWITCH_FREQUENT（频繁切换）

- **现象**：内部错误码（内部头文件定义），开发者可能看到 7400102 或 7400201。
- **原因**：设备在短时间内频繁切换（如快速反复 open/close 相机）。
- **排查思路**：
  1. 避免短时间内反复打开/关闭相机。
  2. 合理管理相机生命周期，复用会话。

### 4.5 错误码 7400112 — CAMERA_LENS_RETRACTED（镜头收回）

- **现象**：内部错误码，可伸缩镜头设备的镜头被收回（如跌落保护触发）。
- **原因**：设备检测到跌落/震动，自动收回可伸缩镜头以保护硬件。
- **排查思路**：
  1. 提示用户镜头已收回，需等待镜头恢复。
  2. 监听设备状态变化，镜头恢复后重新尝试。

---

## 5. 操作不被允许

### 5.1 错误码 7400102 — OPERATION_NOT_ALLOWED

- **现象**：抛出 `7400102: Operation not allowed.`
- **原因**（内部有 4 个子码，经 errorCodeMap 映射回 7400102）：
  - **74001021 SESSION_READY**：会话未就绪（如未 start 就 capture）。
  - **74001022 UNSUPPORTED_FEATURE**：当前设备/会话不支持该特性（如无闪光灯设备设闪光灯模式）。
  - **74001023 DEVICE**：设备原因（如设备忙/设备异常）。
  - **74001024 DEVICE_CONFLICT**：设备冲突。
  - xxx 侧还将 NO_SYSTEM_APP_PERMISSION(202) 也映射为 CAMERA_OPERATION_NOT_ALLOWED(7400102)。
- **排查思路**：
  1. 确认会话处于正确状态（已 start/已 commit）。
  2. 查阅 `getSupportedOutputCapability` 确认目标能力是否被设备支持。
  3. 确认无设备冲突。
  4. xxx 场景：确认应用是否为系统应用（非系统应用调用系统 API 也会返回 7400102）。

---

## 6. 流配置冲突

### 6.1 错误码 7400110 — UNRESOLVED_CONFLICTS_BETWEEN_STREAMS

- **现象**：`commitConfig()` 时抛出 `7400110: Unresolved conflicts with current configurations.`（since 12）
- **原因**：当前流组合（如同时 Preview + Photo + Video + Metadata）不被设备 HAL 支持，存在资源冲突（如管线/带宽/传感器能力限制）。
- **排查思路**：
  1. 减少 session 中同时配置的输出流数量。
  2. 确认输出流组合在设备能力范围内（参考 `getSupportedOutputCapability`）。
  3. 尝试降低分辨率或帧率。
  4. 拍照和录像通常不能在同一 session 同时配置（取决于设备能力）。

---

## 7. 服务致命错误

### 7.1 错误码 7400201 — SERVICE_FATAL_ERROR

- **现象**：抛出 `7400201: Camera service fatal error.` 或通过 error 回调收到此码。
- **原因**（内部有 5 个子码，经 errorCodeMap 映射回 7400201）：
  - **74002011 CONFIG**：配置阶段致命错误（如 HAL 配置流失败）。
  - **74002012 ALLOC**：资源分配致命错误（如 buffer 分配失败）。
  - **74002013 INVALID_SESSION_CFG**：无效会话配置（如流参数非法）。
  - **74002014 INPUT_DEVICE**：输入设备异常（如 camera device 打开失败/断连）。
  - **74002015 SERVICE_NULL**：服务对象为空（IPC 获取 camera_service 失败，服务进程未启动/已崩溃）。
  - **xxx 特殊情况**：xxx 侧 `201`（无 CAMERA 权限）也通过此码返回，因为 C 接口不区分权限码。
- **排查思路**：
  1. **首先检查权限**：确认已获得 `ohos.permission.CAMERA`（特别是 xxx 场景，7400201 可能就是权限缺失）。
  2. **检查 camera_service 进程**：通过 `hilog` 搜索 `HCameraService` 确认服务是否正常运行，可能需要重启设备。
  3. **检查 HDF 层**：搜索 `drivers_interface_camera` 相关日志，确认 HAL 是否正常加载。
  4. **检查 IPC 连接**：如果频繁出现 74002015(SERVICE_NULL)，可能是 binder 连接超时或服务崩溃。
  5. **设备状态**：确认相机硬件正常（无物理损坏/被占用）。
  6. 收到此错误后应释放当前会话并重新创建。

---

## 8. 能力/组合不支持

### 8.1 错误码 7400801 — CAPABILITY_NOT_SUPPORTED（内部码）

- **现象**：内部头文件定义的错误码（不在 d.ts 公开声明中），调用不支持的能力时触发。
- **xxx 映射**：xxx 侧映射为 `CAMERA_ERROR_CAPABILITY_NOT_SUPPORTED = 7400114`（数值不同）。
- **原因**：设备硬件不支持请求的能力（如特定分辨率/帧率/色彩空间/变焦范围）。
- **排查思路**：
  1. 通过 `getSupportedOutputCapability` / `hasFlash` / `isFlashModeSupported` 等查询方法确认能力支持情况。
  2. 不要硬编码分辨率/格式，始终从设备能力查询获取。

### 8.2 错误码 7400113 — UNSUPPORTED_MULTI_CAMERA_COMBINATION（内部码）

- **现象**：内部头文件定义，d.ts 未公开声明。
- **注意**：xxx 侧 `camera.h` 将 7400113 重定义为 `CAMERA_ERROR_OPTIONAL_PROPERTY_NOT_EXIST`（可选属性不存在），与内部语义不同。
- **原因**：请求的多摄组合（如同时使用广角+长焦+超广角）不被设备支持。
- **排查思路**：
  1. 通过 `getCameraConcurrentInfos` 查询支持的并发相机组合。
  2. 减少同时使用的相机数量。

---

## 9. 其它常见问题模式

### 9.1 异步方法未正确使用 Promise/回调

- **现象**：API 调用后无响应或操作顺序混乱。
- **原因**：commitConfig/start/capture/open 等方法为异步，未 await Promise 或未在回调中执行后续操作。
- **排查思路**：
  1. 使用 `async/await` 或正确链式调用 `.then()`。
  2. 确保在 commitConfig 成功后才 start，在 start 成功后才 capture。

### 9.2 surfaceId 为空或无效

- **现象**：createPreviewOutput/createPhotoOutput/createVideoOutput 失败，返回 401/7400101。
- **原因**：XComponent 尚未完成初始化，surfaceId 未生成。
- **排查思路**：
  1. 在 XComponent 的 `onLoad` 回调中获取 surfaceId。
  2. 确认 surfaceId 不为空字符串后再传入。

### 9.3 延迟拍照相关

- **现象**：PhotoOutput 的 `deferImageDelivery` 后无法获取高质量照片。
- **原因**：延迟处理服务（DPS）未正常工作或图片处理超时（DpsError 码 3-8）。
- **排查思路**：
  1. 检查 `isDeferredImageDeliverySupported` 确认设备支持。
  2. 监听 DPS 回调中的错误码（DPS_ERROR_IMAGE_PROC_*）。
  3. 确认 deferred_processing_service 进程正常运行。
