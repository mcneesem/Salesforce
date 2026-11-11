public with sharing class NSP_CreateProjectFromTemplate {
    // test w/ NSP_CreateProjectFromTemplateTest (83%)

    // Class Level variables.
    public sObject objVal{get;set;}
    public static Map<String, String> fieldValuesMap;
    public Case caseRecVal;
    public Asset assetRecVal;
    public String sObjName;
    public static Id parentId;
    public static Id accountId;
    public static String caseComment;
    public static final List<String> CASE_FIELDS = new List<String>{
        'Id',
        'Subject', 'AccountId', 'Project_Template__c'
    };
    public pse__Proj__c inputProj{
        get{
            if(inputProj == null)
                inputProj = new pse__Proj__c();
            return inputProj;
        }set;
    }

    public Case caseRef;
    public Case getcaseRef() {
        return caseRef;
    }
    public void setcaseRef(Case caseRecVal){
        caseRef = caseRecVal;
    }

    public Asset assetRef;
    public Asset getassetRef() {
        return assetRef;
    }
    public void setassetRef(Asset assetRecVal){
        assetRef = assetRecVal;
    }

    public NSP_CreateProjectFromTemplate( ApexPages.StandardController stdController ) {
        Id recId = apexpages.currentpage().getparameters().get( 'id' );
        sObjName = recId.getSObjectType().getDescribe().getName();
        objVal = (sObject)stdController.getRecord();
    }

    public NSP_CreateProjectFromTemplate() {
        Id recordId = System.currentPagereference().getParameters().get( 'parentid' );
        if ( ( recordId != null )
            && ( recordId.getSObjectType() == Asset.getSObjectType() )
            )
        {
            sObjName = 'Project_Asset__c';
            List<Asset> assetRecVal = [
                SELECT Id , Name , AccountId , Project_Template__c
                FROM Asset
                WHERE ( Id = :recordId )
            ];
            if ( !assetRecVal.isEmpty() ) {
                this.setassetRef( assetRecVal[0] );
            }
        } else {
            sObjName = 'pse__Proj__c';
            String caseQuery = new NSP_QueryBuilder( 'Case' , CASE_FIELDS )
                .addFilter(
                    'Id' ,
                    System.currentPagereference().getParameters().get( 'parentid' )
                )
                .addLimit( 1 )
                .build();
            Case caseRecVal =  Database.query( caseQuery );
            setcaseRef( caseRecVal );
        }
    }

    public static Map<String, String> fetchFieldsDetails(String sObjName, sObject objVal, pse__Proj__c inputProj, Case caseRef, Asset assetRef){
        Map<String, String> fieldLebelWithValuesMap = new Map<String, String>();
        if(sObjName == 'Case'){
            Case caseInstance = (Case)objVal;
            fieldLebelWithValuesMap.put('ProjectId', caseInstance.Project_Template__c);
            fieldLebelWithValuesMap.put('StartDate', String.valueof(inputProj.pse__Start_Date__c));
            fieldLebelWithValuesMap.put('ProjectName', caseInstance.Subject);
            parentId = caseInstance.Id;
            accountId = caseInstance.AccountId;
        }
        if(sObjName == 'pse__Proj__c'){
            fieldLebelWithValuesMap.put('ProjectId', caseRef.Project_Template__c);
            fieldLebelWithValuesMap.put('StartDate', String.valueof(inputProj.pse__Start_Date__c));
            fieldLebelWithValuesMap.put('ProjectName', caseRef.Subject);
            parentId = caseRef.Id;
            accountId = caseRef.AccountId;
        }
        if(sObjName == 'Asset'){
            Asset assetInstance = (Asset)objVal;
            fieldLebelWithValuesMap.put('ProjectId', assetInstance.Project_Template__c);
            fieldLebelWithValuesMap.put('StartDate', String.valueof(inputProj.pse__Start_Date__c));
            fieldLebelWithValuesMap.put('ProjectName', assetInstance.Name);
            parentId = assetInstance.Id;
            accountId = assetInstance.AccountId;
        }
        if(sObjName == 'Project_Asset__c'){
            fieldLebelWithValuesMap.put('ProjectId', assetRef.Project_Template__c);
            fieldLebelWithValuesMap.put('StartDate', String.valueof(inputProj.pse__Start_Date__c));
            fieldLebelWithValuesMap.put('ProjectName', assetRef.Name);
            parentId = assetRef.Id;
            accountId = assetRef.AccountId;
        }

        return fieldLebelWithValuesMap;
    }

    public PageReference createProject() {
        fieldValuesMap = fetchFieldsDetails(sObjName, objVal, inputProj, caseRef, assetRef);

        //Set up input fields for template service
        Id templateProjectId = Id.valueof(fieldValuesMap.get('ProjectId'));
        Date startDate = Date.valueof(fieldValuesMap.get('StartDate'));
        //Instantiate the request
        pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest projRequest =
            new pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest(templateProjectId,
                                                                                      startDate);
        //Set new project name to specified name
        projRequest.ProjectName = fieldValuesMap.get('ProjectName');
        //Call the service and create project
        List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projResponse = pse.CreateProjectFromTemplateService.createProjectsFromTemplates(
            new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest>{ projRequest }
        );
        Id newProjectId = CreateProjectFromTemplateAction.handleCreateProjectResponse(
            NSP_CreateProjectFromTemplate.class.getName() ,
            'createProject:visualforce' ,
            projResponse
        );
        if ( newProjectId != null ) {
            // update the project with its related entity.
            if ( sObjName == 'Case' ) {
                linkProjectWithCase( newProjectId , parentId , accountId , caseComment );
            }
            if ( sObjName == 'Asset' || sObjName == 'Project_Asset__c' ) {
                linkProjectWithAsset( newProjectId , parentId );
            }
            PageReference nextPage = new PageReference( '/' + newProjectId );
            nextPage.setRedirect( true );
            return nextPage;
        } else {
            for ( pse.CreateProjectFromTemplateService.CreateProjectError err : projResponse[0].Errors ) {
                ApexPages.addMessage( new ApexPages.message( ApexPages.severity.ERROR , err.Message ) );
            }
            return null;
        }
    }

    public static void linkProjectWithCase( Id projectId , Id parentId , Id accountId , String caseComment ) {
        pse__Proj__c newProject = new pse__Proj__c();
        newProject.Id = projectId;
        newProject.Case__c = parentId;
        newProject.pse__Account__c = accountId;
        newProject.Comments__c = caseComment;
        update newProject;
    }

    public static void linkProjectWithCase( Id projectId , Id parentId , Id accountId , String caseComment , Date dueDate , Id recordTypeId ) {
        pse__Proj__c newProject = new pse__Proj__c();
        newProject.Id = projectId;
        newProject.Case__c = parentId;
        newProject.pse__Account__c = accountId;
        newProject.Comments__c = caseComment;
        newProject.Go_Live_Date__c = dueDate;
        newProject.recordTypeId = recordTypeId;
        update newProject;
    }

    public static void linkProjectWithAsset( Id projectId , Id parentId ) {
        Project_Asset__c newProject = new Project_Asset__c();
        newProject.Project__c = projectId;
        newProject.Asset__c = parentId;
        insert newProject;
    }

    @AuraEnabled
    public static ResponseWrapper createProject(
        String sobjName ,
        Id recordId ,
        String objVal ,
        Date startDate
        )
    {
        Asset oAsset;
        Case oCase;
        Id parentId,accountId;
        String caseComment;
        Date dueDate;
        Map<String,String> fieldValuesMap = new Map<String,String>();
        pse__Proj__c oProject = new pse__Proj__c();
        try {
            if ( recordId.getSobjectType() == Asset.getSObjectType() ) {
                oAsset = (Asset)JSON.deserialize( objVal , Asset.class );
                oProject.pse__Start_Date__c = startDate;
                List<Asset> currentAsset = [
                    SELECT Id , Name , AccountId , Project_Template__c
                    FROM Asset
                    WHERE ( Id = :recordId )
                ];
                fieldValuesMap.put( 'ProjectId' , oAsset.Project_Template__c );
                fieldValuesMap.put( 'ProjectName' , oAsset.name );
                parentId = recordId;
                accountId = null;
                if ( !currentAsset.isEmpty() ) {
                    accountId = currentAsset[0].AccountId;
                }
            } else if ( recordId.getSobjectType() == Case.getSObjectType() ) {
                oCase = (Case)JSON.deserialize(objVal , Case.class );
                fieldValuesMap.put( 'ProjectId', oCase.Project_Template__c );
                if ( oCase.Subject != '' ) {
                    fieldValuesMap.put( 'ProjectName' , oCase.Subject );
                } else {
                    fieldValuesMap.put( 'ProjectName' , oCase.Project_Template__r.Name );
                }
                List<Case> currentCase = [
                    SELECT
                        Id ,
                        Subject ,
                        Comments_for_Project__c ,
                        AccountId ,
                        Project_Template__c ,
                        NSP_Due_Date__c
                    FROM Case
                    WHERE ( Id = :recordId )
                ];
                parentId = recordId;
                accountId = null;
                caseComment = null;
                dueDate = null;
                if ( !currentCase.isEmpty() ) {
                    accountId = currentCase[0].AccountId;
                    caseComment = currentCase[0].Comments_for_Project__c;
                    dueDate = currentCase[0].NSP_Due_Date__c;
                }
            }
            Id templateProjectId = Id.valueof( fieldValuesMap.get( 'ProjectId' ) );
            List<pse__Proj__c> templateProjects = null;
            if ( templateProjectId != null ) {
                templateProjects = [
                    SELECT RecordTypeId
                    FROM pse__Proj__c
                    WHERE ( Id = :templateProjectId )
                ];
            }
            pse__Proj__c templateProject = null;
            if ( !templateProjects?.isEmpty() ) {
                templateProject = templateProjects[0];
            }
            Id projectRecordTypeId = null;
            if ( templateProject != null ) {
                projectRecordTypeId = templateProject.RecordTypeId;
            }
            pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest projRequest = new pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest(
                templateProjectId ,
                startDate
            );
            projRequest.ProjectName = fieldValuesMap.get('ProjectName');
            List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projResponse = pse.CreateProjectFromTemplateService.createProjectsFromTemplates(
                new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest>{ projRequest }
            );
            Id newProjectId = CreateProjectFromTemplateAction.handleCreateProjectResponse(
                NSP_CreateProjectFromTemplate.class.getName() ,
                'createProject:aura' ,
                projResponse
            );
            if ( newProjectId != null ) {
                // update the project with its related entity.
                if ( sObjName == 'Case' ) {
                    linkProjectWithCase(
                        newProjectId ,
                        parentId ,
                        accountId ,
                        caseComment ,
                        dueDate ,
                        projectRecordTypeId
                    );
                }
                if ( sObjName == 'Asset' ) {
                    update new pse__Proj__c(
                        Id=newProjectId ,
                        RecordTypeId=projectRecordTypeId
                    );
                    linkProjectWithAsset( newProjectId , parentId );
                }
                return new ResponseWrapper( true , newProjectId , '' );
            } else {
                List<String> lErros = new List<String>();
                for ( pse.CreateProjectFromTemplateService.CreateProjectError err : projResponse[0].Errors ) {
                    lErros.add( err.Message );
                }
                return new ResponseWrapper( false , '' , lErros[0] );
            }
        } catch ( Exception e ) {
            return new ResponseWrapper( false , '' , e.getMessage() );
        }
    }

}
//
