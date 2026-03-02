public with sharing class WrapTermination {
    // test w/ SingleTermFormController_Test (96%)

    public String clinetName { get; set; }
    public String clinetNumber { get; set; }
    public Decimal eeNumber { get; set; }
    public String psName { get; set; }
    public String clName { get; set; }
    public Date csaTerm { get; set; }
    public Date beneterm { get; set; }
    public String reason { get; set; }
    public String saName { get; set; }
    public String clientnumber { get; set; }
    public String clientname { get; set; }
    public String revision { get; set; }
    public Date previousTermDate { get; set; }
    public String subTermReason { get; set; }
    public Date previousBeneTerm { get; set; }
    public String previousTermReason { get; set; }
    public Date clienTermDate { get; set; }
    public String previousReason { get; set; }
    public String previousSubtermReason { get; set; }
    public Date previousClientTermdate { get; set; }

    private static final Map<String, Schema.SObjectField> terminationFieldMap = Schema.SObjectType.NSP_Termination_Form__c.fields.getMap();

    //This is the contructor method. When we create a new wrapAccount object we pass a Account that is set to the acc property. We also set the selected value to false
    public WrapTermination( NSP_Termination_Form__c termination , Map<String,String> roleMapDetails ) {
        clinetName = WrapTermination.fetchClientName( termination );
        eeNumber = WrapTermination.fetchEENumber( termination );
        if (roleMapDetails != null) {
            psName = this.getRoleName( roleMapDetails , NSP_ServiceConstants.PAYROLL_SPECIALIST );
            clName = this.getJoinedRoleNames(
                roleMapDetails ,
                new List<String>{
                    NSP_ServiceConstants.CLIENT_LIAISION ,
                    NSP_ServiceConstants.BUS_TEAM_HRSP_CL ,
                    NSP_ServiceConstants.MID_MARKET_ACC_EX
                }
            );
            saName = this.getJoinedRoleNames(
                roleMapDetails ,
                new List<String>{
                    NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR ,
                    NSP_ServiceConstants.BUSINESS_PERFORMANCE_CONSULTANT
                }
            );
        }
        //text fields
        clinetNumber = this.populateTextField( termination , 'NSP_Client_Sub_Account_Numbers__c' );
        reason = this.populateTextField( termination , 'NSP_Term_Reason__c' );
        clientnumber = this.populateTextField( termination , 'NSP_New_Client_Number__c' );
        clientname = this.populateTextField( termination , 'NSP_New_Client_Name__c' );
        revision = this.populateTextField( termination , 'NSP_Revision__c' );
        subTermReason = this.populateTextField( termination , 'NSP_SubTerm_reason__c' );
        previousReason = this.populateTextField( termination , 'Previous_Term_Reason__c' );
        previousSubtermReason = this.populateTextField( termination , 'Previous_Sub_Term_Reason__c' );
        //date fields
        previousClientTermdate = termination.Previous_Client_Term_Date__c;
        csaTerm = termination.NSP_Last_Date_Wages_Paid_Through__c;
        beneterm = termination.NSP_Benefit_Termination_Date__c;
        previousTermDate = termination.Previous_term_date__c;
        previousBeneTerm = termination.Previous_Bene_Date__c;
        clientermdate = termination.NSP_Client_Term_Date__c;
    }

    //method to fetch client name
    private static String fetchClientName( NSP_Termination_Form__c termination ) {
        String name = '';
        if ( ( termination != null )
            && ( termination.NSP_Project_Task__c != null )
            && ( termination.NSP_Project_Task__r.pse__Project__c != null )
            && ( termination.NSP_Project_Task__r.pse__Project__r.pse__Account__c != null )
            && String.isNotBlank( termination.NSP_Project_Task__r.pse__Project__r.pse__Account__r.Name )
            )
        {
            name = termination.NSP_Project_Task__r.pse__Project__r.pse__Account__r.Name;
        }
        return name;
    }

    //fetch EE number
    private static decimal fetchEENumber( NSP_Termination_Form__c termination ) {
        Decimal eeNum = 0.0;
        if ( termination != null ) {
            if ( termination.NSP_Number_of_Active_Employees__c != null ) {
                eeNum = termination.NSP_Number_of_Active_Employees__c;
            }
            if ( ( termination.NSP_How_many_employees_were_moved__c != null )
                && ( ( termination.NSP_Term_Reason__c =='1900 Merger with Insperity Client' )
                    || ( termination.NSP_Term_Reason__c =='2700 Change in FEIN' )
                    )
                )
            {
                eeNum = termination.NSP_How_many_employees_were_moved__c;
            }
        }
        return eeNum;
    }

    //populate text fields
    private String populateTextField( NSP_Termination_Form__c termination , String fieldApi ) {
        String fieldValue = 'NA';
        if ( ( termination != null )
            && String.isNotBlank( fieldApi )
            && terminationFieldMap.containsKey( fieldApi )
            && ( termination.get( fieldApi ) != null )
            )
        {
            fieldValue = (String)termination.get( fieldApi );
        }
        return fieldValue;
    }
    
    //method to return role name
    private String getRoleName( Map<String,String> roleMap , String roleKey ) {
        String role = '';
        if ( ( roleMap != null ) 
            && String.isNotBlank( roleKey )
            && roleMap.containsKey( roleKey )
            && ( roleMap.get( roleKey ) != null )
        )
        {
            role = roleMap.get( roleKey );
        }
        return role;
    }

    //method to join the role names in a string
    private String getJoinedRoleNames( Map<String,String> roleMap , List<String> roleKeys ) {
        List<String> names = new List<String>();
        String joinedNames = '';
        if ( ( roleKeys != null )
            && ( !roleKeys.isEmpty() )
            && ( roleMap != null )
            )
        {
            for ( String key : roleKeys ) {
                if ( roleMap.containsKey( key ) ) {
                    names.add( roleMap.get( key ) );
                }
            }
        }
        if ( !names.isEmpty() ) {
            joinedNames = String.join( names , ', ' );
        }
        return joinedNames;
    }
    
    private String formatDate(Date d) {
        String result = 'NA';
        if (d != null) {
            result = d.month() + '/' + d.day() + '/' + d.year();
        }

        return result;
    }
    
    public String getFormattedReinstatementReason() {
        
        String result = '';
        
        Boolean isBlankReason = String.isBlank(reason) || reason == 'NA';
        
        Boolean isRevised =
            revision == 'Yes' &&
            String.isNotBlank(previousReason) &&
            previousReason != 'NA' &&
            previousReason != reason;
        
        if (isBlankReason) {
            result = 'NA';
        } 
        else if (isRevised) {
            result = 'REVISED ' + reason +' (Previous Reason: ' + previousReason + ')';
        } 
        else {
            result = reason;
        }
        
        return result;   
    }
    
    public String getFormattedReinstatementCsaTerm() {
        
        Boolean isRevised =
            revision == 'Yes' &&
            previousClientTermdate != null &&
            previousClientTermdate != clientermdate;
        
        String result = 'NA';
        
        if (clientermdate != null) {
            if (isRevised) {
                result = 'REVISED ' + this.formatDate(clientermdate) +' (Previous Term Date: ' +this.formatDate(previousClientTermdate) + ')';
            } else {
                result = this.formatDate(clientermdate);
            }
        }
        
        return result;
    }

}
//