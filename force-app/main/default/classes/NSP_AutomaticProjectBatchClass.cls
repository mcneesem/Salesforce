/**
* @description  : Batch Class to create project whenever a asset with account id is not present
   Automatically Creating a Service Plan Project for a new client based on STY-01029
* @date 05/12/2022
* Name : NSP_AutomaticProjectBatchClass 
*/
public class NSP_AutomaticProjectBatchClass implements Database.Batchable<sObject>, Database.Stateful {
    private Map<String, pse__proj__c> templateNameProjectMap = new Map<String, pse__proj__c>();

    @TestVisible
    private NSP_OpportunityTriggerServiceHelper opp = new NSP_OpportunityTriggerServiceHelper();
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        Set<Id> assetAccIdSet = new Set<Id>();
        List<Id> accountIdList = new List<Id>();
        List<String> accountFields = new List<String>{'Id','Name'};
        //Storing asset wo record type Id
        Id assertWORTId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE, NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
        //getting all the accountId with wo recordtype, active status and status date is today
        assetAccIdSet= getAssetAccountIds(assertWORTId);
        //checking whether accountId are empty
        if( !assetAccIdSet.isEmpty()){
            //removing all the accountId with existing project 
            accountIdList = getFilteredAccountsFromProjects(assetAccIdSet);
        }
        String query = new NSP_QueryBuilder(NSP_ServiceConstants.ACCOUNT_OBJECT, accountFields)
            					.addFilter('Id', accountIdList, NSP_QueryBuilder.Operator.INCLUDES).build();
        return Database.getQueryLocator(query);
    }

    //execute batch class
    public void execute(Database.BatchableContext bc, List<Account> listAccount){
        map<Id, Asset> accountIdAssetMap = new map<Id, Asset>();
        List<pse__proj__c> projList = new List<pse__proj__c>();
        //storing peo recordtype of project
        pse__proj__c oproject;
        
        //mapping all the accountId adn asset object
        for(Asset oasset: [SELECT Id, Name, AccountId, RecordTypeId, NSP_Account_Status__c, NSP_Account_Status_Date__c, 
                           NSP_Client_Segment_type__c FROM Asset WHERE NSP_Client_Segment_type__c != NULL AND AccountId IN: listAccount  AND Status IN (:NSP_ServiceConstants.ASSET_ACTIVE_STATUS, 
                                                                                                                 :NSP_ServiceConstants.ONBOARDING)]){
                               accountIdAssetMap.put(oasset.AccountId, oasset);
        }
        //iterating over the accountList
        for(Account oAccount: listAccount){
            if(accountIdAssetMap.containsKey(oAccount.Id) && accountIdAssetMap?.get(oAccount.Id) != NULL){
                Asset oasset = accountIdAssetMap.get(oAccount.Id);
                //checking for the client type and getting respective template and account team
                oproject = checkingClientType(oasset, oAccount, opp);
                if(oproject != NULL){
                    projList.add(oproject);
                }
            }
        }
        //updating all the project
        if(!projList.isEmpty()){
            Database.update(projList, false);    
        }
        
    }

    //finish method
    public void finish(Database.BatchableContext bc){
        // execute any post-processing operations
        
    }

     /**
    * @description  : get all the asset account Ids with WO RecordType, active status and status date is today
    * @param: Id of Asset wo recordType
    * @return: set of accountIds
   */
    private static Set<Id> getAssetAccountIds(Id assertWORTId){
        
        Set<Id> assetAccIdSet = new Set<Id>();
        List<String> assetFields = new List<String>{'Id','AccountId'};
        //getting all the assets from record with filter from queryBuilder Class
        String query = new NSP_QueryBuilder(NSP_ServiceConstants.ASSET_SOBJECT_TYPE, assetFields)
            .addFilter('RecordTypeId', String.valueOf(assertWORTId))
            .addFilter('NSP_Account_Status__c', NSP_ServiceConstants.AIMS_STATUS)
            .addFilter('NSP_Account_Status_Date__c', (System.today()+'').split(' ')[0],NSP_QueryBuilder.Operator.EQUALS,False ).build();
        List<Asset> assetsList = (List<Asset>) Database.query(query);
        for(Asset oAsset : assetsList){
             assetAccIdSet.add(oAsset.AccountId);
        }
        return assetAccIdSet;
    }
    
    /**
    * @description  : filtering all the accountId which doesn't have project
    * @param: set of accountIds
    * @return: List of accountIds
   */
    private static List<Id> getFilteredAccountsFromProjects(Set<Id> assetAccIdSet){
        Set<Id> accountFilter = new Set<Id>();
        List<Id> finalAccountId = new List<Id>();
        //getting all the accountId with existing project
        for(pse__proj__c oproject : [SELECT Id, pse__Account__c 
                                     FROM pse__proj__c 
                                     WHERE pse__Account__c IN: assetAccIdSet
                                     AND pse__Is_Active__c = true 
                                     AND pse__Is_Template__c != True 
                                     AND pse__Project_Status__c NOT IN (:NSP_ServiceConstants.PROJECTSTATUSCOMPLETED, 
                                                                        :NSP_ServiceConstants.PROJECTSTATUSCANCELLED, 
                                                                        :NSP_ServiceConstants.PROJECTSTATUSCLOSED)
                                     AND pse__Project_Type__c =: NSP_ServiceConstants.PROJECT_TYPE_SERVICE]){
                                         accountFilter.add(oproject.pse__Account__c);
         }
        //remove all the accountId with the project
        assetAccIdSet.removeAll(accountFilter);
        finalAccountId.addAll(assetAccIdSet);
        return finalAccountId;
    }
    
    /**
    * @description  : getting all the Engagement Plan project templates and storing in a map with template name and project
    * @param: NA
    * @return: map<TemplateName, ProjectTemplateRecord>
   */
    private static List<Template_Key_and_Id_Mapping__mdt> getProjectTemplates(String keyValue){
        
        //getting project template of Engagement Plan project
        List<String> templateFields = new List<String>{
            'Id', 
            'Key__c',
            'Template_ID__c',
            'Template_Name__c' 
        };
         String query = new NSP_QueryBuilder('Template_Key_and_Id_Mapping__mdt', templateFields)
                    .addFilter('Key__c', String.escapeSingleQuotes(keyValue))
                    .addFilter('NSP_From_Object__c', String.escapeSingleQuotes(NSP_ServiceConstants.FROM_OBJECT_ASSET))
                    .setSecurityEnforce(false)
                    .build();
        List<Template_Key_and_Id_Mapping__mdt> oTempKey = (List<Template_Key_and_Id_Mapping__mdt>)Database.query(query);
        return oTempKey;
    }
    
     /**
    * @description  : checking for the client type on Asset and create a project
    * @param: asset record, account record, map<TemplateName, ProjectTemplateRecord>, peo recordType id
    * @return: project record
   */
    private static pse__proj__c checkingClientType(Asset oasset, Account oaccount, NSP_OpportunityTriggerServiceHelper opp){
        
        pse__proj__c oproject;
        if(oasset.NSP_Client_Segment_type__c == NSP_ServiceConstants.BTAssetSegment){
                //getting BT Engagement plan project from the method
                List<Template_Key_and_Id_Mapping__mdt> templateKeyList = getProjectTemplates(NSP_ServiceConstants.PROJECT_TEMPLATE_NAME);
                oproject= createEngagementProject(oAccount, templateKeyList, NSP_ServiceConstants.BTAssetSegment, opp);
            }else if(oasset.NSP_Client_Segment_type__c == NSP_ServiceConstants.CoreAssetSegment || 
                    oasset.NSP_Client_Segment_type__c == NSP_ServiceConstants.EG100AssetSegment || 
                    oasset.NSP_Client_Segment_type__c == NSP_ServiceConstants.EG50AssetSegment){
                     //getting core Engagement plan project from the method
                        List<Template_Key_and_Id_Mapping__mdt> templateKeyList = getProjectTemplates(NSP_ServiceConstants.PROJECT_CORE_TEMPLATE);
                        oproject= createEngagementProject(oAccount, templateKeyList, NSP_ServiceConstants.CoreAssetSegment, opp);
            }else if(oasset.NSP_Client_Segment_type__c == NSP_ServiceConstants.MMAssetSegment){
                //getting Middle Market Engagement plan project from the method 
                List<Template_Key_and_Id_Mapping__mdt> templateKeyList = getProjectTemplates(NSP_ServiceConstants.PROJECT_MM_90_DAY_EP_TEMPLATE);
                oproject= createEngagementProject(oAccount, templateKeyList, NSP_ServiceConstants.MMAssetSegment, opp);
            }else if(oasset.NSP_Client_Segment_type__c == NSP_ServiceConstants.MMEAssetSegment){
                //getting Middle Market Engagement plan project from the method 
                List<Template_Key_and_Id_Mapping__mdt> templateKeyList = getProjectTemplates(NSP_ServiceConstants.PROJECT_MM_ENTERPRISE_EP_TEMPLATE);
                oproject= createEngagementProject(oAccount, templateKeyList, NSP_ServiceConstants.MMAssetSegment, opp);
            }
        return oproject;
    }
    
     /**
    * @description  : getting all the accountTeam of the against account Id and the role
    * @param: account Id and asset client segment type
    * @return: account team record
   */
    private static Id getAccountTeam(Id accountId, String typeClient){
        //mapping of clientType and role 
        Map<String, String> clientTypeAccTeamRole = new Map<String, String>{NSP_ServiceConstants.BTAssetSegment => NSP_ServiceConstants.BUS_TEAM_HRSP_CL,
            NSP_ServiceConstants.CoreAssetSegment => NSP_ServiceConstants.CLIENT_LIAISION,
            NSP_ServiceConstants.MMAssetSegment => NSP_ServiceConstants.MID_MARKET_ACC_EX};
        List<NSP_Account_Team__c> oAccteam;
        String accountTeamObjectName = 'NSP_Account_Team__c';
        List<String> accTeamFields = new List<String>{ 'Id', 'NSP_User__c'};
            
        //getting the account team of against role and accountId
        if(clientTypeAccTeamRole.containsKey(typeClient)){
            String query= new NSP_QueryBuilder(accountTeamObjectName, accTeamFields)
                .addFilter('NSP_Account__c', String.valueOf(accountId))
                .addFilter('NSP_Role__c', String.valueOf(clientTypeAccTeamRole.get(typeClient))).addLimit(1).build();
            oAccTeam = (List<NSP_Account_Team__c>) Database.query(query);
        }
        //if the account team doesn't have the particular role then get Manager, HR Service
        if(oAccteam.isEmpty()){
            String query= new NSP_QueryBuilder(accountTeamObjectName, accTeamFields)
                .addFilter('NSP_Account__c', String.valueOf(accountId))
                .addFilter('NSP_Role__c', String.escapeSingleQuotes(NSP_ServiceConstants.MANAGER_HRSERVICES)).addLimit(1).build();
            oAccTeam = (List<NSP_Account_Team__c>) Database.query(query);
        }
        if(oAccteam != NULL && !oAccteam?.isEmpty()){
            return oAccteam[0]?.NSP_User__c;
        } else {
            return UserInfo.getUserId();
        }
    }
    
    /**
    * @description  :creating project for Engagement Plan Project Template
    * @param: account Id and asset client segment type
    * @return: project record
   */
    private static pse__proj__c createEngagementProject(Account oaccount, List<Template_Key_and_Id_Mapping__mdt> templateKeyList, String clientType, NSP_OpportunityTriggerServiceHelper opp){
        
        //getting the project template based on name of project
        List<pse__proj__c> oproject;
        pse__proj__c updateProject = null;
        Set<Id> newProjectId = new Set<Id> ();
        List<Id> newProjectIdList = new List<Id> ();
        pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest projectrequest;
        List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest> lProjRequests = new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest>();
         //getting account team record of the particular role
        Id userId = getAccountTeam(oAccount.Id, clientType);
        //calling NSP_CreateProjectUsingKey to create the project and it returns project
        projectrequest = new pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest(oaccount.Id, templateKeyList[0].Template_ID__c, System.Today());
        
        //copy recordTypeId
        pse.SObjectCloneMapper.Field mapperFieldRT = new pse.SObjectCloneMapper.Field(Schema.pse__Proj__c.RecordTypeId);
        pse.SObjectCloneMapper.Field mapperFieldStartDate = new pse.SObjectCloneMapper.Field(Schema.pse__Proj__c.pse__Start_Date__c);
        pse.SObjectCloneMapper.Field mapperFieldEndDate = new pse.SObjectCloneMapper.Field(Schema.pse__Proj__c.pse__End_Date__c);
        Set<pse.SObjectCloneMapper.Field> setMapperFields = new Set<pse.SObjectCloneMapper.Field>{mapperFieldRT, mapperFieldStartDate, mapperFieldEndDate};
        pse.SObjectCloneMapper mapp = new pse.SObjectCloneMapper(pse__Proj__c.SObjectType, setMapperFields);
        projectrequest.Mappers = new List<pse.SObjectCloneMapper> { mapp };
        
        projectrequest.ProjectOwnerId = userId;
        projectrequest.IsActive = true;
        lProjRequests.add(projectrequest);
        //checking whether the account request is empty
        if(lProjRequests != null){
            //create a project and deleting Budget
            
            newProjectId = opp.createProjectAndDeleteBudget(lProjRequests);
            newProjectIdList.addAll(newProjectId);
            //querying related project created by the NSP_OpportunityTriggerServiceHelper method
            List<String> projField = new List<String>{'Id','Name','OwnerId', 'RecordTypeId','Template_Name__c','pse__Is_Billable__c',
                'pse__Account__c', 'pse__End_Date__c', 'pse__Start_Date__c'};
        	String query = new NSP_QueryBuilder(NSP_ServiceConstants.PROJECT_SOBJECT_NAME, projField)
            					.addFilter('pse__Is_Template__c', false)
                                .addFilter('pse__Is_Active__c', True)
                                .addFilter('pse__Account__c', String.valueOf(oaccount.Id))
                    			.addFilter('Id',newProjectIdList[0] ,NSP_QueryBuilder.Operator.INCLUDES)
                                .addFilter('OwnerId', userId).build();
        	oproject  = (List<pse__proj__c>) Database.query(query);
            if(!oproject.isEmpty()){
                //updating the values
                if(oproject[0].pse__Start_Date__c != null && oproject[0].pse__End_Date__c != null){
                    Integer numberDays = oproject[0].pse__Start_Date__c.daysBetween(oproject[0].pse__End_Date__c);

                    oproject[0].pse__Start_Date__c = System.today(); 
                    oproject[0].pse__End_Date__c = System.today() + numberDays; 
                    oproject[0].pse__Is_Billable__c = False;
                }else{
                    oproject[0].pse__Start_Date__c = System.today(); 
                    oproject[0].pse__End_Date__c = null;
                    oproject[0].pse__Is_Billable__c = False;
                }
                updateProject = oproject[0];
            }
        }
      
      return updateProject;
    }

}