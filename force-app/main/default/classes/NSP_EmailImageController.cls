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

    // referenced by NSP_TerminationFormTemplate.component...
    public String getServiceOperationsLogoUrl() {
        return getDocumentUrl( 'Insperity_Service_Operations' );
    }

    // referenced by NSP_TerminationFormTemplate.component...
    public String getCopyWriteLogoUrl() {
        return getDocumentUrl( 'Insperity_Copy_write_logo' );
    }

    // referenced by NSP_TerminationFormTemplate.component...
    public String getHRLogoLogoUrl() {
        return getDocumentUrl( 'Insperity_HR_Logo' );
    }

    // referenced by InsperityEmailSignature.component...
    public String getSignatureLogoUrl() {
        return getDocumentUrl( 'Insperity_HR_Logo' );
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
        if ( ( records != null ) && !records.isEmpty() ) {
            documentId = records[0].Id;
        }
        return documentId;
    }

}
//