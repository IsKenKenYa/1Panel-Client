# API参数详细说明

本文档详细说明了openFormManager API的参数定义和使用方法。

## openFormManager API

### API定义
```typescript
formProvider.openFormManager(want: Want): void
```

### 功能说明
打开当前应用的卡片管理页面，用户可以在卡片管理页面选择将卡片添加到桌面或负一屏。

### API版本
- 起始版本: API version 18
- 元服务API: 从API version 18开始支持在元服务中使用
- 系统能力: SystemCapability.Ability.Form

### 参数说明

#### want参数结构

| 参数名 | 类型 | 必填 | 说明 |
|-------|------|------|------|
| bundleName | string | 是 | 卡片所属应用的包名 |
| abilityName | string | 是 | 卡片所属的ability名称 |
| parameters | Record<string, Object> | 否 | 卡片参数信息 |

#### parameters字段说明

parameters字段需要包含以下三个关键参数:

| 参数名 | 类型 | 说明 |
|-------|------|------|
| ohos.extra.param.key.form_dimension | number | 卡片尺寸，取值范围: 1/2/3/4<br>对应尺寸:<br>1 - 1×2<br>2 - 2×2<br>3 - 2×4<br>4 - 4×4 |
| ohos.extra.param.key.form_name | string | 卡片名称，需与form_config.json中的name字段一致 |
| ohos.extra.param.key.module_name | string | 卡片所属的模块名称 |

### 参数示例

#### 完整参数示例
```typescript
const want: Want = {
  bundleName: "com.samples.formmanagerdemo",
  abilityName: 'EntryFormAbility',
  parameters: {
    'ohos.extra.param.key.form_dimension': 2,
    'ohos.extra.param.key.form_name': 'widget',
    'ohos.extra.param.key.module_name': 'entry'
  },
};
```

#### 最小参数示例
```typescript
const want: Want = {
  bundleName: "com.samples.formmanagerdemo",
  abilityName: 'EntryFormAbility'
};
```

### 特殊说明

1. **参数不完整情况**
   - 如果parameters参数没有填完整或者指定的卡片不存在
   - 会默认展示form_config.json中配置的默认卡片
   - 默认卡片由isDefault字段标识

2. **卡片尺寸说明**
   - form_dimension值必须与form_config.json中supportDimensions配置一致
   - 如果指定的尺寸未配置，会报16501012错误码

3. **模块名称说明**
   - moduleName必须与实际模块名称一致
   - 如果卡片在HAR中，moduleName需为依赖该HAR的HAP/HSP的moduleName

### 错误码说明

| 错误码 | 错误信息 | 可能原因 |
|-------|---------|---------|
| 16500050 | IPC connection error | IPC通信失败 |
| 16500100 | Failed to obtain the configuration information | 获取配置信息失败 |
| 16501000 | An internal functional error occurred | 内部功能错误 |

### 使用限制

1. **API版本要求**
   - 必须在API version 18及以上版本使用
   - 低版本调用会报801错误码

2. **卡片配置要求**
   - 卡片必须在form_config.json中正确配置
   - 卡片信息必须与配置文件一致

3. **调用时机**
   - 只能在应用内调用
   - 不能跨应用调用

### 参考文档
- [openFormManager API完整定义](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formprovider)
- [Want接口完整定义](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-want)
- [卡片尺寸定义](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-forminfo)