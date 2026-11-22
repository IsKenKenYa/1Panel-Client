---
name: hmos-device-security-kit-deviceverify
description: 获取设备DeviceToken并查询/更新/删除设备标记状态，支持应用级和开发者级两种粒度，deviceToken有效期1小时，设备标记存储期限2年，适用于新用户营销、优惠券领取状态检测场景
---

# 应用设备状态检测技能

## 功能描述

本技能提供应用设备状态检测能力，通过Device Security Kit获取设备临时标识DeviceToken，应用服务器使用DeviceToken到Device Security服务器查询和管理应用在该设备的使用状态。支持2个bit的状态存储和查询能力，开发者可自行定义这2个bit的含义，用于判断应用是否在该设备上首次安装或用户是否已获取优惠券等状态检测，以支撑业务进行新用户营销活动。

**核心能力**：
- 客户端获取设备DeviceToken（ArkTS API）
- 服务端验证deviceToken合法性
- 服务端查询设备标记状态
- 服务端更新设备标记状态
- 服务端删除设备标记状态

**设备标记状态**：
- 每个设备的每个应用提供2个bit的状态存储
- bit0和bit1的具体含义由应用自行定义
- 支持应用级（mode=1）和开发者级（mode=2）两种粒度
- 开发者级的设备标记状态在同一开发者下的所有应用共享
- 设备标记状态记录的存储期限为2年

## 使用场景

### 触发词
- "获取DeviceToken"
- "设备状态检测"
- "新用户判断"
- "优惠券领取检测"
- "设备标记状态"
- "首次安装判断"
- "应用设备状态"
- "deviceToken验证"

### 能做
- 获取设备临时标识DeviceToken，有效期1小时
- 验证deviceToken合法性，确认设备为真实的华为设备
- 查询设备标记状态（bit0和bit1），判断设备是否被标记过
- 更新设备标记状态，设置bit0和bit1的值
- 删除设备标记状态，使标记在云端失效
- 支持应用级和开发者级两种粒度的设备标记管理
- 判断应用是否在该设备上首次安装
- 判断用户是否在该设备上已获取优惠券等福利

### 绝不做
- 不在模拟器上运行（仅支持真机）
- 不获取持久化设备标识（仅提供临时DeviceToken）
- 不处理超出2个bit的设备标记状态
- 不处理超过2年存储期限的设备标记状态
- 不支持未开通Device Security服务的应用
- 不支持未申请调试Profile的应用

### 补充
- 支持设备：Phone、Tablet、PC/2in1、Wearable（从5.0.0(12)版本），TV（从5.1.1(19)版本）
- 元服务API：从版本5.0.2(14)开始支持在元服务中使用getDeviceToken
- DeviceToken每次调用生成均不一样，有效期1小时
- 需要在AppGallery Connect开通"应用设备状态检测"开关
- 需要申请调试Profile文件
- 服务端需要基于服务账号生成鉴权令牌
- 当getDeviceToken接口无法获取DeviceToken时，需要考虑异常处理方案

## 调用规范和规则

### 输入约束
- DeviceToken有效期：1小时
- Timestamp精度：毫秒级UTC时间
- Mode取值范围：1（应用级）或2（开发者级）
- Bit值类型：Boolean（true或false）
- TransactionId：可选，应用服务的唯一事务标识
- BundleName：必需，开发者APP包名
- Authorization：必需，服务账号令牌

### 执行约束
- 最大重试次数：3次（网络不稳定场景）
- DeviceToken获取失败时必须提供降级方案
- 服务端API调用频次：建议不超过100次/分钟
- 网络请求超时：建议设置10秒超时
- 并发请求限制：建议不超过10个并发请求

### 内容约束
- 禁止使用过期DeviceToken
- 禁止在请求中包含特殊字符
- 禁止使用非Boolean类型的bit值
- 禁止在未开通服务的情况下调用API
- 禁止在模拟器上测试API
- 禁止硬编码DeviceToken或Authorization令牌
- 禁止在前端代码中暴露服务账号私钥

### 降级约束
- DeviceToken获取失败：重试3次，如仍失败则采用其他风控因子进行判断或提示用户稍后重试
- deviceToken过期：重新调用getDeviceToken获取新的DeviceToken
- 网络失败：提示用户检查网络连接，稍后重试
- 权限不足：检查是否开通服务和申请Profile，提示开发者进行配置
- NotFound错误：先调用setDeviceStatus更新标记，再查询状态
- InternalServerError：记录日志，通过在线提单申请帮助

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认已在AppGallery Connect开通"应用设备状态检测"开关
2. 确认已申请调试Profile文件（.p7b）
3. 确认服务端已配置服务账号密钥文件
4. 确认设备为真机（不支持模拟器）
5. 确认设备已联网且网络稳定

