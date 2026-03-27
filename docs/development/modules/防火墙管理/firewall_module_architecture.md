# 防火墙管理模块架构设计

> 2026-03-26 修正：
> 本文下方部分路径与页面缺口描述来自早期规划，当前实际实现已切到 `/hosts/firewall/*`。
> 当前阶段二实施以 `firewall_api_analysis.md/.json`、`阶段2计划.md` 与运行时代码为准。
> 已落地能力为 `status / rules / ip / ports / rule form`，并已有 provider/widget/integration/api client 测试。

## 模块目标

- 适配 Open1PanelApp 作为 1Panel Linux 运维面板社区版的定位
- 提供完整的防火墙规则配置和管理能力
- 支持IP白名单、端口管理、规则管理
- 提供防火墙状态监控和日志查看
- 统一防火墙状态管理与错误反馈

## 功能完整性清单

基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 的 Firewall 标签共 15 个端点:

### 防火墙服务管理
1. GET /firewall - 获取防火墙状态
2. POST /firewall/update - 更新防火墙配置
3. POST /firewall/restart - 重启防火墙
4. POST /firewall/stop - 停止防火墙
5. POST /firewall/start - 启动防火墙

### 防火墙规则管理
6. POST /firewall/rules - 获取防火墙规则列表
7. POST /firewall/rule - 创建防火墙规则
8. POST /firewall/rule/update - 更新防火墙规则
9. POST /firewall/rule/del - 删除防火墙规则
10. POST /firewall/rule/operate - 防火墙规则操作

### IP管理
11. POST /firewall/ips - IP列表管理
12. POST /firewall/ip - 添加IP
13. POST /firewall/ip/del - 删除IP

### 端口管理
14. POST /firewall/ports - 端口列表管理
15. POST /firewall/port - 添加端口
16. POST /firewall/port/del - 删除端口

## 业务流程与交互验证

### 防火墙服务管理流程
- 进入防火墙管理页面
- 显示防火墙服务状态
- 支持启动/停止/重启防火墙
- 配置防火墙参数
- 保存配置并重启服务

### 防火墙规则配置流程
- 进入规则管理页面
- 显示规则列表
- 创建新规则
- 配置规则参数（端口、协议、策略）
- 保存规则并应用

### IP白名单管理流程
- 进入IP管理页面
- 显示IP白名单列表
- 添加新IP地址
- 配置IP访问策略
- 删除不需要的IP

### 端口管理流程
- 进入端口管理页面
- 显示开放端口列表
- 添加新端口
- 配置端口访问策略
- 删除不需要的端口

## 关键边界与异常

### 防火墙服务异常
- 防火墙启动失败的诊断
- 防火墙配置错误的处理
- 防火墙服务不可用的提示
- 规则冲突的处理

### 规则操作异常
- 规则创建失败的诊断
- 规则删除失败的诊断
- 规则冲突的处理
- 规则优先级问题

### IP/端口管理异常
- IP地址格式错误的处理
- 端口范围冲突的处理
- 权限不足的提示
- 服务依赖检查

## 模块分层与职责

### 前端
- UI页面: 防火墙服务管理、规则列表、IP管理、端口管理、日志查看
- 状态管理: 防火墙状态、规则列表、IP列表、端口列表

### 服务层
- API适配: FirewallV2Api
- 数据模型: FirewallService、FirewallRule、FirewallIP、FirewallPort等

## 数据流

1. UI触发 -> Provider/Service -> API客户端请求
2. API响应解析 -> 模型映射 -> 状态更新
3. 状态更新 -> UI刷新 -> 用户反馈
4. 规则变更 -> 防火墙重载 -> 状态确认

## 与现有实现的差距

- `status / rules / ip / ports` 页面已落地
- `FirewallPage` 已切到 server-aware 入口模式
- 危险操作二次确认已补
- 规则表单最小必填校验已补
- 列表页搜索 / strategy 筛选 / 选择模式 / 批量删除 / 批量策略切换已补
- repository 已收口到 `FirewallV2Api`

## 评审记录

| 日期 | 评审人 | 结论 | 备注 |
| --- | --- | --- | --- |
| 待定 | 评审人A | 待评审 | |
| 待定 | 评审人B | 待评审 | |
