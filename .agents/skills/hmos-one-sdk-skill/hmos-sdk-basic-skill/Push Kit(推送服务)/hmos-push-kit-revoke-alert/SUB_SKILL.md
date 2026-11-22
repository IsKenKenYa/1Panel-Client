---
name: hmos-push-kit-revoke-alert
description: 撤回已推送的通知消息，支持使用token和notifyId撤回，最多1000个token，适用于消息内容有误或违规的场景，支持Phone/Tablet/PC/Wearable/TV设备
---

# 撤回通知消息技能

## 功能描述

撤回已推送的通知消息，用于处理消息内容有误或存在违规情况，降低推送可能造成的不良影响。该技能通过REST API调用华为Push服务的消息撤回接口，根据notifyId和token列表撤回指定的通知消息。

**核心能力**：
- 撤回通知消息和语音播报消息
- 支持批量撤回（最多1000个token）
- 提供完整的错误码处理机制
- 支持多种设备类型（Phone、Tablet、PC/2in1、Wearable、TV）

## 使用场景

### 触发词
- "撤回通知消息"
- "撤回推送消息"
- "撤销通知"
- "revoke notification"
- "撤回消息"

### 能做
- 撤回还未下发到端侧的消息
- 撤回已在终端展示但用户还未点击的消息
- 批量撤回多个token的消息
- 处理消息内容有误的场景
- 处理消息存在违规情况的场景

### 绝不做
- 撤回已被用户点击的消息
- 撤回未设置notifyId的消息
- 撤回超过1000个token的消息（需要分批处理）
- 撤回非通知消息类型（仅支持通知消息和语音播报消息）
- 直接处理应用的通知角标

### 补充
- 消息撤回需要预先在推送消息时设置notifyId字段
- 消息撤回仅支持使用token和notifyId撤回
- 消息撤回不会影响应用的通知角标
- 设备版本要求：
  - Phone/Tablet/PC/2in1：全版本支持
  - Wearable：从5.1.0(18)版本开始支持
  - TV：从5.1.1(19)版本开始支持

## 调用规范和规则

### 输入约束
- notifyId：必填，Integer类型，范围[0, 2147483647]
- token：必填，Array[String]类型，最多1000个token
- 消息体大小：最大不能超过4096Bytes（不包括Push Token）
- JWT Token：有效期建议设置为3600秒

### 执行约束
- 最大token数量：单次最多1000个
- API调用频次：建议平均分配发送速度，避免集中发送
- 网络协议：必须使用TLS1.2及以上版本
- 请求超时：建议设置合理的超时时间

### 内容约束
- 禁止使用TLS1.0或TLS1.1协议
- 禁止传递其他应用的Push Token
- 禁止使用不同项目的JWT Token
- 必须使用v1版本的撤回API

### 降级约束
- JWT Token过期：重新生成JWT Token后重试
- Token数量超过1000：分批次发送
- 网络失败：建议稍后重试，或通过在线提单提交问题
- 权限不足：检查Push服务是否开通，检查ClientId是否正确

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认已在推送消息时设置notifyId字段
2. 确认已获取目标用户的Push Token列表
3. 确认已开通Push服务并获取Client ID
4. 确认已生成有效的JWT Token

**参数准备**：
```python
# Python示例
import json

# 准备撤回参数
revoke_params = {
    "notifyId": 1234567,  # 必填：消息下发时携带的notifyId
    "token": [            # 必填：目标用户的Push Token列表（最多1000个）
        "pushToken1",
        "pushToken2",
        "pushToken3"
    ]
}

# 请求头配置
headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer <YOUR_JWT_TOKEN>",  # JWT Token
    "push-type": "0"  # 0：通知消息，2：语音播报消息
}
```

### 步骤2：调用API

