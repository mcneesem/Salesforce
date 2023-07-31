public class NSP_EmailImageController {
    
    static List<String> FIELDS = new List<String>{'Id'};
    
    // Getting the Document Id and creating a Document Url.
    public String getFooterLogoUrl(){
        String query = new NSP_QueryBuilder('Document', FIELDS)
            							   .addFilter('DeveloperName', 'Insperity_Footer_Logo')
            							   .build() ;
        Document lstDocument = Database.query(query);
        String strOrgId = UserInfo.getOrganizationId();
		String footerLogoUrl = System.URL.getSalesforceBaseUrl().toExternalForm() + 
            				   '/servlet/servlet.ImageServer?id='+lstDocument.Id +
            				   '&oid=' + strOrgId;
        return footerLogoUrl;
    }
    
     // Getting the Document Id and creating a Document Url.
    public String getHeaderLogoUrl(){
        String query = new NSP_QueryBuilder('Document', FIELDS)
            							    .addFilter('DeveloperName', 'Insperity_HR')
                                            .build()  ;
        Document lstDocument = Database.query(query);
		String strOrgId = UserInfo.getOrganizationId();
		String headerLogoUrl = System.URL.getSalesforceBaseUrl().toExternalForm() + 
            				   '/servlet/servlet.ImageServer?id='+lstDocument.Id +
            				   '&oid=' + strOrgId;
        return headerLogoUrl;
    }


}