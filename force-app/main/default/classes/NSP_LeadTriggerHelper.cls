/**************************************************************************************************   
Version              :  1.0                                                                          
Created Date         :  October 10, 2021                                                             
Function             :   Represents the Lead trigger helper which handles all the logic.
Test class           :  NSP_LeadTriggerHelperTest
Story                :                                                                             
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                     
* -------------------------------------------------------------------------------------------------  

*	Tejas           October 10, 2021          First Iteration
* Harsha Khiroya  Feb 25, 2021              DF-01321
***************************************************************************************************/


public class NSP_LeadTriggerHelper {
    // test w/ NSP_LeadTriggerHelperTest (81%)
    
    public static final List < String > reasonNurturingReasonsList = System.label.NSP_Lead_at_Nurturing_or_Unqualified.split(';');
    private static final string NEW_LEAD_RT = 'NSP_New_Lead_Record_Type';
    private static final string LEAD_RT = 'Lead';
    private static final Id NEW_LEAD_RT_ID = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(NEW_LEAD_RT).getRecordTypeId();
    private static final Id LEAD_RT_ID = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(LEAD_RT).getRecordTypeId();
    private static final string SYS_ADMIN = 'System Administrator';
    private static final string INTEGRATION_PROFILE = 'Integration User';
    // Added as part of DF-01009
    private static final string REFERRAL_RECORDTYPE = 'Referral';
    private static final Id REFERRAL_RECORDTYPE_ID = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(REFERRAL_RECORDTYPE).getRecordTypeId();
    public static final Id SERVICE_REFERRAL_RECORDTYPE_ID = NSP_GenericRecordType.getRecordTypeId('Lead',NSP_ServiceConstants.SERVICE_REFERRAL_RT );
    /**
* Iterates throught the list of new leads and passes the required attributes to other methods.
* @param newList List of New leads.  
* @return void             
*                
*/
    public void beforeInsertDirector(List < Lead > newList) {
        //Set to store account ids
        Set < String > accountIdSet = new Set < String > ();
        List<Lead> inboundSolutionsList =  new List<Lead>();  // Added as part of DF-01009 
         /* Added to Map Sales Office on insert if Zipcode is populated*/
      List < Lead > zipCodeLeadList = new List < Lead > ();
      List < String > zipCodeList = new List < String > ();
      Boolean isOwnerAssignment = true; 
      /* Added to Map Sales Office on insert if Zipcode is populated*/   
        //Iterating over the new lead list(trigger.new)
        for (Lead leadObject: newList) {
            updateAccountSegment(leadObject);
            preventOneTrustDupe(leadObject);
            if(leadObject.DNB_Connect_DUNS_Number__c != null){
                dunsCheck(leadObject);
            }

            //switch record type to Lead or Referral record type
            if (leadObject.RecordTypeId == NEW_LEAD_RT_ID) {
                leadObject.RecordTypeId = LEAD_RT_ID;
            }

            // When a new lead is created set the status as New.
            leadObject.Status = NSP_SalesConstants.STR_NEW;
            //if the partner field is not blank on the lead adding the partner value in account set
            if (String.isnotBlank(leadObject.NSP_Partner__c)) {
                accountIdSet.add(leadObject.NSP_Partner__c);
            }

            //if lead stage is blank setting it to Suspect
            if (String.isBlank(leadObject.NSP_Lead_Stage__c)) {
                leadObject.NSP_Lead_Stage__c = NSP_SalesConstants.LEAD_STAGE_SUSPECT;
            }
            //STY-03447 When A service referral lead record is saved --> assigning referral user to be loggedin user
            if (leadObject.RecordTypeId == SERVICE_REFERRAL_RECORDTYPE_ID){
                leadObject.NSP_Referral_User__c = UserInfo.getUserId();
            }
            //If FireScore is greater than FIRE_SCORE_THRESH setting lead stage to MPL
            if (null != leadObject.nsp_fire_score__c && leadObject.nsp_fire_score__c > Integer.valueOf(System.label.NSP_FIRE_SCORE_THRESH)) {
                leadObject.NSP_Lead_Stage__c = NSP_SalesConstants.LEAD_STAGE_MPL;
            }

            /* As part of DF-00998 comments, While Creating Lead From ELoqua Integration user or From Referral Form, Lead should get assigned to Inbound solutions Queue */
            List < String > externalUsers = Label.NSP_External_Users.split(',');
            //Added as part of DF-00998
            String createdUserName = UserInfo.getFirstName();
            if (leadObject.RecordTypeId == REFERRAL_RECORDTYPE_ID || 
            leadObject.RecordTypeId == SERVICE_REFERRAL_RECORDTYPE_ID || 
            (String.isNotBlank(createdUserName) && externalUsers.contains(createdUserName))) {
                inboundSolutionsList.add(leadObject);
            }

            //if value Discovery call time is 12 AM , set it to 12 PMto 12 PM.
            if (leadObject.NSP_DC_SetTime__c !=null && leadObject.NSP_DC_SetTime__c == Time.newInstance(0,0,0,0)) {
                leadObject.NSP_DC_SetTime__c += Integer.valueOf(System.Label.NSP_12_hours_Milliseconds);
            }

            /*Added to Map Sales Office on insert if Zipcode is populated */
            if(String.isNotBlank(leadObject.PostalCode) && leadObject.NSP_Lead_Routing__c == true){
                zipCodeLeadList.add(leadObject);
                zipCodeList.add(leadObject.PostalCode.substring(0,5));
            }
        }
        /* Added to Map Sales Office on insert if Zipcode is populated*/
        if(!zipCodeLeadList.isEmpty() && !zipCodeList.isEmpty()){
            isOwnerAssignment = false;
            setLeadRegion(zipCodeList, zipCodeLeadList, isOwnerAssignment);
        }
        /* Added as part of DF-01943*/
        for(Lead zipLead : zipCodeLeadList){
            if(String.isNotBlank(zipLead.NSP_Sales_Office__c)){
                zipLead.NSP_Is_Sales_Office_Assigned__c = true;
            }
        }

        /* Added to Map Sales Office on insert if Zipcode is populated*/
        //calling method to stmap primary contact's email from partner account to lead
        if (!accountIdSet.isEmpty()) {
            putPartnerEmailOnLead(newList, accountIdSet);
        }
        
        //Assigning to Inbound Solutions SalesQueue if the Lead is creating from Referral Form or Eloqua as per new Lead assignment rules.
        if(!inboundSolutionsList.isEmpty()){
            assignLeadToInboundSolutions(inboundSolutionsList);
        }
        
        setSalesOfficeDetails(newList,null); // added for STY-03154
    }
    
