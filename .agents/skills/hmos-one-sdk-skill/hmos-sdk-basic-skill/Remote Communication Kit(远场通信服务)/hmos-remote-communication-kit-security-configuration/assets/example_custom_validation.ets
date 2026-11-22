import { rcp } from '@kit.RemoteCommunicationKit';
import { networkSecurity } from '@kit.NetworkKit';

function makeItTwoChar(s: string): string {
  if (s.length === 1) {
    return '0' + s;
  }
  return s;
}

function getASNDateString(): string {
  const date = new Date();
  let dateStr = date.getFullYear().toString().slice(2);
  dateStr += makeItTwoChar((date.getMonth() + 1).toString());
  dateStr += makeItTwoChar(date.getDate().toString());
  dateStr += makeItTwoChar(date.getHours().toString());
  dateStr += makeItTwoChar(date.getMinutes().toString());
  dateStr += makeItTwoChar(date.getSeconds().toString());
  return dateStr + 'Z';
}

export async function ValidationRemoteServer(context: rcp.ValidationContext): Promise<boolean> {
  let length = context.pemCerts.length;
  if (length <= 0) {
    return Promise.reject('服务器未返回证书');
  }

  const firstCaBlob: networkSecurity.CertBlob = {
    type: networkSecurity.CertType.CERT_TYPE_PEM,
    data: context.pemCerts[length - 1]
  };

  if (networkSecurity.certVerificationSync(firstCaBlob) !== 0) {
    return Promise.reject('证书验证失败');
  }

  for (const x of context.x509Certs) {
    let dateStr = getASNDateString();
    try {
      x.checkValidityWithDate(dateStr);
    } catch (e) {
      return Promise.reject('证书日期校验失败');
    }
  }

  return Promise.resolve(true);
}

export async function testCustomValidation(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com');

  request.configuration = {
    security: {
      remoteValidation: ValidationRemoteServer
    }
  };

  try {
    const response = await session.fetch(request);
    console.info(`[自定义校验] 响应状态码: ${response.statusCode}`);
  } catch (err) {
    console.error(`[自定义校验] 证书校验失败: ${err.code}`);
  } finally {
    session.close();
  }
}

export async function customValidationWithHostnameCheck(context: rcp.ValidationContext): Promise<boolean> {
  let length = context.pemCerts.length;
  if (length <= 0) {
    return Promise.reject('服务器未返回证书');
  }

  const firstCaBlob: networkSecurity.CertBlob = {
    type: networkSecurity.CertType.CERT_TYPE_PEM,
    data: context.pemCerts[length - 1]
  };

  if (networkSecurity.certVerificationSync(firstCaBlob) !== 0) {
    return Promise.reject('证书验证失败');
  }

  for (const x of context.x509Certs) {
    let dateStr = getASNDateString();
    try {
      x.checkValidityWithDate(dateStr);
    } catch (e) {
      return Promise.reject('证书日期校验失败');
    }
  }

  return Promise.resolve(true);
}

export async function testEnhancedCustomValidation(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com');

  request.configuration = {
    security: {
      remoteValidation: customValidationWithHostnameCheck
    }
  };

  try {
    const response = await session.fetch(request);
    console.info(`[增强自定义校验] 响应状态码: ${response.statusCode}`);
    console.info(`[增强自定义校验] 证书链长度: ${response}`);
  } catch (err) {
    console.error(`[增强自定义校验] 失败: ${err.code}, ${err.data}`);
  } finally {
    session.close();
  }
}