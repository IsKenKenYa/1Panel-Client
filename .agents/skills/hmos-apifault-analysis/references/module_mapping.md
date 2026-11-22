# 模块映射表

本文件包含 6 个子映射表格，用于将不同来源的信号（错误码、DOMAIN、.so 库名、API 名称、hilog domain_id）映射到具体的模块，以及模块到代码仓/文档仓 URL 的映射。

**注意：** d.ts 声明名、文档仓 kit 名、代码仓目录名、开发指南目录名之间无机械对应关系，每个子映射需独立维护。

## 目录

本文件含 6 张子映射表（信号→模块）+ 1 个附录：

1. 错误码前缀 → Kit名 → 模块名
2. DOMAIN 标识 → 代码仓
3. .so 库名 → 模块名
4. API 名称前缀 → 模块名
5. hilog domain_id → 模块名
6. 模块名 → 代码仓与文档 URL

- 未识别信号处理指引（附录）

---

## 1. 错误码前缀 → Kit名 → 模块名

用于错误码驱动型问题的模块识别。从问题输入中提取的错误码数字按前缀匹配。

| 错误码前缀        | Kit名           | 模块名                                        | 代码仓目录名                                  |
| ----------------- | --------------- | --------------------------------------------- | --------------------------------------------- |
| 6600xxx / 661xxxx | AVCodecKit      | multimedia_av_session                         | multimedia_av_session                         |
| 5400xxx / 541xxxx | MediaKit        | multimedia_player_framework                   | multimedia_player_framework                   |
| 6800xxx           | AudioKit        | multimedia_audio_framework                    | multimedia_audio_framework                    |
| 7400xxx           | CameraKit       | multimedia_camera_framework                   | multimedia_camera_framework                   |
| 1600xxx           | AbilityKit      | ability_ability_runtime                       | ability_ability_runtime                       |
| 16000xx           | AbilityKit      | ability_ability_runtime（UIAbility）          | ability_ability_runtime                       |
| 3301xxx           | LocationKit     | base_location                                 | base_location                                 |
| 8300xxx           | TelephonyKit    | telephony                                     | telephony_core_service                        |
| 166xxx            | AbilityKit      | ability_dmsfwk                                | ability_dmsfwk                                |
| 167xxx            | AbilityKit      | ability_dmsfwk                                | ability_dmsfwk                                |
| 165xxx            | AbilityKit      | ability_form_fwk                              | ability_form_fwk                              |
| 218xxx            | AdsKit          | advertising_ads_framework                     | advertising_ads_framework                     |
| 173xxx            | AdsKit          | advertising_oaid                              | advertising_oaid                              |
| 171xxx            | ArkWeb          | web_webview                                   | web_webview                                   |
| 299xxx            | AbilityKit      | bundlemanager_app_domain_verify               | bundlemanager_app_domain_verify               |
| 177xxx            | AbilityKit      | bundlemanager_bundle_framework                | bundlemanager_bundle_framework                |
| 310xxx            | ConnectivityKit | communication_connected_nfc_tag               | communication_connected_nfc_tag               |
| 349xxx            | ConnectivityKit | communication_fusion_connectivity             | communication_fusion_connectivity             |
| 210xxx            | NetworkKit      | communication_netmanager_base                 | communication_netmanager_base                 |
| 220xxx / 294xxx   | NetworkKit      | communication_netmanager_ext                  | communication_netmanager_ext                  |
| 290xxx            | ConnectivityKit | connectivity_connectivity_cangjie_wrapper     | connectivity_connectivity_cangjie_wrapper     |
| 154xxx            | ArkData         | distributeddatamgr_data_object                | distributeddatamgr_data_object                |
| 151xxx            | ArkData         | distributeddatamgr_kv_store                   | distributeddatamgr_kv_store                   |
| 155xxx            | ArkData         | distributeddatamgr_preferences                | distributeddatamgr_preferences                |
| 148xxx            | ArkData         | distributeddatamgr_relational_store           | distributeddatamgr_relational_store           |
| 135xxx / 139xxx   | CoreFileKit     | filemanagement_app_file_service               | filemanagement_app_file_service               |
| 143xxx            | CoreFileKit     | filemanagement_app_file_service（fileshare）  | filemanagement_app_file_service               |
| 139xxx            | CoreFileKit     | filemanagement_file_api                       | filemanagement_file_api                       |
| 224xxx            | CoreFileKit     | filemanagement_file_api（DistributedFile）    | filemanagement_file_api                       |
| —                | CoreFileKit     | filemanagement_dfs_service                    | filemanagement_dfs_service                    |
| —                | CoreFileKit     | filemanagement_user_file_service              | filemanagement_user_file_service              |
| —                | CoreFileKit     | filemanagement_filemanagement_cangjie_wrapper | filemanagement_filemanagement_cangjie_wrapper |
| 140xxx / 238xxx   | MediaLibraryKit | multimedia_media_library                      | multimedia_media_library                      |
| 121xxx            | AbilityKit      | security_access_token                         | security_access_token                         |
| 293xxx            | AbilityKit      | security_access_token（EL5）                  | security_access_token                         |
| 201 / 202         |                 | 通用权限错误（跨模块）                        | —                                            |
| 401               |                 | 通用参数错误（跨模块）                        | —                                            |

