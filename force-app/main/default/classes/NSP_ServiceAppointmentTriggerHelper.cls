/**
* @description  :  Helper class for ServiceAppointment trigger.
* @date 14/11/2022
* Author : Nischay Jindal
* Name : NSP_ServiceAppointmentTriggerHelper
*/
public class NSP_ServiceAppointmentTriggerHelper {
    // test w/ NSP_ServiceAppointmentTrigger_Test (??%)

    /***********************************************************************************************
    * MethodName: beforeUpdateDirector
    * Description : This Method updated the status checkbox on Service Appointments  
    * Params:       Map<Id,ServiceAppointment> newMap ,Map<Id,ServiceAppointment> oldMap
    * Author :      Abhishek Kumar
    * ********************************************************************************************/
    //map of service resource Id and operating hrs name
    public static Map<Id, String> mapServResOperHrs = new Map<Id, String>();
    //map of Service Appointment and service resource Ids
    public static Map<Id, Id> mapSAIdServResId = new Map<Id, Id>();
    public static void beforeUpdateDirector(Map<Id,ServiceAppointment> newMap ,Map<Id,ServiceAppointment> oldMap ){
        List<ServiceAppointment> checkStatusChangeSaList =  new List<ServiceAppointment>();
        Set<Id> saIdToUpdateEvent = new Set<Id>();
        Set<Id> saIdToDeletEvent = new Set<Id>();
        try{
            for(ServiceAppointment serApp : newMap.values() ){
                // added as a part of STY-01091
                // update the flag when the first time status is set to dispatched 
                if(serApp.Status!=null 
                   && oldMap.get(serApp.Id).Status != NSP_ServiceConstants.dispatchStatus 
                   && serApp.Status == NSP_ServiceConstants.dispatchStatus 
                   && !oldMap.get(serApp.Id).NSP_IsDispatched__c){
                       
                    checkStatusChangeSaList.add( serApp );
                }
                //added as a part of STY-
                if( serApp.Status != oldMap.get(serApp.Id).Status){
                    //check if SA status is updated to Dispatched

                    //check if SA status is updated to Canceled
                    if( serApp.Status == NSP_ServiceConstants.PROJECT_TASK_CANCELLED ){
                        serApp.NSP_Old_Date__c = oldMap.get(serApp.Id).SchedStartTime;
                        serApp.NSP_Old_Scheduled_Time__c = oldMap.get(serApp.Id).NSP_StartEndTime__c;
                        serApp.NSP_Old_End_Time__c = oldMap.get(serApp.Id).SchedEndTime;
                        saIdToDeletEvent.add( serApp.Id );
                        
                    }
                }

                //added as a part of STY - 04135

                //schedule start is edited AND duration is edited
                if(serApp.Duration != null ){
                    if( serApp.SchedStartTime != null && (serApp.Duration != oldMap.get(serApp.Id).Duration || serApp.SchedStartTime != oldMap.get(serApp.Id).SchedStartTime)){
                        serApp.SchedEndTime = serApp.SchedStartTime.addMinutes(integer.valueof(serApp.Duration));
                    }
    
                    //schedule end is edited AND Duration and scheduled end are updated
                    if( serApp.SchedEndTime != null && (serApp.Duration != oldMap.get(serApp.Id).Duration || serApp.SchedEndTime != oldMap.get(serApp.Id).SchedEndTime)){
                        serApp.SchedStartTime = serApp.SchedEndTime.addMinutes(-integer.valueof(serApp.Duration));
                    }

                }

            }
            //call checkStatusChange
            if(!checkStatusChangeSaList.isEmpty()){
                checkStatusChange( checkStatusChangeSaList );
            }

            //call deleteCancelledEvent
            if(!saIdToDeletEvent.isEmpty()){
                deleteCancelledEvent( saIdToDeletEvent );
            }

        }catch(Exception ex ){
           NSP_ErrorLogHandler.logSaveException('NSP_ServiceAppointmentTriggerHelper', 'beforeUpdateDirector', ex.getMessage());
        }
    }
    

