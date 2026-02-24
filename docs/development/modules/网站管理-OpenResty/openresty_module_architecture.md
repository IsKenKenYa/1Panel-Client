# 网站模块 - OpenResty 子模块架构设计

## 模块目标

- 适配 Open1PanelApp 作为 1Panel Linux 运维面板社区版的定位
- 作为网站模块的子模块，管理OpenResty服务的状态、配置与模块能力
- 提供安全的配置变更、模块更新、默认HTTPS控制与构建操作
- 统一前后端交互与错误反馈，避免配置失效导致服务中断

## 功能完整性清单

基于 1PanelV2OpenAPI.json 的 OpenResty 标签共 10 个端点:

1. GET /openresty
2. POST /openresty/build
3. POST /openresty/file
4. GET /openresty/https
5. POST /openresty/https
6. GET /openresty/modules
7. POST /openresty/modules/update
8. POST /openresty/scope
9. GET /openresty/status
10. POST /openresty/update

## 业务流程与交互验证

### 状态页流程

- 初始化页面加载状态与服务状态
- 展示运行状态、版本、连接数、路径信息
- 当服务停止时展示引导信息与风险提示

### 配置编辑流程

- 拉取当前配置内容与局部片段
- 用户编辑后进行语法校验与备份
- 提交更新并触发服务reload
- 更新后拉取状态确认

### HTTPS默认配置流程

- 获取默认HTTPS开关与证书信息
- 支持启用/禁用操作并提示影响范围
- 若证书缺失则阻止启用并引导配置

### 模块管理流程

- 拉取模块列表与启用状态
- 选择模块后提交更新
- 更新完成后重新加载状态

### 构建流程

- 触发构建任务并展示进度
- 构建完成后回写版本与模块信息
- 失败时输出错误与日志指引

## 关键边界与异常

- 配置更新失败时保持旧配置并恢复状态
- HTTPS启用失败的证书缺失/格式错误场景
- 模块更新时不兼容版本提示与回滚策略
- 构建任务重复触发的幂等处理
- 网络抖动导致状态拉取失败的重试与空态

## 模块分层与职责

### 前端

- UI页面: OpenResty状态、配置编辑、HTTPS默认配置、模块管理、构建
- 状态管理: 拉取与缓存、加载态/错误态、提交操作结果提示

### 服务层

- API适配: OpenRestyV2Api
- 数据模型: OpenrestyStatus、OpenrestyConfig、OpenrestyOperation

## 数据流

1. UI触发 -> Provider/Service -> API客户端请求
2. API响应解析 -> 模型映射 -> 状态更新
3. 状态更新 -> UI刷新 -> 用户反馈

## 与现有实现的差距

- OpenResty 页面未提供构建任务触发入口
- OpenResty 页面未提供局部配置（scope）读取与展示入口

## 评审记录

| 日期 | 评审人 | 结论 | 备注 |
| --- | --- | --- | --- |
| 待定 | 评审人A | 待评审 |  |
| 待定 | 评审人B | 待评审 |  |
