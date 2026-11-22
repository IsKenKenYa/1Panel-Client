/**
 * 静态DNS规则示例
 * 演示如何配置域名与IP地址的静态映射关系
 */

import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 示例1：配置单个静态DNS规则
async function testSingleStaticDnsRule(): Promise<void> {
  try {
    // 创建会话，配置单个静态DNS规则
    const session = rcp.createSession({
      requestConfiguration: {
        dns: {
          dnsRules: [
            {
              host: 'example.com',
              port: 443,
              ipAddresses: ['192.168.1.100']
            }
          ]
        }
      }
    });

    // 创建请求（域名匹配静态规则）
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

// 示例2：配置多个静态DNS规则
async function testMultipleStaticDnsRules(): Promise<void> {
  try {
    // 创建会话，配置多个静态DNS规则
    const session = rcp.createSession({
      requestConfiguration: {
        dns: {
          dnsRules: [
            {
              host: 'api.example.com',
              port: 443,
              ipAddresses: ['10.0.0.1']
            },
            {
              host: 'cdn.example.com',
              port: 443,
              ipAddresses: ['10.0.1.1']
            },
            {
              host: 'static.example.com',
              port: 80,
              ipAddresses: ['10.0.2.1']
            }
          ]
        }
      }
    });

    // 创建多个请求
    const requests = [
      new rcp.Request('https://api.example.com/v1/users'),
      new rcp.Request('https://cdn.example.com/assets/image.png'),
      new rcp.Request('http://static.example.com/files/document.pdf')
    ];

    // 发送所有请求
    for (const request of requests) {
      try {
        const response = await session.fetch(request);
        console.info(`${request.url.href} - Status: ${response.statusCode}`);
      } catch (error) {
        const err = error as BusinessError;
        console.error(`${request.url.href} - Error: ${err.code}`);
      }
    }

    session.close();
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Error code: ${err.code}, message: ${err.data}`);
  }
}

// 示例3：配置多个IP地址并启用Happy Eyeball（6.0.0(20)+）
async function testMultipleIpsWithHappyEyeball(): Promise<void> {
  try {
    // 创建会话，配置多个IP地址
    const session = rcp.createSession({
      requestConfiguration: {
        dns: {
          dnsRules: [
            {
              host: 'example.com',
              port: 443,
              ipAddresses: ['192.168.1.100', '192.168.1.101', '192.168.1.102']
            }
          ],
          happyEyeballOnDnsRule: true  // 启用多IP竞速连接
        }
      }
    });

    // 创建请求
    const request = new rcp.Request('https://example.com/api/data');

    // 发送请求（系统会自动选择最快的IP地址）
    const response = await session.fetch(request);
    console.info(`Response status: ${response.statusCode}`);

    session.close();
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Error code: ${err.code}, message: ${err.data}`);
  }
}

// 示例4：混合IPv4和IPv6地址
async function testMixedIpv4AndIpv6(): Promise<void> {
  try {
    // 创建会话，配置IPv4和IPv6混合地址
    const session = rcp.createSession({
      requestConfiguration: {
        dns: {
          dnsRules: [
            {
              host: 'example.com',
              port: 443,
              ipAddresses: [
                '192.168.1.100',        // IPv4地址
                '2001:db8::1',          // IPv6地址
                '192.168.1.101',        // IPv4备用地址
                '2001:db8::2'           // IPv6备用地址
              ]
            }
          ],
          happyEyeballOnDnsRule: true
        }
      }
    });

    // 创建请求
    const request = new rcp.Request('https://example.com/api/data');

    // 发送请求（系统会根据网络环境选择IPv4或IPv6）
    const response = await session.fetch(request);
    console.info(`Response status: ${response.statusCode}`);

    session.close();
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Error code: ${err.code}, message: ${err.data}`);
  }
}

// 示例5：请求级别配置静态DNS规则
async function testRequestLevelStaticDnsRule(): Promise<void> {
  try {
    // 创建基础会话
    const session = rcp.createSession();

    // 创建请求
    const request = new rcp.Request('https://internal.example.com/api/data');

    // 在请求级别配置静态DNS规则（仅针对此请求）
    request.configuration = {
      dns: {
        dnsRules: [
          {
            host: 'internal.example.com',
            port: 443,
            ipAddresses: ['10.10.10.10']
          }
        ]
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

// 主函数：运行所有示例
async function main(): Promise<void> {
  console.info('=== 测试单个静态DNS规则 ===');
  await testSingleStaticDnsRule();

  console.info('=== 测试多个静态DNS规则 ===');
  await testMultipleStaticDnsRules();

  console.info('=== 测试多个IP地址并启用Happy Eyeball ===');
  await testMultipleIpsWithHappyEyeball();

  console.info('=== 测试混合IPv4和IPv6地址 ===');
  await testMixedIpv4AndIpv6();

  console.info('=== 测试请求级别静态DNS规则 ===');
  await testRequestLevelStaticDnsRule();
}

export { main };