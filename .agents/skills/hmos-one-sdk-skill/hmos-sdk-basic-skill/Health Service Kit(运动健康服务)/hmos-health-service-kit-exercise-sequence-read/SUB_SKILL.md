---
name: hmos-health-service-kit-exercise-sequence-read
description: 读取手表侧最新一条锻炼记录+支持跑步骑行等多种运动类型+需要用户授权和初始化+适用于运动健康数据查询场景
---

# 读取锻炼记录技能

## 功能描述

本技能用于从HarmonyOS Wearable设备读取最新的锻炼记录数据。支持读取跑步、骑行、篮球等多种运动类型的锻炼记录,包括运动时长、心率、距离、海拔等统计数据和详情数据。需要先进行服务初始化和用户授权,仅返回手表侧最新一条数据。

**核心能力**:
- 查询最新一条锻炼记录
- 支持多种运动类型(跑步、骑行、篮球等)
- 获取统计数据(时长、心率、距离等)
- 获取详情数据(心率曲线、海拔变化等)

**API版本**: 从5.1.1(19) Release版本开始支持Wearable设备

**限制条件**:
- 时间参数在Wearable设备上暂不生效,仅返回最新一条数据
- 需先完成服务初始化(init方法)
- 需获得用户授权对应数据类型权限
- 仅支持Wearable设备(手表)

## 使用场景

### 触发词
- "读取锻炼记录"
- "查询运动记录"
- "获取跑步数据"
- "读取骑行记录"
- "查看运动健康数据"

### 能做
- 读取手表侧最新一条锻炼记录
- 查询特定运动类型的锻炼记录(跑步、骑行、篮球等)
- 获取锻炼记录的统计数据(时长、距离、心率等)
- 获取锻炼记录的详情数据(心率曲线、海拔变化等)
- 处理多种运动类型的查询请求

### 绝不做
- 不读取多条锻炼记录(仅返回最新一条)
- 不保存或修改锻炼记录数据
- 不查询历史时间段内的锻炼记录(时间参数不生效)
- 不在未授权状态下读取数据
- 不在未初始化状态下调用接口

### 补充
- Wearable设备上时间参数(startTime/endTime)暂不生效,仅返回最新一条数据
- 需要在调用前完成HealthServiceKit初始化
- 需要通过用户授权接口获取对应数据类型权限
- 错误码处理请参考ArkTS API错误码文档

## 调用规范和规则

### 输入约束
- 运动类型(exerciseType): 必须为有效的SubDataType类型,参考exerciseSequenceHelper定义
- 查询条数(count): 取值范围[1, ∞),推荐设置为1
- 排序顺序(sortOrder): 0(升序)或1(降序)
- 详情数据选项(readOptions): 可选,指定需要查询的详情数据类型

### 执行约束
- 最大耗时: 5秒(含初始化和授权)
- 最大迭代次数: 1次(单次查询)
- API调用顺序: init → 用户授权 → readData
- 必须在Wearable设备上运行

### 内容约束
- 禁止生成: 多条锻炼记录查询代码
- 禁止使用高危函数: eval、exec等
- 禁止操作: 修改、删除锻炼记录
- 必须包含: 错误处理、异常捕获、降级方案

### 降级约束
- 网络失败: 提示用户检查网络连接,稍后重试
- 权限不足: 引导用户进行授权,参考用户授权文档
- 未初始化: 先调用init方法进行初始化
- 无数据: 提示用户暂无锻炼记录,建议先进行运动
- 设备不支持: 提示设备不支持该功能

## 调用流程和步骤

### 步骤1:准备阶段

**前置校验**:
1. 检查设备类型是否为Wearable设备
2. 检查API版本是否>=5.1.1(19)
3. 检查是否已完成HealthServiceKit初始化
4. 检查是否已获得用户授权

**参数准备**:
```typescript
import { healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 查询跑步记录请求参数
const sequenceReadRequest: healthStore.ExerciseSequenceReadRequest<healthStore.exerciseSequenceHelper.running.DetailFields> = {
  startTime: 1698040800000,  // Unix时间戳(毫秒),Wearable设备上暂不生效
  endTime: 1698042600000,    // Unix时间戳(毫秒),Wearable设备上暂不生效
  exerciseType: healthStore.exerciseSequenceHelper.running.EXERCISE_TYPE,  // 运动类型
  count: 1,                  // 查询条数
  sortOrder: 1,              // 排序顺序(降序)
  readOptions: {
    withPartialDetails: ['exerciseHeartRate', 'altitude']  // 部分详情数据
  }
};
```

