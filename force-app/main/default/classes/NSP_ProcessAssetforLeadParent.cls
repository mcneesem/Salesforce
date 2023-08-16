/**
Apex Class Name      :  NSP_processAssetforLeadParent
Version              :  1.0                                                                          
Created Date         :  12/20/2022
Author               :  Sumit
Function             :  class to process lead parent on plan subplan and child asset.
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Sumit singh               9/30/2022           First Iteration for STY-03796
*/
public class NSP_ProcessAssetforLeadParent {
    
    public static void processLeadParent(set<id> assetIdset)
    {	
        Map<Id,Asset> assetMap = new Map<Id,Asset>();
        Map<Id,NSP_Plan_SubPlan__c> planSubPlanUpdateMap = new Map<Id,NSP_Plan_SubPlan__c>();
        for(Asset eachAsset : [SELECT id,NSP_Price_Level__c,(select id,NSP_Plan_Subplan_Relationship__c from Client_Sub_Plan_History__r WHERE NSP_Active_Date__c = true) from Asset WHERE id In : assetIdset])
        {
            assetMap.put(eachAsset.Id,eachAsset);
            if(eachAsset.Client_Sub_Plan_History__r != null && eachAsset.Client_Sub_Plan_History__r.Size() > 0)
            {
                for(NSP_Client_Sub_Plan_History__c eachClientHistory : eachAsset.Client_Sub_Plan_History__r)
                {
                    NSP_Plan_SubPlan__c eachPlanSubPlan = new  NSP_Plan_SubPlan__c(Id = eachClientHistory.NSP_Plan_Subplan_Relationship__c);
                    eachPlanSubPlan.NSP_Subplan_Lead_Parent__c = eachAsset.id;
                    planSubPlanUpdateMap.put(eachPlanSubPlan.Id,eachPlanSubPlan);
                }
            }
        }  
        
        if(planSubPlanUpdateMap.Size() > 0)
        {
            // update plan sub plan records
            List<Database.SaveResult> planSubPlanresults = Database.update(planSubPlanUpdateMap.values(),false);
            NSP_ErrorLogHandler.logSaveResultsException('processAssetforLeadParent', 'ExecuteMethod', planSubPlanresults );
            
            Map<id,Asset> childAssetUpdateMap = new Map<id,Asset>();
            for(NSP_Client_Sub_Plan_History__c eachClientHistory : [SELECT Id,NSP_Plan_Subplan_Relationship__c,NSP_Plan_Subplan_Relationship__r.NSP_Subplan_Lead_Parent__c,NSP_Asset__c,NSP_Asset__r.NSP_Client_is_Lead_Parent__c FROM NSP_Client_Sub_Plan_History__c 
                                                                    WHERE NSP_Plan_Subplan_Relationship__c in :planSubPlanUpdateMap.keySet()  AND
                                                                    NSP_Asset__c not In : assetIdset AND NSP_Active_Date__c = true])
            {
                
                Asset eachAsset = new Asset(Id = eachClientHistory.NSP_Asset__c);
                eachAsset.NSP_RET_lead_parent__c = eachClientHistory.NSP_Plan_Subplan_Relationship__r.NSP_Subplan_Lead_Parent__c;
                if(eachClientHistory.NSP_Asset__r.NSP_Client_is_Lead_Parent__c)
                {
                    eachAsset.NSP_Client_is_Lead_Parent__c = false;
                    eachAsset.NSP_Process_Order_Change__c = true;
                }
                
                childAssetUpdateMap.put(eachAsset.id,eachAsset);
                
            }

            if(childAssetUpdateMap.Size () > 0)
            {   
                // update child asset records
                List<Database.SaveResult> assetResults = Database.update(childAssetUpdateMap.values(),false);
                NSP_ErrorLogHandler.logSaveResultsException('processAssetforLeadParent', 'ExecuteMethod', assetResults );
            
            }
        }      
    }
}