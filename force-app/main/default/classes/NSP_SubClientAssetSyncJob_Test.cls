/**
Apex Class Name      :  NSP_SubClientAssetSyncJob
Version              :  1.0 
Author               :  Virendra Kumar                                                                          
Created Date         :  06/01/22 
Function             :  Represents test class for NSP_AccountRegulatedAreaBatch class
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Virendra                  10/20/2022                First Iteration
*/

@isTest(SeeAllData=false) private class NSP_SubClientAssetSyncJob_Test {

    @testSetup private static void createTestData() {

        //Account creation 
        Account acc = new Account();
        acc.Name = 'Test Acc';
        insert acc;
        
        //Contact creation 
        Contact con = new Contact();
        con.AccountId = acc.Id ;
        con.LastName = 'Test con';
        insert con;
        
        //Asset creation 
        Asset asset = new Asset();
        asset.Name = 'Test Asset' ;
        asset.ContactId = con.Id ;
        asset.AccountId = acc.Id ;
        insert asset;
        
        //NSP_Sub_Client__c creation 
        NSP_Sub_Client__c subClient = new NSP_Sub_Client__c();
        subClient.NSP_Account__c = acc.Id;
        subClient.NSP_Asset__c = asset.Id ;
        subClient.Name = 'Test Sub Client';
        insert subClient ;
        
        //NSP_Sub_Client_Contact__c creation 
        NSP_Sub_Client_Contact__c subClientCon = new NSP_Sub_Client_Contact__c();
        subClientCon.NSP_Sub_Client__c = subClient.Id;
        subClientCon.NSP_Paid_Non_Paid__c = 'Paid WSEE';
        subClientCon.NSP_Employee_Status__c = 'HIRED';
        subClientCon.NSP_Union_Employee__c = false;
        insert subClientCon ;
        
        //NSP_Address__c creation 
        NSP_Address__c address = new NSP_Address__c();
        address.Name = 'Test Add';
        address.NSP_Related_Site__c = acc.Id;
        address.NSP_Legal_Name__c = 'Billing';
        address.NSP_Street__c = 'Test Address AZ';
        address.NSP_Country__c = 'United States';
        address.NSP_State__c = 'AZ';
        address.NSP_Postal_Code__c = '12345';
        address.NSP_Source__c = 'AIMS';
        address.NSP_Address_Type__c = 'Worksite';
        insert address;
        
        //NSP_Sub_Client_Contact_Address__c creation 
        NSP_Sub_Client_Contact_Address__c subClientConAdd = New NSP_Sub_Client_Contact_Address__c();
        subClientConAdd.Name = 'Test';
        subClientConAdd.NSP_Address__c = address.Id;
        subClientConAdd.NSP_Sub_Client_Contact__c = subClientCon.Id;
        insert subClientConAdd ;
        
         //NSP_Sub_Client_Contact_Address__c creation 
        NSP_Sub_Client_Contact_Address__c subClientConAdd1 = New NSP_Sub_Client_Contact_Address__c();
        subClientConAdd1.Name = 'Test';
        subClientConAdd1.NSP_Address__c = address.Id;
        subClientConAdd1.NSP_Sub_Client_Contact__c = subClientCon.Id;
        insert subClientConAdd1 ;
        
        //NSP_Sub_Client_Contact__History creation 
        NSP_Sub_Client_Contact__History instSCCH = New NSP_Sub_Client_Contact__History();
        instSCCH.ParentId = subClientCon.Id;
        instSCCH.Field = 'NSP_Paid_Non_Paid__c';
        insert instSCCH;
        
        //NSP_Sub_Client_Contact__History creation 
        NSP_Sub_Client_Contact_Address__History instSCCAH = New NSP_Sub_Client_Contact_Address__History();
        instSCCAH.ParentId = subClientConAdd1.Id;
        instSCCAH.Field = 'NSP_Address_State_Changed_Date__c';
        insert instSCCAH;
    }

    @isTest private static void shouldTestSubClientAssetSyncJob() {

        Test.startTest();
        
        //Update NSP_Sub_Client_Contact__c
        NSP_Sub_Client_Contact__c subClientCon =[SELECT Id, NSP_Sub_Client__c, NSP_Employee_Status__c, NSP_Paid_Non_Paid__c, NSP_Union_Employee__c
                                                 FROM NSP_Sub_Client_Contact__c WHERE Id!= NULL Limit 1];
        subClientCon.NSP_Paid_Non_Paid__c = 'Paid WSEE';
        subClientCon.NSP_Employee_Status__c = 'HIRED';
        subClientCon.NSP_Union_Employee__c = true;
        update subClientCon;
        
        NSP_Sub_Client_Contact_Address__c subClientConA =[SELECT Id, NSP_Address_State_Changed_Date__c FROM NSP_Sub_Client_Contact_Address__c WHERE Id!= NULL Limit 1];
        subClientConA.NSP_Address_State_Changed_Date__c = System.today();
        update subClientConA;
        
        // Call Batch Class 
        NSP_SubClientAssetSyncJob subClientCont = new NSP_SubClientAssetSyncJob();
        DataBase.executeBatch(subClientCont);
        
        // Call Batch Class 
        NSP_SubClientAssetStateSyncJob subClientContA = new NSP_SubClientAssetStateSyncJob();
        DataBase.executeBatch(subClientContA);
        Test.stopTest();
        
        NSP_Sub_Client_Contact__History scchUpdated = [SELECT Id, OldValue, NewValue, Field, ParentId, Parent.NSP_Sub_Client__r.NSP_Union_Employees__c, 
                                                       DataType FROM NSP_Sub_Client_Contact__History  WHERE Id!= NULL LIMIT 1];
        System.assert(scchUpdated.Parent.NSP_Sub_Client__r.NSP_Union_Employees__c = true);

        // added for code coverage in 09-Aug RC2 release...
        List<NSP_Sub_Client__c> records = [
            SELECT Id , NSP_Asset__c
            FROM NSP_Sub_Client__c
            WHERE ( Id = :subClientCon.NSP_Sub_Client__c )
        ];
        Set<Id> assetIds = new Set<Id>();
        for ( NSP_Sub_Client__c record : records ) {
            assetIds.add( record.NSP_Asset__c );
        }
        NSP_SubClientAssetStateSyncJob.testUpdateStateOfOperation(
            new List<NSP_Sub_Client_Contact__c>{ subClientCon } ,
            new Map<Id,NSP_Sub_Client__c>( records ) ,
            assetIds
        );
    }

}
//