   /**
    * Description: Updated to Service Appointment on specific fields will sync back to ProjectTask and WorkOrder
    * @param newMap of Service Appointment from Trigger
    * @param oldMap of Service Appointment from Trigger
    * @return void             
    */
    @future
    public static void syncBackFieldsToProjectTask( Set<Id> serviceAppointmentIds ){
        Map < Id, ServiceAppointment > workOrderIdServiceAppointment = new Map < Id, ServiceAppointment > ();
        Set<Id> serviceAppointmentIdSet = new Set<Id>();
        Map<Id, Id> serviceAppIdAssigResMap = new Map<Id, Id>();
        Map<Id, Id> assignResIdServiceResMap = new Map<Id, Id>();
        List < WorkOrder > lstWorKOrderToUpdate = new List < WorkOrder > ();     
        List < pse__Project_Task__c > lstProjectTaskToUpdate = new List < pse__Project_Task__c > ();
        Set<Id> serviceTerritoryId = new Set<Id>();
        Map<Id,String> mapOfServiceTerritoryIdToName = new  Map<Id,String>();

        try{
            for( ServiceAppointment eachSa : [ SELECT Id,Status,Description,Subject,NSP_Orientation_Address__c,ServiceTerritoryId,ParentRecordId,EarliestStartTime,OwnerId,Duration,SchedStartTime,SchedEndTime,NSP_Meeting_Type__c 
                                               FROM ServiceAppointment 
                                               WHERE Id IN:  serviceAppointmentIds]){ 
                                                workOrderIdServiceAppointment.put(eachSa.ParentRecordId, eachSa);    
                                                serviceAppointmentIdSet.add(eachSa.Id);
                                                serviceTerritoryId.add(eachSa.ServiceTerritoryId);
                                            }

        if( !serviceTerritoryId.isEmpty() ){
            for( ServiceTerritory eachTerritory : [ SELECT Id,Name FROM ServiceTerritory WHERE Id IN: serviceTerritoryId]){
                mapOfServiceTerritoryIdToName.put(eachTerritory.Id, eachTerritory.Name);
            }
        }

        if (!workOrderIdServiceAppointment.isEmpty()) {
            for (WorkOrder oWorkOrder: [SELECT
                                        Id,
                                        NSP_Project_Task__c
                                        FROM WorkOrder
                                        WHERE Id IN: workOrderIdServiceAppointment.keySet()
                                        WITH SECURITY_ENFORCED
                                       ]) {
                                            ServiceAppointment serviceApp = workOrderIdServiceAppointment.get(oWorkOrder.Id);                                           

                                            lstWorKOrderToUpdate.add(updateWorkOrderRec(oWorkOrder.Id , serviceApp));
                                            lstProjectTaskToUpdate.add(updateProjectTaskRec(oWorkOrder.NSP_Project_Task__c, serviceApp, mapOfServiceTerritoryIdToName));
 
                                       }
        }
            //checking if the map is empty
            if(!workOrderIdServiceAppointment.isEmpty()){
                //querying assigned resource to get service resource
                for(AssignedResource oAssigRes : [SELECT Id,ServiceAppointmentId, ServiceResourceId 
                                                  FROM AssignedResource 
                                                  WHERE ServiceAppointmentId IN: serviceAppointmentIdSet]){
                    //storing map service appointment id and assigned resource Id
                    serviceAppIdAssigResMap.put(oAssigRes.ServiceAppointmentId ,oAssigRes.ServiceResourceId);
                    //storing map assigned resource id and service resouce userId
                    assignResIdServiceResMap.put(oAssigRes.ServiceResourceId, getAssignedResUser(oAssigRes.ServiceResourceId));
                }
                if(!serviceAppIdAssigResMap.isEmpty()){
                    //calling the method to syn the project task, workorder and service appointment ownerId
                    syncProjTaskOwnerSA(workOrderIdServiceAppointment,  serviceAppIdAssigResMap, assignResIdServiceResMap);
                }
            }
            if(!lstWorKOrderToUpdate.isEmpty() && Schema.sObjectType.WorkOrder.isUpdateable()){
                Database.update(lstWorKOrderToUpdate,false);
            }
            if(!lstProjectTaskToUpdate.isEmpty() && Schema.sObjectType.pse__Project_Task__c.isUpdateable() ){
                Database.update(lstProjectTaskToUpdate,false);
            }
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_ServiceAppointmentTriggerHelper', 'syncBackFieldsToProjectTask', ex.getMessage());
        }
        
    }

    /***********************************************************************************************
    * MethodName: updateWorkOrderRec
    * Description : Updating the Work Order Record 
    * Params:  Id workOrderId, ServiceAppointment saRecord
    * ********************************************************************************************/  
    public static WorkOrder updateWorkOrderRec( Id workOrderId, ServiceAppointment saRecord ){
        
        //Updating the Work Order Record when Service Appointment is updated
                WorkOrder woOrderRecToUpdate = new WorkOrder();

                woOrderRecToUpdate.Id = workOrderId;
                woOrderRecToUpdate.Status = saRecord.Status;
                woOrderRecToUpdate.Description = saRecord.Description;
                woOrderRecToUpdate.Subject = saRecord.Subject;
        		woOrderRecToUpdate.NSP_Meeting_Type__c = saRecord.NSP_Meeting_Type__c;
                woOrderRecToUpdate.NSP_Orientation_Address__c = saRecord.NSP_Orientation_Address__c;
                woOrderRecToUpdate.ServiceTerritoryId = saRecord.ServiceTerritoryId;
                woOrderRecToUpdate.Duration = saRecord.Duration;
                woOrderRecToUpdate.DurationType = 'Minutes';
                woOrderRecToUpdate.StartDate = saRecord.SchedStartTime;
                woOrderRecToUpdate.EndDate = saRecord.SchedEndTime;
        		
        		return woOrderRecToUpdate;
    }

