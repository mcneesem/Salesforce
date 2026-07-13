@isTest
private class NSP_ProjectTaskTriggerEmailTest {

    private final static Id PEORecordTypeId  = Schema.SObjectType.pse__Proj__c.getRecordTypeInfosByName().get('PEO Project').getRecordTypeId();
    private final static String PEOProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE).getRecordTypeId();
    private static Id fsoRecordTypeId =  Schema.SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.FSOProfile).getRecordTypeId();
    private static Id ipMMRecordTypeId = SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.MMProfile).getRecordTypeId();


    @testSetup
    private static void setUpData() {
        Email_Deliverability_Settings__c emailSetting = Email_Deliverability_Settings__c.getOrgDefaults();
        emailSetting.IsEnabledOutbound__c = true;
        upsert emailSetting;

        Account newAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        insert newAccount;
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        newContact.accountId = newAccount.Id;
        newContact.NSP_Work_email__c='test@pwc.com';
        newContact.NSP_Work_Phone__c='32574';
        newContact.NSP_Job_Title__c='Developer';
        insert newContact;

        NSP_Account_Team__c accTeam = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.accountTeamDefaults', false);
        accTeam.NSP_Account__c=newAccount.id;
        accTeam.NSP_Role__c =NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR;
        accTeam.NSP_User__c=userInfo.getUserId();
        insert accTeam;

        //project creation
        List<pse__Proj__c> projList  = new List<pse__Proj__c>();
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.pse__Project_Type__c = 'Implementation';
        oProject.RecordTypeId = PEORecordTypeId;
        oProject.TemplateName__c=label.FSOImplementationProject;
        oProject.pse__Project_Status__c='Active';
        oProject.pse__Project_Manager__c=newContact.Id;
        oProject.pse__Account__c=newAccount.Id;
        projList.add(oProject);

        pse__Proj__c oProject2 = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject2.pse__Project_Type__c = 'Implementation';
        oProject2.RecordTypeId = PEORecordTypeId;
        oProject2.TemplateName__c=label.Middle_Market_Implementation_Project;
        oProject2.pse__Project_Status__c='Active';
        oProject2.pse__Project_Manager__c=newContact.Id;
        oProject2.pse__Account__c=newAccount.Id;
        projList.add(oProject2);

        if(!projList.isEmpty()){
          database.insert(projList);
        }



        //project task creation
        List<pse__Project_Task__c> projTaskList = new List<pse__Project_Task__c>();
        List<pse__Project_Task__c> parentTaskList = new List<pse__Project_Task__c>();

        pse__Project_Task__c projTask4 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        projTask4.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        projTask4.RecordTypeId = PEOProjectTaskRecordTypeId;
        projTask4.Name = NSP_ServiceConstants.CLIENTTRANSITION;
        projTask4.pse__Project__c = oProject.Id;
        parentTaskList.add(projTask4);

        pse__Project_Task__c projTask5 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        projTask5.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        projTask5.RecordTypeId = PEOProjectTaskRecordTypeId;
        projTask5.Name = NSP_ServiceConstants.ONSITEDISCOVERY;
        projTask5.pse__Project__c = oProject2.Id;
        parentTaskList.add(projTask5);

        if(!parentTaskList.isEmpty()){
              database.insert(parentTaskList);
        }

        pse__Project_Task__c projTask2 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        projTask2.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        projTask2.RecordTypeId = PEOProjectTaskRecordTypeId;
        projTask2.Name = NSP_ServiceConstants.FORMCOLLECTED;
        projTask2.pse__Project__c = oProject2.Id;
        projTaskList.add(projTask2);

        pse__Project_Task__c projTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        projTask.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        projTask.RecordTypeId = PEOProjectTaskRecordTypeId;
        projTask.Name = NSP_ServiceConstants.FEIN;
        projTask.pse__Project__c = oProject.Id;
        projTaskList.add(projTask);

        pse__Project_Task__c projTask1 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        projTask1.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        projTask1.RecordTypeId = PEOProjectTaskRecordTypeId;
        projTask1.Name = NSP_ServiceConstants.FUNDINGDOCUMENTS;
        projTask1.pse__Project__c = oProject.Id;
        projTaskList.add(projTask1);

        pse__Project_Task__c pt = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        pt.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        pt.RecordTypeId = PEOProjectTaskRecordTypeId;
        pt.Name = NSP_ServiceConstants.PAYROLLAPPROVED;
        pt.pse__Project__c = oProject2.Id;
        pt.pse__Parent_Task__c=projTask5.id;
        projTaskList.add(pt);

        pse__Project_Task__c projTask3 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        projTask3.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        projTask3.RecordTypeId = PEOProjectTaskRecordTypeId;
        projTask3.Name = NSP_ServiceConstants.PAYROLLAPPROVED;
        projTask3.pse__Project__c = oProject.Id;
        projTask3.pse__Parent_Task__c=projTask4.id;
        projTaskList.add(projTask3);

        pse__Project_Task__c pt1 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        pt1.Name =NSP_ServiceConstants.PREPARE_AMENDMENT;
        pt1.Template_Name__c =NSP_ServiceConstants.PLAN_AMENDMENT_TEMPLATE;
        pt1.pse__Project__c = oProject.Id;
        pt1.pse__Status__c=NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        projTaskList.add(pt1);

         Document doc1 = new Document();
        doc1.DeveloperName = 'Insperity_Footer_Logo';
        doc1.ContentType = 'application/pdf';
        doc1.IsPublic = true;
        doc1.Name = 'doc1';
        doc1.FolderId = UserInfo.getUserId();

        Document doc2 = new Document();
        doc2.DeveloperName = 'Insperity_HR';
        doc2.ContentType = 'application/pdf';
        doc2.IsPublic = true;
        doc2.Name = 'doc2';
        doc2.FolderId = UserInfo.getUserId();

        List<Document> docList = new List<Document>();
        docList.add(doc1);
        docList.add(doc2);
        insert docList;

        Test.startTest();

        if(!projTaskList.isEmpty()){
              database.insert(projTaskList);
        }

        //insert sub client
        NSP_Sub_Client__c subClient = (NSP_Sub_Client__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Client__c(), 'NSP_TestDataFactory.SubClientDefaults', false);
        subClient.Name = 'Test SC';
        subClient.NSP_Account__c =   newAccount.Id;
        insert subClient;

        //insert sub client contact
        NSP_Sub_Client_Contact__c scc1= new NSP_Sub_Client_Contact__c();
        scc1.NSP_Job_Title__c = 'Test SCC';
        scc1.NSP_Contact__c=newContact.id;
        scc1.NSP_Sub_Client__c=subClient.id;
        scc1.NSP_Payroll_Contact__c=true;
        insert scc1;

        // Create Asset record
        Asset asst = new Asset();
        asst.Name = 'Test Asset' ;
        asst.ContactId = newContact.Id ;
        asst.AccountId = newAccount.Id ;
        asst.NSP_Client__c='1234';
        asst.NSP_Company_Name__c='test acc';
        insert asst;

        List<Project_Asset__c> projAssetList = new List<Project_Asset__c>();
        Project_Asset__c projAsset= new Project_Asset__c();
        projAsset.Asset__c=asst.Id;
        projAsset.Project__c=oProject.Id;
        projAssetList.add(projAsset);

        Project_Asset__c projAsset1= new Project_Asset__c();
        projAsset1.Asset__c=asst.Id;
        projAsset1.Project__c=oProject2.Id;
        projAssetList.add(projAsset1);
        if(!projAssetList.isEmpty()){
              Database.insert(projAssetList);
        }
        test.stopTest();


    }

    @isTest
    private static void emailNotifyforFsoProjectTasks() {
        List<pse__Project_Task__c> updateTaskList = new List<pse__Project_Task__c>();
        List<NSP_Project_Team__c> projTeamList = new List<NSP_Project_Team__c>();

        Contact con=[SELECT Id ,NSP_Work_email__c FROM Contact WHERE Id != null LIMIT 1];
        pse__Proj__c proj =[SELECT Id,(SELECT NSP_Assignee__c FROM Project_Teams__r )
                            FROM pse__Proj__c
                            WHERE TemplateName__c=:label.FSOImplementationProject LIMIT 1];

        if(proj.Project_Teams__r.size()>0){
            for(NSP_Project_Team__c projTeam : proj.Project_Teams__r){
               projTeam.NSP_Assignee__c=con.Id;
                 projTeamList.add(projTeam);
            }
        }
        NSP_Sub_Client__c sc = [SELECT Id,NSP_Account__c,NSP_Account_Status__c from NSP_Sub_Client__c WHERE Id != null AND Name = 'Test SC' LIMIT 1];
        sc.NSP_Account_Status__c = NSP_ServiceConstants.AIMS_STATUS;
        NSP_Sub_Client_Contact__c scc = [SELECT Id, NSP_Contact__c, NSP_Sub_Client__c,NSP_Sub_Client__r.NSP_Account__c, NSP_Contact__r.NSP_Work_email__c, NSP_Contact__r.Name, NSP_Contact__r.NSP_Work_Phone__c, NSP_Payroll_Contact__c, NSP_On_Site_Supervisor__c, NSP_Job_Title__c
                                        FROM NSP_Sub_Client_Contact__c WHERE Id != null AND NSP_Job_Title__c = 'Test SCC' LIMIT 1];
        scc.NSP_Paid_Non_Paid__c = NSP_ServiceConstants.PAID_NON_PAID_WSEE;
        scc.NSP_Employee_Status__c = NSP_ServiceConstants.FMLA_STATUS;
        scc.NSP_Work_Email__c = 'test@pwc.com';
        scc.NSP_Payroll_Contact__c = TRUE;
        scc.NSP_Sub_Client__c = sc.Id;

        Implementation_Profile__c ip=[SELECT Id,Has_FEIN_documentation_been_collected__c,NSP_Transition_Specialist__c,
                                     NSP_OT_Representative__c,NSP_Client_Liaison__c,NSP_Payroll_Specialist__c,NSP_HR_Specialist__c
                                      FROM Implementation_Profile__c
                                      WHERE NSP_Project__c=:proj.Id  LIMIT 1];
        ip.Has_FEIN_documentation_been_collected__c='No';

        List<pse__Project_Task__c> projTaskList=[SELECT Id,Name
                                                 FROM pse__Project_Task__c
                                                 WHERE pse__Project__c=:proj.Id];
        for(pse__Project_Task__c pt:projTaskList){
            if(pt.Name == NSP_ServiceConstants.FUNDINGDOCUMENTS){
                pt.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
                updateTaskList.add(pt);
            }
            if(pt.Name == NSP_ServiceConstants.PAYROLLAPPROVED){
                pt.pse__Status__c=NSP_ServiceConstants.TASKCOMPLETE;
                updateTaskList.add(pt);
            }
            if(pt.Name == NSP_ServiceConstants.CLIENTTRANSITION){
                pt.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
                updateTaskList.add(pt);
            }
            if(pt.Name == NSP_ServiceConstants.PREPARE_AMENDMENT){
                pt.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
                updateTaskList.add(pt);
            }

        }

        Test.startTest();
        update sc;
        update scc;
        update ip;
        if(!projTeamList.isEmpty()){
            update projTeamList;
        }
        if(!updateTaskList.isEmpty()){
            update updateTaskList;
        }
        Implementation_Profile__c ip1=[SELECT Id,NSP_Project__c
                                      FROM Implementation_Profile__c
                                      WHERE NSP_Project__c=:proj.Id  LIMIT 1];
        System.assertEquals(proj.Id,ip1.NSP_Project__c);
        Test.stopTest();
    }

    @isTest
    private static void emailNotifyforMMProjectTasks() {
        Set<Id> projectFsoIdset = new Set<Id>();
        Map<Id, Id> accountIdFsoProjectTaskMap = new Map<Id, Id>();
        List<pse__Project_Task__c> updateTaskList = new List<pse__Project_Task__c>();
        Contact con=[SELECT Id ,NSP_Work_email__c FROM Contact WHERE Id != null LIMIT 1];

        pse__Proj__c proj =[SELECT Id,
                           (SELECT NSP_Assignee__c
                            FROM Project_Teams__r
                            )
                            FROM pse__Proj__c
                            WHERE TemplateName__c=:label.Middle_Market_Implementation_Project];
        List<NSP_Project_Team__c> projTeamList = new List<NSP_Project_Team__c>();
        if(proj.Project_Teams__r.size()>0){
            for(NSP_Project_Team__c projTeam : proj.Project_Teams__r){
               projTeam.NSP_Assignee__c=con.Id;
                 projTeamList.add(projTeam);

            }
        }
        Test.startTest();
        if(!projTeamList.isEmpty()){
            update projTeamList;
        }


        Implementation_Profile__c ip=[SELECT Id,Has_form_8973_been_discussed__c,NSP_Project_Manager__c,
                                        NSP_Payroll_Project_Manager__c, NSP_Account_Executive__c,NSP_HR_Specialist__c
                                      FROM Implementation_Profile__c
                                      WHERE NSP_Project__c=:proj.Id  LIMIT 1];
        ip.Has_form_8973_been_discussed__c='No';
        update ip;

       List<pse__Project_Task__c> projTaskList=[SELECT Id,Name,pse__Project__c,NSP_AccountId__c
                                                 FROM pse__Project_Task__c
                                                 WHERE pse__Project__c=:proj.Id];
        for(pse__Project_Task__c pt:projTaskList){
            if(pt.Name == NSP_ServiceConstants.FORMCOLLECTED){
                pt.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
                updateTaskList.add(pt);
            }

            if(pt.Name == NSP_ServiceConstants.PAYROLLAPPROVED){
                pt.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
                updateTaskList.add(pt);
                projectFsoIdset.add(pt.pse__Project__c);
                accountIdFsoProjectTaskMap.put(pt.NSP_AccountId__c,pt.Id);
            }
            if(pt.Name == NSP_ServiceConstants.ONSITEDISCOVERY){
                pt.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
                updateTaskList.add(pt);
            }
        }

            if(!updateTaskList.isEmpty()){
                update updateTaskList;
            }
        NSP_ProjectTaskTriggerEmailNotification.emailNotifyforFirstPayrollMM(projectFsoIdset, accountIdFsoProjectTaskMap);
          Implementation_Profile__c ip1=[SELECT Id,Has_form_8973_been_discussed__c
                                          FROM Implementation_Profile__c
                                          WHERE NSP_Project__c=:proj.Id  LIMIT 1];
          System.assertEquals('Yes',ip1.Has_form_8973_been_discussed__c);
        Test.stopTest();


    }

    @isTest
    private static void createEmailMessageRecTest() {
        Map<Messaging.SingleEmailMessage,Id> emailMessageToProjectTaskMap = new Map<Messaging.SingleEmailMessage,Id>();
        List<Messaging.SingleEmailMessage> lstEmailMessages = new List<Messaging.SingleEmailMessage>();
        List<String> projTaskFields = new List<String>{'Id','Name', 'pse__Project__c','pse__Status__c','NSP_Duration_in_minutes__c','pse__Start_Date_Time__c','pse__End_Date_Time__c'};
        String query = new NSP_QueryBuilder('pse__Project_Task__c', projTaskFields)
                            .addFilter('pse__Status__c', NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS).addLimit(1).build();

        pse__Project_Task__c  projectTaskRec = Database.query(query);
        List<String> sendToList = new List<String>{'test123@gmail.com'};
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(sendToList);
        email.setWhatId(projectTaskRec.pse__Project__c);
        lstEmailMessages.add(email);
        emailMessageToProjectTaskMap.put(email,projectTaskRec.id);
        Test.startTest();
        NSP_ProjectTaskTriggerEmailNotification.createEmailMessageRec(emailMessageToProjectTaskMap);
        Test.stopTest();
        System.assertEquals(projectTaskRec.pse__Status__c, NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS);
    }

    @isTest
    private static void emailNotifyforCobraFollowUpTest() {
        List<String> projTaskFields = new List<String>{'Id','Name', 'pse__Project__c','NSP_Duration_in_minutes__c','pse__Start_Date_Time__c','pse__End_Date_Time__c'};
            String query = new NSP_QueryBuilder('pse__Project_Task__c', projTaskFields)
            .addFilter('pse__Status__c', NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS).addLimit(1).build();

        pse__Project_Task__c  projectTaskRec = Database.query(query);
        projectTaskRec.Name = NSP_ServiceConstants.COBRA_FORM_COLLECTED_NO;
        projectTaskRec.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
        Test.startTest();
        update projectTaskRec;
        Test.stopTest();
        System.assertEquals(projectTaskRec.pse__Status__c, NSP_ServiceConstants.TASKCOMPLETE);

    }

}
//