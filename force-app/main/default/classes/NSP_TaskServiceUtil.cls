/* **************************************************************************************************   
Component Name :  NSP_TaskServiceUtil class
Version              :  1.0                                                                          
Created Date         :  October 12, 2021                                                             
Function             :  This class is used as for  	
Story                :                                                                             
Modification Log     :                                                                               
*	Tejas           October 12, 2021          First Iteration
*
***************************************************************************************************
*/
public class NSP_TaskServiceUtil {
    public static void updateLeadStage(List<String> lead){
        
        List<Lead> leadList = new List<Lead> ();
        
        for(Lead leadobj : [select id,nsp_lead_stage__c from lead WHERE id in : lead]){
            leadobj.nsp_lead_stage__c = NSP_SalesConstants.LEAD_STAGE_SRL;
            leadList.add(leadobj);
        }
       
        update leadList;
    }
}