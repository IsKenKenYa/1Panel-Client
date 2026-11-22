---
name: hmos-devicesecurity-service-account-token
description: 基于服务账号生成JWT格式鉴权令牌，用于Device Security Kit应用设备状态检测服务鉴权，需要华为开发者联盟API Console创建服务账号密钥，仅适用于服务端场景，支持Java语言实现，典型场景为调用应用设备状态检测API前的身份认证
---

# 基于服务账号生成鉴权令牌技能

## 功能描述

本技能用于生成华为服务账号鉴权令牌（JWT格式），实现服务器与服务器之间的接口鉴权。通过华为开发者联盟API Console创建的服务账号密钥文件，使用SHA256withRSA/PSS算法生成符合JWT规范的鉴权令牌，用于调用华为公开API（如Device Security Kit的应用设备状态检测服务）。

**核心能力**：
- 解析服务账号密钥文件（JSON格式）
- 生成JWT Header（包含kid、typ、alg字段）
- 生成JWT Payload（包含aud、iss、exp、iat字段）
- 使用SHA256withRSA/PSS算法生成签名
- 拼接生成完整的JWT Token字符串

**技术特点**：
- 基于标准JWT（JSON Web Token）规范
- 使用PS256（SHA256withRSA/PSS）签名算法
- 令牌有效期建议3600秒
- 需要在服务端环境执行，私钥不能暴露

## 使用场景

### 触发词
- "生成服务账号鉴权令牌"
- "创建JWT Token"
- "Device Security Kit鉴权"
- "服务账号令牌生成"
- "应用设备状态检测服务鉴权"

### 能做
- 根据服务账号密钥文件生成JWT格式鉴权令牌
- 为调用华为公开API提供身份认证
- 支持Java语言的服务端实现
- 自动处理JWT的Header、Payload、Signature三部分生成
- 提供完整的错误处理和参数校验

### 绝不做
- 不在前端或客户端环境执行（私钥必须保密）
- 不生成非JWT格式的令牌
- 不支持除PS256以外的签名算法
- 不提供服务账号密钥文件的创建功能（需在华为开发者联盟创建）
- 不处理令牌的刷新逻辑（需要重新生成）

### 补充
- 服务账号密钥文件必须妥善保管，华为不进行存储
- 应用服务器时间需要校准为标准UTC时间
- JWT令牌有效期建议设置为3600秒（1小时）
- 仅适用于应用设备状态检测服务的鉴权
- 需要申请开发者级的服务账号凭证

## 调用规范和规则

### 输入约束
- **密钥文件格式**：标准JSON格式，必须包含以下字段：
  - `project_id`：项目ID
  - `key_id`：密钥ID（用于JWT Header的kid字段）
  - `private_key`：私钥（PKCS#8格式，BASE64编码）
  - `sub_account`：子账号（用于JWT Payload的iss字段）
  - `auth_uri`、`token_uri`、`auth_provider_cert_uri`、`client_cert_uri`：可选字段
- **私钥长度**：建议2048位或以上
- **时间戳要求**：系统时间必须校准为标准UTC时间
- **有效期设置**：JWT的exp字段建议比iat晚3600秒

### 执行约束
- **执行环境**：必须在服务端环境执行，禁止在客户端执行
- **最大耗时**：单个令牌生成操作应在100ms以内
- **私钥安全**：私钥必须在安全环境存储，禁止明文硬编码
- **算法限制**：仅支持PS256（SHA256withRSA/PSS）签名算法
- **并发限制**：建议实现令牌缓存机制，避免频繁生成

### 内容约束
- **禁止硬编码私钥**：生产环境必须从安全存储读取私钥
- **禁止泄露敏感信息**：生成的JWT令牌、私钥等敏感信息禁止记录到日志
- **禁止使用过期令牌**：令牌过期后必须重新生成
- **禁止使用不安全算法**：仅允许使用PS256，禁止使用RS256等其他算法

### 降级约束
- **私钥读取失败**：返回错误提示，要求检查密钥文件路径和格式
- **时间戳错误**：提示检查系统时间是否校准为标准UTC时间
- **签名生成失败**：检查私钥格式是否为PKCS#8，BASE64解码是否正确
- **网络环境异常**：本技能为本地计算，不依赖网络，但调用华为API时需要网络连接

