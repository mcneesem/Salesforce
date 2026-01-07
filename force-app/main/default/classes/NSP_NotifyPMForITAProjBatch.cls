// Batch Class to send email alert when ITA project is created
public with sharing class NSP_NotifyPMForITAProjBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<sObject> {
    // test w/ NSP_NotifyPMForITAProjTest (80%)

    //
    // argument-free constructor is required to be "runnable"...
    //

    public NSP_NotifyPMForITAProjBatch() {
    }

    //
    // ISelfSchedulable
    //

    // runs everyday at 1am central...
    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_NotifyPMForITAProjBatch ~ When a project with the ITA - Implementation template is created for an account AND there is a WO Asset AND the AIMS First Pay Date is Null, then send email to select individuals ~ everyday at 1 AM' + suffix ,
            '0 0 1 ? * * *' ,
            new NSP_NotifyPMForITAProjBatch()
        );
    }

    //
    // Scheduleable
    //

    public void execute( SchedulableContext sc ) {
        this.call( 'run' , null );
    }

    //
    // Callable
    //

    public Object call( String action , Map<String,Object> args ) {
        Object response = null;
        if ( action == 'run' ) {
            response = this.run();
        }
        return response;
    }

    //
    // IJobRunnable
    //

    public Id run() {
        return Database.executeBatch( new NSP_NotifyPMForITAProjBatch() , 200 );
    }

    //
    // Batchable
    //

    // Start method to query project records
    public Database.QueryLocator start( Database.BatchableContext bc ) {
        return Database.getQueryLocator(
            [ SELECT Id ,
                NSP_RET_Client_ID__c ,
                NSP_Is_ITA_Mail_Sent__c ,
                pse__Account__c
              FROM pse__Proj__c
              WHERE (
                ( pse__Is_Template__c = false )
                    AND ( NSP_Is_ITA_Mail_Sent__c = false )
                    AND ( TemplateName__c LIKE '%ITA%Implementation%' )
                )
            ]
        );
    }

    // Execute method to send email alert when ITA project is created
    public void execute( Database.BatchableContext bc , List<pse__Proj__c> projList ) {
        try{
            List<String> sendTo = new List<String>();
            Set<ID> accountIDs = new Set<ID>();
            Set<ID> assetAccountIDs = new Set<ID>();
            Set<ID> acctIDsToupdate = new Set<ID>();
            Map<ID,ID> projAcctIDMap = new  Map<ID,ID>();
            List<pse__Proj__c> projListToUpdate = new List<pse__Proj__c>();
            Id woAssetRecordType = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
            Id ipFSORecordTypeId = NSP_GenericRecordType.getRecordTypeId('Implementation_Profile__c', NSP_ServiceConstants.FSOProfile);
            Id ipMMRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Implementation_Profile__c', NSP_ServiceConstants.MMProfile);
            // get account id set, create a map of proj id and account id from the project records
            for( pse__Proj__c projId:projList ) {
                if( projId.pse__Account__c != null ) {
                    accountIDs.add(projId.pse__Account__c);
                    projAcctIDMap.put(projId.ID,projId.pse__Account__c);
                }
            }
            // check if the linked account has a WO asset with NSP_AIMS_First_Pay_Date__c as null
            for( Asset asst : [
                        SELECT
                            Id ,
                            AccountId
                        FROM Asset
                        WHERE (
                            ( AccountId =: accountIDs )
                            AND ( RecordTypeId =: woAssetRecordType )
                            AND ( NSP_AIMS_First_Pay_Date__c = NULL )
                        )
                    ]
                )
            {
                assetAccountIDs.add(asst.AccountId);
            }
            Map<Id, List<String>> accountIdEmailListMap = new Map<Id, List<String>>();
            //Get proj manager email and payroll specialist emails from IP records (FSO/MM) under same accounts
            for( Implementation_Profile__c ip : [
                        SELECT
                            Id ,
                            NSP_Project__c ,
                            Account__c ,
                            NSP_Project_Manager__c ,
                            NSP_Payroll_Specialist__c ,
                            NSP_Project_Manager__r.NSP_Work_email__c ,
                            NSP_Payroll_Specialist__r.NSP_Work_email__c ,
                            NSP_Payroll_Project_Manager__c ,
                            NSP_Payroll_Project_Manager__r.NSP_Work_email__c ,
                            RecordTypeId
                        FROM Implementation_Profile__c
                        WHERE (
                            ( Account__c IN : assetAccountIDs )
                            AND ( ( RecordTypeId = :ipFSORecordTypeId ) OR ( RecordTypeId = :ipMMRecordTypeId ) )
                            AND ( ( NSP_Project_Manager__c != NULL ) OR ( NSP_Payroll_Specialist__c != NULL ) OR ( NSP_Payroll_Project_Manager__c != NULL ) )
                            AND (
                                NSP_Project__r.pse__Project_Status__c NOT IN (
                                    'Complete' ,
                                    'Cancelled' ,
                                    'Close/Lost' ,
                                    'Quality Review' ,
                                    'Closed Prior to CQA'
                                )
                            )
                        )
                    ]
                )
            {
                if( accountIdEmailListMap.containsKey(Ip.Account__c) ) {
                    if( ip.NSP_Project_Manager__c!=null && ip.NSP_Project_Manager__r.NSP_Work_email__c != null ) {
                        List<String> emailIdList = accountIdEmailListMap.get(Ip.Account__c);
                        emailIdList.add(ip.NSP_Project_Manager__r.NSP_Work_email__c);
                        accountIdEmailListMap.put(Ip.Account__c, emailIdList);
                    }

                    if( ip.RecordTypeId==ipFSORecordTypeId && ip.NSP_Payroll_Specialist__c!=null &&
                        ip.NSP_Payroll_Specialist__r.NSP_Work_email__c!= null){
                            List<String> emailIdList = accountIdEmailListMap.get(Ip.Account__c);
                            emailIdList.add(ip.NSP_Payroll_Specialist__r.NSP_Work_email__c);
                            accountIdEmailListMap.put(Ip.Account__c, emailIdList);
                        }

                    if(ip.RecordTypeId==ipMMRecordTypeId && ip.NSP_Payroll_Project_Manager__c!=null &&
                        ip.NSP_Payroll_Project_Manager__r.NSP_Work_email__c!= null){
                            List<String> emailIdList = accountIdEmailListMap.get(Ip.Account__c);
                            emailIdList.add(ip.NSP_Payroll_Project_Manager__r.NSP_Work_email__c);
                            accountIdEmailListMap.put(Ip.Account__c, emailIdList);
                        }
                } else {
                    acctIDsToupdate.add(ip.Account__c);
                    if(ip.NSP_Project_Manager__c!=null && ip.NSP_Project_Manager__r.NSP_Work_email__c!= null){
                        accountIdEmailListMap.put(Ip.Account__c, new List<String> {ip.NSP_Project_Manager__r.NSP_Work_email__c});
                    }

                    if(ip.RecordTypeId==ipFSORecordTypeId && ip.NSP_Payroll_Specialist__c!=null &&
                        ip.NSP_Payroll_Specialist__r.NSP_Work_email__c!= null){
                            if(accountIdEmailListMap.get(Ip.Account__c) == null){
                                accountIdEmailListMap.put(Ip.Account__c, new List<String> {ip.NSP_Payroll_Specialist__r.NSP_Work_email__c});
                            }else{
                                accountIdEmailListMap.get(Ip.Account__c).add(ip.NSP_Payroll_Specialist__r.NSP_Work_email__c);
                            }
                        }

                    if( ( ip.RecordTypeId == ipMMRecordTypeId )
                    && ( ip.NSP_Payroll_Project_Manager__c!=null )
                    && ( ip.NSP_Payroll_Project_Manager__r.NSP_Work_email__c != null ) ) {
                        if( accountIdEmailListMap.get(Ip.Account__c) == null ) {
                            accountIdEmailListMap.put(Ip.Account__c, new List<String> {ip.NSP_Payroll_Project_Manager__r.NSP_Work_email__c});
                        } else {
                            accountIdEmailListMap.get(Ip.Account__c).add(ip.NSP_Payroll_Project_Manager__r.NSP_Work_email__c);
                        }
                    }
                }
            }

            if(!projAcctIDMap.isEmpty() && !acctIDsToupdate.isEmpty()){
                projListToUpdate = updateProjList(projAcctIDMap,acctIDsToupdate);
            }
            if(!projListToUpdate.isEmpty() && !accountIdEmailListMap.isEmpty()){
                sendEmailToUsers(projListToUpdate,accountIdEmailListMap);
            }
            if(!projListToUpdate.isEmpty()){
                List<Database.SaveResult> results = Database.update( projListToUpdate , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_NotifyPMForITAProjBatch.class.getName() ,
                    'execute:update' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_NotifyPMForITAProjBatch.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    public void finish(Database.BatchableContext bc){

    }

   // Method to send email to the list of users emailaddress present in SendTo list
    public static void sendEmailToUsers(List<pse__Proj__c> projListToUpdate,  Map<Id, List<String>> accountIdEmailListMap){
        try{
            List<Messaging.SingleEmailMessage> lstEmailMessages = new List<Messaging.SingleEmailMessage>();
            List<id> listWithMail = new List<id>();
            // Send email to the PS to notify ITA proj creation
            List<String> emailTempFields = new List<String>{
                    'ID',
                    'BrandTemplateId',
                    'Subject',
                    'HTMLValue',
                    'Body',
                    'DeveloperName'
                    };
            EmailTemplate emailTemp = NSP_sObjectSelector.selectByDeveloperName(emailTempFields,NSP_ServiceConstants.ITA_Project_Creation_Email);
            //  [SELECT Id, BrandTemplateId, Subject, HTMLValue, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName = : NSP_ServiceConstants.ITA_Project_Creation_Email LIMIT 1];
            // check if Email template exists and if we have any sender email
            // Added for 235192
            if(!projListToUpdate.isEmpty()){
                for( EmailMessage emailList : [
                            SELECT
                                RelatedToId
                            FROM EmailMessage
                            WHERE (
                                ( RelatedToId IN: projListToUpdate )
                                AND ( Subject LIKE : label.NotifyITAEmail )
                            )
                        ]
                    )
                {
                    listWithMail.add(emailList.RelatedToId);
                }
            }
            if(emailTemp!=null && !accountIdEmailListMap.isEmpty()){
                for(pse__Proj__c projId : [SELECT Id, pse__Account__c FROM pse__Proj__c WHERE Id IN: projListToUpdate]){
                    if(accountIdEmailListMap.get(projId.pse__Account__c) != null && !listWithMail.contains(projId.Id) ){
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        email= Messaging.renderStoredEmailTemplate(emailTemp.Id, null ,projId.Id);
                        email.setTemplateId(emailTemp.Id);
                        email.setToAddresses(accountIdEmailListMap.get(projId.pse__Account__c));
                        email.setWhatId(projId.Id);
                        if(System.Label.NSP_OrgWideEmail_Insperity != null){
                            email.setOrgWideEmailAddressId(System.Label.NSP_OrgWideEmail_Insperity);
                        }
                        lstEmailMessages.add(email);
                    }
                }
            }
            //Send email to notify PM and PS
            if(!lstEmailMessages.isEmpty() && !Test.isRunningTest()){
                Messaging.sendEmail(lstEmailMessages);
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_NotifyPMForITAProjBatch.class.getName() ,
                'sendEmailToUsers' ,
                e
            );
        }
    }

    // Method to check if the account ids to update list has the account
    // and then mark NSP_Is_ITA_Mail_Sent__c field as TRUE on project to identify that email has been sent for the ITA project
    public static List<pse__Proj__c>  updateProjList(Map<Id,Id> projAcctIDMap, Set<Id> acctIDsToupdate){
        List<pse__Proj__c> projListToUpdate = new List<pse__Proj__c>();
        try{
            // create proj records with NSP_Is_ITA_Mail_Sent__c field as TRUE
            for(ID projID: projAcctIDMap.keySet()){
                if(acctIDsToupdate.contains(projAcctIDMap.get(projID))){
                    pse__Proj__c proj = new pse__Proj__c();
                    proj.ID =  projID;
                    proj.NSP_Is_ITA_Mail_Sent__c = TRUE;
                    projListToUpdate.add(proj);
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_NotifyPMForITAProjBatch.class.getName() ,
                'updateProjList' ,
                e
            );
        }
        return projListToUpdate;
    }

}
//