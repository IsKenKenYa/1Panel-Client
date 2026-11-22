# ArkData 常见故障场景案例库

> 本卷为富模板案例库（含触发代码 / 根因分析 / 修复方案 / 定界指引），与精简风格的 `ArkData-Fault-Cases-1.md` 互补，二者均会被 skill 自动加载与检索。

---

## 1. 概述

### 1.1 ArkData 简介

ArkData 是  的数据管理 Kit，主要包含：

- **relationalStore**：==关系型==数据库（基于 SQLite），支持事务、加密、结果集、分布式同步
- **preferences**：轻量级键值对偏好存储
- **kvStore / distributedKVStore**：键值型数据库，支持分布式同步
- **dataShare**：跨应用数据共享
- **distributedDataObject**：分布式数据对象，内存级跨设备同步

本卷案例聚焦使用最广、错误码最密集的 **relationalStore（==关系型==数据库）**。

### 1.2 文档用途

- 快速识别 ArkData（relationalStore）API 使用中的常见错误
- 理解错误码含义、触发场景与底层映射关系
- 提供可复现的触发代码、根因分析与修复方案
- 给出日志定界关键字，辅助问题定位

### 1.3 适用场景

- ==关系型==数据库功能开发调试
- 故障排查与问题定位
- API 学习与好实践参考

### 1.4 数据库文件说明

| 文件类型    | 说明                                                                                    |
| :---------- | :-------------------------------------------------------------------------------------- |
| .db         | 数据库持久化文件，用于存储数据库数据                                                    |
| .db-wal     | 用于保存操作日志，可在事务失败时回滚更改，确保数据一致性。仅在WAL模式时存在             |
| .db-shm     | 共享内存文件，用于协调多个数据库连接对同一db文件的更改，防止数据冲突。仅在WAL模式时存在 |
| .key_lock   | 用于保存文件锁信息                                                                      |
| .pub_key    | 用于保存数据库密钥信息。仅在配置了数据库加密且未配置自定义加密参数时存在                |
| .db-dwr     | 用于保存文件头信息                                                                      |
| .db-compare | 用于保存所有DDL语句                                                                     |

### 1.5 SQL 调试方法

| 需求                | 接口                                 |
| :------------------ | :----------------------------------- |
| 查看SQL执行异常信息 | `on('sqliteErrorOccurred')`        |
| 获取INSERT语句      | `relationalStore.getInsertSqlInfo` |
| 获取UPDATE语句      | `relationalStore.getUpdateSqlInfo` |
| 获取DELETE语句      | `relationalStore.getDeleteSqlInfo` |
| 获取QUERY语句       | `relationalStore.getQuerySqlInfo`  |

---

## 2. 目录索引

### 2.1 按错误码分类

| 错误码   | 名称                                                                   | 涉及案例               |
| -------- | ---------------------------------------------------------------------- | ---------------------- |
| 14800000 | Inner error（内部错误/兜底码）                                         | 案例08、09             |
| 14800011 | Database corrupted（数据库损坏，JS 路径）                              | 案例07                 |
| 14800013 | The column index is out of range（列索引越界）                         | 案例01                 |
| 14800021 | SQLite error（SQLite 通用错误）                                        | 案例02、03、04、05、06 |
| 14800052 | SQLite database disk image is malformed（数据库损坏，Native API 路径） | 案例07                 |

### 2.2 按场景索引

| 案例编号 | 场景描述             | 预期结果            | 关键 API                                  |
| -------- | -------------------- | ------------------- | ----------------------------------------- |
| 案例01   | 结果集列索引越界     | 14800013            | `getLong`、`getString`、`getDouble` |
| 案例02   | 表或字段不存在       | 14800021            | `insert`、`executeSql`                |
| 案例03   | 重复建表             | 14800021            | `executeSql`                            |
| 案例04   | UNIQUE 约束冲突      | 14800021            | `insert`、`executeSql`                |
| 案例05   | 列数与 VALUES 不匹配 | 14800021            | `executeSql`、`insert`                |
| 案例06   | SQL 语法错误         | 14800021            | `executeSql`                            |
| 案例07   | 数据库损坏           | 14800011 / 14800052 | `query`、`getRdbStore`                |
| 案例08   | 联合主键设分布式表   | 14800000            | `setDistributedTables`                  |
| 案例09   | 远程查询无对端数据   | 14800000            | `remoteQuery`、`goToFirstRow`         |