    /***********************************************************************************************
    * MethodName: updateProjectTaskRec
    * Description : Updating the Project Task Record
    * Params: Id projectTaskId, ServiceAppointment saRecord,  Map<Id,String> mapOfServiceTerritoryIdToName 
    * ********************************************************************************************/  
    public static pse__Project_Task__c updateProjectTaskRec( Id projectTaskId, ServiceAppointment saRecord,  Map<Id,String> mapOfServiceTerritoryIdToName ){
        
        //Updating the Project Task Record when Service Appointment is updated
                pse__Project_Task__c projTaskRecToUpdate = new pse__Project_Task__c();

                projTaskRecToUpdate.Id = projectTaskId;
                projTaskRecToUpdate.pse__Status__c = saRecord.Status;
                projTaskRecToUpdate.pse__Long_Description__c = saRecord.Description;
                projTaskRecToUpdate.Name = saRecord.Subject;
        		projTaskRecToUpdate.NSP_Meeting_Type__c = saRecord.NSP_Meeting_Type__c;
                projTaskRecToUpdate.NSP_Orientation_Address__c = saRecord.NSP_Orientation_Address__c;
                projTaskRecToUpdate.NSP_Dispatch_Region__c = mapOfServiceTerritoryIdToName.get(saRecord.ServiceTerritoryId);
                projTaskRecToUpdate.pse__Start_Date_Time__c = saRecord.SchedStartTime;
                projTaskRecToUpdate.pse__End_Date_Time__c = saRecord.SchedEndTime;

        		return projTaskRecToUpdate;
    }

    
    /**
    * Description: this will check whether the specified fields are updated to sync back to ProjectTask
    * Author : Anil
    * @param oServiceApp of Service Appointment from Trigger
    * @param oldServiceApp of Service Appointment from Trigger
    * @return Boolean             
    */
    public static Boolean isfieldsUpdatedToSyncBackProjectTask(ServiceAppointment oServiceApp, ServiceAppointment oldServiceApp){
        return (
                   oServiceApp.Description != oldServiceApp.Description 
                || oServiceApp.Status != oldServiceApp.Status 
                || oServiceApp.OwnerId != oldServiceApp.OwnerId
                || oServiceApp.Subject != oldServiceApp.Subject
                || oServiceApp.NSP_Orientation_Address__c != oldServiceApp.NSP_Orientation_Address__c
            	|| oServiceApp.NSP_Meeting_Type__c != oldServiceApp.NSP_Meeting_Type__c
                || oServiceApp.ServiceTerritoryId != oldServiceApp.ServiceTerritoryId
                || oServiceApp.Duration != oldServiceApp.Duration
                || oServiceApp.SchedStartTime != oldServiceApp.SchedStartTime
                || oServiceApp.SchedEndTime != oldServiceApp.SchedEndTime
            	);
    }
    
