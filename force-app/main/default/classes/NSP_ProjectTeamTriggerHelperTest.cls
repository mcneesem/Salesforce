/**
* @description  :   Test class for NSP_ProjectTeamTriggerHelper .
* @date 08/3/2022
* Author : Nischay Jindal
* Name : NSP_ProjectTeamTriggerHelperTest
*/
@isTest
public class NSP_ProjectTeamTriggerHelperTest {
    /***********************************************************************************************
    * MethodName: testData
    * Description : Setting the Test Data
    * ********************************************************************************************/
	@testSetup
    public static void setUpData(){
        //Middle_Market
        Id PEORecordTypeId  = Schema.SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
       
		User userRec = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', true);
       
		        
        Account acc = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
		Contact con = new Contact();
        con.AccountId = acc.Id;
        con.lastName= 'Test';
        con.pse__Salesforce_User__c=userRec.Id;
        insert con;
        
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
		oProject.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
        oProject.TemplateName__c = label.Middle_Market_Implementation_Project;
        oProject.RecordTypeId = PEORecordTypeId;
        oProject.pse__Account__c =acc.Id;
        insert oProject;

        //Project Creation
        pse__Proj__c newProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
         newProject.pse__Project_Type__c=NSP_ServiceConstants.ImplementationProjectType;
         newProject.TemplateName__c =label.FSOImplementationProject;
         newProject.RecordTypeId=PEORecordTypeId;
         insert newProject;
    }
    /***********************************************************************************************
    * MethodName: restrictDuplicateTest
    * Description : Unit test for restrictDuplicate 
    * ********************************************************************************************/
    @isTest
    public static void restrictDuplicateTest(){
        Id MiddleMarketRecordTypeId = Schema.SObjectType.NSP_Project_Team__c.getRecordTypeInfosByDeveloperName().get('NSP_Middle_Market_Project_Team').getRecordTypeId();
        pse__Proj__c project = [Select Id ,pse__Project_Type__c,TemplateName__c, RecordTypeId From pse__Proj__c WHERE TemplateName__c =: label.Middle_Market_Implementation_Project ];
		
        NSP_Project_Team__c projTeam = new NSP_Project_Team__c();
        projTeam.RecordTypeId = MiddleMarketRecordTypeId;
        projTeam.NSP_Project__c = project.Id;
        projTeam.NSP_Role__c = 'MidMarket Account Exec';
        
        try{
          Test.startTest();
          //Inserting Project Team
        	insert projTeam;
            Test.stopTest();
        }
        catch(Exception ex){
            Boolean isExpectedExceptionThrown =  ex.getMessage().contains(label.NSP_ProjectTeamTriggerValidationMsg) ? true : false;
            System.assertEquals(isExpectedExceptionThrown, true);
        }    
    }
    
    /***********************************************************************************************
    * MethodName: updateImplementationProfileTest
    * Description : Unit test for update Implementation Profile Role on Project Team role change
    * ********************************************************************************************/
    
    @isTest
    public static void updateImplementationProfileTest(){
        Id MMRecordIPRecordTypeId = Schema.SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get('Middle_Market').getRecordTypeId();
        Account acc=[Select Id from Account WHERE Id != null];
        //Inserting Contact
        Contact contact =[Select Id,AccountId From Contact WHERE Id !=null Limit 1];
        pse__Proj__c project = [Select Id ,pse__Account__c,pse__Project_Type__c,TemplateName__c, RecordTypeId From pse__Proj__c WHERE TemplateName__c =: label.Middle_Market_Implementation_Project ];
		project.pse__Account__c =acc.Id;
        update project;
        //Inserting Implementation Profile
        Implementation_Profile__c impProfile= new Implementation_Profile__c();
        impProfile.NSP_Project__c = project.Id;
        impProfile.RecordTypeId = MMRecordIPRecordTypeId;
        impProfile.Account__c= acc.Id;
        insert impProfile;
        List<NSP_Project_Team__c> projectTeam = [Select Id , NSP_Role__c, NSP_Assignee__c FROM NSP_Project_Team__c WHERE  NSP_Project__c=: project.Id  ];
        for(NSP_Project_Team__c prjTeam: projectTeam){
             prjTeam.NSP_Assignee__c = contact.Id;
        }
        Test.startTest();
        //Updating Project Team
        	update projectTeam;
        Test.stopTest();
       NSP_Project_Team__c accountExecutive = [Select Id , NSP_Role__c, NSP_Assignee__c FROM NSP_Project_Team__c WHERE  NSP_Project__c=: project.Id AND NSP_Role__c ='MidMarket Account Exec' ];
      
        Implementation_Profile__c ImpPrf= [Select Id ,Account__c,NSP_Project__c,NSP_Account_Executive__c from Implementation_Profile__c WHERE Id =:impProfile.Id  ];
        System.assertEquals(accountExecutive.NSP_Assignee__c, ImpPrf.NSP_Account_Executive__c);
        
    }

    /***********************************************************************************************
    * MethodName: updateProjectOwner
    * Description : Unit test for update Project owner on Project Team role project manager
    * ********************************************************************************************/
    
    @isTest
    static void updateProjectOwner(){
          // Getting Project records
          List<pse__Proj__c> projects = [Select Id ,OwnerId from pse__Proj__c WHERE TemplateName__c=:label.FSOImplementationProject];
          //Getting Project Team List records
          List<NSP_Project_Team__c> ptList = [SELECT Id,NSP_Role__c,NSP_Project__c from NSP_Project_Team__c WHERE
                                              NSP_Project__c=:projects[0].id AND NSP_Role__c=: NSP_ServiceConstants.ProjectManager LIMIT 1];
          Contact cc = [SELECT Id,pse__Salesforce_User__c from Contact WHERE pse__Salesforce_User__c != null];
          
          Test.startTest();
            ptList[0].NSP_Assignee__c=cc.Id;
            //Updating Project Team List
            update ptList;
          Test.stopTest();
          
          
          System.assertEquals(cc.Id, ptList[0].NSP_Assignee__c);
          
    }


}