---

## 3. 错误码速查表

| 错误码             | 英文名称                                | 中文含义                      | 常见触发原因                                                                     |
| ------------------ | --------------------------------------- | ----------------------------- | -------------------------------------------------------------------------------- |
| **14800000** | Inner error                             | 内部错误（兜底码）            | 联合主键设分布式表、远程查询无对端、权限缺失、native 返回 JS 不识别的码          |
| **14800011** | Database corrupted                      | 数据库损坏（JS 路径）         | DB 文件被破坏 / 页错位 / 加密密钥不一致                                          |
| **14800013** | The column index is out of range        | 列索引越界                    | `getXxx(index)` 的 index ≥ columnCount 或 < 0；空结果集读取                   |
| **14800021** | SQLite error                            | SQLite 通用错误               | 语法错、表/列不存在、约束冲突、列数不匹配、违反 SQLite 限制                      |
| **14800052** | SQLite database disk image is malformed | 数据库损坏（Native API 路径） | 同 14800011，C-API 表面层把`SQLITE_CORRUPT(11)`/`SQLITE_NOTADB(26)` 映射而来 |

> **第一原则**：定位错误码时，**先问"这个码来自 JS API 还是 xxx"**。同一个损坏，JS 报 `14800011`、xxx 报 `14800052`（见 §5.1）。

---

## 4. 案例详解

---

### 案例01: 结果集列索引越界（14800013）

#### 场景描述

查询数据库后，调用 `ResultSet.getLong`、`getString`、`getDouble` 等接口按列下标读取数据时，传入的下标越界（超出列数或为负），或在空结果集上读取，触发错误。

#### 预期结果

**错误码: 14800013** - The column index is out of range

#### 触发代码

```typescript
let predicates = new relationalStore.RdbPredicates('test_table');
let rs = await store.query(predicates, ['id', 'name', 'value']);   // 列数 = 3，合法下标 0..2
await rs.goToFirstRow();

rs.getLong(99);      // 触发错误 14800013：下标远超列数
// rs.getString(-1); // 负下标同样触发 14800013
// rs.getDouble(3);  // 下标 == 列数（经典 off-by-one）同样触发 14800013
```

#### 问题分析

- `ResultSet.getXxx(columnIndex)` 的合法列下标区间是 `[0, columnCount - 1]`
- `columnIndex >= columnCount` 或 `columnIndex < 0` 都会返回 `E_COLUMN_OUT_RANGE`，JS 层映射为 14800013
- 空结果集（`goToFirstRow()` 失败后仍调用 `getXxx`）也会走同一条错误路径

#### 解决方案

```typescript
// 方案1：固定 SELECT 列序，下标抽成具名常量
const IDX_ID = 0;
const IDX_NAME = 1;
const IDX_VALUE = 2;
let rs = await store.query(predicates, ['id', 'name', 'value']);
while (await rs.goToNextRow()) {
  let id = rs.getLong(IDX_ID);
  let name = rs.getString(IDX_NAME);
}

// 方案2：按列名取下标，避免下标与列序耦合
let idxName = rs.getColumnIndex('name');
let name = rs.getString(idxName);

// 方案3：读取前先判断结果集是否有数据
if (await rs.goToFirstRow()) {
  let name = rs.getString(rs.getColumnIndex('name'));
}
```

#### 关键提示

- 合法列下标是 `0 .. columnCount - 1`，`columnCount` 本身就是越界
- `query` 传入的列数组顺序决定下标，列序变了下标也要跟着变
- 空结果集直接 `getXxx` 也会报 14800013，排查时先确认是否有数据

