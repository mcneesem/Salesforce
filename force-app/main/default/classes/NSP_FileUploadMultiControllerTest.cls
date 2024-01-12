/**
Apex Class Name      :  NSP_FileUploadMultiControllerTest
Version              :  1.0                                                                          
Created Date         :   7/19/2022  
Function             :   Represents test class for NSP_FileUploadMultiController
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Mani Teja                       7/20/2022             First Iteration
*/


@isTest(SeeAllData=false)
private class NSP_FileUploadMultiControllerTest {
    private static final  Id FSO_RECORD_TYPE_ID = NSP_GenericRecordType.getRecordTypeId('Implementation_Profile__c',NSP_ServiceConstants.FSOProfile );
    /**
* Does test data setup
* @param N/A. 
* @return void                          
*/
    
    @testSetup
    static void testData() {
        list<Implementation_Profile__c> ipListFSA = new list<Implementation_Profile__c>();
        Implementation_Profile__c impl = (Implementation_Profile__c)NSP_TestExtendedDataFactory.createSObject(new Implementation_Profile__c(), 'NSP_TestDataFactory.ImplementationProfileDefaults', false);
        impl.RecordTypeId = FSO_RECORD_TYPE_ID;
        impl.NSP_Form_Completed__c = True;
        ipListFSA.add(impl);
        Implementation_Profile__c implWithoutContentDoc = (Implementation_Profile__c)NSP_TestExtendedDataFactory.createSObject(new Implementation_Profile__c(), 'NSP_TestDataFactory.ImplementationProfileDefaults', false);
        implWithoutContentDoc.NSP_Form_Completed__c = false;
        implWithoutContentDoc.RecordTypeId = FSO_RECORD_TYPE_ID;
        ipListFSA.add(implWithoutContentDoc);
        insert ipListFSA;
        
        ContentVersion newContentVersion = (ContentVersion)NSP_TestExtendedDataFactory.createSObject(new ContentVersion(), 'NSP_TestDataFactory.ContentVersionDefaults', false);
        newContentVersion.NSP_Signature_Date__c = System.today();
        INSERT newContentVersion;
        ContentDocumentLink newContentDocumentLink = (ContentDocumentLink)NSP_TestExtendedDataFactory.createSObject(new ContentDocumentLink(), 'NSP_TestDataFactory.ContentDocumentLinkDefaults', false);
        newContentDocumentLink.LinkedEntityId = impl.id;
        newContentDocumentLink.contentdocumentid=[SELECT contentdocumentid FROM contentversion WHERE id =: newContentVersion.id].contentdocumentid;
        insert newContentDocumentLink;        
    }
       /**
* @Description: This test method is used to cover releatedFiles method
* @Created date: 07/20/2022. 
* @return void             
*     */ 
    @isTest
    static void releatedFilesTest(){
        Implementation_Profile__c getImpProfile = [SELECT Id,
                                                   NSP_Form_Completed__c 
                                                   FROM Implementation_Profile__c 
                                                   WHERE NSP_Form_Completed__c = true
                                                   LIMIT 1];
        Test.startTest();
        NSP_FileUploadMultiController.releatedFiles(getImpProfile.Id);
        Test.stopTest();
        List<ContentDocumentLink> assertContentDocLiknk =  [SELECT Id, 
                                                           ContentDocumentId 
                                                           FROM ContentDocumentLink 
                                                           WHERE LinkedEntityId =: getImpProfile.Id];
        system.assertEquals(true, assertContentDocLiknk.size()>0);        
    }
           /**
* @Description: This test method is used to cover releatedFiles Negative Test method 
* @Created date: 11/21/2022. 
* @return void             
*     */ 
    @isTest
    static void releatedFilesNegativeTest(){
        Implementation_Profile__c getImpProfile = [SELECT Id,
                                                   NSP_Form_Completed__c 
                                                   FROM Implementation_Profile__c 
                                                   WHERE NSP_Form_Completed__c = false
                                                   LIMIT 1];
        Test.startTest();
        NSP_FileUploadMultiController.releatedFiles(getImpProfile.Id);
        Test.stopTest();
        List<ContentDocumentLink> assertContentDocLiknk =  [SELECT Id, 
                                                           ContentDocumentId 
                                                           FROM ContentDocumentLink 
                                                           WHERE LinkedEntityId =: getImpProfile.Id];
        system.assertNotEquals(true, assertContentDocLiknk.size()>0);        
    }
}