@isTest
private class PortalPermitActionTest {

    @testSetup
    private static void setupData() {
        //
        Portal_Access_Settings__c settings = Portal_Access_Settings__c.getOrgDefaults();
        settings.IsEnabled__c = true;
        settings.IsDryRun__c = true;
        settings.CommunityProfileId__c = '00e4x0000013MV2AAM'; // Customer Community Plus
        settings.MembershipPermissionSetName__c = 'Portal_Site_Access';
        settings.AllowedPermissionSetNames__c = 'Portal_Site_Access\r\nPortal_Use_File_Actions';
        upsert settings;
        //
    }

    @isTest
    private static void testAction() {
        Test.startTest();
        PortalPermitAction.FlowInput input = new PortalPermitAction.FlowInput();
        input.recordId = UserInfo.getUserId();
        input.selectedPermissionSets = 'Portal_Site_Access;Portal_Use_File_Actions;Modify_All_Data';
        List<PortalPermitAction.FlowInput> inputs = new List<PortalPermitAction.FlowInput>();
        inputs.add( input );
        List<PortalPermitAction.FlowOutput> outputs = PortalPermitAction.permit( inputs );
        System.debug( ' PortalPermitAction.testAction ~ outputs=' + outputs );
        Test.stopTest();
    }

}
//