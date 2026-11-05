public with sharing class NSP_ProjectTasksTriggerServiceHelper {
    // test w/ NSP_ProjectTasksTriggerServiceHelperTest, NSP_ServiceAppointmentTrigger_Test (85%)
    // test w/ NSP_ProjectTasksTriggerServiceHelperTest (68%)
    // test w/ NSP_ServiceAppointmentTrigger_Test (65%)

    private Set<Id> allProjectIds = new Set<Id>();
    public static Boolean runOwnerAssignmentLogic = true;

    //
    // Description - This method handles all the before insert operations of project task records.
    // @return - void
    //
    public void beforeInsertDirector( List<pse__Project_Task__c> newProjectTasks ) {
        prepareBeforeInsertData( newProjectTasks );
    }

    // Prepares a map of data according to diff
    private void prepareBeforeInsertData( List<pse__Project_Task__c> newProjectTasks ) {
        Set<Id> updatePorjectTaskAccountIdSet = new Set<Id>();
        for ( pse__Project_Task__c projectTask : newProjectTasks ) {
            // added as a part of STY-02138
            if ( ( projectTask.pse__Project__c != null ) && ( projectTask.NSP_Account_Id__c == null ) ) {
                updatePorjectTaskAccountIdSet.add( projectTask.pse__Project__c );
            }
        }
        // added as a part of STY-02138
        if ( !updatePorjectTaskAccountIdSet.isEmpty() ) {
            updateProjectTaskAccount( newProjectTasks , updatePorjectTaskAccountIdSet );
        }
    }

    //
    // Iterates throught the list of new pse__Project_Task__c and passes the required attributes to other methods.
    // @param projectTaskList List of New project.
    // @param projectTaskOldMap Map of Old project.
    // @return void
    //
    public void afterUpdateProjectTask( List<pse__Project_Task__c> projectTaskList , Map<Id, pse__Project_Task__c> projectTaskOldMap ) {
        Map<Id,pse__Project_Task__c> mapOfProjectTaskIdAndProjecTask = new Map<Id,pse__Project_Task__c>();
        Map<Id,pse__Project_Task__c> mapOfProjectTaskIdAndProjecTask1 = new Map<Id,pse__Project_Task__c>();
        Map<String,Id> mapDispatchRegionToServiceTerritory = new Map<String,Id>();
        List<String> dispatchRegionList = new List<String>();
        Set<Id> projectIdSet = new Set<Id>();
        Map<Id,Id> accountIdProjectIdMap = new Map<Id,Id>();
        Set<Id> pTaskOwnerIdSet = new Set<Id>();
        Set<Id> setProjectId = new Set<Id>();
        Set<Id> setProjectTaskId = new Set<Id>();
        Set<Id> updateProjectTaskIdSet = new Set<Id>();
        Set<Id> deleteProjTaskIdSet = new Set<Id>();
        Id peoRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'pse__Project_Task__c' , 'PEO_Project_Task' );
        Id bpsRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'pse__Project_Task__c' , 'BPS_Project_Task' );

        for(pse__Project_Task__c pTask : projectTaskList){
            if(pTask.OwnerId != projectTaskOldMap.get(pTask.id).OwnerId && (pTask.RecordTypeId == peoRecordTypeId || pTask.RecordTypeId == bpsRecordTypeId)){
                pTaskOwnerIdSet.add(pTask.OwnerId);
                setProjectId.add(pTask.pse__Project__c);
                setProjectTaskId.add(pTask.Id);
            }


            // STY-02085  checking for checkBox(Create Work Order) on projectTask Object is checked and Disptach region field is not null
            if ( ( pTask.NSP_Create_Work_Order__c == true )
                && ( pTask.NSP_Create_Work_Order__c != projectTaskOldMap.get( pTask.Id ).NSP_Create_Work_Order__c )
                && String.isNotBlank( pTask.NSP_Dispatch_Region__c )
                )
            {
                mapOfProjectTaskIdAndProjecTask.put( pTask.Id , pTask );
            } else if ( pTask.NSP_Create_Work_Order__c
                && ( pTask.NSP_Dispatch_Region__c != null )
                && this.isFieldUpdatedOnPt( projectTaskOldMap.get( pTask.Id ) , pTask )
                )
            {
                dispatchRegionList.add( pTask.NSP_Dispatch_Region__c );
                mapOfProjectTaskIdAndProjecTask1.put( pTask.Id , pTask );
            }

            // added as a part of STY-02138
            if(pTask.pse__Project__c != null && pTask.NSP_Account_Id__c != null &&
               projectTaskOldMap.get(pTask.Id).NSP_Account_Id__c != pTask.NSP_Account_Id__c ){
                   projectIdSet.add(pTask.pse__Project__c);
                   accountIdProjectIdMap.put(pTask.NSP_Account_Id__c,pTask.pse__Project__c);
            }
               //added as a part of STY-03785
            if(pTask.pse__Project__c != null &&
                pTask.NSP_Visible_to_Client__c == true &&  !projectTaskOldMap.get(pTask.Id).NSP_Visible_to_Client__c){
                updateProjectTaskIdSet.add(pTask.id);
            }
            if( pTask.pse__Project__c != null  && !pTask.NSP_Visible_to_Client__c && projectTaskOldMap.get(pTask.Id).NSP_Visible_to_Client__c){
                deleteProjTaskIdSet.add(pTask.Id);
            }
        }
        //STY-03817
        //Getting service territory recs Id from List of regions
        if ( !dispatchRegionList.isEmpty() ) {
            for ( ServiceTerritory eachServiceTerritory : [
                        SELECT Id , Name
                        FROM ServiceTerritory
                        WHERE ( Name IN :dispatchRegionList )
                    ]
                )
            {
                mapDispatchRegionToServiceTerritory.put(
                    eachServiceTerritory.Name ,
                    eachServiceTerritory.Id
                );
            }
        }
        // This will update Resource field on PTA if it is PEO
        if(!setProjectId.isEmpty()){
            Map<String, Object> mapInputParams = new Map<String, Object>{
                'pTaskOwnerIdSet' => pTaskOwnerIdSet,
                'setProjectId' => setProjectId,
                'setProjectTaskId' => setProjectTaskId
            };
            List<NSP_ProjectTaskQueueEvent__e> lstTaskQueueEvent = new List<NSP_ProjectTaskQueueEvent__e>();
            lstTaskQueueEvent.add(new NSP_ProjectTaskQueueEvent__e(NSP_Input_Parameters__c = JSON.serialize(mapInputParams), NSP_MethodName__c = 'createPTAonProject', NSP_UserId__c = UserInfo.getUserId()));
            List<Database.SaveResult> results = EventBus.publish( lstTaskQueueEvent );
            NSP_ErrorLogHandler.logResults(
                NSP_ProjectTasksTriggerServiceHelper.class.getName() ,
                'afterUpdateProjectTask' ,
                results
            );
        }

        //creating WorkOrder Record
        if(mapOfProjectTaskIdAndProjecTask.keySet().size() > 0 ){
            createWorkOrderTask(mapOfProjectTaskIdAndProjecTask);
        }
        //updating Service Appointment
        if ( !mapOfProjectTaskIdAndProjecTask1.keySet().isEmpty()
            && !System.isQueueable()
            && !System.isFuture()
            )
        {
            this.updateServiceAppointment(
                mapOfProjectTaskIdAndProjecTask1 ,
                mapDispatchRegionToServiceTerritory
            );
        }
        // added as a part of STY-02138
        if(!projectIdSet.isEmpty() && !accountIdProjectIdMap.isEmpty()){
            createProjectAccount(projectTaskList,projectIdSet,accountIdProjectIdMap);
        }
        if(!updateProjectTaskIdSet.isEmpty()){
            NSP_ProjectTaskSharing.projectTaskRecordSharing(updateProjectTaskIdSet, null);
        }
        if(!deleteProjTaskIdSet.isEmpty()){
            NSP_ProjectTaskSharing.projectTaskRecordSharing(null, deleteProjTaskIdSet);
        }
    }

    //
    // Updating Service Appointment STY-02085
    // Description: If orientation address is update on project task then orientation address will be updated on service appointment
    // @param map of Project Tasks Id and ProjectTask
    // @param map of Dispatch Region and Service Territory rec
    // @return void
    //
    public void updateServiceAppointment( Map<Id,pse__Project_Task__c> mapProjectTasks , Map<String,Id> mapDispatchRegionToServiceTerritory ) {
        try {
            //Map of Work Order Id and Project Task and Project Task record
            Map<Id,pse__Project_Task__c> mapWorkOrderProjectTask = new Map<Id,pse__Project_Task__c>();
            //List of service appointment
            List<WorkOrder> listWorkOrderToUpdate = new List<WorkOrder>();
            //getting all work order associated with projectTask and storing the workorder id and project task record
            for ( WorkOrder oWorkOrder : [
                        SELECT
                            Id , NSP_Project_Task__c , ServiceTerritoryId ,
                            NSP_Orientation_Address__c , Subject ,
                            Description , OwnerId , Status , Duration ,
                            StartDate , EndDate , NSP_Meeting_Type__c
                        FROM WorkOrder
                        WHERE ( NSP_Project_Task__c= :mapProjectTasks.keySet() )
                    ]
                )
            {
                // STY-03891
                pse__Project_Task__c workOrderProjectTask = mapProjectTasks.get( oWorkOrder.NSP_Project_Task__c );
                if ( workOrderProjectTask != null ) {
                    WorkOrder record = updateWorkOrderRecord(
                        oWorkOrder.Id ,
                        workOrderProjectTask
                    );
                    if ( record != null ) {
                        if ( String.isNotBlank( workOrderProjectTask.NSP_Dispatch_Region__c ) ) {
                            record.ServiceTerritoryId = mapDispatchRegionToServiceTerritory.get(
                                workOrderProjectTask.NSP_Dispatch_Region__c
                            );
                        }
                        mapWorkOrderProjectTask.put(
                            oWorkOrder.Id ,
                            workOrderProjectTask
                        );
                        listWorkOrderToUpdate.add( record );
                    }
                }
            }
            //List of service appointment
            List<ServiceAppointment> listServiceAppointments = new List<ServiceAppointment>();
            //now updating oreientation address on service appointment to projectTask orientation address
            for ( ServiceAppointment oService : [
                        SELECT
                            Id , FSL__GanttLabel__c , Duration , SchedStartTime , SchedEndTime ,
                            NSP_Orientation_Address__c , Description , Status , EarliestStartTime ,
                            ServiceTerritoryId , NSP_Meeting_Type__c , ParentRecordId
                        FROM ServiceAppointment
                        WHERE ( ParentRecordId = :mapWorkOrderProjectTask.keySet() )
                    ]
                )
            {
                // STY-03817 ~ Assigning Service Territory on SA
                pse__Project_Task__c workOrderProjectTask = mapWorkOrderProjectTask.get( oService.ParentRecordId );
                if ( workOrderProjectTask != null ) {
                    ServiceAppointment record = updateServiceAppointmentRecord(
                        oService.Id ,
                        oService.Status ,
                        workOrderProjectTask
                    );
                    if ( record != null ) {
                        if ( String.isNotBlank( workOrderProjectTask.NSP_Dispatch_Region__c ) ) {
                            record.ServiceTerritoryId = mapDispatchRegionToServiceTerritory.get(
                                workOrderProjectTask.NSP_Dispatch_Region__c
                            );
                        }
                        listServiceAppointments.add( record );
                    }
                }
            }
            if ( !listWorkOrderToUpdate.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( listWorkOrderToUpdate , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ProjectTasksTriggerServiceHelper.class.getName() ,
                    'updateServiceAppointment:update:WorkOrder' ,
                    results
                );
            }
            if ( !listServiceAppointments.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( listServiceAppointments , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ProjectTasksTriggerServiceHelper.class.getName() ,
                    'updateServiceAppointment:update:ServiceAppointment' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTasksTriggerServiceHelper.class.getName() ,
                'updateServiceAppointment' ,
                e
            );
        }
    }

    //
    // MethodName: updateWorkOrderRecord
    // Description : Update the respective workorder record and return it
    // Params: Id workOrderId, pse__Project_Task__c mapProjectTask
    //
    public static WorkOrder updateWorkOrderRecord( Id workOrderId , pse__Project_Task__c mapProjectTask ) {
        //Update the respective workorder based on the project task record entries
        WorkOrder woOrderRecToUpdate = new WorkOrder();
        woOrderRecToUpdate.Id = workOrderId;
        woOrderRecToUpdate.NSP_Orientation_Address__c = mapProjectTask.NSP_Orientation_Address__c;
        woOrderRecToUpdate.NSP_Meeting_Type__c =  mapProjectTask.NSP_Meeting_Type__c;
        woOrderRecToUpdate.Subject = mapProjectTask.Name;
        woOrderRecToUpdate.OwnerId = mapProjectTask.OwnerId;
        woOrderRecToUpdate.Description = mapProjectTask.pse__Long_Description__c;
        woOrderRecToUpdate.Status = mapProjectTask.pse__Status__c;
        woOrderRecToUpdate.Duration = (
            ( ( mapProjectTask.pse__End_Date_Time__c != null ) && ( mapProjectTask.pse__Start_Date_Time__c != null ) )
            ? ( Integer.valueOf( ( mapProjectTask.pse__End_Date_Time__c.getTime() - mapProjectTask.pse__Start_Date_Time__c.getTime() ) / ( 1000 * 60 ) ) )
            : null
        );
        woOrderRecToUpdate.DurationType = 'Minutes';
        woOrderRecToUpdate.StartDate = mapProjectTask.pse__Start_Date_Time__c;
        woOrderRecToUpdate.EndDate = mapProjectTask.pse__End_Date_Time__c;
        return woOrderRecToUpdate;
    }

    //
    // MethodName: updateServiceAppointmentRecord
    // Description : Update the respective service appointment and return it
    // Params: Id serviceAppointmentId
    // Params: pse__Project_Task__c mapWorkOrderProjectTask
    //
    private static ServiceAppointment updateServiceAppointmentRecord( Id serviceAppointmentId , String serviceAppointmentStatus , pse__Project_Task__c mapWorkOrderProjectTask ) {
        //Update the respective service appointment based on the project task record entries
        ServiceAppointment serviceAppointmentRecToUpdate = new ServiceAppointment();
        serviceAppointmentRecToUpdate.Id = serviceAppointmentId;
        serviceAppointmentRecToUpdate.NSP_Orientation_Address__c = mapWorkOrderProjectTask.NSP_Orientation_Address__c;
        serviceAppointmentRecToUpdate.NSP_Meeting_Type__c =  mapWorkOrderProjectTask.NSP_Meeting_Type__c;
        serviceAppointmentRecToUpdate.OwnerId = mapWorkOrderProjectTask.OwnerId;
        serviceAppointmentRecToUpdate.Description = mapWorkOrderProjectTask.pse__Long_Description__c;
        serviceAppointmentRecToUpdate.Subject = mapWorkOrderProjectTask.Name;
        serviceAppointmentRecToUpdate.NSP_Project_Attendance__c = mapWorkOrderProjectTask.NSP_Project_Attendance__c;
        // prevent DmlException ~ FIELD_CUSTOM_VALIDATION_EXCEPTION, Cannot change status from *** to null: [Status]
        if ( String.isNotBlank( serviceAppointmentStatus )
            && String.isNotBlank( mapWorkOrderProjectTask.pse__Status__c )
            && NSP_ProjectTasksTriggerServiceHelper.allowedStatusTransitions.containsKey( serviceAppointmentStatus )
            && NSP_ProjectTasksTriggerServiceHelper.allowedStatusTransitions.get( serviceAppointmentStatus ).contains( mapWorkOrderProjectTask.pse__Status__c )
            )
        {
            serviceAppointmentRecToUpdate.Status = mapWorkOrderProjectTask.pse__Status__c;
        }

        serviceAppointmentRecToUpdate.Duration = (
            ( ( mapWorkOrderProjectTask.pse__End_Date_Time__c != null ) && ( mapWorkOrderProjectTask.pse__Start_Date_Time__c != null ) )
            ? Integer.valueOf( ( mapWorkOrderProjectTask.pse__End_Date_Time__c.getTime() - mapWorkOrderProjectTask.pse__Start_Date_Time__c.getTime() ) / ( 1000 * 60 ) )
            : null
        );
        serviceAppointmentRecToUpdate.DurationType = 'Minutes';
        serviceAppointmentRecToUpdate.SchedStartTime = mapWorkOrderProjectTask.pse__Start_Date_Time__c;
        serviceAppointmentRecToUpdate.SchedEndTime = mapWorkOrderProjectTask.pse__End_Date_Time__c;
        return serviceAppointmentRecToUpdate;
    }

    // Using a Map containing Sets instead of a List to prevent duplicates and enable faster lookups
    private static Map<String,Set<String>> allowedStatusTransitions {
        private get {
            if ( allowedStatusTransitions == null ) {
                Map<String,Set<String>> local = new Map<String,Set<String>>();
                for( FSL.StatusTransition transition : FSL.GlobalAPIS.GetAllStatusTransitions() ) {
                    if ( String.isNotBlank( transition.FromStatus )
                        && String.isNotBlank( transition.ToStatus )
                        )
                    {
                        // If the 'FromStatus' dosen't exist in our map yet, initialize its Set
                        if ( !local.containsKey( transition.FromStatus ) ) {
                            local.put(
                                transition.FromStatus ,
                                new Set<String>()
                            );
                        }
                        // Add the 'ToStatus' value to the corresponding Set
                        local.get( transition.FromStatus ).add( transition.ToStatus );
                    }
                }
                allowedStatusTransitions = local;
            }
            return allowedStatusTransitions;
        }
        private set;
    }

    //
    // This will create the new PTA on Project with updated Owner
    // Project Task is changed and Auto Resource on Project is checked.
    // @param listOfProjectTask List of updated Project Task.
    //
    public static void createPTAOnProject( Set<Id> pTaskOwnerIdSet , Set<Id> setProjectId , Set<Id> setProjectTaskId ) {

        Map<Id, Id> mapOfContactIdvsUserId = new Map<Id, Id> ();
        Map<Id, Id> mapOfUserIdvsContactId = new Map<Id, Id> ();
        Set<Id> projectIdSet = new Set<Id> ();
        Map<Id,pse__Proj__c> projMap = new  Map<Id,pse__Proj__c>();
        List<pse__Project_Task_Assignment__c> listOfPTA = new List<pse__Project_Task_Assignment__c> ();
        // PEO project Task

        // Creating map of Project Id and checking if Auto Resource checkbox is true/false. If false adding in map.
        if(!setProjectTaskId.isEmpty()){
            for(pse__Proj__c proj : [SELECT Id,NSP_Auto_Resource_Project__c FROM pse__Proj__c WHERE ID IN : setProjectId AND NSP_Auto_Resource_Project__c =: NSP_ServiceConstants.VALUE_TRUE]){
                projectIdSet.add(proj.id);
                projMap.put(proj.Id,proj);
            }
        }
        // Creating map of Contact Salesforce User and Contact Id
        for(Contact cont : [SELECT Id,pse__Salesforce_User__c FROM Contact WHERE pse__Salesforce_User__c IN : pTaskOwnerIdSet]){
            mapOfContactIdvsUserId.put(cont.Id,cont.pse__Salesforce_User__c);
            mapOfUserIdvsContactId.put(cont.pse__Salesforce_User__c,cont.Id);
        }
        Map<Id,Id> mapTaskIdContactId = new Map<Id,Id>();
        for ( pse__Project_Task_Assignment__c pta : [
                    SELECT pse__Resource__c , pse__Project_Task__c , pse__Project_Task__r.pse__Project__c
                    FROM pse__Project_Task_Assignment__c
                    WHERE ( pse__Project_Task__c IN :setProjectTaskId )
                ]
            )
        {
            if ( projectIdSet.contains( pta.pse__Project_Task__r.pse__Project__c )
                && mapOfContactIdvsUserId.containsKey( pta.pse__Resource__c )
                )
            {
                mapOfContactIdvsUserId.remove( pta.pse__Resource__c );
                mapTaskIdContactId.put( pta.pse__Project_Task__c , pta.pse__Resource__c );
            }
        }
        if(!mapOfContactIdvsUserId.isEmpty()){
            for(pse__Project_Task__c projObj : [SELECT Id,OwnerId ,pse__Project__c FROM pse__Project_Task__c WHERE Id IN:setProjectTaskId AND pse__Project__c != null
                                                AND  pse__Project__r.NSP_Auto_Resource_Project__c =: NSP_ServiceConstants.VALUE_TRUE]){
                if(projectIdSet.contains(projObj.pse__Project__c) && !mapTaskIdContactId.containsKey(projObj.Id)){
                    Id contactId = mapOfUserIdvsContactId.get(projObj.OwnerId);
                    if(mapOfContactIdvsUserId.containsKey(contactId)){
                        pse__Project_Task_Assignment__c ptanew = new pse__Project_Task_Assignment__c();
                        ptanew.pse__Project_Task__c = projObj.Id;
                        ptanew.pse__Resource__c = contactId;
                        ptanew.NSP_Is_Account_Team__c = true;
                        listOfPTA.add(ptanew);
                    }
                }
            }
        }
        if ( !listofPTA.isEmpty() ) {
            Database.SaveResult[] results = Database.insert( listofPTA , false );
            NSP_ErrorLogHandler.logResults(
                NSP_ProjectTasksTriggerServiceHelper.class.getName() ,
                'createPTAOnProject' ,
                results
            );
        }
    }

    //
    // Iterates throught the list of new pse__Project_Task__c and passes the required attributes to other methods.
    // @param listOfProjectTask Map of New Project Tasks
    // Description: This method update assign the recordType to Project Task based on Project RecordType
    // @return void
    //
    //
    public void updateRecordType( List<pse__Project_Task__c> listOfProjectTask ) {
        Set<Id> projectIds = new Set<Id>();
        List<pse__Project_Task__c> projectTasksList = new List<pse__Project_Task__c>();
        //Iterating through the new list of project tasks records which are being inserted and collect the parent Project Ids in a set.
        for ( pse__Project_Task__c eachTask : listOfProjectTask ) {
            if ( eachTask.pse__Project__c != null ) {
                projectIds.add( eachTask.pse__Project__c );
                projectTasksList.add( eachTask );
            }
        }
        //Collect the parent projects record type name to match with the newly created tasks record type.
        if ( !projectIds.isEmpty() ) {
            Map<Id,String> recordTypeMap = new Map<Id,String>();
            for ( pse__Proj__c eachProject : [
                        SELECT Id , RecordType.Name
                        FROM pse__Proj__c
                        WHERE (
                            ( Id IN :projectIds )
                            AND ( RecordType.Name != null )
                        )
                    ]
                )
            {
                recordTypeMap.put(eachProject.Id,eachProject.RecordType.Name);
            }
            //Calling the method to assign the parent project record type to project tasks.
            assignRecordTypeId( recordTypeMap , projectTasksList );
        }
    }

    //
    // Description: This method update assign the recordType to Project Task based on Project RecordType
    // @param  recordTypeMap Map of <Id,String> Project recordId & project RecordType Name
    // @param projectTasksList List of new pse__Project_Task__c record
    // @return void
    //
    //
    public void assignRecordTypeId( Map<Id,String> recordTypeMap , List<pse__Project_Task__c> projectTasksList ) {
        if ( !recordTypeMap.isEmpty() ) {
            //Collect the project tasks record type Id for assignment.
            Id recordTypeIdBPS = NSP_GenericRecordType.getRecordTypeId( 'pse__Project_Task__c' , 'BPS_Project_Task' );
            Id recordTypeIdPEO = NSP_GenericRecordType.getRecordTypeId( 'pse__Project_Task__c'  , 'PEO_Project_Task' );
            Id recordTypeIdRET = NSP_GenericRecordType.getRecordTypeId( 'pse__Project_Task__c'  , 'RET_Project_Task' );
            //Iterate through the newly inserted project tasks and assign the parent record type to tasks.
            for ( pse__Project_Task__c eachTask : projectTasksList ) {
                //Record type assignment from project to tasks.
                if ( recordTypeMap.get(eachTask.pse__Project__c)?.indexOfIgnoreCase((NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE).substring(0,3)) != -1
                    && recordTypeIdPEO != null
                    )
                {
                    eachTask.RecordTypeId = recordTypeIdPEO;
                } else if ( recordTypeMap.get(eachTask.pse__Project__c)?.indexOfIgnoreCase((NSP_ServiceConstants.PROJECT_TASK_BPS_RECORDTYPE).substring(0,3)) != -1
                    && recordTypeIdBPS != null
                    )
                {
                    eachTask.RecordTypeId = recordTypeIdBPS;
                } else if ( recordTypeMap.get(eachTask.pse__Project__c)?.indexOfIgnoreCase((NSP_ServiceConstants.PROJECT_TASK_RET_RECORDTYPE).substring(0,3)) != -1
                    && recordTypeIdRET != null
                    )
                {
                    eachTask.RecordTypeId = recordTypeIdRET;
                }
            }
        }
    }

    //
    // Description: Filter record for other functions
    // @return void
    //
    public void afterInsertFilter( List<pse__Project_Task__c> listProjectTasks , Map<Id,pse__Project_Task__c> mapProjectTasks ) {

        // STY-02085  checking for checkBox(Create Work Order) on projectTask Object is checked and Disptach region field is set
        Set<Id> projectTasksWithNoAssignments = new Set<Id>();
        Map<Id,pse__Project_Task__c> mapOfProjectTaskIdAndProjecTask = new Map<Id,pse__Project_Task__c>();
        Set<Id> newprojTaskIdSet = new Set<Id>();
        Set<Id> setProjectTasksForAutoResource = new Set<Id>();
        Set<Id> projectIdSet = new Set<Id>();
        Map<Id,Id> accountIdProjectIdMap = new Map<Id,Id>();

        for(pse__Project_Task__c pTask : listProjectTasks){
            if(pTask.NSP_Create_Work_Order__c == true && String.isNotBlank(pTask.NSP_Dispatch_Region__c)){
                mapOfProjectTaskIdAndProjecTask.put(pTask.Id, pTask);
            }
            if(pTask.pse__Number_of_Assignments__c == 0 && pTask.OwnerId.getsobjectType() == User.sobjectType
                && pTask.Name != NSP_ServiceConstants.STAY_STRONG_TP_BASED_ON_UNFAVOURABLE_RATING && !pTask.NSP_isClonedFromAutomation__c){
                projectTasksWithNoAssignments.add(pTask.Id);
            }
             if(pTask.pse__Project__c != null && pTask.NSP_Visible_to_Client__c == true ){
             newprojTaskIdSet.add(pTask.Id);
            }
            if(pTask.OwnerId.getsobjectType() == User.sobjectType && String.isBlank(pTask.NSP_Implementation_Account_Id__c)
                && pTask.Name != NSP_ServiceConstants.STAY_STRONG_TP_BASED_ON_UNFAVOURABLE_RATING && !pTask.NSP_isClonedFromAutomation__c){
                setProjectTasksForAutoResource.add(pTask.Id);
            }
            //Added as part of defect DF-03341
            if(pTask.pse__Project__c != null && pTask.NSP_Account_Id__c != null ){
                projectIdSet.add(pTask.pse__Project__c);
                accountIdProjectIdMap.put(pTask.NSP_Account_Id__c,pTask.pse__Project__c);
            }
        }
        //creating a workOrder Record
        if(mapOfProjectTaskIdAndProjecTask.keySet().size() > 0){
            createWorkOrderTask(mapOfProjectTaskIdAndProjecTask);
        }
        if(!projectTasksWithNoAssignments.isEmpty()){
            Map<String, Object> mapInputParams = new Map<String, Object>{'projectTaskIds' => projectTasksWithNoAssignments};
            List<NSP_ProjectTaskQueueEvent__e> lstTaskQueueEvent = new List<NSP_ProjectTaskQueueEvent__e>();
            lstTaskQueueEvent.add(new NSP_ProjectTaskQueueEvent__e(NSP_Input_Parameters__c = JSON.serialize(mapInputParams), NSP_MethodName__c = 'updateProjectTaskOwner', NSP_UserId__c = UserInfo.getUserId()));
            List<Database.SaveResult> results = EventBus.publish( lstTaskQueueEvent );
            NSP_ErrorLogHandler.logResults(
                NSP_ProjectTasksTriggerServiceHelper.class.getName() ,
                'afterInsertFilter:publish' ,
                results
            );
        }
        //Added as part of STY-04100
        if(!newprojTaskIdSet.isEmpty()){
            NSP_ProjectTaskSharing.projectTaskRecordSharing(newprojTaskIdSet, null);
        }
        if ( !setProjectTasksForAutoResource.isEmpty() && NSP_ProjectTasksTriggerServiceHelper.runOwnerAssignmentLogic ) {
            Map<String, Object> mapInputParams = new Map<String, Object>{'projectTaskIds' => setProjectTasksForAutoResource};
            List<NSP_ProjectTaskQueueEvent__e> lstTaskQueueEvent = new List<NSP_ProjectTaskQueueEvent__e>();
            lstTaskQueueEvent.add(new NSP_ProjectTaskQueueEvent__e(NSP_Input_Parameters__c = JSON.serialize(mapInputParams), NSP_MethodName__c = 'updateProjectTaskOwnerForAutoResource', NSP_UserId__c = UserInfo.getUserId()));
            List<Database.SaveResult> results = EventBus.publish( lstTaskQueueEvent );
            NSP_ErrorLogHandler.logResults(
                NSP_ProjectTasksTriggerServiceHelper.class.getName() ,
                'afterInsertFilter:publish:auto' ,
                results
            );
        }
         //creating a project account record
        if(!projectIdSet.isEmpty() && !accountIdProjectIdMap.isEmpty()){
            createProjectAccount(listProjectTasks,projectIdSet,accountIdProjectIdMap);
        }
    }

    //
    // Create this method based on STY-02085
    // Description: If the checkBox(Create Work Order) on projectTask Object is checked and Disptach region field is set then work order record is created and also Service appointment
    // @param map of Project Tasks Id and ProjectTask
    // @return void
    //
    public void createWorkOrderTask( Map<Id,pse__Project_Task__c> mapProjectTasks ) {
    pse__Project_Task__c oMapProjectTask;
    Map<Id, ServiceAppointment> mapProjectTaskIdSA = new Map<Id, ServiceAppointment>();
    Map<Id, pse__Project_Task__c> mapWorkOrderProjectTask = new Map<Id, pse__Project_Task__c>();
    List<ServiceAppointment> listServiceAppointments = new List<ServiceAppointment>();
    Map<String,Id> mapDispatchRegionToServiceTerritory = new Map<String,Id>();
    List<String> dispatchRegionList = new List<String>();

    //getting WorkType record with Name as 'Generic'
    List<WorkType> listWorkTypes = [SELECT Id, ShouldAutoCreateSvcAppt FROM WorkType WHERE Name=:'Generic' LIMIT 1];
    if(listWorkTypes.size() == 0){
        return;
    }
    //Checking whether Automatic create Service appointment checkbox is checked in WorkType
    if(listWorkTypes[0].ShouldAutoCreateSvcAppt != true){
        listWorkTypes[0].ShouldAutoCreateSvcAppt = true;
        UPDATE listWorkTypes[0];
    }

    //assigning all the values from ProjectTask to WorkOrder ---STY-02085
    List<WorkOrder> listWorkOrders = new List<WorkOrder>();
    for(pse__Project_Task__c oProjectTask :
        [SELECT Id, Name, pse__Long_Description__c,NSP_Orientation_Address__c, NSP_AccountId__c ,pse__End_Date_Time__c,pse__Start_Date_Time__c,NSP_Dispatch_Region__c,NSP_Meeting_Type__c
         FROM pse__Project_Task__c WHERE Id =: mapProjectTasks.keySet()]){
             listWorkOrders.add( new WorkOrder(
                 WorkTypeId = listWorkTypes[0].Id,
                 Subject = oProjectTask.Name,
                 Description = oProjectTask.pse__Long_Description__c,
                 NSP_Project_Task__c = oProjectTask.Id,
                 AccountId = oProjectTask.NSP_AccountId__c,
                 StartDate = oProjectTask.pse__Start_Date_Time__c,
                 EndDate = oProjectTask.pse__End_Date_Time__c,
                 Duration =  ((oProjectTask.pse__End_Date_Time__c != null && oProjectTask.pse__Start_Date_Time__c!= null)? (Integer.valueOf((oProjectTask.pse__End_Date_Time__c.getTime() - oProjectTask.pse__Start_Date_Time__c.getTime())/(1000*60))):null),
                 DurationType = 'Minutes',
                 NSP_Meeting_Type__c = oProjectTask.NSP_Meeting_Type__c,
                 NSP_Orientation_Address__c = oProjectTask.NSP_Orientation_Address__c,
                 Status = 'Unscheduled'
             ));

             //STY-03817
             //Storing list of dispactch regioon
             if( oProjectTask.NSP_Dispatch_Region__c != null){
                 dispatchRegionList.add(oProjectTask.NSP_Dispatch_Region__c);
             }
         }
    //STY-03817
    //Getting service territory recs Id from List of regions
    if(!dispatchRegionList.isEmpty()){
    for(ServiceTerritory eachServiceTerritory : [SELECT Id,Name FROM ServiceTerritory WHERE Name IN: dispatchRegionList]){
        mapDispatchRegionToServiceTerritory.put(eachServiceTerritory.Name, eachServiceTerritory.Id);
    }
    }

        try {
    if(!listWorkOrders.isEmpty()){
        //Inserting list of WorkOrder record
        Database.insert(listWorkOrders);
        for(WorkOrder oWorkOrder : listWorkOrders){
            mapWorkOrderProjectTask.put(oWorkOrder.Id, mapProjectTasks.get(oWorkOrder.NSP_Project_Task__c));
        }
        // When we create WorkOrder record it automatically create Service Appointment (because Auto_create_Service_Appointment checkbox is checked on WorkType) with auto-populated values
        for(ServiceAppointment oService : [SELECT Id,FSL__GanttLabel__c, Duration,
                                           NSP_Orientation_Address__c, Description, Status, EarliestStartTime,NSP_Meeting_Type__c,
                                           ParentRecordId
                                           FROM ServiceAppointment
                                           WHERE ParentRecordId =: mapWorkOrderProjectTask.keySet()]){
                                               mapProjectTaskIdSA.put(oService.ParentRecordId, oService);
                                           }
        //Assigning the field values of Service Appointment as ProjectTask-- STY-02085
        for(ServiceAppointment oService: [SELECT Id,FSL__GanttLabel__c, Duration,
                                          NSP_Orientation_Address__c, Description, Status, EarliestStartTime,SchedEndTime,SchedStartTime,ParentRecordId ,ActualEndTime,ActualStartTime,NSP_Project_Attendance__c
                                          FROM ServiceAppointment
                                          WHERE ParentRecordId =: mapProjectTaskIdSA.keySet()]){
                                              oMapProjectTask = mapWorkOrderProjectTask.get(oService.ParentRecordId);
                                              oService.FSL__GanttLabel__c = oMapProjectTask.Name;
                                              oService.Duration = ((oMapProjectTask.pse__End_Date_Time__c != null && oMapProjectTask.pse__Start_Date_Time__c!= null)? (Integer.valueOf((oMapProjectTask.pse__End_Date_Time__c.getTime() - oMapProjectTask.pse__Start_Date_Time__c.getTime())/(1000*60))):null);
                                              oService.Description = oMapProjectTask.pse__Long_Description__c;
                                              oService.Status = 'Unscheduled';
                                              oService.SchedStartTime =  oMapProjectTask.pse__Start_Date_Time__c;
                                              oService.SchedEndTime =  oMapProjectTask.pse__End_Date_Time__c;
                                              oService.NSP_Meeting_Type__c = oMapProjectTask.NSP_Meeting_Type__c;
                                              oService.NSP_Orientation_Address__c = oMapProjectTask.NSP_Orientation_Address__c;
                                              oService.NSP_Project_Attendance__c = oMapProjectTask.NSP_Project_Attendance__c;
                                              oService.DurationType = 'Minutes';
                                              //STY-03817
                                              //Assigning Service Territory on SA
                                              if( oMapProjectTask.NSP_Dispatch_Region__c != null){
                                                  oService.ServiceTerritoryId = mapDispatchRegionToServiceTerritory.get(oMapProjectTask.NSP_Dispatch_Region__c);
                                              }

                                              listServiceAppointments.add(oService);
                                          }
        //updating service appointment
        if(!listServiceAppointments.isEmpty()){
            Database.update(listServiceAppointments);
        }
    }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTasksTriggerServiceHelper.class.getName() ,
                'createWorkOrderTask' ,
                e
            );
        }
    }

    //
    // MethodName:  emailAlertProjectTaskCompleted
    // Description :RET project template's tasks completion email alert
    // Story : STY-02214
    // Author :Abhishek Kumar
    // Params: Map<Id,pse__Project_Task__c> newMapProjecttasks
    // Params: Map<Id,pse__Project_Task__c> oldMapProjecttasks
    //
    public static void emailAlertProjectTaskCompleted( Map<Id,pse__Project_Task__c> newMapProjecttasks , Map<Id,pse__Project_Task__c> oldMapProjecttasks ) {
        List<pse__Project_Task__c> prepareAmendmentTasks = new List<pse__Project_Task__c>();
        List<pse__Project_Task__c> submitCoversheetTasks = new List<pse__Project_Task__c>();
        List<pse__Project_Task__c> verifyAllInfoTasks = new List<pse__Project_Task__c>();
        List<pse__Project_Task__c> collectSignedAmendTasks = new List<pse__Project_Task__c>();
        List<pse__Project_Task__c> collectDocumentTasks = new List<pse__Project_Task__c>();
        List<pse__Project_Task__c> submitEaPackageTasks = new List<pse__Project_Task__c>();
        List<pse__Project_Task__c> validationOfPpttInstallTasks = new List<pse__Project_Task__c>();
        List<pse__Project_Task__c> validationOfPpttStartupTasks = new List<pse__Project_Task__c>();

        try {
            //iterate over each project task updated
            for(pse__Project_Task__c projectTask : newMapProjecttasks.values()){
                //check if project task status is updated to complete
                if(oldMapProjecttasks.get(projectTask.Id).pse__Status__c!=NSP_ServiceConstants.TASKCOMPLETE
                   && projectTask.pse__Status__c==NSP_ServiceConstants.TASKCOMPLETE){

                       //check project task and template name
                       //check if project task is on 'RET Plan Amendment 2020 Form'
                       if(projectTask.Name == NSP_ServiceConstants.PREPARE_AMENDMENT && projectTask.Template_Name__c == NSP_ServiceConstants.PLAN_AMENDMENT_TEMPLATE){
                           prepareAmendmentTasks.add(projectTask);
                        }
                       //check if project task is on 'RET Safe Harbor Retractions 2020 Form'
                       else if(projectTask.Name== NSP_ServiceConstants.SUBMIT_COVERSHEET  && projectTask.Template_Name__c== NSP_ServiceConstants.SAFE_HARBOUR_TEMPLATE){
                           submitCoversheetTasks.add(projectTask);
                       }
                       //check if project task is on 'RET Deconversion 2020'
                       else if(projectTask.Name== NSP_ServiceConstants.VERIFY_ALL_INFO && projectTask.Template_Name__c== NSP_ServiceConstants.DECONVERSION_TEMPLATE){
                           verifyAllInfoTasks.add(projectTask);
                       }
                       //check if project task is on 'RET Prototype Amendment'
                       else if(projectTask.Name== NSP_ServiceConstants.COLLECT_SIGNED && projectTask.Template_Name__c== NSP_ServiceConstants.PROTOTYPE_AMENDMENT_TEMPLATE){
                           collectSignedAmendTasks.add(projectTask);
                       }
                       //check if project task is on 'RET Sales to NSP 401k'
                       else if(projectTask.Name== NSP_ServiceConstants.COLLECT_DOCUMENT && projectTask.Template_Name__c== NSP_ServiceConstants.SALES_NSP401K_TEMPLATE){
                           collectDocumentTasks.add(projectTask);
                       }
                       //check if project task is on 'RET Sales to NSP 401k'
                       else if(projectTask.Name== NSP_ServiceConstants.SUBMIT_EA_PACKAGE && projectTask.Template_Name__c==NSP_ServiceConstants.SALES_NSP401K_TEMPLATE){
                           submitEaPackageTasks.add(projectTask);
                       }
                       //check if project task is on 'NSPK Install for Conversion Form'
                       else if(projectTask.Name== NSP_ServiceConstants.VALIDATION_PPTT_INSTALL && projectTask.Template_Name__c== NSP_ServiceConstants.NSPK_INSTALL_TEMPLATE){
                           validationOfPpttInstallTasks.add(projectTask);
                       }
                       //check if project task is on 'RET Startup Set Up'
                       else if(projectTask.Name== NSP_ServiceConstants.VALIDATION_PPTT_STARTUP && projectTask.Template_Name__c== NSP_ServiceConstants.STARTUP_SETUP_TEMPLATE){
                           validationOfPpttStartupTasks.add(projectTask);
                       }
                   }
            }
            //get email addresses stored in Retirement metadata
            NSP_Retirement_Services__mdt ret401kasfplanemail = NSP_Retirement_Services__mdt.getInstance( NSP_ServiceConstants.RET_401KASFPLAN );
            NSP_Retirement_Services__mdt ret401kcompliance = NSP_Retirement_Services__mdt.getInstance( NSP_ServiceConstants.RET_401KCOMPLIANCE );
            NSP_Retirement_Services__mdt retKWRSBusinessSolutions = NSP_Retirement_Services__mdt.getInstance( NSP_ServiceConstants.RET_KWRSBUISNESS );
            NSP_Retirement_Services__mdt retVirginiaBarnes = NSP_Retirement_Services__mdt.getInstance( NSP_ServiceConstants.RET_VIRGINIA_BARNES );

            //call email alert function for prepareAmendmentTasks
            if ( !prepareAmendmentTasks.isEmpty() ) {
                NSP_ProjectTaskTriggerEmailNotification.emailNotifyforTasksOnRetProjectType(
                    prepareAmendmentTasks ,
                    'NSP_PrepareAmendmentAlertTemplate' ,
                    new List<String>{ ret401kasfplanemail.NSP_Email_Address__c }
                );
            }
            //call email alert function for submitCoversheetTasks
            if ( !submitCoversheetTasks.isEmpty() ) {
                NSP_ProjectTaskTriggerEmailNotification.emailNotifyforTasksOnRetProjectType(
                    submitCoversheetTasks ,
                    'NSP_SubmitCoversheetTemplateAlert' ,
                    new List<String>{ ret401kasfplanemail.NSP_Email_Address__c }
                );
            }
            //call email alert function for verifyAllInfoTasks
            if ( !verifyAllInfoTasks.isEmpty() ) {
                NSP_ProjectTaskTriggerEmailNotification.emailNotifyforTasksOnRetProjectType(
                    verifyAllInfoTasks ,
                    'NSP_VerifyAllInfoTemplateAlert' ,
                    new List<String>{ ret401kasfplanemail.NSP_Email_Address__c }
                );
            }
            //call email alert function for collectSignedAmendTasks
            if ( !collectSignedAmendTasks.isEmpty() ) {
                NSP_ProjectTaskTriggerEmailNotification.emailNotifyforTasksOnRetProjectType(
                    collectSignedAmendTasks ,
                    'NSP_CollectSignedAmendTemplate' ,
                    new List<String>{
                        ret401kasfplanemail.NSP_Email_Address__c ,
                        ret401kcompliance.NSP_Email_Address__c ,
                        retKWRSBusinessSolutions.NSP_Email_Address__c
                    }
                );
            }
            //call email alert function for collectDocumentTasks
            if ( !collectDocumentTasks.isEmpty() ) {
                NSP_ProjectTaskTriggerEmailNotification.emailNotifyforTasksOnRetProjectType(
                    collectDocumentTasks ,
                    'NSP_CollectAllDocsTemplate' ,
                    new List<String>{ ret401kcompliance.NSP_Email_Address__c }
                );
            }
            //call email alert function for submitEaPackageTasks
            if ( !submitEaPackageTasks.isEmpty() ) {
                NSP_ProjectTaskTriggerEmailNotification.emailNotifyforTasksOnRetProjectType(
                    submitEaPackageTasks ,
                    'NSP_SubmitEaPackTemplate' ,
                    new List<String>{ ret401kcompliance.NSP_Email_Address__c }
                );
            }
            //call email alert function for validationOfPpttInstallTasks
            if ( !validationOfPpttInstallTasks.isEmpty() ) {
                NSP_ProjectTaskTriggerEmailNotification.emailNotifyforTasksOnRetProjectType(
                    validationOfPpttInstallTasks ,
                    'NSP_ValidationOfPpttTemplate' ,
                    new List<String>{ retVirginiaBarnes.NSP_Email_Address__c }
                );
            }
            //call email alert function for validationOfPpttStartupTasks
            if ( !validationOfPpttStartupTasks.isEmpty() ) {
                NSP_ProjectTaskTriggerEmailNotification.emailNotifyforTasksOnRetProjectType(
                    validationOfPpttStartupTasks ,
                    'NSP_RET_ValidationOfPpttTemplate' ,
                    new List<String>{ retVirginiaBarnes.NSP_Email_Address__c }
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTasksTriggerServiceHelper.class.getName() ,
                'emailAlertProjectTaskCompleted' ,
                e
            );
        }
    }

    //
    // MethodName: updatePorjectTaskAccount
    // Description : Populate the Account on Project Task on creation
    // Params: List<pse__Project_Task__c> prjTaskList
    //
    public static void updateProjectTaskAccount( List<pse__Project_Task__c> prjTaskList , Set<Id> projectId ) {
        try {
            Map<Id,Id> projectIdAccountIdMap = new Map<Id,Id>();
            if ( !projectId.isEmpty() ) {
                for( pse__Proj__c prj : [
                            SELECT Id , pse__Account__c
                            FROM pse__Proj__c
                            WHERE (
                                ( Id IN :projectId )
                                AND ( pse__Account__c != null )
                            )
                        ]
                    )
                {
                    projectIdAccountIdMap.put( prj.Id , prj.pse__Account__c );
                }
                for ( pse__Project_Task__c prjTsk : prjTaskList ) {
                    if ( projectIdAccountIdMap.containsKey( prjTsk.pse__Project__c ) ) {
                        prjTsk.NSP_Account_Id__c = projectIdAccountIdMap.get( prjTsk.pse__Project__c );
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTasksTriggerServiceHelper.class.getName() ,
                'updateProjectTaskAccount' ,
                e
            );
        }
    }

    //
    // MethodName: updatePorjectTaskAccount
    // Description : Populate the Account on Project Task on creation
    // Params: List<pse__Project_Task__c> prjTaskList
    //
    public static void createProjectAccount( List<pse__Project_Task__c> prjTaskList , Set<Id> projectIdSet , Map<Id,Id> accountIdProjectIdMap ) {
        try {
            Map<Id,Id> projectIdAccountIdMap = new Map<Id,Id>();
            Map<Id,List<Id>> prjIdSetAccountIdMap = new Map<Id,List<Id>>();
            List<Project_Account__c> projAccountList = new List<Project_Account__c>();
            if(!projectIdSet.isEmpty()){
                for(Project_Account__c prjAccount : [SELECT Id , Project__c, Account__c FROM Project_Account__c WHERE Project__c IN: projectIdSet ]){
                    if(!prjIdSetAccountIdMap.containsKey(prjAccount.Project__c)){
                        prjIdSetAccountIdMap.put(prjAccount.Project__c, new List<Id>());
                    }
                    prjIdSetAccountIdMap.get(prjAccount.Project__c).add(prjAccount.Account__c);
                }

                for(pse__Proj__c prj :[SELECT Id , pse__Account__c From pse__Proj__c WHERE Id IN:projectIdSet AND pse__Account__c!=null]){
                    projectIdAccountIdMap.put(prj.Id,prj.pse__Account__c);
                }
                // insert project tasks
                for(pse__Project_Task__c prjTsk:prjTaskList){
                    if(projectIdAccountIdMap.containsKey(prjTsk.pse__Project__c) &&
                       projectIdAccountIdMap.get(prjTsk.pse__Project__c) != prjTsk.NSP_Account_Id__c
                       && (!prjIdSetAccountIdMap.containsKey(prjTsk.pse__Project__c) ||
                           !prjIdSetAccountIdMap.get(prjTsk.pse__Project__c).contains(prjTsk.NSP_Account_Id__c) ) ){
                               Project_Account__c prjAccount = new Project_Account__c();
                               prjAccount.Project__c = prjTsk.pse__Project__c;
                               prjAccount.Account__c = prjTsk.NSP_Account_Id__c ;
                               projAccountList.add(prjAccount);
                           }
                }
            }
            if ( !projAccountList.isEmpty() ) {
                List<Database.UpsertResult> results = Database.upsert( projAccountList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ProjectTasksTriggerServiceHelper.class.getName() ,
                    'createProjectAccount:upsert' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTasksTriggerServiceHelper.class.getName() ,
                'createProjectAccount' ,
                e
            );
        }
    }

    //
    // MethodName: syncProjectTask
    // Description : Populate the Account on Project Task on creation
    // Params: List<pse__Project_Task__c> prjTaskList
    //
    public Boolean isFieldUpdatedOnPt( pse__Project_Task__c newPT , pse__Project_Task__c oldPT ) {
        return (
            ( newPT.Name != oldPT.Name )
            || ( newPT.pse__Long_Description__c != oldPT.pse__Long_Description__c )
            || ( newPT.NSP_Orientation_Address__c != oldPT.NSP_Orientation_Address__c )
            || ( newPT.NSP_Project_Attendance__c != oldPT.NSP_Project_Attendance__c )
            || ( newPT.NSP_Dispatch_Region__c != oldPT.NSP_Dispatch_Region__c )
            || ( newPT.OwnerId != oldPT.OwnerId )
            || ( newPT.pse__Status__c != oldPT.pse__Status__c )
            || ( newPT.NSP_Meeting_Type__c != oldPT.NSP_Meeting_Type__c )
            || ( newPT.pse__End_Date_Time__c != oldPT.pse__End_Date_Time__c )
            || ( newPT.pse__Start_Date_Time__c != oldPT.pse__Start_Date_Time__c )
        );
    }

    //
    // MethodName: updateProjectTaskOwner
    // Description : assign current owner when there is no PTA
    // Params: Set<Id> projectTaskIds
    //
    public static void updateProjectTaskOwner( Set<Id> projectTaskIds , Id currentUserId ) {
        try {
            Id peoRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'pse__Project_Task__c' , 'PEO_Project_Task' );
            Id bpsRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'pse__Project_Task__c'  , 'BPS_Project_Task' );
            String projectTaskQuery = NSP_ProjectTaskAssignmentTriggerHelper.getProjectTaskQuery(
                projectTaskIds ,
                peoRecordTypeId ,
                bpsRecordTypeId
            );
            List<pse__Project_Task__c> lstProjTasks = new List<pse__Project_Task__c>();
            for ( pse__Project_Task__c projTask : Database.query( projectTaskQuery ) ) {
                lstProjTasks.add(
                    new pse__Project_Task__c(
                        Id=projTask.Id ,
                        OwnerId=currentUserId
                    )
                );
            }
            if ( !lstProjTasks.isEmpty() ) {
                List<Database.UpsertResult> results = Database.upsert( lstProjTasks , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ProjectTasksTriggerServiceHelper.class.getName() ,
                    'updateProjectTaskOwner:upsert' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTasksTriggerServiceHelper.class.getName() ,
                'updateProjectTaskOwner' ,
                e
            );
        }
    }

    //
    // MethodName: updateProjectTaskOwnerForAutoResource
    // Description : match project owner as the task owner for auto resourcing
    // Params: Set<Id> projectTaskIds
    //
    public static void updateProjectTaskOwnerForAutoResource( Set<Id> projectTaskIds , Id currentUserId ) {

        try {
            String projTaskQuery = new NSP_QueryBuilder(
                    'pse__Project_Task__c' ,
                    new List<String>{
                        'Id ',
                        'OwnerId' ,
                        'pse__Number_of_Assignments__c' ,
                        'pse__Project__c',
                        'pse__Project__r.NSP_Auto_Resource_Project__c' ,
                        'pse__Project__r.ownerId'
                    }
                )
                .addFilter( 'Id' , new List<Id>(projectTaskIds) , NSP_QueryBuilder.Operator.INCLUDES )
                .build();
            List<pse__Project_Task__c> lstProjectTasks = new List<pse__Project_Task__c>();
            for ( pse__Project_Task__c projTask : Database.query( projTaskQuery ) ) {
                if ( !projTask.pse__Project__r.NSP_Auto_Resource_Project__c) {
                    lstProjectTasks.add(
                        new pse__Project_Task__c(
                            Id=projTask.Id ,
                            OwnerId=currentUserId
                        )
                    );
                }
            }
            if ( !lstProjectTasks.isEmpty() ) {
                List<Database.UpsertResult> results = Database.upsert( lstProjectTasks , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ProjectTasksTriggerServiceHelper.class.getName() ,
                    'updateProjectTaskOwnerForAutoResource:upsert' ,
                    results
                );
            }

        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTasksTriggerServiceHelper.class.getName() ,
                'updateProjectTaskOwnerForAutoResource' ,
                e
            );
        }
    }

}
//
