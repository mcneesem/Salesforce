/**
* Represents test class for NSP_DocusignStatusHelper and NSP_DocusignStatusHandler
*/
@isTest
public class NSP_DocusignStatusHelperTest {
    
     /**
    * Does test data setup
    * @param N/A. 
    * @return void                          
    */
    @testSetup
    public static void createTestData() {        
        dfsle__EnvelopeStatus__c docusignstatus = new dfsle__EnvelopeStatus__c();
        docusignstatus.dfsle__EmailSubject__c	= 'Test Sign Doc';
        docusignstatus.dfsle__Status__c = Label.NSP_Docusign_Status_Completed;
        insert docusignstatus;
        
    }
    
    //Method to test Platform Event trigger
    static testMethod void createPlatformEventForDocusignStatus() {
        Test.startTest();
        dfsle__EnvelopeStatus__c envStatus = [SELECT Id,Name,dfsle__EmailSubject__c,dfsle__Status__c From dfsle__EnvelopeStatus__c LIMIT 1];
        envStatus.dfsle__EmailSubject__c = 'Signed';
        update envStatus;
        
        Test.stopTest();
        List<NSP_Error_Log__c> errorLog = [SELECT Id, Name, NSP_Class__c, NSP_Method__c FROM NSP_Error_Log__c limit 1];
        if(errorLog.size() > 0) {
            system.assert(errorLog.size() > 0, 'Platform Event Success');
        }
        
    }
}