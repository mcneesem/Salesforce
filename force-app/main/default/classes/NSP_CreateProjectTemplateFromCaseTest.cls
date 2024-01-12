/**
Apex Class Name      :  NSP_OpportunityTriggerHelper for Opportunity Trigger
Version              :  1.0                                                                          
Created Date         :  06/01/22  
Function             :  This class is used as a Test class for NSP_CreateProjectTemplateFromCase
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Jtin                 06/01/22           First Iteration
*/

    
    @isTest
    public class NSP_CreateProjectTemplateFromCaseTest {
        
        @testSetup
        static void setupTestData(){
            Case newCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
            newCase.NSP_Category__c = 'Time & Attendance';
            insert newCase;
    
            pse__Proj__c projectObj = new pse__Proj__c();
            projectObj.Name = 'Test 1';
            projectObj.TemplateName__c = NSP_ServiceConstants.ITA_IMPLEMENTATION;
            projectObj.pse__Is_Active__c = true;
            insert projectObj;
        }
    
        @isTest
        static void createProjectFromTemplateSetupOnCase() {
            Test.StartTest();
            Case caseRecord = [SELECT id, NSP_Category__c FROM Case WHERE CaseNumber != null LIMIT 1];
            pse__Proj__c projectRec = [SELECT Id FROM pse__Proj__c WHERE  TemplateName__c =: NSP_ServiceConstants.ITA_IMPLEMENTATION LIMIT 1 ];
            NSP_CreateProjectTemplateFromCase.linkProjectWithCase(projectRec.Id,caseRecord.Id);
            string recordResult = NSP_CreateProjectTemplateFromCase.insertProject(caseRecord.id);
            system.assertNotEquals(System.Label.NSP_Project_Created, recordResult);
            
            Case newCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', true);
            string recordResult1 = NSP_CreateProjectTemplateFromCase.insertProject(newCase.id);
            system.assertNotEquals(System.Label.NSP_Template_Not_Found, recordResult1);          
            Test.StopTest();
        }
    }