# ArkData故障案例库

> 本文档用于故障定位知识库，按错误码分类整理常见故障案例。

---

## 前置知识

### 数据库文件说明

| 文件类型    | 说明                                                                                    |
| :---------- | :-------------------------------------------------------------------------------------- |
| .db         | 数据库持久化文件，用于存储数据库数据                                                    |
| .db-wal     | 用于保存操作日志，可在事务失败时回滚更改，确保数据一致性。仅在WAL模式时存在             |
| .db-shm     | 共享内存文件，用于协调多个数据库连接对同一db文件的更改，防止数据冲突。仅在WAL模式时存在 |
| .key_lock   | 用于保存文件锁信息                                                                      |
| .pub_key    | 用于保存数据库密钥信息。仅在配置了数据库加密且未配置自定义加密参数时存在                |
| .db-dwr     | 用于保存文件头信息                                                                      |
| .db-compare | 用于保存所有DDL语句                                                                     |

### SQL调试方法

| 需求                | 接口                                 |
| :------------------ | :----------------------------------- |
| 查看SQL执行异常信息 | `on('sqliteErrorOccurred')`        |
| 获取INSERT语句      | `relationalStore.getInsertSqlInfo` |
| 获取UPDATE语句      | `relationalStore.getUpdateSqlInfo` |
| 获取DELETE语句      | `relationalStore.getDeleteSqlInfo` |
| 获取QUERY语句       | `relationalStore.getQuerySqlInfo`  |

---

## 故障案例

---

### 案例1：分布式表设置失败（联合主键）

- **错误码：** 14800000
- **故障现象：** 调用`setDistributedTables`设置分布式表失败
- **涉及接口：** `setDistributedTables`
- **可能原因：** 设置分布式表不支持联合主键
- **关键日志：** `Not support create distributed table with composite primary keys`
- **解决方案：** 设置分布式表时不要使用联合主键

---

### 案例2：多进程开库失败（进程冻结导致锁超时）

- **错误码：** 14800000
- **故障现象：** 多进程操作数据库时，其它进程调用`getRdbStore`开库失败
- **涉及接口：** `getRdbStore`
- **可能原因：** 多进程中一个进程被冻结，数据库锁被冻结进程持有无法释放
- **关键日志：**
  - `Freeze pid: 进程号 success`
  - `PID 进程号 has been frozen`
  - `ConnectionPool.*code:-15`
- **解决方案：**
  - 进程退后台时不要操作数据库，避免多进程并发操作
  - 调用`requestSuspendDelay`申请短时任务或`startBackgroundRunning`申请长时任务

---

### 案例3：读连接执行写操作失败

- **错误码：** 14800000
- **故障现象：** 数据库操作失败
- **可能原因：** 使用读连接进行写操作，读连接仅可执行读操作
- **解决方案：** 确保读连接只执行读操作，写操作使用写连接

---

### 案例4：并发查询和删除同一批数据失败

- **错误码：** 14800000
- **故障现象：** 获取结果集后调用`getLong`等接口获取数据失败
- **涉及接口：** `execute`、`executeSql`、`delete`、`getLong`
- **可能原因：** 并发查询和删除同一批数据
- **解决方案：** 业务控制时序，不要并发查询和删除同一批数据

---

### 案例5：事务中删除触发器后重建表再删触发器失败

- **错误码：** 14800000
- **故障现象：** 事务中执行DDL操作失败
- **涉及接口：** `beginTransaction`、`execute`、`executeSql`
- **可能原因：** 事务未提交时，依次执行删除触发器a、删除表A、重建表A、再次删除触发器a
- **解决方案：** 避免在事务未提交时执行此类操作序列

---

### 案例6：加密数据库打开失败（根密钥生成失败）

- **错误码：** 14800000
- **故障现象：** 调用`getRdbStore`打开加密数据库失败
- **涉及接口：** `getRdbStore`
- **可能原因：** HUKS生成根密钥失败，无法生成加密数据库密钥
- **关键日志：** `01650.*Init.*retry.*error`（error不为0）
- **解决方案：** 业务重试打开加密数据库

---

### 案例7：远程查询后获取数据失败

- **错误码：** 14800000
- **故障现象：** 调用`remoteQuery`后调用`goToFirstRow`获取数据失败
- **涉及接口：** `remoteQuery`、`goToFirstRow`
- **可能原因：** 对端数据库中不存在要查询的数据
- **解决方案：** 确保要查询的数据存在后再进行远程查询

---

### 案例8：设置分布式表失败（数据管理服务启动失败）

- **错误码：** 14800000
- **故障现象：** 调用`setDistributedTables`设置分布式表失败
- **涉及接口：** `setDistributedTables`
- **可能原因：** 数据管理服务启动失败
- **关键日志：** `Get distributed data manager failed`
- **解决方案：** 业务重试设置分布式表

---

### 案例9：加密数据库打开失败（密钥不匹配）

