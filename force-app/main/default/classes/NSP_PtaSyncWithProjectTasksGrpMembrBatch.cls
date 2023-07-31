/**
* @description  :  Batch Class to Syn PTA Rec with Project Task's group member field value populated
* @date 11/10/2022
* Author : Abhishek Kumar
* Name : NSP_PtaSyncWithProjectTasksGrpMembrBatch
* Story : STY-02215
* Version : first iteration
*/
public class NSP_PtaSyncWithProjectTasksGrpMembrBatch implements Schedulable,Database.Batchable<SObject>{

    //start
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        Id retProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', NSP_ServiceConstants.PROJECT_RET_RECORDTYPE);

        //query to get Project Task Records with grp member value
        String query = 'SELECT Id, pse__Status__c, RecordTypeId,NSP_Group_Membership_for_Plan_Projects__c, pse__Project__c  FROM pse__Project_Task__c ';
        query += 'WHERE NSP_Group_Membership_for_Plan_Projects__c != null AND pse__Status__c != '+'\''+ NSP_ServiceConstants.PROJECT_TASK_CANCELLED +'\''+ ' AND pse__Status__c != '+'\''+ NSP_ServiceConstants.TASKCOMPLETE +'\''+ ' ' ;
        query += 'AND pse__Project__c != null AND pse__Project__r.pse__Is_Template__c = false AND pse__Project__r.pse__Project_Status__c != '+'\''+ NSP_ServiceConstants.PROJECTSTATUSCOMPLETED +'\''+'';
        query += 'AND ( pse__Project__r.TemplateName__c = '+'\''+ NSP_ServiceConstants.PROJECT_GENERAL_BUSINESS_TEMPLATE +'\''+ '';
        query += 'OR pse__Project__r.TemplateName__c = '+'\''+ NSP_ServiceConstants.PROJECT_NON_REIMBURSABLE +'\''+ '';
        query += 'OR pse__Project__r.TemplateName__c = '+'\''+ NSP_ServiceConstants.PROJECT_ORK_RELATED +'\''+ '';
        query += 'OR pse__Project__r.TemplateName__c = '+'\''+ NSP_ServiceConstants.PROJECT_STANDARD_PLAN_PROJECT +'\''+ ') ';
        query += 'AND pse__Project__r.pse__Project_Status__c != '+'\''+ NSP_ServiceConstants.PROJECTSTATUSCANCELLED +'\''+ ' AND pse__Project__r.pse__Project_Status__c != '+'\''+ NSP_ServiceConstants.LostProject +'\''+ ' ';
        query += 'AND pse__Project__r.RecordTypeId =: retProjectRecordTypeId ' ;

