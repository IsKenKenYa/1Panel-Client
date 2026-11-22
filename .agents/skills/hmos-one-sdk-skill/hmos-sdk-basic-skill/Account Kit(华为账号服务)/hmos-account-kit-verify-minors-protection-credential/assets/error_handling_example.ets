/**
 * 未成年人模式错误处理示例
 * 
 * 功能说明：
 * 本示例展示如何正确处理未成年人模式相关接口的各种错误情况。
 * 包括参数错误、内部错误、未成年人模式未开启、用户取消等场景。
 * 
 * 使用场景：
 * - 接口调用错误处理
 * - 用户提示和引导
 * - 降级方案实现
 * 
 * 注意事项：
 * - 需要根据错误码提供明确的错误提示
 * - 部分错误需要引导用户执行特定操作
 * - 避免在错误处理中执行耗时操作
 */

import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

const LOG_TAG = 'MinorsProtectionError';
const LOG_DOMAIN = 0x0000;

/**
 * 错误类型枚举
 */
enum MinorsProtectionErrorType {
  PARAM_ERROR = 'PARAM_ERROR',
  INTERNAL_ERROR = 'INTERNAL_ERROR',
  MODE_NOT_ENABLED = 'MODE_NOT_ENABLED',
  USER_CANCELED = 'USER_CANCELED',
  UNSUPPORTED_DEVICE = 'UNSUPPORTED_DEVICE',
  UNSUPPORTED_ACCOUNT = 'UNSUPPORTED_ACCOUNT',
  SERVICE_UNAVAILABLE = 'SERVICE_UNAVAILABLE',
  UNKNOWN_ERROR = 'UNKNOWN_ERROR'
}

/**
 * 错误处理信息
 */
interface ErrorHandlingInfo {
  type: MinorsProtectionErrorType;
  errorCode: number;
  message: string;
  solution: string;
  needUserAction: boolean;
}

/**
 * 未成年人模式错误处理组件
 */
@Entry
@Component
struct MinorsProtectionErrorHandler {
  @State errorMessage: string = '';
  @State errorSolution: string = '';
  @State lastErrorType: MinorsProtectionErrorType = MinorsProtectionErrorType.UNKNOWN_ERROR;
  
  /**
   * 处理验证接口错误
   * 
   * @param error 业务错误对象
   * @returns ErrorHandlingInfo 错误处理信息
   */
  handleVerifyError(error: BusinessError<Object>): ErrorHandlingInfo {
    hilog.error(LOG_DOMAIN, LOG_TAG, 
      `Verification error. Code: ${error.code}, Message: ${error.message}`);
    
    let errorInfo: ErrorHandlingInfo;
    
    switch (error.code) {
      case 401:
        // 参数错误
        errorInfo = {
          type: MinorsProtectionErrorType.PARAM_ERROR,
          errorCode: error.code,
          message: '参数错误：Context参数无效',
          solution: '请确保在页面或自定义组件生命周期内调用接口，并传入正确的Context对象',
          needUserAction: false
        };
        break;
        
      case 1001502009:
        // 内部错误
        errorInfo = {
          type: MinorsProtectionErrorType.INTERNAL_ERROR,
          errorCode: error.code,
          message: '系统内部错误',
          solution: '请重启设备后重试，如果问题持续存在，请联系技术支持',
          needUserAction: true
        };
        break;
        
      case 1009900002:
        // 未成年人模式未开启
        errorInfo = {
          type: MinorsProtectionErrorType.MODE_NOT_ENABLED,
          errorCode: error.code,
          message: '未成年人模式未开启',
          solution: '请先在系统设置中开启未成年人模式',
          needUserAction: true
        };
        break;
        
      case 1009900003:
        // 用户取消操作
        errorInfo = {
          type: MinorsProtectionErrorType.USER_CANCELED,
          errorCode: error.code,
          message: '用户取消了验证操作',
          solution: '用户主动取消，无需特殊处理',
          needUserAction: false
        };
        break;
        
      case 1009900007:
        // 不支持的账号
        errorInfo = {
          type: MinorsProtectionErrorType.UNSUPPORTED_ACCOUNT,
          errorCode: error.code,
          message: '当前账号不支持未成年人模式',
          solution: '请使用中国境内（香港特别行政区、澳门特别行政区、中国台湾除外）的华为账号',
          needUserAction: true
        };
        break;
        
      case 1009900011:
        // 服务不可用
        errorInfo = {
          type: MinorsProtectionErrorType.SERVICE_UNAVAILABLE,
          errorCode: error.code,
          message: '未成年人模式服务不可用',
          solution: '请退出隐私空间后重试',
          needUserAction: true
        };
        break;
        
      default:
        // 未知错误
        errorInfo = {
          type: MinorsProtectionErrorType.UNKNOWN_ERROR,
          errorCode: error.code,
          message: `未知错误: ${error.message}`,
          solution: '请稍后重试或联系技术支持',
          needUserAction: true
        };
    }
    
    this.displayErrorInfo(errorInfo);
    return errorInfo;
  }
  
