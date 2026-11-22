---
name: hmos-account-kit-get-risklevel-by-quicklogin
description: 通过华为账号一键登录获取用户风险等级,支持Phone/Tablet/PC/2in1/TV/Car设备,需申请riskLevel scope权限,适用于应用登录风控场景
---

# 通过华为账号一键登录获取用户风险等级技能

## 功能描述

本技能提供通过华为账号一键登录获取用户风险等级的能力,帮助应用在登录场景进行风控判断。支持获取用户的风险等级(0-4级)和风险标签,应用可根据风险等级采取相应的风控措施。

**核心能力**:
- 客户端集成华为账号一键登录按钮,设置riskLevel参数标识
- 服务端通过Authorization Code换取Access Token
- 服务端调用REST API获取用户风险等级和风险标签
- 提供完整的错误码处理和降级方案

**适用设备**: Phone、Tablet、PC/2in1设备(从5.1.1(19)版本开始支持TV,从26.0.0版本开始支持Car)

## 使用场景

### 触发词
- "华为账号一键登录获取风险等级"
- "获取用户风险等级"
- "应用登录风控"
- "风险等级查询"
- "Account Kit riskLevel"

### 能做
- 通过华为账号一键登录获取用户风险等级(0-4级)
- 获取用户风险标签(垃圾邮箱、卡商手机号、风险设备等)
- 应用服务端通过REST API查询用户风险等级
- 提供完整的风控决策建议

### 绝不做
- 不支持用户非首次登录应用的风险等级获取(需使用其他方式登录获取风险等级技能)
- 不支持未申请riskLevel scope权限的应用
- 不支持未登录华为账号的设备
- 不直接拦截用户登录(仅提供风险等级供应用判断)

### 补充
- 需完成开发准备工作,包括申请riskLevel scope权限
- Authorization Code有效期5分钟,仅可使用一次
- Access Token有效期60分钟,Refresh Token有效期180天
- 需要应用服务端配合调用REST API

## 调用规范和规则

### 输入约束
- **Authorization Code**: 长度1-1024字符,有效期5分钟
- **Access Token**: 通过Authorization Code获取,有效期60分钟
- **Client ID**: 由AGC分配的唯一标识,格式^[0-9]{1,64}$
- **Client Secret**: 由AGC分配的密钥
- **scene**: 业务场景参数,可选值"registration"(注册)或"marketing"(营销活动)
- **transactionID**: 交易流水号,格式YYYYMMDDhhmmssxxxxxxxxxx(14位时间+10-20位随机数)

### 执行约束
- 最大耗时: 客户端获取匿名手机号建议设置5秒超时
- API调用频次: Authorization Code仅可使用一次
- 最大迭代次数: Access Token过期后使用Refresh Token刷新,最多刷新1次

### 内容约束
- 禁止生成: 禁止生成虚假的风险等级数据
- 禁止使用高危函数: 禁止使用未加密的HTTP传输,必须使用TLS1.2及以上协议
- 禁止操作: 禁止跳过权限申请直接调用接口

### 降级约束
- 网络失败: 提示用户检查网络并重试,或使用其他登录方式
- Authorization Code失效: 引导用户重新授权获取新的Code
- Access Token过期: 使用Refresh Token刷新,若Refresh Token也过期则重新授权
- 权限未申请: 提示开发者前往AGC申请riskLevel scope权限

## 调用流程和步骤

### 步骤1: 客户端准备阶段

**前置校验**:
1. 检查设备是否已登录华为账号
2. 检查应用是否已申请riskLevel scope权限
3. 检查网络连接状态

**参数准备**:
```typescript
import { authentication } from '@kit.AccountKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function getQuickLoginAnonymousPhone(): Promise<string> {
    const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
    authRequest.scopes = ['quickLoginAnonymousPhone'];
    authRequest.state = util.generateRandomUUID();
    authRequest.forceAuthorization = false;
    
    const controller = new authentication.AuthenticationController();
    let quickLoginAnonymousPhone: string = '';
    
    try {
        await controller.executeRequest(authRequest)
            .then((response: authentication.AuthorizationWithHuaweiIDResponse) => {
                quickLoginAnonymousPhone = response.data?.extraInfo?.quickLoginAnonymousPhone as string;
                if (quickLoginAnonymousPhone) {
                    hilog.info(0x0000, 'testTag', 'Succeeded in getting anonymous phone.');
                }
            })
            .catch((error: BusinessError) => {
                hilog.error(0x0000, 'testTag', `Failed to get anonymous phone: ${error.code}`);
            });
        return quickLoginAnonymousPhone;
    } catch (error) {
        hilog.error(0x0000, 'testTag', 'Exception in getting anonymous phone.');
        return quickLoginAnonymousPhone;
    }
}
```

