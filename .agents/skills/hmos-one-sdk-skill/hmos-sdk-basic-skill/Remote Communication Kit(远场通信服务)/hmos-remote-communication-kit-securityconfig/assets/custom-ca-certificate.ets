import { rcp } from '@kit.RemoteCommunicationKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

const PEM_CA = '-----BEGIN CERTIFICATE-----\n' +
  'MIICPzCCAcWgAwIBAgIQBVVWvPJepDU1w6QP1atFcjAKBggqhkjOPQQDAzBhMQswCQYDVQQGEwJV\n' +
  'UzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSAwHgYD\n' +
  'VQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBHMzAeFw0xMzA4MDExMjAwMDBaFw0zODAxMTUxMjAw\n' +
  'MDBaMGExCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5k\n' +
  'aWdpY2VydC5jb20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IEczMHYwEAYHKoZIzj0C\n' +
  'AQYFK4EEACIDYgAE3afZu4q4C/sLfyHS8L6+c/MzXRq8NOrexpu80JX28MzQC7phW1FGfp4tn+6O\n' +
  'YwwX7Adw9c+ELkCDnOg/QW07rdOkFFk2eJ0DQ+4QE2xy3q6Ip6FrtUPOZ9wj/wMco+I+o0IwQDAP\n' +
  'BgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIBhjAdBgNVHQ4EFgQUs9tIpPmhxdiuNkHMEWNp\n' +
  'Yim8S8YwCgYIKoZIzj0EAwMDaAAwZQIxAK288mw/EkrRLTnDCgmXc/SINoyIJ7vmiI1Qhadj+Z4y\n' +
  '3maTD/HMsQmP3Wyr+mt/oAIwOWZbwmSNuJ5Q3KjVSaLtx9zRSX8XAbjIho9OjIgrqJqpisXRAL34\n' +
  'VOKa5Vt8sycX\n' +
  '-----END CERTIFICATE-----';

/**
 * 使用字符串指定 CA 证书内容
 */
async function testStringCACertificate(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com'); // 请替换为实际的 HTTPS 网址
  
  // 配置自定义 CA 证书内容（字符串格式）
  request.configuration = {
    security: {
      remoteValidation: {
        content: PEM_CA
      }
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info(`Response statusCode: ${JSON.stringify(response.statusCode)}`);
    console.info(`Response: ${JSON.stringify(response.toString())}`);
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Request failed: error code is ${error.code}, error data is ${error.data}`);
    throw error;
  } finally {
    session.close();
  }
}

/**
 * 使用二进制指定 CA 证书内容
 */
async function testBinaryCACertificate(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com'); // 请替换为实际的 HTTPS 网址
  
  // 将 PEM 证书转换为 ArrayBuffer
  const buffer = new ArrayBuffer(PEM_CA.length);
  util.TextEncoder.create('utf-8').encodeIntoUint8Array(PEM_CA, new Uint8Array(buffer));
  
  // 配置自定义 CA 证书内容（ArrayBuffer 格式）
  request.configuration = {
    security: {
      remoteValidation: {
        content: buffer
      }
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info(`Response statusCode: ${JSON.stringify(response.statusCode)}`);
    console.info(`Response: ${JSON.stringify(response.toString())}`);
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Request failed: error code is ${error.code}, error data is ${error.data}`);
    throw error;
  } finally {
    session.close();
  }
}

/**
 * 使用文件指定 CA 证书内容
 */
async function testFileCACertificate(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com'); // 请替换为实际的 HTTPS 网址
  
  // 配置自定义 CA 证书文件路径
  // 注意：路径为沙箱路径，请替换为实际的证书文件路径
  request.configuration = {
    security: {
      remoteValidation: {
        filePath: '/data/storage/el1/bundle/entry/resources/resfile/dd8e9d41.0'
      }
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info(`Response statusCode: ${JSON.stringify(response.statusCode)}`);
    console.info(`Response: ${JSON.stringify(response.toString())}`);
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Request failed: error code is ${error.code}, error data is ${error.data}`);
    throw error;
  } finally {
    session.close();
  }
}

/**
 * 使用文件目录指定 CA 证书
 */
async function testFolderCACertificate(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com'); // 请替换为实际的 HTTPS 网址
  
  // 配置自定义 CA 证书目录路径
  // 目录中的所有证书文件都会被加载用于校验
  request.configuration = {
    security: {
      remoteValidation: {
        folderPath: '/data/storage/el1/bundle/entry/resources/resfile/'
      }
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info(`Response statusCode: ${JSON.stringify(response.statusCode)}`);
    console.info(`Response: ${JSON.stringify(response.toString())}`);
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Request failed: error code is ${error.code}, error data is ${error.data}`);
    throw error;
  } finally {
    session.close();
  }
}

// 主函数
async function main(): Promise<void> {
  try {
    console.info('=== Testing string CA certificate ===');
    await testStringCACertificate();
    
    console.info('=== Testing binary CA certificate ===');
    await testBinaryCACertificate();
    
    console.info('=== Testing file CA certificate ===');
    await testFileCACertificate();
    
    console.info('=== Testing folder CA certificate ===');
    await testFolderCACertificate();
  } catch (error) {
    console.error('Test failed:', error);
  }
}

main();