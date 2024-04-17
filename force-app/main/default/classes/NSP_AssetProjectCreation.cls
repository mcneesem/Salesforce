/**
* @description  :  Helper class for AssetTriggerHelper
* @date 04/04/2023
* Author : Nischay Jindal
* Name : NSP_AssetProjectCreation
*/
public class NSP_AssetProjectCreation implements Queueable {
    // test w/ NSP_AssetServiceTriggerHelperTest (84%)

    private static final String NSP_ASSET_PROJECT_CREATION = 'NSP_AssetProjectCreation';

    public NSP_FF_APIs implInstance = new NSP_FF_APIImpl();
    public NSP_AssetProjectCreation(){
        if(Test.isRunningTest()){
            this.implInstance = new Nsp_FFApiMock();            
        }
    }

    /***********************************************************************************************
    * Variables
    * ********************************************************************************************/   
    public Set<Id>accountIdSet = new Set<Id>();
    public Set<Id> fsoAssetSet = new Set<Id>();
    public Set<Id> MMAssetSet = new Set<Id>();
    public Set<Id> woAssetIdSet = new Set<Id>();
    public NSP_AssetProjectCreation(Set<Id>woAssetIdSet,Set<Id>accountIdSet,Set<Id> fsoAssetSet,Set<Id> MMAssetSet ){
        this.woAssetIdSet = woAssetIdSet;
        this.accountIdSet = accountIdSet;
        this.fsoAssetSet =  fsoAssetSet;
        this.MMAssetSet = MMAssetSet;
    }
    
    public void execute(QueueableContext qc) {  
        try{
            createImplementationProject(woAssetIdSet,accountIdSet,fsoAssetSet,MMAssetSet);
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException(NSP_ASSET_PROJECT_CREATION, 'Execute', ex.getMessage()); 
        }
    }
    
