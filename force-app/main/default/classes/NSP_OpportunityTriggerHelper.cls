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
* Rahul Singh           26/10/2022            Create OCR
* Rahul Singh           11/17/2022            User STory 128436
* Rahul Singh           22/12/2022            User STory 194265
* Rahul Singh           02/02/2023            user story - 192368
*/

public class NSP_OpportunityTriggerHelper {
    
    public static List<string> analysisStageCriteraTypes = System.Label.NSP_AnalysisStageCriteria.split(',');
    public static List<string> proposeStageCriteraTypes = System.Label.NSP_ProposeStageCriteria.split(',');
    public static final List<String> workforceProductsList = System.Label.NSP_Primary_Workforce_Products.split(',');
    public static final String RETIREMENT_SERVICES_FOR_NON_WO_PRODUCTS = System.Label.Retirement_Services_For_Non_WO_Products; 
    public static final String SELECT_PRIMARY_CONTACT = System.Label.NSP_Select_Primary_Contact;
    private static final string ASSET_RECORDTYPE = System.Label.NSP_Asset_Product;
    public static final Id ASSET_RECORDTYPE_ID = Schema.SObjectType.ASSET.getRecordTypeInfosByDeveloperName().get(ASSET_RECORDTYPE).getRecordTypeId();
    public static boolean valueAssignedFromUser = false;
    public static boolean createRewardsOnce = false;
    
    private static set<Id>  byPassValidationOnRole = null;
    
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
        
        //set to store opportunity owner Ids when opportunity owner is changed/or when opportunity is created
        Set<Id> ownerIdsSet = new Set<Id>();
        //118442- Opp list which is Closed on insert
        List<Opportunity> closedStageList =  new List<Opportunity>();
        List<Opportunity> closedOppList =  new List<Opportunity>();
        //Iterating over the opportunity new list 
        for(Opportunity opportunityObject : newList){
            ownerIdsSet.add(opportunityObject.OwnerId);
            
            // Checking if account id is not blank
            if(String.isNotBlank(opportunityObject.Accountid)){
                // Adding account to the set
                accountIdSet.add(opportunityObject.Accountid); 
                
                //Checking if the product type on opty is WO/WX and its a parent opportunity
                // Added as part of DF-01869 handled primary product for WO/WS or WA/WX
                if(String.isnotBlank(opportunityObject.NSP_PrimaryProduct__c) &&
                (opportunityObject.NSP_PrimaryProduct__c.equals(NSP_SalesConstants.WO) ||
                 opportunityObject.NSP_PrimaryProduct__c.equals(NSP_SalesConstants.WS) ||
                 opportunityObject.NSP_PrimaryProduct__c.equals(NSP_SalesConstants.WA) ||
                 opportunityObject.NSP_PrimaryProduct__c.equals(NSP_SalesConstants.WX))
                && String.isBlank(opportunityObject.NSP_Parent_Opportunity__c)){                       
                       opportunityWoWxList.add(opportunityObject);
                   }
            }
            
            if(String.isNotBlank(opportunityObject.NSP_Parent_Opportunity__c)){
                childopportunityList.add(opportunityObject);
                parentOpportunityIdSet.add(opportunityObject.NSP_Parent_Opportunity__c);
            }
            
            //If type is CAMS updating the stage to Analysis
            if (String.isNotBlank(opportunityObject.Type) && opportunityObject.Type.equals(NSP_SalesConstants.OPPORTUNITY_TYPE_CAMS)) {
                opportunityObject.StageName = NSP_SalesConstants.ANALYSIS_STAGE;
            }
            
            //118442- If type is Client Growth Credit and stage is Closed Won updating the recordtype to Locked
            if (String.isNotBlank(opportunityObject.Type) && opportunityObject.Type.equals(NSP_SalesConstants.CLIENT_GROWTH_CREDIT)
                && opportunityObject.StageName.equals(NSP_SalesConstants.CLOSED_WON_STAGE))
                {
                closedStageList.add(opportunityObject);
                changeOpportunityRecordType(closedStageList);
            }

              // checking for closeddate is lessthan today or Not
            if(opportunityObject.CloseDate != null && opportunityObject.CloseDate < date.today()){
            closedOppList.add(opportunityObject);
            }
        }      
        
