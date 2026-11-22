# Core File Kit 常见问题案例库

## 1. ==概述==

### 1.1 Core File Kit 简介

Core File Kit 是  提供的文件管理核心工具包，包含以下主要模块：

- **fileIo**: 文件基础操作（打开、读写、关闭、复制等）
- **fileShare**: 文件共享与权限持久化
- **picker**: 文件选择器（DocumentViewPicker、PhotoViewPicker）
- **fileUri**: URI 路径处理工具

### 1.2 文档用途

本案例库旨在帮助开发者：

- 快速识别 Core File Kit API 使用中的常见错误
- 理解错误码含义及触发场景
- 获取正确的解决方案和代码示例
- 预防类似问题的发生

### 1.3 适用场景

- 文件操作功能开发调试
- 故障排查与问题定位
- API 学习与好实践参考

### 1.4 沙箱路径与 URI 规范

fs 接口对路径类型的要求：

- **接收路径参数**：openSync、mkdirSync、renameSync、listFileSync、rmdirSync、unlinkSync、accessSync、copyFileSync、copyDirSync、moveDirSync 等
- **支持 URI**：openSync、copy、stat/statSync/lstat/lstatSync（API version 22+）
- **仅接收 fd**：readSync、writeSync、closeSync（不涉及路径，操作已打开的文件描述符）

获取沙箱路径的正确方式：

```typescript
const sandboxPath = this.context.filesDir;  // 应用文件目录
const cachePath = this.context.cacheDir;    // 缓存目录
```

排查沙箱目录方法：

```bash
ps -ef | grep 应用包名
nsenter -t pid -m sh
ls -la /data/storage/el2/base/haps/entry/
```

---

## 2. 目录索引

### 2.1 按错误码分类

| 错误码   | 名称                      | 涉及案例           |
| -------- | ------------------------- | ------------------ |
| 13900001 | Operation not permitted   | 案例02、03、04、05 |
| 13900002 | No such file or directory | 案例06、07         |
| 13900005 | I/O error                 | 案例14             |
| 13900008 | Bad file descriptor       | 案例15             |
| 13900010 | try again                 | 案例16             |
| 13900012 | Permission denied         | 案例09             |
| 13900020 | Invalid argument          | 案例10、11         |
| 13900027 | Read-only file system     | 案例12             |
| 13900030 | File name too long        | 案例13             |

### 2.2 按测试场景索引

| 案例编号 | 场景描述                    | 预期结果 | 关键 API                              |
| -------- | --------------------------- | -------- | ------------------------------------- |
| 案例02   | 读取URI文件后权限失效       | 13900001 | fs.openSync                           |
| 案例03   | Picker URI持久化授权失败    | 13900001 | fileShare.persistPermission           |
| 案例04   | PhotoViewPicker读写权限不足 | 13900001 | fs.openSync                           |
| 案例05   | URI拼接导致路径无效         | 13900001 | fileUri.FileUri                       |
| 案例06   | 打开不存在文件              | 13900002 | fs.openSync                           |
| 案例07   | 父目录不存在创建文件        | 13900002 | fs.openSync                           |
| 案例09   | resfile目录写入权限         | 13900012 | fs.openSync                           |
| 案例10   | readSync参数类型错误        | 13900020 | fs.readSync                           |
| 案例11   | copyDir目标父目录不存在     | 13900020 | fs.copyDirSync                        |
| 案例12   | 系统路径读写权限            | 13900027 | fs.openSync                           |
| 案例13   | 文件名超255字节限制         | 13900030 | fs.openSync                           |
| 案例14   | readSync I/O错误            | 13900005 | fs.readSync                           |
| 案例15   | fd无效错误                  | 13900008 | fs.readSync/fs.writeSync/fs.closeSync |
| 案例16   | readSync无数据可读          | 13900010 | fs.readSync                           |

---

## 3. 错误码速查表

