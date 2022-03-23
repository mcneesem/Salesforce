/**
Apex Class Name      :  NSP_OpportunityTriggerHelper for Opportunity Trigger
Version              :  1.0                                                                          
Created Date         :  12/24/2021   
Function             :  This class is used as a helper to Opportunity Trigger Handler. 
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Tejas                 07/02/2021            First Iteration
*/

public class NSP_OpportunityTriggerHelper {
    
    public static List<string> analysisStageCriteraTypes = System.Label.NSP_AnalysisStageCriteria.split(',');
    public static List<string> proposeStageCriteraTypes = System.Label.NSP_ProposeStageCriteria.split(',');
    public static final List<String> workforceProductsList = System.Label.NSP_Primary_Workforce_Products.split(',');
    public static final String RETIREMENT_SERVICES_FOR_NON_WO_PRODUCTS = System.Label.Retirement_Services_For_Non_WO_Products; 
    public static final String SELECT_PRIMARY_CONTACT = System.Label.NSP_Select_Primary_Contact;
    private static final string ASSET_RECORDTYPE = System.Label.NSP_Asset_Product;
    public static final Id ASSET_RECORDTYPE_ID = Schema.SObjectType.ASSET.getRecordTypeInfosByDeveloperName().get(ASSET_RECORDTYPE).getRecordTypeId();
    
/**
* Iterates throught the list of new Opportunity and passes the required attributes to other methods.
* @param newList List of New Opportunity.  
* @return void             
*                
*/
    public void beforeInsertDirector(List<Opportunity> newList){        
        
        Set<String> accountIdSet =  new Set<String>();
        List<Opportunity> opportunityWoWxList =  new List<Opportunity>();
        List<Opportunity> childopportunityList =  new List<Opportunity>();
        Set<Id> parentOpportunityIdSet = new Set<Id>();
        Set<String> docuSignTemplateName = new Set<String>();
        List<Opportunity> opptyListToStampDocusignTemplateId = new List<Opportunity>();
        //set to store opportunity owner Ids when opportunity owner is changed/or when opportunity is created
        Set<Id> ownerIdsSet = new Set<Id>();
        //Iterating over the opportunity new list 
        for(Opportunity opportunityObject : newList){
            ownerIdsSet.add(opportunityObject.OwnerId);
            
            // Checking if account id is not blank
            if(String.isNotBlank(opportunityObject.Accountid)){
                // Adding account to the set
                accountIdSet.add(opportunityObject.Accountid); 
                
                //Checking if the product type on opty is WO/WX and its a parent opportunity
                if(String.isnotBlank(opportunityObject.NSP_PrimaryProduct__c) &&
                   (opportunityObject.NSP_PrimaryProduct__c.equals(NSP_SalesConstants.WO) || opportunityObject.NSP_PrimaryProduct__c.equals(NSP_SalesConstants.WX))
                   && String.isBlank(opportunityObject.NSP_Parent_Opportunity__c)){                       
                       opportunityWoWxList.add(opportunityObject);
                   }
            }
            
            if(String.isNotBlank(opportunityObject.NSP_Parent_Opportunity__c)){
                childopportunityList.add(opportunityObject);
                parentOpportunityIdSet.add(opportunityObject.NSP_Parent_Opportunity__c);
            }
            
            //create list to populate docusign template id for merge on demand templates
            if(!String.isBlank(opportunityObject.NSP_Merge_On_Demand_Template_Selection__c)){
                opptyListToStampDocusignTemplateId.add(opportunityObject);
                docuSignTemplateName.add(opportunityObject.NSP_Merge_On_Demand_Template_Selection__c);
            }
            //If type is CAMS updating the stage to Analysis
            if (String.isNotBlank(opportunityObject.Type) && opportunityObject.Type.equals(NSP_SalesConstants.OPPORTUNITY_TYPE_CAMS)) {
                opportunityObject.StageName = NSP_SalesConstants.ANALYSIS_STAGE;
            }
        }      
        
        
		NSP_OpportunityTriggerHelperFunctions oppHelperFuncObj = new NSP_OpportunityTriggerHelperFunctions();
		//Setting direct assignments to opportunity records
		oppHelperFuncObj.setDirectOpptyFieldsAssignments(newList);
        
        if(!opportunityWoWxList.isEmpty()){
            //Calling method to stamp WO/WX emails on oprty record
            oppHelperFuncObj.stampWoWxEmailOnOpprtunity(opportunityWoWxList);
        }
        
        //Opportunity Validation of Stages
        NSP_ValidateOpportunityStage.validateOpportunityStage(newList);
        
        //copy fields from parent opportuity to child opportunity
        if(! childopportunityList.isEmpty()){
            NSP_ChildOpportunitiesHelperFunctions.defaultFieldsOnChildOpportunity(childopportunityList,parentOpportunityIdSet);
        }        
        
        NSP_OpportunityTriggerHelperFunctions.populateServiceEmail(newList,ownerIdsSet);
        
        //call method to populate template id
        if(opptyListToStampDocusignTemplateId.size() > 0){
            oppHelperFuncObj.setDocuSignTemplateId(opptyListToStampDocusignTemplateId,docuSignTemplateName);
            
        }
            
    }
    
/**
* Iterates throught the map of new Opportunity and passes the required attributes to other methods.
* @param newList List of New Opportunity.  
* @param opportunityNewMap Map of Opportunity id and Opportunity records.
* @return void             
*                
*/
    
