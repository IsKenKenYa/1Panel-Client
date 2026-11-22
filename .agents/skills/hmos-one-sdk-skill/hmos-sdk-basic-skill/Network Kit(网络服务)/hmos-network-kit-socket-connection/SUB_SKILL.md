---
name: hmos-network-kit-socket-connection
description: Socket连接数据传输能力,支持TCP/UDP/Multicast/LocalSocket/TLS协议,最大文件大小无限制,适用于网络通信、进程间通信、加密传输场景
---

# Socket连接技能

## 功能描述

本技能提供Socket连接进行数据传输的能力,支持TCP、UDP、Multicast、LocalSocket、TLS等多种协议。主要功能包括:
- TCP/UDP客户端和服务端通信
- Multicast多播通信
- LocalSocket本地进程间通信
- TLS加密传输
- Socket代理设置

支持IPv4/IPv6网络协议,提供同步和异步调用方式,支持Worker线程和TaskPool线程执行网络操作。

## 使用场景

### 触发词
- "使用Socket访问网络"
- "TCP Socket连接"
- "UDP Socket通信"
- "多播通信"
- "本地Socket通信"
- "TLS加密传输"
- "Socket数据传输"
- "网络通信"

### 能做
- 创建和管理TCP/UDP Socket连接
- 实现客户端和服务端通信模式
- 进行多播组通信
- 实现本地进程间通信
- 提供TLS加密数据传输
- 设置Socket代理和超时参数
- 订阅和取消订阅Socket事件
- 处理Socket错误和异常

### 绝不做
- 不处理WebSocket协议(使用专门的WebSocket技能)
- 不处理HTTP请求(使用HTTP客户端技能)
- 不执行超出Network Kit范围的请求
- 不在UI线程执行耗时网络操作

### 补充
- 建议在Worker线程或TaskPool线程执行网络操作,避免UI线程卡顿
- 应用退后台后Socket可能断开,需重新创建
- TLS通信需要配置证书和密钥
- 多播IP地址范围为224.0.0.0到239.255.255.255

## 各个功能场景的区别

| 场景名称 | 功能描述 | 使用场景 | 限制条件 | API版本 | 技术特点 |
|---------|---------|---------|---------|---------|---------|
| TCP/UDP客户端通信 | 通过TCP/UDP Socket进行客户端数据传输 | 客户端主动连接服务器发送数据 | 需要ohos.permission.INTERNET权限 | API 7+ | 支持IPv4/IPv6,提供Promise和Callback两种方式 |
| TCP Socket Server | 服务端监听并接受客户端连接 | 服务端被动等待客户端连接 | 需要ohos.permission.INTERNET权限 | API 7+ | 支持多客户端连接,返回TCPSocketConnection对象 |
| Multicast Socket | 多播组内广播通信 | 组内设备之间广播形式通信 | 需要ohos.permission.INTERNET权限 | API 11+ | 基于UDP,支持TTL设置和环回模式 |
| LocalSocket客户端 | 本地进程间通信客户端 | 设备内进程间通信,无需网络 | 无需网络权限 | API 7+ | 使用本地套接字文件路径 |
| LocalSocket Server | 本地进程间通信服务端 | 监听本地进程连接请求 | 无需网络权限 | API 7+ | 创建本地套接字文件 |
| TLS Socket客户端 | TLS加密传输客户端 | 双向认证或单向认证加密通信 | 需要配置CA证书和密钥 | API 7+ | 支持TLSv12协议,可升级TCP为TLS |
| TLS Socket Server | TLS加密传输服务端 | TLS加密服务端监听 | 需要配置服务端证书 | API 7+ | 创建并初始化TLS会话 |

**关键区别**:
- **功能定位**: TCP/UDP用于网络通信,LocalSocket用于本地进程间通信,Multicast用于组播通信,TLS用于加密通信
- **使用场景**: 网络通信需要INTERNET权限,本地通信无需网络权限
- **技术特点**: TCP面向连接可靠传输,UDP无连接快速传输,TLS提供安全加密
- **性能差异**: TCP/UDP网络通信有网络延迟,LocalSocket本地通信速度更快

## 每个场景采用的技能方案

### TCP/UDP客户端通信
- **技能名称**: hmos-network-kit-tcp-udp-client
- **技能描述**: TCP/UDP客户端Socket连接和数据传输能力,支持IPv4/IPv6协议,适用于主动连接服务器发送数据场景
- **技能链接**: [查看详细技能](./tcp-udp-client/SKILL.md)

