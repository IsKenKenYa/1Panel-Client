import fs from '@ohos.file.fs';
import json5 from 'json5';
import bundleManager from '@ohos.bundle.bundleManager';

/**
 * Client ID配置验证工具
 * 用于验证module.json5中Client ID配置的正确性
 */
export class ClientIDVerifier {
  private moduleJson5Path: string;

  constructor(moduleJson5Path: string) {
    this.moduleJson5Path = moduleJson5Path;
  }

  /**
   * 验证Client ID配置
   * @returns 验证结果
   */
  verify(): VerifierResult {
    const result: VerifierResult = {
      success: true,
      errors: [],
      warnings: [],
      info: {}
    };

    try {
      // 读取module.json5文件
      const content = this.readModuleJson5();
      
      // 解析JSON5
      const moduleConfig = this.parseJson5(content);
      
      // 验证模块类型
      this.verifyModuleType(moduleConfig, result);
      
      // 验证metadata配置
      this.verifyMetadata(moduleConfig, result);
      
      // 验证Client ID配置
      this.verifyClientID(moduleConfig, result);

    } catch (error) {
      result.success = false;
      result.errors.push(`验证失败: ${error.message}`);
    }

    return result;
  }

  /**
   * 读取module.json5文件
   */
  private readModuleJson5(): string {
    try {
      const content = fs.readTextSync(this.moduleJson5Path);
      if (!content || content.trim().length === 0) {
        throw new Error('module.json5文件为空');
      }
      return content;
    } catch (error) {
      throw new Error(`读取module.json5失败: ${error.message}`);
    }
  }

  /**
   * 解析JSON5内容
   */
  private parseJson5(content: string): any {
    try {
      return json5.parse(content);
    } catch (error) {
      throw new Error('module.json5格式错误，请检查JSON5语法');
    }
  }

  /**
   * 验证模块类型
   */
  private verifyModuleType(config: any, result: VerifierResult): void {
    if (!config.module) {
      result.success = false;
      result.errors.push('module.json5缺少module字段');
      return;
    }

    if (config.module.type !== 'entry') {
      result.success = false;
      result.errors.push(`模块类型错误: 当前类型为"${config.module.type}"，必须为"entry"`);
      return;
    }

    result.info.moduleName = config.module.name;
    result.info.moduleType = config.module.type;
  }

  /**
   * 验证metadata配置
   */
  private verifyMetadata(config: any, result: VerifierResult): void {
    if (!config.module.metadata) {
      result.success = false;
      result.errors.push('缺少metadata配置');
      return;
    }

    if (!Array.isArray(config.module.metadata)) {
      result.success = false;
      result.errors.push('metadata必须是数组类型');
      return;
    }

    result.info.metadataCount = config.module.metadata.length;
  }

  /**
   * 验证Client ID配置
   */
  private verifyClientID(config: any, result: VerifierResult): void {
    const metadata = config.module.metadata;
    
    // 查找client_id配置
    const clientIDConfig = metadata.find((item: any) => item.name === 'client_id');

    if (!clientIDConfig) {
      result.success = false;
      result.errors.push('未找到client_id配置');
      return;
    }

    // 检查是否有重复配置
    const clientIDCount = metadata.filter((item: any) => item.name === 'client_id').length;
    if (clientIDCount > 1) {
      result.warnings.push(`检测到${clientIDCount}个client_id配置，建议只保留一个`);
    }

    // 验证value
    if (!clientIDConfig.value) {
      result.success = false;
      result.errors.push('client_id的value为空');
      return;
    }

    if (typeof clientIDConfig.value !== 'string') {
      result.success = false;
      result.errors.push(`client_id的value类型错误: 期望string，实际为${typeof clientIDConfig.value}`);
      return;
    }

    // 检查value是否有效
    const clientID = clientIDConfig.value.trim();
    if (clientID.length === 0) {
      result.success = false;
      result.errors.push('client_id的value为空字符串');
      return;
    }

    // 检查是否包含可能的错误值
    if (clientID.includes('你的') || clientID.includes('示例') || clientID === 'xxxxx') {
      result.warnings.push('client_id可能是示例值，请确认已替换为真实的应用Client ID');
    }

    result.info.clientID = clientID;
    result.info.clientIDLength = clientID.length;
  }

  /**
   * 获取运行时metadata配置
   */
  async getRuntimeMetadata(): Promise<any> {
    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_WITH_EXTENSION_ABILITY
      );
      return bundleInfo.metadata;
    } catch (error) {
      throw new Error(`获取运行时metadata失败: ${error.message}`);
    }
  }

  /**
   * 打印验证结果
   */
  printResult(result: VerifierResult): void {
    console.log('\n========== Client ID配置验证结果 ==========\n');
    
    if (result.success) {
      console.log('✓ 验证通过\n');
    } else {
      console.log('✗ 验证失败\n');
    }

    // 打印信息
    if (result.info.moduleName) {
      console.log(`模块名称: ${result.info.moduleName}`);
    }
    if (result.info.moduleType) {
      console.log(`模块类型: ${result.info.moduleType}`);
    }
    if (result.info.metadataCount !== undefined) {
      console.log(`metadata配置数量: ${result.info.metadataCount}`);
    }
    if (result.info.clientID) {
      console.log(`Client ID: ${result.info.clientID}`);
      console.log(`Client ID长度: ${result.info.clientIDLength}`);
    }

    // 打印错误
    if (result.errors.length > 0) {
      console.log('\n错误:');
      result.errors.forEach((error, index) => {
        console.log(`  ${index + 1}. ${error}`);
      });
    }

    // 打印警告
    if (result.warnings.length > 0) {
      console.log('\n警告:');
      result.warnings.forEach((warning, index) => {
        console.log(`  ${index + 1}. ${warning}`);
      });
    }

    console.log('\n==========================================\n');
  }
}

/**
 * 验证结果接口
 */
export interface VerifierResult {
  success: boolean;
  errors: string[];
  warnings: string[];
  info: {
    moduleName?: string;
    moduleType?: string;
    metadataCount?: number;
    clientID?: string;
    clientIDLength?: number;
    [key: string]: any;
  };
}

/**
 * 使用示例
 */
export async function verifyClientIDExample(): Promise<void> {
  const moduleJson5Path = 'entry/src/main/module.json5';
  const verifier = new ClientIDVerifier(moduleJson5Path);
  
  const result = verifier.verify();
  verifier.printResult(result);

  if (result.success) {
    console.log('Client ID配置正确，可以进行后续开发');
  } else {
    console.log('请修复上述错误后重新验证');
  }
}