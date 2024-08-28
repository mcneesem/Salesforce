/**
*************************************************************
* 
* @description  : Batch Class to process the termination form for the email template.
* @author Shruti Patil
* @date : 10/18/2021
* Name : NSP_TerminationForm_Batch
*
*************************************************************
*/
global class NSP_TerminationForm_Batch implements Schedulable , Database.Batchable<SObject> , Database.Stateful {
    // test w/ NSP_TerinationForm_Batch_Test (88%)

    private List<String> ccEmailAddressList = new List<String>();

    public Database.QueryLocator start( Database.BatchableContext bc ) {
        return Database.getQueryLocator(
            [
                SELECT
                Id ,
                Name ,
                NSP_Last_Date_Wages_Paid_Through__c ,
                NSP_Status__c ,
                NSP_Term_Code__c ,
                NSP_Client_Term_Date__c ,
                NSP_Term_Reason__c ,
                NSP_Benefit_Termination_Date__c ,
                NSP_Project_Task__r.pse__Project__r.pse__Account__c ,
                NSP_Project_Task__r.pse__Project__r.pse__Account__r.Name ,
                NSP_Project_Task__r.pse__Project__r.pse__Account__r.NSP_AIMS_Client__c ,
                NSP_Project_Task__r.pse__Project__r.pse__Project_Status__c
                FROM NSP_Termination_Form__c
                WHERE (
                    NSP_Last_Date_Wages_Paid_Through__c = LAST_N_DAYS:22
                    AND NSP_Status__c = 'Term Team Approved'
                    AND NSP_Project_Task__r.pse__Project__r.pse__Project_Status__c != 'Complete'
                )
            ]
        );  
    }

    global void execute( Database.BatchableContext bc , List<NSP_Termination_Form__c> terminationsList ) {
        try {
            Set<Id> relatedAccoutIdSet = new Set<Id>();
            if ( ( terminationsList != null ) && !terminationsList.isEmpty() ) {
                for ( NSP_Termination_Form__c termination : terminationsList ) {
                    if ( ( termination != null )
                        && ( termination.NSP_Project_Task__r != null )
                        && ( termination.NSP_Project_Task__r.pse__Project__r != null )
                        && ( termination.NSP_Project_Task__r.pse__Project__r.pse__Account__c != null )
                        )
                    {
                        relatedAccoutIdSet.add( termination.NSP_Project_Task__r.pse__Project__r.pse__Account__c );
                    }
                }
            }
            Set<String> emailIdSet = new Set<String>();
            if ( !relatedAccoutIdSet.isEmpty() ) {
                for ( NSP_Account_Team__c AccTeamMember : [
                            SELECT Id, NSP_Role__c, NSP_Account__c, NSP_Email__c
                            FROM NSP_Account_Team__c 
                            WHERE (
                                NSP_Account__c IN :relatedAccoutIdSet
                                AND (
                                    NSP_Role__c = 'Manager,HR Services'
                                    OR NSP_Role__c = 'Payroll Specialist'
                                    OR NSP_Role__c = 'Payroll Supervisor'
                                    OR NSP_Role__c = 'Client Liaison'
                                    OR NSP_Role__c = 'HR Specialist'
                                    OR NSP_Role__c = 'Renewal Coordinator'
                                )
                            )
                        ]
                    )
                {
                    if ( AccTeamMember.NSP_Email__c != null ) {
                        emailIdSet.add( AccTeamMember.NSP_Email__c );
                    }
                }
            }
            ccEmailAddressList.addAll( emailIdSet );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_TerminationForm_Batch.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    public void finish( Database.BatchableContext bc ) {
        if ( String.isNotBlank( System.Label.NSP_TerminationFormBatchGenericToAddress ) ) {
            EmailTemplate emailTemplate = [SELECT Id, Body FROM EmailTemplate WHERE DeveloperName = 'NSP_Termination_Form_Email_Template'];
            List<String> toEmailAddressList = System.Label.NSP_TerminationFormBatchGenericToAddress.split(',');
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(toEmailAddressList);
            email.setSaveAsActivity(false);
            email.setTemplateId(emailTemplate.Id);
            email.setTargetObjectId(userinfo.getUserId());
            email.setCcAddresses(ccEmailAddressList);
            try {
                if ( !Test.isRunningTest() ) {
                    Messaging.sendEmail( new Messaging.SingleEmailMessage[]{ email } );
                }
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    NSP_TerminationForm_Batch.class.getName() ,
                    'finish' ,
                    e
                );
            }
        }
    }

    global void execute( SchedulableContext scon ) {
        Database.executeBatch( new NSP_TerminationForm_Batch() , 100 );
    }

    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_TerminationForm_Batch ~ everyweekday at 3:45 PM' + suffix ,
            '45 15 * * 1-5', // this is for Every week Day at 3:45 PM...
            new NSP_TerminationForm_Batch()
        );
    }

}