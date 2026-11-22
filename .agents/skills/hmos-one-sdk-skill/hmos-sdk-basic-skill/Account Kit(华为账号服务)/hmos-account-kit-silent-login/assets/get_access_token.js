/**
 * 服务端获取Access Token示例
 * 
 * 本示例展示如何使用Authorization Code获取Access Token、Refresh Token和ID Token
 * 功能：服务端调用华为账号REST API，完成Token获取流程
 */

const axios = require('axios');

// 华为账号服务器地址
const HUAWEI_OAUTH_URL = 'https://oauth-login.cloud.huawei.com/oauth2/v3/token';

// 从环境变量或配置文件获取Client ID和Client Secret
const CLIENT_ID = process.env.CLIENT_ID || '<your_client_id>';
const CLIENT_SECRET = process.env.CLIENT_SECRET || '<your_client_secret>';

/**
 * Token信息
 */
class TokenInfo {
  constructor(data) {
    this.accessToken = data.access_token;
    this.refreshToken = data.refresh_token;
    this.expiresIn = data.expires_in; // Access Token过期时间（秒）
    this.idToken = data.id_token;
    this.scope = data.scope;
    this.tokenType = data.token_type;
  }
}

/**
 * 使用Authorization Code获取Access Token
 * 
 * @param {string} authorizationCode - 客户端传递的Authorization Code
 * @param {string} supportAlg - ID Token签名算法（PS256或RS256，默认PS256）
 * @returns {Promise<TokenInfo>} Token信息
 */
