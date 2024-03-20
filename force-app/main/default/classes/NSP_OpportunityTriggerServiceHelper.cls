/**
* Represents the Opportunity trigger helper created By Service which handles all the logic.
*/
public class NSP_OpportunityTriggerServiceHelper {
    // test w/ NSP_OpportunityTriggerServiceHelperTest (86%)

    /*****************************************************************
    * Creating Constructor to call FF API's
    * Creating Mock records of FF Api's Using interfaces 
    */
    public NSP_FF_APIs implInstance = new NSP_FF_APIImpl();
    public NSP_OpportunityTriggerServiceHelper(){
        if(Test.isRunningTest()){
            this.implInstance = new Nsp_FFApiMock();
        }
    }
    // This constructor is for test use only. Don't use this in actual implementation.
    public NSP_OpportunityTriggerServiceHelper(Set<Id> projectIdSet){
       this.implInstance = new Nsp_FFApiMock(projectIdSet);
    }
    
    /**
    * Iterates throught the Opportunity map and identifies the records that needs to worked based on various criterias.
    * @param opportunityNewMap Map of New Opportunity. 
    * @param opportunityOldMap Map of Old Opportunity. 
    * @return void             
    *                
    */
    
    public void beforeUpdateDirector(Map<Id, Opportunity> opportunityNewMap, Map<Id, Opportunity> opportunityOldMap){
    	List<Opportunity> docusignedOpportunityList = new List<Opportunity>();
        
        //Iterating over the new opportunity map
        for(Id opportunityId : opportunityNewMap.keySet()){
            //Added as part of STY-STY-01602
            if(opportunityNewMap.get(opportunityId).NSP_Signed_CSA__c != opportunityOldMap.get(opportunityId).NSP_Signed_CSA__c &&
                opportunityNewMap.get(opportunityId).NSP_Signed_CSA__c == true){
                docusignedOpportunityList.add(opportunityNewMap.get(opportunityId));
            }
        }
        
        //Added as part of STY-STY-01602
        if(!docusignedOpportunityList.isEmpty()){
            updateCSAsignedDateOnOpportunity(docusignedOpportunityList);
        }
    }
    
    /**
* Iterates throught the list of new leads and passes the required attributes to other methods.
* @param opportunityNewMap Map of New Opportunity. 
* @param opportunityOldMap Map of Old Opportunity.   
* @return void             
*                
*/
    
    public void afterUpdateDirector(Map<Id, Opportunity> opportunityNewMap,Map<Id, Opportunity> opportunityOldMap){              
        List<Opportunity> docusignedOpportunityList = new List<Opportunity>();
        Map<Id,Opportunity> timeAttAssetMap = new Map<Id,Opportunity>();
        Map<Id,Opportunity> perAssetMap = new Map<Id,Opportunity>();
        Map<Id,Id> oppIdAccIdMap = new Map<Id,Id>();
        Set<Id>accountIdSet = new Set<Id>();
        for(Id opportunityId : opportunityNewMap.keySet()){
            Opportunity opp = opportunityNewMap.get(opportunityId);
            Boolean isValidTimeEntryRecommendation = (
                ( opp.NSP_Time_Entry_Recommendation__c == NSP_ServiceConstants.Premier_Time_Att )
                || ( opp.NSP_Time_Entry_Recommendation__c == NSP_ServiceConstants.Premier_Timesheet )
            );
            Boolean isValidWoWsPrimaryProduct = (
                ( opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WO )
                || ( opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WS )
            );
            if ( opp.stagename != opportunityOldMap.get(opportunityId).stagename
                && opp.stagename.equals(NSP_SalesConstants.CLOSED_WON))
            {
                // added as a part of STY-03649
                if ( isValidWoWsPrimaryProduct
                    && isValidTimeEntryRecommendation
                    )
                {
                    timeAttAssetMap.put(opp.Id,opp);
                }
                if ( (opp.NSP_PrimaryProduct__c == NSP_ServiceConstants.TIME_ATTENDANCE)
                    && isValidTimeEntryRecommendation
                    )
                {
                    timeAttAssetMap.put(opp.Id,opp);
                }
                if ( isValidWoWsPrimaryProduct
                    && opp.NSP_IPMRecommendation__c == NSP_SalesConstants.Yes
                    )
                {
                    perAssetMap.put(opp.Id,opp);
                }
                if ( opp.NSP_PrimaryProduct__c == NSP_ServiceConstants.PERFORMANCE_MANAGEMENT 
                    && opp.NSP_IPMRecommendation__c == NSP_SalesConstants.Yes
                    )
                {
                    perAssetMap.put(opp.Id,opp);
                }
                oppIdAccIdMap.put(opp.Id,opp.AccountId);
            }
            //Added as part of STY-STY-01602
            if(opportunityNewMap.get(opportunityId).NSP_Signed_CSA__c != opportunityOldMap.get(opportunityId).NSP_Signed_CSA__c &&
               opportunityNewMap.get(opportunityId).NSP_Signed_CSA__c == true && opportunityNewMap.get(opportunityId).NSP_Signed_CSA_Date__c != null){
                   docusignedOpportunityList.add(opportunityNewMap.get(opportunityId));
               }
            // added as a part of STY-02129
            if(opp.StageName != opportunityOldMap.get(opp.Id).StageName && opp.StageName ==NSP_SalesConstants.CLOSED_WON && opp.AccountId!=null ){
                accountIdSet.add(opp.AccountId);
            }
        }       
        
        //Added as part of STY-STY-01602
        if(!docusignedOpportunityList.isEmpty()){
            updateCSAsignedDateOnAsset(docusignedOpportunityList);
        }
        
        // added as a part of STY-03649
        if((!timeAttAssetMap.isEmpty() || !perAssetMap.isEmpty())  ){
            createAssetwithProject(timeAttAssetMap,perAssetMap,oppIdAccIdMap);
        }
        // added as a part of STY-02129
        if(!accountIdSet.isEmpty() && !system.isfuture() && !system.isBatch()){
            updateImplementationProfile(accountIdSet);
        }
        
    }
   