**客户端准备**：
```typescript
import { deviceCertificate } from '@kit.DeviceSecurityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'DeviceCertificate';
const DOMAIN = 0x0000;
```

**服务端准备**：
```java
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import com.alibaba.fastjson.JSONObject;

private static String authorization = "Bearer eyJraWQiOi...";  // 基于服务账号生成的鉴权令牌
private static String bundleName = "com.huawei.myapplication";  // Hap应用的包名
```

### 步骤2：客户端获取DeviceToken

**示例代码**：
```typescript
async function getDeviceToken(): Promise<string> {
  try {
    const token = await deviceCertificate.getDeviceToken();
    hilog.info(DOMAIN, TAG, 'Succeeded in getting deviceToken');
    return token;
  } catch (err) {
    let error: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, TAG, 'getDeviceToken failed! Code: %{public}d, Message: %{public}s', 
                error.code, error.message);
    throw error;
  }
}

async function handleBusinessWithDeviceToken(): Promise<void> {
  try {
    const token = await getDeviceToken();
    // 将deviceToken发送到应用服务器进行业务处理
    await sendTokenToServer(token);
  } catch (error) {
    // 降级处理：采用其他风控因子进行判断
    hilog.warn(DOMAIN, TAG, 'Fallback to alternative risk control method');
    await alternativeRiskControlMethod();
  }
}
```

**错误处理**：
```typescript
try {
  await handleBusinessWithDeviceToken();
} catch (error) {
  const businessError = error as BusinessError;
  switch (businessError.code) {
    case 201:
      hilog.error(DOMAIN, TAG, 'Permission denied. Please enable Device Security service in AGC.');
      break;
    case 1003300005:
      hilog.error(DOMAIN, TAG, 'Internal error. Retrying...');
      await retryGetDeviceToken();
      break;
    case 1003300006:
      hilog.error(DOMAIN, TAG, 'Network error. Please check device network connection.');
      break;
    default:
      hilog.error(DOMAIN, TAG, 'Unknown error: %{public}d', businessError.code);
  }
}
```

### 步骤3：服务端验证deviceToken

**示例代码**：
```java
public static void checkDeviceToken(String deviceToken) throws IOException {
    String url = "https://connect-api.cloud.huawei.com/api/rms/v1/deviceVerify/checkDeviceToken";
    URL obj = new URL(url);
    HttpURLConnection con = (HttpURLConnection) obj.openConnection();
    
    con.setRequestMethod("POST");
    con.setDoOutput(true);
    con.setRequestProperty("Content-Type", "application/json;charset=utf-8");
    con.setRequestProperty("Authorization", authorization);
    con.setRequestProperty("bundleName", bundleName);
    
    JSONObject data = new JSONObject();
    data.put("deviceToken", deviceToken);
    data.put("timestamp", System.currentTimeMillis());
    
    JSONObject postBody = new JSONObject();
    postBody.put("data", data);
    
    sendRequestAndReadResponse(con, postBody);
}
```

### 步骤4：服务端查询设备标记状态

**示例代码**：
```java
public static void getDeviceStatus(String deviceToken) throws IOException {
    String url = "https://connect-api.cloud.huawei.com/api/rms/v1/deviceVerify/getDeviceStatus";
    URL obj = new URL(url);
    HttpURLConnection con = (HttpURLConnection) obj.openConnection();
    
    con.setRequestMethod("POST");
    con.setDoOutput(true);
    con.setRequestProperty("Content-Type", "application/json;charset=utf-8");
    con.setRequestProperty("Authorization", authorization);
    con.setRequestProperty("bundleName", bundleName);
    
    JSONObject data = new JSONObject();
    data.put("mode", 1);  // 1:应用级, 2:开发者级
    data.put("deviceToken", deviceToken);
    data.put("timestamp", System.currentTimeMillis());
    
    JSONObject postBody = new JSONObject();
    postBody.put("data", data);
    
    String response = sendRequestAndReadResponse(con, postBody);
    
    JSONObject responseJson = JSONObject.parseObject(response);
    if (responseJson.getString("errorCodes").equals("OK")) {
        Boolean bit0 = responseJson.getBoolean("bit0");
        Boolean bit1 = responseJson.getBoolean("bit1");
        Long lastUpdateTime = responseJson.getLong("lastUpdateTime");
        
        System.out.println("bit0: " + bit0);
        System.out.println("bit1: " + bit1);
        System.out.println("lastUpdateTime: " + lastUpdateTime);
    }
}
```

