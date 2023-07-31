/**
 * Represents test class for NSP_FLSACaseCreationBatch class
 */
@isTest(SeeAllData=false)
public class NSP_FLSACaseCreationBatch_Test {
    
    /***********************************************************************************************
    * MethodName: testData
    * Description :  This method will create test data 
    * Params:   None   
    * ********************************************************************************************/    
	@testSetup
    static void testData() {
        Account accoutObject = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        accoutObject.NSP_First_Pay_Date__c = system.today();
        accoutObject.NumberOfEmployees = 2;
        accoutObject.NSP_Account_Segment__c = 'MidMarket'; 
        insert accoutObject;
        
        NSP_Sub_Client__c newSubclient = (NSP_Sub_Client__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Client__c(), 'NSP_TestDataFactory.SubClientDefaults', false);
        newSubclient.NSP_Account__c = accoutObject.Id;
        newSubclient.NSP_First_Pay_Date__c = system.today();
        insert newSubclient;
        
        NSP_Account_Team__c AT = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
        AT.NSP_Account__c = accoutObject.Id;
        insert AT;
        
        NSP_BPA_Mapping__c newBPA = new NSP_BPA_Mapping__c();
		newBPA.NSP_Account__c = accoutObject.Id;
        insert newBPA;

        Account accoutObject1 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        accoutObject1.NSP_First_Pay_Date__c = system.today().addDays(-2);
        accoutObject1.NumberOfEmployees = 160;
        accoutObject1.Name = 'Test Account with Employees';
          accoutObject.NSP_Account_Segment__c = System.Label.NSP_Account_Segment_MidMarketEnterprise; 
        insert accoutObject1;
        
        NSP_Sub_Client__c newSubclient1 = (NSP_Sub_Client__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Client__c(), 'NSP_TestDataFactory.SubClientDefaults', false);
        newSubclient1.NSP_Account__c = accoutObject1.Id;
        newSubclient1.NSP_First_Pay_Date__c = system.today().addDays(-2);
        insert newSubclient1;
        
        
    }    
    
    /***********************************************************************************************
    * MethodName: testAccountRegulatedAreaBatch
    * Description :  This method will test AccountRegulatedAreaBatch 
    * Params:   None   
    * ********************************************************************************************/    
    Static testMethod void testAccountRegulatedAreaBatch() {  
        List<Account> accList = [SELECT Id, NSP_Account_Segment__c, NSP_First_Pay_Date__c, NSP_AIMS_Client__c, 
            		   (SELECT Id, NSP_Account__c,NSP_Account__r.NSP_AIMS_First_Pay_Date__c, NSP_Account__r.NSP_First_Pay_Date__c, NSP_First_Pay_Date__c FROM Sub_Clients__r WHERE NSP_First_Pay_Date__c != null),
            		   (SELECT Id, NSP_FLSA_Case__c FROM Cases WHERE NSP_FLSA_Case__c = True),
            		   (SELECT Id, Name, NSP_Sales_Office__c, NSP_BPA__c, NSP_FLSA_Specialist__c, NSP_Account__c FROM NSP_BPA_Mappings__r) 
            		   FROM Account WHERE NSP_First_Pay_Date__c != null ];
        Test.startTest();
    	//Calling the batch for FLSA case creation for 1st time    
        Database.executeBatch(new NSP_FLSACaseCreationBatch()); //executes the bacth class
        Test.stopTest();
        System.assertEquals(accList[0].Sub_Clients__r.size(), [select count() from NSP_Sub_Client__c WHERE NSP_First_Pay_Date__c != Null LIMIT 1]);
    }


}