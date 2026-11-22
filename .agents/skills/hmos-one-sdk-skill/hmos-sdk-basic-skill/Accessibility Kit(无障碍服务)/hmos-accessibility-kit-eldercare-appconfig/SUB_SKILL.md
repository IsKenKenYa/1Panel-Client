---
name: hmos-accessibility-kit-eldercare-appconfig
description: 声明应用接入系统关怀模式，在module.json5配置metadata，让用户可在设备设置中管理应用关怀模式开关，API版本26.0.0+，适用于长辈关怀、无障碍应用场景
---

# 应用声明接入系统关怀模式技能

## 功能描述

本技能用于在HarmonyOS应用中声明接入系统关怀模式（长辈模式/关爱版/大字版）。通过在应用工程module.json5文件中声明metadata配置，使应用能够被系统识别并在设备"设置>关怀和无障碍>关怀模式>应用管理"中展示，允许用户自由切换关怀模式开关状态。

**核心功能**：
- 配置module.json5的metadata声明接入系统关怀模式
- 实现应用关怀模式与系统设置的联动机制
- 确保应用内关怀模式状态与系统设置保持同步

**适用范围**：
- 已实现独立关怀模式功能的应用（API版本26.0.0及以上）
- 需要在系统设置中展示关怀模式开关的应用
- 希望与系统关怀模式保持同步的应用

**限制条件**：
- 仅支持API版本26.0.0及以上
- 需应用已实现独立关怀模式功能
- 用户关闭系统关怀模式时，应用内关怀模式会同步关闭

## 使用场景

### 触发词
- "接入系统关怀模式"
- "配置长辈模式"
- "声明关爱版"
- "应用关怀模式设置"
- "module.json5配置关怀模式"
- "长辈关怀功能"

### 能做
- 在module.json5中正确配置metadata声明接入系统关怀模式
- 指导如何在module.json5中声明senior_mode metadata
- 说明metadata配置的name和value参数
- 提供完整的module.json5配置示例
- 解释系统关怀模式与应用关怀模式的联动机制
- 引导开发者实现应用内关怀模式与系统设置同步

### 绝不做
- 不直接修改用户的module.json5文件（需要开发者手动配置）
- 不替代具体的应用内关怀模式UI实现
- 不处理应用内关怀模式的具体业务逻辑
- 不涉及关怀模式的具体功能开发（如字体放大、图标放大等）

### 补充
- 建议声明在有关怀模式功能的module下
- 用户在设置中关闭系统关怀模式开关，应用内关怀模式也会随之关闭
- 重新开启系统关怀模式，原先被关闭的应用会同步开启
- 建议配合应用内关怀模式与系统设置同步功能使用

## 调用规范和规则

### 输入约束
- 应用必须已实现独立关怀模式功能
- 应用必须使用API版本26.0.0及以上
- module.json5文件必须存在且格式正确
- metadata配置必须在正确的module节点下

### 执行约束
- 配置修改前需验证module.json5格式正确性
- 需确保metadata的name和value参数符合规范
- 配置完成后需重新编译应用以生效
- 最多允许配置一个senior_mode metadata

### 内容约束
- 禁止在错误的module节点下声明metadata
- 禁止使用不符合规范的name或value值
- 禁止在未实现关怀模式功能的情况下声明metadata
- metadata配置必须完整包含name和value字段

### 降级约束
- 应用未实现关怀模式功能：不声明metadata，建议先实现关怀模式功能
- API版本低于26.0.0：不声明metadata，提示需要升级API版本
- module.json5格式错误：提示修正配置文件格式，不执行metadata声明

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认应用已实现独立关怀模式功能（长辈模式/关爱版/大字版等）
2. 验证应用使用的API版本是否为26.0.0及以上
3. 检查module.json5文件是否存在且格式正确
4. 确认需要声明metadata的目标module节点

**参数准备**：
```typescript
// metadata配置参数
{
  "name": "senior_mode",          // 固定值，表示关怀模式声明
  "value": "independent_control"  // 固定值，表示独立控制模式
}
```

