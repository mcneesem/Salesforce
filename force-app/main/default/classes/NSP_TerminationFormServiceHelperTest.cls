/**
Apex Class Name      :  NSP_TerminationFormServiceHelperTest
Version              :  1.0                                                                          
Created Date         :  10/21/2022  
Author               :  Bindushree  
Function             :  This class is used as a test class to NSP_TerminationFormServiceHelperTest
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Bindushree                 10/21/2022          First Iteration
*/

@isTest
public class NSP_TerminationFormServiceHelperTest {
    
    
    public static final Id WO_ASSET = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.WO_ASSET_RECORDTYPE );
    public static final Id CLIENT_REINSTATE = NSP_GenericRecordType.getRecordTypeId('NSP_Termination_Form__c',NSP_ServiceConstants.CLIENT_REINSTATE );
    
    
    @testSetup
    static void testData() {
        
        //Account creation
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', true);
        oAccount.NSP_AIMS_Client__c='142';
        update oAccount;
        
        //Inserting Project
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.pse__Account__c =oAccount.Id;
        insert oProject;
        
        //Inserting Project Task
        List<string> peoTerminationTaskList = System.Label.PEO_Termination_Tasks.split(';');
        String TERMINATIONCHECKLIST = null;
        if(peoTerminationTaskList != null && !peoTerminationTaskList.isEmpty()){
            TERMINATIONCHECKLIST = peoTerminationTaskList[2];
        }
        pse__Project_Task__c oProjectTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask.pse__Project__c = oProject.Id;
        oProjectTask.Name = TERMINATIONCHECKLIST;
        insert oProjectTask;
        
        //Client reinstate termination form record creation
        NSP_Termination_Form__c oTerminationForm = (NSP_Termination_Form__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Termination_Form__c(), 'NSP_TestDataFactory.TerminationFormDefaults', false);
        oTerminationForm.recordTypeId=CLIENT_REINSTATE;
        oTerminationForm.NSP_Status__c= 'PR Supervisor Approved';
        oTerminationForm.NSP_Project_Task__c = oProjectTask.Id;
        insert oTerminationForm;
        
        //Asset record creation
        Asset woAsset = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        woAsset.RecordTypeId=WO_ASSET;
        woAsset.NSP_Client__c='142';
        woAsset.NSP_Anticipated_Date_Of_Termination__c=Date.newInstance(2022, 11, 17);
        woAsset.NSP_Reason_for_Term__c='test';
        woAsset.NSP_Verbal_Term_recd__c=true;
        woAsset.NSP_Written_Term_recd__c=true;
        woAsset.NSP_Verbal_Term_recd__c=true;
        insert woAsset;
    }
    
    @isTest
    public static void updateAssetTerminationForm(){
        NSP_Termination_Form__c termForm = [SELECT Id,NSP_Status__c,NSP_Client__c FROM NSP_Termination_Form__c WHERE Id != null LIMIT 1];
        termForm.NSP_Status__c=NSP_ServiceConstants.TERM_TEAM_APPROVED;
        
        Test.startTest();
        update termForm;
        Test.stopTest();
        System.assertEquals('142', termForm.NSP_Client__c);   
    }
}