**示例代码**：
```python
# 导入必要模块
import requests
import json

# 撤回通知消息
def revoke_notification(client_id: str, jwt_token: str, notify_id: int, token_list: list, push_type: int = 0):
    """
    撤回通知消息
    
    Args:
        client_id: 应用的Client ID
        jwt_token: JWT Token
        notify_id: 消息ID
        token_list: Push Token列表（最多1000个）
        push_type: 消息类型（0：通知消息，2：语音播报消息）
    
    Returns:
        dict: 响应结果
    """
    # 参数校验
    if not client_id:
        raise ValueError("Client ID不能为空")
    if not jwt_token:
        raise ValueError("JWT Token不能为空")
    if notify_id < 0 or notify_id > 2147483647:
        raise ValueError("notifyId必须在[0, 2147483647]范围内")
    if not token_list or len(token_list) == 0:
        raise ValueError("token列表不能为空")
    if len(token_list) > 1000:
        raise ValueError("token列表最多支持1000个token")
    
    # 构造请求URL
    url = f"https://push-api.cloud.huawei.com/v1/{client_id}/messages:revoke"
    
    # 构造请求头
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {jwt_token}",
        "push-type": str(push_type)
    }
    
    # 构造请求体
    payload = {
        "notifyId": notify_id,
        "token": token_list
    }
    
    try:
        # 发送POST请求
        response = requests.post(url, headers=headers, json=payload, timeout=30)
        
        # 解析响应
        result = response.json()
        
        # 检查响应码
        if result.get("code") == "80000000":
            print(f"消息撤回成功，requestId: {result.get('requestId')}")
            return result
        else:
            print(f"消息撤回失败，错误码: {result.get('code')}, 错误信息: {result.get('msg')}")
            return result
            
    except requests.exceptions.RequestException as e:
        print(f"网络请求失败: {e}")
        raise
    except json.JSONDecodeError as e:
        print(f"响应解析失败: {e}")
        raise
    except Exception as e:
        print(f"未知错误: {e}")
        raise

# 使用示例
if __name__ == "__main__":
    # 替换为实际的参数
    client_id = "YOUR_CLIENT_ID"
    jwt_token = "YOUR_JWT_TOKEN"
    notify_id = 1234567
    token_list = ["pushToken1", "pushToken2", "pushToken3"]
    
    # 调用撤回接口
    result = revoke_notification(client_id, jwt_token, notify_id, token_list)
    print(json.dumps(result, indent=2, ensure_ascii=False))
```

### 步骤3：错误处理

```python
# 错误处理代码
def handle_revoke_error(error_code: str, error_msg: str):
    """
    处理撤回消息的错误
    
    Args:
        error_code: 错误码
        error_msg: 错误信息
    """
    error_handlers = {
        "80100001": lambda: "请求参数部分错误，请检查并修改参数内容",
        "80100003": lambda: "消息结构体错误，请检查并修改请求体结构",
        "80100020": lambda: "消息结构体部分错误，请检查并修改消息结构体参数",
        "80200001": lambda: "认证错误，请检查Authorization参数或重新生成JWT Token",
        "80200003": lambda: "Access token过期，请重新生成JWT Token",
        "80200005": lambda: "JWT Token过期，请重新生成JWT Token",
        "80300002": lambda: "当前应用无权限下发推送消息，请检查Push服务状态和ClientId",
        "80300007": lambda: "所有Token都是无效的，请检查Token是否正确",
        "80300010": lambda: "Token数量超过限制，请分批次发送",
        "80300017": lambda: "Token列表中token属于多个APP，请使用同一个APP生成的token",
        "80300028": lambda: "Token与ClientId对应的应用不一致，请检查应用配置",
        "80300032": lambda: "没有消息撤回权限，请同时使用token与notifyId进行消息撤回",
        "80000001": lambda: "系统内部错误，请通过在线提单提交问题"
    }
    
    handler = error_handlers.get(error_code)
    if handler:
        print(f"错误码 {error_code}: {error_msg}")
        print(f"处理建议: {handler()}")
    else:
        print(f"未知错误码 {error_code}: {error_msg}")

# 使用示例
try:
    result = revoke_notification(client_id, jwt_token, notify_id, token_list)
    if result.get("code") != "80000000":
        handle_revoke_error(result.get("code"), result.get("msg"))
except Exception as e:
    print(f"撤回失败: {e}")
```

