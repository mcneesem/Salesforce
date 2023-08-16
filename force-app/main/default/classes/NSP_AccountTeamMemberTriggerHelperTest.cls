/**
 * Represents test class for 
 * AccountTeamMember trigger helper
 */

 @isTest(SeeAllData=FALSE)
 public class NSP_AccountTeamMemberTriggerHelperTest {
     
     private static final String ACCOUNT_AIMS_CLIENT_NAME = 'ateammember1';
     /**
      * Checks the AccountTeamMember After Insert Trigger
      * @param N/A. 
      * @return void                          
      */
     @testsetup
     static void testData(){
         
         Profile profileobj = [SELECT Id FROM Profile WHERE Name='Integration User'];
         UserRole role = [SELECT Id FROM UserRole WHERE Name='CEO'];
 
         User userobj = new User(alias = 'jsmith', email='jsmith@insperity.com', 
         emailencodingkey='UTF-8', lastname='Smith', 
         languagelocalekey='en_US', 
         localesidkey='en_US', profileid = profileobj.Id, userroleid = role.Id,
         timezonesidkey='America/Los_Angeles', 
         username='insperitytestadminuser@insperity.com',
         NSP_Employee_Per_ID__c = 'test 123',
         IsActive=true);
         insert userobj;
         
     }
 
     @isTest
     static void testAccountTeamMemberInsert() {
         //Insert Test Account record
         Account account = New Account(Name = 'TestAccount', AccountNumber = '12345',NSP_AIMS_Client__c = ACCOUNT_AIMS_CLIENT_NAME);
         insert account;
        // Account account = [SELECT Id FROM Account WHERE Name = 'TestAccount'];
         //Insert Test User Record
 
         User user = [SELECT Alias FROM User WHERE Profile.Name LIKE 'Integration%' AND IsActive=true AND NSP_Employee_Per_ID__c = 'test 123' LIMIT 1];
 
         List<AccountTeamMember>  accountTeamMemberList = New List<AccountTeamMember>();
 
         for(integer count = 0; count < 5; count++) {
             accountTeamMemberList.add(New AccountTeamMember(AccountId = account.Id, UserId = user.Id,NSP_AIMS_Client__c = ACCOUNT_AIMS_CLIENT_NAME,NSP_Employee_Per_ID__c = 'test 123'));
         } 
 
 
         system.runAs(user){
             insert accountTeamMemberList;
         }
         
         AccountTeamMember atmObj = new AccountTeamMember();
         atmObj.Id = accountTeamMemberList[0].Id;
         atmObj.TeamMemberRole = NSP_SalesConstants.LeadQualifier;
         update atmObj;
         // Start Test
         Test.startTest();
         System.assertEquals(NSP_SalesConstants.LeadQualifier, atmObj.TeamMemberRole);
         Test.stopTest();
     }
     
     @isTest
     static void testAccountTeamMemberNonInInsert() {
         //Insert Test Account record
         Account account = New Account(Name = 'TestAccount', AccountNumber = '12345',NSP_AIMS_Client__c = ACCOUNT_AIMS_CLIENT_NAME);
         insert account;
        // Account account = [SELECT Id from Account WHERE Name = 'TestAccount'];
         //Insert Test User Record
         User user =[ SELECT Id,
        Name, 
        Email, 
        Profile.Name, 
        UserRole.Name 
        FROM User
        WHERE Id =: userinfo.getUserId() ];
 
         List<AccountTeamMember>  accountTeamMemberList = New List<AccountTeamMember>();
 
         for(integer count = 0; count < 5; count++) {
             accountTeamMemberList.add(New AccountTeamMember(AccountId = account.Id, UserId = user.Id,NSP_AIMS_Client__c = ACCOUNT_AIMS_CLIENT_NAME,NSP_Employee_Per_ID__c = 'test 123'));
         } 
 
         system.runAs(user){
             insert accountTeamMemberList;
         }
 
         AccountTeamMember atmObj = new AccountTeamMember();
         atmObj.Id = accountTeamMemberList[0].Id;
         atmObj.TeamMemberRole = NSP_SalesConstants.LeadQualifier;
         update atmObj;
         // Start Test
         Test.startTest();
         System.assertEquals(NSP_SalesConstants.LeadQualifier, atmObj.TeamMemberRole);
         Test.stopTest();
     }
 }