    /***********************************************************************************************
    * MethodName: checkStatusChange
    * Description : This Method updated the status checkbox on Service Appointments  
    * Params:       List<ServiceAppointment> checkStatusChangeSaList
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    public static void checkStatusChange( List<ServiceAppointment> checkStatusChangeSaList ){
        try{
            for(ServiceAppointment serApp : checkStatusChangeSaList ){
                // update the flag when the first time status is set to dispatched 
                    serApp.NSP_IsDispatched__c = true;
            }
        }catch(Exception ex ){
           NSP_ErrorLogHandler.logSaveException('NSP_ServiceAppointmentTriggerHelper', 'beforeUpdate', ex.getMessage());
        }
    }
    
    /***********************************************************************************************
    * MethodName: sendEmailNotifications
    * Description : This Method sends email to users after status Changes
    * Params:       Map<Id,ServiceAppointment> newMap ,Map<Id,ServiceAppointment> oldMap
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    public static void sendEmailNotifications(Map<Id,ServiceAppointment> newMap ,Map<Id,ServiceAppointment> oldMap ){
        Set<Id> workOrderIdSet = new Set<Id>();
        Set<Id> serAppIdSet = new Set<Id>();
        Set<Id> taskIdSet = new Set<Id>();
        Map<Id,Id>mapwrkOrderTaskId = new Map<Id,Id>();
        List<String> listOfTOAddresses = new List<String> ();
        Map<Id,List<String>> maptaskIdListEmails = new   Map<Id,List<String>>();
        Map<Id, List<String>> mapSerIdListResources = new Map<Id, List<String>>();
        Map<Id,WorkOrder> workOrderMap  = new Map<Id,WorkOrder>();
        Map<String,EmailTemplate> emailTemplateMap = new Map<String,EmailTemplate>();
        try{
          for(ServiceAppointment servApp:newMap.values() ){
            if(isStatusChange(servApp,oldMap) || isRecordChanged(servApp,oldMap.get(ServApp.Id))){
                if(servApp.ParentRecordId != null){
                       Id myRecordId = servApp.ParentRecordId;
                       String sObjName = myRecordId.getSObjectType().getDescribe().getName();
                       serAppIdSet.add(servApp.Id);
                       if(sObjName == NSP_ServiceConstants.workOrder){ 
                           workOrderIdSet.add(servApp.ParentRecordId);
                       }
                   }
            }
          }
          if(!serAppIdSet.isEmpty() && !workOrderIdSet.isEmpty()){
            mapSerIdListResources = getAssignedResources(serAppIdSet);
            workOrderMap = getWorkOrders(workOrderIdSet);
            for(WorkOrder wrkOrd: workOrderMap.values()){
                if(wrkOrd.NSP_Project_Task__c!=null){
                    taskIdSet.add(wrkOrd.NSP_Project_Task__c);
                    mapwrkOrderTaskId.put(wrkOrd.Id,wrkOrd.NSP_Project_Task__c );
                }
            }
            maptaskIdListEmails = getPrjTaskAssignments(taskIdSet);
            emailTemplateMap = getEmailTemplates();
           for(ServiceAppointment servApp:newMap.values()){
            if(workOrderMap.containsKey(servApp.ParentRecordId) &&  maptaskIdListEmails.containsKey(workOrderMap.get(servApp.ParentRecordId).NSP_Project_Task__c) ){
                listOfTOAddresses.addAll( maptaskIdListEmails.get(workOrderMap.get(servApp.ParentRecordId).NSP_Project_Task__c));
                
            }
            if(mapSerIdListResources.containsKey(servApp.Id)){                   
                listOfTOAddresses.addAll(mapSerIdListResources.get(servApp.Id));
            } 
               // send email to users 
               if(!listOfTOAddresses.isEmpty() ){
                   // send emails when status Updates
                   if( servApp.Status != oldmap.get(servApp.Id).Status ){
                       
                       if(servApp.NSP_IsDispatched__c && !oldMap.get(servApp.Id).NSP_IsDispatched__c){
                            EmailTemplate emp = emailTemplateMap.get(NSP_ServiceConstants.SerAppDispatchedEmailTemplate);
                            sendMail(listOfTOAddresses,servApp.Id,emp.Id);
                        }
                        else if(servApp.Status == NSP_ServiceConstants.dispatchStatus){
                           EmailTemplate emp = emailTemplateMap.get(NSP_ServiceConstants.SerAppReScheduleEmailTemplate);
                           sendMail(listOfTOAddresses,servApp.Id,emp.Id);  
                        }
                        else if(oldmap.get(servApp.Id).Status == NSP_ServiceConstants.dispatchStatus && servApp.Status == NSP_ServiceConstants.PROJECT_TASK_CANCELLED){
                           EmailTemplate emp = emailTemplateMap.get(NSP_ServiceConstants.SerAppNoneEmailTemplate);
                           sendMail(listOfTOAddresses,servApp.Id,emp.Id);
                        }
                    }
                    else if( oldMap.get(servApp.Id).ServiceTerritoryId != null  &&  isRecordChanged(servApp,oldMap.get(ServApp.Id) )   ){
                        EmailTemplate emp = emailTemplateMap.get(NSP_ServiceConstants.SerAppRecordChangeEmailTemplate);
                        sendMail(listOfTOAddresses,servApp.Id,emp.Id);
                    }
               }
            }
        }   
       }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_ServiceAppointmentTriggerHelper', 'sendEmailNotifications', ex.getMessage());
        }
        
    }
    
    /**********************************************************************************************
    * Description: this will syn the project task owner, work order owner and service appointment owner with assigned resource userId
    * @param map of workorder Id and ServiceAppointment Record
    * @param map of serviceAppointment Id and Assigned Resource Id
    * @param map of Assigned Resource Id Id and Service Resource Id
    * @return void
    *********************************************************************************************/
    public static void syncProjTaskOwnerSA(Map<Id,ServiceAppointment> workOrderIdServiceAppointment, Map<Id, Id> serviceAppIdAssigResMap, Map<Id, Id> assignResIdServiceResMap){
        
        ServiceAppointment serviceApp;
        List < WorkOrder > lstWorKOrderToUpdate = new List < WorkOrder > ();     
        List < pse__Project_Task__c > lstProjectTaskToUpdate = new List < pse__Project_Task__c > ();
        
        //quering service appointment to update ownerId field with service resource UserId 
        List<ServiceAppointment> serviceAppList = updateServiceAppointments(serviceAppIdAssigResMap, assignResIdServiceResMap);
        //quering the workorder to update
        for (WorkOrder oWorkOrder: [SELECT Id, NSP_Project_Task__c 
                                    FROM WorkOrder 
                                    WHERE Id IN: workOrderIdServiceAppointment.keySet()]) {
            serviceApp = workOrderIdServiceAppointment.get(oWorkOrder.Id);
            //making the clone of existing workorder Id & project task Id then updating the fields
            lstWorKOrderToUpdate.add(updateWorkOrder(oWorkOrder, serviceApp, serviceAppIdAssigResMap, assignResIdServiceResMap));
            lstProjectTaskToUpdate.add(updateProjectTask(oWorkOrder, serviceApp, serviceAppIdAssigResMap, assignResIdServiceResMap));
        }
         //updating the work order
        if(!lstWorKOrderToUpdate.isEmpty() && Schema.sObjectType.WorkOrder.isUpdateable()){
                List<Database.SaveResult> res = Database.update(lstWorKOrderToUpdate,false);
                NSP_ErrorLogHandler.logSaveResultsException('NSP_ServiceAppointmentTriggerHelper', 'syncProjTaskOwnerSA', res);
        }
        //updating the project task
        if(!lstProjectTaskToUpdate.isEmpty() && Schema.sObjectType.pse__Project_Task__c.isUpdateable() ){
            List<Database.SaveResult> resproj = Database.update(lstProjectTaskToUpdate,false);
            NSP_ErrorLogHandler.logSaveResultsException('NSP_ServiceAppointmentTriggerHelper', 'syncProjTaskOwnerSA', resproj);
        }
        //updating service appointment
        if(!serviceAppList.isEmpty() && Schema.sObjectType.ServiceAppointment.isUpdateable()){
            List<Database.SaveResult> resServ = Database.update(serviceAppList,false);
            NSP_ErrorLogHandler.logSaveResultsException('NSP_ServiceAppointmentTriggerHelper', 'syncProjTaskOwnerSA', resServ);
        }
    }
    
