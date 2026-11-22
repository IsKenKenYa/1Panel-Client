### 测试用例：FUNC-001

**skill**：hmos-account-kit-login-button-client
**类型**：functional（功能验证）

#### 输入

我需要接入华为账号登录按钮，请按默认配置自动接入（自动检测入口、纯文本红色按钮、默认服务端域名`http://localhost:8080`）,无需我再补充其他信息

#### 预期输出

**验证标准**：

- 成功触发 hmos-account-kit-login-button-client Skill
- 输出SKill 能力介绍（华为账号登录、登录页面、协议页面、UnionID/OpenID获取）
- 输出默认配置确认（纯文本按钮、华为红`BUTTON_RED`、服务端域名`http://localhost:8080`、默认应用图标）

---

### 测试用例：FUNC-002

**skill**：hmos-account-kit-login-button-client
**类型**：functional（功能验证）

#### 输入

帮我开通华为账号按钮登录这个功能,请按默认配置自动接入,无需我再补充其他信息

#### 预期输出

**验证标准**：

- 成功触发 Skill（通过语义关联"开通…按钮登录"匹配"接入华为账号登录"）
- 执行流程与 FUNC-001 一致，生成完整的接入方案
- 不因同义词"开通"替代"接入"而影响功能执行

---

### 测试用例：FUNC-003

**skill**：hmos-account-kit-login-button-client
**类型**：functional（功能验证）

#### 输入

帮我接入华为帐号登陆按钮,请按默认配置自动接入,无需我再补充其他信息

#### 预期输出

**验证标准**：

- 成功触发 Skill（通过模糊匹配/纠错识别"帐号登陆"为"账号登录"）
- 执行流程与 FUNC-001 一致
- 不因错别字而中断

---

### 测试用例：FUNC-004

**skill**：hmos-account-kit-login-button-client
**类型**：functional（功能验证）

#### 输入

#立刻给我#接入华为账号登录按钮#！！！请按默认配置自动接入,无需我再补充其他信息

#### 预期输出

**验证标准**：

- 成功触发 Skill，忽略 `#` 和 `！！！` 等特殊字符
- 执行流程与 FUNC-001 一致

---

### 测试用例：FUNC-005

**skill**：hmos-account-kit-login-button-client
**类型**：functional（功能验证）

#### 输入

有一个需求。我需要你先了解了一下官网资料，然后再接入华为账号的那个登录按钮。请按默认配置自动接入,无需我再补充其他信息

#### 预期输出

**验证标准**：

- 成功提取核心意图"接入华为账号登录按钮"
- 不因前置任务"了解官网资料"而偏离主任务
- 按顺序执行，最终完成接入流程

---

### 测试用例：FUNC-006

**skill**：hmos-account-kit-login-button-client
**类型**：functional（功能验证）
**前置条件**：同时安装一键登录 Skill（hmos-account-kit-quicklogin-client）

#### 输入

我需要接入华为账号登录按钮功能

#### 预期输出

**验证标准**：

- 成功触发 hmos-account-kit-login-button-client Skill
- 禁止触发 hmos-account-kit-quicklogin-client Skill
- 通过"登录按钮"关键词精确区分，不误选一键登录 Skill
- 执行完整的按钮登录接入流程
