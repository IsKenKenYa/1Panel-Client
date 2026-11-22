import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TEST_URL = 'https://example.com'; // 请替换为实际的 HTTPS 网址

// 证书公钥 SHA256 哈希值的 BASE64 编码
// 获取方法：
// 1. openssl x509 -in example.pem -noout -pubkey | openssl asn1parse -noout -inform pem -out example.public.key
// 2. openssl dgst -sha256 -binary example.public.key | openssl enc -base64
const RIGHT_EXAMPLE_PUBLIC_KEY_SHA256_HASH = [
  'iMMpIJdSf5VlClHaxZReyhaLxLsmZMMNAiA2pMR8/M4=', // 替换为实际的公钥哈希值
  'qBRjZmOmkSNJL0p70zek7odSIzqs/muR4Jk9xYyCP+E=' // 替换为实际的公钥哈希值
];

/**
 * 配置单个证书锁定
 */
async function testSingleCertificatePinning(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request(TEST_URL);
  
  // 配置单个证书锁定
  request.configuration = {
    security: {
      certificatePinning: {
        kind: 'public-key',
        publicKeyHash: RIGHT_EXAMPLE_PUBLIC_KEY_SHA256_HASH[0],
        hashAlgorithm: 'SHA-256'
      }
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info('Certificate pinning test succeeded: ' + response.statusCode);
    console.info('Response: ' + JSON.stringify(response.toString()));
  } catch (e) {
    console.error('Certificate pinning test failed: ' + JSON.stringify(e));
    throw e;
  } finally {
    session.close();
  }
}

/**
 * 配置多个证书锁定（支持证书更新）
 */
async function testMultipleCertificatePinning(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request(TEST_URL);
  
  // 配置多个证书锁定（可以包含新旧证书的哈希值）
  request.configuration = {
    security: {
      certificatePinning: [
        {
          kind: 'public-key',
          publicKeyHash: RIGHT_EXAMPLE_PUBLIC_KEY_SHA256_HASH[0],
          hashAlgorithm: 'SHA-256'
        },
        {
          kind: 'public-key',
          publicKeyHash: RIGHT_EXAMPLE_PUBLIC_KEY_SHA256_HASH[1],
          hashAlgorithm: 'SHA-256'
        }
      ]
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info('Certificate pinning test succeeded: ' + response.statusCode);
    console.info('Response: ' + JSON.stringify(response.toString()));
  } catch (e) {
    console.error('Certificate pinning test failed: ' + JSON.stringify(e));
    throw e;
  } finally {
    session.close();
  }
}

/**
 * 结合其他安全配置的完整示例
 */
async function testCompleteSecurityConfiguration(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request(TEST_URL);
  
  // 配置完整的安全设置
  request.configuration = {
    security: {
      // 客户端校验服务端证书
      remoteValidation: 'system',
      
      // 证书锁定
      certificatePinning: [
        {
          kind: 'public-key',
          publicKeyHash: RIGHT_EXAMPLE_PUBLIC_KEY_SHA256_HASH[0],
          hashAlgorithm: 'SHA-256'
        }
      ],
      
      // 服务端校验客户端证书（可选）
      certificate: {
        filePath: '/data/storage/el1/bundle/entry/resources/resfile/cert.pem',
        type: 'PEM',
        key: '/data/storage/el1/bundle/entry/resources/resfile/cert.key',
        keyPassword: 'keyPassword'
      }
    },
    
    // 超时配置
    transfer: {
      timeout: {
        connectMs: 5000,
        transferMs: 10000
      }
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info('Complete security configuration test succeeded: ' + response.statusCode);
    console.info('Response: ' + JSON.stringify(response.toString()));
  } catch (e) {
    console.error('Complete security configuration test failed: ' + JSON.stringify(e));
    throw e;
  } finally {
    session.close();
  }
}

/**
 * 错误处理示例
 */
async function testCertificatePinningWithErrorHandling(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request(TEST_URL);
  
  request.configuration = {
    security: {
      certificatePinning: [
        {
          kind: 'public-key',
          publicKeyHash: RIGHT_EXAMPLE_PUBLIC_KEY_SHA256_HASH[0],
          hashAlgorithm: 'SHA-256'
        }
      ]
    }
  };
  
  try {
    const response = await session.fetch(request);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      console.info('Request succeeded: ' + response.statusCode);
      return response;
    } else {
      console.warn('Server returned error status: ' + response.statusCode);
      throw new Error('HTTP error: ' + response.statusCode);
    }
  } catch (err) {
    const error = err as BusinessError;
    
    switch (error.code) {
      case 1007900003:
        console.error('Certificate pinning failed: public key hash mismatch');
        console.error('Please verify the public key hash is correct');
        throw new Error('Certificate pinning failed. Please check your hash configuration.');
      
      case 401:
        console.error('Parameter error: invalid certificate pinning configuration');
        throw new Error('Invalid configuration. Please check your parameters.');
      
      default:
        console.error('Unknown error: code ' + error.code + ', message ' + error.data);
        throw error;
    }
  } finally {
    session.close();
  }
}

// 主函数
async function main(): Promise<void> {
  try {
    console.info('=== Testing single certificate pinning ===');
    await testSingleCertificatePinning();
    
    console.info('=== Testing multiple certificate pinning ===');
    await testMultipleCertificatePinning();
    
    console.info('=== Testing complete security configuration ===');
    await testCompleteSecurityConfiguration();
    
    console.info('=== Testing certificate pinning with error handling ===');
    await testCertificatePinningWithErrorHandling();
  } catch (error) {
    console.error('Test failed:', error);
  }
}

main();