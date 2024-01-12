/**
* @description  : Test Class for NSP_EmailImageController Class
* @date 02/02/2023
* Name : NSP_EmailImageControllerTest
*/

@isTest
public class NSP_EmailImageControllerTest {
	
    @testSetup
    static void testData() { 
        List<Document> docList = new List<Document>();
    	Document doc1 = (Document)NSP_TestExtendedDataFactory.createSObject(new Document(), 'NSP_TestDataFactory.DocumentDefaults', false);
        doc1.DeveloperName = 'Insperity_Footer_Logo';
        doc1.IsPublic = true;
        doc1.Name = 'Insperity Footer Logo';
        docList.add(doc1);
        
        Document doc2 = (Document)NSP_TestExtendedDataFactory.createSObject(new Document(), 'NSP_TestDataFactory.DocumentDefaults', false);
        doc2.DeveloperName = 'Insperity_HR';
        doc2.IsPublic = true;
        doc2.Name = 'Insperity HR';
        docList.add(doc2);
        
        if(!docList.isEmpty()){
            database.insert(docList);
        }
            

    }
    
    @isTest
    static void getURLsTest(){
        
        Test.startTest();
        NSP_EmailImageController emailController = new NSP_EmailImageController();
        String footLogoUrl = emailController.getFooterLogoUrl();
        String headLogoUrl = emailController.getHeaderLogoUrl();
        System.assert(footLogoUrl != '');
        System.assert(headLogoUrl != '');
        Test.stopTest();
    }
}