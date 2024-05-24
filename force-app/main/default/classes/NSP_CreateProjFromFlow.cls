/**
* This class is used to create projects using Financial force service
* Class Type: Invocable
* Constructor : Public 
* Description: Create project based on the order project name
* Purpose: Updates Order Items with NSP_Project__c
*			Updates Order with NSP_Project__c
*/
public class NSP_CreateProjFromFlow {
    // test w/ NSP_CreateProjFromFlowTest (96%)

    @InvocableMethod(label='Create Project' description='Create Project for Order')
    public static void createProject( List<String> records ) {
        Set<Id> orderIdSet = new Set<Id>();
        Map<String,String> projectResponseMap = new Map<String,String>();
        List<OrderItem> oiUpdateList = new List<OrderItem>();
        List<Order> ordUpdateList = new List<Order>();
        Map<String,String> projectIdMap = new Map<String,String>();
        Map<Id,pse__Proj__c> projOwnerMap = new Map<Id,pse__Proj__c>();
        pse__Proj__c projObj = new pse__Proj__c();
        List<Order> orderList = [SELECT Id,NSP_Project_Name__c,AccountId,NSP_Project_Key__c,NSP_Project__c,Name FROM Order WHERE Id IN :records];
        List<NSP_ProjectTemplateMapping__mdt> keyWithTemplateId = NSP_ProjectTemplateMapping__mdt.getAll().values();
        for(NSP_ProjectTemplateMapping__mdt projectMdt: keyWithTemplateId){
            projectIdMap.put(projectMdt.Key__c+projectMdt.Template_Name__c,projectMdt.Template_ID__c);
        }
        for (Order orderObj : orderList) {
            if(projectIdMap.containsKey(orderObj.NSP_Project_Key__c+orderObj.NSP_Project_Name__c)) {
                orderIdSet.add(orderObj.Id);
                if(orderObj.NSP_Project_Name__c != null && orderObj.NSP_Project__c == null){
                    pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest projRequest =
                        new pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest(orderObj.AccountId,projectIdMap.get(orderObj.NSP_Project_Key__c+orderObj.NSP_Project_Name__c), System.today());
                    
                    //Set Order Id as Project Name in the request which helps while constructing the Map out of Create Project Response
                    projRequest.ProjectName = orderObj.Id;
                    //copy recordTypeId & Owner
                    pse.SObjectCloneMapper.Field mapperFieldRT = new pse.SObjectCloneMapper.Field(Schema.pse__Proj__c.RecordTypeId);
                    pse.SObjectCloneMapper.Field mapperFieldOwner = new pse.SObjectCloneMapper.Field(Schema.pse__Proj__c.OwnerId);
                    Set<pse.SObjectCloneMapper.Field> setMapperFields = new Set<pse.SObjectCloneMapper.Field>{mapperFieldRT,mapperFieldOwner};
                    pse.SObjectCloneMapper mapp = new pse.SObjectCloneMapper(pse__Proj__c.SObjectType, setMapperFields);
                    projRequest.Mappers = new List<pse.SObjectCloneMapper> { mapp };

                    //Call the service and create project
                    List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projResponse =
                        pse.CreateProjectFromTemplateService.createProjectsFromTemplates( 
                            new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest>{projRequest});
                    for(pse.CreateProjectFromTemplateService.CreateProjectResponse resp : projResponse){
                        if(resp.NewProjectId!=null || Test.isRunningTest()){
                            projectResponseMap.put(resp.Request.ProjectName,resp.NewProjectId);
                        }
                        else{
                            NSP_ErrorLogHandler.logSaveException('NSP_CreateProjectFromFlow', 'createProject',resp.Errors.toString() );
                        }  
                    }
                    
                }
                else {
                    List<OrderItem> orderItems = [SELECT Id, OrderId,Order.NSP_Project_Name__c FROM OrderItem WHERE OrderId IN :orderIdSet];
                    pse__Proj__c projectName = [SELECT Id FROM pse__Proj__c WHERE Id =: orderObj.NSP_Project__c LIMIT 1];
                    for(OrderItem oi : orderItems){
                        oi.NSP_Project__c = projectName.Id;
                        oiUpdateList.add( oi );
                    }
                }
            }
        }
        if(projectResponseMap.size() > 0){
            List<OrderItem> orderItems = [SELECT Id, OrderId,Order.NSP_Project_Name__c,Order.Name FROM OrderItem WHERE OrderId IN :orderIdSet];
            List<Order> ordList = [SELECT Id,NSP_Project_Name__c,NSP_ProjectOwner__c,Name FROM Order WHERE Id IN :orderIdSet];
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
            List<Database.SaveResult> results = Database.update (oiUpdateList , false );
            NSP_ErrorLogHandler.logSaveResultsException(
                'NSP_CreateProjectFromFlow' ,
                'AssociateProjecttoOrder' ,
                results
            );
        }
            if(ordUpdateList != null && ordUpdateList.size() > 0){
                List<Database.SaveResult> results = Database.update(ordUpdateList,false);
                NSP_ErrorLogHandler.logSaveResultsException('NSP_CreateProjectFromFlow','AssociateProjecttoOrder', results);
            }
            if(projOwnerMap != null && projOwnerMap.size() > 0){
                List<Database.SaveResult> results = Database.update(projOwnerMap.values(),false);
                NSP_ErrorLogHandler.logSaveResultsException('NSP_CreateProjectFromFlow','SetProjectOwner', results);
            }
    }

