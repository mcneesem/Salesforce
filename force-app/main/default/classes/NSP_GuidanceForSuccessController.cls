public class NSP_GuidanceForSuccessController {
    /*
* Author: Tejas Patkar
* Description: method used to retrieve all mdt records of type NSP_Opportunity_Stage_Guidance_Path__mdt
* arguments: void
* return type, List<NSP_Opportunity_Stage_Guidance_Path__mdt>
*/
    @AuraEnabled
    public static List<NSP_Opportunity_Stage_Guidance_Path__mdt> getGuidanceForSuccessMessages(){
        List<NSP_Opportunity_Stage_Guidance_Path__mdt> guidanceMessages = new List<NSP_Opportunity_Stage_Guidance_Path__mdt>();
        try{
            guidanceMessages = [SELECT MasterLabel,NSP_Message__c,NSP_PrimaryProduct__c,NSP_StageName__c,NSP_Account_Segment__c 
                                FROM NSP_Opportunity_Stage_Guidance_Path__mdt 
                                WHERE NSP_Is_Active__c = true ORDER BY NSP_Account_Segment__c NULLS LAST LIMIT 100];
                                
            
        } catch(Exception ex) {
            throw new AuraHandledException('Exceptions occured: '+ex.getMessage());
        } 
        return guidanceMessages;
    }
    
}