    /**
* Iterates throught the lead map and identifies the records that needs to worked based on various criterias.
* @param leadNewMap Map of New leads. 
* @param leadOldMap Map of Old leads. 
* @return void             
*                
*/
    public void beforeUpdateDirector(Map < Id, Lead > leadNewMap, Map < Id, Lead > leadOldMap) {
        //List to hold the leads for round robin distribution
        List < Lead > leadsForRoundRobin = new List < Lead > ();
        //List of zipcodes
        List < String > zipCodeList = new List < String > ();
        //List to store lead records
        List < Lead > fireScoreLeadList = new List < Lead > ();
        //List to hold the leads for mid market
        List < Lead > midMarketList = new List < Lead > ();
        List < Lead > payrollHCMList = new List < Lead > ();
        List < String > nationalAccountList = Label.NSP_National_Accounts.toUppercase().split(',');
        List < Lead > nationalAccountLeadList = new List < Lead > ();
        List < Lead > inboundSolutionsList = new List < Lead > ();
        Boolean isOwnerUpdated = false;
      Lead parentLead = new Lead();
        /* Added as part of STY-01725 */
        List<String> inboundOrOutBoundUserList = Label.Inbound_and_Outbound_UserRole.split(',');
        /* Added as part of DF-01846*/
      List < Lead > zipCodeLeadList = new List < Lead > ();
      List < String > zipCodeUpdateList = new List < String > ();
      Boolean isOwnerAssignment = true;
      Boolean isZipCodeUpdate = false;
      /* Added as part of DF-01846*/
       //228901 - Added Trigger Switch for SOQL issue
       if(NSP_Trigger_Switch__c.getOrgDefaults().NSP_SOQL_Switch__c){
           User userDetails =[ SELECT Id, Name, UserRole.Name, Profile.Name FROM User WHERE Id =: userinfo.getUserId() ];
       }
        /* Added as part of STY-01725 */
        //iterating over trigger.newmap
        for (Id leadId: leadNewMap.keySet()) {
            //checking if fire score is not null and fire score value has changed and fire score value is greater than FIRE_SCORE_THRESH
            if (leadNewMap.get(leadId).nsp_fire_score__c != null && leadNewMap.get(leadId).nsp_fire_score__c > Integer.valueOf(System.label.NSP_FIRE_SCORE_THRESH) &&
                leadNewMap.get(leadId).nsp_fire_score__c != leadOldMap.get(leadId).nsp_fire_score__c) {
                    //adding lead records to the list
                    fireScoreLeadList.add(leadNewMap.get(leadId));
                }
            /* Added as part of CR-027 */
            if (leadNewMap.get(leadId).NSP_Parent_Lead__c != null && (leadNewMap.get(leadId).NSP_Parent_Lead__c != leadOldMap.get(leadId).NSP_Parent_Lead__c)) {
            parentLead = leadNewMap.get(leadId);
                        isOwnerUpdated = true;
            }
            //STY-03447  whenuser change the referral user on detail page, field should not be empty 
            if(leadNewMap.get(leadId).RecordTypeId == SERVICE_REFERRAL_RECORDTYPE_ID && leadNewMap.get(leadId).NSP_Referral_User__c == NULL){
                leadNewMap.get(leadId).NSP_Referral_User__c = UserInfo.getUserId();
            }
            if(leadNewMap.get(leadId).DNB_Connect_DUNS_Number__c != null && leadNewMap.get(leadId).NSP_Lead_Routing__c == true && isOwnerUpdated == false) {
                isOwnerUpdated = dunsCheck(leadNewMap.get(leadId));
            }
            // add 12 hours to time value if value is 12 AM- DF-01502
            if (leadNewMap.get(leadId).NSP_DC_SetTime__c != leadOldMap.get(leadId).NSP_DC_SetTime__c && leadNewMap.get(leadId).NSP_DC_SetTime__c == Time.newInstance(0,0,0,0)) {
                leadNewMap.get(leadId).NSP_DC_SetTime__c += Integer.valueOf(System.Label.NSP_12_hours_Milliseconds);
			}  
            /* Added as part of DF-01301 */
            
            /* As part of DF-00998 comments
* If the loggedIn user is either Inbound or Outbound and Assign Lead Checkbox is checked then only Lead assignment rule will trigger
* If the loggedIn user is not Inbound or Outbound solutions user, then No Lead assignment rules will trigger 
*/
if ((leadNewMap.get(leadId).NSP_Lead_Routing__c == true && 
 leadNewMap.get(leadId).DNB_Connect_DUNS_Number__c == null && 
 leadNewMap.get(leadId).NSP_Parent_Lead__c == null) || 
              (leadNewMap.get(leadId).DNB_Connect_DUNS_Number__c != null && isOwnerUpdated == false && 
               leadNewMap.get(leadId).NSP_Lead_Routing__c == true && leadNewMap.get(leadId).NSP_Parent_Lead__c == null)) {
                    if (String.isnotBlank(leadNewMap.get(leadId).company) && nationalAccountList.contains(leadNewMap.get(leadId).company.toUppercase())) {
                        //If the Lead Company is associated with National Account, route the correct National Account Queue
                        nationalAccountLeadList.add(leadNewMap.get(leadId));
                    } else if (leadNewMap.get(leadId).NumberOfEmployees != null 
                                              && Integer.valueof(leadNewMap.get(leadId).NumberOfEmployees) >= Integer.valueOf(System.Label.NSP_EMP_THRESH_150)
                                              && leadNewMap.get(leadId).NSP_Product_Interest__c != null){
                                                  if (leadNewMap.get(leadId).NSP_Product_Interest__c.contains(System.label.NSP_PRODINT_FULL_SERVICE_HR)) {
                                                      /* If Emp >= 150 and Product of Interest is WO, then assign to mid market queue */
                                                      midMarketList.add(leadNewMap.get(leadId));
                                                      isZipCodeUpdate = true;
                                                  } else if (leadNewMap.get(leadId).NSP_Product_Interest__c.contains(String.valueOf(System.label.NSP_PRODINT_HCM))) {
                                                      /*If Emp >= 150 and Product of Interest is WX, then assign to payroll/HCM queue */
                                                      payrollHCMList.add(leadNewMap.get(leadId));
                                                  }
                                              } else if ((String.isNotBlank(leadNewMap.get(leadId).PostalCode)
                                                     && (leadNewMap.get(leadId).PostalCode.length() >=5))
                                                     && (leadNewMap.get(leadId).NumberOfEmployees == null || Integer.valueof(leadNewMap.get(leadId).NumberOfEmployees) < Integer.valueOf(System.Label.NSP_EMP_THRESH_150))) {
                                                      /* If Postal Code is not blank, Number of Employees is null or < 150 and Product of interest is WO/WX assign to Sales office */
                                                      leadsForRoundRobin.add(leadNewMap.get(leadId));
                                                      zipCodeList.add(leadNewMap.get(leadId).PostalCode.substring(0,5));
                                                      isZipCodeUpdate = true;
                                                  } 
                                                  else {
                                                    leadNewMap.get(leadId).NSP_Lead_Routing__c = FALSE;
                                                     }   
                    }      
          else {
              leadNewMap.get(leadId).NSP_Lead_Routing__c = FALSE;
          }
          
           //collect all Leads to change AccountSegment value based on number of employees
            if (leadNewMap.get(leadId).NumberOfEmployees != leadOldMap.get(leadId).NumberOfEmployees) {
                updateAccountSegment(leadNewMap.get(leadId));
            }
             /* Added as part of DF-01846*/
          if( leadNewMap.get(leadId).PostalCode != leadOldMap.get(leadId).PostalCode &&
          String.isNotBlank(leadNewMap.get(leadId).PostalCode) && isZipCodeUpdate == false &&
          leadNewMap.get(leadId).NSP_Lead_Routing__c == true){
              zipCodeLeadList.add(leadNewMap.get(leadId));
              zipCodeUpdateList.add(leadNewMap.get(leadId).PostalCode.substring(0,5));
          }
       /* Added as part of DF-01846*/
        }

      if(!zipCodeLeadList.isEmpty() && !zipCodeUpdateList.isEmpty()){
        isOwnerAssignment = false;
        setLeadRegion(zipCodeUpdateList, zipCodeLeadList, isOwnerAssignment);
    }
      /* Added as part of DF-01943*/
   for(Lead zipLead : zipCodeLeadList){
    if(String.isNotBlank(zipLead.NSP_Sales_Office__c)){
        zipLead.NSP_Is_Sales_Office_Assigned__c = true;
    }
}
  /* Added as part of DF-01943*/
      if(parentLead != null){
          updateChildOwner(parentLead);
      }
        //calling method to set the lead stage as per the fire score
        if (!fireScoreLeadList.isEmpty()) {
            setLeadStageToMarketingPriortisedLead(fireScoreLeadList, leadOldMap);
        }
        //Roundrobin logic to assign leads to Sales Office
        if (!leadsForRoundRobin.isEmpty()) {
            setLeadRegion(zipCodeList, leadsForRoundRobin, isOwnerAssignment);
        }
        //assigning leads to mid market queue in number of employees >=EMP_THRESH_150
        if (!midMarketList.isEmpty()){
            assignLeadToMidMarket(midMarketList);
        }
        //assigning leads to national accounts queue
        if (!nationalAccountLeadList.isEmpty()){
            assignLeadToNationalAccountQueue(nationalAccountLeadList);
        }
        //assigning leads to mid market queue in number of employees >=EMP_THRESH_150
        if (!payrollHCMList.isEmpty()){
            assignLeadToPayrollHCM(payrollHCMList);
        }
        //Added as part of CR--027 (Convert the child Leads to contacts on Parent Lead Conversion)
        createContact(leadNewMap.Values());        
        setSalesOfficeDetails(leadNewMap.values(),leadOldMap);  // added for STY-03154
    }
  
