---
name: hmos-account-kit-login-button
description: 使用华为账号登录按钮组件获取UnionID/OpenID，支持Phone/Tablet/PC/2in1/TV/Car设备，API版本4.1.0(11)+，适用于用户登录和账号绑定场景
---

# 使用"华为账号登录"按钮登录技能

## 功能描述

本技能提供华为账号登录按钮组件的完整实现方案，应用通过集成LoginWithHuaweiIDButton组件及服务端交互获取华为账号用户身份标识UnionID、OpenID，用于完成用户登录或与应用账号绑定。

华为账号登录按钮包含三种样式：
- Icon类型按钮
- 纯文本按钮
- Icon和文本混合按钮

按钮支持自定义样式、加载态显示、深浅色模式切换等功能。

## 使用场景

### 触发词
- "华为账号登录按钮"
- "LoginWithHuaweiIDButton"
- "UnionID/OpenID登录"
- "华为账号按钮登录"
- "Account Kit按钮"

### 能做
- 集成华为账号登录按钮组件
- 获取Authorization Code、UnionID、OpenID
- 实现用户登录功能
- 实现账号绑定功能
- 自定义按钮样式和属性
- 处理协议状态和错误码

### 绝不做
- 不支持获取手机号（需使用华为账号一键登录功能）
- 不支持静默登录
- 不支持海外账号登录
- 不替代应用自身的账号系统
- 不处理账号注册功能

### 补充
- 支持设备：Phone/Tablet/PC/2in1（默认）、TV（5.1.1(19)+）、Car（26.0.0+）
- API起始版本：4.1.0(11)
- 需要配置签名和指纹
- 需要配置Client ID
- 必须在页面或自定义组件生命周期内调用

## 调用规范和规则

### 输入约束
- 按钮高度：最小40vp
- 按钮宽度：自适应或自定义
- 边框圆角半径：0-50vp
- 图文间距：4-16vp（默认8vp）
- 图标半径：按钮高度的20%-32%（最小8vp）
- API版本要求：>=4.1.0(11)

### 执行约束
- 最大耗时：10秒（网络请求）
- 最大迭代次数：3次（重试机制）
- API调用频次：避免频繁重复调用（错误码1001500002）
- 组件生命周期：必须在页面或自定义组件内调用

### 内容约束
- 禁止生成：硬编码的协议URL、敏感信息日志
- 禁止使用高危函数：eval、exec、系统命令执行
- 禁止操作：直接访问用户隐私数据、绕过协议验证
- 必须校验：Client ID、签名指纹、协议状态

### 降级约束
- 网络失败：提示用户检查网络并提供其他登录方式
- 华为账号未登录：提示用户登录华为账号并重试
- 用户取消授权：无需特别处理，允许用户选择其他方式
- 系统服务异常：提示用户稍后重试或使用其他登录方式
- 协议未同意：弹出协议确认弹框，用户同意后继续登录

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查API版本是否>=4.1.0(11)
2. 验证签名和指纹配置是否正确
3. 验证Client ID配置是否正确
4. 检查设备类型是否支持

**参数准备**：
```typescript
import { LoginWithHuaweiIDButton, loginComponentManager } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 构造控制器
const controller = new loginComponentManager.LoginWithHuaweiIDButtonController();
```

### 步骤2：创建LoginWithHuaweiIDButton组件

**示例代码**：
```typescript
@Entry
@Component
struct LoginButtonPage {
  // 构造控制器
  controller: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .setAgreementStatus(loginComponentManager.AgreementStatus.NOT_ACCEPTED)
      .onClickLoginWithHuaweiIDButton((error: BusinessError, response: loginComponentManager.HuaweiIDCredential) => {
        if (error) {
          this.handleError(error);
          return;
        }
        if (response) {
          const authorizationCode = response.authorizationCode;
          const openID = response.openID;
          hilog.info(0x0000, 'LoginButton', 'Succeeded in getting response.');
          // 将authorizationCode传给服务端
        }
      });

  // 错误处理
  handleError(error: BusinessError): void {
    hilog.error(0x0000, 'LoginButton', `Failed: ${error.code}, ${error.message}`);
    // 根据错误码提示用户
    switch (error.code) {
      case 1001502001: // 账号未登录
        hilog.error(0x0000, 'LoginButton', '华为账号未登录，请登录后重试');
        break;
      case 1001502005: // 网络错误
        hilog.error(0x0000, 'LoginButton', '网络错误，请检查网络状态');
        break;
      case 1005300001: // 协议未同意
        hilog.error(0x0000, 'LoginButton', '用户未同意协议');
        break;
      default:
        hilog.error(0x0000, 'LoginButton', '登录失败，请重试');
    }
  }

  build() {
    Column() {
      LoginWithHuaweiIDButton({
        params: {
          style: loginComponentManager.Style.BUTTON_RED,
          borderRadius: 24,
          loginType: loginComponentManager.LoginType.ID,
          supportDarkMode: true,
          extraStyle: {
            buttonStyle: new loginComponentManager.ButtonStyle().loadingStyle({
              show: true
            })
          }
        },
        controller: this.controller
      })
    }
    .height(40)
    .width('100%')
    .margin({ left: 16, right: 16 })
  }
}
```

