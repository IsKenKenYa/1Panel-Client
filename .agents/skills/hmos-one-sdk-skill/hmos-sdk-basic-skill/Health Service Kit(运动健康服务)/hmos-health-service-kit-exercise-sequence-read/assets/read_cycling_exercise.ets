import { healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';

const TAG = 'ReadCyclingExercise';
const DOMAIN = 0x0000;

@Entry
@Component
struct ReadCyclingExercise {
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  
  build() {
    Column() {
      Button('读取骑行记录')
        .onClick(() => {
          this.readCyclingExercise();
        })
        .width('80%')
        .height(50)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
  
  async readCyclingExercise(): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, 'Start reading cycling exercise sequence...');
      
      await healthStore.init(this.context);
      hilog.info(DOMAIN, TAG, 'HealthStore initialized successfully.');
      
      const sequenceReadRequest: healthStore.ExerciseSequenceReadRequest<healthStore.exerciseSequenceHelper.cycling.DetailFields> = {
        startTime: 1698040800000,
        endTime: 1698042600000,
        exerciseType: healthStore.exerciseSequenceHelper.cycling.EXERCISE_TYPE,
        count: 1,
        sortOrder: 1,
        readOptions: {
          withDetails: true
        }
      };
      
      const cyclingSequences = await healthStore.readData<healthStore.exerciseSequenceHelper.cycling.Model>(sequenceReadRequest);
      hilog.info(DOMAIN, TAG, `Succeeded in reading data. Records count: ${cyclingSequences.length}`);
      
      if (cyclingSequences.length === 0) {
        hilog.info(DOMAIN, TAG, 'No cycling exercise records found.');
        return;
      }
      
      cyclingSequences.forEach((cyclingSequence, index) => {
        hilog.info(DOMAIN, TAG, `=== Cycling Exercise Record ${index + 1} ===`);
        hilog.info(DOMAIN, TAG, `Start Time: ${cyclingSequence.startTime}`);
        hilog.info(DOMAIN, TAG, `End Time: ${cyclingSequence.endTime}`);
        hilog.info(DOMAIN, TAG, `Duration: ${cyclingSequence.duration} ms`);
        hilog.info(DOMAIN, TAG, `Time Zone: ${cyclingSequence.timeZone}`);
        
        Object.keys(cyclingSequence.summaries).forEach((key) => {
          hilog.info(DOMAIN, TAG, `Summary Key: ${key}`);
          Object.keys(cyclingSequence.summaries[key]).forEach((fieldName) => {
            hilog.info(DOMAIN, TAG, `  Field ${fieldName}: ${cyclingSequence.summaries[key][fieldName]}`);
          });
        });
        
        if (cyclingSequence.details) {
          Object.keys(cyclingSequence.details).forEach((detailKey) => {
            const detailPoints = cyclingSequence.details[detailKey];
            hilog.info(DOMAIN, TAG, `Detail Key: ${detailKey}, Points Count: ${detailPoints.length}`);
          });
        }
      });
      
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to read cycling exercise. Code: ${err.code}, Message: ${err.message}`);
      
      switch (err.code) {
        case 201:
          hilog.error(DOMAIN, TAG, 'Permission verification failed.');
          break;
        case 401:
          hilog.error(DOMAIN, TAG, 'Parameter error.');
          break;
        case 1002700001:
          hilog.error(DOMAIN, TAG, 'System internal error.');
          break;
        case 1002701001:
          hilog.error(DOMAIN, TAG, 'Network error.');
          break;
        default:
          hilog.error(DOMAIN, TAG, `Unknown error: ${err.message}`);
      }
    }
  }
}