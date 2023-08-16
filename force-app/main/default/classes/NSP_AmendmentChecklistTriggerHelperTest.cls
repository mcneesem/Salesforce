/**
Apex Class Name      :  NSP_AmendmentChecklistTriggerHelperTest
Version              :  1.0                                                                          
Created Date         :  9/21/2022  
Function             :  Represents test class for NSP_AmendmentChecklistTriggerHelper class
Story                :  STY-02109                                                                    
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Abhishek Kumar              8/24/2022             First Iteration
*/

@isTest
public class NSP_AmendmentChecklistTriggerHelperTest {
    /***********************************************************************************************
    * MethodName: setUpData
    * Description : Setting the Test Data
    * ********************************************************************************************/
    @testSetup
    public static void setUpData(){

        //Get Record type Id of Retirement_Services
        Id AssetRecordTypeId  = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.RET_CHOICE_ASSET_RECORDTYPE);

        User testUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', true);
        
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
    * MethodName: updateSubplanNumberonAmendmentChecklistTest
    * Description : Unit test for updateSubplanNumberonAmendmentChecklist 
    * ********************************************************************************************/
    @isTest
    public static void updateSubplanNumberonAmendmentChecklistTest(){
        
        //get List of Asset created in test setup
        Asset  assetRecHavingClientSubplanHis = [SELECT Id , Name, NSP_Client__c
                                        FROM Asset 
                                        WHERE NSP_Client__c = 'asset1' LIMIT 1 ];
        
        User testUser = [SELECT id FROM User WHERE Id != null LIMIT 1];

        //Given
        
        String expectedErrorMessage = 'Please Add required field value in the Amendment Checklist Object.';
        //create Amendment Checklist Record
        NSP_Amendment_Checklist__c amendmentChecklistRec = new NSP_Amendment_Checklist__c();
        amendmentChecklistRec.NSP_Asset__c = assetRecHavingClientSubplanHis.Id;
        amendmentChecklistRec.NSP_Effective_Date_Consultant__c = Date.newInstance(2016, 12, 9);
        amendmentChecklistRec.NSP_By_Consultant__c = testUser.Id;
        
        try{
            Test.startTest();
            //When
            //Inserting amendmentChecklistRec
            insert amendmentChecklistRec;

            Test.stopTest();

            //Then
            System.assertEquals(null, amendmentChecklistRec.NSP_Subplan_Number__c,'Amendment Checklist Rec Subplan Number got updated ');
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }    
    }

    /***********************************************************************************************
    * MethodName: updateAssetonAmendmentChecklistTest
    * Description : test the updating of Asset on Amendment Checklist
    * ********************************************************************************************/
    @isTest
    public static void updateAssetonAmendmentChecklistTest(){
        
        //get List of Asset created in test setup
        List< Asset >  listOfCreatedassetRec = [SELECT Name, NSP_Client__c
                                    FROM Asset 
                                    WHERE NSP_Client__c = 'asset1' 
                                    OR NSP_Client__c = 'assetNotLinkedWithClientSubPlanHis'  LIMIT 2 ];

        Asset assetRecHavingClientSubplanHis = new Asset();
        Asset assetRecNotHavingClientSubplanHis = new Asset();

        for( Asset eachCreatedAssetRec : listOfCreatedassetRec ){

            //check if asset name is 'assetLinkedWithClientSubPlanHis' 
            if( eachCreatedAssetRec.NSP_Client__c == 'asset1' ){
                assetRecHavingClientSubplanHis = eachCreatedAssetRec;
            }

            //check if asset name is 'assetNotLinkedWithClientSubPlanHis' 
            if( eachCreatedAssetRec.NSP_Client__c == 'assetNotLinkedWithClientSubPlanHis' ){
                assetRecNotHavingClientSubplanHis = eachCreatedAssetRec;
            }
        }

        //Given
        //create Amendment Checklist Record
        NSP_Amendment_Checklist__c amendmentChecklistRec = new NSP_Amendment_Checklist__c();
        amendmentChecklistRec.NSP_Asset__c = assetRecHavingClientSubplanHis.Id;
        amendmentChecklistRec.NSP_Effective_Date_Consultant__c = Date.newInstance(2016, 12, 9);
        insert amendmentChecklistRec;
        //update asset on Amendment Checklist with no client subplan History
        amendmentChecklistRec.NSP_Asset__c = assetRecNotHavingClientSubplanHis.Id;
        amendmentChecklistRec.NSP_By_Consultant__c =null;


        try{
            Test.startTest();
            //When
            update amendmentChecklistRec;

            Test.stopTest();

            //Then
            System.assertEquals(null, amendmentChecklistRec.NSP_Subplan_Number__c,'Amendment Checklist Rec Subplan Number got removed ');
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }     
    }
}