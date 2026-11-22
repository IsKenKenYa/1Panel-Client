/**
 * 服务端解析Access Token示例
 * 
 * 本示例展示如何解析Access Token获取用户信息（UnionID、OpenID等）
 * 功能：调用华为账号REST API解析凭证接口，获取用户身份标识
 */

const axios = require('axios');

// 华为账号服务器地址
const HUAWEI_API_URL = 'https://oauth-api.cloud.huawei.com/rest.php?nsp_fmt=JSON&nsp_svc=huawei.oauth2.user.getTokenInfo';

/**
 * 用户信息
 */
class UserInfo {
  constructor(data) {
    this.clientId = data.client_id;
    this.unionId = data.union_id;
    this.openId = data.open_id;
    this.scope = data.scope;
    this.expiresIn = data.expire_in; // Access Token剩余过期时间（秒）
    this.projectId = data.project_id;
    this.type = data.type; // 凭证类型：0-用户级，1-应用级
  }
}

/**
 * 解析Access Token获取用户信息
 * 
 * @param {string} accessToken - Access Token
 * @param {boolean} getOpenId - 是否获取OpenID（默认true）
 * @returns {Promise<UserInfo>} 用户信息
 */
async function parseAccessToken(accessToken, getOpenId = true) {
  console.log('Starting to parse access token...');
  
  // 构建请求参数
  const params = new URLSearchParams();
  params.append('access_token', accessToken);
  
  // 如果需要获取OpenID，添加open_id参数
  if (getOpenId) {
    params.append('open_id', 'OPENID');
  }
  
  try {
    // 发送POST请求
    const response = await axios.post(HUAWEI_API_URL, params, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      timeout: 30000 // 30秒超时
    });
    
    // 检查响应状态
    if (response.status !== 200) {
      throw new Error(`HTTP error: ${response.status}`);
    }
    
    // 解析响应数据
    const userInfo = new UserInfo(response.data);
    
    console.log('Successfully parsed access token');
    console.log(`UnionID: ${userInfo.unionId}`);
    console.log(`OpenID: ${userInfo.openId}`);
    console.log(`Client ID: ${userInfo.clientId}`);
    console.log(`Expires In: ${userInfo.expiresIn} seconds`);
    console.log(`Type: ${userInfo.type === 0 ? '用户级Token' : '应用级Token'}`);
    
    return userInfo;
    
  } catch (error) {
    // 处理错误
    if (error.response) {
      // 华为账号服务器返回的错误
      const nspStatus = error.response.headers['nsp_status'];
      const errorData = error.response.data;
      
      console.error('Failed to parse access token');
      console.error(`NSP Status: ${nspStatus}`);
      console.error(`Error: ${errorData.error}`);
      
      // 根据错误码判断具体错误
      if (nspStatus === '102') {
        throw new Error('Access Token无效或已过期');
      } else if (nspStatus === '103') {
        throw new Error('Access Token格式错误');
      } else {
        throw new Error(`解析Access Token失败：${errorData.error}`);
      }
    } else if (error.request) {
      // 网络错误
      console.error('Network error:', error.message);
      throw new Error('网络连接失败，请检查网络状态');
    } else {
      // 其他错误
      console.error('Error:', error.message);
      throw error;
    }
  }
}

/**
 * 检查Access Token是否有效
 * 
 * @param {string} accessToken - Access Token
 * @returns {Promise<boolean>} 是否有效
 */
async function isAccessTokenValid(accessToken) {
  try {
    const userInfo = await parseAccessToken(accessToken);
    
    // 检查过期时间（如果剩余时间小于60秒，视为即将过期）
    if (userInfo.expiresIn <= 60) {
      console.warn('Access Token is about to expire');
      return false;
    }
    
    return true;
  } catch (error) {
    console.error('Access Token validation failed:', error.message);
    return false;
  }
}

/**
 * 检查Access Token是否即将过期
 * 
 * @param {string} accessToken - Access Token
 * @param {number} thresholdSeconds - 预警阈值（默认600秒 = 10分钟）
 * @returns {Promise<boolean>} 是否即将过期
 */
async function isAccessTokenExpiringSoon(accessToken, thresholdSeconds = 600) {
  try {
    const userInfo = await parseAccessToken(accessToken);
    
    // 如果剩余时间小于阈值，视为即将过期
    return userInfo.expiresIn <= thresholdSeconds;
  } catch (error) {
    // 如果解析失败，说明Token已过期
    return true;
  }
}

/**
 * 完整的用户信息获取流程
 * 
 * @param {string} accessToken - Access Token
 * @returns {Promise<Object>} 完整的用户信息（包含验证结果）
 */
