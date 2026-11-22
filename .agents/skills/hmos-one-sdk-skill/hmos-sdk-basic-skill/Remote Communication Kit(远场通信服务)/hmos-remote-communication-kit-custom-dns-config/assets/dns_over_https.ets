/**
 * DNS over HTTPS示例
 * 演示如何配置DNS over HTTPS（DoH）加密解析
 */

import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 示例1：基础DNS over HTTPS配置
async function testBasicDoh(): Promise<void> {
  try {
    // 创建会话，配置DNS over HTTPS
    const session = rcp.createSession({
      requestConfiguration: {
        dns: {
          dnsOverHttps: {
            url: 'https://dns.google/dns-query',  // Google DoH服务器
            skipCertificatesValidation: false      // 启用证书验证
          }
        }
      }
    });

    // 创建请求
    const request = new rcp.Request('https://example.com/api/data');

    // 发送请求（使用DoH加密解析）
    const response = await session.fetch(request);
    console.info(`Response status: ${response.statusCode}`);
    console.info('DNS over HTTPS enabled');

    session.close();
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Error code: ${err.code}, message: ${err.data}`);
  }
}

// 示例2：使用Cloudflare DoH服务器
async function testCloudflareDoh(): Promise<void> {
  try {
    // 创建会话，配置Cloudflare DoH服务器
    const session = rcp.createSession({
      requestConfiguration: {
        dns: {
          dnsOverHttps: {
            url: 'https://cloudflare-dns.com/dns-query',  // Cloudflare DoH
            skipCertificatesValidation: false
          }
        }
      }
    });

    // 创建请求
    const request = new rcp.Request('https://example.com/api/data');

    // 发送请求
    const response = await session.fetch(request);
    console.info(`Response status: ${response.statusCode}`);

    session.close();
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Error code: ${err.code}, message: ${err.data}`);
  }
}

// 示例3：跳过证书验证（仅测试环境）
async function testDohSkipCertValidation(): Promise<void> {
  try {
    // 创建会话，配置DoH并跳过证书验证
    const session = rcp.createSession({
      requestConfiguration: {
        dns: {
          dnsOverHttps: {
            url: 'https://internal-dns.example.com/dns-query',
            skipCertificatesValidation: true  // 跳过证书验证（仅测试环境）
          }
        }
      }
    });

    // 创建请求
    const request = new rcp.Request('https://example.com/api/data');

    // 发送请求
    const response = await session.fetch(request);
    console.info(`Response status: ${response.statusCode}`);
    console.warn('Certificate validation skipped (only for testing)');

    session.close();
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Error code: ${err.code}, message: ${err.data}`);
  }
}

// 示例4：DoH配置优先级高于dnsRules
async function testDohPriorityOverDnsRules(): Promise<void> {
  try {
    // 创建会话，同时配置dnsRules和dnsOverHttps
    const session = rcp.createSession({
      requestConfiguration: {
        dns: {
          dnsRules: [
            {
              host: 'example.com',
              port: 443,
              ipAddresses: ['192.168.1.100']
            }
          ],
          dnsOverHttps: {
            url: 'https://dns.google/dns-query',
            skipCertificatesValidation: false
          }
        }
      }
    });

    // 创建请求
    const request = new rcp.Request('https://example.com/api/data');

    // 发送请求
    // 注意：dnsOverHttps优先级高于dnsRules，会优先使用DoH解析
    const response = await session.fetch(request);
    console.info(`Response status: ${response.statusCode}`);
    console.info('DNS over HTTPS has higher priority than dnsRules');

    session.close();
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Error code: ${err.code}, message: ${err.data}`);
  }
}

// 示例5：请求级别配置DoH
async function testRequestLevelDoh(): Promise<void> {
  try {
    // 创建基础会话
    const session = rcp.createSession();

    // 创建请求
    const request = new rcp.Request('https://example.com/api/data');

    // 在请求级别配置DoH
    request.configuration = {
      dns: {
        dnsOverHttps: {
          url: 'https://dns.google/dns-query',
          skipCertificatesValidation: false
        }
      }
    };

    // 发送请求
    const response = await session.fetch(request);
    console.info(`Response status: ${response.statusCode}`);

    session.close();
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Error code: ${err.code}, message: ${err.data}`);
  }
}

// 示例6：DoH失败降级方案
async function testDohFallback(): Promise<void> {
  try {
    const session = rcp.createSession();
    const request = new rcp.Request('https://example.com/api/data');

    // 配置无效的DoH URL
    request.configuration = {
      dns: {
        dnsOverHttps: {
          url: 'https://invalid.doh.server/dns-query',
          skipCertificatesValidation: false
        }
      }
    };

    // 尝试使用DoH
    try {
      const response = await session.fetch(request);
      console.info(`Response status: ${response.statusCode}`);
    } catch (error) {
      console.warn('DNS over HTTPS failed, falling back to system DNS');

      // 降级方案：清除DoH配置使用系统DNS
      request.configuration = {
        dns: undefined
      };

      const fallbackResponse = await session.fetch(request);
      console.info(`Fallback response status: ${fallbackResponse.statusCode}`);
    }

    session.close();
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Error code: ${err.code}, message: ${err.data}`);
  }
}

// 示例7：混合配置DoH和静态DNS规则
async function testMixedDohAndStaticDns(): Promise<void> {
  try {
    // 创建会话，混合配置DoH和静态DNS规则
    const session = rcp.createSession({
      requestConfiguration: {
        dns: {
          // 静态DNS规则：某些域名使用固定IP
          dnsRules: [
            {
              host: 'internal.example.com',
              port: 443,
              ipAddresses: ['10.0.0.1']
            }
          ],
          // DoH：其他域名使用加密DNS解析
          dnsOverHttps: {
            url: 'https://dns.google/dns-query',
            skipCertificatesValidation: false
          }
        }
      }
    });

    // 创建内部域名请求（使用静态DNS规则）
    const internalRequest = new rcp.Request('https://internal.example.com/api/data');
    const internalResponse = await session.fetch(internalRequest);
    console.info(`Internal response status: ${internalResponse.statusCode}`);
    console.info('Internal domain uses static DNS rule');

    // 创建外部域名请求（使用DoH）
    const externalRequest = new rcp.Request('https://external.example.com/api/data');
    const externalResponse = await session.fetch(externalRequest);
    console.info(`External response status: ${externalResponse.statusCode}`);
    console.info('External domain uses DNS over HTTPS');

    session.close();
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Error code: ${err.code}, message: ${err.data}`);
  }
}

// 主函数：运行所有示例
async function main(): Promise<void> {
  console.info('=== 测试基础DNS over HTTPS ===');
  await testBasicDoh();

  console.info('=== 测试Cloudflare DoH服务器 ===');
  await testCloudflareDoh();

  console.info('=== 测试跳过证书验证 ===');
  await testDohSkipCertValidation();

  console.info('=== 测试DoH优先级高于dnsRules ===');
  await testDohPriorityOverDnsRules();

  console.info('=== 测试请求级别配置DoH ===');
  await testRequestLevelDoh();

  console.info('=== 测试DoH失败降级方案 ===');
  await testDohFallback();

  console.info('=== 测试混合配置DoH和静态DNS规则 ===');
  await testMixedDohAndStaticDns();
}

export { main };