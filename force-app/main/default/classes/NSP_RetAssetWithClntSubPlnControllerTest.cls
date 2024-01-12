/**
Apex Class Name      :  NSP_RetAssetWithClntSubPlnController
Version              :  1.0                                                                          
Created Date         :  10/05/2022  
Function             :  Represents test class for NSP_RetAssetWithClntSubPlnController class
Story                :  STY-02252                                                                    
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Abhishek Kumar             10/05/2022            First Iteration
*/
@isTest
public class NSP_RetAssetWithClntSubPlnControllerTest {


    /***********************************************************************************************
    * MethodName: setAllData
    * Description : Setting the Test Data
    * ********************************************************************************************/
    @TestSetup
    static void setAllData(){

        //Get Record type Id of Retirement_Services
        Id AssetRecordTypeId  = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.RET_CHOICE_ASSET_RECORDTYPE);

        //create Account Record
        Account accoutObject = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        insert accoutObject;


        //create Asset Record
        Asset assetObj1 = (Asset) NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        assetObj1.NSP_Client__c = 'asset1';
        assetObj1.name = 'assetLinkedWithClientSubPlanHis';
        assetObj1.RecordTypeId = AssetRecordTypeId;
        insert assetObj1;  

        //create Asset Record
        Asset assetObj2 = (Asset) NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        assetObj2.NSP_Client__c = 'assetNotLinkedWithClientSubPlanHis';
        assetObj2.name = 'asset2';
        assetObj2.RecordTypeId = AssetRecordTypeId;
        insert assetObj2;

        //create Plan Record
        NSP_Plan__c planRec = new NSP_Plan__c();
        insert planRec;

        //create Plan Sub Plan Record
        NSP_Plan_SubPlan__c planSubplanRec = new NSP_Plan_SubPlan__c();
        planSubplanRec.NSP_Parent_Plan_ID__c = planRec.Id;
        planSubplanRec.NSP_Subplan_ID__c = '123';
        insert planSubplanRec;

        //create Client Sub Plan Record
        NSP_Client_Sub_Plan_History__c clientSubPlanHisRec = new NSP_Client_Sub_Plan_History__c();
        clientSubPlanHisRec.NSP_Asset__c = assetObj1.Id;
        clientSubPlanHisRec.NSP_Plan_Subplan_Relationship__c = 	planSubplanRec.Id;
        clientSubPlanHisRec.NSP_Start_Date__c = Date.newInstance(2016, 12, 9);
        insert clientSubPlanHisRec;  
        
    }

    /***********************************************************************************************
    * MethodName: isClientSubPlanAssociatedWithAssetTest
    * Description : Unit test for isClientSubPlanAssociatedWithAsset 
    * ********************************************************************************************/
    @isTest
    public static void isClientSubPlanAssociatedWithAssetTest(){
        
        List< Asset >  listOfCreatedassetRec = [SELECT Name
                                    FROM Asset 
                                    WHERE Name = 'assetLinkedWithClientSubPlanHis' 
                                    OR Name = 'assetNotLinkedWithClientSubPlanHis'  LIMIT 2 ];

        Asset assetRecHavingClientSubplanHis = new Asset();
        Asset assetRecNotHavingClientSubplanHis = new Asset();

        for( Asset eachCreatedAssetRec : listOfCreatedassetRec ){

            //check if asset name is 'assetLinkedWithClientSubPlanHis' 
            if( eachCreatedAssetRec.Name == 'assetLinkedWithClientSubPlanHis' ){
                assetRecHavingClientSubplanHis = eachCreatedAssetRec;
            }

            //check if asset name is 'assetNotLinkedWithClientSubPlanHis' 
            if( eachCreatedAssetRec.Name == 'assetNotLinkedWithClientSubPlanHis' ){
                assetRecNotHavingClientSubplanHis = eachCreatedAssetRec;
            }
        }

        //Given
        
        
        try{
            Test.startTest();
            //When
            //Inserting amendmentChecklistRec
            Boolean isAssociated = NSP_RetAssetWithClntSubPlnController.isClientSubPlanAssociatedWithAsset(assetRecHavingClientSubplanHis.Id);

            Test.stopTest();
            //Then
            System.assertEquals(true, isAssociated);
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }   
    }

    /***********************************************************************************************
    * MethodName: getRecordTypeIdByNameTest
    * Description : Unit test for getRecordTypeIdByName 
    * ********************************************************************************************/
    @isTest
    public static void getRecordTypeIdByNameTest(){
        //Given
        Id recTypeFromGenricMethod = NSP_GenericRecordType.getRecordTypeId('NSP_Client_Sub_Plan_History__c', 'Choice');
        //When
        Test.startTest();
        Id recTypeId = NSP_RetAssetWithClntSubPlnController.getRecordTypeIdByName('NSP_Client_Sub_Plan_History__c', 'Choice');
        Test.stopTest();
        //Then
        System.assertEquals(recTypeFromGenricMethod, recTypeId);
        
    }

}