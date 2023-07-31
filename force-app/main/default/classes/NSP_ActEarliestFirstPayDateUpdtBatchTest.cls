@isTest
public class NSP_ActEarliestFirstPayDateUpdtBatchTest {
    private static final string TEST_ACCOUNT = 'nsp_focus_item__c';
    private static final Id WOASSETRECORDTYPE = NSP_GenericRecordType.getRecordTypeId('Asset', 'WO');
    private static final List<String> ACCOUNT_FIELDS = new List<String>{
        'Id',
        'NSP_Product_First_Pay_Date__c'   
    };
    
    @TestSetup
    static void testDataSetup(){
        User testUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', true);

        //create account record
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        oAccount.Name = TEST_ACCOUNT;
        insert oAccount;

        //create Contact Record
		Contact contactObject = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', true);        
        contactObject.AccountId = oAccount.Id;
        contactObject.lastName= 'Test';
        contactObject.pse__Salesforce_User__c=testUser.Id;
        update contactObject;

        //inserting asset list 
        List<Asset> woAssets = new List<Asset>();
        Asset asst = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        asst.AccountId = oAccount.Id;
        asst.ContactId = contactObject.Id;
        asst.name = 'assetLinked';
        asst.Status='Active';
        asst.NSP_First_Pay_Date__c=Date.today();
        asst.NSP_AIMS_First_Pay_Date__c = Date.today();
        asst.recordTypeId = WOASSETRECORDTYPE;
        woAssets.add(asst);

        Asset asstone = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        asstone.AccountId = oAccount.Id;
        asstone.ContactId = contactObject.Id;
        asstone.name = 'assetLinked1';
        asstone.Status='Active';
        asstone.NSP_First_Pay_Date__c=Date.today();
        asstone.NSP_AIMS_First_Pay_Date__c = Date.today();
        asstone.recordTypeId = WOASSETRECORDTYPE;
        woAssets.add(asstone);

        Database.insert(woAssets);

    }

    //testing when the first pay date is populated
    @isTest
    static void testBatchClass(){
            //Then
            test.startTest();                                                                                              
            NSP_AcntEarliestFirstPayDateUpdateBatch batchSch = new NSP_AcntEarliestFirstPayDateUpdateBatch();
            Database.executeBatch(batchSch, 200);
            batchSch.execute(null);
            test.stopTest(); 

            String query = new NSP_QueryBuilder('Account', ACCOUNT_FIELDS)
                           .addFilter('Name', TEST_ACCOUNT ).addLimit(1).build();
            Account acc = Database.query( query );
            Date dateToday = Date.today();
            system.assertEquals(dateToday , acc.NSP_Product_First_Pay_Date__c);
        
           
        
    }

    //testing when the first pay date is not populated
    @isTest
    static void testBatchClassNeg(){
            //Given
            String query = new NSP_QueryBuilder('Account', ACCOUNT_FIELDS)
                           .addFilter('Name', TEST_ACCOUNT ).addLimit(1).build();
            Account acc = Database.query( query );
            Asset assttwo = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
            assttwo.AccountId = acc.Id;
            assttwo.name = 'assetLinked2';
            assttwo.Status='Active';
            assttwo.NSP_First_Pay_Date__c=null;
            assttwo.recordTypeId = WOASSETRECORDTYPE;
            insert assttwo;

            //When
            test.startTest();                                                                                              
            NSP_AcntEarliestFirstPayDateUpdateBatch batchSch = new NSP_AcntEarliestFirstPayDateUpdateBatch();
            Database.executeBatch(batchSch, 200);
            batchSch.execute(null);
            test.stopTest(); 

            //Then
            String query1 = new NSP_QueryBuilder('Account', ACCOUNT_FIELDS)
                           .addFilter('Name', TEST_ACCOUNT ).addLimit(1).build();
            Account accnt = Database.query( query1 );

            Date dateToday = Date.today();
            system.assertEquals(dateToday , accnt.NSP_Product_First_Pay_Date__c);
        
    }

}