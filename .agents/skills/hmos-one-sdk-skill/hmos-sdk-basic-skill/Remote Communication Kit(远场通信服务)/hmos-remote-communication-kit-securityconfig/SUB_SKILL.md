---
name: hmos-remote-communication-kit-securityconfig
description: 配置HTTP请求的安全传输行为，支持客户端校验服务端证书、服务端校验客户端证书、证书锁定，适用于HTTPS安全通信场景
---

# SecurityConfiguration：定制安全传输行为技能

## 功能描述

本技能提供 HarmonyOS Remote Communication Kit 中 SecurityConfiguration 的完整配置能力，用于定制 HTTP 请求的安全传输行为。通过合理配置证书校验策略，可以显著增强应用程序的安全性，防止中间人攻击、数据泄露等安全风险。

**核心能力**：
- 客户端校验服务端证书（remoteValidation）：支持系统默认证书、跳过校验、自定义证书内容、文件路径、目录路径、自定义校验回调
- 服务端校验客户端证书（certificate）：支持 PEM/DER/P12 格式的客户端证书配置
- 证书锁定（certificatePinning）：通过公钥 SHA256 哈希值限定可信证书范围
- TLS 版本配置：支持 TLS 1.0-1.3 版本选择和范围配置
- 服务器身份验证：支持 Basic/Digest/NTLM 认证方式

## 使用场景

### 触发词
- "配置证书校验"
- "设置 HTTPS 安全"
- "客户端验证服务器证书"
- "服务器验证客户端证书"
- "证书锁定"
- "SecurityConfiguration"
- "自定义证书校验"

### 能做
- 配置客户端校验服务端证书的多种方式（系统默认、跳过、自定义证书）
- 配置服务端校验客户端证书（PEM/DER/P12 格式）
- 实现证书锁定功能（公钥 SHA256 哈希值验证）
- 配置 TLS 版本和加密套件
- 实现自定义证书校验逻辑（ValidationCallback）
- 配置服务器身份验证（Basic/Digest/NTLM）

### 绝不做
- 不处理非 HTTPS 协议的安全配置
- 不处理 SSL 协议（仅支持 TLS）
- 不处理证书生成和签发（仅配置证书校验）
- 不处理网络安全策略配置（需使用 NetworkSecurityKit）

### 补充
- 从 API 5.1.1(19) 开始支持 TV 设备
- 从 API 6.1.0(23) 开始支持 Car 设备
- 自定义证书校验（ValidationCallback）从 API 5.0.0(12) 开始支持
- 证书锁定从 API 5.0.0(12) 开始支持

## 调用规范和规则

### 输入约束
- 证书文件格式：PEM/DER/P12（客户端证书），PEM（CA证书）
- 证书内容：支持字符串或 ArrayBuffer 类型
- 证书路径：必须是有效的沙箱路径（参考应用文件指南）
- 公钥哈希值：必须是 SHA256 哈希值的 BASE64 编码
- TLS 版本：必须在 TLS 1.0-1.3 范围内
- 证书密码：可选，字符串类型

### 执行约束
- 最大证书文件大小：无明确限制，建议不超过 10MB
- 证书校验超时：遵循 HTTP 请求的超时设置
- 并发校验：支持多个并发请求的证书校验
- 校验失败处理：立即终止连接，抛出异常

### 内容约束
- 禁止使用过期或无效证书
- 禁止跳过证书校验在生产环境（仅用于开发测试）
- 禁止硬编码证书密码在代码中
- 禁止使用自签名证书在生产环境（除非有特殊安全需求）
- 禁止使用不安全的 TLS 版本（TLS 1.0/1.1）

### 降级约束
- 证书校验失败：记录错误日志，终止请求，提示用户检查证书配置
- 自定义校验异常：回退到系统默认 CA 校验
- 证书文件不存在：提示用户检查文件路径
- TLS 版本不兼容：自动降级到兼容的最高版本

## 调用流程和步骤

### 步骤1：准备阶段 - 选择证书校验方式

根据安全需求选择合适的证书校验方式：

