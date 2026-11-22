---
name: hmos-share-kit-direct-access-configuration
description: 配置Share Kit指定应用直达功能，通过module.json5配置shareType和shareBundleName元数据实现碰一碰分享时拉起指定应用，仅支持同开发者账号、单文件、非媒体类和压缩包文件，适用于指定应用接收分享数据场景
---

# Share Kit指定应用直达配置技能

## 功能描述

配置Share Kit的指定应用直达功能，允许同开发者账号下的应用在碰一碰分享时优先拉起指定应用。通过在module.json5中配置metadata元数据（shareType和shareBundleName）实现应用分组匹配和指定应用拉起。

**核心能力**：
- 配置shareType元数据实现应用分组匹配
- 配置shareBundleName元数据指定拉起的应用包名
- 支持同包名应用优先直达
- 支持同开发者账号下应用优先拉起配置

**适用场景**：
- 碰一碰分享接收端需要指定特定应用处理
- 同开发者账号下多个应用需要协同处理分享数据
- 需要区分不同场景拉起不同应用

**不适用场景**：
- 跨开发者账号的应用分享
- 多文件（2个及以上）分享
- 媒体类文件（图片、视频）分享
- 压缩包类型文件分享
- 非碰一碰分享方式

## 使用场景

### 触发词
- "Share Kit指定应用直达"
- "碰一碰分享指定应用"
- "配置分享直达应用"
- "shareBundleName配置"
- "分享数据指定应用拉起"

### 能做
- 配置module.json5中的metadata标签实现指定应用直达
- 配置shareType实现同开发者账号下的应用分组
- 配置shareBundleName指定优先拉起的应用包名
- 实现同包名应用优先拉起逻辑
- 实现隐式Want匹配规则配置

### 绝不做
- 不配置跨开发者账号的应用直达（不支持）
- 不处理媒体类文件和压缩包分享（不支持）
- 不处理多文件分享场景（不支持）
- 不配置非碰一碰分享方式（不支持）
- 不配置无隐式Want匹配能力的应用

### 补充
- 需要API版本6.0.0(20) Beta3及以上
- shareType仅支持配置一项，配置多项时仅第一项生效
- shareBundleName可配置多项，按数组顺序匹配
- 应用必须满足隐式Want匹配规则才能被拉起

## 调用规范和规则

### 输入约束
- 配置文件：必须是module.json5格式
- shareType值：字符串类型，用于分组匹配
- shareBundleName值：字符串数组，指定应用包名
- 技能配置：skills配置必须满足隐式Want匹配规则
- metadata标签：必须配置在module层级下

### 执行约束
- 最大配置项：shareType最多1项，shareBundleName可多项
- 包名格式：必须符合HarmonyOS应用包名规范
- 版本要求：API 6.0.0(20) Beta3及以上
- 开发者账号：发送端和接收端必须同developerId

### 内容约束
- 禁止配置媒体文件处理（系统默认处理）
- 禁止配置压缩包文件处理（不支持）
- 禁止配置多文件处理（不支持）
- 禁止跨开发者账号配置
- 必须配置有效的隐式Want匹配规则

### 降级约束
- 配置无效：提示配置错误并给出正确示例
- 不满足版本要求：提示升级API版本
- 不满足隐式Want匹配：提示检查skills配置
- 不满足同开发者账号：提示账号限制

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认API版本为6.0.0(20) Beta3及以上
2. 确认应用包名符合HarmonyOS规范
3. 确认接收端和发送端为同开发者账号
4. 确认分享数据类型为非媒体、非压缩包的单文件

**参数准备**：
```json
// module.json5配置参数
{
  "shareType": "分组标识字符串",
  "shareBundleName": [
    "com.example.app1",
    "com.example.app2"
  ]
}
```

### 步骤2：配置module.json5文件

**完整配置示例**：
```json
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
    "page": "",
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "description": "$string:EntryAbility_desc",
        "icon": "$media:icon",
        "label": "$string:EntryAbility_label",
        "startWindowIcon": "$media:launcher",
        "startWindowBackground": "$color:start_window_background",
        "exported": true,
        "skills": [
          {
            "entities": [
              "entity.system.home"
            ],
            "actions": [
              "ohos.want.action.viewData"
            ],
            "uris": [
              {
                "scheme": "file",
                "linkFeature": "FileOpen",
                "type": "org.openxmlformats.wordprocessingml.document",
                "maxFileSupported": 1
              }
            ],
            "domainVerify": true
          }
        ]
      }
    ],
    "metadata": [
      {
        "name": "shareType",
        "value": "sharekitModel"
      },
      {
        "name": "shareBundleName",
        "value": "com.example.sharekitPhone"
      },
      {
        "name": "shareBundleName",
        "value": "com.example.sharekitPc"
      }
    ]
  }
}
```