### 步骤3：服务端处理Authorization Code

**服务端开发流程**：
1. 使用Client ID、Client Secret、Authorization Code调用获取用户级凭证接口获取Access Token
2. 使用Access Token调用解析凭证接口获取UnionID/OpenID
3. 通过UnionID/OpenID判断用户是否已关联应用账号
4. 如已关联，完成用户登录；如未关联，创建新用户并绑定

**Access Token过期处理**：
- Access Token有效期：60分钟
- Refresh Token有效期：180天
- 过期后使用Refresh Token刷新获取新的Access Token

### 步骤4：协议状态处理

**协议处理代码**：
```typescript
// 设置协议状态为未同意
this.controller.setAgreementStatus(loginComponentManager.AgreementStatus.NOT_ACCEPTED);

// 用户同意协议后设置状态为已同意
Checkbox({ name: 'privacyCheckbox', group: 'privacyCheckboxGroup' })
  .onChange((value: boolean) => {
    if (value) {
      this.controller.setAgreementStatus(loginComponentManager.AgreementStatus.ACCEPTED);
    } else {
      this.controller.setAgreementStatus(loginComponentManager.AgreementStatus.NOT_ACCEPTED);
    }
  })
```

### 步骤5：错误处理与降级

**完整错误处理代码**：
```typescript
enum ErrorCode {
  ERROR_CODE_LOGIN_OUT = 1001502001,           // 账号未登录
  ERROR_CODE_NETWORK_ERROR = 1001502005,       // 网络错误
  ERROR_CODE_INTERNAL_ERROR = 1001502009,      // 内部错误
  ERROR_CODE_USER_CANCEL = 1001502012,         // 用户取消授权
  ERROR_CODE_SYSTEM_SERVICE = 12300001,        // 系统服务异常
  ERROR_CODE_REQUEST_REFUSE = 1001500002,      // 重复请求
  ERROR_CODE_AGREEMENT_STATUS_NOT_ACCEPTED = 1005300001, // 协议未同意
  ERROR_CODE_PARAMETER_ERROR = 401,             // 参数错误
}

dealAllError(error: BusinessError): void {
  if (error.code === ErrorCode.ERROR_CODE_LOGIN_OUT) {
    // 提示：用户未登录华为账号，请登录华为账号并重试
  } else if (error.code === ErrorCode.ERROR_CODE_NETWORK_ERROR) {
    // 提示：网络错误，请检查当前网络状态并重试
  } else if (error.code === ErrorCode.ERROR_CODE_INTERNAL_ERROR) {
    // 提示：登录失败，请尝试使用其他方式登录
  } else if (error.code === ErrorCode.ERROR_CODE_USER_CANCEL) {
    // 用户取消授权，无需处理
  } else if (error.code === ErrorCode.ERROR_CODE_SYSTEM_SERVICE) {
    // 提示：系统服务异常，请稍后重试
  } else if (error.code === ErrorCode.ERROR_CODE_AGREEMENT_STATUS_NOT_ACCEPTED) {
    // 弹出协议确认弹框
  } else {
    // 提示：应用登录失败，请尝试使用其他方式登录
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1001502001 | 用户未登录华为账号 | 提示用户登录华为账号并重试 |
| 1001502005 | 网络错误 | 提示用户检查网络状态并重试 |
| 1001502009 | 内部错误 | 提示用户使用其他方式登录 |
| 1001502012 | 用户取消授权 | 无需处理，允许用户选择其他方式 |
| 12300001 | 系统服务异常 | 提示用户稍后重试 |
| 1001500002 | 重复请求 | 应用无需处理 |
| 1005300001 | 用户未同意协议 | 弹出协议确认弹框 |
| 401 | 参数错误 | 检查参数类型和必填参数 |
| 1001500001 | 应用指纹校验失败 | 检查签名和指纹配置 |
| 1001500003 | scopes或permissions不支持 | 检查权限配置 |
| 1001502014 | 应用缺少必要的scopes或权限 | 申请相应权限 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AccountKit": ">=4.1.0(11)",
    "@kit.BasicServicesKit": ">=4.1.0(11)",
    "@kit.PerformanceAnalysisKit": ">=4.1.0(11)"
  }
}
```

