# 数据库管理模块架构设计

> 2026-03-26 修正：
> 本文下方部分端点清单来自早期规划，和当前 `swagger.json` 以及已落地代码并不完全一致。
> 当前实施以 `database_api_analysis.md/.json`、`阶段总计划（docs/development/modules/阶段2计划.md）` 与运行时代码为准。
> 当前真实已落地能力为 `list / detail / form / remote test / redis config / bind user / description & password write`；
> `backup / restore / backup list` 需要联动 `/backups/*`，不在 `database` 标签端点内直接完成。

## 模块目标

- 适配 Open1PanelApp 作为 1Panel Linux 运维面板社区版的定位
- 提供完整的MySQL、PostgreSQL、Redis数据库管理能力
- 支持数据库创建、配置、备份恢复、性能监控
- 提供数据库用户管理、权限管理功能
- 统一数据库状态管理与错误反馈

## 功能完整性清单

基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 的 Database 相关标签共 42 个端点:

### 通用数据库操作 (Database Common - 3个端点)
1. GET /databases - 获取数据库列表
2. POST /databases/search - 搜索数据库
3. POST /databases/load - 加载数据库

### MySQL管理 (Database Mysql - 14个端点)
1. POST /databases/mysql - 创建MySQL数据库
2. POST /databases/mysql/list - MySQL数据库列表
3. POST /databases/mysql/search - 搜索MySQL数据库
4. POST /databases/mysql/update - 更新MySQL数据库
5. POST /databases/mysql/del - 删除MySQL数据库
6. POST /databases/mysql/backup - 备份MySQL数据库
7. POST /databases/mysql/restore - 恢复MySQL数据库
8. POST /databases/mysql/backup/list - 备份列表
9. POST /databases/mysql/backup/del - 删除备份
10. POST /databases/mysql/user - 用户管理
11. POST /databases/mysql/user/create - 创建用户
12. POST /databases/mysql/user/update - 更新用户
13. POST /databases/mysql/user/del - 删除用户
14. POST /databases/mysql/privilege - 权限管理

### PostgreSQL管理 (Database PostgreSQL - 9个端点)
1. POST /databases/postgresql - 创建PostgreSQL数据库
2. POST /databases/postgresql/list - PostgreSQL数据库列表
3. POST /databases/postgresql/search - 搜索PostgreSQL数据库
4. POST /databases/postgresql/update - 更新PostgreSQL数据库
5. POST /databases/postgresql/del - 删除PostgreSQL数据库
6. POST /databases/postgresql/backup - 备份PostgreSQL数据库
7. POST /databases/postgresql/restore - 恢复PostgreSQL数据库
8. POST /databases/postgresql/user - 用户管理
9. POST /databases/postgresql/privilege - 权限管理

### Redis管理 (Database Redis - 7个端点)
1. POST /databases/redis - 创建Redis数据库
2. POST /databases/redis/list - Redis数据库列表
3. POST /databases/redis/search - 搜索Redis数据库
4. POST /databases/redis/update - 更新Redis数据库
5. POST /databases/redis/del - 删除Redis数据库
6. POST /databases/redis/persistence - 持久化配置
7. POST /databases/redis/keys - 键管理

### 数据库通用操作 (Database - 9个端点)
1. POST /databases/status - 数据库状态
2. POST /databases/operate - 数据库操作
3. POST /databases/remote - 远程数据库管理
4. POST /databases/remote/create - 创建远程数据库
5. POST /databases/remote/update - 更新远程数据库
6. POST /databases/remote/del - 删除远程数据库
7. POST /databases/remote/test - 测试远程连接
8. POST /databases/remote/vars - 远程变量
9. POST /databases/remote/load - 加载远程数据库

## 业务流程与交互验证

### 数据库创建流程
- 选择数据库类型（MySQL/PostgreSQL/Redis）
- 配置数据库参数（名称、字符集、用户名密码）
- 检查创建条件
- 执行创建并显示进度
- 创建完成后跳转到数据库列表

### 数据库备份流程
- 选择需要备份的数据库
- 配置备份参数（备份名称、存储位置）
- 执行备份并显示进度
- 备份完成后更新备份列表

### 数据库恢复流程
- 从备份列表选择备份文件
- 确认恢复操作（警告数据覆盖）
- 执行恢复并显示进度
- 恢复完成后验证数据完整性

### 用户管理流程
- 进入数据库详情页
- 点击用户管理选项卡
- 显示用户列表
- 支持创建、修改、删除用户
- 支持权限分配

### 性能监控流程
- 进入数据库详情页
- 显示性能指标（连接数、查询数、缓存命中率）
- 显示资源使用图表
- 支持慢查询分析

## 关键边界与异常

### 数据库操作异常
- 数据库创建失败的诊断
- 数据库连接失败的排查
- 权限不足的提示
- 资源限制的处理

### 备份恢复异常
- 备份失败的诊断
- 恢复失败的回滚
- 存储空间不足的提示
- 备份文件损坏的处理

### 用户管理异常
- 用户名冲突的处理
- 权限分配失败的诊断
- 用户删除时的依赖检查

### 性能监控异常
- 监控数据获取失败
- 性能指标异常的告警
- 慢查询分析超时

## 模块分层与职责

### 前端
- UI页面: 数据库列表、数据库详情、备份管理、用户管理、性能监控
- 状态管理: 数据库列表缓存、操作状态、监控数据

### 服务层
- API适配: DatabaseV2Api
- 数据模型: Database、DatabaseUser、DatabaseBackup、DatabaseStats等

## 数据流

1. UI触发 -> Provider/Service -> API客户端请求
2. API响应解析 -> 模型映射 -> 状态更新
3. 状态更新 -> UI刷新 -> 用户反馈
4. 长时间操作 -> 进度轮询 -> 状态更新

## 与现有实现的差距

- 列表、详情、表单、远程库、Redis 配置页已落地
- 远程数据库详情页已收紧为只读，不再暴露当前不支持的写操作
- Redis 创建入口已临时禁用，等待真实创建链路完成后再开放
- 备份管理页已通过 `/backups/*` 接入 `list / create / restore / delete`
- 用户管理页已按真实 V2 接入 `MySQL bind user` 与 `PostgreSQL bind user / privilege`
- 性能监控图表与更细分的状态页仍缺

## 评审记录

| 日期 | 评审人 | 结论 | 备注 |
| --- | --- | --- | --- |
| 待定 | 评审人A | 待评审 | |
| 待定 | 评审人B | 待评审 | |
