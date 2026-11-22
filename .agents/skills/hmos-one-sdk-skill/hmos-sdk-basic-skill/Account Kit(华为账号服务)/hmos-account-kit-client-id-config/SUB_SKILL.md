---
name: hmos-account-kit-client-id-config
description: 配置HarmonyOS应用Client ID+Account Kit服务+需AGC项目权限+应用开发准备阶段
---

# 配置Client ID技能

## 功能描述

本技能用于在HarmonyOS应用工程中配置Account Kit的Client ID，确保应用能够正常调用Account Kit相关API。通过本技能，开发者可以在AppGallery Connect（AGC）获取Client ID，并根据需要将其配置到工程的module.json5文件中，解决Client ID与APP ID不一致时的认证问题。

核心功能：
- 从AGC获取应用的Client ID和APP ID
- 判断是否需要配置Client ID
- 在module.json5中正确配置metadata
- 验证配置的有效性

## 使用场景

### 触发词
- "配置Client ID"
- "Account Kit Client ID配置"
- "应用Client ID设置"
- "module.json5配置Client ID"
- "AGC Client ID获取"

### 能做
- 指导开发者在AGC获取Client ID和APP ID
- 判断是否需要配置Client ID（Client ID与APP ID是否相同）
- 在entry模块的module.json5中配置metadata
- 验证Client ID配置的正确性
- 提供常见配置错误的排查方法

### 绝不做
- 不负责AGC项目的创建和应用配置
- 不处理Client ID的动态获取（仅支持静态配置）
- 不处理非entry模块的Client ID配置
- 不支持项目级别的Client ID配置（必须是应用级别）
- 不处理Client ID的权限申请（仅负责配置）

### 补充
- 仅适用于HarmonyOS应用开发
- 需要开发者拥有AGC项目的访问权限
- 配置前需确认已创建HarmonyOS应用项目
- 确保获取的是应用Client ID而非项目Client ID

## 调用规范和规则

### 输入约束
- 工程路径：必须是有效的HarmonyOS工程目录
- module.json5文件：必须存在于entry模块中
- Client ID：必须是有效的字符串格式
- 文件编码：module.json5必须为UTF-8编码

### 执行约束
- 最大配置耗时：5分钟
- 配置验证：配置后需验证语法正确性
- 备份要求：修改前需备份原始module.json5文件
- 格式要求：metadata配置需符合JSON5语法规范

### 内容约束
- 禁止修改非entry模块的配置
- 禁止使用项目Client ID替代应用Client ID
- 禁止在module.json5中配置多个client_id
- 禁止删除或修改已有的metadata配置
- 禁止使用环境变量或占位符设置Client ID值

### 降级约束
- module.json5文件损坏：提示用户手动修复或恢复备份
- Client ID无法获取：提示用户检查AGC权限或联系项目管理员
- 配置语法错误：提供JSON5语法检查工具和修复建议
- 文件权限不足：提示用户调整文件权限或使用管理员权限

## 调用流程和步骤

### 步骤1：获取Client ID和APP ID

**前置校验**：
1. 确认开发者拥有AGC项目的访问权限
2. 确认项目和应用已在AGC中创建
3. 确认当前处于应用开发准备阶段

**操作步骤**：
1. 登录AppGallery Connect平台
2. 进入【开发与服务】>【我的项目】
3. 选择对应的项目和应用
4. 在"常规 > 应用"下查看应用的Client ID和APP ID

**参数说明**：
```
项目路径：https://developer.huawei.com/consumer/cn/service/josp/agc/index.html#/myProject
配置位置：常规 > 应用 > 应用信息
需要获取的字段：
  - Client ID：应用标识，用于API调用认证
  - APP ID：应用唯一标识
```

**输出结果**：
- Client ID：字符串类型，例如："1234567890abcdef"
- APP ID：字符串类型，用于对比判断

### 步骤2：确认是否需要配置Client ID

**判断逻辑**：
```typescript
// 判断是否需要配置
function needConfigureClientID(clientID: string, appID: string): boolean {
  // 如果Client ID和APP ID相同，则无需配置
  if (clientID === appID) {
    console.log('Client ID与APP ID相同，无需额外配置');
    return false;
  }
  // 否则需要配置
  console.log('Client ID与APP ID不同，需要配置Client ID');
  return true;
}
```