| 错误码             | 英文名称                  | 中文含义         | 常见触发原因                               |
| ------------------ | ------------------------- | ---------------- | ------------------------------------------ |
| **13900001** | Operation not permitted   | 操作不被允许     | URI权限失效/权限不足/URI格式无效           |
| **13900002** | No such file or directory | 文件或目录不存在 | 文件不存在/父目录不存在                    |
| **13900005** | I/O error                 | I/O错误          | 文件系统内部错误/网络问题/文件变动         |
| **13900008** | Bad file descriptor       | 文件描述符无效   | fd未正确打开/fd已关闭/fd指向目录/重复close |
| **13900010** | Try again                 | 重试             | 连续read无数据可读/系统调用readSync        |
| **13900012** | Permission denied         | 权限拒绝         | 只读目录写入/权限未授权                    |
| **13900020** | Invalid argument          | 无效参数         | 参数类型错误/路径参数无效                  |
| **13900027** | Read-only file system     | 只读文件系统     | 系统路径写入操作                           |
| **13900030** | File name too long        | 文件名过长       | 文件名超过255字节                          |

---

## 4. 案例详解

---

### 案例02: 读取URI文件后权限失效（13900001）

#### 场景描述

从沙箱文件读取之前保存的 Picker URI，尝试重新打开。由于应用已重启，临时权限已失效。

#### 预期结果

**错误码: 13900001** - Operation not permitted

#### 触发代码

```typescript
// 从文件读取 URI
const testFilePath = `${this.context.filesDir}/saved_picker_uri.txt`;
const readFile = fs.openSync(testFilePath, fs.OpenMode.READ_ONLY);
const stat = fs.statSync(testFilePath);
const buffer = new ArrayBuffer(stat.size);
fs.readSync(readFile.fd, buffer);
fs.closeSync(readFile.fd);

const savedUri = String.fromCharCode(...new Uint8Array(buffer));

// 尝试打开已失效的 Picker URI
const readOnlyFile = fs.openSync(savedUri, fs.OpenMode.READ_ONLY);
// 触发错误 13900001
```

#### 问题分析

- Picker URI 授权类型：**临时权限**
- 权限有效期：仅应用运行期间
- 重启后状态：权限已失效
- 系统行为：拒绝访问操作

#### 解决方案

1. **保存后立即使用**：在权限有效期内完成所有操作

```typescript
// 正确：立即使用 Picker URI
const pickerUri = documentSelectResult[0];
const file = fs.openSync(pickerUri, fs.OpenMode.READ_ONLY);
// 在同一次运行中完成所有操作
```

2. **使用持久化授权**：如需跨会话访问，使用 fileShare 模块

```typescript
// 对于支持的 URI 类型
const policyInfo: fileShare.PolicyInfo = {
  uri: uri,
  operationMode: fileShare.OperationMode.READ_MODE
};
await fileShare.persistPermission([policyInfo]);
```

3. **复制到沙箱**：将文件内容复制到应用沙箱目录

```typescript
// 复制文件到沙箱，永久可访问
const sandboxPath = `${this.context.filesDir}/copied_file.txt`;
fs.copyFile(pickerUri, sandboxPath);
```

#### 关键提示

- 文档选择器 URI 权限是临时的，重启后失效
- 不要将 Picker URI 保存到文件后跨会话使用
- 如需持久访问，应复制文件内容到沙箱

#### 定界指引

排查 URI 权限问题时的日志搜索关键字：

- **AppFileService** — 应用文件服务日志
- **uri_permission_** — URI 权限相关日志
- **DataShare** — 数据共享日志（图库文件场景）

**排查步骤：**

1. 日志查找 DataShare，检查媒体库是否报错返回 `fd = -1`
2. 打开 media/docs URI 失败时，日志查找 AppFileService 或 uri_permission_，确认 URI 对应路径下是否有文件
3. 确认文件的分享方式是 datashare 还是 bind mount

---

### 案例03: Picker URI 持久化授权失败（13900001）

#### 场景描述

尝试对 Picker 返回的 URI 进行持久化授权，期望在应用重启后仍能直接访问该文件，但操作触发报错。

