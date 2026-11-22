### 测试用例：FUNC-001

**skill**：hmos-account-kit-quicklogin-client
**类型**：functional（功能验证）

#### 输入

请帮我添加华为账号一键登录功能

#### 预期输出

**验证标准**：

- 成功触发 hmos-account-kit-quicklogin-client Skill
- 进入 Step1 工程项目感知，检测是否已接入华为账号一键登录
- 搜索 `AppScope/app.json5` 的 `bundleType`、代码中 `quickLoginAnonymousPhone`、`quicklogin` 目录及 `QuickLoginPage.ets`
- 进入 Step2 功能开发，配置网络权限、混淆白名单、新增一键登录页面文件、修改图标、按钮颜色、服务端域名、协议跳转 url、获取匿名手机号点击事件、页面跳转逻辑
- 进入 Step3 代码审查，检查协议页跳转和一键登录页面跳转
- 进入 Step4 项目编译，使用 deveco-cli build_project 编译
- 最终输出包含结论、执行清单、风险与阻塞、配置信息、注意事项、下一步

---

### 测试用例：FUNC-002

**skill**：hmos-account-kit-quicklogin-client
**类型**：functional（功能验证）

#### 输入

帮我接入华为账号一键登录功能，UX颜色为天蓝色，并将按钮形状修改为方形

#### 预期输出

**验证标准**：

- 成功触发 Skill
- 按钮颜色判定为"其他颜色"，使用 `loginComponentManager.Style.BUTTON_CUSTOM` + `customButtonParams`
- 按钮形状修改为方形（borderRadius 设为 0 或较小值）
- 涉及文字等样式修改时读取 `references/api/account-api-component-manager.md`
- 执行流程与 FUNC-001 一致

---

### 测试用例：FUNC-003

**skill**：hmos-account-kit-quicklogin-client
**类型**：functional（功能验证）

#### 输入

请帮我添加华为账号一键登录功能，服务器接口域名地址为http://locahost:8080/api

#### 预期输出

**验证标准**：

- 成功触发 Skill
- 在 `QuickLoginPage.ets` 中替换服务端域名，保持路径 `/huawei/quickLogin/getPhoneNumber` 不变
- 执行流程与 FUNC-001 一致

---

### 测试用例：FUNC-004

**skill**：hmos-account-kit-quicklogin-client
**类型**：functional（功能验证）

#### 输入

请你为我接入华为账号一键登录功能，应用的用户协议地址链接为http://locahost:8080/api/user ，隐私协议地址为http://locahost:8080/api/001

#### 预期输出

**验证标准**：

- 成功触发 Skill
- 配置用户协议地址为 http://locahost:8080/api/user
- 配置隐私协议地址为 http://locahost:8080/api/001
- 协议页面可点击且可返回
- 执行流程与 FUNC-001 一致

---

### 测试用例：FUNC-005

**skill**：hmos-account-kit-quicklogin-client
**类型**：functional（功能验证）
**前置条件**：同时安装按钮登录与自定义按钮登录 Skill

#### 输入

我需要接入华为账号一键登录功能

#### 预期输出

**验证标准**：

- 成功触发 hmos-account-kit-quicklogin-client Skill
- 禁止触发按钮登录 Skill 或自定义按钮登录 Skill
- 通过"一键登录"关键词精确区分，不误选其他登录 Skill
- 执行完整的一键登录接入流程
