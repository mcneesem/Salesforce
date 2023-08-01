/**
Apex Class Name      :   NSP_AccountTerminationBatch_Test
Version              :  1.0                                                                          
Created Date         :   7/25/2022   
Function             :  This class is used as a test class to NSP_AccountTerminationBatch
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Bindu                     8/23/2022            First Iteration
*/

@isTest(SeeAllData=false)
public class NSP_AccountTerminationBatch_Test {
    public static final String OPP_TYPE = 'CAMS';
    private static final List<String> ASSET_FIELDS = new List<String>{
        'Id',
        'Status'   
    };
    @testSetup
    static void setupTestData(){
        
        //Account creation
        Account accRecord = NSP_TestHelper.createAccount(true);
        List<Asset> assetList = new List<Asset>();
        //Create Asset
        Asset assetObj = new Asset();
        assetObj.accountId = accRecord.Id;
        assetObj.NSP_Client__c = 'asset1';
        assetObj.name = 'asset1';
        assetObj.Status = 'Terminated';
        assetObj.NSP_Termination_Date__c = system.today()-31;
        assetList.add(assetObj);
        //Create Asset
        Asset assetObj1 = new Asset();
        assetObj1.accountId = accRecord.Id;
        assetObj1.NSP_Client__c = 'asset2';
        assetObj1.name = 'asset2';
        assetObj1.Status = 'Terminated';
        assetList.add(assetObj1);
        insert assetList;
        
        Opportunity  opportuniytObject = NSP_TestHelper.createOpenOpportunity(accRecord.Id, OPP_TYPE, false);
        opportuniytObject.NSP_PrimaryProduct__c = 'WX';
        opportuniytObject.NSP_Number_of_Employees__c = 100;
        insert opportuniytObject;
        
        Opportunity  opportuniytObject1 = NSP_TestHelper.createOpenOpportunity(accRecord.Id, OPP_TYPE, false);
        opportuniytObject1.StageName = NSP_ServiceConstants.CLOSED_WON;
        opportuniytObject1.NSP_PrimaryProduct__c = 'WX';
        opportuniytObject1.NSP_Number_of_Employees__c = 100;
        insert opportuniytObject1;
    }
    
    @isTest
    static void terminateAccount(){
        try{
            test.startTest();
            NSP_AccountTerminationBatch batchSch = new NSP_AccountTerminationBatch();
            Database.executeBatch(batchSch, 100);
            batchSch.execute(null);
            test.stopTest();
            String query1 = new NSP_QueryBuilder('Asset', ASSET_FIELDS)
                           .addFilter('Name', 'asset1' ).addLimit(1).build();
            Asset asst = Database.query( query1 );

            system.assertEquals('Terminated' , asst.Status);
        } catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
    }
 
   
}