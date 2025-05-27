public class NSP_PTOSmartformTriggerHelper {
    // test w/ NSP_PTOSmartformTriggerHelperTest (87%)

	//
    // Iterates throught the PTO Smartform  map and identifies the records that needs to worked based on various criterias.
    // @param ptoSmartformNewMap Map of New PTO Smartform.
    // @param ptoSmartformOldMap Map of Old PTO Smartform.
    // @return void
    //
    public void beforeUpdateMethod( Map<Id,NSP_PTO_Smartform__c> ptoSmartformNewMap , Map<Id,NSP_PTO_Smartform__c> ptoSmartformOldMap ) {
        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
		List<Case> newCasesList = new List<Case>();
        List<Case> newCasesOnCloseList = new List<Case>();
        List<Case> updateCasesList = new List<Case>();
        List<FeedItem> chatterList = new List<FeedItem>();
        Map<Id,String> contactWithEmailMap = new Map<Id,String>();
        Map<Id,String> accounttWithTeamMemberMap = new Map<Id,String>();
        Map<String,Group> queueMap =  new Map<String,Group> ();
        Set<Id> relatedPTOIdSet = new Set<Id>();
        Map<Id,String> submittedPTOIdMap = new Map<Id,String>();
        Id aimsRecordTypeId  = NSP_GenericRecordType.getRecordTypeId( 'NSP_PTO_Smartform__c' , 'NSP_AIMS' );
        Id itaRecordTypeId  = NSP_GenericRecordType.getRecordTypeId( 'NSP_PTO_Smartform__c' , 'NSP_ITA' );
        for ( Group relatedGroup : [
                    SELECT Id , Name , DeveloperName , Type
                    FROM Group
                    WHERE (
                        Type = :NSP_SalesConstants.Queue
                        AND (
                            DeveloperName = :NSP_SalesConstants.NSP_AIMS_form
                            OR DeveloperName = :NSP_SalesConstants.NSP_ITA_form
                            OR DeveloperName = :NSP_SalesConstants.NSP_National_PTO
                        )
                    )
                ]
            )
        {
        	queueMap.put( relatedGroup.DeveloperName , relatedGroup );
        }
    	for ( NSP_PTO_Smartform__c newPTOSmartform : ptoSmartformNewMap.values() ) {
            if ( newPTOSmartform.NSP_Contact_Name__c != null
                && newPTOSmartform.NSP_Contact_Name__c != ptoSmartformOldMap.get( newPTOSmartform.Id ).NSP_Contact_Name__c
                )
            {
                contactIdSet.add( newPTOSmartform.NSP_Contact_Name__c );
            }
            if ( newPTOSmartform.NSP_Account__c != null
                && newPTOSmartform.NSP_Account__c != ptoSmartformOldMap.get( newPTOSmartform.Id ).NSP_Account__c
                )
            {
                accountIdSet.add( newPTOSmartform.NSP_Account__c );
            }
            if ( ( newPTOSmartform.NSP_Status__c != null ) || ( newPTOSmartform.NSP_Status__c != '' ) ) {
            	if ( ptoSmartformOldMap.get( newPTOSmartform.Id ).NSP_Status__c == NSP_SalesConstants.Draft
                    && newPTOSmartform.NSP_Status__c == NSP_SalesConstants.Submitted
                    )
                {
                    Case newCase = new Case();
                    newCase.NSP_PTO_Smartform__c = newPTOSmartform.Id;
                    newCase.NSP_Category__c = NSP_SalesConstants.HRInfrastructure;
                    newCase.NSP_SubCategory__c = NSP_SalesConstants.PTOPlanAnalysisDevelopmentandtracking;
                    newCase.Subject = NSP_SalesConstants.PTOSmartformSetup;
                    newCase.Status = NSP_SalesConstants.Reopened;
                    if ( newPTOSmartform.RecordTypeId == aimsRecordTypeId ) {
                    	newCase.OwnerId = queueMap.get( NSP_SalesConstants.NSP_AIMS_form ).Id;
                    }
                    if ( newPTOSmartform.RecordTypeId == itaRecordTypeId ) {
                    	newCase.OwnerId = queueMap.get( NSP_SalesConstants.NSP_ITA_form ).Id;
                    }
                    newCasesList.add( newCase );
            	}
                if ( ptoSmartformOldMap.get( newPTOSmartform.Id ).NSP_Status__c == NSP_SalesConstants.Submitted
                    && newPTOSmartform.NSP_Status__c == NSP_SalesConstants.Resubmit
                    )
                {
                	relatedPTOIdSet.add( newPTOSmartform.Id );
                }
                if ( ptoSmartformOldMap.get( newPTOSmartform.Id ).NSP_Status__c != newPTOSmartform.NSP_Status__c
                    && newPTOSmartform.NSP_Status__c == NSP_SalesConstants.Submitted
                    && newPTOSmartform.RecordTypeId == aimsRecordTypeId
                    )
                {
                	submittedPTOIdMap.put( newPTOSmartform.Id , newPTOSmartform.NSP_Is_the_is_a_Middle_Market_client__c );
                }
        	}
		}
        if ( !contactIdSet.isEmpty() ) {
            for ( Contact con : [ SELECT Id , NSP_Work_email__c FROM Contact WHERE Id IN :contactIdSet ] ) {
                if ( con.NSP_Work_email__c != null ) {
                	contactWithEmailMap.put( con.Id , con.NSP_Work_email__c );
                }
            }
        }
        if ( !accountIdSet.isEmpty() ) {
            for ( NSP_Account_Team__c AccTeamMember : [
                        SELECT Id , NSP_Role__c , NSP_Account__c , NSP_Email__c , NSP_User__c , NSP_User__r.Name
                        FROM NSP_Account_Team__c
                        WHERE (
                            NSP_Account__c IN :accountIdSet
                            AND NSP_Role__c = :NSP_SalesConstants.MANAGERHRSERVICE
                        )
                    ]
                )
            {
                if ( AccTeamMember.NSP_User__c != null ) {
                	accounttWithTeamMemberMap.put( AccTeamMember.NSP_Account__c , AccTeamMember.NSP_User__r.Name );
                }
            }
        }
        if ( !contactWithEmailMap.isEmpty() || !accounttWithTeamMemberMap.isEmpty() ) {
        	for ( NSP_PTO_Smartform__c pto : ptoSmartformNewMap.values() ) {
                if ( !contactWithEmailMap.isEmpty() && ( pto.NSP_Contact_Name__c != null ) && ( pto.NSP_Contact_email_address__c == null ) ) {
                    pto.NSP_Contact_email_address__c = contactWithEmailMap.get( pto.NSP_Contact_Name__c );
                }
                if ( !accounttWithTeamMemberMap.isEmpty() && ( pto.NSP_Account__c != null ) ) {
                    pto.NSP_Account_HRS__c = accounttWithTeamMemberMap.get( pto.NSP_Account__c );
                }
            }
        }
        if ( !newCasesList.isEmpty() ) {
            insert newCasesList;
        }
        if ( !relatedPTOIdSet.isEmpty() || !submittedPTOIdMap.isEmpty() ) {
            for ( Case relatedCase : [
                        SELECT Id , NSP_Case_Sub_Status__c , NSP_PTO_Smartform__c , Status
                        FROM Case
                        WHERE NSP_PTO_Smartform__c IN :relatedPTOIdSet
                    ]
                )
            {
                if ( relatedCase.Status != NSP_SalesConstants.Closed || relatedCase.Status != NSP_SalesConstants.Cancelled ) {
                    relatedCase.NSP_Case_Sub_Status__c = NSP_SalesConstants.PTOSmartformresubmitted;
                    updateCasesList.add( relatedCase );
                    //Adding a Text post
                    FeedItem post = new FeedItem();
                    post.ParentId = relatedCase.Id;
                    post.Body = NSP_SalesConstants.CaseSubject;
                    chatterList.add( post );
                }
                if ( relatedCase.Status == NSP_SalesConstants.Closed ) {
                	if ( relatedCase.CreatedDate <= System.Today()
                        && relatedCase.CreatedDate >= System.Today().addDays( 90 )
                        )
                    {
                        relatedCase.Status = NSP_SalesConstants.Reopened;
                        relatedCase.NSP_Case_Sub_Status__c = NSP_SalesConstants.PTOSmartformresubmitted;
                        updateCasesList.add( relatedCase );
                        //Adding a Text post
                        FeedItem post = new FeedItem();
                        post.ParentId = relatedCase.Id;
                        post.Body = NSP_SalesConstants.CaseSubject;
                        chatterList.add( post );
                    } else {
                        Case newCase = new Case();
                        newCase.NSP_PTO_Smartform__c = relatedCase.NSP_PTO_Smartform__c;
                        newCase.Subject = NSP_SalesConstants.PTOSmartformresubmitted;
                        newCase.OwnerId = relatedCase.OwnerId;
                        newCasesOnCloseList.add( newCase );
                    }
                }
                if ( !submittedPTOIdMap.isEmpty() ) {
                	relatedCase.OwnerId = (
                        submittedPTOIdMap.get( relatedCase.NSP_PTO_Smartform__c ) == NSP_SalesConstants.No
                        ? queueMap.get( NSP_SalesConstants.NSP_National_PTO ).Id
                        : relatedCase.OwnerId
                    );
                    updateCasesList.add( relatedCase );
                }
            }
        }
        if ( !chatterList.isEmpty() ) {
            insert chatterList;
        }
        if ( !newCasesOnCloseList.isEmpty() ) {
            insert newCasesOnCloseList;
        }
    }

    //
    // Iterates throught the PTO Smartform  List and identifies the records that needs to worked based on various criterias.
    // @param newPTOSmartformsList List of New PTO Smartform.
    // @return void
    //
    public void beforeInsertMethod( List<NSP_PTO_Smartform__c> newPTOSmartformsList ) {
        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id,String> contactWithEmailMap = new Map<Id,String>();
        Map<Id,String> accounttWithTeamMemberMap = new Map<Id,String>();
        if ( ( newPTOSmartformsList != null ) || !newPTOSmartformsList.isEmpty() ) {
            for ( NSP_PTO_Smartform__c pto : newPTOSmartformsList ) {
                if ( pto.NSP_Contact_Name__c != null ) {
                	contactIdSet.add( pto.NSP_Contact_Name__c );
                }
                if ( pto.NSP_Account__c != null ) {
                	accountIdSet.add( pto.NSP_Account__c );
            	}
            }
        }
        if ( !contactIdSet.isEmpty() ) {
            for ( Contact con : [ SELECT Id , NSP_Work_email__c FROM Contact WHERE ( Id IN :contactIdSet ) ] ) {
                if ( con.NSP_Work_email__c != null ) {
                	contactWithEmailMap.put( con.Id , con.NSP_Work_email__c );
                }
            }
        }
        if ( !accountIdSet.isEmpty() ) {
            for ( NSP_Account_Team__c AccTeamMember : [
                        SELECT Id , NSP_Role__c , NSP_Account__c , NSP_Email__c , NSP_User__c , NSP_User__r.Name
                        FROM NSP_Account_Team__c
                        WHERE (
                            NSP_Account__c IN :accountIdSet
                            AND NSP_Role__c = :NSP_SalesConstants.HRSpecialist
                        )
                    ]
                )
            {
                if ( AccTeamMember.NSP_User__c != null ) {
                	accounttWithTeamMemberMap.put( AccTeamMember.NSP_Account__c , AccTeamMember.NSP_User__r.Name );
                }
            }
        }
        if ( !contactWithEmailMap.isEmpty() || !accounttWithTeamMemberMap.isEmpty() ) {
        	for( NSP_PTO_Smartform__c pto : newPTOSmartformsList ) {
                if ( !contactWithEmailMap.isEmpty() && ( pto.NSP_Contact_Name__c != null ) ) {
                    pto.NSP_Contact_email_address__c = contactWithEmailMap.get( pto.NSP_Contact_Name__c );
                }
                if ( !accounttWithTeamMemberMap.isEmpty() && ( pto.NSP_Account__c != null)  ) {
                    pto.NSP_Account_HRS__c = accounttWithTeamMemberMap.get( pto.NSP_Account__c );
                }
            }
        }
    }

    //
    // Iterates throught the PTO Smartform  List and identifies the records that needs to worked based on various criterias.
    // @param newPTOSmartformsList List of New PTO Smartform.
    // @param ptoSmartformNewMap Map of New PTO Smartform.
    // @return void
    //
    public void afterInsertMethod( List<NSP_PTO_Smartform__c> newPTOSmartformsList , Map<Id,NSP_PTO_Smartform__c> ptoSmartformNewMap ) {
    	List<Case> newCasesList = new List<Case>();
        Map<String,Group> queueMap =  new Map<String,Group>();
        Id aimsRecordTypeId  = NSP_GenericRecordType.getRecordTypeId( 'NSP_PTO_Smartform__c' , 'NSP_AIMS' );
        Id itaRecordTypeId  = NSP_GenericRecordType.getRecordTypeId( 'NSP_PTO_Smartform__c' , 'NSP_ITA' );
        for ( Group relatedGroup : [
                    SELECT Id , Name , DeveloperName , Type
                    FROM Group
                    WHERE (
                        Type = :NSP_SalesConstants.Queue
                        AND (
                            DeveloperName = :NSP_SalesConstants.NSP_AIMS_form
                            OR DeveloperName = :NSP_SalesConstants.NSP_ITA_form
                            OR DeveloperName = :NSP_SalesConstants.NSP_National_PTO
                        )
                    )
                ]
            )
        {
        	queueMap.put( relatedGroup.DeveloperName , relatedGroup );
        }
        if ( ( newPTOSmartformsList != null ) || !newPTOSmartformsList.isEmpty() ) {
            for ( NSP_PTO_Smartform__c pto : newPTOSmartformsList ) {
                if ( pto.NSP_Status__c == NSP_SalesConstants.Submitted ) {
                    Case newCase = new Case();
                    newCase.NSP_PTO_Smartform__c = pto.Id;
                    newCase.NSP_Category__c = NSP_SalesConstants.HRInfrastructure;
                    newCase.NSP_SubCategory__c = NSP_SalesConstants.PTOPlanAnalysisDevelopmentandtracking;
                    newCase.Subject = NSP_SalesConstants.PTOSmartformSetup;
                    if ( pto.RecordTypeId == aimsRecordTypeId ) {
                        newCase.OwnerId = queueMap.get( NSP_SalesConstants.NSP_AIMS_form ).Id;
                    }
                    if ( pto.RecordTypeId == itaRecordTypeId ) {
                        newCase.OwnerId = queueMap.get( NSP_SalesConstants.NSP_ITA_form ).Id;
                    }
                    newCasesList.add( newCase );
                }
            }
        }
        if ( !newCasesList.isEmpty() ) {
            insert newCasesList;
        }
    }

}
//