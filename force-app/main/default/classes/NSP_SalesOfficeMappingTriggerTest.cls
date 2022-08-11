@isTest
public class NSP_SalesOfficeMappingTriggerTest {

    static testMethod void testOnInsert()
    {
        Test.startTest();
        NSP_Sales_Office_Mapping__c officeMapping = new NSP_Sales_Office_Mapping__c();
        officeMapping.NSP_Sales_Office__c = '1081';
        officeMapping.NSP_Sales_Division__c = 'Central';
        officeMapping.NSP_Sales_Region__c = 'Central 1';
        officeMapping.NSP_Start_Date__c = system.today()-1;
        officeMapping.NSP_End_Date__c = system.today()+100;
        insert officeMapping;
        
        NSP_Sales_Office_Mapping__c office1Mapping = new NSP_Sales_Office_Mapping__c();
        office1Mapping.NSP_Sales_Office__c = '1081';
        office1Mapping.NSP_Sales_Division__c = 'Central';
        office1Mapping.NSP_Sales_Region__c = 'Central 1';
        office1Mapping.NSP_Start_Date__c = system.today()+101;
        office1Mapping.NSP_End_Date__c = system.today()+200;
        insert office1Mapping;
        
        office1Mapping.NSP_Start_Date__c = system.today()+102;
        Update office1Mapping;
         Test.stopTest();
    }
}