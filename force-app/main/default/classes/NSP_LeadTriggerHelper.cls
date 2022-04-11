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
    
    public static final List < String > reasonNurturingReasonsList = System.label.NSP_Lead_at_Nurturing_or_Unqualified.split(';');
    private static final string NEW_LEAD_RT = 'NSP_New_Lead_Record_Type';
    private static final string LEAD_RT = 'Lead';
    private static final Id NEW_LEAD_RT_ID = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(NEW_LEAD_RT).getRecordTypeId();
    private static final Id LEAD_RT_ID = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(LEAD_RT).getRecordTypeId();
    private static final string SYS_ADMIN = 'System Administrator';
    // Added as part of DF-01009
    private static final string REFERRAL_RECORDTYPE = 'Referral';
    private static final Id REFERRAL_RECORDTYPE_ID = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(REFERRAL_RECORDTYPE).getRecordTypeId();
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
        //Iterating over the new lead list(trigger.new)
        for (Lead leadObject: newList) {
            updateAccountSegment(leadObject);
            dunsCheck(leadObject);
            
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
            
            //If FireScore is greater than FIRE_SCORE_THRESH setting lead stage to MPL
            if (null != leadObject.nsp_fire_score__c && leadObject.nsp_fire_score__c > Integer.valueOf(System.label.NSP_FIRE_SCORE_THRESH)) {
                leadObject.NSP_Lead_Stage__c = NSP_SalesConstants.LEAD_STAGE_MPL;
            }
            
            /* As part of DF-00998 comments, While Creating Lead From ELoqua Integration user or From Referral Form, Lead should get assigned to Inbound solutions Queue */
            List < String > externalUsers = Label.NSP_External_Users.split(',');
            //Added as part of DF-00998
            String createdUserName = UserInfo.getFirstName();
            if (leadObject.RecordTypeId == REFERRAL_RECORDTYPE_ID || (String.isNotBlank(createdUserName) && externalUsers.contains(createdUserName))) {
                inboundSolutionsList.add(leadObject);
            }
            //change default 12 AM value of Discovery call set date to 12 PM.
            if (leadObject.NSP_DC_SetDate__c !=null) {
                leadObject.NSP_DC_SetDate__c += 1/2;
            }
            
        }
        //calling method to stmap primary contact's email from partner account to lead
        if (!accountIdSet.isEmpty()) {
            putPartnerEmailOnLead(newList, accountIdSet);
        }
        
        //Assigning to Inbound Solutions SalesQueue if the Lead is creating from Referral Form or Eloqua as per new Lead assignment rules.
        if(!inboundSolutionsList.isEmpty()){
            assignLeadToInboundSolutions(inboundSolutionsList);
        }
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
        /* Added as part of STY-01725 */
        List<String> inboundOrOutBoundUserList = Label.Inbound_and_Outbound_UserRole.split(',');
        /*********************/
        Set<String> salesOfficeSet=new Set<String>();
        Set<Id> ownerIdset = new Set<Id>();
        List<String> MMBSPUserList = Label.MM_AND_BPC_USERROLE.split(',');
        /*********************/
        
        User userDetails =[ SELECT Id, Name, UserRole.Name, Profile.Name FROM User WHERE Id =: userinfo.getUserId() ];
        /* Added as part of STY-01725 */
        //iterating over trigger.newmap
        for (Id leadId: leadNewMap.keySet()) {
            //checking if fire score is not null and fire score value has changed and fire score value is greater than FIRE_SCORE_THRESH
            if (leadNewMap.get(leadId).nsp_fire_score__c != null && leadNewMap.get(leadId).nsp_fire_score__c > Integer.valueOf(System.label.NSP_FIRE_SCORE_THRESH) &&
                leadNewMap.get(leadId).nsp_fire_score__c != leadOldMap.get(leadId).nsp_fire_score__c) {
                    //adding lead records to the list
                    fireScoreLeadList.add(leadNewMap.get(leadId));
                }
            /* Added as part of DF-01301 */
            if(trigger.isupdate && trigger.isbefore){
                //Current logged in user not equal to Owner and logged in user profile not sys admin 
                if(userDetails.Id!=leadOldMap.get(leadId).OwnerId && userDetails.Profile.Name!=SYS_ADMIN){
                    //Check logged in user role not in Mid Market/BPS 
                    if(!MMBSPUserList.contains(userDetails.UserRole.Name) ){
                        //Lead owner not a queue check
                        if(leadOldMap.get(leadId).OwnerId.getSObjectType() == User.SObjectType){
                            ownerIdset.add(leadOldMap.get(leadId).OwnerId);
                        }
                    }
                }
            }
            /* Added as part of CR-027 */
            if(leadNewMap.get(leadId).NSP_Parent_Lead__c != leadOldMap.get(leadId).NSP_Parent_Lead__c){
                List < Lead > leadResult = [SELECT Id, OwnerId FROM Lead WHERE id = :leadNewMap.get(leadId).NSP_Parent_Lead__c];
                if (!leadResult.isempty()) {
                    for (Lead dunsLead: leadResult) {
                        leadNewMap.get(leadId).OwnerId = dunsLead.OwnerId;
                        isOwnerUpdated = true;
                    }
                }
            } 
               if(leadNewMap.get(leadId).DNBoptimizer__DNB_D_U_N_S_Number__c != null && leadNewMap.get(leadId).NSP_Lead_Routing__c == true && isOwnerUpdated == false) {
                   isOwnerUpdated = dunsCheck(leadNewMap.get(leadId));
               }
            //change default 12 AM value of Discovery call set date to 12 PM.
            if (leadNewMap.get(leadId).NSP_DC_SetDate__c != leadOldMap.get(leadId).NSP_DC_SetDate__c && leadNewMap.get(leadId).NSP_DC_SetDate__c !=null) {
                leadNewMap.get(leadId).NSP_DC_SetDate__c += 1/2;
            }   
            /* Added as part of DF-01301 */
            
            /* As part of DF-00998 comments
* If the loggedIn user is either Inbound or Outbound and Assign Lead Checkbox is checked then only Lead assignment rule will trigger
* If the loggedIn user is not Inbound or Outbound solutions user, then No Lead assignment rules will trigger 
*/
if ((leadNewMap.get(leadId).NSP_Lead_Routing__c == true && 
 leadNewMap.get(leadId).DNBoptimizer__DNB_D_U_N_S_Number__c == null && 
 leadNewMap.get(leadId).NSP_Parent_Lead__c == null) || 
(leadNewMap.get(leadId).DNBoptimizer__DNB_D_U_N_S_Number__c != null && isOwnerUpdated == false && leadNewMap.get(leadId).NSP_Lead_Routing__c == true)) {
                    if (String.isnotBlank(leadNewMap.get(leadId).company) && nationalAccountList.contains(leadNewMap.get(leadId).company.toUppercase())) {
                        //If the Lead Company is associated with National Account, route the correct National Account Queue
                        nationalAccountLeadList.add(leadNewMap.get(leadId));
                    } else if (leadNewMap.get(leadId).NumberOfEmployees != null 
                                              && Integer.valueof(leadNewMap.get(leadId).NumberOfEmployees) >= Integer.valueOf(System.Label.NSP_EMP_THRESH_150)
                                              && leadNewMap.get(leadId).NSP_Product_Interest__c != null){
                                                  if (leadNewMap.get(leadId).NSP_Product_Interest__c.contains(System.label.NSP_PRODINT_FULL_SERVICE_HR)) {
                                                      /* If Emp >= 150 and Product of Interest is WO, then assign to mid market queue */
                                                      midMarketList.add(leadNewMap.get(leadId));
                                                  } else if (leadNewMap.get(leadId).NSP_Product_Interest__c.contains(String.valueOf(System.label.NSP_PRODINT_HCM))) {
                                                      /*If Emp >= 150 and Product of Interest is WX, then assign to payroll/HCM queue */
                                                      payrollHCMList.add(leadNewMap.get(leadId));
                                                  }
                                              } else if (String.isNotBlank(leadNewMap.get(leadId).PostalCode)
                                                     && (leadNewMap.get(leadId).NumberOfEmployees == null || Integer.valueof(leadNewMap.get(leadId).NumberOfEmployees) < Integer.valueOf(System.Label.NSP_EMP_THRESH_150))) {
                                                      /* If Postal Code is not blank, Number of Employees is null or < 150 and Product of interest is WO/WX assign to Sales office */
                                                      leadsForRoundRobin.add(leadNewMap.get(leadId));
                                                      zipCodeList.add(leadNewMap.get(leadId).PostalCode);
                                                  } 
                    else {
                        inboundSolutionsList.add(leadNewMap.get(leadId));
                    }      
                }
            
            //collect all Leads to change AccountSegment value based on number of employees
            if (leadNewMap.get(leadId).NumberOfEmployees != leadOldMap.get(leadId).NumberOfEmployees) {
                updateAccountSegment(leadNewMap.get(leadId));
            }
        }
        
        /* Added as part of DF-01301 */
        List<GroupMember> groupMemberList = new List<GroupMember>();
        if(ownerIdset != null){
            List<User> ownerIdList = [Select Id,ToLabel(NSP_Sales_Office__c) from User WHERE ID IN:ownerIdset];
            if(!ownerIdList.isEmpty()){
                for(User userList : ownerIdList){
                    if(userList.NSP_Sales_Office__c != Null){
                        salesOfficeSet.add(userList.NSP_Sales_Office__c);
                    }
                }
            }
            if(!salesOfficeSet.isEmpty()){
                groupMemberList =[SELECT Id, Group.Name, UserOrGroupId FROM GroupMember WHERE UserOrGroupId=: userinfo.getUserId() AND Group.Name IN :salesOfficeSet];
            }
            for (Id leadId: leadNewMap.keySet()) {
                if(trigger.isupdate && trigger.isbefore){
                    if(userDetails.Id!=leadOldMap.get(leadId).OwnerId && userDetails.Profile.Name!=SYS_ADMIN){
                        if(!MMBSPUserList.contains(userDetails.UserRole.Name) ){
                            if(leadOldMap.get(leadId).OwnerId.getSObjectType() == User.SObjectType){
                                if(groupMemberList.isEmpty()){
                                    leadNewMap.get(leadId).Id.addError(system.label.NSP_LeadTriggerError);  
                                    
                                }  
                            }
                        }
                    }
                }
            }
        }
        /* Added as part of DF-01301 */
        
        
        //calling method to set the lead stage as per the fire score
        if (!fireScoreLeadList.isEmpty()) {
            setLeadStageToMarketingPriortisedLead(fireScoreLeadList, leadOldMap);
        }
        //Roundrobin logic to assign leads to Sales Office
        if (!leadsForRoundRobin.isEmpty()) {
            system.debug('------> Leads for Roundrobin');
            setLeadRegion(zipCodeList, leadsForRoundRobin);
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
        Set<Id> accountId = new  Set<Id>();
        for (Lead leadObject: leadNewMap.values()) {
            if (leadObject.isconverted && String.isNotBlank(leadObject.convertedOpportunityId)) {
                convertedOpportunityIdsSet.add(leadObject.convertedOpportunityId);
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
        if(!opportunityLeadMap.isEmpty()){
            updateNonProfitOrgFields(opportunityLeadMap);
        }
        
        setContactasCOI(accountLeadMap, opportunityLeadMap);
        // added as a part of story STY-02090
        setContactAsPrimary(accountId, accountLeadMap);
        if (convertedOpportunityIdsSet.size() > 0) {
            defaultOpportunityFields(convertedOpportunityIdsSet);
        }
        
        if (nurturingLeadList.size() > 0) {
            createTasks(nurturingLeadList, leadOldMap);
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
            leadObject.Lead_Owner_Auto_Assignment__c = TRUE;
            leadObject.NSP_Zip_Based_Location__c = NSP_SalesConstants.MIDMARKETREGION;
            zipBasedLocationList.add(leadObject.NSP_Zip_Based_Location__c);
        }
        //get office assignment details for Mid Market queue
        if(midMarketLead != null && zipBasedLocationList !=null && !zipBasedLocationList.isEmpty())
            NSP_RoundRobinAssigner.getOfficeAssignmentDetails(midMarketLead, zipBasedLocationList);
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
            leadObject.Lead_Owner_Auto_Assignment__c = TRUE;
            
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
                    leadObject.Lead_Owner_Auto_Assignment__c = TRUE;
                }
            }
        }
    }
    
    /**
* Stamps Lead region on lead based on zip code 
* @param zipCodeList List of zip code on lead. 
* @param leadsForRoundRobin List of leads that will fo for round robin
* @return void             
*                
*/
    
    public void setLeadRegion(List < String > zipCodeList, List < Lead > leadsForRoundRobin) {
        //Get all the zip codes from zip tp city mapping custom setting
        Map < String, NSP_Zip_To_City_Mapping__c > zipMap = new Map < String, NSP_Zip_To_City_Mapping__c > ();
        //List of zip codes used by the lead records
        List < String > zipBasedLocationList = new List < String > ();
        List < Lead > finalRoundRobinList = new List < Lead > ();
        
        for (NSP_Zip_To_City_Mapping__c zipObj: [SELECT id, NSP_Zip__c, NSP_City__c, NSP_Location_Name__c, nsp_state__c,NSP_Sales_Office__c FROM NSP_Zip_To_City_Mapping__c WHERE NSP_Zip__c in: zipCodeList]) {
            zipMap.put(String.valueof(zipObj.NSP_Zip__c), zipObj);
        }
        for (Lead leadObj: leadsForRoundRobin) {
            //Checking if zip is present on lead or not
            if (zipMap.containsKey(leadObj.PostalCode)) {
                leadObj.NSP_Zip_Based_Location__c = zipMap.get(leadObj.PostalCode).NSP_Location_Name__c;
                zipBasedLocationList.add(zipMap.get(leadObj.PostalCode).NSP_Location_Name__c);
                finalRoundRobinList.add(leadObj);
            }
        }
        //calling method for round robin assignment
        if (finalRoundRobinList != null && !finalRoundRobinList.isEmpty() && zipBasedLocationList!=null && !zipBasedLocationList.isEmpty()) {
            NSP_RoundRobinAssigner.getOfficeAssignmentDetails(finalRoundRobinList, zipBasedLocationList);
        }
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
            acrList.add(acrObject);
        }
        for (String opportunityId: opportunityLeadMap.keySet()) {
            Lead leadObject = opportunityLeadMap.get(opportunityId);
            OpportunityContactRole ocrObject = new OpportunityContactRole();
            ocrObject.OpportunityId = leadObject.convertedOpportunityId;
            ocrObject.ContactId = leadObject.NSP_Referred_By_COI__c;
            ocrObject.Role = leadObject.NSP_Referral_Source__c;
            ocrObject.NSP_isReferral__c = true;
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
    
    /**
* Method added for CR-027 
* @param leadObject Current Lead Object Data. 
* @return void  
*/
public Boolean dunsCheck(Lead leadObject) {
    List < String > zipCodeList = new List < String > ();
    List < Lead > leadsForRoundRobin = new List < Lead > ();
    Boolean isOwnerUpdated = false;
    if (leadObject.DNBoptimizer__DNB_D_U_N_S_Number__c != null && leadObject.NSP_Lead_Routing__c == true) {
        List < Lead > leadResult = [SELECT Id, OwnerId FROM Lead WHERE DNBoptimizer__DNB_D_U_N_S_Number__c != null AND DNBoptimizer__DNB_D_U_N_S_Number__c =: leadObject.DNBoptimizer__DNB_D_U_N_S_Number__c AND NSP_Parent_Lead__c = NULL AND id !=: leadObject.id];
        if (leadResult.size() == 1) {
            for (Lead dunsLead: leadResult) {
                leadObject.NSP_Parent_Lead__c = dunsLead.Id;
                leadObject.OwnerId = dunsLead.OwnerId;
                isOwnerUpdated = true;
            }
        } else if (leadResult.isEmpty()) {
            List < Account > accResult = [SELECT Id, OwnerId, Owner.Name, Owner.UserRole.Name, NSP_Account_Status__c FROM Account WHERE DNBoptimizer__DNB_D_U_N_S_Number__c != null AND DNBoptimizer__DNB_D_U_N_S_Number__c =: leadObject.DNBoptimizer__DNB_D_U_N_S_Number__c];
            if (accResult.size() == 1) {
                for (Account dunsAcc: accResult) {
                    if (dunsAcc.NSP_Account_Status__c == NSP_SalesConstants.INACTIVE && (dunsAcc.Owner.UserRole.Name == System.Label.NSP_PartnerAccountRoles || dunsAcc.Owner.UserRole.Name == NSP_SalesConstants.BPC_USER)) {
                        leadObject.OwnerId = dunsAcc.OwnerId;
                        isOwnerUpdated = true;
                    }
                    if (dunsAcc.NSP_Account_Status__c != NSP_SalesConstants.INACTIVE) {
                        leadObject.OwnerId = dunsAcc.OwnerId;
                        isOwnerUpdated = true;
                    }
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
    List < Database.LeadConvert > MassLeadconvert = new List < Database.LeadConvert > ();
    for (Lead newLead: newLeadList) {
        if (newLead.IsConverted && newLead.NSP_Parent_Lead__c == null && newLead.ConvertedOpportunityId != null) {
            parentMap.put(newLead.Id, newLead);
        } else if (newLead.IsConverted && newLead.NSP_Parent_Lead__c != null && newLead.ConvertedOpportunityId != null) {
            childMap.put(newLead.Id, newLead);
            allLeadList.add(newLead.DNBoptimizer__DNB_D_U_N_S_Number__c);
            child = newLead.Id;
            convertedOpty = newLead.ConvertedOpportunityId;
            accountId = newLead.ConvertedAccountId;
        }
    }
    if (parentMap != null && !parentMap.isEmpty()) {
        parentResult = [SELECT Id, Salutation, FirstName, MiddleName, LastName, Suffix, IsConverted, NSP_Parent_Lead__c, NSP_Parent_Lead__r.Status FROM Lead WHERE DNBoptimizer__DNB_D_U_N_S_Number__c != null AND NSP_Parent_Lead__c IN: parentMap.keySet()];
    } else if (childMap != null && !childMap.isEmpty()) {
        childResult = [SELECT Id, Salutation, FirstName, MiddleName, LastName, Suffix, IsConverted, NSP_Parent_Lead__c, DNBoptimizer__DNB_D_U_N_S_Number__c FROM Lead WHERE DNBoptimizer__DNB_D_U_N_S_Number__c != null AND DNBoptimizer__DNB_D_U_N_S_Number__c IN: allLeadList AND Id !=: child];
    }
    
    if (parentResult != null && !parentResult.isEmpty()) {
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        for (Lead childLead: parentResult) {
            Database.LeadConvert lc = new Database.LeadConvert();
            if (!childLead.IsConverted) {
                taskIdSet.add(childLead.Id);
                if(parentMap != null && !parentMap.isEmpty() && parentMap.get(childLead.NSP_Parent_Lead__c) != null &&
                parentMap.get(childLead.NSP_Parent_Lead__c).ConvertedOpportunityId != null)
                mapLead.put(childLead.Id, parentMap.get(childLead.NSP_Parent_Lead__c).ConvertedOpportunityId);
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
                if(convertedOpty != null)
                mapLead.put(childLead.Id, convertedOpty);
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
        if (!linkTaskList.isEmpty()) {
            update linkTaskList;
        }
        if (!linkEventList.isEmpty()) {
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
*           
*/
    public void setContactAsPrimary( Set<Id> AccountIds, Map < String, Lead > accountLeadMap) {
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
                        if(!accountLeadMap.isEmpty()){
                        Lead leadObject = accountLeadMap.get(Acr.AccountId);
                        acRecord.NSP_Nonprofit_Organization_Name__c = leadObject.NSP_Nonprofit_Organization_Name__c;
                        acRecord.NSP_Nonprofit_Organization_Tax_Id__c = leadObject.NSP_Nonprofit_Organization_Tax_Id__c;
                        acRecord.NSP_Referralbenefitsanonprofitorg__c = leadObject.NSP_Referralbenefitsanonprofitorg__c; 
                    }
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
* @Defect : DF-01654
* @return void                          
*/
    public void updateNonProfitOrgFields(Map < String, Lead > opportunityLeadMap) {
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
    }
   
}