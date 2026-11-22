/**
 * 验证Client ID配置示例
 * 用于验证module.json5中的client_id配置是否正确
 */

import { metadataHelper } from '@ohos/metadataHelper';
import { hilog } from '@ohos/hilog';

const TAG = 'ClientIDVerification';
const DOMAIN = 0xFF00;

/**
 * 验证Client ID是否配置正确
 * @returns Promise<string> 返回Client ID值，如果失败则返回空字符串
 */
async function verifyClientId(): Promise<string> {
  try {
    // 1. 尝试读取client_id metadata
    const clientId = await metadataHelper.getMetadata('client_id');
    
    // 2. 验证Client ID是否存在
    if (!clientId || clientId.length === 0) {
      hilog.error(DOMAIN, TAG, 'Client ID未配置或为空');
      return '';
    }
    
    // 3. 验证Client ID长度（通常为64字符）
    if (clientId.length !== 64) {
      hilog.warn(DOMAIN, TAG, `Client ID长度异常: ${clientId.length}，预期64字符`);
    }
    
    // 4. 验证Client ID格式（应为字母数字组合）
    const clientIdPattern = /^[a-zA-Z0-9]+$/;
    if (!clientIdPattern.test(clientId)) {
      hilog.warn(DOMAIN, TAG, 'Client ID包含非字母数字字符');
    }
    
    // 5. 输出成功日志（注意：不要输出完整的Client ID值）
    hilog.info(DOMAIN, TAG, `Client ID配置成功，长度: ${clientId.length}`);
    
    return clientId;
  } catch (error) {
    hilog.error(DOMAIN, TAG, `获取Client ID失败: ${error.message}`);
    return '';
  }
}

/**
 * 检查module.json5配置是否正确
 * 此函数用于开发调试，不用于生产环境
 */
async function checkMetadataConfiguration(): Promise<void> {
  hilog.info(DOMAIN, TAG, '开始检查metadata配置...');
  
  try {
    // 读取所有metadata配置
    const metadata = await metadataHelper.getAllMetadata();
    
    if (!metadata || metadata.length === 0) {
      hilog.error(DOMAIN, TAG, '未找到任何metadata配置');
      return;
    }
    
    hilog.info(DOMAIN, TAG, `发现 ${metadata.length} 个metadata配置`);
    
    // 查找client_id配置
    const clientIdMetadata = metadata.find(item => item.name === 'client_id');
    
    if (!clientIdMetadata) {
      hilog.error(DOMAIN, TAG, '未找到client_id配置');
      hilog.info(DOMAIN, TAG, '请确保module.json5中包含以下配置:');
      hilog.info(DOMAIN, TAG, '"metadata": [{"name": "client_id", "value": "您的Client ID"}]');
      return;
    }
    
    hilog.info(DOMAIN, TAG, 'client_id配置已找到');
    hilog.info(DOMAIN, TAG, `配置值长度: ${clientIdMetadata.value.length}`);
    
    // 验证配置值
    if (clientIdMetadata.value.length === 0) {
      hilog.error(DOMAIN, TAG, 'client_id值为空');
    } else if (clientIdMetadata.value.length !== 64) {
      hilog.warn(DOMAIN, TAG, `client_id长度异常: ${clientIdMetadata.value.length}`);
    } else {
      hilog.info(DOMAIN, TAG, 'client_id配置验证通过');
    }
  } catch (error) {
    hilog.error(DOMAIN, TAG, `检查metadata配置失败: ${error.message}`);
  }
}

/**
 * 验证Client ID与AppGallery Connect平台是否一致
 * 注意：此函数仅作为示例，实际使用时需要连接服务器验证
 * @param expectedClientId 预期的Client ID
 * @returns Promise<boolean> 是否一致
 */
async function verifyClientIdMatch(expectedClientId: string): Promise<boolean> {
  try {
    const actualClientId = await verifyClientId();
    
    if (!actualClientId) {
      hilog.error(DOMAIN, TAG, '无法读取配置的Client ID');
      return false;
    }
    
    if (actualClientId === expectedClientId) {
      hilog.info(DOMAIN, TAG, 'Client ID验证成功，与AppGallery Connect平台一致');
      return true;
    } else {
      hilog.error(DOMAIN, TAG, 'Client ID不匹配，请检查配置');
      hilog.error(DOMAIN, TAG, `预期长度: ${expectedClientId.length}, 实际长度: ${actualClientId.length}`);
      return false;
    }
  } catch (error) {
    hilog.error(DOMAIN, TAG, `验证Client ID失败: ${error.message}`);
    return false;
  }
}

/**
 * 完整的配置验证流程
 */
export async function performFullVerification(): Promise<void> {
  hilog.info(DOMAIN, TAG, '=== 开始完整配置验证 ===');
  
  // 1. 检查metadata配置
  await checkMetadataConfiguration();
  
  // 2. 验证Client ID
  const clientId = await verifyClientId();
  
  if (clientId) {
    hilog.info(DOMAIN, TAG, '✓ Client ID配置正确');
    
    // 3. 可选：验证是否与平台一致
    // 需要从安全的地方获取预期的Client ID进行比对
    // const expectedClientId = '您的预期Client ID';
    // await verifyClientIdMatch(expectedClientId);
  } else {
    hilog.error(DOMAIN, TAG, '✗ Client ID配置失败');
    hilog.error(DOMAIN, TAG, '请检查以下事项:');
    hilog.error(DOMAIN, TAG, '1. module.json5文件是否正确配置了metadata');
    hilog.error(DOMAIN, TAG, '2. metadata数组是否在module对象内部');
    hilog.error(DOMAIN, TAG, '3. client_id的name和value字段是否都存在');
    hilog.error(DOMAIN, TAG, '4. Client ID值是否从AppGallery Connect平台正确复制');
  }
  
  hilog.info(DOMAIN, TAG, '=== 配置验证完成 ===');
}

// 导出验证函数
export { verifyClientId, checkMetadataConfiguration, verifyClientIdMatch };