               // Added as part of DF-01716
               User userDetails =[ SELECT Id, Name, UserRole.Name, Profile.Name FROM User WHERE Id =: userinfo.getUserId() ];
               List<String> profilesToByPass = Label.NSP_Profile_To_Skip_OLI_Validation.split(',');
               if(!closedOppList.isEmpty() && !profilesToByPass.contains(userDetails.Profile.Name)){
        validateClosedDate(closedOppList);
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
        setSalesOfficeDetails(newList,null); // added for STY-03154
        
            
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
        Set<Id> OpportunityAccountId= new Set<Id>(); 
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
            // Added as a part of DF-01497   
            if(opportunityNewMap.get(opportunityId).NSP_Primary_Contact__c==Null || 
               opportunityNewMap.get(opportunityId).NSP_Customer_Signer__c==Null){
                OpportunityAccountId.add(opportunityNewMap.get(opportunityId).accountId);
            }
        }
        /* Moving to NSP_UpdateRelatedAccounts class as part of DF-01058 */
        NSP_UpdateRelatedAccounts.updateRelatedAccounts(accountIdSet);

        if(! newTaskOpportunityList.isEmpty()){
            NSP_EventAndTaskHelperFunctions.createTaskRecordsForNCSQueue(newTaskOpportunityList, null);
        }
        // added as a part of DF-01497
        getRelatedACR(OpportunityAccountId,opportunityNewMap.keySet());
        createContactRole(newList,opportunityNewMap);
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
        List<Opportunity> closedOppList =  new List<Opportunity>();
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
                   || opportunityNewMap.get(opportunityId).NSP_PrimaryProduct__c != opportunityOldMap.get(opportunityId).NSP_PrimaryProduct__c
                   || opportunityNewMap.get(opportunityId).NSP_Signed_Delivery_Order__c != opportunityOldMap.get(opportunityId).NSP_Signed_Delivery_Order__c)){
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
                   MODaccountIdSet.add(newOpportunity.Accountid);
                   MODownerIdSet.add(newOpportunity.OwnerId);
                   
               }

                           // checking for closeddate is lessthan today or Not
            if(newOpportunity.CloseDate != null && newOpportunity.CloseDate < date.today() &&  
               newOpportunity.NSP_Insperity_Signer__c == oldOpportunity.NSP_Insperity_Signer__c){
                closedOppList.add(newOpportunity);
            }
        }

                 // Added as part of DF-01716
                 User userDetails =[ SELECT Id, Name, UserRole.Name, Profile.Name FROM User WHERE Id =: userinfo.getUserId() ];
                 List<String> profilesToByPass = Label.NSP_Profile_To_Skip_OLI_Validation.split(',');
                 // Added as part of 195079
                 List<String> userRolesToByPass = Label.NSP_Bypass_Roles_from_Validation.split(',');

                 if(!closedOppList.isEmpty() && !profilesToByPass.contains(userDetails.Profile.Name) && !userRolesToByPass.contains(userDetails.UserRole.Name)){
                    validateClosedDate(closedOppList);
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
            uofobj.setDummyUsers(opptyListToStampDocusignTemplateId,MODaccountIdSet,MODownerIdSet);
        }
        
        setSalesOfficeDetails(opportunityNewMap.values(),opportunityOldMap); // added for STY-03154
        
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
        List<String> closedWonOpportunityIdList = new List<String>();
        Set<String> accountIdSet = new Set<String>();
        List<Opportunity> closedWonOpptyList = new List<Opportunity>();
        List<Integration_Opportunity_Event__e> opportunityEventList = New List<Integration_Opportunity_Event__e>();
        List<Opportunity> updateResyncFlagOpportunityList = new List<Opportunity>();
        
        //opportunity list to store oppty records where Primary Quote is newly created
        //List<Opportunity> opportunitiesWithPrimaryQuote = new List<Opportunity>();// commeted as part of user story 128436
        
        //Opportunity list to capture opportunities created with HSA contribution data
        List<Opportunity> newTaskOpportunityList = new List<Opportunity>();
        
        //opportunities with Partner Accounts populated
        List<Opportunity> partnerOpportunityList = new List<Opportunity>();
        Set<Id> partnerAccountIdSet = new Set<Id>();
        //Sending list to update enrollment fee payment
        enrollmentFeeCheck(opportunityNewMap,opportunityOldMap);
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
            
            //check if Primary Quote is created for Opportunity record// commented as part of user story 128436
            //if(String.isNotBlank(opportunityNewMap.get(opportunityId).SBQQ__PrimaryQuote__c)
            //   && String.isBlank(opportunityOldMap.get(opportunityId).SBQQ__PrimaryQuote__c)){
            //       opportunitiesWithPrimaryQuote.add(opportunityNewMap.get(opportunityId));
             //  }
            
            // if the parent opty is closed lost then adding it to the list
            if((String.isBlank(opportunityNewMap.get(opportunityId).NSP_Parent_Opportunity__c) || opportunityNewMap.get(opportunityId).NSP_Parent_Opportunity__c == null)
               && opportunityNewMap.get(opportunityId).stagename.equals(NSP_SalesConstants.CLOSED_LOST) ){   
                   closedOpportunityIdList.add(opportunityId);
               }
            //STY-01519 - Asset creation from Opportunity line item
            if(opportunityNewMap.get(opportunityId).stagename != opportunityOldMap.get(opportunityId).stagename
               && opportunityNewMap.get(opportunityId).stagename.equals(NSP_SalesConstants.CLOSED_WON)){
                closedWonOpptyList.add(opportunityNewMap.get(opportunityId));
               //569718- if parent opportunity - send notification to open child opportunities 
                if(String.isBlank(opportunityNewMap.get(opportunityId).NSP_Parent_Opportunity__c) || opportunityNewMap.get(opportunityId).NSP_Parent_Opportunity__c == null){
                 closedWonOpportunityIdList.add(opportunityId);
               } 
              }
             
            accountIdSet.add(opportunityNewMap.get(opportunityId).accountid);
            // Added as part of DF-01869 handled primary product for WO/WS or WA/WX
            if((opportunityNewMap.get(opportunityId).NSP_PrimaryProduct__c == NSP_SalesConstants.WO || 
               opportunityNewMap.get(opportunityId).NSP_PrimaryProduct__c == NSP_SalesConstants.WS) 
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
        //569718-to send notification to open child opportunities - upsell opportunities enhancement
        if(!closedWonOpportunityIdList.isEmpty()){
            NSP_ChildOpportunitiesHelperFunctions childHlprObj = new NSP_ChildOpportunitiesHelperFunctions();
          childHlprObj.updatesOnOpenChildOpportunity(closedWonOpportunityIdList);
        }
        //Calling Quote to Order method for generating order from Opportunity via a Quote update @utpal Utkalit
        NSP_GenerateOrderFromOpportunity.updateQuotetoOrderWhenOppWON(Trigger.new,opportunityOldMap);
        /* Moving to NSP_UpdateRelatedAccounts class as part of DF-01058 */
        NSP_UpdateRelatedAccounts.updateRelatedAccounts(accountIdSet); 
        
        
        
        //STY-01519 - Asset creation from Opportunity line item
        if(closedWonOpptyList.size() > 0){
            createAssetForCloseWonOpportunity(closedWonOpptyList);
            // commented as a part of Defect-DF-01797
            //NSP_EmailServicesUtility.sendEmailsTOService(closedWonOpptyList, opportunityNewMap, workforceProductsList);
        }
        
        if(newTaskOpportunityList.size() > 0){
            NSP_EventAndTaskHelperFunctions.createTaskRecordsForNCSQueue(newTaskOpportunityList, null);
        }
        
       // NSP_EventAndTaskHelperFunctions.createTaskForPrimaryQuote(opportunitiesWithPrimaryQuote);// commented as part of user story 128436
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
            
            if(opportunityRecord.NSP_Closing_Appointment__c != null
            && (((opportunityRecord.NSP_PrimaryProduct__c == NSP_SalesConstants.WO || 
                  opportunityRecord.NSP_PrimaryProduct__c == NSP_SalesConstants.WS) && 
                 opportunityRecord.NSP_Signed_CSA__c) 
                || ((opportunityRecord.NSP_PrimaryProduct__c == NSP_SalesConstants.WX ||
                     opportunityRecord.NSP_PrimaryProduct__c == NSP_SalesConstants.WA) && 
                    opportunityRecord.NSP_Signed_Delivery_Order__c) 
                || (opportunityRecord.NSP_PrimaryProduct__c != NSP_SalesConstants.WO && 
                    opportunityRecord.NSP_PrimaryProduct__c != NSP_SalesConstants.WS && 
                    opportunityRecord.NSP_PrimaryProduct__c != NSP_SalesConstants.WX &&
                    opportunityRecord.NSP_PrimaryProduct__c != NSP_SalesConstants.WA))){
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
        New NSP_SrcToTargetObjectDataMover(null,'OppAsset') ;//initialize the class
        List<Asset> assetfromCopier= NSP_SrcToTargetObjectDataMover.getSourceDatainTarget( opptyLineItemList);      
        Map<Id, Asset> assetMap = new Map<Id, asset>();
        for(Asset assetItem: assetfromCopier){
            assetMap.put(assetItem.accountId,assetItem);
        }
        List<Asset> existingAssets = [SELECT Id, Name,AccountId, Product2Id FROM Asset WHERE   AccountId in :accountIds AND RecordTypeId =:ASSET_RECORDTYPE_ID];
        Boolean isAssetFound=FALSE;
        for(Id draftAsset:assetMap.keySet()){
            for(Asset existingAsset: existingAssets ){  
                if(assetMap.get(draftAsset).AccountId == existingAsset.AccountId){
                    isAssetFound=TRUE;
                    Break;
                }
            }
            assetMap.get(draftAsset).RecordTypeId = ASSET_RECORDTYPE_ID;
            assetMap.get(draftAsset).Status = NSP_SalesConstants.ONBOARDING;
            if(!isAssetFound){
                upsertList.add(assetMap.get(draftAsset)); 
            }
            isAssetFound=FALSE;
            
            
        }
        upsert upsertList;
        
    }

      
    
/*
* Description: accepts a list of Opportunities with Partener accounts and
* sets the Partenr Lifecycle field on Account to Onboarding
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
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, NSP_Partner_Lifecycle__c,NSP_Onboarding_Contract_Date__c FROM Account WHERE Id IN :accountsIdSet]);
        
        for(Opportunity opportunityRecord : opportunityList){
            if(accountMap.get(opportunityRecord.AccountId).NSP_Partner_Lifecycle__c != NSP_SalesConstants.ONBOARDING){
                accountMap.get(opportunityRecord.AccountId).NSP_Partner_Lifecycle__c = NSP_SalesConstants.ONBOARDING;
                accountMap.get(OpportunityRecord.AccountId).NSP_Onboarding_Contract_Date__c = system.today();
                accountList.add(accountMap.get(opportunityRecord.AccountId));
            }
        }
        
        if(accountList.size() > 0)  {
            update accountList;          
    }    
  
    }
     
    /***********************************************************************************************
    * MethodName: getRelatedACR
    * Description : This method will fetch the Primary ACR records related to Opportunity Account
    * Params:       Set<Id> accountId ,Set<Id>OpportunityIds
    * ********************************************************************************************/  
    public static void getRelatedACR(Set<Id> accountId ,Set<Id>OpportunityIds){
      Map < Id, AccountContactRelation > accountACRMap = new Map < Id, AccountContactRelation > ();
        Set<Id> OppAccountId = new Set<Id>();
        for (AccountContactRelation accountContactRelation: [Select Id , ContactId ,NSP_Is_Primary__c, AccountId from AccountContactRelation WHERE NSP_Is_Primary__c =true AND AccountId IN: accountId]) {
            accountACRMap.put(accountContactRelation.AccountId,accountContactRelation );
        }
        List<Opportunity> OpportunityList =[Select Id, AccountId from Opportunity WHERE Id IN:OpportunityIds];
        for(Opportunity opp:OpportunityList){
            if(accountACRMap.containsKey(opp.AccountId) && accountACRMap.get(opp.AccountId)!=null){
               OppAccountId.add(opp.AccountId); 
            }
        }
        if(!OppAccountId.isEmpty()){
            NSP_OpportunityTriggerHelperFunctions.getAccountOwnerEmail(OppAccountId);
        }
    }   

/***********************************************************************************************
* MethodName: validateByNonProfitAndProfile
* Description : 
* Params:       Opportunity opp
* User-Story:   US-198540
* ********************************************************************************************/ 
public static boolean validateByNonProfitAndRole(Opportunity opp){
  
    if(byPassValidationOnRole== null){
        byPassValidationOnRole = new set<Id>();
        for(UserRole role : [SELECT Id FROM UserRole WHERE DeveloperName IN ('NSP_L1_Support', 'NSP_L2_Support_Admin')]){
            byPassValidationOnRole.add(role.id); 
        }
    }

    //  Check if User's Profile is in the Profile List
    if(byPassValidationOnRole.contains(UserInfo.getUserRoleId())){
        //  Check if stage is closed won OR closed lost
        return opp.StageName.equals('Closed Won') || opp.StageName.equals('Closed Lost');
    }
  

  return false;
}

        /***********************************************************************************************
* MethodName: validateClosedDate
* Description : This method will throw error when Opportunity close date is less than today for all users except for the users
                in NCS Public group
* Params:       List<Opportunity>OpportunityList
* Defect:       DF-01716
* ********************************************************************************************/ 
public static void validateClosedDate(List<Opportunity> OpportunityList){

       Id loggedInUserId = UserInfo.getUserId();   
    set<Id> ncsGrpMemIdSet = new set<Id>();
      List<String> groupList = new List<String>{'NCS', 'Sales Compensation'};
    List<group> ncsGroup = [SELECT Id,Name FROM group WHERE group.Name IN: groupList];
    for(groupMember ncsGrpMembers: [SELECT UserOrGroupId FROM GroupMember WHERE GroupId IN: ncsGroup]){
        ncsGrpMemIdSet.add(ncsGrpMembers.UserOrGroupId); 
    }

        for(Opportunity opp: OpportunityList){
            if(!ncsGrpMemIdSet.contains(loggedInUserId)){
                if(validateByNonProfitAndRole(opp) == false){
              opp.addError(Label.NSP_Opportunity_Close_Date_Validation);
            }  
        } 
        } 
    
}

/* Description: This method sets sales office details from user 
     * 
     * @param: opportunityList, opportunityMap
     * @return: void
     * Modification History:
     * -------------------------------------------------------------------------------------
     *  Date              | Description
     * -------------------------------------------------------------------------------------
     *  08/05/2022          created this new method added for STY-03154
     * 
     * 
    */
    
    public void setSalesOfficeDetails(List<Opportunity> newList,Map<Id, Opportunity> opportunityOldMap)
    {
        set<Id> ownerIdSet = new set<Id>(); // owner id set
        set<string> officeSet = new set<string>(); // sales office set
        set<Id> recordToProcess = new set<Id>();  // record to be process set
        set<string> opportunityStageSet = new set<string>{'Discovery','Analysis','Proposal','Closing'};
        for(Opportunity newOpportunity: newList)
        {
            Opportunity oldOpportunity = opportunityOldMap != null ? opportunityOldMap.get(newOpportunity.Id):null;
            if((Trigger.isInsert || newOpportunity.OwnerId != oldOpportunity.OwnerId) 
               && newOpportunity.OwnerId != null && opportunityStageSet.contains(newOpportunity.StageName)) // value assigned when owner is changed
            {
                ownerIdSet.add(newOpportunity.OwnerId);
            }
            else if(Trigger.isUpdate && newOpportunity.NSP_Sales_Office__c != oldOpportunity.NSP_Sales_Office__c && String.isNotBlank(newOpportunity.NSP_Sales_Office__c) && !valueAssignedFromUser ) // value assigned when sales office is changed.
            {
                recordToProcess.add(newOpportunity.Id);
                officeSet.add(newOpportunity.NSP_Sales_Office__c);
            }
            
        }
        
        if(ownerIdSet.Size() > 0)
        {
            // values assigned from users
            Map<Id,User> userIdMap = new Map<Id,User>([SELECT Id,NSP_SalesDivision__c,NSP_Sales_Office__c,NSP_SalesRegion__c from user where Id In :ownerIdSet AND NSP_Sales_Office__c != null ]);
            for(Opportunity newOpportunity: newList)
            {
                Opportunity oldOpportunity = opportunityOldMap != null ? opportunityOldMap.get(newOpportunity.Id):null;
                if((Trigger.isInsert || newOpportunity.OwnerId != oldOpportunity.OwnerId) && newOpportunity.OwnerId != null && userIdMap.containsKey(newOpportunity.OwnerId))
                {
                    user eachUser = userIdMap.get(newOpportunity.OwnerId);
                    newOpportunity.NSP_Sales_Region__c = eachUser.NSP_SalesRegion__c;  // sales region
                    newOpportunity.NSP_Sales_Division__c = eachUser.NSP_SalesDivision__c; // sales division
                    newOpportunity.NSP_Sales_Office__c = eachUser.NSP_Sales_Office__c; // sales office
                    valueAssignedFromUser = true;
                }
            }
        }
        // values assigned from sales office mapping
        if(officeSet.Size() > 0)
        {
            map<String,NSP_Sales_Office_Mapping__c> salesOfficeToMappingMap =  new map<String,NSP_Sales_Office_Mapping__c>();
            for(NSP_Sales_Office_Mapping__c eachMapping : [SELECT Id,NSP_Sales_Office__c,NSP_Sales_Division__c,NSP_Sales_Region__c 
                                                            FROM NSP_Sales_Office_Mapping__c 
                                                            WHERE NSP_Sales_Office__c In : officeSet AND isActive__c = true])
            {
                salesOfficeToMappingMap.put(eachMapping.NSP_Sales_Office__c,eachMapping);
            }
            
            
            for(Opportunity newOpportunity: newList)
            {
                if(Trigger.isUpdate && recordToProcess.contains(newOpportunity.Id) && salesOfficeToMappingMap.containsKey(newOpportunity.NSP_Sales_Office__c))
                {
                    NSP_Sales_Office_Mapping__c officeMapping = salesOfficeToMappingMap.get(newOpportunity.NSP_Sales_Office__c);
                    newOpportunity.NSP_Sales_Region__c = officeMapping.NSP_Sales_Region__c; // sales region
                    newOpportunity.NSP_Sales_Division__c = officeMapping.NSP_Sales_Division__c; // sales division
                }
            }
        }
    }


/* Description: This method used to create rewards record for Contact role 
     * 
     * @param: opportunityList, opportunityMap
     * @return: void
     * Modification History:
     * -------------------------------------------------------------------------------------
     *  Date              | Description
     * -------------------------------------------------------------------------------------
     *  14/09/2022          created this new method added for STY-03287
     * 
     * 
    */  
    public void creteRewardForContactRole(Map<Id, Opportunity> opportunityNewMap,Map<Id, Opportunity> opportunityOldMap)
    {
        set<String> primaryProductSet = new set<String>{'WX','WA','WO'}; 
        map<Id,String> opportunityIdToRewardTypeMap = new map<Id,String>();
        for(Opportunity newOpportunity: opportunityNewMap.Values())
        {
            Opportunity oldOpportunity = opportunityOldMap != null ? opportunityOldMap.get(newOpportunity.Id):null;
            if(newOpportunity.Type != 'Client Growth Credit') // added for DF-02233
            {
                if(opportunityOldMap != null && newOpportunity.Discovery_Completed__c && !oldOpportunity.Discovery_Completed__c && String.isNotBlank(newOpportunity.NSP_PrimaryProduct__c) && primaryProductSet.contains(newOpportunity.NSP_PrimaryProduct__c))
                {
                    opportunityIdToRewardTypeMap.put(newOpportunity.Id,'Discovery');
                }
                else if(opportunityOldMap != null && newOpportunity.Nsp_1st_Pay_Invoice_Date_Reporting__c != null && oldOpportunity.Nsp_1st_Pay_Invoice_Date_Reporting__c == null && String.isNotBlank(newOpportunity.NSP_PrimaryProduct__c) && primaryProductSet.contains(newOpportunity.NSP_PrimaryProduct__c))
                { 
                    opportunityIdToRewardTypeMap.put(newOpportunity.Id,'Sold');
                }
            }   
            
        }
        
        if(opportunityIdToRewardTypeMap.Size() > 0)
        {
                list<NSP_Reward__c> rewardsInsertList = new list<NSP_Reward__c>();
                map<id,Event> oppottunityToEventMap = new map<id,Event>();
                
                for(Event eachEvent : [SELECT Id,NSP_Completed_Date__c,WhatId from Event Where WhatId in :opportunityIdToRewardTypeMap.KeySet() AND NSP_Event_Subtype__c = 'Discovery Call' AND NSP_Status__c = 'Completed' ])
                {
                    oppottunityToEventMap.put(eachEvent.WhatId,eachEvent);
                }
                
                for(OpportunityContactRole eachOCR : [SELECT id,opportunityId,opportunity.NSP_Number_of_EEs__c,contactId,Role,Opportunity.AccountId,NSP_Referralbenefitsanonprofitorg__c, 
                                                        NSP_Nonprofit_Organization_Name__c,NSP_Nonprofit_Organization_Tax_Id__c from OpportunityContactRole 
                                                        WHERE opportunityId in : opportunityIdToRewardTypeMap.keySet() 
                                                        AND NSP_isReferral__c = true])
                {
                    string rewardType = opportunityIdToRewardTypeMap.get(eachOCR.opportunityId);
                    opportunity currentOppty = opportunityNewMap.get(eachOCR.opportunityId);
                    if(rewardType == 'Discovery')
                    {
                        NSP_Reward__c newReward = createRewards(eachOCR, currentOppty);
                        if(String.isNotBlank(eachOCR.NSP_Referralbenefitsanonprofitorg__c) && eachOCR.NSP_Referralbenefitsanonprofitorg__c == 'Match')
                        {
                            newReward.NSP_Reward_Amount__c = 100;
                            newReward.NSP_Nonprofit_Amount__c = 100;
                            newReward.NSP_Payment_Type_Reward__c = 'Check';
                            newReward.NSP_Payment_Type_Non_Profit__c = 'Check';
                            
                        }
                        else if(String.isNotBlank(eachOCR.NSP_Referralbenefitsanonprofitorg__c) && eachOCR.NSP_Referralbenefitsanonprofitorg__c == 'Donation')
                        {
                            newReward.NSP_Reward_Amount__c = 0;
                            newReward.NSP_Nonprofit_Amount__c = 200;
                            newReward.NSP_Payment_Type_Reward__c = null;
                            newReward.NSP_Payment_Type_Non_Profit__c = 'Check';
                        }
                        else{
                            newReward.NSP_Reward_Amount__c = 200;
                            newReward.NSP_Nonprofit_Amount__c = 0;
                            newReward.NSP_Payment_Type_Reward__c = 'Check';
                            newReward.NSP_Payment_Type_Non_Profit__c = null;
                            
                        }
                        newReward.NSP_Reward_Type__c = 'Discovery';
                        newReward.NSP_Discovery_Call_Completed_Date__c = oppottunityToEventMap.containsKey(eachOCR.opportunityId) ? oppottunityToEventMap.get(eachOCR.opportunityId).NSP_Completed_Date__c: null;
                        rewardsInsertList.add(newReward);
                    }
                    else if(rewardType == 'Sold' && (eachOCR.Role == 'Agency' || currentOppty.NSP_Number_of_Employees__c >= 5) )
                    {
                        NSP_Reward__c newReward = createRewards(eachOCR, currentOppty);
                        if(String.isNotBlank(eachOCR.NSP_Referralbenefitsanonprofitorg__c) && eachOCR.NSP_Referralbenefitsanonprofitorg__c == 'Match')
                        {
                            newReward.NSP_Reward_Amount__c = 500;
                            newReward.NSP_Nonprofit_Amount__c = 500;
                            newReward.NSP_Payment_Type_Reward__c = 'Check';
                            newReward.NSP_Payment_Type_Non_Profit__c = 'Check';
                            
                        }
                        else if(String.isNotBlank(eachOCR.NSP_Referralbenefitsanonprofitorg__c) && eachOCR.NSP_Referralbenefitsanonprofitorg__c == 'Donation')
                        {
                            newReward.NSP_Reward_Amount__c = 0;
                            newReward.NSP_Nonprofit_Amount__c = 1000;
                            newReward.NSP_Payment_Type_Reward__c = null;
                            newReward.NSP_Payment_Type_Non_Profit__c = 'Check';
                        }
                        else{
                            newReward.NSP_Reward_Amount__c = 1000;
                            newReward.NSP_Nonprofit_Amount__c = 0;
                            newReward.NSP_Payment_Type_Reward__c = 'Check';
                            newReward.NSP_Payment_Type_Non_Profit__c = null;
                            
                        }
                        newReward.NSP_Reward_Type__c = 'Sold';
                        rewardsInsertList.add(newReward);
                    }
                }
                
                if(rewardsInsertList.Size() > 0 && !createRewardsOnce )
                {
                    createRewardsOnce  = true;
                    insert rewardsInsertList;
                }
        }
    }
    
    public NSP_Reward__c createRewards(OpportunityContactRole objOCR, opportunity objOpportunity)
    {
        NSP_Reward__c newReward = new NSP_Reward__c();
        newReward.NSP_Account__c = objOCR.Opportunity.AccountId;
        newReward.NSP_Benefits_Non_Profit__c = objOCR.NSP_Referralbenefitsanonprofitorg__c;
        newReward.NSP_Contact__c = objOCR.ContactId;
        newReward.Opportunity__c = objOpportunity.Id;
        newReward.NSP_Contact_Role__c = objOCR.Role;
        newReward.NSP_Non_ProfitName__c = objOCR.NSP_Nonprofit_Organization_Name__c;
        newReward.NSP_Non_Profit_TaxID__c = objOCR.NSP_Nonprofit_Organization_Tax_Id__c;
        newReward.NSP_Non_Profit_Address__c = objOpportunity.NSP_NonprofitNameAddress__c;
        return newReward;
    }

    /***********************************************************************************************
    * MethodName: createContactRole
    * Description : This method will create OCR
    * Params:       List<Opportunity> newList,Map<Id, Opportunity> opportunityNewMap
    * Author : Rahul Singh
    * Created Date:10/26/22
    * Created as part of User story - 128223
    * ********************************************************************************************/   
    
    public void createContactRole(List<Opportunity> newList,Map<Id, Opportunity> opportunityNewMap)
    {
        set<Id> oppWithCon = new set<Id>();
        map<Id,Id> accAndOpp = new map<Id,Id>();
        map<id,AccountContactRelation> acrMap = new map<id,AccountContactRelation>();
        list<OpportunityContactRole> ocrInsertList = new list<OpportunityContactRole>();
   
        for(Opportunity newOpportunity: newList)
        {
            if(Trigger.isInsert && newOpportunity.OwnerId != null && newOpportunity.NSP_Is_Originated_From_Lead_Conversion__c == False)
            {

                accAndOpp.put(newOpportunity.id, newOpportunity.AccountId);
            }
            
            
        }
        
       
         if(accAndOpp.Size() > 0)
        {
             for(AccountContactRelation eachACR : [SELECT Id, AccountId, ContactId, Roles, IsDirect, IsActive, CurrencyIsoCode, NSP_ACCOUNTCONTACT_MERGE__c, Relationship_Strength__c, 
                                                   NSP_Is_Primary__c, NSP_Nonprofit_Organization_Name__c, NSP_Nonprofit_Organization_Tax_Id__c, NSP_OneForce_External_ID__c, 
                                                   NSP_Referralbenefitsanonprofitorg__c, NSP_isReferral__c FROM AccountContactRelation Where AccountId  in :accAndOpp.values() AND NSP_Is_Primary__c = True])
            
            {
                    acrMap.put(eachACR.AccountId,eachACR);                       
            
            }
            
        }
        
        
         if(accAndOpp.Size() > 0 && acrMap.Size() >0)
        {   
            for(id oppOnConv : accAndOpp.keySet() ){
               
                AccountContactRelation eachACR = acrMap.get(accAndOpp.get(oppOnConv));
                 OpportunityContactRole newOcr = new OpportunityContactRole();
                 newOcr.OpportunityId = oppOnConv;
                 newOcr.ContactId = eachACR.ContactId;
                 newOcr.IsPrimary = eachACR.NSP_Is_Primary__c;
                 newOcr.CurrencyIsoCode = eachACR.CurrencyIsoCode;
                 newOcr.NSP_Nonprofit_Organization_Name__c = eachACR.NSP_Nonprofit_Organization_Name__c;
                 newOcr.NSP_Nonprofit_Organization_Tax_Id__c = eachACR.NSP_Nonprofit_Organization_Tax_Id__c;
                 newOcr.NSP_Referralbenefitsanonprofitorg__c = eachACR.NSP_Referralbenefitsanonprofitorg__c;
                 newOcr.NSP_isReferral__c = eachACR.NSP_isReferral__c;
                 ocrInsertList.add(newOcr);   
                
            }
        }
        
        try{
        if(ocrInsertList.Size() > 0)
                
        {
            insert ocrInsertList;
                
        }            
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        } 
            
            
          
    
    }
     /***********************************************************************************************
    * MethodName: enrollmentFeeCheck
    * Description : This method will update enrollment fee payment
    * Params:       Map<Id, Opportunity> opportunityNewMap,Map<Id, Opportunity> opportunityOldMap
    * Author : Rahul Singh
    * Created Date:22/12/22
    * Created for enrollment fee payment user story - 194265
    * ********************************************************************************************/   
    
    
     public void enrollmentFeeCheck(Map<Id, Opportunity> opportunityNewMap,Map<Id, Opportunity> opportunityOldMap)
    {
         set<Id> oppIdTrue = new set<Id>();
         set<Id> oppIdFalse = new set<Id>();
         list<NSP_Enrollment_Fee_Payment__c> enrollmentUpdateList = new list<NSP_Enrollment_Fee_Payment__c>();
         for(Opportunity newOpportunity: opportunityNewMap.Values())
        {
             Opportunity oldOpportunity = opportunityOldMap != null ? opportunityOldMap.get(newOpportunity.Id):null;
            //Modified for user story 192368
            if((newOpportunity.NSP_Number_of_Employees__c != oldOpportunity.NSP_Number_of_Employees__c && newOpportunity.NSP_Number_of_Employees__c >= 150) || 
               (oldOpportunity.NSP_MidMarketNationalAccount__c == Null && newOpportunity.NSP_MidMarketNationalAccount__c != Null))
                {
                    oppIdTrue.add(newOpportunity.Id);
                }
            //Modified for user story 192368
            else if((newOpportunity.NSP_Number_of_Employees__c != oldOpportunity.NSP_Number_of_Employees__c && newOpportunity.NSP_Number_of_Employees__c < 150) || 
                    (oldOpportunity.NSP_MidMarketNationalAccount__c != Null && newOpportunity.NSP_MidMarketNationalAccount__c == Null))
                {
                    oppIdFalse.add(newOpportunity.Id);
                }
            
            
        }
        if(oppIdTrue.Size() > 0)
        { 
          
               for(NSP_Enrollment_Fee_Payment__c eachEnrollment : [SELECT Id FROM NSP_Enrollment_Fee_Payment__c WHERE NSP_Opportunity__c in :oppIdTrue])
            
            {
                  NSP_Enrollment_Fee_Payment__c newEnrollment = new NSP_Enrollment_Fee_Payment__c();
                  newEnrollment.Id = eachEnrollment.Id; 
                  newEnrollment.NSP_Is_MidMarket__c = True; 
                  enrollmentUpdateList.add(newEnrollment);     
            
            }
        }
        else if(oppIdFalse.Size() > 0)
        { 
          
               for(NSP_Enrollment_Fee_Payment__c eachEnrollment : [SELECT Id FROM NSP_Enrollment_Fee_Payment__c WHERE NSP_Opportunity__c in :oppIdFalse])
            
            {
                  NSP_Enrollment_Fee_Payment__c newEnrollment = new NSP_Enrollment_Fee_Payment__c();
                  newEnrollment.Id = eachEnrollment.Id; 
                  newEnrollment.NSP_Is_MidMarket__c = False; 
                  enrollmentUpdateList.add(newEnrollment);     
            
            }
        }
        try{
        if(enrollmentUpdateList.Size() > 0)
                
        {
            update enrollmentUpdateList;
                
        }            
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        } 
            
            
            
        }
        
    
    
    
}