**使用规则：**

- 取错误码的前 4-7 位进行匹配，优先匹配最长的前缀
- 201/202/401 为通用错误码，不直接指向特定模块，需结合其它线索判断
- 若错误码无匹配的前缀，标注"模块未识别"
- 前缀列为「—」的行无专属错误码前缀，不参与前缀匹配；其 Kit名 仅用于「模块名 → Kit名」反查（本表「模块名」列即为该反查索引，模块经 .so/API/DOMAIN 等信号识别后，按阶段 1 步骤 2.1 反查 Kit名）

---

## 2. DOMAIN 标识 → 代码仓

用于崩溃/冻屏日志的模块识别。HiviewDFX 日志中的 DOMAIN 字段对应子系统。

| DOMAIN           | 子系统                     | 代码仓目录名                    |
| ---------------- | -------------------------- | ------------------------------- |
| AAFWK            | Ability Framework          | ability_ability_runtime         |
| ARKCOMPILER      | ArkCompiler                | arkcompiler_ets_runtime         |
| ACE              | ArkUI Engine               | arkui_ace_engine                |
| WINDOW           | Window Manager             | window_window_manager           |
| MULTIMEDIA       | Multimedia（多种模块）     | multimedia_*                    |
| AUDIO            | Audio                      | multimedia_audio_framework      |
| PLAYER           | Player                     | multimedia_player_framework     |
| DISTRIBUTED      | Distributed                | distributedhardware_*           |
| ACCOUNT          | Account                    | os_account                      |
| BUNDLE           | Bundle Manager             | bundlemanager_bundle_framework  |
| BUNDLEMANAGER_UE | Bundle Manager（故障事件） | bundlemanager_bundle_framework  |
| BUNDLE_MANAGER   | Bundle Manager（行为事件） | bundlemanager_bundle_framework  |
| NETWORK          | Network                    | communication_netstack          |
| BLUETOOTH        | Bluetooth                  | communication_bluetooth         |
| WIFI             | Wi-Fi                      | communication_wifi              |
| TELEPHONY        | Telephony                  | telephony_core_service          |
| LOCATION         | Location                   | base_location                   |
| GRAPHIC          | Graphic                    | graphic_graphic_2d              |
| HDF              | Hardware Driver            | drivers_*                       |
| DISTRIBUTEDDATA  | Distributed Data           | distributeddatamgr_*            |
| FILEMANAGEMENT   | File Management            | filemanagement_*                |
| MEDIA_LIBRARY    | Media Library              | multimedia_media_library        |
| ACCESS_TOKEN     | Access Token               | security_access_token           |
| WEB              | Web                        | web_webview                     |
| NFC              | NFC                        | communication_connected_nfc_tag |
| ADS              | Advertising                | advertising_ads_framework       |
| OAID             | OAID                       | advertising_oaid                |
| FORM             | Form                       | ability_form_fwk                |
| DMSFWK           | Distributed Manager        | ability_dmsfwk                  |
| COLLIE           | HiCollie                   | hiviewdfx_hicollie              |
| NETMANAGER       | Network Manager            | communication_netmanager_*      |

