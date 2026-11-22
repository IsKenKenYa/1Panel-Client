---
name: hmos-iap-kit-config-app-identity
description: 配置IAP Kit应用身份信息，包括bundleName和client_id配置，用于应用内支付服务身份鉴权，适用于应用内支付开发准备阶段
---

# 配置应用身份信息技能

## 功能描述

本技能用于配置HarmonyOS应用的IAP Kit（应用内支付服务）身份信息，确保应用能够正确使用IAP Kit的支付能力。主要完成以下配置：

- 配置应用的bundleName，与AppGallery Connect平台创建的应用包名保持一致
- 在AppGallery Connect平台获取应用的Client ID
- 在module.json5中配置client_id，用于IAP Kit接口的应用身份鉴权

## 使用场景

### 触发词
- "配置IAP Kit身份信息"
- "配置应用内支付身份"
- "IAP Kit开发准备"
- "配置client_id"
- "获取IAP Client ID"

### 能做
- 指导开发者配置bundleName以匹配AppGallery Connect应用
- 指导从AppGallery Connect平台获取Client ID
- 指导在module.json5中配置client_id属性
- 提供完整的配置示例代码

### 绝不做
- 不执行实际的支付操作
- 不处理支付订单
- 不管理商品信息
- 不处理支付回调

### 补充
- 如果应用的compatibleSdkVersion>=14，则接入IAP Kit不要求配置应用身份信息
- 本技能仅适用于开发准备阶段，不涉及实际的支付流程

## 调用规范和规则

### 输入约束
- 必须已在AppGallery Connect平台创建应用
- 应用包名必须已确定
- 需要具备AppGallery Connect平台的访问权限

### 执行约束
- 配置文件修改必须准确无误
- Client ID必须从AppGallery Connect平台正确获取
- bundleName必须与AppGallery Connect中的应用包名一致

### 内容约束
- 禁止使用他人的Client ID
- 禁止在代码中硬编码敏感信息
- 禁止泄露Client ID

### 降级约束
- 如果无法访问AppGallery Connect平台，提示用户检查网络连接和账号权限
- 如果配置文件不存在，提示用户检查项目结构
- 如果Client ID获取失败，引导用户检查应用创建状态

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认已在AppGallery Connect平台创建应用
2. 确认应用包名已确定
3. 确认具备AppGallery Connect平台访问权限

**参数准备**：
```json
{
  "bundleName": "com.huawei.***.***.demo",
  "client_id": "从AppGallery Connect平台获取"
}
```

### 步骤2：配置bundleName

在工程"AppScope/app.json5"文件中配置bundleName：

```json
{
  "app": {
    "bundleName": "com.huawei.***.***.demo"
  }
}
```

**注意事项**：
- bundleName必须与AppGallery Connect平台创建应用时的包名保持一致
- bundleName格式通常为域名反转形式，如com.company.project

### 步骤3：获取Client ID

1. 登录[AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)平台
2. 在"开发与服务"中选择目标项目
3. 通过"项目设置 > 常规 > 应用"获取目标应用的Client ID
4. 记录Client ID用于后续配置

**注意事项**：
- APP ID可用于服务器API接口请求
- 确保获取的是正确应用的Client ID

### 步骤4：配置client_id

在工程"entry/src/main/module.json5"的module节点增加client_id属性配置：

```json
{
  "module": {
    "type": "entry",
    "name": "entry",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": [
      "phone",
      "tablet"
    ],
    "metadata": [
      {
        "name": "client_id",
        "value": "从AppGallery Connect平台获取的Client ID"
      }
    ]
  }
}
```

**注意事项**：
- metadata为数组类型，可包含多个配置项
- name固定为"client_id"
- value填写从AppGallery Connect平台获取的实际Client ID值

### 步骤5：验证配置

