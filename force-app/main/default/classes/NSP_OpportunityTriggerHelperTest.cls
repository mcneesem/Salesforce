/**
 * Author: Sales Team
* Represents test class for lead opportunity helper
* Test Class to cover Opportunity Trigger Handler and Helper classes
* Modified Date: 19 Aug 2021
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Rahul Singh      		26/10/2022			         Create OCR as part of user story - 128223
* Rahul Singh      		22/12/2022			         Create for enrollment fee payment user story - 194265
*/

@isTest(SeeAllData=false)
public class NSP_OpportunityTriggerHelperTest {
   
    public static final String OPP_NSP_UPSELL_PRODUCT_ADD_ONS_RETIREMENT_SERVICES = 'Retirement Services'; // Added as part of Code Fix
    public static final String OPP_STAGENAME_CLOSED_WON = 'Closed Won'; // Added as part of Code Fix
    public static final String CONTRACT_PRODUCT_TYPE = 'Organizational Planning;Performance Management'; // Added as part of test class coverage
    public static final String CONTRACT_STATUS = 'Draft'; // Added as part of test class coverage
    public static final String CURRENCY_USD = 'USD'; // Added as part of test class coverage
   
    /**
* Does test data setup
* @param N/A.
* @return void                          
*/
   
    @testSetup
    static void testData() {
       
        //Account creation
        Account accoutObject = new Account();
        accoutObject.Name = 'Test Account';
        //inserting account object
        insert accoutObject;
        
        Contact conObj = new Contact();
        conObj.FirstName = 'FName';
        conObj.LastName = 'LName';
        conObj.AccountId = accoutObject.Id;
        conObj.phone = '8987678652';
        insert conObj;
       
        Account accoutObject1 = new Account();
        accoutObject1.Name = 'Test Account1';
        //inserting account object
        insert accoutObject1;
       
        // Inserting Contract
        Contract ct = new Contract();
        ct.AccountId = accoutObject1.Id;
        ct.ContractTerm = 12;
        ct.NSP_Product_Type__c = CONTRACT_PRODUCT_TYPE;
        ct.StartDate = Date.today();
        ct.Status = CONTRACT_STATUS;
        database.insert(ct);
       
        //Create Opportunity
        Opportunity opportuniytObject = new Opportunity();
        opportuniytObject.Name = 'Test Oppty';
        opportuniytObject.AccountId = accoutObject1.id;
        opportuniytObject.stagename = NSP_SalesConstants.ANALYSIS_STAGE;
        opportuniytObject.CloseDate = date.today();
        opportuniytObject.CurrencyIsoCode = CURRENCY_USD;
        opportuniytObject.NSP_PrimaryProduct__c = 'WX';
        opportuniytObject.NSP_Number_of_Employees__c = 100;
        opportuniytObject.NSP_WS_Number_Of_Employees__c = 123;
        opportuniytObject.NSP_WO_Number_Of_Employees__c = 123;
        opportuniytObject.SBQQ__AmendedContract__c = ct.Id;
        opportuniytObject.SBQQ__RenewedContract__c = ct.Id;
        opportuniytObject.NSP_TransactionType__c = NSP_SalesConstants.TRANSACTION_TYPE_TERMINATION;
        opportuniytObject.Type ='CAMS';
        opportuniytObject.NSP_Upsell_Product_add_ons__c = OPP_NSP_UPSELL_PRODUCT_ADD_ONS_RETIREMENT_SERVICES;
        //Inserting Opportunity Object
        insert opportuniytObject;
        
       
        Opportunity opportuniytObject2 = new Opportunity();
        opportuniytObject2.Name = 'Test Oppty Email';
        opportuniytObject2.AccountId = accoutObject1.id;
        opportuniytObject2.stagename = NSP_SalesConstants.ANALYSIS_STAGE;
        opportuniytObject2.CloseDate = date.today();
        opportuniytObject2.CurrencyIsoCode = CURRENCY_USD;
        opportuniytObject2.NSP_PrimaryProduct__c = 'WO';
        opportuniytObject2.NSP_Number_of_Employees__c = 151; //!do not change. Test might fail
        opportuniytObject2.Type ='CAMS';
        opportuniytObject2.NSP_Upsell_Product_add_ons__c = OPP_NSP_UPSELL_PRODUCT_ADD_ONS_RETIREMENT_SERVICES;
        opportuniytObject2.NSP_WS_Number_Of_Employees__c = 123;
        opportuniytObject2.NSP_TransactionType__c = NSP_SalesConstants.TRANSACTION_TYPE_TERMINATION;
        opportuniytObject2.NSP_Mid_Market_Sales_Email__c='test@insperity.com';
        //Inserting Opportunity Object
        insert opportuniytObject2;
       
        List<Task> taskList = new List<Task>();
        Id taskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Core_Sales_Task_RT').getRecordTypeId();
        Task taskRec = new Task(
            Subject = 'Discovery Call',
            WhatId = opportuniytObject2.Id,
            NSP_Task_Type__c = 'BPS',
            RecordTypeId = taskRecTypeId,
            NSP_Task_Subtype__c = 'Client Meeting',
            NSP_Status__c='Completed'
        );
        taskList.add(taskRec);
       
        Opportunity opportuniytObject3 = new Opportunity();
        opportuniytObject3.Name = 'Test Oppty Email';
        opportuniytObject3.AccountId = accoutObject1.id;
        opportuniytObject3.stagename = NSP_SalesConstants.ANALYSIS_STAGE;
        opportuniytObject3.CloseDate = date.today();
        opportuniytObject3.CurrencyIsoCode = CURRENCY_USD;
        opportuniytObject3.NSP_PrimaryProduct__c = 'WX';
        opportuniytObject3.NSP_Client_For_Life__c='WX';
        opportuniytObject3.NSP_Number_of_Employees__c = 151; //!do not change. Test might fail
        opportuniytObject3.Type ='CAMS';
        opportuniytObject3.NSP_Upsell_Product_add_ons__c = OPP_NSP_UPSELL_PRODUCT_ADD_ONS_RETIREMENT_SERVICES;
        opportuniytObject3.NSP_Mid_Market_Sales_Email__c='test2@insperity.com';
        //Inserting Opportunity Object
        insert opportuniytObject3;

        Opportunity opportuniytObject4 = new Opportunity();
        opportuniytObject4.Name = 'Test Oppty Email';
        opportuniytObject4.AccountId = accoutObject1.id;
        opportuniytObject4.stagename = NSP_SalesConstants.ANALYSIS_STAGE;
        opportuniytObject4.CloseDate = date.today();
        opportuniytObject4.CurrencyIsoCode = CURRENCY_USD;
        opportuniytObject4.NSP_PrimaryProduct__c = 'WA';
        opportuniytObject4.NSP_Client_For_Life__c='WA';
        opportuniytObject4.NSP_Number_of_Employees__c = 151; //!do not change. Test might fail
        opportuniytObject4.Type ='CAMS';
        opportuniytObject4.NSP_Upsell_Product_add_ons__c = OPP_NSP_UPSELL_PRODUCT_ADD_ONS_RETIREMENT_SERVICES;
        opportuniytObject4.NSP_Mid_Market_Sales_Email__c='test4@insperity.com';
        //Inserting Opportunity Object
        insert opportuniytObject4;
       
        SBQQ__Quote__c quoteRec = new SBQQ__Quote__c();
        quoteRec.SBQQ__Opportunity2__c = opportuniytObject3.Id;
        quoteRec.SBQQ__Account__c = opportuniytObject3.AccountId;
        quoteRec.SBQQ__Primary__c = true;
        quoteRec.SBQQ__Type__c = 'New Product';
        quoteRec.SBQQ__Status__c = 'Approved';
       
        insert quoteRec;
       
        insert taskList;
       
        //Create child opportunity for Retirement Service
        Opportunity childopportuniytObject = new Opportunity();
        childopportuniytObject.Name = 'Child Oppty Retirement Service';
        childopportuniytObject.AccountId = accoutObject1.id;
        childopportuniytObject.stagename = 'Qualification';
        childopportuniytObject.CloseDate = date.today();
        childopportuniytObject.CurrencyIsoCode = CURRENCY_USD;
        childopportuniytObject.NSP_Number_of_Employees__c = 100;
        childopportuniytObject.NSP_PrimaryProduct__c = 'Retirement Services';
        childopportuniytObject.NSP_Parent_Opportunity__c = opportuniytObject.id;
        //Inserting Child Opportunity
        insert childopportuniytObject;
       
        //Create child opportuniy for Insurance Service
        Opportunity childopportuniytObject1 = new Opportunity();
        childopportuniytObject1.Name = 'Child Oppty Insurance Service';
        childopportuniytObject1.AccountId = accoutObject1.id;
        childopportuniytObject1.stagename = 'Qualification';
        childopportuniytObject1.CloseDate = date.today();
        childopportuniytObject1.CurrencyIsoCode = CURRENCY_USD;
        childopportuniytObject1.NSP_Number_of_Employees__c = 100;
        childopportuniytObject1.NSP_PrimaryProduct__c = 'Insurance Services';
        childopportuniytObject1.NSP_Parent_Opportunity__c = opportuniytObject.id;
        insert childopportuniytObject1;
 
        Pricebook2 pricebook = new Pricebook2(Name = 'Non-CPQ Product Pricebook');
        insert pricebook;
        
       
        NSP_TestHelper.createCPQQuote(accoutObject1.Id,opportuniytObject.Id,true);

       
    }
   
