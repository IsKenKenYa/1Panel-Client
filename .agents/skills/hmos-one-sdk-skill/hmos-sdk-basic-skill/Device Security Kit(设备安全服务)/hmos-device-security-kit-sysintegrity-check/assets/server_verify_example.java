import java.security.*;
import java.security.cert.*;
import java.util.*;
import org.json.JSONObject;
import org.json.JSONArray;
import java.nio.charset.StandardCharsets;

public class SysIntegrityVerifier {
    
    private static final String ROOT_CA_URL = 
        "https://h5hosting-drcn.dbankcdn.cn/cch5/crl/pki_CA_RootG2Ca/RootG2Ca.cer";
    private static final String EXPECTED_DOMAIN = "sysintegrity.platform.hicloud.com";
    
    public static class VerifyResult {
        public boolean success;
        public String errorMessage;
        public JSONObject payload;
        public boolean basicIntegrity;
        public List<String> details;
        public String nonce;
        public long timestamp;
        public String bundleName;
        public String appId;
    }
    
    public VerifyResult verifyJWS(String jws, String expectedNonce) {
        VerifyResult result = new VerifyResult();
        
        try {
            String[] parts = jws.split("\\.");
            if (parts.length != 3) {
                result.success = false;
                result.errorMessage = "Invalid JWS format";
                return result;
            }
            
            String headerJson = decodeBase64(parts[0]);
            String payloadJson = decodeBase64(parts[1]);
            String signature = parts[2];
            
            JSONObject header = new JSONObject(headerJson);
            JSONObject payload = new JSONObject(payloadJson);
            
            JSONArray x5cArray = header.getJSONArray("x5c");
            if (x5cArray.length() != 3) {
                result.success = false;
                result.errorMessage = "Invalid certificate chain length";
                return result;
            }
            
            X509Certificate leafCert = parseCertificate(x5cArray.getString(0));
            X509Certificate intermediateCert = parseCertificate(x5cArray.getString(1));
            X509Certificate rootCert = parseCertificate(x5cArray.getString(2));
            
            if (!verifyCertificateChain(leafCert, intermediateCert, rootCert)) {
                result.success = false;
                result.errorMessage = "Certificate chain verification failed";
                return result;
            }
            
            if (!verifyDomain(leafCert, EXPECTED_DOMAIN)) {
                result.success = false;
                result.errorMessage = "Certificate domain mismatch";
                return result;
            }
            
            String alg = header.getString("alg");
            if (!verifySignature(parts[0] + "." + parts[1], signature, leafCert, alg)) {
                result.success = false;
                result.errorMessage = "Signature verification failed";
                return result;
            }
            
            String receivedNonce = payload.getString("nonce");
            if (!receivedNonce.equals(expectedNonce)) {
                result.success = false;
                result.errorMessage = "Nonce mismatch - possible replay attack";
                return result;
            }
            
            result.payload = payload;
            result.basicIntegrity = payload.getBoolean("basicIntegrity");
            result.nonce = receivedNonce;
            result.timestamp = payload.getLong("timestamp");
            result.bundleName = payload.optString("hapBundleName", "");
            result.appId = payload.optString("appId", "");
            
            if (payload.has("detail") && !result.basicIntegrity) {
                JSONArray detailArray = payload.getJSONArray("detail");
                result.details = new ArrayList<>();
                for (int i = 0; i < detailArray.length(); i++) {
                    result.details.add(detailArray.getString(i));
                }
            }
            
            result.success = true;
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = "Verification error: " + e.getMessage();
        }
        
        return result;
    }
    
    private String decodeBase64(String base64) {
        String standardBase64 = base64.replace('-', '+').replace('_', '/');
        while (standardBase64.length() % 4 != 0) {
            standardBase64 += "=";
        }
        byte[] decoded = Base64.getDecoder().decode(standardBase64);
        return new String(decoded, StandardCharsets.UTF_8);
    }
    
    private X509Certificate parseCertificate(String certBase64) 
            throws CertificateException {
        CertificateFactory cf = CertificateFactory.getInstance("X.509");
        byte[] certBytes = Base64.getDecoder().decode(certBase64);
        return (X509Certificate) cf.generateCertificate(
            new java.io.ByteArrayInputStream(certBytes));
    }
    
    private boolean verifyCertificateChain(
            X509Certificate leaf, 
            X509Certificate intermediate, 
            X509Certificate root) {
        try {
            intermediate.verify(root.getPublicKey());
            leaf.verify(intermediate.getPublicKey());
            return true;
        } catch (Exception e) {
            return false;
        }
    }
    
    private boolean verifyDomain(X509Certificate cert, String expectedDomain) {
        try {
            String cn = cert.getSubjectX500Principal().getName();
            return cn.contains(expectedDomain);
        } catch (Exception e) {
            return false;
        }
    }
    
    private boolean verifySignature(
            String data, 
            String signatureBase64, 
            X509Certificate cert, 
            String alg) {
        try {
            byte[] signatureBytes = Base64.getDecoder().decode(signatureBase64);
            Signature sig = Signature.getInstance("SHA256withECDSA");
            sig.initVerify(cert.getPublicKey());
            sig.update(data.getBytes(StandardCharsets.UTF_8));
            return sig.verify(signatureBytes);
        } catch (Exception e) {
            return false;
        }
    }
    
    public static String generateNonce() {
        byte[] nonceBytes = new byte[32];
        new SecureRandom().nextBytes(nonceBytes);
        return Base64.getEncoder().encodeToString(nonceBytes)
            .replace('+', '-').replace('/', '_').replace("=", "");
    }
    
    public static void main(String[] args) {
        SysIntegrityVerifier verifier = new SysIntegrityVerifier();
        
        String nonce = generateNonce();
        System.out.println("Generated nonce: " + nonce);
        
        String mockJws = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXUyIsIng1YyI6WyIiLCIiLCIiXX0." +
                         "eyJoYXBCdW5kbGVOYW1lIjoidGVzdCIsImJhc2ljSW50ZWdyaXR5Ijp0cnVlLCJu" +
                         "b25jZSI6IiIsInRpbWVzdGFtcCI6MTYwNDA5ODU3NzMyN30.signature";
        
        VerifyResult result = verifier.verifyJWS(mockJws, nonce);
        
        if (result.success) {
            System.out.println("Verification successful!");
            System.out.println("Basic integrity: " + result.basicIntegrity);
            System.out.println("Nonce: " + result.nonce);
            System.out.println("Timestamp: " + result.timestamp);
            
            if (result.details != null && !result.details.isEmpty()) {
                System.out.println("Risk details: " + result.details);
            }
        } else {
            System.out.println("Verification failed: " + result.errorMessage);
        }
    }
}