#### 定界指引

**日志搜索关键字：**

- `index.*is out of range`
- `Invalid columnIndex`

**排查步骤：**

1. 看调用栈，定位是哪个 `getLong`、`getString`、`getDouble` 抛错
2. 核对 `store.query(predicates, [列数组])` 传入的列数组顺序与长度
3. 检查 `getXxx(index)` 的 index 是否 `>= columnCount` 或 `< 0`
4. 确认结果集非空（`goToFirstRow()` / `goToNextRow()` 返回值）后再读取

---

### 案例02: SQL 执行失败-表或字段不存在（14800021）

#### 场景描述

执行 `INSERT`/`UPDATE`/`DELETE`/`SELECT` 或 `executeSql` 时，SQL 中引用了数据库中不存在的表或不存在的字段，SQLite 返回通用错误。

#### 预期结果

**错误码: 14800021** - SQLite error

#### 触发代码

```typescript
// 场景A：插入不存在的表
let vb: relationalStore.ValuesBucket = { name: 'test', value: 1 } as relationalStore.ValuesBucket;
await store.insert('non_existent_table', vb);   // 触发错误 14800021：no such table

// 场景B：ValuesBucket 含表中不存在的列
let vb2: relationalStore.ValuesBucket = { name: 'hello', fake_column: 42 } as relationalStore.ValuesBucket;
await store.insert('test_table', vb2);           // 触发错误 14800021：no such column
```

#### 问题分析

- DDL/DML 引用的表名或列名与实际 schema 不一致
- `ValuesBucket` 的 key 必须与表字段一一对应，多余的 key（如 `fake_column`）会被当作列名解析

#### 解决方案

```typescript
// 方案1：操作前确保表已建好
await store.executeSql(
  'CREATE TABLE IF NOT EXISTS test_table (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, value INTEGER)');

// 方案2：表名/列名用常量集中维护，避免拼写不一致
const TABLE = 'test_table';
const COL_NAME = 'name';
let vb: relationalStore.ValuesBucket = { [COL_NAME]: 'test', value: 1 } as relationalStore.ValuesBucket;
await store.insert(TABLE, vb);
```

#### 关键提示

- 列名拼写错误、大小写不一致、多余字段都会触发 no such column
- 表名/列名建议用常量维护，避免散落字符串

#### 定界指引

**日志搜索关键字：**

- `Error.*no such table`
- `Error.*no such column`

**排查步骤：**

1. 打印 `err.message`，SQLite 文本会明确指出缺失的表/列名
2. 用 `PRAGMA table_info(表名)` 或查 `sqlite_master` 核对实际 schema
3. 检查建表语句与读写语句是否在同一库、同一表名下

---

### 案例03: SQL 执行失败-重复建表（14800021）

#### 场景描述

重复执行 `CREATE TABLE` 且未带 `IF NOT EXISTS`，第二次执行时表已存在，触发错误。

#### 预期结果

**错误码: 14800021** - SQLite error

#### 触发代码

```typescript
await store.executeSql('CREATE TABLE test_dup (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)');
await store.executeSql('CREATE TABLE test_dup (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)');
// 触发错误 14800021：table test_dup already exists
```

#### 问题分析

- `CREATE TABLE` 不带 `IF NOT EXISTS` 时，表已存在即报错
- 常见于初始化代码被多次调用、或升级流程重复建表

#### 解决方案

```typescript
// DDL 一律带 IF NOT EXISTS
await store.executeSql(
  'CREATE TABLE IF NOT EXISTS test_dup (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)');
```

#### 关键提示

- 所有 `CREATE TABLE` 默认加 `IF NOT EXISTS`
- 同理 `CREATE INDEX`、`CREATE TRIGGER` 也建议加 `IF NOT EXISTS`

#### 定界指引

**日志搜索关键字：**

- `Error.*table.*already exists`

