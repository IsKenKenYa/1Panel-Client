---
name: hmos-health-service-kit-read-samplepoint
description: 读取最新一条运动健康采样数据,支持Wearable设备开发,需先初始化并完成用户授权,适用于获取体温、血压、血氧等实时健康数据场景
---

# 读取运动健康采样数据技能

## 功能描述

本技能用于读取HarmonyOS运动健康服务中最新的运动健康采样数据(SamplePoint)。通过healthStore.readData接口查询指定数据类型的最新一条采样数据,支持多种健康数据类型包括体温、血压、血氧、心率等。该接口从API 19 Release版本开始支持Wearable设备开发。

**核心能力**:
- 查询最新一条运动健康采样数据
- 支持多种健康数据类型(体温、血压、血氧、日常活动等)
- 支持Wearable设备开发(手表、手环等)
- 异步Promise方式返回查询结果

**限制条件**:
- 当前SamplePointReadRequest里的时间参数暂不生效,仅支持返回手表侧最新一条数据
- 查询时间跨度范围为31天
- 需先完成初始化和用户授权
- 读取实时日常活动数据需使用专门的读取实时三环数据接口

## 使用场景

### 触发词
- "读取运动健康采样数据"
- "查询健康数据"
- "获取体温数据"
- "读取血压数据"
- "查询血氧数据"
- "获取最新健康数据"
- "Health Service Kit采样数据"

### 能做
- 查询指定数据类型的最新一条采样数据
- 获取体温、血压、血氧、心率等多种健康数据
- 支持在Wearable设备上读取健康数据
- 处理查询结果并提取所需字段
- 错误处理和异常降级

### 绝不做
- 不读取实时日常活动数据(需使用专门的读取实时三环数据接口)
- 不批量查询多条历史数据(仅返回最新一条)
- 不写入或修改健康数据
- 不删除健康数据记录
- 不在未授权情况下访问用户健康数据

### 补充
- 必须先调用init方法初始化运动健康服务
- 必须先完成用户授权流程,获取对应数据类型的读取权限
- 查询前需确认数据类型对应的fields字段定义
- Wearable设备上时间参数不生效,仅返回最新数据

## 调用规范和规则

### 输入约束
- **数据类型**: 必须使用healthStore.samplePointHelper中定义的DATA_TYPE常量
- **字段参数**: fields字段必须符合对应数据类型的Fields定义
- **时间参数**: startTime和endTime为Unix时间戳(毫秒),但在Wearable设备上不生效
- **权限要求**: 必须已获得对应数据类型的读取权限

### 执行约束
- **初始化要求**: 接口首次调用前必须先使用init方法初始化
- **授权要求**: 必须先引导用户授权对应数据类型权限
- **异步调用**: 使用async/await或Promise方式异步调用
- **错误处理**: 必须使用try-catch捕获异常

### 内容约束
- **禁止伪造数据**: 禁止返回虚假或模拟的健康数据
- **禁止硬编码敏感信息**: 禁止在代码中硬编码用户健康数据
- **禁止绕过权限**: 禁止在没有用户授权的情况下访问健康数据
- **禁止篡改数据**: 禁止修改或伪造查询结果

### 降级约束
- **权限未授权**: 引导用户进行授权流程,不强制查询
- **初始化失败**: 提示用户稍后重试,检查服务状态
- **网络异常**: 检查网络连接后重试,提供离线提示
- **数据不存在**: 返回空数组,提示用户暂无数据

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 确认已完成运动健康服务申请与Client ID配置
2. 确认已调用init方法完成初始化
3. 确认已通过用户授权接口获取对应数据类型的读取权限
4. 确认设备支持Health Service Kit

**参数准备**:
```typescript
// 导入必要模块
import { healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 创建查询请求
let samplePointReadRequest: healthStore.SamplePointReadRequest = {
  samplePointDataType: healthStore.samplePointHelper.bodyTemperature.DATA_TYPE,
  startTime: 1698633801000,  // Unix时间戳(毫秒)
  endTime: 1698633801000,    // Unix时间戳(毫秒)
  fields: {
    bodyTemperature: 39  // 要查询的字段
  }
};
```

