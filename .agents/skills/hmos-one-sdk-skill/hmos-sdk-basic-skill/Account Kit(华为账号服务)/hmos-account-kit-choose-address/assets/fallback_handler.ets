import { shippingAddress } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

export enum FallbackMethod {
  MANUAL_INPUT = 'manual_input',
  GUIDE_LOGIN = 'guide_login',
  SHOW_ERROR = 'show_error',
  RETRY = 'retry'
}

export interface FallbackResult {
  method: FallbackMethod;
  success: boolean;
  message: string;
  data?: shippingAddress.AddressInfo;
}

export class AddressFallbackHandler {
  private static readonly MAX_RETRY_COUNT = 3;
  private retryCount = 0;

  async handleAddressError(
    error: BusinessError,
    context: common.Context
  ): Promise<FallbackResult> {
    hilog.info(0x0000, 'FallbackHandler', `Handling error code: ${error.code}`);

    switch (error.code) {
      case 1008100007:
        return await this.handleUnsupportedAccount();

      case 1008100003:
        return await this.handleUserNotLoggedIn();

      case 1008100002:
        return await this.handleNetworkError(context);

      case 1008100006:
        return this.handleUserCanceled();

      case 1008100004:
      case 1008100005:
        return this.handleConfigurationError(error);

      default:
        return this.handleUnknownError(error);
    }
  }

  private async handleUnsupportedAccount(): Promise<FallbackResult> {
    hilog.warn(0x0000, 'FallbackHandler', 'Account not supported, using manual input.');
    
    return {
      method: FallbackMethod.MANUAL_INPUT,
      success: false,
      message: 'Your account does not support shipping address. Please enter address manually.'
    };
  }

  private async handleUserNotLoggedIn(): Promise<FallbackResult> {
    hilog.warn(0x0000, 'FallbackHandler', 'User not logged in, guiding to login.');
    
    return {
      method: FallbackMethod.GUIDE_LOGIN,
      success: false,
      message: 'Please login with Huawei ID in system settings, then retry.'
    };
  }

  private async handleNetworkError(context: common.Context): Promise<FallbackResult> {
    hilog.warn(0x0000, 'FallbackHandler', 'Network error, attempting retry.');
    
    if (this.retryCount < AddressFallbackHandler.MAX_RETRY_COUNT) {
      this.retryCount++;
      hilog.info(0x0000, 'FallbackHandler', `Retry attempt ${this.retryCount}`);
      
      try {
        const addressInfo = await shippingAddress.chooseAddress(context);
        return {
          method: FallbackMethod.RETRY,
          success: true,
          message: 'Successfully obtained address after retry.',
          data: addressInfo
        };
      } catch (retryError) {
        const businessError = retryError as BusinessError;
        if (businessError.code !== 1008100002) {
          return this.handleAddressError(businessError, context);
        }
      }
    }

    return {
      method: FallbackMethod.MANUAL_INPUT,
      success: false,
      message: 'Network unavailable after retries. Please enter address manually.'
    };
  }

  private handleUserCanceled(): FallbackResult {
    hilog.info(0x0000, 'FallbackHandler', 'User canceled operation.');
    
    return {
      method: FallbackMethod.SHOW_ERROR,
      success: false,
      message: 'You canceled the address selection.'
    };
  }

  private handleConfigurationError(error: BusinessError): FallbackResult {
    hilog.error(0x0000, 'FallbackHandler', 
      `Configuration error: ${error.code}. Developer needs to fix configuration.`);
    
    const isPermissionError = error.code === 1008100005;
    const message = isPermissionError
      ? 'App permission not configured. Please contact app developer.'
      : 'App certificate not configured. Please contact app developer.';
    
    return {
      method: FallbackMethod.SHOW_ERROR,
      success: false,
      message: message
    };
  }

  private handleUnknownError(error: BusinessError): FallbackResult {
    hilog.error(0x0000, 'FallbackHandler', `Unknown error: ${error.code}`);
    
    return {
      method: FallbackMethod.MANUAL_INPUT,
      success: false,
      message: 'Unknown error occurred. Please enter address manually or retry later.'
    };
  }

  resetRetryCount(): void {
    this.retryCount = 0;
  }
}

export async function getAddressWithFallback(
  context: common.Context
): Promise<FallbackResult> {
  const handler = new AddressFallbackHandler();
  
  try {
    const addressInfo = await shippingAddress.chooseAddress(context);
    return {
      method: FallbackMethod.MANUAL_INPUT,
      success: true,
      message: 'Successfully obtained address from Account Kit.',
      data: addressInfo
    };
  } catch (error) {
    const businessError = error as BusinessError;
    return await handler.handleAddressError(businessError, context);
  }
}