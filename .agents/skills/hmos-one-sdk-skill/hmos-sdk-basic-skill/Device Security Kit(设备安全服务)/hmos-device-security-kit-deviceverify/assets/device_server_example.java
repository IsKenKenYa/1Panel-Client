import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import com.alibaba.fastjson.JSONObject;

public class DeviceVerifyServer {
    private static String authorization = "Bearer eyJraWQiOiI5YTU5ZGRkZDZlYzY0MTgyYmUwMTc2MDNjZDU1YjEwNCIsInR5cCI6IkpXVCIsImFsZyI6IlBTMjU2In0.eyJhdWQiOiJodHRwczovL29hdXRoLWxvZ2luLmNsb3VkLmh1YXdlaS5jb20vb2F1dGgyL3YzL3Rva2VuIiwiaXNzIjoiMTE0MDIzMzQ1IiwiZXhwIjoxNzU0NDQ4NDU2LCJpYXQiOjE3NTQ0NDQ4NTZ9.cJEiLM53QBTSxzPjDAqK-HeteSv_qWxnAuEiwaN_udLQz78QZPcD54RFWSOqE459B0Y78hEL1-2eQlcCjbGn0OI2AQbwTwYzoRbLftAEyP5V9Juv1A-cfR8MoVapVdZ3pA9Jg6B5cBjcQLax-GTUJjevgI4PyTxQCIhLa-kaQq_h-KOnpcWlVUx2weLRAcGs4Tr3wYqdLnSPE7Hp_44C3S69dSoXoP8HL6-2L4aJzzvNn7uYoRiZAoCZoarJNHi7d8h9JEJ2K5vmaYV_lJ9l0_G4RDjpEmtCPOEkXLPIvjh5fwEBPyMZiUJqHyqTkdw8AjjgIaFe0wG9wCZk4sEo9GOruuy9tN6mEccFAEKbSf28gpUowWC23uKQPIYb9sdzrN8D3hpalrN5CDh1dv80wlhLxXeJOWWnfjCqYhA0m17UFC4xEhno-M52dEb4BODPsw-96xx02GX8_VqDDjjUmXEr6lwj4yLE_5feR1QFQS2NhC11Py4AzrsEPb9maFqR-bOUO2SfLdD1EjvMx2p-tELosFH8DmvwtbjNVYDN0zGEed150qhMtkDG9DUwT0dL3q_ikRq73syB9WbQrlpWeJAWBmazkb0EoSf24UO2rRjcZ0hGmgFIIH7AzHgw4Ok2ijCJ5uVIY59DUsXXUIBIH7tMyNUjrdZG0_ctDORrk_s";
    private static String bundleName = "com.huawei.myapplication";
    
    private static final String CHECK_DEVICE_TOKEN_URL = "https://connect-api.cloud.huawei.com/api/rms/v1/deviceVerify/checkDeviceToken";
    private static final String GET_DEVICE_STATUS_URL = "https://connect-api.cloud.huawei.com/api/rms/v1/deviceVerify/getDeviceStatus";
    private static final String SET_DEVICE_STATUS_URL = "https://connect-api.cloud.huawei.com/api/rms/v1/deviceVerify/setDeviceStatus";
    private static final String DEL_DEVICE_STATUS_URL = "https://connect-api.cloud.huawei.com/api/rms/v1/deviceVerify/delDeviceStatus";
    
    public static void main(String[] args) throws IOException {
        String deviceToken = "aes-gcm.gouLVEalfJxRLxt+3Gxh/orDAG9kDbkeFydkxGrDOHVJ3KEhiSDhIeW+/KH0ErqVxZ0vfkgtapaMu3yc0IND+lzC8ZH86NHxW+/GsqxYhvZ650TWUkanwdlZwYD0HPZ/KFnDPgIvGLvvWz1BdoPOOiFy5BuCQfGVNxl9OBTd7wsiJpl8kKywMRg/k1x61/8IpaH4F6tPrMV/Fv4N/WLfSHlC9AkB1ekZz4hxambDaXP8aXz59FYWItTl7tBOV09+JKnFqD0dB5ZmXjUhVLRKpYeGH8dPWG2gOmEksY6CsXvWBul+5HF76myfUeSvrWfD7Ee3+5Uuld3v+s8W+aFJkdUo8GSCF4xbiA+01BKnq0DIh0EKW/VJAQHjo/P/X/6jMwoDnbF7NWPmh827LHKQMIsN46zfke7qpdBsYpidKNxlXIb1azyAhD/izf5KQwkzwlVTctIvkUNH9XjTh1I6xb8yYb7TjZ7tnMGg2lWizNsejIcwAPqTTyXXupL5mPc8SwsZ424mDQhf1pCfacbZFaew0jWUC5ZQ2B8CiBeX";
        
        checkDeviceToken(deviceToken);
        getDeviceStatus(deviceToken);
        setDeviceStatus(deviceToken, true, false);
        delDeviceStatus(deviceToken);
    }
    
    public static String checkDeviceToken(String deviceToken) throws IOException {
        URL url = new URL(CHECK_DEVICE_TOKEN_URL);
        HttpURLConnection con = (HttpURLConnection) url.openConnection();
        
        setupRequestHeader(con);
        JSONObject postBody = createRequestBody(deviceToken);
        
        String response = sendRequestAndReadResponse(con, postBody);
        System.out.println("checkDeviceToken response: " + response);
        
        return response;
    }
    