### 步骤2: 客户端集成一键登录按钮

**示例代码**:
```typescript
import { loginComponentManager, LoginWithHuaweiIDButton } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Component
struct QuickLoginButtonComponent {
    @State quickLoginAnonymousPhone: string = '';
    @State isSelected: boolean = false;
    
    controller: loginComponentManager.LoginWithHuaweiIDButtonController =
        new loginComponentManager.LoginWithHuaweiIDButtonController()
            .setAgreementStatus(loginComponentManager.AgreementStatus.NOT_ACCEPTED)
            .onClickLoginWithHuaweiIDButton((error: BusinessError | undefined,
                response: loginComponentManager.HuaweiIDCredential) => {
                if (error) {
                    hilog.error(0x0000, 'testTag', `Login failed: ${error.code}`);
                    return;
                }
                if (response) {
                    const authCode = response.authorizationCode;
                    hilog.info(0x0000, 'testTag', `Got Authorization Code: ${authCode}`);
                }
            })
            .onClickEvent((error: BusinessError, clickEvent: loginComponentManager.ClickEvent) => {
                if (error) {
                    hilog.error(0x0000, 'testTag', `Click event error: ${error.code}`);
                    return;
                }
                hilog.info(0x0000, 'testTag', `Button clicked.`);
                this.controller.setEnabled(false);
            });
    
    build() {
        Column() {
            LoginWithHuaweiIDButton({
                params: {
                    style: loginComponentManager.Style.BUTTON_RED,
                    extraStyle: {
                        buttonStyle: new loginComponentManager.ButtonStyle().loadingStyle({
                            show: true
                        })
                    },
                    borderRadius: 24,
                    loginType: loginComponentManager.LoginType.QUICK_LOGIN,
                    supportDarkMode: true,
                    verifyPhoneNumber: true,
                    riskLevel: true,  // 设置风险等级标识为true
                },
                controller: this.controller
            })
        }
        .height(40)
        .width('100%')
    }
}
```

### 步骤3: 服务端获取Access Token

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

public class GetAccessTokenDemo {
    public static JSONObject getAccessToken(String code, String clientId, String clientSecret) throws IOException {
        String url = "https://oauth-login.cloud.huawei.com/oauth2/v3/token";
        String grantType = "authorization_code";
        
        HttpPost httpPost = new HttpPost(url);
        List<NameValuePair> request = new ArrayList<>();
        request.add(new BasicNameValuePair("code", code));
        request.add(new BasicNameValuePair("client_secret", clientSecret));
        request.add(new BasicNameValuePair("client_id", clientId));
        request.add(new BasicNameValuePair("grant_type", grantType));
        
        httpPost.setHeader("Content-Type", "application/x-www-form-urlencoded");
        httpPost.setEntity(new UrlEncodedFormEntity(request));
        
        JSONObject result = CallUtils.toJsonObject(CallUtils.remoteCallOAuth(httpPost));
        return result;
    }
}
```

### 步骤4: 服务端获取用户风险等级

**示例代码**:
```java
import com.alibaba.fastjson2.JSONArray;
import com.alibaba.fastjson2.JSONObject;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpPost;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

