import { rcp } from '@kit.RemoteCommunicationKit';

export async function testSingleCertificatePinning(): Promise<void> {
  const session = rcp.createSession();
  const TEST_URL = 'https://example.com';
  const request = new rcp.Request(TEST_URL);

  const PUBLIC_KEY_SHA256_HASH = 'iMMpIJdSf5VlClHaxZReyhaLxLsmZMMNAiA2pMR8/M4=';

  request.configuration = {
    security: {
      certificatePinning: [
        {
          kind: 'public-key',
          publicKeyHash: PUBLIC_KEY_SHA256_HASH,
          hashAlgorithm: 'SHA-256'
        }
      ]
    }
  };

  try {
    const response = await session.fetch(request);
    console.info(`[单证书锁定] 验证成功,状态码: ${response.statusCode}`);
  } catch (e) {
    console.error(`[单证书锁定] 验证失败: ${JSON.stringify(e)}`);
  } finally {
    session.close();
  }
}

export async function testMultipleCertificatePinning(): Promise<void> {
  const session = rcp.createSession();
  const TEST_URL = 'https://example.com';
  const request = new rcp.Request(TEST_URL);

  const PUBLIC_KEY_SHA256_HASH_LIST = [
    'iMMpIJdSf5VlClHaxZReyhaLxLsmZMMNAiA2pMR8/M4=',
    'qBRjZmOmkSNJL0p70zek7odSIzqs/muR4Jk9xYyCP+E='
  ];

  request.configuration = {
    security: {
      certificatePinning: PUBLIC_KEY_SHA256_HASH_LIST.map(hash => ({
        kind: 'public-key',
        publicKeyHash: hash,
        hashAlgorithm: 'SHA-256'
      }))
    }
  };

  try {
    const response = await session.fetch(request);
    console.info(`[多证书锁定] 验证成功,状态码: ${response.statusCode}`);
  } catch (e) {
    console.error(`[多证书锁定] 验证失败: ${JSON.stringify(e)}`);
  } finally {
    session.close();
  }
}

export async function testCertificatePinningWithBackup(): Promise<void> {
  const session = rcp.createSession();
  const TEST_URL = 'https://example.com';
  const request = new rcp.Request(TEST_URL);

  const PRIMARY_HASH = 'iMMpIJdSf5VlClHaxZReyhaLxLsmZMMNAiA2pMR8/M4=';
  const BACKUP_HASH = 'qBRjZmOmkSNJL0p70zek7odSIzqs/muR4Jk9xYyCP+E=';

  request.configuration = {
    security: {
      remoteValidation: 'system',
      certificatePinning: [
        {
          kind: 'public-key',
          publicKeyHash: PRIMARY_HASH,
          hashAlgorithm: 'SHA-256'
        },
        {
          kind: 'public-key',
          publicKeyHash: BACKUP_HASH,
          hashAlgorithm: 'SHA-256'
        }
      ]
    }
  };

  try {
    const response = await session.fetch(request);
    console.info(`[证书锁定+系统校验] 验证成功,状态码: ${response.statusCode}`);
  } catch (e) {
    console.error(`[证书锁定+系统校验] 验证失败: ${JSON.stringify(e)}`);
  } finally {
    session.close();
  }
}