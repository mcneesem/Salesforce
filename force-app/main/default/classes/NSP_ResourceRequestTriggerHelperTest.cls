/**
Apex Class Name      :  NSP_ResourceRequestTriggerHelperTest for NSP_ResourceRequestTriggerHelper
Version              :  1.0                                                                          
Created Date         :  12/9/2022   
Function             :  Test class for NSP_ResourceRequestTriggerHelper 
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Srushti                     12/9/2022            First Iteration
*/

@isTest
public class NSP_ResourceRequestTriggerHelperTest {
	
    @testSetup 
    private static void setUpTestData(){
        //Get RET Project Type Record Type Id
        Id retProjectTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c','RET_Deconversion_2020_Form');
        //Creating a region record
        pse__Region__c oRegion = new pse__Region__c();
        oRegion.Name = 'United States';
        Database.insert(oRegion);
        
        User currentUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), false);
        Database.insert(currentUser);
        
        pse__Permission_Control__c permControl = (pse__Permission_Control__c)NSP_TestExtendedDataFactory.createSObject(new pse__Permission_Control__c(), false);
        permControl.pse__User__c = userinfo.getUserId() ;
		permControl.pse__Resource_Request_Entry__c = true;
        permControl.pse__Region__c = oRegion.Id;
        permControl.pse__Staffing__c = true;
        Database.insert(permControl);
        
        //creating a contact rec
        Contact oContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        oContact.pse__Salesforce_User__c = UserInfo.getUserId();
        oContact.pse__Is_Resource__c = True;
        oContact.pse__Is_Resource_Active__c = true;
        Database.insert(oContact);
        
        User newUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', false);
        newUser.UserName =  Integer.valueOf(math.rint(math.random() * 1000000))+ '@test' + UserInfo.getOrganizationId()+ '.org';
        
        Contact oContact1 = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        oContact1.NSP_Buying_Role__c = 'Key decision maker';
        oContact1.pse__Salesforce_User__c = newUser.Id;
        oContact1.pse__Is_Resource__c = True;
        oContact1.pse__Is_Resource_Active__c = true;
        Database.insert(oContact1);

        
        //creating a project rec
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.Name = 'Test Delete 1';
        oProject.RecordTypeId = retProjectTypeId;
        Database.insert(oProject);
        
        //creating a resource request record
        pse__Resource_Request__c oResourceRequest = new pse__Resource_Request__c();
        oResourceRequest.pse__Resource_Role__c = 'RET Compliance';
        oResourceRequest.pse__Staffer_Resource__c = oContact.Id; 
        oResourceRequest.pse__Project__c = oProject.Id;
        oResourceRequest.pse__End_Date__c = System.today();
        oResourceRequest.pse__Region__c = oRegion.Id;
        oResourceRequest.pse__SOW_Hours__c = 123;
        oResourceRequest.pse__Start_Date__c = System.today();
        insert oResourceRequest;

    }
    
    @isTest
    private static void sendEmailTest0(){
        Contact con = [SELECT Id, NSP_Buying_Role__c FROM Contact WHERE NSP_Buying_Role__c =: 'Key decision maker'];
        pse__Resource_Request__c resourceRec = [SELECT Id, pse__End_Date__c, pse__Resource_Role__c, pse__Staffer_Resource__c 
                                                FROM pse__Resource_Request__c WHERE pse__Resource_Role__c =: 'RET Compliance' LIMIT 1];
        
        resourceRec.pse__Resource_Role__c = 'RET Finance';
        resourceRec.pse__Staffer_Resource__c = con.Id;
        Test.startTest();
        Database.update(resourceRec);
        system.assertEquals( resourceRec.pse__Resource_Role__c, 'RET Finance');
        Test.stopTest();
    }
    @isTest
    private static void sendEmailTest1(){
        Contact con = [SELECT Id, NSP_Buying_Role__c FROM Contact WHERE NSP_Buying_Role__c =: 'Key decision maker'];
        pse__Resource_Request__c resourceRec = [SELECT Id, pse__End_Date__c, pse__Resource_Role__c, pse__Staffer_Resource__c 
                                                FROM pse__Resource_Request__c WHERE pse__Resource_Role__c =: 'RET Compliance' LIMIT 1];
        
        resourceRec.pse__Resource_Role__c = 'RET NBI - Conversion & Ork';
        resourceRec.pse__Staffer_Resource__c = con.Id;
        Test.startTest();
        Database.update(resourceRec);
        system.assertEquals(resourceRec.pse__Resource_Role__c, 'RET NBI - Conversion & Ork');
        Test.stopTest();
    }@isTest
    private static void sendEmailTest2(){
        Contact con = [SELECT Id, NSP_Buying_Role__c FROM Contact WHERE NSP_Buying_Role__c =: 'Key decision maker'];
        pse__Resource_Request__c resourceRec = [SELECT Id, pse__End_Date__c, pse__Resource_Role__c, pse__Staffer_Resource__c 
                                                FROM pse__Resource_Request__c WHERE pse__Resource_Role__c =: 'RET Compliance' LIMIT 1];
        
        resourceRec.pse__Resource_Role__c = 'RET NBI - Implementation';
        resourceRec.pse__Staffer_Resource__c = con.Id;
        Test.startTest();
        Database.update(resourceRec);
        system.assertEquals(resourceRec.pse__Resource_Role__c, 'RET NBI - Implementation');
        Test.stopTest();
    }
    @isTest
    private static void sendEmailTest3(){
        Contact con = [SELECT Id, NSP_Buying_Role__c FROM Contact WHERE NSP_Buying_Role__c =: 'Key decision maker'];
        pse__Resource_Request__c resourceRec = [SELECT Id, pse__End_Date__c, pse__Resource_Role__c, pse__Staffer_Resource__c 
                                                FROM pse__Resource_Request__c WHERE pse__Resource_Role__c =: 'RET Compliance' LIMIT 1];
        
        resourceRec.pse__Resource_Role__c = 'RET NBI - QC Analyst';
        resourceRec.pse__Staffer_Resource__c = con.Id;
        Test.startTest();
        Database.update(resourceRec);
        system.assertEquals(resourceRec.pse__Resource_Role__c, 'RET NBI - QC Analyst');
        Test.stopTest();
    }
    @isTest
    private static void sendEmailTest4(){
        Contact con = [SELECT Id, NSP_Buying_Role__c FROM Contact WHERE NSP_Buying_Role__c =: 'Key decision maker'];
        pse__Resource_Request__c resourceRec = [SELECT Id, pse__End_Date__c, pse__Resource_Role__c, pse__Staffer_Resource__c 
                                                FROM pse__Resource_Request__c WHERE pse__Resource_Role__c =: 'RET Compliance' LIMIT 1];
        
        resourceRec.pse__Resource_Role__c = 'RET Ops - OMNI';
        resourceRec.pse__Staffer_Resource__c = con.Id;
        Test.startTest();
        Database.update(resourceRec);
        system.assertEquals(resourceRec.pse__Resource_Role__c, 'RET Ops - OMNI');
        Test.stopTest();
    }
    @isTest
    private static void sendEmailTest5(){
        Contact con = [SELECT Id, NSP_Buying_Role__c FROM Contact WHERE NSP_Buying_Role__c =: 'Key decision maker'];
        pse__Resource_Request__c resourceRec = [SELECT Id, pse__End_Date__c, pse__Resource_Role__c, pse__Staffer_Resource__c 
                                                FROM pse__Resource_Request__c WHERE pse__Resource_Role__c =: 'RET Compliance' LIMIT 1];
        
        resourceRec.pse__Resource_Role__c = 'RET Ops - Processing';
        resourceRec.pse__Staffer_Resource__c = con.Id;
        Test.startTest();
        Database.update(resourceRec);
        system.assertEquals(resourceRec.pse__Resource_Role__c, 'RET Ops - Processing');
        Test.stopTest();
    }
    @isTest
    private static void sendEmailTest6(){
        Contact con = [SELECT Id, NSP_Buying_Role__c FROM Contact WHERE NSP_Buying_Role__c =: 'Key decision maker'];
        pse__Resource_Request__c resourceRec = [SELECT Id, pse__End_Date__c, pse__Resource_Role__c, pse__Staffer_Resource__c 
                                                FROM pse__Resource_Request__c WHERE pse__Resource_Role__c =: 'RET Compliance' LIMIT 1];
        
        resourceRec.pse__Resource_Role__c = 'RET Plan Consulting';
        resourceRec.pse__Staffer_Resource__c = con.Id;
        Test.startTest();
        Database.update(resourceRec);
        system.assertEquals(resourceRec.pse__Resource_Role__c, 'RET Plan Consulting');
        Test.stopTest();
    }
    @isTest
    private static void sendEmailTest7(){
        Contact con = [SELECT Id, NSP_Buying_Role__c FROM Contact WHERE NSP_Buying_Role__c =: 'Key decision maker'];
        pse__Resource_Request__c resourceRec = [SELECT Id, pse__End_Date__c, pse__Resource_Role__c, pse__Staffer_Resource__c 
                                                FROM pse__Resource_Request__c WHERE pse__Resource_Role__c =: 'RET Compliance' LIMIT 1];
        
        resourceRec.pse__Resource_Role__c = 'RET Sales';
        resourceRec.pse__Staffer_Resource__c = con.Id;
        Test.startTest();
        Database.update(resourceRec);
        system.assertEquals(resourceRec.pse__Resource_Role__c, 'RET Sales');
        Test.stopTest();
    }
    @isTest
    private static void sendEmailTest8(){
        Contact con = [SELECT Id, NSP_Buying_Role__c FROM Contact WHERE NSP_Buying_Role__c =: 'Key decision maker'];
        pse__Resource_Request__c resourceRec = [SELECT Id, pse__End_Date__c, pse__Resource_Role__c, pse__Staffer_Resource__c 
                                                FROM pse__Resource_Request__c WHERE pse__Resource_Role__c =: 'RET Compliance' LIMIT 1];
        
        resourceRec.pse__Resource_Role__c = 'RET CSP Processing';
        resourceRec.pse__Staffer_Resource__c = con.Id;
        Test.startTest();
        Database.update(resourceRec);
        system.assertEquals(resourceRec.pse__Resource_Role__c, 'RET CSP Processing');
        Test.stopTest();
    }
    @isTest
    private static void sendEmailTest9(){
        Contact con = [SELECT Id, NSP_Buying_Role__c FROM Contact WHERE NSP_Buying_Role__c =: 'Key decision maker'];
        pse__Resource_Request__c resourceRec = [SELECT Id, pse__End_Date__c, pse__Resource_Role__c, pse__Staffer_Resource__c 
                                                FROM pse__Resource_Request__c WHERE pse__Resource_Role__c =: 'RET Compliance' LIMIT 1];
        
        resourceRec.pse__Resource_Role__c = 'RET CSP Implementation';
        resourceRec.pse__Staffer_Resource__c = con.Id;
        Test.startTest();
        Database.update(resourceRec);
        system.assertEquals(resourceRec.pse__Resource_Role__c, 'RET CSP Implementation');
        Test.stopTest();
    }
    @isTest
    private static void sendEmailTest10(){
        Contact con = [SELECT Id, NSP_Buying_Role__c FROM Contact WHERE NSP_Buying_Role__c =: 'Key decision maker'];
        pse__Resource_Request__c resourceRec = [SELECT Id, pse__End_Date__c, pse__Resource_Role__c, pse__Staffer_Resource__c 
                                                FROM pse__Resource_Request__c WHERE pse__Resource_Role__c =: 'RET Compliance' LIMIT 1];
        
        resourceRec.pse__Resource_Role__c = 'RET CSP Compliance';
        resourceRec.pse__Staffer_Resource__c = con.Id;
        Test.startTest();
        Database.update(resourceRec);
        system.assertEquals(resourceRec.pse__Resource_Role__c, 'RET CSP Compliance');
        Test.stopTest();
    }
    @isTest
    private static void sendEmailTest11(){
        Contact con = [SELECT Id, NSP_Buying_Role__c FROM Contact WHERE NSP_Buying_Role__c =: 'Key decision maker'];
        pse__Resource_Request__c resourceRec = [SELECT Id, pse__End_Date__c, pse__Resource_Role__c, pse__Staffer_Resource__c 
                                                FROM pse__Resource_Request__c WHERE pse__Resource_Role__c =: 'RET Compliance' LIMIT 1];
        
        resourceRec.pse__Resource_Role__c = 'RET CSP Plan Consulting';
        resourceRec.pse__Staffer_Resource__c = con.Id;
        Test.startTest();
        Database.update(resourceRec);
        system.assertEquals(resourceRec.pse__Resource_Role__c, 'RET CSP Plan Consulting');
        Test.stopTest();
    }
    @isTest
    private static void sendEmailTest12(){
        Contact con = [SELECT Id, NSP_Buying_Role__c FROM Contact WHERE NSP_Buying_Role__c =: 'Key decision maker'];
        pse__Resource_Request__c resourceRec = [SELECT Id, pse__End_Date__c, pse__Resource_Role__c, pse__Staffer_Resource__c 
                                                FROM pse__Resource_Request__c WHERE pse__Resource_Role__c =: 'RET Compliance' LIMIT 1];
        
        resourceRec.pse__Resource_Role__c = 'RET SRP';
        resourceRec.pse__Staffer_Resource__c = con.Id;
        Test.startTest();
        Database.update(resourceRec);
        system.assertEquals(resourceRec.pse__Resource_Role__c, 'RET SRP');
        Test.stopTest();
    }
    @isTest
    private static void sendEmailTest13(){
        Contact con = [SELECT Id, NSP_Buying_Role__c FROM Contact WHERE NSP_Buying_Role__c =: 'Key decision maker'];
        pse__Resource_Request__c resourceRec = [SELECT Id, pse__End_Date__c, pse__Resource_Role__c, pse__Staffer_Resource__c 
                                                FROM pse__Resource_Request__c WHERE pse__Resource_Role__c =: 'RET Compliance' LIMIT 1];
        
        resourceRec.pse__Resource_Role__c = 'RET ORK';
        resourceRec.pse__Staffer_Resource__c = con.Id;
        Test.startTest();
        Database.update(resourceRec);
        system.assertEquals(resourceRec.pse__Resource_Role__c, 'RET ORK');
        Test.stopTest();
    }
}