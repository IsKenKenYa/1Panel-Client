---
name: hmos-remote-communication-kit-custom-dns-config
description: 配置HTTP请求的DNS规则，支持自定义DNS服务器、静态DNS映射、动态DNS解析函数，最大支持1024个会话实例，适用于网络优化、安全DNS、域名解析定制场景
---

# DnsConfiguration：定制DNS技能

## 功能描述

本技能用于在Remote Communication Kit中配置HTTP请求的DNS规则，提供高度可定制的DNS查询行为。支持以下三种DNS配置方式：

1. **自定义DNS服务器（DnsServers）**：指定自定义的DNS服务器IP地址和端口进行域名解析
2. **静态DNS规则（StaticDnsRules）**：手动添加域名与IP地址的静态映射关系，hostname匹配时优先使用指定地址
3. **动态DNS规则（DynamicDnsRule）**：通过函数动态返回IP地址，根据hostname和port实时计算解析结果

**核心能力**：
- 配置dnsRules参数：支持DnsServers、StaticDnsRules、DynamicDnsRule三种类型
- 配置dnsOverHttps参数：启用DNS over HTTPS（DoH）加密解析
- 配置happyEyeballOnDnsRule参数：启用Happy Eyeball竞速连接，优化多IP地址连接性能

**适用设备**：
- Phone、2in1、Tablet、Wearable（起始版本：4.1.0(11)）
- TV（起始版本：5.1.1(19)）
- Car（起始版本：6.1.0(23)）

## 使用场景

### 触发词
- "配置DNS服务器"
- "定制DNS解析"
- "设置静态DNS"
- "自定义DNS规则"
- "DNS over HTTPS"
- "DoH配置"
- "优化DNS解析"

### 能做
- 配置自定义DNS服务器（指定IP和端口）
- 设置静态DNS映射规则（域名→IP地址）
- 实现动态DNS解析函数（根据hostname和port返回IP）
- 启用DNS over HTTPS加密解析
- 配置Happy Eyeball竞速连接优化多IP连接性能
- 在Session级别或Request级别配置DNS规则

### 绝不做
- 不处理DNS缓存管理（使用系统默认缓存机制）
- 不配置DNS服务器以外的网络参数
- 不替代系统DNS解析（仅作为定制补充）
- 不处理DNS劫持防护（需要配合其他安全配置）

### 补充
- 针对同一域名配置多个静态或动态DNS规则后，默认仅最后一个IP生效，需设置happyEyeballOnDnsRule=true让多个IP同时生效（从6.0.0(20)版本开始支持）
- DNS over HTTPS配置后优先使用DNS服务器解析的地址
- 静态DNS优先级高于动态DNS，动态DNS优先级高于自定义DNS服务器

## 调用规范和规则

### 输入约束
- DNS服务器IP地址：必须为有效的IPv4或IPv6地址字符串
- DNS服务器端口：取值范围[0, 65535]，默认值为53
- 静态DNS规则：host必须为有效域名，port范围[0, 65535]，ipAddresses必须为有效的IP地址数组
- 动态DNS函数：必须返回IpAddress[]类型数组，不能返回null或undefined
- 会话实例数量：最大1024个（从5.1.0(18)版本开始），需及时关闭会话释放资源

### 执行约束
- DNS配置必须在创建Session或Request时设置，不能在请求过程中动态修改
- Session级别的DNS配置适用于该会话下的所有请求
- Request级别的DNS配置覆盖Session级别的配置
- DNS解析超时：遵循TransferConfiguration.timeout配置的connectMs参数
- 会话关闭后DNS配置失效，需重新创建会话配置

### 内容约束
- 禁止使用无效IP地址（如空字符串、格式错误的地址）
- 禁止配置超过1024个会话实例（会触发错误码1007900994）
- 禁止在DNS函数中使用阻塞操作（如同步网络请求）
- 禁止在DNS函数中抛出异常（必须返回有效数组）

### 降级约束
- DNS服务器不可达：自动降级使用系统默认DNS
- DNS解析失败：返回空数组或系统DNS解析结果
- DNS over HTTPS失败：降级使用普通DNS解析（需设置skipCertificatesValidation=true跳过证书验证）
- 会话数量超限：提示用户关闭不必要会话或等待会话释放

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 验证设备类型和API版本是否支持定制DNS能力
2. 验证DNS服务器IP地址格式（IPv4或IPv6）
3. 验证端口范围是否在[0, 65535]内
4. 验证会话实例数量是否未超过1024个上限

