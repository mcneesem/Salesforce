/**
Apex Class Name      :  NSP_sObjectSelectorTest
Version              :  1.0                                                                         
Created Date         :  11/3/2022
Function             :  This class is used as a test class to NSP_sObjectSelector
Story                :                                                                      
*/
@isTest
private class NSP_sObjectSelectorTest {
    private static final String OBJECT_NAME = 'Account';
    private static List<String> FIELDS = new List<String>{'Id', 'BillingState'};
    private static String CALIFORNIA = 'California';

    @TestSetup
    static void makeDataForselectingSObject(){
        //creating Account
        List<Account> lstAccounts = new List<Account>();
        Account acc1 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acc1.Name = 'Test New Account 1';
        lstAccounts.add(acc1);
        Account acc2 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acc2.Name = 'Test New Account 2';
        acc2.BillingState =  'Washington' ;
        lstAccounts.add(acc2);
        Account acc3 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acc3.Name = 'Test New Account 3';
        acc3.BillingState =  CALIFORNIA;
        lstAccounts.add(acc3);
        insert lstAccounts;
       
        // Creating Group
        List<Group> lstGroups = new List<Group>();
        Group grp1 = (Group)NSP_TestExtendedDataFactory.createSObject(new Group(), 'NSP_TestDataFactory.GroupDefaults', false);
        grp1.Type = 'Queue';
        lstGroups.add(grp1);
        Group grp2 = (Group)NSP_TestExtendedDataFactory.createSObject(new Group(), 'NSP_TestDataFactory.GroupDefaults', false);
        grp2.Type = 'Queue';
        grp2.DeveloperName = 'BPS_Service_User';
        lstGroups.add(grp2);
        Group grp3 = (Group)NSP_TestExtendedDataFactory.createSObject(new Group(), 'NSP_TestDataFactory.GroupDefaults', false);
        grp3.Type = 'Queue';
        grp3.DeveloperName = 'Customer_Success_Team';
        lstGroups.add(grp3);
        insert lstGroups;
    }
    /*Method Name: selectingSObjectById
     Description : This Method is used to check the Account records when Record Id is passed
    */
    @isTest
    static void selectingSObjectById(){
        //GIVEN
        Account expAccRecord = [SELECT Id, Name, BillingState, BillingCountry 
                                                      FROM Account
                                                      WHERE BillingState = 'Texas'
                                                      LIMIT 1] ;
        
        //WHEN
        Account actualAccRecord = (Account) new NSP_sObjectSelector(OBJECT_NAME,FIELDS).selectById(expAccRecord.Id);
        
        //THEN
        System.assertNotEquals(null,actualAccRecord);
        system.assertEquals(expAccRecord.BillingState, actualAccRecord.BillingState);
    }
    /*Method Name: selectingSObjectWhenIdNull
     Description : This Method is used to check the Account Records when Record Id is null
    */
    @isTest
    static void selectingSObjectWhenIdNull(){
        //GIVEN , WHEN
        String recId = null;
        Account accRec = (Account) new NSP_sObjectSelector(OBJECT_NAME,FIELDS).selectById(recId);

        //THEN
        system.assertEquals(null, accRec);

    }
     /*Method Name: selectingSObjectWhenListOfIdsAreNull
     Description : This Method is used to check the Account Records when null Ids are passed
    */
    @isTest
    static void selectingSObjectWhenListOfIdsAreNull(){
        //GIVEN , WHEN
        List<String> recIds = null;
        List<Account>  accRecords = (List<Account>) new NSP_sObjectSelector(OBJECT_NAME,FIELDS).selectById(recIds);
       
        //THEN
        system.assertEquals(true, accRecords.isEmpty());
    }