**使用规则：**

- DOMAIN 为大写标识，从 HiviewDFX 日志的 `DOMAIN` 字段提取
- MULTIMEDIA DOMAIN 需结合 .so 库名进一步区分具体模块
- 若 DOMAIN 不在映射表中，保留 DOMAIN 值用于后续 WebSearch 搜索

---

## 3. .so 库名 → 模块名

用于崩溃/冻屏日志调用栈中的模块识别。从 `#NN pc <addr> <lib_path>` 格式中提取。

| .so 库名                  | 模块名                              | 代码仓目录名                        |
| ------------------------- | ----------------------------------- | ----------------------------------- |
| libavsession.so           | multimedia_av_session               | multimedia_av_session               |
| libohavsession.so         | multimedia_av_session               | multimedia_av_session               |
| libmedia_avplayer.so      | multimedia_player_framework         | multimedia_player_framework         |
| libmedia_soundpool.so     | multimedia_player_framework         | multimedia_player_framework         |
| libmedia_helper_client.so | multimedia_player_framework         | multimedia_player_framework         |
| libaudio_haptic.so        | multimedia_player_framework         | multimedia_player_framework         |
| libplayer.so              | multimedia_player_framework         | multimedia_player_framework         |
| libaudio_*.so             | multimedia_audio_framework          | multimedia_audio_framework          |
| libcamera.so              | multimedia_camera_framework         | multimedia_camera_framework         |
| libace.so                 | arkui_ace_engine                    | arkui_ace_engine                    |
| libark_jsruntime.so       | arkcompiler_ets_runtime             | arkcompiler_ets_runtime             |
| libability_manager.so     | ability_ability_runtime             | ability_ability_runtime             |
| liblocation_sdk.so        | base_location                       | base_location                       |
| libbluetooth.so           | communication_bluetooth             | communication_bluetooth             |
| libwifi_sdk.so            | communication_wifi                  | communication_wifi                  |
| libbundle_manager.so      | bundlemanager_bundle_framework      | bundlemanager_bundle_framework      |
| libbundle_installer.so    | bundlemanager_bundle_framework      | bundlemanager_bundle_framework      |
| libbackup.so              | filemanagement_app_file_service     | filemanagement_app_file_service     |
| libdatashare.so           | distributeddatamgr_data_share       | distributeddatamgr_data_share       |
| libkv_store.so            | distributeddatamgr_kv_store         | distributeddatamgr_kv_store         |
| libpreferences.so         | distributeddatamgr_preferences      | distributeddatamgr_preferences      |
| librdb.so                 | distributeddatamgr_relational_store | distributeddatamgr_relational_store |
| libdata_object.so         | distributeddatamgr_data_object      | distributeddatamgr_data_object      |
| libmedia_library.so       | multimedia_media_library            | multimedia_media_library            |
| libphoto_access_helper.so | multimedia_media_library            | multimedia_media_library            |
| libwebview.so             | web_webview                         | web_webview                         |
| libnfc_tag.so             | communication_connected_nfc_tag     | communication_connected_nfc_tag     |
| libnet_manager.so         | communication_netmanager_base       | communication_netmanager_base       |
| libhicollie.so            | hiviewdfx_hicollie                  | hiviewdfx_hicollie                  |
| libform_manager.so        | ability_form_fwk                    | ability_form_fwk                    |
| libdistributed_manager.so | ability_dmsfwk                      | ability_dmsfwk                      |
| libaccess_token.so        | security_access_token               | security_access_token               |
| libdrawing.so             | graphic_graphic_2d                  | graphic_graphic_2d                  |