### 步骤2：配置module.json5

**示例代码**：
```typescript
// module.json5配置示例
{
  "module": {
    "name": "entry",              // module名称
    "type": "entry",              // module类型
    "deviceTypes": [
      "default",
      "tablet"
    ],
    // 其他声明此处省略...
    
    // 关怀模式metadata声明
    "metadata": [{
      "name": "senior_mode",
      "value": "independent_control"
    }]
  }
}
```

**配置说明**：
1. 在module节点下添加metadata数组
2. metadata数组中添加一个对象，包含name和value字段
3. name字段固定为"senior_mode"
4. value字段固定为"independent_control"
5. 建议声明在有关怀模式功能的module下

### 步骤3：验证配置

**验证要点**：
```typescript
// 配置验证检查项
1. metadata是否在正确的module节点下
2. metadata数组格式是否正确
3. name字段是否为"senior_mode"
4. value字段是否为"independent_control"
5. JSON格式是否正确（无语法错误）
```

### 步骤4：编译和测试

**编译步骤**：
1. 保存module.json5文件修改
2. 清理项目构建缓存（可选）
3. 重新编译应用项目
4. 安装应用到测试设备

**测试验证**：
1. 打开设备"设置"应用
2. 进入"关怀和无障碍 > 关怀模式 > 应用管理"
3. 查看本应用是否在列表中展示
4. 测试切换关怀模式开关是否正常工作
5. 验证应用内关怀模式是否同步变化

### 步骤5：实现状态同步（可选）

如果需要实现应用内关怀模式与系统设置同步，请参照相关技能：

**同步实现步骤**：
1. 使用AccessibilityKit提供的API监听系统关怀模式状态变化
2. 应用启动时查询系统关怀模式状态并同步应用内状态
3. 用户在应用内切换关怀模式时，同步更新系统设置中的状态
4. 监听系统设置中的关怀模式开关变化，及时更新应用内状态

详细实现请参考：
- [应用内关怀模式与系统设置同步](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/eldercare-senior-mode-description)
- [获取关怀模式状态](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/eldercare-description)

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| CONFIG_ERROR_001 | module.json5格式错误 | 检查JSON语法，确保格式正确 |
| CONFIG_ERROR_002 | metadata声明位置错误 | 确保metadata在module节点下声明 |
| CONFIG_ERROR_003 | metadata参数错误 | 确保name为"senior_mode"，value为"independent_control" |
| CONFIG_ERROR_004 | API版本不支持 | 升级应用API版本至26.0.0及以上 |
| CONFIG_ERROR_005 | 应用未实现关怀模式功能 | 先实现应用内关怀模式功能再声明metadata |
| SYNC_ERROR_001 | 系统设置与应用状态不同步 | 实现状态监听和同步机制 |
| SYNC_ERROR_002 | 关怀模式开关失效 | 检查metadata配置和权限设置 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AccessibilityKit": "^26.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK：API版本26.0.0及以上
- DevEco Studio：最新版本
- 测试设备：支持关怀模式的HarmonyOS设备

### 常见编译问题

**问题1：module.json5配置错误**
```
Error: Invalid JSON format in module.json5
```
**解决方法**：
- 使用JSON格式验证工具检查文件格式
- 确保所有字段使用双引号
- 检查数组和大括号是否匹配
- 验证metadata配置在module节点下

**问题2：metadata未生效**
```
Warning: metadata configuration not recognized
```
**解决方法**：
- 确认API版本是否为26.0.0及以上
- 清理项目构建缓存并重新编译
- 检查metadata的name和value参数是否正确
- 确认设备是否支持关怀模式功能

**问题3：应用未在系统设置中展示**
```
Issue: App not shown in Settings > Care Mode > App Management
```
**解决方法**：
- 确认应用已实现独立关怀模式功能
- 检查metadata配置是否正确
- 验证应用是否已正确安装到设备
- 确认设备系统版本是否支持关怀模式