  /**
   * 处理查询接口错误
   */
  handleQueryError(error: BusinessError<Object>): ErrorHandlingInfo {
    hilog.error(LOG_DOMAIN, LOG_TAG, 
      `Query error. Code: ${error.code}, Message: ${error.message}`);
    
    let errorInfo: ErrorHandlingInfo;
    
    switch (error.code) {
      case 1001502009:
        errorInfo = {
          type: MinorsProtectionErrorType.INTERNAL_ERROR,
          errorCode: error.code,
          message: '查询内部错误',
          solution: '请重启设备后重试',
          needUserAction: true
        };
        break;
        
      default:
        errorInfo = {
          type: MinorsProtectionErrorType.UNKNOWN_ERROR,
          errorCode: error.code,
          message: `查询失败: ${error.message}`,
          solution: '请稍后重试',
          needUserAction: true
        };
    }
    
    this.displayErrorInfo(errorInfo);
    return errorInfo;
  }
  
  /**
   * 处理设备不支持错误
   */
  handleUnsupportedDevice(): ErrorHandlingInfo {
    const errorInfo: ErrorHandlingInfo = {
      type: MinorsProtectionErrorType.UNSUPPORTED_DEVICE,
      errorCode: -1,
      message: '当前设备不支持未成年人模式',
      solution: '当前设备环境不支持未成年人模式功能，应用可以考虑构建自己的未成年人模式',
      needUserAction: false
    };
    
    this.displayErrorInfo(errorInfo);
    return errorInfo;
  }
  
  /**
   * 显示错误信息
   */
  displayErrorInfo(errorInfo: ErrorHandlingInfo): void {
    this.errorMessage = errorInfo.message;
    this.errorSolution = errorInfo.solution;
    this.lastErrorType = errorInfo.type;
    
    hilog.error(LOG_DOMAIN, LOG_TAG, 
      `Error displayed: ${errorInfo.message}, Solution: ${errorInfo.solution}`);
    
    // 根据错误类型提供不同的用户提示
    if (errorInfo.needUserAction) {
      this.showErrorDialog(errorInfo);
    } else {
      this.showErrorToast(errorInfo.message);
    }
  }
  
  /**
   * 显示错误对话框（需要用户操作的错误）
   */
  showErrorDialog(errorInfo: ErrorHandlingInfo): void {
    AlertDialog.show({
      title: '错误提示',
      message: `${errorInfo.message}\n\n解决方法：${errorInfo.solution}`,
      confirm: {
        value: '确定',
        action: () => {
          // 根据错误类型执行相应的操作
          this.handleUserAction(errorInfo.type);
        }
      },
      cancel: {
        value: '取消',
        action: () => {
          hilog.info(LOG_DOMAIN, LOG_TAG, 'User canceled error dialog');
        }
      }
    });
  }
  
  /**
   * 显示错误Toast（无需用户操作的错误）
   */
  showErrorToast(message: string): void {
    // 实际应用中使用Toast提示
    hilog.info(LOG_DOMAIN, LOG_TAG, `Toast: ${message}`);
  }
  
  /**
   * 根据错误类型执行用户操作引导
   */
  handleUserAction(errorType: MinorsProtectionErrorType): void {
    switch (errorType) {
      case MinorsProtectionErrorType.MODE_NOT_ENABLED:
        // 引导用户开启未成年人模式
        this.guideToEnableMinorsMode();
        break;
        
      case MinorsProtectionErrorType.INTERNAL_ERROR:
        // 建议用户重启设备
        this.suggestRestart();
        break;
        
      case MinorsProtectionErrorType.UNSUPPORTED_ACCOUNT:
        // 提示用户更换账号
        this.suggestChangeAccount();
        break;
        
      case MinorsProtectionErrorType.SERVICE_UNAVAILABLE:
        // 提示用户退出隐私空间
        this.suggestExitPrivateSpace();
        break;
        
      default:
        hilog.info(LOG_DOMAIN, LOG_TAG, 'No specific action for this error type');
    }
  }
  
  /**
   * 引导用户开启未成年人模式
   */
  guideToEnableMinorsMode(): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Guiding user to enable minors mode');
    