**参数准备**：
```typescript
// 示例1：准备自定义DNS服务器参数
const dnsServerConfig: rcp.DnsConfiguration = {
  dnsRules: [
    { ip: '8.8.8.8', port: 53 },  // Google DNS
    { ip: '1.1.1.1', port: 53 }   // Cloudflare DNS
  ]
};

// 示例2：准备静态DNS规则参数
const staticDnsConfig: rcp.DnsConfiguration = {
  dnsRules: [
    {
      host: 'example.com',
      port: 443,
      ipAddresses: ['192.168.1.100', '192.168.1.101']
    }
  ],
  happyEyeballOnDnsRule: true  // 启用多IP竞速连接（6.0.0(20)+）
};

// 示例3：准备动态DNS规则参数
const dynamicDnsConfig: rcp.DnsConfiguration = {
  dnsRules: (host: string, port: number): rcp.IpAddress[] => {
    if (host === 'api.example.com' && port === 443) {
      return ['10.0.0.1', '10.0.0.2'];
    }
    return [];  // 返回空数组使用系统DNS
  }
};

// 示例4：准备DNS over HTTPS参数
const dohConfig: rcp.DnsConfiguration = {
  dnsOverHttps: {
    url: 'https://dns.google/dns-query',
    skipCertificatesValidation: false
  }
};
```

### 步骤2：导入模块和创建会话

**导入必要模块**：
```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

**创建会话并配置DNS**：
```typescript
// 方式1：在Session创建时配置DNS（适用于会话内所有请求）
const session = rcp.createSession({
  requestConfiguration: {
    dns: dnsServerConfig  // 使用自定义DNS服务器
  }
});