**客户端校验服务端证书（remoteValidation）**：
- 'system'：使用系统默认 CA（推荐用于一般场景）
- 'skip'：跳过校验（仅用于开发测试，不推荐生产环境）
- CertificateAuthority：自定义 CA 证书（用于特殊安全需求）
- ValidationCallback：自定义校验逻辑（用于高级安全场景）

**服务端校验客户端证书（certificate）**：
- 配置客户端证书内容或路径
- 指定证书类型（PEM/DER/P12）
- 配置私钥和密码（可选）

### 步骤2：配置系统默认证书校验

使用系统默认 CA 校验服务端证书（最简单、最推荐的方式）：

```typescript
import { rcp } from '@kit.RemoteCommunicationKit';

async function testSystemValidation() {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com'); // 请替换为实际的 HTTPS 网址
  
  // 配置使用系统默认证书校验
  request.configuration = {
    security: {
      remoteValidation: 'system'
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info(`Response statusCode: ${JSON.stringify(response.statusCode)}`);
    console.info(`Response: ${JSON.stringify(response.toString())}`);
    return response;
  } catch (err) {
    console.error(`Request failed: error code is ${err.code}, error data is ${err.data}`);
    throw err;
  } finally {
    session.close();
  }
}
```

### 步骤3：跳过证书校验（仅用于开发测试）

**警告：此方式仅适用于开发测试环境，不推荐在生产环境使用！**

```typescript
import { rcp } from '@kit.RemoteCommunicationKit';

async function testSkipValidation() {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com'); // 请替换为实际的 HTTPS 网址
  
  // 配置跳过证书校验（仅用于开发测试）
  request.configuration = {
    security: {
      remoteValidation: 'skip' // ⚠️ 不安全，仅用于测试
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info(`Response statusCode: ${JSON.stringify(response.statusCode)}`);
    return response;
  } catch (err) {
    console.error(`Request failed: error code is ${err.code}, error data is ${err.data}`);
    throw err;
  } finally {
    session.close();
  }
}
```

### 步骤4：配置自定义 CA 证书（字符串方式）

使用 PEM 格式的 CA 证书内容：

```typescript
import { rcp } from '@kit.RemoteCommunicationKit';

const PEM_CA = '-----BEGIN CERTIFICATE-----\n' +
  'MIICPzCCAcWgAwIBAgIQBVVWvPJepDU1w6QP1atFcjAKBggqhkjOPQQDAzBhMQswCQYDVQQGEwJV\n' +
  'UzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSAwHgYD\n' +
  'VQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBHMzAeFw0xMzA4MDExMjAwMDBaFw0zODAxMTUxMjAw\n' +
  'MDBaMGExCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5k\n' +
  'aWdpY2VydC5jb20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IEczMHYwEAYHKoZIzj0C\n' +
  'AQYFK4EEACIDYgAE3afZu4q4C/sLfyHS8L6+c/MzXRq8NOrexpu80JX28MzQC7phW1FGfp4tn+6O\n' +
  'YwwX7Adw9c+ELkCDnOg/QW07rdOkFFk2eJ0DQ+4QE2xy3q6Ip6FrtUPOZ9wj/wMco+I+o0IwQDAP\n' +
  'BgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIBhjAdBgNVHQ4EFgQUs9tIpPmhxdiuNkHMEWNp\n' +
  'Yim8S8YwCgYIKoZIzj0EAwMDaAAwZQIxAK288mw/EkrRLTnDCgmXc/SINoyIJ7vmiI1Qhadj+Z4y\n' +
  '3maTD/HMsQmP3Wyr+mt/oAIwOWZbwmSNuJ5Q3KjVSaLtx9zRSX8XAbjIho9OjIgrqJqpisXRAL34\n' +
  'VOKa5Vt8sycX\n' +
  '-----END CERTIFICATE-----';

async function testCustomCACertificate() {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com'); // 请替换为实际的 HTTPS 网址
  
  // 配置自定义 CA 证书内容（字符串方式）
  request.configuration = {
    security: {
      remoteValidation: {
        content: PEM_CA
      }
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info(`Response statusCode: ${JSON.stringify(response.statusCode)}`);
    return response;
  } catch (err) {
    console.error(`Request failed: error code is ${err.code}, error data is ${err.data}`);
    throw err;
  } finally {
    session.close();
  }
}
```