#### 预期结果

**错误码: 13900001** - Operation not permitted

#### 触发代码

```typescript
1const pickerUri = documentSelectResult[0];
2
3// 尝试持久化 Picker URI 权限
4const policyInfo: fileShare.PolicyInfo = {
5  uri: pickerUri,
6  operationMode: fileShare.OperationMode.RENAME_MODE // 错误原因：使用了不支持的权限模式
7};
8await fileShare.persistPermission([policyInfo]);
```

#### 问题分析

1. **操作模式（operationMode）不合法**：触发该报错的最常见原因是权限模式组合错误。例如只给 `CREATE_MODE` 却没给 `WRITE_MODE`，或者使用了系统不支持的模式（如 `RENAME_MODE`）。正确的持久化读取应使用 `READ_MODE`，读写应使用 `READ_WRITE_MODE`。
2. **缺少必要权限**：持久化授权需要应用提前在配置中申请 `ohos.permission.FILE_ACCESS_PERSIST` 权限，否则会触发 201 (Permission verification failed) 或 13900001 错误。
3. **URI 类型限制**：虽然 Picker 返回的文档类 URI 支持持久化，但**不支持远端 URI** 的持久化，从API version 22开始，支持媒体类URI的持久化。

#### 解决方案

**方案：正确执行持久化授权生命周期**

```typescript
1import { fileShare } from '@kit.CoreFileKit';
2
3// 1. 构建正确的权限策略
4const policyInfo: fileShare.PolicyInfo = {
5  uri: pickerUri,
6  operationMode: fileShare.OperationMode.READ_MODE // 必须使用合法的访问模式
7};
8const policies: fileShare.PolicyInfo[] = [policyInfo];
9
10try {
11  // 2. 申请持久化授权（需提前申请 ohos.permission.FILE_ACCESS_PERSIST）
12  await fileShare.persistPermission(policies);
13  console.info('持久化授权成功');
14  
15  // 3. 重要：将 URI 保存到本地存储（如 Preferences），供后续按需激活
16  await this.savePersistedUri(pickerUri);
17} catch (error) {
18  // 4. 统一错误处理
19  console.error(`持久化授权失败: ${error.code}, ${error.message}`);
20}
```

#### ️ 关键提示

- **临时权限机制**：通过 Picker 获取的 URI 默认仅具备临时读写权限，应用退出后台或设备重启后授权自动失效。
- **重启后必须激活**：持久化授权的数据存储在系统数据库中，应用或设备重启后**不会自动加载到内存**。应用每次启动时，必须按需调用 `activatePermission` 接口手动激活已持久化的权限，否则依然会报 `13900001` 错误。
- **按需激活原则**：建议按照使用需求去激活对应的持久化权限，不要盲目全量激活。
- 业务场景区分：
  - 如果业务需要“在历史记录中直接选中打开原文件”，**必须**使用 `persistPermission` + `activatePermission` 机制。
  - 如果业务仅仅是“获取用户的图片作为应用内的永久头像/封面”，推荐将文件拷贝到应用沙箱（如 `filesDir`），这属于数据备份，不受外部文件被用户删除的影响。

---

### 案例04: PhotoViewPicker读写权限不足（13900001）

#### 场景描述

PhotoViewPicker 返回的图片 URI 默认授予只读权限，尝试以读写模式打开触发权限错误。

#### 预期结果

**错误码: 13900001** - Operation not permitted

#### 触发代码

```typescript
const photoViewPicker = new picker.PhotoViewPicker(this.context);
const photoSelectResult = await photoViewPicker.select(photoSelectOptions);
const pickerUri = photoSelectResult.photoUris[0];

// 尝试以读写模式打开（权限不足）
const testFile = fs.openSync(pickerUri, fs.OpenMode.READ_WRITE);
// 触发错误 13900001
```

#### 问题分析

- PhotoViewPicker URI 默认权限：**只读**
- READ_WRITE 模式需要写权限
- 系统拒绝超出授权范围的操作

