---
name: hmos-account-kit-quick-phonenumber-verification
description: 快速验证华为账号用户手机号,通过客户端授权申请获取Authorization Code,服务端使用Code换取Access Token并获取用户手机号,仅首次需要用户授权,适用于用户注册、身份验证、账号关联场景
---

# 快速验证手机号技能

## 功能描述

本技能实现华为账号手机号快速验证功能。当应用对手机号时效性要求不高时,通过Account Kit提供的手机号授权与快速验证能力,向用户发起手机号授权申请,经用户同意后获取到手机号。支持获取华为账号绑定的手机号或用户新增的手机号,整个流程包含客户端授权和服务端信息获取两个阶段。

**关键特性**:
- 不保证实时验证,仅首次需要用户授权
- 支持获取华为账号绑定手机号或新增手机号
- 需提前申请phone scope权限
- Wearable设备不支持获取手机号功能
- 儿童账号手机号无法通过此方式获取

## 使用场景

### 触发词
- "快速验证手机号"
- "获取用户手机号"
- "手机号授权"
- "Account Kit手机号"
- "华为账号手机号验证"

### 能做
- 向用户发起华为账号手机号授权申请
- 获取华为账号绑定的手机号
- 获取用户选择授权的其他手机号
- 获取用户的OpenID和UnionID
- 完成客户端Authorization Code获取
- 完成服务端Access Token和手机号获取

### 绝不做
- 不提供实时手机号验证(需要使用一键登录场景)
- 不获取儿童账号的手机号
- 不在Wearable设备上获取手机号
- 不获取海外账号的手机号(Wearable设备)
- 不替代实时验证手机号Button组件
- 不在没有申请phone scope权限时获取手机号

### 补充
- 仅首次需要用户授权,后续授权自动通过
- Authorization Code有效期5分钟,只能使用一次
- Access Token有效期60分钟
- Refresh Token有效期180天
- 需完成开发准备(签名、指纹、权限申请)
- 需要设备已登录华为账号

## 调用规范和规则

### 输入约束
- 应用必须完成开发准备(签名、指纹配置)
- 必须申请phone scope权限
- 设备必须登录华为账号
- Authorization Code:最大长度1024字符,有效期5分钟
- Access Token:有效期60分钟
- Refresh Token:有效期180天

### 执行约束
- 最大耗时:客户端授权30秒,服务端获取10秒
- Authorization Code只能使用一次
- Access Token过期需使用Refresh Token刷新或重新授权
- 网络请求需使用TLS1.2协议及规定加密套件

### 内容约束
- 禁止伪造或篡改Authorization Code
- 禁止在客户端直接使用Access Token获取手机号(需服务端处理)
- 禁止使用硬编码的Client Secret
- 禁止使用已过期的Authorization Code
- 禁止跳过用户授权流程

### 降级约束
- 网络失败:提示用户检查网络并重试
- Authorization Code过期:重新发起授权申请
- Access Token失效:使用Refresh Token刷新或重新授权
- 用户未登录华为账号:引导用户登录华为账号
- 权限未申请:提示开发者完成phone scope权限申请
- 用户取消授权:提供其他登录方式

## 调用流程和步骤

### 步骤1:准备阶段

**前置校验**:
1. 验证应用已完成签名和指纹配置
2. 验证已在AppGallery Connect申请phone scope权限
3. 验证设备已登录华为账号
4. 准备Client ID和Client Secret(服务端)

**参数准备**:
```typescript
// 客户端参数
const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
authRequest.scopes = ['phone']; // 必须申请phone scope权限
authRequest.permissions = ['serviceauthcode']; // 获取Authorization Code
authRequest.forceAuthorization = true; // 强制拉起授权页
authRequest.state = util.generateRandomUUID(); // 防止跨站攻击
```

```java
// 服务端参数
String clientId = "<Client ID>"; // 从AGC获取
String clientSecret = "<Client Secret>"; // 从AGC获取
String code = "<Authorization Code>"; // 从客户端获取
String grantType = "authorization_code"; // 授权码模式
```

### 步骤2:客户端授权获取Authorization Code

