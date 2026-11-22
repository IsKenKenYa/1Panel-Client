---
name: hmos-remote-communication-kit-security-configuration
description: 定制HTTP安全传输行为,支持客户端校验服务端证书和服务端校验客户端证书,包含system/skip/CertificateAuthority/ValidationCallback多种证书校验方式,支持证书锁定功能,适用于HTTPS安全通信、自定义证书校验场景
---

# SecurityConfiguration定制安全传输行为技能

## 功能描述

SecurityConfiguration是Remote Communication Kit提供的用于定制安全传输行为的配置工具。通过该配置,开发者可以实现:

- **客户端校验服务端证书**: 使用系统默认证书、跳过证书校验、指定证书内容/文件路径/目录、自定义证书校验逻辑
- **服务端校验客户端证书**: 支持PEM/DER/P12多种证书格式
- **证书锁定**: 通过公钥SHA256哈希值限定可信任的证书范围
- **TLS配置**: 支持TLS版本选择和加密套件配置

通过合理的安全配置,可以显著降低应用程序遭受中间人攻击、证书伪造等安全风险。

## 使用场景

### 触发词
- "HTTPS证书校验"
- "自定义证书验证"
- "客户端证书配置"
- "证书锁定"
- "安全传输配置"
- "SecurityConfiguration"

### 能做
- 配置客户端校验服务端证书的多种方式(系统默认、跳过、指定证书、自定义校验)
- 配置服务端校验客户端证书(PEM/DER/P12格式)
- 实现证书锁定功能
- 配置TLS版本和加密套件
- 自定义证书校验逻辑(ValidationCallback)

### 绝不做
- 不处理非HTTP/HTTPS协议的安全配置
- 不处理非证书相关的安全设置(如数据加密、签名验证等)
- 不处理超出SecurityConfiguration接口范围的安全需求

### 补充
- 定制安全传输行为能力支持Phone、2in1、Tablet、Wearable设备
- 从5.1.1(19)开始新增支持TV设备
- 从6.1.0(23)开始新增支持Car设备
- 需要导入@kit.RemoteCommunicationKit模块
- 自定义证书校验还需要导入@kit.NetworkKit模块

## 调用规范和规则

### 输入约束
- URL: 必须是有效的HTTPS地址格式
- 证书内容: PEM格式字符串或ArrayBuffer二进制数据
- 证书文件路径: 必须是有效的沙箱路径
- 证书类型: PEM、DER或P12格式
- 公钥哈希: SHA256哈希值的BASE64编码字符串

### 执行约束
- 证书校验失败时请求会中断
- 自定义证书校验函数必须返回Promise<boolean>
- Session实例数量从5.1.0(18)起增加到1024个(之前为16个)
- 请求完成后必须关闭Session释放资源

### 内容约束
- 禁止使用无效的证书格式
- 禁止使用不存在的证书文件路径
- 禁止在自定义校验函数中使用高危操作(eval、exec等)
- 禁止跳过证书校验在生产环境中使用('skip'仅用于开发测试)

### 降级约束
- 证书校验失败: 记录错误日志,返回错误信息给调用方
- 证书文件不存在: 提示文件路径错误,使用系统默认证书作为备选
- 自定义校验函数异常: 捕获异常,拒绝请求并记录错误信息
- TLS版本不支持: 使用系统默认TLS配置

## 调用流程和步骤

### 步骤1: 导入必要模块

```typescript
// 导入Remote Communication Kit
import { rcp } from '@kit.RemoteCommunicationKit';

// 如果使用自定义证书校验,还需导入Network Kit
import { networkSecurity } from '@kit.NetworkKit';

// 如果使用二进制证书内容,还需导入ArkTS工具
import { util } from '@kit.ArkTS';
```

### 步骤2: 创建Session和Request

```typescript
// 创建HTTP会话
const session = rcp.createSession();

// 创建HTTP请求对象
const request = new rcp.Request('https://example.com'); // 替换为实际的HTTPS地址
```

### 步骤3: 配置SecurityConfiguration

#### 3.1 客户端校验服务端证书 - 使用系统默认证书

