/**
 * 完整的静默登录端到端流程示例
 * 
 * 本示例展示从客户端到服务端的完整静默登录流程
 * 流程：客户端获取Authorization Code -> 服务端获取Access Token -> 解析用户信息 -> 完成登录
 */

const axios = require('axios');

// 导入其他模块（假设已拆分为独立文件）
// const { getAccessToken, refreshAccessToken } = require('./get_access_token');
// const { parseAccessToken, verifyUserIdentity } = require('./parse_access_token');

// 配置信息
const CONFIG = {
  clientId: process.env.CLIENT_ID || '<your_client_id>',
  clientSecret: process.env.CLIENT_SECRET || '<your_client_secret>',
  huaweiOAuthUrl: 'https://oauth-login.cloud.huawei.com/oauth2/v3/token',
  huaweiApiUrl: 'https://oauth-api.cloud.huawei.com/rest.php?nsp_fmt=JSON&nsp_svc=huawei.oauth2.user.getTokenInfo'
};

/**
 * 静默登录完整流程
 */
class SilentLoginFlow {
  
  constructor() {
    this.accessToken = null;
    this.refreshToken = null;
    this.userInfo = null;
  }
  
  /**
   * 步骤1：接收客户端的Authorization Code
   * 
   * @param {string} authorizationCode - Authorization Code
   * @param {string} state - State参数（用于校验）
   * @returns {Promise<Object>} Token信息
   */
  async receiveAuthorizationCode(authorizationCode, state) {
    console.log('=== 步骤1：接收Authorization Code ===');
    console.log(`Authorization Code: ${authorizationCode.substring(0, 20)}...`);
    console.log(`State: ${state}`);
    
    // 注意：state参数应在服务端保存，与客户端请求时的state进行比对
    // 此处省略state校验逻辑，实际应用中必须实现
    
    // 步骤2：使用Authorization Code获取Access Token
    const tokenInfo = await this.getAccessToken(authorizationCode);
    
    return tokenInfo;
  }
  
  /**
   * 步骤2：获取Access Token
   * 
   * @param {string} authorizationCode - Authorization Code
   * @returns {Promise<Object>} Token信息
   */
  async getAccessToken(authorizationCode) {
    console.log('\n=== 步骤2：获取Access Token ===');
    
    const params = new URLSearchParams();
    params.append('grant_type', 'authorization_code');
    params.append('code', authorizationCode);
    params.append('client_id', CONFIG.clientId);
    params.append('client_secret', CONFIG.clientSecret);
    params.append('supportAlg', 'PS256');
    
    try {
      const response = await axios.post(CONFIG.huaweiOAuthUrl, params, {
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        timeout: 30000
      });
      
      this.accessToken = response.data.access_token;
      this.refreshToken = response.data.refresh_token;
      
      console.log('✓ 成功获取Access Token');
      console.log(`Access Token: ${this.accessToken.substring(0, 30)}...`);
      console.log(`Expires In: ${response.data.expires_in} seconds`);
      console.log(`Scope: ${response.data.scope}`);
      
      return {
        accessToken: this.accessToken,
        refreshToken: this.refreshToken,
        expiresIn: response.data.expires_in,
        idToken: response.data.id_token,
        scope: response.data.scope
      };
      
    } catch (error) {
      console.error('✗ 获取Access Token失败');
      throw this.handleTokenError(error);
    }
  }
  
  /**
   * 步骤3：解析Access Token获取用户信息
   * 
   * @returns {Promise<Object>} 用户信息
   */
  async parseUserInfo() {
    console.log('\n=== 步骤3：解析Access Token获取用户信息 ===');
    
    const params = new URLSearchParams();
    params.append('access_token', this.accessToken);
    params.append('open_id', 'OPENID');
    
    try {
      const response = await axios.post(CONFIG.huaweiApiUrl, params, {
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        timeout: 30000
      });
      
      this.userInfo = {
        unionId: response.data.union_id,
        openId: response.data.open_id,
        clientId: response.data.client_id,
        expiresIn: response.data.expire_in
      };
      
      console.log('✓ 成功解析用户信息');
      console.log(`UnionID: ${this.userInfo.unionId}`);
      console.log(`OpenID: ${this.userInfo.openId}`);
      console.log(`Expires In: ${this.userInfo.expiresIn} seconds`);
      
      return this.userInfo;
      
    } catch (error) {
      console.error('✗ 解析用户信息失败');
      throw this.handleParseError(error);
    }
  }
  
