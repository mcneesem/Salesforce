public class NSP_EmailImageController {
    // test w/ NSP_EmailImageControllerTest (100%)

    // referenced by InsperityEmailHeader.component...
    public String getHeaderLogoUrl() {
        return getDocumentUrl( 'Insperity_HR' );
    }

    // referenced by InsperityEmailHeader.component...
    public String getFooterLogoUrl() {
        return getDocumentUrl( 'Insperity_Footer_Logo' );
    }

    // build the Document Url....
    private String getDocumentUrl( String documentName ) {
        return System.URL.getSalesforceBaseUrl().toExternalForm()
            + '/servlet/servlet.ImageServer?id=' + getDocumentId( documentName )
            + '&oid=' + UserInfo.getOrganizationId();
    }

    // query the Document Id...
    private Id getDocumentId( String documentName ) {
        List<Document> records = [
            SELECT Id
            FROM Document
            WHERE ( DeveloperName = :documentName )
        ];
        Id documentId = null;
        if ( ( records != null ) && ( records.size() > 0 ) ) {
            documentId = records[0].Id;
        }
        return documentId;
    }

}
//