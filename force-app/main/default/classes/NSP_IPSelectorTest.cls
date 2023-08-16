/**
Apex Class Name      :  NSP_IPSelectorTest
Version              :  1.0   
Author               :  Simran Thukral                                                                       
Created Date         :  10/3/2022 
Function             :  This class is used as a testclass to  NSP_IPSelectorTest  
Story                :                                                                      
*/
@isTest
private class NSP_IPSelectorTest {
    @testSetup
    static void setUpIPRecords(){
        // Create Account Records
        List<Account> accounts = new List<Account>();

        Account testAccount1 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account());
        testAccount1.Name = 'Test Account 1' ;
        accounts.add(testAccount1);
        
        Account testAccount2 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account());
        testAccount2.Name='Test Account 2' ;
        accounts.add(testAccount2);
        
        Account dummyAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account());
        dummyAccount.Name = 'Dummy Account' ;
        accounts.add(dummyAccount);
        
        insert accounts;
        //Create Asset
        Asset dummyAsset1 = (Asset) NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', true);

        Asset dummyAsset = (Asset) NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        dummyAsset.NSP_Client__c = 'null';
        insert dummyAsset;

        // Create IP records
        List<Implementation_Profile__c> ipRecords = new List<Implementation_Profile__c>();
        Implementation_Profile__c ipRec1 = (Implementation_Profile__c)NSP_TestExtendedDataFactory.createSObject(new Implementation_Profile__c(), 'NSP_TestDataFactory.ImplementationProfileDefaults', false);
        ipRec1.Account__c = testAccount1.Id;
        ipRec1.NSP_Assignment_Notes__c = 'Test';
        ipRec1.NSP_Asset__c = dummyAsset.Id;
        ipRecords.add(ipRec1);

        Implementation_Profile__c ipRec2 = (Implementation_Profile__c)NSP_TestExtendedDataFactory.createSObject(new Implementation_Profile__c(), 'NSP_TestDataFactory.ImplementationProfileDefaults', false);
        ipRec2.Account__c = testAccount2.Id;
        ipRec2.NSP_Asset__c = dummyAsset1.Id;
        ipRecords.add(ipRec2);

        Implementation_Profile__c ipRec3 = (Implementation_Profile__c)NSP_TestExtendedDataFactory.createSObject(new Implementation_Profile__c(), 'NSP_TestDataFactory.ImplementationProfileDefaults', false);
        ipRec3.Account__c = dummyAccount.Id;
        ipRec3.NSP_Asset__c = dummyAsset.Id;
        ipRecords.add(ipRec3);

        insert ipRecords;
    }

    //Method Name:getIPRecordsFilterBySearchTerm
    @isTest
    static void getIPRecordsFilterByFilters(){
        // GIVEN
        Account acc = [SELECT Id,RecordTypeId FROM Account WHERE Name != null LIMIT 1];
        String jsonInput = '{"searchCategory":"Account__r.Name","searchTerm":"te","preSelectedRecs":"[\\"aA33C0000004asySAA\\",\\"aA33C0000004YuMSAU\\"]","recordTypeId":' + ' "' + acc.RecordTypeId + '"' + '}';

        try{
        // WHEN
        List<NSP_LookupOption> actualResults = NSP_IPSelector.searchRecordsByFilters(jsonInput);

        // THEN
        System.assertEquals(2, actualResults.size(), 'Only 2 results should come.');
        }catch(exception excep){
            System.assert(false, 'Should Not throw Error');
        }
    }

    @isTest
    static void getIPRecordsFilterBySearchTermWhenInputNull(){
        try{
            // WHEN
            NSP_IPSelector.searchRecordsByFilters(null);
            
            // THEN
            System.assert(false, 'Should throw Error');
        }catch(AuraHandledException excep){
            System.assertEquals('null input to JSON parser', excep.getMessage());
        }
    }

    // Add Test method - When search term is dummy
    @isTest
    static void getDummyIPRecordsFilterBySearchTerm(){
        // GIVEN
        Account acc = [SELECT Id,RecordTypeId FROM Account WHERE Name != null LIMIT 1];
        String jsonInput = '{"searchCategory":"Account__r.Name","searchTerm":"Dummy Account","preSelectedRecs":"[ ]","recordTypeId":' + ' "'+ acc.RecordTypeId+ '"' + '}';

        try{
            // WHEN
            List<NSP_LookupOption> actualResults = NSP_IPSelector.searchRecordsByFilters(jsonInput);
            
            // THEN
            System.assertEquals(1, actualResults.size(), 'Only 1 results should come.');
        }catch(exception excep){
            // THEN
            System.assert(false, 'Should Not throw Error');
        }
    }

    // Add Test method - When search category is assignmentNotes.
    @isTest
    static void getIPRecordsFilterForAssignmentNotesBySearchTerm(){
        // GIVEN
        Implementation_Profile__c impProfileObj = [SELECT Id, Name, RecordTypeId FROM Implementation_Profile__c WHERE Id != null LIMIT 1];
        String jsonInput = '{"searchCategory":"Name","searchTerm":"' + impProfileObj.Name +'","preSelectedRecs":"[ ]","recordTypeId":' + ' "'+ impProfileObj.RecordTypeId+ '"' + '}';

        try{
            // WHEN
            List<NSP_LookupOption> actualResults = NSP_IPSelector.searchRecordsByFilters(jsonInput);
            
            // THEN
            System.assertEquals(1, actualResults.size(), 'Only 1 result should come.');
        }catch(exception excep){
            System.assert(false, 'Should Not throw Error');
        }
    }

    // When there is some value in preSelected records
    @isTest
    static void getIPRecordsFilterForPreSelectedRecordBySearchTerm(){
        // GIVEN
        String jsonInput = '{"searchCategory":"Account__r.Name","searchTerm":"te","preSelectedRecs":"[\\"aA33C0000004asySAA\\",\\"aA33C0000004YuMSAU\\"]"}';

        try{
            // WHEN
            List<NSP_LookupOption> actualResults = NSP_IPSelector.searchRecordsByFilters(jsonInput);
            
            // THEN
            System.assertEquals(2, actualResults.size(), 'Only 2 results should come.');
        }
        catch(exception excep){
            // THEN
            System.assert(false, 'Should Not throw Error');
        }
    }

     // When there is some value in record Type
     @isTest
     static void getIPRecordsFilterForRecordTypeBySearchTerm(){
         // GIVEN
         Account acc = [SELECT Id,RecordTypeId FROM Account WHERE Name != null LIMIT 1];
         String jsonInput = '{"searchCategory":"Account__r.Name","searchTerm":"te","preSelectedRecs":"[ ]","recordTypeId":' + ' "'+ acc.RecordTypeId+ '"' + '}';
                 
         try{
            // WHEN
            List<NSP_LookupOption> actualResults = NSP_IPSelector.searchRecordsByFilters(jsonInput);
            
            // THEN
            System.assertEquals(2, actualResults.size(), 'Only 2 results should come.');
         }
         catch(exception excep){
            System.assert(false, 'Should Not throw Error');
         }
     }

    @isTest
    static void getIPRecordById(){
        //GIVEN
        Asset assRec = [SELECT Id FROM Asset WHERE NSP_Client__c = 'null' LIMIT 1];
        Account accRec = [SELECT Id FROM Account WHERE Name = 'Dummy Account' LIMIT 1];
        Implementation_Profile__c ipRec = [SELECT Id FROM Implementation_Profile__c WHERE Account__c =: accRec.Id AND  NSP_Asset__c =: assRec.Id];
    
        List<String> fieldsString = new List<String>{'Id', 'NSP_AIMS_ClientNo__c'};

        //WHEN
        Implementation_Profile__c resultedIpRecs = NSP_IPSelector.getRecordById(ipRec.Id, fieldsString);

        //THEN
        System.assertEquals(ipRec.Id, resultedIpRecs.Id);        
    }

     // test method to get record When Input Id is Null
     @isTest
     static void getIPRecordWhenInputIdIsNull(){
        //GIVEN
        List<String> fieldsString = new List<String>{'Id', 'NSP_AIMS_ClientNo__c'};

        //WHEN
        Implementation_Profile__c resultedIpRecs = NSP_IPSelector.getRecordById(null, fieldsString);

        //THEN
        System.assertEquals(null, resultedIpRecs);
    }
}