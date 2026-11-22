/**
 * 完整示例:获取华为账号用户头像和昵称
 * 功能:通过Account Kit授权接口获取用户头像URL和昵称
 * 适用场景:用户信息填写、个人资料设置
 */

import { authentication } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { http } from '@kit.NetworkKit';
import { image } from '@kit.ImageKit';

const TAG = 'AvatarNicknameExample';
const DOMAIN = 0x0000;

/**
 * 获取用户头像和昵称的主要函数
 * @returns Promise包含头像URL、昵称和可选的Authorization Code
 */
async function getAvatarAndNickname(): Promise<{
  avatarUri: string;
  nickName: string;
  authorizationCode?: string;
  openID: string;
  unionID: string;
}> {
  // 步骤1:创建授权请求并设置参数
  const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
  
  // 获取头像昵称需要传profile scope
  authRequest.scopes = ['profile'];
  
  // 如果需要服务端开发,传入serviceauthcode获取Authorization Code
  authRequest.permissions = ['serviceauthcode'];
  
  // 强制授权:未登录或未授权时拉起授权页面
  authRequest.forceAuthorization = true;
  
  // 生成state防止跨站攻击
  authRequest.state = util.generateRandomUUID();
  
  hilog.info(DOMAIN, TAG, 'Created authorization request with state: %s', authRequest.state);

  // 步骤2:创建授权Controller并执行请求
  // 注意:必须在自定义组件实例中调用,传入有效的Context
  const controller = new authentication.AuthenticationController(this.getUIContext().getHostContext());
  
  try {
    const data = await controller.executeRequest(authRequest);
    
    // 步骤3:解析授权响应
    const authorizationWithHuaweiIDResponse = data as authentication.AuthorizationWithHuaweiIDResponse;
    
    // 验证state一致性(防止跨站攻击)
    const state = authorizationWithHuaweiIDResponse?.state;
    if (state && authRequest.state !== state) {
      hilog.error(DOMAIN, TAG, 'State mismatch! Request state: %s, Response state: %s', 
        authRequest.state, state);
      throw new Error('State verification failed - possible CSRF attack');
    }
    
    hilog.info(DOMAIN, TAG, 'Authorization succeeded, state verified');
    
    // 步骤4:提取头像昵称等信息
    const credential = authorizationWithHuaweiIDResponse?.data;
    if (!credential) {
      throw new Error('No credential data in response');
    }
    
    const avatarUri = credential.avatarUri || '';
    const nickName = credential.nickName || '';
    const authorizationCode = credential.authorizationCode;
    const openID = credential.openID || '';
    const unionID = credential.unionID || '';
    
    hilog.info(DOMAIN, TAG, 'Avatar URI: %s', avatarUri);
    hilog.info(DOMAIN, TAG, 'Nickname: %s', nickName);
    hilog.info(DOMAIN, TAG, 'OpenID: %s', openID);
    hilog.info(DOMAIN, TAG, 'UnionID: %s', unionID);
    
    if (authorizationCode) {
      hilog.info(DOMAIN, TAG, 'Authorization Code obtained for server-side development');
    }
    
    return {
      avatarUri,
      nickName,
      authorizationCode,
      openID,
      unionID
    };
    
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, 'Failed to get avatar and nickname. Code: %d, Message: %s', 
      err.code, err.message);
    throw error;
  }
}

/**
 * 错误处理函数
 * @param error BusinessError对象
 */
function handleAuthorizationError(error: BusinessError): void {
  hilog.error(DOMAIN, TAG, 'Authorization error - Code: %d, Message: %s', error.code, error.message);
  
  switch (error.code) {
    case 1001502001: // 用户未登录华为账号
      hilog.warn(DOMAIN, TAG, 'User not logged in. Prompt user to login.');
      // 提示: "请登录华为账号并重试"
      break;
      
    case 1001502005: // 网络异常
      hilog.warn(DOMAIN, TAG, 'Network error. Check network status.');
      // 提示: "网络异常,请检查当前网络状态并重试"
      break;
      
    case 1001502012: // 用户取消授权
      hilog.warn(DOMAIN, TAG, 'User canceled authorization.');
      // 提示: "用户取消授权" - 不强制再次请求
      break;
      
    case 12300001: // 系统服务异常
      hilog.warn(DOMAIN, TAG, 'System service exception.');
      // 提示: "系统服务异常,请稍后重试"
      break;
      
    case 1001500002: // 重复请求被拒绝
      hilog.warn(DOMAIN, TAG, 'Duplicate request rejected. No action needed.');
      // 应用无需处理此错误
      break;
      
    case 1001500001: // 应用指纹证书校验失败
      hilog.error(DOMAIN, TAG, 'App fingerprint verification failed.');
      // 提示: "应用配置错误,请联系开发者"
      // 需要:检查签名和指纹配置
      break;
      
    case 1001502003: // 输入参数值无效
      hilog.error(DOMAIN, TAG, 'Invalid input parameter.');
      // 检查scopes和permissions参数
      break;
      
    case 1001500003: // 不支持该scopes或permissions
      hilog.error(DOMAIN, TAG, 'Unsupported scopes or permissions.');
      // 元服务场景需设置supportAtomicService=true
      break;
      
    case 401: // 参数检查失败
      hilog.error(DOMAIN, TAG, 'Parameter check failed.');
      // 检查Context参数是否正确传入
      break;
      
    default:
      hilog.error(DOMAIN, TAG, 'Unknown error: %d', error.code);
      // 提示: "获取用户信息失败,请稍后重试"
      break;
  }
}

