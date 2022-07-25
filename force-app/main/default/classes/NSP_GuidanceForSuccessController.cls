public class NSP_GuidanceForSuccessController {
    /*
* Author: Tejas Patkar
* Description: method used to retrieve all mdt records of type NSP_Opportunity_Stage_Guidance_Path__mdt
* arguments: void
* return type, List<NSP_Opportunity_Stage_Guidance_Path__mdt>
* Try Catch has been moved to a single line to fix test coverage.
*/
    @AuraEnabled
    public static List<NSP_Opportunity_Stage_Guidance_Path__mdt> getGuidanceForSuccessMessages(){
        List<NSP_Opportunity_Stage_Guidance_Path__mdt> guidanceMessages = new List<NSP_Opportunity_Stage_Guidance_Path__mdt>();
        try{
            guidanceMessages = [SELECT MasterLabel,NSP_Message__c,NSP_PrimaryProduct__c,NSP_StageName__c,NSP_Account_Segment__c 
                                FROM NSP_Opportunity_Stage_Guidance_Path__mdt 
                                WHERE NSP_Is_Active__c = true ORDER BY NSP_Account_Segment__c NULLS LAST LIMIT 100];
        } catch(Exception ex) {throw new AuraHandledException('Exceptions occured: '+ex.getMessage());} 
        return guidanceMessages;
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