  public void updateChildOwner(Lead leadObj) {
      List < Lead > leadResult = [SELECT Id, OwnerId FROM Lead WHERE id = : leadObj.NSP_Parent_Lead__c];
      Lead parentLeadToUpdate = new Lead();
      List <Lead> parentToUpdate = new List <Lead>();
      if (!leadResult.isEmpty()) {
          for (Lead dunsLead: leadResult) {
              leadObj.NSP_Skip_Validation__c= true;
              leadObj.OwnerId = dunsLead.OwnerId;
          }
      }
   }
/**
* Iterates throught the lead map and identifies the records that needs to worked based on various criterias.
* @param leadNewMap Map of New leads. 
* @param leadOldMap Map of Old leads. 
* @return void             
* @DF-01301-The District Administrator is able to reassign the Lead to themself.            
*/
    public void restrictLeadOwnerChange(Map < Id, Lead > leadNewMap, Map < Id, Lead > leadOldMap) {
        //Set to hold the Salesoffices
        Set < String > salesOfficeSet = new Set < String > ();
        Set < Id > ownerIdset = new Set < Id > ();
        //List to hold the groupmembers of salesoffices
        List < String > MMBSPUserList = Label.MM_AND_BPC_USERROLE.split(',');
        List < GroupMember > groupMemberList = new List < GroupMember > ();
        User userDetails = [SELECT Id, Name, UserRole.Name, Profile.Name FROM User WHERE Id = : userinfo.getUserId()];
        for (Id leadId: leadNewMap.keySet()) {
            if (trigger.isupdate && trigger.isbefore) {
                //Current logged in user not equal to Owner and logged in user profile not sys admin 
                if (userDetails.Id != leadOldMap.get(leadId).OwnerId && userDetails.Profile.Name != SYS_ADMIN && userDetails.Profile.Name != INTEGRATION_PROFILE) {
                    //Check logged in user role not in Mid Market/BPS 
                    if (!MMBSPUserList.contains(userDetails.UserRole.Name)) {
                        //Lead owner not a queue check
                        if (leadOldMap.get(leadId).OwnerId.getSObjectType() == User.SObjectType) {
                            ownerIdset.add(leadOldMap.get(leadId).OwnerId);
                        }
                    }
                }
            }
        }
        //Collect User salesoffice details
        if (ownerIdset != null) {
            List < User > ownerIdList = [Select Id, ToLabel(NSP_Sales_Office_Membership__c) from User WHERE ID IN: ownerIdset];
            if (!ownerIdList.isEmpty()) {
                for (User userList: ownerIdList) {
                    if (userList.NSP_Sales_Office_Membership__c != Null) {
                        salesOfficeSet.addAll(new List<String>(userList.NSP_Sales_Office_Membership__c.Split(';')));
                    }
                }
            }
            if (!salesOfficeSet.isEmpty()) {
                groupMemberList = [SELECT Id, Group.Name, UserOrGroupId FROM GroupMember WHERE UserOrGroupId = : userinfo.getUserId() AND Group.Name IN: salesOfficeSet];
            }
            //restrict lead edit access/change owner if logged in user not part of lead owner salesoffice group
            for (Id leadId: leadNewMap.keySet()) {
                if (trigger.isupdate && trigger.isbefore) {
                    Boolean hasNamedAccountGroupBypass = CustomPermissionController.checkUserPermission(
                                                 'Named_Account_Group_Bypass_Restrictions',
                                                 UserInfo.getUserId()
                                                 );
                                                 
                    if (!hasNamedAccountGroupBypass && userDetails.Id != leadOldMap.get(leadId).OwnerId && userDetails.Profile.Name != SYS_ADMIN && userDetails.Profile.Name != INTEGRATION_PROFILE) {
                        if (!MMBSPUserList.contains(userDetails.UserRole.Name)) {
                            if (leadOldMap.get(leadId).OwnerId.getSObjectType() == User.SObjectType) {
                                if (groupMemberList.isEmpty()) {
                                    leadNewMap.get(leadId).Id.addError(system.label.NSP_LeadTriggerError);
                                }
                            }
                        }
                    }
                }
            }
        }
    }    
    /**
* Iterates throught the lead map and identifies the records that needs to worked based on various criterias.
* @param leadNewMap Map of New leads. 
* @param leadOldMap Map of Old leads. 
* @return void             
*                
*/
    public void afterUpdateDirector(Map < Id, Lead > leadNewMap, Map < Id, Lead > leadOldMap) {
        Map < String, Lead > accountLeadMap = new Map < String, Lead > ();
        Map < String, Lead > opportunityLeadMap = new Map < String, Lead > ();
        Set < Id > convertedOpportunityIdsSet = new Set < Id > ();
        List < Lead > nurturingLeadList = new List < Lead > ();
      Lead childList = new Lead ();
      Lead leadToUpdate = new Lead ();
        Set<Id> accountId = new  Set<Id>();
        for (Lead leadObject: leadNewMap.values()) {
            if (leadObject.isconverted && String.isNotBlank(leadObject.convertedOpportunityId)) {
                convertedOpportunityIdsSet.add(leadObject.convertedOpportunityId);
            }
          if(leadObject.OwnerId != leadOldMap.get(leadObject.Id).OwnerId){
              childList = new Lead(Id=leadObject.id);
              childList.OwnerId = leadObject.OwnerID;
          }
          if (leadObject.NSP_Skip_Validation__c == true) {
              leadToUpdate = new Lead(Id=leadObject.id);
              leadToUpdate.NSP_Skip_Validation__c= false;  
          }
            if (leadObject.isconverted && !String.isBlank(leadObject.NSP_Referred_By_COI__c)) {
                accountLeadMap.put(leadObject.convertedAccountId, leadObject);
                opportunityLeadMap.put(leadObject.convertedOpportunityId, leadObject);
            }
            
            if (String.isNotBlank(leadObject.NSP_Reason__c) &&
                reasonNurturingReasonsList.contains(leadObject.NSP_Reason__c) &&
                leadObject.NSP_Reason__c != leadOldMap.get(leadObject.Id).NSP_Reason__c) {
                    nurturingLeadList.add(leadObject);
                }
            // added as a part of story STY-02090
            if(leadObject.isconverted){
                accountId.add(leadObject.convertedAccountId);
            }
        }
        // Added as part of DF-01654
        /*if(!opportunityLeadMap.isEmpty()){
           // updateNonProfitOrgFields(opportunityLeadMap); removed for STY-03346
        }*/
        
        setContactasCOI(accountLeadMap, opportunityLeadMap);
        // added as a part of story STY-02090
        setContactAsPrimary(accountId);
        if (convertedOpportunityIdsSet.size() > 0) {
            defaultOpportunityFields(convertedOpportunityIdsSet);
        }
        
        if (nurturingLeadList.size() > 0) {
            createTasks(nurturingLeadList, leadOldMap);
        }
      if(leadToUpdate != null){
          updateSkipValidationFlag(leadToUpdate);
      }
      if(childList != null){
          updateChildLeadOwner(childList);
      }
        //for tracking history - defect DF-00972
        if(leadNewMap.size() > 0 && !test.isRunningTest()){
            NSP_SObjectHistoryTrackingHelper objectFieldHistoryHelper = new NSP_SObjectHistoryTrackingHelper((Map<Id, sObject>)leadNewMap, (Map<Id, sObject>)leadOldMap);
            If( Limits.getQueueableJobs() != Limits.getLimitQueueableJobs()) {
                System.enqueueJob(objectFieldHistoryHelper);  
            }
        }
    }
    