### 步骤5：服务端更新设备标记状态

**示例代码**：
```java
public static void setDeviceStatus(String deviceToken, Boolean bit0, Boolean bit1) throws IOException {
    String url = "https://connect-api.cloud.huawei.com/api/rms/v1/deviceVerify/setDeviceStatus";
    URL obj = new URL(url);
    HttpURLConnection con = (HttpURLConnection) obj.openConnection();
    
    con.setRequestMethod("POST");
    con.setDoOutput(true);
    con.setRequestProperty("Content-Type", "application/json;charset=utf-8");
    con.setRequestProperty("Authorization", authorization);
    con.setRequestProperty("bundleName", bundleName);
    
    JSONObject data = new JSONObject();
    data.put("mode", 1);
    data.put("deviceToken", deviceToken);
    data.put("timestamp", System.currentTimeMillis());
    data.put("bit0", bit0);
    data.put("bit1", bit1);
    
    JSONObject postBody = new JSONObject();
    postBody.put("data", data);
    
    sendRequestAndReadResponse(con, postBody);
}
```

### 步骤6：服务端删除设备标记状态

**示例代码**：
```java
public static void delDeviceStatus(String deviceToken) throws IOException {
    String url = "https://connect-api.cloud.huawei.com/api/rms/v1/deviceVerify/delDeviceStatus";
    URL obj = new URL(url);
    HttpURLConnection con = (HttpURLConnection) obj.openConnection();
    
    con.setRequestMethod("POST");
    con.setDoOutput(true);
    con.setRequestProperty("Content-Type", "application/json;charset=utf-8");
    con.setRequestProperty("Authorization", authorization);
    con.setRequestProperty("bundleName", bundleName);
    
    JSONObject data = new JSONObject();
    data.put("mode", 1);
    data.put("deviceToken", deviceToken);
    data.put("timestamp", System.currentTimeMillis());
    
    JSONObject postBody = new JSONObject();
    postBody.put("data", data);
    
    sendRequestAndReadResponse(con, postBody);
}
```

### 步骤7：降级处理

**示例代码**：
```typescript
async function fallbackRiskControl(): Promise<void> {
  try {
    // 方案1：重新获取DeviceToken（最多重试3次）
    for (let i = 0; i < 3; i++) {
      try {
        const token = await getDeviceToken();
        await sendTokenToServer(token);
        return;
      } catch (error) {
        hilog.warn(DOMAIN, TAG, `Retry ${i + 1} failed`);
        if (i === 2) {
          throw error;
        }
      }
    }
  } catch (error) {
    // 方案2：采用其他风控因子进行判断
    hilog.info(DOMAIN, TAG, 'Using alternative risk control method');
    await alternativeRiskControlMethod();
  }
}

async function alternativeRiskControlMethod(): Promise<void> {
  // 使用其他风控因子，如IP地址、用户账号、设备型号等
  // 具体实现根据业务需求定制
  hilog.info(DOMAIN, TAG, 'Alternative method executed');
}
```

## 错误码说明

### ArkTS API错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限校验失败，应用hap未开通Device Security服务 | 在AppGallery Connect开启"应用设备状态检测"开关，重新申请调试Profile |
| 1003300005 | 内部异常，接口执行流程中调用系统其它接口出现异常 | 优先重试，若重试不成功请通过在线提单申请帮助 |
| 1003300006 | 访问云端服务器异常，设备未联网或网络不稳定 | 连接网络后重新发起请求，如联网则可能是网络不稳定，请重试 |