### 环境要求
- HarmonyOS SDK：>=4.1.0(11)
- Stage模型：仅支持Stage模型
- 设备类型：Phone/Tablet/PC/2in1/TV/Car

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.AccountKit'
```
**解决方法**：确保HarmonyOS SDK版本>=4.1.0(11)，并正确配置项目依赖

**问题2：组件无法显示**
```
Error: LoginWithHuaweiIDButton is not defined
```
**解决方法**：确保正确导入LoginWithHuaweiIDButton模块，检查拼写是否正确

**问题3：签名指纹错误**
```
Error: 1001500001 Failed to check fingerprint
```
**解决方法**：按照开发准备章节配置签名和指纹

**问题4：Client ID未配置**
```
Error: Client ID not found
```
**解决方法**：在module.json5中正确配置Client ID

## 常见问题与解决方法

### Q1：按钮点击后无响应
**原因**：协议状态未设置或控制器未正确绑定
**解决方法**：
- 设置协议状态为NOT_ACCEPTED或ACCEPTED
- 确保controller正确绑定到组件
- 检查onClickLoginWithHuaweiIDButton回调是否正确注册

### Q2：获取不到Authorization Code
**原因**：华为账号未登录或网络问题
**解决方法**：
- 提示用户登录华为账号
- 检查网络连接状态
- 查看错误码并针对性处理

### Q3：Access Token过期处理
**原因**：Access Token有效期仅60分钟
**解决方法**：
- 使用Refresh Token（有效期180天）刷新获取新的Access Token
- 当Refresh Token过期时，提示用户重新授权

### Q4：协议弹框无法弹出
**原因**：协议状态设置错误或回调未正确处理
**解决方法**：
- 确保协议状态设置为NOT_ACCEPTED
- 在错误处理中正确处理1005300001错误码
- 使用CustomDialogController创建协议弹框

### Q5：深浅色模式切换失效
**原因**：未设置supportDarkMode参数
**解决方法**：
- 在params中设置supportDarkMode: true
- 确保系统支持深浅色模式切换

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "authorizationCode": "string",
  "openID": "string",
  "unionID": "string",
  "apiUsed": [
    "LoginWithHuaweiIDButton",
    "LoginWithHuaweiIDButtonController",
    "onClickLoginWithHuaweiIDButton",
    "setAgreementStatus"
  ],
  "deviceType": "Phone/Tablet/PC/2in1/TV/Car",
  "apiVersion": ">=4.1.0(11)"
}
```

## 参考文档

- [API开发指南：使用"华为账号登录"按钮登录](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-unionid-login-button)
- [API参考：LoginWithHuaweiIDButton](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-huawei-id-button)
- [API参考：loginComponentManager](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-component-manager)
- [API参考：获取用户级凭证](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-obtain-user-token)
- [API参考：解析凭证接口](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-get-token-info)
- [开发准备：配置签名和指纹](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-sign-fingerprints)
- [开发准备：配置Client ID](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-client-id)

## 完整示例代码

- [ArkTS示例：基础登录按钮](assets/example_basic_login_button.ets)
- [ArkTS示例：自定义样式按钮](assets/example_custom_style_button.ets)
- [ArkTS示例：协议处理](assets/example_agreement_handling.ets)
- [ArkTS示例：错误处理](assets/example_error_handling.ets)

## 测试用例

### 正向测试用例
- [测试：正常登录流程](tests/test_positive_login.ets) - 用户正常点击登录按钮并成功获取Authorization Code
- [测试：协议同意后登录](tests/test_positive_agreement.ets) - 用户同意协议后成功登录
- [测试：自定义样式](tests/test_positive_custom_style.ets) - 自定义按钮样式正常显示

### 边界测试用例
- [测试：最小按钮高度](tests/test_boundary_min_height.ets) - 测试最小按钮高度40vp
- [测试：最大边框圆角](tests/test_boundary_max_radius.ets) - 测试最大边框圆角50vp
- [测试：API版本兼容](tests/test_boundary_api_version.ets) - 测试不同API版本的兼容性

### 异常测试用例
- [测试：网络错误](tests/test_exception_network_error.ets) - 模拟网络错误场景
- [测试：账号未登录](tests/test_exception_account_logout.ets) - 华为账号未登录场景
- [测试：用户取消授权](tests/test_exception_user_cancel.ets) - 用户取消授权场景
- [测试：参数错误](tests/test_exception_parameter_error.ets) - 参数类型错误场景