### 步骤2:调用API

**完整示例代码**:
```typescript
import { healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 读取锻炼记录函数
async function readExerciseSequence(): Promise<void> {
  try {
    // 步骤1: 检查是否已初始化(首次调用需要)
    // 注意: 请在组件内获取context,确保this.getUIContext().getHostContext()返回结果为UIAbilityContext
    await healthStore.init(this.getUIContext().getHostContext());
    hilog.info(0x0000, 'testTag', 'Succeeded in initing.');
    
    // 步骤2: 创建查询请求
    const sequenceReadRequest: healthStore.ExerciseSequenceReadRequest<healthStore.exerciseSequenceHelper.running.DetailFields> = {
      startTime: 1698040800000,
      endTime: 1698042600000,
      exerciseType: healthStore.exerciseSequenceHelper.running.EXERCISE_TYPE,
      count: 1,
      sortOrder: 1,
      readOptions: {
        withPartialDetails: ['exerciseHeartRate', 'altitude']
      }
    };
    
    // 步骤3: 执行查询请求
    const runningSequences = await healthStore.readData<healthStore.exerciseSequenceHelper.running.Model>(sequenceReadRequest);
    hilog.info(0x0000, 'testTag', 'Succeeded in reading data.');
    
    // 步骤4: 处理返回结果
    runningSequences.forEach((runningSequence) => {
      hilog.info(0x0000, 'testTag', `the start time is ${runningSequence.startTime}.`);
      hilog.info(0x0000, 'testTag', `the end time is ${runningSequence.endTime}.`);
      hilog.info(0x0000, 'testTag', `the duration is ${runningSequence.duration}.`);
      
      // 处理统计数据
      Object.keys(runningSequence.summaries).forEach((key) => {
        Object.keys(runningSequence.summaries[key]).forEach((fieldName) => {
          hilog.info(0x0000, 'testTag', 
            `the summaries of ${key} field ${fieldName} is ${runningSequence.summaries[key][fieldName]}.`);
        });
      });
      
      // 处理详情数据
      if (runningSequence.details) {
        Object.keys(runningSequence.details).forEach((detailKey) => {
          hilog.info(0x0000, 'testTag', `detail key: ${detailKey}, points count: ${runningSequence.details[detailKey].length}`);
        });
      }
    });
    
  } catch (err) {
    // 错误处理
    hilog.error(0x0000, 'testTag', `Failed to read data. Code: ${err.code}, message: ${err.message}`);
    
    // 根据错误码进行降级处理
    switch (err.code) {
      case 201:
        hilog.error(0x0000, 'testTag', 'Permission verification failed. Please check user authorization.');
        break;
      case 401:
        hilog.error(0x0000, 'testTag', 'Parameter error. Please check request parameters.');
        break;
      case 1002700001:
        hilog.error(0x0000, 'testTag', 'System internal error. Please try again later.');
        break;
      case 1002701001:
        hilog.error(0x0000, 'testTag', 'Network error. Please check network connection.');
        break;
      case 1002702001:
        hilog.error(0x0000, 'testTag', 'Account not logged in. Please login with HUAWEI ID.');
        break;
      case 1002703001:
        hilog.error(0x0000, 'testTag', 'User privacy not agreed. Please start Health app first.');
        break;
      default:
        hilog.error(0x0000, 'testTag', `Unknown error: ${err.message}`);
    }
  }
}

// 调用函数
readExerciseSequence();
```

### 步骤3:错误处理

**错误码处理示例**:
```typescript
try {
  await healthStore.readData<healthStore.exerciseSequenceHelper.running.Model>(sequenceReadRequest);
} catch (error) {
  switch (error.code) {
    case 201:  // 权限验证失败
      console.error('Permission verification failed. Please request user authorization.');
      // 降级方案: 引导用户进行授权
      break;
    case 401:  // 参数错误
      console.error('Parameter error. Please check request parameters.');
      // 降级方案: 检查并修正参数
      break;
    case 1002700001:  // 系统内部错误
      console.error('System internal error. Please try again later.');
      // 降级方案: 提示用户稍后重试
      break;
    case 1002701001:  // 网络错误
      console.error('Network error. Please check network connection.');
      // 降级方案: 提示用户检查网络
      break;
    case 1002702001:  // 账号未登录
      console.error('Account not logged in. Please login with HUAWEI ID.');
      // 降级方案: 引导用户登录华为账号
      break;
    case 1002703001:  // 用户隐私未同意
      console.error('User privacy not agreed. Please start Health app first.');
      // 降级方案: 引导用户启动运动健康App
      break;
    default:
      console.error(`Unknown error: ${error.message}`);
      // 降级方案: 提示用户联系客服
  }
}
```

