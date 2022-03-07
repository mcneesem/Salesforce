/**
* @description  : Test class for NSP_TaskServiceUtil class
* @date 06/04/2021
* Name : NSP_TaskServiceUtilTest
*
*/


@isTest(SeeAllData=false)
public class NSP_TaskServiceUtilTest {   
    
    /*
@CreatedDate : 06/01/2021
@Description : test setup method
@Parameters : N/A
@Return : void
*/ 
    @testSetup
    static void testData() {
		Lead ld = new Lead();
        ld.firstname='Test';
        ld.lastname='Lead';
        ld.Company = 'TestClass';
        ld.Email = 'test@test.com';
        ld.PostalCode = '221010';
        
        insert ld;
        
        List<Task> taskList = new List<Task>();
        Task tsk =  new Task();
        tsk.Subject = 'Call';
        tsk.CurrencyIsoCode ='USD';
        tsk.Priority='Normal';
        tsk.Status='Completed';
        tsk.NSP_Submission_type__c ='Sales ready';
        tsk.WhoId = ld.id;
        
        Task tsk1 =  new Task();
        tsk1.Subject = 'Call';
        tsk1.CurrencyIsoCode ='USD';
        tsk1.Priority='Normal';
        tsk1.Status='Open';
        tsk1.NSP_Submission_type__c ='Sales ready';
        tsk1.WhoId = ld.id;
        
        taskList.add(tsk1);
        taskList.add(tsk);
        insert taskList;
    }
    
    /*
@CreatedDate : 06/01/2021
@Description : Method to check the lead stage is getting updated
@Parameters : N/A
@Return : void
*/ 
    @isTest
    static void checkLeadStage() {
        Test.startTest();
        Task tsk = [SELECT Id,status FROM task WHERE status ='Open'  LIMIT 1];
        tsk.Status = 'Completed';
        update tsk;
        List<Id> leadIds = new List<Id>();
        Map<Id,Lead> leadMap = new Map<Id, Lead>([SELECT Id, Name FROM Lead WHERE Name !='']);
        /*for(Id leadId : leadMap.keySet()){
            leadIds.add(leadId);
        }*/
        
        leadIds.addAll(leadMap.keySet());
        NSP_TaskServiceUtil.updateLeadStage(leadIds);
        Test.stopTest();
        
        List<Lead> leadList = [SELECT Id, nsp_lead_stage__c FROM Lead WHERE Id IN :leadIds];
        System.assertEquals(leadList[0].nsp_lead_stage__c, NSP_SalesConstants.LEAD_STAGE_SRL);
    }
}