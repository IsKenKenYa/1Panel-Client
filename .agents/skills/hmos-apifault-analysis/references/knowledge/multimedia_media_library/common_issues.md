# multimedia_media_library 常见问题模式

> 错误码源：`interface_sdk-js/api/@ohos.file.photoAccessHelper.d.ts`（@throws）、`interfaces/inner_api/media_library_helper/include/media_library_error_code.h`、`frameworks/js/src/napi_error.cpp`（内部 E_ 常量运行时映射）

## 一、权限问题（最高频）

### 201 Permission denied（令牌层，206 次）

- **触发**：缺 `READ_IMAGEVIDEO` / `WRITE_IMAGEVIDEO` / `SHORT_TERM_WRITE_IMAGEVIDEO` / `MANAGE_PRIVATE_PHOTOS` / `ACCESS_MEDIALIB_THUMB_DB`。
- **典型接口**：几乎所有 getAlbums/createAsset/open/getThumbnail/applyAssets。
- **排查**：检查 module.json5 `requestPermissions`；READ/WRITE_IMAGEVIDEO 为 user_grant，需运行时 `abilityAccessCtrl.requestPermissionsFromUser` 动态申请；SHORT_TERM 是短期令牌（相机等场景）。
- **源码**：`napi_error.cpp` E_PERMISSION_DENIED → 201；权限校验位于 DataShare Extension 与 media_permission_helper。

### 202 Called by non-system application（251 次）

- **触发**：调用标注 `systemapi` 的接口（云端同步、隐藏相册、getAllPeers/getPeerDevices、主动分析）。
- **排查**：应用是否为系统应用（签名+特权配置）。三方应用应改用公开 API 或 Picker 组件。
- **源码**：d.ts `@systemapi` 标注 + ability 校验。

### 14000002 数据库权限不足

- **触发**：令牌权限通过，但 DataShare/RDB 层二次校验失败（如跨用户访问、沙箱越界）。
- **排查**：核对 INTERACT_ACROSS_LOCAL_ACCOUNTS；检查 uri 是否指向本应用可见范围。
- **源码**：napi_error.cpp E_PERMISSION_DENIED 数据库分支。

### 13900012 文件系统层 EACCES

- **触发**：open 返回 fd 后文件系统拒绝（SELinux、路径越界）。
- **排查**：hilog 搜 avc denied；确认资产路径属于媒体库可见域。

## 二、参数问题

### 401 Parameter error（261 次）

- **触发**：必填缺失、类型不匹配、枚举越界。
- **排查**：对照 d.ts 参数表；注意 callback 与 Promise 双形式不可混用；fetchOptions 的 predicates 需为合法 DataSharePredicates。
- **源码**：napi_error.cpp E_PARAM_INVALID → 401。

### 13900020 EINVAL（文件系统层，168 次）

- **触发**：路径/参数在文件系统层非法（不支持后缀、非法分隔符）。
- **源码**：E_PATH_NOT_SUPPORT / E_FILE_EXTENSION 映射。

### 23800151 Scene parameters validate failed

- **触发**：场景相册/主动分析参数非法（时间范围、地理范围、阈值）。
- **排查**：对照 analysis album 接口约束。
- **源码**：`media_library_error_code.h:22` MEDIA_LIBRARY_INVALID_PARAMETER_ERROR。

### 14000001 Invalid parameter value

- **触发**：参数值本身非法（如 displayName 含非法字符、相册名超长）。区别于 401 的缺失/类型。
- **源码**：d.ts createAsset `@throws 14000001`。

## 三、内部错误（媒体层最高频）

### 14000011 System inner fail（264 次，最常见媒体错误）

- **触发**：DataShare/RDB/IPC 层内部失败——数据库异常、扩展进程崩溃、IPC 调用失败、服务端处理失败。
- **典型场景**：applyAssets、createAlbum、commitModify、getAlbums 分页。
- **排查**：①hilog 搜 `MediaLibrary` / `DataShare` / tag=medialibrary；②看 hisysevent 是否有 FAULT；③重试（瞬时性）；④检查 DataShare Extension 是否正常加载。
- **源码**：napi_error.cpp E_INNER_FAIL → 14000011。

### 23800301 Internal system error（137 次）