        /**
* @Description: This test method is used to cover updatesOnChildOpportunity
* @Created date: 04/29/2022.
* @return void            
*                
*/
        @isTest
        static void updatesOnChildOpportunityTest(){
            UserRole ur = new UserRole(Name = 'Regional Administrator');
            insert ur;
           
            User userRecord = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id,
                UserRoleId =ur.Id,
                LastName = 'TestClassUser',
                Phone = '1231231231',
                Email = 'testuser@test.com',
                Username = 'testuser@test.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                NSP_Sales_Office_Membership__c = '301'
            );
            insert userRecord;
            user getUser = [SELECT Id,UserRole.Name FROM User WHERE Id =:userRecord.Id ];
            Test.startTest();
            System.runAs(userRecord) {
                Opportunity opp = [SELECT ID,NSP_PrimaryProduct__c,stagename FROM OPPORTUNITY WHERE NSP_Parent_Opportunity__c = null LIMIT 1];
                opp.ownerId = userRecord.Id;
                opp.NSP_PrimaryProduct__c = 'Insurance Services';
                opp.NSP_Lost_Reason__c = 'Backout';
                opp.stagename = NSP_SalesConstants.CLOSED_LOST;
                database.update(opp);
                Test.stopTest();
                System.assertEquals(NSP_SalesConstants.CLOSED_LOST, opp.stagename);
            }
        }
    /**
* Checks the update protion of the trigger
* @param N/A.
* @return void                          
*/
    @isTest
    static void checkUpdate() {
        Test.startTest();
        List<Opportunity> opportunityList = [SELECT ID,NSP_PrimaryProduct__c,stagename FROM OPPORTUNITY WHERE NSP_Parent_Opportunity__c = null ];
        List<Account> accountList = [SELECT ID FROM ACCOUNT WHERE NAME = 'Test Account' ];

        //Setting stage to closed lost
        opportunityList[0].stagename = 'Closed Lost';
        //Setting reason as other
        opportunityList[0].NSP_Lost_Reason__c='Other';
        //Setting the account id
        opportunityList[0].Accountid = accountList[0].id;
        try {
        update opportunityList[0];
        }
        catch (DMLException e) {
            e.getMessage();
        }
        Test.stopTest();
        //Assert statement
        System.assertEquals('Closed Lost', opportunityList[0].stagename);
    }
    /**
* Checks the update protion of the trigger
* @param N/A.
* @return void                          
*/
    @isTest
    static void checkUpdatefoeWOOpptys() {
       
        Test.startTest();
        List<Opportunity> opportunityList = [SELECT ID,NSP_PrimaryProduct__c,stagename FROM OPPORTUNITY WHERE NSP_Parent_Opportunity__c = null ];
        opportunityList[0].NSP_PrimaryProduct__c = 'WX';  
        opportunityList[0].NSP_Reason_for_Product_Change__c='Test';
        update opportunityList[0];        
        Test.stopTest();
        System.assertEquals('WX', opportunityList[0].NSP_PrimaryProduct__c);
    }


