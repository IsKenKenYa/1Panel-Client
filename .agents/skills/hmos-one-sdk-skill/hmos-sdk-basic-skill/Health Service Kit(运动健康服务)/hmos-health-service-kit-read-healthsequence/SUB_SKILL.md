---
name: hmos-health-service-kit-read-healthsequence
description: 读取Wearable设备最新一条健康记录数据,支持夜间睡眠、零星小睡等健康数据类型查询,需申请运动健康服务并获取用户授权,从API 5.1.1(19)版本开始支持,适用于健康管理、睡眠监测等场景
---

# 读取健康记录技能

## 功能描述

本技能提供读取Wearable设备(手表/手环)最新一条健康记录数据的能力。通过调用Health Service Kit的readData接口,可以查询夜间睡眠记录、零星小睡等健康数据类型。查询结果包含健康记录的统计数据和详情数据。

**核心特性**:
- 支持读取最新一条健康记录(当前版本时间参数暂不生效)
- 支持多种健康数据类型(夜间睡眠、零星小睡等)
- 支持查询统计数据和详情数据
- 需申请运动健康服务并获取用户读权限授权
- 从API 5.1.1(19) Release版本开始支持Wearable设备开发

**适用数据类型**:
- 夜间睡眠记录 (sleepRecord)
- 零星小睡记录 (sleepNapRecord)
- 其他健康记录类型(通过healthSequenceHelper查询)

## 使用场景

### 触发词
- "读取健康记录"
- "查询睡眠数据"
- "获取睡眠记录"
- "读取夜间睡眠"
- "查询零星小睡"
- "获取Wearable健康数据"

### 能做
- 读取Wearable设备最新一条健康记录
- 查询夜间睡眠统计数据(入睡时间、醒来时间、睡眠评分等)
- 查询零星小睡统计数据
- 获取健康记录详情数据(睡眠片段、睡眠状态等)
- 支持指定健康数据类型进行查询
- 支持读取全部详情或部分详情数据

### 绝不做
- 不能读取多条健康记录(当前版本仅支持最新一条)
- 不能写入或修改健康记录数据(仅支持读取)
- 不能读取未经用户授权的健康数据类型
- 不能读取非健康记录类型的数据(如锻炼记录、采样点数据)
- 不能在未申请运动健康服务的情况下调用接口
- 不能在未初始化healthStore的情况下调用接口

### 补充
- 当前HealthSequenceReadRequest的时间参数(startTime/endTime)暂不生效,仅支持返回手表侧最新一条数据
- 查询时间跨度限制为31天(虽然当前版本时间参数不生效)
- 需在组件内调用接口,确保获取正确的UIAbilityContext
- 需先调用init()方法进行初始化,仅首次调用需要
- 用户授权后才能读取对应数据类型的健康记录

## 调用规范和规则

### 输入约束
- 健康数据类型: 必须是有效的HealthSequenceDataType (如sleepRecord.DATA_TYPE)
- 时间参数: startTime和endTime为Unix时间戳毫秒,取值范围(0, ∞),当前版本暂不生效
- 详情选项: withDetails为boolean类型,withPartialDetails为数组类型,两者不能同时设置
- 查询时间跨度: 最大31天 (当前版本暂不生效)
- 授权参数: 必须在申请运动健康服务时勾选对应数据类型的读权限

### 执行约束
- 最大耗时: 异步Promise调用,建议设置超时时间10秒
- API调用频次: 无明确限制,建议合理控制调用频次
- 初始化要求: 首次调用前必须先调用init()方法
- 授权要求: 调用前必须先通过requestAuthorizations()获取用户读权限授权
- 上下文要求: 必须在UIAbility或UIExtensionAbility的上下文环境中调用

### 内容约束
- 禁止生成: 禁止生成写入健康记录的代码(使用saveData接口)
- 禁止使用高危函数: 禁止使用eval、exec等高危函数
- 禁止操作: 禁止未经授权读取健康数据、禁止删除健康数据
- 错误处理: 必须使用try-catch捕获异常,处理错误码
- 日志规范: 使用hilog记录关键操作日志,避免记录敏感数据