## 调用流程和步骤

### 步骤1：准备服务账号密钥文件

**前置校验**：
1. 确认已在华为开发者联盟API Console创建服务账号
2. 下载并保存服务账号密钥文件（JSON格式）
3. 确认密钥文件包含必需字段：`key_id`、`private_key`、`sub_account`
4. 确认私钥格式为PKCS#8标准格式

**参数准备**：
```java
// 服务账号密钥文件路径
String keyFilePath = "/path/to/service-account.json";

// 读取密钥文件
JSONObject keyFile = readJsonFile(keyFilePath);
String keyId = keyFile.getString("key_id");
String privateKeyPem = keyFile.getString("private_key");
String iss = keyFile.getString("sub_account");
```

### 步骤2：生成JWT Header

**说明**：JWT Header包含签名算法和密钥ID信息，使用BASE64URL编码。

**示例代码**：
```java
import com.alibaba.fastjson.JSONObject;
import org.apache.commons.codec.binary.Base64;
import java.nio.charset.StandardCharsets;

// JWT Header数据
JSONObject header = new JSONObject();
header.put("alg", "PS256");  // 固定值：PS256
header.put("typ", "JWT");     // 固定值：JWT
header.put("kid", keyId);     // 来自密钥文件的key_id字段

// BASE64URL编码
byte[] encodeHeaderBytes = Base64.encodeBase64URLSafe(
    header.toString().getBytes(StandardCharsets.UTF_8)
);
String encodeHeader = new String(encodeHeaderBytes, StandardCharsets.UTF_8);
```

**字段说明**：
| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| alg | String | 是 | 算法类型，固定值：PS256 |
| typ | String | 是 | 数据类型，固定值：JWT |
| kid | String | 是 | 服务账号密钥文件中的key_id字段 |

### 步骤3：生成JWT Payload

**说明**：JWT Payload包含令牌的声明信息，包括签发者、接收者、有效期等。

**示例代码**：
```java
// JWT Payload数据
long iat = System.currentTimeMillis() / 1000;  // 当前UTC时间戳（秒）
long exp = iat + 3600;  // 过期时间：当前时间 + 3600秒（1小时）

JSONObject payload = new JSONObject();
payload.put("aud", "https://oauth-login.cloud.huawei.com/oauth2/v3/token");  // 固定值
payload.put("iss", iss);  // 来自密钥文件的sub_account字段
payload.put("exp", exp);  // 过期UTC时间戳
payload.put("iat", iat);  // 签发UTC时间戳

// BASE64URL编码
byte[] encodePayloadBytes = Base64.encodeBase64URLSafe(
    payload.toString().getBytes(StandardCharsets.UTF_8)
);
String encodePayload = new String(encodePayloadBytes, StandardCharsets.UTF_8);
```

**字段说明**：
| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| aud | String | 是 | 接收者，固定值：https://oauth-login.cloud.huawei.com/oauth2/v3/token |
| iss | String | 是 | 签发者，来自服务账号密钥文件的sub_account字段 |
| exp | Long | 是 | JWT到期UTC时间戳，建议比iat晚3600秒 |
| iat | Long | 是 | JWT签发UTC时间戳，为自UTC时间1970年1月1日00:00:00的秒数 |

### 步骤4：生成JWT Signature

**说明**：使用私钥对Header和Payload的拼接字符串进行签名。

