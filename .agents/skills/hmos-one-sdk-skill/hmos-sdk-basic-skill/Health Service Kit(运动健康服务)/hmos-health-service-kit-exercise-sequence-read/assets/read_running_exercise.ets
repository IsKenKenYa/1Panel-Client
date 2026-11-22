import { healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';

const TAG = 'ReadRunningExercise';
const DOMAIN = 0x0000;

@Entry
@Component
struct ReadRunningExercise {
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  
  build() {
    Column() {
      Button('读取跑步记录')
        .onClick(() => {
          this.readRunningExercise();
        })
        .width('80%')
        .height(50)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
  
  async readRunningExercise(): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, 'Start reading running exercise sequence...');
      
      await healthStore.init(this.context);
      hilog.info(DOMAIN, TAG, 'HealthStore initialized successfully.');
      
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
      
      const runningSequences = await healthStore.readData<healthStore.exerciseSequenceHelper.running.Model>(sequenceReadRequest);
      hilog.info(DOMAIN, TAG, `Succeeded in reading data. Records count: ${runningSequences.length}`);
      
      if (runningSequences.length === 0) {
        hilog.info(DOMAIN, TAG, 'No running exercise records found.');
        return;
      }
      
      runningSequences.forEach((runningSequence, index) => {
        hilog.info(DOMAIN, TAG, `=== Running Exercise Record ${index + 1} ===`);
        hilog.info(DOMAIN, TAG, `Start Time: ${runningSequence.startTime}`);
        hilog.info(DOMAIN, TAG, `End Time: ${runningSequence.endTime}`);
        hilog.info(DOMAIN, TAG, `Duration: ${runningSequence.duration} ms`);
        hilog.info(DOMAIN, TAG, `Time Zone: ${runningSequence.timeZone}`);
        
        Object.keys(runningSequence.summaries).forEach((key) => {
          hilog.info(DOMAIN, TAG, `Summary Key: ${key}`);
          Object.keys(runningSequence.summaries[key]).forEach((fieldName) => {
            hilog.info(DOMAIN, TAG, `  Field ${fieldName}: ${runningSequence.summaries[key][fieldName]}`);
          });
        });
        
        if (runningSequence.details) {
          Object.keys(runningSequence.details).forEach((detailKey) => {
            const detailPoints = runningSequence.details[detailKey];
            hilog.info(DOMAIN, TAG, `Detail Key: ${detailKey}, Points Count: ${detailPoints.length}`);
            if (detailPoints.length > 0) {
              hilog.info(DOMAIN, TAG, `  First Point Start Time: ${detailPoints[0].startTime}`);
            }
          });
        }
      });
      
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to read running exercise. Code: ${err.code}, Message: ${err.message}`);
      
      switch (err.code) {
        case 201:
          hilog.error(DOMAIN, TAG, 'Permission verification failed. Please check user authorization.');
          break;
        case 401:
          hilog.error(DOMAIN, TAG, 'Parameter error. Please check request parameters.');
          break;
        case 1002700001:
          hilog.error(DOMAIN, TAG, 'System internal error. Please try again later.');
          break;
        case 1002701001:
          hilog.error(DOMAIN, TAG, 'Network error. Please check network connection.');
          break;
        case 1002702001:
          hilog.error(DOMAIN, TAG, 'Account not logged in. Please login with HUAWEI ID.');
          break;
        case 1002703001:
          hilog.error(DOMAIN, TAG, 'User privacy not agreed. Please start Health app first.');
          break;
        default:
          hilog.error(DOMAIN, TAG, `Unknown error: ${err.message}`);
      }
    }
  }
}