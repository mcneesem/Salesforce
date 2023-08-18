/**
* Represents the project trigger helper which handles all the logic.
*/
public class NSP_ProjectTasksTriggerHelper {
// test w/ NSP_ProjectTasksTriggerHelperTest (81%)
    
    private static final String HUNDRED_PERCENT =  '100%';
    private static final String NSP_PROJECTTASKSTRIGGERHELPER = 'NSP_ProjectTasksTriggerHelper';
    private static final string SYS_ADMIN = 'System Administrator';
    /**
    * Iterates throught the list of new pse__Project_Task__c and passes the required attributes to other methods.
    * @param projectTaskNewMap Map of New project. 
    * @param projecttaskOldMap Map of Old project.   
    * @return void             
    *                
    */
    public void updateProjectTaskFields(List<pse__Project_Task__c> projectTaskList){ 
        Map<Id, List<pse__Project_Task__c>> projectTaskMap = new Map<Id, List<pse__Project_Task__c>>();
        Map<Id, pse__Proj__c> parentProjectMap  = new  Map<Id, pse__Proj__c>();
        Map<Id, Id> mapOfparentTaskIdAndMilestoneId = new Map<Id, Id>();
        Set<Id> setOfParentProjectTask = new Set<Id>();
        
        for(pse__Project_Task__c projectTask : projectTaskList){
            if(projectTask.pse__Parent_Task__c != null){
                setOfParentProjectTask.add(projectTask.pse__Parent_Task__c);
            }
            
            // STY-03891
            if(projectTask.NSP_Create_Work_Order__c == true && String.isNotBlank(projectTask.NSP_Dispatch_Region__c)){
                projectTask.pse__Status__c = 'Unscheduled';
            }


            if(projectTask.pse__Project__c != null){
                if(!projectTaskMap.containsKey(projectTask.pse__Project__c)){
                    projectTaskMap.put(projectTask.pse__Project__c, new List<pse__Project_Task__c>());
                } 
                projectTaskMap.get(projectTask.pse__Project__c).add(projectTask);   
            } 

            // UPDATE Started and Completed Details
            if(projectTask.pse__Status__c == NSP_ServiceConstants.PROJECTSTATUSCOMPLETED){
                projectTask.pse__Actual_End_Date_Time__c = Datetime.now();
                projectTask.pse__Completed__c = true;
            }else{
                projectTask.pse__Completed__c = false;
            }
            if(String.isBlank(projectTask.pse__Status__c) || projectTask.pse__Status__c == NSP_ServiceConstants.PROJECT_TASK_CANCELLED || projectTask.pse__Status__c == NSP_ServiceConstants.PROJECTSTATUSNOTSTARTED ){
                projectTask.pse__Started__c = false;
            }else{
                projectTask.pse__Actual_Start_Date_Time__c = Datetime.now();
                projectTask.pse__Started__c = true;
            }
        }    

        if(!setOfParentProjectTask.isEmpty()){
            for(pse__Project_Task__c parentTask : [SELECT pse__Milestone__c FROM pse__Project_Task__c WHERE ID IN : setOfParentProjectTask]){
                mapOfparentTaskIdAndMilestoneId.put(parentTask.id, parentTask.pse__Milestone__c);
            }
    
            for(pse__Project_Task__c pTask : projectTaskList){
                if(pTask.pse__Parent_Task__c != null){
                    pTask.pse__Milestone__c = mapOfparentTaskIdAndMilestoneId.get(pTask.pse__Parent_Task__c);
                }
            }
        }

        if(projectTaskMap.size() > 0){
            parentProjectMap  = new  Map<Id, pse__Proj__c>( [Select Id, pse__Is_Template__c 
                                                             FROM pse__Proj__c 
                                                             WHERE pse__Is_Template__c = True AND 
                                                             ID In: projectTaskMap.keySet()]);
        }
         
       if(!parentProjectMap.isEmpty()){
            for(pse__Proj__c eachProj : parentProjectMap.values() ){
                if( projectTaskMap.get(eachProj.Id) != null){
                    for(pse__Project_Task__c projectTask : projectTaskMap.get(eachProj.Id)){
                            projectTask.NSP_Template_Generated__c = True; 
                    }
                }
            }
        } 
    }

    /**
    * Update Project Task Completed and Started checkbox based on its Status.
    * @param lProjectTasks Map of New project Tasks. 
    * @param mOldProjecTasks Map of Old project Tasks. 
    * @return void
    *                
    */
    public void updateStartedorCompleted(List<pse__Project_Task__c> lProjectTasks,Map<Id, pse__Project_Task__c> mOldProjecTasks){
        Map<Id,pse__Project_Task__c> mCompletedTasks = new Map<Id,pse__Project_Task__c>();
        for(pse__Project_Task__c oProjectTask: lProjectTasks){
            String oldStatus = mOldProjecTasks.get(oProjectTask.Id).pse__Status__c;
            if(oProjectTask.pse__Status__c == NSP_ServiceConstants.PROJECTSTATUSCOMPLETED && oProjectTask.pse__Status__c != oldStatus){
                oProjectTask.pse__Actual_End_Date_Time__c = Datetime.now();
                oProjectTask.pse__Completed__c = true;
                mCompletedTasks.put(oProjectTask.Id,oProjectTask);
            }else if(oProjectTask.pse__Status__c != NSP_ServiceConstants.PROJECTSTATUSCOMPLETED){
                oProjectTask.pse__Completed__c = false;
            }
            if(String.isBlank(oProjectTask.pse__Status__c) || oProjectTask.pse__Status__c == NSP_ServiceConstants.PROJECT_TASK_CANCELLED || oProjectTask.pse__Status__c == NSP_ServiceConstants.PROJECTSTATUSNOTSTARTED ){
                oProjectTask.pse__Started__c = false;
            }else if( oProjectTask.pse__Status__c != oldStatus && ( String.isBlank(oldStatus) || oldStatus == NSP_ServiceConstants.PROJECT_TASK_CANCELLED || oldStatus == NSP_ServiceConstants.PROJECTSTATUSNOTSTARTED )){
                oProjectTask.pse__Actual_Start_Date_Time__c = Datetime.now();
                oProjectTask.pse__Started__c = true;
            }
        }

        if(mCompletedTasks.keySet().size() > 0){
            checkRelatedTerminationsFormStatus(mCompletedTasks);
        }
    }

    /**
    * Check if all Related Terminations forms are Approved , otherwise throw Error
    * @param lProjectTasks List of New project Task. 
    * @return void
    */
    public void checkRelatedTerminationsFormStatus(Map<Id,pse__Project_Task__c> mCompletedTasks){
        List<String> lTerminationFormStatus = new List<String>{NSP_ServiceConstants.PR_SUPERVISOR_APPROVED, NSP_ServiceConstants.TERM_SUPERVISOR_APPROVED};

        List<NSP_Termination_Form__c> lTerminationForms = new List<NSP_Termination_Form__c>([SELECT Id,NSP_Project_Task__c FROM NSP_Termination_Form__c WHERE NSP_Project_Task__c in: mCompletedTasks.keySet() AND NSP_Status__c NOT IN:lTerminationFormStatus]);
        Set<Id> sTasksWithIncompleteForms = new Set<Id>();
        for(NSP_Termination_Form__c oTerminationForm :lTerminationForms){
            sTasksWithIncompleteForms.add(oTerminationForm.NSP_Project_Task__c);
        }

        for(pse__Project_Task__c oProjectTask : mCompletedTasks.values()){
            if(sTasksWithIncompleteForms.contains(oProjectTask.Id)){
                oProjectTask.addError(System.Label.NSP_Project_Task_Completion_Error);
            }
        }
    }
    public void showErrorIfPercentageCompleteChangeToNot100(List<pse__Project_Task__c> lProjectTasks, map<Id, pse__Project_Task__c> oldMap){

        for(pse__Project_Task__c oProjecTask : lProjectTasks){
            if(oProjecTask.pse__Status__c == NSP_ServiceConstants.PROJECTSTATUSCOMPLETED 
                && oProjecTask.NSP_Percentage_Complete__c != HUNDRED_PERCENT
                && oldMap.get(oProjecTask.id).NSP_Percentage_Complete__c == HUNDRED_PERCENT){
                     oProjecTask.addError(System.Label.ShowErrorMessageWhenStausCompleteButPercentageNot100);
            }

            if(oProjecTask.NSP_Percentage_Complete__c == HUNDRED_PERCENT 
            && oProjecTask.NSP_Percentage_Complete__c != oldMap.get(oProjecTask.id).NSP_Percentage_Complete__c
            && oProjecTask.pse__Status__c != NSP_ServiceConstants.PROJECTSTATUSCOMPLETED){
                oProjecTask.addError(System.Label.ShowErrorMessageWhenPercentage100ButStatusNotComplete);
            }

           /* commented as a part of <DF-02510>
           if(oProjecTask.NSP_Percentage_Complete__c == '0%' 
                && oldMap.get(oProjecTask.id).NSP_Percentage_Complete__c != '0%'){
                    oProjecTask.addError(System.Label.ShowErrorMessageWhenPercentageMoveBackToZero);
            } */ 
                // Added Or condition as part of DF-2180
            if(oProjecTask.pse__Status__c == NSP_ServiceConstants.PROJECTSTATUSCOMPLETED || 
            oProjecTask.pse__Status__c == NSP_ServiceConstants.PROJECT_TASK_CANCELLED){
                oProjecTask.NSP_Percentage_Complete__c = HUNDRED_PERCENT;
            }
        }     
    }

    public void sendEmailToAccountTeamMembersIfTaskIsLetterReceived(List<pse__Project_Task__c> lProjectTasks, map<Id, pse__Project_Task__c> oldMap){
        Id wORecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WO_ASSET_RECORDTYPE).getRecordTypeId();
        List<String> listOfToAddresses = new List<String>();
        map<Id, Id> mapOfProjectTaskAndProject = new map<Id, Id>();
        map<Id, Id> mapOfProjectTaskAndProject1 = new map<Id, Id>();
        map<Id, Id> mapOfProjectAndAccount = new map<Id, Id>();
        map<Id, pse__Project_Task__c> mapOfProjectAndAccountName = new map<Id, pse__Project_Task__c>();
        List<Id> listOfAccountId = new List<Id>();
		map<Id, Asset> woActiveList = new map<Id, Asset>();

        map<Id, list<String>> mapOfAccountAndListOfAccountTeamMemberEmailAddress = new map<Id, list<String>>();
        Map<Id, pse__Project_Task__c> projectTaskLetterMap = new Map<Id, pse__Project_Task__c>();
        map<Id, list<NSP_Account_Team__c>> mapOfAccountPayrollMem = new map<Id, list<NSP_Account_Team__c>>();
        List<NSP_Account_Team__c> listOfPayrollMem = new List<NSP_Account_Team__c>();
        map<Id, list<NSP_Account_Team__c>> mapOfNotifyPayrollMem = new map<Id, list<NSP_Account_Team__c>>();
        map<Id, Id> mapOfNotifyaccountMem = new map<Id,Id>();
        List<NSP_Account_Team__c> listOfNotifyMem = new List<NSP_Account_Team__c>();

        for(pse__Project_Task__c projectTask : lProjectTasks){
            if(projectTask.pse__Status__c == 'Complete' 
            && projectTask.pse__Status__c != oldMap.get(projectTask.id).pse__Status__c){
                if(projectTask.name == 'Letter Received (Termination Letter)'){
                    if(!mapOfProjectTaskAndProject.containsKey(projectTask.id)){
                        mapOfProjectTaskAndProject.put(projectTask.id, projectTask.pse__Project__c);
                    } 
                    listOfAccountId.add(projectTask.NSP_AccountId__c);
                    
                }
                if(projectTask.name == 'Notify ITA if term date is today'){
                    if(!mapOfProjectTaskAndProject1.containsKey(projectTask.id)){
                        mapOfProjectTaskAndProject1.put(projectTask.id, projectTask.pse__Project__c);
                    }
                }        
            }    
        }
        //get the data for the email template. - Added by Sruthi
        if(!mapOfProjectTaskAndProject.isEmpty() ){
            for(pse__Project_Task__c projectTask : [SELECT Id, pse__Project__c, Name, pse__Project__r.pse__Account__r.Name,
                                                    pse__Project__r.pse__Account__r.NSP_AIMS_Client__c,NSP_AccountId__c
                                                    FROM pse__Project_Task__c 
                                                    WHERE Id IN :mapOfProjectTaskAndProject.keySet()]){
                //projectTaskWithTerminationMap.put(temination.NSP_Project_Task__c, temination); 
                //mapOfProjectAndAccount.put(temination.NSP_Project_Task__c, temination.NSP_Project_Task__r.pse__Project__r.pse__Account__c);
                if(!mapOfProjectAndAccount.containsKey(projectTask.id)){
                    mapOfProjectAndAccount.put(projectTask.Id, projectTask.NSP_AccountId__c);                                           
                } 
                if(!projectTaskLetterMap.containsKey(projectTask.id)){
                    projectTaskLetterMap.put(projectTask.Id, projectTask);                                           
                }                                        
            }
        }
        if(!listOfAccountId.isEmpty()){
        for(Asset assetLi : [SELECT id,accountid,NSP_Reason_for_Term__c,NSP_Anticipated_Date_Of_Termination__c FROM Asset Where RecordTypeId =: wORecordTypeId AND Status= 'Active'AND accountid IN :listOfAccountId ]){
        woActiveList.put(assetLi.accountid,assetLi);
            }
        }

        if(!mapOfProjectTaskAndProject1.isEmpty()){
            for(pse__Project_Task__c projectTask : [SELECT Id, pse__Project__c, Name, pse__Project__r.pse__Account__r.Name,
                                                    pse__Project__r.pse__Account__r.NSP_AIMS_Client__c,NSP_AccountId__c
                                                    FROM pse__Project_Task__c 
                                                    WHERE Id IN :mapOfProjectTaskAndProject1.keySet()]){
                if(!mapOfProjectAndAccountName.containsKey(projectTask.id)){
                    mapOfProjectAndAccountName.put(projectTask.Id, projectTask);                                           
                }
                 if(!mapOfNotifyaccountMem.containsKey(projectTask.id)){
                    mapOfNotifyaccountMem.put(projectTask.Id, projectTask.NSP_AccountId__c);
                }
            }
        }
		
