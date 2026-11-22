/**
 * 定制DNS服务器示例
 * 演示如何配置自定义DNS服务器进行域名解析
 */

import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 示例1：配置单个DNS服务器
async function testSingleDnsServer(): Promise<void> {
  try {
    // 创建会话，配置单个DNS服务器
    const session = rcp.createSession({
      requestConfiguration: {
        dns: {
          dnsRules: [
            { ip: '8.8.8.8', port: 53 }  // Google DNS
          ]
        }
      }
    });

    // 创建请求
    const request = new rcp.Request('https://example.com/api/data');

    // 发送请求
    const response = await session.fetch(request);
    console.info(`Response status: ${response.statusCode}`);
    console.info(`Response headers: ${JSON.stringify(response.headers)}`);

    // 关闭会话
    session.close();
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Error code: ${err.code}, message: ${err.data}`);
  }
}

// 示例2：配置多个DNS服务器
async function testMultipleDnsServers(): Promise<void> {
  try {
    // 创建会话，配置多个DNS服务器
    const session = rcp.createSession({
      requestConfiguration: {
        dns: {
          dnsRules: [
            { ip: '8.8.8.8', port: 53 },   // Google DNS主服务器
            { ip: '8.8.4.4', port: 53 },   // Google DNS备用服务器
            { ip: '1.1.1.1', port: 53 }    // Cloudflare DNS
          ]
        }
      }
    });

    // 创建请求
    const request = new rcp.Request('https://example.com/api/data');

    // 发送请求
    const response = await session.fetch(request);
    console.info(`Response status: ${response.statusCode}`);

    // 关闭会话
    session.close();
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Error code: ${err.code}, message: ${err.data}`);
  }
}

// 示例3：在请求级别配置DNS服务器（覆盖Session配置）
async function testRequestLevelDnsServer(): Promise<void> {
  try {
    // 创建基础会话
    const session = rcp.createSession();

    // 创建请求
    const request = new rcp.Request('https://example.com/api/data');

    // 在请求级别配置DNS服务器
    request.configuration = {
      dns: {
        dnsRules: [
          { ip: '192.168.1.100', port: 53 }  // 内部DNS服务器
        ]
      }
    };

    // 发送请求
    const response = await session.fetch(request);
    console.info(`Response status: ${response.statusCode}`);

    // 关闭会话
    session.close();
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Error code: ${err.code}, message: ${err.data}`);
  }
}

// 示例4：DNS服务器失败降级方案
async function testDnsServerFallback(): Promise<void> {
  try {
    const session = rcp.createSession();
    const request = new rcp.Request('https://example.com/api/data');

    // 配置自定义DNS服务器
    request.configuration = {
      dns: {
        dnsRules: [
          { ip: 'invalid.dns.server', port: 53 }  // 无效DNS服务器
        ]
      }
    };

    // 尝试使用自定义DNS
    try {
      const response = await session.fetch(request);
      console.info(`Response status: ${response.statusCode}`);
    } catch (error) {
      console.warn('Custom DNS failed, falling back to system DNS');

      // 降级方案：清除DNS配置使用系统DNS
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

// 主函数：运行所有示例
async function main(): Promise<void> {
  console.info('=== 测试单个DNS服务器 ===');
  await testSingleDnsServer();

  console.info('=== 测试多个DNS服务器 ===');
  await testMultipleDnsServers();

  console.info('=== 测试请求级别DNS服务器 ===');
  await testRequestLevelDnsServer();

  console.info('=== 测试DNS服务器降级方案 ===');
  await testDnsServerFallback();
}

export { main };