  /**
   * 步骤4：验证用户身份并完成登录
   * 
   * @returns {Promise<Object>} 登录结果
   */
  async completeLogin() {
    console.log('\n=== 步骤4：验证用户身份并完成登录 ===');
    
    if (!this.userInfo || !this.userInfo.unionId) {
      throw new Error('用户信息不完整，无法完成登录');
    }
    
    // 查询用户数据库，判断用户是否已存在
    // 实际应用中需要查询数据库
    const existingUser = await this.queryUserByUnionId(this.userInfo.unionId);
    
    if (existingUser) {
      // 用户已存在，更新Session
      console.log('✓ 用户已存在，完成登录');
      
      const sessionId = this.generateSessionId();
      await this.updateUserSession(existingUser.id, sessionId);
      
      return {
        success: true,
        isNewUser: false,
        userId: existingUser.id,
        unionId: this.userInfo.unionId,
        openId: this.userInfo.openId,
        sessionId: sessionId
      };
    } else {
      // 用户不存在，创建新用户
      console.log('✓ 创建新用户并完成登录');
      
      const newUser = await this.createNewUser(this.userInfo.unionId, this.userInfo.openId);
      const sessionId = this.generateSessionId();
      await this.updateUserSession(newUser.id, sessionId);
      
      return {
        success: true,
        isNewUser: true,
        userId: newUser.id,
        unionId: this.userInfo.unionId,
        openId: this.userInfo.openId,
        sessionId: sessionId
      };
    }
  }
  
  /**
   * 完整的静默登录流程（一键调用）
   * 
   * @param {string} authorizationCode - Authorization Code
   * @param {string} state - State参数
   * @returns {Promise<Object>} 登录结果
   */
  async performCompleteSilentLogin(authorizationCode, state) {
    console.log('\n=== 开始完整的静默登录流程 ===');
    
    try {
      // 步骤1：接收Authorization Code并获取Token
      await this.receiveAuthorizationCode(authorizationCode, state);
      
      // 步骤2：解析用户信息
      await this.parseUserInfo();
      
      // 步骤3：完成登录
      const loginResult = await this.completeLogin();
      
      console.log('\n✓✓✓ 静默登录流程完成 ✓✓✓');
      console.log(`登录状态: ${loginResult.isNewUser ? '新用户' : '已存在用户'}`);
      console.log(`用户ID: ${loginResult.userId}`);
      console.log(`Session ID: ${loginResult.sessionId}`);
      
      return loginResult;
      
    } catch (error) {
      console.error('\n✗✗✗ 静默登录流程失败 ✗✗✗');
      console.error(`错误: ${error.message}`);
      
      return {
        success: false,
        error: error.message
      };
    }
  }
  
  /**
   * 刷新Token（Access Token过期时）
   */
  async refreshAccessTokenIfNeeded() {
    console.log('\n=== 检查并刷新Token ===');
    
    if (!this.accessToken || !this.refreshToken) {
      throw new Error('Token信息不存在');
    }
    
    // 检查Token是否即将过期
    const userInfo = await this.parseUserInfo();
    
    if (userInfo.expiresIn <= 600) { // 10分钟内过期
      console.log('Token即将过期，开始刷新...');
      
      const params = new URLSearchParams();
      params.append('grant_type', 'refresh_token');
      params.append('refresh_token', this.refreshToken);
      params.append('client_id', CONFIG.clientId);
      params.append('client_secret', CONFIG.clientSecret);
      
      const response = await axios.post(CONFIG.huaweiOAuthUrl, params, {
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        timeout: 30000
      });
      
      this.accessToken = response.data.access_token;
      this.refreshToken = response.data.refresh_token;
      
      console.log('✓ Token刷新成功');
    } else {
      console.log('Token无需刷新');
    }
  }
  