**示例代码**：
```java
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import java.security.*;
import java.security.spec.PKCS8EncodedKeySpec;

// 解析私钥
private static PrivateKey getPrivateKey(String key) 
    throws NoSuchAlgorithmException, InvalidKeySpecException {
    // 移除PEM格式的头尾标记
    String privateKeyPEM = key
        .replace("-----BEGIN PRIVATE KEY-----\n", "")
        .replace("\n-----END PRIVATE KEY-----\n", "");
    
    // BASE64解码
    byte[] encoded = Base64.decodeBase64(privateKeyPEM.getBytes(StandardCharsets.UTF_8));
    
    // 生成PrivateKey对象
    PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(encoded);
    KeyFactory keyFactory = KeyFactory.getInstance("RSA");
    return keyFactory.generatePrivate(keySpec);
}

// 生成签名
String jwtHeaderAndPayload = encodeHeader + "." + encodePayload;

Signature signatureInstance = Signature.getInstance(
    "SHA256withRSA/PSS", 
    new BouncyCastleProvider()
);
signatureInstance.initSign(getPrivateKey(privateKeyPem));
signatureInstance.update(jwtHeaderAndPayload.getBytes(StandardCharsets.UTF_8));

String signature = new String(
    Base64.encodeBase64URLSafe(signatureInstance.sign()), 
    StandardCharsets.UTF_8
);
```

**算法说明**：
- 签名算法：SHA256withRSA/PSS（PS256）
- 需要引入BouncyCastle库作为安全提供者
- 私钥格式：PKCS#8标准格式

### 步骤5：拼接生成完整JWT Token

**示例代码**：
```java
// 拼接JWT Token
String jwtToken = encodeHeader + "." + encodePayload + "." + signature;

System.out.println("生成的JWT令牌：" + jwtToken);
return jwtToken;
```

**JWT Token格式**：
```
{Header的BASE64URL编码}.{Payload的BASE64URL编码}.{Signature的BASE64URL编码}
```

**示例**：
```
eyJraWQiOiIxMjM0NTY3ODkwIiwidHlwIjoiSldUIiwiYWxnIjoiUFMyNTYifQ.
eyJhdWQiOiJodHRwczovL29hdXRoLWxvZ2luLmNsb3VkLmh1YXdlaS5jb20vb2F1dGgyL3YzL3Rva2VuIiwiaXNzIjoiMTIzNDU2NzgiLCJleHAiOjE1ODE0MTA2NjQsImlhdCI6MTU4MTQwNzA2NH0.
BRNssabc123def456ghi789jkl012mno345pqr678stu901vwx234yzA567BC890
```

### 步骤6：错误处理

```java
import java.io.IOException;
import java.security.NoSuchAlgorithmException;
import java.security.InvalidKeySpecException;
import java.security.InvalidKeyException;
import java.security.SignatureException;

public String generateJwtToken(String keyFilePath) {
    try {
        // 步骤1-5的代码
        // ...
        return jwtToken;
        
    } catch (IOException e) {
        System.err.println("密钥文件读取失败：" + e.getMessage());
        throw new RuntimeException("无法读取密钥文件，请检查文件路径和权限", e);
        
    } catch (NoSuchAlgorithmException e) {
        System.err.println("不支持的加密算法：" + e.getMessage());
        throw new RuntimeException("系统不支持RSA算法", e);
        
    } catch (InvalidKeySpecException e) {
        System.err.println("私钥格式错误：" + e.getMessage());
        throw new RuntimeException("私钥格式不正确，请确认为PKCS#8格式", e);
        
    } catch (InvalidKeyException e) {
        System.err.println("私钥无效：" + e.getMessage());
        throw new RuntimeException("私钥无效或已损坏", e);
        
    } catch (SignatureException e) {
        System.err.println("签名生成失败：" + e.getMessage());
        throw new RuntimeException("签名生成失败，请检查私钥和算法配置", e);
        
    } catch (Exception e) {
        System.err.println("未知错误：" + e.getMessage());
        throw new RuntimeException("JWT令牌生成失败", e);
    }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|--------|------|----------|
| FILE_NOT_FOUND | 密钥文件不存在或路径错误 | 检查文件路径是否正确，确认文件存在 |
| INVALID_JSON_FORMAT | 密钥文件JSON格式错误 | 验证JSON格式是否正确，检查必需字段是否存在 |
| MISSING_REQUIRED_FIELD | 缺少必需字段（key_id、private_key、sub_account） | 检查密钥文件是否完整，重新从API Console下载 |
| INVALID_PRIVATE_KEY | 私钥格式错误或损坏 | 确认私钥为PKCS#8格式，检查BASE64编码是否正确 |
| ALGORITHM_NOT_SUPPORTED | 系统不支持RSA或PS256算法 | 检查JVM环境，确认已安装BouncyCastle库 |
| TIMESTAMP_ERROR | 系统时间未校准为标准UTC时间 | 同步系统时间，确保时区设置正确 |
| SIGNATURE_FAILED | 签名生成失败 | 检查私钥是否正确，确认算法参数配置 |
| TOKEN_EXPIRED | JWT令牌已过期 | 重新生成令牌，检查exp字段设置 |

## 编译和修复问题

### 依赖声明

**Maven依赖**：
```xml
<dependencies>
    <!-- JSON处理 -->
    <dependency>
        <groupId>com.alibaba</groupId>
        <artifactId>fastjson</artifactId>
        <version>1.2.83</version>
    </dependency>
    
    <!-- BouncyCastle加密库（PS256算法支持） -->
    <dependency>
        <groupId>org.bouncycastle</groupId>
        <artifactId>bcprov-jdk18on</artifactId>
        <version>1.74</version>
    </dependency>
    
    <!-- BASE64编解码 -->
    <dependency>
        <groupId>commons-codec</groupId>
        <artifactId>commons-codec</artifactId>
        <version>1.15</version>
    </dependency>
