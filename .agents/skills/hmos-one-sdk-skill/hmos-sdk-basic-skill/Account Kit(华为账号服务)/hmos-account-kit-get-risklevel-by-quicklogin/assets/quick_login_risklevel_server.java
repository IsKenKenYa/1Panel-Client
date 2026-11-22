import com.alibaba.fastjson2.JSONArray;
import com.alibaba.fastjson2.JSONObject;
import org.apache.http.NameValuePair;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.message.BasicNameValuePair;
import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Random;

public class QuickLoginRiskLevelServerDemo {
    
    private static final String TOKEN_URL = "https://oauth-login.cloud.huawei.com/oauth2/v3/token";
    private static final String RISK_LEVEL_URL = "https://account.cloud.huawei.com/user/getuserrisklevel";
    
    public static class RiskLevelResult {
        private Integer riskLevel;
        private JSONArray riskTag;
        private String riskLevelMeaning;
        private String suggestedAction;
        private Integer errCode;
        private String errMsg;
        
        public Integer getRiskLevel() {
            return riskLevel;
        }
        
        public void setRiskLevel(Integer riskLevel) {
            this.riskLevel = riskLevel;
        }
        
        public JSONArray getRiskTag() {
            return riskTag;
        }
        
        public void setRiskTag(JSONArray riskTag) {
            this.riskTag = riskTag;
        }
        
        public String getRiskLevelMeaning() {
            return riskLevelMeaning;
        }
        
        public void setRiskLevelMeaning(String riskLevelMeaning) {
            this.riskLevelMeaning = riskLevelMeaning;
        }
        
        public String getSuggestedAction() {
            return suggestedAction;
        }
        
        public void setSuggestedAction(String suggestedAction) {
            this.suggestedAction = suggestedAction;
        }
        
        public Integer getErrCode() {
            return errCode;
        }
        
        public void setErrCode(Integer errCode) {
            this.errCode = errCode;
        }
        
        public String getErrMsg() {
            return errMsg;
        }
        
        public void setErrMsg(String errMsg) {
            this.errMsg = errMsg;
        }
        
        public boolean isSuccess() {
            return errCode != null && errCode == 0;
        }
    }
    
    public static class TokenResult {
        private String accessToken;
        private String refreshToken;
        private Integer expiresIn;
        private String idToken;
        private String scope;
        private String tokenType;
        private Integer errCode;
        private String errMsg;
        
        public String getAccessToken() {
            return accessToken;
        }
        
        public void setAccessToken(String accessToken) {
            this.accessToken = accessToken;
        }
        
        public String getRefreshToken() {
            return refreshToken;
        }
        
        public void setRefreshToken(String refreshToken) {
            this.refreshToken = refreshToken;
        }
        
        public Integer getExpiresIn() {
            return expiresIn;
        }
        
        public void setExpiresIn(Integer expiresIn) {
            this.expiresIn = expiresIn;
        }
        
        public String getIdToken() {
            return idToken;
        }
        
        public void setIdToken(String idToken) {
            this.idToken = idToken;
        }
        
        public String getScope() {
            return scope;
        }
        
        public void setScope(String scope) {
            this.scope = scope;
        }
        
        public String getTokenType() {
            return tokenType;
        }
        
        public void setTokenType(String tokenType) {
            this.tokenType = tokenType;
        }
        
        public Integer getErrCode() {
            return errCode;
        }
        
        public void setErrCode(Integer errCode) {
            this.errCode = errCode;
        }
        
        public String getErrMsg() {
            return errMsg;
        }
        
        public void setErrMsg(String errMsg) {
            this.errMsg = errMsg;
        }
        
        public boolean isSuccess() {
            return accessToken != null && !accessToken.isEmpty();
        }
    }
    