**配置说明**：
1. **metadata配置**：必须在module层级下配置metadata数组
2. **shareType配置**：用于分组匹配，发送端和接收端应用必须配置相同的shareType值
3. **shareBundleName配置**：指定优先拉起的应用包名，可配置多个，按数组顺序匹配
4. **skills配置**：必须配置有效的隐式Want匹配规则，否则无法拉起应用

### 步骤3：验证隐式Want匹配规则

**验证要点**：
```typescript
// 检查skills配置是否满足隐式Want匹配
// 1. actions配置：必须包含能够响应分享数据的action
// 2. uris配置：必须配置scheme、type或linkFeature
// 3. entities配置：可选，但建议配置entity.system.home

// 示例：文件类型隐式匹配配置
{
  "skills": [
    {
      "entities": ["entity.system.home"],
      "actions": ["ohos.want.action.viewData"],
      "uris": [
        {
          "scheme": "file",
          "linkFeature": "FileOpen",
          "type": "org.openxmlformats.wordprocessingml.document",
          "maxFileSupported": 1
        }
      ],
      "domainVerify": true
    }
  ]
}
```

**匹配规则说明**：
- linkFeature匹配：优先级最高，当want参数包含linkFeature时优先匹配
- action匹配：want参数的action必须包含在skills的actions中
- entities匹配：want参数的entities必须全部包含在skills的entities中
- uri匹配：want参数的uri必须匹配skills的uris配置
- type匹配：want参数的type必须匹配skills的type配置

### 步骤4：测试配置

**测试流程**：
1. 安装配置好的应用
2. 使用碰一碰分享功能分享单文件
3. 观察是否拉起指定应用
4. 检查日志确认匹配过程

**调试命令**：
```bash
# 查看应用配置
hdc shell bm dump -n com.example.app

# 查看隐式Want匹配日志
hdc hilog | grep -i "want"

# 测试分享功能
hdc shell aa start -A EntryAbility -b com.example.app -U file:///path/to/file
```

### 步骤5：错误处理

**常见错误处理**：
```typescript
// 处理分享数据接收错误
import common from '@ohos.app.ability.common';

async function handleShareData(want: common.Want): Promise<void> {
  try {
    // 验证want参数
    if (!want.parameters) {
      console.error('Want parameters is empty');
      return;
    }
    
    // 验证文件类型
    const files = want.parameters['ohos.extra.param.key.stream'] as Array<string>;
    if (!files || files.length === 0) {
      console.error('No files received');
      return;
    }
    
    // 验证文件数量限制
    if (files.length > 1) {
      console.error('Multiple files not supported');
      return;
    }
    
    // 处理单文件
    const filePath = files[0];
    console.info('Received file:', filePath);
    
    // 处理文件内容
    // ...
    
  } catch (error) {
    console.error('Handle share data failed:', error.message);
    // 错误上报
    // ...
  }
}
```

### 步骤6：降级处理

