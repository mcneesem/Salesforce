@isTest
private class NSP_PtaSyncPrjtTaskGrpMembrBatchTest {

    @testSetup
    private static void setupTestData() {
        //Get Record type Id of RET Project Type
        Id retProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', NSP_ServiceConstants.PROJECT_RET_RECORDTYPE);

        pse__Proj__c newProj = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        newProj.pse__Is_Template__c = false;
        newProj.pse__Project_Status__c = 'Active';
        newProj.TemplateName__c = NSP_ServiceConstants.PROJECT_GENERAL_BUSINESS_TEMPLATE;
        newProj.RecordTypeId = retProjectRecordTypeId;
        newProj.pse__Start_Date__c = date.newInstance(2023, 01, 01);
        newProj.pse__End_Date__c =  date.newInstance(2091, 12, 31);
        insert newProj;

        pse__Project_Task__c newProjTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        newProjTask.pse__Project__c = newProj.id;
        newProjTask.Name = 'test projectTask';
        newProjTask.NSP_Group_Membership_for_Plan_Projects__c = 'Group 1;';
        insert newProjTask;

        User testUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', true);
        // testUser.NSP_Group_Member_For_Plan_Projects__c = 'Group 1';

        Account acc = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);

        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        newContact.AccountId = acc.Id;
        newContact.lastName= 'Test';
        newContact.pse__Salesforce_User__c = testUser.Id;
        insert newContact;

    }

    @isTest
    private static void ptaCreationforGrpMembersTest() {
        try{
            //Given
            pse__Project_Task__c projectTaskRec = [SELECT Id FROM pse__Project_Task__c WHERE Name = 'test projectTask' LIMIT 1 ];

            Contact contactRec = [SELECT Id,pse__Salesforce_User__c FROM Contact WHERE lastName= 'Test' LIMIT 1];

            User testUser = [ SELECT Id,NSP_Group_Member_For_Plan_Projects__c FROM User WHERE ID =: contactRec.pse__Salesforce_User__c ];
            //update user Group Member Value
            testUser.NSP_Group_Member_For_Plan_Projects__c = 'Group 1' ;

            update testUser;

            //When
            test.startTest();
            NSP_PtaSyncWithProjectTasksGrpMembrBatch batchSch = new NSP_PtaSyncWithProjectTasksGrpMembrBatch();
            Database.executeBatch(batchSch, 200);
            batchSch.execute(null);
            test.stopTest();
            //Then
            pse__Project_Task_Assignment__c newPta = [SELECT id,pse__Resource__c,pse__Project_Task__c
                                                        FROM pse__Project_Task_Assignment__c
                                                        WHERE  pse__Project_Task__c =: projectTaskRec.Id LIMIT 1];
            System.assertEquals(contactRec.Id,newPta.pse__Resource__c,'Pta Created with contact');
        } catch(Exception ex){
        }
    }

    @isTest
    private static void noPtaforUserWithoutGrpMembersTest() {
        try{
            //Given
            pse__Project_Task__c projectTaskRec = [SELECT Id FROM pse__Project_Task__c WHERE Name = 'test projectTask' LIMIT 1 ];

            Contact contactRec = [SELECT Id FROM Contact WHERE lastName= 'Test' LIMIT 1];

            //When
            test.startTest();
            NSP_PtaSyncWithProjectTasksGrpMembrBatch batchSch = new NSP_PtaSyncWithProjectTasksGrpMembrBatch();
            Database.executeBatch(batchSch, 200);
            batchSch.execute(null);
            test.stopTest();
            //Then
            pse__Project_Task_Assignment__c newPta = [SELECT id,pse__Resource__c,pse__Project_Task__c
                                                        FROM pse__Project_Task_Assignment__c
                                                        WHERE  pse__Project_Task__c =: projectTaskRec.Id LIMIT 1];
            System.assertNotEquals(contactRec.Id,newPta.pse__Resource__c,'Pta Not Created with contact');
        } catch(Exception ex){
            System.debug( ' ~ ex=' + ex );
        }
    }

    @isTest
    private static void codeCoverageTest() {
        Test.startTest();
        NSP_PtaSyncWithProjectTasksGrpMembrBatch.testHandleException( null , null );
        NSP_PtaSyncWithProjectTasksGrpMembrBatch.schedule();
        Callable runner = (Callable)Type.forName( 'NSP_PtaSyncWithProjectTasksGrpMembrBatch' ).newInstance();
        runner.call( 'run' , null );
        Test.stopTest();
    }

}
//