---
name: hmos-attribution-service-receive-postback
description: 接收并验签归因结果回传数据，支持SHA256withRSA/PSS验签算法，适用于分发平台、开发者、归因监测平台接收归因结果场景
---

# 归因结果回传接收技能

## 功能描述

本技能提供接收应用归因服务回传的归因结果数据并进行验签的能力。应用归因服务在满足隐私要求后，会将归因结果回传给开发者、获胜的分发平台以及归因监测平台。接收方需要实现HTTP POST接口接收回传数据，并使用SHA256withRSA/PSS算法验证签名以确保数据合法性和完整性。

核心功能包括：
- 实现归因结果回传接收接口
- 解析回传数据并提取关键字段
- 使用应用归因服务公钥进行签名验证
- 处理验签成功和失败的场景
- 支持幂等性处理（通过transaction_id）

## 使用场景

### 触发词
- "接收归因结果"
- "归因结果回传"
- "验签归因数据"
- "处理归因回传"
- "attributon postback"

### 能做
- 接收应用归因服务回传的归因结果数据
- 解析归因结果中的关键字段（ad_tech_id、campaign_id、trigger_data等）
- 验证回传数据的签名确保数据来源合法
- 处理幂等性请求避免重复处理
- 返回标准的响应结果给应用归因服务

### 绝不做
- 不修改回传数据的签名值
- 不绕过验签流程直接处理数据
- 不处理与归因结果无关的HTTP请求
- 不存储未经验签的归因结果数据
- 不泄露验签公钥给第三方

### 补充
- 验签公钥由应用归因服务提供，已内置于技能中
- 回传URL在注册归因角色时配置
- nonce字段每次回传唯一，可用于防重放攻击
- timestamp字段建议校验与当前时间差不超过5分钟
- 部分字段仅满足特定条件时才会携带（如campaign_id、source_id等）

## 调用规范和规则

### 输入约束
- HTTP请求方法：POST
- Content-Type：application/json
- 必填字段：nonce、timestamp、signature、transaction_id
- 选填字段：ad_tech_id、campaign_id、source_id、destination_id、trigger_data等
- timestamp有效范围：当前时间±5分钟
- signature格式：Base64编码字符串
- transaction_id：全局唯一字符串

### 执行约束
- 验签算法：SHA256withRSA/PSS
- 验签最大耗时：500毫秒
- HTTP响应最大耗时：2秒
- 接口响应码：200（成功）、4xx（客户端错误）、5xx（服务端错误）
- 幂等性要求：相同transaction_id的请求返回相同结果

### 内容约束
- 禁止跳过验签流程
- 禁止修改回传数据内容
- 禁止使用自签名证书
- 禁止缓存验签结果超过1小时
- 禁止在验签失败时返回成功响应

### 降级约束
- 验签失败：返回resultCode非0的错误响应，记录日志并告警
- timestamp过期：返回错误响应并提示时间戳无效
- 重复请求：检查transaction_id，如已处理则返回缓存结果
- 公钥失效：联系华为技术支持更新公钥
- 网络超时：返回5xx错误码并建议重试

## 调用流程和步骤

### 步骤1：接收HTTP POST请求

**前置校验**：
1. 检查HTTP方法是否为POST
2. 检查Content-Type是否为application/json
3. 解析Request Body获取JSON数据
4. 校验必填字段是否存在（nonce、timestamp、signature、transaction_id）

**参数准备**：
```java
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import com.fasterxml.jackson.databind.ObjectMapper;

public class AttributionPostbackController {
    
    public void handlePostback(HttpServletRequest request, HttpServletResponse response) {
        // 校验请求方法和Content-Type
        if (!"POST".equalsIgnoreCase(request.getMethod())) {
            response.setStatus(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
            return;
        }
        
        String contentType = request.getContentType();
        if (contentType == null || !contentType.contains("application/json")) {
            response.setStatus(HttpServletResponse.SC_UNSUPPORTED_MEDIA_TYPE);
            return;
        }
        
        // 解析Request Body
        ObjectMapper mapper = new ObjectMapper();
        AttributionPostbackRequest postbackRequest = mapper.readValue(
            request.getInputStream(), 
            AttributionPostbackRequest.class
        );
        
        // 校验必填字段
        validateRequiredFields(postbackRequest);
    }
}
```