### 步骤5：配置自定义 CA 证书（二进制方式）

使用 ArrayBuffer 格式的 CA 证书内容：

```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
import { util } from '@kit.ArkTS';

const PEM_CA = '-----BEGIN CERTIFICATE-----\n...' // 完整的 PEM 证书内容

async function testBinaryCACertificate() {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com'); // 请替换为实际的 HTTPS 网址
  
  // 将 PEM 证书转换为 ArrayBuffer
  const buffer = new ArrayBuffer(PEM_CA.length);
  util.TextEncoder.create('utf-8').encodeIntoUint8Array(PEM_CA, new Uint8Array(buffer));
  
  // 配置自定义 CA 证书内容（二进制方式）
  request.configuration = {
    security: {
      remoteValidation: {
        content: buffer
      }
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info(`Response statusCode: ${JSON.stringify(response.statusCode)}`);
    return response;
  } catch (err) {
    console.error(`Request failed: error code is ${err.code}, error data is ${err.data}`);
    throw err;
  } finally {
    session.close();
  }
}
```

### 步骤6：配置自定义 CA 证书（文件路径方式）

使用证书文件路径配置：

```typescript
import { rcp } from '@kit.RemoteCommunicationKit';

async function testFilePathCACertificate() {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com'); // 请替换为实际的 HTTPS 网址
  
  // 配置自定义 CA 证书文件路径
  // 注意：路径必须是有效的沙箱路径，参考应用文件指南
  request.configuration = {
    security: {
      remoteValidation: {
        filePath: '/data/storage/el1/bundle/entry/resources/resfile/dd8e9d41.0' // 替换为实际的证书文件路径
      }
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info(`Response statusCode: ${JSON.stringify(response.statusCode)}`);
    return response;
  } catch (err) {
    console.error(`Request failed: error code is ${err.code}, error data is ${err.data}`);
    throw err;
  } finally {
    session.close();
  }
}
```

**证书文件准备步骤**：
1. 使用 OpenSSL 生成证书文件：
   ```bash
   openssl x509 -subject_hash -in ./example.pem
   ```
2. 将输出保存为文件（例如 dd8e9d41.0）
3. 将证书文件放入应用的资源目录

### 步骤7：配置自定义 CA 证书（目录路径方式）

使用证书目录配置（支持多个 CA 证书）：

```typescript
import { rcp } from '@kit.RemoteCommunicationKit';

async function testFolderPathCACertificate() {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com'); // 请替换为实际的 HTTPS 网址
  
  // 配置自定义 CA 证书目录路径
  // 目录中的所有证书文件都会被加载用于校验
  request.configuration = {
    security: {
      remoteValidation: {
        folderPath: '/data/storage/el1/bundle/entry/resources/resfile/' // 替换为实际的证书目录路径
      }
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info(`Response statusCode: ${JSON.stringify(response.statusCode)}`);
    return response;
  } catch (err) {
    console.error(`Request failed: error code is ${err.code}, error data is ${err.data}`);
    throw err;
  } finally {
    session.close();
  }
}
```

### 步骤8：配置自定义证书校验逻辑（ValidationCallback）

实现高级自定义校验逻辑：