**系统库（不直接指向业务模块）：**

- `libace.so` — ArkUI 引擎（跨模块通用）
- `libark_jsruntime.so` — JS 运行时（跨模块通用）
- `libc.so` / `libm.so` — C 标准库
- `libhilog.so` — 日志库

**使用规则：**

- 从调用栈最底层（#00）的非系统库开始分析
- 若调用栈中多个 .so 同时出现，优先分析 #00 附近的业务库
- 库名支持通配符匹配（如 `libaudio_*.so`）

---

## 4. API 名称前缀 → 模块名

用于 API 调用异常型问题的模块识别。

| API 名称前缀                      | 模块名                              | SDK .d.ts 文件                              |
| --------------------------------- | ----------------------------------- | ------------------------------------------- |
| avsession.*                       | multimedia_av_session               | @ohos.multimedia.avsession.d.ts             |
| createAVSession                   | multimedia_av_session               | @ohos.multimedia.avsession.d.ts             |
| AVSession*                        | multimedia_av_session               | @ohos.multimedia.avsession.d.ts             |
| AVCastPicker*                     | multimedia_av_session               | @ohos.multimedia.avsession.d.ts             |
| AVMusicTemplate*                  | multimedia_av_session               | @ohos.multimedia.avMusicTemplate.d.ts       |
| media.create*                     | multimedia_player_framework         | @ohos.multimedia.media.d.ts                 |
| media.createSoundPool             | multimedia_player_framework         | @ohos.multimedia.media.d.ts                 |
| AVPlayer*                         | multimedia_player_framework         | @ohos.multimedia.media.d.ts                 |
| AVRecorder*                       | multimedia_player_framework         | @ohos.multimedia.media.d.ts                 |
| SoundPool*                        | multimedia_player_framework         | @ohos.multimedia.media.d.ts                 |
| AVTranscoder*                     | multimedia_player_framework         | @ohos.multimedia.media.d.ts                 |
| audio.*                           | multimedia_audio_framework          | @ohos.multimedia.audio.d.ts                 |
| AudioRenderer*                    | multimedia_audio_framework          | @ohos.multimedia.audio.d.ts                 |
| AudioCapturer*                    | multimedia_audio_framework          | @ohos.multimedia.audio.d.ts                 |
| camera.*                          | multimedia_camera_framework         | @ohos.multimedia.camera.d.ts                |
| geoLocationManager.*              | base_location                       | @ohos.geoLocationManager.d.ts               |
| ble.* / socket.*                  | communication_bluetooth             | @ohos.bluetooth.ble.d.ts                    |
| wifi.*                            | communication_wifi                  | @ohos.wifi.d.ts                             |
| ability.*                         | ability_ability_runtime             | @ohos.app.ability.*.d.ts                    |
| window.*                          | window_window_manager               | @ohos.window.d.ts                           |
| connection.* / socket.* (network) | communication_netstack              | @ohos.net.connection.d.ts                   |
| bundleManager.*                   | bundlemanager_bundle_framework      | @ohos.bundle.bundleManager.d.ts             |
| installer.*                       | bundlemanager_bundle_framework      | @ohos.bundle.installer.d.ts                 |
| dataShare.*                       | distributeddatamgr_data_share       | @ohos.data.dataShare.d.ts                   |
| DataShareHelper.*                 | distributeddatamgr_data_share       | @ohos.data.dataShare.d.ts                   |
| DataSharePredicates.*             | distributeddatamgr_data_share       | @ohos.data.dataSharePredicates.d.ts         |
| kvStore.*                         | distributeddatamgr_kv_store         | @ohos.data.distributedKVStore.d.ts          |
| preferences.*                     | distributeddatamgr_preferences      | @ohos.data.preferences.d.ts                 |
| relationalStore.*                 | distributeddatamgr_relational_store | @ohos.data.relationalStore.d.ts             |
| distributedDataObject.*           | distributeddatamgr_data_object      | @ohos.data.distributedDataObject.d.ts       |
| photoAccessHelper.*               | multimedia_media_library            | @ohos.file.photoAccessHelper.d.ts           |
| userFileManager.*                 | multimedia_media_library            | @ohos.filemanagement.userFileManager.d.ts   |
| backup.*                          | filemanagement_app_file_service     | @ohos.file.backup.d.ts                      |
| fileshare.*                       | filemanagement_app_file_service     | @ohos.fileshare.d.ts                        |
| fs.*                              | filemanagement_file_api             | @ohos.file.fs.d.ts                          |
| environment.*                     | filemanagement_file_api             | @ohos.file.environment.d.ts                 |
| webview.*                         | web_webview                         | @ohos.web.webview.d.ts                      |
| WebviewController.*               | web_webview                         | @ohos.web.webview.d.ts                      |
| WebCookieManager.*                | web_webview                         | @ohos.web.webview.d.ts                      |
| WebStorage.*                      | web_webview                         | @ohos.web.webview.d.ts                      |
| nfc.*                             | communication_connected_nfc_tag     | @ohos.nfc.tag.d.ts                          |
| ethernet.*                        | communication_netmanager_ext        | @ohos.net.ethernet.d.ts                     |
| sharing.*                         | communication_netmanager_ext        | @ohos.net.sharing.d.ts                      |
| vpn.*                             | communication_netmanager_ext        | @ohos.net.vpn.d.ts                          |
| mdns.*                            | communication_netmanager_ext        | @ohos.net.mdns.d.ts                         |
| drawing.*                         | graphic_graphic_2d                  | @ohos.graphics.drawing.d.ts                 |
| text.*                            | graphic_graphic_2d                  | @ohos.graphics.text.d.ts                    |
| formProvider.*                    | ability_form_fwk                    | @ohos.app.form.formProvider.d.ts            |
| formHost.*                        | ability_form_fwk                    | @ohos.app.form.formHost.d.ts                |
| continuationManager.*             | ability_dmsfwk                      | @ohos.continuation.continuationManager.d.ts |
| accessToken.*                     | security_access_token               | @ohos.accessToken.d.ts                      |
| privacyManager.*                  | security_access_token               | @ohos.privacyManager.d.ts                   |
| screenLockFileManager.*           | security_access_token               | @ohos.screenLockFileManager.d.ts            |
| ads.*                             | advertising_ads_framework           | @ohos.advertising.ads.d.ts                  |
| oaid.*                            | advertising_oaid                    | @ohos.oaid.d.ts                             |

