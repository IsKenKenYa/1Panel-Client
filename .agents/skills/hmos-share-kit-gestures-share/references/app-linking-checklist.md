# App Linking 配置确认清单

接入「链接 + 隔空传送直达应用」前，与开发者逐项确认。未确认项不得标为已完成。

官方文档：[使用 App Linking 应用链接拉起指定应用](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-linking-startup)

## 目录

- 云侧 / 仓外（Skill 不能自动完成；不要写入端侧工程）
- 端侧工程内（确认后可由 Agent 改码）
- 与开发者确认的业务字段
- 域名校验与排障（应用安装后）
- 拉起验证（人工，按代价从低到高）

## 云侧 / 仓外（Skill 不能自动完成；**不要写入端侧工程**）

- [ ] 应用已在 AppGallery Connect 创建，取得真实 **appIdentifier**（只用于网站 `applinking.json` 与 AGC，**端侧代码 / `module.json5` 不写此字段**）
- [ ] 域名可公网访问，已部署 `https://<domain>/.well-known/applinking.json`（模板见 `assets/app-linking-tools/applinking.json`，**禁止拷进 HarmonyOS 工程**）
- [ ] 该网站文件中的 `appIdentifier` 已换成 AGC 真实值；同域名关联多个应用时可选配 `index` 定优先级（取值 [-100,100]，值大优先，起始 **6.1.0(23)**；全不配则系统弹框让用户选应用）
- [ ] AGC 域名与应用关联**发布成功**（填域名时**尾部不可加 `/`**；发布超 24 小时系统会重新拉取网站文件做交集校验，状态可能变化）
- [ ] 已配置**手动签名**（DevEco Studio 自动签名无法完成拉起验证；签名在工程构建配置，不是 `appIdentifier`）

## 端侧工程内（确认后可由 Agent 改码）

- [ ] 入口 Ability `exported` = **true**（为 false 时仅具权限的系统应用能拉起，其余来源无法拉起）
- [ ] 入口 Ability `skills` 数组**新增独立 skill 对象**（官方要求：禁止并入 home 入口条目，混置则链接拉起不生效）：含 `entity.system.browsable`、`ohos.want.action.viewData`
- [ ] `uris.scheme` = `https`，`host` = 已验证域名；`path` 为可选（另有 `pathStartWith` / `pathRegex`），仅应用只处理特定路径时配置
- [ ] `domainVerify` = `true`
- [ ] 分享 `SharedData.content` 使用同一域名下的真实链接（含约定 query）
- [ ] `EntryAbility.onCreate` / `onNewWant`：`want.uri` 非空则写入全局 `incomingUri`（不做 Ability 内 host 二次校验；不另加 `fromAppLink`）
- [ ] 落地页按宿主现有路由风格导航（Navigation / router 等）；query 解析用 `url.URL.parseURL(uri)` 取参（官方示例写法），按业务分发，消费后清空 `incomingUri`
- [ ] 冷启动（`onCreate`）与热启动（`onNewWant`，应用已在前台）两条路径均已接线

## 与开发者确认的业务字段

记录后写入代码，禁止沿用示例占位：

| 字段 | 开发者确认值 |
|------|----------------|
| 域名 host | |
| path | |
| 查询参数名（如 id / videoIndex） | |
| 落地页路由名/路径 | |
| 链接卡片 title/description/缩略图策略 | |

## 域名校验与排障（应用安装后）

系统在安装后自动做域名校验，未通过前链接不会拉起应用：

- [ ] 安装后**等待 ≥20 秒**再验证（校验流程需要时间）
- [ ] 查询校验状态：`hdc shell hidumper -s AppDomainVerifyManager`
  - `success` → 通过
  - `client-error` → 核对设备侧 appIdentifier 与 AGC 域名发布状态
  - `http_unknown` → 确保设备可联网后重新安装应用
- [ ] 断网 / 弱网导致校验失败 → 系统将在 **24 小时内自动重试**，无需重装
- [ ] 更新网站文件后未生效 → CDN 缓存 **10 分钟**，等待后重试

设备范围：Phone / PC 2in1 / Tablet；5.1.1(19) 起支持 TV。

## 拉起验证（人工，按代价从低到高）

- [ ] 方式一：链接存入备忘录点击，验证拉起（最快）
- [ ] 方式二：任意应用 `openLink(link, { appLinkingOnly: true })` 拉起（无匹配抛异常，验证配置最直接）
- [ ] 方式三：系统浏览器 / ArkWeb 打开链接（注意：当前浏览页域名与链接域名**完全一致**时仍在浏览器打开，需换不同域名的页面测）
- [ ] 方式四：系统级扫码入口扫链接二维码
- [ ] 隔空传送真机联调（最终验收）：双端已开华为分享、[设备隔空传送开关](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/gestures-share-open)已开、双端亮屏解锁、账号/信任设备条件满足