```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
import { networkSecurity } from '@kit.NetworkKit';

// 辅助函数：生成 ASN.1 格式的日期字符串
function makeItTwoChar(s: string): string {
  if (s.length === 1) {
    return '0' + s;
  }
  return s;
}

function getASNDateString(): string {
  const date = new Date();
  let dateStr = date.getFullYear().toString().slice(2);
  dateStr += makeItTwoChar((date.getMonth() + 1).toString());
  dateStr += makeItTwoChar(date.getDate().toString());
  dateStr += makeItTwoChar(date.getHours().toString());
  dateStr += makeItTwoChar(date.getMinutes().toString());
  dateStr += makeItTwoChar(date.getSeconds().toString());
  return dateStr + 'Z';
}

// 自定义证书校验函数
async function ValidationRemoteServer(context: rcp.ValidationContext): Promise<boolean> {
  // 检查服务器是否返回证书
  let length = context.pemCerts.length;
  if (length <= 0) {
    return Promise.reject('Server did not return certificate');
  }
  
  // 获取根证书（通常是证书链的最后一个）
  const firstCaBlob: networkSecurity.CertBlob = {
    type: networkSecurity.CertType.CERT_TYPE_PEM,
    data: context.pemCerts[length - 1]
  };
  
  // 使用系统默认 CA 验证根证书
  if (networkSecurity.certVerificationSync(firstCaBlob) !== 0) {
    return Promise.reject('Certificate verification failed');
  }
  
  // 校验证书日期是否有效
  for (const x of context.x509Certs) {
    let dateStr = getASNDateString();
    try {
      x.checkValidityWithDate(dateStr);
    } catch (e) {
      return Promise.reject('Certificate date check failed');
    }
  }
  
  // 校验成功
  return Promise.resolve(true);
}

async function testCustomValidation() {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com'); // 请替换为实际的 HTTPS 网址
  
  // 配置自定义证书校验回调
  request.configuration = {
    security: {
      remoteValidation: ValidationRemoteServer
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info(`Response statusCode: ${JSON.stringify(response.statusCode)}`);
    return response;
  } catch (err) {
    console.error(`Request failed: error code is ${err.code}, error data is ${err.data}`);
    throw err;
  } finally {
    session.close();
  }
}
```

### 步骤9：配置客户端证书（PEM 格式）

配置服务端校验客户端证书（PEM 格式）：

```typescript
import { rcp } from '@kit.RemoteCommunicationKit';

async function testPEMClientCertificate() {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com'); // 请替换为实际的 HTTPS 网址
  
  // 配置 PEM 格式的客户端证书
  request.configuration = {
    security: {
      certificate: {
        filePath: '/data/storage/el1/bundle/entry/resources/resfile/cert.pem', // 证书文件路径
        type: 'PEM',
        key: '/data/storage/el1/bundle/entry/resources/resfile/cert.key', // 私钥文件路径（可选）
        keyPassword: 'keyPassword' // 私钥密码（可选）
      }
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info(`Response statusCode: ${JSON.stringify(response.statusCode)}`);
    return response;
  } catch (err) {
    console.error(`Request failed: error code is ${err.code}, error data is ${err.data}`);
    throw err;
  } finally {
    session.close();
  }
}
```

**证书准备步骤**：
使用 OpenSSL 生成自签名证书（示例）：
```bash
openssl genrsa -out cert.key 2048
openssl req -new -key cert.key -out cert.csr
openssl x509 -req -in cert.csr -out cert.crt -signkey cert.key -CAcreateserial -days 3650
openssl x509 -in cert.crt -out cert.pem -outform PEM
```

### 步骤10：配置客户端证书（DER 格式）

配置 DER 格式的客户端证书：

```typescript
import { rcp } from '@kit.RemoteCommunicationKit';

async function testDERClientCertificate() {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com'); // 请替换为实际的 HTTPS 网址
  
  // 配置 DER 格式的客户端证书
  request.configuration = {
    security: {
      certificate: {
        filePath: '/data/storage/el1/bundle/entry/resources/resfile/cert.der', // 证书文件路径
        type: 'DER',
        key: '/data/storage/el1/bundle/entry/resources/resfile/cert.key', // 私钥文件路径（可选）
        keyPassword: 'keyPassword' // 私钥密码（可选）
      }
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info(`Response statusCode: ${JSON.stringify(response.statusCode)}`);
    return response;
  } catch (err) {
    console.error(`Request failed: error code is ${err.code}, error data is ${err.data}`);
    throw err;
  } finally {
    session.close();
  }
}
```

**证书格式转换**：
```bash
openssl x509 -in cert.pem -outform der -out cert.der
```