    /**
* Create Project And Delete Budget
* @param lProjRequests Response received from FinancialForce APIs).    
* @return void             
*                
*/
    
    public Set<Id> createProjectAndDeleteBudget(List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest> lProjRequests){
       
      
        //Call the service and create project      
        List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projResponse = this.implInstance.createProjectFromTemplate(new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest>{lProjRequests[0]});
        Set<Id> newProjectId = this.implInstance.getProjectIdSet(projResponse);
        
        // Deleting all Budgets Created with Projects
        if(!newProjectId.isEmpty()){
            List<pse__Budget__c> lBudgets = [SELECT id FROM pse__Budget__c WHERE pse__Project__c in : newProjectId];
            delete lBudgets;
        }
        
        return newProjectId;
    }
    
    /***********************************************************************************************
* MethodName: updateImplementationProfile
* Description : This Method will update Opportunity related account ProjectId on the Implementation Profile for the Closed Opportunities 
* Params:     Set<Id> accountIdSet
* ********************************************************************************************/     
    @future
    public static void updateImplementationProfile( Set<Id> accountIdSet){  
        Map<Id,Id> mapAccountIdProjectId = new Map<Id,Id>();
        List<Implementation_Profile__c> updateImProfileList = new List<Implementation_Profile__c>();
        try{
            Id projectRecordType = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
            // fetching Implementation Project for Closed Opportunity related Account
            List<pse__Proj__c> projectList = [Select Id, pse__Account__c from pse__Proj__c  WHERE pse__Account__c IN:accountIdSet  
                               AND RecordTypeId=:projectRecordType AND pse__Project_Type__c =:NSP_ServiceConstants.ImplementationProjectType 
                               AND (TemplateName__c = :label.Middle_Market_Implementation_Project OR TemplateName__c = :label.FSOImplementationProject)
                               Order By CreatedDate DESC limit 1];
            // Creating map of opp account Id and Project Id 
            for(pse__Proj__c project:projectList){
                mapAccountIdProjectId.put(project.pse__Account__c,project.Id);
            }
            // fetching and Updating Project Id on  Implementation Profiles 
            List<Implementation_Profile__c> impProfileList =[Select Id ,Account__c,NSP_Project__c from Implementation_Profile__c 
                                                             WHERE Account__c IN: mapAccountIdProjectId.KeySet()  ]; 
            for(Implementation_Profile__c iProfile:impProfileList){
                // checking if Implementaion Profile has valid account and Project 
                if(mapAccountIdProjectId.ContainsKey(iProfile.Account__c)){
                    Implementation_Profile__c impProfile = new Implementation_Profile__c();
                    impProfile.Id= iProfile.Id;
                    // updating Project Id on Implementation Profile
                    impProfile.NSP_Project__c= mapAccountIdProjectId.get(iProfile.Account__c);
                    updateImProfileList.add(impProfile);   
                }
            }
            // Updating Implementation Profiles List 
            if(!updateImProfileList.isEmpty()){
                update updateImProfileList;
            } 
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_OpportunityTriggerHelper', 'updateImplementationProfile', ex.getMessage());
        }
        
    }
    
