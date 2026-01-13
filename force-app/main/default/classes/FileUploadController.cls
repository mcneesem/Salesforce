public with sharing class FileUploadController {
    // test w/ FileUploadControllerTest (95%)

    private static final string loadTime = 'HH:mm:ss';
    private static final string DOL_AUDITS = 'DOL Audits';
    private static final string WAGE_CLAIMS = 'Wage Claims';
    private static final string dunningRecordType = 'Dunning';
    private static final string retRecordType = 'NSP_RET_Time_Tracking';
    private static final string wxRecordType = 'NSP_WX_IMPL';
    private static final string dunningCase = 'Dunning Case';
    private static final string rETTimeTracking = 'RET Time Tracking';
    private static final string wXIMPL = 'WX IMPL';
    private static final string catSubcatError = 'Please check category,subcategory and detail combination';
    private static final string reasonError = 'Please check resolution picklist value';
    private static final string originError = 'Please check case origin picklist value';
    private static final string statusError = 'Please check status picklist value';
    private static final string priorityError = 'Please check priority picklist value';
    private static final string dueDateError = 'Please check due date format';
    private static final string openedDateError = 'Please check opened date format or subject contains comma(,)';
    private static final string closedDateError = 'Please check closed date format';
    private static final string contactError = 'Please check the PerID of contact';
    private static final string aimsError = 'Please check the account or asset value';
    private static final string userError = 'Please check owner';
    private static final string recordTypeError = 'Please check record type';
    private static final string closed = 'Closed';
    private static final string errorRowNum = '.Error occurred at row number - ';
    private static final string objectApiName = NSP_ServiceConstants.CASE_OBJECT_NAME ;

    private static final Id dolAuditRecordTypeId  = getRecordTypeId( objectApiName, NSP_ServiceConstants.DO_AUDITS_RECORDTYPE );
    private static final Id wageClaimRecordTypeId = getRecordTypeId( objectApiName, NSP_ServiceConstants.WAGE_CLAIMS_RECORDTYPE );
    private static final Id peoRecordTypeId       = getRecordTypeId( objectApiName, NSP_ServiceConstants.PEO );
    private static final Id bpsRecordTypeId       = getRecordTypeId( objectApiName, NSP_ServiceConstants.BPS );
    private static final Id itaRecordTypeId       = getRecordTypeId( objectApiName, NSP_ServiceConstants.NSP_ITA_CQA );
    private static final Id dunningRecordTypeId   = getRecordTypeId( objectApiName, dunningRecordType );
    private static final Id retRecordTypeId       = getRecordTypeId( objectApiName, retRecordType );
    private static final Id wxRecordTypeId        = getRecordTypeId( objectApiName, wxRecordType );

    private static List<String> reasonPicklistValues = getPicklistValues(objectApiName, 'Reason');
    private static List<String> originPicklistValues = getPicklistValues(objectApiName, 'Origin');
    private static List<String> statusPicklistValues = getPicklistValues(objectApiName, 'Status');
    private static List<String> priorityPicklistValues = getPicklistValues(objectApiName, 'Priority');

    private static Pattern datePattern = Pattern.compile('^(0?[1-9]|1[0-2])/(0?[1-9]|[12][0-9]|3[01])/\\d{4}$');

    @AuraEnabled(cacheable =true)
    public static Boolean hasPermission() {
        return CustomPermissionController.checkUserPermission( 'Upload_Cases_via_CSV',UserInfo.getUserId() );
    }

    @AuraEnabled
    public static Map<String,String> loadData( Id contentDocumentId ) {
        Map<String,String> successMap = new Map<String,String>();
        if( hasPermission() )
        {
            List<NSP_Category_Sub_Category_Mapping__c> nspCatRecords = [
                SELECT Id,
                    NSP_Category__c,
                    NSP_Subcategory__c,
                    NSP_Detail__c,
                    NSP_Display_confidential_popup__c
                FROM NSP_Category_Sub_Category_Mapping__c
            ];

            if ( contentDocumentId != null
                 && nspCatRecords !=null
                 && !nspCatRecords.isEmpty()
               )
            {
                successMap = processCsvFile( getCsvRowsFromContentDocument( contentDocumentId ), nspCatRecords );
                performDeleteDML(contentDocumentId);

            } else {
                successMap.put( System.NOW().format( loadTime ),'CSV file incorrect');
            }

        }

        return successMap;
    }

    private static map<String,String> processCsvFile( List<String> records, List<NSP_Category_Sub_Category_Mapping__c> nspCatRecords ){

        map<String,String> successMap = new Map<String,String>();
        Set<String> catSubcatKey = new Set<String>();
        Map<String, Boolean> confidentialMap = new Map<String, Boolean>();
        Case_Import_Tool_Settings__c caseSettings =  Case_Import_Tool_Settings__c.getInstance(UserInfo.getUserId());

        if( records != null
           && !records.isEmpty()
           && records.size() <= caseSettings.UploadViaCsvMaxSize__c
          )
        {
            for ( NSP_Category_Sub_Category_Mapping__c catSubcatList : nspCatRecords )
            {
                String key = catSubcatList.NSP_Category__c + catSubcatList.NSP_Subcategory__c;
                if ( String.isNotBlank( catSubcatList.NSP_Detail__c ) )
                {
                    key = catSubcatList.NSP_Category__c + catSubcatList.NSP_Subcategory__c + catSubcatList.NSP_Detail__c;
                }
                catSubcatKey.add( key );
                confidentialMap.put( key, catSubcatList.NSP_Display_confidential_popup__c );
            }

            //Removing the Header
            String headers = records.remove( 0 );
            Boolean allConditionsMet = validateHeaderRow( headers );
            if ( allConditionsMet ) {

                CaseProcessWrapper cpw = parsingCsvFileRows( records, catSubcatKey, confidentialMap );
                successMap = processCaseImport( cpw.createRecordMap, cpw.caseList, cpw.allRowValue, cpw.rowCaseMap );
            }
            else{
                successMap.put( System.NOW().format( loadTime ), 'Some error occured. Please check headers.' );
            }

        }else {
            successMap.put( System.NOW().format( loadTime ), 'There is no record in csv file or UploadViaCsvMaxSize is not defined in custom setting' );
        }
        if(records.isEmpty()) {
            successMap.put( System.NOW().format( loadTime ), 'There is no record in csv file' );
        }
        return successMap;
    }

    public static CaseProcessWrapper  parsingCsvFileRows( List<String> records, Set<String> catSubcatKey, Map<String, Boolean> confidentialMap ) {

        List<CsvRowWrapper> csvRowWrapperList = new  List<CsvRowWrapper>();
        List<Case> caseList = new List<Case>();
        List<List<String>> allRowValue = new List<List<String>>();
        Map<String,String> clientToUserMap = new Map<String,String>();
        Map<String,String> clientEmailtoUserMap = new Map<String,String>();
        Map<String,String> accountToClientMap = new Map<String,String>();
        Map<String,String> assetToClientMap = new Map<String,String>();
        Map<String,String> contactToPerIdMap = new Map<String,String>();
        Map<Integer, String> caseRecord = new Map<Integer, String>();
        Map<Integer, String> contactRecord = new Map<Integer, String>();
        Map<Integer, String> userRecord = new Map<Integer, String>();
        Map<Integer, String> confidentialRecord = new Map<Integer, String>();
        Map<List<String>, String> createRecordMap = new Map<List<String>, String>();
        Map<Case,list<String>> rowCaseMap = new Map<Case,list<String>>();

        Integer rowNum = 1;
        if( records !=null
            && !records.isEmpty()
          )
        {
            for ( String record : records ) {
                rowNum++;
                if ( String.isNotBlank( record ) ) {
                    List < String > row = record.split( ',' );
                    allRowValue.add( row );
                    CsvRowWrapper csvRow = new CsvRowWrapper();
                    csvRow = csvSingleRow( rowNum, row, catSubcatKey, confidentialMap);
                    if( String.isBlank( csvRow.errorMessage ) )
                    {
                        caseList.add( csvRow.caseRecord );
                        rowCaseMap.put( csvRow.caseRecord, row );
                    }
                    csvRowWrapperList.add( csvRow );

                }

            }

        }
        userRecord = buildRecordMap( csvRowWrapperList, 'ownerLink' );
        caseRecord = buildRecordMap( csvRowWrapperList, 'assestLink' );
        contactRecord = buildRecordMap( csvRowWrapperList, 'contactLink' );
        confidentialRecord = buildRecordMap( csvRowWrapperList, 'confidentialRecordOwner' );
        createRecordMap = buildRecordErrorMap( csvRowWrapperList );
        buildQueueAndUserMaps( userRecord.values(), clientToUserMap, clientEmailtoUserMap );
        contactToPerIdMap = buildcontactToPerIdMap(contactRecord.values());
        buildAccountAssetClientMap( caseRecord.values(), accountToClientMap, assetToClientMap );
        CaseProcessWrapper cpw = new CaseProcessWrapper();
            cpw.allRowValue = allRowValue;
            cpw.userRecord = userRecord;
            cpw.caseRecord = caseRecord;
            cpw.contactRecord = contactRecord;
            cpw.confidentialRecord = confidentialRecord;
            cpw.createRecordMap = createRecordMap;
            cpw.clientToUserMap = clientToUserMap;
            cpw.clientEmailtoUserMap = clientEmailtoUserMap;
            cpw.contactToPerIdMap = contactToPerIdMap;
            cpw.caseList = caseList;
            cpw.rowCaseMap = rowCaseMap;
            cpw.accountToClientMap = accountToClientMap;
            cpw.assetToClientMap = assetToClientMap;
        processCases( cpw );
        return cpw;
    }

    private static Map<String,String> processCaseImport( Map<list<String>,String> createRecordMap,
                                                         List<Case> caseList,
                                                         List<list<String>> allRowValue,
                                                         Map<Case,list<String>> rowCaseMap
                                                       )
    {
        Map<String,String> successMap = new Map<String,String>();
        try {
            if ( createRecordMap !=null
                 && !createRecordMap.isEmpty()
               )
            {
                createImportError( createRecordMap );
                if ( caseList.isEmpty() )
                {
                    sendEmail( null, createRecordMap );
                }
            }

            if ( caseList != null
                 && !caseList.isEmpty()
               )
            {
                bypassCustomSettings();
                // Enqueue the Queueable job to process the records in batches
                if ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() ) {
                    System.enqueueJob(
                        new CaseImportQueueable(
                            caseList,
                            allRowValue,
                            rowCaseMap,
                            null,
                            createRecordMap
                        )
                    );
                }
            }

            successMap.put( System.now().format(loadTime), 'Case Loaded. Please check email for success/failure count' );
        } catch ( Exception ex ) {
            successMap.put( System.NOW().format( loadTime ), 'Error: ' + ex.getMessage() );
        }
        return successMap;
    }

    public static CsvRowWrapper csvSingleRow( Integer rowNum,
                                              List<String> row,
                                              Set<String> catSubcatKey,
                                              Map<String, Boolean> confidentialMap
                                            )
    {
        CsvRowWrapper csvRow = new CsvRowWrapper();

        if ( rowNum !=null
             && row !=null
             && !row.isEmpty()
             && row.size()>20
           )
        {
            string errorMessage = '';
            String csvContact = row[ 1 ];
            String csvAccount = row[ 2 ];
            String csvAsset = row[ 3 ];
            String csvCategory = row[ 4 ];
            String csvSubCategory = row[ 5 ];
            String csvDetail = row[ 6 ];
            String csvOwner = row[ 7 ];
            String csvOrigin = row[ 8 ];
            String csvPriority = row[ 9 ];
            String csvStatus = row[ 10 ];
            String csvSubstatus = row[ 11 ];
            String csvResolution = row[ 12 ];
            String csvSubject = row[ 13 ];
            String csvDateOpen = row[ 14 ];
            String csvDueDate = row[ 15 ];
            String csvClosedDate = row[ 16 ];
            String csvConfidential = row[ 17 ];
            String csvQuickRate = row[ 18 ];
            String csvRecordType = row[ 19 ];

            String checkKey = csvCategory + csvSubCategory + csvDetail;

            errorMessage = validateCsvConfidential( csvConfidential, checkKey, catSubcatKey, confidentialMap );
            errorMessage = validateCsvPicklistValue( errorMessage, csvOrigin, originError, originPicklistValues );
            errorMessage = validateCsvPicklistValue( errorMessage, csvPriority, priorityError, priorityPicklistValues );
            errorMessage = validateCsvPicklistValue( errorMessage, csvStatus, statusError, statusPicklistValues) ;
            errorMessage = validateCsvPicklistValue( errorMessage, csvResolution, reasonError, reasonPicklistValues );
            errorMessage = validateCsvDates( errorMessage, csvDateOpen, csvDueDate, csvClosedDate );
            errorMessage = validateCsvLookups( errorMessage, csvAccount, csvAsset, csvOwner );
            errorMessage = validateCsvRecordType( errorMessage, csvRecordType );

            csvRow.rowNum = rowNum;
            csvRow.row = row;
            if( String.isBlank( errorMessage ) )
            {
                Case objCase = new Case();
                objCase.ContactId = csvValueId( csvContact );
                objCase.AccountId = csvValueId( csvAccount );
                objCase.AssetId = csvValueId( csvAsset );
                objCase.NSP_Category__c = checkCatSubCatDetail( checkKey, csvCategory, catSubcatKey );
                objCase.NSP_SubCategory__c = checkCatSubCatDetail( checkKey, csvSubCategory, catSubcatKey );
                objCase.NSP_Detail__c = checkCatSubCatDetail( checkKey, csvDetail, catSubcatKey );
                objCase.OwnerId = checkOwnerId( csvOwner );
                objCase.Origin = csvOrigin;
                objCase.Priority = csvPriority;
                objCase.Status = csvStatus;
                objCase.NSP_Case_Sub_Status__c = csvSubstatus;
                objCase.Reason = csvResolution;
                objCase.Subject = csvSubject;
                objCase.NSP_Opened_Date__c = checkValueDate( csvDateOpen );
                objCase.NSP_Due_Date__c = checkValueDate( csvDueDate );
                objCase.NSP_Date_Closed__c = checkValueDate( csvClosedDate );
                objCase.CreatedDate = checkValueDateTime( csvDateOpen, null, 12, rowNum );
                objCase.NSP_Confidential__c = checkConfidential( csvConfidential, csvCategory, csvSubCategory, csvDetail, confidentialMap );
                objCase.ClosedDate = checkValueDateTime( csvClosedDate, csvStatus,12 , rowNum );
                objCase.NSP_Rating__c = csvQuickRate;
                objCase.RecordTypeId = checkRecordTypeId( csvRecordType );
                objCase.Description = concatenateDescription( row, 20 );
                csvRow.caseRecord = objCase;
                csvRow.assestLink = csvNotValueId( csvAsset );
                csvRow.contactLink = csvNotValueId( csvContact );
                csvRow.ownerLink = csvNotValueId( csvOwner );
                csvRow.confidentialRecordOwner = checkConfidentialRecordOwner( csvCategory, csvSubCategory, csvOwner );
            }else{
                csvRow.errorMessage = errorMessage;
            }

        }
        return csvRow;
    }

    private static String checkOwnerId( String csvOwner ) {
        String caseOwnerId = null;
        if ( String.isNotBlank( csvOwner )
             && csvValueId( csvOwner ) != null
           )
        {
            Id ownerId = Id.valueOf( csvOwner );
            Schema.SObjectType ownerType = ownerId.getSObjectType();
            if ( ownerType !=null
                 && ( ownerType == User.SObjectType
                      || ownerType == Group.SObjectType
                    )
               )
            {
                caseOwnerId = ownerId;
            }
        }
        return caseOwnerId;
    }

    private Static Boolean checkConfidential( String value,
                                              String csvCategory,
                                              String csvSubCategory,
                                              String csvDetail,
                                              Map<String, Boolean> confidentialMap
                                            )
    {

        Boolean returnValue = false;

        if ( String.isNotBlank( value )
             && String.isNotBlank( csvCategory )
             && String.isNotBlank( csvSubCategory )
             && value.contains( 'F' )
             && confidentialMap.containsKey( csvCategory + csvSubCategory + csvDetail )
             && !confidentialMap.get( csvCategory + csvSubCategory + csvDetail )
          )
        {
         	returnValue = FALSE;
        }
        else if ( String.isNotBlank( value )
                  && value.contains( 'T' )
                  && confidentialMap.containsKey( csvCategory + csvSubCategory + csvDetail )
                  && confidentialMap.get( csvCategory + csvSubCategory + csvDetail )
                )
        {
            returnValue = TRUE;
        }

        return returnValue;
    }

    private static String checkCatSubCatDetail( String checkKey, String value, Set<String> catSubcatKey ){

        String returnValue = '';
        if ( String.isNotBlank( checkKey )
             && String.isNotBlank( value )
             && catSubcatKey != null
             && catSubcatKey.contains( checkKey )
           )
        {
            returnValue = value;
        }

        return returnValue;
    }

    private static Date checkValueDate( String value ) {

        Date returnValue = null;

        if ( String.isNotBlank( value )
             && datePattern.matcher( value ).matches()
           )
        {
           returnValue = Date.parse( value );
        }
        return returnValue;
    }

    private static DateTime checkValueDateTime( String value, String status, Integer hours,Integer seconds ) {

        DateTime returnValue = null;

        if( String.isNotBlank( value )
            && String.isNotBlank( status )
            && status == closed
            && hours != null
           && seconds != null
            && datePattern.matcher( value ).matches()
          )
        {
            DateTime closedDateTime = Date.parse( value );
            DateTime newClosedDateTime = closedDateTime.addHours( hours ).addSeconds( seconds );
            returnValue = newClosedDateTime;
        }
        if( String.isNotBlank( value )
            && String.isBlank( status )
            && hours != null
           	&& seconds != null
            && datePattern.matcher( value ).matches()
          )
        {
            DateTime closedDateTime = Date.parse( value );
            DateTime newClosedDateTime = closedDateTime.addHours( hours ).addSeconds( seconds );
            returnValue = newClosedDateTime;
        }
        return returnValue;
    }

    //Checks if not blank and if Instance of ID
    private static String csvValueId( String value ){

        String returnValue = null;

        if( String.isNotBlank( value )
            && ( value InstanceOf Id )
          )
        {
            returnValue = value;
        }
        return returnValue;
    }

    private static String validateCsvConfidential( String csvConfidential,
                                                   String checkkey,
                                                   Set<String> catSubcatKey,
                                                   Map<String,Boolean> confidentialMap
                                                 )
    {

        String errorMessage = '';

        if ( String.isNotBlank( checkkey )
             && catSubcatKey != null
             && !catSubcatKey.isEmpty()
             && !catSubcatKey.contains(checkkey)
           )
        {
            errorMessage =  catSubcatError;
        }
        else if ( String.isNotBlank( csvConfidential )
                  && csvConfidential.contains( 'F' )
                  && confidentialMap.containsKey( checkkey )
                  && confidentialMap.get( checkkey ) )
        {
            errorMessage = 'Case is confidential elegible';
        }else if ( String.isNotBlank( csvConfidential )
                   && csvConfidential.contains('T')
                   && confidentialMap.containsKey( checkkey )
                   && !confidentialMap.get( checkkey )
                 )
        {
            errorMessage = 'Case is not confidential elegible';
        }

        return errorMessage;
    }

    private static String validateCsvPicklistValue( String errorMessage,
                                                    String value,
                                                    String validateErrorMsg,
                                                    List<String> picklistValueSet
                                                  )
    {

        if ( String.isBlank( errorMessage)
            && String.isNotBlank( value )
            && picklistValueSet != null
            && !picklistValueSet.isEmpty()
            && !picklistValueSet.contains( value )
           )
        {
            errorMessage = validateErrorMsg;
        }
        return errorMessage;
    }

    private static String validateCsvDates( String errorMessage,
                                            String csvDateOpen,
                                            String csvDueDate,
                                            String csvClosedDate
                                          )
    {
        if ( String.isBlank( errorMessage )
             && String.isNotBlank( csvDateOpen )
             && !datePattern.matcher( csvDateOpen ).matches()
           )
        {
            errorMessage = openedDateError;
        }
        else if ( String.isBlank( errorMessage )
                  && String.isNotBlank( csvDueDate )
                  && !datePattern.matcher( csvDueDate ).matches()
                )
        {
            errorMessage = dueDateError;
        }
        else if ( String.isBlank( errorMessage )
                   && String.isNotBlank( csvClosedDate )
                   && !datePattern.matcher( csvClosedDate ).matches()
                 )
        {
            errorMessage = closedDateError;
        }

        return errorMessage;
    }

    private static String validateCsvLookups( String errorMessage,
                                              String csvAccount,
                                              String csvAsset,
                                              String csvOwner
                                            )
    {
        if (
             ( String.isBlank( csvAccount )
               && String.isBlank( csvAsset )
             )
            || ( String.isBlank( csvAccount )
                 && String.isNotBlank( csvAsset )
                 && (csvAsset InstanceOf Id )
               )
            || ( String.isNotBlank( csvAccount )
                 &&  String.isBlank( csvAsset )
                 && !( csvAccount InstanceOf Id )
               )
           )
        {
            errorMessage = aimsError +' Account - ' + csvAccount + ', Asset - '+ csvAsset;
        }
        else if ( String.isBlank( csvOwner ) )
        {
            errorMessage = userError +' Owner - ' + csvOwner;
        }

        return errorMessage;
    }

    private static String validateCsvRecordType( String errorMessage,String csvRecordType ){

        List<String> recordTypeValues = new List<String>{
            NSP_ServiceConstants.PEO,
            NSP_ServiceConstants.BPS,
            DOL_AUDITS,
            WAGE_CLAIMS,
            dunningCase,
            NSP_ServiceConstants.SUB_CATEGORY_ITA_CQA,
            rETTimeTracking,
            wXIMPL
         };

        if ( !recordTypeValues.contains( csvRecordType ) )
        {
            errorMessage = recordTypeError;
        }

        return errorMessage;
    }

    public static String csvNotValueId( String value ) {

        String returnValue = null;

        if ( String.isNotBlank( value )
             && !( value instanceof Id )
           )
        {
            returnValue = value;
        }

        return returnValue;
    }

    public static String checkConfidentialRecordOwner( String csvCategory, String csvSubCategory, String csvOwner ){

        String returnValue = null;

        if( String.isNotBlank( csvCategory )
            && String.isNotBlank( csvSubCategory )
            && String.isNotBlank( csvOwner )
          )
        {
            returnValue = csvOwner;
        }

        return returnValue;
    }

    private static void buildQueueAndUserMaps( List<String> usersValueSet,
                                               Map<String,String> clientToUserMap,
                                               Map<String,String> clientEmailtoUserMap
                                             )
    {

        List<String> userRecordList = new List<String>();
        List<String> userEmailRecordList = new List<String>();
        List<String> queueRecordList = new List<String>();

        if( usersValueSet !=null
            && !usersValueSet.isEmpty()
          )
        {
            for(String queueOrUser : usersValueSet ){

                if(queueOrUser.contains( NSP_ServiceConstants.INTERNAL_EMAIL_ADD ) )
                {
                    userRecordList.add( queueOrUser );
                    userEmailRecordList.add( queueOrUser );
                }
                else
                {
                    queueRecordList.add( queueOrUser );
                }
            }
        }

        buildUserEmailRecordList( userEmailRecordList, clientEmailtoUserMap );
        buildGroupToUserMap( queueRecordList, clientToUserMap );
        buildClientToUserMap( userRecordList, clientToUserMap );

    }

    private static Map<Integer, String> buildRecordMap( List<CsvRowWrapper> csvRowWrapperList, String fieldName ){

        Map<Integer, String> linkMap = new Map<Integer, String>();

        if ( csvRowWrapperList != null
             && !csvRowWrapperList.isEmpty()
           )
        {
            for  (CsvRowWrapper obj : csvRowWrapperList ) {
                if ( obj.rowNum != null
                     && String.isBlank( obj.errorMessage )
                   )
                {
                    String value = getFieldValue( obj, fieldName );
                    if ( String.isNotBlank( value ) )
                    {
                        linkMap.put(obj.rowNum, value);
                    }
                }
            }
        }

        return linkMap;
    }

    private static Map<List<String>, String> buildRecordErrorMap( List<CsvRowWrapper> csvRowWrapperList ){

        Map<List<String>, String> errorMap = new Map<List<String>, String>();

        if ( csvRowWrapperList != null
             && !csvRowWrapperList.isEmpty()
           )
        {
            for ( CsvRowWrapper obj : csvRowWrapperList )
            {
                if ( obj.rowNum !=null
                     && obj.row !=null
                     && !obj.row.isEmpty()
                     && String.isNotBlank( obj.errorMessage )
                   )
                {
                    errorMap.put( obj.row, obj.errorMessage + errorRowNum + obj.rowNum );
                }
            }
        }

        return errorMap;
    }

    private static String getFieldValue( CsvRowWrapper obj, String fieldName ) {

        String returnValue = '';

        if ( obj != null
             && String.isNotBlank( fieldName )
           )
        {
            switch on fieldName {
                when 'assestLink' {
                    returnValue = obj.assestLink;
                }
                when 'contactLink' {
                    returnValue = obj.contactLink;
                }
                when 'ownerLink' {
                    returnValue = obj.ownerLink;
                }
                when 'confidentialRecordOwner' {
                    returnValue =  obj.confidentialRecordOwner;
                }
                when else {
                    returnValue = '';
                }
            }
        }

        return returnValue;
    }

    private static Map<String, String> buildcontactToPerIdMap(List<String> contactRecordList ){

        Map<String,String>  contactToPerIdMap = new Map<String,String>();

        If ( contactRecordList != null
             && !contactRecordList.isEmpty()
           )
        {
            for(Contact contList :[ Select id ,NSP_Per_ID__c from Contact where NSP_Per_ID__c IN :contactRecordList ] ){
                if( contList!= null )
                {
                    contactToPerIdMap.put( contList.NSP_Per_ID__c,contList.Id );
                }
            }
        }

        return contactToPerIdMap;
    }

    private static void buildUserEmailRecordList( List<String> userEmailRecordList, Map<String,String> clientEmailtoUserMap ){

        if ( userEmailRecordList != null
             && !userEmailRecordList.isEmpty()
           )
        {
            for(User userList :[ SELECT Id, Email FROM User where Email IN :userEmailRecordList ] )
            {
                if( userList != null )
                {
                    clientEmailtoUserMap.put( userList.Email,userList.Id );
                }
            }
        }
    }

    private static void buildClientToUserMap( List<String> userRecordList, Map<String,String> clientToUserMap ){

        if ( userRecordList != null
             && !userRecordList.isEmpty()
           )
        {

            for( User userList :[ SELECT Id, Username FROM User where Username IN :userRecordList ] )
            {
                if(userList!= null){
                    clientToUserMap.put(userList.Username,userList.Id);
                }
            }

        }

    }

    private static void buildGroupToUserMap( List<String> queueRecordList, Map<String,String> clientToUserMap ){
        if ( queueRecordList != null
             && !queueRecordList.isEmpty()
           )
        {
            for( Group groupList :[ SELECT Id, Name FROM Group where Name IN :queueRecordList ] )
            {
                if( groupList!= null ){
                    clientToUserMap.put( groupList.Name, groupList.Id );
                }
            }
        }
    }

    private static void buildAccountAssetClientMap( List<String> caseRecordList,
                                                    Map<String,String> accountToClientMap,
                                                    Map<String,String> assetToClientMap
                                                  )
    {

        if ( caseRecordList != null
             && !caseRecordList.isEmpty()
           )
        {
            for( Asset assetRecord :[ Select id,
                                      	AccountId,
                                        NSP_Client__c
                                      from Asset
                                      where NSP_Client__c IN :caseRecordList
                                      AND AccountId != NULL
                                    ]
               )
            {
                if( assetRecord != null )
                {
                    accountToClientMap.put( assetRecord.NSP_Client__c, assetRecord.AccountId );
                    assetToClientMap.put( assetRecord.NSP_Client__c, assetRecord.Id );

                }
            }
        }
    }

    private static void processCases( CaseProcessWrapper cpw ){
        List<Integer> indicesToRemove = new List<Integer>();
        if( processCasesIfCheck( cpw ) ){
            for ( Case caseToLoad : cpw.rowCaseMap.keySet() ) {
                Boolean shouldContinue  = true;
                if( cpw.rowCaseMap.containsKey(caseToLoad)
                    &&cpw.rowCaseMap.get(caseToLoad) != null
                    && cpw.allRowValue.indexof( cpw.rowCaseMap.get(caseToLoad) ) != null
                  ){
                       Integer rowNumber = cpw.allRowValue.indexof( cpw.rowCaseMap.get(caseToLoad) ) + 2;
                        shouldContinue  = processAccountAssest( shouldContinue, rowNumber, indicesToRemove, caseToLoad, cpw );
                        shouldContinue  = processContact( shouldContinue, rowNumber, indicesToRemove, caseToLoad, cpw );
                        processOwner( shouldContinue, rowNumber, indicesToRemove, caseToLoad, cpw );
                  }

            }
        }
        if( processCasesIfCheckToIndicatorRemove( cpw, indicesToRemove ) )
        {
            indicesToRemove.sort();
            for ( Integer i = indicesToRemove.size() - 1; i >= 0; i-- ) {
                if( indicesToRemove[i] >=0 ){
                    cpw.caseList.remove( indicesToRemove[i] );
                }
            }
        }
    }

    private static Boolean processCasesIfCheck( CaseProcessWrapper cpw ){

        Boolean returnValue = false;

        if( cpw != null
            && cpw.rowCaseMap != null
            && cpw.rowCaseMap.KeySet() != null
            && !cpw.rowCaseMap.KeySet().isEmpty()
            && cpw.allRowValue !=null
            && !cpw.allRowValue.isEmpty()
          )
        {
            returnValue = true;
        }

        return returnValue;
    }

    private static Boolean processCasesIfCheckToIndicatorRemove( CaseProcessWrapper cpw, List<Integer> indeicesToRemoveList ){

        Boolean returnValue = false;

        if( cpw != null
            && cpw.rowCaseMap != null
            && cpw.rowCaseMap.KeySet() != null
            && !cpw.rowCaseMap.KeySet().isEmpty()
            && cpw.allRowValue !=null
            && !cpw.allRowValue.isEmpty()
            && indeicesToRemoveList != null
            && !indeicesToRemoveList.isEmpty()
          )
        {
            returnValue = true;
        }

        return returnValue;
    }

    private static Boolean processAccountAssest( Boolean shouldContinue,
                                                 Integer rowNumber,
                                                 List<Integer> indicesToRemove,
                                                 Case caseToLoad,
                                                 CaseProcessWrapper cpw
                                               )
    {
        if ( accountUpdateIfCheck( rowNumber, caseToLoad, cpw )
             && shouldContinue
           )
        {
            List<String> row = cpw.rowCaseMap.get( caseToLoad );
            cpw.rowCaseMap.remove( caseToLoad );
            caseToLoad.AccountId = cpw.accountToClientMap.get( cpw.caseRecord.get( rowNumber ) );
            cpw.rowCaseMap.put(caseToLoad, row);

        } else if( accountUpdateIfElseCheck( rowNumber, caseToLoad, cpw )
                   && shouldContinue
                 )
        {
            indicesToRemove.add( cpw.caseList.indexOf( caseToLoad ) );
            cpw.createRecordMap.put(
                cpw.rowCaseMap.get( caseToLoad ),
                aimsError + ' Aims - ' + cpw.caseRecord.get( rowNumber ) + errorRowNum + rowNumber
            );
            shouldContinue  = false;
        }
        if ( assetUpdateIfCheck( rowNumber, caseToLoad, cpw )
            && shouldContinue
           )
        {
            List<String> row = cpw.rowCaseMap.get( caseToLoad );
            cpw.rowCaseMap.remove(caseToLoad);
            caseToLoad.AssetId = cpw.assetToClientMap.get(cpw.caseRecord.get(rowNumber));
            cpw.rowCaseMap.put(caseToLoad, row);
        }

        return shouldContinue;
    }

    private static Boolean accountUpdateIfElseCheck( Integer rowNumber, Case caseToLoad, CaseProcessWrapper cpw ){

        Boolean returnValue = false;

        if ( cpw != null
             && cpw.caseRecord !=null
             && rowNumber != null
             && cpw.caseRecord.containsKey( rowNumber )
             && cpw.caseRecord.get( rowNumber ) != null
             && caseToLoad !=null
             && caseToLoad.AccountId == null
             && cpw.caseList != null
             && !cpw.caseList.isEmpty()
             && cpw.caseList.indexOf( caseToLoad ) >= 0
             && cpw.rowCaseMap.containsKey( caseToLoad )
             && cpw.rowCaseMap.get( caseToLoad ) != null
           )
        {
            returnValue = true;
        }

        return returnValue;
    }

    private static Boolean accountUpdateIfCheck( Integer rowNumber, Case caseToLoad, CaseProcessWrapper cpw ){

        Boolean returnValue = false;

        if (cpw != null
            && cpw.caseRecord !=null
            && rowNumber != null
            && cpw.caseRecord.containsKey(rowNumber)
            && cpw.caseRecord.get(rowNumber) != null
            && caseToLoad !=null
            && caseToLoad.AccountId == null
            && cpw.accountToClientMap != null
            && cpw.accountToClientMap.containsKey(cpw.caseRecord.get(rowNumber))
            && cpw.accountToClientMap.get( cpw.caseRecord.get( rowNumber ) ) != null
            && cpw.rowCaseMap.containsKey(caseToLoad)
            && cpw.rowCaseMap.get(caseToLoad) != null
           )
        {
            returnValue = true;
        }

        return returnValue;
    }

    private static Boolean assetUpdateIfCheck( Integer rowNumber, Case caseToLoad, CaseProcessWrapper cpw ){

        Boolean returnValue = false;

        if ( cpw != null
             && cpw.caseRecord !=null
             && rowNumber != null
             && cpw.caseRecord.containsKey( rowNumber )
             && cpw.caseRecord.get( rowNumber ) != null
             && caseToLoad !=null
             && caseToLoad.AssetId == null
             && cpw.assetToClientMap != null
             && cpw.assetToClientMap.containsKey(cpw.caseRecord.get( rowNumber ) )
             && cpw.assetToClientMap.get(cpw.caseRecord.get(rowNumber)) != null
             && cpw.rowCaseMap.containsKey( caseToLoad )
             && cpw.rowCaseMap.get( caseToLoad ) != null
           )
        {
            returnValue = true;
        }
        return returnValue;
    }

    private static Boolean processContact( Boolean shouldContinue,
                                           Integer rowNumber,
                                           List<Integer> indicesToRemove,
                                           Case caseToLoad, CaseProcessWrapper cpw
                                         )
    {
        if ( contactUpdateIfCheck( rowNumber, caseToLoad, cpw )
             && shouldContinue )
        {
            List<String> row = cpw.rowCaseMap.get( caseToLoad );
            cpw.rowCaseMap.remove( caseToLoad );
            caseToLoad.ContactId = cpw.contactToPerIdMap.get( cpw.contactRecord.get( rowNumber ) );
            cpw.rowCaseMap.put( caseToLoad, row );
        } else if( contactUpdateIfElseCheck( rowNumber, caseToLoad, cpw ) && shouldContinue ) {
            indicesToRemove.add( cpw.caseList.indexOf( caseToLoad ) );
            cpw.createRecordMap.put(
                cpw.rowCaseMap.get( caseToLoad ),
                contactError + ' PerId - ' + cpw.contactRecord.get( rowNumber ) + errorRowNum + rowNumber
            );
            shouldContinue  = false;
        }

        return shouldContinue ;
    }

    private static Boolean contactUpdateIfElseCheck( Integer rowNumber, Case caseToLoad, CaseProcessWrapper cpw ){

        Boolean returnValue = false;

        if ( cpw != null
             && cpw.contactRecord !=null
             && rowNumber != null
             && cpw.contactRecord.containsKey( rowNumber )
             && cpw.contactRecord.get( rowNumber ) != null
             && caseToLoad !=null
             && cpw.caseList != null
             && !cpw.caseList.isEmpty()
             && !cpw.contactToPerIdMap.containsKey( cpw.contactRecord.get( rowNumber ) )
             && cpw.caseList.indexOf( caseToLoad ) >= 0
             && cpw.rowCaseMap.containsKey( caseToLoad )
             && cpw.rowCaseMap.get( caseToLoad ) != null
           )
        {
            returnValue = true;
        }

        return returnValue;
    }

    private static Boolean contactUpdateIfCheck( Integer rowNumber, Case caseToLoad, CaseProcessWrapper cpw ){

        Boolean returnValue = false;

        if (cpw != null
            && cpw.contactRecord !=null
            && rowNumber != null
            && cpw.contactRecord.containsKey(rowNumber)
            && cpw.contactRecord.get(rowNumber) != null
            && caseToLoad !=null
            && caseToLoad.ContactId == null
            && cpw.contactToPerIdMap != null
            && cpw.contactToPerIdMap.containsKey(cpw.contactRecord.get(rowNumber))
            && cpw.contactToPerIdMap.get( cpw.contactRecord.get( rowNumber ) ) != null
            && cpw.rowCaseMap.containsKey(caseToLoad)
            && cpw.rowCaseMap.get(caseToLoad) != null
           )
        {
            returnValue = true;
        }

        return returnValue;
    }

    private static Boolean processOwner( Boolean shouldContinue,
                                         Integer rowNumber,
                                         List<Integer> indicesToRemove,
                                         Case caseToLoad,
                                         CaseProcessWrapper cpw
                                       )
    {
        if ( ownerUpdateIfCheck( rowNumber, caseToLoad, cpw )
             && shouldContinue
           )
        {
            List<String> row = cpw.rowCaseMap.get( caseToLoad );
            cpw.rowCaseMap.remove( caseToLoad );
            caseToLoad.OwnerId = cpw.clientToUserMap.get( cpw.userRecord.get( rowNumber ) );
            if ( caseToLoad.OwnerId != null
                 && caseToLoad.OwnerId.getSObjectType() == Group.SObjectType
               )
            {
                caseToLoad.NSP_Assigned_Queue__c = cpw.userRecord.get( rowNumber );
            }
            cpw.rowCaseMap.put( caseToLoad, row );
        }
        else if ( emailUpdateIfCheck (rowNumber, caseToLoad, cpw )
                  && shouldContinue
                )
        {
            List<String> row = cpw.rowCaseMap.get( caseToLoad );
            cpw.rowCaseMap.remove( caseToLoad );
            caseToLoad.OwnerId = cpw.clientEmailtoUserMap.get( cpw.userRecord.get( rowNumber ) );
            if ( caseToLoad.OwnerId != null
                 && caseToLoad.OwnerId.getSObjectType() == Group.SObjectType
               )
            {
                caseToLoad.NSP_Assigned_Queue__c = cpw.userRecord.get( rowNumber );
            }

            cpw.rowCaseMap.put( caseToLoad, row );
        } else if ( ownerUpdateIfElseCheck( rowNumber, caseToLoad, cpw )
                    && shouldContinue
                  )
        {
            indicesToRemove.add( cpw.caseList.indexOf( caseToLoad ) );
            cpw.createRecordMap.put(
                cpw.rowCaseMap.get( caseToLoad ),
                userError + ' Owner - ' + cpw.userRecord.get( rowNumber ) + errorRowNum + rowNumber
            );
            shouldContinue  = false;
        }

        return shouldContinue;
    }

    private static Boolean ownerUpdateIfCheck( Integer rowNumber, Case caseToLoad, CaseProcessWrapper cpw ){

        Boolean returnValue = false;

        if ( cpw != null
             && rowNumber != null
             && cpw.userRecord != null
             && cpw.userRecord.containsKey( rowNumber )
             && cpw.userRecord.get( rowNumber ) != null
             && caseToLoad !=null
             && caseToLoad.OwnerId == null
             && cpw.clientToUserMap != null
             && cpw.clientToUserMap.containsKey(cpw.userRecord.get( rowNumber ) )
             && cpw.clientToUserMap.get( cpw.userRecord.get( rowNumber ) ) != null
             && cpw.rowCaseMap.containsKey( caseToLoad )
             && cpw.rowCaseMap.get( caseToLoad ) != null
           )
        {
            returnValue = true;
        }

        return returnValue;
    }

    private static Boolean ownerUpdateIfElseCheck( Integer rowNumber, Case caseToLoad, CaseProcessWrapper cpw){

        Boolean returnValue = false;

        if ( cpw != null
             && cpw.userRecord !=null
             && rowNumber != null
             && cpw.userRecord.containsKey( rowNumber )
             && cpw.userRecord.get( rowNumber ) != null
             && caseToLoad !=null
             && caseToLoad.OwnerId == null
             && cpw.caseList != null
             && !cpw.caseList.isEmpty()
             && cpw.caseList.indexOf( caseToLoad )>=0
             && cpw.rowCaseMap.containsKey( caseToLoad )
             && cpw.rowCaseMap.get( caseToLoad ) != null
           )
        {
            returnValue = true;
        }
        return returnValue;
    }

    private static Boolean emailUpdateIfCheck( Integer rowNumber, Case caseToLoad, CaseProcessWrapper cpw){

        Boolean returnValue = false;

        if ( cpw != null
             && cpw.userRecord != null
             && rowNumber != null
             && cpw.userRecord.containsKey( rowNumber )
             && cpw.userRecord.get( rowNumber ) != null
             && caseToLoad != null
             && caseToLoad.OwnerId == null
             && cpw.clientEmailtoUserMap != null
             && cpw.clientEmailtoUserMap.containsKey( cpw.userRecord.get( rowNumber ) )
             && cpw.clientEmailtoUserMap.get( cpw.userRecord.get( rowNumber ) ) != null
             && cpw.rowCaseMap.containsKey( caseToLoad )
             && cpw.rowCaseMap.get( caseToLoad ) != null
           )
        {
            returnValue = true;
        }

        return returnValue;
    }

    private static String processFailureMap( Map<List<String>, String> failureMap ) {

        String failureCsvContent = 'SL No,Contact,Account,Asset,Category,Sub Category,Detail,Owner,Origin,Priority,Status,Substatus,Resolution,Subject,Date Opened,Due Date,Closed Date,Confidential,Quick Rate,Record Type,Description,ErrorMessage\n';

        if ( failureMap != null
             && !failureMap.isEmpty()
             && failureMap.keySet() != null
             && !failureMap.keySet().isEmpty()
           )
        {
            for ( List<String> failureKey : failureMap.keySet() )
            {
                String errorMessage = '';
                if( failureMap.containsKey( failureKey )
                    && failureMap.get( failureKey ) != null
                  )
                {
                    errorMessage = failureMap.get( failureKey );
                }
                String rowContent = processFailureRow( failureKey, errorMessage );
                failureCsvContent += rowContent + '\n';
            }
        }

        return failureCsvContent;
    }

    private static String processFailureRow( List<String> failureKey, String errorMessage ) {

        List<String> processedFields = new List<String>();

        // Process first 20 fields
        if( failureKey !=null
            && !failureKey.isEmpty()
          )
        {
            for ( Integer i = 0; i <= 19 && i < failureKey.size(); i++ ) {

                String field = failureKey[ i ];

                if ( field.contains( ',' )
                     || field.contains( '"' )
                     || field.contains( '\n' )
                   )
                {
                    field = '"' + field.replace( '"', '""' ) + '"';
                }

                processedFields.add( field );
            }

            //process Description
            processedFields.addAll( processDescription( failureKey ) );

            // Quote error message
            if( String.isNotBlank( errorMessage ) )
            {
                processedFields.add( '"' + errorMessage.replace( '"', '""' ) + '"' );
            }
        }

        return String.join( processedFields, ',' );
    }

    private static List<String> processDescription( List<String> failureKey ) {

        List<String> processedFields = new List<String>();


            String finalDescription = '';
            String appendDescription = '';
            String description = concatenateDescription( failureKey, 20 );

            if( String.isNotBlank( description ) )
            {
                for ( Integer i = 0; i < description.length(); i++ )
                {
                    String currentChar = description.substring( i, i + 1 );
                    if ( !currentChar.equals( '\n' ) && !currentChar.equals( '\r' ) )
                    {
                        finalDescription += currentChar;
                    }
                }

                appendDescription = '"' + finalDescription + '"';
            }

            processedFields.add( appendDescription );

        return processedFields;
    }

    private static Id getRecordTypeId( String objectApiName, String developerName ) {

        Id recordTypeId = null;

        if( String.isNotBlank( objectApiName )
           && String.isNotBlank( developerName )
           && Schema.getGlobalDescribe().containsKey( objectApiName )
           && Schema.getGlobalDescribe().get( objectApiName ) != null
          )
        {

            Map<String, Schema.RecordTypeInfo> recordTypeMap =  Schema.getGlobalDescribe().get( objectApiName )
                .getDescribe()
                .getRecordTypeInfosByDeveloperName();
            if( recordTypeMap != null
               && recordTypeMap.containsKey( developerName )
               && recordTypeMap.get(developerName) != null
               && recordTypeMap.get(developerName).getRecordTypeId() != null
              )
            {
                recordTypeId = recordTypeMap.get(developerName).getRecordTypeId();
            }

        }

        return recordTypeId;
    }

    private static List<String> getCsvRowsFromContentDocument( Id contentDocumentId ) {

        List<String> rows = new List<String>();

        if ( contentDocumentId != null
             && String.isNotBlank( contentDocumentId )
           )
        {
            List<ContentVersion> versions = [
                SELECT VersionData
                FROM ContentVersion
                WHERE ContentDocumentId =:contentDocumentId
                LIMIT 1
            ];

            if ( versions != null
                 && !versions.isEmpty()
                 && versions[0].VersionData != null
               )
            {
                rows = versions[0].VersionData.toString().split('\n');
            }
        }
        return rows;
    }

    private static void performDeleteDML( Id contentDocumentId) {

        if ( contentDocumentId != null ) {

            try {
                List<Database.DeleteResult> results = new List<Database.DeleteResult>{ Database.delete( contentDocumentId, true) };
                    NSP_ErrorLogHandler.logResults(
                        FileUploadController.class.getName() ,
                        'performDML:delete' ,
                        results
                    );
            } catch( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    FileUploadController.class.getName() ,
                    'createImportError' ,
                    e
                );
            }
        }

    }

    private static List<String> getPicklistValues( String objectApiName, String fieldApiName ) {

        List<String> values = new List<String>();

        if ( String.isNotBlank( objectApiName )
            && String.isNotBlank( fieldApiName )
            && Schema.getGlobalDescribe().containsKey( objectApiName )
            && Schema.getGlobalDescribe().get( objectApiName ) != null

           )
        {
            Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get( objectApiName ).getDescribe().fields.getMap();

            if( fields != null
               && fields.containsKey( fieldApiName )
               && fields.get( fieldApiName ) != null
               && fields.get( fieldApiName ).getDescribe().getPicklistValues() != null
              )
            {
                for ( Schema.PicklistEntry entry : fields.get( fieldApiName ).getDescribe().getPicklistValues() ) {
                    values.add( entry.getValue() );
                }
            }


        }

        return values;
    }

    public static void sendEmail( List<ID> successList, Map<List<String>, String> failureMap) {

        User user = [ SELECT Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1 ];
        NSP_Trigger_Switch__c triggerSwitch = NSP_Trigger_Switch__c.getInstance( UserInfo.getUserId() );

        if ( triggerSwitch != null
             && !triggerSwitch.SendEmailFlow__c )
        {
            // Create CSV for success list
            String successCsvContent = 'ID\n'; // Header for success list
            if( successList.size()>0 )
            {
                for (ID successId : successList) {
                    successCsvContent += successId + '\n'; // Add each ID on a new line
                }
            }

            // Create CSV for failures
            String failureCsvContent = processFailureMap( failureMap );
            // Create email attachments
            Messaging.EmailFileAttachment successAttachment = new Messaging.EmailFileAttachment();
            successAttachment.setFileName( 'SuccessList.csv' );
            successAttachment.setBody( Blob.valueOf( successCsvContent ) );
            successAttachment.setContentType( 'text/csv' );

            Messaging.EmailFileAttachment failureAttachment = new Messaging.EmailFileAttachment();
            failureAttachment.setFileName( 'FailureList.csv' );
            failureAttachment.setBody( Blob.valueOf( failureCsvContent ) );
            failureAttachment.setContentType( 'text/csv' );

            // Prepare email body
            String mailBody = 'Case Import loaded successfully. Please find the success and error count detail below:';
            mailBody += '<br/><br/>' + 'Total Success: ' + successList.size() + '<br/>Total Failure: ' + failureMap.size();

            // Set email parameters
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { user.Email } );
            email.setSubject( 'Case Import Summary' );
            email.setHtmlBody( mailBody );
            email.setFileAttachments( new Messaging.EmailFileAttachment[] { successAttachment, failureAttachment } );

            // Send the email
            Messaging.sendEmail( new Messaging.SingleEmailMessage[] { email } );
        }
    }

    private static String concatenateDescription( List<String> row, Integer startIndex ) {

        String description = '';

        if( row != null
            && !row.isEmpty()
            && row.size() > 20
            && startIndex != null
          ){
             for (Integer i = startIndex; i < row.size(); i++) {
                if (i > startIndex) {
                    description += ', ';
                }
                description += row[i].replace('"', '');
            }
          }

        return description;
    }

    public static void createImportError( Map<list<String>, String> createRecordMap ){

        List<Import_Error__c> importErrorList = new List<Import_Error__c>();

        try{
            //Masthan null check map (done)
            if( createRecordMap != null )
            {
                 for( list<String> eachRow : createRecordMap.keySet() )
            		{
                        Import_Error__c eachError = new Import_Error__c();
                        eachError.Contact__c = eachRow[1];
                        eachError.Account__c = eachRow[2];
                        eachError.Asset__c = eachRow[3];
                        eachError.Category__c = eachRow[4];
                        eachError.SubCategory__c = eachRow[5];
                        eachError.Detail__c = eachRow[6];
                        eachError.Case_Owner__c = eachRow[7];
                        eachError.Origin__c = eachRow[8];
                        eachError.Priority__c = eachRow[9];
                        eachError.Status__c = eachRow[10];
                        eachError.Case_Sub_Status__c = eachRow[11];
                        eachError.Reason__c = eachRow[12];
                        eachError.Subject__c = eachRow[13];
                        eachError.Due_Date__c = eachRow[14];
                        eachError.Date_Time_Opened__c = eachRow[15];
                        eachError.Date_Closed__c = eachRow[16];
                        eachError.Confidential__c = eachRow[17];
                        eachError.Quick_Rate__c = eachRow[18];
                        eachError.Case_Record_Type_Id__c = eachRow[19];
                        eachError.Description__c = eachRow[20];

                        if( createRecordMap.containsKey( eachRow )
                            && String.isNotBlank( createRecordMap.get( eachRow ) )
                          )
                        {
                            eachError.Error_Message__c = createRecordMap.get( eachRow );
                        }

                        importErrorList.add( eachError );
            		}
            }


            if( importErrorList.size() > 0 )
            {
                insert importErrorList;
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                FileUploadController.class.getName() ,
                'createImportError' ,
                e
            );
        }

    }

    private static void bypassCustomSettings() {

        Case_Import_Tool_Settings__c caseSettings =  Case_Import_Tool_Settings__c.getInstance( UserInfo.getUserId() );
        caseSettings.SetupOwnerId = UserInfo.getUserId();
        caseSettings.Bypass_Opened_Date__c = true;
        upsert caseSettings;

        Notification_Deliverability_Settings__c caseEmailSetting = Notification_Deliverability_Settings__c.getInstance( UserInfo.getUserId() );
        caseEmailSetting.SetupOwnerId = UserInfo.getUserId();
        caseEmailSetting.IsEnabledOutbound__c = false;
        upsert caseEmailSetting;
    }

    public static Boolean validateHeaderRow( String headers ) {

        Boolean allConditionsMet = true;
        List<String> expectedValues = new List<String>{
                'Contact',
                'Account',
                'Asset',
                'Category',
                'Sub Category',
                'Detail',
                'Owner',
                'Origin',
                'Priority',
                'Status',
                'Substatus',
                'Resolution',
                'Subject',
                'Date Opened',
                'Due Date',
                'Closed Date',
                'Confidential',
                'Quick Rate',
                'Record Type',
                'Description'
             };

             if ( String.isNotBlank( headers ) ) {

                 List<String> headerRow = headers.split(',');
                 if( headerRow != null && !headerRow.isEmpty() )
                 {
                     for ( Integer i = 1; i < 21; i++ ) {
                         if ( String.isBlank( headerRow[i] )
                              || !headerRow[i].contains( expectedValues[ i - 1 ] )
                            )
                         {
                             allConditionsMet = false;
                         }
                     }
                 }
             }

        return allConditionsMet;
    }

    private static Id checkRecordTypeId( String value ) {
        Id returnValue = null;
        if( String.isBlank(value) || value == null ){
            returnValue = null;
        }
        else if( value.contains(NSP_ServiceConstants.PEO) )
        {
            returnValue = peoRecordTypeId;
        }
        else if( value.contains( DOL_AUDITS ) )
        {
            returnValue = dolAuditRecordTypeId;
        }
        else if( value.contains( WAGE_CLAIMS ) )
        {
            returnValue = wageClaimRecordTypeId;
        }
        else if( value.contains( NSP_ServiceConstants.BPS ) ){
            returnValue = bpsRecordTypeId;
        }
        else if( value.contains( dunningCase ) )
        {
            returnValue = dunningRecordTypeId;
        }
        else if( value.contains( NSP_ServiceConstants.SUB_CATEGORY_ITA_CQA ) )
        {
            returnValue = itaRecordTypeId;
        }
        else if( value.contains( rETTimeTracking ) )
        {
            returnValue = retRecordTypeId;
        }
        else if( value.contains( wXIMPL ) )
        {
            returnValue = wxRecordTypeId;
        }

        return returnValue;
    }


    public class CsvRowWrapper{

        public Case caseRecord{set;get;}
        public Integer rowNum{set;get;}
        public List<String> row{set;get;}
        public String errorMessage{set;get;}
        public String assestLink{set;get;}
        public String contactLink{set;get;}
        public String ownerLink{set;get;}
        public String confidentialRecordOwner{set;get;}

    }

    public class CaseProcessWrapper{

        public List<List<String>> allRowValue{set;get;}
        public List<Case> caseList{set;get;}
        public  Map<Integer,String> caseRecord{set;get;}
        public  Map<Integer,String> contactRecord{set;get;}
        public  Map<Integer,String> userRecord{set;get;}
        public  Map<Integer,String> confidentialRecord{set;get;}
        public  Map<String,String> clientToUserMap{set;get;}
        public  Map<String,String> clientEmailtoUserMap{set;get;}
        public  Map<String,String> accountToClientMap{set;get;}
        public  Map<String,String> assetToClientMap{set;get;}
        public  Map<String,String> contactToPerIdMap{set;get;}
        public  Map<Case,List<String>> rowCaseMap{set;get;}
        public  Map<List<String>,String> createRecordMap{set;get;}

    }

}