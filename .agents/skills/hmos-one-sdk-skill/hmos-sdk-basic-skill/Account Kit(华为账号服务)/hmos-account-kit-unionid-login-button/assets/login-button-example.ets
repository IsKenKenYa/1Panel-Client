/**
 * 华为账号登录按钮示例 - ArkTS
 * 完整的登录流程实现
 */

import { LoginWithHuaweiIDButton, loginComponentManager } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 错误码枚举
export enum ErrorCode {
  ERROR_CODE_LOGIN_OUT = 1001502001,           // 账号未登录
  ERROR_CODE_NETWORK_ERROR = 1001502005,       // 网络错误
  ERROR_CODE_INTERNAL_ERROR = 1001502009,      // 内部错误
  ERROR_CODE_USER_CANCEL = 1001502012,         // 用户取消授权
  ERROR_CODE_SYSTEM_SERVICE = 12300001,        // 系统服务异常
  ERROR_CODE_REQUEST_REFUSE = 1001500002,      // 重复请求
  ERROR_CODE_AGREEMENT_STATUS_NOT_ACCEPTED = 1005300001  // 用户未同意协议
}

@Entry
@Component
struct LoginButtonExample {
  @State loginStatus: string = '未登录';
  @State unionID: string = '';
  @State authorizationCode: string = '';
  
  // 构造登录按钮控制器
  controller: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .onClickLoginWithHuaweiIDButton((error: BusinessError, response: loginComponentManager.HuaweiIDCredential) => {
        if (error) {
          this.handleError(error);
          return;
        }
        
        if (response) {
          hilog.info(0x0000, 'AccountKit', 'Login succeeded');
          this.authorizationCode = response.authorizationCode || '';
          
          // 发送authorizationCode到服务端获取UnionID
          this.sendCodeToServer(this.authorizationCode);
        }
      });

  // 错误处理函数
  handleError(error: BusinessError): void {
    hilog.error(0x0000, 'AccountKit', 
      `Login failed: code=${error.code}, message=${error.message}`);
    
    this.loginStatus = '登录失败';
    
    switch (error.code) {
      case ErrorCode.ERROR_CODE_LOGIN_OUT:
        this.loginStatus = '请先登录华为账号';
        break;
      case ErrorCode.ERROR_CODE_NETWORK_ERROR:
        this.loginStatus = '网络错误，请检查连接';
        break;
      case ErrorCode.ERROR_CODE_USER_CANCEL:
        this.loginStatus = '用户取消授权';
        break;
      case ErrorCode.ERROR_CODE_AGREEMENT_STATUS_NOT_ACCEPTED:
        this.loginStatus = '请同意用户协议';
        break;
      default:
        this.loginStatus = '登录失败，请重试';
        break;
    }
  }

  // 发送授权码到服务端
  async sendCodeToServer(code: string): Promise<void> {
    try {
      // TODO: 调用应用服务端API
      // const response = await fetch('/api/login', {
      //   method: 'POST',
      //   body: JSON.stringify({ authorizationCode: code })
      // });
      
      hilog.info(0x0000, 'AccountKit', 'Authorization code sent to server');
      this.loginStatus = '已获取授权码';
      
      // 模拟服务端响应
      setTimeout(() => {
        this.unionID = 'mock_union_id_123456';
        this.loginStatus = '登录成功';
      }, 1000);
    } catch (e) {
      hilog.error(0x0000, 'AccountKit', 'Failed to send code to server');
      this.loginStatus = '服务端通信失败';
    }
  }

  build() {
    Column() {
      // 显示登录状态
      Text(`状态: ${this.loginStatus}`)
        .fontSize(16)
        .margin({ bottom: 20 });
      
      if (this.unionID) {
        Text(`UnionID: ${this.unionID}`)
          .fontSize(14)
          .margin({ bottom: 20 });
      }
      
      // 华为账号登录按钮
      Column() {
        LoginWithHuaweiIDButton({
          params: {
            style: loginComponentManager.Style.BUTTON_RED,
            borderRadius: 24,
            loginType: loginComponentManager.LoginType.ID,
            supportDarkMode: true,
            extraStyle: {
              buttonStyle: new loginComponentManager.ButtonStyle().loadingStyle({
                show: this.loginStatus === '登录中'
              })
            }
          },
          controller: this.controller
        })
      }
      .height(40)
      .width('100%')
      
      // 重置按钮
      Button('重置状态')
        .onClick(() => {
          this.loginStatus = '未登录';
          this.unionID = '';
          this.authorizationCode = '';
        })
        .margin({ top: 20 });
    }
    .width('100%')
    .padding(16)
    .justifyContent(FlexAlign.Center)
  }
}
