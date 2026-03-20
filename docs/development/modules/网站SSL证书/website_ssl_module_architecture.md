# 网站SSL证书模块架构设计

## 模块目标

- 适配 Open1PanelApp 作为 1Panel Linux 运维面板社区版的定位
- 提供网站SSL证书管理能力
- 支持证书申请、解析、更新与删除
- 统一证书管理与错误反馈

## 功能完整性清单

基于 `docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json`，网站SSL证书模块共包含 11 个端点:

### 网站SSL证书 (11端点)
1. POST /websites/ssl - 申请SSL证书
2. GET /websites/ssl/:id - 获取证书详情
3. POST /websites/ssl/del - 删除SSL证书
4. POST /websites/ssl/download - 下载证书文件
5. POST /websites/ssl/obtain - 申请证书
6. POST /websites/ssl/resolve - 解析证书状态
7. POST /websites/ssl/search - 分页查询证书
8. POST /websites/ssl/update - 更新证书
9. POST /websites/ssl/upload - 上传证书
10. POST /websites/ssl/upload/file - 上传证书文件
11. GET /websites/ssl/website/:websiteId - 获取网站证书

## 官方文档要点 (2026-03-13)

- 申请证书前需准备 ACME 账户；DNS 验证需配置 DNS 账户，支持 DNS 账户 / DNS 手动 / HTTP 三种验证方式。
- 上传证书需提供 PEM 格式证书与私钥，支持粘贴或文件路径方式。

## 业务流程与交互验证

### 证书申请流程
- 进入SSL证书管理页面
- 点击"申请证书"按钮
- 选择证书类型（免费/商业）
- 填写域名和邮箱
- 选择验证方式
- 提交申请
- 等待签发
- 安装证书

### 证书续期流程
- 从证书列表找到即将过期的证书
- 点击"续期"按钮
- 确认续期信息
- 执行续期操作
- 验证证书有效性

## 关键边界与异常

### 证书申请异常
- 域名验证失败的诊断
- 证书签发超时的处理
- DNS配置错误的提示
- 邮箱验证失败的处理

### 证书续期异常
- 续期失败的处理
- 证书已过期的处理
- 续期冲突的处理

## 模块分层与职责

### 前端
- UI页面: 证书列表、证书详情、申请表单
- 状态管理: 证书列表缓存、申请状态、续期提醒

### 服务层
- API适配: SSLV2Api
- 数据模型: WebsiteSSL, WebsiteSSLApply, WebsiteSSLUpdate等

## 数据流

1. 用户操作 -> 参数验证 -> API请求
2. API响应 -> 证书状态更新 -> UI刷新
3. 证书申请 -> 签发流程 -> 证书安装 -> 状态确认
4. 证书续期 -> 续期请求 -> 证书更新 -> 用户通知

## 与现有实现的差距

- SSL 证书列表页面缺失，当前仅展示单站点证书概览。
- 证书申请、上传、解析、更新与删除流程缺失。
- HTTPS 配置使用 JSON 编辑，缺少结构化表单与校验。

## API 实测备注 (2026-03-13)

- `GET /websites/:id/https` 返回 `{enable,httpConfig,SSL{...}}`，SSL 字段包含 `primaryDomain/pem/privateKey/domains/provider/...` 等。
- `POST /websites/ssl/search` 返回 `{total, items:null}`（空列表场景需兼容）。
- `GET /websites/ssl/website/:websiteId` 在未绑定证书时返回 `record not found`。

## 评审记录

| 日期 | 评审人 | 结论 | 备注 |
| --- | --- | --- | --- |
| 待定 | 评审人A | 待评审 | |
| 待定 | 评审人B | 待评审 | |

---

**文档版本**: 1.0
**最后更新**: 2026-02-14