async function getAccessToken(authorizationCode, supportAlg = 'PS256') {
  console.log('Starting to get access token with authorization code...');
  
  // 构建请求参数
  const params = new URLSearchParams();
  params.append('grant_type', 'authorization_code');
  params.append('code', authorizationCode);
  params.append('client_id', CLIENT_ID);
  params.append('client_secret', CLIENT_SECRET);
  params.append('supportAlg', supportAlg);
  
  try {
    // 发送POST请求
    const response = await axios.post(HUAWEI_OAUTH_URL, params, {
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
    const tokenInfo = new TokenInfo(response.data);
    
    console.log('Successfully got access token');
    console.log(`Access Token: ${tokenInfo.accessToken.substring(0, 20)}...`);
    console.log(`Expires In: ${tokenInfo.expiresIn} seconds`);
    console.log(`Scope: ${tokenInfo.scope}`);
    
    return tokenInfo;
    
  } catch (error) {
    // 处理错误
    if (error.response) {
      // 华为账号服务器返回的错误
      const errorData = error.response.data;
      console.error('Failed to get access token');
      console.error(`Error: ${errorData.error}`);
      console.error(`Sub Error: ${errorData.sub_error}`);
      console.error(`Error Description: ${errorData.error_description}`);
      
      // 根据错误码判断具体错误
      if (errorData.sub_error === 12304) {
        throw new Error('Client Secret无效，请检查配置');
      } else if (errorData.sub_error === 12302) {
        throw new Error('Authorization Code无效或已过期，请重新获取');
      } else if (errorData.sub_error === 12300) {
        throw new Error('Authorization Code已使用，不能重复使用');
      } else {
        throw new Error(`获取Access Token失败：${errorData.error_description}`);
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
 * 使用Refresh Token刷新Access Token
 * 
 * @param {string} refreshToken - Refresh Token
 * @returns {Promise<TokenInfo>} 新的Token信息
 */
async function refreshAccessToken(refreshToken) {
  console.log('Starting to refresh access token...');
  
  // 构建请求参数
  const params = new URLSearchParams();
  params.append('grant_type', 'refresh_token');
  params.append('refresh_token', refreshToken);
  params.append('client_id', CLIENT_ID);
  params.append('client_secret', CLIENT_SECRET);
  
  try {
    // 发送POST请求
    const response = await axios.post(HUAWEI_OAUTH_URL, params, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      timeout: 30000
    });
    
    // 解析响应数据
    const tokenInfo = new TokenInfo(response.data);
    
    console.log('Successfully refreshed access token');
    console.log(`New Access Token: ${tokenInfo.accessToken.substring(0, 20)}...`);
    console.log(`Expires In: ${tokenInfo.expiresIn} seconds`);
    
    // 注意：Refresh Token可能会返回新的值，需要更新保存
    if (tokenInfo.refreshToken !== refreshToken) {
      console.log('Received new refresh token, please update storage');
    }
    
    return tokenInfo;
    
  } catch (error) {
    if (error.response) {
      const errorData = error.response.data;
      
      // Refresh Token过期（错误码1108）
      if (errorData.error === 1108) {
        console.error('Refresh Token expired, need to re-login');
        throw new Error('Refresh Token过期，需要重新登录');
      }
      
      throw new Error(`刷新Access Token失败：${errorData.error_description}`);
    } else {
      console.error('Network error:', error.message);
      throw new Error('网络连接失败');
    }
  }
}

/**
 * 自动管理Token刷新
 * 
 * @param {TokenInfo} tokenInfo - 原始Token信息
 * @param {number} thresholdSeconds - 刷新阈值（默认在过期前10分钟刷新）
 * @returns {Promise<TokenInfo>} Token信息（可能已刷新）
 */
async function manageTokenRefresh(tokenInfo, thresholdSeconds = 600) {
  const currentTimestamp = Date.now() / 1000;
  const tokenExpireTimestamp = currentTimestamp + tokenInfo.expiresIn;
  
  // 如果距离过期时间小于阈值，提前刷新
  if (tokenInfo.expiresIn <= thresholdSeconds) {
    console.log(`Access Token will expire in ${tokenInfo.expiresIn} seconds, refreshing...`);
    return await refreshAccessToken(tokenInfo.refreshToken);
  }
  
  // 否则返回原Token
  return tokenInfo;
}

/**
 * 使用示例
 */
async function accessTokenExample() {
  console.log('=== Access Token获取示例 ===');
  
  try {
    // 示例1：使用Authorization Code获取Access Token
    const authorizationCode = '<从客户端获取的Authorization Code>';
    const tokenInfo = await getAccessToken(authorizationCode);
    
    console.log('\n=== Token信息 ===');
    console.log(`Access Token: ${tokenInfo.accessToken}`);
    console.log(`Refresh Token: ${tokenInfo.refreshToken}`);
    console.log(`Expires In: ${tokenInfo.expiresIn} seconds`);
    console.log(`ID Token: ${tokenInfo.idToken.substring(0, 50)}...`);
    console.log(`Scope: ${tokenInfo.scope}`);
    
    // 示例2：自动管理Token刷新
    const managedTokenInfo = await manageTokenRefresh(tokenInfo);
    
    if (managedTokenInfo.accessToken !== tokenInfo.accessToken) {
      console.log('\n=== Token已刷新 ===');
      console.log(`New Access Token: ${managedTokenInfo.accessToken}`);
    } else {
      console.log('\n=== Token无需刷新 ===');
    }
    
    // 示例3：手动刷新Access Token（模拟过期场景）
    console.log('\n=== 手动刷新示例 ===');
    const newTokenInfo = await refreshAccessToken(tokenInfo.refreshToken);
    console.log(`New Access Token: ${newTokenInfo.accessToken}`);
    
  } catch (error) {
    console.error('Example failed:', error.message);
  }
}

/**
 * 错误处理示例
 */
async function handleAccessTokenErrors() {
  console.log('=== Access Token错误处理示例 ===');
  
  // 错误1：Authorization Code过期
  try {
    const expiredCode = '<已过期的Authorization Code>';
    await getAccessToken(expiredCode);
  } catch (error) {
    console.log('Authorization Code过期错误:', error.message);
    // 处理方法：通知客户端重新获取Authorization Code
  }
  
  // 错误2：Authorization Code重复使用
  try {
    const reusedCode = '<已使用的Authorization Code>';
    await getAccessToken(reusedCode);
  } catch (error) {
    console.log('Authorization Code重复使用错误:', error.message);
    // 处理方法：通知客户端重新获取新的Authorization Code
  }
  
  // 错误3：Client Secret无效
  try {
    const invalidSecretCode = '<Authorization Code>';
    // 模拟错误的Client Secret
    const wrongClientSecret = '<错误的Client Secret>';
    
    const params = new URLSearchParams();
    params.append('grant_type', 'authorization_code');
    params.append('code', invalidSecretCode);
    params.append('client_id', CLIENT_ID);
    params.append('client_secret', wrongClientSecret);
    
    await axios.post(HUAWEI_OAUTH_URL, params, {
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    });
  } catch (error) {
    console.log('Client Secret无效错误:', error.message);
    // 处理方法：检查AppGallery Connect配置
  }
}

// 导出函数
module.exports = {
  getAccessToken,
  refreshAccessToken,
  manageTokenRefresh,
  TokenInfo
};

// 如果直接运行此文件，执行示例
if (require.main === module) {
  accessTokenExample().catch(console.error);
}