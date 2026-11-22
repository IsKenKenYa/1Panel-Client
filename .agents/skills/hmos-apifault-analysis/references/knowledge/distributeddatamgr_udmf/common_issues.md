# UDMF Common Issues

## 1. Permission Issues

### E_NO_PERMISSION (C++) / BusinessError 201 (JS)

**Affected APIs:** `setAppShareOptions`, `removeAppShareOptions`

- **Permission required:** `ohos.permission.MANAGE_UDMF_APP_SHARE_OPTION` (since API 14)
- **Scenario:** The caller attempts to set or remove application share options for the drag data channel without holding the required permission.
- **Code path:** `UdmfClient::SetAppShareOption` / `UdmfClient::RemoveAppShareOption` returns `E_NO_PERMISSION`, which the NAPI layer surfaces as BusinessError 201.

### E_NO_SYSTEM_PERMISSION (C++) / BusinessError 202 (JS)

**Affected APIs:** `setAppShareOptions`, `removeAppShareOptions` (API 12-13), `registerTypeDescriptors`, `unregisterTypeDescriptors`

- **Scenario:** A non-system application calls a system API. In API 12-13, `setAppShareOptions` and `removeAppShareOptions` were system APIs; non-system apps receive error 202.
- **For UTD:** `registerTypeDescriptors` and `unregisterTypeDescriptors` require `ohos.permission.MANAGE_DYNAMIC_UTD_TYPE` and system app status.

## 2. Parameter Validation Issues

### E_INVALID_PARAMETERS (C++) / BusinessError 401 (JS)

The NAPI layer in `unified_data_channel_napi.cpp` performs extensive parameter validation. Common failure scenarios:

#### insertData
- Fewer than 2 arguments provided: "Mandatory parameters are left unspecified"
- `options.intention` is not a valid persistable Intention enum (only DATA_HUB, SYSTEM_SHARE, PICKER, MENU; DRAG is excluded): "parameter options intention type must correspond to Intention"
- Second argument is not a `UnifiedData` object: "parameter data type must be UnifiedData"
- `options.visibility` is provided but not a valid Visibility enum

#### updateData
- Fewer than 2 arguments: "Mandatory parameters are left unspecified"
- `options.key` is missing, invalid (fails `UnifiedKey::IsValid()`), or intention is not DATA_HUB
- Second argument is not `UnifiedData`

#### queryData / deleteData
- No arguments provided
- Neither `key` nor `intention` is specified, or the key/intention combination is invalid
- DRAG intention is not supported for query/delete via public API

#### setAppShareOptions
- Fewer than 2 arguments
- `intention` parameter is not "Drag" (only Drag channel is currently supported)
- `shareOption` value is outside the valid range [IN_APP, CROSS_APP]

#### removeAppShareOptions
- No arguments provided
- `intention` parameter is not "Drag"

#### convertRecordsToEntries
- Argument is not a `UnifiedData` object

#### getTypeDescriptor (UTD)
- `typeId` parameter is not a string

#### registerTypeDescriptors (UTD)
- `descriptors` is not an array of TypeDescriptor objects

## 3. Data Size Limits

Per the README and architectural constraints:

- **Single record limit:** Each data record must not exceed **2MB**. Exceeding this may cause write failures.
- **Group limit:** Each data group (batch) must not exceed **4MB** in total. This applies when inserting multiple records via `insertData` with a single `UnifiedData` object containing multiple records.

These limits are enforced at the service/storage layer and violations result in `E_DB_ERROR` or `E_FS_ERROR`.

## 4. IPC / Service Availability Issues

### E_IPC

- **Scenario:** The UDMF service (distributeddatamgr service) is unavailable, the IPC proxy is null, or the Parcel read/write fails during cross-process communication.
- **Symptoms:** `UdmfClient::GetInstance()` returns a client, but subsequent operations fail because `UdmfServiceClient::GetServiceProxy()` cannot connect to the service.
- **Related error codes:** `E_WRITE_PARCEL_ERROR`, `E_READ_PARCEL_ERROR` are sub-categories of IPC failures.
- **Troubleshooting:** Check if the distributeddatamgr service process is running; verify samgr registration.

## 5. Database / Storage Issues

### E_DB_ERROR

- **Scenario:** The underlying KVDB (key-value database) operation fails. This can occur during data insertion, query, update, or deletion.
- **Possible causes:** Database I/O failure, data corruption in progress, concurrent access conflict.

### E_DB_CORRUPTED

- **Scenario:** The UDMF database file is corrupted and cannot be read or written correctly.
- **Troubleshooting:** May require clearing the UDMF data directory and reinitializing.

### E_FS_ERROR

- **Scenario:** File system operations fail, typically during file copy operations in drag-and-drop or data retrieval scenarios involving file-type records (File, Image, Video, Audio, Folder).
- **Related:** `E_COPY_FILE_FAILED` is a more specific variant for file copy failures. `E_COPY_CANCELED` indicates the copy was user-canceled.

### E_NOT_FOUND

- **Scenario:** The specified key does not exist in the UDMF data store, or no data matches the specified intention. This is returned by `GetBatchData` or `DeleteData` when the query yields no results.
- **Note:** In the JS API, queryData with a non-existent key may return an empty array rather than throwing.

## 6. Share Option Configuration Issues

### E_SETTINGS_EXISTED / BusinessError 20400001

- **Scenario:** `setAppShareOptions` is called when share options for the Drag intention have already been configured. The existing settings must be removed first via `removeAppShareOptions`.
- **Code path:** `UdmfClient::SetAppShareOption` returns `E_SETTINGS_EXISTED`.

## 7. UTD Type Registration Issues

### E_FORMAT_ERROR / BusinessError 20400002

- **Scenario:** `registerTypeDescriptors` is called with TypeDescriptor entries that have invalid format (e.g., missing required fields, incorrect typeId format).

### E_CONTENT_ERROR / BusinessError 20400003

- **Scenario:** `registerTypeDescriptors` is called with TypeDescriptor entries whose content violates UTD rules (e.g., typeId conflicts with existing types, invalid hierarchy).

### E_INVALID_TYPE_ID / BusinessError 20400004

- **Scenario:** `unregisterTypeDescriptors` is called with typeIds that do not exist or are invalid.

## 8. Intelligence Module Issues

### Capability Not Supported (801)

- **Scenario:** The device does not support the intelligence features (image/text embedding). The `IAipCoreManager` library cannot be loaded or the device lacks NPU/algorithm support.
- **Affected APIs:** All `@ohos.data.intelligence` APIs.

### Inner Error (31300000)

- **Scenario:** Internal error in the intelligence module, such as model loading failure, embedding computation failure, or algorithm library loading failure.
- **Troubleshooting:** Check device compatibility, verify algorithm library exists at `/system/lib64/platformsdk/libaip_core.z.so`.