    /***********************************************************************************************
    * MethodName: createAssetwithProject
    * Description : This Method will update Opportunity related account ProjectId on the Implementation Profile for the Closed Opportunities 
    * Params:     Map<Id,String> timeAttAssetMap,Map<Id,String> perAssetMap , Map<Id,Id> oppAccMap
    * ********************************************************************************************/     
    private static void createAssetwithProject( Map<Id,Opportunity> timeAttAssetMap , Map<Id,Opportunity> perAssetMap , Map<Id,Id> oppAccMap ) {
        List<Asset> assetList = new List<Asset>();
        List<pse__Proj__c> updateProjectList = new List<pse__Proj__c>();
        List<Project_Asset__c> projectAssetMapping = new List<Project_Asset__c>();
        try{
        Id TimeAttAssetRecordType = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE,NSP_ServiceConstants.TIME_ATTENDANCE_ASSET);
        Id PermformanceAssetRecordType = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE,NSP_ServiceConstants.PERFORMANCE_MANAGEMENT_ASSET);
        Id TESBPSProjectRecordType = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT,NSP_ServiceConstants.PROJECT_BPS_RECORDTYPE);
        Template_Key_and_Id_Mapping__mdt templateMapping =[SELECT Key__c, Template_ID__c, Template_Name__c FROM Template_Key_and_Id_Mapping__mdt WHERE Key__c =: NSP_ServiceConstants.ITA_Prj_Temp  AND NSP_From_Object__c = : NSP_ServiceConstants.FROM_OBJECT_ASSET];
        
        if(!timeAttAssetMap.isEmpty()){
            for(Id oppId:timeAttAssetMap.keyset() ){
                Opportunity record = timeAttAssetMap.get(oppId);
                if(record != null){
                    Boolean IsPerformWOWSAsset = True;
                    assetList.add(
                        createAssetObject(
                            record.Name ,
                            oppId ,
                            oppAccMap.get(oppId) ,
                            TimeAttAssetRecordType ,
                            NSP_ServiceConstants.ASSET_ONBOARDING_STATUS ,
                            NSP_ServiceConstants.CASE_TIME_ATTENDENCE ,
                            NSP_ServiceConstants.WoWSAsset,
                            IsPerformWOWSAsset
                        )
                    );
                }
            }
        }
        if(!perAssetMap.isEmpty()){
            for(Id oppId:perAssetMap.keyset() ){
                Opportunity record = perAssetMap.get(oppId);
                if(record != null){
                    String assetStatus = NSP_ServiceConstants.ASSET_ONDEMAND_STATUS;
                    Boolean IsPerformWOWSAsset = True;
                    if(record.NSP_PrimaryProduct__c == NSP_ServiceConstants.PERFORMANCE_MANAGEMENT){
                        assetStatus = NSP_ServiceConstants.ASSET_ONBOARDING_STATUS;
                        IsPerformWOWSAsset = False;
                    }
                    assetList.add(
                        createAssetObject(
                            record.Name ,
                            oppId ,
                            oppAccMap.get(oppId) ,
                            PermformanceAssetRecordType ,
                            assetStatus ,
                            NSP_ServiceConstants.PERFORMANCE ,
                            NSP_ServiceConstants.WoWSAsset,
                            IsPerformWOWSAsset
                        )
                    );
                }
            }
        }
        if(!assetList.isEmpty()){
                List<Database.UpsertResult> upsertResults = Database.upsert(assetList, false);
                NSP_ErrorLogHandler.logUpsertResultsException('NSP_OpportunityTriggerHelper', 'createAssetwithProject:upsertResults', upsertResults);
                
            // Create Project and Link Asset With Project
            for(Asset ast: assetList){
                if(ast.recordTypeId == TimeAttAssetRecordType){
                    NSP_AssetServiceTriggerHelper astService = new NSP_AssetServiceTriggerHelper();
                    String projectId;
                    projectId = astService.createProjectWithTemplateFromAsset(templateMapping, ast.Id ); 
                    if(projectId!=null){
                        updateProjectList.add(createProjectObject(projectId, ast.AccountId, TESBPSProjectRecordType));
                        projectAssetMapping.add(NSP_AssetServiceTriggerHelper.linkProjectWithAsset(projectId, ast.Id));
                    }
                }                    
            }
            
        }
        if(!updateProjectList.isEmpty()){
                List<Database.UpsertResult> upsertResults = Database.upsert(updateProjectList, false);
                NSP_ErrorLogHandler.logUpsertResultsException('NSP_OpportunityTriggerServiceHelper', 'createAssetwithProject:upsertResults', upsertResults);
        }        
        if(!projectAssetMapping.isEmpty()){
                List<Database.UpsertResult> upsertResults = Database.upsert(projectAssetMapping, false);
                NSP_ErrorLogHandler.logUpsertResultsException('NSP_OpportunityTriggerServiceHelper', 'createAssetwithProject:upsertResults', upsertResults);
           
        }        
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_OpportunityTriggerServiceHelper', 'createAssetwithProject', ex.getMessage());
        }
       
        
    }
    
    /***********************************************************************************************
    * MethodName: createAssetObject
    * ********************************************************************************************/    
    private static Asset createAssetObject(String assetName , Id oppId, Id accountId , Id assetRecordTypeId , String status , String productLine , String bundle, Boolean IsPerformWOWSAsset){
        Asset ast = new Asset();
        ast.Name = assetName;
        ast.RecordTypeId = assetRecordTypeId;
        ast.Status = status;
        ast.NSP_Signature_Date__c = System.today();
        ast.NSP_Product_Line__c = productLine;   
        ast.NSP_ProductBundle__c = bundle;
        ast.Opportunity__c = OppId;
        ast.AccountId = accountId;
        ast.Is_Perform_WO_WS_Asset__c = IsPerformWOWSAsset;
        return ast;
    }   
    
    /***********************************************************************************************
    * MethodName: createProjectObject
    * ********************************************************************************************/ 
    private static pse__Proj__c createProjectObject(Id projId, Id accountId , Id projectRecordType ){
        pse__Proj__c project = new pse__Proj__c();
        project.Id= projId;
        project.pse__Project_Status__c = NSP_ServiceConstants.INTAKE;
        project.pse__Account__c = accountId;
        project.RecordTypeId = projectRecordType;
        project.pse__End_Date__c = System.Today().addDays(45);
        project.pse__Start_Date__c = System.Today();
        return project;
    }
    
    /***********************************************************************
    * @MethodName : updateCSAsignedDateOnOpportunity
    * @Description: This method will update CSA Signed Date on opportunity
    *               record when Signed CSA is checked.
    * @param      : List<Opportunity> opportunityList
    * @Story      : STY-01602
    * @return     : void                          
    **************************************************************************/
    public void updateCSAsignedDateOnOpportunity(List<Opportunity> opportunityList){
        try{
            for(Opportunity oppoRec : opportunityList){
                oppoRec.NSP_Signed_CSA_Date__c = System.today();
            }
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_OpportunityTriggerHelper', 'updateCSAsignedDateOnOpportunity', ex.getMessage());
        }		
	}

    /***********************************************************************
    * @MethodName : updateCSAsignedDateOnAsset
    * @Description: This method will update the CSA Signed Date field
    *               on opportunity related Asset record.
    * @param      : List<Opportunity> opportunityList
    * @Story      : STY-01602
    * @return     : void                          
    **************************************************************************/
    public void updateCSAsignedDateOnAsset(List<Opportunity> opportunityList){
        try{
            List<Asset> relatedAssetList = new List<Asset>();
            List<Asset> assetListToUpdate = new List<Asset>();
            Set<Id> opportunityIdSet = new Set<Id>();
            for(Opportunity oppoRec : opportunityList){
                opportunityIdSet.add(oppoRec.Id);
            }
            if(!opportunityIdSet.isEmpty()){
                List<String> assetFields = new List<String>{'Id','NSP_CSA_Signed_Date__c','Opportunity__c','Opportunity__r.NSP_Signed_CSA_Date__c'};
                String query = new NSP_QueryBuilder('Asset', assetFields)
                                    .addFilter('Opportunity__c', new List<Id>(opportunityIdSet), NSP_QueryBuilder.Operator.INCLUDES)
                                    .addFilter('Opportunity__r.NSP_Signed_CSA__c', true).build();
                relatedAssetList = (List<Asset>)Database.query(query);
            }

            if(!relatedAssetList.isEmpty()){
                for(Asset assetRec : relatedAssetList){
                    Asset assetObj = new Asset();
                    assetObj.Id = assetRec.Id;
                    assetObj.NSP_CSA_Signed_Date__c = assetRec.Opportunity__r.NSP_Signed_CSA_Date__c;
                    assetListToUpdate.add(assetObj);
                }
            }

            if(!assetListToUpdate.isEmpty()){
                Database.SaveResult[] assetUpdateList = Database.update(assetListToUpdate,false);
                NSP_ErrorLogHandler.logSaveResultsException('NSP_OpportunityTriggerHelper', 'updateCSAsignedDateOnAsset:AssetUpdate', assetUpdateList);
            }
            
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_OpportunityTriggerHelper', 'updateCSAsignedDateOnAsset', ex.getMessage());
        }		
	}
}