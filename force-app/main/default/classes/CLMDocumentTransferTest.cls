@isTest
public class CLMDocumentTransferTest 
{
    @isTest
    private static void testCLMDocSettings()
    {   
        account acct = new account();
        acct.name='Test';
        insert acct;
        
        
        blng__Invoice__c blnginv = new blng__Invoice__c();
        blnginv.blng__Account__c = acct.id;
        insert blnginv;
        
        DocuSign_Settings__c scset = new DocuSign_Settings__c();
        scset.IsEnabled__c = true;
        scset.name = 'test';
        insert scset;
        
        ContentVersion cv = new ContentVersion();
        cv.VersionData = Blob.valueOf('Test Content');
        cv.Title = 'test';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.NSP_Signature_Date__c = System.today();
        insert cv;
        
        //Get Content Version
        List<ContentVersion> cvList = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        System.assertEquals(cvList.size(), 1);
        system.debug('ContentVersionID : ' + cvList[0].Id);
        
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = blnginv.id;
        cdl.ContentDocumentId = cvList[0].ContentDocumentId;
        cdl.shareType = 'V';
        insert cdl;  
        
        test.startTest();
        //CLMDocumentTransfer clmdoctrf = new CLMDocumentTransfer();
        //clmdoctrf.downloadDocumentById(cv.id,cdl.LinkedEntityId);
         CLMDocumentTransfer.downloadDocument(cv.id,cdl.LinkedEntityId);
        test.stopTest();
    }

}