### TCP Socket Server
- **技能名称**: hmos-network-kit-tcp-server
- **技能描述**: TCP Socket Server服务端监听和接受客户端连接能力,支持多客户端连接管理,适用于服务端被动等待连接场景
- **技能链接**: [查看详细技能](./tcp-server/SKILL.md)

### Multicast Socket
- **技能名称**: hmos-network-kit-multicast
- **技能描述**: Multicast多播组通信能力,支持加入退出多播组、TTL设置、环回模式,适用于组内设备广播通信场景
- **技能链接**: [查看详细技能](./multicast/SKILL.md)

### LocalSocket客户端
- **技能名称**: hmos-network-kit-localsocket-client
- **技能描述**: LocalSocket本地进程间通信客户端能力,使用本地套接字文件路径,适用于设备内进程间通信场景
- **技能链接**: [查看详细技能](./localsocket-client/SKILL.md)

### LocalSocket Server
- **技能名称**: hmos-network-kit-localsocket-server
- **技能描述**: LocalSocket Server本地进程间通信服务端能力,创建本地套接字文件监听连接,适用于本地进程间通信服务端场景
- **技能链接**: [查看详细技能](./localsocket-server/SKILL.md)

### TLS Socket客户端
- **技能名称**: hmos-network-kit-tls-client
- **技能描述**: TLS Socket加密传输客户端能力,支持双向认证和单向认证,可升级TCP为TLS,适用于加密数据传输场景
- **技能链接**: [查看详细技能](./tls-client/SKILL.md)

### TLS Socket Server
- **技能名称**: hmos-network-kit-tls-server
- **技能描述**: TLS Socket Server加密传输服务端能力,创建TLS会话加载证书密钥,适用于TLS加密服务端监听场景
- **技能链接**: [查看详细技能](./tls-server/SKILL.md)

## 推荐技能的决策路由表

根据用户需求和触发词,自动推荐最适合的技能:

| 用户需求/触发词 | 推荐技能 | 推荐理由 | 优先级 |
|---------------|---------|---------|--------|
| TCP客户端连接 | hmos-network-kit-tcp-udp-client | 面向连接可靠传输,支持IPv4/IPv6 | 首选 |
| UDP客户端通信 | hmos-network-kit-tcp-udp-client | 无连接快速传输,支持广播 | 首选 |
| TCP服务端监听 | hmos-network-kit-tcp-server | 支持多客户端连接管理 | 首选 |
| 多播通信 | hmos-network-kit-multicast | 专为组播场景设计,支持TTL和环回 | 馀选 |
| 本地进程通信客户端 | hmos-network-kit-localsocket-client | 无需网络权限,本地通信速度快 | 馀选 |
| 本地进程通信服务端 | hmos-network-kit-localsocket-server | 创建本地套接字文件监听 | 馀选 |
| TLS加密客户端 | hmos-network-kit-tls-client | 提供安全加密,支持双向/单向认证 | 馀选 |
| TLS加密服务端 | hmos-network-kit-tls-server | TLS会话管理和证书配置 | 馀选 |
| 加密传输 | hmos-network-kit-tls-client | 自动推荐TLS加密传输 | 备选 |
| 进程间通信 | hmos-network-kit-localsocket-client | 自动推荐LocalSocket通信 | 备选 |

### 决策逻辑

**匹配流程**:
1. 根据用户输入的关键词匹配触发词
2. 优先匹配"首选"技能
3. 如果多个技能匹配,根据推荐理由和用户需求场景选择最合适的
4. 如果没有匹配的技能,提示用户明确需求

**优先级说明**:
- **首选技能**: 完全匹配用户需求,性能最优
- **备选技能**: 部分匹配或特殊场景使用
- **降级方案**: 找不到合适技能时的处理

## 调用规范和规则

### 输入约束
- 用户需求必须包含明确的通信场景关键词(如"TCP客户端"、"UDP服务端"等)
- 需求描述应清晰且可识别具体场景
- 避免模糊或过于宽泛的描述(如仅说"Socket通信")

### 执行约束
- 最大决策耗时: 5秒
- 最多推荐候选: 3个技能
- 必须提供推荐理由和场景对比

### 内容约束
- 禁止推荐不相关的技能
- 禁止跳过路由直接执行原子技能
- 禁止提供无效的技能链接
- 必须说明各场景的区别和适用情况

### 降级约束
- 找不到匹配技能: 提示用户明确需求并列出所有可用场景
- 技能链接失效: 提供技能名称并建议手动查找
- 多个技能匹配: 列出所有候选并说明差异

## 参考文档

- [Socket连接开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/socket-connection)
- [Socket API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-socket)
- [Socket错误码说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-net-socket)