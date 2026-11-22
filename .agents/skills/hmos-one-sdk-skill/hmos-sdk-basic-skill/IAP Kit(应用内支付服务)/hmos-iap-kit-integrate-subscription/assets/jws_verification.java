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

public class JWSChecker {
    private static final String CA_CERT_FILE_PATH = "/path/to/cer/RootCaG2Ecdsa.cer";
    private static final String HEADER_PARAM_X5C = "x5c";
    private static final int X5C_CHAIN_LENGTH = 3;
    private static final String HEADER_PARAM_ALG_ES256 = "ES256";
    private static final String LEAF_CERT_OID = "1.3.6.1.4.1.2011.2.415.1.1";
    
    public static String checkAndDecodeJWS(String jwsStr) throws Exception {
        if (jwsStr == null || jwsStr.isEmpty()) {
            throw new Exception("jwsStr was null");
        }
        
        DecodedJWT decodedJWT = JWT.decode(jwsStr);
        if (!HEADER_PARAM_ALG_ES256.equals(decodedJWT.getAlgorithm())) {
            throw new Exception("alg must be ES256");
        }
        
        String[] x5cChain = decodedJWT.getHeaderClaim(HEADER_PARAM_X5C).asArray(String.class);
        if (x5cChain == null) {
            throw new Exception("x5c chain was null");
        }
        
        PublicKey publicKey = verifyChainAndGetPubKey(x5cChain);
        JWTVerifier jwtVerifier = JWT.require(Algorithm.ECDSA256((ECPublicKey) publicKey)).build();
        jwtVerifier.verify(decodedJWT);
        
        return new String(Base64.getUrlDecoder().decode(decodedJWT.getPayload()), StandardCharsets.UTF_8);
    }
    
    private static PublicKey verifyChainAndGetPubKey(String[] certificates) throws Exception {
        CertificateFactory certificateFactory = CertificateFactory.getInstance("X.509");
        List<Certificate> certificateList = new LinkedList<>();
        
        for (String certificate : certificates) {
            InputStream inputStream = new ByteArrayInputStream(Base64.getDecoder().decode(certificate));
            certificateList.add(certificateFactory.generateCertificate(inputStream));
        }
        
        if (certificateList.size() != X5C_CHAIN_LENGTH) {
            throw new Exception("invalid cert chain length");
        }
        
        PKIXCertPathValidatorResult certPathValidatorResult;
        try {
            PKIXParameters parameters = loadRootCAAndPKIX();
            CertPathValidator validator = CertPathValidator.getInstance("PKIX");
            parameters.setRevocationEnabled(false);
            CertPath certPath = certificateFactory.generateCertPath(certificateList.subList(0, X5C_CHAIN_LENGTH - 1));
            certPathValidatorResult = (PKIXCertPathValidatorResult) validator.validate(certPath, parameters);
        } catch (Exception e) {
            throw new Exception(e);
        }
        
        Certificate iapCert = certificateList.get(0);
        if (!(iapCert instanceof X509Certificate)) {
            throw new Exception("leaf certificate must be X509 format");
        }
        
        X509Certificate x509Certificate = (X509Certificate) iapCert;
        if (x509Certificate.getNonCriticalExtensionOIDs() == null ||
            !x509Certificate.getNonCriticalExtensionOIDs().contains(LEAF_CERT_OID)) {
            throw new CertPathValidatorException("OID not found");
        }
        
        return certPathValidatorResult.getPublicKey();
    }
    
    private static PKIXParameters loadRootCAAndPKIX() throws Exception {
        PKIXParameters parameters;
        try (InputStream fis = Files.newInputStream(Paths.get(CA_CERT_FILE_PATH))) {
            CertificateFactory certificateFactory = CertificateFactory.getInstance("X.509");
            Certificate trustCert = certificateFactory.generateCertificate(fis);
            if (!(trustCert instanceof X509Certificate)) {
                throw new RuntimeException("root certificate must be X509 format");
            }
            Set<TrustAnchor> trustAnchors = new HashSet<>();
            trustAnchors.add(new TrustAnchor((X509Certificate) trustCert, null));
            parameters = new PKIXParameters(trustAnchors);
        }
        return parameters;
    }
}