### 步骤2: 调用API

**示例代码**:
```typescript
// 导入必要模块
import { healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 查询运动健康采样数据
async function readHealthSamplePoint(): Promise<void> {
  try {
    // 创建查询请求
    let samplePointReadRequest: healthStore.SamplePointReadRequest = {
      samplePointDataType: healthStore.samplePointHelper.bodyTemperature.DATA_TYPE,
      startTime: 1698633801000,
      endTime: 1698633801000,
      fields: {
        bodyTemperature: 39
      }
    };
    
    // 调用readData接口查询
    let samplePoints = await healthStore.readData(samplePointReadRequest);
    
    // 处理查询结果
    samplePoints.forEach((samplePoint) => {
      hilog.info(0x0000, 'testTag', 
        `Succeeded in reading data, the bodyTemperature is ${samplePoint.fields.bodyTemperature}.`);
    });
    
  } catch (err) {
    hilog.error(0x0000, 'testTag', 
      `Failed to read data. Code: ${err.code}, message: ${err.message}`);
  }
}
```

### 步骤3: 错误处理

```typescript
// 错误处理代码
try {
  let samplePoints = await healthStore.readData(samplePointReadRequest);
  // 处理结果
} catch (err) {
  switch (err.code) {
    case 201:
      hilog.error(0x0000, 'testTag', 'Permission verification failed.');
      // 引导用户检查权限配置
      break;
    case 401:
      hilog.error(0x0000, 'testTag', 'Parameter error.');
      // 检查参数是否正确
      break;
    case 1002701001:
      hilog.error(0x0000, 'testTag', 'Network error.');
      // 检查网络连接
      break;
    case 1002702001:
      hilog.error(0x0000, 'testTag', 'Account not logged in.');
      // 引导用户登录华为账号
      break;
    case 1002703001:
      hilog.error(0x0000, 'testTag', 'User privacy is not agreed.');
      // 引导用户启动运动健康App并同意隐私协议
      break;
    default:
      hilog.error(0x0000, 'testTag', `Unknown error: ${err.message}`);
  }
}
```

### 步骤4: 降级处理

