public with sharing class NSP_DunningEmailsMessageService {
    // test w/ NSP_DunningEmailNotificationsBatchTest (84%)

    public static List<Integer> processDunningEmails( List<dunningEmailParams> dparams ) {
        Set<Id> caseIds = new set<Id>();
        Map<String,String> templateIdMap = NSP_DunningEmailsMessageService.getTemplates( dparams );
        Map<String,String> caseTemplateMap = new Map<String,String>();
        Map<String,String> caseTemplateNameMap = new Map<String,String>();
        List<Integer> resultList = new List<Integer>{ 0, 0 };
        NSP_DunningEmailsMessageService.extractFromParams(
            dparams,
            templateIdMap,
            caseTemplateMap,
            caseTemplateNameMap,
            caseIds
        );
        //fetch important Case Fields using IDs
        List<Case> caseList = [
            SELECT Id , AccountId
            FROM Case
            WHERE (
                ( Id IN :caseIds )
                AND ( AccountId != null )
            )
        ];
        //get unique Accounts
        Set<Id> accountIds = new Set<Id>();
        if ( ( caseList != null ) && !caseList.isEmpty() ) {
            for ( Case cs : caseList ) {
                accountIds.add( cs.AccountId );
            }
        }
        //extract Contact emails from ACR records
        Map<String,Set<String>> accountIdToContactEmails = NSP_DunningEmailsMessageService.getEmails( accountIds );
        //send out emails for all Cases
        for ( Case cs : caseList ) {
            if ( String.isNotBlank( cs.AccountId )
                && accountIdToContactEmails.containsKey( cs.AccountId )
                && !accountIdToContactEmails.get(cs.AccountId).isEmpty()
                && caseTemplateMap.containsKey( cs.Id )
                && String.isNotBlank( caseTemplateMap.get( cs.Id ) )
                )
            {
                //flow will be called only for valid inputs
                Map<String,Object> inputs = new Map<String,Object>();
                inputs.put(
                    'toEmailAddresses' ,
                    NSP_DunningEmailsMessageService.getToAddress(
                        caseTemplateNameMap ,
                        accountIdToContactEmails ,
                        cs
                    )
                );
                inputs.put( 'emailTemplateId' , caseTemplateMap.get( cs.Id ) );
                inputs.put( 'recordId' , cs.Id );
                List<Integer> result = NSP_DunningEmailsMessageService.callSendEmailFlow( inputs );
                resultList[0] += result[0];
                resultList[1] += result[1];
            }
        }
        return resultList;
    }

    //method to get unique Case IDs and map Case with template IDs
    private static void extractFromParams(
        List<dunningEmailParams> dparams ,
        Map<String,String> templateIdMap ,
        Map<String,String> caseTemplateMap ,
        Map<String,String> caseTemplateNameMap ,
        Set<Id> caseIds
        )
    {
        if ( ( dparams != null ) && !dparams.isEmpty() ){
            for(dunningEmailParams dunningWrap : dparams){
                if( String.isNotBlank( dunningWrap.recordid )
                   && ( String.isNotBlank( dunningWrap.templateName ) )
                   && ( templateIdMap != null )
                   && ( templateIdMap.containsKey( dunningWrap.templateName ) )
                  )
                {
                    caseIds.add( dunningWrap.recordid );
                    caseTemplateMap.put( dunningWrap.recordid , templateIdMap.get( dunningWrap.templateName ));
                    caseTemplateNameMap.put( dunningWrap.recordid , dunningWrap.templateName );
                }
            }
        }
    }

    //method to call SendEmail Flow
    private static List<Integer> callSendEmailFlow( Map<String,Object> inputs ) {
        Integer successCount = 0;
        Integer failCount = 0;
        if ( inputs != null ) {
            try {
                Flow.Interview.Send_Email sendEmailFlow = new Flow.Interview.Send_Email( inputs );
                sendEmailFlow.start();
                successCount++;
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    NSP_DunningEmailsMessageService.class.getName() ,
                    'callSendEmailFlow' ,
                    e
                );
                failCount++;
            }
        }
        return new List<Integer>{ successCount , failCount };
    }

    //method to get template records in map
    private static Map<String,String> getTemplates( List<dunningEmailParams> dparams ) {
        Set<String> templateNames = new Set<String>();
        Map<String,String> templateIdMap = new Map<String,String>();
        if ( dparams != null ) {
            //get unique templates
            for ( dunningEmailParams dunningWrap : dparams ) {
                if ( String.isNotBlank( dunningWrap.templateName ) ) {
                    templateNames.add( dunningWrap.templateName );
                }
            }
            if ( !templateNames.isEmpty() ) {
                //map template names with IDs
                for ( EmailTemplate template : [
                            SELECT Id , DeveloperName
                            FROM EmailTemplate
                            WHERE ( DeveloperName IN :templateNames )
                        ]
                    )
                {
                    templateIdMap.put( template.DeveloperName , template.Id );
                }
            }
        }
        return templateIdMap;
    }

    private static Set<String> getToAddress(
        Map<String,String> caseTemplateNameMap ,
        Map<String,Set<String>> accountIdToContactEmails ,
        Case cs
        )
    {
        Set<String> toAddresses = new set<String>();
        if ( ( caseTemplateNameMap != null )
            && ( cs != null )
            && caseTemplateNameMap.containsKey( cs.Id )
            && ( caseTemplateNameMap.get( cs.Id ) == 'X135_Days_Past_Due' )
            )
        {
            toAddresses = NSP_DunningEmailNotificationsBatch.financeEmailAddresses;
        } else {
            if ( ( accountIdToContactEmails != null )
                && accountIdToContactEmails.containsKey( cs.AccountId )
                )
            {
                toAddresses = accountIdToContactEmails.get( cs.AccountId );
            }
        }
        return toAddresses;
    }

    //method to extract Emails from Contacts of ACR records for the Case Accounts
    private static Map<String,Set<String>> getEmails( Set<Id> accountIds ) {
        Map<String,Set<String>> accountIdToContactEmails = new Map<String,Set<String>>();
        if ( ( accountIDs != null ) && !accountIds.isEmpty() ) {
            for ( AccountContactRelation acr : [
                        SELECT
                            Id ,
                            Contact.Email ,
                            AccountId
                        FROM AccountContactRelation
                        WHERE (
                            ( AccountId IN :accountIds )
                            AND ( NSP_Dunning_Emails__c = true )
                            AND ( ContactId != null )
                        )
                    ]
                )
            {
                if ( String.isNotBlank( acr.AccountId ) && String.isNotBlank( acr.Contact.Email ) ) {
                    if ( !accountIdToContactEmails.containsKey( acr.AccountId ) ) {
                        accountIdToContactEmails.put( acr.AccountId , new Set<String>() );
                    }
                    Set<String> contactEmails = accountIdToContactEmails.get( acr.AccountId );
                    contactEmails.add( acr.Contact.Email );
                    accountIdToContactEmails.put( acr.AccountId , contactEmails );
                }
            }
        }
        return accountIdToContactEmails;
    }

    //
    //
    //

    public class dunningEmailParams {
        public String templateName;
        public String objectName;
        public String recordid;
        public dunningEmailParams( String tmpName , String objName , String recid ) {
            this.templateName = tmpName;
            this.objectName = objName;
            this.recordId = recid;
        }
    }

}
//