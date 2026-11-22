# @security — 安全规则

检查加密算法的安全性，防止使用不安全的算法或密钥长度。覆盖 AES、RSA、Hash、MAC、DH、DSA、ECDSA、ECDH、HUKS、KDF、SM2、SM4、3DES 以及循环依赖、注释代码等。

## 规则集

- `plugin:@security/recommended` — 1 条
- `plugin:@security/all` — 8 条

> 13 条安全规则不在任何预设中，但可通过 `rules` 字段单独启用（见下方"预设外可用规则"）。

## 全部规则列表（21 条）

### 对称加密

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@security/no-unsafe-aes` | — | error | 禁止 AES 使用 ECB 模式；建议用 Petal Aegis SDK |
| `@security/no-unsafe-3des` | — | error | 禁止 3DES/ECB、DES、RC4 等不安全对称加密 |
| `@security/no-unsafe-sm4` | all | warn | 禁止 SM4 使用 ECB 模式 |

### 非对称加密（RSA）

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@security/no-unsafe-rsa-encrypt` | — | error | 禁止不安全 RSA 加密（模数<2048、PKCS1、MD5/SHA1） |
| `@security/no-unsafe-rsa-sign` | — | error | 禁止不安全 RSA 签名 |
| `@security/no-unsafe-rsa-key` | — | error | 禁止 RSA 密钥模数<2048 |

### 非对称加密（国密）

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@security/no-unsafe-sm2-cipher` | all | warn | 禁止 SM2 使用 MD5/SHA1 摘要 |
| `@security/no-unsafe-sm2-key` | all | warn | 禁止不安全 SM2 密钥长度 |

### 哈希/MAC

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@security/no-unsafe-hash` | — | error | 禁止 MD5、SHA1 等不安全哈希 |
| `@security/no-unsafe-mac` | — | error | 禁止 MAC 中使用 SHA1 |

### 密钥协商/签名

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@security/no-unsafe-dh` | — | error | 禁止 DH 模数<2048 |
| `@security/no-unsafe-dh-key` | — | error | 禁止不安全 DH 密钥 |
| `@security/no-unsafe-dsa` | — | error | 禁止 DSA 模数<2048 或 SHA1 摘要 |
| `@security/no-unsafe-dsa-key` | — | error | 禁止不安全 DSA 密钥 |
| `@security/no-unsafe-ecdsa` | — | error | 禁止 ECDSA 中使用 SHA1 |
| `@security/no-unsafe-ecdh` | all | warn | 禁止不安全 ECDH 密钥长度 |

### 密钥管理/派生

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@security/no-unsafe-huks` | all | warn | 禁止 HUKS 中使用 ECB、MD5、SHA1、NONE、PKCS1-V1_5 |
| `@security/no-unsafe-kdf` | all | warn | 禁止 PBKDF2/HKDF 中使用 SHA1 |

### 代码质量

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@security/no-commented-code` | recommended/all | warn | 删除注释掉的无效代码 |
| `@security/no-cycle` | — | error | 禁止循环依赖 |
| `@security/specified-interface-call-chain-check` | all | suggestion | 为指定接口识别调用链 |

## 示例

```json
{
  "ruleSet": ["plugin:@security/all"],
  "rules": {
    "@security/no-unsafe-aes": "error",
    "@security/no-unsafe-3des": "error",
    "@security/no-unsafe-rsa-encrypt": "error",
    "@security/no-unsafe-hash": "error",
    "@security/no-cycle": "error",
    "@security/no-commented-code": "warn"
  }
}
```