    /***********************************************************************************************
    * MethodName: sendMail
    * Description : Helper method for email body 
    * Params:       String subjectString, String mailBody, list<String> listOfTOAddresses, String fromAddress, Id targetId, Id templateId
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    private static void sendMail(list<String> listOfTOAddresses, Id targetId, Id templateId){
        
        //set template structure for the email template                            
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        if(listOfTOAddresses!=null && listOfTOAddresses.size()>0){
            email.setToAddresses(listOfTOAddresses);
        }
        if(targetId!=null && !String.isBlank(targetId)){
            email.setWhatId(targetId);
        }
        if(templateId!=null && !String.isBlank(templateId)){
            email.setTemplateId(templateId);
        }
        email.setTargetObjectId(UserInfo.getUserId());
        email.setTreatTargetObjectAsRecipient(false);
        if(!System.Test.isRunningTest()){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        }
    }
    
    /***********************************************************************************************
    * MethodName: getAssignedResources
    * Description : Helper method to retrieve resourses 
    * Params:   Set<Id>serAppIdSet
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    private static  Map<Id, List<String>> getAssignedResources(Set<Id>serAppIdSet){
        Map<Id, List<String>> mapSerIdListEmailResources = new Map<Id, List<String>>();
        
        for(ServiceAppointment serApp :[SELECT Id, Owner.Email FROM ServiceAppointment WHERE Id IN : serAppIdSet]){
            if(!mapSerIdListEmailResources.containsKey(serApp.Id)){
                mapSerIdListEmailResources.put(serApp.Id, new List<String>());
            }
            mapSerIdListEmailResources.get(serApp.Id).add(serApp.Owner.Email);
        }
        return mapSerIdListEmailResources;  
    }
    
    /***********************************************************************************************
    * MethodName: getWorkOrders
    * Description : Helper method to retrieve workorder 
    * Params:   Set<Id>workOrderIdSet
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    private static  Map<Id,WorkOrder> getWorkOrders(Set<Id>workOrderIdSet ){
        Map<Id,WorkOrder> workOrderMap = new Map<Id,WorkOrder>([Select Id , NSP_Project_Task__c from WorkOrder WHERE Id IN: workOrderIdSet ]);
        return workOrderMap;
    }
    
    /***********************************************************************************************
    * MethodName: getPrjTaskAssignments
    * Description : Helper method to retrieve PTA 
    * Params:   Set<Id>taskIdSet
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    private static  Map<Id,List<String>> getPrjTaskAssignments(Set<Id>taskIdSet ){
         Map<Id,List<String>> maptaskIdListEmails = new   Map<Id,List<String>>();
        for(pse__Project_Task_Assignment__c pta:[SELECT Id , pse__Project_Task__c ,pse__Resource__r.NSP_Work_email__c, pse__Resource__c ,pse__Resource__r.pse__Salesforce_User__c , pse__Resource__r.pse__Salesforce_User__r.Email FROM pse__Project_Task_Assignment__c
                                                 WHERE pse__Resource__c !=null AND pse__Project_Task__c IN:taskIdSet AND pse__Resource__r.pse__Salesforce_User__c !=null]){
            if(!maptaskIdListEmails.containsKey(pta.pse__Project_Task__c)){
                maptaskIdListEmails.put(pta.pse__Project_Task__c , new List<String>());
            } 
            maptaskIdListEmails.get(pta.pse__Project_Task__c).add(pta.pse__Resource__r.pse__Salesforce_User__r.Email);
        }
        return maptaskIdListEmails;
    }
    
    /***********************************************************************************************
    * MethodName: getEmailTemplates
    * Description : Helper method to retrieve Email Templates  
    * Author :      Nischay Jindal
    * ********************************************************************************************/    
     private static Map<String,EmailTemplate> getEmailTemplates(){	
     Map<String,EmailTemplate> emailTempMap = new Map<String,EmailTemplate>();
         List<String>templateNameList = new List<String>{NSP_ServiceConstants.SerAppReScheduleEmailTemplate,NSP_ServiceConstants.SerAppNoneEmailTemplate,
             											NSP_ServiceConstants.SerAppRecordChangeEmailTemplate,NSP_ServiceConstants.SerAppDispatchedEmailTemplate};
     List<EmailTemplate> emailTempList =[SELECT Id,Name, DeveloperName, HtmlValue, Subject, Body FROM EmailTemplate 
                                         WHERE DeveloperName IN:templateNameList ];
        for(EmailTemplate emp:emailTempList ){
            emailTempMap.put(emp.DeveloperName ,emp);
        }
        return emailTempMap;
    }
    /***********************************************************************************************
    * MethodName: isStatusChange
    * Description : return true if status or fields changed on SA
    * Author :      Nischay Jindal
    * ********************************************************************************************/ 
    private static Boolean isStatusChange(ServiceAppointment servApp, Map<Id,ServiceAppointment> oldmap){
        return (servApp.NSP_IsDispatched__c || 
                (servApp.Status !=null && 
                (oldmap.get(servApp.Id).Status != NSP_ServiceConstants.dispatchStatus && servApp.Status == NSP_ServiceConstants.dispatchStatus)  ||
                (oldmap.get(servApp.Id).Status != NSP_ServiceConstants.PROJECT_TASK_CANCELLED && servApp.Status == NSP_ServiceConstants.PROJECT_TASK_CANCELLED))  );
    }
    /***********************************************************************************************
    * MethodName: isRecordChanged
    * Description : return true if record or fields changed on SA
    * Author :      Nischay Jindal
    * ********************************************************************************************/ 
    private static Boolean isRecordChanged(ServiceAppointment servApp, ServiceAppointment oldSa){
        return (
            (ServApp.Status == NSP_ServiceConstants.dispatchStatus)
            &&
            (  ( oldSa.NSP_Orientation_Address__c != servApp.NSP_Orientation_Address__c )
            || ( oldSa.Description != servApp.Description )
            || ( oldSa.Duration != servApp.Duration )
            || ( oldSa.SchedStartTime != servApp.SchedStartTime )
            || ( oldSa.SchedEndTime != servApp.SchedEndTime )
            || ( oldSa.OwnerId != servApp.OwnerId ) 
            ) 
            );
    }
    