</dependencies>
```

**Gradle依赖**：
```groovy
dependencies {
    implementation 'com.alibaba:fastjson:1.2.83'
    implementation 'org.bouncycastle:bcprov-jdk18on:1.74'
    implementation 'commons-codec:commons-codec:1.15'
}
```

### 环境要求
- **Java版本**：Java 8或更高版本
- **JVM环境**：需要支持RSA加密算法
- **安全提供者**：BouncyCastle库（用于PS256算法）
- **开发环境**：推荐使用IntelliJ IDEA或Eclipse
- **生产环境**：确保私钥文件安全存储，权限设置正确

### 常见编译问题

**问题1：找不到BouncyCastle依赖**
```
java.security.NoSuchAlgorithmException: SHA256withRSA/PSS Signature not available
```
**解决方法**：
- 确认已添加BouncyCastle依赖
- 检查依赖版本是否正确（推荐1.74或更高）
- 确认在代码中注册了BouncyCastleProvider：`new BouncyCastleProvider()`

**问题2：私钥格式错误**
```
java.security.InvalidKeySpecException: java.security.InvalidKeyException: invalid key format
```
**解决方法**：
- 确认私钥为PKCS#8格式（PEM格式以`-----BEGIN PRIVATE KEY-----`开头）
- 检查私钥字符串是否包含完整的BASE64编码内容
- 确认已正确移除PEM头尾标记和换行符

**问题3：BASE64解码错误**
```
java.lang.IllegalArgumentException: Illegal base64 character
```
**解决方法**：
- 检查私钥字符串是否包含非法字符
- 确认使用`Base64.decodeBase64()`方法而不是标准的BASE64解码
- 检查私钥字符串是否正确截取（移除头尾标记）

**问题4：时间戳计算错误**
```
JWT令牌验证失败：invalid iat or exp
```
**解决方法**：
- 确认使用`System.currentTimeMillis() / 1000`获取秒级时间戳
- 检查exp是否大于iat（建议exp = iat + 3600）
- 确认系统时间已校准为标准UTC时间

## 常见问题与解决方法

### Q1：如何获取服务账号密钥文件？
**原因**：需要华为开发者联盟账号和项目权限
**解决方法**：
1. 登录华为开发者联盟：https://developer.huawei.com/consumer/cn/console/overview
2. 进入API Console
3. 创建或选择项目
4. 创建服务账号并下载密钥文件
5. 参考：https://developer.huawei.com/consumer/cn/doc/start/api-0000001062522591

### Q2：生成的JWT令牌验证失败怎么办？
**原因**：可能存在多个原因导致验证失败
**解决方法**：
1. 检查Header中的kid是否与密钥文件的key_id一致
2. 检查Payload中的iss是否与密钥文件的sub_account一致
3. 检查系统时间是否校准为标准UTC时间
4. 确认exp字段大于当前时间
5. 确认签名算法为PS256（不是RS256）

### Q3：私钥如何安全存储？
**原因**：私钥泄露会导致严重的安全风险
**解决方法**：
- 使用环境变量存储私钥路径，不硬编码路径
- 使用密钥管理系统（KMS）或加密存储
- 设置文件权限为仅当前用户可读（chmod 600）
- 定期轮换密钥，不长期使用同一密钥
- 生产环境建议使用密钥保险箱服务

### Q4：JWT令牌有效期应该设置多长？
**原因**：有效期过长或过短都会影响使用
**解决方法**：
- 建议设置为3600秒（1小时）
- 不要设置过长（如24小时），存在安全风险
- 不要设置过短（如60秒），可能导致调用时已过期
- 实现令牌缓存机制，在有效期内重复使用
- 令牌过期前5分钟开始刷新

### Q5：如何验证生成的JWT令牌是否正确？
**原因**：需要确认令牌格式和内容正确
**解决方法**：
1. 使用在线JWT解析工具（如https://jwt.io）解析令牌
2. 检查Header部分是否包含kid、typ、alg字段
3. 检查Payload部分是否包含aud、iss、exp、iat字段
4. 检查exp是否为合理的未来时间
5. 调用华为API测试令牌有效性

### Q6：可以在客户端使用这个技能吗？
**原因**：客户端环境安全性无法保证
**解决方法**：
- **绝对禁止**在客户端（如Android、iOS、Web前端）使用此技能
- 私钥必须在服务端环境使用，禁止暴露给客户端
- 客户端应通过服务端接口间接获取鉴权令牌
- 服务端应实现令牌缓存和分发机制

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "jwt_token": "eyJraWQiOi...（完整的JWT令牌）",
  "header": {
    "alg": "PS256",
    "typ": "JWT",
    "kid": "*****"
  },
  "payload": {
    "aud": "https://oauth-login.cloud.huawei.com/oauth2/v3/token",
    "iss": "*****",
    "exp": 1581410664,
    "iat": 1581407064
  },
  "token_expiry": "2025-01-15T10:30:00Z",
  "api_used": [
    "SHA256withRSA/PSS签名算法",
    "BASE64URL编码",
    "PKCS#8私钥解析"
  ]
}
```

