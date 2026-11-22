---
name: hmos-health-service-kit-configuration-client-id
description: 配置Client ID用于应用身份认证，在AppGallery Connect平台获取并在module.json5中配置metadata，适用于Health Service Kit开发接入场景
---

# 配置Client ID技能

## 功能描述

本技能指导开发者在HarmonyOS应用中配置Health Service Kit所需的Client ID。Client ID是应用在AppGallery Connect平台的身份标识，用于Health Service Kit API调用的身份认证和鉴权。

通过本技能，开发者将学会：
1. 从AppGallery Connect平台获取Client ID
2. 在应用工程的module.json5文件中配置metadata

## 使用场景

### 触发词
- "配置Client ID"
- "Health Service Kit Client ID"
- "设置应用身份认证"
- "配置Health Service Kit"

### 能做
- 指导从AppGallery Connect平台获取Client ID
- 提供module.json5配置metadata的标准格式
- 验证配置正确性
- 提供配置问题的排查方法

### 绝不做
- 不代替开发者访问AppGallery Connect平台
- 不自动获取或生成Client ID
- 不提供除Health Service Kit外的其他Kit配置指导

### 补充
- Client ID与应用一一对应，每个应用都有唯一的Client ID
- 配置错误会导致Health Service Kit API调用失败
- 需要确保Client ID值与AppGallery Connect平台一致

## 调用规范和规则

### 输入约束
- 必须拥有AppGallery Connect平台账号
- 必须已在AppGallery Connect平台创建应用
- 应用工程必须存在module.json5文件
- Client ID字符串长度：通常为64个字符

### 执行约束
- 获取Client ID耗时：约1-2分钟（手动操作）
- 配置修改耗时：约30秒
- 必须验证配置正确性后再进行后续开发

### 内容约束
- 禁止硬编码或泄露Client ID到代码仓库
- 禁止使用其他应用的Client ID
- 禁止在示例代码中使用真实的Client ID

### 降级约束
- 无法访问AppGallery Connect：提示检查网络或账号权限
- module.json5文件不存在：提示创建entry模块
- 配置格式错误：提供标准格式模板

## 调用流程和步骤

### 步骤1：获取Client ID

**前置校验**：
1. 确认已拥有华为开发者账号
2. 确认已在AppGallery Connect平台创建应用
3. 确认有应用的访问权限

**获取步骤**：

1. 登录[AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)平台

2. 在"开发与服务"中选择目标应用

3. 进入"项目设置 > 常规 > 应用"页面

4. 复制Client ID字段值

**注意事项**：
- Client ID在"应用"区域，非"项目"区域
- Client ID通常为64字符的字符串
- 不要混淆Client ID和Client Secret

### 步骤2：配置module.json5

**配置位置**：
工程路径：`entry/src/main/module.json5`

**配置示例**：
```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": [
      "phone",
      "tablet"
    ],
    "deliveryWithInstall": true,
    "installationFree": false,
    "pages": "$profile:main_pages",
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "description": "$string:EntryAbility_desc",
        "icon": "$media:icon",
        "label": "$string:EntryAbility_label",
        "startWindowIcon": "$media:StartWindowIcon",
        "startWindowBackground": "$color:start_window_background",
        "exported": true,
        "skills": [
          {
            "entities": [
              "entity.system.home"
            ],
            "actions": [
              "action.system.home"
            ]
          }
        ]
      }
    ],
    "metadata": [
      {
        "name": "client_id",
        "value": "您的Client ID值"
      }
    ]
  }
}
```

**关键配置说明**：
- `metadata`数组位于`module`对象内
- `name`字段固定为`"client_id"`
- `value`字段填写步骤1获取的Client ID值
- 如果`metadata`数组已存在其他配置，追加client_id配置项即可

### 步骤3：验证配置

**验证方法**：
```typescript
import { metadataHelper } from '@ohos/metadataHelper';

async function verifyClientId(): Promise<string> {
  try {
    const clientId = await metadataHelper.getMetadata('client_id');
    if (clientId && clientId.length > 0) {
      console.info('Client ID配置成功:', clientId);
      return clientId;
    } else {
      console.error('Client ID未配置或为空');
      return '';
    }
  } catch (error) {
    console.error('获取Client ID失败:', error.message);
    return '';
  }
}
```

**验证检查清单**：
- [ ] module.json5文件格式正确（JSON语法无错误）
- [ ] metadata数组存在且格式正确
- [ ] client_id的name和value字段都存在
- [ ] Client ID值与AppGallery Connect平台一致
- [ ] 应用能成功编译和安装

### 步骤4：错误处理

**常见配置错误**：

**错误1：metadata位置错误**
```json
// 错误示例：metadata放在module外
{
  "module": {
    "name": "entry"
  },
  "metadata": [  // 错误位置
    {
      "name": "client_id",
      "value": "xxx"
    }
  ]
}
```