#### 解决方案

```typescript
// 正确：使用只读模式打开
const file = fs.openSync(pickerUri, fs.OpenMode.READ_ONLY);

// 如需写入，复制到沙箱后操作
const sandboxPath = `${this.context.filesDir}/editable_image.jpg`;
fs.copyFile(pickerUri, sandboxPath);

// 现在可以对沙箱副本进行读写
const editableFile = fs.openSync(sandboxPath, fs.OpenMode.READ_WRITE);
```

#### 关键提示

- PhotoViewPicker URI 权限范围有限，仅支持读取
- 需要编辑图片时，先复制到应用沙箱

#### 定界指引

**排查是否文件权限问题：**
使用 `hdc file send` 推送文件到 `/storage/media/100/local/files/Photo` 或 `Picture` 目录时，应通过 mediatool 方式推送到图库。

---

### 案例05: URI拼接导致路径无效（13900001）

#### 场景描述

错误地将 Picker URI 与文件名进行字符串拼接，导致构造的路径格式无效。

#### 预期结果

**错误码: 13900001** - Operation not permitted / Invalid URI format

#### 触发代码

```typescript
const documentSaveResult = await documentViewPicker.save(documentSaveOptions);
const selectedUri = documentSaveResult[0]; // 例如: file:///data/storage/...
const fileName = 'test_file.txt';

// 错误：直接拼接 URI 和文件名
const malformedPath = new fileUri.FileUri(selectedUri + fileName).path;
// malformedPath 格式无效

fs.openSync(malformedPath, fs.OpenMode.CREATE);
// 触发错误 13900001
```

#### 问题分析

1. Picker 返回的 URI 格式：`file:///data/storage/emulated/0/Documents/test_file.txt`
2. 直接拼接得到：`file:///data/storage/emulated/0/Documents/test_file.txttest_file.txt`
3. 这种拼接方式**忽略了 URI 的正确构造规则**
4. 导致路径格式无效，触发操作不允许错误

#### 解决方案

```typescript
// 方案1: 直接使用 Picker save 返回的 URI（已包含完整路径）
const documentSaveResult = await documentViewPicker.save(documentSaveOptions);
const fileUri = documentSaveResult[0];
// save 返回的 URI 已经是完整的文件 URI，直接使用
const file = fs.openSync(fileUri, fs.OpenMode.WRITE_ONLY);

// 方案2: 如需处理路径，使用 fileUri API 方法
const uriObj = new fileUri.FileUri(selectedUri);
// 使用 API 方法处理路径，而非字符串拼接
```

#### 关键提示

- **不要使用字符串拼接处理 URI**
- Picker 的 `save` 方法返回的是完整的文件 URI，无需额外处理
- 使用 `fileUri.FileUri` 类提供的 API 方法处理路径

#### 定界指引

**排查 URI 格式问题：**

- 检查应用是否自行编辑/拼接/转码 URI，可能导致格式不正确
- 日志搜索 AppFileService 或 uri_permission_ 确认 URI 对应路径下是否有文件

**排查步骤：**

1. 检查 URI 是否通过 Picker 正确获取
2. 确认 URI 处理代码是否使用了 fileUri API 方法而非字符串拼接

---

### 案例06: 打开不存在文件（13900002）

#### 场景描述

尝试打开一个不存在的文件，触发文件不存在错误。

#### 预期结果

**错误码: 13900002** - No such file or directory

#### 触发代码

```typescript
const nonExistentPath = this.context.filesDir + '/non_existent_file.txt';

// 尝试以只读模式打开不存在的文件
const testFile = fs.openSync(nonExistentPath, fs.OpenMode.READ_ONLY);
// 触发错误 13900002
```

#### 问题分析

- READ_ONLY 模式要求文件必须存在
- 文件不存在时系统返回 "No such file or directory" 错误

#### 解决方案