### 步骤2：验签处理

**验签逻辑**：
1. 按照规则拼接待验签字符串（仅包含参与签名的字段）
2. 使用应用归因服务提供的公钥进行验签
3. 验签通过后继续处理业务逻辑
4. 验签失败返回错误响应

**拼接规则**：
- 按照字段顺序使用`\u2063`分隔符拼接
- 仅包含参与签名的字段：ad_tech_id、campaign_id、source_id、destination_id、trigger_data、nonce、timestamp
- 非必填字段仅当存在时才拼接

**示例代码**：
```java
import org.apache.commons.codec.binary.Base64;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.security.spec.X509EncodedKeySpec;
import java.util.ArrayList;
import java.util.List;

public class AttributionSignatureVerifier {
    
    private static final String PUBLIC_KEY = "MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA0IgrEtIR1kVF/ImKIo3/5AxEFZzL156jLn2CilqGQmFByiMlpa2G0dotCK1mj9bdhDJbUPd3Plx1zVX9WoW/L/mg25+ng0iPlcItqhUuTIVi+0N50BHlVKPFWG/vYxCkR1ABU44zHyg2XAmqs2L6nUA9Hjbmwn5WX9JUWFF3RF4ja6GJRDkq0HFQ6ouM8Vpm3ZnnRTCuEzOpUcG+FMYAa9M9coRMMM3w0M/IgbYL4n86tQ6ybicaeadSwJIzXExLL0bSf1tYZ7CWvdK0V2ftLWC7Wmho64/g/AjqXc5d2nq88Cn+Vm48jLW1gibI1sPLjFhcfgRg0EOHD/FeUHLxhGeLc4KZ7hrcaW+IuVaTpHxbxJ9WiIokf6blQSEyPHx4w95IdGYNe/BGFhYaf3AhCe6b62e//0JdaYPKNDUKOpTf60vAhqQeibx4iaRZh8dEAU1m9lD0aR6+0trNCzdsC0iPCRLCXcFJXN2/ZJRug39xuJoSEkCxUsJdcoYknbRxAgMBAAE=";
    private static final String RSA_ALGORITHM = "RSA";
    private static final String SHA256WITHRSA_PSS_ALGORITHM = "SHA256WithRSA/PSS";
    
    public boolean verifySignature(AttributionPostbackRequest request) 
            throws NoSuchAlgorithmException, InvalidKeySpecException, 
                   InvalidKeyException, SignatureException {
        
        // 拼接待验签字符串
        String content = buildSignatureContent(request);
        
        // 验签
        byte[] plainContent = content.getBytes(StandardCharsets.UTF_8);
        byte[] signContent = Base64.decodeBase64(
            request.getSignature().getBytes(StandardCharsets.UTF_8)
        );
        
        Security.addProvider(new BouncyCastleProvider());
        PublicKey publicKey = getPublicKey(PUBLIC_KEY);
        Signature signature = Signature.getInstance(SHA256WITHRSA_PSS_ALGORITHM);
        signature.initVerify(publicKey);
        signature.update(plainContent);
        
        return signature.verify(signContent);
    }
    
    private String buildSignatureContent(AttributionPostbackRequest request) {
        List<String> fields = new ArrayList<>();
        
        // 仅添加参与签名的字段（按顺序）
        if (request.getAdTechId() != null) {
            fields.add(request.getAdTechId());
        }
        if (request.getCampaignId() != null) {
            fields.add(request.getCampaignId());
        }
        if (request.getSourceId() != null) {
            fields.add(request.getSourceId());
        }
        if (request.getDestinationId() != null) {
            fields.add(request.getDestinationId());
        }
        if (request.getTriggerData() != null) {
            fields.add(String.valueOf(request.getTriggerData()));
        }
        fields.add(request.getNonce());
        fields.add(String.valueOf(request.getTimestamp()));
        
        return String.join("\u2063", fields);
    }
    
    private PublicKey getPublicKey(String key) 
            throws NoSuchAlgorithmException, InvalidKeySpecException {
        byte[] keyBytes = Base64.decodeBase64(key.getBytes(StandardCharsets.UTF_8));
        X509EncodedKeySpec keySpec = new X509EncodedKeySpec(keyBytes);
        KeyFactory keyFactory = KeyFactory.getInstance(RSA_ALGORITHM);
        return keyFactory.generatePublic(keySpec);
    }
}
```

