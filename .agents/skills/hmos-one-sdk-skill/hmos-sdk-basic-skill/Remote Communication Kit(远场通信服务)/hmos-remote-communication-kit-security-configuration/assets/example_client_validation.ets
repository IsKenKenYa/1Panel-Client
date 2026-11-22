import { rcp } from '@kit.RemoteCommunicationKit';
import { util } from '@kit.ArkTS';

export async function testSystemCertificate(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com');

  request.configuration = {
    security: {
      remoteValidation: 'system'
    }
  };

  try {
    const response = await session.fetch(request);
    console.info(`[系统证书] 响应状态码: ${response.statusCode}`);
    console.info(`[系统证书] 响应内容: ${JSON.stringify(response.toString())}`);
  } catch (err) {
    console.error(`[系统证书] 请求失败: 错误码 ${err.code}, 错误信息 ${err.data}`);
  } finally {
    session.close();
  }
}

export async function testSkipCertificate(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com');

  request.configuration = {
    security: {
      remoteValidation: 'skip'
    }
  };

  try {
    const response = await session.fetch(request);
    console.info(`[跳过校验] 响应状态码: ${response.statusCode}`);
  } catch (err) {
    console.error(`[跳过校验] 请求失败: ${err.code}`);
  } finally {
    session.close();
  }
}

export async function testPemContentCertificate(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com');

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

  request.configuration = {
    security: {
      remoteValidation: {
        content: PEM_CA
      }
    }
  };

  try {
    const response = await session.fetch(request);
    console.info(`[PEM内容] 响应状态码: ${response.statusCode}`);
  } catch (err) {
    console.error(`[PEM内容] 证书校验失败: ${err.code}`);
  } finally {
    session.close();
  }
}

export async function testBinaryContentCertificate(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com');

  const PEM_CA = '-----BEGIN CERTIFICATE-----\n...';
  const buffer = new ArrayBuffer(PEM_CA.length);
  util.TextEncoder.create('utf-8').encodeIntoUint8Array(PEM_CA, new Uint8Array(buffer));

  request.configuration = {
    security: {
      remoteValidation: {
        content: buffer
      }
    }
  };

  try {
    const response = await session.fetch(request);
    console.info(`[二进制内容] 响应状态码: ${response.statusCode}`);
  } catch (err) {
    console.error(`[二进制内容] 请求失败: ${err.code}`);
  } finally {
    session.close();
  }
}

export async function testFilePathCertificate(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com');

  request.configuration = {
    security: {
      remoteValidation: {
        filePath: '/data/storage/el1/bundle/entry/resources/resfile/dd8e9d41.0'
      }
    }
  };

  try {
    const response = await session.fetch(request);
    console.info(`[文件路径] 响应状态码: ${response.statusCode}`);
  } catch (err) {
    console.error(`[文件路径] 证书文件读取失败: ${err.code}`);
  } finally {
    session.close();
  }
}

export async function testFolderPathCertificate(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com');

  request.configuration = {
    security: {
      remoteValidation: {
        folderPath: '/data/storage/el1/bundle/entry/resources/resfile/'
      }
    }
  };

  try {
    const response = await session.fetch(request);
    console.info(`[文件目录] 响应状态码: ${response.statusCode}`);
  } catch (err) {
    console.error(`[文件目录] 证书目录读取失败: ${err.code}`);
  } finally {
    session.close();
  }
}