```typescript
// 方案1: 使用 CREATE 模式创建新文件
const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);

// 方案2: 先检查文件是否存在
try {
  const stat = fs.statSync(filePath);
  // 文件存在，可以打开
  const file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
} catch (err) {
  if (err.code === 13900002) {
    // 文件不存在，创建新文件
    const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
  }
}

// 方案3: 使用 CREATE_IF_NOT_EXISTS 模式（如果支持）
const file = fs.openSync(filePath, fs.OpenMode.CREATE_IF_NOT_EXISTS | fs.OpenMode.READ_WRITE);
```

#### 关键提示

- READ_ONLY 模式不会自动创建文件
- 使用 CREATE 模式可创建新文件
- 操作前可使用 `fs.statSync` 检查文件状态

#### 定界指引

**排查步骤：**

1. 进入应用沙箱视角，排查沙箱路径下是否有指定文件：
   ```bash
   ps -ef | grep 应用包名
   nsenter -t pid -m sh
   ls -la <沙箱路径>
   ```
2. 若文件存在但报错，进一步排查文管子系统

**可能原因细化：**

1. 入参路径指向不存在的文件且没有 CREATE 标签，或 path 参数为空
2. 应用沙箱下看不到该目录/文件
3. 带 CREATE 标签时，文件的父级目录不存在
4. 沙箱目录未成功挂载，应用访问私有沙箱目录失败
5. 自行编辑/拼接/转码 URI，可能导致 URI 格式不正确

---

### 案例07: 父目录不存在创建文件（13900002）

#### 场景描述

尝试在不存在父目录的路径下创建文件，fs.openSync 不会自动创建父目录。

#### 预期结果

**错误码: 13900002** - No such file or directory

#### 触发代码

```typescript
const nonExistentDir = `${this.context.filesDir}/nonexistent_dir_${Date.now()}`;
const testFilePath = `${nonExistentDir}/test_file.txt`;

// 尝试在不存在的目录中创建文件
const file = fs.openSync(testFilePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
// 触发错误 13900002
```

#### 问题分析

- `fs.openSync(CREATE)` **不会自动创建父目录**
- 父目录不存在导致整个路径无效
- 这是文件系统的安全限制

#### 解决方案

```typescript
// 正确步骤：先创建父目录，再创建文件
// 步骤1: 创建父目录
fs.mkdirSync(nonExistentDir);

// 步骤2: 在目录中创建文件
const file = fs.openSync(testFilePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
fs.writeSync(file.fd, 'file content');
fs.closeSync(file.fd);
```

#### 关键提示

- `fs.openSync` 不会递归创建目录
- 创建文件前必须确保父目录存在
- 使用 `fs.mkdirSync` 或 `fs.mkdir` 创建目录

---

### 案例09: resfile目录写入权限（13900012）

#### 场景描述

尝试在应用的 resfile（资源文件）目录中创建或写入文件。

#### 预期结果

**错误码: 13900012** - Permission denied

#### 触发代码

```typescript
const resfilePath = this.context.resourceDir;
const newFilePath = `${resfilePath}/test_new_file.txt`;

// 尝试在 resfile 目录创建文件
const file = fs.openSync(newFilePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
// 触发错误 13900012
```

#### 问题分析

- resfile 目录特性：
  - 应用安装后挂载为**只读**
  - 存放应用资源文件
  - 禁止创建或写入文件
- 这是系统安全限制

#### 解决方案

```typescript
// resfile 目录只用于读取资源
// 写入操作应在沙箱目录进行

const writablePath = `${this.context.filesDir}/new_file.txt`;
const file = fs.openSync(writablePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
fs.writeSync(file.fd, 'content');
fs.closeSync(file.fd);

// 读取 resfile 目录中的资源文件（允许）
const resourcePath = `${this.context.resourceDir}/existing_resource.txt`;
const readFile = fs.openSync(resourcePath, fs.OpenMode.READ_ONLY);
```

#### 关键提示

- resfile 目录是**只读资源目录**
- 写入文件应使用 `filesDir`、`cacheDir` 等沙箱目录
- 只能读取 resfile 中预置的资源文件

---