**使用规则：**

- 匹配时优先使用精确匹配，再使用前缀匹配
- JS API 名称区分大小写

---

## 5. hilog domain_id → 模块名

用于 hilog 日志的模块识别。从 hilog tag `C<domain_id>/<package>/<module>` 中提取。

| hilog domain_id (0x 格式)         | 十进制范围 | 模块名                               |
| --------------------------------- | ---------- | ------------------------------------ |
| 0xD002B91                         | —         | multimedia_av_session                |
| 0xD002B2B ~ 0xD002B2D             | —         | multimedia_player_framework          |
| 0xD002B84 / 0xD002B86 / 0xD002B8C | —         | multimedia_audio_framework           |
| 0xD001304                         | —         | ability_ability_runtime              |
| 0xD003900                         | —         | ability_ability_runtime (CJ)         |
| 0xD003935 / 0xD003936             | —         | arkui_ace_engine (UIService)         |
| 0xD004200 / 0xD004201             | —         | window_window_manager                |
| 0xD001201                         | —         | notification_eventhandler            |
| 0xD001400                         | —         | graphic_graphic_2d                   |
| 0xD000101                         | —         | communication_bluetooth              |
| 0xD001560                         | —         | communication_wifi                   |
| 0xD002300                         | —         | base_location                        |
| 0xD004303                         | —         | filemanagement_app_file_service      |
| 0xD001650                         | —         | distributeddatamgr_pasteboard        |
| 0xD001711                         | —         | resourceschedule_background_task_mgr |
| 0xD001F00                         | —         | telephony_core_service               |