    /***********************************************************************************************
    * MethodName: createImplementationProject
    * Description :  This method will create the implementation Project for MM , BT Core ,EG asset
    * Params:   Set<Id>woAssetIdSet,Set<Id>accountIdSet,Set<Id> fsoAssetSet,Set<Id> MMAssetSet    
    * ********************************************************************************************/    
    public  void createImplementationProject(Set<Id>woAssetIdSet,Set<Id>accountIdSet,Set<Id> fsoAssetSet,Set<Id> MMAssetSet){
        List<pse__Proj__c> updatedProjectList = new List<pse__Proj__c>();
        Map<Id,List<pse__Proj__c>> mapAccountIdListProjects = new  Map<Id,List<pse__Proj__c>>();
        List<Project_Asset__c> projectAssetMapping = new List<Project_Asset__c>();
        List<pse__Proj__c> projectList = new List<pse__Proj__c>() ;
        List<pse__Proj__c> ImpProjectList = new  List<pse__Proj__c>();
        try{
            Id projectRecordType = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c',NSP_ServiceConstants.PEOProject);
            // Searching List of Projects for Asset account
            // creating map of AccountId and ListProjects
            for(pse__Proj__c project:[SELECT Id, pse__Account__c FROM pse__Proj__c  WHERE pse__Account__c IN:accountIdSet
                                              AND RecordTypeId=:projectRecordType AND pse__Project_Type__c = :NSP_ServiceConstants.ImplementationProjectType AND 
                                              (TemplateName__c =:label.FSOImplementationProject OR TemplateName__c=:label.Middle_Market_Implementation_Project )]){
                projectList.add(project);
                if (mapAccountIdListProjects.get(project.pse__Account__c) == null){
                    mapAccountIdListProjects.put(project.pse__Account__c, new List <pse__Proj__c> ());
                }
                mapAccountIdListProjects.get(project.pse__Account__c).add(project);
            }
            // getting template from metadata
            Map<String, Template_Key_and_Id_Mapping__mdt> templateMap = new Map<String, Template_Key_and_Id_Mapping__mdt>();
            List<String>projectKeys = label.NSP_ProjectKeySet.Split(',');
            Set<String> templateKeySet = new Set<String>();
            templateKeySet.addAll(projectKeys);
            List<Template_Key_and_Id_Mapping__mdt> templateList =[SELECT Key__c, Template_ID__c, Template_Name__c FROM Template_Key_and_Id_Mapping__mdt
                                                                      WHERE Key__c IN: templateKeySet AND NSP_From_Object__c = : NSP_ServiceConstants.FROM_OBJECT_ASSET];
            for(Template_Key_and_Id_Mapping__mdt template :templateList){
                templateMap.put(template.Key__c, template);
            }
            // checking if the asset has the active project 
            for ( Asset asset : [
                        SELECT Id , RecordTypeId , NSP_Client_Segment_type__c , AccountId , Opportunity__c
                        FROM Asset
                        WHERE ( Id IN :woAssetIdSet )
                    ]
                )
            {
                if(projectList.isEmpty()){
                    String templateType;
                    Id projectId; 
                    Template_Key_and_Id_Mapping__mdt projectTemplateType = new Template_Key_and_Id_Mapping__mdt();
                    // checking for MM Assets 
                    if(MMAssetSet.contains(asset.Id)){
                        projectTemplateType = templateMap.get(NSP_ServiceConstants.MM_PROJECT_TEMPLATE_KEY);
                        templateType = label.Middle_Market_Implementation_Project;
                        projectId = createProjectWithTemplateFromAsset(projectTemplateType, asset.Id );
                    }
                    // checking for EG, BT, Core Assets 
                    else if(fsoAssetSet.Contains(asset.Id)){
                        projectTemplateType = templateMap.get(NSP_ServiceConstants.FSO_PROJECT_TEMPLATE_KEY);
                        templateType = label.FSOImplementationProject;
                        projectId = createProjectWithTemplateFromAsset(projectTemplateType, asset.Id );
                    }
                    if(projectId!=null){
                        // Update Mid Market & FSO Project Data
                        updatedProjectList.add(
                            createProjectObject(
                                projectId ,
                                projectRecordType ,
                                asset.AccountId ,
                                templateType ,
                                asset.opportunity__c
                            )
                        );
                        //Update the project with its related entity.
                        projectAssetMapping.add(linkProjectWithAsset(projectId, asset.Id));
                    }  
                }
            }
            
            if(!updatedProjectList.isEmpty()){
                List<Database.SaveResult> results = Database.update(updatedProjectList,false);
                NSP_ErrorLogHandler.logSaveResultsException(NSP_ASSET_PROJECT_CREATION, 'createImplementationProject', results );
            }
            if(!updatedProjectList.isEmpty()){
                Set<Id> projectIds= new  Set<Id>();
                Set<Id> accIdSet = new  Set<Id>();
                for(pse__Proj__c prj:updatedProjectList){
                    projectIds.add(prj.Id);
                    if(String.isNotBlank(prj.pse__Account__c)){
                        accIdSet.add(prj.pse__Account__c);
                    }
                }

                for(pse__Proj__c impProj:[SELECT Id,pse__Project_Type__c, pse__Account__c,pse__Is_Template__c,recordTypeId,TemplateName__c
                                          FROM pse__Proj__c WHERE Id IN:projectIds]){
                    ImpProjectList.add(impProj);
                }
                NSP_ProjectTriggerHelper.createImplementationProfile(ImpProjectList, accIdSet); 
                NSP_ProjectTriggerHelper.createProjectTeamRoles(ImpProjectList);
                //setting Project Task start and end date for fso and mm implementation
                setStartDateAndEndDateOnFSOImplProjectTask(projectIds);
            }


            if(!projectAssetMapping.isEmpty()){
                List < Database.UpsertResult > upsertResults = Database.upsert(projectAssetMapping, false);
                NSP_ErrorLogHandler.logUpsertResultsException(NSP_ASSET_PROJECT_CREATION, 'createImplementationProject', upsertResults);
            }
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(NSP_ASSET_PROJECT_CREATION, 'createImplementationProject', ex.getMessage());
        }
    }
    
    public Id createProjectWithTemplateFromAsset(Template_Key_and_Id_Mapping__mdt oTempKey, Id assetId){
        Id projectId = new NSP_AssetServiceTriggerHelper().createProjectWithTemplateFromAsset( oTempKey,  assetId);
        return projectId;  
    }
    