**决策表**：
| Client ID与APP ID关系 | 是否需要配置 | 说明 |
|---------------------|------------|------|
| 相同 | 否 | 系统自动识别，无需手动配置 |
| 不同 | 是 | 必须在module.json5中手动配置 |

### 步骤3：配置Client ID

**前置准备**：
1. 备份原始module.json5文件
2. 确认Client ID的值正确（应用Client ID，非项目Client ID）
3. 确认当前操作的模块类型为"entry"

**配置示例**：
```json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": [
      "phone",
      "tablet",
      "2in1"
    ],
    "deliveryWithInstall": true,
    "installationFree": false,
    "pages": "$profile:main_pages",
    "abilities": [
      // ... abilities配置
    ],
    "metadata": [
      // 其他metadata配置...
      {
        "name": "client_id",
        "value": "你的应用Client ID值"  // 注意：直接填写Client ID字符串，不要使用其他方式设置
      }
    ]
  }
}
```

**配置要点**：
1. metadata必须是数组类型
2. 每个metadata项包含name和value两个属性
3. name必须为"client_id"（固定值）
4. value直接填写Client ID的字符串值
5. 如果metadata数组已存在其他配置，追加到数组末尾
6. 如果metadata不存在，创建新的metadata数组

**错误处理代码**：
```typescript
import fs from '@ohos.file.fs';
import json5 from 'json5';

// 配置Client ID
function configureClientID(moduleJson5Path: string, clientID: string): void {
  try {
    // 读取原始文件
    const content = fs.readTextSync(moduleJson5Path);
    const moduleConfig = json5.parse(content);
    
    // 验证模块类型
    if (moduleConfig.module?.type !== 'entry') {
      throw new Error('只能在entry模块中配置Client ID');
    }
    
    // 初始化metadata数组
    if (!moduleConfig.module.metadata) {
      moduleConfig.module.metadata = [];
    }
    
    // 检查是否已存在client_id配置
    const existingIndex = moduleConfig.module.metadata.findIndex(
      (item: any) => item.name === 'client_id'
    );
    
    if (existingIndex >= 0) {
      console.warn('Client ID已存在，将更新配置');
      moduleConfig.module.metadata[existingIndex].value = clientID;
    } else {
      // 添加新的client_id配置
      moduleConfig.module.metadata.push({
        name: 'client_id',
        value: clientID
      });
    }
    
    // 写入文件
    fs.writeTextSync(moduleJson5Path, json5.stringify(moduleConfig, null, 2));
    console.log('Client ID配置成功');
    
  } catch (error) {
    console.error('配置Client ID失败:', error.message);
    throw error;
  }
}
```

### 步骤4：验证配置

**验证步骤**：
```typescript
// 验证Client ID配置
function verifyClientIDConfig(moduleJson5Path: string): boolean {
  try {
    const content = fs.readTextSync(moduleJson5Path);
    const moduleConfig = json5.parse(content);
    
    // 检查metadata是否存在
    if (!moduleConfig.module?.metadata) {
      console.error('metadata配置不存在');
      return false;
    }
    
    // 检查client_id配置
    const clientIDConfig = moduleConfig.module.metadata.find(
      (item: any) => item.name === 'client_id'
    );
    
    if (!clientIDConfig) {
      console.error('未找到client_id配置');
      return false;
    }
    
    // 检查value是否有效
    if (!clientIDConfig.value || typeof clientIDConfig.value !== 'string') {
      console.error('client_id的value无效');
      return false;
    }
    
    console.log('Client ID配置验证通过');
    console.log('Client ID:', clientIDConfig.value);
    return true;
    
  } catch (error) {
    console.error('验证配置失败:', error.message);
    return false;
  }
}
```

**验证清单**：
- [ ] module.json5文件语法正确（JSON5格式）
- [ ] module.type为"entry"
- [ ] metadata数组存在
- [ ] client_id配置项存在
- [ ] client_id的value为字符串类型且非空
- [ ] 配置后应用可正常编译
- [ ] 运行应用无Client ID相关错误

### 步骤5：降级处理