**使用规则：**

- 先尝试精确匹配，再按范围匹配子系统
- hilog tag 中 `C` 后、第一个 `/` 前的数字为 domain_id

---

## 6. 模块名 → 代码仓与文档 URL

用于定位代码仓库和文档。代码仓 URL 直接拼接文件路径访问源码；文档仓 URL 使用 Gitee docs 仓库。

**代码仓文件访问格式：**

- 原始内容：`https://gitee.com/openharmony/{repo}/raw/master/{file_path}`
- 目录浏览：`https://gitee.com/openharmony/{repo}/tree/master/{dir_path}`

**文档仓文件访问格式：**

- 原始内容：`https://gitee.com/openharmony/docs/raw/master/{doc_path}`
- 目录浏览：`https://gitee.com/openharmony/docs/tree/master/{dir_path}`

| 模块名                                    | 代码仓 URL                                                              | errorcode 文档路径                                                                     | 开发指南路径                                  |
| ----------------------------------------- | ----------------------------------------------------------------------- | -------------------------------------------------------------------------------------- | --------------------------------------------- |
| multimedia_player_framework               | https://gitee.com/openharmony/multimedia_player_framework               | zh-cn/application-dev/reference/apis-media-kit/errorcode-media.md                      | zh-cn/application-dev/media/media/            |
| multimedia_av_session                     | https://gitee.com/openharmony/multimedia_av_session                     | zh-cn/application-dev/reference/apis-avsession-kit/errorcode-avsession.md              | zh-cn/application-dev/media/avsession/        |
| multimedia_audio_framework                | https://gitee.com/openharmony/multimedia_audio_framework                | zh-cn/application-dev/reference/apis-audio-kit/errorcode-audio.md                      | zh-cn/application-dev/media/audio/            |
| multimedia_camera_framework               | https://gitee.com/openharmony/multimedia_camera_framework               | zh-cn/application-dev/reference/apis-camera-kit/errorcode-camera.md                    | zh-cn/application-dev/media/camera/           |
| multimedia_av_codec                       | https://gitee.com/openharmony/multimedia_av_codec                       | zh-cn/application-dev/reference/apis-media-kit/errorcode-media.md                      | zh-cn/application-dev/media/media/            |
| multimedia_video_processing_engine        | https://gitee.com/openharmony/multimedia_video_processing_engine        | zh-cn/application-dev/reference/apis-media-kit/errorcode-media.md                      | zh-cn/application-dev/media/media/            |
| multimedia_media_library                  | https://gitee.com/openharmony/multimedia_media_library                  | zh-cn/application-dev/reference/apis-media-kit/errorcode-photoAccessHelper.md          | zh-cn/application-dev/media/                  |
| ability_ability_runtime                   | https://gitee.com/openharmony/ability_ability_runtime                   | zh-cn/application-dev/reference/apis-ability-kit/errorcode-ability.md                  | zh-cn/application-dev/application-models/     |
| ability_dmsfwk                            | https://gitee.com/openharmony/ability_dmsfwk                            | zh-cn/application-dev/reference/apis-continuation-kit/errorcode-continuationManager.md | zh-cn/application-dev/distributed/            |
| ability_form_fwk                          | https://gitee.com/openharmony/ability_form_fwk                          | zh-cn/application-dev/reference/apis-form-kit/errorcode-form.md                        | zh-cn/application-dev/application-models/     |
| base_location                             | https://gitee.com/openharmony/base_location                             | zh-cn/application-dev/reference/apis-location-kit/errorcode-geoLocationManager.md      | zh-cn/application-dev/device/location/        |
| communication_bluetooth                   | https://gitee.com/openharmony/communication_bluetooth                   | zh-cn/application-dev/reference/apis-connectivity-kit/errorcode-nfc.md（部分）         | zh-cn/application-dev/connectivity/bluetooth/ |
| communication_wifi                        | https://gitee.com/openharmony/communication_wifi                        | （散布在 connectivity kit 下）                                                         | zh-cn/application-dev/connectivity/wlan/      |
| communication_connected_nfc_tag           | https://gitee.com/openharmony/communication_connected_nfc_tag           | zh-cn/application-dev/reference/apis-connectivity-kit/errorcode-nfc.md                 | zh-cn/application-dev/connectivity/           |
| communication_netmanager_base             | https://gitee.com/openharmony/communication_netmanager_base             | zh-cn/application-dev/reference/apis-network-kit/errorcode-connection.md               | zh-cn/application-dev/network/                |
| communication_netmanager_ext              | https://gitee.com/openharmony/communication_netmanager_ext              | zh-cn/application-dev/reference/apis-network-kit/errorcode-ethernet.md                 | zh-cn/application-dev/network/                |
| communication_fusion_connectivity         | https://gitee.com/openharmony/communication_fusion_connectivity         | （融合连接）                                                                           | zh-cn/application-dev/connectivity/           |
| connectivity_connectivity_cangjie_wrapper | https://gitee.com/openharmony/connectivity_connectivity_cangjie_wrapper | （仓颉封装）                                                                           | zh-cn/application-dev/connectivity/           |
| window_window_manager                     | https://gitee.com/openharmony/window_window_manager                     | zh-cn/application-dev/reference/apis-arkui/errorcode-bindSheet.md（部分）              | zh-cn/application-dev/application-models/     |
| window_window_manager_lite                | https://gitee.com/openharmony/window_window_manager_lite                | （轻量系统）                                                                           | zh-cn/application-dev/application-models/     |
| telephony_core_service                    | https://gitee.com/openharmony/telephony_core_service                    | zh-cn/application-dev/reference/apis-telephony-kit/errorcode-telephony.md              | zh-cn/application-dev/device/telephony/       |
| web_webview                               | https://gitee.com/openharmony/web_webview                               | zh-cn/application-dev/reference/apis-web-kit/errorcode-webview.md                      | zh-cn/application-dev/web/                    |
| arkweb_arkweb_cangjie_wrapper             | https://gitee.com/openharmony/arkweb_arkweb_cangjie_wrapper             | （仓颉封装）                                                                           | zh-cn/application-dev/web/                    |
| bundlemanager_bundle_framework            | https://gitee.com/openharmony/bundlemanager_bundle_framework            | zh-cn/application-dev/reference/apis-basic-services-kit/errorcode-bundle.md            | zh-cn/application-dev/application-models/     |
| bundlemanager_app_domain_verify           | https://gitee.com/openharmony/bundlemanager_app_domain_verify           | zh-cn/application-dev/reference/apis-basic-services-kit/errorcode-appDomainVerify.md   | zh-cn/application-dev/application-models/     |
| distributeddatamgr_data_share             | https://gitee.com/openharmony/distributeddatamgr_data_share             | zh-cn/application-dev/reference/apis-arkdata/errorcode-dataShare.md                    | zh-cn/application-dev/data/                   |
| distributeddatamgr_data_object            | https://gitee.com/openharmony/distributeddatamgr_data_object            | zh-cn/application-dev/reference/apis-arkdata/errorcode-distributedDataObject.md        | zh-cn/application-dev/data/                   |
| distributeddatamgr_kv_store               | https://gitee.com/openharmony/distributeddatamgr_kv_store               | zh-cn/application-dev/reference/apis-arkdata/errorcode-data-distributedKVStore.md      | zh-cn/application-dev/data/                   |
| distributeddatamgr_preferences            | https://gitee.com/openharmony/distributeddatamgr_preferences            | zh-cn/application-dev/reference/apis-arkdata/errorcode-data-preferences.md             | zh-cn/application-dev/data/                   |
| distributeddatamgr_relational_store       | https://gitee.com/openharmony/distributeddatamgr_relational_store       | zh-cn/application-dev/reference/apis-arkdata/errorcode-data-rdb.md                     | zh-cn/application-dev/data/                   |
| filemanagement_app_file_service           | https://gitee.com/openharmony/filemanagement_app_file_service           | zh-cn/application-dev/reference/apis-filemanagement-kit/errorcode-backup.md            | zh-cn/application-dev/file-management/        |
| filemanagement_file_api                   | https://gitee.com/openharmony/filemanagement_file_api                   | zh-cn/application-dev/reference/apis-filemanagement-kit/errorcode-filemanagement.md    | zh-cn/application-dev/file-management/        |
| graphic_graphic_2d                        | https://gitee.com/openharmony/graphic_graphic_2d                        | zh-cn/application-dev/reference/apis-arkts/errorcode-drawing.md                        | zh-cn/application-dev/ui/                     |
| arkui_ace_engine_lite                     | https://gitee.com/openharmony/arkui_ace_engine_lite                     | （轻量系统）                                                                           | zh-cn/application-dev/ui/                     |
| arkui_advanced_ui_component               | https://gitee.com/openharmony/arkui_advanced_ui_component               | （内置组件）                                                                           | zh-cn/application-dev/ui/                     |
| arkui_arkui_cangjie_wrapper               | https://gitee.com/openharmony/arkui_arkui_cangjie_wrapper               | （仓颉封装）                                                                           | zh-cn/application-dev/ui/                     |
| security_access_token                     | https://gitee.com/openharmony/security_access_token                     | zh-cn/application-dev/reference/apis-basic-services-kit/errorcode-accessToken.md       | zh-cn/application-dev/security/               |
| advertising_ads_framework                 | https://gitee.com/openharmony/advertising_ads_framework                 | zh-cn/application-dev/reference/apis-ads-kit/errorcode-ads.md                          | zh-cn/application-dev/ads/                    |
| advertising_oaid                          | https://gitee.com/openharmony/advertising_oaid                          | zh-cn/application-dev/reference/apis-ads-kit/errorcode-oaid.md                         | zh-cn/application-dev/ads/                    |
| hiviewdfx_hicollie                        | https://gitee.com/openharmony/hiviewdfx_hicollie                        |                                                                                        | zh-cn/application-dev/dfx/                    |
| commonlibrary_ets_utils                   | https://gitee.com/openharmony/commonlibrary_ets_utils                   | zh-cn/application-dev/reference/apis-arkts/errorcode-concurrent.md                     | zh-cn/application-dev/arkts-utils/            |

**WebFetch 兜底策略：**

当模块无映射或映射未命中时：

1. 使用 WebSearch 搜索错误码对应的官方文档
2. 使用 WebFetch 直接访问 `https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/` 下的文件

---

## 未识别信号处理指引

当从输入中提取的信号不匹配上述任何映射表条目时：

1. **标注模块未识别**：在输出中将 `module_identified` 设为 `"未识别"`
2. **保留所有线索**：将提取到的错误码、DOMAIN、.so 名、API 名称等全部记录在 `clues` 中
3. **尝试推测**：
   - 若有 .so 库名，按 `lib<模块关键词>.so` 规则推测代码仓目录名
   - 若有 DOMAIN 值，使用 WebSearch 搜索 DOMAIN + "openharmony" 定位源码
   - 若有 API 名称前缀，使用 WebSearch 搜索定位所属 kit
4. **WebSearch 兜底**：在搜索引擎中搜索错误码 + "" 或 "openharmony"

**映射缺口反馈：** 若某个信号反复出现但不在映射表中，说明映射表需要补充。
