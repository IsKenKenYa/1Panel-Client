---
name: hmos-remote-communication-kit-session-close
description: 关闭HTTP会话并释放资源+支持Phone/2in1/Tablet/Wearable/TV/Car设备+必须在请求完成后调用+适用于HTTP通信资源管理场景
---

# 关闭会话技能

## 功能描述

本技能提供关闭HTTP会话的功能，用于释放通信过程中占用的系统资源。当一个HTTP请求完成或失败后，应及时调用此技能关闭会话，释放内存、网络带宽、处理器时间等资源，清理缓存和连接状态，优化系统性能，并帮助系统从错误状态恢复。支持Phone、2in1、Tablet、Wearable设备，从API version 5.1.1(19)开始支持TV设备，从API version 6.1.0(23)开始支持Car设备。

## 使用场景

### 触发词
- "关闭HTTP会话"
- "释放HTTP资源"
- "关闭session"
- "结束HTTP通信"
- "清理网络连接"

### 能做
- 关闭已创建的HTTP会话（Session对象）
- 释放会话占用的系统资源（内存、网络带宽、处理器时间）
- 清理会话相关的内部状态信息（缓存、连接状态标志）
- 在请求成功完成后释放资源
- 在请求失败或超时后释放资源
- 防止资源泄漏和状态冲突

### 绝不做
- 不在请求过程中关闭会话（会中断正在进行的请求）
- 不重复关闭已关闭的会话
- 不关闭未创建的会话
- 不替代错误处理逻辑（应在错误处理后调用）

### 补充
- 必须在HTTP请求完成后（无论成功或失败）立即调用
- 自5.1.0(18)版本起，可创建的session实例数量增加到1024个，及时关闭session尤为重要
- 支持异步请求场景，可在Promise的then/catch回调中调用
- 调用close()后，Session对象不可再用于发起请求

## 调用规范和规则

### 输入约束
- Session对象：必须是已创建且未关闭的Session实例
- 调用时机：必须在HTTP请求完成后（fetch/get/post等方法的Promise完成后）
- 调用顺序：必须在创建Session后、且在请求完成后调用

### 执行约束
- 最大耗时：立即执行，耗时<1ms
- 资源释放：调用后立即释放所有关联资源
- 状态清理：清理所有会话状态信息
- 并发限制：无并发限制，可同时关闭多个Session

### 内容约束
- 禁止生成：不生成创建Session的代码（仅关闭）
- 禁止操作：不操作Session的configuration属性
- 禁止调用：不调用Session的其他方法（fetch/get/post等）在close之后

### 降级约束
- Session不存在：提示用户先创建Session
- Session已关闭：提示用户Session已关闭，无需重复操作
- 异步请求未完成：等待Promise完成后再关闭

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 验证Session对象已创建：检查session变量是否存在且不为null/undefined
2. 验证请求已完成：确保fetch/get/post等请求的Promise已resolve或reject
3. 验证Session未关闭：确认Session处于活跃状态（可选，调用close不会抛出异常）

**参数准备**：
```typescript
// 无需额外参数，仅需Session实例
const session = rcp.createSession();
// 发起请求并等待完成
```

### 步骤2：调用API

**示例代码**：
```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function closeSessionExample(): void {
  try {
    // 1. 创建会话
    const session = rcp.createSession();
    
    // 2. 创建Request对象
    let req = new rcp.Request("http://www.example.com/fetch", "GET");
    
    // 3. 发起网络请求
    session.fetch(req).then((response) => {
      // 4. 处理响应
      console.info(`Response succeeded: ${response}`);
      
      // 5. 请求成功后关闭会话
      session.close();
      console.info('Session closed successfully after request completed');
    }).catch((err: BusinessError) => {
      // 6. 错误处理
      console.error(`Response error code is ${err.code}, error data is ${err.data}`);
      
      // 7. 即使失败也要关闭会话，释放资源
      session.close();
      console.info('Session closed after error handling');
    });
  } catch (error) {
    console.error(`Unexpected error: ${error.message}`);
  }
}
```

### 步骤3：错误处理

```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function closeSessionWithErrorHandling(): void {
  const session = rcp.createSession();
  let req = new rcp.Request("http://www.example.com/fetch", "GET");
  
  try {
    const response = await session.fetch(req);
    console.info(`Request succeeded with status: ${response.statusCode}`);
    
    // 成功后关闭会话
    session.close();
  } catch (err) {
    const error = err as BusinessError;
    
    // 根据错误类型处理
    switch (error.code) {
      case 401:
        console.error('Parameter error: Invalid request parameters');
        break;
      case 1007900001:
        console.error('Network error: Connection failed');
        break;
      case 1007900002:
        console.error('Timeout error: Request timeout');
        break;
      default:
        console.error(`Unknown error: code=${error.code}, message=${error.message}`);
    }
    
    // 无论何种错误，都要关闭会话释放资源
    session.close();
    console.info('Session closed after error');
  }
}
```

### 步骤4：降级处理

