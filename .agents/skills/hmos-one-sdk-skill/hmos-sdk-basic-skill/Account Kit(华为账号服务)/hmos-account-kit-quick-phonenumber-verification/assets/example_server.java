import com.alibaba.fastjson2.JSONObject;
import org.apache.http.NameValuePair;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.message.BasicNameValuePair;
import org.apache.http.util.EntityUtils;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class QuickPhoneNumberServer {
    
    private static final String TOKEN_URL = "https://oauth-login.cloud.huawei.com/oauth2/v3/token";
    private static final String USER_INFO_URL = "https://account.cloud.huawei.com/rest.php?nsp_svc=GOpen.User.getInfo";
    
    private String clientId;
    private String clientSecret;
    
    public QuickPhoneNumberServer(String clientId, String clientSecret) {
        this.clientId = clientId;
        this.clientSecret = clientSecret;
    }
    
    public AccessTokenResult getAccessTokenByCode(String authorizationCode) throws IOException {
        CloseableHttpClient httpClient = HttpClients.createDefault();
        HttpPost httpPost = new HttpPost(TOKEN_URL);
        
        List<NameValuePair> params = new ArrayList<>();
        params.add(new BasicNameValuePair("grant_type", "authorization_code"));
        params.add(new BasicNameValuePair("code", authorizationCode));
        params.add(new BasicNameValuePair("client_id", clientId));
        params.add(new BasicNameValuePair("client_secret", clientSecret));
        params.add(new BasicNameValuePair("supportAlg", "PS256"));
        
        httpPost.setHeader("Content-Type", "application/x-www-form-urlencoded");
        httpPost.setEntity(new UrlEncodedFormEntity(params));
        
        String responseBody = EntityUtils.toString(httpClient.execute(httpPost).getEntity());
        JSONObject result = JSONObject.parseObject(responseBody);
        
        AccessTokenResult tokenResult = new AccessTokenResult();
        tokenResult.accessToken = result.getString("access_token");
        tokenResult.refreshToken = result.getString("refresh_token");
        tokenResult.expiresIn = result.getInteger("expires_in");
        tokenResult.idToken = result.getString("id_token");
        tokenResult.scope = result.getString("scope");
        tokenResult.tokenType = result.getString("token_type");
        
        httpClient.close();
        return tokenResult;
    }
    
    public PhoneNumberResult getUserPhoneNumber(String accessToken) throws IOException {
        CloseableHttpClient httpClient = HttpClients.createDefault();
        HttpPost httpPost = new HttpPost(USER_INFO_URL);
        
        List<NameValuePair> params = new ArrayList<>();
        params.add(new BasicNameValuePair("access_token", accessToken));
        
        httpPost.setHeader("Content-Type", "application/x-www-form-urlencoded");
        httpPost.setEntity(new UrlEncodedFormEntity(params));
        
        String responseBody = EntityUtils.toString(httpClient.execute(httpPost).getEntity());
        JSONObject result = JSONObject.parseObject(responseBody);
        
        PhoneNumberResult phoneResult = new PhoneNumberResult();
        phoneResult.openID = result.getString("openID");
        phoneResult.unionID = result.getString("unionID");
        phoneResult.mobileNumber = result.getString("mobileNumber");
        phoneResult.purePhoneNumber = result.getString("purePhoneNumber");
        phoneResult.phoneCountryCode = result.getString("phoneCountryCode");
        
        httpClient.close();
        return phoneResult;
    }
    
    public AccessTokenResult refreshAccessToken(String refreshToken) throws IOException {
        CloseableHttpClient httpClient = HttpClients.createDefault();
        HttpPost httpPost = new HttpPost(TOKEN_URL);
        
        List<NameValuePair> params = new ArrayList<>();
        params.add(new BasicNameValuePair("grant_type", "refresh_token"));
        params.add(new BasicNameValuePair("refresh_token", refreshToken));
        params.add(new BasicNameValuePair("client_id", clientId));
        params.add(new BasicNameValuePair("client_secret", clientSecret));
        
        httpPost.setHeader("Content-Type", "application/x-www-form-urlencoded");
        httpPost.setEntity(new UrlEncodedFormEntity(params));
        
        String responseBody = EntityUtils.toString(httpClient.execute(httpPost).getEntity());
        JSONObject result = JSONObject.parseObject(responseBody);
        
        AccessTokenResult tokenResult = new AccessTokenResult();
        tokenResult.accessToken = result.getString("access_token");
        tokenResult.refreshToken = result.getString("refresh_token");
        tokenResult.expiresIn = result.getInteger("expires_in");
        tokenResult.tokenType = result.getString("token_type");
        
        httpClient.close();
        return tokenResult;
    }
    
    public PhoneNumberResult getPhoneNumberByAuthCode(String authorizationCode) throws IOException {
        AccessTokenResult tokenResult = getAccessTokenByCode(authorizationCode);
        return getUserPhoneNumber(tokenResult.accessToken);
    }
    
    public static class AccessTokenResult {
        public String accessToken;
        public String refreshToken;
        public Integer expiresIn;
        public String idToken;
        public String scope;
        public String tokenType;
    }
    
    public static class PhoneNumberResult {
        public String openID;
        public String unionID;
        public String mobileNumber;
        public String purePhoneNumber;
        public String phoneCountryCode;
    }
    
    public static void main(String[] args) {
        String clientId = "<Your Client ID>";
        String clientSecret = "<Your Client Secret>";
        String authorizationCode = "<Authorization Code from Client>";
        
        QuickPhoneNumberServer server = new QuickPhoneNumberServer(clientId, clientSecret);
        
        try {
            PhoneNumberResult result = server.getPhoneNumberByAuthCode(authorizationCode);
            
            System.out.println("=== Phone Number Retrieval Result ===");
            System.out.println("OpenID: " + result.openID);
            System.out.println("UnionID: " + result.unionID);
            System.out.println("Mobile Number: " + result.mobileNumber);
            System.out.println("Pure Phone Number: " + result.purePhoneNumber);
            System.out.println("Phone Country Code: " + result.phoneCountryCode);
            
        } catch (IOException e) {
            System.err.println("Failed to get phone number: " + e.getMessage());
            e.printStackTrace();
        }
    }
}