    public static TokenResult getAccessToken(String code, String clientId, String clientSecret) throws IOException {
        HttpPost httpPost = new HttpPost(TOKEN_URL);
        List<NameValuePair> request = new ArrayList<>();
        request.add(new BasicNameValuePair("code", code));
        request.add(new BasicNameValuePair("client_secret", clientSecret));
        request.add(new BasicNameValuePair("client_id", clientId));
        request.add(new BasicNameValuePair("grant_type", "authorization_code"));
        
        httpPost.setHeader("Content-Type", "application/x-www-form-urlencoded");
        httpPost.setEntity(new UrlEncodedFormEntity(request));
        
        JSONObject result = CallUtils.toJsonObject(CallUtils.remoteCallOAuth(httpPost));
        
        TokenResult tokenResult = new TokenResult();
        if (result.containsKey("access_token")) {
            tokenResult.setAccessToken(result.getString("access_token"));
            tokenResult.setRefreshToken(result.getString("refresh_token"));
            tokenResult.setExpiresIn(result.getInteger("expires_in"));
            tokenResult.setIdToken(result.getString("id_token"));
            tokenResult.setScope(result.getString("scope"));
            tokenResult.setTokenType(result.getString("token_type"));
        } else {
            tokenResult.setErrCode(result.getInteger("error"));
            tokenResult.setErrMsg(result.getString("error_description"));
        }
        
        return tokenResult;
    }
    
    public static TokenResult refreshAccessToken(String refreshToken, String clientId, String clientSecret) throws IOException {
        HttpPost httpPost = new HttpPost(TOKEN_URL);
        List<NameValuePair> request = new ArrayList<>();
        request.add(new BasicNameValuePair("refresh_token", refreshToken));
        request.add(new BasicNameValuePair("client_secret", clientSecret));
        request.add(new BasicNameValuePair("client_id", clientId));
        request.add(new BasicNameValuePair("grant_type", "refresh_token"));
        
        httpPost.setHeader("Content-Type", "application/x-www-form-urlencoded");
        httpPost.setEntity(new UrlEncodedFormEntity(request));
        
        JSONObject result = CallUtils.toJsonObject(CallUtils.remoteCallOAuth(httpPost));
        
        TokenResult tokenResult = new TokenResult();
        if (result.containsKey("access_token")) {
            tokenResult.setAccessToken(result.getString("access_token"));
            tokenResult.setRefreshToken(result.getString("refresh_token"));
            tokenResult.setExpiresIn(result.getInteger("expires_in"));
            tokenResult.setScope(result.getString("scope"));
            tokenResult.setTokenType(result.getString("token_type"));
        } else {
            tokenResult.setErrCode(result.getInteger("error"));
            tokenResult.setErrMsg(result.getString("error_description"));
        }
        
        return tokenResult;
    }
    
    public static RiskLevelResult getUserRiskLevel(String accessToken, String clientID, String scene) throws IOException {
        String transactionID = generateTransactionID();
        
        HttpPost httpPost = new HttpPost(RISK_LEVEL_URL + "?" + "clientID=" + clientID + "&transactionID=" + transactionID);
        Map<String, String> reqBody = new HashMap<>();
        reqBody.put("accessToken", accessToken);
        reqBody.put("scene", scene);
        
        httpPost.setHeader("Content-Type", "application/json;charset=utf-8");
        httpPost.setEntity(CallUtils.wrapJsonEntity(reqBody));
        
        JSONObject result = CallUtils.toJsonObject(CallUtils.remoteCall(httpPost, (CloseableHttpResponse response, String rawBody) -> {
            int statusCode = response.getStatusLine().getStatusCode();
            if (statusCode != 200) {
                return new IOException("HTTP status code: " + statusCode + ", response: " + rawBody);
            }
            
            JSONObject errorResponseBody = CallUtils.toJsonObject(rawBody);
            Integer errCode = errorResponseBody.getInteger("errCode");
            if (Objects.nonNull(errCode) && errCode != 0) {
                return new IOException("Business error code: " + errCode + ", response: " + rawBody);
            }
            return null;
        }));
        
        RiskLevelResult riskLevelResult = new RiskLevelResult();
        riskLevelResult.setErrCode(result.getInteger("errCode"));
        riskLevelResult.setErrMsg(result.getString("errMsg"));
        
        if (riskLevelResult.isSuccess()) {
            riskLevelResult.setRiskLevel(result.getInteger("riskLevel"));
            riskLevelResult.setRiskTag(result.getJSONArray("riskTag"));
            riskLevelResult.setRiskLevelMeaning(getRiskLevelMeaning(riskLevelResult.getRiskLevel()));
            riskLevelResult.setSuggestedAction(getSuggestedAction(riskLevelResult.getRiskLevel()));
        }
        
        return riskLevelResult;
    }
    
