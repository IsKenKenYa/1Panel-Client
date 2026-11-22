import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import org.json.JSONObject;

public class IAPSubscriptionDeliveryServer {
    private static final String ROOT_URL = "https://svc-drcn.developer.huawei.com";
    private static final String CONFIRM_PURCHASE_URL = ROOT_URL + "/subscription/harmony/v1/application/purchase/shipped/confirm";
    
    private String jwtToken;
    
    public IAPSubscriptionDeliveryServer(String jwtToken) {
        this.jwtToken = jwtToken;
    }
    
    public void processSubscriptionDelivery(String jwsSubscriptionStatus) {
        try {
            String subscriptionStatusPayload = JWSChecker.checkAndDecodeJWS(jwsSubscriptionStatus);
            JSONObject statusData = new JSONObject(subscriptionStatusPayload);
            
            JSONObject lastSubscriptionStatus = statusData.getJSONObject("lastSubscriptionStatus");
            String status = lastSubscriptionStatus.getString("status");
            
            if (!"1".equals(status)) {
                System.out.println("Subscription not active. Status: " + status);
                return;
            }
            
            JSONObject purchaseOrder = lastSubscriptionStatus.getJSONObject("lastPurchaseOrder");
            String purchaseOrderId = purchaseOrder.getString("purchaseOrderId");
            String purchaseToken = purchaseOrder.getString("purchaseToken");
            String productId = purchaseOrder.getString("productId");
            
            boolean isDelivered = checkBenefitDeliveryStatus(purchaseOrderId);
            if (isDelivered) {
                System.out.println("Benefit already delivered for order: " + purchaseOrderId);
                return;
            }
            
            grantUserBenefit(productId, purchaseOrderId);
            recordDeliveryOrder(purchaseOrder);
            
            System.out.println("Benefit delivered successfully for order: " + purchaseOrderId);
            
            String finishStatus = purchaseOrder.optString("finishStatus", "2");
            if (!"1".equals(finishStatus)) {
                confirmPurchaseOnServer(purchaseToken, purchaseOrderId);
            }
            
        } catch (Exception e) {
            System.err.println("Failed to process subscription delivery: " + e.getMessage());
            handleDeliveryError(e);
        }
    }
    
    private boolean checkBenefitDeliveryStatus(String orderId) {
        return false;
    }
    
    private void grantUserBenefit(String productId, String orderId) {
        System.out.println("Granting benefit for product: " + productId + ", order: " + orderId);
    }
    
    private void recordDeliveryOrder(JSONObject purchaseOrder) {
        System.out.println("Recording delivery order: " + purchaseOrder.getString("purchaseOrderId"));
    }
    
    public void confirmPurchaseOnServer(String purchaseToken, String purchaseOrderId) {
        try {
            URL url = new URL(CONFIRM_PURCHASE_URL);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            
            connection.setRequestMethod("POST");
            connection.setRequestProperty("Content-Type", "application/json;charset=UTF-8");
            connection.setRequestProperty("Authorization", "Bearer " + jwtToken);
            connection.setDoOutput(true);
            
            JSONObject requestBody = new JSONObject();
            requestBody.put("purchaseToken", purchaseToken);
            requestBody.put("purchaseOrderId", purchaseOrderId);
            
            DataOutputStream outputStream = new DataOutputStream(connection.getOutputStream());
            outputStream.write(requestBody.toString().getBytes(StandardCharsets.UTF_8));
            outputStream.flush();
            outputStream.close();
            
            int responseCode = connection.getResponseCode();
            if (responseCode == HttpURLConnection.HTTP_OK) {
                InputStream inputStream = connection.getInputStream();
                BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));
                StringBuilder response = new StringBuilder();
                String line;
                while ((line = reader.readLine()) != null) {
                    response.append(line);
                }
                reader.close();
                
                JSONObject responseJson = new JSONObject(response.toString());
                String responseCodeStr = responseJson.getString("responseCode");
                if ("0".equals(responseCodeStr)) {
                    System.out.println("Purchase confirmed successfully on server.");
                    updateDeliveryConfirmation(purchaseOrderId);
                } else {
                    System.err.println("Purchase confirmation failed. Response code: " + responseCodeStr);
                    handleConfirmError(responseCodeStr);
                }
            } else {
                System.err.println("HTTP request failed. Response code: " + responseCode);
            }
            
            connection.disconnect();
            
        } catch (Exception e) {
            System.err.println("Failed to confirm purchase on server: " + e.getMessage());
            handleConfirmError(e);
        }
    }
    
    private void updateDeliveryConfirmation(String orderId) {
        System.out.println("Delivery confirmation updated for order: " + orderId);
    }
    
    private void handleDeliveryError(Exception e) {
        System.err.println("Delivery error handled: " + e.getMessage());
    }
    
    private void handleConfirmError(String errorCode) {
        switch (errorCode) {
            case "1001860052":
                System.err.println("Purchase not paid. Cannot confirm.");
                break;
            case "1001860053":
                System.err.println("Purchase already confirmed.");
                break;
            default:
                System.err.println("Unknown error code: " + errorCode);
        }
    }
    
    private void handleConfirmError(Exception e) {
        System.err.println("Confirmation error handled: " + e.getMessage());
        scheduleRetryConfirmation();
    }
    
    private void scheduleRetryConfirmation() {
        System.out.println("Scheduled retry for purchase confirmation.");
    }
    
    public static void main(String[] args) {
        String jwtToken = "your.jwt.token.here";
        String jwsSubscriptionStatus = "your.jws.subscription.status.here";
        
        IAPSubscriptionDeliveryServer server = new IAPSubscriptionDeliveryServer(jwtToken);
        server.processSubscriptionDelivery(jwsSubscriptionStatus);
    }
}