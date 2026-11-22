### 测试用例：FUNC-001

**skill**：hmos-account-kit-login-api-client
**类型**：functional（功能验证）

#### 输入

我需要接入华为账号自定义按钮登录

#### 预期输出

**验证标准**：

- 成功触发 hmos-account-kit-login-api-client Skill
- - 输出SKill 能力介绍（华为账号自定义按钮登录、登录页面、协议页面、UnionID/OpenID获取）
- 输出默认配置确认（自定义按钮样式按钮、服务端域名、应用图标）

---

### 测试用例：FUNC-002

**skill**：hmos-account-kit-login-api-client
**类型**：functional（功能验证）

#### 输入

帮我开通华为自定义按钮登录这个功能

#### 预期输出

**验证标准**：

- 成功触发 Skill（通过语义关联"开通…自定义按钮登录"匹配"接入华为账号自定义按钮登录"）
- 执行流程与 FUNC-001 一致，生成完整的接入方案
- 不因同义词"开通"替代"接入"而影响功能执行

---

### 测试用例：FUNC-003

**skill**：hmos-account-kit-login-api-client
**类型**：functional（功能验证）

#### 输入

帮我接入华为帐号登陆自定义按钮

#### 预期输出

**验证标准**：

- 成功触发 Skill（通过模糊匹配/纠错识别"帐号登陆"为"账号登录"）
- 执行流程与 FUNC-001 一致
- 不因错别字而中断

---

### 测试用例：FUNC-004

**skill**：hmos-account-kit-login-api-client
**类型**：functional（功能验证）

#### 输入

#接入华为账号登录自定义按钮#！！！

#### 预期输出

**验证标准**：

- 成功触发 Skill，忽略 `#` 和 `！！！` 等特殊字符
- 执行流程与 FUNC-001 一致

---

### 测试用例：FUNC-005

**skill**：hmos-account-kit-login-api-client
**类型**：functional（功能验证）

#### 输入

有一个需求。我需要你先了解了一下官网资料，然后再接入华为账号的那个登录自定义按钮

#### 预期输出

**验证标准**：

- 成功提取核心意图"接入华为账号登录自定义按钮"
- 不因前置任务"了解官网资料"而偏离主任务
-  执行流程与 FUNC-001 一致

---

### 测试用例：FUNC-006

**skill**：hmos-account-kit-login-api-client
**类型**：functional（功能验证）
**前置条件**：同时安装一键登录与按钮登录 Skill

#### 输入

我需要接入华为账号自定义按钮登录功能

#### 预期输出

**验证标准**：

- 成功触发 hmos-account-kit-login-api-client Skill
- 禁止触发一键登录 Skill 或按钮登录 Skill
- 通过"自定义按钮"关键词精确区分，不误选其他登录 Skill
- 执行完整的自定义按钮登录接入流程