```typescript
// 降级处理代码
async function readHealthDataWithFallback(): Promise<void> {
  try {
    // 尝试读取健康数据
    let samplePoints = await healthStore.readData(samplePointReadRequest);
    
    if (samplePoints.length === 0) {
      hilog.warn(0x0000, 'testTag', 'No health data available.');
      // 提示用户暂无数据
      return;
    }
    
    // 正常处理结果
    samplePoints.forEach((samplePoint) => {
      hilog.info(0x0000, 'testTag', `Data retrieved successfully.`);
    });
    
  } catch (err) {
    if (err.code === 1002702001) {
      // 账号未登录,引导用户登录
      hilog.warn(0x0000, 'testTag', 'Please login with Huawei ID first.');
    } else if (err.code === 1002703001) {
      // 用户隐私未同意,引导用户启动运动健康App
      hilog.warn(0x0000, 'testTag', 'Please start Health App and agree privacy policy.');
    } else {
      // 其他错误,提供友好提示
      hilog.error(0x0000, 'testTag', 'Service temporarily unavailable, please try again later.');
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 鉴权失败 | 1.检查AGC上应用的指纹证书配置<br>2.确认用户已授权相关权限<br>3.检查是否为白名单用户<br>4.通过在线提单提交问题 |
| 401 | 参数不合法 | 1.确认数据必填项是否填写<br>2.确认参数取值范围是否正确<br>3.通过在线提单提交问题 |
| 801 | 设备不支持此API | 避免在该设备上使用此API,或在代码中判断规避异常 |
| 1002700001 | 系统内部错误 | 根据具体message提示解决,若无法解决则在线提单 |
| 1002700002 | 数据库异常 | 通过在线提单提交问题 |
| 1002701001 | 网络错误 | 1.检查网络配置<br>2.通过在线提单提交问题 |
| 1002702001 | 账号未登录 | 1.拉起登录授权,登录账号后重新调用<br>2.通过在线提单提交问题 |
| 1002702002 | 账号异常 | 通过在线提单提交问题 |
| 1002703001 | 用户隐私未同意 | 引导用户启动运动健康App并同意隐私协议 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.HealthServiceKit": "^5.0.0",
    "@kit.PerformanceAnalysisKit": "^5.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK: 最低版本5.0.0(12)
- Wearable设备支持: 从API 19 Release开始
- DevEco Studio: 推荐使用最新版本
- Node.js: 推荐使用LTS版本

### 常见编译问题

**问题1: 模块导入失败**
```
Error: Cannot find module '@kit.HealthServiceKit'
```
**解决方法**: 确保已安装HarmonyOS SDK 5.0.0及以上版本,并在oh-package.json5中正确配置依赖。

**问题2: 类型定义错误**
```
Error: Property 'samplePointHelper' does not exist on type 'healthStore'
```
**解决方法**: 检查导入语句是否正确,确保使用`import { healthStore } from '@kit.HealthServiceKit'`。

**问题3: 初始化未完成**
```
Error: Health service not initialized
```
**解决方法**: 在调用readData前,必须先调用`healthStore.init(context)`完成初始化。

## 常见问题与解决方法

### Q1: 查询结果为空数组
**原因**: 
- 手表侧暂无对应类型的健康数据
- 用户未授权对应数据类型权限
- 时间范围设置不正确

**解决方法**:
- 确认用户已授权对应数据类型读取权限
- 确认手表已生成对应类型的健康数据
- Wearable设备上时间参数不生效,仅返回最新一条数据

### Q2: 接口调用失败返回201错误码
**原因**: 
- 应用指纹证书配置不正确
- 缺少权限
- 非白名单用户调用

**解决方法**:
- 检查AGC上应用的指纹证书配置
- 确认用户已授权相关权限
- 完成管理台应用验收获取正式权限

### Q3: 用户隐私未同意错误(1002703001)
**原因**: 用户从未启动过运动健康App

**解决方法**: 引导用户启动运动健康App并同意隐私协议

### Q4: 时间参数不生效
**原因**: Wearable设备上readData接口的时间参数暂不生效

**解决方法**: 接口仅支持返回手表侧最新一条数据,如需读取实时日常活动数据,使用专门的读取实时三环数据接口

### Q5: 支持哪些健康数据类型?
**解决方法**: 参考samplePointHelper模块定义的数据类型常量,包括:
- bodyTemperature(体温)
- bloodPressure(血压)
- bloodOxygenSaturation(血氧)
- dailyActivities(日常活动)
- emotion(情绪)
- 等其他健康数据类型

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "dataCount": 1,
  "dataType": "bodyTemperature",
  "fields": {
    "bodyTemperature": 39
  },
  "timestamp": 1698633801000,
  "apiUsed": [
    "healthStore.readData"
  ]
}
```

## 参考文档

- [API开发指南](references/health-wearable-samplepoint-manage.md)
- [API参考说明](references/health-api-healthstore.md)
- [错误码说明](references/errorcode-healthservice.md)
- [数据类型常量](references/health-api-samplepointhelper.md)

## 完整示例代码

- [ArkTS示例代码](assets/example_read_samplepoint.ets)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [查询体温数据](tests/test_positive.py): 正常场景,查询已授权的体温数据
- [查询血压数据](tests/test_positive.py): 正常场景,查询已授权的血压数据

### 边界测试用例
- [空数据场景](tests/test_boundary.py): 手表侧无对应类型健康数据
- [多数据类型查询](tests/test_boundary.py): 使用数组参数查询多种数据类型

### 异常测试用例
- [未授权场景](tests/test_exception.py): 用户未授权对应数据类型权限
- [未初始化场景](tests/test_exception.py): 未调用init方法初始化服务
- [参数错误场景](tests/test_exception.py): 传入错误的参数类型或值
- [网络异常场景](tests/test_exception.py): 网络不可用时的处理