    /**
* Stamps Parent lead owner on child leads
* @param newList List of New leads. 
* @return void             
*                
*/
  public void updateChildLeadOwner(Lead leadObject) {
      //iterating over new lead records
      List <Lead> parentToUpdate = new List <Lead>();
      AggregateResult[]  groupedResults =  [SELECT COUNT(Id) FROM Lead where NSP_Parent_Lead__c =:leadObject.Id]; 

      if(groupedResults != null && !groupedResults.isEmpty()) {
        List < Lead > leadResult = [SELECT Id, OwnerId FROM Lead WHERE NSP_Parent_Lead__c != null AND NSP_Parent_Lead__c = : leadObject.Id];
        if (!leadResult.isempty()) {
            for (Lead dunsLead: leadResult) {
                dunsLead.NSP_Skip_Validation__c = true;
                dunsLead.ownerId = leadObject.OwnerId;
                parentToUpdate.add(dunsLead);
            }
        }
        try {
            if(parentToUpdate != null && parentToUpdate.size() > 0) {
                update parentToUpdate;
            }
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_LeadTriggerHelper', 'updateChildLeadOwner', ex.getMessage());
        }
      }
      
  }
  
  /**
* Stamps Parent lead owner on child leads
* @param newList List of New leads. 
* @return void             
*                
*/
  public void updateSkipValidationFlag(Lead leadToUpdate) {
      //updating the child leads
      try {
          if(leadToUpdate != null) {
              update leadToUpdate;
          }
      } catch (Exception ex) {
          NSP_ErrorLogHandler.logSaveException('NSP_LeadTriggerHelper', 'updateSkipValidationFlag', ex.getMessage());
      }
  }   
  
  /**
* Stamps partner email on lead record
* @param newList List of New leads. 
* @param acctIdSet set of account ids. 
* @return void             
*                
*/
    public void putPartnerEmailOnLead(List < Lead > newList, Set < String > accountIdSet) {
        //map to store account id and primary contact's email
        Map < String, String > mapAccountsPrimaryContact = new Map < String, String > ();
        //Iterating over ACR obejct based on the account ids
        for (AccountContactRelation acrObject: [SELECT id, contact.email, accountid FROM AccountContactRelation WHERE NSP_Is_Primary__c = True
                                                AND accountid in: accountIdSet
                                               ]) {
                                                   //populating map with account ids and primary contact email
                                                   mapAccountsPrimaryContact.put(acrObject.accountid, acrObject.contact.email);
                                               }
        
        for (Lead leadObject: newList) {
            if (mapAccountsPrimaryContact.containskey(leadObject.NSP_Partner__c)) {
                //stamping partner's primary contact email on lead records
                leadObject.NSP_Partner_Email__c = mapAccountsPrimaryContact.get(leadObject.NSP_Partner__c);
            }
        }
    }
    
    /**
* Stamps set leads stage to MPL 
* @param newList List of New leads. 
* @param leadOldMap Map of old leads
* @return void             
*                
*/
    public void setLeadStageToMarketingPriortisedLead(List < Lead > newList, Map < Id, Lead > leadOldMap) {
        //iterating over new lead records
        for (Lead leadObject: newList) {
            if (!(leadOldMap.get(leadObject.id).NSP_Lead_Stage__c).equals(NSP_SalesConstants.LEAD_STAGE_SRL)) {
                leadObject.NSP_Lead_Stage__c = NSP_SalesConstants.LEAD_STAGE_MPL;
            }
        }
    }
    
    /**
* Assigns the leads to the Mid Market Queue 
* @param midMarketLead List of lead for Mid Market
* @return void             
*                
*/
    public void assignLeadToMidMarket(List < Lead > midMarketLead) {
        //Fetching the queue id for the mid market queue
        List < Group > midMarketQueue = [SELECT Id, DeveloperName, name FROM Group WHERE Type = 'Queue'
                                         AND DeveloperName =: System.label.NSP_DEVELOPERNAME_MIDMARKET
                                        ];
        List < String > zipBasedLocationList = new List < String > ();
        for (Lead leadObject: midMarketLead) {
            leadObject.OwnerId = midMarketQueue[0].id;
          leadObject.NSP_Lead_Routing__c = FALSE;
            leadObject.NSP_Zip_Based_Location__c = NSP_SalesConstants.MIDMARKETREGION;
            zipBasedLocationList.add(leadObject.NSP_Zip_Based_Location__c);
        }
        //get office assignment details for Mid Market queue
        if(midMarketLead != null && zipBasedLocationList !=null && !zipBasedLocationList.isEmpty())
            NSP_RoundRobinAssigner.getOfficeAssignmentDetails(midMarketLead, zipBasedLocationList, true);
    }
    /**
* Assigns the leads to the inBound Solutions Queue 
* @param inBoundSolutionsList List of lead for inBound Solutions 
* @return void 
*@CreatedDate: 1/19/2022
*@Story: DF-01009
*                
*/
    public void assignLeadToInboundSolutions(List<Lead> inBoundSolutionsList){   
        //Fetching the queue id for the inBound SolutionsQueue queue
        List<Group> inBoundSolutionsQueue = [SELECT Id,DeveloperName,name FROM Group WHERE Type = 'Queue' AND DeveloperName = :System.label.NSP_DEVELOPERNAME_INBOUNDSOLUTIONS];
        for(Lead leadObject : inBoundSolutionsList){
            leadObject.OwnerId = inBoundSolutionsQueue[0].id;
          leadObject.NSP_Lead_Routing__c = FALSE;
        }
    }
    /**
* Assigns the leads to the Payroll/HCM  Queue 
* @param payrollHCMLead List of lead for Payroll/HCM
* @return void             
*                
*/
    public void assignLeadToPayrollHCM(List < Lead > payrollHCMLead) {
        List < Group > payrollHCMQueue = [SELECT Id, DeveloperName, name FROM Group WHERE Type = 'Queue'
                                          AND DeveloperName =: System.label.NSP_DEVELOPERNAME_PAYROLLHCM
                                         ];
        for (Lead leadObject: payrollHCMLead) {
            leadObject.OwnerId = payrollHCMQueue[0].id;
          leadObject.NSP_Lead_Routing__c = FALSE;
            
        }
        
    }
    /**
* Assigns the leads to the respective National Account Queues 
* @param nationalAccountLeadList List of lead related to National Account
* @return void             
*                
*/
    public void assignLeadToNationalAccountQueue(List < Lead > nationalAccountLeadList) {
        //Splitting the stirng to create a list 
        List < String > nationalAccountList = Label.NSP_National_Accounts.split(',');
        //Query to fetch the correct queue name
        List < Group > nationalAccountQueues = [SELECT Id, DeveloperName, name FROM Group WHERE Type = 'Queue'
                                                AND Name in: nationalAccountList
                                               ];
        
        //Iterating over the lead records to assign lead owner
        for (Lead leadObject: nationalAccountLeadList) {
            
            for (Group grpObject: nationalAccountQueues) {
                if (leadObject.Company.equalsIgnoreCase(grpObject.Name)) {
                    //Assigning queue as the lead owner
                    leadObject.OwnerId = grpObject.id;
                  leadObject.NSP_Lead_Routing__c = FALSE;
                }
            }
        }
    }