- **触发**：媒体库服务内部系统错误（IPC 断连、RDB 严重故障）。官方建议重试 + 查日志。
- **源码**：`media_library_error_code.h:32` MEDIA_LIBRARY_INTERNAL_SYSTEM_ERROR。

### 14000016 Database operation fail

- **触发**：RDB 增删改查执行失败（约束冲突、SQL 错误、事务异常）。
- **排查**：通常伴随 14000011；检查是否有重复主键、外键悬空。

## 四、相册场景问题

### 14000014 Album invalid / not exist

- **触发**：目标相册不存在、已删除、或 PhotoKey 属性名非法。
- **典型**：场景相册 createAlbum/commitModify/getAlbums(member)。
- **源码**：E_SCENE_ALBUM_NOT_EXIST。

### 场景相册状态错误（E_ 常量，运行时映射）

- `E_SCENE_HAS_CANCEL` / `E_SCENE_HAS_DELETED`（14000014 类）— 相册已被取消/删除后再操作。
- `E_SCENE_HAS_RENAMED`（E_RENAME 类）— 相册已重命名导致引用失效。
- `E_SCENE_IS_CLOUD` / `E_SCENE_IS_HIDDEN` — 相册为云相册/隐藏相册，本地操作受限。
- **排查**：操作前用 getAlbums 校验相册仍在且类型匹配。

## 五、文件操作问题

### 13900002 No such file or directory

- **触发**：open/getThumbnail 时底层文件已删除或路径错误。
- **排查**：资产可能已被并发删除；先 get 确认状态。
- **源码**：E_FILE_NOT_EXIST。

### 13900015 File exists / E_FILE_OPER_FAIL

- **触发**：createAsset 目标已存在；或文件操作（拷贝/移动）失败。
- **排查**：检查目标 displayName 唯一性；移动跨卷时确认空间。

### E_SCENE_NO_ENOUGH_SPACE 空间不足

- **触发**：拷贝/创建/移动时存储不足（场景相册重建尤甚）。
- **排查**：检查剩余空间；主动分析也可能抛 23800205。

## 六、媒体类型 / 扩展名校验

### E_CHECK_MEDIATYPE_FAIL / E_MEDIA_TYPE

- **触发**：声明的媒体类型与文件实际不符（声明 IMAGE 但内容是视频）。
- **源码**：napi_error.cpp 映射到 14000001/13900020。

### E_FILE_EXTENSION / E_CHECK_EXTENSION_FAIL / E_CHECK_MEDIATYPE_MATCH_EXTENSION_FAIL

- **触发**：后缀不在白名单（如 .heic/.mov 之外）；后缀与声明类型不匹配。
- **排查**：对照 supportedExtensions；相机/相册写入需用受支持后缀。

## 七、能力 / 设备

### 801 Capability not supported

- **触发**：接口在当前设备/系统版本不可用（small 设备常受限）。
- **排查**：查 d.ts `@syscap` 与设备 profile。

## 八、并发与批量操作

### 大批量 applyChanges 失败

- **触发**：单次提交过多 ChangeRequest（移动/拷贝数百张），DataShare 事务超时或内存不足 → 14000011/14000016。
- **排查**：分批提交（如每批 ≤50）；用计数器跟踪成功项。

### FetchResult 未关闭

- **触发**：忘调 close()，ResultSet 句柄泄漏，后续查询 RDB 锁或句柄耗尽。
- **排查**：finally 中 close；不要用 getAllObject 处理大数据量。

### Moving Photo / 双文件一致性

- **触发**：动态照片由 image+video 双文件组成，applyChanges 仅写其一 → 23800301 或获取失败。
- **排查**：用 createImageAssetRequest 配合 MovingPhoto 专用接口保证原子性。

## 快速诊断清单

| 现象           | 首查错误码                | 次查方向                           |
| -------------- | ------------------------- | ---------------------------------- |
| 三方应用报错   | 201 / 202                 | 权限声明 + 动态申请 / 是否系统应用 |
| 参数错         | 401 / 13900020 / 14000001 | d.ts 参数表 / 后缀白名单           |
| 一切正常却失败 | 14000011 / 23800301       | hilog + hisysevent + 重试          |
| 相册操作异常   | 14000014                  | 相册存在性 / 场景状态 E_ 常量      |
| 文件打不开     | 13900002 / 13900012       | 资产是否被删 / SELinux             |
| 主动分析不工作 | 23800203~209              | 温度/电量/存储/省电/开关           |
