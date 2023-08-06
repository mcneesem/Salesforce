public class NSP_dunningInvoicesListController {

    public String caseIdstr{get;set;}
    public String caseAccountId{get;set;}
    static List<String> FIELDS = new List<String>{'Id'};
    //constructor
    public NSP_dunningInvoicesListController() {
        
        
    }
    
/**
* Method Name : getdunningInvoicesList 
* Description : Method to query the overdue invoices from the account related to Case
* Author : Rakesh       Date : 07/09/2022
* @return List  
*/ 
    public List<blng__Invoice__c> getdunningInvoicesList() {
        List<blng__Invoice__c> overdueInvoices = new List<blng__Invoice__c>();
        overdueInvoices = [SELECT Id, Name, blng__Account__c, blng__DueDate__c, blng__BillToContact__c,blng__InvoiceDate__c, blng__Balance__c, NSP_Invoice_To_Email__c, blng__PaymentStatus__c, blng__InvoiceStatus__c, NSP_Payment_Link__c 
							FROM blng__Invoice__c 
                           	WHERE blng__DueDate__c <= N_DAYS_AGO:30 AND blng__Balance__c > 0 AND blng__InvoiceStatus__c = 'Posted' AND blng__PaymentStatus__c!='Paid' 
                           	AND blng__Account__c=:caseAccountId];
                                           
        return overdueInvoices;
    }

    // Getting the Document Id and creating a Document Url.
    public String getLogoUrl() {
        List<String> FIELDS = new List<String>{'Id'};
        String query = new NSP_QueryBuilder( 'Document' , FIELDS )
            .addFilter( 'DeveloperName' , 'Insperity_HR_Logo' )
            .build();
        List<Document> logoDocuments = Database.query( query );
        Id logoDocumentId = null;
        if ( ( logoDocuments != null ) && ( logoDocuments.size() > 0 ) ) {
            logoDocumentId = logoDocuments[0].Id;
        }
        String logoUrl = ''
            + System.URL.getSalesforceBaseUrl().toExternalForm()
            + '/servlet/servlet.ImageServer'
            + '?id=' + logoDocumentId
            + '&oid=' + UserInfo.getOrganizationId();
        return logoUrl;
    }

}
//