async function getCompleteUserInfo(accessToken) {
  console.log('=== 开始获取完整用户信息 ===');
  
  try {
    // 步骤1：解析Access Token
    const userInfo = await parseAccessToken(accessToken);
    
    // 步骤2：检查Token有效性
    const isValid = userInfo.expiresIn > 60;
    
    // 步骤3：检查是否即将过期
    const isExpiringSoon = userInfo.expiresIn <= 600;
    
    // 步骤4：返回完整信息
    return {
      success: true,
      userInfo: userInfo,
      tokenStatus: {
        isValid: isValid,
        isExpiringSoon: isExpiringSoon,
        expiresIn: userInfo.expiresIn,
        expiresInMinutes: Math.floor(userInfo.expiresIn / 60)
      }
    };
    
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}

/**
 * 使用示例
 */
async function userInfoExample() {
  console.log('=== 用户信息解析示例 ===');
  
  try {
    // 示例1：解析Access Token获取用户信息
    const accessToken = '<从Token获取接口获得的Access Token>';
    const userInfo = await parseAccessToken(accessToken);
    
    console.log('\n=== 用户信息 ===');
    console.log(`UnionID: ${userInfo.unionId}`);
    console.log(`OpenID: ${userInfo.openId}`);
    console.log(`Client ID: ${userInfo.clientId}`);
    console.log(`Project ID: ${userInfo.projectId}`);
    console.log(`Scope: ${userInfo.scope}`);
    console.log(`Expires In: ${userInfo.expiresIn} seconds (${Math.floor(userInfo.expiresIn / 60)} minutes)`);
    
    // 示例2：检查Token有效性
    const isValid = await isAccessTokenValid(accessToken);
    console.log(`\nToken有效性: ${isValid ? '有效' : '无效或即将过期'}`);
    
    // 示例3：检查是否即将过期
    const isExpiringSoon = await isAccessTokenExpiringSoon(accessToken);
    if (isExpiringSoon) {
      console.log('\n警告：Token即将过期，建议刷新');
    }
    
    // 示例4：获取完整用户信息
    const completeInfo = await getCompleteUserInfo(accessToken);
    console.log('\n=== 完整用户信息 ===');
    console.log(JSON.stringify(completeInfo, null, 2));
    
  } catch (error) {
    console.error('Example failed:', error.message);
  }
}

/**
 * 错误处理示例
 */
async function handleUserInfoErrors() {
  console.log('=== 用户信息解析错误处理示例 ===');
  
  // 错误1：Access Token过期
  try {
    const expiredToken = '<已过期的Access Token>';
    await parseAccessToken(expiredToken);
  } catch (error) {
    console.log('Access Token过期错误:', error.message);
    // 处理方法：使用Refresh Token刷新，或重新登录
  }
  
  // 错误2：Access Token格式错误
  try {
    const invalidToken = '<格式错误的Access Token>';
    await parseAccessToken(invalidToken);
  } catch (error) {
    console.log('Access Token格式错误:', error.message);
    // 处理方法：检查Token来源，确保正确获取
  }
}

/**
 * 用户身份验证流程
 * 
 * @param {string} unionId - 用户UnionID
 * @returns {Promise<Object>} 用户验证结果
 */
async function verifyUserIdentity(unionId) {
  console.log('=== 开始用户身份验证 ===');
  
  // 注意：此处需要查询应用自己的用户数据库
  // 示例代码仅展示逻辑流程
  
  // 步骤1：查询用户是否已存在
  // const existingUser = await queryUserFromDatabase(unionId);
  
  // 模拟查询结果
  const existingUser = null; // 假设用户不存在
  
  if (existingUser) {
    // 用户已存在，返回登录成功
    console.log('用户已存在，完成登录');
    return {
      isNewUser: false,
      userId: existingUser.id,
      unionId: unionId,
      message: '用户登录成功'
    };
  } else {
    // 用户不存在，创建新用户
    console.log('用户不存在，创建新用户');
    
    // const newUser = await createNewUserInDatabase(unionId);
    
    // 模拟创建新用户
    const newUser = {
      id: 'new_user_' + Date.now(),
      unionId: unionId,
      createdAt: new Date()
    };
    
    return {
      isNewUser: true,
      userId: newUser.id,
      unionId: unionId,
      message: '新用户创建成功'
    };
  }
}

// 导出函数
module.exports = {
  parseAccessToken,
  isAccessTokenValid,
  isAccessTokenExpiringSoon,
  getCompleteUserInfo,
  UserInfo,
  verifyUserIdentity
};

// 如果直接运行此文件，执行示例
if (require.main === module) {
  userInfoExample().catch(console.error);
}