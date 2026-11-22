import com.alibaba.fastjson.JSONObject;
import org.apache.commons.codec.binary.Base64;
import org.bouncycastle.jce.provider.BouncyCastleProvider;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Objects;

/**
 * 基于华为服务账号生成JWT鉴权令牌示例
 * 
 * 本示例演示如何使用华为开发者联盟API Console创建的服务账号密钥文件，
 * 生成符合JWT规范的鉴权令牌，用于调用华为公开API。
 * 
 * 使用方法：
 * 1. 在华为开发者联盟API Console创建服务账号并下载密钥文件
 * 2. 将密钥文件路径传入generateJwtToken方法
 * 3. 获取生成的JWT令牌用于API调用
 * 
 * 依赖：
 * - fastjson: 1.2.83
 * - bcprov-jdk18on: 1.74
 * - commons-codec: 1.15
 * 
 * @author HarmonyOS Device Security Kit
 * @version 1.0
 */
public class JWTGenerateDemo {

    private static final String AUD = "https://oauth-login.cloud.huawei.com/oauth2/v3/token";
    private static final String ALG_PS256 = "PS256";
    private static final String DOT = ".";
    private static final int TOKEN_EXPIRY_SECONDS = 3600; // JWT有效期：1小时

    /**
     * 读取JSON格式的密钥文件
     * 
     * @param keyFilePath 密钥文件路径
     * @return JSON对象
     * @throws IOException 文件读取失败
     */
    private static JSONObject readJsonFile(String keyFilePath) throws IOException {
        File file = new File(keyFilePath);
        if (!file.exists()) {
            throw new IOException("密钥文件不存在：" + keyFilePath);
        }

        try (FileInputStream fis = new FileInputStream(file)) {
            byte[] data = new byte[(int) file.length()];
            int bytesRead = fis.read(data);
            if (bytesRead != data.length) {
                throw new IOException("文件读取不完整");
            }
            String jsonStr = new String(data, StandardCharsets.UTF_8);
            return JSONObject.parseObject(jsonStr);
        }
    }

    /**
     * 解析PKCS#8格式的私钥
     * 
     * @param privateKeyPEM PEM格式的私钥字符串（包含头尾标记）
     * @return PrivateKey对象
     * @throws NoSuchAlgorithmException 不支持的算法
     * @throws InvalidKeySpecException 私钥格式错误
     */
    private static PrivateKey getPrivateKey(String privateKeyPEM) 
            throws NoSuchAlgorithmException, InvalidKeySpecException {
        
        // 移除PEM格式的头尾标记和换行符
        String privateKeyContent = privateKeyPEM
                .replace("-----BEGIN PRIVATE KEY-----", "")
                .replace("-----END PRIVATE KEY-----", "")
                .replaceAll("\\s+", ""); // 移除所有空白字符

        // BASE64解码
        byte[] encoded = Base64.decodeBase64(privateKeyContent.getBytes(StandardCharsets.UTF_8));

        // 生成PrivateKey对象
        PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(encoded);
        KeyFactory keyFactory = KeyFactory.getInstance("RSA");
        return keyFactory.generatePrivate(keySpec);
    }

    /**
     * 生成JWT鉴权令牌
     * 
     * @param keyFilePath 服务账号密钥文件路径
     * @return JWT令牌字符串
     * @throws IOException 文件读取失败
     * @throws NoSuchAlgorithmException 不支持的算法
     * @throws InvalidKeySpecException 私钥格式错误
     * @throws InvalidKeyException 私钥无效
     * @throws SignatureException 签名生成失败
     */
    public static String generateJwtToken(String keyFilePath) 
            throws IOException, NoSuchAlgorithmException, InvalidKeySpecException, 
                   InvalidKeyException, SignatureException {
        
        // 步骤1：读取并验证密钥文件
        System.out.println("步骤1：读取密钥文件...");
        JSONObject keyFile = readJsonFile(keyFilePath);
        
        String keyId = keyFile.getString("key_id");
        String privateKeyPEM = keyFile.getString("private_key");
        String iss = keyFile.getString("sub_account");
        
        // 验证必需字段
        if (keyId == null || keyId.trim().isEmpty()) {
            throw new IllegalArgumentException("密钥文件缺少必需字段：key_id");
        }
        if (privateKeyPEM == null || privateKeyPEM.trim().isEmpty()) {
            throw new IllegalArgumentException("密钥文件缺少必需字段：private_key");
        }
        if (iss == null || iss.trim().isEmpty()) {
            throw new IllegalArgumentException("密钥文件缺少必需字段：sub_account");
        }
        
        System.out.println("  - key_id: " + keyId);
        System.out.println("  - sub_account: " + iss);

        // 步骤2：生成JWT Header
        System.out.println("\n步骤2：生成JWT Header...");
        JSONObject header = new JSONObject();
        header.put("alg", ALG_PS256);
        header.put("typ", "JWT");
        header.put("kid", keyId);
        
        byte[] encodeHeaderBytes = Base64.encodeBase64URLSafe(
                header.toString().getBytes(StandardCharsets.UTF_8));
        String encodeHeader = new String(encodeHeaderBytes, StandardCharsets.UTF_8);
        System.out.println("  - Header: " + header.toString());
        System.out.println("  - Base64URL编码后: " + encodeHeader);

        // 步骤3：生成JWT Payload
        System.out.println("\n步骤3：生成JWT Payload...");
        long iat = System.currentTimeMillis() / 1000;  // 当前UTC时间戳（秒）
        long exp = iat + TOKEN_EXPIRY_SECONDS;         // 过期时间
        
        JSONObject payload = new JSONObject();
        payload.put("aud", AUD);
        payload.put("iss", iss);
        payload.put("exp", exp);
        payload.put("iat", iat);
        
        byte[] encodePayloadBytes = Base64.encodeBase64URLSafe(
                payload.toString().getBytes(StandardCharsets.UTF_8));
        String encodePayload = new String(encodePayloadBytes, StandardCharsets.UTF_8);
        System.out.println("  - Payload: " + payload.toString());
        System.out.println("  - Base64URL编码后: " + encodePayload);
        System.out.println("  - 令牌有效期: " + TOKEN_EXPIRY_SECONDS + "秒");
        System.out.println("  - 过期时间: " + new java.util.Date(exp * 1000));

        // 步骤4：生成JWT Signature
        System.out.println("\n步骤4：生成JWT Signature...");
        String jwtHeaderAndPayload = encodeHeader + DOT + encodePayload;
        
        PrivateKey privateKey = getPrivateKey(privateKeyPEM);
        Signature signatureInstance = Signature.getInstance(
                "SHA256withRSA/PSS", 
                new BouncyCastleProvider());
        signatureInstance.initSign(privateKey);
        signatureInstance.update(jwtHeaderAndPayload.getBytes(StandardCharsets.UTF_8));
        
        String signature = new String(
                Objects.requireNonNull(Base64.encodeBase64URLSafe(signatureInstance.sign())), 
                StandardCharsets.UTF_8);
        System.out.println("  - Signature: " + signature);

        // 步骤5：拼接生成完整JWT Token
        System.out.println("\n步骤5：拼接生成完整JWT Token...");
        String jwtToken = jwtHeaderAndPayload + DOT + signature;
        
        System.out.println("\n✓ JWT令牌生成成功！");
        System.out.println("  - 令牌长度: " + jwtToken.length() + "字符");
        System.out.println("  - 令牌预览: " + jwtToken.substring(0, Math.min(50, jwtToken.length())) + "...");
        
        return jwtToken;
    }

