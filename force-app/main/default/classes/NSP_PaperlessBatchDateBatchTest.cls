@isTest
public class NSP_PaperlessBatchDateBatchTest {
    
    @TestSetup
    public static void creatTestData() {
        
        Account accIns = New Account ();
        accIns.Name = 'Test';
        accIns.Phone = '11223344';
        insert accIns; 
        
        Contact conIns = New Contact();
        conIns.LastName = 'Tset2';
        conIns.AccountId = accIns.Id;
        insert conIns;
        
        Id WORecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('WO').getRecordTypeId();
        Asset assetIns = New Asset();
        assetIns.Name = 'Test';
        assetIns.NSP_Company_Name__c = 'Test1';
        assetIns.Status = 'Terminated';
        assetIns.NSP_Service_Package__c = 'WO - Full BUndle';
        assetIns.NSP_Paperless_Batch_Date__c = system.today()-1;
        assetIns.NSP_AIMS_First_Pay_Date__c = system.today()-1;
        assetIns.ContactId = conIns.Id;
        assetIns.AccountId = accIns.Id;
        assetIns.RecordTypeId = WORecordTypeId;
        insert assetIns ; 
        
        NSP_Sub_Client__c SubClientIns = New NSP_Sub_Client__c();
        SubClientIns.Name = 'Test1';
        SubClientIns.NSP_Asset__c = assetIns.Id ;
        SubClientIns.NSP_Account__c = accIns.Id ;
        SubClientIns.NSP_Paperless_Batch_Date__c = system.today()-1;
        insert SubClientIns ;
        
        NSP_Sub_Client_Contact__c subClientContactIns = New NSP_Sub_Client_Contact__c();
        subClientContactIns.NSP_Sub_Client__c= SubClientIns.Id ;
        subClientContactIns.NSP_Work_Phone__c= '55667788' ;
        subClientContactIns.NSP_Employee_Status__c= 'FMLA' ;
        subClientContactIns.NSP_Paid_Non_Paid__c= 'Paid WSEE';
        subClientContactIns.NSP_IsPaperless__c= True; 
        subClientContactIns.NSP_Paperless_Batch_Date__c = system.today()-1;
        insert subClientContactIns ;
        
    }
    
    public static testmethod void shouldTestPaperless() {
        Test.startTest();
        List<NSP_Sub_Client__c> SbCliList =[SELECT Id, Name, NSP_Paperless_Batch_Date__c, NSP_Account__c, NSP_Asset__c FROM NSP_Sub_Client__c WHERE Id != null];
        List<Asset> AssetList =[SELECT Id, AccountId, ContactId, Status, NSP_Service_Package__c, NSP_Company_Name__c FROM Asset WHERE Id != null ];
        List<NSP_Sub_Client_Contact__c> SbCliCnList =[SELECT Id, NSP_Work_Phone__c, NSP_Paperless_Batch_Date__c, NSP_IsPaperless__c, NSP_Employee_Status__c, Name FROM NSP_Sub_Client_Contact__c WHERE Id != null];
        
        SbCliCnList[0].NSP_Paperless_Batch_Date__c = system.Today()-1;
        AssetList[0].NSP_Paperless_Batch_Date__c = system.Today()-1;
        SbCliList[0].NSP_Paperless_Batch_Date__c = system.Today()-1;
        
        update AssetList ;
        update SbCliList ;
        update SbCliCnList ;
        
        NSP_PaperlessBatchDateBatch batchSch = new NSP_PaperlessBatchDateBatch();
        Database.executeBatch(batchSch);
        Test.stopTest();
       Asset updatedAsset = [SELECT Id, NSP_Paperless__c FROM Asset WHERE Name = 'Test' LIMIT 1];
        System.assert(updatedAsset.NSP_Paperless__c == false);
    }
    
