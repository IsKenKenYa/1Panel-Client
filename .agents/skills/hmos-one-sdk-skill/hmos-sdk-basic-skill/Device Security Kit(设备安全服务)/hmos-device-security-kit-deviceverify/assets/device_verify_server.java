import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import com.alibaba.fastjson.JSONObject;

public class DeviceVerifyServer {
    private static final String CHECK_TOKEN_URL = 
        "https://connect-api.cloud.huawei.com/api/rms/v1/deviceVerify/checkDeviceToken";
    private static final String GET_STATUS_URL = 
        "https://connect-api.cloud.huawei.com/api/rms/v1/deviceVerify/getDeviceStatus";
    private static final String SET_STATUS_URL = 
        "https://connect-api.cloud.huawei.com/api/rms/v1/deviceVerify/setDeviceStatus";
    private static final String DEL_STATUS_URL = 
        "https://connect-api.cloud.huawei.com/api/rms/v1/deviceVerify/delDeviceStatus";
    
    private String authorization;
    private String bundleName;
    
    public DeviceVerifyServer(String authorization, String bundleName) {
        this.authorization = authorization;
        this.bundleName = bundleName;
    }
    
    public boolean checkDeviceToken(String deviceToken) throws IOException {
        URL url = new URL(CHECK_TOKEN_URL);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        
        setRequestHeader(conn);
        
        JSONObject data = new JSONObject();
        data.put("deviceToken", deviceToken);
        data.put("timestamp", System.currentTimeMillis());
        
        JSONObject requestBody = new JSONObject();
        requestBody.put("data", data);
        
        try (OutputStream os = conn.getOutputStream()) {
            os.write(requestBody.toJSONString().getBytes("utf-8"));
        }
        
        int responseCode = conn.getResponseCode();
        if (responseCode == 200) {
            String response = readResponse(conn.getInputStream());
            JSONObject result = JSONObject.parseObject(response);
            String errorCodes = result.getString("errorCodes");
            return "OK".equals(errorCodes);
        }
        
        return false;
    }
    
    public DeviceStatusResult getDeviceStatus(String deviceToken, int mode) throws IOException {
        URL url = new URL(GET_STATUS_URL);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        
        setRequestHeader(conn);
        
        JSONObject data = new JSONObject();
        data.put("mode", mode);
        data.put("deviceToken", deviceToken);
        data.put("timestamp", System.currentTimeMillis());
        
        JSONObject requestBody = new JSONObject();
        requestBody.put("data", data);
        
        try (OutputStream os = conn.getOutputStream()) {
            os.write(requestBody.toJSONString().getBytes("utf-8"));
        }
        
        int responseCode = conn.getResponseCode();
        InputStream stream = responseCode >= 200 && responseCode < 300 
            ? conn.getInputStream() 
            : conn.getErrorStream();
        
        String response = readResponse(stream);
        JSONObject result = JSONObject.parseObject(response);
        
        DeviceStatusResult statusResult = new DeviceStatusResult();
        statusResult.errorCode = result.getString("errorCodes");
        
        if ("OK".equals(statusResult.errorCode)) {
            statusResult.bundleName = result.getString("bundleName");
            statusResult.bit0 = result.getBoolean("bit0");
            statusResult.bit1 = result.getBoolean("bit1");
            statusResult.lastUpdateTime = result.getLong("lastUpdateTime");
        }
        
        return statusResult;
    }
    
    public boolean setDeviceStatus(String deviceToken, int mode, 
                                   boolean bit0, boolean bit1) throws IOException {
        URL url = new URL(SET_STATUS_URL);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        
        setRequestHeader(conn);
        
        JSONObject data = new JSONObject();
        data.put("mode", mode);
        data.put("deviceToken", deviceToken);
        data.put("timestamp", System.currentTimeMillis());
        data.put("bit0", bit0);
        data.put("bit1", bit1);
        
        JSONObject requestBody = new JSONObject();
        requestBody.put("data", data);
        
        try (OutputStream os = conn.getOutputStream()) {
            os.write(requestBody.toJSONString().getBytes("utf-8"));
        }
        
        int responseCode = conn.getResponseCode();
        if (responseCode == 200) {
            String response = readResponse(conn.getInputStream());
            JSONObject result = JSONObject.parseObject(response);
            return "OK".equals(result.getString("errorCodes"));
        }
        
        return false;
    }
    
