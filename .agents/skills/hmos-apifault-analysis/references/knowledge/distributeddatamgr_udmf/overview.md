# UDMF (Unified Data Management Framework) - Module Overview

## Module Responsibility

UDMF (统一数据管理框架) is a component of the distributeddatamgr subsystem (SysCap: SystemCapability.DistributedDataManager.UDMF.Core). It defines standards for data crossing applications, devices, and platforms, providing a unified OpenHarmony data language and standardized data access/read channels. UDMF manages the lifecycle, security, permissions, and storage of data, and supports scenarios such as drag-and-drop, system sharing, and picker-based data exchange.

**Key constraints:**
- Each data record must not exceed 2MB.
- Each data group must not exceed 4MB.

## Simplified Directory Tree

```
distributeddatamgr_udmf/
├── framework/
│   ├── common/                          # Common utilities
│   ├── innerkitsimpl/                   # Native C++ implementation
│   │   ├── client/                      # Client layer (UdmfClient, UtdClient, UdmfAsyncClient)
│   │   ├── common/                      # Common tools (UnifiedKey, UnifiedMeta, ProgressQueue)
│   │   ├── data/                        # Data structure implementations (UnifiedData, types)
│   │   ├── convert/                     # xxx/data conversion
│   │   ├── dynamic/                     # Dynamic libraries (PixelMap, XML wrappers)
│   │   ├── service/                     # IPC service proxy/stub
│   │   └── test/                        # Tests
│   └── jskitsimpl/                      # JS/NAPI implementation
│       ├── common/                      # NAPI common utilities
│       ├── data/                        # NAPI data channel & type implementations (22 *_napi.cpp)
│       ├── intelligence/                # Intelligence module (image/text embedding)
│       └── unittest/                    # JS unit tests
├── interfaces/
│   ├── innerkits/                       # C++ API declarations
│   │   ├── client/                      # Client headers (udmf_client.h, utd_client.h, etc.)
│   │   ├── common/                      # Common headers (error_code.h, unified_key.h, etc.)
│   │   ├── data/                        # Data type headers
│   │   └── convert/                     # Conversion headers
│   ├── jskits/                          # NAPI declarations
│   │   ├── common/                      # NAPI utils (napi_queue.h)
│   │   ├── data/                        # NAPI data headers
│   │   ├── intelligence/                # Intelligence NAPI headers
│   │   └── module/                      # Module registration entry
│   ├── xxx/                             # Native API C API (udmf.h, uds.h, utd.h, udmf_meta.h)
│   ├── cj/                              # CJ (Cangjie) FFI interface
│   ├── components/                      # UDMF components
│   └── taihe/                           # Taihe (ArkTS static) interface
├── bundle.json                          # Module configuration
├── README_zh.md                         # Chinese README
└── udmf.gni                             # Build configuration header
```

## Core Files

| File | Purpose |
|------|---------|
| `framework/jskitsimpl/data/unified_data_channel_napi.cpp` | Main NAPI channel: insertData/updateData/queryData/deleteData/setAppShareOptions/removeAppShareOptions/convertRecordsToEntries |
| `framework/jskitsimpl/data/uniform_type_descriptor_napi.cpp` | UTD NAPI: getTypeDescriptor, getUniformDataTypeByFilenameExtension/MIMEType, register/unregisterTypeDescriptors |
| `framework/jskitsimpl/data/unified_data_napi.cpp` | UnifiedData class NAPI wrapper |
| `framework/jskitsimpl/data/unified_record_napi.cpp` | UnifiedRecord class NAPI wrapper |
| `framework/jskitsimpl/data/plain_text_napi.cpp` | PlainText type NAPI |
| `framework/jskitsimpl/data/text_napi.cpp` | Text type NAPI |
| `framework/jskitsimpl/data/html_napi.cpp` | HTML type NAPI |
| `framework/jskitsimpl/data/file_napi.cpp` | File type NAPI |
| `framework/jskitsimpl/data/image_napi.cpp` | Image type NAPI |
| `framework/jskitsimpl/data/video_napi.cpp` | Video type NAPI |
| `framework/jskitsimpl/data/audio_napi.cpp` | Audio type NAPI |
| `framework/jskitsimpl/data/folder_napi.cpp` | Folder type NAPI |
| `framework/jskitsimpl/data/link_napi.cpp` | Hyperlink type NAPI |
| `framework/jskitsimpl/data/system_defined_record_napi.cpp` | SystemDefinedRecord type NAPI |
| `framework/jskitsimpl/data/system_defined_form_napi.cpp` | SystemDefinedForm type NAPI |
| `framework/jskitsimpl/data/system_defined_appitem_napi.cpp` | SystemDefinedAppItem type NAPI |
| `framework/jskitsimpl/data/system_defined_pixelmap_napi.cpp` | SystemDefinedPixelMap type NAPI |
| `framework/jskitsimpl/data/application_defined_record_napi.cpp` | ApplicationDefinedRecord type NAPI |
| `framework/jskitsimpl/data/type_descriptor_napi.cpp` | TypeDescriptor class NAPI |
| `framework/jskitsimpl/intelligence/image_embedding_napi.cpp` | Image embedding NAPI (loadModel/getEmbedding/releaseModel) |
| `framework/jskitsimpl/intelligence/text_embedding_napi.cpp` | Text embedding NAPI (loadModel/getEmbedding/releaseModel/splitText/getSupportedCloudModel) |
| `framework/jskitsimpl/intelligence/native_module_intelligence.cpp` | Intelligence NAPI module registration (nm_modname="data.intelligence") |
| `interfaces/jskits/module/unified_data_channel_napi_module.cpp` | NAPI module entry for unifiedDataChannel |
| `interfaces/jskits/module/uniform_type_descriptor_napi_module.cpp` | NAPI module entry for uniformTypeDescriptor |
| `framework/innerkitsimpl/client/udmf_client.cpp` | UdmfClient singleton: SetData/GetBatchData/UpdateData/DeleteData/SetAppShareOption/RemoveAppShareOption |
| `framework/innerkitsimpl/client/udmf_async_client.cpp` | Async client implementation |
| `framework/innerkitsimpl/client/utd_client.cpp` | UtdClient: GetTypeDescriptor/GetUniformDataTypeByFilenameExtension/MIMEType/Register/Unregister |
| `framework/innerkitsimpl/client/getter_system.cpp` | System data getter |
| `framework/innerkitsimpl/service/udmf_service_client.cpp` | IPC service client (get service proxy) |
| `framework/innerkitsimpl/service/udmf_service_proxy.cpp` | IPC service proxy |
| `framework/innerkitsimpl/service/utd_service_client.cpp` | UTD service client |
| `framework/innerkitsimpl/service/utd_service_proxy.cpp` | UTD service proxy |
| `framework/innerkitsimpl/service/udmf_notifier_stub.cpp` | UDMF notifier IPC stub |
| `framework/innerkitsimpl/service/progress_callback.cpp` | Progress callback implementation |
| `interfaces/innerkits/common/error_code.h` | C++ Status enum error codes |
| `interfaces/xxx/data/udmf_err_code.h` | Native API error codes (Udmf_ErrCode, Udmf_ListenerStatus) |
| `interfaces/jskits/common/napi_error_utils.h` | NAPI error utility declarations |
| `interfaces/jskits/intelligence/aip_napi_error.h` | Intelligence module error codes (TsErrCode enum) |
