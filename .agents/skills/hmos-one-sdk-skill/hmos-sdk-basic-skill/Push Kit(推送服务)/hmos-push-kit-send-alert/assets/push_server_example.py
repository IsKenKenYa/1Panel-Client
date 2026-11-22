import requests
import json
from typing import Dict, List, Optional

class PushKitNotificationSender:
    def __init__(self, project_id: str, authorization_token: str):
        self.project_id = project_id
        self.authorization_token = authorization_token
        self.base_url = "https://push-api.cloud.huawei.com/v3"
        
    def send_notification(
        self,
        tokens: List[str],
        title: str,
        body: str,
        category: str = "MARKETING",
        action_type: int = 0,
        test_message: bool = True,
        foreground_show: bool = True,
        notify_id: Optional[int] = None,
        image: Optional[str] = None,
        inbox_content: Optional[List[str]] = None,
        style: Optional[int] = None,
        action: Optional[str] = None,
        uri: Optional[str] = None,
        data: Optional[Dict] = None,
        profile_id: Optional[str] = None,
        sound: Optional[str] = None,
        sound_duration: Optional[int] = None,
        ttl: int = 86400
    ) -> Dict:
        """
        发送Push Kit通知消息
        
        Args:
            tokens: Push Token数组
            title: 通知标题
            body: 通知内容
            category: 通知消息类型（MARKETING或其他服务通讯类）
            action_type: 点击动作类型（0=首页，1=内页）
            test_message: 测试消息标识
            foreground_show: 是否在前台展示
            notify_id: 自定义消息标识
            image: 大图标URL
            inbox_content: 多行文本内容数组
            style: 通知样式（3=多行文本）
            action: 点击消息动作
            uri: 点击消息URI
            data: 点击消息携带数据
            profile_id: 应用账号匿名标识
            sound: 自定义铃声文件名
            sound_duration: 铃声时长（秒）
            ttl: 消息缓存时间
            
        Returns:
            响应结果字典
        """
        url = f"{self.base_url}/{self.project_id}/messages:send"
        
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.authorization_token}",
            "push-type": "0"
        }
        
        notification = {
            "category": category,
            "title": title,
            "body": body,
            "clickAction": {
                "actionType": action_type
            },
            "foregroundShow": foreground_show
        }
        
        if notify_id is not None:
            notification["notifyId"] = notify_id
        
        if image:
            notification["image"] = image
        
        if inbox_content and style == 3:
            notification["style"] = style
            notification["inboxContent"] = inbox_content
        
        if action_type == 1:
            if action:
                notification["clickAction"]["action"] = action
            if uri:
                notification["clickAction"]["uri"] = uri
            if data:
                notification["clickAction"]["data"] = data
        
        if profile_id:
            notification["profileId"] = profile_id
        
        if sound and category != "MARKETING":
            notification["sound"] = sound
            if sound_duration:
                notification["soundDuration"] = sound_duration
        
        payload = {
            "payload": {
                "notification": notification
            },
            "target": {
                "token": tokens
            },
            "pushOptions": {
                "testMessage": test_message,
                "ttl": ttl
            }
        }
        
        try:
            response = requests.post(url, headers=headers, json=payload, timeout=30)
            response.raise_for_status()
            return {
                "status": "success",
                "code": response.status_code,
                "data": response.json()
            }
        except requests.exceptions.RequestException as e:
            return {
                "status": "failed",
                "error": str(e),
                "code": e.response.status_code if hasattr(e, 'response') else None
            }

    def send_basic_notification(self, tokens: List[str], title: str, body: str) -> Dict:
        """发送普通通知消息"""
        return self.send_notification(
            tokens=tokens,
            title=title,
            body=body,
            category="MARKETING",
            action_type=0,
            test_message=True
        )

    def send_image_notification(self, tokens: List[str], title: str, body: str, image_url: str) -> Dict:
        """发送带大图标的通知消息"""
        return self.send_notification(
            tokens=tokens,
            title=title,
            body=body,
            category="MARKETING",
            action_type=0,
            test_message=True,
            image=image_url
        )

    def send_multiline_notification(self, tokens: List[str], title: str, body: str, lines: List[str]) -> Dict:
        """发送多行文本样式通知消息"""
        return self.send_notification(
            tokens=tokens,
            title=title,
            body=body,
            category="MARKETING",
            action_type=0,
            test_message=True,
            inbox_content=lines,
            style=3
        )

    def send_notification_with_account(
        self, 
        tokens: List[str], 
        title: str, 
        body: str, 
        profile_id: str
    ) -> Dict:
        """发送带账号校验的通知消息"""
        return self.send_notification(
            tokens=tokens,
            title=title,
            body=body,
            category="MARKETING",
            action_type=0,
            test_message=True,
            profile_id=profile_id
        )

    def send_notification_to_inner_page(
        self,
        tokens: List[str],
        title: str,
        body: str,
        action: str = None,
        uri: str = None,
        data: Dict = None
    ) -> Dict:
        """发送点击跳转到应用内页的通知消息"""
        return self.send_notification(
            tokens=tokens,
            title=title,
            body=body,
            category="MARKETING",
            action_type=1,
            test_message=True,
            action=action,
            uri=uri,
            data=data
        )

    def send_notification_with_custom_sound(
        self,
        tokens: List[str],
        title: str,
        body: str,
        sound_file: str,
        duration: int = 10
    ) -> Dict:
        """发送带自定义铃声的通知消息（category不能为MARKETING）"""
        return self.send_notification(
            tokens=tokens,
            title=title,
            body=body,
            category="TRAVEL",
            action_type=0,
            test_message=True,
            sound=sound_file,
            sound_duration=duration
        )


if __name__ == "__main__":
    PROJECT_ID = "your_project_id_here"
    AUTHORIZATION_TOKEN = "your_jwt_token_here"
    PUSH_TOKENS = ["MAMzLg**********lPW"]
    
    sender = PushKitNotificationSender(PROJECT_ID, AUTHORIZATION_TOKEN)
    
    result = sender.send_basic_notification(
        tokens=PUSH_TOKENS,
        title="推送服务",
        body="推送服务是华为提供的消息推送平台"
    )
    
    print("发送结果:", json.dumps(result, indent=2))