        if(!mapOfProjectAndAccount.values().isEmpty() || !mapOfNotifyaccountMem.values().isEmpty() ){
            for(NSP_Account_Team__c accTeamMember :  [SELECT Id, NSP_Role__c, NSP_Account__c, NSP_Email__c,NSP_First_Name__c,NSP_Last_Name__c,NSP_Work_Phone__c
                                                    FROM NSP_Account_Team__c 
                                                    WHERE (NSP_Account__c IN: mapOfProjectAndAccount.values() AND
                                                    (NSP_Role__c = 'Business Performance Advisor' OR
                                                    NSP_Role__c = 'Client Liaison' OR 
                                                    NSP_Role__c = 'Manager,HR Services' OR 
                                                    NSP_Role__c = 'Payroll Manager' OR 
                                                    NSP_Role__c = 'Customer Success Specialist' OR
                                                    NSP_Role__c = 'Payroll Specialist'
                                                    )) OR (NSP_Account__c IN: mapOfNotifyaccountMem.values() AND
                                                    NSP_Role__c = 'Payroll Specialist')]){
                                                     
                if(accTeamMember.NSP_Role__c !='Payroll Specialist' && mapOfProjectAndAccount.values().contains(accTeamMember.NSP_Account__c) ){
                if(mapOfAccountAndListOfAccountTeamMemberEmailAddress.containsKey(accTeamMember.NSP_Account__c)){
                    mapOfAccountAndListOfAccountTeamMemberEmailAddress.get(accTeamMember.NSP_Account__c).add(accTeamMember.NSP_Email__c);
                } else{
                    mapOfAccountAndListOfAccountTeamMemberEmailAddress.put(accTeamMember.NSP_Account__c, new list<String> {accTeamMember.NSP_Email__c});
                }
            }
               Else if(accTeamMember.NSP_Role__c =='Payroll Specialist'&& mapOfProjectAndAccount.values().contains(accTeamMember.NSP_Account__c) ){  
                if(mapOfAccountPayrollMem.containsKey(accTeamMember.NSP_Account__c)){
                    mapOfAccountPayrollMem.get(accTeamMember.NSP_Account__c).add(accTeamMember);
                } else{
                    mapOfAccountPayrollMem.put(accTeamMember.NSP_Account__c, new list<NSP_Account_Team__c> {accTeamMember});
        }
               }
               Else if(accTeamMember.NSP_Role__c =='Payroll Specialist'&& mapOfNotifyaccountMem.values().contains(accTeamMember.NSP_Account__c) ){
                 if(mapOfNotifyPayrollMem.containsKey(accTeamMember.NSP_Account__c)){
                    mapOfNotifyPayrollMem.get(accTeamMember.NSP_Account__c).add(accTeamMember);
                } else{
                    mapOfNotifyPayrollMem.put(accTeamMember.NSP_Account__c, new list<NSP_Account_Team__c> {accTeamMember});
                }
               }
             
            }
        }
       
        
        if(projectTaskLetterMap.size()>0 || (mapOfProjectTaskAndProject1.size()>0 && mapOfProjectAndAccountName.size()>0 ) ){
           // Group terminationQueueEmailAddress = [SELECT Id, Email FROM Group WHERE Type = 'Queue' and DeveloperNAME = 'Termination_Team'];   

        for(pse__Project_Task__c pTask : lProjectTasks){
            if(projectTaskLetterMap.containsKey(pTask.id)&& woActiveList.containsKey(pTask.NSP_AccountId__c) && pTask.name == 'Letter Received (Termination Letter)'){
                String emailNSP_Termination_Team = System.Label.NSP_Termination_Team;
                listOfPayrollMem.addAll(mapOfAccountPayrollMem.get(mapOfProjectAndAccount.get(pTask.id)));
                if(mapOfAccountAndListOfAccountTeamMemberEmailAddress.size()>0){
                listOfToAddresses.addAll(mapOfAccountAndListOfAccountTeamMemberEmailAddress.get(mapOfProjectAndAccount.get(pTask.id)));
                }
                listOfToAddresses.add(emailNSP_Termination_Team);
                letterRecievedEmail(projectTaskLetterMap.get(pTask.id).pse__Project__r.pse__Account__r.Name,
                                    projectTaskLetterMap.get(pTask.id).pse__Project__r.pse__Account__r.NSP_AIMS_Client__c,
                                    listOfToAddresses,listOfPayrollMem,
                                    woActiveList.get(pTask.NSP_AccountId__c).NSP_Reason_for_Term__c,
                                    woActiveList.get(pTask.NSP_AccountId__c).NSP_Anticipated_Date_Of_Termination__c);
                
            }if(mapOfProjectAndAccountName.containsKey(pTask.id) && mapOfProjectAndAccountName.get(pTask.id).Name == 'Notify ITA if term date is today'){
                if(mapOfNotifyPayrollMem.size()>0){
                	listOfNotifyMem.addAll(mapOfNotifyPayrollMem.get(mapOfNotifyaccountMem.get(pTask.id)));
                }
                notifyEmail(mapOfProjectAndAccountName.get(pTask.id).pse__Project__r.pse__Account__r.Name, mapOfProjectAndAccountName.get(pTask.id).pse__Project__r.pse__Account__r.NSP_AIMS_Client__c, listOfNotifyMem);
            }
        }
    }
    }
    
    //Letter Received email.
    public void letterRecievedEmail(String accountName, String accountAIMS, list<String> listOfToAddresses, List<NSP_Account_Team__c> listOfPayrollMem, String ReasonForTerm, Date TermDate){
        String dtStr;
        if(TermDate!= null){
        dtStr = TermDate.format();
        }
        String subjectString = 'Termination letter received for '+accountName+'('+accountAIMS+')';
        String mailBody = 'Hello Team,'+'<br/><br/>';
        mailBody += accountName+'('+accountAIMS+')'+' submitted written notification of their intent to terminate their contract with Insperity. Below are the details of the termination:'+'<br/><br/>';
        mailBody += 'Intended effective termination date: '+dtStr+'<br/>';
        mailBody += 'Termination reason: '+ReasonForTerm+'<br/><br/>';
        mailBody += 'Regards,'+'<br/>';
        for(NSP_Account_Team__c payrollTeam : listOfPayrollMem){
        mailBody += payrollTeam.NSP_First_Name__c+' '+payrollTeam.NSP_Last_Name__c+'<br/>';  // updated as part of STY-04147
        mailBody += payrollTeam.NSP_Role__c+'<br/>';
        mailBody += payrollTeam.NSP_Email__c+'<br/>';
        mailBody += payrollTeam.NSP_Work_Phone__c+'<br/>';  
        //mailBody += UserInfo.getFirstName()+' '+UserInfo.getLastName()+'<br/>';
        //mailBody += UserInfo.getUserEmail();
        }
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(listOfToAddresses);
        email.setSubject(subjectString);
        email.setHtmlBody(mailBody);
        email.setSaveAsActivity(false);
        email.setTargetObjectId(userinfo.getUserId());
        if(!System.Test.isRunningTest()){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        }
    }
    
    //Notify email.
    public void notifyEmail(String accountName, String accountAIMS, List<NSP_Account_Team__c> listOfNotifyMem){
        String subjectString = 'Termination date is today for '+accountName+'('+accountAIMS+')'+' - do not disable access to ITA';
        //string[] to = new string[] {'time.support@insperity.com'};
        String[] to = new String[] {System.Label.NSP_ITA_Email_Address};
        String mailBody = 'Hello Team,'+'<br/><br/>';
        mailBody += accountName+'('+accountAIMS+')'+'  is terminating their contract with Insperity effective today, '+System.today().month()+'/'+System.today().day()+'/'+System.today().year()+'<br/><br/>';
        mailBody += 'This client is an Insperity Time and Attendance client and will need to retain access to ITA in order to process their final payroll. Please do not disable this client’s access to ITA until their final payroll is processed.'+'<br/><br/>';
        mailBody += 'Should you have any questions or concerns, please reach out to me.'+'<br/><br/>';
        mailBody += 'Regards,'+'<br/>';
        for(NSP_Account_Team__c notifyPayrollTeam : listOfNotifyMem){
        mailBody += notifyPayrollTeam.NSP_First_Name__c+' '+notifyPayrollTeam.NSP_Last_Name__c+'<br/>';  //updated as part of STY-04147
        mailBody += notifyPayrollTeam.NSP_Role__c+'<br/>';
        mailBody += notifyPayrollTeam.NSP_Email__c+'<br/>';
        mailBody += notifyPayrollTeam.NSP_Work_Phone__c+'<br/>';  
        }
        //mailBody += UserInfo.getFirstName()+' '+UserInfo.getLastName()+'<br/>';
        //mailBody += UserInfo.getUserEmail();
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(to);
        email.setSubject(subjectString);
        email.setHtmlBody(mailBody);
        email.setSaveAsActivity(false);
        email.setTargetObjectId(userinfo.getUserId());
        if(!System.Test.isRunningTest()){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        }
    }
    

    /* Description : This method throws an error if Dependent Task is started
                    without completing Preceding Task
       Date        : 12/10/2021 */

    public void showErrorIfPreceedingTaskNotCompleted(List<pse__Project_Task__c> lProjectTasks, map<Id, pse__Project_Task__c> oldMap){
        set<ID> setOfDependentTask                      = new set<ID>();
        set<ID> setOfPrecedingTask                      = new set<ID>();
        map<Id, Id> mapOfDependentTaskAndPrecedingtask  = new map<Id, Id>();
        map<Id, Boolean> isMapOfPrecedingTaskAndCompleted = new map<Id, Boolean>();

        for(pse__Project_Task__c projectTask : lProjectTasks){
            if(projectTask.pse__Started__c 
                && projectTask.pse__Started__c != oldMap.get(projectTask.id).pse__Started__c){
                setOfDependentTask.add(projectTask.id);
            }
        }

        if(!setOfDependentTask.isEmpty()){
            for(pse__Project_Task_Dependency__c projectDependency : [SELECT pse__Dependent_Task__c, pse__Preceding_Task__c, pse__Type__c 
                                                                    FROM pse__Project_Task_Dependency__c 
                                                                    WHERE pse__Dependent_Task__c IN : setOfDependentTask
                                                                    and pse__Type__c = :NSP_ServiceConstants.FINISH_To_START]){
                if(projectDependency.pse__Preceding_Task__c != null){
                    setOfPrecedingTask.add(projectDependency.pse__Preceding_Task__c);

                    if(!mapOfDependentTaskAndPrecedingtask.containsKey(projectDependency.pse__Dependent_Task__c)){
                        mapOfDependentTaskAndPrecedingtask.put(projectDependency.pse__Dependent_Task__c, projectDependency.pse__Preceding_Task__c);
                    }
                }
            }
        }

        if(!setOfPrecedingTask.isEmpty()){
            for(pse__Project_Task__c task : [SELECT pse__Completed__c FROM pse__Project_Task__c 
                                            WHERE ID IN : setOfPrecedingTask]){
                if(!isMapOfPrecedingTaskAndCompleted.containsKey(task.id)){
                    isMapOfPrecedingTaskAndCompleted.put(task.id, task.pse__Completed__c);
                }
            }
        }

        if(!isMapOfPrecedingTaskAndCompleted.isEmpty()){
            for(pse__Project_Task__c projectTaskError : lProjectTasks){
                if(projectTaskError.pse__Started__c 
                    && !isMapOfPrecedingTaskAndCompleted.get(mapOfDependentTaskAndPrecedingtask.get(projectTaskError.id))){
                    projectTaskError.addError(System.Label.NSP_ProjectTask_Validation);
                }
            }
        } 
    }

    /**
    * Iterates throught the list of new pse__Project_Task__c and passes the required attributes to other methods.
    * @param projectTaskNewMap Map of New project. 
    * @param projecttaskOldMap Map of Old project.   
    * @return void             
    *                
    */
    @future
    public static void onChangeOfProjectTemplate(Set<Id> projectTaskList){
        Set<Id> projectsIdSet = new Set<Id>();
        Map<Id, pse__Proj__c> parentProjectMap = new Map<Id, pse__Proj__c>();
        Map<Id, pse__Project_Task__c> projectTaskMap = new Map<Id, pse__Project_Task__c>();
        List<pse__Project_Task_Assignment__c> projectTaskAssignmentList = new List<pse__Project_Task_Assignment__c>();
        try{
            Contact resourceContact = [Select Id, pse__Salesforce_User__c From Contact WHERE pse__Salesforce_User__c =: UserInfo.getUserId()];
            if(resourceContact != null){
                for(pse__Project_Task__c projectTask : [SELECT pse__Project__c, NSP_Template_Generated__c 
                                                        FROM pse__Project_Task__c 
                                                        WHERE ID IN : projectTaskList]){
                    if(projectTask.pse__Project__c != null && !projectTask.NSP_Template_Generated__c){
                        projectsIdSet.add(projectTask.pse__Project__c);  
                        projectTaskMap.put(projectTask.Id, projectTask);
                    }
                }    
            }
            if(projectsIdSet.size() > 0){
                parentProjectMap = new Map<Id, pse__Proj__c>([Select Id, pse__Is_Template__c 
                                                  From pse__Proj__c 
                                                  WHERE pse__Is_Template__c = False
                                                  AND ID In: projectsIdSet]);
                    
            }
            if(!parentProjectMap.isEmpty()){
                for(pse__Project_Task__c projectTask : projectTaskMap.values()){
                    if(parentProjectMap.get(projectTask.pse__Project__c) != null){
                        pse__Project_Task_Assignment__c projectTaskAssignment = new pse__Project_Task_Assignment__c(); 
                        projectTaskAssignment.pse__Resource__c = resourceContact.Id;
                        projectTaskAssignment.NSP_Priority__c = 1;
                        projectTaskAssignment.pse__Project_Task__c = projectTask.Id;
                        projectTaskAssignmentList.add(projectTaskAssignment);
                    }
                }
            }
            if(projectTaskAssignmentList.size() > 0){
                insert projectTaskAssignmentList;
            }
        }catch(exception ex){
            
        }
    }
    /**
    * This method update Template Used field on Project from Template Name field on Project task
    * @param projectTaskList List of New project.  
    * @return void             
    *                
    */
    public void updateTemplateUsedFieldOnProject(List<pse__Project_Task__c> projectTaskList){
        Set<Id> setOfProjectId = new Set<Id>();
        Map<Id, Set<String>> mapOfProjectIdAndSetOfTemplateNameOnProjectTask = new Map<Id, Set<String>>();
        List<pse__Proj__c> listOfProject = new List<pse__Proj__c>();
        String templateUsed = '';

        for(pse__Project_Task__c projectTask : projectTaskList){
            if(projectTask.pse__Project__c != null && String.isBlank(projectTask.NSP_Implementation_Account_Id__c)){
                setOfProjectId.add(projectTask.pse__Project__c);
                if(mapOfProjectIdAndSetOfTemplateNameOnProjectTask.containsKey(projectTask.pse__Project__c)){
                    mapOfProjectIdAndSetOfTemplateNameOnProjectTask.get(projectTask.pse__Project__c);
                } else if(!mapOfProjectIdAndSetOfTemplateNameOnProjectTask.containsKey(projectTask.pse__Project__c) 
                    && projectTask.Template_Name__c != null){
                              mapOfProjectIdAndSetOfTemplateNameOnProjectTask.put(projectTask.pse__Project__c, new Set<String> {projectTask.Template_Name__c});
                    }
                          }   
        }

        for(pse__Proj__c project : [SELECT Templates_Used__c FROM pse__Proj__c WHERE ID IN : setOfProjectId and pse__Is_Template__c = false]){
            if(!mapOfProjectIdAndSetOfTemplateNameOnProjectTask.isEmpty()){
                if(project.Templates_Used__c != null){
                    templateUsed = project.Templates_Used__c + mapOfProjectIdAndSetOfTemplateNameOnProjectTask.get(project.id) + ',';
                } else {
                    templateUsed = mapOfProjectIdAndSetOfTemplateNameOnProjectTask.get(project.id) + ',';
                }
                if(templateUsed.contains('{') || templateUsed.contains('}')){
                    String tempRemovedSingleBrances = templateUsed.remove('{');
                    String tempRemovedSecondBraces  = tempRemovedSingleBrances.remove('}');
                    project.Templates_Used__c = tempRemovedSecondBraces.length()>255? tempRemovedSecondBraces.substring(0, 255):tempRemovedSecondBraces;
                }

                listOfProject.add(project);
            }
        }

        if(!listOfProject.isEmpty()){
            Database.update(listOfProject);
        }
        
    }

    /**
    * INSERT: This method update Milestone Complete field on related Milestone and Project Complete field on related Project
    * @param projectTaskList List of New project.  
    * @return void 
    * STY-00717                        
    */
    public void updateMilestoneAndProjectPercentCompleteOnInsert(List<pse__Project_Task__c> projectTaskList){
        Set<Id> setOfMilestoneId = new Set<Id>();
        Set<Id> setOfProjectId = new Set<Id>();
        for(pse__Project_Task__c pTask : projectTaskList){
            if(pTask.pse__Milestone__c != null){
                setOfMilestoneId.add(pTask.pse__Milestone__c);
            }
            if(pTask.pse__Project__c != null){
                setOfProjectId.add(pTask.pse__Project__c);
            }
        }
        if(!setOfMilestoneId.isEmpty()){
            updateMilestonePercentComplete(setOfMilestoneId);
        }
        
        //updating values in Project Percent Complete Field
        if(!setOfProjectId.isEmpty() && !System.isFuture() && !System.isBatch()){
            updateProjectPercentageComplete(setOfProjectId);
        }
    }
       /**
* UPDATE: This method update Milestone Complete field and Project Complete on related Milestone and Project respectively after deletion of Project task
* @param projectTaskList List of old project.
* @Defect : DF-02180
* STORY : STY-00717
* @return void             
*                
*/
public void afterDeleteProjectTask(List<pse__Project_Task__c> projectTaskList){
    Set<Id> setOfMilestoneId = new Set<Id>();
    Set<Id> projectIdSet = new Set<Id>(); 
    for(pse__Project_Task__c pTask : projectTaskList){
        if(pTask.pse__Milestone__c != null){
            setOfMilestoneId.add(pTask.pse__Milestone__c);
        }
        if(pTask.pse__Project__c != null){
            projectIdSet.add(pTask.pse__Project__c);
        }
    }
    
    if(!setOfMilestoneId.isEmpty()){
            updateMilestonePercentComplete(setOfMilestoneId);
        }
    if(!projectIdSet.isEmpty() && !System.isFuture() && !System.isBatch()){
            updateProjectPercentageComplete(projectIdSet);
         }
}
    /**
    * UPDATE: This method update Milestone Complete field and Project Complete field on related Milestone and Project respectively.
    * @param projectTaskList List of New project.
    * @param oldMap Map of Project  
    * @return void
    * STY-00717                 
    */
   public void updateMilestoneAndProjectPercentCompleteOnUpdate(List<pse__Project_Task__c> projectTaskList, Map<Id, pse__Project_Task__c> oldMap){
        Set<Id> setOfMilestoneId = new Set<Id>();
        Set<Id> setOFProjectId = new Set<Id>();
        for(pse__Project_Task__c pTask : projectTaskList){
            if(pTask.NSP_PercentageCompleteFormula__c!=null && !String.isBlank(pTask.pse__Status__c) && 
               pTask.NSP_PercentageCompleteFormula__c != oldMap.get(pTask.id).NSP_PercentageCompleteFormula__c 
            || (pTask.pse__Status__c != oldMap.get(pTask.id).pse__Status__c)){

                if(String.isNotBlank(pTask.pse__Milestone__c)){
                    setOfMilestoneId.add(pTask.pse__Milestone__c);
                }
                 if(String.isNotBlank(pTask.pse__Project__c)){
                    setOFProjectId.add(pTask.pse__Project__c);
                }
            }
        }
     if(!setOfMilestoneId.isEmpty()){
            updateMilestonePercentComplete(setOfMilestoneId);
        }
     if(!setOfProjectId.isEmpty() && !System.isFuture() && !System.isBatch()){
        updateProjectPercentageComplete(setOfProjectId);
        }
    }
    
    public static void updateMilestonePercentComplete(Set<Id> setOfMilestone){
        List<pse__Milestone__c> listOfMilestone = new List<pse__Milestone__c>();

            AggregateResult[] groupedResults = [SELECT SUM(NSP_PercentageCompleteFormula__c),Count(id),pse__Milestone__c 
                                                FROM pse__Project_Task__c 
                                                WHERE pse__Milestone__c IN :setOfMilestone and 
                                                (pse__Status__c !=: NSP_ServiceConstants.PROJECT_TASK_CANCELLED OR
                                                 pse__Status__c !=: NSP_ServiceConstants.PROJECTSTATUSCOMPLETED ) AND
                                                pse__Synchronize_Milestone_And_Task__c = false 
                                                GROUP BY pse__Milestone__c ];
            
            for(AggregateResult ar:groupedResults) {
                Id pMilestone = (ID)ar.get('pse__Milestone__c');
                
                Decimal count = (Decimal)ar.get('expr0');
                Decimal countOfrecords = (Decimal)ar.get('expr1');
                pse__Milestone__c milestone = new pse__Milestone__c(Id = pMilestone);
                milestone.NSP_Milestone_Complete__c= count/countOfrecords;
                
                listOfMilestone.add(milestone);
        }
        
        if(!listOfMilestone.isEmpty()){
            Database.update(listOfMilestone);
        }
    }
