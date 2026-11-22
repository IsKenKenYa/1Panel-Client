# 华为账号一键登录服务端示例代码(Python)
# 实现接收Authorization Code并调用华为账号REST API获取用户信息

from flask import Flask, request, jsonify
import requests
import json

app = Flask(__name__)

# 配置信息(从AGC获取)
AGC_CONFIG = {
    "client_id": "<your_client_id>",
    "client_secret": "<your_client_secret>"
}

# 华为账号一键登录接口地址
QUICK_LOGIN_URL = "https://account-api.cloud.huawei.com/oauth2/v6/quickLogin/getPhoneNumber"


@app.route('/login', methods=['POST'])
def login():
    """
    接收客户端的Authorization Code，调用华为账号API获取用户信息
    """
    # 验证请求参数
    request_data = request.get_json()
    if not request_data or 'authorizationCode' not in request_data:
        return jsonify({
            'code': 400,
            'message': 'invalid authorizationCode',
            'data': None
        }), 400
    
    authorization_code = request_data['authorizationCode']
    
    # 调用华为账号服务获取用户信息
    user_info = get_user_info_from_huawei(authorization_code)
    
    if not user_info:
        return jsonify({
            'code': 401,
            'message': 'Failed to authenticate with Huawei',
            'data': None
        }), 401
    
    # 数据库操作：
    # 1. 使用UnionID查询用户，匹配则返回用户信息
    # 2. 未匹配则使用手机号查询，查到则关联UnionID
    # 3. 均未匹配则创建新用户
    
    user = query_or_create_user(user_info)
    
    # 成功响应
    return jsonify({
        'code': 200,
        'message': 'Login successful',
        'data': {
            'userId': user['id'],
            'phone': user['phone'],
            'unionId': user_info['unionId'],
            'openId': user_info['openId']
        }
    })


def get_user_info_from_huawei(authorization_code):
    """
    调用华为账号REST API获取用户信息
    """
    # 构建请求体
    request_body = {
        "code": authorization_code,
        "clientId": AGC_CONFIG["client_id"],
        "clientSecret": AGC_CONFIG["client_secret"]
    }
    
    try:
        # 发送POST请求
        response = requests.post(
            QUICK_LOGIN_URL,
            headers={'Content-Type': 'application/json'},
            json=request_body,
            timeout=10
        )
        
        user_info = response.json()
        
        # 检查是否有错误
        if 'resultCode' in user_info and user_info['resultCode'] != 0:
            print(f"Error: {user_info['resultCode']} - {user_info['resultDesc']}")
            return None
        
        # 返回用户信息
        return {
            'openId': user_info.get('openId'),
            'unionId': user_info.get('unionId'),
            'phoneNumber': user_info.get('phoneNumber'),
            'purePhoneNumber': user_info.get('purePhoneNumber'),
            'phoneNumberValid': user_info.get('phoneNumberValid'),
            'phoneCountryCode': user_info.get('phoneCountryCode')
        }
        
    except requests.RequestException as e:
        print(f"Request error: {e}")
        return None


def query_or_create_user(user_info):
    """
    查询或创建用户
    实际应用中需要连接数据库操作
    """
    union_id = user_info['unionId']
    phone_number = user_info['purePhoneNumber']
    
    # 示例：模拟数据库查询
    # 实际应用中替换为真实的数据库操作
    
    # 1. 使用UnionID查询
    # user = db.query_user_by_union_id(union_id)
    user = None
    
    if user:
        # 用户已存在，返回用户信息
        return user
    
    # 2. 使用手机号查询
    # user = db.query_user_by_phone(phone_number)
    user = None
    
    if user:
        # 用户存在，关联UnionID
        # db.update_user_union_id(user['id'], union_id)
        user['unionId'] = union_id
        return user
    
    # 3. 创建新用户
    # user_id = db.create_user(phone_number, union_id, user_info['openId'])
    new_user = {
        'id': 'new_user_id',
        'phone': phone_number,
        'unionId': union_id,
        'openId': user_info['openId']
    }
    
    return new_user


@app.route('/health', methods=['GET'])
def health():
    """健康检查接口"""
    return jsonify({'status': 'ok'})


if __name__ == '__main__':
    # 启动服务
    # 生产环境建议使用更安全的方式部署(如使用Nginx反向代理)
    app.run(debug=True, host='0.0.0.0', port=8080)