    public static RiskLevelResult getRiskLevelByAuthCode(String authCode, String clientId, String clientSecret, String scene) throws IOException {
        TokenResult tokenResult = getAccessToken(authCode, clientId, clientSecret);
        
        if (!tokenResult.isSuccess()) {
            RiskLevelResult riskLevelResult = new RiskLevelResult();
            riskLevelResult.setErrCode(tokenResult.getErrCode());
            riskLevelResult.setErrMsg("Failed to get access token: " + tokenResult.getErrMsg());
            return riskLevelResult;
        }
        
        return getUserRiskLevel(tokenResult.getAccessToken(), clientId, scene);
    }
    
    private static String generateTransactionID() {
        LocalDateTime now = LocalDateTime.now();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");
        String timestamp = now.format(formatter);
        
        Random random = new Random();
        StringBuilder randomPart = new StringBuilder();
        for (int i = 0; i < 15; i++) {
            randomPart.append(random.nextInt(10));
        }
        
        return timestamp + randomPart.toString();
    }
    
    private static String getRiskLevelMeaning(Integer riskLevel) {
        if (riskLevel == null) {
            return "未知风险等级";
        }
        
        switch (riskLevel) {
            case 0:
                return "未发现显著风险";
            case 1:
                return "低风险";
            case 2:
                return "中风险";
            case 3:
                return "高风险";
            case 4:
                return "风险未知";
            default:
                return "未知风险等级";
        }
    }
    
    private static String getSuggestedAction(Integer riskLevel) {
        if (riskLevel == null) {
            return "无法提供建议";
        }
        
        switch (riskLevel) {
            case 0:
                return "建议确认无风险后放通";
            case 1:
                return "建议进行简单验证(如验证码、短信等),或人工审核";
            case 2:
                return "建议根据业务场景采取一定措施规避伤害。例如,营销活动可降低高等级奖励的概率、登录注册要求二次验证等";
            case 3:
                return "建议业务逻辑直接拦截。例如,红包类活动返回不中奖或最小额红包、登录/注册操作要求二次验证";
            case 4:
                return "建议结合账号历史行为及业务场景做出最终决策";
            default:
                return "无法提供建议";
        }
    }
    
    public static void main(String[] args) throws IOException {
        String authCode = "<Authorization Code>";
        String clientId = "<Client ID>";
        String clientSecret = "<Client Secret>";
        String scene = "registration";
        
        RiskLevelResult result = getRiskLevelByAuthCode(authCode, clientId, clientSecret, scene);
        
        if (result.isSuccess()) {
            System.out.println("=== 用户风险等级查询成功 ===");
            System.out.println("风险等级: " + result.getRiskLevel() + " (" + result.getRiskLevelMeaning() + ")");
            System.out.println("风险标签: " + result.getRiskTag());
            System.out.println("建议操作: " + result.getSuggestedAction());
        } else {
            System.out.println("=== 用户风险等级查询失败 ===");
            System.out.println("错误码: " + result.getErrCode());
            System.out.println("错误描述: " + result.getErrMsg());
            
            if (result.getErrCode() == 6) {
                System.out.println("建议: Access Token无效或已过期,请使用Refresh Token刷新或重新授权");
            } else if (result.getErrCode() == 403) {
                System.out.println("建议: 无权访问,请前往AGC申请riskLevel scope权限");
            }
        }
    }
}