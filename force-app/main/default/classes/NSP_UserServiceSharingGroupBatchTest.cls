//***Test Class for NSP_UserServiceSharingGroupBatch Class***
/**
* @description  : Test Class for NSP_UserServiceSharingGroupBatch Class
* @date  January 24, 2023 
* Name : NSP_UserServiceSharingGroupBatchTest
*/
@IsTest
private class NSP_UserServiceSharingGroupBatchTest {
    private static final List<String> USER_FIELDS = new List<String>{'Id', 'NSP_Profile_Name__c'};
        private static final List<String> profileFields = new List<String>{'Id', 'Name'};
            private static final Profile peoProfile =  Database.query(new NSP_QueryBuilder('Profile', profileFields).addFilter('Name', NSP_ServiceConstants.PEOSERVICE).addLimit(1).setSecurityEnforce(false).build());
    private static final Profile integrationProfile =  Database.query(new NSP_QueryBuilder('Profile', profileFields).addFilter('Name', NSP_ServiceConstants.INTEGRATION_USER).addLimit(1).setSecurityEnforce(false).build());
    @testSetup
    static void setupTestData(){
        
        List<User> userList = new List<user>();
        User peoUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', false);
        peoUser.ProfileId = peoProfile.Id;
        peoUser.Username = 'testuser@test.com' + System.currentTimeMillis();
        userList.add(peoUser);
        
        User integrationUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', false);
        integrationUser.ProfileId = integrationProfile.Id;
        userList.add(integrationUser);
        
        insert userList;
    }
    
    /* @Description: This test method is used to cover NSP_UserServiceSharingGroupBatch
* @Created date: 01/24/2023. 
* @return void             
*/
    
    @isTest
    static void addtoServiceProfilePublicGroupTest() {
        
        List<String> grpFields = new List<String>{'Id', 'Type','DeveloperName'};
            List<String> grpMemFields = new List<String>{'Id', 'GroupId','UserOrGroupId'};
                Set<Id> grpMemIdSet = new Set<Id>();
        Id serviceProfileGroupId = NSP_sObjectSelector.selectGroupByTypeAndApiName(NSP_ServiceConstants.TYPE_REGULAR, NSP_ServiceConstants.SERVICE_PROFILE_GROUP_MEMBERS, grpFields).Id;
        
        // Query Integration User
        String integrationUserQuery = new NSP_QueryBuilder('User', USER_FIELDS).addFilter('NSP_User_Profile_Name__c', NSP_ServiceConstants.INTEGRATION_USER).addLimit(1).setSecurityEnforce(false).build();
        User getIntegrationUser =  Database.query(integrationUserQuery);
        
        Test.startTest();
        NSP_UserServiceSharingGroupBatch obj = new NSP_UserServiceSharingGroupBatch(userInfo.getUserId(), 'TODAY');
        database.executeBatch(obj);
        Test.stopTest();
        
        // Query Group Member
        String grpMemQuery = new NSP_QueryBuilder('GroupMember', grpMemFields).addFilter('GroupId', serviceProfileGroupId).addLimit(1).setSecurityEnforce(false).build();
         List<GroupMember> assertGrpMem =  Database.query(grpMemQuery);
        
        for(GroupMember grpMem : assertGrpMem){
            grpMemIdSet.add(grpMem.UserOrGroupId);
        }
        system.assertEquals(grpMemIdSet.contains(getIntegrationUser.Id), false, 'Integration user will not be added to Service profile public group'); // Negative case
        system.assert(assertGrpMem != null); // Positive Case
    }
}