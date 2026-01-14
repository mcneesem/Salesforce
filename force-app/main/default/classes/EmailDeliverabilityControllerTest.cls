@isTest
private class EmailDeliverabilityControllerTest {

    // Verifies that isEnabledOutbound returns true when the user setting IsEnabledOutbound__c = true.
    @isTest
    private static void testEnabledWhenSettingTrue() {
        // Ensure a user-specific settings record exists and is true
        Email_Deliverability_Settings__c settings = Email_Deliverability_Settings__c.getInstance(UserInfo.getUserId());
        settings.IsEnabledOutbound__c = true;
        upsert settings;
        Test.startTest();
        Boolean enabled = EmailDeliverabilityController.isEnabledOutbound;
        Test.stopTest();
        System.assertEquals(true, enabled, 'Outbound deliverability should reflect settings.IsEnabledOutbound__c = true.');
    }

}
//