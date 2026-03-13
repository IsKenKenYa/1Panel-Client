# 网站配置管理模块架构设计

## 模块目标

- 适配 Open1PanelApp 作为 1Panel Linux 运维面板社区版的定位
- 提供完整的Nginx配置管理能力
- 提供配置备份和恢复功能
- 统一配置管理与错误反馈

## 功能完整性清单

基于 1PanelV2OpenAPI.json，网站配置管理模块共包含 5 个端点:

### Nginx配置 (4端点)
1. GET /websites/:id/config/:type - 获取站点配置文件
2. POST /websites/config - 加载站点Nginx配置
3. POST /websites/config/update - 更新站点Nginx配置
4. POST /websites/nginx/update - 更新站点Nginx配置内容

### PHP版本 (1端点)
1. POST /websites/php/version - 切换PHP版本

## 官方文档要点 (2026-03-13)

- HTTPS 配置包含 HTTP 访问策略（重定向到 HTTPS / 保留 HTTP / 禁用 HTTP）。
- 支持 HSTS 与 HTTP/3 等高级开关。
- 证书配置支持选择已有证书或手动导入（证书 + 私钥，支持粘贴或文件路径）。

## 业务流程与交互验证

### Nginx配置流程
- 进入Nginx配置页面
- 查看当前配置
- 编辑配置内容
- 验证配置语法
- 保存并重载配置

### PHP版本切换流程
- 进入网站配置页面
- 选择PHP版本
- 确认切换操作
- 验证网站运行状态

## 关键边界与异常

### Nginx配置异常
- 配置语法错误的处理
- 配置重载失败的处理
- 配置冲突的处理

### PHP版本异常
- 版本切换失败
- 网站不兼容
- 服务重启失败

## 模块分层与职责

### 前端
- UI页面: Nginx配置编辑器、版本选择器
- 状态管理: 配置缓存、版本切换状态

### 服务层
- API适配: WebsiteV2Api
- 数据模型: FileInfo等

## 数据流

1. 用户编辑 -> 配置验证 -> API请求
2. API响应 -> 配置更新 -> 服务重载
3. 重载结果 -> 状态确认 -> 用户反馈
## 与现有实现的差距

- 配置编辑缺少语法校验与差异预览，保存失败时缺少回滚入口。
- 配置版本与备份管理能力缺失。
- PHP 版本切换未在 UI 中提供入口。

## API 实测备注 (2026-03-13)

- `POST /websites/config` 返回 `enable` 与 `params[]`（包含 `name` 与 `params[]`）。
- `POST /websites/config/update` 成功返回 `{code:200,message:\"success\",data:null}`。
- `GET /websites/:id/config/:type` 与 `POST /websites/nginx/update` 在当前静态站点返回 `目标路径不存在`（需站点具备可编辑配置文件后复测）。

## 评审记录

| 日期 | 评审人 | 结论 | 备注 |
| --- | --- | --- | --- |
| 待定 | 评审人A | 待评审 | |
| 待定 | 评审人B | 待评审 | |

---

**文档版本**: 1.0
**最后更新**: 2026-02-14