    public static testmethod void shouldTestForPaidUserInActive() {
        Test.startTest();
        List<NSP_Sub_Client__c> SbCliList =[SELECT Id, Name, NSP_Account_Status__c, NSP_Paperless_Batch_Date__c, NSP_Account__c, NSP_Asset__c FROM NSP_Sub_Client__c WHERE Id != null];
        List<Asset> AssetList =[SELECT Id, AccountId, ContactId, Status, NSP_Service_Package__c, NSP_Company_Name__c FROM Asset WHERE Id != null ];
        List<NSP_Sub_Client_Contact__c> SbCliCnList =[SELECT Id, NSP_Work_Phone__c, NSP_Paperless_Batch_Date__c, NSP_IsPaperless__c, NSP_Employee_Status__c, Name FROM NSP_Sub_Client_Contact__c WHERE Id != null];
        
        SbCliList[0].NSP_Paperless_Batch_Date__c = system.Today()-1;
        SbCliList[0].NSP_Account_Status__c = 'Inactive' ;
        AssetList[0].NSP_Paperless_Batch_Date__c = system.Today()-1;
        AssetList[0].Status = 'Active';
        SbCliCnList[0].NSP_Paperless_Batch_Date__c = system.Today()-1;
        
        update SbCliList ;
        update AssetList ;
        update SbCliCnList ;
        
        NSP_PaperlessBatchDateBatch batchSch = new NSP_PaperlessBatchDateBatch();
        Database.executeBatch(batchSch);
        Test.stopTest();
        Asset updatedAsset = [SELECT Id, NSP_Paperless__c FROM Asset WHERE Name = 'Test' LIMIT 1];
        System.assert(updatedAsset.NSP_Paperless__c == false);
    }
    
    public static testmethod void shouldTestForPaidUser() {
        Test.startTest();
        List<NSP_Sub_Client__c> SbCliList =[SELECT Id, Name, NSP_Account_Status__c, NSP_Paperless_Batch_Date__c, NSP_Account__c, NSP_Asset__c FROM NSP_Sub_Client__c WHERE Id != null];
        List<Asset> AssetList =[SELECT Id, AccountId, ContactId, Status, NSP_Service_Package__c, NSP_Company_Name__c FROM Asset WHERE Id != null ];
        List<NSP_Sub_Client_Contact__c> SbCliCnList =[SELECT Id, NSP_Work_Phone__c, NSP_Paperless_Batch_Date__c, NSP_IsPaperless__c, NSP_Employee_Status__c, Name FROM NSP_Sub_Client_Contact__c WHERE Id != null];
        
        SbCliList[0].NSP_Paperless_Batch_Date__c = system.Today()-1;
        SbCliList[0].NSP_Account_Status__c = 'Active' ;
        
        AssetList[0].NSP_Paperless_Batch_Date__c = system.Today()-1;
        AssetList[0].Status = 'Active';
        
        SbCliCnList[0].NSP_Paperless_Batch_Date__c = system.Today()-1;
        SbCliCnList[0].NSP_Paid_Non_Paid__c = 'Paid WSEE';
        SbCliCnList[0].NSP_Employee_Status__c = 'PRIMED';
        SbCliCnList[0].NSP_IsPaperless__c = true;
            
        update SbCliList ;
        update AssetList ;
        update SbCliCnList ;
        
        NSP_PaperlessBatchDateBatch batchSch = new NSP_PaperlessBatchDateBatch();
        Database.executeBatch(batchSch);
        Test.stopTest();
        Asset updatedAsset = [SELECT Id, NSP_Paperless__c FROM Asset WHERE Name = 'Test' LIMIT 1];
        System.assert(updatedAsset.NSP_Paperless__c == true);
    }
    
