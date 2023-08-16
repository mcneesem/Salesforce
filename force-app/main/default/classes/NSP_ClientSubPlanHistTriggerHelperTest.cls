/**
Apex Class Name      :  NSP_ClientSubPlanHistTriggerHelperTest for NSP_ClientSubPlanHistTriggerHelper
Version              :  1.0                                                                          
Created Date         :  10/14/2022   
Function             :  Test class for NSP_ClientSubPlanHistTriggerHelper 
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Srushti                     10/14/2022            First Iteration
*/


@isTest
public class NSP_ClientSubPlanHistTriggerHelperTest {
    public static final Id CHOICECLIENTSUBPLANRECORDTYPEID = NSP_GenericRecordType.getRecordTypeId('NSP_Client_Sub_Plan_History__c', 'Choice');
	public static final Id RETSERVICESASSETRECORDTYPEID = NSP_GenericRecordType.getRecordTypeId('Asset', 'Recruiting_Services');
       
    @testSetup
    public static void setUpTestData(){
		Id choicePlanSubPlanRecordTypeId = NSP_GenericRecordType.getRecordTypeId('NSP_Plan_SubPlan__c', 'Choice');
    	Id choicePlanRecordTypeId = NSP_GenericRecordType.getRecordTypeId('NSP_Plan__c', 'Choice');
 
        //Creat a new Asset Record
        Asset newAsset = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        newAsset.RecordTypeId = RETSERVICESASSETRECORDTYPEID;
        Database.insert(newAsset);
        
        //Create a new Plan Record
        NSP_Plan__c planRec = (NSP_Plan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan__c(), 'NSP_TestDataFactory.PlanDefaults', false);
        planRec.RecordTypeId = choicePlanRecordTypeId;
        Database.insert(planRec);
        
        //Creat a new Plan Sub Plan Record and link it to Plan Record    
        NSP_Plan_SubPlan__c planSubPlanRec = (NSP_Plan_SubPlan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan_SubPlan__c(), 'NSP_TestDataFactory.SubPlanDefaults', false);
        planSubPlanRec.RecordTypeId = choicePlanSubPlanRecordTypeId;
        planSubPlanRec.NSP_Subplan_ID__c = 'Test Plan Sub Plan 1';
        planSubPlanRec.NSP_Parent_Plan_ID__c = planRec.Id;
        Database.insert(planSubPlanRec);
                
        //Create a new Client Sub Plan History Record and link it to Asset and Plan Sub Plan
        NSP_Client_Sub_Plan_History__c clientSubPlanHistRec = new NSP_Client_Sub_Plan_History__c();
        clientSubPlanHistRec.RecordTypeId = CHOICECLIENTSUBPLANRECORDTYPEID;
		clientSubPlanHistRec.NSP_Asset__c = newAsset.Id;
        clientSubPlanHistRec.NSP_End_Date__c = null;
        clientSubPlanHistRec.NSP_Current_Subplan__c = true;
        clientSubPlanHistRec.NSP_Plan_Subplan_Relationship__c = planSubPlanRec.Id;
        clientSubPlanHistRec.NSP_Start_Date__c = Date.today();
        Database.insert(clientSubPlanHistRec);
    }
    
    @isTest
    public static void checkCurrentSubPlanOfExistingAndNewRecord(){
        //Get Client Sub Plan History with current subplan checked and uncheck the current subplan
        NSP_Client_Sub_Plan_History__c getUncheckedClientSubPlanRec = [SELECT Id, NSP_Current_Subplan__c 
                                                                       FROM NSP_Client_Sub_Plan_History__c
                                                                       WHERE NSP_Current_Subplan__c = true 
                                                                       LIMIT 1];
        getUncheckedClientSubPlanRec.NSP_Current_Subplan__c = false;
        
        Asset getAssetRec = [SELECT Id FROM Asset WHERE RecordTypeId =: RETSERVICESASSETRECORDTYPEID LIMIT 1];
        NSP_Plan_SubPlan__c getPlanSubPlanRec = [SELECT Id 
                                                 FROM NSP_Plan_SubPlan__c
                                                 WHERE NSP_Subplan_ID__c = 'Test Plan Sub Plan 1' 
                                                 LIMIT 1];
        
        //Create a new Client Sub Plan History Record and check the current sub plan checkbox
        NSP_Client_Sub_Plan_History__c newClientSubPlanHistRec = new NSP_Client_Sub_Plan_History__c();
        newClientSubPlanHistRec.RecordTypeId = CHOICECLIENTSUBPLANRECORDTYPEID;
        newClientSubPlanHistRec.NSP_Asset__c = getAssetRec.Id;
        newClientSubPlanHistRec.NSP_End_Date__c = null;
        newClientSubPlanHistRec.NSP_Current_Subplan__c = true;
        newClientSubPlanHistRec.NSP_Start_Date__c = Date.today();
        newClientSubPlanHistRec.NSP_Plan_Subplan_Relationship__c = getPlanSubPlanRec.Id;
        
        Test.startTest();
        Database.insert(newClientSubPlanHistRec);
        Database.update(getUncheckedClientSubPlanRec);
        Test.stopTest();
        System.assertEquals(true, newClientSubPlanHistRec.NSP_Current_Subplan__c);
        System.assertNotEquals(true, getUncheckedClientSubPlanRec.NSP_Current_Subplan__c);
    }
    
     @IsTest
    static void afterUpdate() {
        new NSP_ClientSubPlanHistTriggerHandler().afterUpdate(null, null);
         System.assert(new NSP_ClientSubPlanHistTriggerHandler().afterUpdate(null, null) == null);
    }
    @IsTest
    static void beforeDelete() {
        new NSP_ClientSubPlanHistTriggerHandler().beforeDelete(null, null);
         System.assert(new NSP_ClientSubPlanHistTriggerHandler().beforeDelete(null, null) == null);
    }
    @IsTest
    static void afterDelete() {
        new NSP_ClientSubPlanHistTriggerHandler().afterDelete(null, null);
         System.assert(new NSP_ClientSubPlanHistTriggerHandler().afterDelete(null, null) == null);
    }
   
}