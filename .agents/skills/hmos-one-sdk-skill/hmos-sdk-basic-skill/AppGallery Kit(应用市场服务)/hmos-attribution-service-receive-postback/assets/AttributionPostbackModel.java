import com.fasterxml.jackson.annotation.JsonProperty;

public class AttributionPostbackRequest {
    
    @JsonProperty("ad_tech_id")
    private String adTechId;
    
    @JsonProperty("campaign_id")
    private String campaignId;
    
    @JsonProperty("source_id")
    private String sourceId;
    
    @JsonProperty("destination_id")
    private String destinationId;
    
    @JsonProperty("service_tag")
    private String serviceTag;
    
    @JsonProperty("business_scene")
    private Integer businessScene;
    
    @JsonProperty("trigger_data")
    private Integer triggerData;
    
    @JsonProperty("installation_status")
    private Integer installationStatus;
    
    @JsonProperty("nonce")
    private String nonce;
    
    @JsonProperty("timestamp")
    private long timestamp;
    
    @JsonProperty("signature")
    private String signature;
    
    @JsonProperty("transaction_id")
    private String transactionId;
    
    public String getAdTechId() {
        return adTechId;
    }
    
    public void setAdTechId(String adTechId) {
        this.adTechId = adTechId;
    }
    
    public String getCampaignId() {
        return campaignId;
    }
    
    public void setCampaignId(String campaignId) {
        this.campaignId = campaignId;
    }
    
    public String getSourceId() {
        return sourceId;
    }
    
    public void setSourceId(String sourceId) {
        this.sourceId = sourceId;
    }
    
    public String getDestinationId() {
        return destinationId;
    }
    
    public void setDestinationId(String destinationId) {
        this.destinationId = destinationId;
    }
    
    public String getServiceTag() {
        return serviceTag;
    }
    
    public void setServiceTag(String serviceTag) {
        this.serviceTag = serviceTag;
    }
    
    public Integer getBusinessScene() {
        return businessScene;
    }
    
    public void setBusinessScene(Integer businessScene) {
        this.businessScene = businessScene;
    }
    
    public Integer getTriggerData() {
        return triggerData;
    }
    
    public void setTriggerData(Integer triggerData) {
        this.triggerData = triggerData;
    }
    
    public Integer getInstallationStatus() {
        return installationStatus;
    }
    
    public void setInstallationStatus(Integer installationStatus) {
        this.installationStatus = installationStatus;
    }
    
    public String getNonce() {
        return nonce;
    }
    
    public void setNonce(String nonce) {
        this.nonce = nonce;
    }
    
    public long getTimestamp() {
        return timestamp;
    }
    
    public void setTimestamp(long timestamp) {
        this.timestamp = timestamp;
    }
    
    public String getSignature() {
        return signature;
    }
    
    public void setSignature(String signature) {
        this.signature = signature;
    }
    
    public String getTransactionId() {
        return transactionId;
    }
    
    public void setTransactionId(String transactionId) {
        this.transactionId = transactionId;
    }
}

public class AttributionPostbackResponse {
    
    @JsonProperty("resultCode")
    private String resultCode;
    
    @JsonProperty("resultDesc")
    private String resultDesc;
    
    public String getResultCode() {
        return resultCode;
    }
    
    public void setResultCode(String resultCode) {
        this.resultCode = resultCode;
    }
    
    public String getResultDesc() {
        return resultDesc;
    }
    
    public void setResultDesc(String resultDesc) {
        this.resultDesc = resultDesc;
    }
}

public class AttributionException extends Exception {
    
    public AttributionException(String message) {
        super(message);
    }
    
    public AttributionException(String message, Throwable cause) {
        super(message, cause);
    }
}