```typescript
request.configuration = {
  security: {
    remoteValidation: 'system', // 使用系统默认CA证书
  }
};

try {
  const response = await session.fetch(request);
  console.info(`响应状态码: ${response.statusCode}`);
  console.info(`响应内容: ${response.toString()}`);
} catch (err) {
  console.error(`请求失败: 错误码 ${err.code}, 错误信息 ${err.data}`);
} finally {
  session.close(); // 必须关闭Session释放资源
}
```

#### 3.2 客户端校验服务端证书 - 跳过证书校验(仅开发测试)

```typescript
request.configuration = {
  security: {
    remoteValidation: 'skip', // 跳过证书校验 - 仅用于开发测试
  }
};

try {
  const response = await session.fetch(request);
  console.info(`响应状态码: ${response.statusCode}`);
} catch (err) {
  console.error(`请求失败: ${err.code}`);
} finally {
  session.close();
}
```

#### 3.3 客户端校验服务端证书 - 使用字符串指定证书内容

```typescript
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

request.configuration = {
  security: {
    remoteValidation: {
      content: PEM_CA, // PEM格式证书内容
    }
  }
};

try {
  const response = await session.fetch(request);
  console.info(`响应状态码: ${response.statusCode}`);
} catch (err) {
  console.error(`证书校验失败: ${err.code}`);
} finally {
  session.close();
}
```

#### 3.4 客户端校验服务端证书 - 使用二进制指定证书内容

```typescript
const PEM_CA = '-----BEGIN CERTIFICATE-----\n...' // PEM证书内容
const buffer = new ArrayBuffer(PEM_CA.length);
util.TextEncoder.create('utf-8').encodeIntoUint8Array(PEM_CA, new Uint8Array(buffer));

request.configuration = {
  security: {
    remoteValidation: {
      content: buffer, // ArrayBuffer类型证书内容
    }
  }
};

try {
  const response = await session.fetch(request);
  console.info(`响应状态码: ${response.statusCode}`);
} catch (err) {
  console.error(`请求失败: ${err.code}`);
} finally {
  session.close();
}
```

#### 3.5 客户端校验服务端证书 - 使用文件指定证书

**准备证书文件(使用OpenSSL生成)**:
```bash
openssl x509 -subject_hash -in ./example.pem
# 输出第一行为文件名(如dd8e9d41),保存为dd8e9d41.0文件
```

```typescript
request.configuration = {
  security: {
    remoteValidation: {
      filePath: '/data/storage/el1/bundle/entry/resources/resfile/dd8e9d41.0', // 证书文件沙箱路径
    }
  }
};

try {
  const response = await session.fetch(request);
  console.info(`响应状态码: ${response.statusCode}`);
} catch (err) {
  console.error(`证书文件读取失败: ${err.code}`);
} finally {
  session.close();
}
```

#### 3.6 客户端校验服务端证书 - 使用文件目录指定证书

```typescript
request.configuration = {
  security: {
    remoteValidation: {
      folderPath: '/data/storage/el1/bundle/entry/resources/resfile/', // 证书目录沙箱路径
    }
  }
};

try {
  const response = await session.fetch(request);
  console.info(`响应状态码: ${response.statusCode}`);
} catch (err) {
  console.error(`证书目录读取失败: ${err.code}`);
} finally {
  session.close();
}
```

#### 3.7 客户端校验服务端证书 - 自定义证书校验

```typescript
// 日期格式化辅助函数
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
  // 服务器未返回证书,校验失败
  let length = context.pemCerts.length;
  if (length <= 0) {
    return Promise.reject('服务器未返回证书');
  }
  
  // 最后一个证书为根证书,根据实际情况调整
  const firstCaBlob: networkSecurity.CertBlob = {
    type: networkSecurity.CertType.CERT_TYPE_PEM,
    data: context.pemCerts[length - 1],
  };
  
  // 使用系统默认CA验证
  if (networkSecurity.certVerificationSync(firstCaBlob) !== 0) {
    return Promise.reject('证书验证失败');
  }
  
  // 校验证书日期
  for (const x of context.x509Certs) {
    let dateStr = getASNDateString();
    try {
      x.checkValidityWithDate(dateStr);
    } catch (e) {
      return Promise.reject('证书日期校验失败');
    }
  }
  
  // 校验成功
  return Promise.resolve(true);
}

// 配置自定义证书校验
request.configuration = {
  security: {
    remoteValidation: ValidationRemoteServer, // 自定义校验函数
  }
};

try {
  const response = await session.fetch(request);
  console.info(`响应状态码: ${response.statusCode}`);
} catch (err) {
  console.error(`自定义证书校验失败: ${err.code}`);
} finally {
  session.close();
}
```