    /********************************************************************************************
    * Description: this will return the service resource UserId
    * @param Service Resource Id
    * @return Id
*********************************************************************************************/
    private static Id getAssignedResUser(Id serviceResId){
        List<String> serviceResApp_Fields = new List<String>{'Id', 'RelatedRecordId'};
        String query = new NSP_QueryBuilder(NSP_ServiceConstants.SERVICERES_SOBJECT_NAME, serviceResApp_Fields)
            					.addFilter('Id', serviceResId).build();
        List<ServiceResource> oserviceRes = (List<ServiceResource>) Database.query(query);
        return oserviceRes[0].RelatedRecordId;
    }
    
    /**********************************************************************************************
    * Description: this method will update Service Appointment OwnerId and return the list of Service Appointment
    * @param map of service appointment Id and Assigned resource Id
    * @param map of Assigned resource Id and Resource Service User Id
    * @return List of Service Appointment           
    *********************************************************************************************/
    private static List<ServiceAppointment> updateServiceAppointments(Map<Id, Id> serviceAppIdAssigResMap, Map<Id, Id> assignResIdServiceResMap){
        List<ServiceAppointment> serviceAppList = new List<ServiceAppointment>();
        for(ServiceAppointment oservice: [SELECT Id, OwnerId 
                                          FROM ServiceAppointment 
                                          WHERE Id IN: serviceAppIdAssigResMap.keySet()]){
            oservice.OwnerId = assignResIdServiceResMap.get(serviceAppIdAssigResMap.get(oservice.Id));
            serviceAppList.add(oservice);
        }
        return serviceAppList;
    }
    
    /**********************************************************************************************
    * Description: this method will update WorkOrder fields
    * @param WorkOrder record
    * @param map of service appointment Id and Assigned resource Id
    * @param map of Assigned resource Id and Resource Service User Id
    * @return List of Service Appointment           
    *********************************************************************************************/
    private static WorkOrder updateWorkOrder(WorkOrder oWorkOrder, ServiceAppointment serviceApp, Map<Id, Id> serviceAppIdAssigResMap, Map<Id, Id> assignResIdServiceResMap){
        return new WorkOrder(
                Id = oWorkOrder.Id,
                OwnerId = assignResIdServiceResMap.get(serviceAppIdAssigResMap.get(serviceApp.Id)),
                StartDate = serviceApp.EarliestStartTime,
                Status = serviceApp.Status,
                Description = serviceApp.Description,
            	NSP_Meeting_Type__c = serviceApp.NSP_Meeting_Type__c
            );
    }
    
    /**********************************************************************************************
    * Description: this method will update Project Task fields
    * @param WorkOrder record
    * @param Service Appointment record
    * @param map of service appointment Id and Assigned resource Id
    * @param map of Assigned resource Id and Resource Service User Id
    * @return List of Service Appointment           
    *********************************************************************************************/
    private static pse__Project_Task__c updateProjectTask(WorkOrder oWorkOrder, ServiceAppointment serviceApp, Map<Id, Id> serviceAppIdAssigResMap, Map<Id, Id> assignResIdServiceResMap){

        return new pse__Project_Task__c(
            Id = oWorkOrder.NSP_Project_Task__c,
            OwnerId = assignResIdServiceResMap.get(serviceAppIdAssigResMap.get(serviceApp.Id)),
            pse__Start_Date_Time__c = serviceApp.EarliestStartTime,
            pse__Status__c = serviceApp.Status,
            NSP_Meeting_Type__c = serviceApp.NSP_Meeting_Type__c,
            pse__Long_Description__c = serviceApp.Description);
    }

    /***********************************************************************************************
    * MethodName: createOrDeleteFreeEvent
    * Description : create event rec after scheduling Event 
    * Params: List<ServiceAppointment> createOrDeletSaList
    * ********************************************************************************************/  
    public static void createOrDeleteFreeEvent( List<ServiceAppointment> createOrDeletSaList ){
        List<Event> eventToInsert = new List<Event>();
        Map<Id,Id> serResToSaIdMap = new Map<Id,Id>();
        Map<Id,Id> saToSerResUserIdMap = new Map<Id,Id>();
        //get Assigned Service Resource Rec
        for( AssignedResource eachAssigned : [SELECT ServiceResourceId, ServiceAppointmentId FROM AssignedResource WHERE ServiceAppointmentId IN: createOrDeletSaList]){
            serResToSaIdMap.put( eachAssigned.ServiceResourceId, eachAssigned.ServiceAppointmentId );
        }
        //get User Id From Assigned Service Resource
        for( ServiceResource eachServiceRes : [ SELECT Id,RelatedRecordId FROM ServiceResource WHERE Id IN: serResToSaIdMap.keySet()]){
            saToSerResUserIdMap.put( serResToSaIdMap.get(eachServiceRes.Id), eachServiceRes.RelatedRecordId );
        }
        
        //iterate over updated Service Appointment 
        for (ServiceAppointment eachNewSa : createOrDeletSaList ) {
                //new event record
                eventToInsert.add( createNewEventRec( eachNewSa, saToSerResUserIdMap ) );
        }

        //insert free events 
        if(!eventToInsert.isEmpty()){
            List<Database.SaveResult> results = Database.insert( eventToInsert , false );
            NSP_ErrorLogHandler.logSaveResultsException('NSP_ServiceAppointmentTriggerHelper', 'createOrDeleteFreeEvent', results );
        }
    }
    /***********************************************************************************************
    * MethodName: changeFreeEventToBusy
    * Description : change free event to busy
    * Params: Set<Id> eventIdDelete
    * ********************************************************************************************/  
    public static void changeFreeEventToBusy(Set<Id> eventIdDelete ){
        
        List<Event> eventRecListDelete = new List<Event>();
        //list event update to busy
        for( Event eachEvent : [SELECT Id,WhatId,ShowAs FROM Event WHERE WhatId IN: eventIdDelete]){
            eachEvent.ShowAs = 'Busy';
            eventRecListDelete.add(eachEvent);
        }

        //update the evnet record 
        if( !eventRecListDelete.isEmpty()){
            List<Database.SaveResult> results =  Database.update( eventRecListDelete , false );
            NSP_ErrorLogHandler.logSaveResultsException('NSP_ServiceAppointmentTriggerHelper', 'changeFreeEventToBusy', results );
        }
    }