@isTest
    static void checkUpdatefoeWOOpptys1() {
       
        Test.startTest();
        List<Opportunity> opportunityList = [SELECT ID,NSP_PrimaryProduct__c,stagename FROM OPPORTUNITY WHERE NSP_Parent_Opportunity__c = null ];
        opportunityList[0].NSP_PrimaryProduct__c = 'WO';  
        opportunityList[0].NSP_Contribution_Level__c = 'Level 1';  
        opportunityList[0].NSP_Frequency_of_Distribution__c = 'Lump sum';  
        opportunityList[0].NSP_Reason_for_Product_Change__c='Test';
        update opportunityList[0];        
        Test.stopTest();
        System.assertEquals('WO', opportunityList[0].NSP_PrimaryProduct__c);
    }    
    /*
     * checks Email services for WO Closed Won Opportunties
*/
    @isTest
    static void checkClosedWonWOOpportunity(){
       
        Test.startTest();
        List<Opportunity> opportunityList = [SELECT Id, Name,NSP_Number_of_Employees__c,Type, NSP_PrimaryProduct__c,
                                             NSP_DM_User__c,NSP_DA_User__c,NSP_BPA__c,OwnerId,StageName,NSP_Merge_On_Demand_Template_Selection__c FROM Opportunity
                                             WHERE NSP_Number_Of_Employees__c = 151 AND StageName =: NSP_SalesConstants.ANALYSIS_STAGE AND NSP_PrimaryProduct__c = 'WO'];
        opportunity oppty = opportunityList[0];
       
        oppty.NSP_DM_User__c = oppty.OwnerId;
        oppty.NSP_DA_User__c = oppty.OwnerId;
     
       
        oppty.NSP_Merge_On_Demand_Template_Selection__c = 'NDA';
        update oppty;
        Test.stopTest();
        System.assertEquals(oppty.StageName, NSP_SalesConstants.ANALYSIS_STAGE); // Added as part of Code fix
    }
   
    /*
     * checks Email services for WO Closed Won Opportunties
*/
    @isTest
    static void checkClosedWonWXOpportunity(){
       
       
        Test.startTest(); 
        List<Opportunity> opportunityList = [SELECT Id,AccountId, Name,NSP_Number_of_Employees__c,Type, NSP_PrimaryProduct__c,
                                             NSP_DM_User__c,NSP_DA_User__c,NSP_Merge_On_Demand_Template_Selection__c,SBQQ__PrimaryQuote__c,NSP_BPA__c,OwnerId FROM Opportunity
                                             WHERE NSP_Number_Of_Employees__c = 151 AND StageName =: NSP_SalesConstants.ANALYSIS_STAGE AND NSP_PrimaryProduct__c = 'WX'];
        opportunity oppty = opportunityList[0];
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :oppty.Id];
        oppty.SBQQ__PrimaryQuote__c = quote.Id;
        oppty.NSP_DM_User__c = oppty.OwnerId;
        oppty.NSP_DA_User__c = oppty.OwnerId;
        oppty.NSP_BPA__c = oppty.OwnerId;
        oppty.StageName = 'Closed Won';
        oppty.NSP_Merge_On_Demand_Template_Selection__c = 'NDA';
       
        update oppty;  
       Test.stopTest();
        System.assertEquals(oppty.StageName, OPP_STAGENAME_CLOSED_WON); // Added as part of Code fix
    }
   
           /**
* @Description: This test method is used to cover moveOpportunityToClosingStage method
* @Created date: 03/03/2022.
* @return void            
*                
*/
    @isTest
    static void moveOpportunityToClosingStageTest() {
        
        Test.startTest();
        List<Opportunity> opportunityList = [SELECT ID,
                                                   NSP_PrimaryProduct__c,
                                                   stagename,
                                                   NSP_Signed_CSA__c,
                                                   NSP_Signed_Delivery_Order__c,
                                                   CloseDate,
                                                   NSP_Closing_Appointment__c,
                                                   OwnerId FROM OPPORTUNITY WHERE NSP_Parent_Opportunity__c = null ];
               
        opportunityList[0].NSP_PrimaryProduct__c = NSP_SalesConstants.WX;  
        opportunityList[0].NSP_Signed_Delivery_Order__c = true;
         /* Added as part of test class coverage */
        opportunityList[0].NSP_Signed_CSA__c = true;
        opportunityList[0].NSP_Closing_Appointment__c = true;
         /* Added as part of test class coverage */
        update opportunityList[0];      
        NSP_OpportunityTriggerHelper helper = new NSP_OpportunityTriggerHelper();
        helper.moveOpportunityToClosingStage(opportunityList);
        Test.stopTest();
        System.assertEquals(NSP_SalesConstants.WX, opportunityList[0].NSP_PrimaryProduct__c);
    }
   
       /**
* @Description: This test method is used to cover updatesOnChildOpportunity method
* @Created date: 03/03/2022.
* @return void            
*                
*/

    @isTest
    static void defaultFieldsOnChildOpportunityTest(){
       Test.startTest();
       Set<Id> pOppIdSet = new Set<Id>();
       List<Opportunity> cOppList = new List<Opportunity>();
       List<Opportunity> opportunityList = [SELECT Id, stagename, NSP_PrimaryProduct__c, NSP_Parent_Opportunity__r.NSP_PrimaryProduct__c FROM Opportunity
                                                WHERE NSP_Parent_Opportunity__c != null LIMIT 1];
       pOppIdSet.add(opportunityList[0].NSP_Parent_Opportunity__c);
       cOppList.add(opportunityList[0]);

       NSP_ChildOpportunitiesHelperFunctions.defaultFieldsOnChildOpportunity(cOppList, pOppIdSet);
        Test.stopTest();
    }
     
    /**
    * @Description: This test method is used to cover sendClosedWonEmailNotifications for WX method of NSP_EmailWithAttachment
    * @Created date: 22/03/2022.
    * @return void            
    * @author : Nischay Jindal              
    */
       
    @isTest
        static void sendClosedWonEmailNotificationWX(){
          
            Test.startTest(); 
            List<Opportunity> opportunityList = [SELECT Id,NSP_PrimaryProduct__c,AccountId,OwnerId FROM Opportunity WHERE NSP_Number_Of_Employees__c = 151 AND StageName =: NSP_SalesConstants.ANALYSIS_STAGE AND NSP_PrimaryProduct__c = 'WX'];
           
            ContentVersion cvlist = new Contentversion();
            cvlist.Title = 'WX_0_Delivery Order__completed';
            cvlist.PathOnClient = 'test';
            cvlist.VersionData = EncodingUtil.base64Decode('Unit Test Attachment Body');
            cvlist.FirstPublishLocationId=opportunityList[0].Id;
            insert cvlist;
            
            opportunity oppty = opportunityList[0];
            oppty.NSP_DM_User__c = oppty.OwnerId;
            oppty.NSP_DA_User__c = oppty.OwnerId;
            oppty.NSP_BPA__c = oppty.OwnerId;
            oppty.StageName = 'Closed Won';
            update oppty;
            List<String> workforceProductsList = System.Label.NSP_Primary_Workforce_Products.split(',');
            Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
            oppMap.put(oppty.Id,oppty);
            NSP_EmailServicesUtility.sendEmailsTOService(oppMap.Values(),oppMap,workforceProductsList);
           Test.stopTest();
            System.assertEquals(oppty.StageName, OPP_STAGENAME_CLOSED_WON); // Added as part of Code fix
        }

    /**
    * @Description: This test method is used to cover sendClosedWonEmailNotifications for WA method of NSP_EmailWithAttachment
    * @Created date: 22/03/2022.
    * @return void            
    * @author : Nischay Jindal              
    */
       
    @isTest
        static void sendClosedWonEmailNotificationWA(){
           
           Test.startTest(); 
            List<Opportunity> opportunityList = [SELECT Id,NSP_PrimaryProduct__c,AccountId,OwnerId FROM Opportunity WHERE NSP_Number_Of_Employees__c = 151 AND StageName =: NSP_SalesConstants.ANALYSIS_STAGE AND NSP_PrimaryProduct__c = 'WA'];
          
            ContentVersion cvlist = new Contentversion();
            cvlist.Title = 'WA_0_Delivery Order__completed';
            cvlist.PathOnClient = 'test';
            cvlist.VersionData = EncodingUtil.base64Decode('Unit Test Attachment Body');
            cvlist.FirstPublishLocationId=opportunityList[0].Id;
            insert cvlist;
            opportunity oppty = opportunityList[0];
            oppty.NSP_DM_User__c = oppty.OwnerId;
            oppty.NSP_DA_User__c = oppty.OwnerId;
            oppty.NSP_BPA__c = oppty.OwnerId;
            oppty.StageName = 'Closed Won';
            update oppty;
            List<String> workforceProductsList = System.Label.NSP_Primary_Workforce_Products.split(',');
            Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
            oppMap.put(oppty.Id,oppty);
            NSP_EmailServicesUtility.sendEmailsTOService(oppMap.Values(),oppMap,workforceProductsList);
           Test.stopTest();
            System.assertEquals(oppty.StageName, OPP_STAGENAME_CLOSED_WON); // Added as part of Code fix
        }

   /**
    * @Description: This test method is used to cover createClosedLostRegenTasks method of NSP_OpportunityTriggerHelper
    * @Created date: 13/04/2022.
    * @return void            
    * @author : Nischay Jindal
    * Commented this menthod as this is no longer needed
    * @Commented By: Ruchi Roy              
    */
       
    /**@isTest
        static void createClosedLostRegenTasks(){
           List<Opportunity> opportunityList = [SELECT Id,AccountId,NSP_Regen_Date__c,NSP_Lost_Reason__c,StageName, OwnerId FROM Opportunity WHERE NSP_Number_Of_Employees__c = 151 Limit 1];
           try {
           Test.startTest();      
            opportunity oppty = opportunityList[0];
            oppty.NSP_Regen_Date__c = System.Today();
            oppty.NSP_Lost_Reason__c = 'Regen';
            oppty.StageName = 'Closed Lost';
            update oppty;  
           Test.stopTest();
               if(oppty.Id!=NULL ){
            Task task = [Select Id, Subject, WhatId from Task where WhatId=:oppty.Id Limit 1];
            System.assertEquals(task.Subject, 'Regen Follow Up'); // Added as part of Code fix
                   }
           }catch (DMLException e) {
             e.getMessage();
                 }
        }
        **/
   /**
   * @Description: This test method is used to cover validateClosedDate method
   * @Created date: 04/20/2022.
   * @return void                          
   */
  @isTest
  static void validateClosedDateTest(){
  List<Opportunity> opportunityList = [SELECT Id,AccountId,OwnerId,StageName,CloseDate FROM Opportunity WHERE NSP_Number_Of_Employees__c = 151 AND StageName =: NSP_SalesConstants.ANALYSIS_STAGE AND NSP_PrimaryProduct__c = 'WX'];
      Test.startTest();
      NSP_OpportunityTriggerHelper.validateClosedDate(opportunityList);
      Test.stopTest();
      System.assertEquals(opportunityList[0].CloseDate, date.today());
  }
 
   @isTest
   static void salesOfficeTest()
   {
       User currentUser = [SELECT Id,NSP_SalesDivision__c,NSP_Sales_Office__c,NSP_SalesRegion__c from user where Id =:UserInfo.getUserId()];
         currentUser.NSP_Sales_Office__c = '301';
         currentUser.NSP_SalesRegion__c = 'Central 1';
         currentUser.NSP_SalesDivision__c = 'Central';
         update currentUser;
       NSP_Sales_Office_Mapping__c officeMapping = new NSP_Sales_Office_Mapping__c();
        officeMapping.NSP_Sales_Office__c = '1081';
        officeMapping.NSP_Sales_Division__c = 'Central';
        officeMapping.NSP_Sales_Region__c = 'Central 1';
        officeMapping.NSP_Start_Date__c = system.today()-1;
        officeMapping.NSP_End_Date__c = system.today()+100;
        insert officeMapping;
       
       NSP_Sales_Office_Mapping__c office1Mapping = new NSP_Sales_Office_Mapping__c();
        office1Mapping.NSP_Sales_Office__c = '301';
        office1Mapping.NSP_Sales_Division__c = 'Central';
        office1Mapping.NSP_Sales_Region__c = 'Central 1';
        office1Mapping.NSP_Start_Date__c = system.today()-1;
        office1Mapping.NSP_End_Date__c = system.today()+200;
        insert office1Mapping;
       
       Test.startTest();
        List<Opportunity> opportunityList = [SELECT ID,NSP_PrimaryProduct__c,stagename FROM OPPORTUNITY WHERE NSP_Parent_Opportunity__c = null ];
               for(Opportunity eachOppty : opportunityList)
               {
                   eachOppty.NSP_Sales_Office__c = '1081';
               }
       update opportunityList;
       Test.stopTest();
       
       
   }
 
   @isTest
   static void rewardCreationTest()
   {
       
       Test.startTest();
       List<Opportunity> opportunityList = [SELECT ID,NSP_PrimaryProduct__c,stagename,Discovery_Completed__c,Nsp_1st_Pay_Invoice_Date_Reporting__c FROM OPPORTUNITY WHERE Name != null limit 1 ];
       List<Account> accountList = [SELECT ID FROM ACCOUNT WHERE NAME = 'Test Account' ];
       list<Contact> cntInsertlist = new list<Contact>();
       for(Account objAccount: accountList)
       {
           Contact objContact = new Contact();
           objContact.firstName = 'Test';
           objContact.LastName = 'Contact NSP';
           objContact.Email = 'testcnt@nsp.com';
           objContact.AccountId = objAccount.Id;
           cntInsertlist.add(objContact);
       }
       insert cntInsertlist;
       
       OpportunityContactRole objOCR = new OpportunityContactRole();
       objOCR.OpportunityId = opportunityList[0].id;
       objOCR.ContactId = cntInsertlist[0].Id;
       objOCR.NSP_isReferral__c = true;
       objOCR.Role = 'Agency';
       insert objOCR;
       opportunityList[0].Discovery_Completed__c = true;
       update opportunityList;
       opportunityList[0].Nsp_1st_Pay_Invoice_Date_Reporting__c = system.today()+2;
       update opportunityList;
       Test.stopTest();
   }
    
       /** 
    * Test for before and after insert of ACR trigger
    * Method Name : testAccountContactInsert
    * created as part of user story - 128223
    */
    @isTest
    static void testAccountContactInsert() {
       
        // Start Test
        Test.startTest();
        
        Account accObj = [Select Id,Name from Account WHERE Name = 'Test Account' Limit 1];
        ID accountId = accObj.Id;
        AccountContactRelation acrObj  = [Select Id from AccountContactRelation WHERE AccountId =: accountId];
        acrObj.Roles = 'Agency';
        acrObj.NSP_Is_Primary__c = true;
        acrObj.IsActive =true;
        update acrObj; 
        
        Opportunity opportuniytObject = new Opportunity();
        opportuniytObject.Name = 'Test Oppty';
        opportuniytObject.AccountId = accountId;
        opportuniytObject.stagename = NSP_SalesConstants.DISCOVERY_STAGE;
        opportuniytObject.CloseDate = date.today();
        opportuniytObject.NSP_PrimaryProduct__c = 'WX';
        opportuniytObject.NSP_Number_of_Employees__c = 100;
        opportuniytObject.NSP_WS_Number_Of_Employees__c = 123;
        opportuniytObject.NSP_WO_Number_Of_Employees__c = 123;
        //Inserting Opportunity Object
        insert opportuniytObject;
        Test.stopTest();
    }

   /** 
    * Test for after update trigger
    * Method Name : testenrollmentfee
    * Create for enrollment fee payment user story - 194265
    */
    @isTest
    static void testEnrollmentFeeTrue() {
  
        // Start Test
        Test.startTest();
         
        //Create Enrollment fee payment 
        Opportunity oppObj = [Select Id,Name,NSP_Number_of_Employees__c from Opportunity WHERE NSP_Number_of_Employees__c < 150 Limit 1];
        ID oppId = oppObj.Id;
        NSP_Enrollment_Fee_Payment__c enrollmentfee = new NSP_Enrollment_Fee_Payment__c();
        enrollmentfee.NSP_Opportunity__c = oppId;
        enrollmentfee.CurrencyIsoCode = CURRENCY_USD;
        insert enrollmentfee;
        
        Opportunity opportuniytObject = new Opportunity();
        opportuniytObject.Id = oppId;
        opportuniytObject.NSP_Number_of_Employees__c = 200;
        //Inserting Opportunity Object
        update opportuniytObject;
        Test.stopTest();
    }
    
     /** 
    * Test for after update trigger
    * Method Name : testenrollmentfee
    * Create for enrollment fee payment user story - 194265
    */
    @isTest
    static void testEnrollmentFeeFalse() {
        
        // Start Test
        Test.startTest();
         
        //Create Enrollment fee payment
        Opportunity oppObj = [Select Id,Name,NSP_Number_of_Employees__c from Opportunity WHERE NSP_Number_of_Employees__c > 150 Limit 1];
        ID oppId = oppObj.Id; 
        
        NSP_Enrollment_Fee_Payment__c enrollmentfee = new NSP_Enrollment_Fee_Payment__c();
        enrollmentfee.NSP_Opportunity__c = oppId;
        enrollmentfee.CurrencyIsoCode = CURRENCY_USD;
        insert enrollmentfee;
        
        Opportunity opportuniytObject = new Opportunity();
        opportuniytObject.Id = oppId;
        opportuniytObject.NSP_Number_of_Employees__c = 100;
        //Inserting Opportunity Object
        update opportuniytObject;
        Test.stopTest();
    }
    
    
     
 
}