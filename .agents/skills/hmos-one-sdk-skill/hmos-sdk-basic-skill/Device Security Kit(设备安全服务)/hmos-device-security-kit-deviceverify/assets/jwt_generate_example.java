import com.alibaba.fastjson.JSONObject;
import org.apache.commons.codec.binary.Base64;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Objects;

public class JWTGenerateExample {
    private static final String PRIVATE_KEY = "MIIJQgIBADANBgkqhkiG9w0BAQEFAASCCSwwggkoAgEAAoICAQCKw6kJKtCh7qmMvp1u1dI27z2TKZrPOzHbQaXO/Eez0AWZ2EN+ouF496R3pfo7fQXC1XOT/YTbVC4DNZwWSMA54fu3/AOCY9Zzyi46OK*****";
    private static final String ISS = "114023345";
    private static final String KID = "9a59dddd6ec64182be017603cd55b104";
    private static final String AUD = "https://oauth-login.cloud.huawei.com/oauth2/v3/token";
    private static final String ALG_PS256 = "PS256";
    private static final String DOT = ".";
    
    static {
        Security.addProvider(new BouncyCastleProvider());
    }
    
    private static PrivateKey getPrivateKey(String key) throws NoSuchAlgorithmException, InvalidKeySpecException {
        PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(decodeBase64(key));
        KeyFactory keyFactory = KeyFactory.getInstance("RSA");
        return keyFactory.generatePrivate(keySpec);
    }
    
    private static byte[] decodeBase64(String Base64Str) {
        return Base64.decodeBase64(Base64Str.getBytes(StandardCharsets.UTF_8));
    }
    
    public String createJwt() throws NoSuchAlgorithmException, InvalidKeySpecException, InvalidKeyException, SignatureException {
        long iat = System.currentTimeMillis() / 1000;
        long exp = iat + 3600;
        
        JSONObject header = new JSONObject();
        header.put("alg", ALG_PS256);
        header.put("kid", KID);
        header.put("typ", "JWT");
        
        JSONObject payload = new JSONObject();
        payload.put("aud", AUD);
        payload.put("iss", ISS);
        payload.put("exp", exp);
        payload.put("iat", iat);
        
        byte[] encodeHeaderBytes = Base64.encodeBase64URLSafe(header.toString().getBytes(StandardCharsets.UTF_8));
        byte[] encodePayloadBytes = Base64.encodeBase64URLSafe(payload.toString().getBytes(StandardCharsets.UTF_8));
        
        String encodeHeader = new String(encodeHeaderBytes, StandardCharsets.UTF_8);
        String encodePayload = new String(encodePayloadBytes, StandardCharsets.UTF_8);
        
        String jwtHeaderAndPayload = encodeHeader + DOT + encodePayload;
        
        Signature signatureInstance = Signature.getInstance("SHA256withRSA/PSS", new BouncyCastleProvider());
        signatureInstance.initSign(getPrivateKey(PRIVATE_KEY));
        signatureInstance.update(jwtHeaderAndPayload.getBytes(StandardCharsets.UTF_8));
        
        String signature = new String(
            Objects.requireNonNull(Base64.encodeBase64URLSafe(signatureInstance.sign())),
            StandardCharsets.UTF_8
        );
        
        return jwtHeaderAndPayload + DOT + signature;
    }
    
    public static void main(String[] args) {
        try {
            JWTGenerateExample jwtGenerator = new JWTGenerateExample();
            String jwtToken = jwtGenerator.createJwt();
            
            System.out.println("Generated JWT Token:");
            System.out.println(jwtToken);
            
            String authorization = "Bearer " + jwtToken;
            System.out.println("\nAuthorization Header:");
            System.out.println(authorization);
        } catch (Exception e) {
            System.err.println("Error generating JWT token: " + e.getMessage());
            e.printStackTrace();
        }
    }
}