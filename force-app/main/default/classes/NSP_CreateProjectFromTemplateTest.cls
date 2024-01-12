@isTest
private class NSP_CreateProjectFromTemplateTest {
    private static final String ACCOUNTDEFAULTS = 'NSP_TestDataFactory.AccountDefaults';
    private static final String ASSETDEFAULTS = 'NSP_TestDataFactory.AssetDefaults';
    
    @isTest static void testButton() {
        Account acc = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), ACCOUNTDEFAULTS, true);
        Case case1 = new Case();
        case1.Subject = 'Test Case Project';
        case1.Status = 'Open';
        case1.Origin = 'Phone';
        case1.AccountId = acc.Id;

        pse__Proj__c proj1 = new pse__Proj__c();
        proj1.pse__Start_Date__c = Date.Today();
        proj1.Name = 'Test';
        proj1.pse__Is_Template__c = true;
        insert proj1;
        case1.Project_Template__c = proj1.Id;
        insert case1;
        
        Asset assetObj = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), ASSETDEFAULTS, false);
        assetObj.Project_Template__c = proj1.Id;
        assetObj.AccountId = acc.Id;
        INSERT assetObj;

        Test.StartTest();
         PageReference pageRef = Page.NSP_CreateProjectForCase; 
         pageRef.getParameters().put('id', String.valueOf(case1.Id));
         Test.setCurrentPage(pageRef);
  
        ApexPages.StandardController sc = new ApexPages.StandardController(case1);
        NSP_CreateProjectFromTemplate scc = new NSP_CreateProjectFromTemplate(sc);
        scc.inputProj = proj1;
        scc.setassetRef(assetObj);
        PageReference returnPage = scc.createProject();
        Test.StopTest();
    
        //Check input fields from Visualforce page match
        System.assertEquals(Date.Today(), scc.inputProj.pse__Start_Date__c, 'inputted start date does not match');
        pse__Proj__c proj = [SELECT Id, Name FROM pse__Proj__c WHERE Id != null LIMIT 1];
        PageReference testPage = new PageReference('/' + proj.Id);
    }
    
    /* Commented Date : 13/Oct
    @isTest static void testGetProject(){
        Case c = new Case();
        ApexPages.StandardController sc = new ApexPages.StandardController(c);
        SimpleCPFTController scc = new SimpleCPFTController(sc);
        Test.StartTest();        
        pse__Proj__c proj = scc.inputProj;
        Test.StopTest();
        
        System.assertNotEquals(null, proj, 'dummy project should be created by controller');
    }*/

    @isTest static void testNoStartDate(){
		PageReference returnPage;
        Case case2 = new Case();
        case2.Subject = 'Test Case Project';
        case2.Status = 'Open';
        case2.Origin = 'Phone';

        pse__Proj__c proj2 = new pse__Proj__c();
        proj2.Name = 'Test';
        proj2.pse__Is_Template__c = true;
		proj2.pse__Start_Date__c = Date.Today();
        insert proj2;
        case2.Project_Template__c = proj2.Id;
        insert case2;

        try{
            Test.StartTest();
            PageReference pageRef = Page.NSP_CreateProjectForCase; 
             pageRef.getParameters().put('id', String.valueOf(case2.Id));
             Test.setCurrentPage(pageRef);
             
            ApexPages.StandardController sc = new ApexPages.StandardController(case2);
            NSP_CreateProjectFromTemplate scc = new NSP_CreateProjectFromTemplate(sc);
            scc.inputProj = proj2;
            returnPage = scc.createProject();
            Test.StopTest();
        }catch(Exception ex){
            System.assertEquals( returnPage.getURL(), 'Not redirected to correct page');
        }
    }
    
    @isTest static void testButtonFromRelatedList() {
        Case case3 = new Case();
        case3.Subject = 'Test Case Project';
        case3.Status = 'Open';
        case3.Origin = 'Phone';

        pse__Proj__c proj3 = new pse__Proj__c();
        proj3.pse__Start_Date__c = Date.Today();
        proj3.Name = 'Test';
        proj3.pse__Is_Template__c = true;
        insert proj3;
        case3.Project_Template__c = proj3.Id;
        insert case3;

        Test.StartTest();
         PageReference pageRef = Page.NSP_CreateProjectFromTemplate; 
         pageRef.getParameters().put('parentid', String.valueOf(case3.Id));
         Test.setCurrentPage(pageRef);
  
        NSP_CreateProjectFromTemplate scc = new NSP_CreateProjectFromTemplate();
        scc.inputProj = proj3;
        PageReference returnPage = scc.createProject();
        scc.getcaseRef();
        scc.getassetRef();
        Test.StopTest();
    
        //Check input fields from Visualforce page match
        System.assertEquals(Date.Today(), scc.inputProj.pse__Start_Date__c, 'inputted start date does not match');
        pse__Proj__c proj = [SELECT Id, Name FROM pse__Proj__c WHERE Id != null LIMIT 1];
        PageReference testPage = new PageReference('/' + proj.Id);
    }
    
    @isTest
    public static void createProject(){
        Case oCase = new Case();
        oCase.Subject = 'Test Case Project';
        oCase.Status = 'Open';
        oCase.Origin = 'Phone';
        oCase.Comments_for_Project__c = 'abc';
        oCase.NSP_Due_Date__c = Date.Today();

        pse__Proj__c oProject = new pse__Proj__c();
        oProject.pse__Start_Date__c = Date.Today();
        oProject.Name = 'Test';
        oProject.pse__Is_Template__c = true;
        insert oProject;
        oCase.Project_Template__c = oProject.Id;
        insert oCase;
        
        //Account  Contact
        Account oAccount = createAccount('ABC Account',true);
        Contact oContact = createContact('First','Last',false);
        oContact.AccountId = oAccount.Id;
        insert oContact;
        Asset oAsset = new Asset();
        oAsset.Name = 'Test Asset';
        oAsset.AccountId = oAccount.Id;
        oAsset.ContactId = oContact.Id;
        insert oAsset;
        Project_Asset__c projAsset = new Project_Asset__c ();
        projAsset.Project__c = oProject.Id;
        projAsset.Asset__c = oAsset.Id;
        insert projAsset;
        Test.startTest();
        NSP_CreateProjectFromTemplate.createProject('Case', oCase.Id, JSON.serialize(new Case(Project_Template__c = oProject.Id,Subject = 'Test Project')),Date.today());
        ResponseWrapper oProjectWrapper = NSP_CreateProjectFromTemplate.createProject('Asset', oAsset.Id, JSON.serialize(new Asset(Project_Template__c = oProject.Id,Name = 'Test Project')),Date.today());
        Test.stopTest();
        System.assertEquals(1, [SELECT count() FROM pse__Proj__c WHERE Case__c =: oCase.Id]);
        System.assertEquals(1, [SELECT count() FROM Project_Asset__c WHERE Asset__c =: oAsset.Id AND Project__c =: oProjectWrapper.data]);

        //query related project
        pse__Proj__c projectRec = [SELECT Name,Go_Live_Date__c,Comments__c FROM pse__Proj__c WHERE Case__c =: oCase.Id LIMIT 1];
        System.assertEquals('abc',projectRec.Comments__c,'Comments Sourced from Case');
        System.assertEquals(Date.Today(),projectRec.Go_Live_Date__c,' Go Live Date sourced from Case');
    }
    
    public static Account createAccount(String accountName, Boolean doInsert){
        Account oAccount = new Account(Name = accountName);
        if(doInsert){
            insert oAccount;
        }
        return oAccount;
	}
    
    public static Contact createContact(String firstName,String lastName, Boolean doInsert){
        Contact oContact = new Contact(FirstName = firstName, LastName = lastName);
        if(doInsert){
            insert oContact;
        }
        return oContact;
	}
}