/**
 * 动态DNS函数示例
 * 演示如何通过函数动态返回IP地址
 */

import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 示例1：基础动态DNS函数
async function testBasicDynamicDnsFunction(): Promise<void> {
  try {
    // 创建会话，配置动态DNS函数
    const session = rcp.createSession({
      requestConfiguration: {
        dns: {
          dnsRules: (host: string, port: number): rcp.IpAddress[] => {
            console.info(`DNS function called: host=${host}, port=${port}`);

            // 根据hostname和port返回不同的IP地址
            if (host === 'api.example.com') {
              return ['10.0.0.1', '10.0.0.2'];
            }

            if (host === 'cdn.example.com') {
              return ['10.0.1.1'];
            }

            // 无法解析的域名返回空数组，使用系统DNS
            return [];
          }
        }
      }
    });

    // 创建请求
    const request = new rcp.Request('https://api.example.com/v1/users');

    // 发送请求
    const response = await session.fetch(request);
    console.info(`Response status: ${response.statusCode}`);

    session.close();
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Error code: ${err.code}, message: ${err.data}`);
  }
}

// 示例2：基于端口的动态DNS函数
async function testPortBasedDynamicDnsFunction(): Promise<void> {
  try {
    // 创建会话，配置基于端口返回IP的动态函数
    const session = rcp.createSession({
      requestConfiguration: {
        dns: {
          dnsRules: (host: string, port: number): rcp.IpAddress[] => {
            // HTTPS请求（port=443）使用特定IP
            if (host === 'example.com' && port === 443) {
              return ['192.168.1.100'];
            }

            // HTTP请求（port=80）使用其他IP
            if (host === 'example.com' && port === 80) {
              return ['192.168.2.100'];
            }

            // 其他情况使用系统DNS
            return [];
          }
        }
      }
    });

    // 创建HTTPS请求
    const httpsRequest = new rcp.Request('https://example.com/api/data');
    const httpsResponse = await session.fetch(httpsRequest);
    console.info(`HTTPS response status: ${httpsResponse.statusCode}`);

    // 创建HTTP请求
    const httpRequest = new rcp.Request('http://example.com/api/data');
    const httpResponse = await session.fetch(httpRequest);
    console.info(`HTTP response status: ${httpResponse.statusCode}`);

    session.close();
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Error code: ${err.code}, message: ${err.data}`);
  }
}

// 示例3：负载均衡动态DNS函数
async function testLoadBalancingDynamicDnsFunction(): Promise<void> {
  try {
    // 模拟负载均衡计数器
    let counter = 0;

    // 创建会话，配置负载均衡动态函数
    const session = rcp.createSession({
      requestConfiguration: {
        dns: {
          dnsRules: (host: string, port: number): rcp.IpAddress[] => {
            if (host === 'api.example.com') {
              // 轮询返回不同的IP地址实现负载均衡
              counter++;
              const ipIndex = counter % 3;

              const ipPool = [
                ['10.0.0.1'],  // 服务器1
                ['10.0.0.2'],  // 服务器2
                ['10.0.0.3']   // 服务器3
              ];

              console.info(`Load balancing: selected server ${ipIndex + 1}`);
              return ipPool[ipIndex];
            }

            return [];
          }
        }
      }
    });

    // 发送多个请求观察负载均衡效果
    const requests = Array(5).fill(null).map((_, i) => 
      new rcp.Request('https://api.example.com/v1/users')
    );

    for (const request of requests) {
      try {
        const response = await session.fetch(request);
        console.info(`Request succeeded: ${response.statusCode}`);
      } catch (error) {
        console.error('Request failed');
      }
    }

    session.close();
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Error code: ${err.code}, message: ${err.data}`);
  }
}

// 示例4：地理位置智能DNS函数
async function testGeoLocationBasedDynamicDnsFunction(): Promise<void> {
  try {
    // 模拟地理位置检测函数
    function getUserRegion(): string {
      // 实际应用中可以从系统获取用户地理位置
      return 'asia';  // 模拟亚洲地区用户
    }

    // 创建会话，配置地理位置智能DNS函数
    const session = rcp.createSession({
      requestConfiguration: {
        dns: {
          dnsRules: (host: string, port: number): rcp.IpAddress[] => {
            if (host === 'cdn.example.com') {
              const region = getUserRegion();

              // 根据用户地理位置返回最近的CDN节点IP
              switch (region) {
                case 'asia':
                  return ['10.0.1.1'];  // 亚洲CDN节点
                case 'europe':
                  return ['10.0.2.1'];  // 欧洲CDN节点
                case 'america':
                  return ['10.0.3.1'];  // 美洲CDN节点
                default:
                  return ['10.0.0.1'];  // 默认CDN节点
              }
            }

            return [];
          }
        }
      }
    });

    // 创建请求
    const request = new rcp.Request('https://cdn.example.com/assets/video.mp4');

    // 发送请求（自动选择地理位置最近的CDN节点）
    const response = await session.fetch(request);
    console.info(`Response status: ${response.statusCode}`);

    session.close();
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Error code: ${err.code}, message: ${err.data}`);
  }
}

// 示例5：动态DNS函数失败降级方案
async function testDynamicDnsFunctionFallback(): Promise<void> {
  try {
    const session = rcp.createSession();
    const request = new rcp.Request('https://unknown.example.com/api/data');

    // 配置动态DNS函数（无法解析该域名）
    request.configuration = {
      dns: {
        dnsRules: (host: string, port: number): rcp.IpAddress[] => {
          console.info(`DNS function called for: ${host}`);

          // 无法解析返回空数组
          return [];
        }
      }
    };

    // 发送请求（系统自动降级使用系统DNS）
    const response = await session.fetch(request);
    console.info(`Response status: ${response.statusCode}`);
    console.info('DNS function returned empty, system DNS used');

    session.close();
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Error code: ${err.code}, message: ${err.data}`);
  }
}

// 主函数：运行所有示例
async function main(): Promise<void> {
  console.info('=== 测试基础动态DNS函数 ===');
  await testBasicDynamicDnsFunction();

  console.info('=== 测试基于端口的动态DNS函数 ===');
  await testPortBasedDynamicDnsFunction();

  console.info('=== 测试负载均衡动态DNS函数 ===');
  await testLoadBalancingDynamicDnsFunction();

  console.info('=== 测试地理位置智能DNS函数 ===');
  await testGeoLocationBasedDynamicDnsFunction();

  console.info('=== 测试动态DNS函数降级方案 ===');
  await testDynamicDnsFunctionFallback();
}

export { main };