### 步骤3：时间戳和幂等性校验

**时间戳校验**：
```java
public void validateTimestamp(long timestamp) {
    long currentTime = System.currentTimeMillis();
    long timeDiff = Math.abs(currentTime - timestamp);
    
    // 建议校验时间差不超过5分钟（300000毫秒）
    if (timeDiff > 300000) {
        throw new AttributionException("Timestamp expired or invalid");
    }
}
```

**幂等性处理**：
```java
import java.util.concurrent.ConcurrentHashMap;

public class IdempotencyManager {
    
    private static final ConcurrentHashMap<String, AttributionPostbackResponse> 
        processedRequests = new ConcurrentHashMap<>();
    
    public AttributionPostbackResponse checkIdempotency(String transactionId) {
        return processedRequests.get(transactionId);
    }
    
    public void storeResponse(String transactionId, AttributionPostbackResponse response) {
        processedRequests.put(transactionId, response);
    }
}
```

### 步骤4：业务处理和响应

**业务处理**：
```java
public class AttributionPostbackService {
    
    public void processPostback(AttributionPostbackRequest request) {
        // 业务逻辑处理
        // 例如：存储归因结果、触发后续业务流程等
        
        // 提取关键字段
        String adTechId = request.getAdTechId();
        String campaignId = request.getCampaignId();
        String destinationId = request.getDestinationId();
        Integer triggerData = request.getTriggerData();
        
        // 根据trigger_data判断转化事件类型
        if (triggerData != null) {
            if (triggerData >= 1 && triggerData <= 200) {
                // 标准转化事件
                processStandardEvent(request);
            } else if (triggerData >= 501 && triggerData <= 600) {
                // 自定义转化事件
                processCustomEvent(request);
            }
        }
    }
    
    private void processStandardEvent(AttributionPostbackRequest request) {
        // 处理标准转化事件
    }
    
    private void processCustomEvent(AttributionPostbackRequest request) {
        // 处理自定义转化事件
    }
}
```