#### 3.8 服务端校验客户端证书 - PEM类型

**生成PEM证书(使用OpenSSL)**:
```bash
openssl genrsa -out cert.key 2048
openssl req -new -key cert.key -out cert.csr
openssl x509 -req -in cert.csr -out cert.crt -signkey cert.key -CAcreateserial -days 3650
openssl x509 -in cert.crt -out cert.pem -outform PEM
```

```typescript
request.configuration = {
  security: {
    certificate: {
      filePath: '/data/storage/el1/bundle/entry/resources/resfile/cert.pem', // PEM证书路径
      type: 'PEM', // PEM类型
      key: '/data/storage/el1/bundle/entry/resources/resfile/cert.key', // 私钥路径
      keyPassword: 'keyPassword', // 私钥密码(可选)
    }
  }
};

try {
  const response = await session.fetch(request);
  console.info(`响应状态码: ${response.statusCode}`);
} catch (err) {
  console.error(`客户端证书校验失败: ${err.code}`);
} finally {
  session.close();
}
```

#### 3.9 服务端校验客户端证书 - DER类型

**将PEM转换为DER**:
```bash
openssl x509 -in cert.pem -outform der -out cert.der
```

```typescript
request.configuration = {
  security: {
    certificate: {
      filePath: '/data/storage/el1/bundle/entry/resources/resfile/cert.der', // DER证书路径
      type: 'DER', // DER类型
      key: '/data/storage/el1/bundle/entry/resources/resfile/cert.key', // 私钥路径
      keyPassword: 'keyPassword', // 私钥密码(可选)
    }
  }
};

try {
  const response = await session.fetch(request);
  console.info(`响应状态码: ${response.statusCode}`);
} catch (err) {
  console.error(`客户端证书校验失败: ${err.code}`);
} finally {
  session.close();
}
```

#### 3.10 服务端校验客户端证书 - P12类型

**生成P12证书**:
```bash
openssl pkcs12 -export -out cert.p12 -inkey cert.key -in cert.pem
# 设置密码"1234"
```

```typescript
request.configuration = {
  security: {
    certificate: {
      filePath: '/data/storage/el1/bundle/entry/resources/resfile/cert.p12', // P12证书路径
      type: 'P12', // P12类型(P12证书已包含私钥)
      keyPassword: '1234', // P12证书密码
    }
  }
};

try {
  const response = await session.fetch(request);
  console.info(`响应状态码: ${response.statusCode}`);
} catch (err) {
  console.error(`客户端证书校验失败: ${err.code}`);
} finally {
  session.close();
}
```

#### 3.11 证书锁定(Certificate Pinning)

**获取证书公钥SHA256哈希值**:
```bash
# 获取证书公钥
openssl x509 -in example.pem -noout -pubkey | openssl asn1parse -noout -inform pem -out example.public.key

# 计算公钥SHA256哈希值的BASE64编码
openssl dgst -sha256 -binary example.public.key | openssl enc -base64
```

```typescript
const TEST_URL = 'https://example.com';
const RIGHT_EXAMPLE_PUBLIC_KEY_SHA256_HASH = [
  'iMMpIJdSf5VlClHaxZReyhaLxLsmZMMNAiA2pMR8/M4=', // 公钥SHA256哈希值1
  'qBRjZmOmkSNJL0p70zek7odSIzqs/muR4Jk9xYyCP+E=', // 公钥SHA256哈希值2
];

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
      },
    ]
  }
};

try {
  const response = await session.fetch(request);
  console.info(`证书锁定验证成功,状态码: ${response.statusCode}`);
} catch (e) {
  console.error(`证书锁定验证失败: ${JSON.stringify(e)}`);
} finally {
  session.close();
}
```