### 步骤4：降级处理

```python
# 降级处理代码
import time

def revoke_notification_with_fallback(client_id: str, jwt_token: str, notify_id: int, token_list: list, push_type: int = 0, max_retries: int = 3):
    """
    带降级处理的撤回通知消息
    
    Args:
        client_id: 应用的Client ID
        jwt_token: JWT Token
        notify_id: 消息ID
        token_list: Push Token列表（最多1000个）
        push_type: 消息类型（0：通知消息，2：语音播报消息）
        max_retries: 最大重试次数
    
    Returns:
        dict: 响应结果
    """
    # 如果token数量超过1000，分批处理
    if len(token_list) > 1000:
        print(f"Token数量超过1000，将分批处理，共{len(token_list)}个token")
        batch_size = 1000
        results = []
        for i in range(0, len(token_list), batch_size):
            batch_tokens = token_list[i:i + batch_size]
            print(f"处理第{i//batch_size + 1}批，共{len(batch_tokens)}个token")
            result = revoke_notification(client_id, jwt_token, notify_id, batch_tokens, push_type)
            results.append(result)
            time.sleep(0.1)  # 避免频繁调用
        return results
    
    # 重试机制
    for attempt in range(max_retries):
        try:
            result = revoke_notification(client_id, jwt_token, notify_id, token_list, push_type)
            
            # JWT Token过期，重新生成
            if result.get("code") in ["80200003", "80200005"]:
                print("JWT Token过期，请重新生成JWT Token")
                # 这里可以调用重新生成JWT Token的逻辑
                # new_jwt_token = generate_jwt_token()
                # return revoke_notification(client_id, new_jwt_token, notify_id, token_list, push_type)
                return result
            
            return result
            
        except requests.exceptions.RequestException as e:
            print(f"网络请求失败，第{attempt + 1}次重试: {e}")
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)  # 指数退避
            else:
                print("达到最大重试次数，撤回失败")
                raise
    
    return {"code": "99999999", "msg": "超过最大重试次数"}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 80000000 | 成功 | 不涉及 |
| 80100001 | 请求参数部分错误 | 检查并修改请求参数内容 |
| 80100003 | 消息结构体错误 | 检查并修改请求体结构 |
| 80100020 | 消息结构体部分错误 | 检查并修改消息结构体参数 |
| 80200001 | 认证错误 | 检查Authorization参数或重新生成JWT Token |
| 80200003 | Access token过期 | 重新生成JWT Token |
| 80200005 | JWT Token过期 | 重新生成JWT Token |
| 80300002 | 当前应用无权限下发推送消息 | 检查Push服务状态和ClientId |
| 80300007 | 所有Token都是无效的 | 检查Token是否正确，确保使用正确的应用包名和ID |
| 80300010 | Token数量超过限制 | 分批次发送，单次最多1000个token |
| 80300017 | Token列表中token属于多个APP | 使用同一个APP生成的token |
| 80300028 | Token与ClientId对应的应用不一致 | 检查应用配置，确保包名和ID一致 |
| 80300032 | 没有消息撤回权限 | 同时使用token与notifyId进行消息撤回 |
| 80000001 | 系统内部错误 | 通过在线提单提交问题 |

**HTTP响应码说明**：
- 200：成功
- 400：参数错误，检查业务响应码
- 401：鉴权失败，检查Authorization参数
- 404：找不到服务，检查请求URI
- 500：服务内部错误，通过在线提单提交问题
- 502：请求连接异常，稍后重试
- 503：流量控制，平均分配发送速度

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "requests": ">=2.28.0"
  }
}
```

### 环境要求
- Python：3.7及以上版本
- 网络协议：TLS1.2及以上版本
- 开发环境：已开通华为Push服务