**排查步骤：**

1. 确认报错表名，检查是否有重复建表逻辑（多处 init、多次进入页面）
2. 建表语句统一加 `IF NOT EXISTS`

---

### 案例04: SQL 执行失败-UNIQUE 约束冲突（14800021）

#### 场景描述

向声明了 `UNIQUE` 或 `PRIMARY KEY` 的列插入重复值，或更新成已存在的值，触发约束冲突。

#### 预期结果

**错误码: 14800021** - SQLite error

#### 触发代码

```typescript
await store.executeSql(
  'CREATE TABLE IF NOT EXISTS test_unique (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, value INTEGER)');

let vb1: relationalStore.ValuesBucket = { name: 'unique_val', value: 100 } as relationalStore.ValuesBucket;
await store.insert('test_unique', vb1);

let vb2: relationalStore.ValuesBucket = { name: 'unique_val', value: 200 } as relationalStore.ValuesBucket;
await store.insert('test_unique', vb2);   // 触发错误 14800021：UNIQUE constraint failed
```

#### 问题分析

- `UNIQUE` / `PRIMARY KEY` / `NOT NULL` 等约束冲突统一归 14800021（不是单独错误码）
- 第二次插入相同的 `name='unique_val'` 违反唯一约束

#### 解决方案

```typescript
// 方案1：写入前先查是否存在
let predicates = new relationalStore.RdbPredicates('test_unique');
predicates.equalTo('name', 'unique_val');
let rs = await store.query(predicates, ['id']);
let exists = await rs.goToFirstRow();
rs.close();
if (!exists) {
  await store.insert('test_unique', vb2);
}

// 方案2：用 ON CONFLICT 做 upsert（API 版本支持时）
await store.executeSql(
  "INSERT INTO test_unique(name, value) VALUES('unique_val', 200) " +
  "ON CONFLICT(name) DO UPDATE SET value=excluded.value");
```

#### 关键提示

- UNIQUE / NOT NULL / CHECK 约束冲突都归 14800021，必须看 `err.message` 区分
- 业务上先查后写或用 `ON CONFLICT` 子句

#### 定界指引

**日志搜索关键字：**

- `Error.*UNIQUE constraint failed`
- `Error.*NOT NULL constraint failed`

**排查步骤：**

1. 看 `err.message` 确认是哪一列、哪种约束
2. 核对该列的约束定义与写入值

---

### 案例05: SQL 执行失败-列数与 VALUES 不匹配（14800021）

#### 场景描述

`INSERT` 语句显式给出 N 个列名，但 `VALUES` 只提供 M 个值（M ≠ N），触发错误。

#### 预期结果

**错误码: 14800021** - SQLite error

#### 触发代码

```typescript
await store.executeSql(
  'CREATE TABLE IF NOT EXISTS test_col_count (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, value INTEGER)');

await store.executeSql(
  "INSERT INTO test_col_count (id, name, value) VALUES (1, 'only_two_values')");
// 触发错误 14800021：3 columns but 2 values supplied
```

#### 问题分析

- 列名列表与 VALUES 值列表数量必须一致
- 用 `executeSql` 手拼 INSERT 时容易漏值

#### 解决方案

```typescript
// 推荐：用 store.insert + ValuesBucket，由框架拼参数，避免手拼出错
let vb: relationalStore.ValuesBucket = { name: 'ok', value: 1 } as relationalStore.ValuesBucket;
await store.insert('test_col_count', vb);

// 若必须手拼 SQL，列名与 VALUES 严格对齐，并用占位符 ?
await store.executeSql(
  'INSERT INTO test_col_count (name, value) VALUES (?, ?)', ['ok', 1]);
```

#### 关键提示

- 优先用 `store.insert` + `ValuesBucket`，而非手拼 SQL
- 手拼时列名与占位符 `?` 数量必须一致

#### 定界指引

**日志搜索关键字：**

- `columns but`
- `values were supplied`

**排查步骤：**