### 案例10: readSync参数类型错误（13900020）

#### 场景描述

`fs.readSync` 的 buffer 参数要求 ArrayBuffer 类型，传入 Uint8Array 导致参数类型错误。

#### 预期结果

**错误码: 13900020** - Invalid argument

#### 触发代码

```typescript
const readFile = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
const stat = fs.statSync(filePath);

// 创建 Uint8Array
const uint8Array = new Uint8Array(stat.size);

// 错误：直接传入 Uint8Array 作为 buffer 参数
const bytesRead = fs.readSync(readFile.fd, uint8Array);
// 触发错误 13900020
```

#### 问题分析

- `fs.readSync(fd, buffer)` 要求 buffer 为 **ArrayBuffer 类型**
- Uint8Array 不是 ArrayBuffer，而是 TypedArray
- TypeScript 类型系统未能捕获此错误
- 运行时检测到参数类型不匹配

#### 解决方案

```typescript
// 正确：传入 ArrayBuffer
const buffer = new ArrayBuffer(stat.size);
const bytesRead = fs.readSync(readFile.fd, buffer);

// 或：使用 Uint8Array 的 buffer 属性
const uint8Array = new Uint8Array(stat.size);
const bytesRead = fs.readSync(readFile.fd, uint8Array.buffer);

// 转换数据
const data = new Uint8Array(buffer, 0, bytesRead);
const text = String.fromCharCode(...data);
```

#### 关键提示

- `fs.readSync` 和 `fs.writeSync` 的 buffer 参数必须是 **ArrayBuffer**
- TypedArray（如 Uint8Array）需要使用 `.buffer` 属性获取底层 ArrayBuffer
- 注意 TypeScript 类型定义与实际 API 要求的差异

---

### 案例11: copyDir目标父目录不存在（13900020）

#### 场景描述

使用 `fs.copyDirSync` 复制目录到不存在父目录的目标路径。

#### 预期结果

**错误码: 13900020** - Invalid argument（也可能是 13900002）

#### 触发代码

```typescript
const srcDir = `${this.context.filesDir}/source_dir`;
const nonExistentParent = '/data/storage/el99/nonexistent_parent';
const destDir = `${nonExistentParent}/target_dir`;

// 目标父目录不存在
fs.copyDirSync(srcDir, destDir);
// 触发错误 13900020 或 13900002
```

#### 问题分析

- `copyDir` **不支持自动创建目标父目录**
- 目标父目录不存在导致参数无效
- 不同  版本可能返回不同错误码

#### 解决方案

```typescript
// 正确步骤：先创建目标父目录
// 步骤1: 创建目标父目录
const parentDir = `${this.context.filesDir}/parent_dir`;
fs.mkdirSync(parentDir);

// 步骤2: 执行 copyDir
const destDir = `${parentDir}/target_dir`;
fs.copyDirSync(srcDir, destDir);
```

#### 关键提示

- `copyDir` 不会自动创建目标目录的父目录
- 确保目标路径的父目录存在后再执行复制
- 使用 `fs.mkdirSync` 创建必要的目录结构

---

### 案例12: 系统路径读写权限（13900027）

#### 场景描述

尝试以读写模式访问系统受保护路径（如 /system/bin/sh）。

#### 预期结果

**错误码: 13900027** - Read-only file system

#### 触发代码

```typescript
const systemPath = '/system/bin/sh';

// 尝试以读写模式打开系统路径
const testFile = fs.openSync(systemPath, fs.OpenMode.READ_WRITE);
// 触发错误 13900027
```

#### 问题分析

- 系统路径（/system、/vendor 等）是**只读保护区域**
- 应用无权限修改系统文件
- 这是  的安全沙箱限制

#### 解决方案

```typescript
// 系统路径禁止写入，这是正确的安全设计
// 应用只能访问自己的沙箱目录

// 可访问的沙箱路径：
// - this.context.filesDir    // 应用文件目录
// - this.context.cacheDir    // 缓存目录
// - this.context.tempDir     // 临时目录

// 如需读取系统资源（仅读取）
// 某些系统路径可能允许读取，但不允许写入
```