### 降级约束
- 网络失败: 提示用户检查网络连接,稍后重试
- 权限不足: 引导用户进行授权操作,调用requestAuthorizations()
- 账号未登录: 提示用户登录华为账号后重试
- 用户隐私未同意: 引导用户启动运动健康App并同意隐私协议
- 初始化失败: 检查context参数是否正确,重新初始化
- 数据类型不支持: 提示用户该健康数据类型暂不支持查询

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 检查是否已完成申请运动健康服务流程
2. 检查是否已配置Client ID
3. 检查是否已调用init()方法进行初始化(仅首次需要)
4. 检查是否已获取用户读权限授权

**参数准备**:
```typescript
import { healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';

let context: common.UIAbilityContext;
let healthSequenceDataType: healthStore.DataType;
let startTime: number;
let endTime: number;
let readOptions: healthStore.SequenceReadOptions;
```

**初始化示例**:
```typescript
try {
  await healthStore.init(this.getUIContext().getHostContext());
  hilog.info(0x0000, 'testTag', 'Succeeded in initing healthStore.');
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to init. Code: ${err.code}, message: ${err.message}`);
  throw err;
}
```

### 步骤2: 用户授权

**授权请求创建**:
```typescript
let authorizationRequest: healthStore.AuthorizationRequest = {
  readDataTypes: [healthStore.healthSequenceHelper.sleepRecord.DATA_TYPE],
  writeDataTypes: []
};
```

**授权调用**:
```typescript
try {
  let authorizationResponse = await healthStore.requestAuthorizations(
    this.getUIContext().getHostContext() as common.UIAbilityContext,
    authorizationRequest
  );
  
  authorizationResponse.readDataTypes.forEach(dataType => {
    hilog.info(0x0000, 'testTag', `Granted read data type: ${dataType.name}`);
  });
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to request authorization. Code: ${err.code}, message: ${err.message}`);
  throw err;
}
```

### 步骤3: 创建查询请求

**创建HealthSequenceReadRequest**:
```typescript
let healthSequenceReadRequest: healthStore.HealthSequenceReadRequest = {
  healthSequenceDataType: healthStore.healthSequenceHelper.sleepRecord.DATA_TYPE,
  startTime: 1695740400000,
  endTime: 1695769200000,
  readOptions: {
    withDetails: true
  }
};
```

**参数说明**:
- `healthSequenceDataType`: 健康数据类型,使用healthSequenceHelper获取 (必填)
  - 夜间睡眠: `healthStore.healthSequenceHelper.sleepRecord.DATA_TYPE`
  - 零星小睡: `healthStore.healthSequenceHelper.sleepNapRecord.DATA_TYPE`
- `startTime`: 查询开始时间,Unix时间戳毫秒 (必填,当前版本暂不生效)
- `endTime`: 查询结束时间,Unix时间戳毫秒 (必填,当前版本暂不生效)
- `readOptions`: 详情数据选项 (可选)
  - `withDetails`: true表示读取全部详情, false表示不读取详情
  - `withPartialDetails`: 数组类型,指定读取部分详情数据类型

### 步骤4: 调用readData接口

**执行查询**:
```typescript
try {
  const healthSequences = await healthStore.readData(healthSequenceReadRequest);
  hilog.info(0x0000, 'testTag', 'Succeeded in reading health sequence data.');
  
  healthSequences.forEach((healthSequence) => {
    hilog.info(0x0000, 'testTag', `Health sequence start time: ${healthSequence.startTime}`);
    hilog.info(0x0000, 'testTag', `Health sequence end time: ${healthSequence.endTime}`);
    
    Object.keys(healthSequence.summaries).forEach((key) => {
      hilog.info(0x0000, 'testTag', `Summary ${key}: ${healthSequence.summaries[key]}`);
    });
    
    if (healthSequence.details) {
      Object.keys(healthSequence.details).forEach((detailKey) => {
        hilog.info(0x0000, 'testTag', `Detail ${detailKey} count: ${healthSequence.details[detailKey].length}`);
      });
    }
  });
  
  return healthSequences;
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to read data. Code: ${err.code}, message: ${err.message}`);
  throw err;
}
```

### 步骤5: 错误处理

**错误码处理**:
```typescript
try {
  const healthSequences = await healthStore.readData(healthSequenceReadRequest);
} catch (error) {
  switch (error.code) {
    case 201:
      hilog.error(0x0000, 'testTag', 'Permission verification failed. Please check if user has granted read permission.');
      break;
    case 401:
      hilog.error(0x0000, 'testTag', 'Parameter error. Please check if mandatory parameters are correct.');
      break;
    case 1002700001:
      hilog.error(0x0000, 'testTag', 'System internal error. Please try again later.');
      break;
    case 1002700002:
      hilog.error(0x0000, 'testTag', 'Database processing error. Please try again later.');
      break;
    case 1002701001:
      hilog.error(0x0000, 'testTag', 'Network error. Please check network connection.');
      break;
    case 1002702001:
      hilog.error(0x0000, 'testTag', 'Account error. User has not logged in with HUAWEI ID.');
      break;
    case 1002702002:
      hilog.error(0x0000, 'testTag', 'Account error. Failed to obtain account information.');
      break;
    case 1002703001:
      hilog.error(0x0000, 'testTag', 'User privacy is not agreed. Please start Health app and agree privacy.');
      break;
    default:
      hilog.error(0x0000, 'testTag', `Unknown error: ${error.message}`);
  }
  
  throw error;
}
```

### 步骤6: 降级处理

**网络失败降级**:
```typescript
async function readHealthSequenceWithFallback(request: healthStore.HealthSequenceReadRequest): Promise<healthStore.HealthSequence[] | null> {
  try {
    const healthSequences = await healthStore.readData(request);
    return healthSequences;
  } catch (error) {
    if (error.code === 1002701001) {
      hilog.warn(0x0000, 'testTag', 'Network error occurred. Please check your network connection and try again.');
      return null;
    } else if (error.code === 201) {
      hilog.warn(0x0000, 'testTag', 'Permission denied. Please request user authorization first.');
      return null;
    } else {
      hilog.error(0x0000, 'testTag', `Failed to read health sequence: ${error.message}`);
      throw error;
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 鉴权失败,权限验证失败 | 1. 检查应用指纹证书配置<br>2. 确认用户已授权相关读权限<br>3. 通过requestAuthorizations()引导用户授权 |
| 401 | 参数错误,必填参数未指定或参数类型错误 | 1. 检查healthSequenceDataType是否正确<br>2. 检查startTime/endTime是否为有效时间戳<br>3. 参考文档确认参数取值范围 |
| 801 | 设备不支持此API | 避免在该设备上使用此API,或通过判断规避异常场景 |
| 1002700001 | 系统内部错误 | 根据具体message提示解决,无法解决时在线提单 |
| 1002700002 | 数据库处理错误 | 通过在线提单提交问题 |
| 1002701001 | 网络错误,网络不可用 | 1. 检查网络配置<br>2. 提示用户检查网络连接后重试 |
| 1002702001 | 账号错误,用户未登录华为账号 | 1. 引导用户登录华为账号<br>2. 通过requestAuthorizations()拉起登录授权 |
| 1002702002 | 账号错误,获取账号信息失败 | 通过在线提单提交问题 |
| 1002703001 | 用户隐私未同意 | 引导用户启动运动健康App并同意隐私协议 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.HealthServiceKit": ">=5.1.1(19)",
    "@kit.AbilityKit": ">=5.0.0(12)",
    "@kit.PerformanceAnalysisKit": ">=5.0.0(12)"
  }
}
```

### 环境要求
- HarmonyOS API版本: >= 5.1.1(19) Release
- 设备类型: Wearable设备(手表/手环)
- 开发环境: DevEco Studio >= 5.0
- 运行环境: HarmonyOS Wearable设备

### 常见编译问题

**问题1: 导入模块失败**
```
Error: Cannot find module '@kit.HealthServiceKit'
```
**解决方法**: 
- 确保HarmonyOS SDK版本 >= 5.1.1(19)
- 在DevEco Studio中配置正确的SDK路径
- 检查module.json5中是否正确声明依赖

**问题2: 类型定义错误**
```
Error: Property 'healthSequenceHelper' does not exist on type 'healthStore'
```
**解决方法**:
- 确保使用正确的导入方式: `import { healthStore } from '@kit.HealthServiceKit'`
- 检查API版本是否 >= 5.1.1(19)
- 通过healthStore.healthSequenceHelper方式访问

**问题3: context参数错误**
```
Error: Parameter error. context must be UIAbilityContext
```
**解决方法**:
- 在组件内使用`this.getUIContext().getHostContext()`获取context
- 确保返回结果为UIAbilityContext类型
- 使用`as common.UIAbilityContext`进行类型转换

**问题4: 初始化失败**
```
Error: Failed to init. Code: 401, message: Parameter error
```
**解决方法**:
- 检查context参数是否为UIAbilityContext
- 确保在UIAbility或UIExtensionAbility环境中调用
- 仅首次调用需要初始化,后续调用可跳过

**问题5: 权限验证失败**
```
Error: Permission verification failed. Code: 201
```
**解决方法**:
- 检查是否在AGC上申请了运动健康服务
- 确认是否勾选了对应健康数据类型的读权限
- 通过requestAuthorizations()引导用户授权

## 常见问题与解决方法

### Q1: 为什么时间参数不生效?
**原因**: 当前版本HealthSequenceReadRequest的时间参数(startTime/endTime)暂不生效,仅支持返回手表侧最新一条数据。
**解决方法**:
- 了解当前版本限制,仅能读取最新一条健康记录
- 时间参数仍需填写但不会影响查询结果
- 未来版本可能支持时间范围查询,届时可更新代码

### Q2: 如何获取睡眠记录的统计数据?
**原因**: 需要正确使用healthSequenceHelper获取睡眠数据类型常量。
**解决方法**:
- 夜间睡眠: `healthStore.healthSequenceHelper.sleepRecord.DATA_TYPE`
- 零星小睡: `healthStore.healthSequenceHelper.sleepNapRecord.DATA_TYPE`
- 查询结果中`summaries`字段包含统计数据
- 夜间睡眠包含: fallAsleepTime(入睡时间)、wakeupTime(醒来时间)、sleepScore(睡眠评分)等

### Q3: 如何获取睡眠详情数据?
**原因**: 需要在readOptions中设置withDetails或withPartialDetails参数。
**解决方法**:
- 设置`readOptions: { withDetails: true }`读取全部详情
- 或设置`readOptions: { withPartialDetails: ['sleepSegment'] }`读取部分详情
- 详情数据存储在`details`字段中
- 夜间睡眠详情包含sleepSegment(睡眠片段)数组

### Q4: 用户拒绝授权怎么办?
**原因**: 用户可能拒绝授权或取消授权。
**解决方法**:
- 通过requestAuthorizations()再次引导用户授权
- 说明授权用途和数据使用场景
- 提供取消授权功能: cancelAuthorizations()
- 用户拒绝后可提示功能受限

### Q5: 如何查询其他健康记录类型?
**原因**: 需要通过healthSequenceHelper查询支持的健康记录类型。
**解决方法**:
- 参考[健康记录类型常量](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/health-api-healthsequencehelper)
- 使用对应数据类型的DATA_TYPE常量
- 当前支持: sleepRecord(夜间睡眠)、sleepNapRecord(零星小睡)
- 其他健康记录类型需要查看API文档确认支持情况

### Q6: 如何处理账号未登录错误?
**原因**: 用户未登录华为账号或账号异常。
**解决方法**:
- 通过requestAuthorizations()拉起账号登录授权页面
- 提示用户登录华为账号
- 登录后重新调用查询接口
- 检查账号状态是否正常

### Q7: Wearable设备读取失败返回1002700001?
**原因**: 某些接口在Wearable设备上不支持或有限制。
**解决方法**:
- readData接口从API 5.1.1(19)开始支持Wearable设备开发
- 确保API版本 >= 5.1.1(19)
- 检查设备类型和系统版本
- 如果仍报错,参考错误码说明进行处理

### Q8: 如何判断是否已初始化?
**原因**: init()方法仅首次调用需要,重复调用可能报错。
**解决方法**:
- 使用全局变量记录初始化状态
- 首次调用init()后标记为已初始化
- 后续调用跳过初始化步骤
- 初始化失败时重新尝试初始化

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "healthSequences": [
    {
      "dataType": {
        "id": 100004,
        "name": "sleepRecord"
      },
      "startTime": 1695740400000,
      "endTime": 1695769200000,
      "summaries": {
        "fallAsleepTime": 1695740400000,
        "wakeupTime": 1695769200000,
        "sleepScore": 80,
        "wakeCount": 2,
        "sleepType": 1,
        "shallowDuration": 14400,
        "deepDuration": 7200,
        "dreamDuration": 7200,
        "wakeDuration": 0,
        "duration": 28800
      },
      "details": {
        "sleepSegment": [
          {
            "startTime": 1695740400000,
            "endTime": 1695747600000,
            "sleepStatus": 2
          },
          {
            "startTime": 1695747600000,
            "endTime": 1695754800000,
            "sleepStatus": 1
          }
        ]
      }
    }
  ],
  "count": 1,
  "apiUsed": [
    "healthStore.init",
    "healthStore.requestAuthorizations",
    "healthStore.readData"
  ]
}
```

**输出字段说明**:
- `status`: 执行状态,success表示成功
- `healthSequences`: 健康记录数组,包含查询到的健康数据
- `count`: 健康记录数量,当前版本仅返回最新一条(count=1)
- `apiUsed`: 本次调用使用的API列表

## 参考文档

- [读取健康记录开发指南](references/health-wearable-healthsequence-manage-guide.md)
- [健康记录类型常量](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/health-api-healthsequencehelper)
- [healthStore API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/health-api-healthstore)
- [申请运动健康服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-apply)
- [管理用户授权](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-add-permissions)
- [ArkTS API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-healthservice)

## 完整示例代码

- [ArkTS完整示例](assets/read_health_sequence.ets)
- [授权流程示例](assets/authorization_flow.ets)
- [错误处理示例](assets/error_handling.ets)

## 测试用例

### 正向测试用例
- [读取夜间睡眠记录](tests/test_read_sleep_record.py): 测试读取最新一条夜间睡眠数据
- [读取零星小睡记录](tests/test_read_sleep_nap.py): 测试读取最新一条零星小睡数据
- [读取带详情的睡眠记录](tests/test_read_with_details.py): 测试读取包含详情数据的睡眠记录

### 边界测试用例
- [时间参数边界值测试](tests/test_time_boundary.py): 测试startTime/endTime边界值
- [详情选项边界测试](tests/test_read_options_boundary.py): 测试withDetails和withPartialDetails边界值
- [数据类型边界测试](tests/test_data_type_boundary.py): 测试不同健康数据类型

### 异常测试用例
- [未授权读取测试](tests/test_unauthorized_read.py): 测试未授权时读取健康记录
- [未初始化调用测试](tests/test_without_init.py): 测试未初始化时调用接口
- [参数错误测试](tests/test_invalid_parameters.py): 测试各种参数错误场景
- [网络异常测试](tests/test_network_error.py): 测试网络异常时的降级处理
- [账号未登录测试](tests/test_account_not_login.py): 测试账号未登录时的处理