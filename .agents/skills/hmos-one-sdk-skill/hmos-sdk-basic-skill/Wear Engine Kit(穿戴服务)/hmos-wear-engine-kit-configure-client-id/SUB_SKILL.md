---
name: hmos-wear-engine-kit-configure-client-id
description: 为HarmonyOS应用配置Wear Engine Kit的Client ID，在module.json5文件中添加metadata配置，确保应用能够正常使用穿戴服务功能，适用于穿戴设备应用开发场景
---

# 配置Client ID技能

## 功能描述

为HarmonyOS应用配置Wear Engine Kit的Client ID，通过在工程entry模块的module.json5文件中添加metadata配置，实现应用与华为穿戴服务的集成。该配置是使用Wear Engine Kit功能的前置条件，确保应用能够被正确识别和授权。

## 使用场景

### 触发词
- "配置Client ID"
- "配置穿戴服务Client ID"
- "Wear Engine Kit配置"
- "设置client_id"

### 能做
- 从AppGallery Connect平台获取应用的Client ID
- 在module.json5文件中正确配置Client ID
- 验证配置是否生效

### 绝不做
- 不涉及实际的API调用
- 不处理除Client ID配置外的其他配置
- 不修改除module.json5外的其他配置文件

### 补充
- 该配置是使用Wear Engine Kit功能的必要前提
- 需要先在AppGallery Connect平台创建应用并获取Client ID
- 配置完成后需要重新编译应用

## 调用规范和规则

### 输入约束
- Client ID值：必须是有效的字符串，从AppGallery Connect平台获取
- module.json5文件：必须存在且格式正确
- 应用类型：必须是entry类型的模块

### 执行约束
- 配置时间：小于1分钟
- 操作步骤：固定2步
- 文件修改：仅修改module.json5文件

### 内容约束
- 禁止修改或删除其他metadata配置
- 禁止配置无效或空的Client ID
- 禁止在非entry模块中配置

### 降级约束
- AppGallery Connect无法访问：提示用户检查网络连接
- Client ID获取失败：提供获取流程指导
- 配置文件损坏：提供备份恢复方案

## 调用流程和步骤

### 步骤1：获取Client ID

**前置校验**：
1. 验证是否有AppGallery Connect账号
2. 验证应用是否已在平台创建
3. 验证网络连接是否正常

**操作说明**：
1. 登录[AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)平台
2. 在"开发与服务"中选择目标应用
3. 进入"项目设置 > 常规 > 应用"
4. 复制Client ID值

**注意事项**：
- 确保选择正确的应用项目
- Client ID区分大小写，复制时不要修改
- 建议保存Client ID备份

### 步骤2：配置module.json5文件

**配置示例**：
```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": [],
    "pages": "$profile:main_pages",
    "abilities": [],
    "metadata": [
      {
        "name": "client_id",
        "value": "您从AppGallery Connect获取的Client ID"
      }
    ]
  }
}
```

**配置说明**：
1. 打开工程中entry模块的module.json5文件
2. 在`module`对象中找到或创建`metadata`数组
3. 添加一个metadata对象：
   - `name`字段设置为`"client_id"`
   - `value`字段设置为从AppGallery Connect获取的Client ID值
4. 保存文件

**参数说明**：
- `name`：固定值`"client_id"`，表示配置的类型
- `value`：Client ID的实际值，从AppGallery Connect获取

### 步骤3：验证配置

**验证步骤**：
1. 确认module.json5文件格式正确（JSON格式验证）
2. 确认metadata配置在正确的位置
3. 确认Client ID值已正确填写
4. 重新编译应用确保配置生效

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| CONFIG_FILE_NOT_FOUND | module.json5文件不存在 | 检查文件路径是否正确，确认entry模块是否存在 |
| INVALID_JSON_FORMAT | JSON格式错误 | 使用JSON格式化工具检查文件格式，修复语法错误 |
| MISSING_CLIENT_ID | Client ID为空或无效 | 从AppGallery Connect重新获取Client ID |
| METADATA_ALREADY_EXISTS | metadata配置已存在 | 检查是否重复配置，更新现有配置 |
| MODULE_TYPE_ERROR | 模块类型不是entry | 确认当前模块类型，仅在entry模块中配置 |

## 编译和修复问题

### 依赖声明
无需额外依赖库，配置为HarmonyOS应用标准配置项。

### 环境要求
- DevEco Studio：3.0或更高版本
- HarmonyOS SDK：API 8或更高版本
- 应用类型：entry模块

### 常见编译问题

**问题1：module.json5文件格式错误**
```
Error: Invalid JSON format in module.json5
```
**解决方法**：
- 使用JSON格式化工具检查文件格式
- 确保所有字段使用双引号
- 检查逗号和括号是否匹配

**问题2：metadata配置未生效**
```
Client ID not found or invalid
```
**解决方法**：
- 确认配置在正确的entry模块中
- 检查Client ID值是否正确复制
- 清理项目并重新编译

**问题3：配置后应用无法启动**
```
Application failed to start
```
**解决方法**：
- 检查Client ID是否与应用包名匹配
- 确认AppGallery Connect中的应用配置是否正确
- 查看日志获取详细错误信息

## 常见问题与解决方法

### Q1：如何获取Client ID？
**原因**：用户不熟悉AppGallery Connect平台操作
**解决方法**：
- 登录AppGallery Connect平台
- 选择目标应用
- 进入"项目设置 > 常规 > 应用"
- 查看并复制Client ID

### Q2：Client ID配置在哪里？
**原因**：不清楚配置文件位置
**解决方法**：
- 配置文件位于entry模块的module.json5
- 路径通常为：`entry/src/main/module.json5`
- 在module对象的metadata数组中添加配置

### Q3：配置后还是无法使用穿戴服务？
**原因**：可能存在其他前置条件未满足
**解决方法**：
- 确认已在AppGallery Connect中开通穿戴服务
- 检查应用签名是否正确
- 确认设备支持穿戴服务功能
- 查看应用日志排查具体错误

### Q4：可以配置多个Client ID吗？
**原因**：不清楚配置规则
**解决方法**：
- 一个应用只需配置一个Client ID
- 如果metadata数组中已有client_id配置，直接更新value值即可
- 不要重复添加同名配置

### Q5：Client ID泄露了怎么办？
**原因**：安全意识问题
**解决方法**：
- Client ID不是密钥，可以公开
- 如有安全顾虑，可在AppGallery Connect重新生成
- 更新配置文件中的Client ID值

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "configFile": "entry/src/main/module.json5",
  "configItem": "metadata.client_id",
  "clientIDConfigured": true,
  "nextSteps": [
    "重新编译应用",
    "验证穿戴服务功能是否正常"
  ]
}
```

## 参考文档

- [API开发指南](references/configuration_client_id.md)

## 完整示例代码

- [module.json5配置示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [正常配置Client ID](tests/test_positive.py)：在空的metadata数组中添加client_id配置
- [更新Client ID配置](tests/test_positive.py)：在已有metadata中更新client_id值

### 边界测试用例
- [超长Client ID值](tests/test_boundary.py)：测试最大长度的Client ID
- [特殊字符Client ID](tests/test_boundary.py)：测试包含特殊字符的Client ID

### 异常测试用例
- [空Client ID值](tests/test_exception.py)：测试空字符串的情况
- [错误的文件路径](tests/test_exception.py)：测试module.json5文件不存在的情况
- [JSON格式错误](tests/test_exception.py)：测试module.json5文件格式错误的情况