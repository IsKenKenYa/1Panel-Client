import { rcp } from '@kit.RemoteCommunicationKit';

export async function testPemClientCertificate(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com');

  request.configuration = {
    security: {
      certificate: {
        filePath: '/data/storage/el1/bundle/entry/resources/resfile/cert.pem',
        type: 'PEM',
        key: '/data/storage/el1/bundle/entry/resources/resfile/cert.key',
        keyPassword: 'keyPassword'
      }
    }
  };

  try {
    const response = await session.fetch(request);
    console.info(`[PEM客户端证书] 响应状态码: ${response.statusCode}`);
  } catch (err) {
    console.error(`[PEM客户端证书] 证书校验失败: ${err.code}`);
  } finally {
    session.close();
  }
}

export async function testDerClientCertificate(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com');

  request.configuration = {
    security: {
      certificate: {
        filePath: '/data/storage/el1/bundle/entry/resources/resfile/cert.der',
        type: 'DER',
        key: '/data/storage/el1/bundle/entry/resources/resfile/cert.key',
        keyPassword: 'keyPassword'
      }
    }
  };

  try {
    const response = await session.fetch(request);
    console.info(`[DER客户端证书] 响应状态码: ${response.statusCode}`);
  } catch (err) {
    console.error(`[DER客户端证书] 证书校验失败: ${err.code}`);
  } finally {
    session.close();
  }
}

export async function testP12ClientCertificate(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com');

  request.configuration = {
    security: {
      certificate: {
        filePath: '/data/storage/el1/bundle/entry/resources/resfile/cert.p12',
        type: 'P12',
        keyPassword: '1234'
      }
    }
  };

  try {
    const response = await session.fetch(request);
    console.info(`[P12客户端证书] 响应状态码: ${response.statusCode}`);
  } catch (err) {
    console.error(`[P12客户端证书] 证书校验失败: ${err.code}`);
  } finally {
    session.close();
  }
}

export async function testContentBasedClientCertificate(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com');

  const CERT_CONTENT = '-----BEGIN CERTIFICATE-----\n...';
  const KEY_CONTENT = '-----BEGIN PRIVATE KEY-----\n...';

  request.configuration = {
    security: {
      certificate: {
        content: CERT_CONTENT,
        type: 'PEM',
        key: KEY_CONTENT,
        keyPassword: 'password'
      }
    }
  };

  try {
    const response = await session.fetch(request);
    console.info(`[内容客户端证书] 响应状态码: ${response.statusCode}`);
  } catch (err) {
    console.error(`[内容客户端证书] 证书校验失败: ${err.code}`);
  } finally {
    session.close();
  }
}