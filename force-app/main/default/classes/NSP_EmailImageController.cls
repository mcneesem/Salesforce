public class NSP_EmailImageController {
    // test w/ NSP_EmailImageControllerTest (100%)

    // referenced by InsperityEmailHeader.component...
    public String getHeaderLogoUrl() {
        return getStaticResourceUrl( 'Insperity_HR' );
    }

    // referenced by InsperityEmailHeader.component...
    public String getFooterLogoUrl() {
        return getStaticResourceUrl( 'Insperity_Footer_Logo' );
    }

    // referenced by NSP_TerminationFormTemplate.component...
    public String getServiceOperationsLogoUrl() {
        return getStaticResourceUrl( 'Insperity_Service_Operations' );
    }

    // referenced by NSP_TerminationFormTemplate.component...
    public String getCopyWriteLogoUrl() {
        return getStaticResourceUrl( 'Insperity_Copyright_Logo' );
    }

    // referenced by NSP_TerminationFormTemplate.component...
    public String getHRLogoLogoUrl() {
        return getStaticResourceUrl( 'Insperity_HR_Logo' );
    }

    // build the Static Resource Url....
    private String getStaticResourceUrl(String resourceName) {
        return System.URL.getOrgDomainUrl().toExternalForm()
        + '/resource/' + resourceName;
    }
}
//