/**
    * UPDATE: This method update Project Complete field on related Project
    * @return void
    * STY-00717                 
    */
    @future
    private static void updateProjectPercentageComplete(Set<Id> projectIds){
        List<pse__Proj__c> listOfProject = new List<pse__Proj__c>();
        
        AggregateResult[] groupedResults = [SELECT SUM(NSP_PercentageCompleteFormula__c),Count(id),pse__Project__c 
                                            FROM pse__Project_Task__c 
                                            WHERE pse__Project__c IN :projectIds AND
                                            (pse__Status__c !=: NSP_ServiceConstants.PROJECT_TASK_CANCELLED OR
                                             pse__Status__c !=: NSP_ServiceConstants.PROJECTSTATUSCOMPLETED )
                                            GROUP BY pse__Project__c ];
        
        for(AggregateResult ar:groupedResults) {
            if(ar.get(NSP_ServiceConstants.PSE_PROJECT)!=null ){
                Id pProject = (ID)ar.get(NSP_ServiceConstants.PSE_PROJECT);
            Decimal count = (Decimal)ar.get('expr0');
            Decimal countOfrecords = (Decimal)ar.get('expr1');
                pse__Proj__c projectObj = new pse__Proj__c(Id = pProject);
            projectObj.NSP_Project_Complete__c= count/countOfrecords;
            listOfProject.add(projectObj);
        }
        }
        if(!listOfProject.isEmpty()){
            Database.update(listOfProject);
        }
    }
    
    /**
    * Description: This method update NSP_NumberOfCompletedProjectTask__c field on related Milestone
                    when project gets Cancelled/complete with total number of Complete + cancelled projects
    * @param projectTaskList List of New project.
    * @param oldMap Map of Project  
    * @return void             
    *                
    */

    public void calculateNumberOfCompletedAndCancelledProjectTask(List<pse__Project_Task__c> projectTaskList, Map<Id, pse__Project_Task__c> oldMap){
        Set<Id> setOfMilestoneId = new Set<Id> ();
        List<pse__Milestone__c> listOfMilestone = new List<pse__Milestone__c>();
        try{
            String PEOProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get('PEO_Project_Task').getRecordTypeId();
            
            for(pse__Project_Task__c projectTask : projectTaskList){
                if(projectTask.pse__Milestone__c != null && projectTask.RecordTypeId == PEOProjectTaskRecordTypeId
                  && (projectTask.pse__Status__c == NSP_ServiceConstants.PROJECTSTATUSCOMPLETED || projectTask.pse__Status__c == NSP_ServiceConstants.PROJECT_TASK_CANCELLED )){
                    setOfMilestoneId.add(projectTask.pse__Milestone__c);
                }
            }
            if(!setOfMilestoneId.isEmpty()){
            AggregateResult[] groupedResults = [SELECT Count(id),pse__Milestone__c 
                                                FROM pse__Project_Task__c 
                                                WHERE pse__Milestone__c IN :setOfMilestoneId AND 
                                                (pse__Status__c =: NSP_ServiceConstants.PROJECTSTATUSCOMPLETED OR pse__Status__c =: NSP_ServiceConstants.PROJECT_TASK_CANCELLED) AND
                                                pse__Synchronize_Milestone_And_Task__c = false 
                                                GROUP BY pse__Milestone__c ];
            
            for(AggregateResult ar:groupedResults) {
                Id pMilestone = (ID)ar.get('pse__Milestone__c');
                if(pMilestone!=null){
                    
                    Decimal countOfrecords = (Decimal)ar.get('expr0');
                    pse__Milestone__c milestone = new pse__Milestone__c(Id = pMilestone);
                    milestone.NSP_NumberOfCompletedProjectTask__c= countOfrecords;
                    
                    listOfMilestone.add(milestone);
                }
            }
            }
            
            if(!listOfMilestone.isEmpty()){
                Database.update(listOfMilestone);
            }
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException(NSP_PROJECTTASKSTRIGGERHELPER, 'calculateNumberOfCompletedAndCancelledProjectTask', ex.getMessage());
        }
        
    }
    

   /**
    * Update Depenedent Task Resources about Precending Task Completion if Responsible Party is Different
    * @param mNewProjectTasks Map of New project. 
    * @param mOldProjectTasks Map of Old project. 
    * @return void
    */
    public void afterUpdateTaskfilters(Map<Id, pse__Project_Task__c> mNewProjectTasks,Map<Id, pse__Project_Task__c> oldMapProjecttasks){
        Set<Id> sProjectTasksIds = new Set<Id>();
        Map<Id,Id> mapofProjecttasks = new Map<Id,Id>();
        Set<Id> projectTaskIdSet = new Set<Id>();
        Map<Id,Id> mapofFundingProjecttasks = new Map<Id,Id>();
        Set<Id> fundingprojectTaskIdSet = new Set<Id>();
        Map<Id,Id> mapofFormProjecttasks = new Map<Id,Id>();
        Set<Id> projectFsoIdset = new Set<Id>();
        Map<Id, Id> accountIdFsoProjectTaskMap = new Map<Id, Id>();
        Set<Id> projectTaskCobraIdSet = new  Set<Id>();
        Set<Id> projectTaskidsChangedOwner = new  Set<Id>();
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        Map<Id, Id> mapOfProjectTaskOwner = new Map<Id,Id>();
        Map<Id, Id> mapofClientProjectTask = new Map<Id, Id>();
        Map<Id, Id> mapofDiscoveryProjectTask = new Map<Id,Id>();
        Map<Id, Id> mapOfDiscoveryProjectTaskOwner = new Map<Id, Id>();
        Set<Id>hcmProjectSet = new Set<Id>();
        Set<Id>newTaxIMPLSubProjectSet =new Set<Id>(); 
        Set<Id>wXWADataMigrationSubProject =new Set<Id>();
        Set<Id> goLiveProjectTaskIds = new Set<Id>();
        for(pse__Project_Task__c oProjectTask : mNewProjectTasks.values()){
            // FILTER COMPLETED PROJECTS
            if(oProjectTask.pse__Status__c == NSP_ServiceConstants.PROJECTSTATUSCOMPLETED && oldMapProjecttasks.get(oProjectTask.Id).pse__Status__c != NSP_ServiceConstants.PROJECTSTATUSCOMPLETED){
                sProjectTasksIds.add(oProjectTask.Id);
            }
            if(oProjectTask.Name ==NSP_ServiceConstants.GO_LIVE && oProjectTask.pse__Project__c != NULL && oProjectTask.pse__Status__c == NSP_ServiceConstants.PROJECTSTATUSCOMPLETED
               && oProjectTask.NSP_Is_Status_Completed__c && !oldMapProjecttasks.get(oProjectTask.Id).NSP_Is_Status_Completed__c){
                goLiveProjectTaskIds.add(oProjectTask.Id);
            }
            
            if(oldMapProjecttasks.get(oProjectTask.Id).pse__Status__c!=NSP_ServiceConstants.TASKCOMPLETE 
                   && oProjectTask.pse__Status__c==NSP_ServiceConstants.TASKCOMPLETE && oProjectTask.pse__Project__c!=null){
                       //check if FEIN project task is completed
                    if(oProjectTask.Name==NSP_ServiceConstants.FEIN  ){
                        mapofProjecttasks.put(oProjectTask.pse__Project__c,oProjectTask.Id);
                        projectTaskIdSet.add(oProjectTask.Id);
                    }
                       //check if FUNDING DOCUMENTS project task is completed
                    if(oProjectTask.Name==NSP_ServiceConstants.FUNDINGDOCUMENTS ){
                        mapofFundingProjecttasks.put(oProjectTask.pse__Project__c,oProjectTask.Id);
                        fundingprojectTaskIdSet.add(oProjectTask.Id);
                    }
                       //check if FORM COLLECTED project task is completed
                    if(oProjectTask.Name==NSP_ServiceConstants.FORMCOLLECTED){
                        mapofFormProjecttasks.put(oProjectTask.pse__Project__c,oProjectTask.Id);
                    }
                       //Check if subtask first payroll approved task is completed
                    if(oProjectTask.pse__Parent_Task__c!=null && oProjectTask.Name==NSP_ServiceConstants.PAYROLLAPPROVED){
                         projectFsoIdset.add(oProjectTask.pse__Project__c);
                         accountIdFsoProjectTaskMap.put(oProjectTask.NSP_AccountId__c, oProjectTask.Id);  
                    }
                       //Check if cobra  task is completed
                    if(oProjectTask.Name.startsWith(NSP_ServiceConstants.COBRA_FORM_YES) ||
                        oProjectTask.Name.startsWith(NSP_ServiceConstants.COBRA_FORM_NO)){
                            projectTaskCobraIdSet.add(oProjectTask.Id);
                            projectTaskList.add(oProjectTask);

                    }
                       //Check if client transition is completed
                    if(oProjectTask.Name==NSP_ServiceConstants.CLIENTTRANSITION){
                         mapOfProjectTaskOwner.put(oProjectTask.pse__Project__c, oProjectTask.OwnerId);
                         mapofClientProjectTask.put(oProjectTask.pse__Project__c,oProjectTask.id);   
                    }
                       //Check if onsite discovery task is completed
                    if(oProjectTask.Name==NSP_ServiceConstants.ONSITEDISCOVERY){
                         mapOfDiscoveryProjectTaskOwner.put(oProjectTask.pse__Project__c, oProjectTask.OwnerId);
                         mapofDiscoveryProjectTask.put(oProjectTask.pse__Project__c,oProjectTask.id);
                        
                    }
                    
            }

            if(oldMapProjecttasks.get(oProjectTask.Id).pse__Status__c != oProjectTask.pse__Status__c &&
                   oProjectTask.pse__Status__c == NSP_ServiceConstants.TASKCOMPLETE){
                       if(oProjectTask.Name == NSP_ServiceConstants.PROJECT_TASK_DISCOVERY){
                            hcmProjectSet.add(oProjectTask.Id); 
                       }
                       if(oProjectTask.Name == NSP_ServiceConstants.CONFIGURATION_TASK){
                            newTaxIMPLSubProjectSet.add(oProjectTask.Id);
                            wXWADataMigrationSubProject.add(oProjectTask.Id);
                       }
            }
            if(oldMapProjecttasks.get(oProjectTask.Id).OwnerId != oProjectTask.OwnerId && oProjectTask.OwnerId.getsobjecttype() == User.sobjecttype){
                projectTaskidsChangedOwner.add(oProjectTask.Id);
            }
        }
        
        if(!hcmProjectSet.isEmpty() && !System.isFuture() && !System.isBatch()){
           createHCMCaseOnProjectTaskUpdate(hcmProjectSet);
        }
        if(!projectTaskidsChangedOwner.isEmpty() && !System.isFuture() && !System.isBatch()){
            Map<String, Object> mapInputParams = new Map<String, Object>{
                'projectTaskidsChangedOwner' => projectTaskidsChangedOwner
            };
            List<NSP_ProjectTaskQueueEvent__e> lstTaskQueueEvent = new List<NSP_ProjectTaskQueueEvent__e>();
            lstTaskQueueEvent.add(new NSP_ProjectTaskQueueEvent__e(NSP_Input_Parameters__c = JSON.serialize(mapInputParams), NSP_MethodName__c = 'createPTAIfOwnerIsChanged', NSP_UserId__c = UserInfo.getUserId()));
            List<Database.SaveResult> saveResults = EventBus.publish(lstTaskQueueEvent);
        }
       // Added as part of STY-02157
        if(!newTaxIMPLSubProjectSet.isEmpty() && !System.isFuture() && !System.isBatch()){
           createNewTaxIMPLSubProject(newTaxIMPLSubProjectSet);
        }
       // Added as part of STY-02158
        if(!wXWADataMigrationSubProject.isEmpty() && !System.isFuture() && !System.isBatch()){
           createWXWADataMigrationSubProject(wXWADataMigrationSubProject);
        }
        if(sProjectTasksIds.size() > 0){
            sendNotificationToDependentResource(sProjectTasksIds);
            sendBellNotificationToDependentResource(sProjectTasksIds);
            //As a part of STY-02213
            sendEmailToProjectResource(sProjectTasksIds);
        }
        if(!projectTaskIdSet.isEmpty()){
            NSP_ProjectTaskTriggerEmailNotification.emailNotifyforFEIN(projectTaskIdSet,mapofProjecttasks);
        }
        if(!fundingprojectTaskIdSet.isEmpty()){
            NSP_ProjectTaskTriggerEmailNotification.emailNotifyforFundingDocuments(fundingprojectTaskIdSet,mapofFundingProjecttasks);
        }
        if(mapofFormProjecttasks.size()>0){
            NSP_ProjectTaskTriggerEmailNotification.emailNotifyforFormCollected(mapofFormProjecttasks);
        }
        if(!projectFsoIdset.isEmpty()){
            NSP_ProjectTaskTriggerEmailNotification.emailNotifyforFirstPayrollFSO(projectFsoIdset, accountIdFsoProjectTaskMap);
        }
        if(!projectFsoIdset.isEmpty()){
            NSP_ProjectTaskTriggerEmailNotification.emailNotifyforFirstPayrollMM(projectFsoIdset, accountIdFsoProjectTaskMap);
        }
        if(!projectTaskCobraIdSet.isEmpty()){
            NSP_ProjectTaskTriggerEmailNotification.emailNotifyforCobraFollowUp(projectTaskCobraIdSet, projectTaskList);
        }
        if(mapofClientProjectTask.size()>0){
            NSP_ProjectTaskTriggerEmailNotification.emailNotifyClientTransition(mapofClientProjectTask, mapOfProjectTaskOwner);
        }
        if(mapofDiscoveryProjectTask.size()>0){
            NSP_ProjectTaskTriggerEmailNotification.emailNotifyOnsiteDiscovery(mapofDiscoveryProjectTask, mapOfDiscoveryProjectTaskOwner);
        }
        if(!goLiveProjectTaskIds.isEmpty()){
            createCasesOnProjectTasksUpdate(goLiveProjectTaskIds);
        }
    }
    /**
    * Method to Send Bell Notifications when a Client, Payroll Termination Form is Approved
    */
    @future
    public static void sendBellNotificationToDependentResource(Set<Id> sProjectTasksIds){
        String PEOProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE).getRecordTypeId();
        String ClientRecordTypeId = Schema.SObjectType.NSP_Termination_Form__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.NSP_Client_Reinstatement).getRecordTypeId();
        String PayrollRecordTypeId = Schema.SObjectType.NSP_Termination_Form__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.NSP_Payroll_Specialist_Form).getRecordTypeId();
        String mPrecedingTaskId;
        Set<String> mDependentTaskOwnerIds = new Set<String>();
        Set<Id> termFormRecordList = new Set<Id>();
                
        List<pse__Project_Task_Dependency__c> mDependentTasksOwner = new List<pse__Project_Task_Dependency__c>([SELECT Id,pse__Preceding_Task__c, pse__Dependent_Task__r.OwnerId FROM pse__Project_Task_Dependency__c WHERE pse__Preceding_Task__c in: sProjectTasksIds]);
        List<NSP_Termination_Form__c> termFormList = new List<NSP_Termination_Form__c>([SELECT Id,NSP_Project_Task__c,ownerId FROM NSP_Termination_Form__c WHERE NSP_Project_Task__c in: sProjectTasksIds AND NSP_Project_Task__r.RecordTypeId =: PEOProjectTaskRecordTypeId AND (Recordtypeid =: ClientRecordTypeId OR Recordtypeid =: PayrollRecordTypeId )]);
        
        if(!mDependentTasksOwner.isEmpty()){
        mPrecedingTaskId = mDependentTasksOwner.get(0).pse__Preceding_Task__c;
        }

        if(mDependentTasksOwner.size() == 0){
            return;
        }
        
        if(termFormList.size() > 0){
		for(NSP_Termination_Form__c termFormTask : termFormList){
            if(termFormTask.ownerId != null){
                termFormRecordList.add(termFormTask.NSP_Project_Task__c);
                }
            }
        }
             
        for(pse__Project_Task_Dependency__c mOwnerDependentTask : mDependentTasksOwner){
            if(mOwnerDependentTask.pse__Dependent_Task__r.ownerId != null && termFormRecordList.contains(mOwnerDependentTask.pse__Preceding_Task__c)){
                mDependentTaskOwnerIds.add(mOwnerDependentTask.pse__Dependent_Task__r.ownerId);
        
            }
        }
       
        if(mDependentTaskOwnerIds.size() == 0){
            return;
        }
        
        if(mDependentTaskOwnerIds.size() > 0){
        CustomNotificationType bellNotificationTermForm = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='NSP_Bell_Notification_Termination_Form' LIMIT 1]; 
                                                        
        Messaging.CustomNotification Notification = new Messaging.CustomNotification();
        Notification.setNotificationTypeId(bellNotificationTermForm.id);
        Notification.setTitle('Termination Form approval Completed');
        Notification.setBody('You have task(s) to complete'); 
        Notification.setTargetId(mPrecedingTaskId);
        Notification.send(mDependentTaskOwnerIds);
        }
    }

   /**
    * Update Depenedent Task Resources about Precending Task Completion if Responsible Party is Different
    * @param sProjectTasksIds Set of project Task Ids
    * @return void
    */
    @future
    public static void sendNotificationToDependentResource(Set<Id> sProjectTasksIds){
        String BPSProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_BPS_RECORDTYPE).getRecordTypeId();
        String PEOProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE).getRecordTypeId();
        Set<Id> sDependentTasksIds = new Set<Id>();
        List<pse__Project_Task_Dependency__c> lDependentTasks = new List<pse__Project_Task_Dependency__c>([SELECT Id,pse__Preceding_Task__c,pse__Preceding_Task__r.RecordTypeId,pse__Preceding_Task__r.Responsible_Party__c,pse__Dependent_Task__c,pse__Dependent_Task__r.RecordTypeId,pse__Dependent_Task__r.Responsible_Party__c FROM pse__Project_Task_Dependency__c WHERE pse__Preceding_Task__c in: sProjectTasksIds]);
        if(lDependentTasks.size() == 0){
            return;
        }
        for(pse__Project_Task_Dependency__c oDependentTask : lDependentTasks){
            if(oDependentTask.pse__Dependent_Task__r.RecordTypeId == BPSProjectTaskRecordTypeId){
                if(String.isBlank(oDependentTask.pse__Dependent_Task__r.Responsible_Party__c) || oDependentTask.pse__Dependent_Task__r.Responsible_Party__c != oDependentTask.pse__Preceding_Task__r.Responsible_Party__c){
                    sDependentTasksIds.add(oDependentTask.pse__Dependent_Task__c);
                }
            }else if(oDependentTask.pse__Dependent_Task__r.RecordTypeId == PEOProjectTaskRecordTypeId){
                // NO RESPONSIBLE PARTY CONDITION FOR PEO TASK
                sDependentTasksIds.add(oDependentTask.pse__Dependent_Task__c);
            }
        }
        if(sDependentTasksIds.size() == 0){
            return;
        }
        List<pse__Project_Task_Assignment__c> lTaskAssignments = new List<pse__Project_Task_Assignment__c>([SELECT Id,pse__Project_Task__c,pse__Project_Task__r.RecordTypeId,pse__Resource__c,pse__Resource__r.pse__Salesforce_User__c FROM pse__Project_Task_Assignment__c WHERE pse__Project_Task__c in :sDependentTasksIds]);
        Map<Id,Id> mBPSProjectTaskToResourceId = new Map<Id,Id>();
        Map<Id,Id> mPEOProjectTaskToResourceId = new Map<Id,Id>();
        for(pse__Project_Task_Assignment__c oProjectTaskAssignment : lTaskAssignments){    
            if(oProjectTaskAssignment.pse__Resource__c != null && oProjectTaskAssignment.pse__Resource__r.pse__Salesforce_User__c != null){
                if(oProjectTaskAssignment.pse__Project_Task__r.RecordTypeId == BPSProjectTaskRecordTypeId){
                    mBPSProjectTaskToResourceId.put(oProjectTaskAssignment.pse__Project_Task__c , oProjectTaskAssignment.pse__Resource__r.pse__Salesforce_User__c);
                }else if(oProjectTaskAssignment.pse__Project_Task__r.RecordTypeId == PEOProjectTaskRecordTypeId){
                    mPEOProjectTaskToResourceId.put(oProjectTaskAssignment.pse__Project_Task__c , oProjectTaskAssignment.pse__Resource__r.pse__Salesforce_User__c);
                }
            }
        }
        if(mBPSProjectTaskToResourceId.keySet().size() > 0){
            NSP_EmailService.sendEmail(mBPSProjectTaskToResourceId, NSP_ServiceConstants.BPS_DEPENDENTTASKNOTIFICATIONTEMPLATE);
        }
        if(mPEOProjectTaskToResourceId.keySet().size() > 0){
            NSP_EmailService.sendEmail(mPEOProjectTaskToResourceId, NSP_ServiceConstants.PEO_DEPENDENTTASKNOTIFICATIONTEMPLATE);
        }
    }

    /**
    * Update Start Date and End date on Project Task using Offset date and # number of days offset.
    * USE THIS METHOD IF YOU ADD MORE VALUES TO OFFSET DATE.
    * @param projectTaskList List of project. 
* @return void
*/
    
    public void setStartDateAndEndDateOnProjectTask(List<pse__Project_Task__c> projectTaskList){
        Set<Id> setOfProjectId                         = new Set<Id>();
        Map<Id,pse__Proj__c> projectMap                = new Map<Id,pse__Proj__c> ();
        
        String PEOProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE).getRecordTypeId();
        String woAssetRecordTypeId =  Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WO_ASSET_RECORDTYPE)?.getRecordTypeId();
        Id projectRecordType = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c',NSP_ServiceConstants.PEOProject);
        try{
            //iterate over project task to store project id
            for(pse__Project_Task__c projectTask : projectTaskList){
            if(projectTask.pse__Project__c != null && projectTask.NSP_Template_Generated__c){
                    setOfProjectId.add(projectTask.pse__Project__c);
            }else{
                projectTask.pse__Start_Date_Time__c = projectTask.pse__Start_Date_Time__c != null ? DateTime.newInstance(projectTask.pse__Start_Date_Time__c.date(), Time.newInstance(12, 0, 0, 0))
                    : projectTask.pse__Start_Date_Time__c;
                projectTask.pse__End_Date_Time__c = projectTask.pse__End_Date_Time__c != null ? DateTime.newInstance(projectTask.pse__End_Date_Time__c.date(), Time.newInstance(12, 0, 0, 0))
                    : projectTask.pse__End_Date_Time__c;
                }
            }


            if(!setOfProjectId.isEmpty()){
                for(pse__Proj__c project : [SELECT  Id, TemplateName__c,pse__Project_Type__c, RecordTypeId, pse__Account__r.NSP_AIMS_Renewal_Date__c, pse__Start_Date__c, pse__End_Date__c 
                                            FROM pse__Proj__c 
                                            WHERE ID IN : setOfProjectId and pse__Is_Template__c = false]){
                                                //check if project of type implementation and MM or FSO template
                                                if(!projectMap.containsKey(project.id) && project.RecordTypeId == projectRecordType && project.pse__Project_Type__c == NSP_ServiceConstants.ImplementationProjectType 
                                                && (project.TemplateName__c == label.Middle_Market_Implementation_Project || project.TemplateName__c == label.FSOImplementationProject ) ){
                                                    projectMap.put(project.id,project);
                                                }
                                            }
            }
            //update start & end time of project task of type implementation and template MM or FSO as part of STY-02129
            if(!projectMap.isEmpty()){
                for(pse__Project_Task__c prTask:projectTaskList){
                    // updating Project Start and End Date on Project Taks 
                    if(prTask.pse__Project__c!=null && projectMap.containsKey(prTask.pse__Project__c)){
                        prTask.pse__Start_Date_Time__c	= DateTime.newInstance(system.Now().date(), Time.newInstance(12, 0, 0, 0));
                        prTask.pse__End_Date_Time__c = DateTime.newInstance(projectMap.get(prTask.pse__Project__c).pse__End_Date__c, Time.newInstance(12, 0, 0, 0));
                    }   
                }
            }
            //update start & end time of project task of rec type PEO & not of type implementation and template MM or FSO 
            if(!setOfProjectId.isEmpty()){
                    for(pse__Project_Task__c projectTasks : projectTaskList){ 
                        if(projectTasks.NSP_Offset_Date__c == null){
                            projectTasks.pse__Start_Date_Time__c = projectTasks.pse__Start_Date_Time__c != null ? DateTime.newInstance(projectTasks.pse__Start_Date_Time__c.date(), Time.newInstance(12, 0, 0, 0))
                                : projectTasks.pse__Start_Date_Time__c;
                            projectTasks.pse__End_Date_Time__c = projectTasks.pse__End_Date_Time__c != null ? DateTime.newInstance(projectTasks.pse__End_Date_Time__c.date(), Time.newInstance(12, 0, 0, 0))
                                : projectTasks.pse__End_Date_Time__c;
                        }
                    }
            }
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_PROJECTTASKSTRIGGERHELPER, 'setStartDateAndEndDateOnProjectTask', ex.getMessage());
        }
    }

    /**calling platform event trigger from after insert to call the setStartDateAndEndDateOnProjectTaskQTP method**/
    public void platformEventToSetStartDateAndTimePT(Map<Id, pse__Project_Task__c> newMap){
        Map<String, Object> mapInputParams = new Map<String, Object>{
            'projectTaskIdsOffsetDate' => (Set<Id>) newMap.keySet()
        };
        List<NSP_ProjectTaskQueueEvent__e> lstTaskQueueEvent = new List<NSP_ProjectTaskQueueEvent__e>();
        lstTaskQueueEvent.add(new NSP_ProjectTaskQueueEvent__e(NSP_Input_Parameters__c = JSON.serialize(mapInputParams), NSP_MethodName__c = 'setStartDateAndEndDateOnProjectTaskQTP', NSP_UserId__c = UserInfo.getUserId()));
        List<Database.SaveResult> saveResults = EventBus.publish(lstTaskQueueEvent);
    }
    
    /**
    * @description : Update Start Date and End date on Project Task using Offset date and # number of days offset.
    * USE THIS METHOD IF YOU ADD MORE VALUES TO OFFSET DATE.
    * Start and End date fields ON PROJECT TASKS are updated by manage package and its overwritting the value.
    To overcome this issue the method is called in AFTER INSERT transcation.
    * @param projectTaskSet Id of project. 
    * @return void
    */

    public static void setStartDateAndEndDateOnProjectTaskQTP(Set<Id> projectTaskSet){
        Set<Id> setOfProjectId                         = new Set<Id>();
        Map<Id, Date> mapOfProjectIdAndAccountRenewal  = new Map<Id, Date>();
        
        String PEOProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE).getRecordTypeId();
        try{
            //iterate over project task to store project id
            List<String> projTaskFields = new List<String>{'Id','Name','NSP_Template_Generated__c','pse__Project__c','pse__Start_Date_Time__c',
                'pse__End_Date_Time__c', 'RecordTypeId', 'NSP_of_Days_Offset__c', 'NSP_Offset_Date__c'};
            String query = new NSP_QueryBuilder(NSP_ServiceConstants.PROJECT_TASK_SOBJECT_TYPE, projTaskFields)
                    .addFilter('Id', new List<Id>(projectTaskSet), NSP_QueryBuilder.Operator.INCLUDES)
                    .build();
        
            List<pse__Project_Task__c> projectTaskList = (List<pse__Project_Task__c>)Database.query(query);
            for(pse__Project_Task__c projectTask : projectTaskList){
                if(projectTask.pse__Project__c != null && projectTask.NSP_Template_Generated__c){
                    setOfProjectId.add(projectTask.pse__Project__c);
                }            
            }
            
            if(!setOfProjectId.isEmpty()){
                for(pse__Proj__c project : [SELECT  Id, TemplateName__c,pse__Project_Type__c, RecordTypeId, pse__Account__r.NSP_AIMS_Renewal_Date__c, pse__Start_Date__c, pse__End_Date__c 
                                            FROM pse__Proj__c 
                                            WHERE ID IN : setOfProjectId and pse__Is_Template__c = false]){
                                                if(!mapOfProjectIdAndAccountRenewal.containsKey(project.id)){
                                                    mapOfProjectIdAndAccountRenewal.put(project.id,project.pse__Account__r.NSP_AIMS_Renewal_Date__c);
                                                }
                                            }
            }
            //update start & end time of project task of rec type PEO & not of type implementation and template MM or FSO 
            if(!mapOfProjectIdAndAccountRenewal.isEmpty()){
                
                if(!setOfProjectId.isEmpty()){
                    Integer daysBetweenStartAndEndDate;
                    for(pse__Project_Task__c projectTasks : projectTaskList){   
                        if( projectTasks.RecordTypeId == PEOProjectTaskRecordTypeId && projectTasks.pse__Start_Date_Time__c != null && projectTasks.pse__End_Date_Time__c != null){
                            daysBetweenStartAndEndDate = Date.valueOf(projectTasks.pse__Start_Date_Time__c).daysBetween(Date.valueOf(projectTasks.pse__End_Date_Time__c));
                        }
                
                        if(projectTasks.NSP_Offset_Date__c != null && projectTasks.NSP_Offset_Date__c == NSP_ServiceConstants.ASSET_OFFSET_DATE){
                            Integer offsetDays = (projectTasks.NSP_of_Days_Offset__c != null) ? Integer.valueOf(projectTasks.NSP_of_Days_Offset__c) : 0;
                            if(mapOfProjectIdAndAccountRenewal.get(projectTasks.pse__Project__c) != null){
                                Date newdate = mapOfProjectIdAndAccountRenewal.get(projectTasks.pse__Project__c).addDays(offsetDays);
                                projectTasks.pse__Start_Date_Time__c = DateTime.newInstance(newdate, Time.newInstance(12, 0, 0, 0));
                                if(daysBetweenStartAndEndDate != null){
                                    projectTasks.pse__End_Date_Time__c = DateTime.newInstance(newdate.addDays(daysBetweenStartAndEndDate+2), Time.newInstance(12, 0, 0, 0)) ;
                                }
                            }
                        }
                    }
                }
                if(!projectTaskList.isEmpty()){
                    Database.Update(projectTaskList, false);
                }
            }
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_PROJECTTASKSTRIGGERHELPER, 'setStartDateAndEndDateOnProjectTaskQTP', ex.getMessage());
        }
    }

    /**
    * This will update Parent Project Status to Cancelled if Reinstatement Requested Task is marked as Complete
    * @param projectTaskList List of project Task.
    * @param oldMap Map of Project Id and Project
    * @return void
    */
    
    public void cancelParentProjectIfProjectTaskIsCompletedonReinstatementRequestedTask(List<pse__Project_Task__c> projectTaskList, Map<Id, pse__Project_Task__c> oldMap){
        Set<Id> setOfProjectId                 = new Set<Id> ();
        Set<Id> setOfParentProject             = new Set<Id> ();
        List<pse__Proj__c> listOfParentProject = new List<pse__Proj__c> ();

        for(pse__Project_Task__c pTask : projectTaskList){
            if(pTask.pse__Status__c == NSP_ServiceConstants.PROJECTSTATUSCOMPLETED &&
            pTask.pse__Status__c != oldMap.get(pTask.id).pse__Status__c && 
            pTask.Name == NSP_ServiceConstants.REINSTATEMENT_REQUESTED_TASK){
                setOfProjectId.add(pTask.pse__Project__c);
            }
        }

        if(!setOfProjectId.isEmpty()){
            for(pse__Proj__c project : [SELECT pse__Parent_Project__c FROM pse__Proj__c WHERE ID IN : setOfProjectId]){
                if(project.pse__Parent_Project__c != null){
                    setOfParentProject.add(project.pse__Parent_Project__c);
                }
            }

            for(pse__Proj__c parentProj : [SELECT pse__Project_Status__c, NSP_Cancelled_Reason__c FROM pse__Proj__c WHERE ID IN : setOfParentProject]){
                parentProj.pse__Project_Status__c = NSP_ServiceConstants.PROJECTSTATUSCANCELLED;
                parentProj.NSP_Cancelled_Reason__c = NSP_ServiceConstants.CANCELLED_REASON;
                listOfParentProject.add(parentProj);
            }

            if(!listOfParentProject.isEmpty()){
                Database.update(listOfParentProject, false);
            }
        }
    }


    /**
    * Update Template Name field on Project Task and Templates Used field on Project
    * @param projectTaskList List of project. 
    * @return void
    */

    public void updateTemplateNameOnProjectTaskAndTemplatesUsedOnProject(List<pse__Project_Task__c> projectTaskList){
        Set<Id> setOfProjectId = new Set<Id>();
        Map<Id, pse__Proj__c> mapOfProjectTaskIdAndProject = new Map<Id, pse__Proj__c>();

        for(pse__Project_Task__c projectTask : projectTaskList){
            if(projectTask.pse__Project__c != null){
                setOfProjectId.add(projectTask.pse__Project__c);
            }
        }

        for(pse__Proj__c project : [SELECT TemplateName__c, pse__Is_Template__c FROM pse__Proj__c WHERE ID IN : setOfProjectId]){
            if(!mapOfProjectTaskIdAndProject.containsKey(project.id)){
                mapOfProjectTaskIdAndProject.put(project.id, project);
            }
        }

        for(pse__Project_Task__c projectTask : projectTaskList){
            if(projectTask.pse__Project__c != null &&
               mapOfProjectTaskIdAndProject.get(projectTask.pse__Project__c).pse__Is_Template__c){
            projectTask.Template_Name__c = mapOfProjectTaskIdAndProject.get(projectTask.pse__Project__c).TemplateName__c;
            }
        }
    }
    
    /***********************************************************************************************
    * MethodName: assignQueueTasks
    * Description : This Method will update Queue as the Owner of MM and FSO projects   
    * Params:      List<pse__Project_Task__c> projectTaskList
    * Author :Nischay 
    * ********************************************************************************************/  
    public static void assignQueueTasks(List<pse__Project_Task__c> projectTaskList){
        try{ 
            Set<Id>projectIdSet = new set<Id>();
            // storing PEO Project recordtype
            Id peoProjectRecordTypeId = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
            Set<String> MMCoreQueueSet = new  Set<String>{NSP_ServiceConstants.IPIC, NSP_ServiceConstants.HWProducts};
            // searching for Queue's
            List<Group> MMCoreQueues= [Select Id ,Name,DeveloperNAME from Group WHERE Type=:NSP_ServiceConstants.GroupType AND DeveloperNAME IN:MMCoreQueueSet];
            Id IPICQueueId;
            Id HWQueueId;
            for(Group mmcoreQueue:MMCoreQueues){
                if(mmcoreQueue.DeveloperName==NSP_ServiceConstants.IPIC){
                    IPICQueueId=mmcoreQueue.Id;
                }else if(mmcoreQueue.DeveloperName==NSP_ServiceConstants.HWProducts){
                    HWQueueId=mmcoreQueue.Id;
                }
            }
            // store Project Task project Id in set 
            for(pse__Project_Task__c prjTask:projectTaskList){
                projectIdSet.add(prjTask.pse__Project__c);
            }
            // Searching for MM and FSO Projects 
            Map<Id,pse__Proj__c> projectMap= new Map<Id,pse__Proj__c>([Select Id,OwnerId, TemplateName__c, pse__End_Date__c from pse__Proj__c WHERE Id IN:projectIdSet  
                                                                       AND pse__Project_Type__c=:NSP_ServiceConstants.ImplementationProjectType AND
                                                                       (TemplateName__c = :label.Middle_Market_Implementation_Project OR TemplateName__c=  :label.FSOImplementationProject) AND recordTypeId=:peoProjectRecordTypeId   ]);
           // Assign Queue as the Owner of  Project tasks
            for(pse__Project_Task__c prjTask:projectTaskList){
                if(projectMap.containsKey(prjTask.pse__Project__c) && !MMCoreQueues.isEmpty()){
                    if( prjTask.Name==NSP_ServiceConstants.PayCodeClientTask
                       || prjTask.Name==NSP_ServiceConstants.ClientPackingTask || prjTask.Name==NSP_ServiceConstants.EnrollmentTask){
                           prjTask.OwnerId=IPICQueueId;
                       } else if(prjTask.Name==NSP_ServiceConstants.ClientOptumTask){
                           prjTask.OwnerId=HWQueueId;
                      }else if(prjTask.Name==NSP_ServiceConstants.CONFIGURATION){
                        prjTask.OwnerId=projectMap.get(prjTask.pse__Project__c).OwnerId;
                        
                                 
                    }
                }
            }
            
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_PROJECTTASKSTRIGGERHELPER, 'assignQueueTasks', ex.getMessage());
        } 
        
    }     

    /***********************************************************************************************
    * MethodName: updateEmailsTransitionToService
    * Description : Update ListToemails from Account Teams members emails
    * Story : STY-00711
    * Params: List<pse__Project_Task__c> newList
    * Params: Map<Id,pse__Project_Task__c> oldProjectTaskMap
    * ********************************************************************************************/ 
    public static void updateEmailsTransitionToService(List<pse__Project_Task__c> newList , Map<Id,pse__Project_Task__c> oldProjectTaskMap){
        try{   
            set<Id> setAccountIds = new set<Id>();
            List<NSP_Account_Team__c> lstAccTeams = new List<NSP_Account_Team__c>();
            Map<String,set<String>> mapAccTeamEmails = new Map<String,set<String>>();
            Map<String,NSP_Account_Team__c> mapAccTeamCLHR = new Map<String,NSP_Account_Team__c>();
            for(pse__Project_Task__c project : newList){
                if((oldProjectTaskMap == null && project.NSP_AccountId__c!=null) ||  (oldProjectTaskMap != null && project.NSP_AccountId__c !=null && oldProjectTaskMap.get(project.id).NSP_AccountId__c!=project.NSP_AccountId__c )){
                    setAccountIds.add(project.NSP_AccountId__c);
                }
            }
            if(!setAccountIds.isEmpty()){
                lstAccTeams =  getAccountTeamRecords(setAccountIds);
                mapAccTeamEmails = getCCAccountTeams(lstAccTeams);
                mapAccTeamCLHR = getAccountTeams(lstAccTeams);
            }
            for(pse__Project_Task__c proj : newList){
                if(mapAccTeamEmails.containsKey(proj.NSP_AccountId__c) && mapAccTeamEmails.get(proj.NSP_AccountId__c)!=null){
                    List<String> ccEmails = new List<String>();
                    ccEmails.addAll(mapAccTeamEmails.get(proj.NSP_AccountId__c));
                    proj.NSP_CC_Emails__c = String.join(ccEmails, ',');
                }
                if(mapAccTeamCLHR.containsKey(NSP_ServiceConstants.BUS_TEAM_HRSP_CL)){
                    proj.NSP_Client_Liaison_Name__c = mapAccTeamCLHR?.get(NSP_ServiceConstants.BUS_TEAM_HRSP_CL)?.NSP_First_Name__c +' '+mapAccTeamCLHR?.get(NSP_ServiceConstants.BUS_TEAM_HRSP_CL)?.NSP_Last_Name__c;
                    proj.NSP_Client_Liaison_Email__c = mapAccTeamCLHR?.get(NSP_ServiceConstants.BUS_TEAM_HRSP_CL)?.NSP_Email__c;
                    proj.NSP_HR_Specialist_Name__c = mapAccTeamCLHR?.get(NSP_ServiceConstants.BUS_TEAM_HRSP_CL)?.NSP_First_Name__c +' '+mapAccTeamCLHR?.get(NSP_ServiceConstants.BUS_TEAM_HRSP_CL)?.NSP_Last_Name__c;
                    proj.NSP_HR_Specialist_Email__c =  mapAccTeamCLHR?.get(NSP_ServiceConstants.BUS_TEAM_HRSP_CL)?.NSP_Email__c;
                }else if(mapAccTeamCLHR.containsKey(NSP_ServiceConstants.CLIENT_LIAISION) || mapAccTeamCLHR.containsKey(NSP_ServiceConstants.HRSpecialist)){
                    proj.NSP_Client_Liaison_Name__c = mapAccTeamCLHR?.get(NSP_ServiceConstants.CLIENT_LIAISION)?.NSP_First_Name__c +' '+mapAccTeamCLHR?.get(NSP_ServiceConstants.CLIENT_LIAISION)?.NSP_Last_Name__c;
                    proj.NSP_Client_Liaison_Email__c = mapAccTeamCLHR?.get(NSP_ServiceConstants.CLIENT_LIAISION)?.NSP_Email__c;
                    proj.NSP_HR_Specialist_Name__c = mapAccTeamCLHR?.get(NSP_ServiceConstants.HRSpecialist)?.NSP_First_Name__c +' '+mapAccTeamCLHR?.get(NSP_ServiceConstants.HRSpecialist)?.NSP_Last_Name__c;
                    proj.NSP_HR_Specialist_Email__c =  mapAccTeamCLHR?.get(NSP_ServiceConstants.HRSpecialist)?.NSP_Email__c;
                }
            }
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_PROJECTTASKSTRIGGERHELPER, 'updateEmailsTransitionToService', ex.getMessage());
        }
    }
    
    /***********************************************************************************************
    * MethodName: createHCMCaseOnProjectTaskUpdate
    * Description : Create HCM Case when Discovery Project Task status is Complete on 
    *               iSolved HCM Implementation project
    * Story : STY-02181
    * Params: List<pse__Project_Task__c> newProjectTaskList
    * Params: Map<Id,pse__Project_Task__c> oldProjectTaskMap
    * ********************************************************************************************/ 
   @future
    public static void createHCMCaseOnProjectTaskUpdate(Set<Id> projectTaskIdSet){
        try{
            List<Case> createCaseList = new List<Case>();

            List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
            //To get Project Tasks
            if(!projectTaskIdSet.isEmpty()){
            for(pse__Project_Task__c projectTask : [SELECT Id, Name, pse__Status__c, pse__Project__c, pse__Project__r.Name,
                                                    pse__Project__r.Project_Implementer__c, pse__Project__r.TemplateName__c
                                                    FROM pse__Project_Task__c
                                                        WHERE Id IN: projectTaskIdSet
                                                    AND pse__Project__c != null
                                                    AND pse__Project__r.Project_Implementer__c != null
                                                    AND pse__Project__r.TemplateName__c =:NSP_ServiceConstants.HCM_PROJECT_NAME 
                                                    AND Name =: NSP_ServiceConstants.PROJECT_TASK_DISCOVERY 
                                                    AND pse__Status__c =: NSP_ServiceConstants.TASKCOMPLETE
                                                   ]){
                    if(projectTask.pse__Status__c ==NSP_ServiceConstants.TASKCOMPLETE){
                    projectTaskList.add(projectTask);
                    }
                
                }
            }
            //Checking projectTaskList List not empty
            if(!projectTaskList.isEmpty()){
                createCaseList = createHCMCase(projectTaskList);
            }
            //Checking createCaseList Task List not empty
            if(!createCaseList.isEmpty()){
                //Inserting HCM Case 
                database.insert(createCaseList, false);
            }
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_PROJECTTASKSTRIGGERHELPER, 'createHCMCaseOnProjectTaskUpdate', ex.getMessage());
        }
    }

    /***********************************************************************************************
    * MethodName: createHCMCase
    * Description : Create HCM Case 
    * Story : STY-02181
    * Params: List<pse__Project_Task__c> projectTaskList
    * Params: Map<Id,pse__Project_Task__c> oldProjectTaskMap
    * ********************************************************************************************/
    private static List<Case> createHCMCase(List<pse__Project_Task__c> projectTaskList){

        //Variable declaration
        List<Case> createCaseList = new List<Case>();
        String dataTemplateContent;
        
        //Reading static resource 
        StaticResource srObject = [SELECT Id, Name, Body FROM StaticResource WHERE Name =:NSP_ServiceConstants.HCM_CASE_DATA_TEMPLATE LIMIT 1];
        
        if (srObject != null) {
            dataTemplateContent = srObject.body.toString();
        }
    
        //To get case recordtypeId
        Id recordTypeIdWxImpl = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.CASE_OBJECT_NAME,NSP_ServiceConstants.WX_IMPL);

        for(pse__Project_Task__c projTask : projectTaskList){

            Case hcmCase = new Case();
            hcmCase.RecordTypeId = recordTypeIdWxImpl;
            hcmCase.Subject = NSP_ServiceConstants.HCM_CASE_SUBJECT+projTask.pse__Project__r.Name;
            hcmCase.OwnerId = projTask.pse__Project__r.Project_Implementer__c;    
            hcmCase.Status = NSP_ServiceConstants.OPEN;
            hcmCase.NSP_Case_Sub_Status__c = NSP_ServiceConstants.CASE_SUB_STATUS_NOT_STARTED;
            hcmCase.NSP_Opened_Date__c = Date.Today();
            hcmCase.Priority = NSP_ServiceConstants.MEDIUM;
            hcmCase.NSP_Category__c = NSP_ServiceConstants.CASE_CATEGORY_WX_WA;
            hcmCase.NSP_SubCategory__c = NSP_ServiceConstants.CASE_SUB_CATEGORY_PROJECTS;
            hcmCase.NSP_Detail__c = NSP_ServiceConstants.CASE_DETAIL_HCM_AUDIT;
            hcmCase.NSP_Assigned_Queue__c = NSP_ServiceConstants.CASE_ASIGNED_QUEUE_WX_IMPL_SUPPORT;
            hcmCase.Project__c = projTask.pse__Project__c;
            hcmCase.NSP_Data_Template__c = dataTemplateContent;
            createCaseList.add(hcmCase);
        }
        return createCaseList;
    }

    private static Map<String,set<String>> getCCAccountTeams(List<NSP_Account_Team__c> accTeamRecords){
        Map<String,set<String>> mapAccTeamEmails = new Map<String,set<String>>();
        for(NSP_Account_Team__c accTeam: accTeamRecords){
            if(mapAccTeamEmails.containsKey(accTeam.NSP_Account__c)){
                mapAccTeamEmails.get(accTeam.NSP_Account__c).add(accTeam.NSP_Email__c);
            }else{
                mapAccTeamEmails.put(accTeam.NSP_Account__c,new set<String>{accTeam.NSP_Email__c});
            }
        }
        return mapAccTeamEmails;
    }
    
    private static Map<String,NSP_Account_Team__c> getAccountTeams(List<NSP_Account_Team__c> accTeamRecords){
        Map<String,NSP_Account_Team__c> mapAccTeamCLHR = new Map<String,NSP_Account_Team__c>();
        for(NSP_Account_Team__c accTeam: accTeamRecords){
            if(accTeam.NSP_Role__c == NSP_ServiceConstants.BUS_TEAM_HRSP_CL){
                mapAccTeamCLHR.put(NSP_ServiceConstants.BUS_TEAM_HRSP_CL, accTeam);
            }
            if(accTeam.NSP_Role__c == NSP_ServiceConstants.CLIENT_LIAISION){
                mapAccTeamCLHR.put(NSP_ServiceConstants.CLIENT_LIAISION, accTeam);
            }
            if(accTeam.NSP_Role__c == NSP_ServiceConstants.HRSpecialist){
                mapAccTeamCLHR.put(NSP_ServiceConstants.HRSpecialist, accTeam);
            }
        }
        return mapAccTeamCLHR;
    }
    
    private static List<NSP_Account_Team__c> getAccountTeamRecords(Set<Id> setAccountIds){
        List<String> lstAccTeamRoles = new List<String>{NSP_ServiceConstants.MANAGER_HRSERVICES,NSP_ServiceConstants.PAYROLL_SUPERVISOR,
            NSP_ServiceConstants.CLIENT_LIAISION,NSP_ServiceConstants.HRSpecialist,NSP_ServiceConstants.PayrollSpecialist,
            NSP_ServiceConstants.PERFOMANCE_SPECIALIST,NSP_ServiceConstants.SAFETY_CONSULTANT,NSP_ServiceConstants.BUS_TEAM_HRSP_CL,
            NSP_ServiceConstants.MID_MARKET_ACC_EX,NSP_ServiceConstants.NATIONAL_ACC_EX};
                return [SELECT Id,NSP_Email__c,NSP_Account__c,NSP_First_Name__c,NSP_Last_Name__c,NSP_Role__c FROM NSP_Account_Team__c 
                        WHERE NSP_Account__c IN:setAccountIds AND NSP_Role__c IN:lstAccTeamRoles];
    }
    
    
    /***********************************************************************************************
    * MethodName  : checkStatusComplete
    * Description : This Method updated the NSP_Is_Status_Completed__c checkbox on Project Task
    * Params:     : Map<Id, pse__Project_Task__c> newMap,Map<Id, pse__Project_Task__c> oldMap
    * ********************************************************************************************/

    public static void checkStatusComplete(Map<Id, pse__Project_Task__c> newMap,Map<Id, pse__Project_Task__c> oldMap){
        try{
            for(pse__Project_Task__c projTask :newMap.values() ){
                // update the flag when first time the NSP_Is_Status_Completed__c is set to Complete
                if(projTask.pse__Status__c !=null && 
                   oldMap.get(projTask.Id).pse__Status__c != NSP_ServiceConstants.PROJECTSTATUSCOMPLETED && 
                   projTask.pse__Status__c == NSP_ServiceConstants.PROJECTSTATUSCOMPLETED && !oldMap.get(projTask.Id).NSP_Is_Status_Completed__c){
                       projTask.NSP_Is_Status_Completed__c = true;
                }
            }
        }catch(Exception ex ){
           NSP_ErrorLogHandler.logSaveException(NSP_PROJECTTASKSTRIGGERHELPER, 'beforeUpdate', ex.getMessage());
        }
    }
    
    /***********************************************************************************************
    * MethodName: createCasesOnProjectTasksUpdate
    * Description : Create First Live Payroll Case when Go Live Project Task status is Complete on 
    *               iSolved HCM Implementation project
    * Story : STY-02182
    * Params: List<pse__Project_Task__c> newProjectTaskList
    * Params: Map<Id,pse__Project_Task__c> oldProjectTaskMap
    * ********************************************************************************************/ 
    
    public static void createCasesOnProjectTasksUpdate(Set<Id> newProjectTaskIds ){
        List<pse__Project_Task__c> projTasksList = new List<pse__Project_Task__c>();
        try{
            for(pse__Project_Task__c projTaskRec: [SELECT Id, Name, pse__Status__c, NSP_Is_Status_Completed__c,
                                                   pse__Project__c, pse__Project__r.Name,
                                                   pse__Project__r.TemplateName__c, pse__Project__r.Project_Implementer__c
                                                   FROM pse__Project_Task__c
                                                   WHERE Id IN: newProjectTaskIds
                                                  
                                                   AND pse__Project__r.Project_Implementer__c != NULL
                                                   AND pse__Project__r.TemplateName__c =: NSP_ServiceConstants.HCM_PROJECT_NAME
                                                   
                                                  ]){
                                                      //if the project task status is set to 'Complete' for the first time
                                                     
                                                             projTasksList.add(projTaskRec);
                                                         
                                                  }
            if(!projTasksList.isEmpty()){
                createCaseForISolvedHCMProj(projTasksList);
            }
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_PROJECTTASKSTRIGGERHELPER, 'createCasesOnProjectTasksUpdate', ex.getMessage());
        }
    }
    
    /***********************************************************************************************
    * MethodName: createCaseForISolvedHCMProj
    * Description : Helper mehtod for createCasesOnProjectTasksUpdate which will create a case 
    * 				and send an email to project implementer
    * Story : STY-02182
    * Params: List<pse__Project_Task__c> projTaskList
    * ********************************************************************************************/ 
    
    private static void createCaseForISolvedHCMProj(List<pse__Project_Task__c> projTaskList){
        List<Case> createCaseList = new List<Case>();
        List<String> emailTempFields = new List<String>{'ID'};
        List<Messaging.SingleEmailMessage> lstEmailMessages = new List<Messaging.SingleEmailMessage>();
        List<String> sendToList = new List<String>();
        //Get WX IMPL Case RecordType
        Id recordTypeIdWxImpl = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.CASE_OBJECT_NAME,NSP_ServiceConstants.WX_IMPL);
        //Get email template
        EmailTemplate emailTemplate = NSP_sObjectSelector.selectByDeveloperName(emailTempFields, 'NSP_First_Live_Payroll_Case_Creation_Email');