public class GetUserRiskLevelDemo {
    public static JSONObject getUserRiskLevel(String accessToken, String clientID, 
        String transactionID, String scene) throws IOException {
        String url = "https://account.cloud.huawei.com/user/getuserrisklevel";
        
        HttpPost httpPost = new HttpPost(url + "?" + "clientID=" + clientID + "&transactionID=" + transactionID);
        Map<String, String> reqBody = new HashMap<>();
        reqBody.put("accessToken", accessToken);
        reqBody.put("scene", scene);
        
        httpPost.setHeader("Content-Type", "application/json;charset=utf-8");
        httpPost.setEntity(CallUtils.wrapJsonEntity(reqBody));
        
        return CallUtils.toJsonObject(CallUtils.remoteCall(httpPost, (CloseableHttpResponse response, String rawBody) -> {
            int statusCode = response.getStatusLine().getStatusCode();
            if (statusCode != 200) {
                return new IOException("HTTP status code: " + statusCode + ", response: " + rawBody);
            }
            
            JSONObject errorResponseBody = CallUtils.toJsonObject(rawBody);
            Integer errCode = errorResponseBody.getInteger("errCode");
            if (Objects.nonNull(errCode) && errCode != 0) {
                return new IOException("Business error code: " + errCode + ", response: " + rawBody);
            }
            return null;
        }));
    }
    
    public static void main(String[] args) throws IOException {
        String accessToken = "<Access Token>";
        String clientID = "<Client ID>";
        String transactionID = "20260704121800123456789";
        String scene = "registration";
        
        JSONObject result = getUserRiskLevel(accessToken, clientID, transactionID, scene);
        Integer errCode = result.getInteger("errCode");
        String errMsg = result.getString("errMsg");
        Integer riskLevel = result.getInteger("riskLevel");
        JSONArray riskTag = result.getJSONArray("riskTag");
        
        System.out.println("Risk Level: " + riskLevel);
        System.out.println("Risk Tags: " + riskTag);
    }
}
```

### 步骤5: 错误处理

**客户端错误处理**:
```typescript
dealAllError(error: BusinessError): void {
    hilog.error(0x0000, 'testTag', `Error: ${error.code}, Message: ${error.message}`);
    
    if (error.code === 1001502001) {
        // 用户未登录华为账号,请登录华为账号并重试
    } else if (error.code === 1001502005) {
        // 网络异常,请检查当前网络状态并重试
    } else if (error.code === 1001502009) {
        // 登录失败,请尝试使用其他方式登录
    } else if (error.code === 1001502012) {
        // 用户取消授权
    } else if (error.code === 12300001) {
        // 系统服务异常,请稍后重试
    } else if (error.code === 1001502014) {
        // 应用未申请scopes或permissions权限
    } else {
        // 应用登录失败,请尝试使用其他方式登录
    }
}
```

**服务端错误处理**:
```java
public static void handleRiskLevelError(Integer errCode, String errMsg) {
    switch (errCode) {
        case 6:
            // Access Token无效或已过期,请重新获取
            break;
        case 403:
            // 无权访问,请前往AGC申请riskLevel scope权限
            break;
        case 503:
            // 触发系统流控,请稍后重试
            break;
        case 70001201:
            // 请求参数错误,请检查参数格式
            break;
        case 70001402:
            // 系统鉴权错误,请通过在线提单提交问题
            break;
        case 70020002:
            // 接口内部超时,请稍后重试
            break;
        default:
            // 其他错误,请根据errMsg进行处理
            break;
    }
}
```

### 步骤6: Access Token过期处理

```java
public static JSONObject refreshAccessToken(String refreshToken, String clientId, String clientSecret) throws IOException {
    String url = "https://oauth-login.cloud.huawei.com/oauth2/v3/token";
    String grantType = "refresh_token";
    
    HttpPost httpPost = new HttpPost(url);
    List<NameValuePair> request = new ArrayList<>();
    request.add(new BasicNameValuePair("refresh_token", refreshToken));
    request.add(new BasicNameValuePair("client_secret", clientSecret));
    request.add(new BasicNameValuePair("client_id", clientId));
    request.add(new BasicNameValuePair("grant_type", grantType));
    
    httpPost.setHeader("Content-Type", "application/x-www-form-urlencoded");
    httpPost.setEntity(new UrlEncodedFormEntity(request));
    
    return CallUtils.toJsonObject(CallUtils.remoteCallOAuth(httpPost));
}
```

## 错误码说明

### 客户端错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1001502001 | 用户未登录华为账号 | 提示用户登录华为账号或使用其他登录方式 |
| 1001502005 | 网络错误 | 提示用户检查网络状态并重试 |
| 1001502009 | 内部错误 | 使用其他登录方式 |
| 1001502012 | 用户取消授权 | 无需特别处理 |
| 12300001 | 系统服务异常 | 提示用户稍后重试或使用其他登录方式 |
| 1001502014 | 应用未申请scopes或permissions权限 | 前往AGC申请riskLevel scope权限 |
| 1001500001 | 应用指纹证书校验失败 | 配置签名和指纹证书 |
| 1001500002 | 重复请求 | 应用无需处理 |
| 1001500003 | 不支持该scopes或permissions | 检查用户注册地或使用其他登录方式 |
| 1005300001 | 用户未同意协议 | 引导用户同意协议 |

### 服务端错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 6 | Access Token无效或已过期 | 使用Refresh Token刷新或重新授权 |
| 403 | 无权访问 | 前往AGC申请riskLevel scope权限 |
| 503 | 触发系统流控 | 稍后重试 |
| 70001201 | 请求参数错误 | 检查URL和请求体参数 |
| 70001402 | 系统鉴权错误 | 通过在线提单提交问题 |
| 70020002 | 接口内部超时 | 稍后重试 |
| 70001401 | 接口内部错误 | 根据错误描述处理或在线提单 |

### HTTP错误码

| HTTP状态码 | 说明 | 解决方法 |
|-----------|------|---------|
| 400 | 参数错误 | 根据业务响应错误码进一步排查 |
| 403 | 无权限访问 | 检查网络环境配置 |
| 404 | 找不到服务 | 检查请求URI是否正确 |
| 405 | 不支持的HTTP请求method | 检查HTTP请求method |
| 500 | 服务内部错误 | 通过在线提单提交问题 |
| 502 | 请求连接异常 | 稍后重试或在线提单 |
| 504 | 请求连接超时 | 稍后重试或在线提单 |
| 590 | 服务内部错误 | 通过在线提单提交问题 |

## 编译和修复问题

### 依赖声明

**客户端ArkTS依赖**:
```json
{
  "dependencies": {
    "@kit.AccountKit": "latest",
    "@kit.ArkTS": "latest",
    "@kit.PerformanceAnalysisKit": "latest",
    "@kit.BasicServicesKit": "latest"
  }
}
```

**服务端Java依赖**:
```xml
<dependencies>
    <dependency>
        <groupId>com.alibaba.fastjson2</groupId>
        <artifactId>fastjson2</artifactId>
        <version>2.0.43</version>
    </dependency>
    <dependency>
        <groupId>org.apache.httpcomponents</groupId>
        <artifactId>httpclient</artifactId>
        <version>4.5.14</version>
    </dependency>
