//
// @description  :  Batch Class to Syn PTA Rec with Project Task's group member field value populated
// Story : STY-02215
//
public class NSP_PtaSyncWithProjectTasksGrpMembrBatch implements Schedulable , Database.Batchable<SObject> {
    // test w/ NSP_PtaSyncPrjtTaskGrpMembrBatchTest (89%)

    //
    // Scheduleable
    //

    public void execute( SchedulableContext sc ) {
        Database.executeBatch(
            new NSP_PtaSyncWithProjectTasksGrpMembrBatch() ,
            NSP_PtaSyncWithProjectTasksGrpMembrBatch.batchSize
        );
    }

    //
    // Batchable
    //

    public Database.QueryLocator start( Database.BatchableContext bc ) 
    {
        Set<String> projectTaskStatus = new Set<String>
        {
            NSP_ServiceConstants.PROJECT_TASK_CANCELLED, 
            NSP_ServiceConstants.TASKCOMPLETE
        };
        Set<String> projectTemplateNameSet = new Set<String>
        {
            NSP_ServiceConstants.PROJECT_GENERAL_BUSINESS_TEMPLATE, 
            NSP_ServiceConstants.PROJECT_NON_REIMBURSABLE, 
            NSP_ServiceConstants.PROJECT_ORK_RELATED, 
            NSP_ServiceConstants.PROJECT_STANDARD_PLAN_PROJECT
        };
        Set<String> pseProjectStatusSet = new Set<String>
        {
            NSP_ServiceConstants.PROJECTSTATUSCOMPLETED, 
            NSP_ServiceConstants.PROJECTSTATUSCANCELLED,
            NSP_ServiceConstants.LostProject
        };
        Id retProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'pse__Proj__c' , NSP_ServiceConstants.PROJECT_RET_RECORDTYPE );
        return Database.getQueryLocator(
            [
                SELECT
                    Id ,
                    RecordTypeId ,
                    NSP_Group_Membership_for_Plan_Projects__c ,
                    pse__Status__c ,
                    pse__Project__c, 
                    pse__Project__r.pse__Start_Date__c , 
                    pse__Project__r.pse__End_Date__c 
                FROM pse__Project_Task__c
                WHERE (
                    NSP_Group_Membership_for_Plan_Projects__c != null
                    AND pse__Status__c NOT IN :projectTaskStatus
                    AND pse__Project__c != null
                    AND pse__Project__r.pse__Is_Template__c = false
                    AND pse__Project__r.pse__Project_Status__c NOT IN :pseProjectStatusSet
                    AND pse__Project__r.TemplateName__c IN :projectTemplateNameSet
                    AND pse__Project__r.RecordTypeId = :retProjectRecordTypeId
                )
            ]
        );
    }

    public void execute( Database.BatchableContext bc , List<pse__Project_Task__c> projectTaskList ) 
    {
        try
        {
            Map<Id,pse__Proj__c> projectNewMap = new Map<Id,pse__Proj__c>();
            Set<Id> projectTaskIdSet           = new Set<Id>();
            Set<Id> projectIdSet               = new Set<Id>();

            //iterating over project task to get grp member values
            for( pse__Project_Task__c eachProjectTaskRec : projectTaskList ) 
            {
                projectTaskIdSet.add(eachProjectTaskRec.Id);
                projectIdSet.add(eachProjectTaskRec.pse__Project__c);

                //Creating Map of project Id and Project
                projectNewMap.put(eachProjectTaskRec.pse__Project__c, 
                new pse__Proj__c(
                    id=eachProjectTaskRec.pse__Project__c, 
                    pse__Start_Date__c=eachProjectTaskRec.pse__Project__r.pse__Start_Date__c, 
                    pse__End_Date__c=eachProjectTaskRec.pse__Project__r.pse__End_Date__c
                    ));
            }

            // Get project task related group members
            Map<String, Set<String>> mapOfProjectTaskIdWithGrpMemberVal     = getProjectTaskRelatedGroupMembers(projectTaskList);
            
            // Get all the group member values
            Set<String> groupMemberValuesSet = new Set<String>();
            for (Set<String> groupMemberValues : mapOfProjectTaskIdWithGrpMemberVal.values()) 
            {
                groupMemberValuesSet.addAll(groupMemberValues);
            }


            //get all the project related group member values
            Map<Id, Set<String>> mapOfProjectIdWithGrpMemberVal              = getProjectRelatedGroupMembers(projectTaskList);
           
            // Create Schedule for assignments
            Map<Id,pse__Schedule__c> projectWithScheduleMap                 =  createSchedule( projectNewMap );
           
            // getting map of group member val with contact list
            Map<String,List<Id>> mapOfGroupMemberValWithContactList         = getUserContactWithSameGroupMemberValue( groupMemberValuesSet );
            
            // Get Project with related to resources
            Map<Id,List<Id>> mapOfProjectIdWithResource                     = getProjectIdWithResource(projectIdSet);

            // Get lit of Assignments to Create
            List<pse__Assignment__c> listOfAssignmentToCreate               = getListOfAssignmentsToCreate(
                mapOfProjectIdWithGrpMemberVal, 
                mapOfProjectIdWithResource, 
                mapOfGroupMemberValWithContactList, 
                projectWithScheduleMap
            );

            // Get the project task realted pta resources
            Map<Id,List<Id>> mapOfProjectTaskIdWithPtaResource = getProjectTaskIdWithPtaResource(projectTaskIdSet);  
            
            // Get all pta records to create
            List<pse__Project_Task_Assignment__c> listOfPtaToCreate = getListOfPtaRecordsToCreate(
                mapOfProjectTaskIdWithGrpMemberVal, 
                mapOfProjectTaskIdWithPtaResource, 
                mapOfGroupMemberValWithContactList
                );

            // Coditions beofre the dml operations
            if ( !listOfAssignmentToCreate.isEmpty() ) {
                this.handleDatabaseInsertOperation(
                   listOfAssignmentToCreate ,
                   'execute:insert:pse__Assignment__c'
                );
            }
            if ( !listOfPtaToCreate.isEmpty() ) {
                this.handleDatabaseInsertOperation(
                    listOfPtaToCreate ,
                    'execute:insert:pse__Project_Task_Assignment__c'
                );
            }
        } 
        catch ( Exception e ) 
        {
            NSP_ErrorLogHandler.logException(
                NSP_PtaSyncWithProjectTasksGrpMembrBatch.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    //== Finish Method
    public void finish( Database.BatchableContext bc ) 
    {
    } 

    //== Database operations
    private void handleDatabaseInsertOperation( List<Sobject> sObjectList , String methodName ) 
    {
        Database.SaveResult[] results = Database.insert(
            sObjectList ,
            NSP_PtaSyncWithProjectTasksGrpMembrBatch.isAllOrNone
        );
        NSP_ErrorLogHandler.logResults(
            NSP_PtaSyncWithProjectTasksGrpMembrBatch.class.getName() ,
            methodName ,
            results
        );
    } 

    //== Returns the list of pta records to create
    private static List<pse__Project_Task_Assignment__c> getListOfPtaRecordsToCreate(
        Map<String, Set<String>> mapOfProjectTaskIdWithGrpMemberVal , 
        Map<Id,List<Id>> mapOfProjectTaskIdWithPtaResource, 
        Map<String,List<Id>> mapOfGroupMemberValWithContactList)
    {
        List<pse__Project_Task_Assignment__c> listOfPtaToCreate = new List<pse__Project_Task_Assignment__c>();

        //iterating over Project Task to create list of PTA to be created
        for ( Id projectTaskId : mapOfProjectTaskIdWithGrpMemberVal.keySet() ) 
        {
            //over Project Task group member values
            for( String eachgrpMemberVal : mapOfProjectTaskIdWithGrpMemberVal.get( projectTaskId ) ) 
            {
                //getting list of PTAs to be created
                listOfPtaToCreate.addAll(
                    getListOfPtaToCreate(
                        mapOfProjectTaskIdWithPtaResource ,
                        mapOfGroupMemberValWithContactList ,
                        eachgrpMemberVal ,
                        projectTaskId
                    )
                );
            }
        }

        return listOfPtaToCreate;
    } 
    
    //== Method to reatun the project task Id with Pta resouce as value
    private static Map<Id,List<Id>> getProjectTaskIdWithPtaResource(Set<Id> projectTaskIdSet)
    {
        Map<Id,List<Id>> mapOfProjectTaskIdWithPtaResource = new Map<Id,List<Id>>();

        List<pse__Project_Task_Assignment__c> projectTaskAssignmentList = [
            SELECT Id , pse__Resource__c , pse__Project_Task__c 
            FROM pse__Project_Task_Assignment__c 
            WHERE pse__Project_Task__c =: projectTaskIdSet];
        
            //iterating over PTs to map Project Task with PT Resource
        for ( pse__Project_Task_Assignment__c eachPtaRec : projectTaskAssignmentList)
        {
            if (!mapOfProjectTaskIdWithPtaResource.containsKey(eachPtaRec.pse__Project_Task__c) || (
                mapOfProjectTaskIdWithPtaResource.containsKey(eachPtaRec.pse__Project_Task__c) && 
                mapOfProjectTaskIdWithPtaResource.get(eachPtaRec.pse__Project_Task__c) == null )) 
            {
                mapOfProjectTaskIdWithPtaResource.put(eachPtaRec.pse__Project_Task__c, new List<String>{ eachPtaRec.pse__Resource__c });
            }
                else 
            {
                mapOfProjectTaskIdWithPtaResource.get(eachPtaRec.pse__Project_Task__c).add(eachPtaRec.pse__Resource__c);
            }
        }

        return mapOfProjectTaskIdWithPtaResource;
    } 
    
    //== Returns the list of assignments to create
    private static List<pse__Assignment__c>  getListOfAssignmentsToCreate(
        Map<Id,Set<String>> mapOfProjectIdWithGrpMemberVal, 
        Map<Id,List<Id>>  mapOfProjectIdWithResource, 
        Map<String,List<Id>> mapOfGroupMemberValWithContactList, 
        Map<Id,pse__Schedule__c> projectWithScheduleMap)
    {
        List<pse__Assignment__c> listOfAssignmentToCreate = new List<pse__Assignment__c>();
        
        //iterating over Project to create list of Assignments to be created
        for ( Id projectId: mapOfProjectIdWithGrpMemberVal.keySet() ) 
        {
            //over Project Task group member values
            for ( String eachgrpMemberVal:  mapOfProjectIdWithGrpMemberVal.get( projectId ) ) 
            {
                //getting list of PTAs to be created
                listOfAssignmentToCreate.addAll(
                    getListOfAssignmentToCreate(
                        mapOfProjectIdWithResource ,
                        mapOfGroupMemberValWithContactList ,
                        eachgrpMemberVal ,
                        projectId ,
                        projectWithScheduleMap
                    )
                );
            }
        }

        return listOfAssignmentToCreate;
    } 
    
    //== Returns the project with related resources
    private static Map<Id,List<Id>> getProjectIdWithResource(Set<Id> projectIdSet)
    {
        Map<Id,List<Id>> mapOfProjectIdWithResource = new Map<Id,List<Id>>();
        List<pse__Assignment__c> assignmetList = [
            SELECT Id , pse__Resource__c , pse__Project__c 
            FROM pse__Assignment__c 
            WHERE (
                 pse__Project__c =:projectIdSet
                  )
        ];

        //iterating over Assignments to map Project with Resource
        for( pse__Assignment__c eachAssignment : assignmetList)
        {
            if(!mapOfProjectIdWithResource.containsKey(eachAssignment.pse__Project__c) || 
                (   mapOfProjectIdWithResource.containsKey(eachAssignment.pse__Project__c) && 
                    mapOfProjectIdWithResource.get(eachAssignment.pse__Project__c) == null))    
            {
                mapOfProjectIdWithResource.put(
                    eachAssignment.pse__Project__c , 
                    new List<Id>{ eachAssignment.pse__Resource__c }
                );
            }
            else 
            {
                mapOfProjectIdWithResource.get( eachAssignment.pse__Project__c ).add( eachAssignment.pse__Resource__c );
            }
        }

        return mapOfProjectIdWithResource;
    } 
    
    //== Returns the project task with related group members
    private static Map<String, Set<String>> getProjectTaskRelatedGroupMembers(List<pse__Project_Task__c> projectTaskList ) 
    {
        
        Map<String, Set<String>> mapOfProjectTaskIdWithGrpMemberVal = new Map<String, Set<String>>();
        for( pse__Project_Task__c eachProjectTaskRec : projectTaskList)
        {
            if( eachProjectTaskRec.NSP_Group_Membership_for_Plan_Projects__c != null )
            {
                if ( !mapOfProjectTaskIdWithGrpMemberVal.containsKey(eachProjectTaskRec.Id) || 
                    (mapOfProjectTaskIdWithGrpMemberVal.containsKey(eachProjectTaskRec.Id) && 
                    mapOfProjectTaskIdWithGrpMemberVal.get(eachProjectTaskRec.Id) == null)) 
                {
                    mapOfProjectTaskIdWithGrpMemberVal.put(
                        eachProjectTaskRec.Id, 
                        new Set<String>(eachProjectTaskRec.NSP_Group_Membership_for_Plan_Projects__c.split(';'))
                        );
                } 
                else 
                {
                    mapOfProjectTaskIdWithGrpMemberVal.get(eachProjectTaskRec.Id).addAll(eachProjectTaskRec.NSP_Group_Membership_for_Plan_Projects__c.split(';'));
                }
            }
        }

        return mapOfProjectTaskIdWithGrpMemberVal;
    } 
    //== Returns the project with related group members
    private static Map<Id, Set<String>> getProjectRelatedGroupMembers(List<pse__Project_Task__c> projectTaskList ) 
    {
        Map<Id, Set<String>> mapOfProjectIdWithGrpMemberVal = new Map<Id, Set<String>>();
        for( pse__Project_Task__c eachProjectTaskRec : projectTaskList)
        {
            if( eachProjectTaskRec.NSP_Group_Membership_for_Plan_Projects__c != null )
            {
                if ( !mapOfProjectIdWithGrpMemberVal.containsKey(eachProjectTaskRec.pse__Project__c) || 
                    (mapOfProjectIdWithGrpMemberVal.containsKey(eachProjectTaskRec.pse__Project__c) && 
                    mapOfProjectIdWithGrpMemberVal.get(eachProjectTaskRec.pse__Project__c) == null)) 
                {
                    mapOfProjectIdWithGrpMemberVal.put(
                        eachProjectTaskRec.pse__Project__c, 
                        new Set<String>(eachProjectTaskRec.NSP_Group_Membership_for_Plan_Projects__c.split(';'))
                        );
                } 
                else 
                {
                    mapOfProjectIdWithGrpMemberVal.get(eachProjectTaskRec.pse__Project__c).addAll(eachProjectTaskRec.NSP_Group_Membership_for_Plan_Projects__c.split(';'));
                }
            }
        }

        return mapOfProjectIdWithGrpMemberVal;
    }

    //
    // MethodName: getUserContactWithSameGroupMemberValue
    // Description : gets list of user contact mapped with group member value
    // Story : STY-02215
    // Author :Abhishek Kumar
    // Params: List<pse__Project_Task__c> groupMemberValuesSet
    //
    public static Map<String,List<Id>> getUserContactWithSameGroupMemberValue( Set<String> groupMemberValuesSet ) {
        Map<String, List<Id>> mapOfGroupMemberValWithContactList = new Map<String, List<Id>>();

        try {
            //iterate over contact where grp member value is populated and in groupMemberValuesSet
            for ( Contact eachContact : [
                        SELECT
                            Id ,
                            Name ,
                            pse__Salesforce_User__c ,
                            pse__Salesforce_User__r.NSP_Group_Member_For_Plan_Projects__c
                        FROM Contact
                        WHERE (
                            ( pse__Salesforce_User__c != null )
                            AND ( pse__Salesforce_User__r.NSP_Group_Member_For_Plan_Projects__c != null )
                            AND ( pse__Salesforce_User__r.NSP_Group_Member_For_Plan_Projects__c IN :groupMemberValuesSet )
                        )
                    ]
                )
            {

                //map group member val with contact list
                if ( mapOfGroupMemberValWithContactList.get( eachContact.pse__Salesforce_User__r.NSP_Group_Member_For_Plan_Projects__c ) == null ) {
                    mapOfGroupMemberValWithContactList.put(
                        eachContact.pse__Salesforce_User__r.NSP_Group_Member_For_Plan_Projects__c ,
                        new List<Id>{eachContact.Id}
                    );
                } else {
                    mapOfGroupMemberValWithContactList.get( eachContact.pse__Salesforce_User__r.NSP_Group_Member_For_Plan_Projects__c ).add( eachContact.Id );
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_PtaSyncWithProjectTasksGrpMembrBatch.class.getName() ,
                'getUserContactWithSameGroupMemberValue' ,
                e
            );
        }
        return mapOfGroupMemberValWithContactList;
    }

    //
    // MethodName: getListOfAssignmentToCreate
    // Params: Map<Id,List<Id>> mapOfProjectIdWithGrpMemberVal
    // Params: Map<String,List<Id>> mapOfGroupMemberValWithContactList
    // Params: String groupMembershipVal
    // Params: Id projectTaskId
    //
    public static List<pse__Assignment__c> getListOfAssignmentToCreate(
        Map<Id,List<Id>> mapOfProjectIdWithResource ,
        Map<String,List<Id>> mapOfGroupMemberValWithContactList ,
        String groupMembershipVal ,
        Id projectId ,
        Map<Id,pse__Schedule__c> projectWithScheduleMap
        )
    {
        List<pse__Assignment__c> listOfAssignToBeCreated = new List<pse__Assignment__c>();
        try {
            if ( ( mapOfProjectIdWithResource != null )
                && ( mapOfGroupMemberValWithContactList != null )
                && mapOfGroupMemberValWithContactList.containsKey( groupMembershipVal )
                && ( mapOfGroupMemberValWithContactList.get( groupMembershipVal ) != null )
                )
            {
                //iterate over contact with groupMembershipVal
                for ( Id eachContactRec : mapOfGroupMemberValWithContactList.get( groupMembershipVal ) ) {
                    //check if project does not contain Assignment with this contact
                    if ( ( mapOfProjectIdWithResource.get( projectId ) == null )
                        || !mapOfProjectIdWithResource.get( projectId ).contains( eachContactRec )
                        )
                    {
                        //initialize new Assignment Rec
                        pse__Assignment__c newAssRec = new pse__Assignment__c();
                        newAssRec.pse__Resource__c = eachContactRec;
                        newAssRec.pse__Project__c = projectId;
                        newAssRec.pse__Schedule__c = projectWithScheduleMap.get( projectId ).Id;
                        newAssRec.pse__Bill_Rate__c = 0.0000;
                        listOfAssignToBeCreated.add( newAssRec );
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_PtaSyncWithProjectTasksGrpMembrBatch.class.getName() ,
                'getListOfAssignmentToCreate' ,
                e
            );
        }
        return listOfAssignToBeCreated;
    }

    //
    // MethodName: getListOfPtaToCreate
    // Description : returns list of PTAs to be created
    // Story : STY-02215
    // Author :Abhishek Kumar 
    // Params: Map<Id,List<Id>> mapOfProjectTaskIdWithPtaResource
    // Params: Map<String,List<Id>> mapOfGroupMemberValWithContactList
    // Params: String groupMembershipVal
    // Params: Id projectTaskId
    //
    public static List<pse__Project_Task_Assignment__c> getListOfPtaToCreate(
        Map<Id,List<Id>> mapOfProjectTaskIdWithPtaResource ,
        Map<String,List<Id>> mapOfGroupMemberValWithContactList ,
        String groupMembershipVal ,
        Id projectTaskId
        )
    {
        List<pse__Project_Task_Assignment__c> listOfPtaToBeCreated = new List<pse__Project_Task_Assignment__c>();
        try {
            if ( ( mapOfProjectTaskIdWithPtaResource != null )
                && ( mapOfGroupMemberValWithContactList != null )
                && mapOfGroupMemberValWithContactList.containsKey( groupMembershipVal )
                && ( mapOfGroupMemberValWithContactList.get( groupMembershipVal ) != null )
                )
            {
                //iterate over contact with groupMembershipVal
                for ( Id eachContactRec : mapOfGroupMemberValWithContactList.get( groupMembershipVal ) ) {
                    //check if project does not contain PTA with this contact
                    if ( ( mapOfProjectTaskIdWithPtaResource.get( projectTaskId ) == null )
                        || !mapOfProjectTaskIdWithPtaResource.get( projectTaskId ).contains( eachContactRec )
                        )
                    {
                        //initialize new PTA Rec
                        pse__Project_Task_Assignment__c newPtaRec = new pse__Project_Task_Assignment__c();
                        newPtaRec.pse__Resource__c = eachContactRec;
                        newPtaRec.pse__Project_Task__c = projectTaskId;
                        listOfPtaToBeCreated.add( newPtaRec );
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_PtaSyncWithProjectTasksGrpMembrBatch.class.getName() ,
                'getListOfPtaToCreate' ,
                e
            );
        }
        return listOfPtaToBeCreated;
    }

    //
    // method to create schedule for the assignments.
    // @param Map<Id, Id> userWithContactMap, Map<Id, pse__Proj__c> projectNewMap
    // @return Map<Id, pse__Schedule__c> projectWithScheduleMap
    //
    public Map<Id,pse__Schedule__c> createSchedule( Map<Id,pse__Proj__c> projectNewMap ) {
        Map<Id,pse__Schedule__c> projectWithScheduleMap = new Map<Id,pse__Schedule__c>();
        for ( pse__Proj__c project : projectNewMap.values() ) {
            pse__Schedule__c sch = new pse__Schedule__c();
            sch.pse__Start_Date__c = project.pse__Start_Date__c;
            sch.pse__End_Date__c = project.pse__End_Date__c;
            projectWithScheduleMap.put( project.Id , sch );
        }
        if ( !projectWithScheduleMap.isEmpty() ) {
            insert projectWithScheduleMap.values();
        }
        return projectWithScheduleMap;
    }

    //
    // attributes controlled by Custom Settings...
    // ~ intentionally static to allow Custom Settings to modify the attributes a Scheduled job...
    //

    private static Project_Task_Assignment_Batch_Settings__c settings {
        private get {
            if ( settings == null ) {
                settings = Project_Task_Assignment_Batch_Settings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isAllOrNone {
        private get {
            if ( isAllOrNone == null ) {
                Boolean local = False;
                if ( NSP_PtaSyncWithProjectTasksGrpMembrBatch.settings != null ) {
                    local = NSP_PtaSyncWithProjectTasksGrpMembrBatch.settings.IsAllOrNone__c;
                }
                isAllOrNone = local;
            }
            return isAllOrNone;
        }
        private set;
    }

    private static Integer batchSize {
        private get {
            if ( batchSize == null ) {
                Integer local = 200;
                if ( ( NSP_PtaSyncWithProjectTasksGrpMembrBatch.settings != null )
                    && ( NSP_PtaSyncWithProjectTasksGrpMembrBatch.settings.BatchSize__c != null )
                    )
                {
                    local = NSP_PtaSyncWithProjectTasksGrpMembrBatch.settings.BatchSize__c.intValue();
                }
                // batch size must be greater than zero...
                if ( local < 1 ) {
                    local = 1;
                }
                // batch size must be less than or equal to 2000...
                if ( local > 2000 ) {
                    local = 2000;
                }
                batchSize = local;
            }
            return batchSize;
        }
        private set;
    }

}
//