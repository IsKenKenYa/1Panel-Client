import com.auth0.jwt.JWT;
import com.auth0.jwt.JWTVerifier;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.interfaces.DecodedJWT;
import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.security.PublicKey;
import java.security.cert.CertPath;
import java.security.cert.CertPathValidator;
import java.security.cert.CertPathValidatorException;
import java.security.cert.Certificate;
import java.security.cert.CertificateFactory;
import java.security.cert.PKIXCertPathValidatorResult;
import java.security.cert.PKIXParameters;
import java.security.cert.TrustAnchor;
import java.security.cert.X509Certificate;
import java.security.interfaces.ECPublicKey;
import java.util.Base64;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Set;

export class JWSUtil {
  private static readonly CA_CERT_FILE_PATH: string = '/path/to/cer/RootCaG2Ecdsa.cer';
  private static readonly HEADER_PARAM_X5C: string = 'x5c';
  private static readonly X5C_CHAIN_LENGTH: number = 3;
  private static readonly HEADER_PARAM_ALG_ES256: string = 'ES256';
  private static readonly LEAF_CERT_OID: string = '1.3.6.1.4.1.2011.2.415.1.1';

  public static decodeJwsObj(jwsStr: string): string {
    if (!jwsStr || jwsStr.length === 0) {
      throw new Error('jwsStr was null or empty');
    }

    try {
      const decodedJWT = JWT.decode(jwsStr);
      
      if (decodedJWT.getHeaderClaim(HEADER_PARAM_ALG_ES256) !== HEADER_PARAM_ALG_ES256) {
        throw new Error('Algorithm must be ES256');
      }

      const x5cChain = decodedJWT.getHeaderClaim(HEADER_PARAM_X5C).asArray(string);
      if (!x5cChain || x5cChain.length !== X5C_CHAIN_LENGTH) {
        throw new Error('Invalid x5c certificate chain');
      }

      const publicKey = this.verifyChainAndGetPubKey(x5cChain);
      
      const jwtVerifier = JWTVerifier.require(Algorithm.ECDSA256(publicKey as ECPublicKey)).build();
      jwtVerifier.verify(decodedJWT);

      const payload = Base64.getUrlDecoder().decode(decodedJWT.getPayload());
      return new TextDecoder('utf-8').decode(payload);
    } catch (err) {
      console.error('JWS decode and verify failed:', err);
      throw err;
    }
  }

  private static verifyChainAndGetPubKey(certificates: string[]): PublicKey {
    const certificateFactory = CertificateFactory.getInstance('X.509');
    const certificateList: Certificate[] = [];

    for (const cert of certificates) {
      const certBytes = Base64.getDecoder().decode(cert);
      const inputStream = new ByteArrayInputStream(certBytes);
      certificateList.push(certificateFactory.generateCertificate(inputStream));
    }

    if (certificateList.length !== X5C_CHAIN_LENGTH) {
      throw new Error('Invalid certificate chain length');
    }

    try {
      const parameters = this.loadRootCAAndPKIX();
      const validator = CertPathValidator.getInstance('PKIX');
      parameters.setRevocationEnabled(false);

      const certPath = certificateFactory.generateCertPath(
        certificateList.slice(0, X5C_CHAIN_LENGTH - 1)
      );

      const certPathValidatorResult = validator.validate(certPath, parameters) as PKIXCertPathValidatorResult;

      const iapCert = certificateList[0];
      if (!(iapCert instanceof X509Certificate)) {
        throw new Error('Leaf certificate must be X509 format');
      }

      const x509Certificate = iapCert as X509Certificate;
      const oidSet = x509Certificate.getNonCriticalExtensionOIDs();
      if (!oidSet || !oidSet.contains(LEAF_CERT_OID)) {
        throw new CertPathValidatorException('Required OID not found in certificate');
      }

      return certPathValidatorResult.getPublicKey();
    } catch (err) {
      console.error('Certificate chain verification failed:', err);
      throw err;
    }
  }

  private static loadRootCAAndPKIX(): PKIXParameters {
    try {
      const certPath = Paths.get(CA_CERT_FILE_PATH);
      const fis = Files.newInputStream(certPath);
      const certificateFactory = CertificateFactory.getInstance('X.509');
      const trustCert = certificateFactory.generateCertificate(fis);

      if (!(trustCert instanceof X509Certificate)) {
        throw new Error('Root certificate must be X509 format');
      }

      const trustAnchors = new HashSet<TrustAnchor>();
      trustAnchors.add(new TrustAnchor(trustCert as X509Certificate, null));

      return new PKIXParameters(trustAnchors);
    } catch (err) {
      console.error('Failed to load root CA certificate:', err);
      throw err;
    }
  }

  public static verifyPurchaseData(purchaseData: string): boolean {
    try {
      const payload = this.decodeJwsObj(purchaseData);
      const data = JSON.parse(payload);
      
      if (!data.purchaseOrderId || !data.purchaseToken) {
        return false;
      }

      return true;
    } catch (err) {
      console.error('Purchase data verification failed:', err);
      return false;
    }
  }

  public static verifySubscriptionStatus(jwsSubscriptionStatus: string): SubGroupStatusPayload | null {
    try {
      const payload = this.decodeJwsObj(jwsSubscriptionStatus);
      return JSON.parse(payload) as SubGroupStatusPayload;
    } catch (err) {
      console.error('Subscription status verification failed:', err);
      return null;
    }
  }
}

interface SubGroupStatusPayload {
  environment: string;
  applicationId: string;
  packageName: string;
  subGroupId: string;
  lastSubscriptionStatus?: SubscriptionStatus;
  historySubscriptionStatusList?: SubscriptionStatus[];
}

interface SubscriptionStatus {
  subGroupGenerationId: string;
  subscriptionId: string;
  purchaseToken: string;
  status: string;
  expiresTime: number;
  lastPurchaseOrder?: PurchaseOrderPayload;
}

interface PurchaseOrderPayload {
  purchaseOrderId: string;
  purchaseToken: string;
  productId: string;
  productType: string;
  finishStatus?: string;
}