    /***********************************************************************************************
    * MethodName: deleteCancelledEvent
    * Description : delete evevt of cancelled SA
    * Params: Set<Id> saIdToDeletEvent
    * ********************************************************************************************/  
    public static void deleteCancelledEvent(Set<Id> saIdToDeletEvent ){
        List<Event> eventRecListDelete = new List<Event>();
        //get the event related to cancelled SA 
        for( Event eachEvent : [SELECT Id,WhatId FROM Event WHERE WhatId IN: saIdToDeletEvent]){
            eachEvent.WhatId = null;
            eventRecListDelete.add(eachEvent);
        }
        //delete tha event for cancelled 
        if( !eventRecListDelete.isEmpty()){
            List<Database.SaveResult> results =  Database.update( eventRecListDelete , false );
            NSP_ErrorLogHandler.logSaveResultsException('NSP_ServiceAppointmentTriggerHelper', 'deleteCancelledEvent', results );

            List<Database.DeleteResult> results1 = Database.delete( eventRecListDelete ,false); 
            NSP_ErrorLogHandler.logDeleteResultsException('NSP_ServiceAppointmentTriggerHelper', 'deleteCancelledEvent', results1 );

        }
    }
    
    /***********************************************************************************************
    * MethodName: createNewEventRec
    * Description : return new related Event record
    * Params: ServiceAppointment relatedSa
    * ********************************************************************************************/  
    public static Event createNewEventRec( ServiceAppointment relatedSa  , Map<Id,Id> saToSerResUserIdMap){
        
        //Create new event record if service Appointment Scheduled
                Event newFreeEvent = new Event();
                newFreeEvent.WhatId = relatedSa.id;
                newFreeEvent.ShowAs = 'Free';
                newFreeEvent.Subject = relatedSa.Subject;
                newFreeEvent.Description = relatedSa.Description;
                newFreeEvent.Location = relatedSa.NSP_Orientation_Address__c;
                newFreeEvent.StartDateTime = relatedSa.SchedStartTime;
                newFreeEvent.EndDateTime = relatedSa.SchedEndTime;
                newFreeEvent.OwnerId =  saToSerResUserIdMap.get( relatedSa.Id );
        		
        		return newFreeEvent;
    }

    /***********************************************************************************************
    * MethodName: afterUpdateDirector
    * Description : after update Director method
    * Params:       Map<Id,ServiceAppointment> newMap ,Map<Id,ServiceAppointment> oldMap
    * Author :      Abhishek Kumar
    * ********************************************************************************************/
    public static void afterUpdateDirector(Map<Id,ServiceAppointment> newMap ,Map<Id,ServiceAppointment> oldMap ){
        Set<Id> serviceAppintmentUpdatedIds = new Set<Id>();
        List<ServiceAppointment> createOrDeletSaList =  new List<ServiceAppointment>();
        Map< Id, ServiceAppointment> mapOfSaIdToRec = new Map<Id,ServiceAppointment> ();
        Map< Id, ServiceAppointment> mapOfSaIdToServAppRec = new Map<Id,ServiceAppointment> ();
        Set<Id> saIdToUpdateEvent = new Set<Id>();

        try{
            for(ServiceAppointment serApp : newMap.values() ){
                
                // added as a part of STY-03891
                if(isfieldsUpdatedToSyncBackProjectTask(serApp, oldMap.get(serApp.Id))){
                    serviceAppintmentUpdatedIds.add(serApp.Id);
                }
				
                if( serApp.Status != oldMap.get(serApp.Id).Status ){ 
                    if( serApp.Status == NSP_ServiceConstants.scheduleStatus){
                    //check if SA status is updated to Scheduled
                    	createOrDeletSaList.add( serApp );
                        mapOfSaIdToServAppRec.put(serApp.Id, serApp);
                    }
                    //check if SA status is updated to Dispatched
                    else if( SerApp.Status == NSP_ServiceConstants.dispatchStatus ){
                        saIdToUpdateEvent.add( serApp.Id );
                    }
                }
                if( isSaUpdatedToUpdateEvent(serApp, oldMap.get(serApp.Id) ) ){
                    if( mapOfSaIdToRec.get(serApp.Id) == null  ){
                        mapOfSaIdToRec.put( serApp.Id, serApp );
                    }
                }
                
            }
            if(!mapOfSaIdToServAppRec.isEmpty()){
                updateServiceTerritory(mapOfSaIdToServAppRec);
            }
            if( !serviceAppintmentUpdatedIds.isEmpty() && !System.isFuture() && !System.isBatch() ){
                syncBackFieldsToProjectTask(serviceAppintmentUpdatedIds);
            }
            //call createOrDeleteFreeEvent
            if(!createOrDeletSaList.isEmpty()){
                createOrDeleteFreeEvent( createOrDeletSaList );
            }
            
            //call changeFreeEventToBusy
            if(!saIdToUpdateEvent.isEmpty()){
                changeFreeEventToBusy( saIdToUpdateEvent ); 
            }
            
            //call UpdateSaRelatedEvent
            if( !mapOfSaIdToRec.isEmpty() ){
                UpdateSaRelatedEvent (mapOfSaIdToRec);
            }
            
            
        }catch(Exception ex ){
           NSP_ErrorLogHandler.logSaveException('NSP_ServiceAppointmentTriggerHelper', 'afterUpdateDirector', ex.getMessage());
        }
    }

