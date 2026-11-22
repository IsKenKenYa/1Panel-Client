import com.alibaba.fastjson2.JSONObject;
import org.apache.http.NameValuePair;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.message.BasicNameValuePair;
import org.apache.http.util.EntityUtils;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.client.methods.CloseableHttpResponse;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class SilentLoginServerDemo {
    
    private static final String OAUTH_TOKEN_URL = "https://oauth-login.cloud.huawei.com/oauth2/v3/token";
    private static final String TOKEN_INFO_URL = "https://oauth-api.cloud.huawei.com/rest.php?nsp_fmt=JSON&nsp_svc=huawei.oauth2.user.getTokenInfo";
    
    public static class TokenResult {
        public String accessToken;
        public String refreshToken;
        public String idToken;
        public Integer expiresIn;
        public String scope;
        public String tokenType;
    }
    
    public static class TokenInfoResult {
        public String unionID;
        public String openID;
        public String clientID;
        public Integer expiresIn;
        public String scope;
        public String projectID;
        public Integer type;
    }
    
    public static TokenResult getTokenByAuthorizationCode(String code, String clientID, String clientSecret) throws IOException {
        CloseableHttpClient httpClient = HttpClients.createDefault();
        HttpPost httpPost = new HttpPost(OAUTH_TOKEN_URL);
        
        List<NameValuePair> requestParams = new ArrayList<>();
        requestParams.add(new BasicNameValuePair("grant_type", "authorization_code"));
        requestParams.add(new BasicNameValuePair("code", code));
        requestParams.add(new BasicNameValuePair("client_id", clientID));
        requestParams.add(new BasicNameValuePair("client_secret", clientSecret));
        requestParams.add(new BasicNameValuePair("supportAlg", "PS256"));
        
        httpPost.setHeader("Content-Type", "application/x-www-form-urlencoded");
        httpPost.setEntity(new UrlEncodedFormEntity(requestParams));
        
        CloseableHttpResponse response = httpClient.execute(httpPost);
        String responseBody = EntityUtils.toString(response.getEntity());
        JSONObject result = JSONObject.parseObject(responseBody);
        
        if (response.getStatusLine().getStatusCode() != 200) {
            System.err.println("Token request failed: " + responseBody);
            return null;
        }
        
        TokenResult tokenResult = new TokenResult();
        tokenResult.accessToken = result.getString("access_token");
        tokenResult.refreshToken = result.getString("refresh_token");
        tokenResult.idToken = result.getString("id_token");
        tokenResult.expiresIn = result.getInteger("expires_in");
        tokenResult.scope = result.getString("scope");
        tokenResult.tokenType = result.getString("token_type");
        
        System.out.println("Access Token obtained successfully.");
        System.out.println("Expires in: " + tokenResult.expiresIn + " seconds");
        System.out.println("Scope: " + tokenResult.scope);
        
        httpClient.close();
        return tokenResult;
    }
    
    public static TokenInfoResult getTokenInfo(String accessToken) throws IOException {
        CloseableHttpClient httpClient = HttpClients.createDefault();
        HttpPost httpPost = new HttpPost(TOKEN_INFO_URL);
        
        List<NameValuePair> requestParams = new ArrayList<>();
        requestParams.add(new BasicNameValuePair("access_token", accessToken));
        requestParams.add(new BasicNameValuePair("open_id", "OPENID"));
        
        httpPost.setHeader("Content-Type", "application/x-www-form-urlencoded");
        httpPost.setEntity(new UrlEncodedFormEntity(requestParams));
        
        CloseableHttpResponse response = httpClient.execute(httpPost);
        String responseBody = EntityUtils.toString(response.getEntity());
        JSONObject result = JSONObject.parseObject(responseBody);
        
        String nspStatus = response.getFirstHeader("NSP_STATUS") != null ? 
            response.getFirstHeader("NSP_STATUS").getValue() : null;
        
        if (nspStatus != null) {
            System.err.println("Token info request failed. NSP_STATUS: " + nspStatus);
            System.err.println("Error: " + result.getString("error"));
            return null;
        }
        
        TokenInfoResult tokenInfo = new TokenInfoResult();
        tokenInfo.unionID = result.getString("union_id");
        tokenInfo.openID = result.getString("open_id");
        tokenInfo.clientID = result.getString("client_id");
        tokenInfo.expiresIn = result.getInteger("expire_in");
        tokenInfo.scope = result.getString("scope");
        tokenInfo.projectID = result.getString("project_id");
        tokenInfo.type = result.getInteger("type");
        
        System.out.println("Token info obtained successfully.");
        System.out.println("UnionID: " + tokenInfo.unionID);
        System.out.println("OpenID: " + tokenInfo.openID);
        System.out.println("Type: " + tokenInfo.type);
        
        httpClient.close();
        return tokenInfo;
    }
    
    public static String processSilentLogin(String authorizationCode, String clientID, String clientSecret) {
        try {
            System.out.println("Processing silent login with authorization code...");
            
            TokenResult tokenResult = getTokenByAuthorizationCode(authorizationCode, clientID, clientSecret);
            if (tokenResult == null) {
                System.err.println("Failed to get token by authorization code.");
                return null;
            }
            
            TokenInfoResult tokenInfo = getTokenInfo(tokenResult.accessToken);
            if (tokenInfo == null) {
                System.err.println("Failed to get token info.");
                return null;
            }
            
            System.out.println("Silent login processing completed.");
            System.out.println("User UnionID: " + tokenInfo.unionID);
            
            return tokenInfo.unionID;
        } catch (IOException e) {
            System.err.println("Silent login processing error: " + e.getMessage());
            return null;
        }
    }
    
    public static void main(String[] args) {
        String authorizationCode = "<Authorization Code from Client>";
        String clientID = "<Your Client ID>";
        String clientSecret = "<Your Client Secret>";
        
        String unionID = processSilentLogin(authorizationCode, clientID, clientSecret);
        
        if (unionID != null) {
            System.out.println("Silent login successful! UnionID: " + unionID);
        } else {
            System.out.println("Silent login failed.");
        }
    }
}