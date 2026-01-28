@isTest
private class NSP_EmailImageControllerTest {

    @testSetup private static void testData() { 
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

        Document doc3 = (Document)NSP_TestExtendedDataFactory.createSObject(new Document(), 'NSP_TestDataFactory.DocumentDefaults', false);
        doc3.DeveloperName = 'Insperity_Service_Operations';
        doc3.IsPublic = true;
        doc3.Name = 'Insperity Service Operations';
        docList.add(doc3);

        Document doc4 = (Document)NSP_TestExtendedDataFactory.createSObject(new Document(), 'NSP_TestDataFactory.DocumentDefaults', false);
        doc4.DeveloperName = 'Insperity_Copy_write_logo';
        doc4.IsPublic = true;
        doc4.Name = 'Insperity Copy Write logo';
        docList.add(doc4);

        Document doc5 = (Document)NSP_TestExtendedDataFactory.createSObject(new Document(), 'NSP_TestDataFactory.DocumentDefaults', false);
        doc5.DeveloperName = 'Insperity_HR_Logo';
        doc5.IsPublic = true;
        doc5.Name = 'Insperity HR Logo';
        docList.add(doc5);

        if(!docList.isEmpty()){
            database.insert(docList);
        }
    }

    @isTest private static void getURLsTest(){
        Test.startTest();
        NSP_EmailImageController emailController = new NSP_EmailImageController();
        String footLogoUrl = emailController.getFooterLogoUrl();
        String headLogoUrl = emailController.getHeaderLogoUrl();
        String servicelogoUrl = emailController.getServiceOperationsLogoUrl();
        String copywriteUrl = emailController.getCopyWriteLogoUrl();
        String hrLogoUrl = emailController.getHRLogoLogoUrl();
        String signatureLogoUrl = emailController.getSignatureLogoUrl();
        System.assert(footLogoUrl != '');
        System.assert(headLogoUrl != '');
        System.assert(servicelogoUrl != '');
        System.assert(copywriteUrl != '');
        System.assert(hrLogoUrl != '');
        System.assert(signatureLogoUrl != '');
        Test.stopTest();
    }

}
//