**验证方法**：
1. 检查app.json5中的bundleName是否与AppGallery Connect应用包名一致
2. 检查module.json5中是否正确配置了client_id
3. 检查Client ID是否为正确的值（非空且格式正确）

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| CONFIG_NOT_FOUND | 配置文件不存在 | 检查项目结构，确保app.json5和module.json5文件存在 |
| INVALID_BUNDLENAME | bundleName格式错误 | 检查bundleName格式，确保为域名反转形式 |
| BUNDLENAME_MISMATCH | bundleName与AppGallery Connect不匹配 | 修改bundleName使其与AppGallery Connect应用包名一致 |
| CLIENT_ID_EMPTY | Client ID为空 | 从AppGallery Connect平台获取正确的Client ID |
| CLIENT_ID_INVALID | Client ID格式错误 | 检查Client ID是否正确复制，确保无多余空格或字符 |
| PERMISSION_DENIED | 无权限访问AppGallery Connect | 检查账号权限，确保有权限访问目标应用 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.IAPKit": ">=4.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK: >=4.0.0(10)
- DevEco Studio: 最新版本
- AppGallery Connect账号: 已创建应用

### 常见编译问题

**问题1：bundleName不存在**
```
Error: bundleName is required in app.json5
```
**解决方法**：在app.json5的app节点下添加bundleName配置

**问题2：client_id配置未生效**
```
Error: IAP Kit initialization failed - missing client_id
```
**解决方法**：检查module.json5中metadata配置是否正确，确保name为"client_id"

**问题3：bundleName不匹配**
```
Error: Bundle name does not match AGC app configuration
```
**解决方法**：确保app.json5中的bundleName与AppGallery Connect应用包名完全一致

## 常见问题与解决方法

### Q1：如何判断是否需要配置应用身份信息？
**原因**：不同SDK版本配置要求不同
**解决方法**：
- 如果应用的compatibleSdkVersion>=14，则接入IAP Kit不要求配置应用身份信息
- 如果compatibleSdkVersion<14，则必须完成应用身份信息配置

### Q2：找不到Client ID在哪里？
**原因**：AppGallery Connect平台界面可能更新
**解决方法**：
- 登录AppGallery Connect平台
- 选择"开发与服务"中的目标项目
- 进入"项目设置 > 常规 > 应用"
- 在应用信息中查找Client ID字段

### Q3：配置后仍然提示身份验证失败？
**原因**：可能存在多个配置问题
**解决方法**：
- 检查bundleName是否与AppGallery Connect应用包名完全一致
- 检查Client ID是否正确复制，无多余空格
- 检查module.json5中metadata配置格式是否正确
- 检查网络连接是否正常

### Q4：能否在多个应用中使用同一个Client ID？
**原因**：Client ID与应用一一对应
**解决方法**：
- 不能在多个应用中使用同一个Client ID
- 每个应用必须配置对应的Client ID
- Client ID与AppGallery Connect平台的应用绑定

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "配置成功",
  "bundleName": "com.huawei.***.***.demo",
  "clientIdConfigured": true,
  "configFiles": [
    "AppScope/app.json5",
    "entry/src/main/module.json5"
  ],
  "nextSteps": [
    "继续IAP Kit其他开发准备工作",
    "配置商品信息",
    "集成支付能力"
  ]
}
```

## 参考文档

- [API开发指南](references/iap-config-app-identity-info.md)
- [创建应用](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-overview)
- [IAP Kit API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-iap)

## 完整示例代码

- [配置文件示例](assets/config_example.json)
- [app.json5示例](assets/app_json5_example.json)
- [module.json5示例](assets/module_json5_example.json)

## 测试用例

### 正向测试用例
- [配置正确的bundleName和client_id](tests/test_positive.py)：验证配置成功
- [compatibleSdkVersion>=14的场景](tests/test_positive.py)：验证不配置也可正常使用

### 边界测试用例
- [bundleName最长长度限制](tests/test_boundary.py)：验证bundleName长度限制
- [client_id格式边界](tests/test_boundary.py)：验证client_id格式验证

### 异常测试用例
- [bundleName格式错误](tests/test_exception.py)：验证bundleName格式校验
- [client_id为空](tests/test_exception.py)：验证必填项校验
- [bundleName不匹配](tests/test_exception.py)：验证与AGC应用包名一致性校验