### 步骤4:降级处理

**降级方案示例**:
```typescript
// 检查是否已初始化
async function checkInitialization(): Promise<boolean> {
  try {
    // 假设已初始化,直接返回true
    return true;
  } catch (error) {
    hilog.warn(0x0000, 'testTag', 'Not initialized, initializing now...');
    try {
      await healthStore.init(this.getUIContext().getHostContext());
      return true;
    } catch (initError) {
      hilog.error(0x0000, 'testTag', `Failed to init: ${initError.message}`);
      return false;
    }
  }
}

// 检查是否有数据
async function safeReadExerciseSequence(): Promise<void> {
  const isInitialized = await checkInitialization();
  if (!isInitialized) {
    hilog.warn(0x0000, 'testTag', 'Service not initialized. Please initialize first.');
    return;
  }
  
  try {
    const sequences = await healthStore.readData<healthStore.exerciseSequenceHelper.running.Model>(sequenceReadRequest);
    
    if (sequences.length === 0) {
      hilog.info(0x0000, 'testTag', 'No exercise records found. Please start a workout first.');
      return;
    }
    
    // 处理数据...
  } catch (error) {
    // 错误处理...
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限验证失败 | 1.检查应用指纹证书配置<br>2.确认用户已授权相关权限<br>3.参考用户授权文档重新申请权限 |
| 401 | 参数错误 | 1.检查必填参数是否填写<br>2.检查参数类型是否正确<br>3.检查参数取值范围是否合法 |
| 801 | 设备不支持此API | 1.检查设备是否为Wearable设备<br>2.检查API版本是否>=5.1.1(19)<br>3.避免在不支持的设备上使用此API |
| 1002700001 | 系统内部错误 | 1.稍后重试<br>2.查看具体message提示<br>3.通过在线提单提交问题 |
| 1002700002 | 数据库异常 | 1.通过在线提单提交问题<br>2.华为支持人员会及时处理 |
| 1002701001 | 网络错误 | 1.检查网络配置<br>2.确认网络已连接<br>3.稍后重试 |
| 1002702001 | 账号未登录 | 1.引导用户登录华为账号<br>2.参考用户授权文档拉起登录授权<br>3.登录后重新调用接口 |
| 1002702002 | 账号异常 | 1.通过在线提单提交问题<br>2.华为支持人员会及时处理 |
| 1002703001 | 用户隐私未同意 | 1.引导用户启动运动健康App<br>2.参考FAQ文档<br>3.用户同意隐私后再调用接口 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.HealthServiceKit": "5.1.1(19)或更高版本",
    "@kit.PerformanceAnalysisKit": "用于日志输出"
  }
}
```

### 环境要求
- HarmonyOS API版本: >=5.1.1(19) Release
- 设备类型: Wearable设备(手表)
- 开发环境: DevEco Studio 5.1.1或更高版本
- 运行环境: HarmonyOS Wearable设备

### 常见编译问题

**问题1:导入模块失败**
```
Error: Cannot find module '@kit.HealthServiceKit'
```
**解决方法**: 
- 检查DevEco Studio版本是否>=5.1.1
- 确认项目SDK版本配置正确
- 在module.json5中添加必要权限配置

**问题2:类型定义错误**
```
Error: Property 'exerciseSequenceHelper' does not exist on type 'healthStore'
```
**解决方法**:
- 检查API版本是否>=5.1.1(19)
- 确认导入路径正确: `import { healthStore } from '@kit.HealthServiceKit'`
- 参考API文档确认类型定义

**问题3:权限配置错误**
```
Error: Permission verification failed (201)
```
**解决方法**:
- 在module.json5中添加ohos.permission.HEALTH_DATA权限
- 参考[申请运动健康服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-apply)文档
- 确认应用已在AGC平台配置健康数据权限

## 常见问题与解决方法