### REST API错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| OK | 请求处理成功 | 正常处理业务逻辑 |
| InvalidBundleName | bundleName缺失或不合法 | 检查请求header中是否携带bundleName，确保与getDeviceToken接口应用的bundleName一致 |
| InvalidDeviceToken | deviceToken缺失或不合法 | 检查请求参数中deviceToken字段是否缺失或包含特殊字符 |
| DeviceTokenExpired | deviceToken过期 | DeviceToken有效期1小时，重新生成token后尝试 |
| InvalidTimeStamp | timeStamp缺失或不合法 | 检查请求参数中timeStamp字段是否缺失或非法（非long型字段） |
| NotFound | 未找到设备的标记记录 | 先调用setDeviceStatus更新标记，再查询状态；或切换mode枚举（1或2） |
| InvalidMode | mode不合法 | 检查请求参数中mode字段枚举是否正确（1或2） |
| InvalidBits | bit值缺失或不合法 | 检查请求参数中bit字段是否缺失且传参类型是否是Boolean |
| InternalServerError | 服务器内部错误 | 通过在线提单申请帮助 |

## 编译和修复问题

### 依赖声明

**ArkTS客户端**：
```json
{
  "dependencies": {
    "@kit.DeviceSecurityKit": "^5.0.0",
    "@kit.BasicServicesKit": "^5.0.0",
    "@kit.PerformanceAnalysisKit": "^5.0.0"
  }
}
```

**Java服务端**：
```xml
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>fastjson</artifactId>
    <version>1.2.83</version>
</dependency>
<dependency>
    <groupId>org.bouncycastle</groupId>
    <artifactId>bcprov-jdk18on</artifactId>
    <version>1.74</version>
</dependency>
<dependency>
    <groupId>commons-codec</groupId>
    <artifactId>commons-codec</artifactId>
    <version>1.15</version>
</dependency>
```

### 环境要求

**客户端环境**：
- HarmonyOS版本：5.0.0(12)及以上
- 支持设备：Phone、Tablet、PC/2in1、Wearable、TV（从5.1.1(19)版本）
- 必须使用真机测试，不支持模拟器
- 设备必须联网

**服务端环境**：
- Java版本：Java 8及以上
- 网络环境：可访问华为云服务API端点
- 必须配置服务账号密钥文件

### 常见编译问题

**问题1：导入模块失败**
```
Cannot find module '@kit.DeviceSecurityKit'
```
**解决方法**：确保HarmonyOS SDK版本为5.0.0(12)及以上，检查ohpm配置是否正确

**问题2：权限校验失败（错误码201）**
```
Error code: 201 - has no permission
```
**解决方法**：
1. 在AppGallery Connect开启"应用设备状态检测"开关
2. 重新申请调试Profile文件
3. 将新申请的Profile作为工程的签名文件

**问题3：网络错误（错误码1003300006）**
```
Error code: 1003300006 - access cloud server fail
```
**解决方法**：
1. 检查设备是否联网
2. 检查网络连接是否稳定
3. 重试获取DeviceToken

**问题4：REST API返回InvalidBundleName**
```
{
  "errorCodes": "InvalidBundleName"
}
```
**解决方法**：
1. 检查请求header中是否携带bundleName
2. 确保header中的bundleName与客户端应用的bundleName一致

**问题5：deviceToken过期**
```
{
  "errorCodes": "DeviceTokenExpired"
}
```
**解决方法**：重新调用getDeviceToken获取新的DeviceToken（有效期1小时）

## 常见问题与解决方法

### Q1：如何判断应用是否在该设备上首次安装？
**原因**：需要使用设备标记状态来判断设备的首次安装状态
**解决方法**：
- 客户端调用getDeviceToken获取DeviceToken
- 服务端调用getDeviceStatus查询设备标记状态
- 如果返回NotFound错误，表示该设备未被标记过，可判断为首次安装
- 如果返回bit0=false，也可表示首次安装（具体含义由开发者定义）
- 更新标记状态：调用setDeviceStatus设置bit0=true，表示已安装过

### Q2：如何判断用户是否已在该设备上领取过优惠券？
**原因**：需要使用设备标记状态来记录优惠券领取状态
**解决方法**：
- 使用bit0或bit1来标识优惠券领取状态（如bit1=true表示已领取）
- 服务端调用getDeviceStatus查询设备标记状态
- 如果bit1=true，表示已领取过优惠券，可拒绝继续领取
- 如果bit1=false，表示未领取过，可发放优惠券并调用setDeviceStatus更新bit1为true

### Q3：NotFound错误是什么意思？
**原因**：未找到设备的标记记录，表示设备身份验证成功但该设备未被标记过
**解决方法**：
- 这是正常情况，表示该设备首次使用应用
- 先调用setDeviceStatus更新标记状态
- 再调用getDeviceStatus查询状态
- 或切换mode枚举（1或2）尝试查询