**降级方案**：
```typescript
// 当指定应用无法拉起时的降级处理
import common from '@ohos.app.ability.common';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';

async function fallbackHandler(want: common.Want): Promise<void> {
  try {
    // 尝试拉起默认应用
    console.warn('Fallback to default handler');
    
    // 检查文件权限
    const atManager = abilityAccessCtrl.createAtManager();
    const grantStatus = await atManager.verifyAccessToken(
      getContext().applicationInfo.accessTokenId,
      'ohos.permission.READ_MEDIA'
    );
    
    if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      // 有权限，使用默认文件查看器
      const defaultWant: common.Want = {
        action: 'ohos.want.action.viewData',
        uri: want.uri,
        type: want.type
      };
      await common.getContext().startAbility(defaultWant);
    } else {
      // 无权限，提示用户
      console.error('Permission denied, cannot open file');
      // 显示提示信息
    }
  } catch (error) {
    console.error('Fallback handler failed:', error.message);
    // 最终降级：显示错误信息给用户
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 16000050 | 内部错误 | 检查配置文件格式，确认module.json5语法正确 |
| 16000001 | 输入参数无效 | 检查shareType和shareBundleName配置是否有效 |
| 16000007 | 服务异常 | 检查系统服务状态，重启应用或设备 |
| 16000004 | 未找到Ability | 确认应用已安装，包名配置正确 |
| 16000005 | 不允许的Ability调用 | 检查应用权限配置和签名信息 |
| 16000011 | 系统内部错误 | 检查系统日志，确认系统服务正常 |
| 16000012 | 应用控制校验失败 | 确认开发者账号一致，签名信息正确 |
| 16000013 | 应用未安装 | 安装指定的应用后再试 |
| 16000050 | 元数据配置错误 | 检查metadata配置格式，确认name和value字段有效 |

## 编译和修复问题

### 依赖声明
```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "deviceTypes": ["phone", "tablet", "2in1"],
    "abilities": [...],
    "metadata": [...]
  }
}
```

### 环境要求
- HarmonyOS SDK: API 12 (6.0.0) Beta3及以上
- DevEco Studio: 4.0及以上
- 编译工具: hvigor 4.0及以上
- 目标设备: 支持碰一碰分享的设备

### 常见编译问题

**问题1：metadata配置位置错误**
```
ERROR: metadata should be configured under module tag
```
**解决方法**：确保metadata配置在module层级下，而非abilities或skills内

**问题2：shareType重复配置**
```
WARNING: Only the first shareType will take effect
```
**解决方法**：shareType仅配置一项，移除多余配置

**问题3：隐式Want匹配失败**
```
ERROR: No ability matched the implicit want
```
**解决方法**：
1. 检查skills配置的actions、entities、uris是否正确
2. 确认linkFeature配置有效
3. 验证type和scheme匹配规则

**问题4：权限不足**
```
ERROR: Permission denied
```
**解决方法**：
1. 在module.json5中添加所需权限
2. 运行时动态申请权限
3. 检查签名配置是否包含权限声明

## 常见问题与解决方法

### Q1：配置后应用无法被拉起
**原因**：隐式Want匹配规则配置不正确
**解决方法**：
- 检查skills配置是否完整（actions、entities、uris）
- 确认linkFeature配置正确
- 验证type和scheme匹配接收的数据类型
- 查看系统日志确认匹配过程

### Q2：shareType配置无效
**原因**：发送端和接收端shareType不一致
**解决方法**：
- 确保发送端和接收端配置相同的shareType值
- 检查是否存在多余的空格或特殊字符
- 确认shareType配置在metadata数组的第一项

### Q3：多个shareBundleName配置如何生效
**原因**：系统按数组顺序匹配第一个已安装且支持拉起的应用
**解决方法**：
- 将优先级高的应用包名放在数组前面
- 确保列表中的应用都已安装且配置正确
- 测试时逐个验证每个应用的拉起情况

### Q4：跨设备分享无法拉起指定应用
**原因**：跨设备场景暂不支持指定应用直达
**解决方法**：
- 确认使用碰一碰分享方式
- 检查设备是否支持碰一碰功能
- 验证两端设备是否连接正常

### Q5：分享媒体文件无法拉起指定应用
**原因**：媒体文件由系统默认处理，不支持指定应用
**解决方法**：
- 确认分享数据类型为非媒体文件
- 使用文档、文本等支持自定义处理的文件类型
- 参考"一步直达"规则表格确认数据类型支持情况

### Q6：开发者账号不一致导致无法拉起
**原因**：指定应用直达仅支持同developerId的应用
**解决方法**：
- 确认发送端和接收端应用使用相同的开发者账号签名
- 检查签名信息中的developerId是否一致
- 使用相同的签名证书重新签名应用

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "configuration": {
    "shareType": "sharekitModel",
    "shareBundleNames": [
      "com.example.sharekitPhone",
      "com.example.sharekitPc"
    ],
    "apiVersion": "6.0.0(20) Beta3+",
    "matchRule": "implicit_want"
  },
  "abilities": [
    {
      "name": "EntryAbility",
      "actions": ["ohos.want.action.viewData"],
      "entities": ["entity.system.home"],
      "uris": [
        {
          "scheme": "file",
          "linkFeature": "FileOpen",
          "type": "org.openxmlformats.wordprocessingml.document"
        }
      ]
    }
  ],
  "restrictions": {
    "developerAccount": "same",
    "fileType": "non-media, non-archive",
    "fileCount": 1,
    "shareMethod": "touch_share_only"
  }
}
```

## 参考文档

- [目标设备接收分享数据一步直达体验](references/share-access-one-step.md)
- [显式Want与隐式Want匹配规则](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/explicit-implicit-want-mappings)
- [module.json5配置文件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/module-configuration-file)

## 完整示例代码

- [module.json5配置示例](assets/module.json5)
- [Ability接收分享数据处理示例](assets/EntryAbility.ets)
- [错误处理和降级示例](assets/fallback_handler.ets)

## 测试用例

### 正向测试用例
- [单文件指定应用拉起测试](tests/test_single_file_launch.ets)：验证单文件分享时能正确拉起指定应用
- [同包名应用优先拉起测试](tests/test_same_package_priority.ets)：验证同包名应用优先拉起逻辑
- [多应用顺序匹配测试](tests/test_multi_app_order.ets)：验证多个shareBundleName按顺序匹配

### 边界测试用例
- [最低API版本测试](tests/test_min_api_version.ets)：验证API 6.0.0(20) Beta3最低版本要求
- [最大包名数量测试](tests/test_max_bundle_names.ets)：验证shareBundleName数组最大数量限制
- [数据类型边界测试](tests/test_file_type_boundary.ets)：验证支持的文件类型边界

### 异常测试用例
- [跨开发者账号测试](tests/test_cross_developer.ets)：验证跨开发者账号场景的错误处理
- [媒体文件测试](tests/test_media_file.ets)：验证媒体文件分享的错误处理
- [多文件测试](tests/test_multi_files.ets)：验证多文件分享的错误处理
- [无效配置测试](tests/test_invalid_config.ets)：验证无效配置的错误处理