    //
    // Stamps Lead region on lead based on zip code
    // @param zipCodeList List of zip code on lead.
    // @param leadsForRoundRobin List of leads that will fo for round robin
    // @return void
    //
    public void setLeadRegion( List<String> zipCodeList , List<Lead> leadsForRoundRobin , Boolean isOwnerAssignment ) {
        // build a list of Lead that qualify for Round Robin assignment...
        List<Lead> finalRoundRobinList = new List<Lead>();
        // build a list of zip codes used by the qualified Lead records...
        List<String> zipBasedLocationList = new List<String>();
        // build a translation map from 5-digit zip codes to location names... 
        Map<String,String> zipMap = this.buildZipCodeLocationNameMap( zipCodeList );
        if ( zipMap != null ) {
            for ( Lead leadObj : leadsForRoundRobin ) {
                // determine if a zip code is present on Lead and in the translation map...
                String zipcode = this.getRecordZipCode( leadObj );
                if ( String.isNotBlank( zipcode )
                    && zipMap.containsKey( zipcode )
                   )
                {
                    // Lead qualifies for Round Robin assignment...
                    leadObj.NSP_Zip_Based_Location__c = zipMap.get( zipcode );
                    zipBasedLocationList.add( zipMap.get( zipcode ) );
                    finalRoundRobinList.add( leadObj );
                }
            }
        }
        // call method for round robin assignment
        if ( ( finalRoundRobinList != null )
            && !finalRoundRobinList.isEmpty()
            && ( zipBasedLocationList != null )
            && !zipBasedLocationList.isEmpty()
           )
        {
            NSP_RoundRobinAssigner.getOfficeAssignmentDetails(
                finalRoundRobinList ,
                zipBasedLocationList ,
                isOwnerAssignment
            );
        }
    }

    // build a map from 5-digit zip codes to location names... 
    private Map<String,String> buildZipCodeLocationNameMap( List<String> zipcodes ) {
        List<NSP_Zip_To_City_Mapping__c> records = [
            SELECT NSP_Zip__c , NSP_Location_Name__c
            FROM NSP_Zip_To_City_Mapping__c
            WHERE NSP_Zip__c IN :zipcodes
        ];
        Map<String,String> zipCodeLocationNameMap = new Map<String,String>();
        for ( NSP_Zip_To_City_Mapping__c record : records ) {
            zipCodeLocationNameMap.put(
                String.valueof( record.NSP_Zip__c ) ,
                record.NSP_Location_Name__c
            );
        }
        return zipCodeLocationNameMap;
    }

    // extract 5-digit zip code from Lead record...
    private String getRecordZipCode( Lead record ) {
        String zipcode = null;
        if ( ( record != null )
            && String.isNotBlank( record.PostalCode )
            )
        {
            zipcode = record.PostalCode;
            if ( zipcode.length() >= 5 ) {
                zipcode = zipcode.substring( 0 , 5 );
            }
        }
        return zipcode;
    }

    /**
* Marks the contact which refered the lead as COI on the converted Account 
* @param leadList List of lead. 
* @return void             
*                
*/
    
    public void setContactasCOI(Map < String, Lead > accountLeadMap, Map < String, Lead > opportunityLeadMap) {
         
        List < AccountContactRelation > acrList = new List < AccountContactRelation > ();
        List < OpportunityContactRole > ocrList = new List < OpportunityContactRole > ();
        for (String accntID: accountLeadMap.keyset()) {
            Lead leadObject = accountLeadMap.get(accntID);
            AccountContactRelation acrObject = new AccountContactRelation();
            acrObject.AccountId = accntID;
            acrObject.ContactId = leadObject.NSP_Referred_By_COI__c;
            acrObject.Roles = leadObject.NSP_Referral_Source__c;
            acrObject.NSP_isReferral__c = true;
			acrObject.NSP_Nonprofit_Organization_Name__c = leadObject.NSP_Nonprofit_Organization_Name__c;
            acrObject.NSP_Nonprofit_Organization_Tax_Id__c = leadObject.NSP_Nonprofit_Organization_Tax_Id__c;
            acrObject.NSP_Referralbenefitsanonprofitorg__c = leadObject.NSP_Referralbenefitsanonprofitorg__c;
            acrList.add(acrObject);
        }
        for (String opportunityId: opportunityLeadMap.keySet()) {
            Lead leadObject = opportunityLeadMap.get(opportunityId);
            OpportunityContactRole ocrObject = new OpportunityContactRole();
            ocrObject.OpportunityId = leadObject.convertedOpportunityId;
            ocrObject.ContactId = leadObject.NSP_Referred_By_COI__c;
            ocrObject.Role = leadObject.NSP_Referral_Source__c;
            ocrObject.NSP_isReferral__c = true;
			ocrObject.NSP_Nonprofit_Organization_Name__c = leadObject.NSP_Nonprofit_Organization_Name__c;
            ocrObject.NSP_Nonprofit_Organization_Tax_Id__c = leadObject.NSP_Nonprofit_Organization_Tax_Id__c;
            ocrObject.NSP_Referralbenefitsanonprofitorg__c = leadObject.NSP_Referralbenefitsanonprofitorg__c;   
                                                          
            ocrList.add(ocrObject);
        }
        try {
            if(acrList.size() > 0){
                insert acrList;
            }
            if(ocrList.size() > 0){
                insert ocrList;
            }
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_LeadTriggerHelper', 'setContactasCOI', ex.getMessage());
        }
    }
    
    /**
* This method accepts all oppportunity Ids during lead conversion and defaults the
* Opportunity fields 
* @param convertedOpportunityIdsSet
* @return void                
*/
    public void defaultOpportunityFields(Set < Id > convertedOpportunityIdsSet) {
        //fetch all opportunities where Type value is Blank
        List < Opportunity > opportunityList = [SELECT Id, Type, NSP_AddonType__c FROM Opportunity WHERE Id IN: convertedOpportunityIdsSet];
        
        for (Opportunity opportunityObject: opportunityList) {
            
            //when new opportunity is created during lead conversion, Oppty.Type field will be blank
            if (String.isBlank(opportunityObject.Type) || opportunityObject.Type == null) {
                opportunityObject.Type = NSP_SalesConstants.NEW_BUSINESS_OPPORTUNITY;
                //default opportunity closed date to 30 days from today i.e oppty created date
                opportunityObject.CloseDate = System.today().addDays(30);
            }
        }
        
        if (opportunityList.size() > 0) {
            update opportunityList;
        }
    }
    