### Q1:为什么只返回一条数据?
**原因**: Wearable设备上时间参数(startTime/endTime)暂不生效,接口仅支持返回最新一条锻炼记录。
**解决方法**:
- 这是正常行为,符合API设计
- 如需多条数据,建议在Phone/Tablet设备上调用相应接口
- 可以定期查询获取最新数据

### Q2:如何查询不同运动类型?
**原因**: 不同运动类型有不同的数据模型和字段。
**解决方法**:
- 参考[锻炼记录类型常量](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/health-api-exercisedequencehelper)文档
- 使用对应的exerciseSequenceHelper子模块
- 示例:
  - 跑步: `healthStore.exerciseSequenceHelper.running.EXERCISE_TYPE`
  - 骑行: `healthStore.exerciseSequenceHelper.cycling.EXERCISE_TYPE`
  - 篮球: `healthStore.exerciseSequenceHelper.basketball.EXERCISE_TYPE`

### Q3:如何获取详情数据?
**原因**: 默认不查询详情数据,需要通过readOptions指定。
**解决方法**:
- 设置readOptions.withDetails = true读取全部详情
- 或设置readOptions.withPartialDetails指定部分详情类型
- 详情数据类型参考exerciseSequenceHelper对应运动类型的DetailFields

### Q4:初始化失败怎么办?
**原因**: 可能context参数不正确或服务未就绪。
**解决方法**:
- 确认使用正确的context(UIAbilityContext)
- 在组件内获取context: `this.getUIContext().getHostContext()`
- 检查设备是否支持HealthServiceKit
- 参考[init方法](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/health-api-healthstore)文档

### Q5:如何处理无数据情况?
**原因**: 用户可能尚未进行过运动,数据库中无锻炼记录。
**解决方法**:
- 检查返回数组长度: `sequences.length === 0`
- 提示用户暂无锻炼记录
- 建议用户先进行运动并同步数据
- 提供友好的空数据UI展示

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "exerciseRecordsCount": 1,
  "exerciseType": "running",
  "startTime": 1698040800000,
  "endTime": 1698042600000,
  "duration": 1800000,
  "hasSummaryData": true,
  "hasDetailData": true,
  "apiUsed": [
    "healthStore.init",
    "healthStore.readData"
  ],
  "dataTypes": [
    "ExerciseSequence",
    "ExerciseSequenceReadRequest"
  ]
}
```

## 参考文档

- [API开发指南 - 读取锻炼记录](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-wearable-exercisesequence-manage)
- [API参考说明 - healthStore](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/health-api-healthstore)
- [锻炼记录类型常量 - exerciseSequenceHelper](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/health-api-exercisedequencehelper)
- [ArkTS API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-healthservice)
- [申请运动健康服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-apply)
- [配置Client ID](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-configuration-client-id)
- [用户授权](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-add-permissions)
- [Health Service Kit常见问题](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-faqs)

## 完整示例代码

- [ArkTS示例代码 - 读取跑步记录](assets/read_running_exercise.ets)
- [ArkTS示例代码 - 读取骑行记录](assets/read_cycling_exercise.ets)
- [ArkTS示例代码 - 读取篮球记录](assets/read_basketball_exercise.ets)
- [配置文件示例 - module.json5权限配置](assets/module.json5)

## 测试用例

### 正向测试用例
- [读取最新跑步记录](tests/test_read_running_positive.ets): 成功读取跑步锻炼记录
- [读取最新骑行记录](tests/test_read_cycling_positive.ets): 成功读取骑行锻炼记录
- [读取带详情数据的记录](tests/test_read_with_details_positive.ets): 成功读取包含详情数据的锻炼记录

### 边界测试用例
- [无锻炼记录情况](tests/test_no_records_boundary.ets): 数据库中无锻炼记录时的处理
- [未初始化调用](tests/test_without_init_boundary.ets): 未调用init方法时的处理
- [空运动类型参数](tests/test_empty_exercise_type_boundary.ets): 运动类型为空时的处理

### 异常测试用例
- [权限不足异常](tests/test_permission_denied_exception.ets): 用户未授权时的错误处理
- [网络异常](tests/test_network_error_exception.ets): 网络不可用时的降级处理
- [账号未登录异常](tests/test_account_not_logged_in_exception.ets): 华为账号未登录时的处理
- [参数错误异常](tests/test_parameter_error_exception.ets): 参数不合法时的错误处理