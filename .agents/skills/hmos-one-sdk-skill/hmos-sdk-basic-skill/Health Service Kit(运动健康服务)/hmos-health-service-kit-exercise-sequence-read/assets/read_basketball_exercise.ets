import { healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';

const TAG = 'ReadBasketballExercise';
const DOMAIN = 0x0000;

@Entry
@Component
struct ReadBasketballExercise {
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  
  build() {
    Column() {
      Button('读取篮球记录')
        .onClick(() => {
          this.readBasketballExercise();
        })
        .width('80%')
        .height(50)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
  
  async readBasketballExercise(): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, 'Start reading basketball exercise sequence...');
      
      await healthStore.init(this.context);
      hilog.info(DOMAIN, TAG, 'HealthStore initialized successfully.');
      
      const sequenceReadRequest: healthStore.ExerciseSequenceReadRequest<healthStore.exerciseSequenceHelper.basketball.DetailFields> = {
        startTime: 1698040800000,
        endTime: 1698042600000,
        exerciseType: healthStore.exerciseSequenceHelper.basketball.EXERCISE_TYPE,
        count: 1,
        sortOrder: 1
      };
      
      const basketballSequences = await healthStore.readData<healthStore.exerciseSequenceHelper.basketball.Model>(sequenceReadRequest);
      hilog.info(DOMAIN, TAG, `Succeeded in reading data. Records count: ${basketballSequences.length}`);
      
      if (basketballSequences.length === 0) {
        hilog.info(DOMAIN, TAG, 'No basketball exercise records found.');
        return;
      }
      
      basketballSequences.forEach((basketballSequence, index) => {
        hilog.info(DOMAIN, TAG, `=== Basketball Exercise Record ${index + 1} ===`);
        hilog.info(DOMAIN, TAG, `Start Time: ${basketballSequence.startTime}`);
        hilog.info(DOMAIN, TAG, `End Time: ${basketballSequence.endTime}`);
        hilog.info(DOMAIN, TAG, `Duration: ${basketballSequence.duration} ms`);
        
        Object.keys(basketballSequence.summaries).forEach((key) => {
          hilog.info(DOMAIN, TAG, `Summary Key: ${key}`);
          Object.keys(basketballSequence.summaries[key]).forEach((fieldName) => {
            hilog.info(DOMAIN, TAG, `  Field ${fieldName}: ${basketballSequence.summaries[key][fieldName]}`);
          });
        });
      });
      
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to read basketball exercise. Code: ${err.code}, Message: ${err.message}`);
      
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