**场景1：module.json5文件损坏**
```typescript
// 恢复备份文件
function restoreBackup(backupPath: string, targetPath: string): void {
  try {
    const backupContent = fs.readTextSync(backupPath);
    fs.writeTextSync(targetPath, backupContent);
    console.log('已从备份恢复module.json5');
  } catch (error) {
    console.error('恢复备份失败:', error.message);
    console.warn('请手动修复module.json5文件或重新创建工程');
  }
}
```

**场景2：无法获取Client ID**
```text
降级方案：
1. 检查AGC账号权限，确认是否有项目访问权限
2. 联系项目管理员获取Client ID
3. 确认项目和应用是否已创建
4. 如果是团队开发，向项目管理员申请查看权限
5. 临时使用模拟Client ID进行开发（仅限开发阶段，上线前必须使用真实Client ID）
```

**场景3：配置后编译失败**
```text
排查步骤：
1. 检查module.json5的JSON5语法是否正确
2. 确认metadata配置格式是否符合规范
3. 验证Client ID是否包含特殊字符或空格
4. 检查是否有其他metadata配置冲突
5. 清理工程缓存重新编译：npm run clean && npm run build
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| CONFIG_FILE_NOT_FOUND | module.json5文件不存在 | 检查文件路径是否正确，确认entry模块是否存在 |
| INVALID_JSON5_SYNTAX | JSON5语法错误 | 使用JSON5语法检查工具修复语法错误 |
| CLIENT_ID_DUPLICATE | client_id配置重复 | 删除重复的client_id配置项，保留一个即可 |
| CLIENT_ID_EMPTY | Client ID值为空 | 填写有效的Client ID字符串 |
| INVALID_MODULE_TYPE | 模块类型不是entry | 仅在entry模块中配置Client ID |
| PERMISSION_DENIED | 文件权限不足 | 使用管理员权限或调整文件权限 |
| BACKUP_FAILED | 备份文件失败 | 检查磁盘空间和文件权限 |
| AGC_ACCESS_DENIED | 无法访问AGC平台 | 检查网络连接和账号权限 |
| CLIENT_ID_MISMATCH | Client ID与APP ID不匹配但未配置 | 按步骤配置Client ID |

## 编译和修复问题

### 依赖声明
本技能不需要额外的依赖库，仅需HarmonyOS SDK提供的标准API。

### 环境要求
- HarmonyOS SDK：API 10及以上
- DevEco Studio：3.1及以上版本
- 开发环境：Node.js 14.x及以上

### 常见编译问题

**问题1：module.json5语法错误**
```
Error: SyntaxError: Unexpected token in JSON5 file
```
**解决方法**：
1. 检查JSON5语法，注意逗号、引号的使用
2. 使用DevEco Studio的JSON5格式化工具
3. 参考JSON5规范：https://json5.org/

**问题2：Client ID配置后仍报错**
```
Error: Authentication failed, invalid client_id
```
**解决方法**：
1. 确认使用的是应用Client ID，而非项目Client ID
2. 检查Client ID是否正确复制，无多余空格
3. 在AGC重新查看Client ID并验证
4. 清理工程缓存重新编译

**问题3：metadata配置格式错误**
```
Error: Invalid metadata configuration
```
**解决方法**：
1. 确认metadata是数组类型
2. 每个配置项包含name和value两个属性
3. name和value都是字符串类型
4. 参考正确格式：
```json5
"metadata": [
  {
    "name": "client_id",
    "value": "你的Client ID"
  }
]
```

**问题4：编译后Client ID未生效**
```
应用运行时仍提示Client ID错误
```
**解决方法**：
1. 清理工程缓存：Build > Clean Project
2. 重新编译：Build > Rebuild Project
3. 卸载设备上的旧版本应用
4. 重新安装应用
5. 检查是否在正确的entry模块中配置

## 常见问题与解决方法

### Q1：Client ID和APP ID有什么区别？
**原因**：开发者在AGC看到的两个标识容易混淆
**解决方法**：
- Client ID：应用客户端标识，用于API调用认证
- APP ID：应用唯一标识，用于应用识别
- 在AGC的"常规 > 应用"下可以看到这两个字段
- 如果两者相同，则无需配置Client ID；如果不同，必须配置

### Q2：为什么配置后仍然报Client ID错误？
**原因**：可能使用了错误的Client ID或配置格式不正确
**解决方法**：
1. 确认获取的是应用Client ID，而非项目Client ID
2. 检查Client ID是否完整，没有遗漏或多余空格
3. 验证module.json5的配置格式是否正确
4. 确认是在entry模块中配置，而非其他模块
5. 清理工程缓存并重新编译
6. 卸载旧版本应用重新安装

### Q3：多模块工程应该在哪里配置Client ID？
**原因**：工程中存在多个模块，不确定配置位置
**解决方法**：
- 必须在type为"entry"的模块中配置
- 检查module.json5中的module.type字段
- 如果工程有多个entry模块，在主entry模块中配置
- 其他feature模块不需要配置

### Q4：如何确认配置是否生效？
**原因**：开发者需要验证配置的正确性
**解决方法**：
1. 编译应用，确认无语法错误
2. 查看编译日志，确认无Client ID相关错误
3. 运行应用，调用Account Kit相关API
4. 如果API调用成功，说明Client ID配置正确
5. 可以在代码中打印metadata配置进行验证：
```typescript
import bundleManager from '@ohos.bundle.bundleManager';