```typescript
import { rcp } from '@kit.RemoteCommunicationKit';

async function closeSessionWithFallback(): void {
  let session: rcp.Session | null = null;
  
  try {
    // 尝试创建会话
    session = rcp.createSession();
    
    let req = new rcp.Request("http://www.example.com/fetch", "GET");
    const response = await session.fetch(req);
    
    console.info(`Response received: ${response.statusCode}`);
  } catch (error) {
    console.error(`Error occurred: ${error.message}`);
    
    // 降级方案：即使发生错误，也要确保资源释放
    if (session) {
      try {
        session.close();
        console.info('Session closed in fallback');
      } catch (closeError) {
        console.warn(`Failed to close session: ${closeError.message}`);
        // 最终降级：Session会在应用退出时自动清理
      }
    }
  } finally {
    // 确保无论如何都尝试关闭会话
    if (session) {
      session.close();
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 无 | close()方法无错误码返回 | 调用成功即返回void，失败时不会有异常抛出 |
| 401 | 参数错误（仅createSession时） | 检查SessionConfiguration参数类型和格式 |
| 1007900994 | Session数量达到上限（仅createSession时） | 关闭不需要的Session后再创建新Session |

注意：close()方法本身不返回错误码，调用即成功释放资源。错误码主要出现在createSession和fetch等请求方法中。

## 编译和修复问题

### 依赖声明

**oh-package.json5**：
```json
{
  "dependencies": {
    "@kit.RemoteCommunicationKit": "^4.1.0",
    "@kit.BasicServicesKit": "^4.1.0"
  }
}
```

**module.json5权限配置**：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET",
        "reason": "用于HTTP网络通信",
        "usedScene": {
          "abilities": ["MainAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

### 环境要求
- HarmonyOS API版本：≥4.1.0(11)
- DevEco Studio版本：≥4.0
- 设备类型：Phone、2in1、Tablet、Wearable（API 4.1.0+）、TV（API 5.1.1+）、Car（API 6.1.0+）

### 常见编译问题

**问题1：导入模块错误**
```
Error: Cannot find module '@kit.RemoteCommunicationKit' or its corresponding type declarations.
```
**解决方法**：
- 确保项目API版本≥4.1.0(11)
- 在oh-package.json5中添加依赖声明
- 运行`ohpm install`安装依赖

**问题2：Session类型未定义**
```
Error: Type 'Session' is not defined.
```
**解决方法**：
- 使用完整的类型路径：`rcp.Session`
- 或导入类型：`import { rcp, Session } from '@kit.RemoteCommunicationKit'`

**问题3：close()调用时机错误**
```
Warning: Session closed before request completion.
```
**解决方法**：
- 确保在fetch/get/post等请求的Promise完成后调用close()
- 使用async/await或.then()确保请求完成

## 常见问题与解决方法

### Q1：何时应该调用close()？
**原因**：调用时机不明确可能导致资源泄漏或请求中断
**解决方法**：
- 在请求成功完成后（Promise的.then()回调中）
- 在请求失败后（Promise的.catch()回调中）
- 使用try-finally确保无论如何都关闭
- 不要在请求过程中（fetch/get/post执行时）调用

### Q2：能否重复调用close()？
**原因**：担心重复关闭会导致异常
**解决方法**：
- close()方法可以重复调用，不会抛出异常
- 但建议避免重复调用，保持代码逻辑清晰
- 可以添加状态标志跟踪Session是否已关闭

### Q3：Session关闭后能否重新使用？
**原因**：不清楚Session的生命周期
**解决方法**：
- Session关闭后不可再用于发起请求
- 需要重新创建Session实例：`const newSession = rcp.createSession()`
- 建议每次请求序列使用独立的Session

### Q4：忘记关闭Session会有什么影响？
**原因**：不理解资源泄漏的危害
**解决方法**：
- 会导致内存泄漏、网络连接占用
- 自5.1.0(18)版本起Session上限1024个，未关闭会耗尽资源
- 应用退出时系统会自动清理，但建议主动管理
- 使用try-finally或Promise回调确保关闭

### Q5：异步请求中如何正确关闭Session？
**原因**：异步回调时机不确定
**解决方法**：
- 在.then()和.catch()中都调用close()
- 或使用async/await配合try-finally
- 示例：
```typescript
try {
  const response = await session.fetch(req);
  // 处理响应
} finally {
  session.close(); // 确保无论如何都关闭
}
```

## 输出结果报告

执行完成后输出以下信息：

```typescript
{
  "status": "success",
  "sessionClosed": true,
  "resourcesReleased": [
    "memory",
    "network_bandwidth",
    "connection_state",
    "internal_cache"
  ],
  "apiUsed": [
    "rcp.createSession",
    "session.fetch",
    "session.close"
  ],
  "message": "HTTP session closed successfully, all resources released"
}
```

## 参考文档

- [关闭会话开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/remote-communication-netclose-arkts)
- [Remote Communication Kit API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)
- [错误码参考文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-error-code)

## 完整示例代码

- [ArkTS完整示例](assets/session_close_example.ets)

## 测试用例

### 正向测试用例
- [正常关闭会话](tests/test_positive.ts)：请求成功后关闭Session
- [创建多个Session并关闭](tests/test_positive.ts)：验证资源释放效果

### 边界测试用例
- [重复调用close()](tests/test_boundary.ts)：验证多次调用不抛异常
- [并发关闭多个Session](tests/test_boundary.ts)：验证并发关闭正常工作

### 异常测试用例
- [请求失败后关闭](tests/test_exception.ts)：验证错误处理流程中关闭Session
- [超时后关闭](tests/test_exception.ts)：验证超时场景下资源释放
- [未创建Session直接调用close](tests/test_exception.ts)：验证空指针处理