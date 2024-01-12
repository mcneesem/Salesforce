/**
* @description  :  class for sharing project records based on ACR.
* @date 01/11/2023
* Added as part of STY-03866
* Name : NSP_AccountContactRelationSharing
* Version : 1.0
*/
public class NSP_AccountContactRelationSharing {
    
    private static final String CLASS_NAME = 'NSP_AccountContactRelationSharing';
    
    /***********************************************************************************************
	* MethodName: projectRecordSharing 
	* Description : Method for sharing records With Community Users
	* Params:       Set<Id> newAccountIdSet
	* 
	* ********************************************************************************************/      
    public static void projectRecordSharing(Set<Id> newAccountIdSet){
        try{
            //fetch all the related projects for acr contact for sharing the project records
            Map<Id, pse__Proj__c> mapOfNewProjects =new Map<Id, pse__Proj__c>([SELECT Id,pse__Account__c,
                                                                                   NSP_Visible_to_Client__c
                                                                                   FROM pse__Proj__c 
                                                                                   WHERE pse__Account__c 
                                                                                   IN :newAccountIdSet AND NSP_Visible_to_Client__c = TRUE ]);
            
            if(mapOfNewProjects.size()>0){
                    NSP_ProjectRecordSharing.projectRecordSharing(newAccountIdSet, mapOfNewProjects);
            }
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(CLASS_NAME, 'projectRecordSharing', ex.getMessage());
        }
        
    }
    
    /***********************************************************************************************
	* MethodName: projectRemoveSharing 
	* Description : Method for removing sharing access  With Community Users
	* Params:       Set<Id> oldAccountIdSet
	* 
	* ********************************************************************************************/
    
    public static void projectRemoveSharing(Set<Id> oldAccountIdSet){
        try{
            //fetch all the related projects where project sharing needs to delete when acr is updated
            Map<Id, pse__Proj__c> mapOfOldProjects =new Map<Id, pse__Proj__c>([SELECT Id,pse__Account__c 
                                                                                 FROM pse__Proj__c 
                                                                                 WHERE pse__Account__c 
                                                                                 IN :oldAccountIdSet AND NSP_Visible_to_Client__c = TRUE ]);
            
            if(mapOfOldProjects.size()>0){
                    NSP_ProjectRecordSharing.projectRemoveSharing(mapOfOldProjects.keySet());
            }
            

        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(CLASS_NAME, 'projectRemoveSharing', ex.getMessage());
        }
        
    }

    /***********************************************************************************************
	* MethodName: projectTaskRecordSharing 
	* Description : Method for sharing project task records With Community Users
	* Params:       Set<Id> newAccountIdSet,Set<Id> oldAccountIdSet
	* 
	* ********************************************************************************************/      
  
    public static void projectTaskRecordSharing(Set<Id> newAccountIdSet, Set<Id> oldAccountIdSet){
        try{
            //fetch all the related projects for acr contact for sharing the project records
            if(newAccountIdSet!=null && !newAccountIdSet.isEmpty()){
                Map<Id, pse__Project_Task__c> mapOfNewProjectTasks =new Map<Id, pse__Project_Task__c>([SELECT Id,pse__Project__c,
                                                                                    pse__Project__r.pse__Account__c,
                                                                                    NSP_Visible_to_Client__c
                                                                                    FROM pse__Project_Task__c 
                                                                                    WHERE pse__Project__r.pse__Account__c 
                                                                                    IN :newAccountIdSet AND NSP_Visible_to_Client__c = TRUE ]);

                if(mapOfNewProjectTasks.size()>0){
                        NSP_ProjectTaskSharing.projectTaskRecordSharing(mapOfNewProjectTasks.keyset(),null);
                }
            }
            if(oldAccountIdSet!=null && !oldAccountIdSet.isEmpty()){
                Map<Id, pse__Project_Task__c> mapOfOldProjectTasks =new Map<Id, pse__Project_Task__c>([SELECT Id,pse__Project__c,
                                                                                    pse__Project__r.pse__Account__c,
                                                                                    NSP_Visible_to_Client__c
                                                                                    FROM pse__Project_Task__c 
                                                                                    WHERE pse__Project__r.pse__Account__c 
                                                                                    IN :oldAccountIdSet AND NSP_Visible_to_Client__c != TRUE ]);
                
                
                if(mapOfOldProjectTasks.size()>0){
                        NSP_ProjectTaskSharing.projectTaskRecordSharing(null,mapOfOldProjectTasks.keyset());
                }
            }
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(CLASS_NAME, 'projectTaskRecordSharing', ex.getMessage());
        }
        
    }
    
    /***********************************************************************************************
	* MethodName: milestoneRecordSharing 
	* Description : Method for sharing milestone records With Community Users
	* Params:       Set<Id> newAccountIdSet,Set<Id> oldAccountIdSet
	* 
	* ********************************************************************************************/      
  
    public static void milestoneRecordSharing(Set<Id> newAccountIdSet, Set<Id> oldAccountIdSet){
        try{
            //fetch all the related projects for acr contact for sharing the project records
            if(newAccountIdSet!=null && !newAccountIdSet.isEmpty()){
                Map<Id, pse__Milestone__c> mapOfNewMilestones =new Map<Id, pse__Milestone__c>([SELECT Id,pse__Project__c,
                                                                                    pse__Project__r.pse__Account__c,
                                                                                    NSP_Visible_to_Client__c
                                                                                    FROM pse__Milestone__c 
                                                                                    WHERE pse__Project__r.pse__Account__c 
                                                                                    IN :newAccountIdSet AND NSP_Visible_to_Client__c = TRUE ]);
                if(mapOfNewMilestones.size()>0){
                        NSP_MilestoneTaskSharing.mileStoneRecordSharing(mapOfNewMilestones.keyset(),null);
                }
            }
            if(oldAccountIdSet!=null && !oldAccountIdSet.isEmpty()){
                Map<Id, pse__Milestone__c> mapOfOldMilestones =new Map<Id, pse__Milestone__c>([SELECT Id,pse__Project__c,
                                                                                   pse__Project__r.pse__Account__c,
                                                                                   NSP_Visible_to_Client__c
                                                                                   FROM pse__Milestone__c 
                                                                                   WHERE pse__Project__r.pse__Account__c 
                                                                                   IN :oldAccountIdSet AND NSP_Visible_to_Client__c != TRUE ]);
            
            
        	    if(mapOfOldMilestones.size()>0){
                    NSP_MilestoneTaskSharing.mileStoneRecordSharing(null,mapOfOldMilestones.keyset());
                }
            }
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(CLASS_NAME, 'milestoneRecordSharing', ex.getMessage());
        }
        
    }
}