**示例代码**:
```typescript
import { authentication } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

// 创建授权请求
const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
authRequest.scopes = ['phone']; // 获取手机号需要phone scope
authRequest.permissions = ['serviceauthcode']; // 获取Authorization Code
authRequest.forceAuthorization = true;
authRequest.state = util.generateRandomUUID(); // 建议使用generateRandomUUID

// 执行授权请求
try {
  const controller = new authentication.AuthenticationController(this.getUIContext().getHostContext());
  controller.executeRequest(authRequest).then((data) => {
    const authorizationWithHuaweiIDResponse = data as authentication.AuthorizationWithHuaweiIDResponse;
    const state = authorizationWithHuaweiIDResponse.state;
    
    // 校验state防止跨站攻击
    if (state && authRequest.state !== state) {
      hilog.error(0x0000, 'testTag', `Failed to authorize. The state is different`);
      return;
    }
    
    hilog.info(0x0000, 'testTag', 'Succeeded in authentication.');
    const authorizationWithHuaweiIDCredential = authorizationWithHuaweiIDResponse?.data;
    const authorizationCode = authorizationWithHuaweiIDCredential?.authorizationCode;
    
    // 将authorizationCode传给应用服务端处理
    // ...
  }).catch((err: BusinessError) => {
    dealAllError(err);
  });
} catch (error) {
  dealAllError(error);
}
```

**错误处理**:
```typescript
function dealAllError(error: BusinessError): void {
  hilog.error(0x0000, 'testTag', `Failed to obtain phone number. Code: ${error.code}, message: ${error.message}`);
  
  if (error.code === 1001502001) {
    // 用户未登录华为账号,请登录华为账号并重试
  } else if (error.code === 1001502005) {
    // 网络错误,请检查当前网络状态并重试
  } else if (error.code === 1001502012) {
    // 用户取消授权
  } else if (error.code === 12300001) {
    // 系统服务异常,请稍后重试
  } else if (error.code === 1001500002) {
    // 重复请求,应用无需处理
  } else if (error.code === 1001500001) {
    // 应用指纹证书校验失败,请检查签名和指纹配置
  } else if (error.code === 1001502014) {
    // 应用未申请scopes或permissions权限,请完成权限申请
  } else {
    // 获取手机号失败,请尝试使用其他方式登录
  }
}
```

### 步骤3:服务端获取Access Token

**示例代码**:
```java
import com.alibaba.fastjson2.JSONObject;
import org.apache.http.NameValuePair;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.message.BasicNameValuePair;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class UserTokenAPIDemo {
    public static JSONObject getTokenByCode(String code, String clientSecret, String clientId) throws IOException {
        String url = "https://oauth-login.cloud.huawei.com/oauth2/v3/token";
        String grantType = "authorization_code";
        
        HttpPost httpPost = new HttpPost(url);
        List<NameValuePair> request = new ArrayList<>();
        request.add(new BasicNameValuePair("code", code));
        request.add(new BasicNameValuePair("client_secret", clientSecret));
        request.add(new BasicNameValuePair("client_id", clientId));
        request.add(new BasicNameValuePair("grant_type", grantType));
        request.add(new BasicNameValuePair("supportAlg", "PS256"));
        
        httpPost.setHeader("Content-Type", "application/x-www-form-urlencoded");
        httpPost.setEntity(new UrlEncodedFormEntity(request));
        
        return CallUtils.toJsonObject(CallUtils.remoteCallOAuth(httpPost));
    }
}
```

### 步骤4:服务端获取用户手机号

**示例代码**:
```java
import com.alibaba.fastjson2.JSONObject;
import org.apache.http.NameValuePair;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.message.BasicNameValuePair;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class GetUserMobileDemo {
    public static JSONObject getUserPhoneNumber(String accessToken) throws IOException {
        String url = "https://account.cloud.huawei.com/rest.php?nsp_svc=GOpen.User.getInfo";
        
        HttpPost httpPost = new HttpPost(url);
        List<NameValuePair> request = new ArrayList<>();
        request.add(new BasicNameValuePair("access_token", accessToken));
        
        httpPost.setHeader("Content-Type", "application/x-www-form-urlencoded");
        httpPost.setEntity(new UrlEncodedFormEntity(request));
        
        return CallUtils.toJsonObject(CallUtils.remoteCall(httpPost));
    }
    
    public static void parseUserInfo(JSONObject result) {
        String openID = result.getString("openID");
        String unionID = result.getString("unionID");
        String mobileNumber = result.getString("mobileNumber");
        String purePhoneNumber = result.getString("purePhoneNumber");
        String phoneCountryCode = result.getString("phoneCountryCode");
        
        // 处理手机号信息
        // ...
    }
}
```