OrgWideEmailAddress orgWideAddress;
        if(Label.NSP_Report_Dev_OrgWideEmail != null && !Test.isRunningTest()){
            List<String> orgWideEmailFields = new List<String>{'Id'};
                String query = new NSP_QueryBuilder(NSP_ServiceConstants.ORG_WIDE_EMAIL_SOBJECT_TYPE, orgWideEmailFields)
                .addFilter('Address', Label.NSP_Report_Dev_OrgWideEmail).setSecurityEnforce(false).build();
            orgWideAddress = Database.query(query);
        }
        //for each project task create a case
        for(pse__Project_Task__c projTaskRec: projTaskList){
            Case newCase = new Case();
            newCase.RecordTypeId = recordTypeIdWxImpl;
            newCase.Subject = NSP_ServiceConstants.FIRST_LIVE_PAYROLL_CASE_SUB + projTaskRec.pse__Project__r.Name;
            newCase.OwnerId = projTaskRec.pse__Project__r.Project_Implementer__c;
            newCase.Status = NSP_ServiceConstants.OPEN;
            newCase.NSP_Case_Sub_Status__c = NSP_ServiceConstants.CASE_SUB_STATUS_NOT_STARTED;
            newCase.NSP_Opened_Date__c = System.Today();
            newCase.Priority = NSP_ServiceConstants.MEDIUM;
            newCase.NSP_Category__c = NSP_ServiceConstants.CASE_CATEGORY_WX_WA;
            newCase.NSP_SubCategory__c = NSP_ServiceConstants.CASE_SUB_CATEGORY_PROJECTS;
            newCase.NSP_Detail__c = NSP_ServiceConstants.FIRST_LIVE_PAYROLL_DETAIL;
            newCase.NSP_Data_Template__c = NSP_ServiceConstants.FIRST_LIVE_PAYROLL_DATA_TEMPLATE;
            newCase.NSP_Assigned_Queue__c = NSP_ServiceConstants.CASE_ASIGNED_QUEUE_WX_IMPL_SUPPORT;
            newCase.Project__c = projTaskRec.pse__Project__c;
            createCaseList.add(newCase);
        }
        if(!createCaseList.isEmpty()){
            Database.insert(createCaseList, false);
        }
        //for each case record created send an email
        for(Case eachCase: [SELECT Id, Project__c, Project__r.Project_Implementer__c
                            FROM Case 
                            WHERE Id IN: createCaseList]){
            sendToList.add(eachCase.Project__r.Project_Implementer__c);                 
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email= Messaging.renderStoredEmailTemplate(emailTemplate.Id, null , eachCase.Id);
            email.setTemplateId(emailTemplate.Id); 
            email.setToAddresses(sendToList);
            email.setWhatId(eachCase.Id);
            email.setSaveAsActivity(false);
            if(orgWideAddress != null && orgWideAddress.Id != null && !Test.isRunningTest()){
                email.setOrgWideEmailAddressId(orgWideAddress.Id);
            }
            lstEmailMessages.add(email);
        }
        if(!lstEmailMessages.isEmpty()){
            Messaging.sendEmail(lstEmailMessages);
        } 
    }
    
    /***********************************************************************************************
    * MethodName: createNewTaxIMPLSubProject
    * Description : Create New Tax IMPL sub project
    * Story : STY-02157
    * Params: List<pse__Project_Task__c> projectTaskList
    * Params: Map<Id,pse__Project_Task__c> oldProjectTaskMap
    * ********************************************************************************************/
    @future
    public static void createNewTaxIMPLSubProject(Set<Id> projectTaskIdSet){
        try{
            Id templateProjectId;
            Date startDateForProject;
            String projectName;
            List<pse__Proj__c> childProjectList = new List<pse__Proj__c>();
            List<pse__Proj__c> projListToUpdate = new List<pse__Proj__c>();
            List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
            Set<Id> parentProjectIdSet = new Set<Id>();
            Set<Id> newProjectIdSet = new Set<Id>();
            Map<Id, Id> projectIdWithAccountIdMap = new Map<Id, Id>();
                        List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest> projRequestList = new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest>();
            pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest projRequest;
            
            //Querying Project Template            
            List<String> projectFields = new List<String>{'Id','Name','Project_Coordinator__c','Project_Implementer__c'};
            String query = new NSP_QueryBuilder('pse__Proj__c', projectFields)
                            .addFilter('Name', NSP_ServiceConstants.NEW_TAX_IMPL_PROJECT)
                            .addFilter('pse__Is_Template__c', true).addLimit(1).build();
            pse__Proj__c projectTemplate = Database.query(query);
            
            //To get Project Tasks
            for(pse__Project_Task__c projectTask : [SELECT Id, Name, pse__Status__c, pse__Project__c, pse__Project__r.Name,
                                                    pse__Project__r.TemplateName__c,
                                                    pse__Project__r.pse__Account__c
                                                    FROM pse__Project_Task__c
                                                    WHERE Id IN: projectTaskIdSet
                                                    AND pse__Project__c != null
                                                    AND pse__Project__r.TemplateName__c =:NSP_ServiceConstants.HCM_PROJECT_NAME 
                                                    AND Name =: NSP_ServiceConstants.CONFIGURATION_TASK
                                                    AND pse__Status__c =: NSP_ServiceConstants.TASKCOMPLETE
                                                   ]){
                if(projectTask.pse__Status__c == NSP_ServiceConstants.TASKCOMPLETE){
                    projectTaskList.add(projectTask);

                    if(projectTemplate != null){
                        templateProjectId = Id.valueOf(projectTemplate.Id);//Template project Id used to clone the new project.
                        startDateForProject = Date.Today();// Provide a project start date.
                        projectName = projectTemplate.Name;
                    }
                    
                    if(templateProjectId != null){
                        projRequest = NSP_CreateProjectUsingKey.createProjectFromTemplate(templateProjectId, startDateForProject, projectName);
                        projRequestList.add(projRequest);
                        parentProjectIdSet.add(projectTask.pse__Project__c);
                        projectIdWithAccountIdMap.put(projectTask.pse__Project__c, projectTask.pse__Project__r.pse__Account__c);
                                                                                   }
                }
                
            }

            //Getting list of child project 
            if(!parentProjectIdSet.isEmpty()){            
                List<String> projFields = new List<String>{'Id','Name'};
                String queryProject = new NSP_QueryBuilder('pse__Proj__c', projFields)
                    .addFilter('pse__Parent_Project__c', new List<Id>(parentProjectIdSet), NSP_QueryBuilder.Operator.INCLUDES)
                    .addContainsFilter('Name', NSP_ServiceConstants.NEW_TAX_IMPL_PROJECT).build();
                childProjectList = (List<pse__Proj__c>)Database.query(queryProject);
            }
            
            //send email alert when confiuration task status is complete
            if(!projectTaskList.isEmpty() && childProjectList.size() == 0){
                configurationTaskCompletionEmail(projectTaskList);
            }
            
            // Creating Project and Deleting Budget
            if(!projRequestList.isEmpty() && childProjectList.size() == 0){
                newProjectIdSet = NSP_CreateProjectUsingKey.createProjectAndDeleteBudget(projRequestList);
            }

            //Linking newly created project with parent project
            if(!newProjectIdSet.isEmpty() && !parentProjectIdSet.isEmpty() && projectTemplate != null && childProjectList.size() == 0){
                for(Id newProjectId : newProjectIdSet){
                    projListToUpdate = linkProjectWithParentProject(newProjectId, parentProjectIdSet, projectIdWithAccountIdMap, projectTemplate);
                }
            }
            
            if(!projListToUpdate.isEmpty() && childProjectList.size() == 0){
                Database.SaveResult[] projectUpdateList = Database.update(projListToUpdate,false);
                NSP_ErrorLogHandler.logSaveResultsException(NSP_PROJECTTASKSTRIGGERHELPER, 'createNewTaxIMPLSubProject:ProjectUpdate', projectUpdateList);
            }
            
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_PROJECTTASKSTRIGGERHELPER, 'createNewTaxIMPLSubProject', ex.getMessage());
        }
    }
    
     /***********************************************************************************************
    * MethodName: createWXWADataMigrationSubProject
    * Description : Create New Tax IMPL sub project
    * Story : STY-02158
    * Params: List<pse__Project_Task__c> projectTaskList
    * Params: Map<Id,pse__Project_Task__c> oldProjectTaskMap
    * ********************************************************************************************/
    @future
    public static void createWXWADataMigrationSubProject(Set<Id> projectTaskIdSet){
        try{
            Id templateProjectId;
            Date startDateForProject;
            String projectName;
            List<pse__Proj__c> childProjectList = new List<pse__Proj__c>();
            Set<Id> newProjectIdSet = new Set<Id>();
            List<pse__Proj__c> projListToUpdate = new List<pse__Proj__c>();
            Set<Id> parentProjectIdSet = new Set<Id>();
            Map<Id, Id> projectIdWithAccountIdMap = new Map<Id, Id>();
                        List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest> projRequestList = new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest>();
            pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest projRequest;
            
            //Querying Project Template            
            List<String> projectFields = new List<String>{'Id','Name','Project_Coordinator__c','Project_Implementer__c'};
            String query = new NSP_QueryBuilder('pse__Proj__c', projectFields)
                            .addFilter('Name', NSP_ServiceConstants.WX_WA_DATA_MIGRATION_PROJECT)
                            .addFilter('pse__Is_Template__c', true).addLimit(1).build();
            pse__Proj__c projectTemplate = Database.query(query);
            
            //To get Project Tasks
            for(pse__Project_Task__c projectTask : [SELECT Id, Name, pse__Status__c, pse__Project__c, pse__Project__r.Name,
                                                    pse__Project__r.TemplateName__c,
                                                    pse__Project__r.pse__Account__c
                                                    FROM pse__Project_Task__c
                                                    WHERE Id IN: projectTaskIdSet
                                                    AND pse__Project__c != null
                                                    AND pse__Project__r.TemplateName__c =:NSP_ServiceConstants.HCM_PROJECT_NAME 
                                                    AND Name =: NSP_ServiceConstants.CONFIGURATION_TASK
                                                    AND pse__Status__c =: NSP_ServiceConstants.TASKCOMPLETE
                                                   ]){
                if(projectTask.pse__Status__c == NSP_ServiceConstants.TASKCOMPLETE){

                    if(projectTemplate != null){
                        templateProjectId = Id.valueOf(projectTemplate.Id);//Template project Id used to clone the new project.
                        startDateForProject = Date.Today();// Provide a project start date.
                        projectName = projectTemplate.Name;
                    }
                    
                    if(templateProjectId != null){
                        projRequest = NSP_CreateProjectUsingKey.createProjectFromTemplate(templateProjectId, startDateForProject, projectName);
                        projRequestList.add(projRequest);
                        parentProjectIdSet.add(projectTask.pse__Project__c);
                        projectIdWithAccountIdMap.put(projectTask.pse__Project__c, projectTask.pse__Project__r.pse__Account__c);
                                                                                   }
                }
                
            }

            //Getting list of child project
            if(!parentProjectIdSet.isEmpty()){            
                List<String> projFields = new List<String>{'Id','Name'};
                String queryProject = new NSP_QueryBuilder('pse__Proj__c', projFields)
                    .addFilter('pse__Parent_Project__c', new List<Id>(parentProjectIdSet), NSP_QueryBuilder.Operator.INCLUDES)
                    .addContainsFilter('Name', NSP_ServiceConstants.WX_WA_DATA_MIGRATION_PROJECT).build();
                childProjectList = (List<pse__Proj__c>)Database.query(queryProject);
            }

            // Creating Project and Deleting Budget
            if(!projRequestList.isEmpty() && childProjectList.size() == 0){
                newProjectIdSet = NSP_CreateProjectUsingKey.createProjectAndDeleteBudget(projRequestList);
            }

            //Linking newly created project with parent project
            if(!newProjectIdSet.isEmpty() && !parentProjectIdSet.isEmpty() && projectTemplate != null && childProjectList.size() == 0){
                for(Id newProjectId : newProjectIdSet){
                    projListToUpdate = linkProjectWithParentProject(newProjectId, parentProjectIdSet, projectIdWithAccountIdMap, projectTemplate);
                }
            }
             
            if(!projListToUpdate.isEmpty() && !newProjectIdSet.isEmpty() && childProjectList.size() == 0){
                Database.SaveResult[] projectUpdateList = Database.update(projListToUpdate,false);
                //send email
                wxwaDataMigrationProjectCreationEmail(newProjectIdSet);
                NSP_ErrorLogHandler.logSaveResultsException(NSP_PROJECTTASKSTRIGGERHELPER, 'createWXWADataMigrationSubProject:ProjectUpdate', projectUpdateList);
            }
            
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_PROJECTTASKSTRIGGERHELPER, 'createWXWADataMigrationSubProject', ex.getMessage());
        }
    }
    /***********************************************************************************************
    * MethodName: linkProjectWithParentProject
    * Description : Link New Tax IMPL project with Parent Project
    * Story : STY-02157
    * Params: Id projectId, Id parentId
    * ********************************************************************************************/
    public static List<pse__Proj__c> linkProjectWithParentProject(Id projectId, Set<Id> parentProjectIdSet, Map<Id, Id> projectIdWithAccountIdMap, pse__Proj__c projTemplate){
        List<pse__Proj__c> projectList = new List<pse__Proj__c>();
        for(Id parentProjectId : parentProjectIdSet){
            pse__Proj__c newProject = new pse__Proj__c();
            newProject.Id = projectId;
            newProject.pse__Parent_Project__c = parentProjectId;
                        newProject.pse__Account__c = projectIdWithAccountIdMap.get(parentProjectId);
                            newProject.pse__End_Date__c = Date.Today().addDays(90);
            if(projTemplate.Project_Implementer__c != null){
                newProject.Project_Implementer__c = projTemplate.Project_Implementer__c;
            }
            if(projTemplate.Project_Coordinator__c != null){
                newProject.Project_Coordinator__c = projTemplate.Project_Coordinator__c;
            }
            projectList.add(newProject);  
        }
        return projectList;
    }

    /***********************************************************************************************
    * MethodName: configurationTaskCompletionEmail
    * Description : Send Email when iSolved HCM Project Configuration Task is complete 
    * Story : STY-02157
    * Params: List<pse__Project_Task__c> ProjectTaskList
    * ********************************************************************************************/
    public static void configurationTaskCompletionEmail(List<pse__Project_Task__c> ProjectTaskList){
        List<Messaging.SingleEmailMessage> lstEmailMessages = new List<Messaging.SingleEmailMessage>();
        List<String> emailTempFields = new List<String>{'Id'};      
        EmailTemplate emailTemplate = NSP_sObjectSelector.selectByDeveloperName(emailTempFields, 'NSP_Isolved_HCM_Configuration_Task_Completion_Email');
        List<String> sendToList = new List<String>{System.Label.HCM_Case_Email_Send_To_Address,System.Label.NSP_Tes_Tax_Email_Address};
            for(pse__Project_Task__c projectTaskRec: [SELECT Id FROM pse__Project_Task__c WHERE Id IN: ProjectTaskList]){
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email= Messaging.renderStoredEmailTemplate(emailTemplate.Id, UserInfo.getUserId() , projectTaskRec.Id);
                email.setTemplateId(emailTemplate.Id); 
                email.setToAddresses(sendToList);
                email.setWhatId(projectTaskRec.Id);  
                email.setSaveAsActivity(false);
                lstEmailMessages.add(email);
            }
        if(!lstEmailMessages.isEmpty() && !Test.isRunningTest()){
            //send email alert
            Messaging.sendEmail(lstEmailMessages);
        }
    }

    /***********************************************************************************************
    * MethodName: wxwaDataMigrationProjectCreationEmail
    * Description : Send Email when WX/WA Data Migration Project is created 
    * Story : STY-02158
    * Params: Set<Id> projectIdSet
    * ********************************************************************************************/
    public static void wxwaDataMigrationProjectCreationEmail(Set<Id> projectIdSet){
        List<Messaging.SingleEmailMessage> lstEmailMessages = new List<Messaging.SingleEmailMessage>();
        List<String> emailTempFields = new List<String>{'Id'};      
        EmailTemplate emailTemplate = NSP_sObjectSelector.selectByDeveloperName(emailTempFields, 'NSP_WXWA_Data_Migration_Project_Creation_Email');
        List<String> sendToList = new List<String>{System.Label.NSP_TES_Data_Team_Email_Address};
            for(pse__Proj__c projectRec: [SELECT Id FROM pse__Proj__c WHERE Id IN: projectIdSet]){
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email= Messaging.renderStoredEmailTemplate(emailTemplate.Id, UserInfo.getUserId() , projectRec.Id);
                email.setTemplateId(emailTemplate.Id); 
                email.setToAddresses(sendToList);
                email.setWhatId(projectRec.Id);  
                email.setSaveAsActivity(false);
                lstEmailMessages.add(email);
            }
        if(!lstEmailMessages.isEmpty() && !Test.isRunningTest()){
            //send email alert
            Messaging.sendEmail(lstEmailMessages);
        }
    }
    
