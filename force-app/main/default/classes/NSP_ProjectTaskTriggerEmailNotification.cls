public class NSP_ProjectTaskTriggerEmailNotification {
    // test w/ NSP_ProjectTaskTriggerEmailTest (81%)

    //
    // MethodName: updateImplementationProfile
    // Description : This Method will update implementation profile and send email notification to project OS
    // Params:      List<pse__Project_Task__c> projectTaskList
    //
    private static final List<String> EMAIL_TEMPLATES = new List<String>{NSP_ServiceConstants.COBRA_FOLLOWUP};
    private static Map<String, EmailTemplate> mapOfEmailTempaltes = new Map<String, EmailTemplate>();

    private static final String FEINDOCUMENTTOEMAIL='FEIN_Documentation_Email';
    private static final String Funding_Document_Email='Funding_Document_Email';
    private static final String INTERNAL_DISCOVERY_FN ='NSP_Internal_Discovery';
    private static final String ONSITE_DISCOVERY_FN ='NSP_Onsite_Discovery';

    public static Id peoProjectRecordTypeId = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
    public static Id ipFSORecordTypeId = SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.FSOProfile).getRecordTypeId();
    public static Id ipMMRecordTypeId = SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.MMProfile).getRecordTypeId();
    public static List<String> listOfProjectStatus = new List<String>{NSP_ServiceConstants.TASKCOMPLETE,NSP_ServiceConstants.PROJECTSTATUSCANCELLED};

    //
    // MethodName: emailNotifyforFundingDocuments
    // Description : This Method send email notification when Funding Documents project task completed
    // Params:       Map <Id, pse__Project_Task__c >newMapProjecttasks, Map <Id, pse__Project_Task__c >oldMapProjecttasks
    //
    public static void emailNotifyforFundingDocuments( Set<Id> projectTaskIdSet , Map<Id,Id> mapofProjecttasks ) {
        //as part of STY-02170
        Map <Id, List<Messaging.EmailFileAttachment>> mapPrjIdListAttachment = new Map <Id, List<Messaging.EmailFileAttachment>>();
        try{
            Id peoProjectRecordTypeId = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
            NSP_PEO_Implementations__mdt pf = NSP_PEO_Implementations__mdt.getInstance(Funding_Document_Email);

            if(!mapofProjecttasks.isEmpty()){
                mapPrjIdListAttachment = NSP_EmailServiceAttachment.getProjectTaskAttachments(projectTaskIdSet);
                Map<Id,Implementation_Profile__c> mapofprojectIdAssets = new Map<Id,Implementation_Profile__c>();
                for ( Implementation_Profile__c projIp : [
                        SELECT Id , NSP_Project__c , NSP_AIMS_Client_Name__c , NSP_AIMS_ClientNo__c
                        FROM Implementation_Profile__c
                        WHERE ( NSP_Project__c IN :mapofProjecttasks.keySet() )
                    ]
                )
                {
                    if ( projIp!=null ) {
                        mapofprojectIdAssets.put( projIp.NSP_Project__c , projIp );
                    }
                }
                for(pse__Proj__c proj: [SELECT Id, recordTypeId, TemplateName__c, pse__Project_Type__c,pse__Project_Status__c,
                                        (SELECT Id,NSP_Role__c,NSP_Assignee__c, NSP_Assignee__r.Name,NSP_Assignee__r.NSP_Job_Title__c,
                                        NSP_Assignee__r.NSP_Work_email__c FROM Project_Teams__r WHERE NSP_Role__c =: NSP_ServiceConstants.ProjectManager AND NSP_Assignee__c!=null LIMIT 1 )
                                        FROM pse__Proj__c where Id in:mapofProjecttasks.keyset() AND
                                        pse__Project_Type__c=:NSP_ServiceConstants.ImplementationProjectType AND recordTypeId=:peoProjectRecordTypeId AND
                                        TemplateName__c=:label.FSOImplementationProject AND pse__Project_Status__c NOT IN :listOfProjectStatus])
                {
                    sendFundingDocumentMail(
                        mapofprojectIdAssets.get( proj.Id ).NSP_AIMS_ClientNo__c ,
                        mapofprojectIdAssets.get( proj.Id ).NSP_AIMS_Client_Name__c ,
                        proj.Project_Teams__r[0].NSP_Assignee__r.NSP_Job_Title__c ,
                        new List<String>{ pf.NSP_Email_Address__c } ,
                        proj.Project_Teams__r[0].NSP_Assignee__r.Name ,
                        mapPrjIdListAttachment.get( mapofProjecttasks.get( proj.Id ) ) ,
                        mapofProjecttasks.get( proj.Id )
                    );
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTaskTriggerEmailNotification.class.getName() ,
                'emailNotifyforFundingDocuments' ,
                e
            );
        }
    }

    //
    // MethodName: emailNotifyforFirstPayrollFSO
    // Description : This Method send email notification when First payroll approved subtask project task completed
    // Params:       Map <Id, pse__Project_Task__c >newMapProjecttasks, Map <Id, pse__Project_Task__c >oldMapProjecttasks
    //
    public static void emailNotifyforFirstPayrollFSO( Set<Id> projectIds , Map<Id,Id> accountIdProjectTaskMap ) {
        Set<Id> accountIds =new Set<Id>();
        Map<Id, pse__Proj__c> mapofAccountIds = new Map<Id,pse__Proj__c>();
        Set<Id> subclientIds =new Set<Id>();
        Set<Id> projectIdset = new Set<Id>();
        Map<Id, Set<Id>> mapofSubclientIds = new Map<Id,Set<Id>>();
        Map<Id, Set<String>> mapAccountIdSetContactEmail = new Map<Id, Set<String>>();
        Map<Id, List<String>> mapofccEmailSet = new Map<Id, List<String>>();
        Map<Id, Set<String>> mapOfAccountTeamEmail=new Map<Id,Set<String>>(); // map of Account team id, cc email address



        try{
            for(pse__Proj__c proj:[SELECT Id, pse__Account__c,Project_Team_Payroll_Specialist__c,NSP_Account__c,NSP_RET_Client_ID__c,
                                        (SELECT NSP_Assignee__c, NSP_Assignee__r.Name,
                                        NSP_Assignee__r.NSP_Work_email__c, NSP_Assignee__r.NSP_Work_Phone__c
                                        FROM Project_Teams__r
                                        WHERE NSP_Role__c=:NSP_ServiceConstants.PAYROLL_SPECIALIST AND NSP_Assignee__c !=null)
                                        FROM pse__Proj__c where Id in:projectIds AND  recordTypeId=:peoProjectRecordTypeId
                                        AND TemplateName__c=:label.FSOImplementationProject
                                        AND pse__Project_Status__c NOT IN : listOfProjectStatus ]){
                        mapofAccountIds.put(proj.pse__Account__c, proj);
                        accountIds.add(proj.pse__Account__c);
                        projectIdset.add(proj.Id);

            }

            //fetch all users of FSO IP to adddress cc
            List<String> ccAddress = new List<String>();
            if(!projectIdset.isEmpty()){
                for(Implementation_Profile__c imp: [SELECT Id, NSP_Project__c,  NSP_Client_Liaison__c, NSP_Client_Liaison__r.NSP_Work_email__c, NSP_Project_Manager__c, NSP_Project_Manager__r.NSP_Work_email__c,
                NSP_Manager_HR_Services__c, NSP_Manager_HR_Services__r.NSP_Work_email__c,NSP_HR_Specialist__c, NSP_HR_Specialist__r.NSP_Work_email__c,NSP_Payroll_Specialist__c,NSP_Payroll_Specialist__r.NSP_Work_email__c
                FROM Implementation_Profile__c WHERE NSP_Project__c in:projectIdset ]){


                    if(String.isNotBlank(imp.NSP_Client_Liaison__r.NSP_Work_email__c)){
                        ccAddress.add(imp.NSP_Client_Liaison__r.NSP_Work_email__c);
                    }
                    if(String.isNotBlank(imp.NSP_Project_Manager__r.NSP_Work_email__c)){
                        ccAddress.add(imp.NSP_Project_Manager__r.NSP_Work_email__c);
                    }
                    if(String.isNotBlank(imp.NSP_Manager_HR_Services__r.NSP_Work_email__c)){
                        ccAddress.add(imp.NSP_Manager_HR_Services__r.NSP_Work_email__c);
                    }
                    if(String.isNotBlank(imp.NSP_HR_Specialist__r.NSP_Work_email__c)){
                        ccAddress.add(imp.NSP_HR_Specialist__r.NSP_Work_email__c);
                    }
                    if(imp.NSP_Payroll_Specialist__c != null && String.isNotBlank(imp.NSP_Payroll_Specialist__r.NSP_Work_email__c)){
                        ccAddress.add(imp.NSP_Payroll_Specialist__r.NSP_Work_email__c);
                    }
                    mapofccEmailSet.put(imp.NSP_Project__c, ccAddress);
                }
            }



            if(!accountIds.isEmpty()){
                //get all Business Performance Advisor and/or Business Performance Consultant, payroll specialist from account team for cc address
                Set<String> accountTeamccAddress = new Set<String>();
                for(NSP_Account_Team__c accTeam: [SELECT NSP_Account__c,NSP_User__c,NSP_User__r.Name, NSP_User__r.Title, NSP_Role__c,  NSP_Email__c
                                                FROM NSP_Account_Team__c
                                                WHERE (NSP_Role__c=:NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR OR
                                                        NSP_Role__c=:NSP_ServiceConstants.BUSINESS_PERFORMANCE_CONSULTANT)
                                                AND NSP_User__c!=NULL AND NSP_Account__c IN: accountIds] ){

                    if(accTeam.NSP_Role__c==NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR && String.isNotBlank(accTeam.NSP_Email__c)){
                        accountTeamccAddress.add(accTeam.NSP_Email__c);
                    }
                    if(accTeam.NSP_Role__c==NSP_ServiceConstants.BUSINESS_PERFORMANCE_CONSULTANT && String.isNotBlank(accTeam.NSP_Email__c)){
                        accountTeamccAddress.add(accTeam.NSP_Email__c);
                    }
                    mapOfAccountTeamEmail.put(accTeam.NSP_Account__c, accountTeamccAddress);
                }
                //get all subclient related to fso project account
                for ( NSP_Sub_Client__c sc : [
                            SELECT Id , NSP_Account__c , NSP_Account_Status__c
                            FROM NSP_Sub_Client__c
                            WHERE (
                                ( NSP_Account_Status__c = :NSP_ServiceConstants.AIMS_STATUS )
                                AND ( NSP_Account__c IN :accountIds )
                            )
                        ]
                    )
                {
                    if ( !mapofSubclientIds.containsKey( sc.NSP_Account__c ) ) {
                        mapofSubclientIds.put( sc.NSP_Account__c , new Set<Id>() );
                    }
                    mapofSubclientIds.get( sc.NSP_Account__c ).add( sc.Id );
                    subclientIds.add( sc.Id );
                }
            }
            //fetch all contacts  email who has On-site Supervisor and payroll contacts for to address

            if ( !subclientIds.isEmpty() ) {
                for ( NSP_Sub_Client_Contact__c scc : [
                            SELECT
                                Id , NSP_Work_Email__c , NSP_Contact__c , NSP_Sub_Client__c , NSP_Sub_Client__r.NSP_Account__c ,
                                NSP_Contact__r.NSP_Work_email__c , NSP_Contact__r.Name , NSP_Contact__r.NSP_Work_Phone__c ,
                                NSP_Payroll_Contact__c , NSP_On_Site_Supervisor__c , NSP_Job_Title__c
                            FROM NSP_Sub_Client_Contact__c
                            WHERE (
                                ( ( NSP_Payroll_Contact__c = true ) OR ( NSP_On_Site_Supervisor__c = true ) )
                                AND ( ( NSP_Paid_Non_Paid__c =: NSP_ServiceConstants.PAID_NON_PAID_WSEE ) OR ( NSP_Paid_Non_Paid__c =: NSP_ServiceConstants.PAID_NON_PAID_ACTIVE ) )
                                AND ( NSP_Employee_Status__c != :NSP_ServiceConstants.TERMINATED_STATUS )
                                AND ( NSP_Sub_Client__c IN :subclientIds )
                                AND ( ( NSP_Work_email__c != null ) OR ( NSP_Contact__r.NSP_Work_email__c != null ) )
                            )
                        ]
                    )
                {
                    if ( !mapAccountIdSetContactEmail.containsKey( scc.NSP_Sub_Client__r.NSP_Account__c ) ) {
                        mapAccountIdSetContactEmail.put( scc.NSP_Sub_Client__r.NSP_Account__c , new Set<String>() );
                    }
                    Set<String> toEmailSet =  mapAccountIdSetContactEmail.get( scc.NSP_Sub_Client__r.NSP_Account__c );
                    if ( scc.NSP_Work_Email__c != null ) {
                        toEmailSet.add( scc.NSP_Work_email__c );
                    } else if ( ( scc.NSP_Contact__c != null ) && ( scc.NSP_Contact__r.NSP_Work_email__c != null ) ) {
                        toEmailSet.add( scc.NSP_Contact__r.NSP_Work_email__c );
                    }
                    mapAccountIdSetContactEmail.put( scc.NSP_Sub_Client__r.NSP_Account__c , toEmailSet );
                }
            }

            if(!accountIdProjectTaskMap.values().isEmpty()){

                List<EmailTemplate> templates =[SELECT Id, BrandTemplateId, Subject, HTMLValue, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName =:NSP_ServiceConstants.CONGRATULATIONTEMPLATE];
                EmailTemplate template = null;
                if ( !templates.isEmpty() ) {
                    template = templates[0];
                }

                for(Id accId: accountIds){

                    List<String> listOfTOAddresses= new List<String>();
                    listOfTOAddresses.addAll(mapAccountIdSetContactEmail.get(accId));
                    List<String> listOfCCAddresses=new List <String>();
                    pse__Proj__c proj = mapofAccountIds.get(accId);
                        if(mapofccEmailSet.containsKey(mapofAccountIds.get(accId).Id)&& mapofccEmailSet.get(mapofAccountIds.get(accId).Id).size()>0){
                            listOfCCAddresses.addAll(mapofccEmailSet.get(mapofAccountIds.get(accId).Id));

                        }
                        if(mapOfAccountTeamEmail.containsKey(accId) && mapOfAccountTeamEmail.get(accId).size()>0){
                            listOfCCAddresses.addAll(mapOfAccountTeamEmail.get(accId));
                        }


                    if(!listOfTOAddresses.isEmpty()){
                        String mailBody = getMailBody(proj, template.Id);
                        String fromAddress = null;
                        List<User> records = [SELECT Email FROM User WHERE (Id = :Userinfo.getUserId())];
                        if(!records.isEmpty()){
                            fromAddress = records[0].Email;
                        }
                        String subjectString = '';
                        if ( ( proj != null )
                            && String.isNotBlank( proj.NSP_Account__c )
                            && String.isNotBlank( proj.NSP_RET_Client_ID__c )
                            )
                        {
                            subjectString = proj.NSP_Account__c +' ('+ proj.NSP_RET_Client_ID__c+')'+ ' – ';
                        }
                        if(template!=null){
                            subjectString = subjectString + template.subject;
                        }
                        sendMail(
                            subjectString,
                            mailBody,
                            listOfTOAddresses,
                            null,
                            listOfCCAddresses,
                            fromaddress,
                            accountIdProjectTaskMap.get(accId),
                            template.Id
                        );
                    }
                }

            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTaskTriggerEmailNotification.class.getName() ,
                'emailNotifyforFirstPayrollFSO' ,
                e
            );
        }
    }

    //
    // MethodName: emailNotifyforFirstPayrollMM
    // Description : This Method send email notification when first payroll approved subtask  task completed
    // Params:       Map <Id, pse__Project_Task__c >newMapProjecttasks, Map <Id, pse__Project_Task__c >oldMapProjecttasks
    //
    public static void emailNotifyforFirstPayrollMM( Set<Id> projectIds , Map<Id,Id> accountIdProjectTaskMap ) {
        Set<Id> accountIds =new Set<Id>();
        Map<Id, pse__Proj__c> mapofAccountIds = new Map<Id,pse__Proj__c>();
        Set<Id> subclientIds =new Set<Id>();
        Set<Id> projectIdset = new Set<Id>();
        Map<Id, Set<Id>> mapofSubclientIds = new Map<Id,Set<Id>>();
        Map<Id, Set<String>> mapAccIdSetConEmail = new Map<Id, Set<String>>();
        Map<Id, List<String>> mapofccEmailSet = new Map<Id, List<String>>();
        Map<Id, Set<String>> mapOfAccountTeamEmail=new Map<Id,Set<String>>();// map of Account team id, cc email address


        try{
            for(pse__Proj__c proj:[SELECT Id, pse__Account__c,Project_Team_Payroll_Specialist__c,
                                      (SELECT NSP_Assignee__c, NSP_Assignee__r.Name,
                                      NSP_Assignee__r.NSP_Work_email__c, NSP_Assignee__r.NSP_Work_Phone__c
                                      FROM Project_Teams__r
                                      WHERE NSP_Role__c=:NSP_ServiceConstants.PAYROLL_SPECIALIST
                                      AND NSP_Assignee__c !=null)  from pse__Proj__c
                                      WHERE Id in:projectIds AND recordTypeId=:peoProjectRecordTypeId AND TemplateName__c =:label.Middle_Market_Implementation_Project
                                      AND pse__Project_Status__c NOT IN : listOfProjectStatus ]){
                          mapofAccountIds.put(proj.pse__Account__c, proj);
                          accountIds.add(proj.pse__Account__c);
                          projectIdset.add(proj.Id);

            }

             //fetch all users of FSO IP to adddress cc
             List<String> ccAddress = new List<String>();
            if(!projectIdset.isEmpty()){
                for(Implementation_Profile__c imp: [SELECT Id, NSP_Project__c,  NSP_Payroll_Project_Manager__c, NSP_Payroll_Project_Manager__r.NSP_Work_email__c, NSP_Project_Manager__c, NSP_Project_Manager__r.NSP_Work_email__c,
                                                    NSP_Account_Executive__c, NSP_Account_Executive__r.NSP_Work_email__c,NSP_HR_Specialist__c, NSP_HR_Specialist__r.NSP_Work_email__c
                                                    FROM Implementation_Profile__c WHERE NSP_Project__c in:projectIdset ]){

                    if(String.isNotBlank(imp.NSP_Payroll_Project_Manager__r.NSP_Work_email__c)){
                        ccAddress.add(imp.NSP_Payroll_Project_Manager__r.NSP_Work_email__c);
                    }
                    if(String.isNotBlank(imp.NSP_Project_Manager__r.NSP_Work_email__c)){
                        ccAddress.add(imp.NSP_Project_Manager__r.NSP_Work_email__c);
                    }
                    if(String.isNotBlank(imp.NSP_Account_Executive__r.NSP_Work_email__c)){
                        ccAddress.add(imp.NSP_Account_Executive__r.NSP_Work_email__c);
                    }
                    if(String.isNotBlank(imp.NSP_HR_Specialist__r.NSP_Work_email__c)){
                        ccAddress.add(imp.NSP_HR_Specialist__r.NSP_Work_email__c);
                    }

                    mapofccEmailSet.put(imp.NSP_Project__c, ccAddress);
                }
            }
            if(!accountIds.isEmpty()){
               //get all Business Performance Advisor and/or Business Performance Consultant, payroll specialist from account team for cc address
                Set<String> accountTeamccAddress = new Set<String>();

                for(NSP_Account_Team__c accTeam: [SELECT NSP_Account__c,NSP_User__c, NSP_User__r.Name, NSP_User__r.Title,NSP_Role__c,  NSP_Email__c
                                                  FROM NSP_Account_Team__c
                                                  WHERE (NSP_Role__c=:NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR OR
                                                         NSP_Role__c=:NSP_ServiceConstants.BUSINESS_PERFORMANCE_CONSULTANT)
                                                  AND NSP_User__c!=NULL AND NSP_Account__c IN: accountIds] ){
                    if(accTeam.NSP_Role__c==NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR && String.isNotBlank(accTeam.NSP_Email__c)){
                        accountTeamccAddress.add(accTeam.NSP_Email__c);
                    }
                    if(accTeam.NSP_Role__c==NSP_ServiceConstants.BUSINESS_PERFORMANCE_CONSULTANT && String.isNotBlank(accTeam.NSP_Email__c)){
                        accountTeamccAddress.add(accTeam.NSP_Email__c);
                    }
                    mapOfAccountTeamEmail.put(accTeam.NSP_Account__c, accountTeamccAddress);

                }
                //get all sublcients related to mm project account
                for(NSP_Sub_Client__c sc: [SELECT Id,NSP_Account__c from NSP_Sub_Client__c  WHERE NSP_Account__c IN:accountIds]){
                        if(!mapofSubclientIds.containsKey(sc.NSP_Account__c)){
                          mapofSubclientIds.put(sc.NSP_Account__c, new Set<Id>());
                        }
                            mapofSubclientIds.get(sc.NSP_Account__c).add(sc.Id) ;
                            subclientIds.add(sc.Id);
                    }
            }

            //fetch all contacts  email who has On-site Supervisor and payroll contacts for to address

            if(!subclientIds.isEmpty()){

                    for(NSP_Sub_Client_Contact__c scc: [SELECT Id, NSP_Contact__c, NSP_Sub_Client__c,NSP_Sub_Client__r.NSP_Account__c,NSP_Contact__r.NSP_Work_email__c, NSP_Contact__r.Name, NSP_Contact__r.NSP_Work_Phone__c, NSP_Payroll_Contact__c, NSP_On_Site_Supervisor__c, NSP_Job_Title__c from NSP_Sub_Client_Contact__c
                                                           WHERE (NSP_Payroll_Contact__c=TRUE OR NSP_On_Site_Supervisor__c=TRUE) AND  NSP_Sub_Client__c IN :subclientIds
                                                       AND NSP_Contact__r.NSP_Work_email__c !=null]){

                          if(!mapAccIdSetConEmail.containsKey(scc.NSP_Sub_Client__r.NSP_Account__c)){
                          mapAccIdSetConEmail.put(scc.NSP_Sub_Client__r.NSP_Account__c, new Set<String>());
                        }
                        Set<String> toEmailSet =  mapAccIdSetConEmail.get(scc.NSP_Sub_Client__r.NSP_Account__c);
                        toEmailSet.add(scc.NSP_Contact__r.NSP_Work_email__c);
                        mapAccIdSetConEmail.put(scc.NSP_Sub_Client__r.NSP_Account__c,toEmailSet);
                    }
            }

            if(!accountIdProjectTaskMap.values().isEmpty()){
                List<EmailTemplate> templates =[SELECT Id, BrandTemplateId, Subject, HTMLValue, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName =:NSP_ServiceConstants.CONGRATULATIONTEMPLATEMM];
                EmailTemplate template = null;
                if ( !templates.isEmpty() ) {
                    template = templates[0];
                }
                String fromAddress=[select email from User WHERE id=:Userinfo.getUserId()].email;

                for(Id accId: accountIds){

                    List<String> listOfTOAddresses=new List <String>();
                    listOfTOAddresses.addAll(mapAccIdSetConEmail.get(accId));
                    List<String> listOfCCAddresses=new List <String>();
                    pse__Proj__c proj = mapofAccountIds.get(accId);
                    if(mapofccEmailSet.containsKey(mapofAccountIds.get(accId).Id)&& mapofccEmailSet.get(mapofAccountIds.get(accId).Id).size()>0){
                        listOfCCAddresses.addAll(mapofccEmailSet.get(mapofAccountIds.get(accId).Id));

                    }
                    if(mapOfAccountTeamEmail.containsKey(accId) && mapOfAccountTeamEmail.get(accId).size()>0){
                        listOfCCAddresses.addAll(mapOfAccountTeamEmail.get(accId));
                    }

                    if(!listOfTOAddresses.isEmpty()){
                        String mailBody = getMailBody(proj, template.Id);
                        sendMail(template.Subject,mailBody,listOfTOAddresses,null,listOfCCAddresses,
                                fromAddress,accountIdProjectTaskMap.get(accId), template.Id);

                    }
                    }
                }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTaskTriggerEmailNotification.class.getName() ,
                'emailNotifyforFirstPayrollMM' ,
                e
            );
        }
    }
    private static List<String> getContactsEmailList(Set<Id> contactIds){

        List<String> emailList=new List<String>();
        if(!contactIds.isEmpty()){
            for(Contact  cc:[SELECT Id, Name, NSP_Work_email__c, NSP_Work_Phone__c from Contact WHERE Id in:contactIds]){
                emailList.add(cc.NSP_Work_email__c);
            }
        }

        return emailList;
    }

    public static void sendFundingDocumentMail(String aimsClient, String aimsClientName, String jobTitle, list<String> listOfTOAddresses, String projectManager, List<Messaging.EmailFileAttachment> emailAttachments, String prjTaskId){
        //email template for funding documents
        String subjectString = aimsClientName+' ('+aimsClient+')'+' – Funding Documents ';
        String mailBody ='The funding documents for ' +aimsClientName+' ('+aimsClient+')';
        mailBody += ' are attached.'+'<br/><br/>';
        mailBody += 'Regards,'+'<br/>';
        mailBody += projectManager+'<br/>';
        mailBody += jobTitle;

        sendMail(subjectString,mailBody,listOfTOAddresses,emailAttachments,null, null, prjTaskId, null);

    }

    public static void sendMailFEIN(String aimsClient, String aimsClientName, String jobTitle, list<String> listOfTOAddresses,
                                            list<String> listOfCCAddresses, String projectManager, List<Messaging.EmailFileAttachment> emailAttachments, String prjcTaskId){

                                                //email template for FEIN Document
        String subjectString = aimsClientName+' ('+aimsClient+')'+' – IRS Documentation collected ';
        String mailBody ='The IRS Documentation for ' +aimsClientName+' ('+aimsClient+')';
        mailBody += ' has been collected and is attached.'+'<br/><br/>';
        mailBody += 'Regards,'+'<br/>';
        mailBody += projectManager+'<br/>';
        mailBody += jobTitle;

        sendMail(subjectString,mailBody,listOfTOAddresses,emailAttachments,listOfCCAddresses,null, prjcTaskId, null);
    }




    public static void sendMail(String subjectString, String mailBody, list<String> listOfTOAddresses,
                                 List<Messaging.EmailFileAttachment> emailAttachments,
                                list<String> listOfCCAddresses){
         sendMail(subjectString,mailBody,listOfTOAddresses,emailAttachments,listOfCCAddresses,null,null, null);
    }

    public static void sendMail(String subjectString, String mailBody, list<String> listOfTOAddresses,
                                 List<Messaging.EmailFileAttachment> emailAttachments,
                                list<String> listOfCCAddresses, String fromAddress, Id targetId, Id templateId){

        //set template structure for the email template
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        if(listOfTOAddresses!=null && listOfTOAddresses.size()>0){
            email.setToAddresses(listOfTOAddresses);
        }

        if(listOfCCAddresses!=null && listOfCCAddresses.size()>0){
            email.setCcAddresses(listOfCCAddresses);
        }

        if(subjectString!=null && !String.isBlank(subjectString)){
            email.setSubject(subjectString);
        }

        if(mailBody!=null && !String.isBlank(mailBody)){
            email.setHtmlBody(mailBody);
        }

        if(emailAttachments!=null && emailAttachments.size()>0){
            email.setFileAttachments(emailAttachments);
        }
        if(targetId!=null && !String.isBlank(targetId)){
            email.setWhatId(targetId);
        }
        if(templateId!=null && !String.isBlank(templateId)){
            email.setTemplateId(templateId);
        }
        email.setSaveAsActivity(true);
        email.setTargetObjectId(UserInfo.getUserId());
        email.setTreatTargetObjectAsRecipient(false);
        if(fromAddress!=null && !String.isBlank(fromAddress)){
            email.setSenderDisplayName(fromAddress);
          }
          else{
              if(Label.NSP_OrgWideEmail_Insperity != null){
                  email.setOrgWideEmailAddressId(Label.NSP_OrgWideEmail_Insperity);
              }
          }
        if ( !System.Test.isRunningTest()
            && EmailDeliverabilityController.isEnabledOutbound
            )
        {
            Messaging.sendEmail( new Messaging.SingleEmailMessage[]{ email } );
        }
    }

    public static void emailNotifyforCobraFollowUp(Set<Id> setProjectTaskIds, List<pse__Project_Task__c> projectTaskList ){

        List<Messaging.SingleEmailMessage> lstEmailMessage = new List<Messaging.SingleEmailMessage>();
        Map<Id,List<Messaging.EmailFileAttachment>> mapTaskIdListAttachments = new  Map<Id,List<Messaging.EmailFileAttachment>>();
        try{

            NSP_PEO_Implementations__mdt pI = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.COBRA_FOLLOWUP);

            // map of Project task and List of attachments

            if(!setProjectTaskIds.isEmpty()){
                mapTaskIdListAttachments = NSP_EmailServiceAttachment.getProjectTaskAttachments(setProjectTaskIds);
                getEmailTemplates();

            }

            for(pse__Project_Task__c projectTask: projectTaskList){
                           String[] toAddresses= new List<String>{pI.NSP_Email_Address__c};
                               List<Messaging.EmailFileAttachment>  emailAttachmentList = mapTaskIdListAttachments?.get((projectTask.Id));
                           lstEmailMessage.add(sendMail(mapOfEmailTempaltes.get(NSP_ServiceConstants.COBRA_FOLLOWUP), projectTask, toAddresses, emailAttachmentList));


            }
            if ( !lstEmailMessage.isEmpty()
                && EmailDeliverabilityController.isEnabledOutbound
                )
            {
                Messaging.sendEmail( lstEmailMessage , false );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTaskTriggerEmailNotification.class.getName() ,
                'emailNotifyforCobraFollowUp' ,
                e
            );
        }
    }

    public static Messaging.SingleEmailMessage sendMail(EmailTemplate et, pse__Project_Task__c projTask, String[] toAddresses, List<Messaging.EmailFileAttachment> emailAttachments ){
        //set template structure for the email template
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTemplateId(et.Id);
        email.setToAddresses(toAddresses);
        email.setWhatId(projTask.Id);
        email.setSaveAsActivity(true);
        email.setTargetObjectId(UserInfo.getUserId());
        email.setTreatTargetObjectAsRecipient(false);
        email.setUseSignature(false);
        email.setFileAttachments(emailAttachments);
        if(Label.NSP_OrgWideEmail_Insperity != null){
            email.setOrgWideEmailAddressId(Label.NSP_OrgWideEmail_Insperity);
        }
        return email;
    }

    //
    // MethodName: emailNotifyClientTransition
    // Description : This Method send email notification when project task completed
    // Params:       Map <Id, pse__Project_Task__c >newMapProjecttasks, Map <Id, pse__Project_Task__c >oldMapProjecttasks
    //
    public static void emailNotifyClientTransition( Map<Id,Id> mapofProjectTask ,  Map<Id,Id> mapOfProjectTaskOwner ) {
        Map<Id, User> mapOfUser = new Map<Id, User>();

        //fetch project owner details like name, title
        if(mapOfProjectTaskOwner.size()>0){
            for(User userRec:[SELECT Name, Title from User WHERE Id in : mapOfProjectTaskOwner.values() ]){
                mapOfUser.put(userRec.Id, userRec);

            }
        }
        try{
            //send email to the set of users for which the project is of fso implementation type
            for(pse__Proj__c proj:[select Id,pse__Account__c,pse__Account__r.Name, NSP_RET_Client_ID__c from pse__Proj__c WHERE Id in:mapofProjectTask.keyset() AND pse__Project_Type__c=:NSP_ServiceConstants.ImplementationProjectType AND recordTypeId=:peoProjectRecordTypeId
                AND  TemplateName__c=:label.FSOImplementationProject AND pse__Project_Status__c NOT IN : listOfProjectStatus ]){
                    User user=mapOfUser.get(mapOfProjectTaskOwner.get(proj.Id));
                    sendClientTransitionMail(proj.Id, proj.pse__Account__r.Name, proj.NSP_RET_Client_ID__c, user.Name,user.Title,mapofProjectTask.get(proj.Id) );

            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTaskTriggerEmailNotification.class.getName() ,
                'emailNotifyClientTransition' ,
                e
            );
        }
    }

    //
    // MethodName: sendClientTransitionMail
    // Description : This Method prepare email template
    //
    public static void sendClientTransitionMail(
        String projectId ,
        String aimsClientName ,
        String aimsClient ,
        String projectTaskOwner ,
        String jobTitle ,
        String projectTaskId
        )
    {
        //email template for Client Transition
        NSP_PEO_Implementations__mdt pf = NSP_PEO_Implementations__mdt.getInstance(INTERNAL_DISCOVERY_FN);
        NSP_PEO_Implementations__mdt pf1 = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.ALLOSCOORDINATOR);
        NSP_PEO_Implementations__mdt pf3 = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.ORIENTCOORDINATOR);

        List<String> listOfToAddresses = new List<String>();
        listOfTOAddresses.add(pf.NSP_Email_Address__c);
        listOfTOAddresses.add(pf1.NSP_Email_Address__c);
        listOfTOAddresses.add(pf3.NSP_Email_Address__c);

        String subjectString = 'Client Transition Meeting for ';
        String mailBody ='The Client Transition Meeting for '  ;
        for(Implementation_Profile__c ip: [
                    SELECT
                    Id, NSP_AIMS_Client_Name__c, NSP_AIMS_ClientNo__c,
                    NSP_Transition_Specialist__c,NSP_Transition_Specialist__r.NSP_Work_email__c,
                    NSP_OT_Representative__c,NSP_OT_Representative__r.NSP_Work_email__c,
                    NSP_Client_Liaison__c,NSP_Client_Liaison__r.NSP_Work_email__c,
                    NSP_Payroll_Specialist__c,NSP_Payroll_Specialist__r.NSP_Work_email__c,
                    NSP_HR_Specialist__c,NSP_HR_Specialist__r.NSP_Work_email__c,
                    NSP_HR_Quality_Support_Team_Member__c,
                    NSP_HR_Quality_Support_Team_Member__r.NSP_Work_email__c
                    FROM Implementation_Profile__c
                    WHERE ( NSP_Project__c = :projectId )
                ]
            )
        {
            subjectString   +=  ip.NSP_AIMS_Client_Name__c +' ('+ip.NSP_AIMS_ClientNo__c+') '+' is complete';
            mailBody+=  ip.NSP_AIMS_Client_Name__c + ' ('+ip.NSP_AIMS_ClientNo__c+'), ';
            if(ip.NSP_Transition_Specialist__c!=null && ip.NSP_Transition_Specialist__r.NSP_Work_email__c!=null){
                listOfTOAddresses.add(ip.NSP_Transition_Specialist__r.NSP_Work_email__c);
            }
            if(ip.NSP_OT_Representative__c!=null && ip.NSP_OT_Representative__r.NSP_Work_email__c!=null){
                listOfTOAddresses.add(ip.NSP_OT_Representative__r.NSP_Work_email__c);
            }
            if(ip.NSP_Client_Liaison__c!=null && ip.NSP_Client_Liaison__r.NSP_Work_email__c!=null){
                listOfTOAddresses.add(ip.NSP_Client_Liaison__r.NSP_Work_email__c);
            }
            if(ip.NSP_Payroll_Specialist__c!=null && ip.NSP_Payroll_Specialist__r.NSP_Work_email__c!=null){
                listOfTOAddresses.add(ip.NSP_Payroll_Specialist__r.NSP_Work_email__c);
            }
            if(ip.NSP_HR_Specialist__c!=null && ip.NSP_HR_Specialist__r.NSP_Work_email__c!=null){
                listOfTOAddresses.add(ip.NSP_HR_Specialist__r.NSP_Work_email__c);
            }
            if ( ( ip.NSP_HR_Quality_Support_Team_Member__c != null )
                && ( ip.NSP_HR_Quality_Support_Team_Member__r.NSP_Work_email__c != null )
                )
            {
                listOfTOAddresses.add( ip.NSP_HR_Quality_Support_Team_Member__r.NSP_Work_email__c );
            }
        }
        mailBody+='is complete.'+'<br/>';
        mailBody += 'Please refer to the Implementation Profile in Salesforce ';
        mailBody+='for information regarding your client, including payroll frequency information. '+'<br/><br/>';
        mailBody += 'Regards,'+'<br/>';
        mailBody += projectTaskOwner+'<br/>';
        mailBody += jobTitle;
        if(!listOfTOAddresses.isEmpty()){
            sendMail(subjectString,mailBody,listOfToAddresses,null,null,null,projectTaskId,null);
        }
    }

    //
    // MethodName: emailNotifyOnsiteDiscovery
    // Description : This Method send email notification when  On-Site Discovery Meeting  project task completed
    // Params:       Map <Id, pse__Project_Task__c >newMapProjecttasks, Map <Id, pse__Project_Task__c >oldMapProjecttasks
    //
    public static void emailNotifyOnsiteDiscovery( Map<Id,Id> mapofProjectTask , Map<Id,Id> mapOfProjectTaskOwner ) {
        Map<Id, User> mapOfUser = new Map<Id, User>();
        //fetch all the project where On-Site Discovery Meeting  project task is completed
        NSP_PEO_Implementations__mdt pf = NSP_PEO_Implementations__mdt.getInstance(ONSITE_DISCOVERY_FN);

        List<String> listOfToAddresses = new List<String>();
        listOfToAddresses.add(pf.NSP_Email_Address__c);

        if(mapOfProjectTaskOwner.size()>0){
            for(User userRec:[SELECT Name, Title,Email from User WHERE Id in : mapOfProjectTaskOwner.values() ]){
                mapOfUser.put(userRec.Id, userRec);

            }
        }
        try{
            //send email to the set of users for which the project is of MM implementation type
            for(pse__Proj__c proj:[SELECT Id,pse__Account__c,pse__Account__r.Name, NSP_RET_Client_ID__c,
                (SELECT Id,NSP_Role__c,NSP_Assignee__c, NSP_Assignee__r.NSP_Work_email__c FROM Project_Teams__r  WHERE Id!=NULL)
                FROM pse__Proj__c WHERE Id in:mapofProjectTask.keyset() AND pse__Project_Type__c=:NSP_ServiceConstants.ImplementationProjectType AND recordTypeId=:peoProjectRecordTypeId
                AND TemplateName__c =:label.Middle_Market_Implementation_Project AND pse__Project_Status__c NOT IN : listOfProjectStatus ]){

                    if(proj.Project_Teams__r.size()>0){
                        for(NSP_Project_Team__c projTeam : proj.Project_Teams__r){
                            if(projTeam.NSP_Role__c == NSP_ServiceConstants.SrHrSpecialist && projTeam.NSP_Assignee__c!=null && projTeam.NSP_Assignee__r.NSP_Work_email__c!=null){
                                listOfTOAddresses.add(projTeam.NSP_Assignee__r.NSP_Work_email__c);
                            }
                            if(projTeam.NSP_Role__c == NSP_ServiceConstants.AccountExecutive && projTeam.NSP_Assignee__c!=null && projTeam.NSP_Assignee__r.NSP_Work_email__c!=null){
                                listOfTOAddresses.add(projTeam.NSP_Assignee__r.NSP_Work_email__c);
                            }
                            if(projTeam.NSP_Role__c == NSP_ServiceConstants.PAYROLL_SPECIALIST && projTeam.NSP_Assignee__c!=null && projTeam.NSP_Assignee__r.NSP_Work_email__c!=null){
                                listOfTOAddresses.add(projTeam.NSP_Assignee__r.NSP_Work_email__c);
                            }
                            if(projTeam.NSP_Role__c == NSP_ServiceConstants.PayrollProjectManager && projTeam.NSP_Assignee__c!=null && projTeam.NSP_Assignee__r.NSP_Work_email__c!=null){
                                listOfTOAddresses.add(projTeam.NSP_Assignee__r.NSP_Work_email__c);
                            }
                        }
                    }
                     User user=mapOfUser.get(mapOfProjectTaskOwner.get(proj.Id));
                    if(!listOfToAddresses.isEmpty()){
                        sendOnsiteDiscoveryMail(proj.Id, proj.pse__Account__r.Name, proj.NSP_RET_Client_ID__c, user,listOfToAddresses,mapofProjectTask.get(proj.Id) );
                    }

            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTaskTriggerEmailNotification.class.getName() ,
                'emailNotifyOnsiteDiscovery' ,
                e
            );
        }
    }

    //
    // MethodName : sendOnsiteDiscoveryMail
    // Description : This Method prepare email template
    //
    public static void sendOnsiteDiscoveryMail(
        String projectId ,
        String aimsClientName ,
        String aimsClient ,
        User who ,
        List<String> listOfToAddresses ,
        String projectTaskId
        )
    {
        //email template for Client Transition
        String subjectString = 'Discovery Meeting for ' + aimsClientName + ' is complete';
        String mailBody ='The Discovery meeting for ';
        mailBody += aimsClientName;
        mailBody += ' is complete.<br/>';
        mailBody += 'Please refer to the Implementation Profile for information regarding your Client.<br/><br/><br/>';
        mailBody += 'Regards,<br/>';
        mailBody += who.Name + '<br/>';
        mailBody += who.Title + '<br/>';
        mailBody += who.Email;
        NSP_ProjectTasksTriggerHelper.sendEmail(
            listOfTOAddresses ,
            subjectString ,
            mailBody ,
            projectTaskId
        );
    }

    private static void getEmailTemplates(){
        for(EmailTemplate iEmailTemplate : [SELECT Id, BrandTemplateId, Subject, HTMLValue, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName IN: EMAIL_TEMPLATES]){
            mapOfEmailTempaltes.put(iEmailTemplate.DeveloperName,iEmailTemplate);
        }
    }

    private static String getMailBody(pse__Proj__c proj, Id templateId){
        List<NSP_Project_Team__c> projTeamList = proj.Project_Teams__r;
        String mailBody;
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email=Messaging.renderStoredEmailTemplate(templateId, null ,proj.Project_Team_Payroll_Specialist__c);
                mailBody=email.htmlbody;
        return mailBody;

    }

    //
    // MethodName: emailNotifyforTasksOnRetProjectType
    // Description : This Method send email notification when submit Coversheet project task completed
    // Params: List<pse__Project_Task__c> retProjectTasks
    // Params: String emailTemplateName
    // Params: List<String> sendToList
    //
    public static void emailNotifyforTasksOnRetProjectType(
        List<pse__Project_Task__c> retProjectTasks ,
        String emailTemplateName ,
        List<String> sendToList
        )
    {
        Map<Id,boolean> completionEmailAlreadySent= new Map<Id,boolean>();
        List<Messaging.SingleEmailMessage> lstEmailMessages = new List<Messaging.SingleEmailMessage>();
        Map<Messaging.SingleEmailMessage,Id> emailMessageToProjectTaskMap = new Map<Messaging.SingleEmailMessage,Id>();
        Set<Id> projectTaskIds = new Set<Id>();
        try{
            //Store Ids of project tasks in set
            for(pse__Project_Task__c eachProjectTask : retProjectTasks){
                projectTaskIds.add(eachProjectTask.Id);
            }
            //get email template
            List<EmailTemplate> emailTemps =  [SELECT Id, BrandTemplateId, Subject, HTMLValue, Body, DeveloperName
                                        FROM EmailTemplate
                                        WHERE DeveloperName =: emailTemplateName LIMIT 1];
            EmailTemplate emailTemp = null;
            if ( !emailTemps.isEmpty() ) {
                emailTemp = emailTemps[0];
            }
            //get email message recs for already sent email
            for(EmailMessage eachEmailMessage : [SELECT ID,RelatedToId,Subject,HtmlBody,Status,ToAddress
                                                FROM EmailMessage
                                                WHERE RelatedToId IN: projectTaskIds ]){
                //check if email message already present with template subject
                if(eachEmailMessage.Subject.substring(0,10) == emailTemp.Subject.substring(0,10)){
                    completionEmailAlreadySent.put(eachEmailMessage.RelatedToId, true);
                }
            }

            if(emailTemp != null){
                //iterate over prject tasks to send email alert
                for(pse__Project_Task__c eachProjectTask : retProjectTasks){{
                        //check if email alert is already sent otherwise send one
                        if(completionEmailAlreadySent.get(eachProjectTask.Id) == null){
                            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                            email= Messaging.renderStoredEmailTemplate(emailTemp.Id, null ,eachProjectTask.pse__Project__c);
                            email.setTemplateId(emailTemp.Id);
                            email.setToAddresses(sendToList);
                            email.setWhatId(eachProjectTask.pse__Project__c);
                            lstEmailMessages.add(email);
                            emailMessageToProjectTaskMap.put(email,eachProjectTask.id);
                        }
                    }
                }
            }

            if ( !lstEmailMessages.isEmpty()
                && EmailDeliverabilityController.isEnabledOutbound
                )
            {
                Messaging.sendEmail( lstEmailMessages );
                createEmailMessageRec( emailMessageToProjectTaskMap );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTaskTriggerEmailNotification.class.getName() ,
                'emailNotifyforTasksOnRetProjectType' ,
                e
            );
        }
    }

    //
    // MethodName: createEmailMessageRec
    // Description : Create email message record for tracebility
    // Params: Map<Messaging.SingleEmailMessage,Id> emailMessageToProjectTaskMap
    //
    public static void createEmailMessageRec( Map<Messaging.SingleEmailMessage,Id> emailMessageToProjectTaskMap ) {
        List<EmailMessage> listEmailMessageRec = new List<EmailMessage>();
        try{
            //iterate over single email messages to create email message
            for(Messaging.SingleEmailMessage eachEmail : emailMessageToProjectTaskMap.keySet()){
                EmailMessage newEmailMessage = new EmailMessage();
                newEmailMessage.Subject = eachEmail.getSubject();
                newEmailMessage.htmlbody = eachEmail.getHtmlBody();
                newEmailMessage.RelatedToId = emailMessageToProjectTaskMap.get(eachEmail);
                newEmailMessage.status = '3';
                newEmailMessage.ToAddress = eachEmail.getToAddresses()[0];
                listEmailMessageRec.add(newEmailMessage);
            }
            //create email message recs
            if(!listEmailMessageRec.isEmpty()){
                Database.insert(listEmailMessageRec);
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjectTaskTriggerEmailNotification.class.getName() ,
                'createEmailMessageRec' ,
                e
            );
        }
    }

}
//