# SSH管理模块架构设计

## 模块目标

- 适配 Open1PanelApp 作为 1Panel Linux 运维面板社区版的定位
- 提供完整的SSH服务配置和管理能力
- 支持SSH会话创建、管理、断开
- 提供SSH密钥管理功能
- 支持SSH终端访问和命令执行
- 统一SSH状态管理与错误反馈

## 功能完整性清单

基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 的 SSH 标签共 12 个端点:

### SSH服务配置
1. GET /ssh - 获取SSH服务状态
2. POST /ssh/update - 更新SSH服务配置
3. POST /ssh/restart - 重启SSH服务
4. POST /ssh/stop - 停止SSH服务
5. POST /ssh/start - 启动SSH服务

### SSH会话管理
6. POST /ssh/session - 创建SSH会话
7. GET /ssh/sessions - 获取SSH会话列表
8. POST /ssh/session/operate - SSH会话操作
9. POST /ssh/session/close - 关闭SSH会话
10. GET /ssh/session/{id} - 获取SSH会话详情

### SSH密钥管理
11. POST /ssh/keys - SSH密钥列表
12. POST /ssh/keys/create - 创建SSH密钥
13. POST /ssh/keys/del - 删除SSH密钥

## 业务流程与交互验证

### SSH服务管理流程
- 进入SSH管理页面
- 显示SSH服务状态
- 支持启动/停止/重启SSH服务
- 配置SSH服务参数
- 保存配置并重启服务

### SSH会话创建流程
- 选择目标服务器
- 配置SSH连接参数
- 创建SSH会话
- 进入Web终端
- 执行命令操作
- 关闭SSH会话

### SSH密钥管理流程
- 进入SSH密钥管理页面
- 显示SSH密钥列表
- 支持创建新密钥
- 支持删除密钥
- 支持密钥导入导出

## 关键边界与异常

### SSH服务异常
- SSH服务启动失败的诊断
- SSH服务配置错误的处理
- 端口冲突的提示
- 权限不足的处理

### SSH会话异常
- 会话创建失败的诊断
- 连接超时的处理
- 会话中断的恢复
- 多会话冲突的处理

### SSH密钥异常
- 密钥创建失败的诊断
- 密钥删除的依赖检查
- 密钥权限不足的提示

### 终端操作异常
- 命令执行失败的诊断
- 终端连接中断的处理
- 大量输出的性能优化

## 模块分层与职责

### 前端
- UI页面: SSH服务管理、SSH会话列表、Web终端、SSH密钥管理
- 状态管理: SSH服务状态、会话列表、密钥列表、终端状态

### 服务层
- API适配: TerminalV2Api (SSH相关)
- 数据模型: SSHService、SSHSession、SSHKey、TerminalConfig等

## 数据流

1. UI触发 -> Provider/Service -> API客户端请求
2. API响应解析 -> 模型映射 -> 状态更新
3. 状态更新 -> UI刷新 -> 用户反馈
4. 终端连接 -> WebSocket -> 实时输出

## 与现有实现的差距

- SSH服务管理页面缺失
- SSH会话列表页面缺失
- Web终端功能缺失
- SSH密钥管理页面缺失

## 评审记录

| 日期 | 评审人 | 结论 | 备注 |
| --- | --- | --- | --- |
| 待定 | 评审人A | 待评审 | |
| 待定 | 评审人B | 待评审 | |
