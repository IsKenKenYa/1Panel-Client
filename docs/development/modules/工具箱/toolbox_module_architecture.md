# 工具箱模块架构设计

## 模块目标

- 适配 Open1PanelApp 作为 1Panel Linux 运维面板社区版的定位
- 提供统一的运维工具管理入口
- 支持ClamAV、Fail2ban、FTP、磁盘管理等工具
- 提供工具状态监控和配置管理
- 统一工具操作与错误反馈

## 功能完整性清单

基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json，工具箱模块共包含 38 个端点:

### ClamAV病毒扫描 (12端点)
1. GET /toolbox/clam - 获取ClamAV状态
2. POST /toolbox/clam/update - 更新ClamAV配置
3. POST /toolbox/clam/scan - 执行病毒扫描
4. GET /toolbox/clam/scan/result - 获取扫描结果
5. POST /toolbox/clam/scan/stop - 停止扫描
6. GET /toolbox/clam/infected - 获取感染文件列表
7. POST /toolbox/clam/infected/del - 删除感染文件
8. POST /toolbox/clam/infected/restore - 恢复隔离文件
9. POST /toolbox/clam/database/update - 更新病毒库
10. GET /toolbox/clam/database/status - 获取病毒库状态
11. POST /toolbox/clam/start - 启动ClamAV
12. POST /toolbox/clam/stop - 停止ClamAV

### FTP服务 (8端点)
1. GET /toolbox/ftp - 获取FTP服务状态
2. POST /toolbox/ftp/update - 更新FTP配置
3. GET /toolbox/ftp/users - 获取FTP用户列表
4. POST /toolbox/ftp/user - 创建FTP用户
5. POST /toolbox/ftp/user/update - 更新FTP用户
6. POST /toolbox/ftp/user/del - 删除FTP用户
7. POST /toolbox/ftp/start - 启动FTP服务
8. POST /toolbox/ftp/stop - 停止FTP服务

### Fail2ban入侵防御 (7端点)
1. GET /toolbox/fail2ban - 获取Fail2ban状态
2. POST /toolbox/fail2ban/update - 更新配置
3. GET /toolbox/fail2ban/jails - 获取监狱列表
4. POST /toolbox/fail2ban/jail - 创建监狱
5. POST /toolbox/fail2ban/jail/update - 更新监狱
6. POST /toolbox/fail2ban/jail/del - 删除监狱
7. GET /toolbox/fail2ban/banned - 获取封禁IP列表

### 主机工具 (7端点)
1. GET /toolbox/host/info - 获取主机信息
2. POST /toolbox/host/diagnose - 系统诊断
3. POST /toolbox/host/clean - 系统清理
4. GET /toolbox/host/ports - 端口占用查看
5. GET /toolbox/host/processes - 进程管理
6. POST /toolbox/host/reboot - 重启主机
7. POST /toolbox/host/shutdown - 关机

### 磁盘管理 (4端点)
1. GET /toolbox/disk - 获取磁盘列表
2. GET /toolbox/disk/{id} - 获取磁盘详情
3. POST /toolbox/disk/mount - 挂载磁盘
4. POST /toolbox/disk/umount - 卸载磁盘

## 业务流程与交互验证

### 病毒扫描流程
- 进入ClamAV管理页面
- 查看服务状态和病毒库版本
- 配置扫描路径和规则
- 执行扫描任务
- 查看扫描结果
- 处理感染文件

### FTP账户管理流程
- 进入FTP管理页面
- 查看服务状态
- 创建FTP账户
- 配置访问权限和目录
- 启用/禁用账户

### Fail2ban配置流程
- 进入Fail2ban管理页面
- 查看服务状态和封禁统计
- 配置监狱规则
- 查看封禁IP列表
- 手动解封IP

### 磁盘管理流程
- 进入磁盘管理页面
- 查看磁盘列表和状态
- 执行挂载/卸载操作
- 查看磁盘使用情况

## 关键边界与异常

### 服务异常
- 服务启动失败的诊断
- 服务配置错误的处理
- 服务依赖检查

### 操作异常
- 权限不足的提示
- 资源不存在的处理
- 操作冲突的处理

### 数据异常
- 磁盘空间不足
- 病毒库更新失败
- 配置文件损坏

## 模块分层与职责

### 前端
- UI页面: 工具状态概览、各工具管理页面、操作日志
- 状态管理: 工具状态、配置缓存、操作结果

### 服务层
- API适配: ToolboxV2Api
- 数据模型: ClamAV、FTP、Fail2ban、Disk等

## 数据流

1. UI触发 -> Provider/Service -> API客户端请求
2. API响应解析 -> 模型映射 -> 状态更新
3. 状态更新 -> UI刷新 -> 用户反馈
4. 工具操作 -> 状态轮询 -> 结果确认

## 与现有实现的差距

- 工具箱统一入口页面缺失
- ClamAV管理页面缺失
- FTP管理页面缺失
- Fail2ban管理页面缺失
- 磁盘管理页面缺失

## 评审记录

| 日期 | 评审人 | 结论 | 备注 |
| --- | --- | --- | --- |
| 待定 | 评审人A | 待评审 | |
| 待定 | 评审人B | 待评审 | |

---

**文档版本**: 1.0
**最后更新**: 2026-02-14