### 步骤4: 错误处理和资源释放

```typescript
async function secureHttpRequest(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com');
  
  // 配置安全选项
  request.configuration = {
    security: {
      remoteValidation: 'system', // 使用系统默认证书
    }
  };
  
  try {
    const response = await session.fetch(request);
    
    // 检查响应状态码
    if (response.statusCode >= 200 && response.statusCode < 300) {
      console.info(`请求成功: ${response.statusCode}`);
      console.info(`响应内容: ${response.toString()}`);
    } else {
      console.warn(`服务器返回错误: ${response.statusCode}`);
    }
    
  } catch (err) {
    // 错误处理
    const errorCode = err.code;
    const errorMsg = err.data;
    
    switch (errorCode) {
      case 401:
        console.error('参数错误: 请检查请求参数');
        break;
      case 1007900001:
        console.error('网络错误: 请检查网络连接');
        break;
      case 1007900002:
        console.error('证书校验失败: 请检查证书配置');
        break;
      case 1007900994:
        console.error('Session数量达到上限: 请关闭未使用的Session');
        break;
      default:
        console.error(`未知错误: 错误码 ${errorCode}, 错误信息 ${errorMsg}`);
    }
    
  } finally {
    // 必须关闭Session释放资源
    session.close();
    console.info('Session已关闭');
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误 | 检查请求参数是否正确,包括URL、证书路径等 |
| 1007900001 | 网络错误 | 检查网络连接是否正常,URL是否可访问 |
| 1007900002 | SSL/TLS握手失败 | 检查证书配置是否正确,证书格式是否支持 |
| 1007900003 | 证书验证失败 | 检查证书内容/路径是否正确,证书是否过期 |
| 1007900004 | 证书锁定验证失败 | 检查公钥哈希值是否正确匹配 |
| 1007900005 | 自定义证书校验失败 | 检查自定义校验函数逻辑是否正确 |
| 1007900994 | Session数量达到上限 | 关闭未使用的Session释放资源(5.1.0前上限16,之后上限1024) |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.RemoteCommunicationKit": ">=4.1.0(11)",
    "@kit.NetworkKit": ">=5.0.0(12)",
    "@kit.ArkTS": ">=5.0.0(12)"
  }
}
```

### 环境要求
- API版本: 4.1.0(11)及以上
- 设备类型: Phone、2in1、Tablet、Wearable(基础支持); TV(5.1.1+); Car(6.1.0+)
- 权限要求: ohos.permission.INTERNET(基础); ohos.permission.GET_NETWORK_INFO(使用cellular路径时需要)

### 常见编译问题

**问题1: 找不到@kit.RemoteCommunicationKit模块**
```
Error: Cannot find module '@kit.RemoteCommunicationKit'
```
**解决方法**: 确保API版本>=4.1.0(11),检查项目配置文件是否正确声明Kit依赖

**问题2: 证书文件路径不存在**
```
Error: File not found: /data/storage/el1/bundle/entry/resources/resfile/cert.pem
```
**解决方法**: 
1. 检查证书文件是否已放置在正确的沙箱路径
2. 使用文件管理API确认文件存在
3. 参考应用文件开发指南获取正确的沙箱路径

**问题3: OpenSSL命令执行失败**
```
Error: Unable to generate certificate
```
**解决方法**: 
1. 确保已安装OpenSSL工具
2. 检查命令参数是否正确
3. 在Windows系统执行OpenSSL命令后需按Enter键退出

**问题4: 证书格式不支持**
```
Error: Unsupported certificate type
```
**解决方法**: 
1. 检查证书type字段是否为PEM/DER/P12之一
2. 使用OpenSSL转换证书格式
3. 确认证书内容/文件路径配置正确

## 常见问题与解决方法