1. 看 `err.message`，SQLite 会给出 "N columns but M values were supplied"
2. 核对列名列表与 VALUES 的数量

---

### 案例06: SQL 执行失败-语法错误（14800021）

#### 场景描述

SQL 关键字拼写错误、对不存在的表执行 `ALTER`、或 SQL 结构非法，在 prepare 阶段报语法错误。

#### 预期结果

**错误码: 14800021** - SQLite error

#### 触发代码

```typescript
// 场景A：关键字拼写错误（SELECT 写成 SELEC）
await store.executeSql('SELEC * FROM EMPLOYEE');   // 触发错误 14800021：near "SELEC": syntax error

// 场景B：ALTER 不存在的表
await store.executeSql('ALTER TABLE non_existent_table ADD COLUMN extra TEXT');
// 触发错误 14800021：no such table / syntax error
```

#### 问题分析

- SQLite 在 prepare 阶段做语法解析，关键字错、结构错、引用不存在对象都会失败
- 归为 `E_SQLITE_ERROR` → 14800021

#### 解决方案

```typescript
// 方案1：校对关键字拼写
await store.executeSql('SELECT * FROM EMPLOYEE');

// 方案2：ALTER 前确认表存在
await store.executeSql(
  'CREATE TABLE IF NOT EXISTS test_real (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)');
await store.executeSql('ALTER TABLE test_real ADD COLUMN extra TEXT');
```

#### 关键提示

- SQL 开头不要带注释、关键字不要拼错
- 含 `IN` 时括号内必须传 `?` 占位符或具体值，不要传空
- 表名/字段名附近不要出现 `{`、`}`、`$` 等特殊字符

#### 定界指引

**日志搜索关键字：**

- `Error.*syntax error`
- `Error.*unrecognized token`
- `Error.*incomplete input`
- `Error.*near`

**排查步骤：**

1. 看 `err.message`，SQLite 会指出出错位置（near "xxx"）
2. 用 `on('sqliteErrorOccurred')` 监听 SQL 异常，或用 `relationalStore.getInsertSqlInfo` 等接口还原实际执行的 SQL

---

### 案例07: 数据库损坏（14800011 / Native API 14800052）

#### 场景描述

数据库文件（B-tree、文件头、WAL、SHM）因进程踩内存、误关 fd、断电、存储异常等被破坏，读写时报损坏错误。JS API 报 14800011，Native API（C-API）报 14800052，是同一类问题。

#### 预期结果

**错误码: 14800011** - Database corrupted
（Native API 路径：**错误码: 14800052** - SQLite database disk image is malformed）

#### 触发代码

```typescript
// 典型现象：增删改查任意接口失败，err.code = 14800011
try {
  let rs = await store.query(new relationalStore.RdbPredicates('GOODS'), ['id', 'name']);
} catch (err) {
  // err.code === 14800011，err.message 含 "corruption" / "unsupported file format"
}
```

#### 问题分析

- DB 文件被外部篡改 / 断电 / 存储异常 / 页错位，SQLite 读到非法页结构
- xxx 把 SQLite 原生码 `SQLITE_CORRUPT(11)`、`SQLITE_NOTADB(26)` 映射为 14800052；JS 把损坏映射为 14800011（详见 §5.1）
- 常见诱因：业务进程踩内存、误关 fd、加密库密钥不一致导致文件被错误解读

#### 解决方案

```typescript
// 方案1：删除并重建数据库（最直接）
try {
  await relationalStore.deleteRdbStore(context, STORE_CONFIG.name);
} catch (e) { /* 库可能已不存在 */ }
let store = await relationalStore.getRdbStore(context, STORE_CONFIG);
await store.executeSql('CREATE TABLE IF NOT EXISTS GOODS (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, price INTEGER)');

// 方案2：接入备份恢复，从上次正常备份还原
// 方案3：排查并修复业务进程踩内存 / 误关 fd 的问题，避免再次损坏
```

#### 关键提示

