import com.alibaba.fastjson2.JSONObject;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

public class GetQuickLoginMobilePhoneByCodeDemo {
    
    public static void main(String[] args) throws IOException {
        String url = "https://account-api.cloud.huawei.com/oauth2/v6/quickLogin/getPhoneNumber";
        String authorizationCode = "<Authorization Code>";
        String clientId = "<Client ID>";
        String clientSecret = "<Client Secret>";
        
        JSONObject result = getQuickLoginMobile(url, authorizationCode, clientId, clientSecret);
        
        if (result.containsKey("resultCode")) {
            int resultCode = result.getInteger("resultCode");
            String resultDesc = result.getString("resultDesc");
            System.out.println("Error: resultCode=" + resultCode + ", resultDesc=" + resultDesc);
            handleError(resultCode);
            return;
        }
        
        String openId = result.getString("openId");
        String unionId = result.getString("unionId");
        String phoneNumber = result.getString("phoneNumber");
        Integer phoneNumberValid = result.getInteger("phoneNumberValid");
        String purePhoneNumber = result.getString("purePhoneNumber");
        String phoneCountryCode = result.getString("phoneCountryCode");
        
        System.out.println("Success:");
        System.out.println("OpenID: " + openId);
        System.out.println("UnionID: " + unionId);
        System.out.println("PhoneNumber: " + phoneNumber);
        System.out.println("PhoneNumberValid: " + phoneNumberValid);
        System.out.println("PurePhoneNumber: " + purePhoneNumber);
        System.out.println("PhoneCountryCode: " + phoneCountryCode);
        
        if (phoneNumberValid == 0) {
            System.out.println("Warning: Phone number needs verification (phoneNumberValid=0)");
        } else if (phoneNumberValid == 1) {
            System.out.println("Phone number is valid and can be used directly (phoneNumberValid=1)");
        }
        
        completeUserLogin(phoneNumber, unionId, openId);
    }
    
    private static JSONObject getQuickLoginMobile(String url, String authorizationCode,
            String clientId, String clientSecret) throws IOException {
        
        CloseableHttpClient httpClient = HttpClients.createDefault();
        HttpPost httpPost = new HttpPost(url);
        
        Map<String, Object> reqBody = new HashMap<>();
        reqBody.put("code", authorizationCode);
        reqBody.put("clientId", clientId);
        reqBody.put("clientSecret", clientSecret);
        
        httpPost.setHeader("Content-Type", "application/json");
        httpPost.setEntity(new StringEntity(JSONObject.toJSONString(reqBody)));
        
        try {
            org.apache.http.HttpResponse response = httpClient.execute(httpPost);
            String responseStr = EntityUtils.toString(response.getEntity());
            return JSONObject.parseObject(responseStr);
        } finally {
            httpClient.close();
        }
    }
    
    private static void handleError(int resultCode) {
        switch (resultCode) {
            case 60010002:
                System.out.println("Solution: Check request parameters");
                break;
            case 60010012:
                System.out.println("Solution: Code parameter is incorrect or tampered");
                break;
            case 60010013:
                System.out.println("Solution: Check Client Secret parameter");
                break;
            case 60180003:
                System.out.println("Solution: Check clientId consistency");
                break;
            case 60180004:
                System.out.println("Solution: Code expired, get new code from user");
                break;
            case 60180005:
                System.out.println("Solution: Code already used, get new code");
                break;
            case 60180006:
                System.out.println("Solution: Code authorization canceled, get new code");
                break;
            case 60180007:
                System.out.println("Solution: Complete quick login permission application");
                break;
            case 60180008:
                System.out.println("Solution: User has no phone number, show other login methods");
                break;
            case 60180009:
                System.out.println("Solution: Ensure server deployed in China mainland");
                break;
            case 60010001:
                System.out.println("Solution: Internal error, retry or submit ticket");
                break;
            default:
                System.out.println("Solution: Unknown error, submit ticket");
        }
    }
    
    private static void completeUserLogin(String phoneNumber, String unionId, String openId) {
        System.out.println("Completing user login process...");
        System.out.println("Associating phone number: " + phoneNumber);
        System.out.println("Associating UnionID: " + unionId);
        System.out.println("Associating OpenID: " + openId);
        
        boolean userExists = checkUserExists(unionId);
        
        if (userExists) {
            System.out.println("User already exists, performing login...");
            createSession(unionId);
        } else {
            System.out.println("New user, performing registration...");
            createUser(phoneNumber, unionId, openId);
        }
        
        System.out.println("User login completed successfully!");
    }
    
    private static boolean checkUserExists(String unionId) {
        return false;
    }
    
    private static void createSession(String unionId) {
        System.out.println("Session created for UnionID: " + unionId);
    }
    
    private static void createUser(String phoneNumber, String unionId, String openId) {
        System.out.println("New user created with phone: " + phoneNumber);
    }
}