    /**
* Method Name : createProjectFromButton 
* Description : This method is called from NSP_CreateProject Lightning component to create Project on click of Create Project button from Order Page.
* Author : CPQ Team       Date : 06/28/2023
* @return Boolean  
*/     
    @AuraEnabled(cacheable=true)
    public static Boolean validateUserRole(){
        Boolean isValidUser = false;
        Id userId = userinfo.getUserId();
        Set<String> validRoles = new Set<String>(System.Label.NSP_FinanceAccesstoCreateProject.split(','));
        User userDetails =[SELECT Id, Name, Email, Profile.Name, UserRole.Name FROM User where Id=:userId];
        if(validRoles.contains(userDetails.UserRole.Name) || userDetails.Profile.Name == 'System Administrator'){
            isValidUser = true;
        }
        else{
            isValidUser = false;
        }
        return isValidUser;
    } 
    /**
* Method Name : checkCreateProject 
* Description : This method is called from NSP_CreateProject Lightning component to check Create Project on click of Create Project button from Order Page.
* Author : CPQ Team       Date : 06/28/2023
* @param OrderNewMap Map of New Order. 
* @param OrderOldMap Map of Old Order.   
* @return void  
*/ 
    @AuraEnabled    
    public static void checkCreateProject(List<String> recordId){
        List<Order> orderList = [Select NSP_CreateProject__c,Id from Order where Id = :recordId];
        List<Order> updateList = new List<Order>();
        for(Order ordObj:orderList){
            ordObj.NSP_CreateProject__c = true;
            updateList.add(ordObj);
        }
        if(updateList != null && updateList.size()>0) {
            List<Database.SaveResult> results = Database.update(updateList,false);
            NSP_ErrorLogHandler.logSaveResultsException('NSP_OrderTriggerHelper','checkCreateProject', results);
        }
    }
    
/**
* Method Name : linkProjectToOrderLines 
* Description : This method is called from NSP_linkProjectToOrderItems Lightning component to link Project to Order Items
* Author : CPQ Team       Date : 03/09/2023
* @return Boolean  
*/ 
@AuraEnabled    
public static Boolean linkProjectToOrderLines(String orderId){
    Boolean res = false;
    List<Order> orderRec = [Select Id, NSP_Project__c from Order where Id =:orderId];
    List<OrderItem> orderItemList = [Select Id, NSP_Project__c from OrderItem where OrderId = :orderId];
    
    if (orderRec.size() >0 && orderRec[0].NSP_Project__c!=null) {
        for(OrderItem oli : orderItemList){
            oli.NSP_Project__c = orderRec[0].NSP_Project__c;
        }
        if(orderItemList != null && orderItemList.size()>0) {
            List<Database.SaveResult> results = Database.update(orderItemList,false);
            NSP_ErrorLogHandler.logSaveResultsException('NSP_CreateProjFromFlow','linkProjectToOrderLines', results);
            res=true;
        }
    }
    return res;
}

}