- 14800052（Native API）与 14800011（JS）是同一损坏，跨层比对时要做映射
- 加密库密钥每次打开必须一致，否则文件会被当作损坏（见 §5.2）
- 建议接入备份恢复机制，避免用户数据丢失

#### 定界指引

**日志搜索关键字：**

- `Error.*database corruption`
- `Error.*unsupported file format`
- `database disk image is malformed`

**排查步骤：**

1. 先确认报错来自 JS（14800011）还是 Native API（14800052）
2. 用 `PRAGMA integrity_check` 复核库完整性
3. 排查业务是否有踩内存、误关 fd、多进程并发写同一文件等问题
4. 若为加密库，核对每次打开的密钥参数是否一致

---

### 案例08: 分布式表设置失败-联合主键（14800000）

#### 场景描述

对带联合主键（复合主键）的表调用 `setDistributedTables` 设置分布式表失败。

#### 预期结果

**错误码: 14800000** - Inner error

#### 触发代码

```typescript
await store.executeSql(
  'CREATE TABLE IF NOT EXISTS test_composite_pk (a INTEGER, b INTEGER, name TEXT, PRIMARY KEY(a, b))');

await store.setDistributedTables(['test_composite_pk']);
// 触发错误 14800000：不支持联合主键的分布式表
```

#### 问题分析

- 分布式表不支持联合主键，框架在主键解析阶段返回非 SQL 类错误
- 该类"框架路径失败"在 JS 层常以兜底码 14800000 上抛

#### 解决方案

```typescript
// 分布式表改用单列主键
await store.executeSql(
  'CREATE TABLE IF NOT EXISTS test_dist (id INTEGER PRIMARY KEY AUTOINCREMENT, a INTEGER, b INTEGER, name TEXT)');
await store.setDistributedTables(['test_dist']);
```

#### 关键提示

- 14800000 是兜底码（native 给了 JS 不认识的码），必须看 `err.message` 才能定位真实原因
- 分布式相关操作还需组网环境与对应权限

#### 定界指引

**日志搜索关键字：**

- `Not support create distributed table with composite primary keys`
- `Get distributed data manager failed`

**排查步骤：**

1. 确认表的主键是否为联合主键
2. 看 `err.message` 区分是主键不支持、还是数据管理服务启动失败
3. 分布式场景确认已声明所需权限（如 `ohos.permission.DISTRIBUTED_DATASYNC`）并处于组网环境

---

### 案例09: 远程查询无对端数据（14800000）

#### 场景描述

调用 `remoteQuery` 后用 `goToFirstRow` 取数据失败，常因对端不存在、未组网、或对端无符合条件的数据。

#### 预期结果

**错误码: 14800000** - Inner error

#### 触发代码

```typescript
let predicates = new relationalStore.RdbPredicates('test_remote');
predicates.equalTo('id', -1);

let rs = await new Promise<relationalStore.ResultSet>((resolve, reject) => {
  store.remoteQuery('0.0.0.0', 'test_remote', predicates, ['id', 'name'],
    (e, r) => { if (e) reject(e); else resolve(r); });
});
await rs.goToFirstRow();   // 触发错误 14800000：非法 device / 无对端
```

#### 问题分析

- `remoteQuery` 需要分布式组网环境，非法 deviceId 或无对端必然失败
- 对端数据库无符合条件数据时，`goToFirstRow` 取不到数据

#### 解决方案

```typescript
// 方案1：远程查询前确认组网与 deviceId 有效
// 方案2：确保对端数据库存在要查询的数据后再发起 remoteQuery
// 方案3：补齐分布式所需权限（ohos.permission.DISTRIBUTED_DATASYNC 等）
```

#### 关键提示

- `remoteQuery` 依赖分布式组网，单机/非法 device 必失败
- 14800000 受运行条件限制，不同设备/版本可能抛不同下层码

#### 定界指引

**日志搜索关键字：**

- `remoteQuery`
- `distributed`

**排查步骤：**