### 步骤11：配置客户端证书（P12 格式）

配置 P12 格式的客户端证书（包含私钥）：

```typescript
import { rcp } from '@kit.RemoteCommunicationKit';

async function testP12ClientCertificate() {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com'); // 请替换为实际的 HTTPS 网址
  
  // 配置 P12 格式的客户端证书
  // P12 证书已包含私钥，不需要单独配置 key
  request.configuration = {
    security: {
      certificate: {
        filePath: '/data/storage/el1/bundle/entry/resources/resfile/cert.p12', // 证书文件路径
        type: 'P12',
        keyPassword: '1234' // P12 证书密码（必须）
      }
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info(`Response statusCode: ${JSON.stringify(response.statusCode)}`);
    return response;
  } catch (err) {
    console.error(`Request failed: error code is ${err.code}, error data is ${err.data}`);
    throw err;
  } finally {
    session.close();
  }
}
```

**证书格式转换**：
```bash
openssl pkcs12 -export -out cert.p12 -inkey cert.key -in cert.pem
```

### 步骤12：配置证书锁定（Certificate Pinning）

使用公钥 SHA256 哈希值锁定可信证书：

```typescript
import { rcp } from '@kit.RemoteCommunicationKit';

const TEST_URL = 'https://example.com'; // 请替换为实际的 HTTPS 网址
const RIGHT_EXAMPLE_PUBLIC_KEY_SHA256_HASH = [
  'iMMpIJdSf5VlClHaxZReyhaLxLsmZMMNAiA2pMR8/M4=', // 替换为实际的公钥哈希值
  'qBRjZmOmkSNJL0p70zek7odSIzqs/muR4Jk9xYyCP+E=' // 替换为实际的公钥哈希值
];

async function testCertificatePinning() {
  const session = rcp.createSession();
  const request = new rcp.Request(TEST_URL);
  
  // 配置证书锁定
  request.configuration = {
    security: {
      certificatePinning: [
        {
          kind: 'public-key',
          publicKeyHash: RIGHT_EXAMPLE_PUBLIC_KEY_SHA256_HASH[0],
          hashAlgorithm: 'SHA-256'
        },
        {
          kind: 'public-key',
          publicKeyHash: RIGHT_EXAMPLE_PUBLIC_KEY_SHA256_HASH[1],
          hashAlgorithm: 'SHA-256'
        }
      ]
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info('Certificate pinning test succeeded: ' + response.statusCode);
    return response;
  } catch (e) {
    console.error('Certificate pinning test failed: ' + JSON.stringify(e));
    throw e;
  } finally {
    session.close();
  }
}
```

**获取公钥哈希值的步骤**：
1. 获取证书公钥：
   ```bash
   openssl x509 -in example.pem -noout -pubkey | openssl asn1parse -noout -inform pem -out example.public.key
   ```
2. 计算公钥 SHA256 哈希值的 BASE64 编码：
   ```bash
   openssl dgst -sha256 -binary example.public.key | openssl enc -base64
   ```

### 步骤13：错误处理和降级方案

完整的错误处理示例：

