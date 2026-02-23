public with sharing class NSP_ServiceAppointmentTriggerHelper {
    // test w/ NSP_ServiceAppointmentTrigger_Test (87%)

    //
    // MethodName : beforeUpdateDirector
    // Description : This Method updated the status checkbox on Service Appointments
    // Params : Map<Id,ServiceAppointment> newMap ,Map<Id,ServiceAppointment> oldMap
    // Author : Abhishek Kumar
    //
    public static void beforeUpdateDirector( Map<Id,ServiceAppointment> newMap , Map<Id,ServiceAppointment> oldMap ) {
        try {
            List<ServiceAppointment> checkStatusChangeSaList = new List<ServiceAppointment>();
            Set<Id> saIdToDeletEvent = new Set<Id>();
            for ( ServiceAppointment serApp : newMap.values() ) {
                // added as a part of STY-01091
                // update the flag when the first time status is set to dispatched
                if ( ( serApp.Status != null )
                    && ( serApp.Status == NSP_ServiceConstants.dispatchStatus )
                    && ( oldMap.get( serApp.Id ).Status != NSP_ServiceConstants.dispatchStatus )
                    && !oldMap.get( serApp.Id ).NSP_IsDispatched__c
                    )
                {
                    checkStatusChangeSaList.add( serApp );
                }
                if ( ( serApp.Status != oldMap.get( serApp.Id ).Status )
                    && ( serApp.Status == NSP_ServiceConstants.PROJECT_TASK_CANCELLED )
                    )
                {
                    serApp.NSP_Old_Date__c = oldMap.get( serApp.Id ).SchedStartTime;
                    serApp.NSP_Old_Scheduled_Time__c = oldMap.get( serApp.Id ).NSP_StartEndTime__c;
                    serApp.NSP_Old_End_Time__c = oldMap.get( serApp.Id ).SchedEndTime;
                    saIdToDeletEvent.add( serApp.Id );
                }
                //added as a part of STY - 04135
                //schedule start is edited AND duration is edited
                if ( serApp.Duration != null ) {
                    if ( ( serApp.SchedStartTime != null )
                        && ( ( serApp.Duration != oldMap.get( serApp.Id ).Duration )
                            || ( serApp.SchedStartTime != oldMap.get( serApp.Id ).SchedStartTime )
                            )
                        )
                    {
                        serApp.SchedEndTime = serApp.SchedStartTime.addMinutes(
                            Integer.valueof( serApp.Duration )
                        );
                    }
                    //schedule end is edited AND Duration and scheduled end are updated
                    if ( ( serApp.SchedEndTime != null )
                        && ( ( serApp.Duration != oldMap.get( serApp.Id ).Duration )
                            || ( serApp.SchedEndTime != oldMap.get( serApp.Id ).SchedEndTime )
                            )
                        )
                    {
                        serApp.SchedStartTime = serApp.SchedEndTime.addMinutes(
                            ( -1 * Integer.valueof( serApp.Duration ) )
                        );
                    }
                }
            }
            if ( !checkStatusChangeSaList.isEmpty() ) {
                checkStatusChange( checkStatusChangeSaList );
            }
            if ( !saIdToDeletEvent.isEmpty() ) {
                EventDeletion.deleteCancelledEvent( saIdToDeletEvent );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ServiceAppointmentTriggerHelper.class.getName() ,
                'beforeUpdateDirector' ,
                e
            );
        }
    }

    //
    //
    //

    private static void syncBackFieldsToProjectTask( Set<Id> serviceAppointmentIds ) {
        if ( ( serviceAppointmentIds != null )
            && !serviceAppointmentIds.isEmpty()
            && !System.isBatch()
            )
        {
            if ( NSP_ServiceAppointmentTriggerHelper.isEnabledQueueableSync ) {
                if ( ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() )
                    && !System.isQueueable()
                    )
                {
                    ServiceAppointmentSyncQueueable.enqueueJob( serviceAppointmentIds );
                }
            } else if ( NSP_ServiceAppointmentTriggerHelper.isEnabledFutureSync ) {
                if ( ( Limits.getFutureCalls() < Limits.getLimitFutureCalls() )
                    && !System.isFuture()
                    )
                {
                    NSP_ServiceAppointmentTriggerHelper.syncBackFieldsToProjectTaskFuture( serviceAppointmentIds );
                }
            }
        }
    }

    //
    // Description: Updated to Service Appointment on specific fields will sync back to ProjectTask and WorkOrder
    // @param newMap of Service Appointment from Trigger
    // @param oldMap of Service Appointment from Trigger
    // @return void
    //
    // DEPRECATED
    @future
    private static void syncBackFieldsToProjectTaskFuture( Set<Id> serviceAppointmentIds ) {
        Map<Id,ServiceAppointment> workOrderIdServiceAppointment = new Map<Id,ServiceAppointment>();
        Set<Id> serviceAppointmentIdSet = new Set<Id>();
        Map<Id,Id> serviceAppIdAssigResMap = new Map<Id,Id>();
        Map<Id,Id> assignResIdServiceResMap = new Map<Id,Id>();
        List<WorkOrder> lstWorKOrderToUpdate = new List<WorkOrder>();
        List<pse__Project_Task__c> lstProjectTaskToUpdate = new List<pse__Project_Task__c>();
        Set<Id> serviceTerritoryId = new Set<Id>();
        Map<Id,String> mapOfServiceTerritoryIdToName = new Map<Id,String>();
        try {
            for ( ServiceAppointment eachSa : [
                        SELECT
                            Id ,
                            Status ,
                            Description ,
                            Subject ,
                            NSP_Orientation_Address__c ,
                            ServiceTerritoryId ,
                            ParentRecordId ,
                            EarliestStartTime ,
                            OwnerId ,
                            Duration ,
                            SchedStartTime ,
                            SchedEndTime,NSP_Meeting_Type__c
                        FROM ServiceAppointment
                        WHERE ( Id IN :serviceAppointmentIds )
                    ]
                )
            {
                workOrderIdServiceAppointment.put( eachSa.ParentRecordId , eachSa );
                serviceAppointmentIdSet.add( eachSa.Id );
                serviceTerritoryId.add( eachSa.ServiceTerritoryId );
            }
            if ( !serviceTerritoryId.isEmpty() ) {
                for ( ServiceTerritory eachTerritory : [
                            SELECT Id , Name
                            FROM ServiceTerritory
                            WHERE ( Id IN :serviceTerritoryId )
                        ]
                    )
                {
                    mapOfServiceTerritoryIdToName.put( eachTerritory.Id , eachTerritory.Name );
                }
            }
            if ( !workOrderIdServiceAppointment.isEmpty() ) {
                for ( WorkOrder oWorkOrder : [
                            SELECT Id , NSP_Project_Task__c
                            FROM WorkOrder
                            WHERE ( Id IN :workOrderIdServiceAppointment.keySet() )
                            WITH SECURITY_ENFORCED
                        ]
                    )
                {
                    ServiceAppointment serviceApp = workOrderIdServiceAppointment.get( oWorkOrder.Id );
                    lstWorKOrderToUpdate.add(
                        NSP_ServiceAppointmentTriggerHelper.updateWorkOrderRec(
                            oWorkOrder.Id ,
                            serviceApp
                        )
                    );
                    lstProjectTaskToUpdate.add(
                        NSP_ServiceAppointmentTriggerHelper.updateProjectTaskRec(
                            oWorkOrder.NSP_Project_Task__c ,
                            serviceApp ,
                            mapOfServiceTerritoryIdToName
                        )
                    );
                }
            }
            //checking if the map is empty
            if ( !workOrderIdServiceAppointment.isEmpty() ) {
                //querying assigned resource to get service resource
                for ( AssignedResource oAssigRes : [
                            SELECT Id , ServiceAppointmentId , ServiceResourceId
                            FROM AssignedResource
                            WHERE ( ServiceAppointmentId IN :serviceAppointmentIdSet )
                        ]
                    )
                {
                    //storing map service appointment id and assigned resource Id
                    serviceAppIdAssigResMap.put(
                        oAssigRes.ServiceAppointmentId ,
                        oAssigRes.ServiceResourceId
                    );
                    //storing map assigned resource id and service resouce userId
                    assignResIdServiceResMap.put(
                        oAssigRes.ServiceResourceId ,
                        NSP_ServiceAppointmentTriggerHelper.getAssignedResUser( oAssigRes.ServiceResourceId )
                    );
                }
                if ( !serviceAppIdAssigResMap.isEmpty() ) {
                    //calling the method to syn the project task, workorder and service appointment ownerId
                    NSP_ServiceAppointmentTriggerHelper.syncProjTaskOwnerSA(
                        workOrderIdServiceAppointment ,
                        serviceAppIdAssigResMap ,
                        assignResIdServiceResMap
                    );
                }
            }
            if ( !lstWorKOrderToUpdate.isEmpty() && Schema.sObjectType.WorkOrder.isUpdateable() ) {
                Database.update( lstWorKOrderToUpdate , false );
            }
            if ( !lstProjectTaskToUpdate.isEmpty() && Schema.sObjectType.pse__Project_Task__c.isUpdateable() ) {
                Database.update( lstProjectTaskToUpdate , false );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ServiceAppointmentTriggerHelper.class.getName() ,
                'syncBackFieldsToProjectTask' ,
                e
            );
        }
    }

    //
    // MethodName: updateWorkOrderRec
    // Description : Updating the Work Order Record
    // Params:  Id workOrderId, ServiceAppointment saRecord
    //
    // DEPRECATED
    private static WorkOrder updateWorkOrderRec( Id workOrderId , ServiceAppointment saRecord ) {
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

    //
    // MethodName: updateProjectTaskRec
    // Description : Updating the Project Task Record
    // Params: Id projectTaskId, ServiceAppointment saRecord,  Map<Id,String> mapOfServiceTerritoryIdToName
    //
    // DEPRECATED
    private static pse__Project_Task__c updateProjectTaskRec( Id projectTaskId , ServiceAppointment saRecord , Map<Id,String> mapOfServiceTerritoryIdToName ) {
        //Updating the Project Task Record when Service Appointment is updated
        pse__Project_Task__c projTaskRecToUpdate = new pse__Project_Task__c();
        projTaskRecToUpdate.Id = projectTaskId;
        projTaskRecToUpdate.pse__Status__c = saRecord.Status;
        projTaskRecToUpdate.pse__Long_Description__c = saRecord.Description;
        projTaskRecToUpdate.Name = saRecord.Subject;
        projTaskRecToUpdate.NSP_Meeting_Type__c = saRecord.NSP_Meeting_Type__c;
        projTaskRecToUpdate.NSP_Orientation_Address__c = saRecord.NSP_Orientation_Address__c;
        projTaskRecToUpdate.NSP_Dispatch_Region__c = mapOfServiceTerritoryIdToName.get( saRecord.ServiceTerritoryId );
        projTaskRecToUpdate.pse__Start_Date_Time__c = saRecord.SchedStartTime;
        projTaskRecToUpdate.pse__End_Date_Time__c = saRecord.SchedEndTime;
        return projTaskRecToUpdate;
    }

    //
    // Description: this will check whether the specified fields are updated to sync back to ProjectTask
    // Author : Anil
    // @param oServiceApp of Service Appointment from Trigger
    // @param oldServiceApp of Service Appointment from Trigger
    // @return Boolean
    //
    public static Boolean isfieldsUpdatedToSyncBackProjectTask( ServiceAppointment oServiceApp , ServiceAppointment oldServiceApp ) {
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

    //
    // MethodName : checkStatusChange
    // Description : This Method updated the status checkbox on Service Appointments
    // Params : List<ServiceAppointment> checkStatusChangeSaList
    // Author : Nischay Jindal
    //
    public static void checkStatusChange( List<ServiceAppointment> checkStatusChangeSaList ) {
        try {
            for ( ServiceAppointment serApp : checkStatusChangeSaList ) {
                // update the flag when the first time status is set to dispatched
                serApp.NSP_IsDispatched__c = true;
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ServiceAppointmentTriggerHelper.class.getName() ,
                'checkStatusChange' ,
                e
            );
        }
    }

    // sends email to users after status Changes
    public static void sendEmailNotifications( Map<Id,ServiceAppointment> newMap , Map<Id,ServiceAppointment> oldMap ) {
        try {
            Set<Id> workOrderIdSet = new Set<Id>();
            Set<Id> serAppIdSet = new Set<Id>();
            for ( ServiceAppointment servApp : newMap.values() ) {
                if ( ( NSP_ServiceAppointmentTriggerHelper.isStatusChange( servApp , oldMap )
                        || NSP_ServiceAppointmentTriggerHelper.isRecordChanged( servApp , oldMap.get( ServApp.Id ) )
                        )
                    && ( servApp.ParentRecordId != null )
                    )
                {
                    Id myRecordId = servApp.ParentRecordId;
                    String sObjName = myRecordId.getSObjectType().getDescribe().getName();
                    serAppIdSet.add( servApp.Id );
                    if ( sObjName == NSP_ServiceConstants.workOrder ) {
                        workOrderIdSet.add( servApp.ParentRecordId );
                    }
                }
            }
            if ( !serAppIdSet.isEmpty() && !workOrderIdSet.isEmpty() ) {
                Map<Id,List<String>> mapSerIdListResources = NSP_ServiceAppointmentTriggerHelper.getAssignedResources( serAppIdSet );
                Map<Id,WorkOrder> workOrderMap = NSP_ServiceAppointmentTriggerHelper.getWorkOrders( workOrderIdSet );
                Set<Id> taskIdSet = new Set<Id>();
                Map<Id,Id> mapwrkOrderTaskId = new Map<Id,Id>();
                for ( WorkOrder wrkOrd : workOrderMap.values() ) {
                    if ( wrkOrd.NSP_Project_Task__c != null ) {
                        taskIdSet.add( wrkOrd.NSP_Project_Task__c );
                        mapwrkOrderTaskId.put( wrkOrd.Id , wrkOrd.NSP_Project_Task__c );
                    }
                }
                Map<Id,List<String>> maptaskIdListEmails = NSP_ServiceAppointmentTriggerHelper.getPrjTaskAssignments( taskIdSet );
                Set<Id> ownerIdSet = NSP_ServiceAppointmentTriggerHelper.getOldOwnerSet( oldMap );
                Map<Id,String> ownerIdToEmailMap = NSP_ServiceAppointmentTriggerHelper.getOwnerEmailMap( ownerIdSet );
                List<String> listOfTOAddresses = new List<String> ();
                Map<String,EmailTemplate> emailTemplateMap = NSP_ServiceAppointmentTriggerHelper.getEmailTemplates();
                for ( ServiceAppointment servApp : newMap.values() ) {
                    if ( workOrderMap.containsKey( servApp.ParentRecordId )
                        && maptaskIdListEmails.containsKey( workOrderMap.get( servApp.ParentRecordId ).NSP_Project_Task__c )
                        )
                    {
                        listOfTOAddresses.addAll(
                            maptaskIdListEmails.get( workOrderMap.get( servApp.ParentRecordId ).NSP_Project_Task__c )
                        );
                    }
                    if ( mapSerIdListResources.containsKey( servApp.Id ) ) {
                        listOfTOAddresses.addAll( mapSerIdListResources.get( servApp.Id ) );
                    }
                    NSP_ServiceAppointmentTriggerHelper.callSendEmail(
                        listOfTOAddresses ,
                        servApp ,
                        oldMap ,
                        ownerIdToEmailMap ,
                        emailTemplateMap
                    );
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ServiceAppointmentTriggerHelper.class.getName() ,
                'sendEmailNotifications' ,
                e
            );
        }
    }
    private static Set<Id> getOldOwnerSet(Map<Id,ServiceAppointment> oldMap){
        Set<Id> ownerIdSet = new Set<Id>();
        if(oldMap != null && oldMap.values() != null){
            for(ServiceAppointment oldSA : oldMap.values()){
                if(oldSA != null){
                    ownerIdSet.add(oldSA.ownerId);
                }
            }
        }
        return ownerIdSet;
    }

    private static void callSendEmail(List<String> listOfTOAddresses, ServiceAppointment servApp, Map<Id,ServiceAppointment> oldMap, Map<Id,String> ownerIdToEmailMap, Map<String,EmailTemplate> emailTemplateMap ) {
        if(listOfTOAddresses != null && !listOfTOAddresses.isEmpty() && servApp != null && oldMap != null && oldMap.containsKey(servApp.Id)){
            ServiceAppointment oldSA = oldMap.get(servApp.Id);
            if(oldSA != null && oldSA.ServiceTerritoryId != null  &&  isOwnerChanged (servApp,oldSA ) ){
                Id oldOwnerId = oldSA.ownerId;
                if(ownerIdToEmailMap != null && ownerIdToEmailMap.containskey(oldOwnerId)){
                    listOfTOAddresses.add(ownerIdToEmailMap.get(oldOwnerId));
                }
            }
            Id empTemplateId = getEmailTemplateId(servApp,oldSA,emailTemplateMap);
            if(empTemplateId != null && listOfTOAddresses != null){
                sendMail(listOfTOAddresses,servApp.Id,empTemplateId);
            }
        }
    }

    // determines correct Email Template to be sent based on new/old Service Appointment records...
    private static Id getEmailTemplateId(
        ServiceAppointment recordNew ,
        ServiceAppointment recordOld ,
        Map<String,EmailTemplate> emailTemplateMap
        )
    {
        EmailTemplate template = null;
        if ( ( recordNew != null )
            && ( recordOld != null )
            && ( emailTemplateMap != null )
            )
        {
            if ( recordNew.Status != recordOld.Status ) {
                if ( recordNew.NSP_IsDispatched__c
                    && !recordOld.NSP_IsDispatched__c
                    && emailTemplateMap.containsKey( NSP_ServiceConstants.SerAppDispatchedEmailTemplate )
                    )
                {
                    template = emailTemplateMap.get( NSP_ServiceConstants.SerAppDispatchedEmailTemplate );
                } else if ( ( recordNew.Status == NSP_ServiceConstants.dispatchStatus )
                    && emailTemplateMap.containsKey( NSP_ServiceConstants.SerAppReScheduleEmailTemplate )
                    )
                {
                    template = emailTemplateMap.get( NSP_ServiceConstants.SerAppReScheduleEmailTemplate );
                }
                else if ( ( recordOld.Status == NSP_ServiceConstants.dispatchStatus )
                    && ( recordNew.Status == NSP_ServiceConstants.PROJECT_TASK_CANCELLED )
                    && emailTemplateMap.containsKey( NSP_ServiceConstants.SerAppNoneEmailTemplate )
                    )
                {
                    template = emailTemplateMap.get( NSP_ServiceConstants.SerAppNoneEmailTemplate );
                }
            } else if ( ( recordOld.ServiceTerritoryId != null )
                && NSP_ServiceAppointmentTriggerHelper.isRecordChanged( recordNew , recordOld )
                && emailTemplateMap.containsKey( NSP_ServiceConstants.SerAppRecordChangeEmailTemplate )
                )
            {
                template = emailTemplateMap.get( NSP_ServiceConstants.SerAppRecordChangeEmailTemplate );
            }
        }
        return ( ( template != null ) ? template.Id : null );
    }

    private static Map<Id,String> getOwnerEmailMap(Set<Id> ownerIdSet){
        Map<Id,String> ownerMap = new Map<Id,String>();
        if(ownerIdSet != null){
            List<User> userList = [SELECT id, Email FROM User WHERE ID = :ownerIdSet];
            for(User eachUser : userList) {
                if(eachUser != null && eachUser.Email != null){
                    ownerMap.put(eachUser.Id, eachUser.Email);
                }
            }
        }
        return ownerMap;
    }

    private static Boolean isOwnerChanged(ServiceAppointment servApp, ServiceAppointment oldSa){
        Boolean isRecordOwnerChanged = false;
        if(oldSa != null && servApp != null && oldSa.OwnerId != servApp.OwnerId){
            isRecordOwnerChanged = true;
        }
        return isRecordOwnerChanged;
    }

    //
    // Description: this will syn the project task owner, work order owner and service appointment owner with assigned resource userId
    // @param map of workorder Id and ServiceAppointment Record
    // @param map of serviceAppointment Id and Assigned Resource Id
    // @param map of Assigned Resource Id Id and Service Resource Id
    // @return void
    //
    public static void syncProjTaskOwnerSA(
        Map<Id,ServiceAppointment> workOrderIdServiceAppointment ,
        Map<Id,Id> serviceAppIdAssigResMap ,
        Map<Id,Id> assignResIdServiceResMap
        )
    {
        ServiceAppointment serviceApp;
        List<WorkOrder> lstWorKOrderToUpdate = new List<WorkOrder>();
        List<pse__Project_Task__c> lstProjectTaskToUpdate = new List<pse__Project_Task__c>();
        //quering service appointment to update ownerId field with service resource UserId
        List<ServiceAppointment> serviceAppList = updateServiceAppointments( serviceAppIdAssigResMap , assignResIdServiceResMap );
        //quering the workorder to update
        for ( WorkOrder oWorkOrder : [
                    SELECT
                        Id ,
                        StartDate ,
                        EndDate ,
                        NSP_Project_Task__c ,
                        NSP_Project_Task__r.pse__Start_Date_Time__c ,
                        NSP_Project_Task__r.pse__End_Date_Time__c ,
                        LastModifiedDate
                    FROM WorkOrder
                    WHERE ( Id IN :workOrderIdServiceAppointment.keySet() )
                ]
            )
        {
            serviceApp = workOrderIdServiceAppointment.get( oWorkOrder.Id );
            //making the clone of existing workorder Id & project task Id then updating the fields
            lstWorKOrderToUpdate.add(
                updateWorkOrder(
                    oWorkOrder ,
                    serviceApp ,
                    serviceAppIdAssigResMap ,
                    assignResIdServiceResMap
                )
            );
            lstProjectTaskToUpdate.add(
                updateProjectTask(
                    oWorkOrder ,
                    serviceApp ,
                    serviceAppIdAssigResMap ,
                    assignResIdServiceResMap
                )
            );
        }
         //updating the work order
        if ( !lstWorKOrderToUpdate.isEmpty() && Schema.sObjectType.WorkOrder.isUpdateable() ) {
            List<Database.SaveResult> results = Database.update( lstWorKOrderToUpdate , false );
            NSP_ErrorLogHandler.logResults(
                NSP_ServiceAppointmentTriggerHelper.class.getName() ,
                'syncProjTaskOwnerSA:WorkOrder' ,
                results
            );
        }
        //updating the project task
        if ( !lstProjectTaskToUpdate.isEmpty() && Schema.sObjectType.pse__Project_Task__c.isUpdateable() ) {
            List<Database.SaveResult> results = Database.update( lstProjectTaskToUpdate , false );
            NSP_ErrorLogHandler.logResults(
                NSP_ServiceAppointmentTriggerHelper.class.getName() ,
                'syncProjTaskOwnerSA:pse__Project_Task__c' ,
                results
            );
        }
        //updating service appointment
        if ( !serviceAppList.isEmpty() && Schema.sObjectType.ServiceAppointment.isUpdateable() ) {
            List<Database.SaveResult> results = Database.update( serviceAppList , false );
            NSP_ErrorLogHandler.logResults(
                NSP_ServiceAppointmentTriggerHelper.class.getName() ,
                'syncProjTaskOwnerSA:ServiceAppointment' ,
                results
            );
        }
    }

    //
    // MethodName: sendMail
    // Description : Helper method for email body
    // Params:       String subjectString, String mailBody, list<String> listOfTOAddresses, String fromAddress, Id targetId, Id templateId
    // Author :      Nischay Jindal
    //
    private static void sendMail( List<String> listOfTOAddresses , Id targetId , Id templateId ) {
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
        if ( !System.Test.isRunningTest()
            && EmailDeliverabilityController.isEnabledOutbound
            )
        {
            Messaging.sendEmail( new Messaging.SingleEmailMessage[]{ email } );
        }
    }

    //
    // MethodName: getAssignedResources
    // Description : Helper method to retrieve resourses
    // Params: Set<Id>serAppIdSet
    // Author : Nischay Jindal
    //
    private static Map<Id,List<String>> getAssignedResources( Set<Id> serAppIdSet ) {
        Map<Id,List<String>> mapSerIdListEmailResources = new Map<Id,List<String>>();
        for(ServiceAppointment serApp :[SELECT Id, Owner.Email FROM ServiceAppointment WHERE Id IN : serAppIdSet]){
            if(!mapSerIdListEmailResources.containsKey(serApp.Id)){
                mapSerIdListEmailResources.put(serApp.Id, new List<String>());
            }
            mapSerIdListEmailResources.get(serApp.Id).add(serApp.Owner.Email);
        }
        return mapSerIdListEmailResources;
    }

    //
    // MethodName: getWorkOrders
    // Description : Helper method to retrieve workorder
    // Params:   Set<Id>workOrderIdSet
    // Author :      Nischay Jindal
    //
    private static Map<Id,WorkOrder> getWorkOrders( Set<Id> workOrderIdSet ) {
        Map<Id,WorkOrder> workOrderMap = new Map<Id,WorkOrder>([Select Id , NSP_Project_Task__c from WorkOrder WHERE Id IN: workOrderIdSet ]);
        return workOrderMap;
    }

    //
    // MethodName: getPrjTaskAssignments
    // Description : Helper method to retrieve PTA
    // Params:   Set<Id>taskIdSet
    // Author :      Nischay Jindal
    //
    private static Map<Id,List<String>> getPrjTaskAssignments( Set<Id> taskIdSet ) {
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

    // select relevant Email Templates...
    private static Map<String,EmailTemplate> getEmailTemplates() {
        List<EmailTemplate> emailTempList =[
            SELECT
                Id ,
                Name ,
                DeveloperName ,
                HtmlValue ,
                Subject ,
                Body
            FROM EmailTemplate
            WHERE (
                DeveloperName IN (
                    :NSP_ServiceConstants.SerAppReScheduleEmailTemplate ,
                    :NSP_ServiceConstants.SerAppNoneEmailTemplate ,
                    :NSP_ServiceConstants.SerAppRecordChangeEmailTemplate ,
                    :NSP_ServiceConstants.SerAppDispatchedEmailTemplate
                )
            )
        ];
        Map<String,EmailTemplate> emailTempMap = new Map<String,EmailTemplate>();
        if ( ( emailTempList != null ) && !emailTempList.isEmpty() ) {
            for ( EmailTemplate emp : emailTempList ) {
                emailTempMap.put( emp.DeveloperName , emp );
            }
        }
        return emailTempMap;
    }

    //
    // MethodName: isStatusChange
    // Description : return true if status or fields changed on SA
    // Author :      Nischay Jindal
    //
    private static Boolean isStatusChange( ServiceAppointment servApp , Map<Id,ServiceAppointment> oldmap ) {
        return (servApp.NSP_IsDispatched__c ||
                (servApp.Status !=null &&
                (oldmap.get(servApp.Id).Status != NSP_ServiceConstants.dispatchStatus && servApp.Status == NSP_ServiceConstants.dispatchStatus)  ||
                (oldmap.get(servApp.Id).Status != NSP_ServiceConstants.PROJECT_TASK_CANCELLED && servApp.Status == NSP_ServiceConstants.PROJECT_TASK_CANCELLED))  );
    }

    private static Boolean isRecordChanged( ServiceAppointment recordNew , ServiceAppointment recordOld ) {
        return (
            ( recordNew != null )
            && ( recordNew.Status == NSP_ServiceConstants.dispatchStatus )
            && ( recordOld != null )
            && ( ( recordOld.NSP_Orientation_Address__c != recordNew.NSP_Orientation_Address__c )
                || ( recordOld.Description != recordNew.Description )
                || ( recordOld.Duration != recordNew.Duration )
                || ( recordOld.SchedStartTime != recordNew.SchedStartTime )
                || ( recordOld.SchedEndTime != recordNew.SchedEndTime )
                || ( recordOld.OwnerId != recordNew.OwnerId )
            )
        );
    }

    //
    // Description: this will return the service resource UserId
    // @param Service Resource Id
    // @return Id
    //
    private static Id getAssignedResUser( Id serviceResId ) {
        List<String> serviceResApp_Fields = new List<String>{'Id', 'RelatedRecordId'};
        String query = new NSP_QueryBuilder(NSP_ServiceConstants.SERVICERES_SOBJECT_NAME, serviceResApp_Fields)
                                .addFilter('Id', serviceResId).build();
        List<ServiceResource> oserviceRes = (List<ServiceResource>) Database.query(query);
        return oserviceRes[0].RelatedRecordId;
    }

    //
    // Description: this method will update Service Appointment OwnerId and return the list of Service Appointment
    // @param map of service appointment Id and Assigned resource Id
    // @param map of Assigned resource Id and Resource Service User Id
    // @return List of Service Appointment
    //
    private static List<ServiceAppointment> updateServiceAppointments( Map<Id,Id> serviceAppIdAssigResMap , Map<Id,Id> assignResIdServiceResMap ) {
        List<ServiceAppointment> serviceAppList = new List<ServiceAppointment>();
        for(ServiceAppointment oservice: [SELECT Id, OwnerId
                                          FROM ServiceAppointment
                                          WHERE Id IN: serviceAppIdAssigResMap.keySet()]){
            oservice.OwnerId = assignResIdServiceResMap.get(serviceAppIdAssigResMap.get(oservice.Id));
            serviceAppList.add(oservice);
        }
        return serviceAppList;
    }

    //
    // Description: this method will update WorkOrder fields
    // @param WorkOrder record
    // @param map of service appointment Id and Assigned resource Id
    // @param map of Assigned resource Id and Resource Service User Id
    // @return List of Service Appointment
    //
    private static WorkOrder updateWorkOrder(
        WorkOrder oWorkOrder ,
        ServiceAppointment serviceApp ,
        Map<Id,Id> serviceAppIdAssigResMap ,
        Map<Id,Id> assignResIdServiceResMap
        )
    {
        WorkOrder response = new WorkOrder(
            Id=oWorkOrder.Id ,
            OwnerId=assignResIdServiceResMap.get( serviceAppIdAssigResMap.get( serviceApp.Id ) ) ,
            Status=serviceApp.Status ,
            Description=serviceApp.Description ,
            NSP_Meeting_Type__c=serviceApp.NSP_Meeting_Type__c
        );
        // prevent ~ FIELD_INTEGRITY_EXCEPTION, The Start Date must be equal to or earlier than the End Date.: Start Date: [StartDate]
        if ( serviceApp.EarliestStartTime <= oWorkOrder.EndDate ) {
            response.StartDate = serviceApp.EarliestStartTime;
        }
        return response;
    }

    //
    // Description: this method will update Project Task fields
    // @param WorkOrder record
    // @param Service Appointment record
    // @param map of service appointment Id and Assigned resource Id
    // @param map of Assigned resource Id and Resource Service User Id
    // @return List of Service Appointment
    //
    private static pse__Project_Task__c updateProjectTask(
        WorkOrder oWorkOrder ,
        ServiceAppointment serviceApp ,
        Map<Id,Id> serviceAppIdAssigResMap ,
        Map<Id,Id> assignResIdServiceResMap
        )
    {
        pse__Project_Task__c response = new pse__Project_Task__c(
            Id=oWorkOrder.NSP_Project_Task__c ,
            OwnerId=assignResIdServiceResMap.get( serviceAppIdAssigResMap.get( serviceApp.Id ) ) ,
            pse__Status__c=serviceApp.Status ,
            NSP_Meeting_Type__c=serviceApp.NSP_Meeting_Type__c ,
            pse__Long_Description__c=serviceApp.Description
        );
        // prevent ~ FIELD_CUSTOM_VALIDATION_EXCEPTION, Start date &amp; time must be before the end date &amp; time: [pse__End_Date_Time__c]
        if ( serviceApp.EarliestStartTime <= oWorkOrder.NSP_Project_Task__r.pse__End_Date_Time__c ) {
            response.pse__Start_Date_Time__c = serviceApp.EarliestStartTime;
        }
        return response;
    }

    //
    // MethodName: createOrDeleteFreeEvent
    // Description : create event rec after scheduling Event
    // Params: List<ServiceAppointment> createOrDeletSaList
    //
    public static void createOrDeleteFreeEvent( List<ServiceAppointment> createOrDeletSaList ) {
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
        if ( !eventToInsert.isEmpty() ) {
            List<Database.SaveResult> results = Database.insert( eventToInsert , false );
            NSP_ErrorLogHandler.logResults(
                NSP_ServiceAppointmentTriggerHelper.class.getName() ,
                'createOrDeleteFreeEvent' ,
                results
            );
        }
    }

    //
    // MethodName: changeFreeEventToBusy
    // Description : change free event to busy
    // Params: Set<Id> eventIdDelete
    //
    public static void changeFreeEventToBusy( Set<Id> eventIdDelete ) {
        if ( ( eventIdDelete != null ) && !eventIdDelete.isEmpty() ) {
            List<Event> eventRecListDelete = new List<Event>();
            for( Event eachEvent : [
                        SELECT Id ,WhatId ,ShowAs
                        FROM Event
                        WHERE ( WhatId IN :eventIdDelete )
                    ]
                )
            {
                eachEvent.ShowAs = 'Busy';
                eventRecListDelete.add(eachEvent);
            }
            if ( !eventRecListDelete.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( eventRecListDelete , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ServiceAppointmentTriggerHelper.class.getName() ,
                    'changeFreeEventToBusy' ,
                    results
                );
            }
        }
    }

    // MethodName: createNewEventRec
    // Description : return new related Event record
    // Params: ServiceAppointment relatedSa
    //
    private static Event createNewEventRec( ServiceAppointment relatedSa , Map<Id,Id> saToSerResUserIdMap ) {
        // create new event record when a Service Appointment is scheduled...
        Event newFreeEvent = new Event();
        if ( relatedSa != null ) {
            newFreeEvent.WhatId = relatedSa.id;
            newFreeEvent.RecordTypeId = NSP_ServiceAppointmentTriggerHelper.coreServiceEventRecordType;
            newFreeEvent.NSP_Event_Type__c = 'Core Service';
            newFreeEvent.FSL__Event_Type__c = 'Service Appointment';
            newFreeEvent.ShowAs = 'Free';
            newFreeEvent.Subject = relatedSa.Subject;
            newFreeEvent.Description = relatedSa.Description;
            newFreeEvent.Location = relatedSa.NSP_Orientation_Address__c;
            newFreeEvent.StartDateTime = relatedSa.SchedStartTime;
            newFreeEvent.EndDateTime = relatedSa.SchedEndTime;
            if ( ( saToSerResUserIdMap != null )
                && saToSerResUserIdMap.containsKey( relatedSa.Id )
                && ( saToSerResUserIdMap.get( relatedSa.Id ) != null )
                )
            {
                newFreeEvent.OwnerId = saToSerResUserIdMap.get( relatedSa.Id );
            }
        }
        return newFreeEvent;
    }

    //
    // MethodName : afterUpdateDirector
    // Description : after update Director method
    // Params : Map<Id,ServiceAppointment> newMap ,Map<Id,ServiceAppointment> oldMap
    // Author : Abhishek Kumar
    //
    public static void afterUpdateDirector( Map<Id,ServiceAppointment> newMap , Map<Id,ServiceAppointment> oldMap ) {
        Set<Id> serviceAppintmentUpdatedIds = new Set<Id>();
        List<ServiceAppointment> createOrDeletSaList =  new List<ServiceAppointment>();
        Map<Id,ServiceAppointment> mapOfSaIdToRec = new Map<Id,ServiceAppointment> ();
        Map<Id,ServiceAppointment> mapOfSaIdToServAppRec = new Map<Id,ServiceAppointment> ();
        Set<Id> saIdToUpdateEvent = new Set<Id>();
        try {
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
                if ( isSaUpdatedToUpdateEvent( serApp , oldMap.get( serApp.Id ) )
                    && ( mapOfSaIdToRec.get( serApp.Id ) == null )
                    )
                {
                    mapOfSaIdToRec.put( serApp.Id , serApp );
                }
            }
            if(!mapOfSaIdToServAppRec.isEmpty()){
                updateServiceTerritory(mapOfSaIdToServAppRec);
            }
            NSP_ServiceAppointmentTriggerHelper.syncBackFieldsToProjectTask( serviceAppintmentUpdatedIds );
            //call createOrDeleteFreeEvent
            if(!createOrDeletSaList.isEmpty()){
                createOrDeleteFreeEvent( createOrDeletSaList );
            }
            //call changeFreeEventToBusy
            if(!saIdToUpdateEvent.isEmpty()){
                changeFreeEventToBusy( saIdToUpdateEvent );
            }
            if ( !mapOfSaIdToRec.isEmpty() ) {
                NSP_ServiceAppointmentTriggerHelper.updateSaRelatedEvent( mapOfSaIdToRec );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ServiceAppointmentTriggerHelper.class.getName() ,
                'afterUpdateDirector' ,
                e
            );
        }
    }

    //
    // MethodName: updateServiceTerr
    // Description : Updating the Service Appointment Service Territory field
    // Params: (Map< Id, ServiceAppointment> mapOfSaIdToServAppRec
    //
    private static void updateServiceTerritory( Map<Id,ServiceAppointment> mapOfSaIdToServAppRec ) {
        Map<Id,Id> serviceResAssignRes = new Map<Id,Id>();
        Map<Id,Id> servAppAssignRes = new Map<Id,Id>();
        Map<Id,Id> servAppUser = new Map<Id,Id>();
        List<ServiceAppointment> updateServApp = new List<ServiceAppointment>();
        try {
            for ( AssignedResource assignRes : [
                        SELECT Id , ServiceAppointmentId , ServiceResourceId
                        FROM AssignedResource
                        WHERE ( ServiceAppointmentId IN :mapOfSaIdToServAppRec.keySet() )
                    ]
                )
            {
                serviceResAssignRes.put( assignRes.ServiceResourceId , assignRes.Id );
                servAppAssignRes.put( assignRes.Id , assignRes.ServiceAppointmentId );
            }
            for ( ServiceTerritoryMember servTemMem : [
                        SELECT Id , ServiceResourceId , ServiceTerritoryId
                        FROM ServiceTerritoryMember
                        WHERE ( ServiceResourceId IN :serviceResAssignRes.keySet() )
                    ]
                )
            {
                servAppUser.put(
                    servAppAssignRes.get( serviceResAssignRes.get( servTemMem.ServiceResourceId ) ) ,
                    servTemMem.ServiceTerritoryId
                );
            }
            for ( ServiceAppointment servApp : [
                        SELECT Id , ServiceTerritoryId
                        FROM ServiceAppointment
                        WHERE ( Id IN :servAppUser.keySet() )
                    ]
                )
            {
                servApp.ServiceTerritoryId = servAppUser.get( servApp.Id );
                updateServApp.add( servApp );
            }
            if ( !updateServApp.isEmpty() ) {
                List<Database.SaveResult> results =  Database.update( updateServApp , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ServiceAppointmentTriggerHelper.class.getName() ,
                    'updateServiceTerritory:update' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ServiceAppointmentTriggerHelper.class.getName() ,
                'updateServiceTerritory' ,
                e
            );
        }
    }

    //
    // MethodName: isSaUpdatedToUpdateEvent
    // Description : return true if record or fields changed on SA
    //
    private static Boolean isSaUpdatedToUpdateEvent( ServiceAppointment servApp , ServiceAppointment oldSa ) {
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

    // update related Event when ServiceAppointment is updated...
    private static void updateSaRelatedEvent( Map<Id,ServiceAppointment> mapSaIdToRec ) {
        if ( ( mapSaIdToRec != null ) && !mapSaIdToRec.isEmpty() ) {
            List<Event> eventListToUpdate = new List<Event>();
            for ( Event eachEvent : [
                        SELECT
                            Id ,
                            Subject ,
                            Description ,
                            Location ,
                            StartDateTime ,
                            EndDateTime ,
                            OwnerId ,
                            WhatId
                        FROM Event
                        WHERE ( WhatId IN :mapSaIdToRec.keySet() )
                    ]
                )
            {
                if ( mapSaIdToRec.containsKey( eachEvent.WhatId ) ) {
                    Event record = NSP_ServiceAppointmentTriggerHelper.populateEventFromServiceAppointment(
                        eachEvent ,
                        mapSaIdToRec.get( eachEvent.WhatId )
                    );
                    if ( record != null ) {
                        eventListToUpdate.add( eachEvent );
                    }
                }
            }
            if ( !eventListToUpdate.isEmpty() ) {
                List<Database.SaveResult> results =  Database.update( eventListToUpdate , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ServiceAppointmentTriggerHelper.class.getName() ,
                    'updateSaRelatedEvent' ,
                    results
                );
            }
        }
    }

    // helper method to defeat sonar cognitive complexity...
    private static Event populateEventFromServiceAppointment( Event record , ServiceAppointment related ) {
        if ( ( record != null ) && ( related != null ) ) {
            record.Subject = '[SF] ' + related.Subject;
            record.Description = related.Description;
            record.Location = related.NSP_Orientation_Address__c;
            record.StartDateTime = related.SchedStartTime;
            // Prevent DmlExceptions: FIELD_INTEGRITY_EXCEPTION, An event can't last longer than 14 days.: [EndDateTime]
            DateTime endDateTime = related.SchedEndTime;
            if ( ( related.SchedStartTime != null )
                && ( endDateTime != null )
                && ( ( endDateTime.getTime() - related.SchedStartTime.getTime() ) > ( 14 * 24 * 60 * 60 * 1000 ) )
                )
            {
                endDateTime = related.SchedStartTime.addDays( 14 );
            }
            record.EndDateTime = endDateTime;
            record.OwnerId =  related.OwnerId;
        }
        return record;
    }

    private static Id coreServiceEventRecordType {
        private get {
            if ( coreServiceEventRecordType == null ) {
                coreServiceEventRecordType = NSP_GenericRecordType.getRecordTypeId( 'Event' , 'Core_Serv_Event_RT' );
            }
            return coreServiceEventRecordType;
        }
        private set;
    }

    //
    //
    //

    private static Service_Appointment_Settings__c settings {
        private get {
            if ( settings == null ) {
                settings = Service_Appointment_Settings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabledQueueableSync {
        private get {
            if ( isEnabledQueueableSync == null ) {
                Boolean local = False;
                if ( settings != null ) {
                    local = NSP_ServiceAppointmentTriggerHelper.settings.IsEnabledQueueableSync__c;
                }
                isEnabledQueueableSync = local;
            }
            return isEnabledQueueableSync;
        }
        private set;
    }

    private static Boolean isEnabledFutureSync {
        private get {
            if ( isEnabledFutureSync == null ) {
                Boolean local = False;
                if ( settings != null ) {
                    local = NSP_ServiceAppointmentTriggerHelper.settings.IsEnabledFutureSync__c;
                }
                isEnabledFutureSync = local;
            }
            return isEnabledFutureSync;
        }
        private set;
    }

}
//