     public static testmethod void shouldTestForNonPaidUserWithPaperless() {
        Test.startTest();
        List<NSP_Sub_Client__c> SbCliList =[SELECT Id, Name, NSP_Account_Status__c, NSP_Paperless_Batch_Date__c, NSP_Account__c, NSP_Asset__c FROM NSP_Sub_Client__c WHERE Id != null];
        List<Asset> AssetList =[SELECT Id, AccountId, ContactId, Status, NSP_Service_Package__c, NSP_Company_Name__c FROM Asset WHERE Id != null];
        List<NSP_Sub_Client_Contact__c> SbCliCnList =[SELECT Id, NSP_Work_Phone__c, NSP_Paperless_Batch_Date__c, NSP_IsPaperless__c, NSP_Employee_Status__c, Name FROM NSP_Sub_Client_Contact__c WHERE Id != null];
        
        SbCliList[0].NSP_Paperless_Batch_Date__c = system.Today()-1;
        SbCliList[0].NSP_Account_Status__c = 'Active' ;
        
        AssetList[0].NSP_Paperless_Batch_Date__c = system.Today()-1;
        AssetList[0].Status = 'Active';
        
        SbCliCnList[0].NSP_Paperless_Batch_Date__c = system.Today()-1;
        SbCliCnList[0].NSP_Paid_Non_Paid__c = 'Active Non-Paid User';
        SbCliCnList[0].NSP_IsPaperless__c = true;
            
        update SbCliList ;
        update AssetList ;
        update SbCliCnList ;
        
        NSP_PaperlessBatchDateBatch batchSch = new NSP_PaperlessBatchDateBatch();
        Database.executeBatch(batchSch);
        Test.stopTest();
        Asset updatedAsset = [SELECT Id, NSP_Paperless__c FROM Asset WHERE Name = 'Test' LIMIT 1];
        System.assert(updatedAsset.NSP_Paperless__c == true);
    }
     public static testmethod void shouldTestForNonPaidUserWithoutPaperless() {
        Test.startTest();
        List<NSP_Sub_Client__c> SbCliList =[SELECT Id, Name, NSP_Account_Status__c, NSP_Paperless_Batch_Date__c, NSP_Account__c, NSP_Asset__c FROM NSP_Sub_Client__c WHERE Id != null];
        List<Asset> AssetList =[SELECT Id, AccountId, ContactId, Status, NSP_Service_Package__c, NSP_Company_Name__c FROM Asset WHERE Id != null ];
        List<NSP_Sub_Client_Contact__c> SbCliCnList =[SELECT Id, NSP_Work_Phone__c, NSP_Paperless_Batch_Date__c, NSP_IsPaperless__c, NSP_Employee_Status__c, Name FROM NSP_Sub_Client_Contact__c WHERE Id !=  null];
        
        SbCliList[0].NSP_Paperless_Batch_Date__c = system.Today()-1;
        SbCliList[0].NSP_Account_Status__c = 'Active' ;
        
        AssetList[0].NSP_Paperless_Batch_Date__c = system.Today()-1;
        AssetList[0].Status = 'Active';
        
        SbCliCnList[0].NSP_Paperless_Batch_Date__c = system.Today()-1;
        SbCliCnList[0].NSP_Paid_Non_Paid__c = 'Active Non-Paid User';
        SbCliCnList[0].NSP_IsPaperless__c = False;
            
        update SbCliList ;
        update AssetList ;
        update SbCliCnList ;
        
        NSP_PaperlessBatchDateBatch batchSch = new NSP_PaperlessBatchDateBatch();
        Database.executeBatch(batchSch);
        Test.stopTest();
        Asset updatedAsset = [SELECT Id, NSP_Paperless__c FROM Asset WHERE Name = 'Test' LIMIT 1];
        System.assert(updatedAsset.NSP_Paperless__c == false);
    }
    
	public static testmethod void shouldTestTerminatedAsset() {
        Test.startTest();
        List<Asset> AssetList =[SELECT Id, AccountId, ContactId, Status, NSP_Service_Package__c, NSP_Company_Name__c FROM Asset WHERE Name = 'Test' LIMIT 1 ];
        
        AssetList[0].NSP_Paperless_Batch_Date__c = system.Today()-1;
        AssetList[0].Status = 'Terminated';
        Update AssetList[0];
        
        NSP_PaperlessBatchDateBatch batchSch = new NSP_PaperlessBatchDateBatch();
        Database.executeBatch(batchSch);
        Test.stopTest();
        Asset updatedAsset = [SELECT Id, NSP_Paperless__c FROM Asset WHERE Name = 'Test' LIMIT 1];
        System.assert(updatedAsset.NSP_Paperless__c == false);
    }
    
    static testMethod void testPaperBatchDateScheduler() {  
        Test.startTest();  
        NSP_PaperlessBatchDateBatch regualtedAreaScheduler = new NSP_PaperlessBatchDateBatch();
        String sch = '0 0 2 * * ?';
        String jobId = System.schedule('Test Regulated Batch', sch, regualtedAreaScheduler);
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(sch, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();     
   }  
}