#### 关键提示

- 系统路径是受保护的只读区域
- 应用只能在沙箱目录内进行读写操作
- 不要尝试访问或修改系统文件

---

### 案例13: 文件名超255字节限制（13900030）

#### 场景描述

尝试创建文件名超过 255 字节系统限制的文件。

#### 预期结果

**错误码: 13900030** - File name too long

#### 触发代码

```typescript
// 构造超长文件名（260字节 + 扩展名）
const baseName = 'a'.repeat(260);
const longFileName = `${baseName}.txt`; // 总长度 264 字节
const testFilePath = `${this.context.filesDir}/${longFileName}`;

const file = fs.openSync(testFilePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
// 触发错误 13900030
```

#### 问题分析

- 文件系统文件名最大长度：**255 字节**
- 测试文件名长度：264 字节
- 超过限制触发 "File name too long" 错误

#### 解决方案

```typescript
// 限制文件名长度
function createSafeFileName(baseName: string, extension: string): string {
  const maxBaseLength = 255 - extension.length;
  if (baseName.length > maxBaseLength) {
    baseName = baseName.substring(0, maxBaseLength);
  }
  return `${baseName}${extension}`;
}

const safeFileName = createSafeFileName('long_file_name', '.txt');
const filePath = `${this.context.filesDir}/${safeFileName}`;
const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
```

#### 关键提示

- 文件名限制是 **255 字节**（注意：中文等多字节字符需要计算字节数）
- 创建文件前验证文件名长度
- 超长文件名可能在不同平台表现不同

---

### 案例14: readSync I/O错误（13900005）

#### 场景描述

调用 fs.readSync() 读取文件时发生 I/O 错误。

#### 预期结果

**错误码: 13900005** - I/O error

#### 可能原因

1. 本地文件可能是文件系统内部错误
2. 文件读写过程中有文件变动
3. 跨端场景受网络条件影响

#### 解决方案

```typescript
// 检查文件完整性
const stat = fs.statSync(filePath);
if (stat.size === 0) {
  console.error('文件可能损坏或为空');
}

// 跨端场景建议增加错误处理
try {
  const bytesRead = fs.readSync(fd, buffer);
} catch (err) {
  if (err.code === 13900005) {
    console.error('I/O错误，建议检查网络状态或重试');
  }
}
```

#### 定界指引

**排查步骤：**

1. 检查本地文件完整性
2. 跨端场景检查网络状态
3. 确认文件读写过程中是否有其它进程修改文件

---

### 案例15: fd无效错误（13900008）

#### 场景描述

调用 fs.readSync()、fs.writeSync() 或 fs.closeSync() 时 fd 无效。

#### 预期结果

**错误码: 13900008** - Bad file descriptor

#### 可能原因

**readSync 场景：**

1. 调用 read 之前没有正确打开文件
2. 读取文件时文件已被关闭

**writeSync 场景：**

1. 只读方式打开的文件进行写入操作
2. fd 指向的不是普通文件（如目录）
3. fd 被关闭后再次使用

**closeSync 场景：**

1. fd 已关闭后重复调用 fs.closeSync(fd)
2. file 变量未定义或已失效

#### 解决方案

```typescript
// 确保 fd 有效
let file: fs.File | null = null;
try {
  file = fs.openSync(filePath, fs.OpenMode.READ_WRITE);
  fs.writeSync(file.fd, data);
} finally {
  if (file) {
    fs.closeSync(file.fd);
    file = null;
  }
}

// 检查 fd 有效性（系统可能占用 0、1、2）
function isValidFd(fd: number): boolean {
  return fd > 2;
}
```

#### 定界指引

**排查步骤：**

1. 检查 fd 是否正确打开
2. 确认 fd 在操作时未被关闭
3. 日志搜索 `fs.closeSync()` 找到调用位置，确认是否重复调用
4. 确认 fd 来源（业务代码生成还是系统提供）
5. 若 CreatewithFd 接口创建 fd 失败，先排查 fd 是否为 0-2，大于 2 的 fd 都是有效的

