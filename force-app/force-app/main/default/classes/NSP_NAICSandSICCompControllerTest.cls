/*
 * Test class to cover NSP_NAICSandSICCompController controller class
 * which is used for NAICS/SIC LWC component
*/
@isTest
public class NSP_NAICSandSICCompControllerTest {
    
    @testSetup
    public static void createTestData(){
        Account acc = NSP_TestHelper.createAccount(false);
        acc.Name = 'TestAccountSIC';
        acc.Sic = '123321';
        insert acc;
        
        Lead lead = NSP_TestHelper.createLeadRecord(false);
        lead.NSP_SIC__c = '123321';
        lead.Email = 'testUniqueLead@nsp.co.invalid';
        insert lead;
    }
    
    @isTest
    public static void getAccountRecordTest(){
        Account acc = [SELECT Id, Name, Sic, SicDesc FROM Account WHERE Id != null LIMIT 1];
        Account accRecord = NSP_NAICSandSICCompController.getAccountRecord(acc.Id);
        NSP_NAICSandSICCompController.updateAccount(acc);
        System.assertEquals(acc.Id, accRecord.Id);
    }
    
    @isTest
    public static void getAccountWrapperTest(){
        Map<String, String> recordMap = new Map<String, String>();
        NSP_NAICSandSICCompController.ResponseWrapper responseWrapper = new NSP_NAICSandSICCompController.ResponseWrapper();
        Account acc = [SELECT Id, Name, Sic, SicDesc, NSP_NAICS__c, NSP_NaicsDesc__c FROM Account WHERE Id != null LIMIT 1];
        recordMap.put('Id', acc.Id);
        recordMap.put('SicDesc', acc.Id);
        recordMap.put('Sic', acc.Id);
        recordMap.put('Naics', acc.Id);
        recordMap.put('NaicsDesc', acc.Id);
        
        responseWrapper.recordMap = recordMap;
        responseWrapper.sObjectName = 'Account';
        
        responseWrapper = NSP_NAICSandSICCompController.getRecordDetails(acc.Id);
        
        system.assertEquals('123321', responseWrapper.recordMap.get('Sic'));
        
        sObject genericObject =  NSP_NAICSandSICCompController.saveRecord(recordMap, 'Account');
        System.assertEquals(acc.Id, genericObject.Id);
        
    }
    
    @isTest
    public static void getLeadWrapperTest(){
        Map<String, String> recordMap = new Map<String, String>();
        NSP_NAICSandSICCompController.ResponseWrapper responseWrapper = new NSP_NAICSandSICCompController.ResponseWrapper();
        Lead lead = [SELECT Id, Name, NSP_SIC__c, NSP_SicDesc__c, NSP_NAICS__c, NSP_NaicsDesc__c FROM Lead WHERE Id != null LIMIT 1];
        recordMap.put('Id', lead.Id);
        recordMap.put('SicDesc', lead.Id);
        recordMap.put('Sic', lead.Id);
        recordMap.put('Naics', lead.Id);
        recordMap.put('NaicsDesc', lead.Id);
        
        responseWrapper.recordMap = recordMap;
        responseWrapper.sObjectName = 'Lead';
        
        responseWrapper = NSP_NAICSandSICCompController.getRecordDetails(lead.Id);
        
        system.assertEquals('123321', responseWrapper.recordMap.get('Sic'));
        
        sObject genericObject =  NSP_NAICSandSICCompController.saveRecord(recordMap, 'Lead');
        System.assertEquals(lead.Id, genericObject.Id);
        
    }
}