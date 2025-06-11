/**
 * AUTHOR: PRAKASH JADA
 * CREATED DATE: MAY 30, 2025
 * DESCRIPTION: Helper class for creating projects and updating projects from batch
 */

public with sharing class WXBenefitsRenewalProjectHelper
{
    // test w/ NSP_WXBenefitsRenewalProjCreat_Test (97%)
    
    // Global Variabels
    @TestVisible
    private NSP_OpportunityTriggerServiceHelper opp = new NSP_OpportunityTriggerServiceHelper();
    
    //== Method to create Project based on asset, account and template
    public void createProjectFromTemplateBasedOnAccountAndAsset(List<Asset> assetList)
    {
        List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest> projectList = getListOfProjects(assetList);
        
        try {
            if(!projectList?.isEmpty())
            {
                // Receives one Project Id for Asset.
                Set<Id> projectResponseId 				= opp.createProjectAndDeleteBudget(projectList);
                
                List<Id> projectResponseList = new List<Id>(projectResponseId);
                if(!projectResponseList?.isEmpty() && projectResponseList?.size() == 1 && projectResponseList[0] != null)
                {
                    string projectId = projectResponseList[0];
                    updateProjectFields(projectId, assetList);
                }
                
            }
        } catch (Exception ex) 
        {
            NSP_ErrorLogHandler.logException(
                WXBenefitsRenewalProjectHelper.class.getName() ,
                'createProjectFromTemplateBasedOnAccountAndAsset' ,
                 ex
                 );
        }
    }

    //== Update the Project based on Account teams Information or send email based on project Id
    private static void updateProjectFields(string projectId, List<Asset> assetList)
    {
        Set<String> accountIdSet 				= getAccountIdSet(assetList);
        List<NSP_Account_Team__c> accountTeams 	=  getAccountTeams(accountIdSet);
        
        // Get Project Details
        pse__Proj__c project 					= getProjectDetailsBasedOnProjectId(projectId);
        Map<String, NSP_Account_Team__c> benefitsAccountTeamMap;
        
        if(!accountTeams?.isEmpty())
        {
            benefitsAccountTeamMap = getAccountTeamsMap(accountTeams);
        }
        
        if(project != null && benefitsAccountTeamMap != null && !benefitsAccountTeamMap?.isEmpty() 
           && project.pse__Account__c != null 
           && benefitsAccountTeamMap.containsKey(project.pse__Account__c))
        {
            // Set project mapping and handle DML Operations
            updateProjectFieldsAndDMLProcess(project, benefitsAccountTeamMap);
        }else
        {
            sendSingleEmailMessage(project.Id);
        }
        
    }

    //== Get Account Ids from Assets list
    private static Set<String> getAccountIdSet(List<Asset> assetList)
    {
        Set<String> accountIdSet = new Set<String>();

        for(Asset asset : assetList)
        {
            if(Asset.AccountId != null)
            {
                accountIdSet.add(asset.AccountId);
            }
        }

        return accountIdSet;
    }

    //== Get Account Team Member that are matching to the role
    private static Map<String, NSP_Account_Team__c> getAccountTeamsMap(List<NSP_Account_Team__c> accountTeams)
    {
        Map<String, NSP_Account_Team__c> benefitsAccountTeamMap = new Map<String, NSP_Account_Team__c>();
        for(NSP_Account_Team__c team : accountTeams)
        {
            if ('WX Open Enrollment Specialist'.equalsIgnoreCase(team.NSP_Role__c) && (!benefitsAccountTeamMap.containsKey(team.NSP_Account__c) || 
                (team.NSP_Primary__c && !benefitsAccountTeamMap.get(team.NSP_Account__c).NSP_Primary__c)) ) 
            {
                benefitsAccountTeamMap.put(team.NSP_Account__c, team);
            }
        }

        return benefitsAccountTeamMap;
    }

    //== Get Projects List based on Asset Records
    private static List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest> getListOfProjects(List<Asset> assets)
    {
        List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest> returnProjectList = 
            new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest>();

            // Getting metadata record based on the fully qualified name
            Template_Key_and_Id_Mapping__mdt metadata = Template_Key_and_Id_Mapping__mdt.getInstance('NSP_WX_Benefits_Renewal_Project');
        // Iterating over the assets
        for(Asset asset : assets)
        {
            if(asset.accountId != null && metadata != null && string.isNotBlank(metadata?.Template_ID__c))
            {
                //Creating Project with WX Renewal Project Template
                pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest projRequest =
                new pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest(asset.AccountId, metadata.Template_ID__c, System.Today());
                projRequest.ProjectName = metadata.Key__c;
                returnProjectList.add(projRequest);
            } 
        }

        return returnProjectList;
    }

    /*************************************** DATA MAPPING AND DML **************** */
    //== Updating the projects
    private static void updateProjectFieldsAndDMLProcess(pse__Proj__c project,  Map<String, NSP_Account_Team__c> benefitsAccountTeamMap)
    {
        project.Project_Implementer__c = benefitsAccountTeamMap.get(project.pse__Account__c).NSP_User__c;

        // DML Operation
        Database.SaveResult result = Database.update( project , false );
        NSP_ErrorLogHandler.logResults(
            WXBenefitsRenewalProjectHelper.class.getName() ,
            'updateProjectFieldsAndDMLProcess' ,
            new List<Database.SaveResult>{ result }
            );
    }

    /*************************************** QUERIES  **************************** */
    //== Fetch account team members based on account Ids
    public static List<NSP_Account_Team__c> getAccountTeams(Set<String> accountIdSet)
    {
        List<NSP_Account_Team__c> accountTeams = ([SELECT Id, NSP_User__c, NSP_Role__c, NSP_Account__c, NSP_Primary__c 
        FROM NSP_Account_Team__c 
        WHERE 
        NSP_Account__c =: accountIdSet  
        WITH SECURITY_ENFORCED 
        ORDER BY 
        NSP_Primary__c DESC 
        ]);

        return accountTeams;
    }

    //== Get project details based on project Id
    public static pse__Proj__c getProjectDetailsBasedOnProjectId(Id projectId)
    {
        pse__Proj__c project = [SELECT Id, Name, TemplateName__c, pse__Account__c, pse__Start_Date__c , recordTypeId, Project_Implementer__c 
        FROM pse__Proj__c 
        WHERE 
        Id =: projectId 
        AND 
        TemplateName__c = 'WX Benefits Renewal Project'  
        WITH SECURITY_ENFORCED];

        return project;
    }

    //== Get Template Information based on template Name
    public static EmailTemplate getEmailTemplate()
    {
        EmailTemplate emailTemplate = [SELECT ID, DeveloperName 
        FROM 
        EmailTemplate 
        WHERE 
        DeveloperName = 'NSP_Project_Task_Assignment_Alert'];

        return emailTemplate;
    }

    /************************ SEND EMAIL MESSAGES ****************** */
    private static void sendSingleEmailMessage(Id projectId)
    {
        // Get email template based on developer name
         EmailTemplate emailTemplate = getEmailTemplate();

        List<Messaging.SingleEmailMessage> lstEmailMessages = new List<Messaging.SingleEmailMessage>();
        List<String> toEmailAddressList                     = new List<String>();  

        toEmailAddressList.add(System.label.NSP_WXCarrierEmail);
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email= Messaging.renderStoredEmailTemplate(emailTemplate.Id, null , projectId);
        email.setTemplateId(emailTemplate.Id); 
        email.setToAddresses(toEmailAddressList);
        email.setWhatId(projectId);
        email.setSaveAsActivity(false);
        
        lstEmailMessages.add(email);

        if(!lstEmailMessages?.isEmpty())
        {
            NSP_GenericEmailUtility.sendSingleEmailMessages(lstEmailMessages, false); //method to send emails
        }
            
    }
}