**正确配置**：
```json
{
  "module": {
    "name": "entry",
    "metadata": [  // 正确位置
      {
        "name": "client_id",
        "value": "xxx"
      }
    ]
  }
}
```

**错误2：name字段错误**
```json
// 错误示例
{
  "name": "clientId",  // 错误，应为client_id
  "value": "xxx"
}
```

**正确配置**：
```json
{
  "name": "client_id",  // 正确
  "value": "xxx"
}
```

**错误3：缺少引号**
```json
// 错误示例
{
  "name": client_id,  // 错误，缺少引号
  "value": xxx
}
```

**正确配置**：
```json
{
  "name": "client_id",  // 正确
  "value": "xxx"
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| ERR_METADATA_NOT_FOUND | metadata数组未配置或位置错误 | 检查metadata是否在module对象内部 |
| ERR_CLIENT_ID_EMPTY | Client ID值为空 | 检查value字段是否填写了正确的Client ID |
| ERR_CLIENT_ID_INVALID | Client ID格式错误 | 确认Client ID为64字符的字符串 |
| ERR_JSON_SYNTAX | JSON语法错误 | 使用JSON格式化工具检查module.json5语法 |
| ERR_PERMISSION_DENIED | 无权限访问AppGallery Connect | 确认账号权限或联系项目管理员 |

## 编译和修复问题

### 依赖声明
Health Service Kit无需额外依赖，已集成在HarmonyOS SDK中。

### 环境要求
- HarmonyOS SDK: API 10+（推荐API 12）
- DevEco Studio: 3.1+（推荐4.0+）
- Node.js: 14.19.1+

### 常见编译问题

**问题1：module.json5格式错误**
```
Error: Parse error in module.json5
```
**解决方法**：
1. 使用JSON格式化工具验证语法
2. 检查是否有遗漏的逗号或引号
3. 确认所有字段值都用双引号包裹

**问题2：编译时找不到metadata**
```
Error: Cannot find property 'metadata'
```
**解决方法**：
1. 确认metadata数组在module对象内部
2. 检查DevEco Studio版本是否支持metadata配置
3. 升级HarmonyOS SDK到最新版本

**问题3：运行时Client ID读取失败**
```
Error: Failed to get client_id metadata
```
**解决方法**：
1. 确认应用已重新编译安装
2. 检查metadata配置是否正确
3. 使用调试工具验证metadata是否生效

## 常见问题与解决方法

### Q1：在哪里可以找到Client ID？
**原因**：不熟悉AppGallery Connect平台布局  
**解决方法**：
1. 登录AppGallery Connect平台
2. 选择"我的项目"
3. 选择目标项目
4. 点击"项目设置" > "常规"
5. 在"应用"区域找到Client ID字段

### Q2：Client ID和Client Secret有什么区别？
**原因**：混淆了两个不同的认证字段  
**解决方法**：
- **Client ID**：应用公开标识，用于身份识别，可配置在应用中
- **Client Secret**：应用私密密钥，用于服务端签名，不可泄露

### Q3：配置后Health Service Kit API仍然调用失败？
**原因**：可能是其他配置或权限问题  
**解决方法**：
1. 确认已在AppGallery Connect开通Health Service服务
2. 检查应用是否申请了必要的权限
3. 验证签名证书指纹是否正确配置
4. 查看API调用返回的错误码

### Q4：能否在多个module中配置client_id？
**原因**：不了解client_id配置规则  
**解决方法**：
- Client ID只需在entry模块配置一次
- 其他feature模块无需重复配置
- 配置在entry模块即可全局生效

## 输出结果报告

配置完成后输出以下信息：

```json
{
  "status": "success",
  "client_id_configured": true,
  "module": "entry",
  "config_file": "entry/src/main/module.json5",
  "next_steps": [
    "申请Health Service Kit权限",
    "集成Health Service SDK",
    "调用Health Service API"
  ]
}
```

## 参考文档

- [API开发指南](references/health-configuration-client-id.md)
- [AppGallery Connect平台](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)

## 完整示例代码

- [module.json5配置示例](assets/module.json5)
- [验证配置示例](assets/verify_config.ets)

## 测试用例

### 正向测试用例
- [配置正确Client ID](tests/test_positive.ets)：使用有效的Client ID配置metadata
- [读取Client ID](tests/test_positive.ets)：成功读取已配置的Client ID

### 边界测试用例
- [Client ID长度边界](tests/test_boundary.ets)：测试64字符长度限制
- [特殊字符处理](tests/test_boundary.ets)：测试Client ID中的特殊字符

### 异常测试用例
- [Client ID为空](tests/test_exception.ets)：value字段为空字符串
- [metadata缺失](tests/test_exception.ets)：未配置metadata数组
- [JSON格式错误](tests/test_exception.ets)：module.json5语法错误