// 方式2：创建基础会话，在请求时配置DNS
const session = rcp.createSession();
```

### 步骤3：创建请求并设置DNS配置

**创建请求对象**：
```typescript
const request = new rcp.Request('https://example.com/api/data');
```

**在请求级别配置DNS（覆盖Session配置）**：
```typescript
request.configuration = {
  dns: staticDnsConfig  // 使用静态DNS规则
};
```

### 步骤4：发送请求和处理响应

**发送HTTP请求**：
```typescript
session.fetch(request).then((response: rcp.Response) => {
  console.info(`Request succeeded with status: ${response.statusCode}`);
  console.info(`Response headers: ${JSON.stringify(response.headers)}`);
  
  // 处理响应数据
  if (response.body) {
    console.info(`Response body length: ${response.body.byteLength}`);
  }
  
  // 关闭会话释放资源
  session.close();
}).catch((err: BusinessError) => {
  console.error(`Request failed with error code: ${err.code}`);
  console.error(`Error message: ${err.data}`);
  
  // 错误处理后关闭会话
  session.close();
});
```

### 步骤5：错误处理

**常见错误码处理**：
```typescript
try {
  const response = await session.fetch(request);
  console.info(`Response status: ${response.statusCode}`);
  session.close();
} catch (error) {
  const err = error as BusinessError;
  
  switch (err.code) {
    case 401:
      console.error('Parameter error: Invalid DNS configuration');
      // 检查DNS配置参数格式
      break;
    case 1007900994:
      console.error('Sessions number reached limit (max 1024)');
      // 关闭不必要会话或等待会话释放
      break;
    default:
      console.error(`Unknown error: ${err.code}, ${err.data}`);
      // 降级使用系统DNS
      request.configuration = undefined;  // 清除DNS配置
      break;
  }
  
  session.close();
}
```

### 步骤6：降级处理

**DNS解析失败降级方案**：
```typescript
async function fetchWithDnsFallback(
  session: rcp.Session,
  request: rcp.Request
): Promise<rcp.Response> {
  try {
    // 尝试使用自定义DNS
    return await session.fetch(request);
  } catch (error) {
    const err = error as BusinessError;
    console.warn(`Custom DNS failed, falling back to system DNS`);
    
    // 降级方案：清除DNS配置使用系统DNS
    request.configuration = {
      dns: undefined  // 使用系统默认DNS
    };
    
    try {
      return await session.fetch(request);
    } catch (fallbackError) {
      console.error('System DNS also failed');
      throw fallbackError;
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误：DNS配置参数格式不正确 | 检查DNS服务器IP地址格式、端口范围、静态规则参数有效性 |
| 1007900994 | 会话数量达到上限（1024个） | 关闭不必要会话释放资源，或在请求完成后及时调用session.close() |
| 网络错误 | DNS服务器不可达或解析超时 | 降级使用系统DNS，检查网络连接状态 |
| DNS解析错误 | 返回无效IP地址 | 验证DNS函数返回值格式，确保返回有效的IpAddress[]数组 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.RemoteCommunicationKit": "^4.1.0",
    "@kit.BasicServicesKit": "^4.1.0"
  }
}
```

### 环境要求
- HarmonyOS SDK：最低版本4.1.0(11)
- 设备类型：Phone、2in1、Tablet、Wearable、TV（5.1.1+）、Car（6.1.0+）
- 权限要求：ohos.permission.INTERNET

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.RemoteCommunicationKit'
```
**解决方法**：检查HarmonyOS SDK版本是否>=4.1.0(11)，确保项目依赖正确配置

**问题2：类型定义错误**
```
Type 'DnsServers' is not assignable to type 'DnsConfiguration'
```
**解决方法**：检查dnsRules参数类型，确保使用正确的类型：DnsServers | StaticDnsRules | DynamicDnsRule

**问题3：Happy Eyeball参数未生效**
```
Property 'happyEyeballOnDnsRule' does not exist
```
**解决方法**：检查API版本是否>=6.0.0(20)，该参数仅在6.0.0+版本支持

## 常见问题与解决方法

### Q1：配置多个DNS服务器后仅最后一个生效？
**原因**：默认情况下，多个静态或动态DNS规则配置后仅最后一个IP生效  
**解决方法**：
- 从6.0.0(20)版本开始，设置`happyEyeballOnDnsRule=true`启用多IP竞速连接
- 或使用数组配置多个DNS服务器（DnsServers类型）

### Q2：DNS over HTTPS配置失败？
**原因**：证书验证失败或DoH服务器不可达  
**解决方法**：
- 设置`skipCertificatesValidation=true`跳过证书验证（仅测试环境）
- 检查DoH URL是否正确（如：https://dns.google/dns-query）
- 确认DoH服务器支持DNS查询协议

### Q3：会话数量超限错误？
**原因**：创建的Session实例数量超过1024个上限  
**解决方法**：
- 在请求完成后及时调用`session.close()`释放资源
- 避免创建不必要的会话实例
- 使用会话池管理会话实例

### Q4：动态DNS函数返回错误？
**原因**：DNS函数返回null、undefined或无效IP地址  
**解决方法**：
- 确保DNS函数始终返回IpAddress[]类型数组
- 无法解析时返回空数组[]，系统自动使用默认DNS
- 验证返回的IP地址格式为有效的IPv4或IPv6字符串

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "dnsConfiguration": {
    "type": "StaticDnsRules | DnsServers | DynamicDnsRule",
    "rulesCount": 2,
    "happyEyeballEnabled": true
  },
  "response": {
    "statusCode": 200,
    "headers": {...},
    "bodySize": 1024
  },
  "apiUsed": [
    "rcp.createSession",
    "rcp.Request",
    "rcp.Session.fetch",
    "rcp.Session.close",
    "rcp.DnsConfiguration",
    "rcp.StaticDnsRules",
    "rcp.DnsServers",
    "rcp.DynamicDnsRule"
  ]
}
```

## 参考文档

- [API开发指南](references/remote-communication-customdnsconfig.md)
- [API参考说明](references/remote-communication-rcp.md)

## 完整示例代码

- [定制DNS服务器示例](assets/custom_dns_server.ets)
- [静态DNS规则示例](assets/static_dns_rules.ets)
- [动态DNS函数示例](assets/dynamic_dns_function.ets)
- [DNS over HTTPS示例](assets/dns_over_https.ets)

## 测试用例

### 正向测试用例
- [配置单个DNS服务器](tests/test_positive.py)：验证单个DNS服务器配置成功
- [配置多个静态DNS规则](tests/test_positive.py)：验证多域名静态映射配置
- [配置动态DNS函数](tests/test_positive.py)：验证动态解析函数返回正确IP

### 边界测试用例
- [配置最大端口65535](tests/test_boundary.py)：验证端口边界值
- [配置1024个会话实例](tests/test_boundary.py)：验证会话数量上限

### 异常测试用例
- [配置无效IP地址](tests/test_exception.py)：验证错误IP格式处理
- [DNS服务器不可达](tests/test_exception.py)：验证降级方案生效
- [会话数量超限](tests/test_exception.py)：验证错误码1007900994处理