### 步骤5:Access Token过期处理

**降级处理**:
```java
// 使用Refresh Token刷新Access Token
public class RefreshTokenDemo {
    public static JSONObject refreshAccessToken(String refreshToken, String clientId, String clientSecret) throws IOException {
        String url = "https://oauth-login.cloud.huawei.com/oauth2/v3/token";
        String grantType = "refresh_token";
        
        HttpPost httpPost = new HttpPost(url);
        List<NameValuePair> request = new ArrayList<>();
        request.add(new BasicNameValuePair("refresh_token", refreshToken));
        request.add(new BasicNameValuePair("client_id", clientId));
        request.add(new BasicNameValuePair("client_secret", clientSecret));
        request.add(new BasicNameValuePair("grant_type", grantType));
        
        httpPost.setHeader("Content-Type", "application/x-www-form-urlencoded");
        httpPost.setEntity(new UrlEncodedFormEntity(request));
        
        return CallUtils.toJsonObject(CallUtils.remoteCallOAuth(httpPost));
    }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1001500001 | 应用指纹证书校验失败 | 检查应用签名和指纹配置是否正确 |
| 1001500002 | 重复请求 | 应用无需处理 |
| 1001500003 | 不支持该scopes或permissions | Wearable设备不支持获取手机号 |
| 1001502001 | 用户未登录华为账号 | 引导用户登录华为账号并重试 |
| 1001502003 | 输入参数值无效 | 检查scopes和permissions参数 |
| 1001502005 | 网络错误 | 检查网络状态并重试 |
| 1001502009 | 内部错误 | 系统内部错误,稍后重试 |
| 1001502012 | 用户取消授权 | 提供其他登录方式 |
| 1001502014 | 应用未申请scopes或permissions权限 | 完成phone scope权限申请 |
| 12300001 | 系统服务异常 | 系统服务异常,稍后重试 |
| 20155 | Authorization Code过期 | Code有效期5分钟,需重新授权获取 |
| 20156 | Authorization Code已使用 | Code只能使用一次,需重新获取 |
| 20158 | Authorization Code失效 | 用户修改密码或取消授权导致Code失效 |
| NSP_STATUS=6 | Access Token无效或过期 | 使用Refresh Token刷新或重新授权 |
| NSP_STATUS=105 | 参数错误 | 检查请求参数是否符合规范 |
| NSP_STATUS=403 | 访问无权限 | 在AGC申请phone scope权限 |

## 编译和修复问题

### 依赖声明

**客户端ArkTS依赖**:
```json
{
  "dependencies": {
    "@kit.AccountKit": "系统Kit",
    "@kit.PerformanceAnalysisKit": "系统Kit",
    "@kit.ArkTS": "系统Kit",
    "@kit.BasicServicesKit": "系统Kit"
  }
}
```

**服务端Java依赖**:
```xml
<dependencies>
    <dependency>
        <groupId>com.alibaba.fastjson2</groupId>
        <artifactId>fastjson2</artifactId>
        <version>2.0.23</version>
    </dependency>
    <dependency>
        <groupId>org.apache.httpcomponents</groupId>
        <artifactId>httpclient</artifactId>
        <version>4.5.13</version>
    </dependency>
