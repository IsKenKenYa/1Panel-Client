/**
 * 华为账号登录服务端示例 - Node.js
 * 处理Authorization Code并获取UnionID/OpenID
 */

const axios = require('axios');
const crypto = require('crypto');

// 配置信息
const CLIENT_ID = 'YOUR_CLIENT_ID';          // 替换为实际的Client ID
const CLIENT_SECRET = 'YOUR_CLIENT_SECRET';  // 替换为实际的Client Secret
const REDIRECT_URI = 'YOUR_REDIRECT_URI';    // 重定向URI

// 华为账号服务API端点
const HUAWEI_TOKEN_URL = 'https://oauth-login.cloud.huawei.com/oauth2/v2/token';
const HUAWEI_USER_INFO_URL = 'https://account-api.huawei.com/v2/userInfo';

/**
 * 使用Authorization Code获取Access Token
 */
async function getAccessToken(authorizationCode) {
  try {
    const response = await axios.post(HUAWEI_TOKEN_URL, {
      grant_type: 'authorization_code',
      code: authorizationCode,
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      redirect_uri: REDIRECT_URI
    }, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    });

    return {
      accessToken: response.data.access_token,
      refreshToken: response.data.refresh_token,
      expiresIn: response.data.expires_in,
      idToken: response.data.id_token
    };
  } catch (error) {
    console.error('Failed to get access token:', error.response?.data || error.message);
    throw new Error('获取Access Token失败');
  }
}

/**
 * 使用Access Token获取用户信息(UnionID/OpenID)
 */
async function getUserInfo(accessToken) {
  try {
    const response = await axios.get(HUAWEI_USER_INFO_URL, {
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    });

    return {
      unionID: response.data.unionID,
      openID: response.data.openID,
      displayName: response.data.displayName,
      country: response.data.country
    };
  } catch (error) {
    console.error('Failed to get user info:', error.response?.data || error.message);
    throw new Error('获取用户信息失败');
  }
}

/**
 * 验证ID Token签名
 */
function verifyIdToken(idToken) {
  try {
    // 解析ID Token (JWT格式)
    const [header, payload, signature] = idToken.split('.');
    
    // 解码payload
    const payloadData = JSON.parse(Buffer.from(payload, 'base64').toString('utf-8'));
    
    // 验证必要字段
    if (payloadData.iss !== 'https://account.huawei.com') {
      throw new Error('无效的issuer');
    }
    
    if (payloadData.aud !== CLIENT_ID) {
      throw new Error('无效的audience');
    }
    
    if (payloadData.exp < Date.now() / 1000) {
      throw new Error('ID Token已过期');
    }
    
    return {
      valid: true,
      data: payloadData
    };
  } catch (error) {
    console.error('Failed to verify ID token:', error.message);
    return {
      valid: false,
      error: error.message
    };
  }
}

/**
 * 使用Refresh Token刷新Access Token
 */
async function refreshAccessToken(refreshToken) {
  try {
    const response = await axios.post(HUAWEI_TOKEN_URL, {
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET
    }, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    });

    return {
      accessToken: response.data.access_token,
      expiresIn: response.data.expires_in
    };
  } catch (error) {
    console.error('Failed to refresh token:', error.response?.data || error.message);
    throw new Error('刷新Token失败');
  }
}

/**
 * 处理登录请求
 */
async function handleLogin(authorizationCode) {
  try {
    // 步骤1: 获取Access Token
    const tokenInfo = await getAccessToken(authorizationCode);
    
    // 步骤2: 验证ID Token (可选，建议执行)
    if (tokenInfo.idToken) {
      const verification = verifyIdToken(tokenInfo.idToken);
      if (!verification.valid) {
        throw new Error('ID Token验证失败');
      }
    }
    
    // 步骤3: 获取用户信息
    const userInfo = await getUserInfo(tokenInfo.accessToken);
    
    // 步骤4: 返回结果给客户端
    return {
      success: true,
      data: {
        unionID: userInfo.unionID,
        openID: userInfo.openID,
        displayName: userInfo.displayName,
        accessToken: tokenInfo.accessToken,
        refreshToken: tokenInfo.refreshToken,
        expiresIn: tokenInfo.expiresIn
      }
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}

// Express路由示例
// app.post('/api/login', async (req, res) => {
//   const { authorizationCode } = req.body;
//   const result = await handleLogin(authorizationCode);
//   res.json(result);
// });

// 导出函数供外部使用
module.exports = {
  handleLogin,
  getAccessToken,
  getUserInfo,
  refreshAccessToken,
  verifyIdToken
};