</dependencies>
```

### 环境要求
- HarmonyOS API版本: 5.1.0(18)及以上
- Java版本: JDK 8及以上
- TLS协议: TLS1.2及以上

### 常见编译问题

**问题1: 未配置混淆白名单导致匿名手机号被混淆**
```
quickLoginAnonymousPhone属性被混淆,无法获取值
```
**解决方法**: 在obfuscation-rules.txt中添加:
```
-enable-property-obfuscation
-keep-property-name
quickLoginAnonymousPhone
```

**问题2: 未申请riskLevel scope权限导致调用失败**
```
错误码1001502014: 应用未申请scopes或permissions权限
```
**解决方法**: 发送邮件至accountkit@huawei.com申请riskLevel scope权限,邮件模板:
```
邮件主题: 【获取风险等级】权限申请
邮件正文: 申请riskLevel scope权限
企业名称: ***
应用名称: ***
应用包名: com.***.***
APP ID: ***
Client ID: ***
背景介绍: ***
使用场景: ***
使用该权限的必要性: ***
```

**问题3: Access Token过期导致查询失败**
```
错误码6: Access Token无效或已过期
```
**解决方法**: 使用Refresh Token刷新Access Token,若Refresh Token也过期则引导用户重新授权

## 常见问题与解决方法

### Q1: 如何判断用户风险等级的含义?

**风险等级含义**:
- **0级(未发现显著风险)**: 建议确认无风险后放通
- **1级(低风险)**: 建议进行简单验证(如验证码、短信等),或人工审核
- **2级(中风险)**: 建议根据业务场景采取一定措施规避伤害。例如,营销活动可降低高等级奖励的概率、打榜类活动对此类投票降低权重、登录注册要求二次验证等
- **3级(高风险)**: 建议业务逻辑直接拦截。例如,红包类活动返回不中奖或最小额红包、打榜类活动不计算票数、登录/注册操作要求二次验证、高危业务可选择限制本次操作
- **4级(风险未知)**: 建议结合账号历史行为及业务场景做出最终决策

### Q2: 如何处理Access Token和Refresh Token过期?

**解决方法**:
1. Access Token有效期为60分钟,过期后使用Refresh Token刷新
2. Refresh Token有效期为180天,过期后需要重新授权获取新的Authorization Code
3. 当用户修改密码、退出账号、删除设备时,Access Token和Refresh Token会提前失效,需重新授权

### Q3: 如何处理用户非首次登录的风险等级查询?

**解决方法**: 
本技能仅支持用户首次登录应用时获取风险等级。若用户非首次登录,请使用"华为账号其他方式登录获取用户风险等级"技能。

### Q4: 风险标签有哪些类型?

**风险标签说明**:
- **spamMailbox**: 绑定垃圾邮箱
- **riskPhoneNumber**: 绑定卡商手机号
- **riskDevice**: 使用风险设备(自动机、群控等)
- **ipCluster**: IP聚集(半年内存在IP聚集性异常)
- **deviceCluster**: 设备聚集(半年内存在设备聚集性异常)
- **batchBehavior**: 批量操作(与大量垃圾账号存在批量协同行为)
- **illegalLogin**: 非法登录
- **activityFraud**: 恶意行为-薅羊毛

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "riskLevel": 2,
  "riskTag": ["spamMailbox", "ipCluster"],
  "riskLevelMeaning": "中风险,建议根据业务场景采取一定措施规避伤害",
  "suggestedAction": "营销活动可降低高等级奖励的概率、登录注册要求二次验证",
  "apiUsed": [
    "LoginWithHuaweiIDButton",
    "LoginWithHuaweiIDButtonParams",
    "/oauth2/v3/token",
    "/user/getuserrisklevel"
  ],
  "timestamp": "2026-07-04T12:18:00Z",
  "transactionID": "20260704121800123456789"
}
```