    public static String getDeviceStatus(String deviceToken) throws IOException {
        URL url = new URL(GET_DEVICE_STATUS_URL);
        HttpURLConnection con = (HttpURLConnection) url.openConnection();
        
        setupRequestHeader(con);
        JSONObject postBody = createRequestBodyWithMode(deviceToken, 1);
        
        String response = sendRequestAndReadResponse(con, postBody);
        System.out.println("getDeviceStatus response: " + response);
        
        JSONObject responseJson = JSONObject.parseObject(response);
        if (responseJson.containsKey("errorCodes")) {
            String errorCode = responseJson.getString("errorCodes");
            if ("OK".equals(errorCode)) {
                Boolean bit0 = responseJson.getBoolean("bit0");
                Boolean bit1 = responseJson.getBoolean("bit1");
                Long lastUpdateTime = responseJson.getLong("lastUpdateTime");
                
                System.out.println("Device status - bit0: " + bit0 + ", bit1: " + bit1);
                System.out.println("Last update time: " + lastUpdateTime);
            } else if ("NotFound".equals(errorCode)) {
                System.out.println("Device not marked yet, this is a new device");
            }
        }
        
        return response;
    }
    
    public static String setDeviceStatus(String deviceToken, Boolean bit0, Boolean bit1) throws IOException {
        URL url = new URL(SET_DEVICE_STATUS_URL);
        HttpURLConnection con = (HttpURLConnection) url.openConnection();
        
        setupRequestHeader(con);
        JSONObject postBody = createRequestBodyWithBits(deviceToken, 1, bit0, bit1);
        
        String response = sendRequestAndReadResponse(con, postBody);
        System.out.println("setDeviceStatus response: " + response);
        
        return response;
    }
    
    public static String delDeviceStatus(String deviceToken) throws IOException {
        URL url = new URL(DEL_DEVICE_STATUS_URL);
        HttpURLConnection con = (HttpURLConnection) url.openConnection();
        
        setupRequestHeader(con);
        JSONObject postBody = createRequestBodyWithMode(deviceToken, 1);
        
        String response = sendRequestAndReadResponse(con, postBody);
        System.out.println("delDeviceStatus response: " + response);
        
        return response;
    }
    
    private static void setupRequestHeader(HttpURLConnection con) throws IOException {
        con.setRequestMethod("POST");
        con.setDoOutput(true);
        con.setRequestProperty("Content-Type", "application/json;charset=utf-8");
        con.setRequestProperty("Authorization", authorization);
        con.setRequestProperty("bundleName", bundleName);
        con.setConnectTimeout(10000);
        con.setReadTimeout(10000);
    }
    
    private static JSONObject createRequestBody(String deviceToken) {
        JSONObject data = new JSONObject();
        data.put("deviceToken", deviceToken);
        data.put("timestamp", System.currentTimeMillis());
        
        JSONObject postBody = new JSONObject();
        postBody.put("data", data);
        return postBody;
    }
    
    private static JSONObject createRequestBodyWithMode(String deviceToken, int mode) {
        JSONObject data = new JSONObject();
        data.put("mode", mode);
        data.put("deviceToken", deviceToken);
        data.put("timestamp", System.currentTimeMillis());
        
        JSONObject postBody = new JSONObject();
        postBody.put("data", data);
        return postBody;
    }
    
    private static JSONObject createRequestBodyWithBits(String deviceToken, int mode, Boolean bit0, Boolean bit1) {
        JSONObject data = new JSONObject();
        data.put("mode", mode);
        data.put("deviceToken", deviceToken);
        data.put("timestamp", System.currentTimeMillis());
        data.put("bit0", bit0);
        data.put("bit1", bit1);
        
        JSONObject postBody = new JSONObject();
        postBody.put("data", data);
        return postBody;
    }
    
    private static String sendRequestAndReadResponse(HttpURLConnection con, JSONObject postBody) throws IOException {
        try (OutputStream os = con.getOutputStream()) {
            byte[] input = postBody.toString().getBytes("utf-8");
            os.write(input, 0, input.length);
        }
        
        int responseCode = con.getResponseCode();
        System.out.println("Response Code: " + responseCode);
        
        InputStream stream;
        if (responseCode >= 200 && responseCode < 300) {
            stream = con.getInputStream();
        } else {
            stream = con.getErrorStream();
        }
        
        StringBuilder response = new StringBuilder();
        String line;
        try (BufferedReader br = new BufferedReader(new InputStreamReader(stream, "utf-8"))) {
            while ((line = br.readLine()) != null) {
                response.append(line);
            }
        } catch (Exception e) {
            System.out.println("Error reading response: " + e.getMessage());
        }
        
        return response.toString();
    }
    
    public static void handleNewUserCoupon(String deviceToken) throws IOException {
        String statusResponse = getDeviceStatus(deviceToken);
        JSONObject responseJson = JSONObject.parseObject(statusResponse);
        
        if (responseJson.containsKey("errorCodes")) {
            String errorCode = responseJson.getString("errorCodes");
            
            if ("NotFound".equals(errorCode)) {
                System.out.println("New device detected, granting coupon...");
                setDeviceStatus(deviceToken, false, true);
                System.out.println("Coupon granted successfully");
            } else if ("OK".equals(errorCode)) {
                Boolean bit1 = responseJson.getBoolean("bit1");
                if (bit1 == null || !bit1) {
                    System.out.println("User has not received coupon, granting coupon...");
                    setDeviceStatus(deviceToken, responseJson.getBoolean("bit0"), true);
                    System.out.println("Coupon granted successfully");
                } else {
                    System.out.println("User has already received coupon on this device");
                }
            }
        }
    }
}