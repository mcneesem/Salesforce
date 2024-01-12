/**
Apex Class Name      :  NSP_ProjectAssignmentTriggerHelperTest
Version              :  1.0                                                                          
Created Date         :  06/01/22   
Function             :  This class is used as a test class to  NSP_ProjectAssignmentTriggerHelperTest
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Jatin                 06/09/22            First Iteration
*/

@isTest
public class NSP_ProjectAssignmentTriggerHelperTest {
    @testSetup
    public static void createData(){
        //inserting Region 
        pse__Region__c oRegion = new pse__Region__c(Name = 'United States');
        insert oRegion;
        Id iRETRecordTypeId = Schema.SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get('RET_Deconversion_2020_Form')?.getRecordTypeId();
        //inserting Project
        pse__Proj__c oProject = new pse__Proj__c();
        oProject.pse__Start_Date__c = Date.Today();
        oProject.Name = 'Test';
        oProject.pse__Is_Active__c = true;
        oProject.pse__Region__c = oRegion.Id;
        oProject.RecordTypeId = iRETRecordTypeId;
        insert oProject;
        //  inserting Project Task
        pse__Project_Task__c oPTask = new pse__Project_Task__c();
        oPTask.Name = 'RET Compliance';
        oPTask.pse__Project__c = oProject.Id;
        oPTask.Responsible_Party__c = 'RET Compliance';
        insert oPTask;
        pse__Project_Task__c oPTask2 = new pse__Project_Task__c();
        oPTask2.Name = 'RET Compliance';
        oPTask2.pse__Project__c = oProject.Id;
        oPTask2.Responsible_Party__c = 'RET Compliance';
        insert oPTask2;
        //inserting Account
        Account oAccount = new Account(Name = 'ABC Company');
        insert oAccount;
        //inserting Contact
        Contact oContact = new Contact(FirstName = 'First', LastName = 'Last' , AccountId = oAccount.Id, Email = 'abctestexamplyxyz@test.com.abc',
                                       pse__Salesforce_User__c = UserInfo.getUserId(),pse__Is_Resource_Active__c = true,pse__Is_Resource__c = true,
                                       pse__Region__c = oRegion.Id);
        insert oContact;
        //inserting Permission Control
        pse__Permission_Control__c oPControl = new pse__Permission_Control__c(pse__Region__c = oRegion.Id,pse__User__c = UserInfo.getUserId(),
                                                                              pse__Staffing__c = true);
        insert oPControl;
    }
    @isTest
    public static void updateRoleOnAssignment(){
        Contact oContact = [SELECT Id FROM Contact WHERE Name != null Limit 1];
        oContact.pse__Resource_Role__c = 'RET Compliance';
        update oContact;
        Account oAccount = [SELECT Id FROM Account WHERE Name != null LIMIT 1];
        pse__Region__c oRegion = [SELECT Id FROM pse__Region__c WHERE Name != null Limit 1];
        Profile pro = [SELECT Id FROM Profile WHERE UserLicense.Name = : 'Customer Community' LIMIT 1];
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@randomorg.com';
        User newUser = new User(alias = 'uDelet', email='testfake@testexmplae.xom', 
                          emailencodingkey='UTF-8', lastname='temp', 
                          languagelocalekey='en_US', ContactId = oContact.Id,
                          localesidkey='en_US', profileid = pro.Id,
                          timezonesidkey='America/Los_Angeles', 
                          username=uniqueUserName);
        insert newUser;
        
        User oUser = [SELECT ID from User WHERE Id = : UserInfo.getUserId()];
        System.runAs(oUser){
            Contact oCustomerContact = new Contact(FirstName = 'First', LastName = 'Last' , AccountId = oAccount.Id, Email = 'abctestexamplyxyz@test.com.abc2',
                                           pse__Salesforce_User__c = newUser.Id,pse__Is_Resource_Active__c = true,pse__Is_Resource__c = true,
                                           pse__Region__c = oRegion.Id);
            insert oCustomerContact;
            Id iProject = [SELECT Id FROM pse__Proj__c WHERE Name != null  LIMIT 1]?.Id;
            Test.startTest();
            //inserting Assignment
            pse__Assignment__c oAssignment = new pse__Assignment__c();
            oAssignment.pse__Project__c = iProject;
            oAssignment.pse__Resource__c = oContact.Id;
            oAssignment.pse__Bill_Rate__c = 0;
            oAssignment.pse__Role__c = 'RET Compliance';
            insert oAssignment;
            System.assertEquals('RET Compliance', [SELECT Id,pse__Role__c FROM pse__Assignment__c WHERE pse__Role__c != null LIMIT 1]?.pse__Role__c);
            oAssignment.pse__Resource__c = oCustomerContact.Id;
            update oAssignment;
            System.assertEquals('Customer', [SELECT Id,pse__Role__c FROM pse__Assignment__c WHERE Id =: oAssignment.Id LIMIT 1]?.pse__Role__c);
            /*pse__Permission_Control__c oPControl = new pse__Permission_Control__c(pse__Region__c = oRegion.Id,pse__User__c = u.Id,
                                                                                  pse__Staffing__c = true);
            insert oPControl;
            pse__Assignment__c oCustomerAssignment = new pse__Assignment__c();
            oCustomerAssignment.pse__Project__c = iProject;
            oCustomerAssignment.pse__Resource__c = oCustomerContact.Id;
            oCustomerAssignment.pse__Bill_Rate__c = 0;
            insert oCustomerAssignment;
            
            System.assertEquals('Customer', [SELECT Id,pse__Role__c FROM pse__Assignment__c WHERE Id =: oCustomerAssignment.Id LIMIT 1]?.pse__Role__c);*/
            
            Test.stopTest();
        }
    }
}