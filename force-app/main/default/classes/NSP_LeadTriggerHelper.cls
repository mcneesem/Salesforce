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
  // Added as part of DF-01009
  private static final string REFERRAL_RECORDTYPE = 'Referral';
  private static final Id REFERRAL_RECORDTYPE_ID = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(REFERRAL_RECORDTYPE).getRecordTypeId();
  // DF-01301
  List<String> DADMUserList = Label.DA_and_DM_Userrole.split(',');
  

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
         String createdUserName = leadObject.createdBy.FirstName;
       if (leadObject.RecordTypeId == REFERRAL_RECORDTYPE_ID || (String.isNotBlank(createdUserName) && externalUsers.contains(createdUserName))) {
          inboundSolutionsList.add(leadObject);
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
    /* Added as part of STY-01725 */
      List<String> inboundOrOutBoundUserList = Label.Inbound_and_Outbound_UserRole.split(',');
      /*********************/
      Map<Id,Id> leadIdsOwnerMap = New Map<Id,Id>();
      Set<String> salesOfficeSet=new Set<String>();
      /*********************/

      User userDetails =[ SELECT Id, Name, UserRole.Name FROM User WHERE Id =: userinfo.getUserId() ];
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
        if(userDetails.UserRole.Name != null && string.valueOf(leadOldMap.get(leadId).OwnerId).startsWith('005')
           && DADMUserList.contains(userDetails.UserRole.Name) 
           && leadNewMap.get(leadId).OwnerId != leadOldMap.get(leadId).OwnerId){
               leadIdsOwnerMap.put(leadOldMap.get(leadId).Id, leadOldMap.get(leadId).OwnerId);
           }
        /* Added as part of DF-01301 */
        
     /* As part of DF-00998 comments
      * If the loggedIn user is either Inbound or Outbound and Assign Lead Checkbox is checked then only Lead assignment rule will trigger
      * If the loggedIn user is not Inbound or Outbound solutions user, then No Lead assignment rules will trigger 
      */

        if (inboundOrOutBoundUserList.contains(userDetails.UserRole.Name) 
            && leadNewMap.get(leadId).NSP_Assign_Lead__c == true
            && leadOldMap.get(leadId).Lead_Owner_Auto_Assignment__c == False) {
                if (String.isnotBlank(leadNewMap.get(leadId).company) && nationalAccountList.contains(leadNewMap.get(leadId).company.toUppercase())) {
                    //If the Lead Company is associated with National Account, route the correct National Account Queue
                    nationalAccountLeadList.add(leadNewMap.get(leadId));
                } else if (String.isNotBlank(leadNewMap.get(leadId).PostalCode)
                            && (leadNewMap.get(leadId).NumberOfEmployees == null || Integer.valueof(leadNewMap.get(leadId).NumberOfEmployees) < Integer.valueOf(System.Label.NSP_EMP_THRESH_150))
                            && leadNewMap.get(leadId).NSP_Product_Interest__c != null 
                            && (leadNewMap.get(leadId).NSP_Product_Interest__c.contains(System.label.NSP_PRODINT_FULL_SERVICE_HR) ||
                            leadNewMap.get(leadId).NSP_Product_Interest__c.contains(String.valueOf(System.label.NSP_PRODINT_HCM)))) {
                                /* If Postal Code is not blank, Number of Employees is null or < 150 and Product of interest is WO/WX assign to Sales office */
                                leadsForRoundRobin.add(leadNewMap.get(leadId));
                                zipCodeList.add(leadNewMap.get(leadId).PostalCode);
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
                                       }
        }

      //collect all Leads to change AccountSegment value based on number of employees
      if (leadNewMap.get(leadId).NumberOfEmployees != leadOldMap.get(leadId).NumberOfEmployees) {
        updateAccountSegment(leadNewMap.get(leadId));
      }
    }
     
      /* Added as part of DF-01301 */
      List<GroupMember> groupMemberList = new List<GroupMember>();
      if(leadIdsOwnerMap != null){
          List<User> ownerIdList = [Select Id,ToLabel(NSP_Sales_Office__c) from User WHERE ID IN:leadIdsOwnerMap.values()];
          if(!ownerIdList.isEmpty()){
              for(User userList : ownerIdList){
                  if(userList.NSP_Sales_Office__c != Null){
                      salesOfficeSet.add(userList.NSP_Sales_Office__c);
                  }
                  
              }
          }
          if(!salesOfficeSet.isEmpty() && DADMUserList.contains(userDetails.UserRole.Name)){
              groupMemberList =[SELECT Id, Group.Name, UserOrGroupId FROM GroupMember WHERE UserOrGroupId=: userinfo.getUserId() AND Group.Name IN :salesOfficeSet];
          }
          
          for (Id leadId: leadNewMap.keySet()) {
              if(userDetails.UserRole.Name !=null && string.valueOf(leadOldMap.get(leadId).OwnerId).startsWith('005')
                 && DADMUserList.contains(userDetails.UserRole.Name) 
                 && leadNewMap.get(leadId).OwnerId != leadOldMap.get(leadId).OwnerId){
                     if(groupMemberList.isEmpty()){
                         leadNewMap.get(leadId).Id.addError(system.label.NSP_LeadTriggerError);  
                         
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
      setLeadRegion(zipCodeList, leadsForRoundRobin);
    }
    //assigning leads to mid market queue in number of employees >=EMP_THRESH_150
    assignLeadToMidMarket(midMarketList);
    //assigning leads to national accounts queue
    assignLeadToNationalAccountQueue(nationalAccountLeadList);
    //assigning leads to mid market queue in number of employees >=EMP_THRESH_150
    assignLeadToPayrollHCM(payrollHCMList);

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

    for (Lead leadObject: leadNewMap.values()) {
      //temporarily added
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
    }

    setContactasCOI(accountLeadMap, opportunityLeadMap);

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
    for (Lead leadObject: midMarketLead) {
      leadObject.OwnerId = midMarketQueue[0].id;
      leadObject.Lead_Owner_Auto_Assignment__c = TRUE;
      leadObject.NSP_Sales_Office__c = NSP_SalesConstants.MIDMARKETSALESOFFICE;
    }

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
    if (!finalRoundRobinList.isEmpty()) {
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
      acrObject.NSP_Referralbenefitsanonprofitorg__c = leadObject.NSP_Referralbenefitsanonprofitorg__c;
      acrObject.NSP_Nonprofit_Organization_Name__c = leadObject.NSP_Nonprofit_Organization_Name__c;
      acrObject.NSP_Nonprofit_Organization_Tax_Id__c = leadObject.NSP_Nonprofit_Organization_Tax_Id__c;

      acrList.add(acrObject);
    }

    for (String opportunityId: opportunityLeadMap.keySet()) {
      Lead leadObject = opportunityLeadMap.get(opportunityId);

      OpportunityContactRole ocrObject = new OpportunityContactRole();
      ocrObject.OpportunityId = leadObject.convertedOpportunityId;
      ocrObject.ContactId = leadObject.NSP_Referred_By_COI__c;
      ocrObject.Role = leadObject.NSP_Referral_Source__c;
      ocrObject.NSP_isReferral__c = true;
      ocrObject.NSP_Referralbenefitsanonprofitorg__c = leadObject.NSP_Referralbenefitsanonprofitorg__c;
      ocrObject.NSP_Nonprofit_Organization_Name__c = leadObject.NSP_Nonprofit_Organization_Name__c;
      ocrObject.NSP_Nonprofit_Organization_Tax_Id__c = leadObject.NSP_Nonprofit_Organization_Tax_Id__c;

      ocrList.add(ocrObject);
    }

    try {
      insert acrList;
      insert ocrList;
    } catch (Exception ex) {
      NSP_CustomException.LogException(ex);
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
        String addMonthsValue = leadRecord.NSP_Reason__c.replaceAll('[^0-9]', '');

        taskRecord.Subject = leadRecord.NSP_Reason__c;
        taskRecord.OwnerId = leadRecord.OwnerId;
        taskRecord.WhoId = leadRecord.Id;
        taskRecord.Type = NSP_SalesConstants.CALL_BACK_TASK;
        taskRecord.ActivityDate = System.today().addMonths(Integer.valueOf(addMonthsValue));

        tasksList.add(taskRecord);
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
        String addMonthsValue = leadRecord.NSP_Reason__c.replaceAll('[^0-9]', '');
        DateTime dt = leadIdTaskMap.get(leadRecord.Id).CreatedDate.addMonths(Integer.valueOf(addMonthsValue));
        leadIdTaskMap.get(leadRecord.Id).Subject = leadRecord.NSP_Reason__c;
        leadIdTaskMap.get(leadRecord.Id).ActivityDate = Date.newInstance(dt.year(), dt.month(), dt.day());

        tasksList.add(leadIdTaskMap.get(leadRecord.Id));
      }
    }

    try {
      upsert tasksList;
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
    } else if(leadObject.NumberOfEmployees!=null){
      leadObject.NSP_Account_Segment__c = System.Label.NSP_Account_Segment_Core_Sales;
    }
  }

}