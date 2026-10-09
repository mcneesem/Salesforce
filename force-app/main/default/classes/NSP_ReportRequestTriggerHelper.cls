public with sharing class NSP_ReportRequestTriggerHelper {
    // test w/ NSP_ReportRequestTriggerHelperTest (89%)

    private static final String UNDER_40 = 'Under 40';
    private static final String OVER_40 = 'Over 40';
    private static final String UNKNOWN = 'Unknown';
    private static final String INSPERITY_PREPARED = 'Insperity-Prepared';
    private static final string SEPERATION_AGREEMENT_RECORD_TYPE_ID = NSP_GenericRecordType.getRecordTypeId( 'NSP_ReportRequest__c' , 'NSP_SeparationRequest' );

    public void beforeUpdateDirector( Map<Id,NSP_ReportRequest__c> newMap , Map<Id,NSP_ReportRequest__c> oldMap ) {
        List<NSP_ReportRequest__c> repReqList = new List<NSP_ReportRequest__c>();
        List<NSP_ReportRequest__c> insperityPreparedRepReqList = new List<NSP_ReportRequest__c>();
        Set<Id> repReqContactIds = new Set<Id>();
        Set<Id> repReqAccountIds = new Set<Id>();
        this.beforeInsertDirector( newMap.values() , oldMap );
        //Added the below logic as part of STY-04602
        String YES_VALUE = 'YES';
        for ( NSP_ReportRequest__c repReq: newMap.values() ) {
            if ( YES_VALUE.equalsIgnoreCase( repReq.NSP_RequestingMultipleEmployees__c ) ) {
                repReq.NSP_WSEE__c = null;
                repReq.NSP_Consideration_Amount_min_2wks_Salary__c = null;
            }
            if ( ( repReq.NSP_WSEE__c != oldMap.get( repReq.Id ).NSP_WSEE__c )
                && ( repReq.NSP_RequestingMultipleEmployees__c != NSP_ServiceConstants.YES )
                )
            {
                repReqContactIds.add( repReq.NSP_WSEE__c );
                repReqAccountIds.add( repReq.NSP_ClientName__c );
                repReqList.add( repReq );
            }
            if ( ( repReq.NSP_WSEE__c != oldMap.get( repReq.Id ).NSP_WSEE__c )
                && ( oldMap.get( repReq.Id ).NSP_WSEE__c == null )
                && ( repReq.NSP_AgreementType__c == INSPERITY_PREPARED )
                && ( repReq.NSP_RequestingMultipleEmployees__c == NSP_ServiceConstants.YES )
                )
            {
                insperityPreparedRepReqList.add( repReq );
            }
            // Change By Prakash Jada || Modified Date: Jan 17, 2024 || Description: When the record type is Separation Agreement then check the Request multiple employees field
            if ( repReq.RecordTypeId == SEPERATION_AGREEMENT_RECORD_TYPE_ID ) {
                if ( repReq.NSP_RequestingMultipleEmployees__c == NSP_ServiceConstants.YES ) {
                    repReq.NSP_Consideration_Amount_min_2wks_Salary__c = null;
                } else if ( repReq.NSP_RequestingMultipleEmployees__c == NSP_ServiceConstants.NO ) {
                    repReq.NSP_Severance_Total__c = null;
                }
            }
        }
        if ( !repReqList.isEmpty() && !repReqContactIds.isEmpty() && !repReqAccountIds.isEmpty() ) {
            this.updateWSEEDetails( repReqList , repReqContactIds , repReqAccountIds );
        }
        if ( !insperityPreparedRepReqList.isEmpty() ) {
            this.showValidationForInsperityPrepared( insperityPreparedRepReqList );
        }
    }

    public void beforeInsertDirector( List<NSP_ReportRequest__c> newList , Map<Id,NSP_ReportRequest__c> oldMap ) {
        Id recordTypeId = NSP_GenericRecordType.getRecordTypeId( 'NSP_ReportRequest__c' , 'NSP_DevelopmentReport' );
        Id hrScaleRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'NSP_ReportRequest__c' , 'HRScale_Workday_Report' );
        for ( NSP_ReportRequest__c eachRepoReq : newList ) {
            if ( ( recordTypeId != null ) && ( eachRepoReq.RecordTypeId == recordTypeId ) ) {
                if ( ( eachRepoReq.NSP_Existing_NewReport__c != null )
                    && ( oldMap.size() == 0 || oldMap.get(eachRepoReq.Id)?.NSP_Existing_NewReport__c != eachRepoReq.NSP_Existing_NewReport__c )
                    )
                {
                    if ( eachRepoReq.NSP_Existing_NewReport__c == NSP_ServiceConstants.NEW_REPORT ) {
                        eachRepoReq.NSP_Action__c = NSP_ServiceConstants.WIZARD_DEVELOPMENT;
                        if ( eachRepoReq.NSP_InternalClientReport__c == NSP_ServiceConstants.INTERNAL_REPORT ) {
                            eachRepoReq.NSP_ReportType__c = NSP_ServiceConstants.INTERNAL_CLIENT_REPORT;
                            eachRepoReq.NSP_ReportLocation__c = NSP_ServiceConstants.WEBFOCUS_MRE;
                        }
                    } else {
                        eachRepoReq.NSP_Action__c = NSP_ServiceConstants.WIZARD_MAINTENANCE;
                        eachRepoReq.NSP_ReportLocation__c = null;
                    }
                }
                if ( ( eachRepoReq.NSP_InternalClientReport__c != null )
                    && ( oldMap.size() == 0 || oldMap.get(eachRepoReq.Id)?.NSP_InternalClientReport__c != eachRepoReq.NSP_InternalClientReport__c )
                    )
                {
                    if ( eachRepoReq.NSP_InternalClientReport__c == NSP_ServiceConstants.INTERNAL_REPORT ) {
                        if ( eachRepoReq.NSP_Existing_NewReport__c == NSP_ServiceConstants.NEW_REPORT ) {
                            eachRepoReq.NSP_ReportType__c = NSP_ServiceConstants.INTERNAL_CLIENT_REPORT;
                        }
                        eachRepoReq.NSP_ReportLocation__c = NSP_ServiceConstants.WEBFOCUS_MRE;
                    } else {
                        eachRepoReq.NSP_ReportType__c = null;
                    }
                }
                if ( ( eachRepoReq.NSP_ReportLocation__c != null )
                    && ( oldMap.size() == 0 || oldMap.get(eachRepoReq.Id)?.NSP_ReportLocation__c != eachRepoReq.NSP_ReportLocation__c )
                    )
                {
                    if ( eachRepoReq.NSP_ReportLocation__c == NSP_ServiceConstants.PREMIER_REPORTING ) {
                        eachRepoReq.NSP_Misc__c = NSP_ServiceConstants.WIRE;
                    }
                    if ( eachRepoReq.NSP_ReportLocation__c == NSP_ServiceConstants.WEBFOCUS_MRE ) {
                        eachRepoReq.NSP_Misc__c = NSP_ServiceConstants.NON_WIRE;
                    }
                }
            } else if ( ( hrScaleRecordTypeId != null )
                && ( eachRepoReq.RecordTypeId == hrScaleRecordTypeId )
                )
            {
                NSP_ReportRequestTriggerHelper.processHRScaleBeforeInsertDirector(
                    eachRepoReq ,
                    oldMap ,
                    hrScaleRecordTypeId
                );
            }
        }
    }

    //
    // MethodName : processHRScaleBeforeInsertDirector
    // Description : Entry point for HRScale (Workday) Report field automation on before-insert and
    //               before-update. Guards that the record is non-null and belongs to the HRScale
    //               record type, resolves the prior saved record once, then delegates field-level
    //               logic to setActionFromExistingNewReport and setReportTypeFromInternalClientReport
    //               before enforcing NSP_ReportLocation__c to the fixed HRScale value.
    // Params : NSP_ReportRequest__c newRecord      - record being inserted or updated
    //          Map<Id,NSP_ReportRequest__c> oldMap - prior field values; empty map on insert
    //          Id hrScaleRecordTypeId              - record type Id for HRScale_Workday_Report
    //
    private static void processHRScaleBeforeInsertDirector(
        NSP_ReportRequest__c newRecord ,
        Map<Id,NSP_ReportRequest__c> oldMap ,
        Id hrScaleRecordTypeId
        )
    {
        if ( ( newRecord != null )
            && ( hrScaleRecordTypeId != null )
            && ( newRecord.RecordTypeId == hrScaleRecordTypeId )
            )
        {
            NSP_ReportRequest__c oldRecord = ( ( ( oldMap != null ) && !oldMap.isEmpty() ) ? oldMap.get( newRecord.Id ) : null );
            NSP_ReportRequestTriggerHelper.setActionFromExistingNewReport( newRecord , oldRecord );
            NSP_ReportRequestTriggerHelper.setReportTypeFromInternalClientReport( newRecord , oldRecord );
            newRecord.NSP_ReportLocation__c = 'HRScale (Workday) Report';
        }
    }

    //
    // MethodName : setActionFromExistingNewReport
    // Description : Sets NSP_Action__c based on a change to NSP_Existing_NewReport__c.
    //               On insert (oldRecord is null) or when the value differs from the prior saved
    //               value, sets Action to WIZARD_DEVELOPMENT for New Report or WIZARD_MAINTENANCE
    //               for existing. Also auto-populates NSP_ReportType__c when the report is both
    //               New and Internal.
    // Params : NSP_ReportRequest__c newRecord  - record being inserted or updated
    //          NSP_ReportRequest__c oldRecord  - prior saved record; null on insert
    //
    private static void setActionFromExistingNewReport( NSP_ReportRequest__c newRecord , NSP_ReportRequest__c oldRecord ) {
        if ( ( newRecord != null )
            && ( newRecord.NSP_Existing_NewReport__c != null )
            && ( oldRecord?.NSP_Existing_NewReport__c != newRecord.NSP_Existing_NewReport__c )
            )
        {
            if ( newRecord.NSP_Existing_NewReport__c == NSP_ServiceConstants.NEW_REPORT ) {
                newRecord.NSP_Action__c = NSP_ServiceConstants.WIZARD_DEVELOPMENT;
                if ( newRecord.NSP_InternalClientReport__c == NSP_ServiceConstants.INTERNAL_REPORT ) {
                    newRecord.NSP_ReportType__c = NSP_ServiceConstants.INTERNAL_CLIENT_REPORT;
                }
            } else {
                newRecord.NSP_Action__c = NSP_ServiceConstants.WIZARD_MAINTENANCE;
            }
        }
    }

    //
    // MethodName : setReportTypeFromInternalClientReport
    // Description : Sets or clears NSP_ReportType__c based on a change to NSP_InternalClientReport__c.
    //               On insert (oldRecord is null) or when the value differs from the prior saved
    //               value, sets NSP_ReportType__c to INTERNAL_CLIENT_REPORT when the report is
    //               both Internal and New; clears it for any other report type selection.
    // Params : NSP_ReportRequest__c newRecord  - record being inserted or updated
    //          NSP_ReportRequest__c oldRecord  - prior saved record; null on insert
    //
    private static void setReportTypeFromInternalClientReport( NSP_ReportRequest__c newRecord , NSP_ReportRequest__c oldRecord ) {
        if ( ( newRecord != null )
            && ( newRecord.NSP_InternalClientReport__c != null )
            && ( oldRecord?.NSP_InternalClientReport__c != newRecord.NSP_InternalClientReport__c )
            )
        {
            if ( newRecord.NSP_InternalClientReport__c == NSP_ServiceConstants.INTERNAL_REPORT ) {
                if ( newRecord.NSP_Existing_NewReport__c == NSP_ServiceConstants.NEW_REPORT ) {
                    newRecord.NSP_ReportType__c = NSP_ServiceConstants.INTERNAL_CLIENT_REPORT;
                }
            } else {
                newRecord.NSP_ReportType__c = null;
            }
        }
    }

    //
    // Description: This method is used to validate completed wizard record before deleting
    // @Param : List<NSP_ReportRequest__c> oldList and Map<Id, NSP_ReportRequest__c > oldMap
    // @return type: void
    // Defect:DF-02745
    //
    public void beforeDeleteDirector( List<NSP_ReportRequest__c> oldList ,  Map<Id,NSP_ReportRequest__c > oldMap ) {
        Boolean isSystemAdmin = ( Userinfo.getProfileId() == '00e4x000001r0zsAAA' ); // System Administrator
        for ( NSP_ReportRequest__c eachRepoReq : oldList ) {
            if ( !eachRepoReq.NSP_IsDraft__c && !isSystemAdmin ) {
                eachRepoReq.addError( label.NSP_Restrict_Wizard_Delete );
            }
        }
    }
    //
    // MethodName : updateWSEEDetails
    // Description : Updates all the related WSEE details on wizard output record
    // Params : List <NSP_ReportRequest__c> newList, Set<Id> contactIdSet, Set<Id> accountIdSet
    // Created Date : 24/08/2023 created as part of story STY-04602
    //
    private void updateWSEEDetails( List<NSP_ReportRequest__c> repReqList , Set<Id> repReqContactIds , Set<Id> repReqAccountIds ) {
        try {
            Map<Id,Contact> contactMap = new Map<Id,Contact>();
            Map<Id,NSP_Sub_Client_Contact__c> subClientContactMap = new Map<Id,NSP_Sub_Client_Contact__c>();
            Map<Id,NSP_Sub_Client_Contact_Address__c> subClientContactAddressMap = new Map<Id,NSP_Sub_Client_Contact_Address__c>();
            for ( Contact con : [
                        SELECT Id , NSP_Date_of_Birth__c , Name
                        FROM Contact
                        WHERE ( Id IN :repReqContactIds )
                    ]
                )
            {
                contactMap.put( con.Id , con );
            }
            for ( NSP_Sub_Client_Contact__c scc : [
                        SELECT
                            Id ,
                            NSP_Is_Primary__c ,
                            NSP_Employee_Status__c ,
                            NSP_Status_Date__c ,
                            NSP_AIMS_Sub_Client__c ,
                            NSP_Sub_Client__c ,
                            NSP_Sub_Client__r.NSP_Account__c ,
                            NSP_Contact__c
                        FROM NSP_Sub_Client_Contact__c
                        WHERE (
                            ( NSP_Contact__c IN :repReqContactIds )
                            AND ( NSP_Is_Primary__c = true )
                            AND ( NSP_Sub_Client__r.NSP_Account__c IN :repReqAccountIds )
                        )
                    ]
                )
            {
                subClientContactMap.put(scc.NSP_Contact__c, scc);
            }
            for ( NSP_Sub_Client_Contact_Address__c scca : [
                        SELECT
                            Id ,
                            NSP_State__c ,
                            NSP_Sub_Client_Contact__c ,
                            NSP_Sub_Client_Contact__r.NSP_Contact__c
                        FROM NSP_Sub_Client_Contact_Address__c
                        WHERE (
                            ( NSP_Sub_Client_Contact__r.NSP_Contact__c IN :repReqContactIds )
                            AND ( NSP_Sub_Client_Contact__r.NSP_Is_Primary__c = true )
                            AND ( NSP_State__c != null )
                        )
                    ]
                )
            {
                subClientContactAddressMap.put( scca.NSP_Sub_Client_Contact__r.NSP_Contact__c , scca );
            }
            for ( NSP_ReportRequest__c repReq : repReqList ) {
                repReq.NSP_DOB__c = (contactMap.containskey(repReq.NSP_WSEE__c) && contactMap.get(repReq.NSP_WSEE__c).NSP_Date_of_Birth__c != null) ?
                    contactMap.get(repReq.NSP_WSEE__c).NSP_Date_of_Birth__c : null;
                repReq.NSP_Termination_Date__c = (subClientContactMap.containsKey(repReq.NSP_WSEE__c) &&
                                                  subClientContactMap.get(repReq.NSP_WSEE__c).NSP_Employee_Status__c != null &&
                                                  subClientContactMap.get(repReq.NSP_WSEE__c).NSP_Employee_Status__c == NSP_ServiceConstants.TERMINATED_STATUS ) ?
                    subClientContactMap.get(repReq.NSP_WSEE__c).NSP_Status_Date__c : repReq.NSP_Termination_Date__c;
                repReq.NSP_Age_Range_Is__c = getAgeRange(repReq.NSP_DOB__c, repReq.NSP_Termination_Date__c);
            }
        } catch ( Exception e ) {
            NSP_ReportRequestTriggerHelper.handleException( e , 'updateWSEEDetails' );
        }
    }

    //
    // MethodName : afterUpdateDirector
    // Description : handles all the after update operations on wizard output record
    // Params : Map<Id, NSP_ReportRequest__c> newMap, Map<Id, NSP_ReportRequest__c > oldMap
    // Created Date : 24/08/2023 created as part of story STY-04602
    //
    public void afterUpdateDirector( Map<Id,NSP_ReportRequest__c> newMap , Map<Id,NSP_ReportRequest__c > oldMap ) {
        Set<Id> caseIdSet = new Set<Id>();
        Set<Id> contactIdSet = new Set<Id>();
        List<NSP_ReportRequest__c> reportRequestList = new List<NSP_ReportRequest__c>();
        List<NSP_ReportRequest__c> newReportRequestList = new List<NSP_ReportRequest__c>();
        for ( NSP_ReportRequest__c repReq : newMap.values() ) {
            if ( ( repReq.NSP_WSEE__c != oldMap.get( repReq.Id ).NSP_WSEE__c )
                && !repReq.NSP_IsDraft__c
                && ( repReq.NSP_Case__c != null )
                )
            {
                caseIdSet.add( oldMap.get( repReq.Id ).NSP_Case__c );
                contactIdSet.add( oldMap.get( repReq.Id ).NSP_WSEE__c );
                contactIdSet.add( repReq.NSP_WSEE__c );
                reportRequestList.add( repReq );
            }
            if ( ( repReq.NSP_Case__c != oldMap.get( repReq.Id ).NSP_Case__c )
                && ( oldMap.get( repReq.Id ).NSP_Case__c == null )
                && ( repReq.NSP_Case__c != null )
                )
            {
                newReportRequestList.add( repReq );
            }
        }
        if ( !caseIdSet.isEmpty() && !contactIdSet.isEmpty() ) {
            this.deleteCaseContacts( caseIdSet , contactIdSet );
        }
        if ( !reportRequestList.isEmpty() ) {
            this.insertCaseContacts( reportRequestList , false );
            this.updateCaseSubjectName( reportRequestList );
        }
        if ( !newReportRequestList.isEmpty() ) {
            this.insertCaseContacts( newReportRequestList , true );
        }
    }

    //
    // MethodName : insertCaseContacts
    // Description : insert case contacts by taking WSEE and Client Contact Value from wizard output
    // Params : List<NSP_ReportRequest__c> reportRequestList
    // Created Date : 24/08/2023 created as part of story STY-04602
    //
    private void insertCaseContacts( List<NSP_ReportRequest__c> reportRequestList , Boolean isClientContactRequired ) {
        try {
            List<NSP_Case_Contacts__c> caseContactList = new List<NSP_Case_Contacts__c>();
            for ( NSP_ReportRequest__c repRequest : reportRequestList ) {
                if ( repRequest.NSP_WSEE__c != null ) {
                    caseContactList.add( this.createCaseContacts( repRequest , false , true ) );
                }
                if ( ( repRequest.NSP_Client_Contact__c != null ) && isClientContactRequired ) {
                    caseContactList.add( this.createCaseContacts( repRequest , true , false ) );
                }
            }
            if ( !caseContactList.isEmpty() ) {
                List<Database.SaveResult> results = Database.insert( caseContactList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ReportRequestTriggerHelper.class.getName() ,
                    'insertCaseContacts:insert' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ReportRequestTriggerHelper.handleException( e , 'insertCaseContacts' );
        }
    }

    //
    // MethodName : createCaseContacts
    // Description : create case contacts and assign values by taking WSEE and Client Contact Value from wizard output
    // Params : NSP_ReportRequest__c reportRequest, Boolean clientContactIsPresent, Boolean isWSEEPresent
    // Created Date : 24/08/2023 created as part of story STY-04602
    //
    private NSP_Case_Contacts__c createCaseContacts( NSP_ReportRequest__c repRequest , Boolean clientContactIsPresent , Boolean isWSEEPresent ) {
        NSP_Case_Contacts__c caseContact = new NSP_Case_Contacts__c();
        caseContact.NSP_Case__c = repRequest.NSP_Case__c;
        if ( ( repRequest.NSP_WSEE__c != null ) && isWSEEPresent ) {
            caseContact.NSP_IsPrimary__c = true;
            caseContact.NSP_Contact__c = repRequest.NSP_WSEE__c;
        }
        if ( ( repRequest.NSP_Client_Contact__c != null ) && clientContactIsPresent ) {
            caseContact.NSP_IsPrimary__c = ( repRequest.NSP_RequestingMultipleEmployees__c == 'Yes' );
            caseContact.NSP_Contact__c = repRequest.NSP_Client_Contact__c;
        }
        return caseContact;
    }

    //
    // MethodName : deleteCaseContacts
    // Description : deletes previous case contact which was primary
    // Params : Set<Id> caseIdSet, Set<Id> contactIdSet
    // Created Date : 24/08/2023 created as part of story STY-04602
    //
    private void deleteCaseContacts( Set<Id> caseIdSet , Set<Id> contactIdSet ) {
        try{
            List<NSP_Case_Contacts__c> caseContactList = [
                SELECT
                    Id ,
                    NSP_Case__c ,
                    NSP_Contact__c ,
                    NSP_IsPrimary__c
                FROM NSP_Case_Contacts__c
                WHERE (
                    ( NSP_Case__c IN :caseIdSet )
                    AND ( NSP_Contact__c IN :contactIdSet )
                )
            ];
            if ( !caseContactList.isEmpty() ) {
                List<Database.DeleteResult> results = Database.delete( caseContactList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ReportRequestTriggerHelper.class.getName() ,
                    'deleteCaseContacts:delete' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ReportRequestTriggerHelper.handleException( e , 'deleteCaseContacts' );
        }
    }

    // for test code coverage only...
    public static void testShowValidationForInsperityPrepared( List<NSP_ReportRequest__c> insperityPreparedRepReqList ) {
        if ( Test.isRunningTest() ) {
            NSP_ReportRequestTriggerHelper helper = new NSP_ReportRequestTriggerHelper();
            helper.showValidationForInsperityPrepared( insperityPreparedRepReqList );
        }
    }

    //
    // MethodName : showValidationForInsperityPrepared
    // Description : Displays an error message if WSEE field is updated on Insperity Wizard Output Records
    // Params : List <NSP_ReportRequest__c> insperityPreparedRepReqList
    // Created Date : 24/08/2023 created as part of story STY-04602
    //
    private void showValidationForInsperityPrepared( List<NSP_ReportRequest__c> insperityPreparedRepReqList ) {
        try {
            for ( NSP_ReportRequest__c inspRepReq : insperityPreparedRepReqList ) {
                //After custom label is deployed to UAT, we have to update the error message with custom label
                inspRepReq.addError( 'You cannot add WSEEs to multi employee agreements' );
            }
        } catch ( Exception e ) {
            NSP_ReportRequestTriggerHelper.handleException( e , 'showValidationForInsperityPrepared' );
        }
    }

    //
    // MethodName : getAgeRange
    // Description : calculates the difference between start date and end date and based on output age range value is set
    // Params : Date startDate, Date endDate
    // Created Date : 24/08/2023 created as part of story STY-04602
    //
    private String getAgeRange( Date startDate , Date endDate ) {
        String ageRange = '';
        Integer year;
        integer month;
        integer day;
        if ( ( startDate != null ) && ( endDate != null ) && ( endDate > startDate ) ) {
            year = endDate.year() - startDate.year();
            month = endDate.month() - startDate.month();
            day = endDate.day() - startDate.day();
            ageRange = (year < 40)? UNDER_40 : (year > 40) ? OVER_40 : (year == 40 && month >0)? OVER_40: (year == 40 && month <0)? UNDER_40: (year == 40 && month == 0 && day >= 0 )? OVER_40: UNDER_40;
        } else if ( ( startDate == null ) || ( endDate == null ) || ( startDate > endDate ) ) {
            ageRange = UNKNOWN;
        }
        return ageRange;
    }

    //
    // MethodName : updateCaseSubjectName
    // Description : updates the case subject when WSEE value is updated on wizard output
    // Params : List<NSP_ReportRequest__c>repReqList
    // Created Date : 24/08/2023 created as part of story STY-04602
    //

	private void updateCaseSubjectName( List<NSP_ReportRequest__c> repReqList ) {
        List<Case> caseIdSet = new List<Case>();
        try{
            for ( NSP_ReportRequest__c repRequestRecord : [
                        SELECT
                            Id ,
                            NSP_WSEE__c ,
                            NSP_WSEE__r.Name ,
                            NSP_Case__c ,
                            NSP_ReviewType__c ,
                            NSP_AgreementType__c
                        FROM NSP_ReportRequest__c
                        WHERE ( Id IN :repReqList )
                    ]
                )
            {
                case newCase = new Case();
                newCase.Id = repRequestRecord.NSP_Case__c;
                if(repRequestRecord.NSP_ReviewType__c != null){
                newCase.Subject = repRequestRecord.NSP_AgreementType__c + ' - ' + repRequestRecord.NSP_ReviewType__c + ' - ' +
                        repRequestRecord.NSP_WSEE__r.Name ;
                }else if(repRequestRecord.NSP_ReviewType__c == null && repRequestRecord.NSP_RequestingMultipleEmployees__c == NSP_ServiceConstants.NO){
                newCase.Subject = repRequestRecord.NSP_AgreementType__c + ' - ' + repRequestRecord.NSP_WSEE__r.Name;
                }
                caseIdSet.add(newCase);
            }
            if ( !caseIdSet.isEmpty() ) {
                Database.SaveResult[] results = Database.update( caseIdSet , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ReportRequestTriggerHelper.class.getName() ,
                    'updateCaseSubjectName:update' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ReportRequestTriggerHelper.handleException( e , 'updateCaseSubjectName' );
        }
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_ReportRequestTriggerHelper.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_ReportRequestTriggerHelper.class.getName() ,
            methodName ,
            e
        );
    }

}
//