    /*
* Method accepts all Leads that are in nurturing or Unqualified state and 
* creates a task assined to Lead owner
* @param List<Lead> newLeadList
* @return void
*/
    public static void createTasks(List < Lead > newLeadList, Map < Id, Lead > leadOldMap) {
        List < Task > tasksList = new List < Task > ();
        List < Lead > regenValueUpdateList = new List < Lead > ();
        //map to store Lead Id and Call back task
        Map < Id, Task > leadIdTaskMap = new Map < Id, Task > ();
        for (Lead leadRecord: newLeadList) {
            if (!reasonNurturingReasonsList.contains(leadOldMap.get(leadRecord.Id).NSP_Reason__c)) {
                
                Task taskRecord = new Task();
                if(leadRecord.NSP_Reason__c != null){
                    String addMonthsValue = leadRecord.NSP_Reason__c.replaceAll('[^0-9]', '');
                    taskRecord.Subject = leadRecord.NSP_Reason__c;
                    taskRecord.OwnerId = leadRecord.OwnerId;
                    taskRecord.WhoId = leadRecord.Id;
                    taskRecord.Type = NSP_SalesConstants.CALL_BACK_TASK;
                    taskRecord.ActivityDate = System.today().addMonths(Integer.valueOf(addMonthsValue));
                    tasksList.add(taskRecord);
                }
            } else {
                regenValueUpdateList.add(leadRecord);
            }
        }
        
        /*if(tasksList.size() > 0) {
insert tasksList;
}*/
        
        //code to handle if the regen value is changed in Reason field eg
        //value changed from too early, 18 months to too early, 12 months
        if (regenValueUpdateList.size() > 0) {
            
            List < Task > tasksToUpdate = [SELECT Id, WhoId, ActivityDate, Type, CreatedDate, Subject FROM Task WHERE WhoId IN: regenValueUpdateList AND Subject IN: reasonNurturingReasonsList];
            
            for (Task taskRecord: tasksToUpdate) {
                leadIdTaskMap.put(taskRecord.WhoId, taskRecord);
            }
            
            for (Lead leadRecord: regenValueUpdateList) {
                if(leadRecord.NSP_Reason__c != null) {
                    String addMonthsValue = leadRecord.NSP_Reason__c.replaceAll('[^0-9]', '');
                    DateTime dt = leadIdTaskMap.get(leadRecord.Id).CreatedDate.addMonths(Integer.valueOf(addMonthsValue));
                    leadIdTaskMap.get(leadRecord.Id).Subject = leadRecord.NSP_Reason__c;
                    leadIdTaskMap.get(leadRecord.Id).ActivityDate = Date.newInstance(dt.year(), dt.month(), dt.day());
                    tasksList.add(leadIdTaskMap.get(leadRecord.Id));
                }
            }
        }
        
        try {
            if(tasksList.Size() > 0){
                upsert tasksList;
            }
        } catch (Exception ex) {
            NSP_CustomException.LogException(ex);
        }
    }
    
    /**
* Based on the number of employees, Account segmentation field is populated.
* @return void
*/
    public static void updateAccountSegment(Lead leadObject) {
        if (leadObject.NumberOfEmployees > Integer.valueOf(System.Label.NSP_MidMarket_Threshold)) {
            leadObject.NSP_Account_Segment__c = System.Label.NSP_Account_Segment_MidMarket;
        } else if (leadObject.NumberOfEmployees > Integer.valueOf(System.Label.NSP_Emerging_Growth_Threshold_Employees) &&
                   leadObject.NumberOfEmployees <= Integer.valueOf(System.Label.NSP_MidMarket_Threshold)) {
                       leadObject.NSP_Account_Segment__c = System.Label.NSP_Account_Segment_Emerging_Growth;
        } else if(leadObject.NumberOfEmployees!=null &&  leadObject.NumberOfEmployees>0 ){ // Modified as a part of Defect No:DF-01659
                       leadObject.NSP_Account_Segment__c = System.Label.NSP_Account_Segment_Core_Sales;
        }else if(leadObject.NumberOfEmployees==null || leadObject.NumberOfEmployees==0 ){   // added as a part of Defect No:DF-01659
                       leadObject.NSP_Account_Segment__c = null;
                   }
    }

    public void restrictDelete( List<Lead> records , Map<Id,Lead> deprecated ) {
        if ( ( records != null ) && !records.isEmpty() ) {
            Boolean hasPermissionDelete = CustomPermissionController.checkUserPermission(
                'Allow_Delete_Leads' ,
                UserInfo.getUserId()
            );
            if ( !hasPermissionDelete ) {
                for ( Lead record : records ) {
                    record.addError( System.Label.CANNOT_DELETE_LEAD );
                }
            }
        }
    }

