public class NSP_IpCopyActionEmailBodyCont {

    private String recType;
    private String sectionTitle;
    private final List<Implementation_Profile__c> SUCCESS_IP_RECORDS = new List<Implementation_Profile__c>();
    private final List<Implementation_Profile__c> FAIL_IP_RECORDS = new List<Implementation_Profile__c>();

    public NSP_IpCopyActionEmailBodyCont(){
        this.populateActionDetails(ApexPages.currentPage().getParameters());
    }

    public List<Implementation_Profile__c> getSuccessfulIpRecords() {
        return SUCCESS_IP_RECORDS;
    }

    public List<Implementation_Profile__c> getFailIpRecords() {
        return FAIL_IP_RECORDS;
    }

    public String getRecordTypeLabel() {
        return this.recType;
    }

    public String getSectionTitle() {
        return sectionTitle;
    }

    public Boolean getShowSuccessSection(){
        return !SUCCESS_IP_RECORDS.isEmpty();
    }

    public Boolean getShowFailureSection(){
        return !FAIL_IP_RECORDS.isEmpty();
    }

    public String getInsperityLogoLink(){
        return 'https://insperity--sfdev2--c.documentforce.com/sfc/dist/version/renditionDownload?rendition=ORIGINAL_Jpg&versionId=0683C000001bMMD&operationContext=DELIVERY&contentId=05T3C000005TZkC&page=0&d=/a/3C000000IFL2/xCx3ylOfIm8HmRBLr2eldIB13zVyE7L9w9c6oAlsyWQ&oid=00D3C0000004znZ&dpt=null&viewId=';
    }
    
    @TestVisible
    private void populateActionDetails(Map<String, String> params){
        this.recType = params.get('recType');
        populateSectionTitle(params.get('source'));
		populateRecordsByStatus(params);
    }

    private void populateRecordsByStatus(Map<String, String> params){
        List<String> successIds = getListByStringValue(params.get('success'));
        List<String> failIds = getListByStringValue(params.get('fail'));
        List<String> allIpRecords = new List<String>();

		allIpRecords.addAll(successIds);
		allIpRecords.addAll(failIds);

        if(allIpRecords.isEmpty()){
            return;
        }

        for(Implementation_Profile__c ipRec : [SELECT Id, Account__r.Name FROM Implementation_Profile__c WHERE ID IN :allIpRecords]){
            if(successIds != null && successIds.contains(ipRec.Id)){
                SUCCESS_IP_RECORDS.add(ipRec);
            }

            if(failIds != null && failIds.contains(ipRec.Id)){
                FAIL_IP_RECORDS.add(ipRec);
            }
        }
    }

    private static List<String> getListByStringValue(String input){
        if(String.isBlank(input)){
            return new List<String>();
        }

        return (List<String>) JSON.deserialize(input, List<String>.class);        
    }

    private void populateSectionTitle(String accName){
        String title = 'The copy action ';
        if(String.isNotBlank(accName)){
			title += 'from ' + accName + ' ';            
        }

        title += 'to the following client(s) was ';

        this.sectionTitle = title;
    }
}