---

### 案例16: readSync无数据可读（13900010）

#### 场景描述

连续调用 fs.readSync() 但没有数据可读，抛出 try again 错误。

#### 预期结果

**错误码: 13900010** - Try again

#### 可能原因

1. 应用调用 readSync 时无数据可读
2. 系统调用 readSync（非应用代码），如多屏协同场景

#### 解决方案

```typescript
// 应用代码排查：搜索 fs.readSync 调用位置
// 系统调用排查：日志搜索 readSync 找到调用模块
```

#### 定界指引

**排查步骤：**

1. 若应用调用 readSync → 分析代码逻辑
2. 若代码不涉及 read → 一般为系统调用
3. 日志搜索 readSync 找到调用模块，根据模块日志标签分析
4. 多屏协同场景：日志搜索 distributedfile_daemon 查看分布式文件相关错误

---

## 5. 应用空间统计与缓存清理

### 5.1 cacheDir 目录说明

`getContext(this).cacheDir` 只返回系统默认缓存路径 `/data/storage/el2/base/haps/entry/cache`，但应用缓存可能存储在以下目录：

- /data/storage/el1/base/cache
- /data/storage/el1/base/haps/entry/cache
- /data/storage/el2/base/cache
- /data/storage/el2/base/haps/entry/cache

### 5.2 统计接口说明

`storageStatistics.getCurrentBundleStats()` 透传调用包管理的 `GetBundleStats` 接口。

统计逻辑：计算应用内所有文件夹名称为 `cache` 的目录大小。

### 5.3 缓存清理排查

清理 cacheDir 目录但缓存大小无变化时：

1. 检查上述四个目录是否有缓存未清理
2. 检查应用自己创建的 cache 文件夹是否有文件残留
3. 确认统计接口调用正确

#### 定界指引

**排查步骤：**

1. 检查多个 cache 目录是否有缓存未清理
2. 检查应用创建的 cache 文件夹是否有文件残留

---

## 6. 好实践总结

### 6.1 URI 处理规范

| 规则                           | 说明                                                                                                                                                                                                       |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 不使用字符串拼接               | 使用 fileUri API 方法处理路径                                                                                                                                                                              |
| 临时权限在应用进程存活期间有效 | 如果业务场景需要长期访问该文件（如文档编辑器的“最近打开”列表），**不应**要求用户每次都重新通过 Picker 选择，而是应该走**持久化授权机制**（`persistPermission` + `activatePermission`）。 |
| 区分 URI 类型                  | `file://media/`、`datashare://` 权限特性不同                                                                                                                                                           |

### 6.2 权限管理建议

| 建议           | 说明                                            |
| -------------- | ----------------------------------------------- |
| 了解权限范围   | PhotoViewPicker 只读，DocumentViewPicker 可读写 |
| 知晓授权类型   | Picker URI 是临时授权，重启后失效               |
| 遵守目录权限   | resfile 只读，filesDir 可读写                   |
| 不访问系统路径 | 系统路径受保护，禁止写入                        |

### 6.3 参数类型检查

| API            | 参数要求            | 常见错误        |
| -------------- | ------------------- | --------------- |
| fs.readSync    | buffer: ArrayBuffer | 传入 Uint8Array |
| fs.writeSync   | buffer: ArrayBuffer | 传入 Uint8Array |
| fs.openSync    | path: string        | 路径不存在      |
| fs.copyDirSync | src/dest: string    | 父目录不存在    |

### 6.4 路径构造规范

| 规范            | 说明                               |
| --------------- | ---------------------------------- |
| 确保父目录存在  | 创建文件前检查并创建父目录         |
| 控制文件名长度  | 文件名不超过 255 字节              |
| 使用 UTF-8 编码 | 文件名和路径使用 UTF-8 编码        |
| 使用沙箱路径    | 写入操作使用 filesDir、cacheDir 等 |