## 参考文档

- [API开发指南](references/devicesecurity-deviceverify-token.md) - 基于服务账号生成鉴权令牌开发指南
- [JWT规范](https://jwt.io/introduction/) - JSON Web Token介绍
- [华为开发者联盟API Console](https://developer.huawei.com/consumer/cn/console/overview) - 服务账号管理
- [服务账号密钥创建指南](https://developer.huawei.com/consumer/cn/doc/start/api-0000001062522591) - API Console操作指南

## 完整示例代码

- [Java示例代码](assets/JWTGenerateDemo.java) - 完整的JWT令牌生成示例（包含错误处理和参数校验）
- [Maven配置示例](assets/pom.xml) - Maven项目依赖配置
- [服务账号密钥文件示例](assets/service-account-example.json) - 密钥文件格式示例（脱敏）

## 测试用例

### 正向测试用例
- [test_positive_key_validation.java](tests/test_positive_key_validation.java) - 验证正确的密钥文件格式
- [test_positive_token_generation.java](tests/test_positive_token_generation.java) - 验证JWT令牌成功生成
- [test_positive_token_format.java](tests/test_positive_token_format.java) - 验证JWT令牌格式正确性

### 边界测试用例
- [test_boundary_expiry_time.java](tests/test_boundary_expiry_time.java) - 测试令牌有效期边界值（3600秒）
- [test_boundary_private_key_length.java](tests/test_boundary_private_key_length.java) - 测试私钥长度边界
- [test_boundary_timestamp_range.java](tests/test_boundary_timestamp_range.java) - 测试时间戳范围有效性

### 异常测试用例
- [test_exception_invalid_key_format.java](tests/test_exception_invalid_key_format.java) - 测试无效的私钥格式
- [test_exception_missing_fields.java](tests/test_exception_missing_fields.java) - 测试缺少必需字段
- [test_exception_expired_token.java](tests/test_exception_expired_token.java) - 测试过期的令牌验证
- [test_exception_invalid_signature.java](tests/test_exception_invalid_signature.java) - 测试签名验证失败