    /**
     * 主方法：演示JWT令牌生成过程
     * 
     * @param args 命令行参数（第一个参数为密钥文件路径）
     */
    public static void main(String[] args) {
        if (args.length < 1) {
            System.err.println("使用方法：java JWTGenerateDemo <密钥文件路径>");
            System.err.println("示例：java JWTGenerateDemo service-account.json");
            System.exit(1);
        }

        String keyFilePath = args[0];
        System.out.println("========================================");
        System.out.println("华为服务账号JWT令牌生成工具");
        System.out.println("========================================");
        System.out.println("密钥文件路径：" + keyFilePath);
        System.out.println();

        try {
            // 生成JWT令牌
            String jwtToken = generateJwtToken(keyFilePath);
            
            System.out.println("\n========================================");
            System.out.println("生成的JWT令牌：");
            System.out.println("========================================");
            System.out.println(jwtToken);
            System.out.println("\n提示：可以使用 https://jwt.io 解析此令牌");
            
        } catch (IOException e) {
            System.err.println("\n✗ 错误：密钥文件读取失败");
            System.err.println("  原因：" + e.getMessage());
            System.err.println("  解决方法：");
            System.err.println("    1. 检查文件路径是否正确");
            System.err.println("    2. 检查文件是否存在");
            System.err.println("    3. 检查文件权限");
            System.exit(2);
            
        } catch (IllegalArgumentException e) {
            System.err.println("\n✗ 错误：密钥文件格式不正确");
            System.err.println("  原因：" + e.getMessage());
            System.err.println("  解决方法：");
            System.err.println("    1. 确认密钥文件包含必需字段：key_id, private_key, sub_account");
            System.err.println("    2. 从华为开发者联盟API Console重新下载密钥文件");
            System.exit(3);
            
        } catch (NoSuchAlgorithmException e) {
            System.err.println("\n✗ 错误：系统不支持RSA算法");
            System.err.println("  原因：" + e.getMessage());
            System.err.println("  解决方法：检查JVM环境配置");
            System.exit(4);
            
        } catch (InvalidKeySpecException e) {
            System.err.println("\n✗ 错误：私钥格式不正确");
            System.err.println("  原因：" + e.getMessage());
            System.err.println("  解决方法：");
            System.err.println("    1. 确认私钥为PKCS#8格式");
            System.err.println("    2. 检查私钥内容是否完整");
            System.err.println("    3. 从华为开发者联盟API Console重新下载密钥文件");
            System.exit(5);
            
        } catch (InvalidKeyException e) {
            System.err.println("\n✗ 错误：私钥无效或已损坏");
            System.err.println("  原因：" + e.getMessage());
            System.err.println("  解决方法：从华为开发者联盟API Console重新下载密钥文件");
            System.exit(6);
            
        } catch (SignatureException e) {
            System.err.println("\n✗ 错误：签名生成失败");
            System.err.println("  原因：" + e.getMessage());
            System.err.println("  解决方法：");
            System.err.println("    1. 检查BouncyCastle库是否正确安装");
            System.err.println("    2. 确认使用PS256算法");
            System.exit(7);
            
        } catch (Exception e) {
            System.err.println("\n✗ 错误：未知错误");
            System.err.println("  原因：" + e.getMessage());
            e.printStackTrace();
            System.exit(99);
        }
    }
}