**响应处理**：
```java
public class AttributionPostbackController {
    
    public void handlePostback(HttpServletRequest request, HttpServletResponse response) {
        try {
            // 1. 解析请求
            AttributionPostbackRequest postbackRequest = parseRequest(request);
            
            // 2. 幂等性检查
            IdempotencyManager idempotencyManager = new IdempotencyManager();
            AttributionPostbackResponse cachedResponse = 
                idempotencyManager.checkIdempotency(postbackRequest.getTransactionId());
            if (cachedResponse != null) {
                sendResponse(response, cachedResponse);
                return;
            }
            
            // 3. 时间戳校验
            validateTimestamp(postbackRequest.getTimestamp());
            
            // 4. 验签
            AttributionSignatureVerifier verifier = new AttributionSignatureVerifier();
            boolean isValid = verifier.verifySignature(postbackRequest);
            
            if (!isValid) {
                sendErrorResponse(response, "SIGNATURE_INVALID", "Signature verification failed");
                return;
            }
            
            // 5. 业务处理
            AttributionPostbackService service = new AttributionPostbackService();
            service.processPostback(postbackRequest);
            
            // 6. 返回成功响应
            AttributionPostbackResponse successResponse = new AttributionPostbackResponse();
            successResponse.setResultCode("0");
            successResponse.setResultDesc("Success.");
            
            idempotencyManager.storeResponse(postbackRequest.getTransactionId(), successResponse);
            sendResponse(response, successResponse);
            
        } catch (AttributionException e) {
            sendErrorResponse(response, "PROCESSING_ERROR", e.getMessage());
        } catch (Exception e) {
            sendErrorResponse(response, "INTERNAL_ERROR", "Internal server error");
        }
    }
    
    private void sendResponse(HttpServletResponse response, AttributionPostbackResponse postbackResponse) {
        response.setContentType("application/json;charset=UTF-8");
        response.setStatus(HttpServletResponse.SC_OK);
        
        ObjectMapper mapper = new ObjectMapper();
        response.getWriter().write(mapper.writeValueAsString(postbackResponse));
    }
    
    private void sendErrorResponse(HttpServletResponse response, String code, String message) {
        response.setContentType("application/json;charset=UTF-8");
        
        AttributionPostbackResponse errorResponse = new AttributionPostbackResponse();
        errorResponse.setResultCode(code);
        errorResponse.setResultDesc(message);
        
        ObjectMapper mapper = new ObjectMapper();
        response.getWriter().write(mapper.writeValueAsString(errorResponse));
    }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| SIGNATURE_INVALID | 签名验证失败 | 检查签名算法是否为SHA256withRSA/PSS，确认公钥正确，验证待签名内容拼接顺序 |
| TIMESTAMP_EXPIRED | 时间戳过期 | 检查timestamp字段与当前时间差是否超过5分钟，同步服务器时间 |
| MISSING_REQUIRED_FIELD | 缺少必填字段 | 检查请求中是否包含nonce、timestamp、signature、transaction_id字段 |
| INVALID_FIELD_VALUE | 字段值无效 | 检查字段值是否符合规范（如ad_tech_id长度为8，destination_id长度不超过64） |
| TRANSACTION_ID_DUPLICATE | 事务ID重复 | 正常情况，表示幂等性处理，返回已缓存的成功响应即可 |
| PUBLIC_KEY_ERROR | 公钥加载失败 | 检查公钥格式是否正确，确认使用的是应用归因服务提供的公钥 |
| ALGORITHM_NOT_SUPPORTED | 不支持的算法 | 确认运行环境支持SHA256withRSA/PSS算法，安装BouncyCastle库 |
| JSON_PARSE_ERROR | JSON解析失败 | 检查请求Body是否为有效的JSON格式 |
| INTERNAL_ERROR | 内部服务错误 | 检查服务器日志，确认数据库连接、网络等基础设施正常 |

## 编译和修复问题

### 依赖声明

**Maven依赖**：
```xml
<dependencies>
    <!-- BouncyCastle加密库 -->
    <dependency>
        <groupId>org.bouncycastle</groupId>
        <artifactId>bcprov-jdk18on</artifactId>
        <version>1.77</version>
    </dependency>
    
    <!-- Base64编解码 -->
    <dependency>
        <groupId>commons-codec</groupId>
        <artifactId>commons-codec</artifactId>
        <version>1.15</version>
    </dependency>
    
    <!-- JSON处理 -->
    <dependency>
        <groupId>com.fasterxml.jackson.core</groupId>
        <artifactId>jackson-databind</artifactId>
        <version>2.15.0</version>
    </dependency>
    
    <!-- Servlet API -->
    <dependency>
        <groupId>javax.servlet</groupId>
        <artifactId>javax.servlet-api</artifactId>
        <version>4.0.1</version>
        <scope>provided</scope>
    </dependency>