### Q1: 证书校验总是失败怎么办?
**原因**: 可能是证书配置不正确、证书过期或证书格式不支持
**解决方法**:
- 检查证书内容是否为有效的PEM格式
- 验证证书文件路径是否正确(使用沙箱路径)
- 确认证书未过期(使用OpenSSL检查: `openssl x509 -in cert.pem -text -noout`)
- 尝试使用'system'模式进行基础验证

### Q2: 如何获取证书公钥的SHA256哈希值?
**原因**: 需要计算证书锁定所需的公钥哈希值
**解决方法**:
```bash
# 步骤1: 获取证书公钥
openssl x509 -in example.pem -noout -pubkey | openssl asn1parse -noout -inform pem -out example.public.key

# 步骤2: 计算SHA256哈希值的BASE64编码
openssl dgst -sha256 -binary example.public.key | openssl enc -base64
```

### Q3: 自定义证书校验函数抛出异常怎么办?
**原因**: 校验函数中可能存在逻辑错误或未正确处理异常
**解决方法**:
- 在校验函数中使用try-catch捕获所有异常
- 确保校验函数返回Promise<boolean>或Promise.reject()
- 添加详细的日志记录帮助调试
- 测试各个校验步骤(证书存在性、格式、日期等)

### Q4: Session未关闭导致资源泄露怎么办?
**原因**: Session使用完成后未调用close()方法
**解决方法**:
- 在finally块中确保调用session.close()
- 建立Session生命周期管理规范
- 定期检查Session数量(5.1.0前上限16个,之后上限1024个)
- 使用Session监听器监控Session状态

### Q5: 如何在生产环境中配置安全传输?
**原因**: 生产环境需要更严格的安全配置
**解决方法**:
- 禁止使用'skip'跳过证书校验
- 使用CertificateAuthority指定可信证书
- 配置证书锁定防止中间人攻击
- 定期更新证书并检查有效期
- 使用自定义校验函数实现额外的安全检查

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "statusCode": 200,
  "responseBody": "响应内容字符串",
  "securityConfig": {
    "remoteValidation": "system|skip|CertificateAuthority|ValidationCallback",
    "certificateType": "PEM|DER|P12",
    "certificatePinning": "已启用|未启用"
  },
  "apiUsed": [
    "rcp.createSession",
    "rcp.Request",
    "session.fetch",
    "session.close",
    "networkSecurity.certVerificationSync",
    "networkSecurity.CertBlob"
  ]
}
```

## 参考文档

- [API开发指南: SecurityConfiguration定制安全传输行为](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/remote-communication-customsecurityconfig)
- [API参考: rcp模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)
- [API参考: SecurityConfiguration接口](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)
- [应用文件开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-file)

## 完整示例代码

- [ArkTS示例: 客户端校验服务端证书](assets/example_client_validation.ets)
- [ArkTS示例: 服务端校验客户端证书](assets/example_server_validation.ets)
- [ArkTS示例: 证书锁定](assets/example_certificate_pinning.ets)
- [ArkTS示例: 自定义证书校验](assets/example_custom_validation.ets)

## 测试用例

### 正向测试用例
- [测试使用系统默认证书校验](tests/test_system_certificate.py): 验证基础HTTPS通信功能
- [测试使用PEM证书内容校验](tests/test_pem_content.py): 验证PEM格式证书配置
- [测试使用文件路径证书校验](tests/test_file_path.py): 验证证书文件路径配置
- [测试证书锁定功能](tests/test_certificate_pinning.py): 验证证书锁定配置

### 边界测试用例
- [测试Session数量上限](tests/test_session_limit.py): 验证Session资源管理
- [测试证书过期场景](tests/test_expired_certificate.py): 验证过期证书处理
- [测试多种证书格式](tests/test_certificate_types.py): 验证PEM/DER/P12格式兼容性

### 异常测试用例
- [测试无效证书内容](tests/test_invalid_certificate.py): 验证无效证书的错误处理
- [测试证书文件不存在](tests/test_missing_file.py): 验证文件路径错误的处理
- [测试自定义校验异常](tests/test_custom_validation_error.py): 验证校验函数异常处理
- [测试证书锁定失败](tests/test_pinning_failure.py): 验证证书不匹配的错误处理