```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function testWithErrorHandling() {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com');
  
  request.configuration = {
    security: {
      remoteValidation: 'system'
    }
  };
  
  try {
    const response = await session.fetch(request);
    
    // 检查响应状态码
    if (response.statusCode >= 200 && response.statusCode < 300) {
      console.info(`Request succeeded: ${response.statusCode}`);
      return response;
    } else {
      console.warn(`Server returned error status: ${response.statusCode}`);
      // 根据业务需求处理错误状态码
      throw new Error(`HTTP error: ${response.statusCode}`);
    }
  } catch (err) {
    const error = err as BusinessError;
    
    // 根据错误码进行不同的处理
    switch (error.code) {
      case 401:
        console.error('Parameter error: invalid certificate configuration');
        // 降级方案：使用系统默认配置重新尝试
        request.configuration = {
          security: {
            remoteValidation: 'system'
          }
        };
        break;
      
      case 1007900001:
        console.error('Certificate verification failed: invalid or expired certificate');
        // 降级方案：提示用户检查证书配置
        throw new Error('Certificate verification failed. Please check your certificate configuration.');
      
      case 1007900002:
        console.error('Connection timeout: server did not respond');
        // 降级方案：增加超时时间重试
        if (request.configuration?.transfer?.timeout) {
          request.configuration.transfer.timeout.connectMs = 10000;
        }
        break;
      
      default:
        console.error(`Unknown error: code ${error.code}, message ${error.data}`);
        throw error;
    }
    
    // 重新尝试请求（可选）
    try {
      const retryResponse = await session.fetch(request);
      return retryResponse;
    } catch (retryErr) {
      console.error('Retry failed, giving up');
      throw retryErr;
    }
  } finally {
    session.close();
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误：证书配置无效 | 检查证书格式、路径、类型等参数是否正确 |
| 1007900001 | 证书校验失败：证书无效或过期 | 检查证书是否有效，更新证书或使用正确的 CA |
| 1007900002 | 连接超时 | 检查网络连接，增加超时时间配置 |
| 1007900003 | 证书锁定失败 | 检查公钥哈希值是否正确，更新哈希值配置 |
| 1007900004 | TLS 版本不兼容 | 调整 TLS 版本配置，使用兼容的版本 |
| 1007900005 | 客户端证书验证失败 | 检查客户端证书配置是否正确，确认服务器要求客户端证书 |
| 1007900994 | Session 数量达到上限 | 关闭不使用的 Session，释放资源 |

## 编译和修复问题

### 依赖声明

**模块导入**：
```typescript
import { rcp } from '@kit.RemoteCommunicationKit'; // 核心模块
import { networkSecurity } from '@kit.NetworkKit'; // 自定义证书校验时需要
import { util } from '@kit.ArkTS'; // ArrayBuffer 编码时需要
import { BusinessError } from '@kit.BasicServicesKit'; // 错误处理
```

**权限配置**（module.json5）：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET",
        "reason": "用于 HTTPS 网络请求"
      }
    ]
  }
}
```

### 环境要求
- HarmonyOS API 版本：≥ 4.1.0(11)（基础功能）
- 自定义证书校验（ValidationCallback）：≥ 5.0.0(12)
- 证书锁定（certificatePinning）：≥ 5.0.0(12)
- TV 设备支持：≥ 5.1.1(19)
- Car 设备支持：≥ 6.1.0(23)

### 常见编译问题

**问题1：导入模块错误**
```
Error: Cannot find module '@kit.RemoteCommunicationKit'
```
**解决方法**：
- 确保 HarmonyOS SDK 版本 ≥ 4.1.0(11)
- 检查项目配置文件是否正确引用了 RemoteCommunicationKit

**问题2：证书路径错误**
```
Error: Certificate file not found at path '/data/storage/...'
```
**解决方法**：
- 检查证书文件是否放置在正确的沙箱路径
- 参考[应用文件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-file)指南获取正确的路径
- 确保文件已正确打包到应用资源中

**问题3：证书格式错误**
```
Error: Invalid certificate format
```
**解决方法**：
- 确保证书格式与配置的 type 参数匹配（PEM/DER/P12）
- 使用 OpenSSL 验证证书格式：`openssl x509 -in cert.pem -text -noout`

**问题4：TLS 版本不兼容**
```
Error: TLS version not supported
```
**解决方法**：
- 检查服务器支持的 TLS 版本
- 调整 tlsOptions 或 tlsRange 配置，使用兼容的版本

## 常见问题与解决方法

### Q1：证书校验失败，提示 "Certificate verification failed"
**原因**：
- CA 证书与服务端证书不匹配
- 服务端证书过期或无效
- 使用了错误的证书链

**解决方法**：
- 确认使用的 CA 证书是否正确
- 检查服务端证书的有效期
- 使用系统默认证书（'system'）重新尝试
- 获取正确的证书链并配置

### Q2：跳过证书校验后仍然失败
**原因**：
- 网络连接问题
- 服务器地址错误
- 其他 HTTP 错误（非证书问题）