</dependencies>
```

**Gradle依赖**：
```gradle
dependencies {
    implementation 'org.bouncycastle:bcprov-jdk18on:1.77'
    implementation 'commons-codec:commons-codec:1.15'
    implementation 'com.fasterxml.jackson.core:jackson-databind:2.15.0'
    providedCompile 'javax.servlet:javax.servlet-api:4.0.1'
}
```

### 环境要求
- Java版本：Java 8或更高版本（建议Java 11+）
- Servlet容器：支持Servlet 3.1+（如Tomcat 8.5+、Jetty 9+）
- 加密库：BouncyCastle 1.77+
- 网络环境：能够接收HTTPS POST请求

### 常见编译问题

**问题1：找不到BouncyCastle类**
```
java.lang.NoClassDefFoundError: org/bouncycastle/jce/provider/BouncyCastleProvider
```
**解决方法**：添加BouncyCastle依赖到项目构建文件中，确保依赖正确下载和引用。

**问题2：验签算法不支持**
```
java.security.NoSuchAlgorithmException: SHA256WithRSA/PSS Signature not available
```
**解决方法**：
1. 确认Java版本支持该算法（Java 8+）
2. 显式添加BouncyCastle Provider：
```java
Security.addProvider(new BouncyCastleProvider());
```

**问题3：Base64解码失败**
```
org.apache.commons.codec.binary.Base64异常
```
**解决方法**：检查signature字段是否包含非法字符，确认Base64格式正确。

**问题4：公钥格式错误**
```
java.security.spec.InvalidKeySpecException
```
**解决方法**：确认使用应用归因服务提供的完整公钥，不要遗漏任何部分。

## 常见问题与解决方法

### Q1：验签总是失败怎么办？
**原因**：
- 待签名字符串拼接顺序错误
- 公钥不正确或已过期
- signature字段Base64解码错误

**解决方法**：
- 严格按照字段顺序使用`\u2063`分隔符拼接字符串
- 仅包含参与签名的字段（非必填字段不存在时不拼接）
- 确认使用应用归因服务提供的最新公钥
- 检查signature字段是否完整，没有空格或换行

### Q2：如何处理重复的回传请求？
**原因**：网络重试或应用归因服务重发导致同一transaction_id的请求被多次接收

**解决方法**：
- 实现幂等性处理，使用transaction_id作为唯一标识
- 缓存已处理请求的响应结果
- 相同transaction_id直接返回缓存结果，不重复处理业务逻辑

### Q3：timestamp校验失败怎么办？
**原因**：
- 服务器时间不同步
- 网络延迟导致请求处理时时间差超过阈值

**解决方法**：
- 使用NTP服务同步服务器时间
- 适当放宽时间差校验阈值（建议不超过5分钟）
- 记录timestamp用于问题排查

### Q4：如何区分标准转化事件和自定义转化事件？
**原因**：trigger_data字段取值范围不同

**解决方法**：
- 标准转化事件：trigger_data范围 [1, 200]
- 自定义转化事件：trigger_data范围 [501, 600]
- 根据取值范围进行不同业务逻辑处理

### Q5：如何保证验签性能？
**原因**：RSA验签计算量较大，可能影响接口响应时间

**解决方法**：
- 使用缓存减少重复验签（注意缓存时效）
- 优化签名验证代码，减少对象创建
- 使用线程池处理并发请求
- 监控验签耗时，确保在500ms内完成

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "transaction_id": "回传事务ID",
  "ad_tech_id": "分发平台ID",
  "campaign_id": "营销任务ID",
  "source_id": "媒体应用ID",
  "destination_id": "开发者应用ID",
  "trigger_data": "转化事件编码",
  "verification_result": "验签结果（成功/失败）",
  "process_time": "处理时间戳",
  "apiUsed": [
    "Attribution Postback API"
  ]
}
```

## 参考文档

- [归因结果回传](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/store-attribution-receive)
- [归因结果回传API说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/store-rest-receive)
- [标准转化事件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/store-attribution-trigger-standard)
- [自定义转化事件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/store-attribution-trigger-custom)
- [标准转化事件信息](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/appgallery-attribution-appendix-triger)

## 完整示例代码

- [Java验签示例](assets/AttributionPostbackHandler.java)
- [Spring Boot Controller示例](assets/AttributionPostbackController.java)
- [请求响应模型](assets/AttributionPostbackModel.java)
- [配置文件示例](assets/application.properties)

## 测试用例

### 正向测试用例
- [验签成功测试](tests/test_positive.java)：测试正常的归因结果回传验签流程
- [幂等性测试](tests/test_idempotency.java)：测试相同transaction_id的重复请求处理
- [标准转化事件测试](tests/test_standard_event.java)：测试trigger_data在[1,200]范围内的处理

### 边界测试用例
- [时间戳边界测试](tests/test_boundary.java)：测试timestamp在5分钟边界值的处理
- [字段长度边界测试](tests/test_field_length.java)：测试各字段最大长度限制
- [可选字段缺失测试](tests/test_optional_fields.java)：测试仅必填字段时的验签流程

### 异常测试用例
- [验签失败测试](tests/test_signature_failed.java)：测试签名错误时的错误处理
- [时间戳过期测试](tests/test_timestamp_expired.java)：测试timestamp过期时的错误响应
- [必填字段缺失测试](tests/test_missing_fields.java)：测试缺少nonce、signature等必填字段时的错误
- [无效JSON格式测试](tests/test_invalid_json.java)：测试请求Body不是有效JSON时的处理