# App Linking 配置确认清单

接入「链接 + 碰一碰直达应用」前，与开发者逐项确认。未确认项不得标为已完成。


## 云侧 / 仓外（不要写入端侧工程）

- [ ] AGC 取得真实 **appIdentifier**（只用于网站 `applinking.json` 与 AGC）
- [ ] 已部署 `https://<domain>/.well-known/applinking.json`（模板 `assets/applinking.json`，**禁止拷进 HarmonyOS 工程**）
- [ ] AGC 域名关联已通过
- [ ] 已配置手动/正式签名（调试签名通常无法完成域名关联）

## 端侧（确认后可由 Agent 改码）

- [ ] Ability `skills` 含 `entity.system.browsable`、`ohos.want.action.viewData`
- [ ] `uris.scheme` = `https`，`host` = 已验证域名，`domainVerify` = `true`
- [ ] 分享 `content` 使用同一域名下的真实链接
- [ ] `onCreate` / `onNewWant`：非空 `want.uri` 写入 `KnockShare_incomingUri`（不做 host 二次校验）
- [ ] 按宿主路由跳到落地页；消费后清空

## 与开发者确认的业务字段

| 字段 | 开发者确认值 |
|------|----------------|
| 域名 host | |
| path | |
| 查询参数名 | |
| 落地页 | |
| 链接卡片字段策略 | |
