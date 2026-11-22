# IFAA免密身份认证技能 - 参考文档

## 原始文档引用

本技能基于以下HarmonyOS官方文档生成：

### 1. API开发指南

**文档名称**：IFAA免密身份认证开发指南

**文档路径**：
- 本地路径：`D:\z00810349\APIDevice\output\md_output\harmonyos-guides\系统\安全\Online Authentication Kit（在线认证服务）\IFAA免密身份认证\onlineauthentication-ifaa.md`
- 华为开发者官网：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/onlineauthentication-ifaa

**文档内容**：
- 场景介绍：开通、认证、注销三种场景
- 基本概念：互联网金融身份认证联盟（IIFAA）
- 相关权限：ohos.permission.ACCESS_BIOMETRIC
- 约束与限制：设备联网、IIFAA联盟接入、ATL4认证可信等级
- 业务流程：完整的IFAA认证流程图
- 接口说明：register、auth、deregisterSync、getAnonymousIdSync等API
- 开发步骤：三个场景的完整代码示例
- 常见问题：开通失败的处理方法

### 2. API参考说明

**文档名称**：IFAA API参考说明

**文档路径**：
- 本地路径：`D:\z00810349\APIDevice\output\md_output\harmonyos-references\系统\安全\Online Authentication Kit（在线认证服务）\ArkTS API\onlineauthentication-ifaa-api.md`
- 华为开发者官网：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/onlineauthentication-ifaa-api

**文档内容**：
- 模块导入：`import { ifaa } from '@kit.OnlineAuthenticationKit'`
- 起始版本：4.1.0(11)
- 支持设备：Phone, PC/2in1, Tablet
- 系统能力：SystemCapability.Security.Ifaa
- API列表：
  - getVersionSync() - 获取IFAA接口版本号
  - getAnonymousIdSync(userToken) - 获取匿名化ID
  - getAnonymousId(userToken) - Promise异步版本
  - queryStatusSync(userToken) - 查询开通状态
  - queryStatus(userToken) - Promise异步版本
  - register(registerData) - 开通IFAA
  - preAuthSync() - 获取预认证参数
  - preAuth() - Promise异步版本
  - authSync(authToken, authData) - IFAA认证
  - auth(authToken, authData) - Promise异步版本
  - deregisterSync(deregisterData) - 注销IFAA
  - deregister(deregisterData) - Promise异步版本
  - getProtocolVersionSync() - 获取协议版本
  - getProtocolVersion() - Promise异步版本
  - getSupportedCertTypesSync() - 获取支持的证书格式
  - getSupportedCertTypes() - Promise异步版本
- API参数说明、返回值、错误码
- 完整的API调用示例代码

### 3. 错误码说明

**文档名称**：IFAA错误码说明

**文档路径**：
- 本地路径：`D:\z00810349\APIDevice\output\md_output\harmonyos-references\系统\安全\Online Authentication Kit（在线认证服务）\ArkTS API\ArkTS API错误码\onlineauthentication-error-code-ifaa.md`
- 华为开发者官网：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/onlineauthentication-error-code-ifaa

**文档内容**：
- 1006100001 - 系统中断错误
- 1006100002 - 服务异常错误
- 401 - 参数错误（通用错误码）
- 801 - 设备类型错误（通用错误码）
- 错误原因分析和处理步骤

### 4. 相关参考文档

**个人数据处理说明**：
- 本地路径：`D:\z00810349\APIDevice\output\md_output\harmonyos-guides\系统\安全\Online Authentication Kit（在线认证服务）\个人数据处理说明\onlineauthentication-personal-data-processing-description.md`
- 华为开发者官网：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/onlineauthentication-personal-data-processing-description

## 文档链接转换规则

根据用户要求，所有Markdown文档链接已按照以下规则转换：

### HarmonyOS Guides文档

原始格式：`D:/code/APIDevice/output/md_output/harmonyos-guides/.../xxx.md`

转换格式：`https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/xxx`

**示例**：
- 原始：`D:/code/APIDevice/output/md_output/harmonyos-guides/系统/安全/Online Authentication Kit（在线认证服务）/个人数据处理说明/onlineauthentication-personal-data-processing-description.md`
- 转换：`https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/onlineauthentication-personal-data-processing-description`

### HarmonyOS References文档

原始格式：`D:/code/APIDevice/output/md_output/harmonyos-references/.../xxx.md`

转换格式：`https://developer.huawei.com/consumer/cn/doc/harmonyos-references/xxx`

**示例**：
- 原始：`D:/code/APIDevice/output/md_output/harmonyos-references/系统/安全/Online Authentication Kit（在线认证服务）/ArkTS API/onlineauthentication-ifaa-api.md`
- 转换：`https://developer.huawei.com/consumer/cn/doc/harmonyos-references/onlineauthentication-ifaa-api`

## 技能生成信息

**生成工具**：api-coding-skill-creator

**生成时间**：2026-07-04

**技能类型**：原子类型技能（Atomic Skill）

**技能规范**：遵循SDK编码规范

**API查找目录**：`D:\z00810349\APIDevice\output\md_output\harmonyos-references`

**技能输出目录**：`D:\z00810349\APIDevice\output\skill\系统\安全\Online Authentication Kit（在线认证服务）\IFAA免密身份认证`

## 技能文档结构

本技能包含以下文件：

- **SKILL.md** - 主技能定义文件（符合SDK规范）
- **references/** - 参考文档目录
  - `api_document_links.md` - 原始文档引用说明（本文件）
- **assets/** - 代码示例目录
  - `register_ifaa_example.ets` - 开通IFAA示例
  - `auth_ifaa_example.ets` - 认证IFAA示例
  - `deregister_ifaa_example.ets` - 注销IFAA示例
  - `query_ifaa_status_example.ets` - 查询IFAA状态示例
  - `ifaa_complete_flow_example.ets` - 完整流程示例
- **tests/** - 测试用例目录
  - `test_positive.ets` - 正向测试用例
  - `test_boundary.ets` - 边界测试用例
  - `test_exception.ets` - 异常测试用例

## 注意事项

1. 所有示例代码中的TLV数据格式为示例格式，实际开发需按照IIFAA协议规范构造
2. 服务端交互部分为模拟示例，实际开发需实现真实的HTTP请求逻辑
3. 测试用例中的模拟数据仅供演示，实际测试需使用真实环境数据
4. 权限申请和配置需在module.json5中正确配置
5. IFAA功能要求设备联网且已接入IIFAA联盟