    /***********************************************************************************************
    * MethodName: updateServiceTerr
    * Description : Updating the Service Appointment Service Territory field 
    * Params: (Map< Id, ServiceAppointment> mapOfSaIdToServAppRec
    * ********************************************************************************************/  
    private static void updateServiceTerritory(Map< Id, ServiceAppointment> mapOfSaIdToServAppRec){
        Map<Id, Id> serviceResAssignRes= new Map<Id,Id>();
        Map<Id, Id> servAppAssignRes= new Map<Id,Id>();
        Map<Id, Id> servAppUser= new Map<Id,Id>();
        List<ServiceAppointment> updateServApp =new List<ServiceAppointment>();
        try{
            for(AssignedResource assignRes : [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource WHERE ServiceAppointmentId IN: mapOfSaIdToServAppRec.keySet() ]){
                serviceResAssignRes.put(assignRes.ServiceResourceId,assignRes.Id);
                servAppAssignRes.put(assignRes.Id,assignRes.ServiceAppointmentId);
            }
            for(ServiceTerritoryMember servTemMem: [SELECT Id, ServiceResourceId, ServiceTerritoryId FROM ServiceTerritoryMember WHERE ServiceResourceId IN: serviceResAssignRes.keySet() ]){
                servAppUser.put(servAppAssignRes.get(serviceResAssignRes.get(servTemMem.ServiceResourceId)),servTemMem.ServiceTerritoryId);
            }
            for(ServiceAppointment servApp : [SELECT Id, ServiceTerritoryId FROM ServiceAppointment WHERE Id IN: servAppUser.keySet() ]){
                servApp.ServiceTerritoryId = servAppUser.get(servApp.Id);
                updateServApp.add(servApp);
            }
            if(!updateServApp.isEmpty()){
                List<Database.SaveResult> results =  Database.update(updateServApp, false);
                NSP_ErrorLogHandler.logSaveResultsException('NSP_ServiceAppointmentTriggerHelper', 'updateServiceTerritory', results );
            }
        }catch(Exception ex ){
           NSP_ErrorLogHandler.logSaveException('NSP_ServiceAppointmentTriggerHelper', 'updateServiceTerritory', ex.getMessage());
        }
    }
    
    /***********************************************************************************************
            * MethodName: isSaUpdatedToUpdateEvent
            * Description : return true if record or fields changed on SA
            * Author :      Abhishek Kumar
            * ********************************************************************************************/ 
            private static Boolean isSaUpdatedToUpdateEvent(ServiceAppointment servApp, ServiceAppointment oldSa){
                return (
                    ( servApp.Status == oldSa.Status )
                    && 
                    (  ( servApp.Status == NSP_ServiceConstants.scheduleStatus ) 
                        || ( servApp.Status == NSP_ServiceConstants.dispatchStatus ) 
                    ) 
                    && 
                    ( ( oldSa.NSP_Orientation_Address__c != servApp.NSP_Orientation_Address__c )
                        || ( oldSa.Description != servApp.Description )
                        || ( oldSa.Subject != servApp.Subject )
                        || ( oldSa.SchedStartTime != servApp.SchedStartTime )
                        || ( oldSa.SchedEndTime != servApp.SchedEndTime )
                        || ( oldSa.OwnerId != servApp.OwnerId )
                    )
                );
            }
             /***********************************************************************************************
    * MethodName: UpdateSaRelatedEvent
    * Description : Update Related Event If SA is updated
    * Author :      Abhishek Kumar
    * ********************************************************************************************/ 
    public static Void UpdateSaRelatedEvent( Map< Id,ServiceAppointment> mapSaIdToRec){
        List<Event> eventListToUpdate = new List<Event>();
        for( Event eachEvent : [SELECT Id,Subject,Description,Location,StartDateTime,EndDateTime,OwnerId,WhatId
                                FROM Event
                                WHERE WhatId IN: mapSaIdToRec.keySet()] ){                                    
                                    ServiceAppointment relatedSa = mapSaIdToRec.get(eachEvent.WhatId);
                                    
                                    eachEvent.Subject = '[SF] '+relatedSa.Subject;
                                    eachEvent.Description = relatedSa.Description;
                                    eachEvent.Location = relatedSa.NSP_Orientation_Address__c;
                                    eachEvent.StartDateTime = relatedSa.SchedStartTime;
                                    eachEvent.EndDateTime = relatedSa.SchedEndTime;
                                    eachEvent.OwnerId =  relatedSa.OwnerId;
                                    eventListToUpdate.add( eachEvent);
                                }

        if( !eventListToUpdate.isEmpty()){
            List<Database.SaveResult> results =  Database.update( eventListToUpdate , false );
            NSP_ErrorLogHandler.logSaveResultsException('NSP_ServiceAppointmentTriggerHelper', 'UpdateSaRelatedEvent', results );
        }
    }
}