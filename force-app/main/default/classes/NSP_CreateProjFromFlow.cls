//
// This class is used to create projects using Financial force service
// Class Type: Invocable
// Constructor : Public
// Description: Create project based on the order project name
// Purpose: Updates Order Items with NSP_Project__c
// Updates Order with NSP_Project__c
//
public with sharing class NSP_CreateProjFromFlow {
    // test w/ NSP_CreateProjFromFlowTest, NSP_AssetServiceTriggerHelperTest (80%)
    // test w/ NSP_CreateProjFromFlowTest (78%)
    // test w/ NSP_AssetServiceTriggerHelperTest (15%)

    @InvocableMethod(label='Create Project' description='Create Project for Order')
    public static void createProject( List<String> records ) {
        try {
            Set<Id> orderIdSet = new Set<Id>();
            Map<String,String> projectResponseMap = new Map<String,String>();
            List<OrderItem> oiUpdateList = new List<OrderItem>();
            List<Order> ordUpdateList = new List<Order>();
            Map<String,String> projectIdMap = new Map<String,String>();
            Map<Id,pse__Proj__c> projOwnerMap = new Map<Id,pse__Proj__c>();
            pse__Proj__c projObj = new pse__Proj__c();
            List<Order> orderList = [
                SELECT Id , Name , AccountId , NSP_Project_Name__c , NSP_Project_Key__c , NSP_Project__c
                FROM Order
                WHERE ( Id IN :records )
            ];
            List<NSP_ProjectTemplateMapping__mdt> keyWithTemplateId = NSP_ProjectTemplateMapping__mdt.getAll().values();
            for(NSP_ProjectTemplateMapping__mdt projectMdt: keyWithTemplateId){
                projectIdMap.put(projectMdt.Key__c+projectMdt.Template_Name__c,projectMdt.Template_ID__c);
            }
            for (Order orderObj : orderList) {
                if(projectIdMap.containsKey(orderObj.NSP_Project_Key__c+orderObj.NSP_Project_Name__c)) {
                    orderIdSet.add(orderObj.Id);
                    if(orderObj.NSP_Project_Name__c != null && orderObj.NSP_Project__c == null){
                        pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest projRequest = new pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest(
                            orderObj.AccountId ,
                            projectIdMap.get( orderObj.NSP_Project_Key__c+orderObj.NSP_Project_Name__c ) ,
                            System.today()
                        );
                        
                        //Set Order Id as Project Name in the request which helps while constructing the Map out of Create Project Response
                        projRequest.ProjectName = orderObj.Id;
                        //copy recordTypeId & Owner
                        pse.SObjectCloneMapper.Field mapperFieldRT = new pse.SObjectCloneMapper.Field(Schema.pse__Proj__c.RecordTypeId);
                        pse.SObjectCloneMapper.Field mapperFieldOwner = new pse.SObjectCloneMapper.Field(Schema.pse__Proj__c.OwnerId);
                        Set<pse.SObjectCloneMapper.Field> setMapperFields = new Set<pse.SObjectCloneMapper.Field>{
                            mapperFieldRT ,
                            mapperFieldOwner ,
                            NSP_CreateProjFromFlow.getDefaultRegionMapperField()
                        };
                        pse.SObjectCloneMapper mapp = new pse.SObjectCloneMapper(pse__Proj__c.SObjectType, setMapperFields);
                        projRequest.Mappers = new List<pse.SObjectCloneMapper> { mapp };

                        //Call the service and create project
                        List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projResponse = pse.CreateProjectFromTemplateService.createProjectsFromTemplates(
                            new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest>{ projRequest }
                        );
                        Id newProjectId = CreateProjectFromTemplateAction.handleCreateProjectResponse(
                            NSP_CreateProjFromFlow.class.getName() ,
                            'createProject' ,
                            projResponse
                        );
                        if ( newProjectId != null ) {
                            projectResponseMap.put( projResponse[0].Request.ProjectName , newProjectId );
                        }
                    } else {
                        List<OrderItem> orderItems = [
                            SELECT Id , OrderId , Order.NSP_Project_Name__c
                            FROM OrderItem
                            WHERE (
                                ( OrderId IN :orderIdSet )
                                AND ( Separate_Project__c = false )
                            )
                        ];
                        List<pse__Proj__c> projectRecords = [
                            SELECT Id
                            FROM pse__Proj__c
                            WHERE ( Id = :orderObj.NSP_Project__c )
                            LIMIT 1
                        ];
                        pse__Proj__c selectedProject = null;
                        if ( !projectRecords.isEmpty() ) {
                            selectedProject = projectRecords[0];
                        }
                        if ( selectedProject != null ) {
                            for ( OrderItem oi : orderItems ) {
                                oi.NSP_Project__c = selectedProject.Id;
                                oiUpdateList.add( oi );
                            }
                        }
                    }
                }
            }
            if(projectResponseMap.size() > 0){
                List<OrderItem> orderItems = [
                    SELECT Id , OrderId , Order.NSP_Project_Name__c , Order.Name
                    FROM OrderItem
                    WHERE (
                        ( OrderId IN :orderIdSet )
                        AND ( Separate_Project__c = false )
                    )
                ];
                List<Order> ordList = [
                    SELECT Id , Name , NSP_Project_Name__c , NSP_ProjectOwner__c
                    FROM Order
                    WHERE ( Id IN :orderIdSet )
                ];
                Map<Id,OrderItem> orderItemCheckMap = new Map<Id,OrderItem>( oiUpdateList );
                if ( ( oiUpdateList != null ) && !oiUpdateList.isEmpty() ) {
                    orderItemCheckMap = new Map<Id,OrderItem>( oiUpdateList );
                }
                for ( OrderItem oi : orderItems ) {
                    if ( projectResponseMap.containsKey( oi.OrderId ) ) {
                        oi.NSP_Project__c = projectResponseMap.get( oi.OrderId );
                        if ( !orderItemCheckMap.containsKey( oi.Id ) ) { // prevent System.ListException: Duplicate id in list: 802XXXXXXXXXXXXXXX
                            oiUpdateList.add( oi );
                        }
                    }
                }
                for(Order orderObj : ordList){
                    if(projectResponseMap.containsKey(orderObj.Id)) {
                        orderObj.NSP_Project__c = projectResponseMap.get(orderObj.Id);
                        orderObj.NSP_CreateProject__c = false;
                        ordUpdateList.add(orderObj);
                        if(!projOwnerMap.containsKey(orderObj.NSP_Project__c) && orderObj.NSP_ProjectOwner__c != null){
                            projObj = new pse__Proj__c();
                            projObj.NSP_ProjectOwner__c = orderObj.NSP_ProjectOwner__c;
                            projObj.OwnerId=orderObj.NSP_ProjectOwner__c;
                            projObj.Id = projectResponseMap.get(orderObj.Id);
                            projOwnerMap.put(orderObj.NSP_Project__c,projObj);
                        }
                    }
                }
            }
            if ( ( oiUpdateList != null ) && !oiUpdateList.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( oiUpdateList , false );
                NSP_CreateProjFromFlow.handleResults( results , 'createProject:update:OrderItem' );
            }
            if ( ( ordUpdateList != null ) && !ordUpdateList.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( ordUpdateList , false );
                NSP_CreateProjFromFlow.handleResults( results , 'createProject:update:Order' );
            }
            if ( ( projOwnerMap != null ) && !projOwnerMap.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( projOwnerMap.values() , false );
                NSP_CreateProjFromFlow.handleResults( results , 'createProject:update:pse__Proj__c' );
            }
        } catch ( Exception e ) {
            NSP_CreateProjFromFlow.handleException( e , 'createProject' );
        }
    }

    //
    // Method Name : createProjectFromButton
    // Description : This method is called from NSP_CreateProject Lightning component to create Project on click of Create Project button from Order Page.
    // Author : CPQ Team       Date : 06/28/2023
    // @return Boolean
    //
    @AuraEnabled(cacheable=true)
    public static Boolean validateUserRole(){
        List<User> userRecords =[
            SELECT
                Id ,
                Name ,
                Email ,
                Profile.Name ,
                UserRole.Name
            FROM User
            WHERE ( Id = :UserInfo.getUserId() )
            LIMIT 1
        ];
        User selectedUser = null;
        if ( !userRecords.isEmpty() ) {
            selectedUser = userRecords[0];
        }
        Boolean isValidUser = false;
        if ( selectedUser != null ) {
            Set<String> validRoles = new Set<String>();
            if ( String.isNotBlank( System.Label.NSP_FinanceAccesstoCreateProject ) ) {
                validRoles = new Set<String>(
                    System.Label.NSP_FinanceAccesstoCreateProject.split( ',' )
                );
            }
            if ( ( selectedUser.UserRole != null )
                && String.isNotBlank( selectedUser.UserRole.Name )
                && !validRoles.isEmpty()
                && validRoles.contains( selectedUser.UserRole.Name )
                )
            {
                isValidUser = true;
            } else if ( ( selectedUser.Profile != null )
                && String.isNotBlank( selectedUser.Profile.Name )
                && selectedUser.Profile.Name.startsWith( 'System Admin' )
                )
            {
                isValidUser = true;
            }
        }
        return isValidUser;
    }

    //
    // Method Name : checkCreateProject
    // Description : This method is called from NSP_CreateProject Lightning component to check Create Project on click of Create Project button from Order Page.
    // Author : CPQ Team       Date : 06/28/2023
    // @param OrderNewMap Map of New Order.
    // @param OrderOldMap Map of Old Order.
    // @return void
    //
    @AuraEnabled    
    public static void checkCreateProject( List<String> recordId ) {
        List<Order> orderList = [
            SELECT Id , NSP_CreateProject__c
            FROM Order
            WHERE ( Id = :recordId )
        ];
        List<Order> updateList = new List<Order>();
        for ( Order ordObj : orderList ) {
            ordObj.NSP_CreateProject__c = true;
            updateList.add( ordObj );
        }
        if ( !updateList.isEmpty() ) {
            List<Database.SaveResult> results = Database.update( updateList , false );
            NSP_CreateProjFromFlow.handleResults( results , 'checkCreateProject' );
        }
    }

    //
    // Method Name : linkProjectToOrderLines
    // Description : This method is called from NSP_linkProjectToOrderItems Lightning component to link Project to Order Items
    // Author : CPQ Team       Date : 03/09/2023
    // @return Boolean
    //
    @AuraEnabled    
    public static Boolean linkProjectToOrderLines( String orderId ) {
        Boolean res = false;
        List<Order> orderRec = [
            SELECT Id , NSP_Project__c
            FROM Order
            WHERE ( Id = :orderId )
        ];
        List<OrderItem> orderItemList = [
            SELECT Id , NSP_Project__c
            FROM OrderItem
            WHERE ( OrderId = :orderId )
        ];
        if ( ( orderItemList != null )
            && !orderRec.isEmpty()
            && ( orderRec[0].NSP_Project__c != null )
            )
        {
            for ( OrderItem oli : orderItemList ) {
                oli.NSP_Project__c = orderRec[0].NSP_Project__c;
            }
            if ( !orderItemList.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( orderItemList , false );
                NSP_CreateProjFromFlow.handleResults( results , 'linkProjectToOrderLines' );
                res = true;
            }
        }
        return res;
    }

    private static ProjectCreationSettings__c settings {
        get {
            if ( settings == null ) {
                settings = ProjectCreationSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Id defaultRegionId {
        get {
            if ( defaultRegionId == null ) {
                ID local ;
                if ( NSP_CreateProjFromFlow.settings != null
                    && String.isNotBlank( NSP_CreateProjFromFlow.settings.DefaultRegionId__c )
                    && (NSP_CreateProjFromFlow.settings.DefaultRegionId__c InstanceOf Id)
                    )
                {
                    local = NSP_CreateProjFromFlow.settings.DefaultRegionId__c;
                }
                defaultRegionId = local;
            }
            return defaultRegionId;
        }
        private set;
    }

    public static pse.SObjectCloneMapper.Field getDefaultRegionMapperField() {
        pse.SObjectCloneMapper.Field mapperField = new pse.SObjectCloneMapper.Field(
            Schema.pse__Proj__c.pse__Region__c
        );
        if ( NSP_CreateProjFromFlow.defaultRegionId != null ) {
            mapperField.DefaultValue = NSP_CreateProjFromFlow.defaultRegionId;
        }
        return mapperField;
    }

    public static pse.SObjectCloneMapper getDefaultMappers() {
        pse.SObjectCloneMapper mapper = new pse.SObjectCloneMapper(
            pse__Proj__c.SObjectType ,
            new Set<pse.SObjectCloneMapper.Field>{
                NSP_CreateProjFromFlow.getDefaultRegionMapperField()
            }
        );
        return mapper ;
    }

    // for test code coverage only...
    public static void testHandleResults( List<Database.SaveResult> results , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_CreateProjFromFlow.handleResults( results , methodName );
        }
    }

    private static void handleResults( List<Database.SaveResult> results , String methodName ) {
        NSP_ErrorLogHandler.logResults(
            NSP_CreateProjFromFlow.class.getName() ,
            methodName ,
            results
        );
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_CreateProjFromFlow.handleException( e , methodName );
        }
    }
    
    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_CreateProjFromFlow.class.getName() ,
            methodName ,
            e
        );
    }

}
//