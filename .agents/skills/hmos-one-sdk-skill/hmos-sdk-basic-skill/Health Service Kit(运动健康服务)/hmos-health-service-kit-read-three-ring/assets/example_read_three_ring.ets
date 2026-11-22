import { healthService, healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ThreeRingReadExample';
const DOMAIN = 0x0000;

export class ThreeRingReader {
  private isInitialized: boolean = false;

  async initialize(): Promise<void> {
    try {
      await healthStore.init();
      this.isInitialized = true;
      hilog.info(DOMAIN, TAG, 'HealthStore initialized successfully');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to initialize HealthStore. Code: ${error.code}, message: ${error.message}`);
      throw error;
    }
  }

  async readThreeRingData(): Promise<healthService.workout.ActivityReport | null> {
    if (!this.isInitialized) {
      hilog.error(DOMAIN, TAG, 'HealthStore not initialized. Call initialize() first.');
      return null;
    }

    try {
      const result: healthService.workout.ActivityReport = await healthService.workout.readActivityReport();
      hilog.info(DOMAIN, TAG, 'Succeeded in reading ActivityReport');
      
      this.logActivityReport(result);
      
      return result;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to read ActivityReport. Code: ${error.code}, message: ${error.message}`);
      this.handleReadError(error);
      return null;
    }
  }

  private logActivityReport(report: healthService.workout.ActivityReport): void {
    hilog.info(DOMAIN, TAG, `Steps: ${report.steps}`);
    if (report.stepsGoal !== undefined) {
      hilog.info(DOMAIN, TAG, `Steps Goal: ${report.stepsGoal}`);
      const stepsProgress = (report.steps / report.stepsGoal) * 100;
      hilog.info(DOMAIN, TAG, `Steps Progress: ${stepsProgress.toFixed(1)}%`);
    }

    hilog.info(DOMAIN, TAG, `Active Calories: ${report.activeCalories} cal`);
    if (report.activeCaloriesGoal !== undefined) {
      hilog.info(DOMAIN, TAG, `Active Calories Goal: ${report.activeCaloriesGoal} cal`);
      const caloriesProgress = (report.activeCalories / report.activeCaloriesGoal) * 100;
      hilog.info(DOMAIN, TAG, `Calories Progress: ${caloriesProgress.toFixed(1)}%`);
    }

    hilog.info(DOMAIN, TAG, `Exercise Duration: ${report.exercise} minutes`);
    if (report.exerciseGoal !== undefined) {
      hilog.info(DOMAIN, TAG, `Exercise Goal: ${report.exerciseGoal} minutes`);
      const exerciseProgress = (report.exercise / report.exerciseGoal) * 100;
      hilog.info(DOMAIN, TAG, `Exercise Progress: ${exerciseProgress.toFixed(1)}%`);
    }

    hilog.info(DOMAIN, TAG, `Active Hours: ${report.activeHours}`);
    if (report.activeHoursGoal !== undefined) {
      hilog.info(DOMAIN, TAG, `Active Hours Goal: ${report.activeHoursGoal}`);
      const hoursProgress = (report.activeHours / report.activeHoursGoal) * 100;
      hilog.info(DOMAIN, TAG, `Hours Progress: ${hoursProgress.toFixed(1)}%`);
    }
  }

  private handleReadError(error: any): void {
    switch (error.code) {
      case 201:
        hilog.error(DOMAIN, TAG, 'Permission denied. Please request user authorization for daily activity data read permission.');
        break;
      case 14500101:
        hilog.error(DOMAIN, TAG, 'Service exception. Please try again later.');
        break;
      case 1002702001:
        hilog.error(DOMAIN, TAG, 'Account not logged in. Please login with HUAWEI ID.');
        break;
      case 1002703001:
        hilog.error(DOMAIN, TAG, 'User privacy not agreed. Please launch Health app first.');
        break;
      default:
        hilog.error(DOMAIN, TAG, `Unknown error: ${error.code}`);
    }
  }

  async readWithRetry(maxRetries: number = 3): Promise<healthService.workout.ActivityReport | null> {
    for (let i = 0; i < maxRetries; i++) {
      const result = await this.readThreeRingData();
      if (result !== null) {
        return result;
      }
      
      if (i < maxRetries - 1) {
        hilog.warn(DOMAIN, TAG, `Retry attempt ${i + 1} of ${maxRetries}`);
        await this.delay(1000);
      }
    }
    
    hilog.error(DOMAIN, TAG, `Failed after ${maxRetries} retries`);
    return null;
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

export async function main(): Promise<void> {
  const reader = new ThreeRingReader();
  
  try {
    await reader.initialize();
    const report = await reader.readWithRetry(3);
    
    if (report !== null) {
      hilog.info(DOMAIN, TAG, 'Three-ring data reading completed successfully');
    } else {
      hilog.error(DOMAIN, TAG, 'Failed to read three-ring data');
    }
  } catch (error) {
    hilog.error(DOMAIN, TAG, `Application error: ${error.message}`);
  }
}