     /*Method Name: selectingSObjectWhenListOfEmptyRecordIds
     Description : This Method is used to check the Account Records When Empty record Ids list is passed
    */
    @isTest
    static void selectingSObjectWhenListOfEmptyRecordIds(){
        //GIVEN , WHEN
        List<String> recIds = new List<String>();
        List<Account>  accRecords = (List<Account>) new NSP_sObjectSelector(OBJECT_NAME,FIELDS).selectById(recIds);
       
        //THEN
        system.assert(accRecords.isEmpty());
    }
    /*Method Name: selectingSObjectWhenListOfIds
     Description : This Method is used to check the records when List of Ids is passed as Input
    */
    @isTest
    static void selectingSObjectByListOfIds(){
        //GIVEN
        List<Account> expAccRecord = [SELECT Id 
                                       FROM Account
                                       WHERE Name IN ('Test New Account 1','Test New Account 2') 
                                       LIMIT 2];
        List<String> accRecordIds = new List<String>();
                for(Account acc: expAccRecord){
                    accRecordIds.add(acc.Id);
                    }
        //WHEN
        List<Account>  actualAccRecords = (List<Account>) new NSP_sObjectSelector('Account').selectById(accRecordIds);
        //THEN
        System.assertEquals(2, actualAccRecords.size(), 'Only 2 Account Records should come.');
    }
    /*Method Name: selectingSObjectByRecordTypeName
     Description : This Method is used to check the Records when Record Type Name is Passed
    */
    @isTest
    static void selectingSObjectByRecordTypeName(){
        //GIVEN ,WHEN
        List<Account> expAccRecord = [SELECT Id, Name,
                                        BillingState 
                                        FROM Account
                                        WHERE Name IN ('Test New Account 1','Test New Account 2')
                                        LIMIT 2
                                        ] ;
  
        NSP_sObjectSelector selector = new NSP_sObjectSelector(OBJECT_NAME,FIELDS);
        selector.addlimit(2);
        List<Account>  actualAccRecords = (List<Account>) selector.selectByRecordTypeName('NSP_Client');
     
        //THEN
        
        System.assertEquals(expAccRecord[0].BillingState, actualAccRecords[0].BillingState);
        System.assertNotEquals(CALIFORNIA, actualAccRecords[0].BillingState);
        System.assertEquals(expAccRecord[1].BillingState, actualAccRecords[1].BillingState);
        System.assertNotEquals(CALIFORNIA, actualAccRecords[1].BillingState);
        
        
    }
    /*
    Method Name: selectingSObjectByRecordTypeId
    Description: This method is used to check Account Records  when Record Type Id is passed
    */
    @isTest
    static void selectingSObjectByRecordTypeId(){
        //GIVEN
        List<Account> expAccRecord = [SELECT Id, Name,
                                        BillingState,
                                        RecordTypeId
                                        FROM Account
                                        WHERE Name IN ('Test New Account 1','Test New Account 2')
                                        LIMIT 2
                                        ] ;
        
        //WHEN
        NSP_sObjectSelector selector = new NSP_sObjectSelector(OBJECT_NAME,FIELDS);
        selector.addlimit(2);
        List<Account>  actualAccRecords = (List<Account>) selector.selectByRecordTypeId(expAccRecord[0].RecordTypeId);

        //THEN
        System.assertEquals(2, actualAccRecords.size(), 'Only 2 Account Records should come.');
        System.assertEquals(expAccRecord[0].BillingState, actualAccRecords[0].BillingState);
        System.assertNotEquals(CALIFORNIA, actualAccRecords[0].BillingState);
    }
    /*
    Method Name: selectingGroupByTypeAndApiName
    Description: This method is used to check the Group Records  when Type and Field API Names are passed 
    */
    @isTest
    static void selectingGroupByTypeAndApiName(){
      //GIVEN
      List<Group> expGroupRecords = [SELECT Id, Name, DeveloperName, Type
                            FROM Group
                            WHERE Name = 'Contact Center' LIMIT 2];

      List<String> fields = new List<String>{'Id', 'Name', 'Type','DeveloperName'};
      //WHEN
      List<Group> actualGrpRecords = NSP_sObjectSelector.selectGroupsByTypeAndApiName(expGroupRecords[0].Type,expGroupRecords[0].DeveloperName,fields, 1);
        actualGrpRecords.addAll(NSP_sObjectSelector.selectGroupsByTypeAndApiName(expGroupRecords[1].Type,expGroupRecords[1].DeveloperName,fields, 1));
        
        //THEN
      System.assertEquals(2, actualGrpRecords.size(), 'Only 2 group records should come.');
      System.assertEquals(expGroupRecords[0].Type, actualGrpRecords[0].Type);
      System.assertNotEquals('Customer_Success_Team', actualGrpRecords[0].DeveloperName);
      System.assertEquals(expGroupRecords[1].Type, actualGrpRecords[1].Type); 

    }

      /*
    Method Name: selectByNameTest
    Description: This method is used to check the selectByName Method
    */
    
    @isTest
    static void selectByNameTest(){
    List<Account> getTestAccounts = [SELECT Id, Name
                            FROM Account
                            WHERE Name = 'Test New Account 1'];
        List<Account>  assertAccounts = new NSP_sObjectSelector('Account').selectByName('Test New Account 1');
        system.assertEquals(getTestAccounts.size(), assertAccounts.size());
        
    }

}