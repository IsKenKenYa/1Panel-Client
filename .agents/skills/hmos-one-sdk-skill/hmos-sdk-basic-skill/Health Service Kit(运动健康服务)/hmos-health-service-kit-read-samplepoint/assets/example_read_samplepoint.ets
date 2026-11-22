/**
 * 读取运动健康采样数据示例代码
 * 功能: 查询最新一条运动健康采样数据
 * 支持数据类型: 体温、血压、血氧、日常活动等
 */

import { healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';

const TAG = 'HealthSamplePointRead';
const DOMAIN = 0x0000;

/**
 * 初始化运动健康服务
 * 必须在其他接口调用前完成初始化
 */
async function initHealthService(context: common.Context): Promise<void> {
  try {
    await healthStore.init(context);
    hilog.info(DOMAIN, TAG, 'Health service initialized successfully.');
  } catch (err) {
    hilog.error(DOMAIN, TAG, `Failed to init health service. Code: ${err.code}, message: ${err.message}`);
    throw err;
  }
}

/**
 * 查询体温采样数据
 * 返回最新一条体温数据
 */
async function readBodyTemperature(): Promise<void> {
  try {
    // 创建体温数据查询请求
    let samplePointReadRequest: healthStore.SamplePointReadRequest = {
      samplePointDataType: healthStore.samplePointHelper.bodyTemperature.DATA_TYPE,
      startTime: Date.now() - 24 * 60 * 60 * 1000, // 最近24小时
      endTime: Date.now(),
      fields: {
        bodyTemperature: 0 // 查询体温字段
      }
    };

    // 调用readData接口查询
    let samplePoints = await healthStore.readData(samplePointReadRequest);

    // 处理查询结果
    if (samplePoints.length === 0) {
      hilog.info(DOMAIN, TAG, 'No body temperature data available.');
      return;
    }

    samplePoints.forEach((samplePoint) => {
      const temperature = samplePoint.fields.bodyTemperature;
      const startTime = samplePoint.startTime;
      hilog.info(DOMAIN, TAG, 
        `Body temperature: ${temperature}°C, timestamp: ${startTime}`);
    });

  } catch (err) {
    handleReadError(err);
  }
}

/**
 * 查询血压采样数据
 * 返回最新一条血压数据
 */
async function readBloodPressure(): Promise<void> {
  try {
    // 创建血压数据查询请求
    let samplePointReadRequest: healthStore.SamplePointReadRequest = {
      samplePointDataType: healthStore.samplePointHelper.bloodPressure.DATA_TYPE,
      startTime: Date.now() - 24 * 60 * 60 * 1000,
      endTime: Date.now(),
      fields: {
        systolic: 0,  // 收缩压
        diastolic: 0  // 舒张压
      }
    };

    // 调用readData接口查询
    let samplePoints = await healthStore.readData(samplePointReadRequest);

    if (samplePoints.length === 0) {
      hilog.info(DOMAIN, TAG, 'No blood pressure data available.');
      return;
    }

    samplePoints.forEach((samplePoint) => {
      const systolic = samplePoint.fields.systolic;
      const diastolic = samplePoint.fields.diastolic;
      hilog.info(DOMAIN, TAG, 
        `Blood pressure: ${systolic}/${diastolic} mmHg`);
    });

  } catch (err) {
    handleReadError(err);
  }
}

/**
 * 查询血氧采样数据
 * 返回最新一条血氧数据
 */
async function readBloodOxygen(): Promise<void> {
  try {
    // 创建血氧数据查询请求
    let samplePointReadRequest: healthStore.SamplePointReadRequest = {
      samplePointDataType: healthStore.samplePointHelper.bloodOxygenSaturation.DATA_TYPE,
      startTime: Date.now() - 24 * 60 * 60 * 1000,
      endTime: Date.now(),
      fields: {
        bloodOxygenSaturation: 0 // 血氧饱和度
      }
    };

    // 调用readData接口查询
    let samplePoints = await healthStore.readData(samplePointReadRequest);

    if (samplePoints.length === 0) {
      hilog.info(DOMAIN, TAG, 'No blood oxygen data available.');
      return;
    }

    samplePoints.forEach((samplePoint) => {
      const oxygen = samplePoint.fields.bloodOxygenSaturation;
      hilog.info(DOMAIN, TAG, 
        `Blood oxygen saturation: ${oxygen}%`);
    });

  } catch (err) {
    handleReadError(err);
  }
}

/**
 * 查询日常活动数据
 * 注意: 读取实时日常活动数据建议使用专门的读取实时三环数据接口
 */
async function readDailyActivities(): Promise<void> {
  try {
    // 创建日常活动数据查询请求
    let samplePointReadRequest: healthStore.SamplePointReadRequest = {
      samplePointDataType: healthStore.samplePointHelper.dailyActivities.DATA_TYPE,
      startTime: Date.now() - 24 * 60 * 60 * 1000,
      endTime: Date.now(),
      fields: {
        steps: 0,        // 步数
        distance: 0,     // 距离
        calories: 0      // 卡路里
      }
    };

    // 调用readData接口查询
    let samplePoints = await healthStore.readData(samplePointReadRequest);

    if (samplePoints.length === 0) {
      hilog.info(DOMAIN, TAG, 'No daily activities data available.');
      return;
    }

    samplePoints.forEach((samplePoint) => {
      const steps = samplePoint.fields.steps;
      const distance = samplePoint.fields.distance;
      const calories = samplePoint.fields.calories;
      hilog.info(DOMAIN, TAG, 
        `Steps: ${steps}, Distance: ${distance}m, Calories: ${calories}kcal`);
    });

  } catch (err) {
    handleReadError(err);
  }
}

/**
 * 错误处理函数
 * 根据错误码提供相应的处理建议
 */
function handleReadError(err: Error): void {
  const errorCode = (err as any).code;
  
  switch (errorCode) {
    case 201:
      hilog.error(DOMAIN, TAG, 'Permission verification failed. Please check:');
      hilog.error(DOMAIN, TAG, '1. App fingerprint certificate configuration');
      hilog.error(DOMAIN, TAG, '2. User authorization status');
      hilog.error(DOMAIN, TAG, '3. White list user status');
      break;
      
    case 401:
      hilog.error(DOMAIN, TAG, 'Parameter error. Please check:');
      hilog.error(DOMAIN, TAG, '1. Required parameters are filled');
      hilog.error(DOMAIN, TAG, '2. Parameter types are correct');
      hilog.error(DOMAIN, TAG, '3. Parameter value ranges are valid');
      break;
      
    case 801:
      hilog.error(DOMAIN, TAG, 'Device does not support this API.');
      hilog.error(DOMAIN, TAG, 'Please avoid using this API on current device.');
      break;
      
    case 1002700001:
      hilog.error(DOMAIN, TAG, 'System internal error.');
      hilog.error(DOMAIN, TAG, 'Please try again later or submit issue online.');
      break;
      
    case 1002700002:
      hilog.error(DOMAIN, TAG, 'Database processing error.');
      hilog.error(DOMAIN, TAG, 'Please submit issue online.');
      break;
      
    case 1002701001:
      hilog.error(DOMAIN, TAG, 'Network error. Please check:');
      hilog.error(DOMAIN, TAG, '1. Network connection status');
      hilog.error(DOMAIN, TAG, '2. Network configuration');
      break;
      
    case 1002702001:
      hilog.error(DOMAIN, TAG, 'Account not logged in.');
      hilog.error(DOMAIN, TAG, 'Please login with Huawei ID first.');
      break;
      
    case 1002702002:
      hilog.error(DOMAIN, TAG, 'Account error.');
      hilog.error(DOMAIN, TAG, 'Please submit issue online.');
      break;
      
    case 1002703001:
      hilog.error(DOMAIN, TAG, 'User privacy not agreed.');
      hilog.error(DOMAIN, TAG, 'Please start Health App and agree privacy policy.');
      break;
      
    default:
      hilog.error(DOMAIN, TAG, `Unknown error. Code: ${errorCode}, message: ${err.message}`);
  }
}

/**
 * 主函数 - 综合示例
 * 包含初始化、查询多种健康数据类型的完整流程
 */
@Entry
@Component
struct HealthSamplePointExample {
  private context: common.Context = getContext(this) as common.Context;
  
  build() {
    Column() {
      Button('Init Health Service')
        .onClick(async () => {
          await initHealthService(this.context);
        })
        .margin(10);
      
      Button('Read Body Temperature')
        .onClick(async () => {
          await readBodyTemperature();
        })
        .margin(10);
      
      Button('Read Blood Pressure')
        .onClick(async () => {
          await readBloodPressure();
        })
        .margin(10);
      
      Button('Read Blood Oxygen')
        .onClick(async () => {
          await readBloodOxygen();
        })
        .margin(10);
      
      Button('Read Daily Activities')
        .onClick(async () => {
          await readDailyActivities();
        })
        .margin(10);
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}

/**
 * 使用说明:
 * 1. 在UIAbility或UIExtensionAbility的上下文环境中调用initHealthService
 * 2. 确保已完成用户授权流程,获取对应数据类型的读取权限
 * 3. Wearable设备上时间参数不生效,仅返回最新一条数据
 * 4. 查询实时日常活动数据建议使用专门的读取实时三环数据接口
 * 
 * 参考文档:
 * - https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-wearable-samplepoint-manage
 * - https://developer.huawei.com/consumer/cn/doc/harmonyos-references/health-api-healthstore
 * - https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-healthservice
 */