    /**
* Name        : linkProjectWithAsset
* Purpose     : Method to link the entity to the project
* @param      : Id projectId, Id assetId
* @return     : Project_Asset__c
*/
    public static Project_Asset__c linkProjectWithAsset(Id projectId, Id assetId){
        Project_Asset__c newProject = new Project_Asset__c();
        newProject.Project__c = projectId;
        newProject.Asset__c = assetId;
        
        return newProject;
    }

    private static pse__Proj__c createProjectObject(Id projId, Id recordTypeId, Id accountId,String assetTemplateType, Id opportunityId ){
        pse__Proj__c project = new pse__Proj__c();
        project.Id= projId;
        project.pse__Project_Status__c = NSP_ServiceConstants.ProjectStatus;
        project.pse__Account__c = accountId;
        project.RecordTypeId = recordTypeId;
        project.pse__Is_Billable__c = False;
        project.NSP_Asset_Implementation_Project__c= True;
        // AZD-269852 ~ mflorian created on 4/4/2024
        if ( NSP_hotfix_Switch__c.getInstance( UserInfo.getUserId() ).Is_Opportunity_Allowed_On_Project__c ) {
            project.pse__Opportunity__c = opportunityId;
        }
        if(assetTemplateType== label.Middle_Market_Implementation_Project){
            project.pse__End_Date__c = System.Today().addDays(180);
        }else if(assetTemplateType== label.FSOImplementationProject){
            project.pse__End_Date__c = System.Today().addDays(90);
        }
        return project;
    }

    /**
    * Update Start Date and End date on Project Task when WO Asset are created
    * @param setOfProject List of project. 
    * @return void
    */
    private static void setStartDateAndEndDateOnFSOImplProjectTask(Set<Id> setOfProject){   
        Set<Id> setOfProjectId = new Set<Id>();
        Id projectRecordType = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c',NSP_ServiceConstants.PEOProject);
        Map<Id,pse__Proj__c> projectMap = new Map<Id,pse__Proj__c> ();
        List<pse__Project_Task__c> projectTaskList= [SELECT Id, Name,pse__Project__c FROM pse__Project_Task__c WHERE pse__Project__c IN:  setOfProject];
        for(pse__Project_Task__c projectTask : projectTaskList){
        if(projectTask.pse__Project__c != null && projectTask.NSP_Template_Generated__c){
                    setOfProjectId.add(projectTask.pse__Project__c);
            }
        }
        
        if(!setOfProjectId.isEmpty()){
            for(pse__Proj__c project : [SELECT  Id, TemplateName__c,pse__Project_Type__c, RecordTypeId, pse__Account__r.NSP_AIMS_Renewal_Date__c, pse__Start_Date__c, pse__End_Date__c 
                                        FROM pse__Proj__c 
                                        WHERE ID IN : setOfProjectId and pse__Is_Template__c = false])
                                        //check if project of type implementation and MM or FSO template
                                        if(!projectMap.containsKey(project.id) && project.RecordTypeId == projectRecordType && project.pse__Project_Type__c == NSP_ServiceConstants.ImplementationProjectType 
                                        && (project.TemplateName__c == label.Middle_Market_Implementation_Project || project.TemplateName__c == label.FSOImplementationProject ) ){
                                            projectMap.put(project.id,project);
                                        }
            }
            //update start & end time of project task of type implementation and template MM or FSO as part of STY-02129
        if(!projectMap.isEmpty()){
            for(pse__Project_Task__c prTask:projectTaskList){
                // updating Project Start and End Date on Project Taks 
                if(prTask.pse__Project__c!=null && projectMap.containsKey(prTask.pse__Project__c)){
                    prTask.pse__Start_Date_Time__c	= DateTime.newInstance(system.Now().date(), Time.newInstance(12, 0, 0, 0));
                    prTask.pse__End_Date_Time__c = DateTime.newInstance(projectMap.get(prTask.pse__Project__c).pse__End_Date__c, Time.newInstance(12, 0, 0, 0));
                }  
        
            }
        }
    }
    
}