### 常见编译问题

**问题1：导入requests模块失败**
```
ModuleNotFoundError: No module named 'requests'
```
**解决方法**：
```bash
pip install requests
```

**问题2：SSL/TLS协议版本不兼容**
```
SSLError: [SSL: UNSUPPORTED_PROTOCOL] unsupported protocol
```
**解决方法**：
- 升级Python到3.7及以上版本
- 确保系统支持TLS1.2及以上版本

**问题3：JWT Token格式错误**
```
401 Unauthorized
```
**解决方法**：
- 检查Authorization格式：`Bearer <JWT_TOKEN>`
- 确保Bearer后面有空格

## 常见问题与解决方法

### Q1：如何获取Client ID？
**原因**：需要应用的Client ID才能调用撤回接口
**解决方法**：
- 登录AppGallery Connect网站
- 查看应用信息获取Client ID
- 参考指导：https://developer.huawei.com/consumer/cn/doc/app/agc-help-view-app-info-0000002282674569

### Q2：如何生成JWT Token？
**原因**：调用API需要JWT Token进行鉴权
**解决方法**：
- 参考基于服务账号生成鉴权令牌文档
- 建议JWT Token过期时间设置为3600秒
- 确保Project Id与应用一致

### Q3：token数量超过1000怎么办？
**原因**：单次请求最多支持1000个token
**解决方法**：
- 将token列表分批处理，每批最多1000个
- 使用降级处理函数自动分批发送
- 避免集中发送，平均分配推送时间段

### Q4：消息撤回失败怎么办？
**原因**：可能的原因包括token无效、权限不足、消息已点击等
**解决方法**：
- 检查错误码，根据错误码提示处理
- 确保消息设置了notifyId
- 确保使用的是正确的token
- 确保Push服务已开通
- 检查消息是否已被用户点击（已点击的消息无法撤回）

### Q5：如何确认消息撤回是否成功？
**原因**：需要验证撤回结果
**解决方法**：
- 检查响应码是否为80000000
- 在终端设备上确认通知是否已消失
- 查看响应中的requestId用于问题追踪

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success/failed",
  "requestId": "请求标识",
  "code": "响应码",
  "msg": "响应码描述",
  "revokedCount": "撤回成功的token数量",
  "failedTokens": "撤回失败的token列表",
  "apiUsed": [
    "POST /v1/{clientId}/messages:revoke"
  ]
}
```

## 参考文档

- [撤回通知消息开发指南](references/push-revoke-alert.md)
- [消息撤回API参考](references/push-msg-revoke.md)
- [发送通知消息](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/push-send-alert)
- [获取Push Token](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/push-get-token)
- [基于服务账号生成鉴权令牌](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/push-jwt-token)

## 完整示例代码

- [Python示例](assets/revoke_notification.py)
- [配置文件示例](assets/config.json)

## 测试用例

### 正向测试用例
- [撤回单个token的通知消息](tests/test_positive.py)：测试正常撤回单个token的消息
- [批量撤回多个token的通知消息](tests/test_positive.py)：测试批量撤回最多1000个token的消息
- [撤回语音播报消息](tests/test_positive.py)：测试撤回语音播报消息（push-type=2）

### 边界测试用例
- [撤回1000个token的消息](tests/test_boundary.py)：测试最大token数量限制
- [使用最大notifyId值](tests/test_boundary.py)：测试notifyId边界值2147483647
- [JWT Token即将过期](tests/test_boundary.py)：测试JWT Token有效期边界

### 异常测试用例
- [token数量超过1000](tests/test_exception.py)：测试token数量超限的错误处理
- [JWT Token过期](tests/test_exception.py)：测试认证失败的处理
- [无效的notifyId](tests/test_exception.py)：测试无效notifyId的错误处理
- [网络请求失败](tests/test_exception.py)：测试网络异常的降级处理
- [权限不足](tests/test_exception.py)：测试应用无权限的错误处理