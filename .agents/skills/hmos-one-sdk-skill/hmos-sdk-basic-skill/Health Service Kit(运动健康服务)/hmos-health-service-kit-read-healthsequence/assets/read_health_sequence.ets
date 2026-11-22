import { healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';

const TAG = 'HealthSequenceRead';
const DOMAIN = 0x0000;

export class HealthSequenceReader {
  private context: common.UIAbilityContext;
  private isInitialized: boolean = false;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  async initialize(): Promise<void> {
    if (this.isInitialized) {
      hilog.info(DOMAIN, TAG, 'healthStore already initialized');
      return;
    }

    try {
      await healthStore.init(this.context);
      this.isInitialized = true;
      hilog.info(DOMAIN, TAG, 'Succeeded in initializing healthStore');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to init. Code: ${error.code}, message: ${error.message}`);
      throw error;
    }
  }

  async requestReadPermission(dataTypes: healthStore.DataType[]): Promise<healthStore.AuthorizationResponse> {
    try {
      const authorizationRequest: healthStore.AuthorizationRequest = {
        readDataTypes: dataTypes,
        writeDataTypes: []
      };

      const authorizationResponse = await healthStore.requestAuthorizations(
        this.context,
        authorizationRequest
      );

      authorizationResponse.readDataTypes.forEach(dataType => {
        hilog.info(DOMAIN, TAG, `Granted read data type: ${dataType.name}`);
      });

      return authorizationResponse;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to request authorization. Code: ${error.code}, message: ${error.message}`);
      throw error;
    }
  }

  async readSleepRecord(withDetails: boolean = true): Promise<healthStore.HealthSequence[]> {
    try {
      await this.initialize();

      const healthSequenceReadRequest: healthStore.HealthSequenceReadRequest = {
        healthSequenceDataType: healthStore.healthSequenceHelper.sleepRecord.DATA_TYPE,
        startTime: Date.now() - 86400000,
        endTime: Date.now(),
        readOptions: {
          withDetails: withDetails
        }
      };

      const healthSequences = await healthStore.readData(healthSequenceReadRequest);
      hilog.info(DOMAIN, TAG, `Succeeded in reading sleep record, count: ${healthSequences.length}`);

      healthSequences.forEach((healthSequence, index) => {
        hilog.info(DOMAIN, TAG, `Sleep record ${index}:`);
        hilog.info(DOMAIN, TAG, `  Start time: ${healthSequence.startTime}`);
        hilog.info(DOMAIN, TAG, `  End time: ${healthSequence.endTime}`);
        
        if (healthSequence.summaries) {
          hilog.info(DOMAIN, TAG, `  Summaries:`);
          const summaries = healthSequence.summaries as any;
          if (summaries.fallAsleepTime) {
            hilog.info(DOMAIN, TAG, `    Fall asleep time: ${summaries.fallAsleepTime}`);
          }
          if (summaries.wakeupTime) {
            hilog.info(DOMAIN, TAG, `    Wakeup time: ${summaries.wakeupTime}`);
          }
          if (summaries.sleepScore) {
            hilog.info(DOMAIN, TAG, `    Sleep score: ${summaries.sleepScore}`);
          }
          if (summaries.duration) {
            hilog.info(DOMAIN, TAG, `    Duration: ${summaries.duration} seconds`);
          }
        }

        if (healthSequence.details) {
          hilog.info(DOMAIN, TAG, `  Details:`);
          const details = healthSequence.details as any;
          if (details.sleepSegment) {
            hilog.info(DOMAIN, TAG, `    Sleep segment count: ${details.sleepSegment.length}`);
            details.sleepSegment.forEach((segment: any, segIndex: number) => {
              hilog.info(DOMAIN, TAG, `      Segment ${segIndex}: start=${segment.startTime}, end=${segment.endTime}, status=${segment.sleepStatus}`);
            });
          }
        }
      });

      return healthSequences;
    } catch (error) {
      this.handleReadError(error);
      throw error;
    }
  }

  async readSleepNapRecord(withDetails: boolean = false): Promise<healthStore.HealthSequence[]> {
    try {
      await this.initialize();

      const healthSequenceReadRequest: healthStore.HealthSequenceReadRequest = {
        healthSequenceDataType: healthStore.healthSequenceHelper.sleepNapRecord.DATA_TYPE,
        startTime: Date.now() - 86400000,
        endTime: Date.now(),
        readOptions: {
          withDetails: withDetails
        }
      };

      const healthSequences = await healthStore.readData(healthSequenceReadRequest);
      hilog.info(DOMAIN, TAG, `Succeeded in reading sleep nap record, count: ${healthSequences.length}`);

      return healthSequences;
    } catch (error) {
      this.handleReadError(error);
      throw error;
    }
  }

  private handleReadError(error: any): void {
    switch (error.code) {
      case 201:
        hilog.error(DOMAIN, TAG, 'Permission verification failed. Please request user authorization first.');
        break;
      case 401:
        hilog.error(DOMAIN, TAG, 'Parameter error. Please check mandatory parameters.');
        break;
      case 1002700001:
        hilog.error(DOMAIN, TAG, 'System internal error.');
        break;
      case 1002700002:
        hilog.error(DOMAIN, TAG, 'Database processing error.');
        break;
      case 1002701001:
        hilog.error(DOMAIN, TAG, 'Network error. Please check network connection.');
        break;
      case 1002702001:
        hilog.error(DOMAIN, TAG, 'Account error. User has not logged in with HUAWEI ID.');
        break;
      case 1002702002:
        hilog.error(DOMAIN, TAG, 'Account error. Failed to obtain account information.');
        break;
      case 1002703001:
        hilog.error(DOMAIN, TAG, 'User privacy is not agreed. Please start Health app.');
        break;
      default:
        hilog.error(DOMAIN, TAG, `Unknown error: ${error.message}`);
    }
  }
}

export async function demonstrateHealthSequenceRead(context: common.UIAbilityContext): Promise<void> {
  const reader = new HealthSequenceReader(context);

  try {
    await reader.requestReadPermission([
      healthStore.healthSequenceHelper.sleepRecord.DATA_TYPE
    ]);

    const sleepRecords = await reader.readSleepRecord(true);
    hilog.info(DOMAIN, TAG, `Read ${sleepRecords.length} sleep records`);
  } catch (error) {
    hilog.error(DOMAIN, TAG, 'Failed to demonstrate health sequence read');
  }
}