    public boolean delDeviceStatus(String deviceToken, int mode) throws IOException {
        URL url = new URL(DEL_STATUS_URL);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        
        setRequestHeader(conn);
        
        JSONObject data = new JSONObject();
        data.put("mode", mode);
        data.put("deviceToken", deviceToken);
        data.put("timestamp", System.currentTimeMillis());
        
        JSONObject requestBody = new JSONObject();
        requestBody.put("data", data);
        
        try (OutputStream os = conn.getOutputStream()) {
            os.write(requestBody.toJSONString().getBytes("utf-8"));
        }
        
        int responseCode = conn.getResponseCode();
        if (responseCode == 200) {
            String response = readResponse(conn.getInputStream());
            JSONObject result = JSONObject.parseObject(response);
            return "OK".equals(result.getString("errorCodes"));
        }
        
        return false;
    }
    
    private void setRequestHeader(HttpURLConnection conn) throws IOException {
        conn.setRequestMethod("POST");
        conn.setDoOutput(true);
        conn.setRequestProperty("Content-Type", "application/json;charset=utf-8");
        conn.setRequestProperty("Authorization", authorization);
        conn.setRequestProperty("bundleName", bundleName);
        conn.setConnectTimeout(50000);
        conn.setReadTimeout(50000);
    }
    
    private String readResponse(InputStream inputStream) throws IOException {
        BufferedReader reader = new BufferedReader(
            new InputStreamReader(inputStream, "utf-8"));
        StringBuilder response = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            response.append(line);
        }
        reader.close();
        return response.toString();
    }
    
    public ClaimResult claimNewUserPackage(String deviceToken, String userId) {
        try {
            DeviceStatusResult status = getDeviceStatus(deviceToken, 1);
            
            if ("OK".equals(status.errorCode)) {
                if (status.bit0 != null && status.bit0) {
                    return new ClaimResult(false, "您已领取过新机礼包");
                }
            } else if ("NotFound".equals(status.errorCode)) {
                System.out.println("新设备,允许领取");
            } else {
                return new ClaimResult(false, "状态查询失败: " + status.errorCode);
            }
            
            boolean updateSuccess = setDeviceStatus(deviceToken, 1, true, false);
            if (!updateSuccess) {
                System.out.println("警告:状态更新失败,但礼包已发放");
            }
            
            return new ClaimResult(true, "新机礼包领取成功");
            
        } catch (IOException e) {
            return new ClaimResult(false, "网络错误: " + e.getMessage());
        }
    }
    
    public static void main(String[] args) {
        String authorization = "Bearer eyJraWQiOi...";
        String bundleName = "com.example.myapplication";
        String deviceToken = "aes-gcm.xxx...";
        
        DeviceVerifyServer server = new DeviceVerifyServer(authorization, bundleName);
        
        try {
            boolean isValid = server.checkDeviceToken(deviceToken);
            System.out.println("DeviceToken验证结果: " + isValid);
            
            DeviceStatusResult status = server.getDeviceStatus(deviceToken, 1);
            System.out.println("设备状态查询结果: " + status.errorCode);
            
            ClaimResult result = server.claimNewUserPackage(deviceToken, "user123");
            System.out.println("领取结果: " + result.message);
            
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}

class DeviceStatusResult {
    String errorCode;
    String bundleName;
    Boolean bit0;
    Boolean bit1;
    Long lastUpdateTime;
}

class ClaimResult {
    boolean success;
    String message;
    
    ClaimResult(boolean success, String message) {
        this.success = success;
        this.message = message;
    }
}