    AlertDialog.show({
      title: '开启未成年人模式',
      message: '请前往系统设置开启未成年人模式',
      confirm: {
        value: '前往设置',
        action: () => {
          // 实际应用中可以跳转到系统设置
          hilog.info(LOG_DOMAIN, LOG_TAG, 'User accepted to go to settings');
        }
      }
    });
  }
  
  /**
   * 建议用户重启设备
   */
  suggestRestart(): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Suggesting device restart');
    
    AlertDialog.show({
      title: '建议重启设备',
      message: '遇到内部错误，建议重启设备后重试',
      confirm: {
        value: '确定',
        action: () => {
          hilog.info(LOG_DOMAIN, LOG_TAG, 'User acknowledged restart suggestion');
        }
      }
    });
  }
  
  /**
   * 建议用户更换账号
   */
  suggestChangeAccount(): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Suggesting account change');
    
    AlertDialog.show({
      title: '账号不支持',
      message: '当前账号不支持未成年人模式，请使用中国境内华为账号',
      confirm: {
        value: '确定',
        action: () => {
          hilog.info(LOG_DOMAIN, LOG_TAG, 'User acknowledged account change suggestion');
        }
      }
    });
  }
  
  /**
   * 建议用户退出隐私空间
   */
  suggestExitPrivateSpace(): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Suggesting exit from private space');
    
    AlertDialog.show({
      title: '服务不可用',
      message: '当前处于隐私空间，未成年人模式服务不可用，请退出隐私空间后重试',
      confirm: {
        value: '确定',
        action: () => {
          hilog.info(LOG_DOMAIN, LOG_TAG, 'User acknowledged private space suggestion');
        }
      }
    });
  }
  
  /**
   * 降级方案：构建自己的未成年人模式
   */
  implementFallbackMinorsMode(): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Implementing fallback minors mode');
    
    // 当设备不支持系统未成年人模式时，应用可以构建自己的未成年人模式
    // 包括：
    // 1. 应用内密码验证机制
    // 2. 内容过滤和推荐算法
    // 3. 使用时长限制
    // 4. 年龄段识别和内容分级
    
    // 示例：提示用户
    AlertDialog.show({
      title: '使用应用内未成年人模式',
      message: '当前设备不支持系统未成年人模式，将使用应用内的未成年人模式功能',
      confirm: {
        value: '确定',
        action: () => {
          // 初始化应用内未成年人模式
          this.initAppMinorsMode();
        }
      }
    });
  }
  
  /**
   * 初始化应用内未成年人模式
   */
  initAppMinorsMode(): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Initializing app-level minors mode');
    
    // 实际应用中，这里会：
    // 1. 设置应用内密码验证
    // 2. 配置内容过滤规则
    // 3. 初始化时间限制功能
  }
  
  build() {
    Column() {
      Text('未成年人模式错误处理')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });
      
      // 错误信息显示
      if (this.errorMessage !== '') {
        Text('错误信息:')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 });
        
        Text(this.errorMessage)
          .fontSize(16)
          .fontColor(Color.Red)
          .margin({ bottom: 20 });
        
        Text('解决方法:')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 });
        
        Text(this.errorSolution)
          .fontSize(16)
          .fontColor(Color.Blue)
          .margin({ bottom: 20 });
      }
      
      // 测试按钮
      Button('模拟参数错误')
        .width('80%')
        .height(50)
        .fontSize(18)
        .onClick(() => {
          const mockError = {
            code: 401,
            message: 'Parameter error',
            name: 'BusinessError'
          } as BusinessError<Object>;
          this.handleVerifyError(mockError);
        })
        .margin({ bottom: 10 });
      
      Button('模拟未成年人模式未开启')
        .width('80%')
        .height(50)
        .fontSize(18)
        .onClick(() => {
          const mockError = {
            code: 1009900002,
            message: 'Minors mode not enabled',
            name: 'BusinessError'
          } as BusinessError<Object>;
          this.handleVerifyError(mockError);
        })
        .margin({ bottom: 10 });
      
      Button('模拟用户取消')
        .width('80%')
        .height(50)
        .fontSize(18)
        .onClick(() => {
          const mockError = {
            code: 1009900003,
            message: 'User canceled',
            name: 'BusinessError'
          } as BusinessError<Object>;
          this.handleVerifyError(mockError);
        })
        .margin({ bottom: 10 });
      
      Button('模拟服务不可用')
        .width('80%')
        .height(50)
        .fontSize(18)
        .onClick(() => {
          const mockError = {
            code: 1009900011,
            message: 'Service unavailable',
            name: 'BusinessError'
          } as BusinessError<Object>;
          this.handleVerifyError(mockError);
        })
        .margin({ bottom: 10 });
      
      Button('降级方案：应用内未成年人模式')
        .width('80%')
        .height(50)
        .fontSize(18)
        .onClick(() => {
          this.implementFallbackMinorsMode();
        })
        .margin({ bottom: 10 });
      
      Text('点击上方按钮测试不同错误场景的处理')
        .fontSize(14)
        .fontColor(Color.Gray)
        .margin({ top: 20 });
    }
    .width('100%')
    .padding(20);
  }
}