</dependencies>
```

### 环境要求
- HarmonyOS API版本: 4.0.0(10)及以上
- 元服务支持: 5.0.0(12)及以上
- Java环境: JDK 8及以上
- 网络协议: TLS1.2及规定加密套件

### 常见编译问题

**问题1:导入模块失败**
```
Error: Cannot find module '@kit.AccountKit'
```
**解决方法**:确保项目配置正确引入系统Kit,检查build-profile.json5配置

**问题2:Context对象获取失败**
```
Error: Cannot get UIContext or HostContext
```
**解决方法**:确保在自定义组件实例中调用,使用`this.getUIContext().getHostContext()`

**问题3:网络请求失败**
```
Error: TLS protocol version mismatch
```
**解决方法**:确保使用TLS1.2协议及规定加密套件

**问题4:权限未申请错误**
```
Error: 1001502014 应用未申请scopes或permissions权限
```
**解决方法**:在AppGallery Connect申请phone scope权限

## 常见问题与解决方法

### Q1:如何申请phone scope权限?
**原因**:获取手机号前必须申请phone scope权限
**解决方法**:
- 登录AppGallery Connect
- 找到应用配置
- 申请"获取您的手机号"权限
- 等待审批通过

### Q2:Authorization Code过期怎么办?
**原因**:Authorization Code有效期5分钟
**解决方法**:
- 重新调用客户端授权接口获取新的Authorization Code
- 及时将Code传给服务端处理

### Q3:Access Token过期如何处理?
**原因**:Access Token有效期60分钟
**解决方法**:
- 使用Refresh Token刷新Access Token
- Refresh Token过期则重新授权

### Q4:用户未登录华为账号怎么办?
**原因**:设备未登录华为账号
**解决方法**:
- 设置forceAuthorization=true自动拉起登录页
- 或提示用户手动登录华为账号

### Q5:儿童账号无法获取手机号?
**原因**:儿童账号的手机号无法通过phone scope获取
**解决方法**:
- 使用其他身份验证方式
- 或引导家长账号授权

### Q6:Wearable设备无法获取手机号?
**原因**:Wearable设备不支持获取手机号功能
**解决方法**:
- 使用其他设备类型获取手机号
- 或使用一键登录场景(如果支持)

### Q7:如何处理手机号格式?
**原因**:不同地区手机号格式不同
**解决方法**:
- 中国境内:直接返回手机号(如11136000008)
- 其他地区:国际冠码+国际电话区号+手机号(如0085261234567)
- 使用purePhoneNumber和phoneCountryCode字段解析

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "authorizationCode": "获取的Authorization Code(客户端)",
  "accessToken": "获取的Access Token(服务端)",
  "refreshToken": "获取的Refresh Token(服务端)",
  "openID": "用户OpenID",
  "unionID": "用户UnionID",
  "mobileNumber": "用户授权的手机号",
  "purePhoneNumber": "不带国际冠码的手机号",
  "phoneCountryCode": "国际电话区号",
  "apiUsed": [
    "createAuthorizationWithHuaweiIDRequest",
    "AuthenticationController.constructor",
    "executeRequest",
    "获取用户级凭证接口",
    "获取用户信息接口"
  ]
}
```

## 参考文档

- [API开发指南-快速验证](references/account-get-phonenumber.md)
- [API参考-Authentication](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-authentication)
- [API参考-获取用户级凭证](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-obtain-user-token)
- [API参考-获取用户手机号](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-get-user-info-get-phone)
- [开发准备-申请账号权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-config-permissions)
- [快速验证手机号Button](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scenario-fusion-button-getphonenumber)
- [OpenID和UnionID格式说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-faq-9)
- [应用指纹证书校验失败](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-faq-1)
- [应用未申请权限错误](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-faq-2)

## 完整示例代码

- [ArkTS客户端示例](assets/example_client.ets)
- [Java服务端示例](assets/example_server.java)
- [配置文件示例](assets/config.json)

## 测试用例

### 正向测试用例
- [正常获取手机号](tests/test_positive.ts):用户已登录,已授权,获取手机号成功
- [首次授权获取手机号](tests/test_first_authorization.ts):首次授权后获取手机号
- [使用Refresh Token刷新](tests/test_refresh_token.java):Access Token过期后刷新

### 边界测试用例
- [Authorization Code过期](tests/test_code_expired.java):Code超过5分钟过期
- [Authorization Code重复使用](tests/test_code_reuse.java):Code已使用,再次使用失败
- [Access Token过期](tests/test_token_expired.java):Token超过60分钟过期

### 异常测试用例
- [用户未登录](tests/test_user_not_login.ts):设备未登录华为账号
- [用户取消授权](tests/test_user_cancel.ts):用户取消授权操作
- [网络异常](tests/test_network_error.ts):网络连接失败
- [权限未申请](tests/test_permission_not_applied.ts):未申请phone scope权限
- [应用指纹校验失败](tests/test_fingerprint_failed.ts):签名或指纹配置错误