- **错误码：** 14800011
- **故障现象：** 调用`getRdbStore`打开加密数据库失败
- **涉及接口：** `getRdbStore`
- **可能原因：** 自定义密钥参数与创建数据库时的密钥参数不一致
- **解决方案：** 每次打开加密数据库时，确保自定义密钥参数一致

---

### 案例10：数据库操作失败（数据库文件异常）

- **错误码：** 14800011
- **故障现象：** 调用增删改查接口操作数据库失败
- **可能原因：** 数据库文件异常
- **关键日志：** `Error.*unsupported file format`、`Error.*database corruption`
- **解决方案：**
  - 解决业务进程踩内存或误关fd的问题
  - 接入备份恢复
  - 删除重建数据库

---

### 案例11：结果集获取数据失败（列索引越界）

- **错误码：** 14800013
- **故障现象：** 调用`getLong`、`getString`等接口获取数据失败
- **涉及接口：** `getLong`、`getString`
- **可能原因：** 传入的列索引参数超过表中字段数量或为负值
- **关键日志：** `index.*is out of range`、`Invalid columnIndex`
- **解决方案：** 确保传入参数符合预期，不要超过数据库表中的列数

---

### 案例12：SQL执行失败（语法错误）

- **错误码：** 14800021
- **故障现象：** 调用`executeSql`、`execute`、`executeSync`执行SQL失败
- **涉及接口：** `executeSql`、`execute`、`executeSync`
- **可能原因：** SQL拼写错误、存在语法问题
- **关键日志：** `Error.*unrecognized token`、`Error.*syntax error`、`Error.*incomplete input`
- **解决方案：**
  - SQL语句拼写完整
  - 触发器语句中不要存在RETURN关键字
  - SQL语句开头不要包含注释
  - SQL包含in时，括号中匹配值必须传?占位符或具体值，不要传空值
  - SQL中的表名或字段名附近不要存在`{`、`}`、`$`等特殊字符

---

### 案例13：SQL执行失败（表或字段不存在）

- **错误码：** 14800021
- **故障现象：** 调用`executeSql`、`execute`、`executeSync`执行SQL失败
- **涉及接口：** `executeSql`、`execute`、`executeSync`
- **可能原因：** 数据库中不存在某张表或表中不存在某个字段
- **关键日志：** `Error.*no such table`、`Error.*no such column`
- **解决方案：**
  - 建表或添加字段之后再操作数据库
  - 进行加固，重新创建丢失的表或添加字段

---

### 案例14：SQL执行失败（重复添加字段）

- **错误码：** 14800021
- **故障现象：** 调用`executeSql`、`execute`、`executeSync`执行SQL失败
- **涉及接口：** `executeSql`、`execute`、`executeSync`
- **可能原因：** 重复添加表中已存在的字段
- **关键日志：** `Error.*duplicate column name`
- **解决方案：** 不要重复添加表中已存在的字段

---

### 案例15：SQL执行失败（违反SQLite系统限制）

- **错误码：** 14800021
- **故障现象：** 调用`executeSql`、`execute`、`executeSync`执行SQL失败
- **涉及接口：** `executeSql`、`execute`、`executeSync`
- **可能原因：** 违反SQLite系统限制（字符串或BLOB长度超限、列数过多、SQL变量过多、表达式树过深、复合SELECT过多、附加库过多等）
- **关键日志：**
  - `too many SQL variables`
  - `string or blob too big`
  - `too many columns`
  - `expression tree too deep`
  - `too many terms in compound SELECT`
  - `too many attached databases`
- **解决方案：** 确保SQL执行时不违反SQLite系统限制，参考：https://sqlite.org/limits.html

---

### 案例16：结果集获取数据失败（单条数据超过2M）

- **错误码：** 14800012
- **故障现象：** 调用`getLong`等接口获取数据失败
- **涉及接口：** `getLong`
- **可能原因：** 查询的单条数据大小超过2M
- **关键日志：** `ResetStatement.*over 2MB`
- **解决方案：** 调用`queryWithoutRowCount`获取`LiteResultSet`后再查询单条大小超过2M的数据

---

### 案例17：结果集获取数据失败（表中无数据）

- **错误码：** 14800012
- **故障现象：** 调用`getLong`等接口获取数据失败
- **涉及接口：** `getLong`
- **可能原因：** 表中无任何数据
- **解决方案：** 插入数据后再查询

---

### 案例18：结果集获取数据失败（无符合条件数据）

- **错误码：** 14800012
- **故障现象：** 调用`getLong`等接口获取数据失败
- **涉及接口：** `getLong`
- **可能原因：** 表中无符合查询条件的数据
- **解决方案：** 确保查询条件符合预期，可以查询到数据

---

## 快速索引表

| 错误码   | 案例      |
| :------- | :-------- |
| 14800000 | 案例1-8   |
| 14800011 | 案例9-10  |
| 14800013 | 案例11    |
| 14800021 | 案例12-15 |
| 14800012 | 案例16-18 |
