//Using class without sharing for apex sharing to work for non admin users
public without sharing class NSP_MilestoneTriggerHelper {

    
    /***********************************************************************************************
    * MethodName: afterInsertDirector
    * Description : Iterates through the list of new pse__Milestone__c and map of new pse__Milestone__c
    * Params: List<pse__Milestone__c> newList, Map<Id, pse__Milestone__c> newMap
    * ********************************************************************************************/
    public static void afterInsertDirector(List<pse__Milestone__c> newList , Map<Id, pse__Milestone__c> newMap){
        Set<Id> newMilestoneIdSet = new Set<Id>();
        //Added as part of STY-04100
        for(pse__Milestone__c oMilestone : newList){
            if(oMilestone.pse__Project__c != null && oMilestone.NSP_Visible_to_Client__c == true ) {
               newMilestoneIdSet.add(oMilestone.id); 
            }
        }
        if(!newMilestoneIdSet.isEmpty()){
        	NSP_MilestoneTaskSharing.mileStoneRecordSharing(newMilestoneIdSet,null);
        }
    }

    /***********************************************************************************************
    * MethodName: afterUpdateDirector
    * Description : Iterates through the map of new pse__Milestone__c and map of old pse__Milestone__c
    * Params:  Map<Id, pse__Milestone__c> newMap,Map<Id, pse__Milestone__c> oldMap
    * ********************************************************************************************/

    public static void afterUpdateDirector(List<pse__Milestone__c> newList , Map<Id, pse__Milestone__c> oldMap){
        Set<Id> newMilestoneIdSet = new Set<Id>();
        Set<Id> oldMilestoneIdSet = new Set<Id>();
        //Added as part of STY-04100
        for(pse__Milestone__c oMilestone : newList){
            if(oMilestone.pse__Project__c != null && oMilestone.NSP_Visible_to_Client__c == true
              && !oldMap.get(oMilestone.Id).NSP_Visible_to_Client__c) {
               newMilestoneIdSet.add(oMilestone.id); 
            }
            if(oMilestone.pse__Project__c != null && !oMilestone.NSP_Visible_to_Client__c == true
              && oldMap.get(oMilestone.Id).NSP_Visible_to_Client__c) {
               oldMilestoneIdSet.add(oMilestone.id); 
            }
        }
        if(!newMilestoneIdSet.isEmpty()){
        	NSP_MilestoneTaskSharing.mileStoneRecordSharing(newMilestoneIdSet,null);
        }
        if(!oldMilestoneIdSet.isEmpty()){
        	NSP_MilestoneTaskSharing.mileStoneRecordSharing(null,oldMilestoneIdSet);
        }
    }
           
    
    
    /**
    * Iterates throught the list of new pse__Milestone__c and passes the required attributes to other methods.
    * @param mNewMilestones Map of New milestones
    * @param mOldMilestones Map of Old milestones
    * @return void             
    *                
    */
    public void handleMilestoneCompletion(Map<Id,pse__Milestone__c> mNewMilestones,Map<Id,pse__Milestone__c> mOldMilestones){
        Set<Id> sMilestoneIds = new Set<Id>();
        List<pse__Milestone__c> listOfMilestone = new List<pse__Milestone__c> ();
         List<String> PROJECTTASKNAMES = label.NSP_Project_Task_Names.split(',');
        
        for(pse__Milestone__c oMilestone : mNewMilestones.values()){
            if(oMilestone.pse__Status__c == NSP_ServiceConstants.MILESTONESTATUSCOMPLETE && mOldMilestones.get(oMilestone.Id).pse__Status__c != NSP_ServiceConstants.MILESTONESTATUSCOMPLETE){
                sMilestoneIds.add(oMilestone.Id);
            }

            if((oMilestone.NSP_NumberOfCompletedProjectTask__c != mOldMilestones.get(oMilestone.id).NSP_NumberOfCompletedProjectTask__c)){
                listOfMilestone.add(oMilestone);
        }
        }
        if(sMilestoneIds.size() > 0){
            
            List<pse__Project_Task__c> lProjectTasks = new List<pse__Project_Task__c>([SELECT Id, pse__Milestone__c, pse__Status__c FROM pse__Project_Task__c WHERE pse__Milestone__c in: sMilestoneIds AND  
                                                                                       ( pse__Status__c !=: NSP_ServiceConstants.MILESTONESTATUSCOMPLETE AND pse__Status__c !=: NSP_ServiceConstants.PROJECT_TASK_CANCELLED) AND
                                                                                      Name NOT IN: PROJECTTASKNAMES]);
            for(pse__Project_Task__c oProjectTask  : lProjectTasks){
                mNewMilestones.get(oProjectTask.pse__Milestone__c).addError(System.Label.NSP_MilestoneTask_Completion_Error);
            }
        }

        if(!listOfMilestone.isEmpty()){
            updateStatusToComplete(listOfMilestone);
        }
    }

    /**
    * Description: This method update status to complete when number of project task = NSP_NumberOfCompletedProjectTask__c
                    NSP_NumberOfCompletedProjectTask__c gets updated when project task status update to complete/cancelled.
    * @param listOfMilestone List of milestones
    * @return void             
    *                
    */

    public void updateStatusToComplete(List<pse__Milestone__c> listOfMilestone){
        Map<Id, list<pse__Project_Task__c>> mapOfMilestoneAndListOfProjectTask = new Map<Id, list<pse__Project_Task__c>>();
        String PEOProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get('PEO_Project_Task').getRecordTypeId();
		List<String> PROJECTTASKNAMES = label.NSP_Project_Task_Names.split(',');
        for(pse__Project_Task__c pTask : [SELECT Id, Name, pse__Milestone__c FROM pse__Project_Task__c 
                                          WHERE pse__Milestone__c IN : listOfMilestone 
                                          and RecordTypeId = : PEOProjectTaskRecordTypeId
                                          and pse__Synchronize_Milestone_And_Task__c = false AND Name NOT IN: PROJECTTASKNAMES]){
            if(mapOfMilestoneAndListOfProjectTask.containsKey(pTask.pse__Milestone__c)){
                mapOfMilestoneAndListOfProjectTask.get(pTask.pse__Milestone__c).add(pTask);
            } else{
                mapOfMilestoneAndListOfProjectTask.put(pTask.pse__Milestone__c, new list<pse__Project_Task__c> {pTask});
            }
        }

        for(pse__Milestone__c mStone : listOfMilestone){
            if(mapOfMilestoneAndListOfProjectTask.get(mStone.id) != null){
                List<pse__Project_Task__c> listOfProjectTask = mapOfMilestoneAndListOfProjectTask.get(mStone.id);
                if(mStone.NSP_NumberOfCompletedProjectTask__c == listOfProjectTask.size() && mStone.pse__Status__c != NSP_ServiceConstants.MILESTONESTATUSCOMPLETE){
                    mStone.pse__Status__c = NSP_ServiceConstants.MILESTONESTATUSCOMPLETE;
                } else if(mStone.NSP_NumberOfCompletedProjectTask__c != listOfProjectTask.size()){
                    mStone.pse__Status__c = NSP_ServiceConstants.MILESTONESTATUSINPROGRESS;
                }
            }
        }
    }
    
     /**
    * Iterates throught the list of new pse__Milestone__c and passes the required attributes to other methods.
    * @param listOfMilestone Map of New milestones
    * Description: This method update assign the recordType to MileStone based on Project RecordType
    * @return void             
    *                
    */

    public void updateRecordType(List<pse__Milestone__c> listOfMilestone) {
    Set<Id> projectIds = new Set<Id>();
      List<pse__Milestone__c> projectMilestone = New List<pse__Milestone__c>();
        for(pse__Milestone__c eachMilestone : listOfMilestone){
           if( eachMilestone.pse__Project__c !=null){
             projectIds.add(eachMilestone.pse__Project__c);
             projectMilestone.add(eachMilestone);
           }
        }
        
        if(projectIds.size() >0)  {
            Map<Id,String> recordTypeMap = new Map<Id,String>();
             for ( pse__Proj__c eachProject : [SELECT Id,RecordType.Name FROM pse__Proj__c WHERE Id IN :projectIds AND RecordType.Name != null]){
                   recordTypeMap.put(eachProject.Id,eachProject.RecordType.Name);
             }
             assignRecordTypeId(recordTypeMap,projectMilestone);  
        }  
    }

    /**
    * Description: This method update assign the recordType to MileStone based on Project RecordType
    * @param  recordTypeMap Map of <Id,String> Project recordId & project RecordType Name
    * @param projectMilestone List of new pse__Milestone__c record
    * @return void             
    *                
    */
    
    public void assignRecordTypeId( Map<Id,String> recordTypeMap, List<pse__Milestone__c> projectMilestone){
         String peoMilstone = NSP_ServiceConstants.PEOMILSTONE;
         String bpsMilestone = NSP_ServiceConstants.BPSMILESTONE;

        if(recordTypeMap.size() >0){
            Id recordTypeIdBPS = SObjectType.pse__Milestone__c.getRecordTypeInfosByDeveloperName().get(bpsMilestone)?.getRecordTypeId();
            Id recordTypeIdPEO = SObjectType.pse__Milestone__c.getRecordTypeInfosByDeveloperName().get(peoMilstone)?.getRecordTypeId();
        for(pse__Milestone__c eachMilestone : projectMilestone){
                if(recordTypeMap.get(eachMilestone.pse__Project__c)?.indexOfIgnoreCase(peoMilstone.substring(0,3)) != -1 &&  recordTypeIdPEO !=null){
                eachMilestone.RecordTypeId = recordTypeIdPEO;
                } else
                if(recordTypeIdBPS !=null){
                eachMilestone.RecordTypeId = recordTypeIdBPS;
                }
            }
        }
    }
    
    /***********************************************************************************************
    * MethodName: updateTargetDate
    * Description : Update target and start date on the Milestone after insert for MM Implentation and FSO Implementation Projects 
    * Params:       List<pse__Milestone__c> milestoneList
    * Author: Nischay Jindal
    * ********************************************************************************************/
    public void updateTargetDate(List<pse__Milestone__c> milestoneList){
        Set<Id> projectIdSet = new Set<Id>();
        try{
            for(pse__Milestone__c milestone:milestoneList ){
                // checking if Milestone is related to Project
                if(milestone.pse__Project__c!=null){
                    // creating a Set of Milestone Projects
                    projectIdSet.add(milestone.pse__Project__c);
                }
            }
            // checking a Map of Project 
            Map<Id,pse__Proj__c> projectMap = new  Map<Id,pse__Proj__c>([Select Id, pse__Start_Date__c ,pse__End_Date__c FROM pse__Proj__c
                                                                        WHERE pse__Start_Date__c!=null AND pse__End_Date__c !=null AND Id IN:projectIdSet
                                                                        AND (TemplateName__c = :label.Middle_Market_Implementation_Project OR 
                                                                             TemplateName__c = :label.FSOImplementationProject)
                                                                         ]);
            // updating Milestone Start and Target Dates 
            for(pse__Milestone__c milestone:milestoneList ){
                // Updating Milestone Start Date and End Date with Project dates 
                if(milestone.pse__Project__c!=null && projectMap.containsKey(milestone.pse__Project__c)){
                    milestone.pse__Start_Date__c= projectMap.get(milestone.pse__Project__c).pse__Start_Date__c;
                    milestone.pse__Target_Date__c= projectMap.get(milestone.pse__Project__c).pse__End_Date__c;
                }
            }            
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_MilestoneTriggerHelper','updateTargetDate',ex.getMessage());
        }
    }

    /***********************************************************************************************
    * MethodName: checkDuplicateMilestone
    * Description : mark as duplicate if same milestone exists with Same name on Project
    * Params: List<pse__Milestone__c> milestoneList
    * Story: STY-02725
    * Author: Abhishek Kumar
    * ********************************************************************************************/
    public void checkDuplicateMilestone(List<pse__Milestone__c> milestoneList){
        Set<Id> projectIds = new Set<Id>();
        Map<Id,List<pse__Milestone__c>> mapOfProjectWithMilestone = new Map<Id,List<pse__Milestone__c>>();
        try{
            //iterate over milestone to store project ids of milestone
            for( pse__Milestone__c eachMilestone : milestoneList){
                projectIds.add(eachMilestone.pse__Project__c);
            }
            //get all milestone on Project    
            if (!projectIds.isEmpty()) {
                for(pse__Milestone__c eachRealtedMilestone : [SELECT Id, Name,pse__Project__c FROM pse__Milestone__c WHERE pse__Project__c IN: projectIds]){
                    //mpa milestone list with project id
                    if(mapOfProjectWithMilestone.get(eachRealtedMilestone.pse__Project__c) == null ){
                        mapOfProjectWithMilestone.put(eachRealtedMilestone.pse__Project__c , new List<pse__Milestone__c>{eachRealtedMilestone});
                    }
                    else{
                        mapOfProjectWithMilestone.get(eachRealtedMilestone.pse__Project__c).add(eachRealtedMilestone);
                    }
                }
            }
            //iterate over each milestones on project 
            for( pse__Milestone__c eachMilestone : milestoneList){
                if (mapOfProjectWithMilestone.get(eachMilestone.pse__Project__c) != null) {
                    for(pse__Milestone__c eachRelatedMilestone : mapOfProjectWithMilestone.get(eachMilestone.pse__Project__c)){
                        //mark as duplicate milestone if milestone already present with same name
                        if(eachRelatedMilestone.Name == eachMilestone.Name){
                            eachMilestone.NSP_isDuplicate__c = true;
                        }
                    }
                }
            }            
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_MilestoneTriggerHelper','checkDuplicateMilestone',ex.getMessage());
        }
    }
}