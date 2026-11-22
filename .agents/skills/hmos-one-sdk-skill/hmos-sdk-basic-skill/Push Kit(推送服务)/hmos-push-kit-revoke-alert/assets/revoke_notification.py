#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
华为Push Kit - 撤回通知消息示例代码

功能：撤回已推送的通知消息
适用场景：当推送的通知消息内容有误或存在违规情况时

依赖：
    pip install requests

使用前提：
    1. 已开通华为Push服务
    2. 已获取应用的Client ID
    3. 已生成JWT Token
    4. 推送消息时已设置notifyId字段
"""

import requests
import json
import time
from typing import List, Dict, Optional


class PushRevokeNotification:
    """华为Push Kit - 撤回通知消息客户端"""
    
    def __init__(self, client_id: str, jwt_token: str):
        """
        初始化撤回客户端
        
        Args:
            client_id: 应用的Client ID
            jwt_token: JWT Token
        """
        self.client_id = client_id
        self.jwt_token = jwt_token
        self.base_url = "https://push-api.cloud.huawei.com/v1"
        
    def revoke_notification(
        self, 
        notify_id: int, 
        token_list: List[str], 
        push_type: int = 0
    ) -> Dict:
        """
        撤回通知消息
        
        Args:
            notify_id: 消息ID（推送时设置的notifyId）
            token_list: Push Token列表（最多1000个）
            push_type: 消息类型（0：通知消息，2：语音播报消息）
        
        Returns:
            dict: 响应结果
            {
                "code": "80000000",
                "msg": "Success",
                "requestId": "157*******006"
            }
        
        Raises:
            ValueError: 参数校验失败
            requests.RequestException: 网络请求失败
        """
        # 参数校验
        self._validate_params(notify_id, token_list)
        
        # 构造请求URL
        url = f"{self.base_url}/{self.client_id}/messages:revoke"
        
        # 构造请求头
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.jwt_token}",
            "push-type": str(push_type)
        }
        
        # 构造请求体
        payload = {
            "notifyId": notify_id,
            "token": token_list
        }
        
        try:
            # 发送POST请求
            response = requests.post(
                url, 
                headers=headers, 
                json=payload, 
                timeout=30,
                verify=True  # 启用SSL证书验证
            )
            
            # 解析响应
            result = response.json()
            
            # 检查响应码
            if result.get("code") == "80000000":
                print(f"[成功] 消息撤回成功，requestId: {result.get('requestId')}")
            else:
                print(f"[失败] 消息撤回失败，错误码: {result.get('code')}, 错误信息: {result.get('msg')}")
            
            return result
            
        except requests.exceptions.SSLError as e:
            print(f"[错误] SSL证书验证失败: {e}")
            print("请确保使用TLS1.2及以上版本")
            raise
        except requests.exceptions.Timeout as e:
            print(f"[错误] 请求超时: {e}")
            raise
        except requests.exceptions.RequestException as e:
            print(f"[错误] 网络请求失败: {e}")
            raise
        except json.JSONDecodeError as e:
            print(f"[错误] 响应解析失败: {e}")
            raise
    
    def revoke_notification_batch(
        self, 
        notify_id: int, 
        token_list: List[str], 
        push_type: int = 0,
        batch_size: int = 1000
    ) -> List[Dict]:
        """
        批量撤回通知消息（自动分批处理）
        
        Args:
            notify_id: 消息ID
            token_list: Push Token列表
            push_type: 消息类型
            batch_size: 每批最大token数量（默认1000）
        
        Returns:
            list: 响应结果列表
        """
        results = []
        total_tokens = len(token_list)
        
        # 如果token数量不超过batch_size，直接撤回
        if total_tokens <= batch_size:
            print(f"[信息] Token数量: {total_tokens}，单次撤回")
            result = self.revoke_notification(notify_id, token_list, push_type)
            results.append(result)
            return results
        
        # 分批处理
        batch_count = (total_tokens + batch_size - 1) // batch_size
        print(f"[信息] Token数量: {total_tokens}，将分{batch_count}批处理")
        
        for i in range(0, total_tokens, batch_size):
            batch_num = i // batch_size + 1
            batch_tokens = token_list[i:i + batch_size]
            
            print(f"[信息] 处理第{batch_num}/{batch_count}批，共{len(batch_tokens)}个token")
            
            result = self.revoke_notification(notify_id, batch_tokens, push_type)
            results.append(result)
            
            # 避免频繁调用
            if i + batch_size < total_tokens:
                time.sleep(0.1)
        
        return results
    
    def revoke_notification_with_retry(
        self, 
        notify_id: int, 
        token_list: List[str], 
        push_type: int = 0,
        max_retries: int = 3,
        retry_delay: float = 1.0
    ) -> Dict:
        """
        带重试机制的撤回通知消息
        
        Args:
            notify_id: 消息ID
            token_list: Push Token列表
            push_type: 消息类型
            max_retries: 最大重试次数
            retry_delay: 重试延迟（秒）
        
        Returns:
            dict: 响应结果
        """
        for attempt in range(max_retries):
            try:
                result = self.revoke_notification(notify_id, token_list, push_type)
                
                # 检查是否需要重试
                code = result.get("code")
                
                # JWT Token过期，无法自动恢复
                if code in ["80200003", "80200005"]:
                    print(f"[警告] JWT Token过期，请重新生成JWT Token")
                    return result
                
                # 成功，直接返回
                if code == "80000000":
                    return result
                
                # 其他错误，尝试重试
                if attempt < max_retries - 1:
                    print(f"[信息] 第{attempt + 1}次尝试失败，{retry_delay}秒后重试...")
                    time.sleep(retry_delay)
                    retry_delay *= 2  # 指数退避
                else:
                    return result
                    
            except requests.exceptions.RequestException as e:
                if attempt < max_retries - 1:
                    print(f"[信息] 网络请求失败，第{attempt + 1}次重试: {e}")
                    time.sleep(retry_delay)
                    retry_delay *= 2
                else:
                    print(f"[错误] 达到最大重试次数，撤回失败")
                    raise
        
        return {
            "code": "99999999",
            "msg": "超过最大重试次数"
        }
    
    def _validate_params(self, notify_id: int, token_list: List[str]):
        """
        参数校验
        
        Args:
            notify_id: 消息ID
            token_list: Push Token列表
        
        Raises:
            ValueError: 参数校验失败
        """
        if not self.client_id:
            raise ValueError("Client ID不能为空")
        
        if not self.jwt_token:
            raise ValueError("JWT Token不能为空")
        
        if not isinstance(notify_id, int):
            raise ValueError("notifyId必须是整数类型")
        
        if notify_id < 0 or notify_id > 2147483647:
            raise ValueError("notifyId必须在[0, 2147483647]范围内")
        
        if not token_list or len(token_list) == 0:
            raise ValueError("token列表不能为空")
        
        if not isinstance(token_list, list):
            raise ValueError("token列表必须是数组类型")
        
        if len(token_list) > 1000:
            print(f"[警告] token数量超过1000（共{len(token_list)}个），建议使用批量撤回方法")


def handle_error(error_code: str, error_msg: str):
    """
    错误处理
    
    Args:
        error_code: 错误码
        error_msg: 错误信息
    """
    error_handlers = {
        "80100001": "请求参数部分错误，请检查并修改参数内容",
        "80100003": "消息结构体错误，请检查并修改请求体结构",
        "80100020": "消息结构体部分错误，请检查并修改消息结构体参数",
        "80200001": "认证错误，请检查Authorization参数或重新生成JWT Token",
        "80200003": "Access token过期，请重新生成JWT Token",
        "80200005": "JWT Token过期，请重新生成JWT Token",
        "80300002": "当前应用无权限下发推送消息，请检查Push服务状态和ClientId",
        "80300007": "所有Token都是无效的，请检查Token是否正确",
        "80300010": "Token数量超过限制，请分批次发送",
        "80300017": "Token列表中token属于多个APP，请使用同一个APP生成的token",
        "80300028": "Token与ClientId对应的应用不一致，请检查应用配置",
        "80300032": "没有消息撤回权限，请同时使用token与notifyId进行消息撤回",
        "80000001": "系统内部错误，请通过在线提单提交问题"
    }
    
    handler = error_handlers.get(error_code)
    if handler:
        print(f"[错误] 错误码: {error_code}, 信息: {error_msg}")
        print(f"[建议] {handler}")
    else:
        print(f"[错误] 未知错误码: {error_code}, 信息: {error_msg}")


# 使用示例
if __name__ == "__main__":
    # 配置参数
    CLIENT_ID = "YOUR_CLIENT_ID"  # 替换为实际的Client ID
    JWT_TOKEN = "YOUR_JWT_TOKEN"  # 替换为实际的JWT Token
    NOTIFY_ID = 1234567  # 替换为实际的notifyId
    TOKEN_LIST = [
        "pushToken1",
        "pushToken2",
        "pushToken3"
    ]  # 替换为实际的Push Token列表
    
    # 创建客户端实例
    client = PushRevokeNotification(CLIENT_ID, JWT_TOKEN)
    
    print("=" * 60)
    print("华为Push Kit - 撤回通知消息示例")
    print("=" * 60)
    
    # 示例1：基本撤回
    print("\n【示例1】基本撤回")
    try:
        result = client.revoke_notification(NOTIFY_ID, TOKEN_LIST)
        print(json.dumps(result, indent=2, ensure_ascii=False))
    except Exception as e:
        print(f"撤回失败: {e}")
    
    # 示例2：带重试机制的撤回
    print("\n【示例2】带重试机制的撤回")
    try:
        result = client.revoke_notification_with_retry(
            NOTIFY_ID, 
            TOKEN_LIST,
            max_retries=3,
            retry_delay=1.0
        )
        print(json.dumps(result, indent=2, ensure_ascii=False))
    except Exception as e:
        print(f"撤回失败: {e}")
    
    # 示例3：批量撤回（token数量超过1000）
    print("\n【示例3】批量撤回")
    # 模拟大量token
    large_token_list = [f"pushToken{i}" for i in range(1500)]
    try:
        results = client.revoke_notification_batch(NOTIFY_ID, large_token_list)
        print(f"批量撤回完成，共处理{len(results)}批")
        for idx, result in enumerate(results):
            print(f"第{idx + 1}批结果: {result.get('code')} - {result.get('msg')}")
    except Exception as e:
        print(f"批量撤回失败: {e}")
    
    print("\n" + "=" * 60)