    // * Prevents Lead duplicate based on email address and OneTrust Opt-out
    // * Matt McNeese      04/28/2023           AZD Story 212804
    public void preventOneTrustDupe(Lead leadObject) {
        List <Contact> contactOneTrustDupe = [SELECT Id, OneTrust_Opt_Out__c, Email FROM Contact WHERE OneTrust_Opt_Out__c = true
                                              AND Email != null AND Email = :leadObject.Email LIMIT 1];
        List <Lead> leadOneTrustDupe = [SELECT Id, OneTrust_Opt_Out__c, Email FROM Lead WHERE OneTrust_Opt_Out__c = true
                                        AND Email != null AND Email = :leadObject.Email LIMIT 1];
        if(contactOneTrustDupe.size() > 0 || leadOneTrustDupe.size() > 0) leadObject.addError(System.Label.NSP_OneTrustDupeError);
    }
    
    
/**
* Method added for CR-027 
* @param leadObject Current Lead Object Data. 
* @return void  
*/
public Boolean dunsCheck(Lead leadObject) {
    List < String > zipCodeList = new List < String > ();
    List < Lead > leadsForRoundRobin = new List < Lead > ();
    Boolean isOwnerUpdated = false;
    if (leadObject.DNB_Connect_DUNS_Number__c != null && leadObject.NSP_Lead_Routing__c == true) {
            List < Account > accResult = [SELECT Id, OwnerId, Owner.Name, Owner.UserRole.Name, NSP_Account_Status__c FROM Account WHERE DNB_Connect_DUNS_Number__c != null AND DNB_Connect_DUNS_Number__c =: leadObject.DNB_Connect_DUNS_Number__c];
            if (accResult.size() == 1) {
                for (Account dunsAcc: accResult) {
                  if (dunsAcc.NSP_Account_Status__c == NSP_SalesConstants.INACTIVE && dunsAcc.Owner.UserRole != null &&
                      (dunsAcc.Owner.UserRole.Name == System.Label.NSP_PartnerAccountRoles || dunsAcc.Owner.UserRole.Name == NSP_SalesConstants.BPC_USER)) {
                        leadObject.OwnerId = dunsAcc.OwnerId;
              leadObject.NSP_Lead_Routing__c = FALSE;
                        isOwnerUpdated = true;
                    }
                    if (dunsAcc.NSP_Account_Status__c != NSP_SalesConstants.INACTIVE) {
                        leadObject.OwnerId = dunsAcc.OwnerId;
              leadObject.NSP_Lead_Routing__c = FALSE;
                        isOwnerUpdated = true;
                    }
                }
            }
          else if (accResult.isEmpty()) {
              List < Lead > leadResult = [SELECT Id, OwnerId FROM Lead WHERE DNB_Connect_DUNS_Number__c != null AND DNB_Connect_DUNS_Number__c = : leadObject.DNB_Connect_DUNS_Number__c AND NSP_Parent_Lead__c = NULL AND id != : leadObject.id];
              if (leadResult.size() == 1) {
                  for (Lead dunsLead: leadResult) {
                      leadObject.NSP_Parent_Lead__c = dunsLead.Id;
                      leadObject.NSP_Skip_Validation__c= true;  
                      leadObject.OwnerId = dunsLead.OwnerId;
                      leadObject.NSP_Lead_Routing__c = FALSE;
                      isOwnerUpdated = true;
                  }
              } 
            
        } else {
            isOwnerUpdated = false;
        }
    }
    return isOwnerUpdated;
}
/**
* Method Name : createContact 
* Description : Method to create Contact on Lead Conversion
* Author : Date : 11/03/2022
* @param newContactList.  
* @return void  
*/
public void createContact(List < Lead > newLeadList) {
    Map < Id, Lead > parentMap = new Map < Id, Lead > ();
    Map < Id, Lead > childMap = new Map < Id, Lead > ();
    Map < Id, Id > mapLead = new Map < Id, Id > ();
    List < String > allLeadList = new List < String > ();
    List < Task > linkTaskList = new List < Task > ();
    List < Event > linkEventList = new List < Event > ();
    List < Lead > parentResult = new List < Lead > ();
    List < Lead > childResult = new List < Lead > ();
    Set < Id > taskIdSet = new Set < Id > ();
    Set < Id > eventIdSet = new Set < Id > ();
    String convertedOpty;
    String accountId;
    Id child;
      Id parent;
    List < Database.LeadConvert > MassLeadconvert = new List < Database.LeadConvert > ();
      
    for (Lead newLead: newLeadList) {
        if (newLead.IsConverted && newLead.NSP_Parent_Lead__c == null && newLead.ConvertedOpportunityId != null) {
            parentMap.put(newLead.Id, newLead);
        } else if (newLead.IsConverted && newLead.NSP_Parent_Lead__c != null && newLead.ConvertedOpportunityId != null) {
            childMap.put(newLead.Id, newLead);
            allLeadList.add(newLead.DNB_Connect_DUNS_Number__c);
            child = newLead.Id;
              parent = newLead.NSP_Parent_Lead__c;
            convertedOpty = newLead.ConvertedOpportunityId;
            accountId = newLead.ConvertedAccountId;
        }
    }
      
    if (parentMap != null && !parentMap.isEmpty()) {
          parentResult = [SELECT Id, Salutation, FirstName, MiddleName, LastName, Suffix, IsConverted, NSP_Parent_Lead__c, NSP_Parent_Lead__r.Status FROM Lead WHERE NSP_Parent_Lead__c IN: parentMap.keySet()];
    } else if (childMap != null && !childMap.isEmpty()) {
          childResult = [SELECT Id, Salutation, FirstName, MiddleName, LastName, Suffix, IsConverted, NSP_Parent_Lead__c, DNB_Connect_DUNS_Number__c FROM Lead WHERE ((DNB_Connect_DUNS_Number__c != null AND DNB_Connect_DUNS_Number__c IN: allLeadList) OR (DNB_Connect_DUNS_Number__c = null AND ((NSP_Parent_Lead__c = :parent) OR (Id = :parent))))  AND Id != : child];
    }
    if (parentResult != null && !parentResult.isEmpty()) {
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        for (Lead childLead: parentResult) {
            Database.LeadConvert lc = new Database.LeadConvert();
            if (!childLead.IsConverted) {
                taskIdSet.add(childLead.Id);
                  if (parentMap != null && !parentMap.isEmpty() && parentMap.get(childLead.NSP_Parent_Lead__c) != null && parentMap.get(childLead.NSP_Parent_Lead__c).ConvertedOpportunityId != null) mapLead.put(childLead.Id, parentMap.get(childLead.NSP_Parent_Lead__c).ConvertedOpportunityId);
                lc.setLeadId(childLead.id);
                lc.setAccountId(parentMap.get(childLead.NSP_Parent_Lead__c).ConvertedAccountId);
                lc.setOwnerId(userinfo.getUserId());
                lc.setDoNotCreateOpportunity(TRUE);
                lc.setConvertedStatus(convertStatus.MasterLabel);
                MassLeadconvert.add(lc);
            }
        }
    }
    if (childResult !=null && !childResult.isEmpty()) {
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        for (Lead childLead: childResult) {
            Database.LeadConvert lc = new Database.LeadConvert();
            if (childLead.IsConverted == false) {
                taskIdSet.add(childLead.Id);
                if (convertedOpty != null) mapLead.put(childLead.Id, convertedOpty);
                lc.setLeadId(childLead.id);
                lc.setAccountId(accountId);
                lc.setOwnerId(userinfo.getUserId());
                lc.setDoNotCreateOpportunity(TRUE);
                lc.setConvertedStatus(convertStatus.MasterLabel);
                MassLeadconvert.add(lc);
            }
        }
    }
    if (mapLead != null && !mapLead.isEmpty()) {
        List < Task > taskList = [SELECT Id, WhatId, WhoId FROM Task WHERE WhoId IN: mapLead.keySet()];
        List < Event > eventList = [SELECT Id, WhatId, WhoId FROM Event WHERE WhoId IN: mapLead.keySet()];
        if (taskList !=null && !taskList.isEmpty()) {
            for (Task taskObj: taskList) {
                taskObj.WhatId = mapLead.get(taskObj.WhoId);
                taskObj.WhoId = null;
                linkTaskList.add(taskObj);
            }
        }
        if (eventList !=null && !eventList.isEmpty()) {
            for (Event eventObj: eventList) {
                eventObj.WhatId = mapLead.get(eventObj.WhoId);
                eventObj.WhoId = null;
                linkEventList.add(eventObj);
            }
        }
    }
    try {
        if (!MassLeadconvert.isEmpty()) {
            List < Database.LeadConvertResult > lcr = Database.convertLead(MassLeadconvert);
        }
          if (linkTaskList != null && !linkTaskList.isEmpty()) {
            update linkTaskList;
        }
          if (linkEventList != null && !linkEventList.isEmpty()) {
            update linkEventList;
        }
    } catch (Exception ex) {
        NSP_ErrorLogHandler.logSaveException('NSP_LeadTriggerHelper', 'createContact', ex.getMessage());
    }
}

    
/**
* @MethodName: setContactAsPrimary
* @Description: Marks the converted contact as Primary Contact  ,added as a part of story STY-02090 
* @param Map<Id,Id> AccountContactMap. 
* @return void             
* @author : Nischay Jindal  
*-----------------------------------------------------------------------------------
Modified History: Name : Description : date
				 Mani Teja : Commented the If condition as we do not require it anymore and moved to future to avoid soql 101. : 3/31/2023
------------------------------------------------------------------------------------  
*           
*/
    @future
    public static void setContactAsPrimary( Set<Id> AccountIds) {
        try{
            Set < Id > AccountId = new Set < Id > ();
            List<AccountContactRelation >acrList = new List<AccountContactRelation >();
            Map<Id,Contact> accountContactMap= new Map<Id,Contact>([Select Id,AccountId from Contact WHERE AccountId IN:AccountIds]);
            // checking for the existing Primary ACR associated with the account 
            List < AccountContactRelation > accountContactRelationLists = [SELECT Id  ,NSP_Is_Primary__c, AccountId from AccountContactRelation WHERE  AccountId IN: AccountIds And NSP_Is_Primary__c=true ];
            if(!accountContactRelationLists.isEmpty()){
                for(AccountContactRelation acr:accountContactRelationLists){
                    AccountId.add(acr.AccountId);
                }
            } 
            else if(accountContactRelationLists.isEmpty() ){
                acrList = [SELECT Id  ,NSP_Is_Primary__c, ContactId,AccountId from AccountContactRelation WHERE  ContactId IN: accountContactMap.KeySet() ];
                List<AccountContactRelation> UpdatedacrList= new List<AccountContactRelation>();
                for (AccountContactRelation Acr: acrList) {
                    if(!AccountId.contains(Acr.AccountId)){
                        AccountContactRelation acRecord= new AccountContactRelation();
                        AccountId.add(Acr.AccountId);
                        acRecord.Id= Acr.Id;
                        acRecord.NSP_Is_Primary__c = true;
                        // Added as part of DF-01654
                        /*if(!accountLeadMap.isEmpty()){
                        Lead leadObject = accountLeadMap.get(Acr.AccountId); removed based on STY-03346
                        acRecord.NSP_Nonprofit_Organization_Name__c = leadObject.NSP_Nonprofit_Organization_Name__c;
                        acRecord.NSP_Nonprofit_Organization_Tax_Id__c = leadObject.NSP_Nonprofit_Organization_Tax_Id__c;
                        acRecord.NSP_Referralbenefitsanonprofitorg__c = leadObject.NSP_Referralbenefitsanonprofitorg__c; 
                    }*/
                        UpdatedacrList.add(acRecord);  
                    }
                }
                if(!UpdatedacrList.isEmpty()){
                    Database.Update(UpdatedacrList, false);
                }
            }
            NSP_OpportunityTriggerHelperFunctions.getAccountOwnerEmail(AccountId);
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_LeadTriggerHelper', 'setContactAsPrimary', ex.getMessage());
        }
        
    }
     /**
* @MethodName: updateNonProfitOrgFields
* @Description: When Referral Lead is converted update Non Profit Organisation fields
* @param Map<Id,Id> opportunityLeadMap. 
* @Defect : DF-01654 removed for STY-03346
* @return void                          
*/
    /*public void updateNonProfitOrgFields(Map < String, Lead > opportunityLeadMap) {
        List<OpportunityContactRole> oppConRoleList = new List<OpportunityContactRole>();
        try{
            for (OpportunityContactRole oppConRole : [SELECT Id, 
                                                      OpportunityId, 
                                                      ContactId, 
                                                      IsPrimary,
                                                      NSP_Nonprofit_Organization_Name__c,
                                                      NSP_Nonprofit_Organization_Tax_Id__c, 
                                                      NSP_Referralbenefitsanonprofitorg__c 
                                                      FROM OpportunityContactRole
                                                      WHERE OpportunityId IN: opportunityLeadMap.keySet() 
                                                      AND IsPrimary = true]) {
                                                          Lead leadObject = opportunityLeadMap.get(oppConRole.opportunityId);
                                                          oppConRole.NSP_Nonprofit_Organization_Name__c = leadObject.NSP_Nonprofit_Organization_Name__c;
                                                          oppConRole.NSP_Nonprofit_Organization_Tax_Id__c = leadObject.NSP_Nonprofit_Organization_Tax_Id__c;
                                                          oppConRole.NSP_Referralbenefitsanonprofitorg__c = leadObject.NSP_Referralbenefitsanonprofitorg__c;   
                                                          oppConRoleList.add(oppConRole);
                                                      }
            if(!oppConRoleList.isEmpty()){
                Database.update(oppConRoleList, false);
            }
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_LeadTriggerHelper', 'updateNonProfitOrgFields', ex.getMessage());
        }
    }*/
   
