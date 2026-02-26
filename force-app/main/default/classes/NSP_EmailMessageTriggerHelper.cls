public with sharing class NSP_EmailMessageTriggerHelper {
    // test w/ NSP_EmailMessageTriggerHelperTest (86%)

    public static boolean isFirst = false;
    private static List<String> ContactCenterEmailAddresses = System.Label.NSP_Contact_Center_Email_Addresses.toLowerCase().split( ',' );
    public static final String QUEUE = 'Queue';
    public static final String CONTACTCENTER = 'NSP_ContactCenter';
    private static final Id CONTACTCENTER_QUEUEID = '00G4x000001fXVREA2';
    public static final String REOPENED = 'ReOpened';
    public static final String CLOSED = 'Closed';
    public static final String UNASSIGNED = 'Unassigned';
    public static final String OPEN = 'Open';
    private static final Id PEO_RECORDTYPEID = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'PEO' );
    private static final Id BPS_RECORDTYPEID = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'BPS' );

    public void afterInsertionEmailMessage( List<EmailMessage> newList , Map<Id,EmailMessage> newMap ) {
        Boolean switchEnabled = EmailMessageTriggerSettings__c.getInstance( UserInfo.getUserId() ).IsHealthAndWelfareEmailMessageEnabled__c;
        Set<Id> parentIds = new Set<Id>();
        Set<Id> employmentScreeningcaseIdSet = new Set<Id>();
        Map<Id,EmailMessage> healthWelfareInternalExternalCaseIdFromAddMap = new Map<Id,EmailMessage>();
        for ( EmailMessage eMessage : newList ) {
            if ( ( eMessage.ParentId != null ) && incomingEmailCheck( eMessage ) ) {
                parentIds.add( eMessage.ParentId );
            }
            //As a part of STY-03671
            if ( eMessage.ToAddress == System.Label.NSP_Customer_Service_Email
                || eMessage.ToAddress == System.Label.NSP_Les_Drug_Screening_Email
                )
            {
                employmentScreeningcaseIdSet.add(eMessage.ParentId);
            }
            //As a part of STY-03531
            if ( !switchEnabled && ( eMessage.ToAddress == System.Label.NSP_Health_Welfare_Section_125 ) ) {
                healthWelfareInternalExternalCaseIdFromAddMap.put( eMessage.ParentId , eMessage );
            }
        }
        Set<Id> validatedParentIds = new Set<Id>();
        if ( !parentIds.isEmpty() ) {
            // prevent Validation Rule DmlExceptions by excluding 'Closed' Cases from the list of Cases modified by this logic...
            List<Case> validatedParents = [
                SELECT Id
                FROM Case
                WHERE (
                    ( Id IN :parentIds )
                    AND ( Status != 'Closed' )
                )
            ];
            Map<Id,Case> validatedParentsMap = new Map<Id,Case>();
            if ( ( validatedParents != null ) && !validatedParents.isEmpty() ) {
                validatedParentsMap = new Map<Id,Case>( validatedParents );
            }
            validatedParentIds = validatedParentsMap.keySet();
        }
        List<Case> caseToUpdate = new List<Case>();
        if ( !validatedParentIds.isEmpty() ) {
            //Added as a part of STY-04132
            for ( Id caseId : validatedParentIds ) {
                Case caseRecord = new Case();
                caseRecord.Id = caseId;
                caseRecord.NSP_Case_Created_From_Email_To_Case__c = true;
                caseToUpdate.add( caseRecord );
            }
        }
        if ( !parentIds.isEmpty() ) {
            NSP_WebCaseAssignment.webCaseAssign( parentIds , newList );
            reOpenOrMarkResponseAfterCloseTrue( parentIds , newList );
        }
        //As a part of STY-03671
        if ( !employmentScreeningcaseIdSet.isEmpty() ) {
            updateConfidentialCheckBoxForEmpScreening( employmentScreeningcaseIdSet );
        }
        //As a part of STY-03531
        if ( !switchEnabled && !healthWelfareInternalExternalCaseIdFromAddMap.isEmpty() ) {
            sendEmailToHealthWelfareInternalExternal( healthWelfareInternalExternalCaseIdFromAddMap );
        }
        // Added as a part of STY-04132
        if ( !caseToUpdate.isEmpty() ) {
            List<Database.SaveResult> results = Database.update( caseToUpdate , false );
            NSP_ErrorLogHandler.logResults(
                NSP_EmailMessageTriggerHelper.class.getName() ,
                'afterInsertionEmailMessage' ,
                results
            );
        }
    }

    //
    // MethodName: beforeInsertionEmailMessage
    // Description: This method will be called before insert of EmailMessage
    // Story : STY-03643
    // Params: List<EmailMessage> listOfEmailMessage
    //
    public void beforeInsertionEmailMessage( List<EmailMessage> newList ) {
        restrictEmailFromRestrictedSenders( newList );
    }

    // ***********************************************************************************************
    // Description: This method will reOpen an existing case if days between closing of (BPS) Case
    // and EmailMessage date is less than 90 days,else, it will mark Response After Close to True
    // Date : 17/11/2021
    // Modified Date : 20/09/2021
    // Update- This Method will also will reOpen an existing case if days between closing of
    // case (PEO) and EmailMessage date is within 5 days,else, it will create a new Case
    // ***********************************************************************************************
    private static void reOpenOrMarkResponseAfterCloseTrue( Set<Id> caseIds , List<EmailMessage> listOfEmailMessage ) {
        if ( ( caseIds != null ) && !caseIds.isEmpty() ) {
            //
            Map<Id,Case> mapOfCaseIdAndCase = new Map<Id,Case>([
                SELECT
                    Status , NSP_Response_After_Close__c , NSP_Case_Reopened_EmaiToCase__c , NSP_Case_Sub_Status__c ,
                    ClosedDate , NSP_Date_Closed__c , RecordTypeId , Origin , Priority , NSP_SubCategory__c ,
                    NSP_Category__c , ContactId , AccountId , AssetId , Subject , OwnerId , Description
                FROM Case
                WHERE ( Id IN : caseIds )
            ]);
            Map<Id,User> mapOfUserIdToUserRecord = new Map<Id,User>();
            if ( mapOfCaseIdAndCase != null ) {
                Set<Id> userIds = new Set<Id>();
                for ( Case caseRecord:mapOfCaseIdAndCase.values() ) {
                    if ( ( caseRecord.OwnerId != null )
                        && Id.valueOf( caseRecord.OwnerId ).getSObjectType() == User.getSObjectType()
                        )
                    {
                        userIds.add( caseRecord.OwnerId );
                    }
                }
                if ( ( userIds != null ) && !userIds.isEmpty() ){
                    mapOfUserIdToUserRecord = new Map<Id,User>([
                        SELECT Id , IsActive
                        FROM User
                        WHERE ( Id IN :userIds )
                    ]);
                }
            }
            //
            List<Case> casesToUpdate = new List<Case>();
            Map<Case,EmailMessage> caseToEmailMessageMap = new Map<Case,EmailMessage>();
            Map<String,String> mapOfEmailAddressToQueueName = new Map<String,String>();
            Map<String,String> mapOfQueueNameToQueueId = new Map<String,String>();
            if ( ( listOfEmailMessage != null ) && !listOfEmailMessage.isEmpty() ) {
                mapOfEmailAddressToQueueName = getMapOfEmailAddressToQueueName( listOfEmailMessage );
                mapOfQueueNameToQueueId = getMapOfQueueNameToQueueId( mapOfEmailAddressToQueueName );
                for ( EmailMessage eMessage : listOfEmailMessage ) {
                    if ( mapOfCaseIdAndCase.containsKey( eMessage.ParentId ) ) {
                        Case currentCase = mapOfCaseIdAndCase.get( eMessage.ParentId );
                        if ( ( currentCase != null )
                            && ( currentCase.ClosedDate != null )
                            && ( eMessage.MessageDate != null )
                            && ( eMessage.Source != 'Email Integration App Manual' )
                            )
                        {
                            List<String> toAddressList = NSP_EmailMessageTriggerHelper.getAddressList( eMessage );
                            Boolean isContactCenterToAddress = NSP_EmailMessageTriggerHelper.isContactCenterCase( toAddressList );
                            if ( ( currentCase.RecordTypeId == BPS_RECORDTYPEID )
                                || (
                                    ( currentCase.RecordTypeId == NSP_EmailMessageTriggerHelper.PEO_RECORDTYPEID )
                                    && !isContactCenterToAddress
                                    )
                                )
                            {
                                Integer daysBetween = (currentCase.ClosedDate.date()).daysBetween( eMessage.MessageDate.date() );
                                if ( NSP_EmailMessageTriggerHelper.isLessThanEqualToCategoryTierDays( currentCase.NSP_Category__c , daysBetween ) ) {
                                    currentCase.Status = REOPENED;
                                    currentCase.NSP_Case_Reopened_EmaiToCase__c = true;
                                    currentCase.OwnerId = NSP_EmailMessageTriggerHelper.getQueueOwnerId(
                                        currentCase.OwnerId ,
                                        eMessage ,
                                        mapOfEmailAddressToQueueName ,
                                        mapOfQueueNameToQueueId ,
                                        mapOfUserIdToUserRecord
                                    );
                                    casesToUpdate.add( currentCase );
                                } else if ( NSP_EmailMessageTriggerHelper.isGreaterThanCategoryTierDays( currentCase.NSP_Category__c , daysBetween ) ) {
                                    currentCase.NSP_Response_After_Close__c = true;
                                    casesToUpdate.add( currentCase );
                                    caseToEmailMessageMap.put( currentCase , eMessage );
                                } else if (
                                    ( currentCase.RecordTypeId == NSP_EmailMessageTriggerHelper.PEO_RECORDTYPEID )
                                    && !isContactCenterToAddress
                                    )
                                {
                                    currentCase.NSP_Response_After_Close__c = true;
                                    casesToUpdate.add( currentCase );
                                }
                            } else if (
                                ( currentCase.RecordTypeId == NSP_EmailMessageTriggerHelper.PEO_RECORDTYPEID )
                                && isContactCenterToAddress
                                && ( currentCase.Status == CLOSED )
                                )
                            {
                                Integer businessDaysBetween = getNoOfBusinessDaysBetweenDates(
                                    currentCase.ClosedDate.date() ,
                                    eMessage.MessageDate.date()
                                );
                                if ( businessDaysBetween <= 5 ) {
                                    currentCase.Status = REOPENED;
                                    currentCase.NSP_Case_Sub_Status__c = UNASSIGNED;
                                    currentCase.OwnerId = NSP_EmailMessageTriggerHelper.CONTACTCENTER_QUEUEID;
                                    currentCase.NSP_Response_After_Close__c = true;
                                    casesToUpdate.add( currentCase );
                                } else {
                                    caseToEmailMessageMap.put( currentCase , eMessage );
                                    currentCase.NSP_Response_After_Close__c = true;
                                    casesToUpdate.add( currentCase );
                                }
                            }
                        }
                    }
                }
            }
            //
            if ( !caseToEmailMessageMap.isEmpty() ) {
                List<Case> insertedCases = createCaseFromEmail(
                    caseToEmailMessageMap ,
                    NSP_EmailMessageTriggerHelper.CONTACTCENTER_QUEUEID ,
                    mapOfEmailAddressToQueueName ,
                    mapOfQueueNameToQueueId
                );
                if ( !insertedCases.isEmpty() ) {
                    updateRelatedCaseOnEmailMessage( caseToEmailMessageMap , insertedCases );
                }
            }
            if ( !casesToUpdate.isEmpty() ) {
                try {
                    List<Database.SaveResult> results = Database.update( casesToUpdate , false );
                    NSP_ErrorLogHandler.logResults(
                        NSP_EmailMessageTriggerHelper.class.getName() ,
                        'reOpenOrMarkResponseAfterCloseTrue:update' ,
                        results
                    );
                } catch ( Exception e ) {
                    NSP_ErrorLogHandler.logException(
                        NSP_EmailMessageTriggerHelper.class.getName() ,
                        'reOpenOrMarkResponseAfterCloseTrue' ,
                        e
                    );
                }
            }
        }
    }

    // ********************************************************************************************
    // MethodName    : isContactCenterCase
    // Description   : Check if ToAddress contains Contact Center Email
    // Story         : STY-04647
    // Params        : List<String> ContactCenterEmailAddresses , List<String> ToAddress
    // ********************************************************************************************
    private static Boolean isContactCenterCase( List<String> ToAddress ) {
        Integer count = 0;
        if ( ( ToAddress != null )
            && !ToAddress.isEmpty()
            && ( NSP_EmailMessageTriggerHelper.ContactCenterEmailAddresses != null )
            && !NSP_EmailMessageTriggerHelper.ContactCenterEmailAddresses.isEmpty()
            )
        {
            for ( String str : ToAddress ) {
                if ( NSP_EmailMessageTriggerHelper.ContactCenterEmailAddresses.contains( str.toLowerCase() ) ) {
                    count++;
                }
            }
        }
        Boolean isPresent = False;
        if ( count > 0 ) {
            isPresent = True;
        }
        return isPresent;
    }

    // helper method to reduce sonar cognitive complexity...
    private static Boolean isLessThanEqualToCategoryTierDays( String caseCategory , Integer daysBetween ) {
        Boolean response = false;
        if ( String.isNotBlank( caseCategory ) && ( daysBetween != null ) ) {
            response = (
                ( NSP_EmailMessageTriggerHelper.bpsCaseTier1Categories.contains( caseCategory ) && ( daysBetween <= NSP_EmailMessageTriggerHelper.tier1Days ) )
                || ( NSP_EmailMessageTriggerHelper.bpsCaseTier2Categories.contains( caseCategory ) && ( daysBetween <= NSP_EmailMessageTriggerHelper.tier2Days ) )
                || ( NSP_EmailMessageTriggerHelper.bpsCaseTier3Categories.contains( caseCategory ) && ( daysBetween <= NSP_EmailMessageTriggerHelper.tier3Days ) )
            );
        }
        return response;
    }

    // helper method to reduce sonar cognitive complexity...
    private static Boolean isGreaterThanCategoryTierDays( String caseCategory , Integer daysBetween ) {
        Boolean response = false;
        if ( String.isNotBlank( caseCategory ) && ( daysBetween != null ) ) {
            response = (
                ( NSP_EmailMessageTriggerHelper.bpsCaseTier1Categories.contains( caseCategory ) && ( daysBetween > NSP_EmailMessageTriggerHelper.tier1Days ) )
                || ( NSP_EmailMessageTriggerHelper.bpsCaseTier2Categories.contains( caseCategory ) && ( daysBetween > NSP_EmailMessageTriggerHelper.tier2Days ) )
                || ( NSP_EmailMessageTriggerHelper.bpsCaseTier3Categories.contains( caseCategory ) && ( daysBetween > NSP_EmailMessageTriggerHelper.tier3Days ) )
            );
        }
        return response;
    }

    // helper method to reduce sonar cognitive complexity...
    private static Id getQueueOwnerId(
        Id currentOwnerId ,
        EmailMessage eMessage ,
        Map<String,String> mapOfEmailAddressToQueueName ,
        Map<String,String> mapOfQueueNameToQueueId ,
        Map<Id,User> mapOfUserIdToUserRecord
        )
    {
        Id response = currentOwnerId;
        String queueName = '';
        if ( ( eMessage != null ) && ( mapOfEmailAddressToQueueName != null ) ) {
            queueName = mapOfEmailAddressToQueueName.get( eMessage.ToAddress );
        }
        if ( String.isNotBlank( queueName ) && ( mapOfQueueNameToQueueId != null ) ) {
            if ( currentOwnerId != null ) {
                if ( ( Id.valueOf( currentOwnerId ).getSObjectType() == User.getSObjectType() )
                    && !NSP_EmailMessageTriggerHelper.isUserActive( currentOwnerId , mapOfUserIdToUserRecord )
                    )
                {
                    // change the owner to a queue when the current owner is not active...
                    response = mapOfQueueNameToQueueId.get( queueName );
                }
            } else {
                response = mapOfQueueNameToQueueId.get( queueName );
            }
        }
        return response;
    }

    // helper method to reduce sonar cognitive complexity...
    private static Boolean isUserActive( Id userId , Map<Id,User> mapOfUserIdToUserRecord ) {
        Boolean response = false;
        if ( ( userId != null )
            && ( mapOfUserIdToUserRecord != null )
            && mapOfUserIdToUserRecord.containsKey( userId )
            )
        {
            User userRecord = mapOfUserIdToUserRecord.get( userId );
            if ( userRecord != null ) {
                response = userRecord.IsActive;
            }
        }
        return response;
    }

    //
    // MethodName    : getNoOfBusinessDaysBetweenDates
    // Description   : Get number of business days between two dates
    // Story         : STY-04647
    // Params        : Date startDate, DateTime endDate
    //
    private static Integer getNoOfBusinessDaysBetweenDates(Date startDate, Date endDate){
        Integer workingDays = 0;
        if ( ( startDate != null ) && ( endDate != null ) ) {
            for ( Integer i=0 ; i <= startDate.daysBetween( endDate ) ; i++ ) {
                Date dt = startDate.addDays( i );
                DateTime currDate = DateTime.newInstance( dt.year() , dt.month() , dt.day() );
                String todayDay = currDate.format( 'EEEE' );
                if ( ( todayDay != 'Saturday' ) && ( todayDay != 'Sunday' ) ) {
                    workingDays = workingDays + 1;
                }
            }
        }
        return workingDays;
    }

    //
    // MethodName    : createCaseFromEmail
    // Description   : method to Create case based on Parent Case
    // Story         : STY-04647
    // Params        : Map<Case,String> CaseToSubjectMap, ID contactCenterQueueId
    //
    public static List<Case> createCaseFromEmail(
        Map<Case,EmailMessage> caseToEmailMessageMap ,
        Id contactCenterQueueId ,
        Map<String,String> mapOfEmailAddressToQueueName ,
        Map<String,String> mapOfQueueNameToQueueId
        )
    {
        List<Case> caseToInsert = new List<Case>();
        try {
            if ( caseToEmailMessageMap != null ) {
                for ( Case getCase : caseToEmailMessageMap.keySet() ) {
                    EmailMessage record = caseToEmailMessageMap.get( getCase );
                    if ( record != null ) {
                        Case newCase = new Case();
                        newCase.OwnerId = caseOwnerAssignment( getCase , record , contactCenterQueueId , mapOfEmailAddressToQueueName ,  mapOfQueueNameToQueueId);
                        // Safely set the Case description
                        newCase.Description = SchemaController.safeText(
                            record.TextBody ,
                            sObjectType.Case.Fields.Description
                        );
                        newCase.ParentId = getCase.Id;
                        newCase.RecordTypeId = getCase.RecordTypeId;
                        newCase.Status = OPEN;
                        newCase.NSP_Case_Sub_Status__c = UNASSIGNED;
                        newCase.AccountId = getCase.AccountId;
                        newCase.AssetId = getCase.AssetId;
                        newCase.ContactId = getCase.ContactId;
                        newCase.NSP_Category__c = getCase.NSP_Category__c;
                        newCase.NSP_SubCategory__c = getCase.NSP_SubCategory__c;
                        newCase.Priority = getCase.Priority;
                        newCase.Origin = getCase.Origin;
                        newCase.Subject = record.Subject;
                        caseToInsert.add( newCase );
                    }
                }
            }
            if ( !caseToInsert.isEmpty() ) {
                Database.insert(caseToInsert, false);
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_EmailMessageTriggerHelper.class.getName() ,
                'createCaseFromEmail' ,
                e
            );
        }
        return caseToInsert;
    }

    //
    // MethodName    : caseOwnerAssignment
    // Description   : method to Assigns the appropriate Case Owner (Queue) ID based on the Case's record type and email recipients.
    // Story         : ADO-351648
    // Params        : Case getCase,EmailMessage record,ID contactCenterQueueId
    //
    private static Id caseOwnerAssignment(
        Case getCase ,
        EmailMessage record ,
        Id contactCenterQueueId ,
        Map<String,String> mapOfEmailAddressToQueueName ,
        Map<String,String> mapOfQueueNameToQueueId
        )
    {
        Id caseOwnerId = ( getCase != null ) ? getCase.OwnerId : null;
        List<String> toAddressList = NSP_EmailMessageTriggerHelper.getAddressList(record);
        Boolean isContactCenter = (
            NSP_EmailMessageTriggerHelper.isContactCenterCase( toAddressList )
            && ( getCase.RecordTypeId == NSP_EmailMessageTriggerHelper.PEO_RECORDTYPEID )
        );
        if ( isContactCenter ) {
            caseOwnerId = contactCenterQueueId;
        } else if ( ( getCase.RecordTypeId == NSP_EmailMessageTriggerHelper.BPS_RECORDTYPEID )
            || ( getCase.RecordTypeId == NSP_EmailMessageTriggerHelper.PEO_RECORDTYPEID )
            )
        {
            String queueName = NSP_EmailMessageTriggerHelper.getQueueNameFromEmail(
                mapOfEmailAddressToQueueName ,
                record
            );
            if ( String.isNotBlank( queueName )
                && ( mapOfQueueNameToQueueId != null )
                && mapOfQueueNameToQueueId.containsKey( queueName )
                && ( mapOfQueueNameToQueueId.get( queueName ) != null )
                )
            {
                caseOwnerId = mapOfQueueNameToQueueId.get( queueName );
            }
        }
        return caseOwnerId;
    }

    private static List<String> getAddressList( EmailMessage record ) {
        List<String> toAddressList = new List<String>();
        if ( String.isNotBlank( record.ToAddress ) ) {
            toAddressList = record.ToAddress.split( ';' );
        }
        return toAddressList;
    }

    //Method to get queue name from email address.
    private static String getQueueNameFromEmail( Map<String,String> mapOfEmailAddressToQueueName , EmailMessage record ) {
        List<String> queueNames = new List<String>();
        String queueName = null;
        if (record != null && mapOfEmailAddressToQueueName != null) {
            // Split 'To' and 'Cc' addresses
            List<String> toAddressList = String.isNotBlank(record.ToAddress)
                ? record.ToAddress.split(';\\s*')
                : new List<String>();
            List<String> ccAddressList = String.isNotBlank(record.CcAddress)
                ? record.CcAddress.split(';\\s*')
                : new List<String>();
            // Combine both address lists
            toAddressList.addAll(ccAddressList);
            // Check and collect queue names from map
            for (String emailAddress : toAddressList) {
                queueName = mapOfEmailAddressToQueueName.get(emailAddress);
                if (String.isNotBlank(queueName)) {
                    queueNames.add(queueName);
                }
            }
        }
        queueName = (queueNames != null && !queueNames.isEmpty()) ? queueNames[0] : null;
        return queueName;
    }

    //
    // MethodName    : updateRelatedCaseOnEmailMessage
    // Description   : method to clone Email Message and delete duplicate Email message
    // Story         : STY-04647
    // Params        : Map<Case,EmailMessage> ParentCaseToEmailMessageMap,List<Case> insertedCaseList
    //
    public static void updateRelatedCaseOnEmailMessage( Map<Case,EmailMessage> ParentCaseToEmailMessageMap , List<Case> insertedCaseList ) {
        // List to keep clone Email Messages
        List<EmailMessage> emailMessageClonedList = new List<EmailMessage>();
        // List to delete the cloned Email Message
        List<EmailMessage> emailMessageInserted = new List<EmailMessage>();
        Set<Id> emailMessageTobeDeleted = new Set<Id>();
        Boolean isRelatedEmailMessageEnabled = EmailMessageTriggerSettings__c.getInstance( UserInfo.getUserId() ).IsRelatedEmailMessageEnabled__c;
        try{
            for ( EmailMessage emailMessage : ParentCaseToEmailMessageMap.Values() ) {
                if ( emailMessage != null && emailMessage.ParentId != null ) {
                    // Clonning the Email Message
                    EmailMessage emailMessageCloned = emailMessage.clone( false , true , false , false );
                    if ( isRelatedEmailMessageEnabled ) {
                        emailMessageCloned.Related_Email_Message__c = emailMessage.Id;
                    } else {
                        emailMessageTobeDeleted.add( emailMessage.Id );
                    }
                    emailMessageClonedList.add( emailMessageCloned );
                }
            }
            // insert updated cases
            if ( !emailMessageClonedList.isEmpty() ) {
                emailMessageInserted = updateParentIdOnClonedEmailMessage(
                    emailMessageClonedList ,
                    insertedCaseList
                );
            }
            if ( !emailMessageInserted.isEmpty() ) {
                if ( isRelatedEmailMessageEnabled ) {
                    Map<Id,Id> oldVsNewEmailMessageMap = new Map<Id,Id>();
                    for ( EmailMessage em : emailMessageInserted ) {
                        oldVsNewEmailMessageMap.put( em.Related_Email_Message__c , em.id );
                    }
                    handleDmlOperationsRelatedEmailMessages( oldVsNewEmailMessageMap );
                } else {
                    // After process, delete all the Email Message Records which are cloned.
                    deleteEmailMessages( emailMessageTobeDeleted );
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_EmailMessageTriggerHelper.class.getName() ,
                'updateRelatedCaseOnEmailMessage' ,
                e
            );
        }
    }

    // MethodName: handleDmlOperationsRelatedEmailMessages
    // Description: Handles Dml Operations of Related EmailMessages
    // Story: AZD-320679
    // Params: Map<Id,Id> linkedEntityIdMap
    private static void handleDmlOperationsRelatedEmailMessages( Map<Id,Id> linkedEntityIdMap ) {
        cloneContentDocumentLinks(linkedEntityIdMap);
        // After process, delete all the Email Message Records which are cloned.
        if ( ( linkedEntityIdMap != null ) && !linkedEntityIdMap.isEmpty() ) {
            deleteEmailMessages( linkedEntityIdMap.keySet() );
        }
    }

    // MethodName: cloneContentDocumentLinks
    // Description: Method to create ContentDocumentLink of cloned Email Message record.
    // Story: AZD-320679
    // Params: Map<Id,Id> linkedEntityIdMap
    private static void cloneContentDocumentLinks( Map<Id,Id> linkedEntityIdMap ) {
        List<ContentDocumentLink> contentDocumentLinkClonedList = new list<ContentDocumentLink>();
        List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
        try {
            if ( ( linkedEntityIdMap != null ) && !linkedEntityIdMap.isEmpty() ) {
                contentDocumentLinkList = [
                    SELECT Id , ContentDocumentId , LinkedEntityId
                    FROM ContentDocumentLink
                    WHERE ( LinkedEntityId IN :linkedEntityIdMap.keySet() )
                ];
            }
            if ( !contentDocumentLinkList.isEmpty() ) {
                for ( ContentDocumentLink cLink : contentDocumentLinkList ) {
                    if ( ( cLink.LinkedEntityId != null )
                        && linkedEntityIdMap.containsKey( cLink.LinkedEntityId )
                        )
                    {
                        ContentDocumentLink contentDocumentLinkCloned = cLink.clone( false , true , false , false );
                        contentDocumentLinkCloned.LinkedEntityId = linkedEntityIdMap.get( cLink.LinkedEntityId );
                        contentDocumentLinkClonedList.add( contentDocumentLinkCloned );
                    }
                }
            }
            if ( !contentDocumentLinkClonedList.isEmpty() ) {
                insert contentDocumentLinkClonedList;
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_EmailMessageTriggerHelper.class.getName() ,
                'cloneContentDocumentLinks' ,
                e
            );
        }
    }

    // MethodName: deleteEmailMessages
    // Description: Method to delete cloned Email Message record.
    // Story: AZD-320679
    // Params: Set<Id> recordIds
    private static void deleteEmailMessages( Set<Id> recordIds ) {
        try {
            if ( ( recordIds != null ) && !recordIds.isEmpty() ) {
                List<EmailMessage> emailMessageTobeDeleted = [
                    SELECT Id
                    FROM EmailMessage
                    WHERE ( Id IN :recordIds )
                ];
                if ( ( emailMessageTobeDeleted != null ) && !emailMessageTobeDeleted.isEmpty() ) {
                      delete emailMessageTobeDeleted;
                }
            }
          } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_EmailMessageTriggerHelper.class.getName() ,
                'deleteEmailMessages' ,
                e
            );
        }
    }

    // MethodName    : updateParentIdOnClonedEmailMessage
    // Description   : Method to insert updated Email Message record.
    // Story         : STY-04647
    // Params        : List<EmailMessage> emailMessageClonedList, List<Case> insertedCaseList
    //
    private static List<EmailMessage> updateParentIdOnClonedEmailMessage( List<EmailMessage> emailMessageClonedList , List<Case> insertedCaseList ) {
        List<EmailMessage> emailMessageToBeInserted = New List<EmailMessage>();
        Map<Id,Id> parentCaseIdToCaseIdMap = new Map<Id,Id>();
        try{
            for ( Case c : insertedCaseList ) {
                parentCaseIdToCaseIdMap.put( c.ParentId , c.Id );
            }
            for ( EmailMessage eMessage : emailMessageClonedList ) {
                if ( parentCaseIdToCaseIdMap.containsKey( eMessage.ParentId )
                    && ( parentCaseIdToCaseIdMap.get( eMessage.ParentId ) != null )
                    )
                {
                    // Update Parent Id
                    eMessage.ParentId = parentCaseIdToCaseIdMap.get( eMessage.ParentId );
                    emailMessageToBeInserted.add( eMessage );
                }
            }
            // Insert Updated Email Messages
            if ( !emailMessageToBeInserted.isEmpty() ) {
                insert emailMessageToBeInserted;
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_EmailMessageTriggerHelper.class.getName() ,
                'updateParentIdOnClonedEmailMessage' ,
                e
            );
        }
        return emailMessageToBeInserted;
    }

    // MethodName    : restrictEmailFromRestrictedSenders
    // Description   : Restrict Email to Case from restricted senders
    // Story         : STY-03643
    // Params        : List<EmailMessage> listOfEmailMessage
    public static void restrictEmailFromRestrictedSenders( List<EmailMessage> listOfEmailMessage ) {
        try{
            if ( ( listOfEmailMessage != null ) && !listOfEmailMessage.isEmpty() ) {
                for ( EmailMessage eMessage : listOfEmailMessage ) {
                    if ( restrictedEmailCheck( eMessage ) ) {
                        eMessage.addError(
                            'EmailMessage cannot be created as sender is from restricted list.'
                        );
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_EmailMessageTriggerHelper.class.getName() ,
                'restrictEmailFromRestrictedSenders' ,
                e
            );
        }
    }

    // MethodName  : restrictedEmailCheck
    // Description : Restrict Email check
    // Story       : STY-03643
    // Params      : EmailMessage eMessage
    private static Boolean restrictedEmailCheck( EmailMessage eMessage ) {
        List<String> restrictedEmailAddresses = new List<String>();
        if ( String.isNotBlank( System.Label.NSP_Restricted_Email_Addresses ) ) {
            restrictedEmailAddresses = System.Label.NSP_Restricted_Email_Addresses.split( ',' );
        }
        return (
            ( eMessage != null )
            && eMessage.Incoming
            && String.isNotBlank( eMessage.FromAddress )
            && (
                restrictedEmailAddresses.contains( eMessage.FromAddress )
                || eMessage.FromAddress.startsWith( 'postmaster@' )
            )
        );
    }

    // ********************************************************************************************
    // MethodName: incomingEmailCheck
    // Description: Incoming Email check for subject check
    // Story : STY-03643
    // Params: EmailMessage eMessage
    // ********************************************************************************************
    private static Boolean incomingEmailCheck( EmailMessage eMessage ) {
        return (
            ( eMessage != null ) // prevent NullPointerException...
            && eMessage.Incoming
            && ( eMessage.ParentId != null ) // prevent NullPointerException when EmailMessage is not related to a Case...
            && ( eMessage.ParentId.getSObjectType() == Case.getSObjectType() )
            && String.isNotBlank( eMessage.Subject ) // prevent NullPointerException when Subject is missing a value...
            && !eMessage.Subject.containsIgnoreCase( 'OOO' )
            && !eMessage.Subject.containsIgnoreCase( 'Out of Office' )
            && !eMessage.Subject.containsIgnoreCase( 'Auto-Response' )
            && !eMessage.Subject.containsIgnoreCase( 'Auto Response' )
            && !eMessage.Subject.containsIgnoreCase( 'Auto-Reply' )
            && !eMessage.Subject.containsIgnoreCase( 'Auto Reply' )
            && !eMessage.Subject.containsIgnoreCase( 'Automatic Response' )
            && !eMessage.Subject.containsIgnoreCase( 'Automatic-Response' )
            && !eMessage.Subject.containsIgnoreCase( 'Automatic Reply' )
            && !eMessage.Subject.containsIgnoreCase( 'Automatic-Reply' )
        );
    }

    //
    // MethodName : updateConfidentialCheckBoxForEmpScreening
    // Story : STY-03671
    // Description : This method will update the case fields if an email is sent to
    // 'test.customer.service@insperity.com' or 'test.lesdrugscreening.service@insperity.com
    // Params : Set<Id> caseIdSet
    //
    public static void updateConfidentialCheckBoxForEmpScreening( Set<Id> caseIdSet ) {
        List<Case> caseListToUpdate = new List<Case>();
        try {
            for ( Case caseRec: [
                        SELECT Id , NSP_Confidential__c , NSP_Category__c
                        FROM Case
                        WHERE Id IN: caseIdSet
                    ]
                )
            {
                caseRec.NSP_Confidential__c = True;
                caseRec.NSP_Category__c = 'Employment Screening';
                caseListToUpdate.add(caseRec);
            }
            if ( !caseListToUpdate.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( caseListToUpdate , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_EmailMessageTriggerHelper.class.getName() ,
                    'updateConfidentialCheckBoxForEmpScreening' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_EmailMessageTriggerHelper.class.getName() ,
                'updateConfidentialCheckBoxForEmpScreening' ,
                e
            );
        }
    }

    //
    // MethodName : sendEmailToHealthWelfareInternalExternal
    // Story  : STY-03531
    // Description   : This method will send auto-response mail based on internal/external sender email
    // Params : Map<Id, EmailMessage> healthWelfareInternalExternalCaseIdFromAddMap
    //
    public static void sendEmailToHealthWelfareInternalExternal( Map<Id,EmailMessage> healthWelfareInternalExternalCaseIdFromAddMap ) {
        try {
            //get all the cases created from email-to-case if anybody sends email to Health & Welfare email ID
            //send auto response email with internal email template if the from address has an '@insperity.com' domain
            for ( Case caseRec : [
                        SELECT Id , NSP_Case_Created_From_Email_To_Case__c
                        FROM Case
                        WHERE ( Id IN :healthWelfareInternalExternalCaseIdFromAddMap.keySet() )
                    ]
                )
            {
                //DF-03783 - email should be triggered only when case is created
                if ( caseRec.NSP_Case_Created_From_Email_To_Case__c ) {
                    continue;
                }
                if ( healthWelfareInternalExternalCaseIdFromAddMap.get(caseRec.Id).FromAddress.contains(NSP_ServiceConstants.INTERNAL_EMAIL_ADD)
                    && healthWelfareInternalExternalCaseIdFromAddMap.get(caseRec.Id).ToAddress.equals(System.Label.NSP_Health_Welfare_Section_125)
                    )
                {
                    sendEmailToInternalExternal(
                        'NSP_Health_Welfare_Internal_Email_Template' ,
                        healthWelfareInternalExternalCaseIdFromAddMap.get( caseRec.Id ).FromAddress ,
                        caseRec.Id
                    );
                } else {
                    if ( healthWelfareInternalExternalCaseIdFromAddMap.get( caseRec.Id ).ToAddress.equals( System.Label.NSP_Health_Welfare_Section_125 ) ) {
                        sendEmailToInternalExternal(
                            'NSP_Health_Welfare_External_Email_Template' ,
                            healthWelfareInternalExternalCaseIdFromAddMap.get( caseRec.Id ).FromAddress ,
                            caseRec.Id
                        );
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_EmailMessageTriggerHelper.class.getName() ,
                'sendEmailToHealthWelfareInternalExternal' ,
                e
            );
        }
    }

    //
    // MethodName : sendEmailToInternalExternal
    // Story  : STY-03531
    // Description   : Helper method for sendEmailToHealthWelfareInternalExternal
    // Params : String emailTemplateName, String ToAddress, Id caseRecId
    //
    private static void sendEmailToInternalExternal( String emailTemplateName , String ToAddress , Id caseRecId ) {
        try {
            List<Messaging.SingleEmailMessage> lstEmailMessages = new List<Messaging.SingleEmailMessage>();
            List<String> sendToList = new List<String>();
            sendToList.add(ToAddress);
            List<String> emailTempFields = new List<String>{'ID'};
            EmailTemplate emailTemplate = NSP_sObjectSelector.selectByDeveloperName(emailTempFields, emailTemplateName);
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email= Messaging.renderStoredEmailTemplate(emailTemplate.Id, null, caseRecId);
            email.setTemplateId(emailTemplate.Id);
            email.setToAddresses(sendToList);
            OrgWideEmailAddress orgWidAddress = NSP_GenericEmailUtility.getOrgWideAddress( System.label.NSP_no_reply );
            if ( orgWidAddress != null ) {
                email.setOrgWideEmailAddressId( orgWidAddress.Id );
            }
            email.setWhatId(caseRecId);
            email.setSaveAsActivity(false);
            lstEmailMessages.add(email);
            if(!lstEmailMessages.isEmpty()){
                NSP_GenericEmailUtility.sendSingleEmailMessages(lstEmailMessages,false);
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_EmailMessageTriggerHelper.class.getName() ,
                'sendEmailToInternalExternal' ,
                e
            );
        }
    }

    //
    // MethodName : UpdateEmailMessageFields
    // Story  : STY-03853
    // Description   : This method will update EmailMessage ParentId Based on Case External Id
    // Params : List<EmailMessage> newList
    //
    public static void updateEmailMessageFields( List<EmailMessage> newList ) {
        if(!isFirst) {
            isFirst = true;
            //List to store case Ids
            List<String> caseExternalId = new List<String>();
            //List to keep clone Email Messages
            List<EmailMessage> emailMessageClonedList = new List<EmailMessage>();
            //List to delete the cloned Email Message
            Set<Id> emailMessageTobeDeleted = new Set<Id>();
            //To Keep external id with its related case Id
            Map<String, String> caseExtrnlIdsByCaseIds = new Map<String, String>();
            for(EmailMessage emailMessage : newList) {
                //To Filter netsuote cases only
                if(emailMessage.FromName != null && emailMessage.FromName.Contains('netsuite')){
                    //Get the case external Id from FromName
                    string[] caseExtDetails = emailMessage.FromName.split('\\.');
                    string[] caseExtIds = caseExtDetails[2].split('_');
                    //Case number should be there
                    if(!caseExtIds.isEmpty()) {
                        //Store the external case Id
                        caseExternalId.add(caseExtIds[0]);
                        emailMessageTobeDeleted.add(emailMessage.Id);
                        //Clonning the Email Message
                        EmailMessage emailMessageCloned = emailMessage.clone(false, true, false, false);
                        emailMessageClonedList.add(emailMessageCloned);
                    }
                }
            }
            if(!caseExternalId.isEmpty()) {
                //Get cases for External Case
                for(Case cases : [SELECT Id, ParentId, NSP_Case_External_Id__c FROM Case WHERE NSP_Case_External_Id__c =: caseExternalId]) {
                    caseExtrnlIdsByCaseIds.put(cases.NSP_Case_External_Id__c, cases.Id);
                }
                //insert updated cases
                if(!emailMessageClonedList.isEmpty() && !caseExtrnlIdsByCaseIds.isEmpty()) {
                    updateParentIdOnEmailMessage(emailMessageClonedList, caseExtrnlIdsByCaseIds);
                }
                //Finally after process, delete all the Email Message Records which are cloned.
                if(!emailMessageTobeDeleted.isEmpty()) {
                    deleteEmailMessages( emailMessageTobeDeleted );
                }
            }
        }
    }

    //Method to insert updated Email Message record.
    private static void updateParentIdOnEmailMessage( List<EmailMessage> emailMessageClonedList , Map<String,String> caseExtrnlIdsByCaseIds ) {
        List<EmailMessage> emailMessageToBeInserted = New List<EmailMessage>();
        for(EmailMessage eMessage : emailMessageClonedList) {
            string[] caseExtDetails = eMessage.FromName.split('\\.');
            string[] caseExtIds = caseExtDetails[2].split('_');
            //Case number should be there
            if(!caseExtIds.isEmpty()) {
                if(caseExtrnlIdsByCaseIds.containskey(caseExtIds[0])){
                    //Update Parent Id
                    eMessage.ParentId = caseExtrnlIdsByCaseIds.get(caseExtIds[0]);
                    emailMessageToBeInserted.add(eMessage);
                }
            }
        }
        //Insert Updated Email Messages
        if(!emailMessageToBeInserted.isEmpty()) {
            insert emailMessageToBeInserted;
        }
    }

    private static Map<String,String> getMapOfEmailAddressToQueueName(List<EmailMessage> emailMessages) {
        Map<String,String> mapOfEmailAddressToQueueName = new Map<String,String>();
        if((emailMessages != null) && !emailMessages.isEmpty()) {
            Set<String> allToEmailAddress = NSP_EmailMessageTriggerHelper.getAllReceiverAddresses( emailMessages );
            if(allToEmailAddress != null && !allToEmailAddress.isEmpty()) {
                List<Email_Address_to_Case_Owner_Mapping__mdt> eacoList = [SELECT Id, Case_Owner_Name__c, Email_Address__c FROM Email_Address_to_Case_Owner_Mapping__mdt WHERE Email_Address__c IN :allToEmailAddress];
                if(eacoList != null && !eacoList.isEmpty()) {
                    for (Email_Address_to_Case_Owner_Mapping__mdt eaco:eacoList) {
                        if(String.isNotBlank(eaco.Case_Owner_Name__c) && String.isNotBlank(eaco.Email_Address__c)) {
                            mapOfEmailAddressToQueueName.put(eaco.Email_Address__c, eaco.Case_Owner_Name__c);
                        }
                    }
                }
            }
        }
        return mapOfEmailAddressToQueueName;
    }

    //Method returns a set of receiver(To and Cc address) email addresses.
    private static Set<String> getAllReceiverAddresses( List<EmailMessage> records ) {
        Set<String> allReceiverAddress = new Set<String>();
        if ( ( records != null ) && !records.isEmpty() ){
            for ( EmailMessage record : records ) {
                if ( String.isNotBlank( record.ToAddress ) ) {
                    allReceiverAddress.addAll( (record.ToAddress).split(';\\s*') );
                }
                if ( String.isNotBlank( record.CcAddress ) ) {
                    allReceiverAddress.addAll( (record.CcAddress).split(';\\s*') );
                }
            }
        }
        return allReceiverAddress;
    }

    private static Map<String,String> getMapOfQueueNameToQueueId(Map<String,String> mapOfEmailAddressToQueueName) {
        Map<String,String> mapOfQueueNameToQueueId = new Map<String,String>();
        if(mapOfEmailAddressToQueueName != null && mapOfEmailAddressToQueueName.values() != null) {
            List<Group> queueList = [SELECT Id, DeveloperName FROM Group WHERE Type ='Queue' AND DeveloperName IN :mapOfEmailAddressToQueueName.values()];
            if(queueList != null && !queueList.isEmpty()) {
                for(Group queue:queueList) {
                    if(String.isNotBlank(queue.DeveloperName)) {
                        mapOfQueueNameToQueueId.put(queue.DeveloperName, queue.Id);
                    }
                }
            }
        }
        return mapOfQueueNameToQueueId;
    }

    //
    //
    //

    private static Case_Settings__c caseSettings {
        private get {
            if ( caseSettings == null ) {
                caseSettings = Case_Settings__c.getInstance( UserInfo.getUserId() );
            }
            return caseSettings;
        }
        private set;
    }

    private static List<String> bpsCaseTier1Categories {
        get {
            if ( bpsCaseTier1Categories == null ) {
                List<String> local = new List<String>();
                if ( NSP_EmailMessageTriggerHelper.caseSettings != null ) {
                    if ( String.isNotBlank( NSP_EmailMessageTriggerHelper.caseSettings.BPS_Case_Tier_1_Categories_1__c ) ) {
                        local.addAll( NSP_EmailMessageTriggerHelper.caseSettings.BPS_Case_Tier_1_Categories_1__c.split( ',' ) );
                    }
                    if ( String.isNotBlank( NSP_EmailMessageTriggerHelper.caseSettings.BPS_Case_Tier_1_Categories_2__c ) ) {
                        local.addAll( NSP_EmailMessageTriggerHelper.caseSettings.BPS_Case_Tier_1_Categories_2__c.split( ',' ) );
                    }
                }
                bpsCaseTier1Categories = local;
            }
            return bpsCaseTier1Categories;
        }
        private set;
    }

    private static List<String> bpsCaseTier2Categories {
        get {
            if ( bpsCaseTier2Categories == null ) {
                List<String> local = new List<String>();
                if ( ( NSP_EmailMessageTriggerHelper.caseSettings != null )
                    && String.isNotBlank( NSP_EmailMessageTriggerHelper.caseSettings.BPS_Case_Tier_2_Categories__c )
                    )
                {
                    local = NSP_EmailMessageTriggerHelper.caseSettings.BPS_Case_Tier_2_Categories__c.split( ',' );
                }
                bpsCaseTier2Categories = local;
            }
            return bpsCaseTier2Categories;
        }
        private set;
    }

    private static List<String> bpsCaseTier3Categories {
        get {
            if ( bpsCaseTier3Categories == null ) {
                List<String> local = new List<String>();
                if ( ( NSP_EmailMessageTriggerHelper.caseSettings != null )
                    && String.isNotBlank( NSP_EmailMessageTriggerHelper.caseSettings.BPS_Case_Tier_3_Categories__c )
                    )
                {
                    local = NSP_EmailMessageTriggerHelper.caseSettings.BPS_Case_Tier_3_Categories__c.split( ',' );
                }
                bpsCaseTier3Categories = local;
            }
            return bpsCaseTier3Categories;
        }
        private set;
    }

    private static Integer tier1Days {
        get {
            if ( tier1Days == null ) {
                Integer local = 14;
                if ( ( NSP_EmailMessageTriggerHelper.caseSettings != null )
                    && ( NSP_EmailMessageTriggerHelper.caseSettings.BPS_Case_Tier_1_Reopen_Days__c != null )
                    )
                {
                    local = NSP_EmailMessageTriggerHelper.caseSettings.BPS_Case_Tier_1_Reopen_Days__c.intValue();
                }
                tier1Days = local;
            }
            return tier1Days;
        }
        private set;
    }

    private static Integer tier2Days {
        get {
            if ( tier2Days == null ) {
                Integer local = 30;
                if ( ( NSP_EmailMessageTriggerHelper.caseSettings != null )
                    && ( NSP_EmailMessageTriggerHelper.caseSettings.BPS_Case_Tier_2_Reopen_Days__c != null )
                    )
                {
                    local = NSP_EmailMessageTriggerHelper.caseSettings.BPS_Case_Tier_2_Reopen_Days__c.intValue();
                }
                tier2Days = local;
            }
            return tier2Days;
        }
        private set;
    }

    private static Integer tier3Days {
        get {
            if ( tier3Days == null ) {
                Integer local = 90;
                if ( ( NSP_EmailMessageTriggerHelper.caseSettings != null )
                    && ( NSP_EmailMessageTriggerHelper.caseSettings.BPS_Case_Tier_3_Reopen_Days__c != null )
                    )
                {
                    local = NSP_EmailMessageTriggerHelper.caseSettings.BPS_Case_Tier_3_Reopen_Days__c.intValue();
                }
                tier3Days = local;
            }
            return tier3Days;
        }
        private set;
    }

}
//