/**
Apex Class Name      :  NSP_ProjtaskTriggerServiceHelperUpdate
Version              :  1.0                                                                          
Created Date         :  7/6/2022  
Function             :  Represents the new project task trigger helper which handles all the logic for update scenario.
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Bindu                      7/9/2022             First Iteration
*/

public class NSP_ProjtaskTriggerServiceHelperUpdate {
    /**
        * Iterates throught the list of new pse__Project_Task__c and passes the required attributes to other methods.
        * @param projectTaskList List of New project. 
        * @param projectTaskOldMap Map of Old project.   
        * @return void             
        *                
        */
        private static Id ipFSORecordTypeId = SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.FSOProfile).getRecordTypeId();
        private static Id ipMMRecordTypeId = SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.MMProfile).getRecordTypeId();
        private static Map<Id, List<String>> mapOfGarnishEmployees = new Map<Id, List<String>>();
    	private static Map<Id, List<String>> mapOfLeviesEmployees = new Map<Id, List<String>>();
    
        public static void afterUpdateProjectTask(List<pse__Project_Task__c> projectTaskList, Map<Id, pse__Project_Task__c> projectTaskOldMap){
            try{
                Id recordTypeIdPEO = SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE)?.getRecordTypeId();
                
                
                
                List<Implementation_Profile__c> updateIpList=new List<Implementation_Profile__c>();
                Map<Id, List<String>> completedProjectTaskMap = new Map<Id, List<String>>();
                Map<Id, List<String>> completedGarnishTaskMap = new Map<Id, List<String>>();
                    Map<Id, List<String>> completedleviesTaskMap = new Map<Id, List<String>>();
                //iterating project task list
                for(pse__Project_Task__c projTask:projectTaskList){
                    //AS PART OF STY-001959 -update IP when project task is completed for FSO IP
                    if(projTask.recordTypeId==recordTypeIdPEO && projTask.pse__Status__c==NSP_ServiceConstants.TASKCOMPLETE && projectTaskOldMap.get(projTask.Id).pse__Status__c!=NSP_ServiceConstants.TASKCOMPLETE){
                    //checking if project task name is equal to certificate
                        if(projTask.Name==NSP_ServiceConstants.CERTIFICATE){
                            //creating list which store completed task records
                            List<String> completedTaskList = completedProjectTaskMap.get(projTask.pse__Project__c);
                            // checking if completed task list is null or not
                            if(completedTaskList==null){
                                completedTaskList =new List<String>();
                                
                            }
                            completedTaskList.add(NSP_ServiceConstants.CERTIFICATE);
                            completedProjectTaskMap.put(projTask.pse__Project__c,completedTaskList);
                            
                        }
                        //checking if project task name is equal to EEO
                        if(projTask.Name==NSP_ServiceConstants.EEO ){
                            // creating list which stores complted task records
                            List<String> completedTaskList = completedProjectTaskMap.get(projTask.pse__Project__c);
                            //checking if completed task list is null or not
                            if(completedTaskList==null){
                                completedTaskList =new List<String>();
                                
                            }
                            completedTaskList.add(NSP_ServiceConstants.EEO);
                            completedProjectTaskMap.put(projTask.pse__Project__c,completedTaskList);
                            
                        }
                        //checking if project task name is equal to PTOSICKLEAVE
                        if(projTask.Name==NSP_ServiceConstants.PTOSICKLEAVE){
                            // creating list which stores complted task records
                            List<String> completedTaskList = completedProjectTaskMap.get(projTask.pse__Project__c);
                            //checking if completed task list is null or not
                            if(completedTaskList==null){
                                completedTaskList =new List<String>();
                                
                            }
                            completedTaskList.add(NSP_ServiceConstants.PTOSICKLEAVE);
                            completedProjectTaskMap.put(projTask.pse__Project__c,completedTaskList);
                            
                        }
                        //checking if project task name is equal to Primingdata
                        if(projTask.Name==NSP_ServiceConstants.PRIMINGDATA){
                            //creating list which store completed task records
                            List<String> completedTaskList = completedProjectTaskMap.get(projTask.pse__Project__c);
                            //checking if completed task list is null or not
                            if(completedTaskList==null){
                                completedTaskList =new List<String>();
                                
                            }
                            completedTaskList.add(NSP_ServiceConstants.PRIMINGDATA);
                            completedProjectTaskMap.put(projTask.pse__Project__c,completedTaskList);
                            
                        }
                        //checking if project task name is CPR 
                        if(projTask.Name==NSP_ServiceConstants.CPR){
                            //creating list which stores completed task records
                            List<String> completedTaskList = completedProjectTaskMap.get(projTask.pse__Project__c);
                            //checking if completed task list is null or not 
                            if(completedTaskList==null){
                                completedTaskList =new List<String>();
                                
                            }
                            completedTaskList.add(NSP_ServiceConstants.CPR);
                            completedProjectTaskMap.put(projTask.pse__Project__c,completedTaskList);
                            
                        }
                        
                        //AS PART OF STY-02192 -update IP when project task is completed for MM IP
                        //checking if project task name is SECTIONQUESTIONNAIRE
                        if(projTask.Name==NSP_ServiceConstants.SECTIONQUESTIONNAIRE){
                            //creating list which stores completed task records
                            List<String> completedTaskList = completedProjectTaskMap.get(projTask.pse__Project__c);
                            //checking if completed task list is null or not 
                            if(completedTaskList==null){
                                completedTaskList =new List<String>();
                                
                            }
                            completedTaskList.add(NSP_ServiceConstants.SECTIONQUESTIONNAIRE);
                            completedProjectTaskMap.put(projTask.pse__Project__c,completedTaskList);
                            
                        }
                        //checking if project task name is Fein Document
                        if(projTask.Name==NSP_ServiceConstants.FEINDOCUMENT){
                            //creating list which stores completed task records
                            List<String> completedTaskList = completedProjectTaskMap.get(projTask.pse__Project__c);
                            //checking if completed task list is null or not 
                            if(completedTaskList==null){
                                completedTaskList =new List<String>();
                                
                            }
                            completedTaskList.add(NSP_ServiceConstants.FEINDOCUMENT);
                            completedProjectTaskMap.put(projTask.pse__Project__c,completedTaskList);
                            
                        }
                        if(projTask.Name.endsWith(NSP_ServiceConstants.GARNISHDOC)){
                            List<String> completedTaskList = completedGarnishTaskMap.get(projTask.pse__Project__c);
                            //checking if completed task list is null or not 
                            if(completedTaskList==null){
                                completedTaskList =new List<String>();
                            }
                            completedTaskList.add(projTask.Name);
                            completedGarnishTaskMap.put(projTask.pse__Project__c,completedTaskList);
                    }
                    if(projTask.Name.endsWith(NSP_ServiceConstants.LEVYDOC)){
                            List<String> completedTaskList = completedleviesTaskMap.get(projTask.pse__Project__c);
                            //checking if completed task list is null or not 
                            if(completedTaskList==null){
                                completedTaskList =new List<String>();
                            }
                            completedTaskList.add(projTask.Name);
                            completedleviesTaskMap.put(projTask.pse__Project__c,completedTaskList);
                        }
                }
                }
                        
                        
                        
        
                //checking if completed Project task map size is greater than zero
                if(completedProjectTaskMap.size()>0 || completedGarnishTaskMap.size()>0 || completedleviesTaskMap.size()>0){
                    Set<Id> setOfCompleteIps = new Set<Id>();
                    setOfCompleteIps.addAll(completedProjectTaskMap.keyset());
                    setOfCompleteIps.addAll(completedGarnishTaskMap.keyset());
                    setOfCompleteIps.addAll(completedleviesTaskMap.keyset());
                    map<Id,Implementation_Profile__c> mapOfIpRecords=new Map<Id,Implementation_Profile__c>([SELECT Id, NSP_Project__c, Gotten_Cvrg_Cert_Gen_Liability_Auto__c,Gave_copy_of_PTO_sick_leave_other_policy__c,NSP_Documents_garnishments__c,
                                                                                                        NSP_Documents_Collected_Leviesd__c,Recent_Payroll_Register_Collected__c,Received_Section_125_Questionnaire__c,RecordTypeId,NSP_Employee_Names_List_garnishments__c,
                                                                                                        NSP_List_Employee_Names_Levies__c,Has_FEIN_documentation_been_collected__c, Employee_Data_Collection_EDC_collected__c FROM  Implementation_Profile__c WHERE NSP_Project__c IN :setOfCompleteIps]);
                
            
                    for(Implementation_Profile__c ip:mapOfIpRecords.values()){
                        if(completedProjectTaskMap.size()>0){
                    if(completedProjectTaskMap.get(ip.NSP_Project__c).contains(NSP_ServiceConstants.CERTIFICATE) && ip.Gotten_Cvrg_Cert_Gen_Liability_Auto__c==NSP_ServiceConstants.REQUESTED){
                        ip.Gotten_Cvrg_Cert_Gen_Liability_Auto__c=NSP_ServiceConstants.RECEIVED;
                    }
                    
                    if((completedProjectTaskMap.get(ip.NSP_Project__c).contains(NSP_ServiceConstants.EEO) || completedProjectTaskMap.get(ip.NSP_Project__c).contains(NSP_ServiceConstants.PTOSICKLEAVE) ) && (ip.Gave_copy_of_PTO_sick_leave_other_policy__c==NSP_ServiceConstants.REQUESTED ||
                                                                                                                    ip.Gave_copy_of_PTO_sick_leave_other_policy__c==NSP_ServiceConstants.NO)){
                        ip.Gave_copy_of_PTO_sick_leave_other_policy__c=NSP_ServiceConstants.YES;
                    }
                    if(completedProjectTaskMap.get(ip.NSP_Project__c).contains(NSP_ServiceConstants.PRIMINGDATA) && (ip.Employee_Data_Collection_EDC_collected__c==NSP_ServiceConstants.NO ||
                                                                                                                    ip.Employee_Data_Collection_EDC_collected__c==NSP_ServiceConstants.NOTCOLLECTED)){
                        ip.Employee_Data_Collection_EDC_collected__c=NSP_ServiceConstants.YES;
                    }
                    if(completedProjectTaskMap.get(ip.NSP_Project__c).contains(NSP_ServiceConstants.CPR) && (ip.Recent_Payroll_Register_Collected__c==NSP_ServiceConstants.NO ||
                                                                                                                    ip.Recent_Payroll_Register_Collected__c==NSP_ServiceConstants.NOTCOLLECTED)){
                        ip.Recent_Payroll_Register_Collected__c=NSP_ServiceConstants.YES;
                    }
                    
                    //STY-2192 -WHEN TASK IS COMPLETE UPDATE RELEVANT MM IP
                    if(completedProjectTaskMap.get(ip.NSP_Project__c).contains(NSP_ServiceConstants.SECTIONQUESTIONNAIRE) && ip.RecordTypeId==ipMMRecordTypeId && (ip.Received_Section_125_Questionnaire__c==NSP_ServiceConstants.NO
                                                                                                                    || ip.Received_Section_125_Questionnaire__c==NSP_ServiceConstants.NOTCOLLECTED)){
                        ip.Received_Section_125_Questionnaire__c=NSP_ServiceConstants.YES;
                    }
                    if(completedProjectTaskMap.get(ip.NSP_Project__c).contains(NSP_ServiceConstants.FEINDOCUMENT) && ip.RecordTypeId==ipMMRecordTypeId && (ip.Has_FEIN_documentation_been_collected__c==NSP_ServiceConstants.NO
                                                                                                                    || ip.Has_FEIN_documentation_been_collected__c==NSP_ServiceConstants.NOTCOLLECTED)){
                        ip.Has_FEIN_documentation_been_collected__c=NSP_ServiceConstants.YES;
                    }
                    
                    updateIpList.add(ip);
                    }
                    if(completedGarnishTaskMap.size()>0 && completedGarnishTaskMap.get(ip.NSP_Project__c)!=null && ip.RecordTypeId==ipFSORecordTypeId &&
                        ip.NSP_Employee_Names_List_garnishments__c!=null){
                        List<String> employeeList = ip.NSP_Employee_Names_List_garnishments__c.split(',');
                        List<String> completedTaskList = mapOfGarnishEmployees.get(ip.id);
                        for(String garnish :completedGarnishTaskMap.get(ip.NSP_Project__c) ){
                            if(employeeList.contains(garnish.substring(0,garnish.length()-26))){
                                if(completedTaskList==null){
                                    completedTaskList =new List<String>();
                                }
                                completedTaskList.add(garnish.substring(0,garnish.length()-26));
                                mapOfGarnishEmployees.put(ip.id, completedTaskList);
                            }
                        }
                    }
                    
                    if(completedleviesTaskMap.size()>0 && completedleviesTaskMap.get(ip.NSP_Project__c)!=null && ip.RecordTypeId==ipFSORecordTypeId &&
                        ip.NSP_List_Employee_Names_Levies__c!=null){
                        List<String> employeeList = ip.NSP_List_Employee_Names_Levies__c.split(',');
                        List<String> completedTaskList = mapOfLeviesEmployees.get(ip.id);
                        for(String levies :completedleviesTaskMap.get(ip.NSP_Project__c) ){
                            if(employeeList.contains(levies.substring(0,levies.length()-19))){
                                if(completedTaskList==null){
                                    completedTaskList =new List<String>();
                                }
                                completedTaskList.add(levies.substring(0,levies.length()-19));
                                mapOfLeviesEmployees.put(ip.id, completedTaskList);
                            }
                        }
                    }
                    
        
                
            
        
                    }
                }
                //checking updated Ip list is empty or not
                if(!updateIpList.isEmpty()){
                    //updating IP list
                    List<Database.SaveResult> results =  Database.update( updateIpList , false );
                    NSP_ErrorLogHandler.logSaveResultsException('NSP_ProjtaskTriggerServiceHelperUpdate', 'afterUpdateProjectTask', results );
            }
            //update Implementation Employee Data
            updateIPEmployeeData(mapOfGarnishEmployees,mapOfLeviesEmployees );
        }catch(Exception ex ){
               NSP_ErrorLogHandler.logSaveException('NSP_ProjtaskTriggerServiceHelperUpdate', 'afterUpdateProjectTask', ex.getMessage());
        }
    }
        
        
        public static void updateSubtaskStatus(Map<Id,pse__Project_Task__c> newMapProjecttasks, Map<Id,pse__Project_Task__c> oldMapProjecttasks ){
            
            //as part of STY-02170
            Set<Id> parentTaskIDs=new Set<Id>();
            //iterating new map project tasks
             for(pse__Project_Task__c pt :newMapProjecttasks.values()){
                //checking if parent task is equal to null or not
                 if(pt.pse__Parent_Task__c!=null){
                        parentTaskIDs.add(pt.pse__Parent_Task__c); 
                    }
                /*if(pt.Name==NSP_ServiceConstants.TESTPAYROLL || pt.Name==NSP_ServiceConstants.FIRSTPAYROLL){
                   parentTaskIDs.add(pt.Id); 
                } */            
            }
            //checking parent task Ids is empty or not
            if(!parentTaskIDs.isEmpty()){
                //creating list which stores complted task records
                List<pse__Project_Task__c> completedTask=getAllSubTasksCompletedTasks(parentTaskIDs); 
                //checking if completed task is empty or not
                if(!completedTask.isEmpty()){

                    database.update(completedTask, false);
                } 
            }
        }
        
        private static List<pse__Project_Task__c> getAllSubTasksCompletedTasks(Set<Id> taskIds){
            //mark parent task as complete when all sub task is complete
            List<pse__Project_Task__c> taskList=new List<pse__Project_Task__c>();
            Map<Id, pse__Project_Task__c> parentIdChildIncompleteTaskMap = new Map<Id, pse__Project_Task__c>();
            Map<Id, pse__Project_Task__c> parentIdChildCompleteTaskMap = new Map<Id, pse__Project_Task__c>();
            for(Id taskId : taskIds){
                parentIdChildIncompleteTaskMap.put(taskId, null);
            }
            //Iterating subtask list
            for(pse__Project_Task__c subtask : [Select Id , pse__Parent_Task__c ,pse__Status__c 
                                              FROM pse__Project_Task__c WHERE pse__Parent_Task__c =: taskIds AND
                                              pse__Parent_Task__r.pse__Status__c !=:NSP_ServiceConstants.TASKCOMPLETE]){
                                                  
            if(subtask.pse__Status__c!=NSP_ServiceConstants.TASKCOMPLETE){
                 parentIdChildIncompleteTaskMap.put(subtask.pse__Parent_Task__c, subtask);
            }
            if(subtask.pse__Status__c == NSP_ServiceConstants.TASKCOMPLETE ){
                parentIdChildCompleteTaskMap.put(subtask.pse__Parent_Task__c, subtask);
            }              
            }
            for(Id taskId : taskIds){
                if(parentIdChildIncompleteTaskMap.get(taskId) == null){
                    pse__Project_Task__c parentTask = new pse__Project_Task__c();
                    parentTask.pse__Status__c=NSP_ServiceConstants.TASKCOMPLETE;
                    parentTask.Id=taskId;
                    taskList.add(parentTask);
                } else if(parentIdChildCompleteTaskMap.get(taskId) != null){
                    pse__Project_Task__c parentTask = new pse__Project_Task__c();
                    parentTask.pse__Status__c=NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
                    parentTask.Id=taskId;
                    taskList.add(parentTask);
                }
            }
             //returning task list
             return taskList;        
        }

        public static void updateIPEmployeeData(map<Id, List<String>> mapOfGarnishEmployees, map<Id, List<String>> mapOfLeviesEmployees){
            try{
                List<NSP_Employee_Data__c> empDataToUpdate = new List <NSP_Employee_Data__c>();
                Set<Id> mapOfAllEmployees = new Set<Id>();
                if(mapOfGarnishEmployees.size()>0){
                     mapOfAllEmployees.addAll(mapOfGarnishEmployees.keyset());
                }
                if(mapOfLeviesEmployees.size()>0){
                     mapOfAllEmployees.addAll(mapOfLeviesEmployees.keyset());
                }
                if(!mapOfAllEmployees.isEmpty()){
                    for(NSP_Employee_Data__c empData : [SELECT Id,NSP_Parent_Field_API_Name__c,NSP_Name__c,NSP_Documents__c,NSP_Implementation_Profile__c FROM
                                                        NSP_Employee_Data__c WHERE NSP_Implementation_Profile__c IN :mapOfAllEmployees]){
                                                            if(mapOfGarnishEmployees.size()>0 && empData.NSP_Parent_Field_API_Name__c==NSP_ServiceConstants.GARNISH_API_NAME
                                                               && mapOfGarnishEmployees.get(empData.NSP_Implementation_Profile__c).contains(empData.NSP_Name__c) ){
                                                                   empData.NSP_Documents__c=NSP_ServiceConstants.COLLECTED;
                                                                   empDataToUpdate.add(empData);
                                                            }
                                                            if(mapOfLeviesEmployees.size()>0 && empData.NSP_Parent_Field_API_Name__c==NSP_ServiceConstants.LEVIES_API_NAME
                                                               && mapOfLeviesEmployees.get(empData.NSP_Implementation_Profile__c).contains(empData.NSP_Name__c) ){
                                                                   empData.NSP_Documents__c=NSP_ServiceConstants.COLLECTED;
                                                                   empDataToUpdate.add(empData);
                                                            }
                                                            
                    }
                }
                if(!empDataToUpdate.isEmpty()){
                     List<Database.SaveResult> results =  Database.update( empDataToUpdate , false );
                     NSP_ErrorLogHandler.logSaveResultsException('NSP_ProjtaskTriggerServiceHelperUpdate', 'updateIPEmployeeData', results );
                }
            }catch(Exception ex ){
                        NSP_ErrorLogHandler.logSaveException('NSP_ProjtaskTriggerServiceHelperUpdate', 'updateIPEmployeeData', ex.getMessage());
            }
         }
         
         
     
    }