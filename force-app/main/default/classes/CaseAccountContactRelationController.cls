public without sharing class CaseAccountContactRelationController {
    // test w/ CaseAccountContactRelationControllerTest (91%)

    @AuraEnabled(cacheable=false)
    public static List<Detail> getACRDetails( Id caseId ) {
        List<Detail> acrcdList = new List<Detail>();
        try {
            Case record = CaseAccountContactRelationController.selectCase( caseId );
            if ( record != null ) {
                List<AccountContactRelation> aCRList = [
                    SELECT
                        Id ,
                        AccountId ,
                        ContactId ,
                        Account.Name ,
                        Contact_Name__c ,
                        NSP_Work_Email__c ,
                        NSP_Work_Phone__c ,
                        NSP_Job_Title__c ,
                        Contact.NSP_IsPrimary__c ,
                        Contact.NSP_Employee_Status__c ,
                        Contact.Salutation ,
                        NSP_Employee_Status__c ,
                        Workday_Employee_ID__c
                    FROM AccountContactRelation
                    WHERE (
                        ( AccountId = :record.AccountId )
                        AND (
                            ContactId IN (
                                SELECT NSP_Contact__c
                                FROM NSP_Case_Contacts__c
                                WHERE ( NSP_Case__c = :record.Id )
                            )
                        )
                    )
                ];
                Map<Id,NSP_Case_Contacts__c> caseConMap = CaseAccountContactRelationController.buildCaseContactMap( record.Id );
                for ( AccountContactRelation acr : aCRList ) {
                    Detail acrcd = CaseAccountContactRelationController.buildDetail(
                        acr ,
                        caseConMap
                    );
                    if ( acrcd != null ) {
                        acrcdList.add( acrcd );
                    }
                }
            }
        } catch ( Exception e ) {
            throw new AuraHandledException( e.getMessage() );
        }
        return acrcdList;
    }

    private class Detail {
        @AuraEnabled
        public Id recordId { get; set; }
        @AuraEnabled
        public String workEmail { get; set; }
        @AuraEnabled
        public String workPhone { get; set; }
        @AuraEnabled
        public String accountName { get; set; }
        @AuraEnabled
        public String contactName { get; set; }
        @AuraEnabled
        public String jobTitle { get; set; }
        @AuraEnabled
        public Boolean isPrimary { get; set; }
        @AuraEnabled
        public String status { get; set; }
        @AuraEnabled
        public String workdayEmployeeId { get; set; }
    }

    private static Detail buildDetail(
        AccountContactRelation record ,
        Map<Id,NSP_Case_Contacts__c> caseConMap
        )
    {
        Detail acrcd = null;
        if ( record != null ) {
            acrcd = new Detail();
            acrcd.recordId = record.Id;
            acrcd.workEmail = record.NSP_Work_Email__c;
            acrcd.workPhone = record.NSP_Work_Phone__c;
            acrcd.jobTitle = record.NSP_Job_Title__c;
            acrcd.accountName = record.Account.Name;
            acrcd.contactName = record.Contact_Name__c;
            if ( ( record.Contact != null )
                && String.isNotBlank( record.Contact.Salutation )
                )
            {
                acrcd.contactName = record.Contact.Salutation + ' ' + record.Contact_Name__c;
            }
            acrcd.isPrimary = false;
            if ( ( caseConMap != null )
                && caseConMap.containsKey( record.ContactId )
                && ( caseConMap.get( record.ContactId ) != null )
                )
            {
                acrcd.isPrimary = caseConMap.get( record.ContactId ).NSP_IsPrimary__c;
            }
            acrcd.status = record.NSP_Employee_Status__c;
            acrcd.workdayEmployeeId = record.Workday_Employee_ID__c;
        }
        return acrcd;
    }

    private static Map<Id,NSP_Case_Contacts__c> buildCaseContactMap( Id recordId ) {
        Map<Id,NSP_Case_Contacts__c> caseConMap = new Map<Id,NSP_Case_Contacts__c>();
        if ( recordId != null ) {
            List<NSP_Case_Contacts__c> caseConList = [
                SELECT
                    Id ,
                    NSP_Contact__c ,
                    NSP_IsPrimary__c ,
                    Workday_Employee_ID__c
                FROM NSP_Case_Contacts__c
                WHERE (
                    NSP_Case__c = :recordId
                    AND NSP_Contact__c != null
                )
            ];
            if ( !caseConList.isEmpty() ) {
                for ( NSP_Case_Contacts__c caseCon : caseConList ) {
                    caseConMap.put(
                        caseCon.NSP_Contact__c ,
                        caseCon
                    );
                }
            }
        }
        return caseConMap;
    }

    private static Case selectCase( Id recordId ) {
        Case record = null;
        if ( recordId != null ) {
            List<Case> records = [
                SELECT
                    Id ,
                    AccountId ,
                    ContactId
                FROM Case
                WHERE ( Id = :recordId )
                LIMIT 1
            ];
            if ( ( records != null ) && !records.isEmpty() ) {
                record = records[0];
            }
        }
        return record;
    }

}
//