    public void afterInsertDirector(List<Opportunity> newList,Map<Id, Opportunity> opportunityNewMap){ 
        
        Set<String> accountIdSet = new Set<String>();
        //publish opportunity event
        List<Integration_Opportunity_Event__e> opportunityEventList = New List<Integration_Opportunity_Event__e>();
        List<Opportunity> updateResyncFlagOpportunityList = new List<Opportunity>();
        //Opportunity list to capture opportunities created with HSA contribution data
        List<Opportunity> newTaskOpportunityList = new List<Opportunity>();
        
        for(Id opportunityId : opportunityNewMap.keySet()){
            accountIdSet.add(opportunityNewMap.get(opportunityId).accountid);
            if(opportunityNewMap.get(opportunityId).NSP_Ready_for_Integration_Sync__c){ 
                opportunityEventList.add(new Integration_Opportunity_Event__e(Id__c = opportunityId));
                updateResyncFlagOpportunityList.add(opportunityNewMap.get(opportunityId));
            }
            
            if(! String.isBlank(opportunityNewMap.get(opportunityId).NSP_Contribution_Level__c)
               && ! String.isBlank(opportunityNewMap.get(opportunityId).NSP_Frequency_of_Distribution__c)){
                   newTaskOpportunityList.add(opportunityNewMap.get(opportunityId));
               }
        }
        /* Moving to NSP_UpdateRelatedAccounts class as part of DF-01058 */
        NSP_UpdateRelatedAccounts.updateRelatedAccounts(accountIdSet);

        if(! newTaskOpportunityList.isEmpty()){
            NSP_EventAndTaskHelperFunctions.createTaskRecordsForNCSQueue(newTaskOpportunityList, null);
        }
        
        // Send the list to publish event bus
        Id profileId=userinfo.getProfileId();
        String profileName=[SELECT Id,Name from Profile WHERE Id=:profileId].Name;
        /* Adding OR Condition as part of DF-01043 so that publishEventBus method will not trigger for Integration user profile*/
        if(String.isNotBlank(profileName) && !profileName.containsIgnoreCase(System.label.NSP_Integration_User_Profile_Name)){
            publishEventBus(opportunityEventList, updateResyncFlagOpportunityList);       
        }
    }
    
/**
* Iterates throught the Opportunity map and identifies the records that needs to worked based on various criterias.
* @param opportunityNewMap Map of New Opportunity. 
* @param opportunityOldMap Map of Old Opportunity. 
* @return void             
*                
*/
    
