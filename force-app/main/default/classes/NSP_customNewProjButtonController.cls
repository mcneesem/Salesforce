public class NSP_customNewProjButtonController {
    // test w/ NSP_customNewProjButtonControllerTest (83%)

    // STY-01938 ~ method to check if a User is allowed to create Project via custom components...
    @AuraEnabled(cacheable=false)
    public static Boolean isUserPermittedToCreateProject( Id currentUserId ) {
        //query login in user
        try {
            List<String> fields = new List<String>();
            fields.add( 'NSP_Profile_Name__c' );
            User record = (User) new NSP_sObjectSelector( 'User' , fields ).selectById( currentUserId );
            Boolean isAllowedCreate = False;
            if ( String.isNotBlank( record.NSP_Profile_Name__c )
                && record.NSP_Profile_Name__c.startsWith( 'System Admin' )
               )
            {
                isAllowedCreate = True;
            }
            return isAllowedCreate;
        } catch ( Exception ex ) {
            throw NSP_Utilities.getAuraException( ex );
        }
    }
    
}
//