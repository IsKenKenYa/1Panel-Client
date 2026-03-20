# 备份账户管理模块架构设计

## 模块目标

- 适配 Open1PanelApp 作为 1Panel Linux 运维面板社区版的定位
- 提供完整的备份源配置和管理能力
- 支持本地备份、S3、SFTP、WebDAV等多种备份方式
- 提供备份策略配置和自动备份功能
- 统一备份状态管理与错误反馈

## 功能完整性清单

基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 的 Backup Account 标签共 25 个端点:

### 备份账户管理
1. GET /backup/accounts - 获取备份账户列表
2. POST /backup/accounts/search - 搜索备份账户
3. POST /backup/accounts - 创建备份账户
4. POST /backup/accounts/update - 更新备份账户
5. POST /backup/accounts/del - 删除备份账户
6. GET /backup/accounts/{id} - 获取备份账户详情
7. POST /backup/accounts/test - 测试备份账户连接

### 备份操作
8. POST /backup/create - 创建备份
9. POST /backup/restore - 恢复备份
10. POST /backup/del - 删除备份
11. POST /backup/search - 搜索备份
12. GET /backup/list - 备份列表
13. GET /backup/{id} - 备份详情
14. POST /backup/download - 下载备份
15. POST /backup/upload - 上传备份

### 备份策略
16. POST /backup/schedule - 创建备份计划
17. POST /backup/schedule/update - 更新备份计划
18. POST /backup/schedule/del - 删除备份计划
19. GET /backup/schedules - 备份计划列表
20. POST /backup/schedule/enable - 启用备份计划
21. POST /backup/schedule/disable - 禁用备份计划

### 备份记录
22. GET /backup/records - 备份记录列表
23. POST /backup/records/search - 搜索备份记录
24. POST /backup/records/clean - 清理备份记录
25. GET /backup/records/{id} - 备份记录详情

## 业务流程与交互验证

### 备份账户配置流程
- 进入备份账户管理页面
- 选择备份类型（本地/S3/SFTP/WebDAV）
- 配置连接参数
- 测试连接
- 保存配置

### 创建备份流程
- 选择备份源
- 选择备份目标账户
- 配置备份参数
- 执行备份并显示进度
- 备份完成后更新列表

### 恢复备份流程
- 从备份列表选择备份
- 确认恢复操作（警告数据覆盖）
- 执行恢复并显示进度
- 恢复完成后验证数据

### 备份计划配置流程
- 进入备份计划页面
- 创建备份计划
- 配置计划时间
- 选择备份内容
- 启用计划

## 关键边界与异常

### 备份账户异常
- 连接失败的诊断
- 认证错误的处理
- 权限不足的提示
- 存储空间检查

### 备份操作异常
- 备份失败的诊断
- 恢复失败的回滚
- 存储空间不足的提示
- 网络中断的处理

### 备份计划异常
- 计划执行失败的诊断
- 计划冲突的处理
- 资源不足的跳过

## 模块分层与职责

### 前端
- UI页面: 备份账户列表、备份账户配置、备份列表、备份计划、备份记录
- 状态管理: 备份账户缓存、备份状态、计划状态

### 服务层
- API适配: BackupAccountV2Api
- 数据模型: BackupAccount、Backup、BackupSchedule、BackupRecord等

## 数据流

1. UI触发 -> Provider/Service -> API客户端请求
2. API响应解析 -> 模型映射 -> 状态更新
3. 状态更新 -> UI刷新 -> 用户反馈
4. 长时间操作 -> 进度轮询 -> 状态更新

## 与现有实现的差距

- 备份账户列表页面缺失
- 备份账户配置页面缺失
- 备份列表页面缺失
- 备份计划页面缺失
- 备份恢复功能缺失

## 评审记录

| 日期 | 评审人 | 结论 | 备注 |
| --- | --- | --- | --- |
| 待定 | 评审人A | 待评审 | |
| 待定 | 评审人B | 待评审 | |