## 常见问题与解决方法

### Q1：为什么应用未在系统设置中展示？
**原因**：
- 应用未实现独立关怀模式功能
- metadata配置错误或未生效
- API版本不支持（低于26.0.0）
- 设备系统版本不支持

**解决方法**：
- 先实现应用内关怀模式功能
- 检查并修正metadata配置
- 升级应用API版本至26.0.0及以上
- 使用支持关怀模式的设备测试

### Q2：如何确保应用内关怀模式与系统设置同步？
**原因**：需要监听系统关怀模式状态变化并实时更新应用内状态

**解决方法**：
- 实现状态监听机制（参考应用内关怀模式与系统设置同步文档）
- 应用启动时查询系统状态并同步
- 用户操作时双向同步状态
- 监听系统设置变化并及时响应

### Q3：用户关闭系统关怀模式后，应用内关怀模式会怎样？
**原因**：系统关怀模式与应用关怀模式存在联动机制

**解决方法**：
- 应用内关怀模式会自动关闭
- 重新开启系统关怀模式时，原先关闭的应用会同步开启
- 可通过监听机制实现更精细的控制

### Q4：应用内没有独立关怀模式开关怎么办？
**原因**：应用希望完全跟随系统关怀模式，不提供独立开关

**解决方法**：
- 不声明metadata（不在系统设置中展示）
- 使用AccessibilityKit API监听系统关怀模式状态
- 实现跟随系统关怀模式变化的功能
- 参考"获取关怀模式状态"文档实现

### Q5：metadata可以声明多个吗？
**原因**：metadata数组可以包含多个配置项

**解决方法**：
- metadata数组支持多个配置项
- senior_mode配置建议只声明一次
- 可以与其他metadata配置共存
- 确保每个metadata对象格式正确

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "configuration": {
    "metadata": {
      "name": "senior_mode",
      "value": "independent_control"
    },
    "module": "entry",
    "apiVersion": "26.0.0+"
  },
  "validation": {
    "jsonFormat": "valid",
    "metadataPlacement": "correct",
    "apiVersionSupported": true
  },
  "testing": {
    "settingsVisibility": true,
    "switchFunction": "working",
    "stateSync": "recommended"
  },
  "recommendations": [
    "建议实现应用内关怀模式与系统设置同步功能",
    "建议在有关怀模式功能的module下声明metadata",
    "建议测试设备系统版本是否支持关怀模式"
  ],
  "apiUsed": [],
  "configFilesModified": [
    "module.json5"
  ]
}
```

## 参考文档

- [应用声明接入系统关怀模式](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/eldercare-appconfig) - 原始开发指南
- [应用内关怀模式与系统设置同步](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/eldercare-senior-mode-description) - 状态同步实现指导
- [获取关怀模式状态](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/eldercare-description) - 监听系统关怀模式状态

## 完整示例代码

- [module.json5配置示例](assets/module.json5.example) - 完整的module.json5配置示例
- [关怀模式状态监听示例](assets/senior_mode_listener.ets) - ArkTS状态监听实现示例
- [关怀模式同步示例](assets/senior_mode_sync.ets) - ArkTS状态同步实现示例

## 测试用例

### 正向测试用例
- [配置验证测试](tests/test_config_positive.ets) - 验证metadata配置正确性
- [系统设置展示测试](tests/test_settings_display.ets) - 验证应用在系统设置中展示
- [开关功能测试](tests/test_switch_function.ets) - 验证关怀模式开关功能

### 边界测试用例
- [API版本边界测试](tests/test_api_version_boundary.ets) - 测试API版本兼容性
- [多module配置测试](tests/test_multi_module.ets) - 测试多个module配置场景

### 异常测试用例
- [配置错误测试](tests/test_config_error.ets) - 测试错误配置的处理
- [API版本不支持测试](tests/test_api_version_unsupported.ets) - 测试低版本API的处理
- [设备不支持测试](tests/test_device_unsupported.ets) - 测试不支持关怀模式的设备