1. 确认设备已组网、deviceId 有效
2. 确认对端库中有符合 `predicates` 条件的数据
3. 确认已声明分布式数据同步权限

---

## 5. 附录

### 5.1 xxx ↔ JS 错误码映射

同一个数据库损坏，Native API（C-API）与 JS（NAPI）报不同错误码：

| API 表面层                           | 错误码   | 来源                                                                                   |
| ------------------------------------ | -------- | -------------------------------------------------------------------------------------- |
| JS（`@ohos.data.relationalStore`） | 14800011 | NAPI 层把损坏映射为`E_DB_CORRUPTED`                                                  |
| Native API（`OH_Rdb_*` C-API）     | 14800052 | 把 SQLite`SQLITE_CORRUPT(11)`、`SQLITE_NOTADB(26)` 映射为 `RDB_E_SQLITE_CORRUPT` |

**定位原则**：拿到损坏类错误码时，先确认报错来自 JS API 还是 xxx，再按对应口径解读；跨层比对时套用 `14800052 → 14800011` 映射。

```typescript
// 应用层统一码口径的示例
function mapCode(code: number): number {
  if (code === 14800052) return 14800011;  // xxx 损坏码 → JS 损坏码
  return code;
}
```

### 5.2 加密数据库排查

- 自定义密钥参数每次打开必须完全一致，否则文件会被当作损坏（报 14800011）
- HUKS 生成根密钥失败时无法生成加密库密钥，业务应重试打开加密库
- 日志搜索关键字：`01650.*Init.*retry.*error`（error 不为 0 表示生成失败）

### 5.3 ResultSet 资源释放范式

- **JS**：`rs` 声明在 try 外，`finally` 中 `if (rs != null) rs.close()`，即使中途 `getXxx` 抛错也关闭

```typescript
let rs: relationalStore.ResultSet | null = null;
try {
  rs = await store.query(predicates, ['id', 'name']);
  while (await rs.goToNextRow()) {
    // ... 读取
  }
} finally {
  try { if (rs != null) rs.close(); } catch (e) {}
}
```

---

## 6. 好实践总结

### 6.1 列下标管理

| 规则             | 说明                                                       |
| ---------------- | ---------------------------------------------------------- |
| 固定 SELECT 列序 | 下标抽具名常量（如`IDX_ID = 0`）                         |
| 按列名取下标     | 用`getColumnIndex` 避免 schema 漂移                      |
| 读取前判空       | `goToFirstRow`/`goToNextRow` 返回值判断后再 `getXxx` |

### 6.2 SQL 编写规范

| 规则                              | 说明                             |
| --------------------------------- | -------------------------------- |
| DDL 带`IF NOT EXISTS`           | 避免重复建表触发 14800021        |
| 优先`insert` + `ValuesBucket` | 避免手拼 SQL 出错                |
| 列名与`?` 占位符对齐            | 数量必须一致                     |
| 关键字不拼错                      | `SELECT` 不要写成 `SELEC` 等 |
| 表名/字段名附近无特殊字符         | 不要出现`{`、`}`、`$`      |

### 6.3 结果集与连接管理

| 规则                    | 说明           |
| ----------------------- | -------------- |
| `finally` 关闭 `rs` | 防 fd 泄漏     |
| 读连接只读              | 写操作用写连接 |
| 不并发查删同一批数据    | 业务控制时序   |

### 6.4 加密与安全等级

| 规则         | 说明                                         |
| ------------ | -------------------------------------------- |
| 密钥每次一致 | 否则报 14800011                              |
| 安全等级匹配 | `StoreConfig.securityLevel` 与使用场景匹配 |
| 加密库防误改 | 减小被外部工具篡改概率                       |

### 6.5 xxx/JS 错误码口径

| 规则        | 说明                            |
| ----------- | ------------------------------- |
| 先认 API 层 | JS 报 14800011，xxx 报 14800052 |
| 跨层映射    | `14800052 ↔ 14800011`        |
