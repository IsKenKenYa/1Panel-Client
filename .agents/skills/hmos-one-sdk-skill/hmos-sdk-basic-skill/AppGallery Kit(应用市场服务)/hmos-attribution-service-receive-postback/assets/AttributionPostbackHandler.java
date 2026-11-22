import org.apache.commons.codec.binary.Base64;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.security.spec.X509EncodedKeySpec;
import java.util.ArrayList;
import java.util.List;

public class AttributionPostbackHandler {
    
    private static final String PUBLIC_KEY = "MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA0IgrEtIR1kVF/ImKIo3/5AxEFZzL156jLn2CilqGQmFByiMlpa2G0dotCK1mj9bdhDJbUPd3Plx1zVX9WoW/L/mg25+ng0iPlcItqhUuTIVi+0N50BHlVKPFWG/vYxCkR1ABU44zHyg2XAmqs2L6nUA9Hjbmwn5WX9JUWFF3RF4ja6GJRDkq0HFQ6ouM8Vpm3ZnnRTCuEzOpUcG+FMYAa9M9coRMMM3w0M/IgbYL4n86tQ6ybicaeadSwJIzXExLL0bSf1tYZ7CWvdK0V2ftLWC7Wmho64/g/AjqXc5d2nq88Cn+Vm48jLW1gibI1sPLjFhcfgRg0EOHD/FeUHLxhGeLc4KZ7hrcaW+IuVaTpHxbxJ9WiIokf6blQSEyPHx4w95IdGYNe/BGFhYaf3AhCe6b62e//0JdaYPKNDUKOpTf60vAhqQeibx4iaRZh8dEAU1m9lD0aR6+0trNCzdsC0iPCRLCXcFJXN2/ZJRug39xuJoSEkCxUsJdcoYknbRxAgMBAAE=";
    private static final String RSA_ALGORITHM = "RSA";
    private static final String SHA256WITHRSA_PSS_ALGORITHM = "SHA256WithRSA/PSS";
    private static final long TIMESTAMP_THRESHOLD = 300000;
    
    public boolean verifySignature(AttributionPostbackRequest request) 
            throws NoSuchAlgorithmException, InvalidKeySpecException, 
                   InvalidKeyException, SignatureException {
        
        String content = buildSignatureContent(request);
        
        byte[] plainContent = content.getBytes(StandardCharsets.UTF_8);
        byte[] signContent = Base64.decodeBase64(
            request.getSignature().getBytes(StandardCharsets.UTF_8)
        );
        
        Security.addProvider(new BouncyCastleProvider());
        PublicKey publicKey = getPublicKey(PUBLIC_KEY);
        Signature signature = Signature.getInstance(SHA256WITHRSA_PSS_ALGORITHM);
        signature.initVerify(publicKey);
        signature.update(plainContent);
        
        return signature.verify(signContent);
    }
    
    public void validateTimestamp(long timestamp) throws AttributionException {
        long currentTime = System.currentTimeMillis();
        long timeDiff = Math.abs(currentTime - timestamp);
        
        if (timeDiff > TIMESTAMP_THRESHOLD) {
            throw new AttributionException("Timestamp expired or invalid");
        }
    }
    
    public void validateRequiredFields(AttributionPostbackRequest request) 
            throws AttributionException {
        if (request.getNonce() == null || request.getNonce().isEmpty()) {
            throw new AttributionException("Missing required field: nonce");
        }
        if (request.getTimestamp() == 0) {
            throw new AttributionException("Missing required field: timestamp");
        }
        if (request.getSignature() == null || request.getSignature().isEmpty()) {
            throw new AttributionException("Missing required field: signature");
        }
        if (request.getTransactionId() == null || request.getTransactionId().isEmpty()) {
            throw new AttributionException("Missing required field: transaction_id");
        }
    }
    
    private String buildSignatureContent(AttributionPostbackRequest request) {
        List<String> fields = new ArrayList<>();
        
        if (request.getAdTechId() != null && !request.getAdTechId().isEmpty()) {
            fields.add(request.getAdTechId());
        }
        if (request.getCampaignId() != null && !request.getCampaignId().isEmpty()) {
            fields.add(request.getCampaignId());
        }
        if (request.getSourceId() != null && !request.getSourceId().isEmpty()) {
            fields.add(request.getSourceId());
        }
        if (request.getDestinationId() != null && !request.getDestinationId().isEmpty()) {
            fields.add(request.getDestinationId());
        }
        if (request.getTriggerData() != null) {
            fields.add(String.valueOf(request.getTriggerData()));
        }
        fields.add(request.getNonce());
        fields.add(String.valueOf(request.getTimestamp()));
        
        return String.join("\u2063", fields);
    }
    
    private PublicKey getPublicKey(String key) 
            throws NoSuchAlgorithmException, InvalidKeySpecException {
        byte[] keyBytes = Base64.decodeBase64(key.getBytes(StandardCharsets.UTF_8));
        X509EncodedKeySpec keySpec = new X509EncodedKeySpec(keyBytes);
        KeyFactory keyFactory = KeyFactory.getInstance(RSA_ALGORITHM);
        return keyFactory.generatePublic(keySpec);
    }
}