        return Database.getQueryLocator(query);
    }
    
    //Execute
    public void execute(Database.BatchableContext bc, List<pse__Project_Task__c> projectTaskList){
        
        try{
            Set<Id> projectTaskIds = new Set<Id>();
            Set<String> groupMemberValuesList = new Set<String>();
            Map<Id,Set<String>> mapOfProjectTaskIdWithGrpMemberVal = new Map<Id,Set<String>> ();
            List<pse__Project_Task_Assignment__c> listOfPtaToCreate = new List<pse__Project_Task_Assignment__c>();
			List<pse__Assignment__c> listOfAssignmentToCreate = new List<pse__Assignment__c>();
            Map<Id,List<Id>> mapOfProjectIdWithResource = new Map<Id,List<Id>>();
			Map<Id,Set<String>> mapOfProjectIdWithGrpMemberVal = new Map<Id,Set<String>> ();
			Map<Id,List<Id>> mapOfProjectTaskIdWithPtaResource = new Map<Id,List<Id>>();
			List<Id> prjIdList = new List<Id>();
			Map<Id, pse__Proj__c> projectNewMap = new Map<Id, pse__Proj__c>();
            
            //iterating over project task to get grp member values
            for( pse__Project_Task__c eachProjectTaskRec : projectTaskList ){

                //split grp member multi select value and map it with project task
				List<String> semiColonSeperatedGrpMemeberValList = eachProjectTaskRec.NSP_Group_Membership_for_Plan_Projects__c.split(';'); 
                Set<String> semiColonSeperatedGrpMemeberVal = new Set<String>();
				semiColonSeperatedGrpMemeberVal.addAll(semiColonSeperatedGrpMemeberValList);
                mapOfProjectTaskIdWithGrpMemberVal.put(eachProjectTaskRec.Id,semiColonSeperatedGrpMemeberVal);
                groupMemberValuesList.addAll(semiColonSeperatedGrpMemeberVal);   
                projectTaskIds.add(eachProjectTaskRec.Id);
				//get a List of project Id
				prjIdList.add(eachProjectTaskRec.pse__Project__c);
            }

			//iterating over project task to get grp member values
			for(pse__Project_Task__c eachProjectTaskRec : [SELECT id,pse__Project__c from pse__Project_Task__c WHERE ID IN:projectTaskIds]){
				if(eachProjectTaskRec.pse__Project__c != null){
					if(!mapOfProjectIdWithGrpMemberVal.containsKey(eachProjectTaskRec.pse__Project__c)){
						mapOfProjectIdWithGrpMemberVal.put(eachProjectTaskRec.pse__Project__c, mapOfProjectTaskIdWithGrpMemberVal.get(eachProjectTaskRec.ID));
					}
					else{
						mapOfProjectIdWithGrpMemberVal.get(eachProjectTaskRec.pse__Project__c).addAll(mapOfProjectTaskIdWithGrpMemberVal.get(eachProjectTaskRec.ID));
					}
				}
			}
			
             //Creating Map of project Id and Project
			projectNewMap = new Map<Id, pse__Proj__c>([SELECT Id, pse__Start_Date__c, pse__End_Date__c from pse__Proj__c WHERE id IN :prjIdList]);
			Map<Id, pse__Schedule__c> projectWithScheduleMap = new Map<Id, pse__Schedule__c>(createSchedule(projectNewMap));
			
            //getting map of group member val with contact list
            Map<String,List<Id>> mapOfGroupMemberValWithContactList = getUserContactWithSameGroupMemberValue(groupMemberValuesList) ;
			
			//iterating over Assignments to map Project with Resource
			for( pse__Assignment__c eachAssignment : [ SELECT Id, pse__Resource__c ,pse__Project__c 
                                                                FROM pse__Assignment__c 
                                                                WHERE pse__Project__c IN: prjIdList] ){
                if (mapOfProjectIdWithResource.get( eachAssignment.pse__Project__c ) == null) {
                    mapOfProjectIdWithResource.put( eachAssignment.pse__Project__c , new List<String>{eachAssignment.pse__Resource__c} );
                }
                else{
                    mapOfProjectIdWithResource.get( eachAssignment.pse__Project__c ).add(eachAssignment.pse__Resource__c);
                }
            }
			//iterating over Project to create list of Assignments to be created
			for(Id projectId: mapOfProjectIdWithGrpMemberVal.keySet()){
                //over Project Task group member values
                for( String eachgrpMemberVal:  mapOfProjectIdWithGrpMemberVal.get(projectId)){
                    //getting list of PTAs to be created
                    listOfAssignmentToCreate.addAll(getListOfAssignmentToCreate(mapOfProjectIdWithResource,
                                                                    mapOfGroupMemberValWithContactList,
                                                                    eachgrpMemberVal,
                                                                    projectId, projectWithScheduleMap));
                }
            }
			
			//iterating over PTs to map Project Task with PT Resource
            for( pse__Project_Task_Assignment__c eachPtaRec : [ SELECT Id, pse__Resource__c ,pse__Project_Task__c 
                                                                FROM pse__Project_Task_Assignment__c 
                                                                WHERE pse__Project_Task__c IN: projectTaskIds] ){
                if (mapOfProjectTaskIdWithPtaResource.get( eachPtaRec.pse__Project_Task__c ) == null) {
                    mapOfProjectTaskIdWithPtaResource.put( eachPtaRec.pse__Project_Task__c , new List<String>{eachPtaRec.pse__Resource__c} );
                }
                else{
                    mapOfProjectTaskIdWithPtaResource.get( eachPtaRec.pse__Project_Task__c ).add(eachPtaRec.pse__Resource__c);
                }
            }

            //iterating over Project Task to create list of PTA to be created
            for(Id projectTaskId: mapOfProjectTaskIdWithGrpMemberVal.keySet()){
                //over Project Task group member values
                for( String eachgrpMemberVal:  mapOfProjectTaskIdWithGrpMemberVal.get(projectTaskId)){
                    //getting list of PTAs to be created
                    listOfPtaToCreate.addAll(getListOfPtaToCreate(mapOfProjectTaskIdWithPtaResource,
                                                                    mapOfGroupMemberValWithContactList,
                                                                    eachgrpMemberVal,
                                                                    projectTaskId));
                }
            }
			
			//Create Assignment if List is not empty
            if( !listOfAssignmentToCreate.isEmpty() ){
                Database.insert(listOfAssignmentToCreate);
            }

            //Create PTA if List is not empty
            if( !listOfPtaToCreate.isEmpty() ){
                Database.insert(listOfPtaToCreate);
            }
            
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_PtaSyncWithProjectTasksGrpMembrBatch', 'ExecuteMethod', ex.getMessage());
        }
    }

    //finish
    public void finish(Database.BatchableContext bc){
        
    }
    public void execute(SchedulableContext scon) {
        //Executes Batch
        Database.executeBatch(new NSP_PtaSyncWithProjectTasksGrpMembrBatch(),200);
    }

    /***********************************************************************************************
    * MethodName: getUserContactWithSameGroupMemberValue
    * Description : gets list of user contact mapped with group member value
    * Story : STY-02215
    * Author :Abhishek Kumar 
    * Params: List<pse__Project_Task__c> groupMemberValuesList
    * ********************************************************************************************/ 
    public static Map<String,List<Id>> getUserContactWithSameGroupMemberValue(Set<String> groupMemberValuesList ){
        Map<String,List<Id>> mapOfGroupMemberValWithContactList = new Map<String,List<Id>>();
        try{
            //iterate over contact where grp member value is populated and in groupMemberValuesList
            for( Contact eachContact : [SELECT Id,Name,pse__Salesforce_User__c,pse__Salesforce_User__r.NSP_Group_Member_For_Plan_Projects__c
                                        FROM Contact 
                                        WHERE pse__Salesforce_User__c != null
                                        AND pse__Salesforce_User__r.NSP_Group_Member_For_Plan_Projects__c != null
                                        AND pse__Salesforce_User__r.NSP_Group_Member_For_Plan_Projects__c IN: groupMemberValuesList] ){

                //map group member val with contact list
                if( mapOfGroupMemberValWithContactList.get(eachContact.pse__Salesforce_User__r.NSP_Group_Member_For_Plan_Projects__c) == null){
                    mapOfGroupMemberValWithContactList.put(eachContact.pse__Salesforce_User__r.NSP_Group_Member_For_Plan_Projects__c, 
                                                            new List<Id>{eachContact.Id});
                }
                else{
                    mapOfGroupMemberValWithContactList.get(eachContact.pse__Salesforce_User__r.NSP_Group_Member_For_Plan_Projects__c).add(eachContact.Id);
                }
            }
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_PtaSyncWithProjectTasksGrpMembrBatch', 'getUserContactWithSameGroupMemberValue', ex.getMessage());
        }

        return mapOfGroupMemberValWithContactList;
    }

    /***********************************************************************************************
    * MethodName: getListOfAssignmentToCreate
    * Params: Map<Id,List<Id>> mapOfProjectIdWithGrpMemberVal
    * Params: Map<String,List<Id>> mapOfGroupMemberValWithContactList
    * Params: String groupMembershipVal
    * Params: Id projectTaskId
    * ********************************************************************************************/ 
    public static List<pse__Assignment__c> getListOfAssignmentToCreate(Map<Id,List<Id>> mapOfProjectIdWithResource ,
                                                            Map<String,List<Id>> mapOfGroupMemberValWithContactList ,
                                                            String groupMembershipVal ,
                                                            Id projectId, Map<Id, pse__Schedule__c> projectWithScheduleMap){
        List<pse__Assignment__c> listOfAssignToBeCreated = new List<pse__Assignment__c>();
        try{
            //iterate over contact with groupMembershipVal
            for( Id eachContactRec : mapOfGroupMemberValWithContactList.get(groupMembershipVal) ){
                //check if project does not contain Assignment with this contact
                if( mapOfProjectIdWithResource.get(projectId) == null || !mapOfProjectIdWithResource.get(projectId).contains( eachContactRec ) ){
                    //initialize new Assignment Rec
                    pse__Assignment__c newAssRec = new pse__Assignment__c();
                    newAssRec.pse__Resource__c = eachContactRec;
                    newAssRec.pse__Project__c = projectId;
					newAssRec.pse__Schedule__c = projectWithScheduleMap.get(projectId).Id;
					newAssRec.pse__Bill_Rate__c = 0.0000;
                    listOfAssignToBeCreated.add(newAssRec);
                }
            }
        }catch (Exception ex) {
        }
        return listOfAssignToBeCreated;
    }
	
    /***********************************************************************************************
    * MethodName: getListOfPtaToCreate
    * Description : returns list of PTAs to be created
    * Story : STY-02215
    * Author :Abhishek Kumar 
    * Params: Map<Id,List<Id>> mapOfProjectTaskIdWithPtaResource
    * Params: Map<String,List<Id>> mapOfGroupMemberValWithContactList
    * Params: String groupMembershipVal
    * Params: Id projectTaskId
    * ********************************************************************************************/ 
    public static List<pse__Project_Task_Assignment__c> getListOfPtaToCreate(Map<Id,List<Id>> mapOfProjectTaskIdWithPtaResource ,
                                                            Map<String,List<Id>> mapOfGroupMemberValWithContactList ,
                                                            String groupMembershipVal ,
                                                            Id projectTaskId){
        List<pse__Project_Task_Assignment__c> listOfPtaToBeCreated = new List<pse__Project_Task_Assignment__c>();
        try{
            //iterate over contact with groupMembershipVal
            for( Id eachContactRec : mapOfGroupMemberValWithContactList.get(groupMembershipVal) ){
                //check if project does not contain PTA with this contact
                if( mapOfProjectTaskIdWithPtaResource.get(projectTaskId) == null || !mapOfProjectTaskIdWithPtaResource.get(projectTaskId).contains( eachContactRec ) ){
                    //initialize new PTA Rec
                    pse__Project_Task_Assignment__c newPtaRec = new pse__Project_Task_Assignment__c();
                    newPtaRec.pse__Resource__c = eachContactRec;
                    newPtaRec.pse__Project_Task__c = projectTaskId;
                    listOfPtaToBeCreated.add(newPtaRec);
                }
            }
        }catch (Exception ex) {
        }
        return listOfPtaToBeCreated;
    }
	

	/**
    * method to create schedule for the assignments.
    * @param Map<Id, Id> userWithContactMap, Map<Id, pse__Proj__c> projectNewMap  
    * @return Map<Id, pse__Schedule__c> projectWithScheduleMap            
    */
    public Map<Id, pse__Schedule__c> createSchedule(Map<Id, pse__Proj__c> projectNewMap){
        Map<Id, pse__Schedule__c> projectWithScheduleMap = new Map<Id, pse__Schedule__c>();
        for(pse__Proj__c project : projectNewMap.values()){ 
            pse__Schedule__c sch = new pse__Schedule__c();
            sch.pse__Start_Date__c = project.pse__Start_Date__c;
            sch.pse__End_Date__c = project.pse__End_Date__c;
            projectWithScheduleMap.put(project.Id, sch);
        }
        if(!projectWithScheduleMap.isEmpty()){
            insert projectWithScheduleMap.values();
        }
		return projectWithScheduleMap;
    }
}