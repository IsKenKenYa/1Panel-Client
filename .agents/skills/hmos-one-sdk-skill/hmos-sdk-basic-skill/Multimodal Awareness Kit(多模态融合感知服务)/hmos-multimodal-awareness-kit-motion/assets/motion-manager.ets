import { motion } from '@kit.MultimodalAwarenessKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';

export class MotionManager {
  private static instance: MotionManager;
  private operatingHandCallback: Callback<motion.OperatingHandStatus> | null = null;
  private holdingHandCallback: Callback<motion.HoldingHandStatus> | null = null;
  private retryCount: number = 0;
  private maxRetryCount: number = 3;
  private context: common.UIAbilityContext | null = null;

  static getInstance(): MotionManager {
    if (!MotionManager.instance) {
      MotionManager.instance = new MotionManager();
    }
    return MotionManager.instance;
  }

  setContext(context: common.UIAbilityContext) {
    this.context = context;
  }

  async checkAndRequestPermission(permission: Permissions): Promise<boolean> {
    if (!this.context) {
      console.error('Context未设置');
      return false;
    }

    const atManager = abilityAccessCtrl.createAtManager();
    try {
      const grantStatus = await atManager.checkAccessToken(
        this.context.applicationInfo.accessTokenId,
        permission
      );

      if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        console.info(`权限 ${permission} 已授予`);
        return true;
      }

      console.info(`申请权限 ${permission}`);
      const result = await atManager.requestPermissionsFromUser(
        this.context,
        [permission]
      );

      if (result.authResults[0] === 0) {
        console.info(`权限 ${permission} 申请成功`);
        return true;
      } else {
        console.warn(`权限 ${permission} 申请失败`);
        return false;
      }
    } catch (err) {
      const error = err as BusinessError;
      console.error(`权限检查失败: ${error.message}`);
      return false;
    }
  }

  async subscribeOperatingHandWithRetry(
    callback: Callback<motion.OperatingHandStatus>
  ): Promise<boolean> {
    const hasPermission = await this.checkAndRequestPermission(
      'ohos.permission.ACTIVITY_MOTION'
    );

    if (!hasPermission) {
      console.error('缺少必要权限');
      return false;
    }

    this.operatingHandCallback = callback;
    this.retryCount = 0;

    while (this.retryCount < this.maxRetryCount) {
      try {
        motion.on('operatingHandChanged', callback);
        console.info('订阅操作手状态成功');
        return true;
      } catch (err) {
        const error = err as BusinessError;
        console.error(`订阅失败，错误码: ${error.code}, 错误信息: ${error.message}`);

        if (error.code === 201) {
          console.error('权限不足，请重新申请权限');
          return false;
        }

        if (error.code === 801) {
          console.error('设备不支持操作手识别功能');
          return false;
        }

        this.retryCount++;
        if (this.retryCount < this.maxRetryCount) {
          console.info(`将在1秒后重试，当前重试次数: ${this.retryCount}`);
          await this.delay(1000);
        }
      }
    }

    console.error('订阅失败，已达最大重试次数');
    return false;
  }

  async unsubscribeOperatingHandWithRetry(): Promise<boolean> {
    this.retryCount = 0;

    while (this.retryCount < this.maxRetryCount) {
      try {
        motion.off('operatingHandChanged');
        console.info('取消订阅操作手状态成功');
        this.operatingHandCallback = null;
        return true;
      } catch (err) {
        const error = err as BusinessError;
        console.error(`取消订阅失败，错误码: ${error.code}`);

        if (error.code === 201 || error.code === 801) {
          return false;
        }

        this.retryCount++;
        if (this.retryCount < this.maxRetryCount) {
          console.info(`将在1秒后重试，当前重试次数: ${this.retryCount}`);
          await this.delay(1000);
        }
      }
    }

    console.error('取消订阅失败，已达最大重试次数');
    return false;
  }

  async subscribeHoldingHandWithRetry(
    callback: Callback<motion.HoldingHandStatus>
  ): Promise<boolean> {
    const hasPermission = await this.checkAndRequestPermission(
      'ohos.permission.DETECT_GESTURE'
    );

    if (!hasPermission) {
      console.error('缺少必要权限');
      return false;
    }

    this.holdingHandCallback = callback;
    this.retryCount = 0;

    while (this.retryCount < this.maxRetryCount) {
      try {
        motion.on('holdingHandChanged', callback);
        console.info('订阅握持手状态成功');
        return true;
      } catch (err) {
        const error = err as BusinessError;
        console.error(`订阅失败，错误码: ${error.code}`);

        if (error.code === 201 || error.code === 801) {
          return false;
        }

        this.retryCount++;
        if (this.retryCount < this.maxRetryCount) {
          await this.delay(1000);
        }
      }
    }

    console.error('订阅失败，已达最大重试次数');
    return false;
  }

  async unsubscribeHoldingHandWithRetry(): Promise<boolean> {
    this.retryCount = 0;

    while (this.retryCount < this.maxRetryCount) {
      try {
        motion.off('holdingHandChanged');
        console.info('取消订阅握持手状态成功');
        this.holdingHandCallback = null;
        return true;
      } catch (err) {
        const error = err as BusinessError;
        console.error(`取消订阅失败，错误码: ${error.code}`);

        if (error.code === 201 || error.code === 801) {
          return false;
        }

        this.retryCount++;
        if (this.retryCount < this.maxRetryCount) {
          await this.delay(1000);
        }
      }
    }

    return false;
  }

  getLatestOperatingHandStatus(): motion.OperatingHandStatus | null {
    try {
      const status = motion.getRecentOperatingHandStatus();
      console.info(`当前操作手状态: ${status}`);
      return status;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`获取状态失败，错误码: ${error.code}`);
      return null;
    }
  }

  checkDeviceSupport(): boolean {
    try {
      const status = motion.getRecentOperatingHandStatus();
      console.info('设备支持动作感知功能');
      return true;
    } catch (err) {
      const error = err as BusinessError;
      if (error.code === 801) {
        console.warn('当前设备不支持动作感知功能');
        return false;
      }
      return true;
    }
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}