  // ===== 辅助函数 =====
  
  /**
   * 处理Token获取错误
   */
  handleTokenError(error) {
    if (error.response) {
      const errorData = error.response.data;
      
      switch (errorData.sub_error) {
        case 12304:
          return new Error('Client Secret无效');
        case 12302:
          return new Error('Authorization Code无效或已过期');
        case 12300:
          return new Error('Authorization Code已使用');
        default:
          return new Error(`Token获取失败: ${errorData.error_description}`);
      }
    }
    
    return new Error('网络连接失败');
  }
  
  /**
   * 处理解析错误
   */
  handleParseError(error) {
    if (error.response) {
      const nspStatus = error.response.headers['nsp_status'];
      
      switch (nspStatus) {
        case '102':
          return new Error('Access Token无效或已过期');
        case '103':
          return new Error('Access Token格式错误');
        default:
          return new Error('用户信息解析失败');
      }
    }
    
    return new Error('网络连接失败');
  }
  
  /**
   * 查询用户（模拟数据库查询）
   */
  async queryUserByUnionId(unionId) {
    // 实际应用中应查询数据库
    // 示例：SELECT * FROM users WHERE union_id = ?
    
    console.log(`查询用户: UnionID=${unionId}`);
    
    // 模拟返回null（用户不存在）
    return null;
  }
  
  /**
   * 创建新用户（模拟数据库插入）
   */
  async createNewUser(unionId, openId) {
    // 实际应用中应插入数据库
    // 示例：INSERT INTO users (union_id, open_id, created_at) VALUES (?, ?, NOW())
    
    console.log(`创建新用户: UnionID=${unionId}, OpenID=${openId}`);
    
    // 模拟返回新用户
    return {
      id: 'user_' + Date.now(),
      unionId: unionId,
      openId: openId,
      createdAt: new Date()
    };
  }
  
  /**
   * 更新用户Session（模拟）
   */
  async updateUserSession(userId, sessionId) {
    // 实际应用中应更新数据库或Session存储
    // 示例：UPDATE users SET session_id = ?, last_login = NOW() WHERE id = ?
    
    console.log(`更新Session: UserID=${userId}, SessionID=${sessionId}`);
  }
  
  /**
   * 生成Session ID
   */
  generateSessionId() {
    return 'session_' + Date.now() + '_' + Math.random().toString(36).substring(7);
  }
}

/**
 * 使用示例
 */
async function completeSilentLoginExample() {
  console.log('====================================');
  console.log('完整的静默登录端到端流程示例');
  console.log('====================================');
  
  const flow = new SilentLoginFlow();
  
  // 模拟客户端传来的Authorization Code
  const authorizationCode = '<从客户端获取的Authorization Code>';
  const state = '<客户端生成的state参数>';
  
  // 执行完整的静默登录流程
  const result = await flow.performCompleteSilentLogin(authorizationCode, state);
  
  if (result.success) {
    console.log('\n登录结果:');
    console.log(JSON.stringify(result, null, 2));
  } else {
    console.log('\n登录失败:');
    console.log(result.error);
  }
}

/**
 * API端点示例（Express框架）
 */
function expressApiExample() {
  // 假设使用Express框架
  // 实际应用中需要安装express和body-parser
  
  /*
  const express = require('express');
  const bodyParser = require('body-parser');
  
  const app = express();
  app.use(bodyParser.json());
  
  // 静默登录API端点
  app.post('/api/silent-login', async (req, res) => {
    const { authorizationCode, state } = req.body;
    
    const flow = new SilentLoginFlow();
    const result = await flow.performCompleteSilentLogin(authorizationCode, state);
    
    if (result.success) {
      res.json({
        status: 'success',
        data: result
      });
    } else {
      res.status(400).json({
        status: 'error',
        message: result.error
      });
    }
  });
  
  app.listen(3000, () => {
    console.log('Server running on port 3000');
  });
  */
}

// 导出类
module.exports = {
  SilentLoginFlow
};

// 如果直接运行此文件，执行示例
if (require.main === module) {
  completeSilentLoginExample().catch(console.error);
}