// 获取metadata配置
async function getMetadata(): Promise<void> {
  try {
    const bundleInfo = await bundleManager.getBundleInfoForSelf(
      bundleManager.BundleFlag.GET_BUNDLE_WITH_EXTENSION_ABILITY
    );
    console.log('Metadata:', bundleInfo.metadata);
  } catch (error) {
    console.error('获取metadata失败:', error);
  }
}
```

### Q5：能否使用环境变量或配置文件设置Client ID？
**原因**：开发者希望动态管理Client ID
**解决方法**：
- 不支持在module.json5中使用环境变量
- Client ID的value必须是明确的字符串值
- 建议在开发、测试、生产环境使用不同的Client ID
- 可以通过构建脚本替换module.json5中的Client ID值
- 参考DevEco Studio的多环境配置方案

### Q6：配置Client ID后应用体积会增加吗？
**原因**：开发者担心配置会影响应用大小
**解决方法**：
- Client ID只是字符串配置，不会显著增加应用体积
- metadata配置会被编译到应用的manifest中
- 增加的大小通常只有几十字节
- 对应用性能和体积的影响可以忽略不计

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "message": "Client ID配置成功",
  "config": {
    "module": "entry",
    "client_id": "配置的Client ID值",
    "config_file": "entry/src/main/module.json5",
    "backup_created": true
  },
  "validation": {
    "syntax_valid": true,
    "module_type_valid": true,
    "metadata_valid": true,
    "client_id_valid": true
  },
  "next_steps": [
    "清理工程缓存",
    "重新编译应用",
    "测试Account Kit相关API调用"
  ]
}
```

## 参考文档

- [API开发指南](references/account-client-id.md)
- [AppGallery Connect控制台](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html#/myProject)
- [HarmonyOS应用配置文件说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-configuration)

## 完整示例代码

- [module.json5配置示例](assets/module.json5.example)
- [配置验证脚本](assets/verify_client_id.ets)

## 测试用例

### 正向测试用例
- [正常配置Client ID](tests/test_positive.ets)：验证Client ID正确配置后的应用行为
- [Client ID与APP ID相同场景](tests/test_positive.ets)：验证无需配置时的应用行为

### 边界测试用例
- [Client ID包含特殊字符](tests/test_boundary.ets)：验证Client ID包含特殊字符时的处理
- [metadata已存在其他配置](tests/test_boundary.ets)：验证追加client_id配置的场景
- [多次配置Client ID](tests/test_boundary.ets)：验证重复配置的处理逻辑

### 异常测试用例
- [module.json5文件不存在](tests/test_exception.ets)：验证文件不存在的错误处理
- [Client ID为空字符串](tests/test_exception.ets)：验证空值的错误处理
- [非entry模块配置](tests/test_exception.ets)：验证模块类型错误的处理
- [JSON5语法错误](tests/test_exception.ets)：验证语法错误的处理
- [使用项目Client ID](tests/test_exception.ets)：验证Client ID类型错误的识别