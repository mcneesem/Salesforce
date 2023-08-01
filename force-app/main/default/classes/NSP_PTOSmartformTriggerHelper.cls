public class NSP_PTOSmartformTriggerHelper {
	/**
    * Iterates throught the PTO Smartform  map and identifies the records that needs to worked based on various criterias.
    * @param PTOSmartformNewMap Map of New PTO Smartform. 
    * @param PTOSmartformOldMap Map of Old PTO Smartform. 
    * @return void             
    *                
    */
    
    public void beforeUpdateMethod(Map<Id, NSP_PTO_Smartform__c> PTOSmartformNewMap, Map<Id, NSP_PTO_Smartform__c> PTOSmartformOldMap){
        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
		List<Case> newCasesList = new List<Case>();
        List<Case> newCasesOnCloseList = new List<Case>();
        List<Case> updateCasesList = new List<Case>();
        List<FeedItem> chatterList = new List<FeedItem>();
        Map<Id, String> contactWithEmailMap = new Map<Id, String>();
        Map<Id, String> accounttWithTeamMemberMap = new Map<Id, String>();
        Map<String, Group> queueMap =  new Map<String, Group> (); 
        Set<Id> relatedPTOIdSet = new Set<Id>(); 
        Map<Id, String> submittedPTOIdMap = new Map<Id, String>(); 
        
        Id AIMSrecordTypeId = Schema.SObjectType.NSP_PTO_Smartform__c.getRecordTypeInfosByDeveloperName().get(NSP_SalesConstants.AIMS).getRecordTypeId();
        Id ITArecordTypeId = Schema.SObjectType.NSP_PTO_Smartform__c.getRecordTypeInfosByDeveloperName().get(NSP_SalesConstants.ITA).getRecordTypeId();
        
        for(Group relatedGroup : [SELECT DeveloperName, Id, Name, Type 
                                  FROM Group 
                                  WHERE Type =: NSP_SalesConstants.Queue AND 
                                  (DeveloperName =: NSP_SalesConstants.NSP_AIMS_form OR 
                                   DeveloperName =: NSP_SalesConstants.NSP_ITA_form OR
                                   DeveloperName =: NSP_SalesConstants.NSP_National_PTO)]){
        	queueMap.put(relatedGroup.DeveloperName, relatedGroup);                              
        }
        
    	for(NSP_PTO_Smartform__c newPTOSmartform : PTOSmartformNewMap.values()) {
            if(newPTOSmartform.NSP_Contact_Name__c != null && 
               newPTOSmartform.NSP_Contact_Name__c != PTOSmartformOldMap.get(newPTOSmartform.Id).NSP_Contact_Name__c){
                contactIdSet.add(newPTOSmartform.NSP_Contact_Name__c);    
            }
            if(newPTOSmartform.NSP_Account__c != null && 
               newPTOSmartform.NSP_Account__c != PTOSmartformOldMap.get(newPTOSmartform.Id).NSP_Account__c){
                accountIdSet.add(newPTOSmartform.NSP_Account__c);    
            }
            if((newPTOSmartform.NSP_Status__c != null || newPTOSmartform.NSP_Status__c != '')){  
            	if(PTOSmartformOldMap.get(newPTOSmartform.Id).NSP_Status__c == NSP_SalesConstants.Draft && 
                    newPTOSmartform.NSP_Status__c == NSP_SalesConstants.Submitted){
                    Case newCase = new Case();
                    newCase.NSP_PTO_Smartform__c = newPTOSmartform.Id;
                    newCase.NSP_Category__c = NSP_SalesConstants.HRInfrastructure;
                    newCase.NSP_SubCategory__c = NSP_SalesConstants.PTOPlanAnalysisDevelopmentandtracking;
                    newCase.Subject = NSP_SalesConstants.PTOSmartformSetup;
                    newCase.CreatedById = newPTOSmartform.LastModifiedById;
                    newCase.Status = NSP_SalesConstants.Reopened;
                    if(newPTOSmartform.RecordTypeId == AIMSrecordTypeId){
                    	newCase.OwnerId = queueMap.get(NSP_SalesConstants.NSP_AIMS_form).Id;    
                    }
                    if(newPTOSmartform.RecordTypeId == ITArecordTypeId){
                    	newCase.OwnerId = queueMap.get(NSP_SalesConstants.NSP_ITA_form).Id;    
                    }
                    newCasesList.add(newCase);
            	}
                if(PTOSmartformOldMap.get(newPTOSmartform.Id).NSP_Status__c == NSP_SalesConstants.Submitted && 
                    newPTOSmartform.NSP_Status__c == NSP_SalesConstants.Resubmit){
                	relatedPTOIdSet.add(newPTOSmartform.Id);  
                }
                if(PTOSmartformOldMap.get(newPTOSmartform.Id).NSP_Status__c != newPTOSmartform.NSP_Status__c&& 
                    newPTOSmartform.NSP_Status__c == NSP_SalesConstants.Submitted && newPTOSmartform.RecordTypeId == AIMSrecordTypeId){
                	submittedPTOIdMap.put(newPTOSmartform.Id, newPTOSmartform.NSP_Is_the_is_a_Middle_Market_client__c); 
                }
        	}
		}
        if(contactIdSet.size() > 0){
            for(Contact con : [SELECT Id, NSP_Work_email__c FROM Contact WHERE Id IN: contactIdSet]){
                if(con.NSP_Work_email__c != null){
                	contactWithEmailMap.put(con.Id, con.NSP_Work_email__c);    
                }
            }
        }
        if(accountIdSet.size() > 0){
            for(NSP_Account_Team__c AccTeamMember : [SELECT Id, NSP_Role__c, NSP_Account__c, NSP_Email__c, 
                                                     NSP_User__c, NSP_User__r.Name
                                                     FROM NSP_Account_Team__c 
                                                     WHERE NSP_Account__c IN: accountIdSet AND
                                                     NSP_Role__c =: NSP_SalesConstants.MANAGERHRSERVICE]){
                if(AccTeamMember.NSP_User__c != null){
                	accounttWithTeamMemberMap.put(AccTeamMember.NSP_Account__c, AccTeamMember.NSP_User__r.Name);    
                }
            }
        }
        if(!contactWithEmailMap.isEmpty() || !accounttWithTeamMemberMap.isEmpty()){
        	for(NSP_PTO_Smartform__c PTO : PTOSmartformNewMap.values()){
                if(!contactWithEmailMap.isEmpty()){
                    if(PTO.NSP_Contact_Name__c != null && PTO.NSP_Contact_email_address__c == null){
                        PTO.NSP_Contact_email_address__c = contactWithEmailMap.get(PTO.NSP_Contact_Name__c);  
                    }
                }
                if(!accounttWithTeamMemberMap.isEmpty()){
                    if(PTO.NSP_Account__c != null){
                        PTO.NSP_Account_HRS__c = accounttWithTeamMemberMap.get(PTO.NSP_Account__c);  
                    }
                }
            }
        }
        if(newCasesList.size() > 0){
            insert newCasesList;
        }
        if(relatedPTOIdSet.size() > 0 || !submittedPTOIdMap.isEmpty()){
            for(Case relatedCase : [SELECT Id, NSP_Case_Sub_Status__c, NSP_PTO_Smartform__c, Status
                                    FROM Case 
                                    WHERE NSP_PTO_Smartform__c IN: relatedPTOIdSet]){
                if(relatedCase.Status != NSP_SalesConstants.Closed || relatedCase.Status != NSP_SalesConstants.Cancelled){
                    relatedCase.NSP_Case_Sub_Status__c = NSP_SalesConstants.PTOSmartformresubmitted;	 
                    updateCasesList.add(relatedCase);
                    //Adding a Text post
                    FeedItem post = new FeedItem();
                    post.ParentId = relatedCase.Id;
                    post.Body = NSP_SalesConstants.CaseSubject;
                    chatterList.add(post);
                }
                if(relatedCase.Status == NSP_SalesConstants.Closed){
                	if(relatedCase.CreatedDate <= System.Today() && relatedCase.CreatedDate >= system.Today().addDays(90)){
                        relatedCase.Status = NSP_SalesConstants.Reopened;
                        relatedCase.NSP_Case_Sub_Status__c = NSP_SalesConstants.PTOSmartformresubmitted;	 
                        updateCasesList.add(relatedCase);
                        //Adding a Text post
                        FeedItem post = new FeedItem();
                        post.ParentId = relatedCase.Id;
                        post.Body = NSP_SalesConstants.CaseSubject;
                        chatterList.add(post);
                    }else{
                        Case newCase = new Case();
                        newCase.NSP_PTO_Smartform__c = relatedCase.NSP_PTO_Smartform__c;
                        newCase.Subject = NSP_SalesConstants.PTOSmartformresubmitted;
                        newCase.CreatedById = relatedCase.CreatedById;
                        newCase.OwnerId = relatedCase.OwnerId; 
                        newCasesOnCloseList.add(newCase);       
                    }
                }
                if(!submittedPTOIdMap.isEmpty()){
                	relatedCase.OwnerId = submittedPTOIdMap.get(relatedCase.NSP_PTO_Smartform__c) == NSP_SalesConstants.No ?
                            					queueMap.get(NSP_SalesConstants.NSP_National_PTO).Id : relatedCase.OwnerId;  
                        updateCasesList.add(relatedCase);
                }
            }    
        }
        if(updateCasesList.size() > 0){
           // update updateCasesList; // as we are not using PTO object anymore commenting this line as this is causing isse with deployment.
        }
        if(chatterList.size() > 0){
            insert chatterList;
        }
        if(newCasesOnCloseList.size() > 0){
            insert newCasesOnCloseList;
        }
    }
    
    /**
    * Iterates throught the PTO Smartform  List and identifies the records that needs to worked based on various criterias.
    * @param newPTOSmartformsList List of New PTO Smartform. 
    * @return void             
    *                
    */
    
    public void beforeInsertMethod(List<NSP_PTO_Smartform__c> newPTOSmartformsList){
        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id, String> contactWithEmailMap = new Map<Id, String>();
        Map<Id, String> accounttWithTeamMemberMap = new Map<Id, String>();
        
        
        if(newPTOSmartformsList != null || newPTOSmartformsList.size() > 0){
            for(NSP_PTO_Smartform__c PTO : newPTOSmartformsList){
                if(PTO.NSP_Contact_Name__c != null){
                	contactIdSet.add(PTO.NSP_Contact_Name__c);    
                }
                if(PTO.NSP_Account__c != null){
                	accountIdSet.add(PTO.NSP_Account__c);    
            	}
            } 
        }
        
        if(contactIdSet.size() > 0){
            for(Contact con : [SELECT Id, NSP_Work_email__c FROM Contact WHERE Id IN: contactIdSet]){
                if(con.NSP_Work_email__c != null){
                	contactWithEmailMap.put(con.Id, con.NSP_Work_email__c);    
                }
            }
        }
        if(accountIdSet.size() > 0){
            for(NSP_Account_Team__c AccTeamMember : [SELECT Id, NSP_Role__c, NSP_Account__c, NSP_Email__c, 
                                                     NSP_User__c, NSP_User__r.Name
                                                     FROM NSP_Account_Team__c 
                                                     WHERE NSP_Account__c IN: accountIdSet AND
                                                     NSP_Role__c =: NSP_SalesConstants.HRSpecialist]){
                if(AccTeamMember.NSP_User__c != null){
                	accounttWithTeamMemberMap.put(AccTeamMember.NSP_Account__c, AccTeamMember.NSP_User__r.Name);    
                }
            }
        }
        
        if(!contactWithEmailMap.isEmpty() || !accounttWithTeamMemberMap.isEmpty()){
        	for(NSP_PTO_Smartform__c PTO : newPTOSmartformsList){
                if(!contactWithEmailMap.isEmpty()){
                    if(PTO.NSP_Contact_Name__c != null){
                        PTO.NSP_Contact_email_address__c = contactWithEmailMap.get(PTO.NSP_Contact_Name__c);  
                    }
                }
                if(!accounttWithTeamMemberMap.isEmpty()){
                    if(PTO.NSP_Account__c != null){
                        PTO.NSP_Account_HRS__c = accounttWithTeamMemberMap.get(PTO.NSP_Account__c);  
                    }
                }

            }
        }
    }
    
    /**
    * Iterates throught the PTO Smartform  List and identifies the records that needs to worked based on various criterias.
    * @param newPTOSmartformsList List of New PTO Smartform. 
    * @param PTOSmartformNewMap Map of New PTO Smartform. 
    * @return void             
    *                
    */
    
    public void afterInsertMethod(List<NSP_PTO_Smartform__c> newPTOSmartformsList, Map<Id, NSP_PTO_Smartform__c> PTOSmartformNewMap){
    	List<Case> newCasesList = new List<Case>();
        Map<String, Group> queueMap =  new Map<String, Group> ();
        
        Id AIMSrecordTypeId = Schema.SObjectType.NSP_PTO_Smartform__c.getRecordTypeInfosByDeveloperName().get(NSP_SalesConstants.AIMS).getRecordTypeId();
        Id ITArecordTypeId = Schema.SObjectType.NSP_PTO_Smartform__c.getRecordTypeInfosByDeveloperName().get(NSP_SalesConstants.ITA).getRecordTypeId();
        
        for(Group relatedGroup : [SELECT DeveloperName, Id, Name, Type 
                                  FROM Group 
                                  WHERE Type =: NSP_SalesConstants.Queue AND 
                                  (DeveloperName =: NSP_SalesConstants.NSP_AIMS_form OR 
                                   DeveloperName =: NSP_SalesConstants.NSP_ITA_form OR
                                   DeveloperName =: NSP_SalesConstants.NSP_National_PTO)]){
        	queueMap.put(relatedGroup.DeveloperName, relatedGroup);                              
        }  
        if(newPTOSmartformsList != null || newPTOSmartformsList.size() > 0){
            for(NSP_PTO_Smartform__c PTO : newPTOSmartformsList){
                if(PTO.NSP_Status__c == NSP_SalesConstants.Submitted){
                    Case newCase = new Case();
                    newCase.NSP_PTO_Smartform__c = PTO.Id;
                    newCase.NSP_Category__c = NSP_SalesConstants.HRInfrastructure;
                    newCase.NSP_SubCategory__c = NSP_SalesConstants.PTOPlanAnalysisDevelopmentandtracking;
                    newCase.Subject = NSP_SalesConstants.PTOSmartformSetup;
                    newCase.CreatedById = PTO.LastModifiedById;
                    if(PTO.RecordTypeId == AIMSrecordTypeId){
                        newCase.OwnerId = queueMap.get(NSP_SalesConstants.NSP_AIMS_form).Id;    
                    }
                    if(PTO.RecordTypeId == ITArecordTypeId){
                        newCase.OwnerId = queueMap.get(NSP_SalesConstants.NSP_ITA_form).Id;    
                    }
                    newCasesList.add(newCase);
                }
            }
        }
        if(newCasesList.size() > 0){
            insert newCasesList;
        }
    }
    
}