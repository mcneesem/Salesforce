public without sharing class  NSP_GuidanceForSuccessController {
    // test w/ NSP_GuidanceForSuccessControllerTest (85%)
    
    /* Description: This method queries the guidance for success from the custom metadata "NSP_Opportunity_Stage_Guidance_Path__mdt"
     * @param: stageName
     * @param: productId
     * @param: segmentId
     * @return: guidance message (String)
     * Modification History:
     * -------------------------------------------------------------------------------------
     * author           | Date              | Description
     * -------------------------------------------------------------------------------------
     * Niguel Florian   07/28/2025         created this new method - ADO-442075
     */
    @AuraEnabled
    public static String getMessage(String stageName, String productId, String segmentId){
        String segment = !String.isEmpty(segmentId) ? segmentId : null;
        try{
            //  Get guidance text
            List<NSP_Opportunity_Stage_Guidance_Path__mdt> guidanceMessages =
                [SELECT NSP_Message__c FROM NSP_Opportunity_Stage_Guidance_Path__mdt 
            WHERE NSP_StageName__c =: stageName AND NSP_PrimaryProduct__c =:productId AND NSP_Account_Segment__c =: segment
            AND NSP_Is_Active__c = true];
            
            //  If not found then get default guidance text (non techology product)
            if(guidanceMessages.size() == 0){
                guidanceMessages = [SELECT NSP_Message__c FROM NSP_Opportunity_Stage_Guidance_Path__mdt 
                WHERE NSP_StageName__c =: stageName AND NSP_PrimaryProduct__c = 'Technology' AND NSP_Is_Active__c = true];
            }
            
            if(guidanceMessages.size() > 0){
                return  guidanceMessages[0].NSP_Message__c;
            }
            
        } catch(Exception ex){
            throw new AuraHandledException('Exceptions occured: '+ ex.getMessage());
        }
        return '';
    }
    
    /* Description: This method queries the required field from opportunity with recordId
     * @param: recordId
     * @return: Opportunity
     * Modification History:
     * -------------------------------------------------------------------------------------
     * author           | Date              | Description
     * -------------------------------------------------------------------------------------
     * Harsha Khiroya    07/14/2022          created this new method - ticket 557355
     */
    @AuraEnabled
    public static Opportunity getOpportunityDetails(String recordId){
        Opportunity opportunityRecord;
        try{
            opportunityRecord = [Select Id, NSP_Account_Segment__c, NSP_PrimaryProduct__c,StageName,NSP_Number_of_Employees__c from Opportunity where Id =: recordId];
        }catch(Exception ex){
            throw new NSP_CustomException(ex);
        }
        return opportunityRecord;
    }
    
}