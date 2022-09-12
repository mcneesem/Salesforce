@isTest
public class NSP_SyncSalesOfficeDetailsOnUserTest {
    
    static testMethod void testBatch()
    {
        User currentUser = [SELECT Id,NSP_SalesDivision__c,NSP_Sales_Office__c,NSP_SalesRegion__c from user where Id =: userinfo.getUserId() limit 1];
        currentUser.NSP_Sales_Office__c = '1081';
        update currentUser;
        
        Test.startTest();
        NSP_Sales_Office_Mapping__c officeMapping = new NSP_Sales_Office_Mapping__c();
        officeMapping.NSP_Sales_Office__c = '1081';
        officeMapping.NSP_Sales_Division__c = 'Central';
        officeMapping.NSP_Sales_Region__c = 'Central 1';
        officeMapping.NSP_Start_Date__c = system.today()-1;
        officeMapping.NSP_End_Date__c = system.today()+100;
        insert officeMapping;
            NSP_SyncSalesOfficeDetailsOnUserBatch sch = new NSP_SyncSalesOfficeDetailsOnUserBatch();
            String schstr = '0 0 0 3 9 ? 2050';
			String jobID = system.schedule('Merge user sync Job', schstr, sch);
        Test.stopTest();
    }

}