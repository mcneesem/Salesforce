/**
Apex Class Name      :  NSP_TimeCardTriggerHelperTest
Version              :  1.0  
Author               :   Jatin                                                                        
Created Date         :    6/1/2022
Function             :  This class is used as a test class for  NSP_TimeCardTriggerHelper
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Jatin                6/9/2022           First Iteration
*/
  
@isTest
public class NSP_TimeCardTriggerHelperTest {
    @testSetup
    static void testData() {
        pse__Region__c oRegion = new pse__Region__c(Name = 'United States');
        insert oRegion;
        //Creatin Contact
        Contact con = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        con.pse__Allow_Timecards_Without_Assignment__c = true;
        con.pse__Resource_Role__c = 'Insperity';
        con.pse__Region__c = oRegion.Id;
        con.pse__Salesforce_User__c = UserInfo.getUserId();
        insert con;
        //Creating Project
        pse__Proj__c Prj = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        Prj.pse__Region__c = oRegion.Id;
        Prj.pse__Is_Billable__c = true;
        Prj.pse__Start_Date__c = Date.Today();
        insert Prj;
        //Creatting Project task
        pse__Project_Task__c PrjTsk = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        PrjTsk.pse__Project__c = Prj.Id;
        insert PrjTsk;
        //Creating Permission Control
        pse__Permission_Control__c PControl = new pse__Permission_Control__c();
        PControl.pse__Region__c = oRegion.Id;
        PControl.pse__User__c = UserInfo.getUserId();
        PControl.pse__Staffing__c = true;
        insert PControl;
        // Creating Schedule
        pse__Schedule__c Sch = new pse__Schedule__c();
        Sch.pse__Start_Date__c = Date.today();
        Sch.pse__End_Date__c = Date.Today().addDays(7);
        Sch.pse__Scheduled_Hours__c = 21;
        insert Sch;
        //creating Assignment
        pse__Assignment__c Asnt = new pse__Assignment__c();
        Asnt.pse__Project__c = Prj.ID;
        Asnt.pse__Resource__c = con.Id;
        Asnt.pse__Bill_Rate__c = 150;
        insert Asnt;
        
    }
    @isTest
    static void populateTimeCardsFields(){
        test.startTest();
        Contact con = [SELECT Id FROM Contact WHERE Contact.FirstName = 'ResourceFN'];
        pse__Assignment__c Asnt = [SELECT Id, pse__Project__c FROM pse__Assignment__c WHERE pse__Assignment__c.pse__Resource__c =: con.Id ];
        //creating timecard 
        pse__Timecard_Header__c TCard = new pse__Timecard_Header__c();
        Tcard.pse__Assignment__c = Asnt.Id;
        Tcard.pse__Project__c = Asnt.pse__Project__c;
        Tcard.pse__Resource__c = con.Id;
        Tcard.pse__Start_Date__c = Date.today();
        Tcard.pse__End_Date__c = Date.Today().addDays(6);
        Tcard.pse__Billable__c = True;
        //inserting Time card
        insert Tcard;
        Tcard = [SELECT Id,pse__Submitted__c,pse__Approved__c,pse__Include_In_Financials__c FROM pse__Timecard_Header__c WHERE pse__Timecard_Header__c.pse__Assignment__c =: Asnt.Id];
        System.assertEquals(Tcard.pse__Submitted__c,true);
        System.assertEquals(Tcard.pse__Approved__c,true);
        System.assertEquals(Tcard.pse__Include_In_Financials__c,true);
        test.stopTest();
    }
}