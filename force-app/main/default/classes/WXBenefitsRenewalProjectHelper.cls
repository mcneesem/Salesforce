// Helper class for creating projects and updating projects from batch
public with sharing class WXBenefitsRenewalProjectHelper {
    // test w/ NSP_WXBenefitsRenewalProjCreat_Test (91%)

    // Global Variabels
    @TestVisible
    private NSP_OpportunityTriggerServiceHelper opp = new NSP_OpportunityTriggerServiceHelper();

    //== Method to create Project based on asset, account and template
    public void createProjectFromTemplateBasedOnAccountAndAsset( List<Asset> assetList ) {
        try {
            List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest> projectList = WXBenefitsRenewalProjectHelper.getListOfProjects( assetList );
            if ( !projectList?.isEmpty() ) {
                // Receives one Project Id for Asset.
                Set<Id> projectResponseId = this.opp.createProjectAndDeleteBudget( projectList );
                if ( !projectResponseId?.isEmpty() ) {
                    List<Id> projectResponseList = new List<Id>( projectResponseId );
                    if ( !projectResponseList?.isEmpty()
                        && ( projectResponseList?.size() == 1 )
                        )
                    {
                        String projectId = projectResponseList[0];
                        if ( String.isNotBlank( projectId ) ) {
                            WXBenefitsRenewalProjectHelper.updateProjectFields( projectId , assetList );
                        }
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                WXBenefitsRenewalProjectHelper.class.getName() ,
                'createProjectFromTemplateBasedOnAccountAndAsset' ,
                e
            );
        }
    }

    //== Update the Project based on Account teams Information or send email based on project Id
    private static void updateProjectFields( String projectId , List<Asset> assetList ) {
        Set<String> accountIdSet = WXBenefitsRenewalProjectHelper.getAccountIdSet( assetList );
        List<NSP_Account_Team__c> accountTeams = WXBenefitsRenewalProjectHelper.getAccountTeams( accountIdSet );
        Map<String,NSP_Account_Team__c> benefitsAccountTeamMap = WXBenefitsRenewalProjectHelper.getAccountTeamsMap( accountTeams );
        pse__Proj__c project = WXBenefitsRenewalProjectHelper.getProjectDetailsBasedOnProjectId( projectId );
        if ( ( project != null )
            && ( project.pse__Account__c != null )
            && ( benefitsAccountTeamMap != null )
            && !benefitsAccountTeamMap?.isEmpty()
            && benefitsAccountTeamMap.containsKey( project.pse__Account__c )
            )
        {
            NSP_Account_Team__c team = benefitsAccountTeamMap.get( project.pse__Account__c );
            if ( team != null ) {
                project.Project_Implementer__c = team.NSP_User__c;
            }
            WXBenefitsRenewalProjectHelper.updateProjectFieldsAndDmlProcess( project );
        }
            WXBenefitsRenewalProjectHelper.sendSingleEmailMessage( project.Id ); 
    }

    //== Get Account Ids from Assets list
    private static Set<String> getAccountIdSet( List<Asset> records ) {
        Set<String> accountIdSet = new Set<String>();
        if ( ( records != null ) && !records.isEmpty() ) {
            for ( Asset record : records ) {
                if ( record.AccountId != null ) {
                    accountIdSet.add( record.AccountId );
                }
            }
        }
        return accountIdSet;
    }

    //== Get Account Team Member that are matching to the role
    private static Map<String,NSP_Account_Team__c> getAccountTeamsMap( List<NSP_Account_Team__c> accountTeams ) {
        Map<String,NSP_Account_Team__c> benefitsAccountTeamMap = new Map<String,NSP_Account_Team__c>();
        if ( ( accountTeams != null ) && !accountTeams.isEmpty() ) {
            for ( NSP_Account_Team__c team : accountTeams ) {
                if ( 'WX Open Enrollment Specialist'.equalsIgnoreCase( team.NSP_Role__c )
                    && (
                        !benefitsAccountTeamMap.containsKey( team.NSP_Account__c )
                        || ( team.NSP_Primary__c && !benefitsAccountTeamMap.get( team.NSP_Account__c ).NSP_Primary__c )
                        )
                    )
                {
                    benefitsAccountTeamMap.put( team.NSP_Account__c , team );
                }
            }
        }
        return benefitsAccountTeamMap;
    }

    //== Get Projects List based on Asset Records
    private static List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest> getListOfProjects( List<Asset> records ) {
        List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest> returnProjectList = 
            new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest>();
        if ( ( records != null ) && !records.isEmpty() ) {
            // Getting metadata record based on the fully qualified name
            Template_Key_and_Id_Mapping__mdt metadata = Template_Key_and_Id_Mapping__mdt.getInstance( 'NSP_WX_Benefits_Renewal_Project' );
            for ( Asset record : records ) {
                if ( ( record.accountId != null )
                    && ( metadata != null )
                    && String.isNotBlank( metadata.Template_ID__c )
                    )
                {
                    //Creating Project with WX Renewal Project Template
                    pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest projRequest =
                        new pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest(
                            record.AccountId ,
                            metadata.Template_ID__c ,
                            System.Today()
                        );
                    projRequest.ProjectName = metadata.Key__c;
                    returnProjectList.add( projRequest );
                }
            }
        }
        return returnProjectList;
    }

    /*************************************** DATA MAPPING AND DML **************** */
    //== Updating the projects
    private static void updateProjectFieldsAndDmlProcess( pse__Proj__c project ) {
        if ( project != null ) {
            List<Database.SaveResult> results = Database.update( new List<pse__Proj__c>{ project } , false );
            NSP_ErrorLogHandler.logResults(
                WXBenefitsRenewalProjectHelper.class.getName() ,
                'updateProjectFieldsAndDmlProcess' ,
                results
            );
        }
    }

    /*************************************** QUERIES  **************************** */
    //== Fetch account team members based on account Ids
    private static List<NSP_Account_Team__c> getAccountTeams( Set<String> accountIdSet ) {
        List<NSP_Account_Team__c> accountTeams = new List<NSP_Account_Team__c>();
        if ( ( accountIdSet != null ) && !accountIdSet.isEmpty() ) {
            accountTeams = [
                SELECT Id , NSP_User__c , NSP_Role__c , NSP_Account__c , NSP_Primary__c
                FROM NSP_Account_Team__c
                WHERE ( NSP_Account__c = :accountIdSet )
                WITH SECURITY_ENFORCED
                ORDER BY NSP_Primary__c DESC
            ];
        }
        return accountTeams;
    }

    //== Get project details based on project Id
    private static pse__Proj__c getProjectDetailsBasedOnProjectId( Id projectId ) {
        List<pse__Proj__c> projects = null;
        if ( projectId != null ) {
            projects = [
                SELECT Id , Name , TemplateName__c , RecordTypeId , Project_Implementer__c , pse__Account__c , pse__Start_Date__c
                FROM pse__Proj__c
                WHERE (
                    ( Id = :projectId )
                    AND ( TemplateName__c = 'WX Benefits Renewal Project' )
                )
                WITH SECURITY_ENFORCED
            ];
        }
        pse__Proj__c project = null;
        if ( ( projects != null ) && !projects.isEmpty() ) {
            project = projects[0];
        }
        return project;
    }

    /************************ SEND EMAIL MESSAGES ****************** */
    private static void sendSingleEmailMessage( Id projectId ) {
        try {
            EmailTemplate template = WXBenefitsRenewalProjectHelper.getEmailTemplate();
            List<String> toEmailAddressList = new List<String>();
            toEmailAddressList.add( System.label.NSP_WXCarrierEmail );
            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(
                template.Id ,
                null ,
                projectId
            );
            email.setTemplateId( template.Id );
            email.setToAddresses( toEmailAddressList );
            email.setWhatId( projectId );
            email.setSaveAsActivity( false );
            List<Messaging.SingleEmailMessage> lstEmailMessages = new List<Messaging.SingleEmailMessage>();
            lstEmailMessages.add( email );
            if ( !lstEmailMessages?.isEmpty() ) {
                NSP_GenericEmailUtility.sendSingleEmailMessages( lstEmailMessages , false ); //method to send emails
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                WXBenefitsRenewalProjectHelper.class.getName() ,
                'sendSingleEmailMessage' ,
                e
            );
        }
    }

    //== Get Template Information based on template Name
    private static EmailTemplate getEmailTemplate() {
        List<EmailTemplate> templates = [
            SELECT Id , DeveloperName
            FROM EmailTemplate
            WHERE ( DeveloperName = 'NSP_Project_Task_Assignment_Alert' )
        ];
        EmailTemplate template = null;
        if ( ( templates != null ) && !templates.isEmpty() ) {
            template = templates[0];
        }
        return template;
    }

}
//