/**
 * 下载并保存头像图片到本地
 * @param avatarUrl 头像URL
 * @param localPath 本地保存路径
 * @returns Promise<boolean> 是否下载成功
 */
async function downloadAndSaveAvatar(avatarUrl: string, localPath: string): Promise<boolean> {
  if (!avatarUrl) {
    hilog.warn(DOMAIN, TAG, 'No avatar URL provided');
    return false;
  }
  
  try {
    hilog.info(DOMAIN, TAG, 'Downloading avatar from: %s', avatarUrl);
    
    // 使用http请求下载头像
    const httpRequest = http.createHttp();
    const response = await httpRequest.request(avatarUrl, {
      method: http.RequestMethod.GET,
      header: {
        'Content-Type': 'image/jpeg'
      }
    });
    
    if (response.responseCode === 200) {
      // 获取图片数据
      const imageData = response.result as ArrayBuffer;
      
      // 保存到本地(实际应用中需要文件系统API)
      hilog.info(DOMAIN, TAG, 'Avatar downloaded successfully, size: %d bytes', imageData.byteLength);
      
      // 这里可以使用fs.writeFile保存到本地
      // 示例: await fs.writeFile(localPath, imageData);
      
      httpRequest.destroy();
      return true;
    } else {
      hilog.error(DOMAIN, TAG, 'Failed to download avatar, response code: %d', response.responseCode);
      httpRequest.destroy();
      return false;
    }
    
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, 'Error downloading avatar: %s', err.message);
    return false;
  }
}

/**
 * 完整的使用示例
 * 在页面组件中调用
 */
@Entry
@Component
struct AvatarNicknamePage {
  @State avatarUrl: string = '';
  @State nickName: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  
  build() {
    Column() {
      // 显示头像
      if (this.avatarUrl) {
        Image(this.avatarUrl)
          .width(100)
          .height(100)
          .borderRadius(50)
          .objectFit(ImageFit.Cover)
      } else {
        // 默认头像占位
        Image($r('app.media.default_avatar'))
          .width(100)
          .height(100)
          .borderRadius(50)
      }
      
      // 显示昵称
      Text(this.nickName || '未获取昵称')
        .fontSize(18)
        .margin({ top: 10 })
      
      // 错误提示
      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor(Color.Red)
          .margin({ top: 10 })
      }
      
      // 获取头像昵称按钮
      Button('获取头像昵称')
        .width('80%')
        .margin({ top: 20 })
        .enabled(!this.isLoading)
        .onClick(async () => {
          this.isLoading = true;
          this.errorMessage = '';
          
          try {
            // 调用获取头像昵称函数
            const result = await getAvatarAndNickname();
            
            this.avatarUrl = result.avatarUri;
            this.nickName = result.nickName;
            
            // 建议下载保存头像
            if (result.avatarUri) {
              const saved = await downloadAndSaveAvatar(result.avatarUri, '/data/avatar.jpg');
              if (saved) {
                hilog.info(DOMAIN, TAG, 'Avatar saved to local storage');
              }
            }
            
            // 如果有Authorization Code,可以发送到服务端
            if (result.authorizationCode) {
              // sendAuthorizationCodeToServer(result.authorizationCode);
              hilog.info(DOMAIN, TAG, 'Authorization Code ready for server-side processing');
            }
            
          } catch (error) {
            const err = error as BusinessError;
            handleAuthorizationError(err);
            
            // 根据错误码显示用户提示
            if (err.code === 1001502001) {
              this.errorMessage = '请登录华为账号并重试';
            } else if (err.code === 1001502005) {
              this.errorMessage = '网络异常,请检查网络状态';
            } else if (err.code === 1001502012) {
              this.errorMessage = '用户取消授权';
            } else {
              this.errorMessage = '获取用户信息失败,请稍后重试';
            }
          }
          
          this.isLoading = false;
        })
      
      // 加载指示器
      if (this.isLoading) {
        LoadingProgress()
          .width(50)
          .height(50)
          .margin({ top: 20 })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}

/**
 * 错误码枚举定义
 */
export enum ErrorCode {
  ERROR_CODE_LOGIN_OUT = 1001502001,
  ERROR_CODE_NETWORK_ERROR = 1001502005,
  ERROR_CODE_USER_CANCEL = 1001502012,
  ERROR_CODE_SYSTEM_SERVICE = 12300001,
  ERROR_CODE_REQUEST_REFUSE = 1001500002,
  ERROR_CODE_FINGERPRINT_ERROR = 1001500001,
  ERROR_CODE_PARAM_INVALID = 1001502003,
  ERROR_CODE_SCOPE_UNSUPPORTED = 1001500003,
  ERROR_CODE_PARAM_CHECK_FAILED = 401
}

/**
 * 使用说明:
 * 1. 在DevEco Studio中创建HarmonyOS项目
 * 2. 将此文件放到entry/src/main/ets/pages/目录下
 * 3. 确保已配置签名和指纹、配置Client ID
 * 4. 在module.json5中添加必要权限
 * 5. 运行应用并点击"获取头像昵称"按钮测试
 * 
 * 注意事项:
 * - 头像URL有效期较短,建议下载保存
 * - State必须使用generateRandomUUID生成并验证
 * - 必须在页面组件生命周期内调用
 * - 避免连续点击发起重复请求
 */