/***********************************************************************************************
* MethodName: sendEmailToProjectResource
* Description : Method to send an email to proj resource when higher peer order proj task is completed.
* Params: List<pse__Project_Task__c> newProjectTaskList, Map<Id, pse__Project_Task__c> projectTaskOldMap
* Story : STY-02213
* ********************************************************************************************/ 
    public static void sendEmailToProjectResource(Set<Id> projectTaskIdSet){
        //A list to store all RET Templates
        List<String> retTemplateNames = System.Label.NSP_RET_Project_Templates.split(',');
        //Map of project and current project task
        Map<Id, pse__Project_Task__c> mapOfProjAndProjTask = new Map<Id, pse__Project_Task__c>();
        //Map of Project and the resource email address
        Map<Id, Map<String, String>> mapOfProjAndResourceEmail = new Map<Id, Map<String, String>>();
        
        try{
            for(pse__Project_Task__c projTask: [SELECT Id, Name, pse__Order__c, pse__Status__c, pse__Project__r.TemplateName__c, Responsible_Party__c 
                                                FROM pse__Project_Task__c WHERE Id IN: projectTaskIdSet AND pse__Project__r.TemplateName__c IN :retTemplateNames]){
                
                                                                mapOfProjAndProjTask.put(projTask.pse__Project__c, projTask);
                   
            }
            
            List<String> projTaskFields = new List<String>{'Id', 'Name', 'pse__Project__c', 'pse__Order__c', 'Responsible_Party__c'};
                
                //Get a list of all the project task associated with the parent project
            String query = new NSP_QueryBuilder('pse__Project_Task__c', projTaskFields)
                               .addFilter('pse__Project__c',  new List<Id>(mapOfProjAndProjTask.keySet()), NSP_QueryBuilder.Operator.INCLUDES).build();
            List<pse__Project_Task__c> listOfAllPrjTaskForAProject = (List<pse__Project_Task__c>) Database.query(query);
            
            for(pse__Resource_Request__c resourceRequest: [SELECT Id, pse__Resource_Role__c, pse__Staffer_Resource__r.pse__Salesforce_User__r.Email, pse__Project__c
                                                           FROM pse__Resource_Request__c
                                                           WHERE pse__Project__c IN: mapOfProjAndProjTask.keySet()]){
                                                               if(!mapOfProjAndResourceEmail.containsKey(resourceRequest.pse__Project__c)){
                                                                   mapOfProjAndResourceEmail.put(resourceRequest.pse__Project__c, new Map<String,String>());
                                                               }
                                                               mapOfProjAndResourceEmail.get(resourceRequest.pse__Project__c).put(resourceRequest.pse__Resource_Role__c, resourceRequest.pse__Staffer_Resource__r.pse__Salesforce_User__r.Email);
                                                           }
            
            //If the next in line projTask Responsibe party is diff send an email to the proj resource who's resource role matches with the next in line projTask's Responsibe party
            if(!listOfAllPrjTaskForAProject.isEmpty() && !mapOfProjAndResourceEmail.isEmpty()){        
                for(pse__Project_Task__c projTask : listOfAllPrjTaskForAProject){
                    if(projTask.pse__Order__c == mapOfProjAndProjTask.get(projTask.pse__Project__c).pse__Order__c+1 &&
                       projTask.Responsible_Party__c != mapOfProjAndProjTask.get(projTask.pse__Project__c).Responsible_Party__c &&
                       mapOfProjAndResourceEmail.containsKey(projTask.pse__Project__c) && 
                       mapOfProjAndResourceEmail.get(projTask.pse__Project__c).containsKey(projTask.Responsible_Party__c)){
                           sendEmailNotificationToResource(mapOfProjAndProjTask.get(projTask.pse__Project__c).Name, mapOfProjAndResourceEmail.get(projTask.pse__Project__c).get(projTask.Responsible_Party__c), projTask.Id);
                       }
                }
            }
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_PROJECTTASKSTRIGGERHELPER, 'sendEmailToProjectResource', ex.getMessage());
        }
    }
    
    /***********************************************************************************************
    * MethodName: sendEmailNotificationToResource
    * Description : Helper method for sendEmailToProjectResource
    * Params: String nextInLineProjTask, String completedProjTask, String sendToUserAddress, Id projTaskId
    * Story : STY-02213
    * ********************************************************************************************/ 
    
    private static void sendEmailNotificationToResource(String completedProjTask, String sendToUserAddress, Id projTaskId){
        //list to store to email address
        List<String> toEmailAddress = new List<String>();
        toEmailAddress.add(sendToUserAddress);
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        List<String> emailTempFields = new List<String>{'ID'};
        //Get email template
        EmailTemplate emailTemplate = NSP_sObjectSelector.selectByDeveloperName(emailTempFields, 'NSP_Send_email_to_resource');
        Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(emailTemplate.Id, NULL, projTaskId);
        email.setTemplateId(emailTemplate.Id); 
        email.setToAddresses(toEmailAddress);
        //replace '$resource$' in the email template body with the completed project task name
        String emailBody = email.getHtmlBody().replace('$resource$', completedProjTask);
        email.setHtmlBody(emailBody);
        email.setSaveAsActivity(false);
        emailList.add(email);
        
        //send email
        if(!emailList.isEmpty()){
            Messaging.sendEmail(emailList);
        }
    }

    /***********************************************************************************************
    * MethodName: beforeUpdateDirector
    * Description : before update director mehtod
    * Params: List<pse__Project_Task__c> newProjectTasks
    * Params:  Map<Id, pse__Project_Task__c> oldProjectTaskMap
    * ********************************************************************************************/ 
    public void beforeUpdateDirector(List<pse__Project_Task__c> newProjectTasks, Map<Id, pse__Project_Task__c> oldProjectTaskMap){
        // Get filtered data on the basis of different conditions
        Map<String, Object> filteredData = getBeforeUpdateFilteredData(newProjectTasks, oldProjectTaskMap);

        // Perform before update operations if required data is present 
        doBeforeUpdateActions(filteredData);
    }

    /***********************************************************************************************
    * MethodName: getBeforeUpdateFilteredData
    * Description : filter before update Records
    * Params: List<pse__Project_Task__c> newProjectTasks
    * Params:  Map<Id, pse__Project_Task__c> oldProjectTaskMap
    * ********************************************************************************************/ 
    private Map<String, Object> getBeforeUpdateFilteredData(List<pse__Project_Task__c> newProjectTasks, Map<Id, pse__Project_Task__c> oldProjectTaskMap){
        Map<String, Object> dataMap = new Map<String, Object>();
        try{
            List<pse__Project_Task__c> scheduledProjectTasks = new List<pse__Project_Task__c>();
            Set<Id> scheduledProjectTaskOwnerIds = new Set<Id>();
            Set<Id> projectTaskId = new Set<Id>();

            for (pse__Project_Task__c projectTask : newProjectTasks) {
                pse__Project_Task__c priorProjectTask = oldProjectTaskMap.get(projectTask.Id);
                //STY-03891
                // When Status field on project task is changed to "Scheduled"
                if(isStatusChangedToScheduled(projectTask, priorProjectTask)){
                    scheduledProjectTasks.add(projectTask);
                    scheduledProjectTaskOwnerIds.add(projectTask.OwnerId);
                    projectTaskId.add(projectTask.Id);
                }
                //STY-03891
                // When Create Work Order is checked and Dispatch Region populated
                if( projectTask.NSP_Create_Work_Order__c != priorProjectTask.NSP_Create_Work_Order__c && String.isNotBlank(projectTask.NSP_Dispatch_Region__c)){
                    projectTask.pse__Status__c = 'Unscheduled';
                }

                

        //Added as part of story STY-04172
        if( projectTask.NSP_Create_Work_Order__c != null && String.isNotBlank(projectTask.NSP_Dispatch_Region__c)){
                
                if(projectTask.pse__Start_Date_Time__c == projectTask.pse__End_Date_Time__c){
                    projectTask.pse__End_Date_Time__c = projectTask.pse__Start_Date_Time__c.addHours(1);
                                   
            }
                else if (projectTask.pse__End_Date_Time__c == null){
                    projectTask.pse__End_Date_Time__c = projectTask.pse__Start_Date_Time__c.addHours(1);
            }
            
        }

            }

            // Populate all the filtered data in the map
            dataMap.put('scheduledProjectTasks', scheduledProjectTasks);
            dataMap.put('scheduledProjectTaskOwnerIds', scheduledProjectTaskOwnerIds);
            dataMap.put('projectTaskIds', projectTaskId);
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_PROJECTTASKSTRIGGERHELPER, 'getBeforeUpdateFilteredData', ex.getMessage());
        }
        return dataMap;
    }

     /***********************************************************************************************
    * MethodName: doBeforeUpdateActions
    * Description : before Update Actions
    * Params: Map<String, Object> filteredDataMap
    * ********************************************************************************************/ 
    private void doBeforeUpdateActions(Map<String, Object> filteredDataMap){
        List<pse__Project_Task__c> scheduledProjectTasks = (List<pse__Project_Task__c>) filteredDataMap.get('scheduledProjectTasks');
        Set<Id> scheduledProjectTaskOwnerIds = (Set<Id>) filteredDataMap.get('scheduledProjectTaskOwnerIds');
        Set<Id> projectTaskId = (Set<Id>) filteredDataMap.get('projectTaskIds');

        // STY-03891
        // Check filtered list & call respective method if there is any record available
        if(projectTaskId != null && !scheduledProjectTasks.isEmpty()){
            assignResourceToServiceAppointment(scheduledProjectTasks, scheduledProjectTaskOwnerIds , projectTaskId);
        }
        
    }

     /***********************************************************************************************
    * MethodName: assignResourceToServiceAppointment
    * Description : assuign Resource to SA before Scheduling
    * Params: List<pse__Project_Task__c> projectTasks
    * Params: Set<Id> ownerIds
    * Params: Set<Id> projectTaskId
    * STY-03891
    * ********************************************************************************************/ 
    private void assignResourceToServiceAppointment(List<pse__Project_Task__c> projectTasks, Set<Id> ownerIds, Set<Id> projectTaskId ){
        Map<Id,Id> mapUserIdsToServiceResource = new Map<Id,Id>();
        Map<Id,WorkOrder> mapPtIDToWo = new Map<Id,WorkOrder>();
        Map<Id,pse__Project_Task__c> mapWoIdToPt = new Map<Id,pse__Project_Task__c>();
        List<WorkOrder> woListToUpdate = new List<WorkOrder>();

        for(ServiceResource serviceResource : [SELECT Id, RelatedRecordId FROM ServiceResource WHERE RelatedRecordId IN :ownerIds]){
            mapUserIdsToServiceResource.put( serviceResource.RelatedRecordId , serviceResource.Id );
        }

        for( WorkOrder eachWo : [SELECT Id,Status,NSP_Project_Task__c,OwnerId,StartDate FROM WorkOrder WHERE NSP_Project_Task__c IN: projectTaskId]){
            mapPtIDToWo.put( eachWo.NSP_Project_Task__c , eachWo);
        }
        
        for (pse__Project_Task__c projectTask : projectTasks) {
            
            //check if Owner is not valid Service Resource 
            if( mapUserIdsToServiceResource.get(projectTask.OwnerId) == null ){
                projectTask.pse__Status__c.addError(System.Label.NSP_Owner_Not_Valid_Resource);
            }
            //Check if related WO is not there 
            else if( mapPtIDToWo.get( projectTask.ID ) == null ){
                projectTask.pse__Status__c.addError(System.Label.NSP_ProjectTask_Unschedule_Validation);
            }
            //check if Start and end date is not populated 
            else if( projectTask.pse__Start_Date_Time__c == null || projectTask.pse__End_Date_Time__c == null ){
                projectTask.pse__Status__c.addError(System.Label.NSP_PorjectTask_Date_Validation);
            }
            //add Wo to list to update 
            else{
                woListToUpdate.add( mapPtIDToWo.get(projectTask.Id ));
                mapWoIdToPt.put( mapPtIDToWo.get(projectTask.Id ).Id , projectTask );
            }
        }
        //check if woListToUpdate is not empty
        if( !woListToUpdate.isEmpty() && !System.isFuture() ){
            scheduleWorkOrderAndSA( woListToUpdate , mapWoIdToPt, mapUserIdsToServiceResource );
        }
    }

    /***********************************************************************************************
    * MethodName: scheduleWorkOrderAndSA
    * Description : Schedule WO and SA when Project task status is changed to Scheduled
    * Params: List<WorkOrder> woListToUpdate
    * Params: Map<Id,pse__Project_Task__c> mapWoIdToPt
    * Params: Map<Id,Id> mapUserIdsToServiceResource
    * STY-03891
    * ********************************************************************************************/ 
    private static void scheduleWorkOrderAndSA(List<WorkOrder> woListToUpdate, Map<Id,pse__Project_Task__c> mapWoIdToPt, Map<Id,Id> mapUserIdsToServiceResource ){
        List<ServiceAppointment> saListToUpdate = new List<ServiceAppointment>();
        List<AssignedResource> assgnResToCreate = new List<AssignedResource>();
        List<sObject> recordsToUpdate = new List<sObject>();
        //update WorkOrder Status and Sync other fields
        for( WorkOrder eachWo : woListToUpdate){
            eachWo.StartDate = mapWoIdToPt.get( eachWo.Id).pse__Start_Date_Time__c;
            eachWo.EndDate = mapWoIdToPt.get( eachWo.Id).pse__End_Date_Time__c;
            eachWo.Status = 'Scheduled';
            // eachWo.OwnerId = mapWoIdToPt.get( eachWo.Id).OwnerId;
        } 
        //update Service Appointment and sync other fields
        for( ServiceAppointment eachSa : [ SELECT Id,Status,SchedStartTime,SchedEndTime,OwnerId ,ParentRecordId
                                            FROM ServiceAppointment 
                                            WHERE ParentRecordId IN: mapWoIdToPt.keySet() ]){

                                                eachSa.SchedStartTime = mapWoIdToPt.get( eachSa.ParentRecordId).pse__Start_Date_Time__c;
                                                eachSa.SchedEndTime = mapWoIdToPt.get( eachSa.ParentRecordId).pse__End_Date_Time__c;
                                                eachSa.Status = 'Scheduled';
                                                // eachSa.OwnerId =  mapWoIdToPt.get( eachSa.ParentRecordId).OwnerId;
                                                saListToUpdate.add(eachSa);
                                                //Create new Assigned Resource Rec
                                                    AssignedResource newAssgnRes = new AssignedResource(); 
                                                newAssgnRes.ServiceResourceId = mapUserIdsToServiceResource.get( mapWoIdToPt.get( eachSa.ParentRecordId).OwnerId);
                                                newAssgnRes.ServiceAppointmentId = eachSa.Id;
                                                assgnResToCreate.add(newAssgnRes);
        }
        //update WO And SA
        recordsToUpdate.addAll(woListToUpdate);
        recordsToUpdate.addAll(saListToUpdate);
        List<Database.SaveResult> results1 =  Database.update( recordsToUpdate , false );
        NSP_ErrorLogHandler.logSaveResultsException(NSP_PROJECTTASKSTRIGGERHELPER, 'scheduleWorkOrderAndSA', results1 );
        
        //insert Assigned Resource
        List<Database.SaveResult> results3 = Database.insert( assgnResToCreate , false );
        NSP_ErrorLogHandler.logSaveResultsException(NSP_PROJECTTASKSTRIGGERHELPER, 'scheduleWorkOrderAndSA', results3 );
    }
    /***********************************************************************************************
    * MethodName: isStatusChangedToScheduled
    * Description : check if status changed to schedule
    * Params: pse__Project_Task__c projectTask
    * Params: pse__Project_Task__c priorProjectTask
    * ********************************************************************************************/ 
    private static Boolean isStatusChangedToScheduled(pse__Project_Task__c projectTask, pse__Project_Task__c priorProjectTask){
        return isValueChanged(projectTask, priorProjectTask, 'pse__Status__c') && projectTask.pse__Status__c == 'Scheduled' && (projectTask.NSP_Create_Work_Order__c && projectTask.NSP_Dispatch_Region__c != null);
    }
    /***********************************************************************************************
    * MethodName: isStatusChangedToScheduled
    * Description : check if status changed to schedule
    * Params: SObject newObj
    * Params: SObject oldObj
    * Params: String fieldName
    * ********************************************************************************************/ 
    private static Boolean isValueChanged(SObject newObj, SObject oldObj, String fieldName){
        return newObj != null && oldObj != null && String.isNotBlank(fieldName) ? newObj.get(fieldName) != oldObj.get(fieldName) : false;
    }

    /**********************************************************************************************
     * MethodName: restrictProjectTaskDelete
     * Description : Restricts Delete if the Users didn't create a Project Task
     * Params: List<pse__Project_Task__c> projectTaskList
     * Params: Map < Id, pse__Project_Task__c > projectTaskMap
     * ********************************************************************************************/
    public void restrictProjectTaskDelete(List<pse__Project_Task__c> projectTaskList, Map < Id, pse__Project_Task__c > projectTaskMap) {
        User userDetails = [SELECT Id, Name, UserRole.Name, Profile.Name FROM User WHERE Id = : userinfo.getUserId()];
        Id PEOProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE).getRecordTypeId();
        for (pse__Project_Task__c ptObject: projectTaskList) {
            if (userDetails.Id != ptObject.createdById && ptObject.recordtypeId == PEOProjectTaskRecordTypeId && userDetails.Profile.Name != SYS_ADMIN) {
                ptObject.addError(System.Label.NSP_Cannot_Delete_Project_Task);
            }
        }
    }
    
    /***********************************************************************************************
    * MethodName: createPTAIfOwnerIsChanged
    * Description : if Project task owner is updated Check for PTA and Insert new PTA if doesnt exist
    * Params: projectTaskIds projectTask recordIds if Owner is Updated
    * ********************************************************************************************/ 
    public static void createPTAIfOwnerIsChanged(Set<Id> projectTaskIds){
        Id peoRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT_TASK_SOBJECT_TYPE,NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE);
        Id bpsRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT_TASK_SOBJECT_TYPE,NSP_ServiceConstants.PROJECT_TASK_BPS_RECORDTYPE);
        
        Map<Id,Id> projTaskIdWithOwnerIds = new Map<Id,Id>();
        Map<Id,Decimal> projTaskIdWithPTACount = new Map<Id,Decimal>();
        Map<Id,Id> userIdWithcontId = new Map<Id,Id>();
        Map<Id, List<Id>> projTaskWithResourceLst = new Map<Id, List<Id>>();
        List<pse__Project_Task_Assignment__c> newPTAList = new List<pse__Project_Task_Assignment__c> () ;
        try{
            String projTaskQuery = new NSP_QueryBuilder('pse__Project_Task__c', new List<String>{'Id', 'OwnerId', 'pse__Number_of_Assignments__c'})
                            .addFilter('Id', new List<Id>(projectTaskIds) , NSP_QueryBuilder.Operator.INCLUDES)
                            .addFilter('pse__Project__r.NSP_Auto_Resource_Project__c', true , NSP_QueryBuilder.Operator.EQUALS, false)
                            .addFilter('RecordTypeId', new List<Id>{ peoRecordTypeId, bpsRecordTypeId } , NSP_QueryBuilder.Operator.INCLUDES)
                            .build();

            for(pse__Project_Task__c projTask : Database.query(projTaskQuery)) {
                projTaskIdWithOwnerIds.put(projTask.Id, projTask.OwnerId);
                projTaskIdWithPTACount.put(projTask.Id, projTask.pse__Number_of_Assignments__c);
            }

            if(!projTaskIdWithOwnerIds.isEmpty()) {
                String contactQuery = new NSP_QueryBuilder('Contact', new List<String>{'Id', 'Name', 'pse__Salesforce_User__c'})
                            .addFilter('pse__Salesforce_User__c', projTaskIdWithOwnerIds.values() , NSP_QueryBuilder.Operator.INCLUDES)
                            .build();
                        
                for(Contact cont: Database.query(contactQuery)) {
                    userIdWithcontId.put(cont.pse__Salesforce_User__c, cont.Id);
                }
            }

            String projTaskAssignmtQuery = NSP_ProjectTaskAssignmentTriggerHelper.getProjectTaskAssignQuery(projectTaskIds, peoRecordTypeId, bpsRecordTypeId);
        
            for(pse__Project_Task_Assignment__c projTaskAssign: Database.query(projTaskAssignmtQuery)) {

                if(!projTaskWithResourceLst.containsKey(projTaskAssign.pse__Project_Task__c)) {
                    projTaskWithResourceLst.put(projTaskAssign.pse__Project_Task__c, new List<Id>{ projTaskAssign.pse__Resource__c });
                }
                projTaskWithResourceLst.get(projTaskAssign.pse__Project_Task__c).add(projTaskAssign.pse__Resource__c);

            }

            if(!projTaskWithResourceLst.isEmpty()) {

                for(Id projTaskId : projTaskWithResourceLst.keySet()) {
                    Id contResourceId = userIdWithcontId?.get(projTaskIdWithOwnerIds?.get(projTaskId));    
                    List<Id> lstResouceListOfProjTask = projTaskWithResourceLst?.get(projTaskId);

                    if(String.isNotBlank(contResourceId) && !lstResouceListOfProjTask.contains(contResourceId)){
                        newPTAList.add(new pse__Project_Task_Assignment__c(pse__Resource__c = contResourceId,pse__Project_Task__c = projTaskId));  
                    }
                }

            } else {

                for(Id projId : projTaskIdWithPTACount.keySet()) {
                    Id contResourceId = userIdWithcontId?.get(projTaskIdWithOwnerIds?.get(projId));
                    if(projTaskIdWithPTACount.get(projId) == 0) {
                        newPTAList.add(new pse__Project_Task_Assignment__c(pse__Resource__c = contResourceId, pse__Project_Task__c = projId));  
                    }
                }
            }  
            
            if(!newPTAList.isEmpty()) {
                NSP_ProjectTaskAssignmentTriggerHelper.runAssignmentMethod = true;
                Database.UpsertResult[] upsertResults = Database.upsert(newPTAList, false);
                NSP_ErrorLogHandler.logUpsertResultsException(NSP_PROJECTTASKSTRIGGERHELPER, 'createPTAIfOwnerIsChanged:upsertResults', upsertResults);
            }
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_PROJECTTASKSTRIGGERHELPER, 'createPTAIfOwnerIsChanged', ex.getMessage());
        }
    }
    }