**解决方法**：
- 检查网络连接状态
- 确认 HTTPS URL 是否正确
- 检查其他 HTTP 配置（超时、代理等）

### Q3：客户端证书配置后服务器拒绝连接
**原因**：
- 客户端证书不匹配服务器要求
- 证书格式错误
- 私钥或密码配置错误

**解决方法**：
- 确认服务器是否要求客户端证书
- 检查证书类型是否正确（PEM/DER/P12）
- 验证私钥文件路径和密码是否正确
- 使用 OpenSSL 验证证书和私钥是否匹配

### Q4：证书锁定失败
**原因**：
- 公钥哈希值不匹配
- 服务器更换了证书
- 哈希值计算错误

**解决方法**：
- 重新计算公钥 SHA256 哈希值
- 确认服务器证书是否已更换
- 更新 certificatePinning 配置中的哈希值
- 添加多个可信哈希值（证书更新后仍可验证）

### Q5：自定义证书校验逻辑异常
**原因**：
- ValidationCallback 实现错误
- 缺少 networkSecurity 模块导入
- 证书处理逻辑错误

**解决方法**：
- 确保正确导入 networkSecurity 模块
- 检查 ValidationCallback 函数逻辑
- 确保正确处理证书链和日期校验
- 使用 try-catch 捕获校验过程中的异常

### Q6：Session 创建失败，提示 "Sessions number reached limit"
**原因**：
- 创建的 Session 实例超过上限（1024个）

**解决方法**：
- 及时关闭不使用的 Session（调用 session.close()）
- 复用 Session 实例进行多个请求
- 检查代码中是否有 Session 未正确关闭

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "message": "SecurityConfiguration configured successfully",
  "requestUrl": "https://example.com",
  "statusCode": 200,
  "securityConfig": {
    "remoteValidation": "system | custom | skip",
    "certificate": "configured | none",
    "certificatePinning": "enabled | disabled"
  },
  "apiUsed": [
    "rcp.createSession",
    "rcp.Request",
    "Session.fetch",
    "SecurityConfiguration",
    "CertificateAuthority",
    "ClientCertificate",
    "CertificatePinning"
  ]
}
```

## 参考文档

- [SecurityConfiguration：定制安全传输行为开发指南](references/remote-communication-customsecurityconfig.md)
- [Remote Communication Kit API 参考](references/remote-communication-rcp.md)

**相关文档链接**：
- [应用文件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-file) - 了解沙箱路径和文件访问
- [NetworkKit 证书校验](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-networksecurity) - 自定义证书校验时使用

## 完整示例代码

- [系统默认证书校验示例](assets/system-validation.ets)
- [自定义 CA 证书示例](assets/custom-ca-certificate.ets)
- [客户端证书配置示例](assets/client-certificate.ets)
- [证书锁定示例](assets/certificate-pinning.ets)
- [自定义校验逻辑示例](assets/custom-validation.ets)

## 测试用例

### 正向测试用例
- [test_system_validation](tests/test_positive.ets)：测试系统默认证书校验
- [test_custom_ca_certificate](tests/test_positive.ets)：测试自定义 CA 证书校验
- [test_client_certificate](tests/test_positive.ets)：测试客户端证书配置
- [test_certificate_pinning](tests/test_positive.ets)：测试证书锁定功能

### 边界测试用例
- [test_expired_certificate](tests/test_boundary.ets)：测试过期证书处理
- [test_invalid_certificate_path](tests/test_boundary.ets)：测试无效证书路径处理
- [test_max_certificate_size](tests/test_boundary.ets)：测试大证书文件处理
- [test_multiple_ca_certificates](tests/test_boundary.ets)：测试多个 CA 证书配置

### 异常测试用例
- [test_invalid_certificate_format](tests/test_exception.ets)：测试无效证书格式错误处理
- [test_missing_certificate](tests/test_exception.ets)：测试证书缺失错误处理
- [test_certificate_verification_failure](tests/test_exception.ets)：测试证书校验失败处理
- [test_tls_version_incompatible](tests/test_exception.ets)：测试 TLS 版本不兼容处理