    /* Description: This method sets sales office details from user 
     * 
     * @param: leadList, leadMap
     * @return: void
     * Modification History:
     * -------------------------------------------------------------------------------------
     *  Date              | Description
     * -------------------------------------------------------------------------------------
     *  08/05/2022          created this new method added for STY-03154
     * 
     * 
    */
    
    public void setSalesOfficeDetails(List<Lead> newList,Map<Id, Lead> leadOldMap) {

        set<Id> ownerIdSet = new set<Id>();
        set<string> officeSet = new set<string>(); // sales office set
        set<Id> recordToOwnerProcess = new set<Id>();  // record to be process set
        set<Id> recordToOfficeProcess = new set<Id>();  // record to be process set
        map<String,NSP_Sales_Office_Mapping__c> salesOfficeToMappingMap =  new map<String,NSP_Sales_Office_Mapping__c>();
        Map<Id,User> userIdMap;
        
        for(Lead newLead: newList) {
            Lead oldLead = leadOldMap != null ? leadOldMap.get(newLead.Id):null;
            if(Trigger.isInsert)
            {
                if(String.isNotBlank(newLead.NSP_Sales_Office__c))
                {
                    officeSet.add(newLead.NSP_Sales_Office__c);
                }
                else if(newLead.OwnerId != null)
                {
                    ownerIdSet.add(newLead.OwnerId);
                }
            }
            else if(Trigger.isUpdate && newLead.OwnerId != oldLead.OwnerId && newLead.OwnerId != null)
            {
                recordToOwnerProcess.add(newLead.Id);
                ownerIdSet.add(newLead.OwnerId);
            }
            else if(Trigger.isUpdate && newLead.NSP_Sales_Office__c != oldLead.NSP_Sales_Office__c && String.isNotBlank(newLead.NSP_Sales_Office__c))
            {
                recordToOfficeProcess.add(newLead.Id);
                officeSet.add(newLead.NSP_Sales_Office__c);
            }
        }
        
        if(ownerIdSet.Size() > 0) {
            userIdMap = new Map<Id,User>([SELECT Id,NSP_SalesDivision__c,NSP_Sales_Office__c,NSP_SalesRegion__c from user where Id In :ownerIdSet AND NSP_Sales_Office__c != null ]);
            
        }
        
        // values assigned from sales office mapping
        if(officeSet.Size() > 0) {
            for(NSP_Sales_Office_Mapping__c eachMapping : [SELECT Id,NSP_Sales_Office__c,NSP_Sales_Division__c,NSP_Sales_Region__c 
                                                            FROM NSP_Sales_Office_Mapping__c 
                                                            WHERE NSP_Sales_Office__c In : officeSet AND isActive__c = true])
            {
                salesOfficeToMappingMap.put(eachMapping.NSP_Sales_Office__c,eachMapping);
            }
        }
        
        
        for(Lead newLead: newList)
        {
            if( (Trigger.isInsert || recordToOfficeProcess.contains(newLead.Id)) &&  String.isNotBlank(newLead.NSP_Sales_Office__c) && salesOfficeToMappingMap.containsKey(newLead.NSP_Sales_Office__c))
            {
                NSP_Sales_Office_Mapping__c officeMapping = salesOfficeToMappingMap.get(newLead.NSP_Sales_Office__c);
                newLead.NSP_Sales_Region__c = officeMapping.NSP_Sales_Region__c; // sales region
                newLead.NSP_Sales_Division__c = officeMapping.NSP_Sales_Division__c; // sales division
            }
            else if((Trigger.isInsert || recordToOwnerProcess.contains(newLead.Id)) && newLead.OwnerId != null && userIdMap!= null && userIdMap.containsKey(newLead.OwnerId))
            {
                user eachUser = userIdMap.get(newLead.OwnerId);
                newLead.NSP_Sales_Region__c = eachUser.NSP_SalesRegion__c;  // sales region
                newLead.NSP_Sales_Division__c = eachUser.NSP_SalesDivision__c; // sales division
                newLead.NSP_Sales_Office__c = eachUser.NSP_Sales_Office__c; // sales office
            }
        }
    }
   
}