## 参考文档

- [通过华为账号一键登录获取用户风险等级开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-get-risklevel-byquicklogin)
- [华为账号一键登录开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-phone-unionid-login)
- [LoginWithHuaweiIDButton API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-huawei-id-button)
- [loginComponentManager API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-component-manager)
- [获取用户级凭证接口](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-obtain-user-token)
- [获取用户风险等级接口](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-getuserrisklevel)
- [获取华为账号用户信息概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-get-user-info-overview)
- [申请账号权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-config-permissions)

## 完整示例代码

- [ArkTS客户端示例](assets/quick_login_risklevel_client.ets)
- [Java服务端示例](assets/quick_login_risklevel_server.java)
- [完整流程示例](assets/complete_flow_demo.java)

## 测试用例

### 正向测试用例
- [获取低风险用户的风险等级](tests/test_low_risk_user.py): 验证风险等级为0或1的正常场景
- [获取中风险用户的风险等级](tests/test_medium_risk_user.py): 验证风险等级为2的场景
- [获取高风险用户的风险等级](tests/test_high_risk_user.py): 验证风险等级为3的场景

### 边界测试用例
- [Access Token即将过期](tests/test_access_token_expiring.py): 验证Access Token有效期边界处理
- [Refresh Token即将过期](tests/test_refresh_token_expiring.py): 验证Refresh Token有效期边界处理
- [Authorization Code有效期边界](tests/test_auth_code_expiry.py): 验证Authorization Code 5分钟有效期

### 异常测试用例
- [用户未登录华为账号](tests/test_user_not_logged_in.py): 验证错误码1001502001处理
- [网络异常](tests/test_network_error.py): 验证错误码1001502005处理
- [权限未申请](tests/test_permission_not_applied.py): 验证错误码1001502014处理
- [Access Token过期](tests/test_access_token_expired.py): 验证错误码6处理
- [请求参数错误](tests/test_invalid_parameters.py): 验证错误码70001201处理