### Q4：如何处理设备标记状态的有效期？
**原因**：设备标记状态记录的存储期限为2年
**解决方法**：
- 根据getDeviceStatus响应中的lastUpdateTime字段判断有效期
- lastUpdateTime精度到每月1号零点（如1722441600000对应2024-08-01 00:00:00）
- 如果距离lastUpdateTime超过2年，设备标记状态将失效
- 需要重新更新设备标记状态

### Q5：应用级和开发者级有什么区别？
**原因**：mode参数支持两种粒度，不同粒度的设备标记状态相互独立
**解决方法**：
- 应用级（mode=1）：设备标记状态仅在当前应用中有效
- 开发者级（mode=2）：设备标记状态在同一开发者下的所有应用共享
- 例如开发者甲的应用A更新了设备标记状态，开发者甲的应用B查询到的设备标记状态也会跟随变化
- 根据业务需求选择合适的粒度

### Q6：deviceToken每次调用都不一样，如何处理？
**原因**：deviceToken由Device Security Kit加密生成，每次调用生成Token均不一样
**解决方法**：
- 这是正常现象，deviceToken为设备临时标识，不用于持久化存储
- deviceToken有效期1小时，在有效期内可多次使用
- 服务端通过deviceToken查询的设备标记状态是持久化的，与临时deviceToken无关
- 如果deviceToken过期，重新调用getDeviceToken获取新的Token

## 输出结果报告

执行完成后输出以下信息：

**客户端输出**：
```json
{
  "status": "success",
  "deviceToken": "aes-gcm.gouLVEalfJxRLxt+3Gxh/orDAG9kDbke...",
  "timestamp": 1711072205525,
  "apiUsed": [
    "deviceCertificate.getDeviceToken"
  ]
}
```

**服务端输出（查询状态）**：
```json
{
  "status": "success",
  "bundleName": "com.huawei.myapplication",
  "bit0": true,
  "bit1": false,
  "lastUpdateTime": 1711072206323,
  "errorCodes": "OK",
  "apiUsed": [
    "getDeviceStatus"
  ]
}
```

**服务端输出（更新状态）**：
```json
{
  "status": "success",
  "bundleName": "com.huawei.myapplication",
  "errorCodes": "OK",
  "apiUsed": [
    "setDeviceStatus"
  ]
}
```

## 参考文档

- [应用设备状态检测开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/devicesecurity-deviceverify-develop)
- [DeviceVerify ArkTS API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/devicesecurity-deviceverify-api)
- [验证deviceToken REST API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/devicesecurity-deviceverify-checkdevicetoken)
- [查询设备标记状态 REST API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/devicesecurity-deviceverify-getdevicestatus)
- [更新设备标记状态 REST API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/devicesecurity-deviceverify-updatedevicestatus)
- [删除设备标记状态 REST API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/devicesecurity-deviceverify-deletedevicestatus)
- [ArkTS API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/devicesecurity-arktsapi-errcode-deviceverify)
- [REST API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/devicesecurity-restapi-errcode)
- [开通Device Security服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/devicesecurity-deviceverify-activateservice)
- [基于服务账号生成鉴权令牌](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/devicesecurity-deviceverify-token)

## 完整示例代码

- [ArkTS客户端示例](assets/device_client_example.ets)
- [Java服务端示例](assets/device_server_example.java)
- [服务账号JWT生成示例](assets/jwt_generate_example.java)
- [配置文件示例](assets/config_template.json)

## 测试用例

### 正向测试用例
- [客户端获取DeviceToken成功测试](tests/test_client_positive.py)
- [服务端查询设备标记状态成功测试](tests/test_server_get_positive.py)
- [服务端更新设备标记状态成功测试](tests/test_server_set_positive.py)
- [服务端删除设备标记状态成功测试](tests/test_server_del_positive.py)

### 边界测试用例
- [DeviceToken过期测试](tests/test_token_expired_boundary.py)
- [设备标记状态存储期限测试](tests/test_status_expiry_boundary.py)
- [应用级和开发者级切换测试](tests/test_mode_switch_boundary.py)

### 异常测试用例
- [未开通服务权限测试](tests/test_permission_denied_exception.py)
- [网络异常测试](tests/test_network_error_exception.py)
- [无效DeviceToken测试](tests/test_invalid_token_exception.py)
- [服务器内部错误测试](tests/test_internal_error_exception.py)