    public void beforeUpdateDirector(Map<Id, Opportunity> opportunityNewMap,Map<Id, Opportunity> opportunityOldMap){
        //Creating collection of account and opportunity
        Set<String> accountIdSet =  new Set<String>();
        Set<String> MODaccountIdSet =  new Set<String>();
        Set<Id> ownerIdSet = new Set<Id>();
        Set<Id> MODownerIdSet = new Set<Id>();
        List<Opportunity> opportunityWoWxList =  new List<Opportunity>();
        List<Opportunity> opportunityNewAccountList = new List<Opportunity>();
        //list to store opportunities where Opportunity owner is changed
        List<Opportunity> ownerChangedOpptyList = new List<Opportunity>();
        List<Opportunity> stageChangedOpportunityList = new List<Opportunity>();
        List<Opportunity> opportunitiesToClosingStageList = new List<Opportunity>();
        List<Opportunity> lockOpportunitiesList = new List<Opportunity>();
        List<Opportunity> optyList = new List<Opportunity>();
        ID quoteId = null;
        
        List<Opportunity> updatePriceBookList = new List<Opportunity>();
        List<String> primaryProductChanged = new List<String>();
        
        //docusign merge template
        Set<String> docuSignTemplateName = new Set<String>();
        List<Opportunity> opptyListToStampDocusignTemplateId = new List<Opportunity>();
        
        //Iterating over the new opportunity map
        for(Id opportunityId : opportunityNewMap.keySet()){
            
            Opportunity newOpportunity =  opportunityNewMap.get(opportunityId);
            Opportunity oldOpportunity =  opportunityOldMap.get(opportunityId);
            
            if(newOpportunity.OwnerId != oldOpportunity.OwnerId){
                ownerChangedOpptyList.add(newOpportunity);
                ownerIdSet.add(newOpportunity.OwnerId);
            }

            //Checking if the account id updated on the record
            if(opportunityNewMap.get(opportunityId).Accountid != opportunityOldMap.get(opportunityId).Accountid){
                accountIdSet.add(opportunityNewMap.get(opportunityId).Accountid);
                opportunityNewAccountList.add(opportunityNewMap.get(opportunityId));
            }
            //Checking if the primary quote id updated on the record
            if(opportunityNewMap.get(opportunityId).SBQQ__PrimaryQuote__c != null){
                if(opportunityNewMap.get(opportunityId).SBQQ__PrimaryQuote__c != opportunityOldMap.get(opportunityId).SBQQ__PrimaryQuote__c){
                    quoteId = opportunityNewMap.get(opportunityId).SBQQ__PrimaryQuote__c;
                    optyList.add(opportunityNewMap.get(opportunityId));
                }
            }
            if(opportunityNewMap.get(opportunityId).StageName != opportunityOldMap.get(opportunityId).StageName){
                stageChangedOpportunityList.add(opportunityNewMap.get(opportunityId));  
            }  
            
            if(opportunityNewMap.get(opportunityId).NSP_Signed_Delivery_Order__c && opportunityNewMap.get(opportunityId).NSP_Signed_Delivery_Order__c != opportunityOldMap.get(opportunityId).NSP_Signed_Delivery_Order__c){
                opportunityNewMap.get(opportunityId).NSP_Signed_Delivery_Order_Date__c = system.today();
            }
            
            if(opportunityNewMap.get(opportunityId).StageName.equals(NSP_SalesConstants.PROPOSAL_STAGE) 
               && (opportunityNewMap.get(opportunityId).NSP_Closing_Appointment__c != opportunityOldMap.get(opportunityId).NSP_Closing_Appointment__c
                   || opportunityNewMap.get(opportunityId).NSP_Order_Generated__c != opportunityOldMap.get(opportunityId).NSP_Order_Generated__c
                   || opportunityNewMap.get(opportunityId).NSP_Docusign_Sent_Date__c != opportunityOldMap.get(opportunityId).NSP_Docusign_Sent_Date__c
                   || opportunityNewMap.get(opportunityId).NSP_PrimaryProduct__c != opportunityOldMap.get(opportunityId).NSP_PrimaryProduct__c
                   || opportunityNewMap.get(opportunityId).NSP_Signed_Delivery_Order__c != opportunityOldMap.get(opportunityId).NSP_Signed_Delivery_Order__c
                   || opportunityNewMap.get(opportunityId).NSP_Signed_CSA__c != opportunityOldMap.get(opportunityId).NSP_Signed_CSA__c)){
                       opportunitiesToClosingStageList.add(opportunityNewMap.get(opportunityId));
                       
                   }
            
            if(opportunityNewMap.get(opportunityId).StageName != opportunityOldMap.get(opportunityId).StageName
               && (opportunityNewMap.get(opportunityId).StageName.equals(NSP_SalesConstants.CLOSED_WON) 
                   ||opportunityNewMap.get(opportunityId).StageName.equals(NSP_SalesConstants.CLOSED_LOST)) ){
                       lockOpportunitiesList.add(opportunityNewMap.get(opportunityId));
                   }
            
            
            //Checking if the product type is changed on the record and is WO/WX
            //and the opty record is a parent opportunity
            if(String.isnotBlank(opportunityNewMap.get(opportunityId).NSP_PrimaryProduct__c) &&
               (opportunityNewMap.get(opportunityId).NSP_PrimaryProduct__c.equals(NSP_SalesConstants.WO) || opportunityNewMap.get(opportunityId).NSP_PrimaryProduct__c.equals(NSP_SalesConstants.WX))
               && (opportunityNewMap.get(opportunityId).NSP_PrimaryProduct__c != opportunityOldMap.get(opportunityId).NSP_PrimaryProduct__c)
               && String.isBlank(opportunityNewMap.get(opportunityId).NSP_Parent_Opportunity__c)){
                   
                   opportunityWoWxList.add(opportunityNewMap.get(opportunityId));
               }
            
            if(String.isNotBlank(opportunityNewMap.get(opportunityId).NSP_PrimaryProduct__c) && 
               (opportunityNewMap.get(opportunityId).NSP_PrimaryProduct__c != opportunityOldMap.get(opportunityId).NSP_PrimaryProduct__c)){
                   updatePriceBookList.add(opportunityNewMap.get(opportunityId));
               }
            
            
            
           
            
            //create list to populate docusign template id for merge on demand templates
            if(!String.isBlank(newOpportunity.NSP_Merge_On_Demand_Template_Selection__c) && 
               newOpportunity.NSP_Merge_On_Demand_Template_Selection__c != oldOpportunity.NSP_Merge_On_Demand_Template_Selection__c){
                   opptyListToStampDocusignTemplateId.add(newOpportunity);
                   docuSignTemplateName.add(newOpportunity.NSP_Merge_On_Demand_Template_Selection__c);
                   MODaccountIdSet.add(newOpportunity.Accountid);
                   MODownerIdSet.add(newOpportunity.OwnerId);
                   
               }
        }
        
		NSP_OpportunityTriggerHelperFunctions oppHelperFuncObj = new NSP_OpportunityTriggerHelperFunctions();
		oppHelperFuncObj.setDirectOpptyFieldsAssignments(opportunityNewMap.values());
		
        // Account list is empty or not
        oppHelperFuncObj.getAccountOwnerEmail(opportunityNewAccountList,accountIdSet);
        NSP_UserAndOwnerFunctions uofobj = new NSP_UserAndOwnerFunctions();
        if(!optyList.isEmpty()){
            uofobj.getQuoteOwner(optyList,quoteId);  
        }
        // opportunity list is empty or not
        oppHelperFuncObj.stampWoWxEmailOnOpprtunity(opportunityWoWxList);
        
        //Validate opportunity stage progression
        NSP_ValidateOpportunityStage.validateOpportunityStage(stageChangedOpportunityList); 
        
        moveOpportunityToClosingStage(opportunitiesToClosingStageList);            
        changeOpportunityRecordType(lockOpportunitiesList);
        NSP_ChildOpportunitiesHelperFunctions childOpptyHlprObj = new NSP_ChildOpportunitiesHelperFunctions();
        childOpptyHlprObj.updateChildOpportunityOnProductChange(primaryProductChanged);
        
        //call updateTriggerclass for metadata check ad update integration sync field on account
        Set<Id> opportunityIdSetToUpdateResyncFLag = new Set<Id>();
        NSP_SObjectUpdateTriggerHelper sObjectUpdateObj = new NSP_SObjectUpdateTriggerHelper();
        opportunityIdSetToUpdateResyncFLag.addAll(sObjectUpdateObj.fetchUpdFieldsLst('Opportunity', (Map<Id, sObject>) opportunityNewMap, (Map<Id, sObject>) opportunityOldMap));
        
        if(opportunityIdSetToUpdateResyncFLag.size() > 0){
            for(Id opptyId : opportunityIdSetToUpdateResyncFLag){
                opportunityNewMap.get(opptyId).NSP_Ready_for_Integration_Sync__c = true;
            }
        }
        
        if(ownerChangedOpptyList.size()>0){
            NSP_OpportunityTriggerHelperFunctions.populateServiceEmail(ownerChangedOpptyList, ownerIdSet);
        }
        
        //call method to populate template id
        if(opptyListToStampDocusignTemplateId.size() > 0){
            oppHelperFuncObj.setDocuSignTemplateId(opptyListToStampDocusignTemplateId,docuSignTemplateName);
            uofobj.setDummyUsers(opptyListToStampDocusignTemplateId,MODaccountIdSet,MODownerIdSet);
            
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
        List<String> closedOpportunityIdList = new List<String>();
        Set<String> accountIdSet = new Set<String>();
        List<Opportunity> closedWonOpptyList = new List<Opportunity>();
        List<Integration_Opportunity_Event__e> opportunityEventList = New List<Integration_Opportunity_Event__e>();
        List<Opportunity> updateResyncFlagOpportunityList = new List<Opportunity>();
        
        //opportunity list to store oppty records where Primary Quote is newly created
        List<Opportunity> opportunitiesWithPrimaryQuote = new List<Opportunity>();
        
        //Opportunity list to capture opportunities created with HSA contribution data
        List<Opportunity> newTaskOpportunityList = new List<Opportunity>();
        
        //opportunities with Partner Accounts populated
        List<Opportunity> partnerOpportunityList = new List<Opportunity>();
        Set<Id> partnerAccountIdSet = new Set<Id>();
        
        //I terating over the opportunity new map
        for(Id opportunityId : opportunityNewMap.keySet()){
            
            Opportunity newOpportunity = opportunityNewMap.get(opportunityId);
            Opportunity oldOpportunity = opportunityOldMap.get(opportunityId);
            
            if((newOpportunity.NSP_Signed_Delivery_Order__c
                && newOpportunity.NSP_Signed_Delivery_Order__c != oldOpportunity.NSP_Signed_Delivery_Order__c)|| (newOpportunity.NSP_MOD_Document_Signed__c
                                                                                                                  && newOpportunity.NSP_MOD_Document_Signed__c != oldOpportunity.NSP_MOD_Document_Signed__c)){
                                                                                                                      partnerOpportunityList.add(newOpportunity);
                                                                                                                      partnerAccountIdSet.add(newOpportunity.AccountId);
                                                                                                                  }
            
            //check if Primary Quote is created for Opportunity record
            if(String.isNotBlank(opportunityNewMap.get(opportunityId).SBQQ__PrimaryQuote__c)
               && String.isBlank(opportunityOldMap.get(opportunityId).SBQQ__PrimaryQuote__c)){
                   opportunitiesWithPrimaryQuote.add(opportunityNewMap.get(opportunityId));
               }
            
            // if the parent opty is closed lost then adding it to the list
            if((String.isBlank(opportunityNewMap.get(opportunityId).NSP_Parent_Opportunity__c) || opportunityNewMap.get(opportunityId).NSP_Parent_Opportunity__c == null)
               && opportunityNewMap.get(opportunityId).stagename.equals(NSP_SalesConstants.CLOSED_LOST) ){   
                   closedOpportunityIdList.add(opportunityId);
               }
            //STY-01519 - Asset creation from Opportunity line item
            if(opportunityNewMap.get(opportunityId).stagename != opportunityOldMap.get(opportunityId).stagename
               && opportunityNewMap.get(opportunityId).stagename.equals(NSP_SalesConstants.CLOSED_WON)){
               // Added as part of DF-01325 
                NSP_EmailWithAttachment.sendClosedWonEmailNotifications(opportunityId,newOpportunity);
                   closedWonOpptyList.add(opportunityNewMap.get(opportunityId));
               }
            accountIdSet.add(opportunityNewMap.get(opportunityId).accountid);
            if(opportunityNewMap.get(opportunityId).NSP_PrimaryProduct__c == NSP_SalesConstants.WO 
               && (String.isNotBlank(opportunityNewMap.get(opportunityId).NSP_Contribution_Level__c) 
                   && String.isNotBlank(opportunityNewMap.get(opportunityId).NSP_Frequency_of_Distribution__c))
               &&(String.isBlank(opportunityOldMap.get(opportunityId).NSP_Contribution_Level__c)
                  ||String.isBlank(opportunityOldMap.get(opportunityId).NSP_Frequency_of_Distribution__c))){
                      newTaskOpportunityList.add(opportunityNewMap.get(opportunityId));
                  }
            
            //publish opportunity event
            if(opportunityNewMap.get(opportunityId).NSP_Ready_for_Integration_Sync__c) {
                opportunityEventList.add(New Integration_Opportunity_Event__e(Id__c = opportunityId));
                updateResyncFlagOpportunityList.add(opportunityNewMap.get(opportunityId));
            }
        }
        
        //for tracking history
        if(!Test.isRunningTest()){
        if(opportunityNewMap.size() > 0){
            NSP_SObjectHistoryTrackingHelper objectFieldHistoryHelper = new NSP_SObjectHistoryTrackingHelper((Map<Id, sObject>)opportunityNewMap, (Map<Id, sObject>)opportunityOldMap);
            If( Limits.getQueueableJobs() != Limits.getLimitQueueableJobs()) {
                System.enqueueJob(objectFieldHistoryHelper);  
            }
        }
        }
        
        // Send the list to publish event bus
        if(updateResyncFlagOpportunityList.size() > 0){
            /* Adding If Condition as part of DF-01043 so that publishEventBus method will not trigger for Integration user profile*/
            Id profileId = userinfo.getProfileId();
            String profileName = [SELECT Id,Name from Profile WHERE Id=:profileId].Name;
            if(String.isNotBlank(profileName) && !profileName.containsIgnoreCase(System.label.NSP_Integration_User_Profile_Name)){
                publishEventBus(opportunityEventList, updateResyncFlagOpportunityList);
            }
        }
        //List is empty or not
        if(!closedOpportunityIdList.isEmpty()){
            NSP_ChildOpportunitiesHelperFunctions childHlprObj = new NSP_ChildOpportunitiesHelperFunctions();
			childHlprObj.updatesOnChildOpportunity(closedOpportunityIdList);
        }
        //Calling Quote to Order method for generating order from Opportunity via a Quote update @utpal Utkalit
        NSP_GenerateOrderFromOpportunity.updateQuotetoOrderWhenOppWON(Trigger.new,opportunityOldMap);
        /* Moving to NSP_UpdateRelatedAccounts class as part of DF-01058 */
        NSP_UpdateRelatedAccounts.updateRelatedAccounts(accountIdSet); 
        
        
        
        //STY-01519 - Asset creation from Opportunity line item
        if(closedWonOpptyList.size() > 0){
            createAssetForCloseWonOpportunity(closedWonOpptyList);
            NSP_EmailServicesUtility.sendEmailsTOService(closedWonOpptyList, opportunityNewMap, workforceProductsList);
        }
        
        if(newTaskOpportunityList.size() > 0){
            NSP_EventAndTaskHelperFunctions.createTaskRecordsForNCSQueue(newTaskOpportunityList, null);
        }
        
        NSP_EventAndTaskHelperFunctions.createTaskForPrimaryQuote(opportunitiesWithPrimaryQuote);
        setPartnerAccount(partnerOpportunityList,partnerAccountIdSet);
        
    }       
    
    

     
    
/**
* When Opportunity in Proposal Stage meets all criterias then update the stage to Closing
* @param opportunityList list of New Opportunity.  
* @return void             
*                
*/     
    public void moveOpportunityToClosingStage(List<Opportunity> opportunityList){
        for(Opportunity opportunityRecord : opportunityList){
            
            if(opportunityRecord.NSP_Docusign_Sent_Date__c != null && opportunityRecord.NSP_Closing_Appointment__c != null
               && (((opportunityRecord.NSP_PrimaryProduct__c==NSP_SalesConstants.WO || opportunityRecord.NSP_PrimaryProduct__c==NSP_SalesConstants.WS) && opportunityRecord.NSP_Signed_CSA__c) 
                   || (opportunityRecord.NSP_PrimaryProduct__c == NSP_SalesConstants.WX && opportunityRecord.NSP_Signed_Delivery_Order__c) 
                   || (opportunityRecord.NSP_PrimaryProduct__c!=NSP_SalesConstants.WO && opportunityRecord.NSP_PrimaryProduct__c!=NSP_SalesConstants.WS && opportunityRecord.NSP_PrimaryProduct__c!=NSP_SalesConstants.WX))){
                       opportunityRecord.StageName = NSP_SalesConstants.CLOSING_STAGE;
                   }
            
        }
    }
    
    
    /**
* When Opportunity in closed won/lost change the record type to lock the page layout
* @param opportunityList list of New Opportunity.  
* @return void             
*                
*/  
    public void changeOpportunityRecordType(List<Opportunity> opportunityList){
        Id opportunityRecordType = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(NSP_SalesConstants.LOCKED_OPPORTUNITY).getRecordTypeId();
        for(Opportunity opportunityRecord : opportunityList){
            opportunityRecord.RecordTypeId = opportunityRecordType;
        }
    }
    

    
/**
* prevent the users when existing Business opportunity with Interest in Retirement
* services for accounts who does not own WO products is created. 
* @param opportunityList list of New Opportunity.  
* @return void
*/ 
    public void retirementServicesForNonWOProducts(List<Opportunity> opportunityList){
        Map<Id, List<Asset>> accountIdAssetListMap = new Map<Id, List<Asset>>();
        Set<Id> accountIdsSet = new Set<Id>();
        
        for(Opportunity opportunityRecord : opportunityList){
            accountIdsSet.add(opportunityRecord.AccountId);
        }
        
        List<Asset> assetWithWOProductsList = [SELECT Id, AccountId,Name, Product2.NSP_Product_Type__c FROM Asset WHERE AccountId IN :accountIdsSet AND Product2.NSP_Product_Type__c = 'WOSS Bundle'];
        
        //create a map of AccountId and List of Assets for each account
        for(Asset assetRecord : assetWithWOProductsList){
            if(accountIdAssetListMap.containsKey(assetRecord.AccountId)){
                accountIdAssetListMap.get(assetRecord.AccountId).add(assetRecord);
            } else {
                accountIdAssetListMap.put(assetRecord.AccountId, new List<Asset> {assetRecord});
            }
        }
        
        for(Opportunity opportunityRecord : opportunityList){
            if(accountIdAssetListMap.containsKey(opportunityRecord.AccountId)) {
                if( accountIdAssetListMap.get(opportunityRecord.AccountId).size() == 0){
                    opportunityRecord.addError(RETIREMENT_SERVICES_FOR_NON_WO_PRODUCTS);
                }
            }else{
                opportunityRecord.addError(RETIREMENT_SERVICES_FOR_NON_WO_PRODUCTS);
            }
        }
    }
    
    
    /**
* Setting Opportunity Type to Renewal for Renewal Oportunities
* copy value from original opportunity to renewal /Amendment opportunity 
* Stage = Proposal : Number of Employees = Populated from original opportunity.
* @param opportunityList list of New Opportunity.  
* @return void
*/ 
    
    public void setTypeforRenewalOpportunity(List<Opportunity> opportunityList){
        
        set<Id> contractIdSet = new set<Id> ();
        
        for(Opportunity op : opportunityList){
            
            if(op.SBQQ__AmendedContract__c != null){
                if(op.NSP_TransactionType__c == NSP_SalesConstants.TRANSACTION_TYPE_TERMINATION){
                    op.Type = NSP_SalesConstants.TRANSACTION_TYPE_TERMINATION;
                    op.StageName = NSP_SalesConstants.PROPOSAL_STAGE;
                    contractIdSet.add(op.SBQQ__AmendedContract__c);
                }else{
                    op.Type = NSP_SalesConstants.OPPORTUNITY_TYPE_EXISTING_PRODUCT;
                    op.CloseDate = DATE.TODAY()+30;
                    contractIdSet.add(op.SBQQ__AmendedContract__c);
                }
            }
            
            if(op.SBQQ__RenewedContract__c != null) {
                op.Type = NSP_SalesConstants.OPPORTUNITY_TYPE_RENEWAL;
                contractIdSet.add(op.SBQQ__RenewedContract__c);
            }
        }
        
        if(contractIdSet.Size() > 0){
            Map<Id,Contract> comtractMap = new Map<Id,Contract>([SELECT Id,SBQQ__Opportunity__c,
                                                                 SBQQ__Opportunity__r.NSP_PrimaryProduct__c,
                                                                 SBQQ__Opportunity__r.NSP_Client_For_Life__c,
                                                                 SBQQ__Opportunity__r.NSP_Partner__c
                                                                 FROM Contract WHERE Id IN : contractIdSet AND SBQQ__Opportunity__c != null  ]);
            if(comtractMap.Size() > 0){
                for(Opportunity newOpportunty : opportunityList){
                    Id contractIdstr = newOpportunty.SBQQ__RenewedContract__c != null ? newOpportunty.SBQQ__RenewedContract__c :newOpportunty.SBQQ__AmendedContract__c != null ? newOpportunty.SBQQ__AmendedContract__c : null; 
                    if(contractIdstr != null && comtractMap.containskey(contractIdstr)){
                        Contract objContract = comtractMap.get(contractIdstr);
                        newOpportunty.NSP_PrimaryProduct__c = objContract.SBQQ__Opportunity__r.NSP_PrimaryProduct__c;
                        newOpportunty.NSP_Client_For_Life__c = objContract.SBQQ__Opportunity__r.NSP_Client_For_Life__c;
                        newOpportunty.NSP_Partner__c = objContract.SBQQ__Opportunity__r.NSP_Partner__c;
                        
                    }
                }
            }           
        }
        
    }
    
    
    /**
* Iterates throught the event list publish the records in event bus.
* @param eventList of New Account.
* @param objectList of New Account.
* @return void             
* 
*/
    public void publishEventBus(List<Integration_Opportunity_Event__e> eventList, List<Opportunity> objectList) {
        List<Opportunity> updateResyncFlagOpportunityList = new List<Opportunity>();
        if(!eventList.isEmpty()) {
            // Publishing records Event 
            List<Database.SaveResult> results = EventBus.publish(eventList);
            
            // Inspect publishing result for each event
            List<NSP_Error_Log__c> logList = new List<NSP_Error_Log__c>();
            for (Database.SaveResult sr : results) {
                NSP_Error_Log__c log = new NSP_Error_Log__c();
                log.NSP_Class__c = 'NSP_OpportunityTriggerHelper';
                log.NSP_Method__c = 'publishEventBus';                
                log.NSP_Description__c = String.valueOf(sr.getErrors()[0].getMessage()) + '  '+String.valueOf(sr.getErrors()[0].getStatusCode());
                log.NSP_Record_Id__c = sr.getId();
                logList.add(log);  
            }
            
            if(logList.size() > 0){
                insert logList;
            }
            for(Opportunity  oppObj : objectList) {
                Opportunity tempOppObj = new Opportunity();
                tempOppObj.Id = oppObj.Id;
                tempOppObj.NSP_Ready_for_Integration_Sync__c = FALSE;
                updateResyncFlagOpportunityList.add(tempOppObj);
            }
            
            if(updateResyncFlagOpportunityList.size() > 0){
                update updateResyncFlagOpportunityList; 
            }
        }
    }
    
    /**
* Iterates tthrough closed won oportunity and looks for product where asset should be created
* @param closedWonOpptyList of closed won Opportunity.
* @return void             
* 
*/
    public void createAssetForCloseWonOpportunity(List<Opportunity> closedWonOpptyList){
        Set<Id> productIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        List<OpportunityLineItem> opptyLineItemList = [SELECT Name,Opportunity.accountId,NSP_Product_Name__c,NSP_AccountId__c,
                                                       Product2Id,Quantity,UnitPrice,NSP_Opportunity_Booked_Date__c,NSP_Signed_Delivery_Order_Date__c,
                                                       NSP_ProductType__c,NSP_ProductBundle__c,//if its required on Asset then we create a formula for it
                                                       NSP_Original_Sold_EE_Count__c,NSP_Primary_Product__c FROM OpportunityLineItem WHERE
                                                       Product2.NSP_Convert_to_Asset__c = TRUE AND
                                                       Opportunity.NSP_PrimaryProduct__c IN ('WX','WA') AND
                                                       OpportunityId IN: closedWonOpptyList];
        
        for(OpportunityLineItem oppItem : opptyLineItemList){
            productIds.add(oppItem.Product2Id);
            accountIds.add(oppItem.Opportunity.accountId);        
        }
        List<Asset> upsertList=new List<Asset>();
        New NSP_SrcToTargetObjectDataMover(null,'OppAsset')	;//initialize the class
        List<Asset> assetfromCopier= NSP_SrcToTargetObjectDataMover.getSourceDatainTarget( opptyLineItemList);	    
        List<Asset> existingAssets = [SELECT Id, Name,AccountId, Product2Id FROM Asset WHERE   AccountId in :accountIds AND RecordTypeId =:ASSET_RECORDTYPE_ID];
        Boolean isAssetFound=FALSE;
        for(Asset draftAsset:assetfromCopier){
            for(Asset existingAsset: existingAssets ){	
                if(draftAsset.AccountId == existingAsset.AccountId  ){
                    isAssetFound=TRUE;
                    Break;
                }
            }
            draftAsset.RecordTypeId = ASSET_RECORDTYPE_ID;
            if(!isAssetFound){
                upsertList.add(draftAsset); 
            }
            isAssetFound=FALSE;
            
            
        }
        upsert upsertList;
        
    }

      
    
/*
* Description: accepts a list of Opportunities with Partener accounts and
* sets the Partenr Lifecycle field on Account to Active
* @param : List<Opportunity>, Set<Id> AccountIdSet
* -------------------------------------------------------------------------------------
* author           | Date              | Description
* -------------------------------------------------------------------------------------
* Tejas          11-02-2021          created this new method
* 
* 
*/    
    public static void setPartnerAccount(List<Opportunity> opportunityList, Set<Id> accountsIdSet){
        List<Account> accountList = new List<Account>();
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, NSP_Partner_Lifecycle__c FROM Account WHERE Id IN :accountsIdSet]);
        
        for(Opportunity opportunityRecord : opportunityList){
            if(accountMap.get(opportunityRecord.AccountId).NSP_Partner_Lifecycle__c != NSP_SalesConstants.ACTIVE){
                accountMap.get(opportunityRecord.AccountId).NSP_Partner_Lifecycle__c = NSP_SalesConstants.ACTIVE;
                accountList.add(accountMap.get(opportunityRecord.AccountId));
            }
        }
        
        if(accountList.size() > 0)  {
            update accountList;          
    }    
  
    }
    

}