/**
Apex Class Name      :  NSP_ChatterPostControllerTest
Version              :  1.0 
Author               :  Anil                                                                          
Created Date         :  12/21/22 
Function             :  Represents for NSP_ChatterPostController
Story                :  As part of STY-01980                                                                    
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Anil                      12/21/22                First Iteration
*/
@isTest
public with sharing class NSP_ChatterPostController_Test {

    /**
     * @description Post a chatter when Owner is changed
     * The Connect API is not called in test context. The alternative to using seeAllData=true is applying a mocking for Feed.
     */
    @isTest(SeeAllData=true)
    static void testChatterPost(){
        Id recordTypePEOID = NSP_GenericRecordType.getRecordTypeId('Case', NSP_ServiceConstants.PEO);

        Account newAccount = Database.Query(new NSP_QueryBuilder( 'Account', new List<String>{'Id'}).addLimit(1).build());

        Case newCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
        newCase.AccountId = newAccount.Id;
        newCase.RecordTypeId = recordTypePEOID;
        newCase.NSP_Category__c = NSP_SalesConstants.HR_SERVICES;
        newCase.NSP_SubCategory__c = NSP_SalesConstants.Discuss_Paid_Sick_Leave;
        newCase.Status = NSP_SalesConstants.OPEN;
        newCase.Subject = 'Employees work in New Jersey, California, New York, Chicago';
        insert newCase; 
        
        Profile profileId = [SELECT Id FROM Profile WHERE Name= 'PEO Service' LIMIT 1];
        String uniqueUserName = 'PEOSerivceUserNSP' + DateTime.now().getTime() + '@testorg.com';

        User user = new User(Alias = 'standt', 
                             Email='standarduser@insperity.com',
                             EmailEncodingKey='UTF-8', 
                             LastName='Testing',
                             LanguageLocaleKey='en_US',
                             LocaleSidKey='en_US', 
                             ProfileId = profileId.Id,
                             TimeZoneSidKey = 'America/Los_Angeles',
                             UserName = uniqueUserName);
        insert user;
               
        Test.startTest();
        NSP_ChatterPostController.InputResponse inputParameters = new NSP_ChatterPostController.InputResponse();
        inputParameters.relatedId =  newCase.Id;
        inputParameters.userIds = new List<String>{ user.Id };
        inputParameters.subject = 'Employees work in New Jersey, California, New York, Chicago has been assigned to the';
        NSP_ChatterPostController.postChatterFeed(new List<NSP_ChatterPostController.InputResponse>{inputParameters});
        Test.stopTest();
        
        FeedItem chatterFeed = Database.Query(new NSP_QueryBuilder( 'FeedItem', new List<String>{'Id','Body'})
                                   .addFilter('ParentId', newCase.Id)
                                   .addLimit(1).build());

        Boolean containsBody = chatterFeed.body.contains('Employees work in New Jersey, California, New York, Chicago has been assigned to the');
        //verifying the chatter posted on the Case object record
        System.assertEquals(containsBody,true);
    }
    
    /**
     * @description Owner is changed to systemAdmin Profile User so it wont post any chatter
     */
    @istest static void testChatterPostNegative(){
        List<FeedItem> chatterFeed  = new List<FeedItem>(); 
        
        try{
            Id recordTypePEOID = NSP_GenericRecordType.getRecordTypeId('Case', NSP_ServiceConstants.PEO);
            Account newAccount = Database.Query(new NSP_QueryBuilder( 'Account', new List<String>{'Id'}).addLimit(1).build());
            
            Case newCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
            newCase.AccountId = newAccount.Id;
            newCase.RecordTypeId = recordTypePEOID;
            newCase.NSP_Category__c = NSP_SalesConstants.HR_SERVICES;
            newCase.NSP_SubCategory__c = NSP_SalesConstants.Discuss_Paid_Sick_Leave;
            newCase.Status = NSP_SalesConstants.OPEN;
            newCase.Subject = 'Employees work in New Jersey, California, New York, Chicago';
            insert newCase; 
            
            Test.startTest();
            update newCase;
            Test.stopTest();
            chatterFeed = Database.Query(new NSP_QueryBuilder( 'FeedItem', new List<String>{'Id','Body'})
                                                        .addFilter('ParentId', newCase.Id)
                                                        .addLimit(1).build());
            //verifying the chatter posted on the Case object record
            
        } catch (Exception ex){
            System.assertEquals(ex.getMessage(),'List has no rows for assignment to SObject');
            System.assertEquals(chatterFeed.size(),0);
        }
    }
}