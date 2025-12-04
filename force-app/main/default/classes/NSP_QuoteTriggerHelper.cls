//
// Represents the Quote trigger helper which handles all the logic.
// Modification History
// -------------------------------------------------------------------------------------
// author           | Date              | Description
// -------------------------------------------------------------------------------------
// Rahul         11-17-2022            Modified this class for user story 128436
//
public class NSP_QuoteTriggerHelper {
    // test w/ NSP_QuoteTriggerTest, NSP_QuoteTriggerHelper_Test (83%)
    // test w/ NSP_QuoteTriggerTest (82%)
    // test w/ NSP_QuoteTriggerHelper_Test (56%)

    private static Boolean STOP_ACCOUNT_QUERY = false;
    private static final String PRICING_MODEL_INCORRECT_ERR_MESSAGE = System.Label.NSP_Incorrect_Pricing_Model;
    private static final String WO_APP_PRICEBOOK_ERR_MESSAGE = System.Label.NSP_WO_Applicable_PriceBooks_Error;
    private static final String BYPASS_SIGNATURE_NOT_ALLOWED = System.Label.NSP_Bypass_Signature_Not_Allowed;
    private static final String SUPPLEMENTAL_TYPE_CHANGE_ERROR = System.Label.NSP_Cannot_Change_Supplemental_Error;
    private static final String AMENDMENT_TYPE_CHANGE_ERROR = System.Label.NSP_Cannot_Change_Amendment_Error;
    private static final String WX_WA_QUOTE_VALIDATION_ERROR = System.Label.NSP_WX_WA_Quote_Validation_Message;
    private static final String STRING_WO_WS = 'WO/WS';
    private static final String LASSO_PARTNERNAME = System.Label.NSP_Lasso_PartnerName;

    public void beforeInsertDirector( List<SBQQ__Quote__c> newList ) {
        List<SBQQ__Quote__c> primaryQuotes= new List<SBQQ__Quote__c>();
        validateQuote( newList );
        stampQuoteOwnerGrouponInsert( newList );
        initializeDefaultFieldValuesOnInsert( newList );
        setQuoteDetailsOnInsert( newList );
        updateBillingAccountOnQuote( newList , null );
        updateBillingAndShippringAddressOnQuote( newList , null );
        updateScholarshipEligibility( newList );
        for ( SBQQ__Quote__c quote:newList ) {
            if ( quote.SBQQ__Primary__c == true ) {
                //Update primary quote's bypass Docusign Field to true for termination opportunities - (DF-03498)
                if ( quote.NSP_TransactionType__c == NSP_CPQConstants.QUOTE_TYPE_TERMINATION ) {
                    quote.NSP_Bypass_DocuSign_Signature__c = true;
                }
                primaryQuotes.add( quote );
            }
        }
        if ( !primaryQuotes.isEmpty() ) {
            unCheckPrimaryQuotesIfExist( newList );
        }
    }

    //
    // Iterates throught the Quote map and identifies the records that needs to worked based on various criterias.
    // @param QuoteNewMap Map of New Quote.
    // @param QuoteOldMap Map of Old Quote.
    // @return void
    //
    public void beforeUpdateDirector( Map<Id,SBQQ__Quote__c> quoteNewMap , Map<Id,SBQQ__Quote__c> quoteOldMap ) {
        List<SBQQ__Quote__c> quoteUpdatedToPrimary= new List<SBQQ__Quote__c>();
        copyApprovalStatusToQuoteStatus( quoteNewMap , quoteOldMap );
        setImplementationDateForTalentConnect( quoteNewMap , quoteOldMap );
        stampQuoteOwnerGroup( quoteNewMap , quoteOldMap );
        initializeDefaultFieldValues( quoteNewMap , quoteOldMap );
        updateBillingAccountOnQuote( quoteNewMap.values() , quoteOldMap );
        updateBillingAndShippringAddressOnQuote( quoteNewMap.values() , quoteOldMap );
        updateScholarshipEligibility( quoteNewMap.values() );
        for ( SBQQ__Quote__c quote : quoteNewMap.values() ) {
            if ( ( quote.SBQQ__Primary__c == true )
                && ( quote.SBQQ__Primary__c != quoteOldMap.get( quote.Id ).SBQQ__Primary__c )
                )
            {
                quoteUpdatedToPrimary.add( quote );
            }
            //Updating Termination quote's start date to Termination Date - DF-03158
            if ( ( quote.SBQQ__Primary__c == true )
                && ( quote.NSP_TransactionType__c == NSP_CPQConstants.QUOTE_TYPE_TERMINATION )
                && ( quote.NSP_TerminationDate__c != null )
                && ( quoteOldMap.get( quote.Id ).NSP_TerminationDate__c != quote.NSP_TerminationDate__c )
                )
            {
                quote.SBQQ__StartDate__c = quote.NSP_TerminationDate__c.addDays( 1 );
            }
        }
        if ( !quoteUpdatedToPrimary.isEmpty() ) {
            unCheckPrimaryQuotesIfExist( quoteUpdatedToPrimary );
        }
    }

    //
    // Iterates throught the Quote map and identifies the records that needs to worked based on various criterias.
    // @param newList of New Quote.
    // @param newMap Map of Old Quote.
    // @return void
    // Modification History
    // -------------------------------------------------------------------------------------
    // author           | Date              | Description
    // -------------------------------------------------------------------------------------
    // Rahul            15-11-2022            created this method for user story 128436
    //
    public void afterInsertDirector( List<SBQQ__Quote__c> newList , Map<Id,SBQQ__Quote__c> newMap ) {
         updatePrimaryQuote( newList , newMap );
    }

    //
    // Iterates throught the list of new leads and passes the required attributes to other methods.
    // @param QuoteNewMap Map of New Quote.
    // @param QuoteOldMap Map of Old Quote.
    // @return void
    //
    public void afterUpdateDirector( Map<Id,SBQQ__Quote__c> quoteNewMap , Map<Id,SBQQ__Quote__c> quoteOldMap ) {
        List<SBQQ__Quote__c> primaryQuotes= new List<SBQQ__Quote__c>();
        populateInsperitySigner( quoteNewMap , quoteOldMap );
        createEnrollmentFee( quoteNewMap , quoteOldMap );
        calcTaxOnOpportunity( quoteNewMap , quoteOldMap );
        for ( SBQQ__Quote__c quote : quoteNewMap.values() ) {
            if ( ( quote.SBQQ__Primary__c == true )
                && ( quote.SBQQ__Primary__c != quoteOldMap.get( quote.Id ).SBQQ__Primary__c )
                )
            {
                primaryQuotes.add( quote );
            }
        }
        if ( !primaryQuotes.isEmpty() ) {
            syncQuoteAndOptyPriceBookIfNotSame( primaryQuotes );
        }
    }

    //
    // Method added for STY-00397 to copy approval status to  status feild on quote and STY-01394 :  set lock recordtype on quote
    // @param QuoteNewMap Map of New Quote.
    // @param QuoteOldMap Map of Old Quote.
    // @return void
    //
    public void copyApprovalStatusToQuoteStatus( Map<Id,SBQQ__Quote__c> quoteNewMap , Map<Id,SBQQ__Quote__c> quoteOldMap ) {
        Map<String,string> quoteLockedRecordTypeMap = new Map<String,string>();
        quoteLockedRecordTypeMap.put('NSP_Recruiting_and_Talent_Connect','NSP_Recruiting_and_Talent_Connect_Locked');
        quoteLockedRecordTypeMap.put('NSP_Retirement_Services','NSP_Retirement_Services_Locked');
        quoteLockedRecordTypeMap.put('NSP_Standard','NSP_Standard_Locked');
        quoteLockedRecordTypeMap.put('NSP_WO_WS','NSP_WO_WS_Locked');
        quoteLockedRecordTypeMap.put('NSP_WX_WA','NSP_WX_WA_Locked');
        for(SBQQ__Quote__c newQuote : quoteNewMap.values()){

            SBQQ__Quote__c oldQuote = quoteOldMap != null ? quoteOldMap.get(newQuote.id):null;
            if(string.isNotBlank(newQuote.ApprovalStatus__c) && newQuote.ApprovalStatus__c != oldQuote.ApprovalStatus__c){

                if(newQuote.ApprovalStatus__c == NSP_CPQConstants.QUOTE_APPROVAL_STATUS_PENDING ){
                    newQuote.SBQQ__Status__c = NSP_CPQConstants.QUOTE_STATUS_SFA;
                    // update the quote to locked recordtype and store the previous recordtype id
                    string recordTypeDevName = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosById().get(newQuote.recordTypeId).getDeveloperName();
                    if(String.isNotBlank(recordTypeDevName) && quoteLockedRecordTypeMap.containsKey(recordTypeDevName)){
                        newQuote.recordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get(quoteLockedRecordTypeMap.get(recordTypeDevName)).getRecordTypeId();
                        newQuote.NSP_Previous_RecordType_Id__c = oldQuote.recordTypeId;
                    }
                }
                if(newQuote.ApprovalStatus__c == NSP_CPQConstants.QUOTE_APPROVAL_STATUS_APPROVED  ){
                    newQuote.SBQQ__Status__c = NSP_CPQConstants.QUOTE_STATUS_APPROVED ;
                     // update the quote to locked recordtype
                     string recordTypeDevName = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosById().get(newQuote.recordTypeId).getDeveloperName();
                     if(String.isNotBlank(recordTypeDevName) && quoteLockedRecordTypeMap.containsKey(recordTypeDevName)){
                         newQuote.recordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get(quoteLockedRecordTypeMap.get(recordTypeDevName)).getRecordTypeId();
                         newQuote.NSP_Previous_RecordType_Id__c = oldQuote.recordTypeId;
                     }
                }
                if(newQuote.ApprovalStatus__c == NSP_CPQConstants.QUOTE_APPROVAL_STATUS_REJECTED  ){
                    newQuote.SBQQ__Status__c = NSP_CPQConstants.QUOTE_STATUS_REJECTED;
                }
                if(newQuote.ApprovalStatus__c == NSP_CPQConstants.QUOTE_APPROVAL_STATUS_RECALLED ){
                    newQuote.SBQQ__Status__c = NSP_CPQConstants.QUOTE_STATUS_RECALLED ;
                    // change recordtype to previus value
                    if(String.isNotBlank(newQuote.NSP_Previous_RecordType_Id__c)){
                        newQuote.recordTypeId = newQuote.NSP_Previous_RecordType_Id__c;
                    }
                }
            }
        }
    }

    //
    // Method Name : setImplementationDateForTalentConnect
    // Description : Method to set Implementation Date on quote after 30 days of Subscription Start Date. Ref Story# STY-00402.
    // Author : Rakesh Das       Date : 28/06/2021
    // @param QuoteNewMap Map of New Quote.
    // @param QuoteOldMap Map of Old Quote.
    // @return void
    //
    public void setImplementationDateForTalentConnect( Map<Id,SBQQ__Quote__c> quoteNewMap , Map<Id,SBQQ__Quote__c> quoteOldMap ) {
        for ( SBQQ__Quote__c newQuote : quoteNewMap.values() ) {
            if ( !String.isBlank( newQuote.NSP_TC_Implementation_Plan_Selected__c )
                && ( newQuote.NSP_Talent_Connect_Subscription_Date__c != null )
                && ( newQuote.NSP_Implementation_Start_Date__c == null )
                )
            {
                newQuote.NSP_Implementation_Start_Date__c = newQuote.NSP_Talent_Connect_Subscription_Date__c.addDays( -30 );
            }
        }
    }

    //
    // Method Name : setQuoteDetailsOnInsert
    // Description : Method to set default Pricebook, Pricing Model, Product Type based on Opportunity Primary Product and Client for Life
    // Author : Rakesh Das       Date : 08/10/2021
    // @param newQuotesList List of New Quote.
    // @return void
    //
    public void setQuoteDetailsOnInsert( List<SBQQ__Quote__c> newQuotesList ) {
        Map<String, NSP_Opportunity_To_Quote_Data_Map__mdt> pricebookConfigs = NSP_Opportunity_To_Quote_Data_Map__mdt.getAll();
        Map<String, NSP_Opportunity_To_Quote_Data_Map__mdt> configsWithKey = new Map<String, NSP_Opportunity_To_Quote_Data_Map__mdt>();
        Map<String, NSP_Partner_Configurations__mdt> partConfigWithpbNameMap = new Map<String,NSP_Partner_Configurations__mdt>();
        Map<String, NSP_Partner_Configurations__mdt> partnerConfigs = NSP_Partner_Configurations__mdt.getAll();
        Map<Id, Opportunity> opportunityMap = new Map<Id,Opportunity>();
        Set<Id> opportunityIds = new Set<Id>();
        List<String> partnerNames = new List<String>();
        Set<String> partnerCodeForKey = new Set<String>();
        //STY-01492 copy Oppty owner email on Quote
        for(SBQQ__Quote__c quoteRecord : newQuotesList){
            if(String.isNotBlank(quoteRecord.SBQQ__Opportunity2__c)){
                opportunityIds.add(quoteRecord.SBQQ__Opportunity2__c);
            }
        }
        if(opportunityIds.size() > 0){
            opportunityMap = new Map<Id, Opportunity>([SELECT Id, Name, Type, Owner.Email, NSP_Partner__c FROM Opportunity WHERE Id IN :opportunityIds]);
        }
        Map<String, Id> pbNamesWithId = new Map<String,Id> ();
        for (NSP_Opportunity_To_Quote_Data_Map__mdt pc : pricebookConfigs.values() ) {
             String partnerCode = pc.NSP_Partner__c!=null ? pc.NSP_Partner__c : NSP_CPQConstants.NONE_VALUE;
             String uniqKey = pc.NSP_Opportunity_Primary_Product__c+'_'+pc.NSP_Client_for_Life__c+'_'+partnerCode;
             configsWithKey.put(uniqKey,pc);
        }

        for (PriceBook2 pb : [SELECT Id, Name FROM PriceBook2 WHERE IsActive=TRUE]) {
            pbNamesWithId.put(pb.Name, pb.Id);
        }

        for(NSP_Partner_Configurations__mdt partc : partnerConfigs.values()) {
            partnerNames.add(partc.NSP_Partner_Unique_Code__c);
            if(partc.NSP_Use_For_Partner_Key_Internal__c) {
                partnerCodeForKey.add(partc.NSP_Partner_Unique_Code__c);
            }
            if(partc.NSP_Partner_Unique_Code__c == 'Sage') {
                partConfigWithpbNameMap.put(partc.Label,partc);
            }
            else {
            partConfigWithpbNameMap.put(partc.NSP_Partner_Unique_Code__c,partc);
            }
        }

        for(SBQQ__Quote__c newQuote : newQuotesList) {
            //STY-01492 copy Oppty owner email on Quote
            if(String.isNotBlank(newQuote.SBQQ__Opportunity2__c)){
                Opportunity opportunityRecord = opportunityMap.get(newQuote.SBQQ__Opportunity2__c);
                if(opportunityRecord != null){
                    String opptyOwnerEmail = opportunityRecord.Owner.Email;
                    newQuote.NSP_Opportunity_Owner_Email_Id__c = opptyOwnerEmail;
                }
            }
            //Setting Start Date to Today as default
            if(newQuote.SBQQ__StartDate__c == null ) {
            newQuote.SBQQ__StartDate__c = DATE.TODAY();
            }
            String quotePartnerCode = (newQuote.NSP_Opportunity_Partner_Name__c!=null &&  partnerCodeForKey.contains(newQuote.NSP_Opportunity_Partner_Name__c)) ? newQuote.NSP_Opportunity_Partner_Name__c : NSP_CPQConstants.NONE_VALUE;
            String quoteKey = newQuote.NSP_Opportunity_Primary_Product__c+'_'+newQuote.NSP_Client_For_Life__c+'_'+quotePartnerCode;
            if(configsWithKey.containsKey(quoteKey)) {
                NSP_Opportunity_To_Quote_Data_Map__mdt qconfig = configsWithKey.get(quoteKey);
                if(pbNamesWithId.containskey(qconfig.NSP_PriceBook__c)) {
                    newQuote.SBQQ__PricebookId__c = pbNamesWithId.get(qconfig.NSP_PriceBook__c);
                    newQuote.SBQQ__PriceBook__c = pbNamesWithId.get(qconfig.NSP_PriceBook__c);
                    newQuote.NSP_Price_Book__c = pbNamesWithId.get(qconfig.NSP_PriceBook__c);
                }
                if(qconfig.NSP_Pricing_Model__c!=null && String.isNotEmpty(qconfig.NSP_Pricing_Model__c) ) {
                    newQuote.NSP_Pricing_Model__c= qconfig.NSP_Pricing_Model__c;
                }
                if(qconfig.NSP_Product_Type__c!=null && String.isNotEmpty(qconfig.NSP_Product_Type__c) && !newQuote.SBQQ__Type__c.equals(NSP_CPQConstants.QUOTE_TYPE_RENEWAL)) {
                    newQuote.NSP_Product_Type__c = qconfig.NSP_Product_Type__c;
                }
                newQuote.recordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get(qconfig.NSP_Default_Recordtype__c).getRecordTypeId();
            }
            if(String.isNotEmpty(newQuote.NSP_Opportunity_Partner_Name__c) && partnerNames.contains(newQuote.NSP_Opportunity_Partner_Name__c)) {
                NSP_Partner_Configurations__mdt pcc = partConfigWithpbNameMap.get(newQuote.NSP_Opportunity_Partner_Name__c);
                if((newQuote.SBQQ__Type__c.equals(NSP_CPQConstants.QUOTE_TYPE_NEW) ||  newQuote.SBQQ__Type__c.equals(NSP_CPQConstants.QUOTE_TYPE_AMENDMENT) && newQuote.NSP_TransactionType__c != NSP_CPQConstants.QUOTE_TYPE_TERMINATION) && pcc.NSP_New_Sale_Discount__c!=null) {
                    newQuote.SBQQ__PartnerDiscount__c = pcc.NSP_New_Sale_Discount__c;
                }
                if(newQuote.SBQQ__Type__c.equals(NSP_CPQConstants.QUOTE_TYPE_RENEWAL) && pcc.NSP_Renewal_Discount__c!=null ) {
                    newQuote.SBQQ__PartnerDiscount__c = pcc.NSP_Renewal_Discount__c;
                }
            }
            if(newQuote.SBQQ__Type__c.equals(NSP_CPQConstants.QUOTE_TYPE_NEW) && (newQuote.NSP_Opportunity_Primary_Product__c == 'WX' || newQuote.NSP_Opportunity_Primary_Product__c == 'WA') && newQuote.NSP_Opportunity_Primary_Bundle__c != STRING_WO_WS && newQuote.NSP_Opportunity_Partner_Name__c != LASSO_PARTNERNAME) {
                newQuote.NSP_Budgetary_Quote__c = true;
                if(newQuote.SBQQ__Partner__c == null &&  opportunityMap.get(newQuote.SBQQ__Opportunity2__c).NSP_Partner__c!=null) {
                    newQuote.SBQQ__Partner__c = opportunityMap.get(newQuote.SBQQ__Opportunity2__c).NSP_Partner__c;
                }
            }
            if ( newQuote.SBQQ__Type__c.equals( NSP_CPQConstants.QUOTE_TYPE_NEW )
                && ( newQuote.NSP_Opportunity_Primary_Product__c == 'Contractor Management' )
                )
            {
                newQuote.NSP_Budgetary_Quote__c = true;
            }
        }
    }

    //
    // Method Name : initializeDefaultFieldValues
    // Description : Method to set default Quote values based on conditions.
    // Author : Rakesh Das       Date : 10/08/2021
    // @param QuoteNewMap Map of New Quote.
    // @param QuoteOldMap Map of Old Quote.
    // @return void
    //
    public void initializeDefaultFieldValues( Map<Id,SBQQ__Quote__c> quoteNewMap , Map<Id,SBQQ__Quote__c> quoteOldMap ) {
        NSP_Partner_Configurations__mdt partnerConfigRec = NSP_Partner_Configurations__mdt.getInstance( 'Altula' );
        Map<String,String> woPBNames = new Map<String,String>{
            'WA Pricebook' => 'WA' ,
            'WX Pricebook' => 'WX'
        };
        List<String> notapplicableCoreProducts = new List<String>{ 'HR Consulting Services' };
        List<String> applicableCoreProducts = new List<String>{
            'IWXPerCheckFee' ,
            'IWAPerCheckFee'
        };
        Map<Id,PriceBook2> woapplicablePBMap = new Map<Id,PriceBook2>(
            [
                SELECT Id , Name
                FROM PriceBook2
                WHERE ( Name IN :woPBNames.keySet() )
            ]
        );
        Map<String,NSP_Docusign_Template_Automation_Setting__mdt> templateAutoSettings = NSP_Docusign_Template_Automation_Setting__mdt.getAll();
        Map<String,NSP_Docusign_Template_Automation_Setting__mdt> sortedTemplateSettingsByProduct = new Map<String,NSP_Docusign_Template_Automation_Setting__mdt>();
        Map<String,NSP_Docusign_Template_Automation_Setting__mdt> amendTemplateSettingsByProduct = new Map<String,NSP_Docusign_Template_Automation_Setting__mdt>();
        Map<String,NSP_Docusign_Template_Automation_Setting__mdt> renewTemplateSettingsByProduct = new Map<String,NSP_Docusign_Template_Automation_Setting__mdt>();
        Map<String,Set<String>> quoteProductBundles = new Map<String,Set<String>>();
        Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>();
        Set<Id> opportunityIds = new Set<Id>();
        Set<String> productsToBypassSignature = new Set<String>( System.Label.NSP_Primary_Products_To_Bypass_Signature.split( ',' ) );
        List<Opportunity> opportunityupdateList = new List<Opportunity>();
        Set<Id> opportunityIdSet = new Set<Id>();
        Map<String,NSP_Opportunity_To_Quote_Data_Map__mdt> pricebookConfigs = NSP_Opportunity_To_Quote_Data_Map__mdt.getAll();
        Map<String,NSP_Opportunity_To_Quote_Data_Map__mdt> configsWithKey = new Map<String,NSP_Opportunity_To_Quote_Data_Map__mdt>();

        for ( NSP_Opportunity_To_Quote_Data_Map__mdt pc : pricebookConfigs.values() ) {
            String partnerCode = ( ( pc.NSP_Partner__c != null ) ? pc.NSP_Partner__c : NSP_CPQConstants.NONE_VALUE );
            String uniqKey = pc.NSP_Opportunity_Primary_Product__c + '_' + pc.NSP_Client_for_Life__c + '_' + partnerCode;
            configsWithKey.put( uniqKey , pc );
        }
        //STY-01492 copy Oppty owner email on Quote
        for ( Id newQuoteId : quoteNewMap.keySet() ) {
            SBQQ__Quote__c newQuoteRecord = quoteNewMap.get( newQuoteId );
            SBQQ__Quote__c oldQuoteRecord = quoteOldMap.get( newQuoteId );
            if ( newQuoteRecord.SBQQ__Opportunity2__c != oldQuoteRecord.SBQQ__Opportunity2__c ) {
                opportunityIds.add( newQuoteRecord.SBQQ__Opportunity2__c );
            }
            // logic added for story STY-01948
            if ( ( newQuoteRecord.SBQQ__Primary__c != oldQuoteRecord.SBQQ__Primary__c )
                && ( newQuoteRecord.NSP_Opportunity_Primary_Product__c == 'WO' )
                && String.isNotBlank( newQuoteRecord.SBQQ__PricebookId__c )
                && woapplicablePBMap.containsKey( newQuoteRecord.SBQQ__PricebookId__c )
                )
            {
                PriceBook2 objPricebook = woapplicablePBMap.get( newQuoteRecord.SBQQ__PricebookId__c );
                Opportunity objOpportunity = new Opportunity( Id=newQuoteRecord.SBQQ__Opportunity2__c );
                String quotePartnerCode = NSP_CPQConstants.NONE_VALUE;
                String quoteKey = '';
                if ( objPricebook.Name == 'WA Pricebook' ) {
                    newQuoteRecord.NSP_Opportunity_Primary_Product__c = 'WA';
                    newQuoteRecord.NSP_Client_For_Life__c = 'WA';
                    objOpportunity.NSP_PrimaryProduct__c = 'WA';
                    objOpportunity.NSP_Client_For_Life__c = 'WA';
                    objOpportunity.PriceBook2Id = objPricebook.Id;
                    quoteKey = newQuoteRecord.NSP_Opportunity_Primary_Product__c + '_' + newQuoteRecord.NSP_Client_For_Life__c + '_' + quotePartnerCode;
                    opportunityIdSet.add( objOpportunity.Id );
                    opportunityupdateList.add( objOpportunity );
                } else if ( objPricebook.Name == 'WX Pricebook' ) {
                    newQuoteRecord.NSP_Opportunity_Primary_Product__c = 'WX';
                    newQuoteRecord.NSP_Client_For_Life__c = 'WX';
                    objOpportunity.NSP_PrimaryProduct__c = 'WX';
                    objOpportunity.NSP_Client_For_Life__c = 'WX';
                    objOpportunity.PriceBook2Id = objPricebook.Id;
                    quoteKey = newQuoteRecord.NSP_Opportunity_Primary_Product__c + '_' + newQuoteRecord.NSP_Client_For_Life__c + '_' + quotePartnerCode;
                    opportunityIdSet.add( objOpportunity.Id );
                    opportunityupdateList.add( objOpportunity );
                }
                if ( String.isNotBlank( quoteKey )
                    && configsWithKey.containsKey( quoteKey )
                    )
                {
                    NSP_Opportunity_To_Quote_Data_Map__mdt qconfig = configsWithKey.get( quoteKey );
                    newQuoteRecord.recordTypeId = NSP_GenericRecordType.getRecordTypeId( 'SBQQ__Quote__c' , qconfig.NSP_Default_Recordtype__c );
                }
            }
            if ( newQuoteRecord.NSP_Billing_Account__c != oldQuoteRecord.NSP_Billing_Account__c ) {
                Opportunity oppObj = new Opportunity();
                oppObj.NSP_Billing_Account__c = newQuoteRecord.NSP_Billing_Account__c;
                oppObj.Id = newQuoteRecord.SBQQ__Opportunity2__c;
                opportunityupdateList.add( oppObj );
            }
        }
        try {
            // logic added for story STY-01948
            if ( !opportunityIdSet.isEmpty() ) {
                List<Database.DeleteResult> results = Database.delete(
                    [ SELECT Id FROM OpportunityLineItem WHERE ( OpportunityId IN :opportunityIdSet ) ] ,
                    false
                );
                NSP_ErrorLogHandler.logResults(
                    NSP_QuoteTriggerHelper.class.getName() ,
                    'initializeDefaultFieldValues:delete:OpportunityLineItem' ,
                    results
                );
            }
            // logic added for story STY-01948
            if ( !opportunityupdateList.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( opportunityupdateList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_QuoteTriggerHelper.class.getName() ,
                    'initializeDefaultFieldValues:update:Opportunity' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_QuoteTriggerHelper.handleException( e , 'initializeDefaultFieldValues' );
        }
        if ( !opportunityIds.isEmpty() ) {
            opportunityMap = new Map<Id,Opportunity>(
                [
                    SELECT Id , Name , Owner.Email
                    FROM Opportunity
                    WHERE ( Id IN :opportunityIds )
                ]
            );
        }
        for ( NSP_Docusign_Template_Automation_Setting__mdt dta : templateAutoSettings.values() ) {
            if ( ( dta.NSP_Active__c == true )
                && ( dta.NSP_Linked_Product__c != null )
                )
            {
                String bundleProductCodes = dta.NSP_Linked_Product__c;
                List<String> bundleCodesList = bundleProductCodes.split( ';' );
                bundleCodesList.sort();
                String sortedBundle = String.join(bundleCodesList,';');
                if ( ( dta.NSP_Applicable_Transaction__c == 'All' )
                    || ( dta.NSP_Applicable_Transaction__c == 'New Product' )
                    )
                {
                    sortedTemplateSettingsByProduct.put( sortedBundle , dta );
                }
                if ( ( dta.NSP_Applicable_Transaction__c == 'All' )
                    || ( dta.NSP_Applicable_Transaction__c == 'Amendment' )
                    )
                {
                    amendTemplateSettingsByProduct.put( sortedBundle , dta );
                }
                if ( ( dta.NSP_Applicable_Transaction__c == 'All' )
                    || ( dta.NSP_Applicable_Transaction__c == 'Renewal' )
                    )
                {
                    renewTemplateSettingsByProduct.put( sortedBundle , dta );
                }
            }
        }
        for ( SBQQ__QuoteLine__c ql : [
                    SELECT Id , SBQQ__ProductCode__c , NSP_Lock_On_QLI__c , SBQQ__Quote__c , SBQQ__Quote__r.Has_Retirement_Integration_Product__c
                    FROM SBQQ__QuoteLine__c
                    WHERE (
                        (	(Bundle_Template_Determination_Flag__c = true)
                            OR ( NSP_ActionType__c != null )
                            OR ( SBQQ__Quote__r.Has_Retirement_Integration_Product__c = true )
                        )
                        AND (
                            ( NSP_Lock_On_QLI__c = true )
                            OR ( NSP_Parent_Product_Code__c = 'HR Consulting Services' )
                            OR ( SBQQ__ProductCode__c IN :applicableCoreProducts )
                        )
                        AND SBQQ__Quote__c IN : quoteNewMap.keySet()
                        AND SBQQ__ProductCode__c NOT IN :notapplicableCoreProducts
                    )
                ]
            )
        {
            if ( ql.SBQQ__ProductCode__c!=null ) {
                if ( quoteProductBundles.containskey( ql.SBQQ__Quote__c ) ) {
                    Set<String> prodlist = quoteProductBundles.get( ql.SBQQ__Quote__c );
                    prodlist.add( ql.SBQQ__ProductCode__c );
                    quoteProductBundles.put( ql.SBQQ__Quote__c , prodlist );
                } else {
                    quoteProductBundles.put( ql.SBQQ__Quote__c , new Set<String>{ ql.SBQQ__ProductCode__c } );
                }
            }
        }
        for ( SBQQ__Quote__c newQuote : quoteNewMap.values() ) {
            //copy Opportunity Owner email on Quote record STY-01492
            if ( String.isNotBlank( newQuote.SBQQ__Opportunity2__c ) ) {
                Opportunity opportunityRecord = opportunityMap.get( newQuote.SBQQ__Opportunity2__c );
                if ( opportunityRecord != null ) {
                    String opptyOwnerEmail = opportunityRecord.Owner.Email;
                    newQuote.NSP_Opportunity_Owner_Email_Id__c = opptyOwnerEmail;
                }
            }
            if ( String.isNotEmpty( newQuote.NSP_Product_Type__c )
                && newQuote.NSP_Product_Type__c.contains( NSP_CPQConstants.QUOTE_PRODUCT_TYPE_TC )
                && ( newQuote.SBQQ__LineItemCount__c == 0 )
                )
            {
                newQuote.NSP_BPS_Billing_Frequency__c = NSP_CPQConstants.MONTHLY;
            }
            if ( String.isNotEmpty( newQuote.NSP_Opportunity_Partner_Name__c )
                && newQuote.NSP_Opportunity_Partner_Name__c.equals( partnerConfigRec.NSP_Partner_Unique_Code__c )
                )
            {
                if ( newQuote.SBQQ__Type__c.equals( NSP_CPQConstants.QUOTE_TYPE_NEW )
                    || newQuote.SBQQ__Type__c.equals( NSP_CPQConstants.QUOTE_TYPE_AMENDMENT )
                    )
                {
                    newQuote.SBQQ__PartnerDiscount__c = partnerConfigRec.NSP_New_Sale_Discount__c;
                }
                if ( newQuote.SBQQ__Type__c.equals( NSP_CPQConstants.QUOTE_TYPE_RENEWAL ) ) {
                    newQuote.SBQQ__PartnerDiscount__c = partnerConfigRec.NSP_Renewal_Discount__c;
                }
            }
            if ( productsToBypassSignature.contains( newQuote.NSP_Opportunity_Primary_Product__c ) ) {
                newQuote.NSP_Bypass_DocuSign_Signature__c = true;
            }
            if ( ( newQuote.NSP_Client_For_Life__c == NSP_CPQConstants.CLIENT_WOWS )
                && ( newQuote.NSP_Opportunity_Primary_Product__c == NSP_CPQConstants.OPPTY_WO )
                && ( newQuote.NSP_Price_Book__c != quoteOldMap.get( newQuote.Id ).NSP_Price_Book__c )
                )
            {
                if ( !woapplicablePBMap.containsKey( newQuote.NSP_Price_Book__c ) ) {
                    newQuote.NSP_Price_Book__c.addError( WO_APP_PRICEBOOK_ERR_MESSAGE );
                } else {
                    newQuote.SBQQ__PricebookId__c = newQuote.NSP_Price_Book__c;
                    newQuote.SBQQ__PriceBook__c = newQuote.NSP_Price_Book__c;
                    newQuote.NSP_Pricing_Model__c = woPBNames.get( woapplicablePBMap.get( newQuote.NSP_Price_Book__c ).Name );
                }
            }
            newQuote.NSP_Final_Template__c = null;
            if ( quoteProductBundles.containsKey( newQuote.Id ) ) {
                Set<String> coreBundleSet = quoteProductBundles.get( newQuote.Id );
                List<String> coreBundlesList = new List<String>( coreBundleSet );
                coreBundlesList.sort();
                String settingkey = String.join( coreBundlesList , ';' );
                if ( sortedTemplateSettingsByProduct.containsKey( settingkey )
                    && newQuote.SBQQ__Type__c.equals( NSP_CPQConstants.QUOTE_TYPE_NEW )
                    )
                {
                    newQuote.NSP_Final_Template__c = sortedTemplateSettingsByProduct.get( settingkey ).NSP_Selected_Template__c;
                }
                if ( amendTemplateSettingsByProduct.containsKey( settingkey )
                    && newQuote.SBQQ__Type__c.equals( NSP_CPQConstants.QUOTE_TYPE_AMENDMENT )
                    && ( newQuote.NSP_TransactionType__c != NSP_CPQConstants.QUOTE_TYPE_TERMINATION )
                    )
                {
                    newQuote.NSP_Final_Template__c = amendTemplateSettingsByProduct.get( settingkey ).NSP_Selected_Template__c;
                }
                if ( renewTemplateSettingsByProduct.containsKey( settingkey )
                    && newQuote.SBQQ__Type__c.equals( NSP_CPQConstants.QUOTE_TYPE_RENEWAL )
                    )
                {
                    newQuote.NSP_Final_Template__c = renewTemplateSettingsByProduct.get( settingkey ).NSP_Selected_Template__c;
                }
            }
            if ( newQuote.SBQQ__Type__c==NSP_CPQConstants.SUPPLEMENTAL ) {
                //newQuote.NSP_Product_Type__c = NSP_CPQConstants.SUPPLEMENTAL;
                //Template Selection for the interim phase Supplemental quote
                if ( newQuote.NSP_SupplementBPS__c ) {
                    newQuote.NSP_Final_Template__c = NSP_CPQConstants.SUPPLEMENTBPS;
                }
                if ( newQuote.NSP_Supplement__c ) {
                    newQuote.NSP_Final_Template__c = NSP_CPQConstants.SUPPLEMENT;
                }
            }
            //Template Selection for the Show Discount scenario
            if ( newQuote.NSP_Show_Discounts__c == true ) {
                if ( ( newQuote.SBQQ__Type__c == NSP_CPQConstants.QUOTE_TYPE_NEW )
                    && ( newQuote.NSP_Final_Template__c != 'TimeStar' )
                    )
                {
                    newQuote.NSP_Final_Template__c = NSP_CPQConstants.QUOTE_NEW_SHOW_DISCOUNT_BPS;
                }
                if ( ( newQuote.SBQQ__Type__c == NSP_CPQConstants.QUOTE_TYPE_AMENDMENT )
                    && ( newQuote.NSP_TransactionType__c != NSP_CPQConstants.QUOTE_TYPE_TERMINATION )
                    )
                {
                    newQuote.NSP_Final_Template__c = NSP_CPQConstants.QUOTE_AMENDMENT_SHOW_DISCOUNT_BPS;
                }
                if ( newQuote.SBQQ__Type__c == NSP_CPQConstants.QUOTE_TYPE_RENEWAL ) {
                    newQuote.NSP_Final_Template__c = NSP_CPQConstants.QUOTE_RENEWAL_SHOW_DISCOUNT_BPS;
                }
                if ( ( newQuote.SBQQ__Type__c == NSP_CPQConstants.QUOTE_TYPE_NEW )
                    && ( newQuote.NSP_Final_Template__c == 'TimeStar' )
                    )
                {
                    newQuote.NSP_Final_Template__c = NSP_CPQConstants.QUOTE_NEW_SHOW_DISCOUNT_Timestar;
                }
            }
            if ( newQuote.NSP_WX_Scholarship__c == true ) {
                newQuote.NSP_Final_Template__c = NSP_CPQConstants.QUOTE_SCHOLARSHIP;
            }
            if ( ( newQuote.NSP_Select_Payroll_Frequency__c != null )
                && String.isNotEmpty( newQuote.NSP_Select_Payroll_Frequency__c )
                )
            {
                String rawValue = newQuote.NSP_Select_Payroll_Frequency__c;
                String modifiedValue = rawValue.replace( ';' , ', ' );
                newQuote.NSP_Payroll_Frequency_Text__c = modifiedValue;
            } else {
                newQuote.NSP_Payroll_Frequency_Text__c = null;
            }
            if ( String.isNotEmpty( newQuote.NSP_Opportunity_Partner_Name__c )
                && newQuote.NSP_Opportunity_Partner_Name__c.equals( partnerConfigRec.NSP_Partner_Unique_Code__c )
                )
            {
                newQuote.NSP_Final_Template__c = NSP_CPQConstants.ALTULA;
            }
            if ( ( newQuote.SBQQ__Type__c == NSP_CPQConstants.QUOTE_TYPE_RENEWAL )
                && ( newQuote.NSP_Opportunity_Non_DocuPay__c == false )
                && ( newQuote.NSP_Budgetary_Quote__c == true )
                && ( newQuote.NSP_Opportunity_Primary_Product__c == 'Time & Attendance' )
                )
            {
                newQuote.NSP_Final_Template__c = 'Estimate';
                newQuote.NSP_Estimate__c = true;
            }
            if ( ( newQuote.SBQQ__Type__c != quoteOldMap.get(newQuote.Id).SBQQ__Type__c )
                && ( ( quoteOldMap.get(newQuote.Id).SBQQ__Type__c == NSP_CPQConstants.QUOTE_TYPE_AMENDMENT )
                    || ( quoteOldMap.get(newQuote.Id).SBQQ__Type__c == NSP_CPQConstants.SUPPLEMENTAL )
                    )
                && ( newQuote.SBQQ__LineItemCount__c != 0 )
                && ( newQuote.NSP_TransactionType__c != NSP_CPQConstants.QUOTE_TYPE_TERMINATION )
                )
            {
                newQuote.SBQQ__Type__c.addError( AMENDMENT_TYPE_CHANGE_ERROR );
            }
            //Added for Partner CS Story
            if ( newQuote.SBQQ__Partner__c == null ) {
                newQuote.NSP_Is_Partner_CS_Applicable__c = false;
            }
            //Added for Partner CS Story
        }
    }

    //
    // Method Name : initializeDefaultFieldValuesOnInsert
    // Description : Method to set default Quote values based on conditions.
    // Author : Rakesh Das       Date : 13/10/2021
    // @param newQuotesList List of New Quote.
    // @return void
    //
public void initializeDefaultFieldValuesOnInsert(List<SBQQ__Quote__c> newQuotesList) {
    Set<Id> opportunityIds = new set<Id> ();
    List<SBQQ__Quote__c> renewAmendQuotes = new List<SBQQ__Quote__c>();
    NSP_Partner_Configurations__mdt partnerConfigRec = NSP_Partner_Configurations__mdt.getInstance('Altula');

    for(SBQQ__Quote__c newQuote : newQuotesList) {
        if(String.isNotEmpty(newQuote.NSP_Product_Type__c)){
        if((newQuote.NSP_Product_Type__c.contains(NSP_CPQConstants.QUOTE_PRODUCT_TYPE_TC) && newQuote.SBQQ__LineItemCount__c == 0 ) || newQuote.NSP_Product_Type__c.contains(NSP_CPQConstants.QUOTE_PRODUCT_TYPE_LEARNDEV)){
        newQuote.NSP_BPS_Billing_Frequency__c = NSP_CPQConstants.MONTHLY;
        }
        }
        if(String.isNotEmpty(newQuote.NSP_Opportunity_Partner_Name__c) && newQuote.NSP_Opportunity_Partner_Name__c.equals(partnerConfigRec.NSP_Partner_Unique_Code__c)) {
            if(newQuote.SBQQ__Type__c.equals(NSP_CPQConstants.QUOTE_TYPE_NEW) ||  newQuote.SBQQ__Type__c.equals(NSP_CPQConstants.QUOTE_TYPE_AMENDMENT)) {
                newQuote.SBQQ__PartnerDiscount__c = partnerConfigRec.NSP_New_Sale_Discount__c;
            }
            if(newQuote.SBQQ__Type__c.equals(NSP_CPQConstants.QUOTE_TYPE_RENEWAL) ) {
                newQuote.SBQQ__PartnerDiscount__c = partnerConfigRec.NSP_Renewal_Discount__c;
            }
        }

        if(newQuote.SBQQ__Type__c==NSP_CPQConstants.SUPPLEMENTAL) {
            newQuote.NSP_Product_Type__c = NSP_CPQConstants.SUPPLEMENTAL;
        }
        if(newQuote.SBQQ__Opportunity2__c!=null) {
            opportunityIds.add(newQuote.SBQQ__Opportunity2__c);
            renewAmendQuotes.add(newQuote);
        }
    }

    if(opportunityIds.size()>0) {
        Map<Id,Opportunity> renewAmendOpptys = new Map<Id,Opportunity>();
        for ( Opportunity opp : [Select Id, SBQQ__AmendedContract__c, SBQQ__RenewedContract__c,
                                            SBQQ__AmendedContract__r.NSP_Number_of_Employees__c, SBQQ__AmendedContract__r.NSP_Pricing_Model__c, SBQQ__AmendedContract__r.NSP_Product_Type__c, SBQQ__AmendedContract__r.SBQQ__Quote__r.NSP_Billing_Account__c,  SBQQ__AmendedContract__r.SBQQ__Quote__r.NSP_Billing_Address__c , SBQQ__AmendedContract__r.SBQQ__Quote__r.NSP_Shipping_Address__c, SBQQ__AmendedContract__r.SBQQ__Quote__r.NSP_Customer_Billing_Address__c, SBQQ__AmendedContract__r.SBQQ__Quote__r.NSP_Customer_Shipping_Address__c,SBQQ__AmendedContract__r.SBQQ__Quote__r.NSP_Opportunity_Type__c,
                                            SBQQ__AmendedContract__r.SBQQ__Quote__r.NSP_Client_For_Life__c, SBQQ__AmendedContract__r.SBQQ__Quote__r.SBQQ__Partner__c, SBQQ__AmendedContract__r.SBQQ__Quote__r.NSP_Opportunity_Primary_Product__c, SBQQ__AmendedContract__r.SBQQ__Quote__r.SBQQ__PrimaryContact__c,SBQQ__AmendedContract__r.SBQQ__Quote__r.NSP_Invoice_To_Email__c, SBQQ__AmendedContract__r.SBQQ__Quote__r.NSP_Product_Type__c,
                                            SBQQ__RenewedContract__r.NSP_Number_of_Employees__c, SBQQ__RenewedContract__r.NSP_Pricing_Model__c, SBQQ__RenewedContract__r.NSP_Product_Type__c, SBQQ__RenewedContract__r.SBQQ__Quote__r.NSP_Billing_Account__c,  SBQQ__RenewedContract__r.SBQQ__Quote__r.NSP_Billing_Address__c, SBQQ__RenewedContract__r.SBQQ__Quote__r.NSP_Shipping_Address__c, SBQQ__RenewedContract__r.SBQQ__Quote__r.NSP_Customer_Billing_Address__c, SBQQ__RenewedContract__r.SBQQ__Quote__r.NSP_Customer_Shipping_Address__c,SBQQ__RenewedContract__r.SBQQ__Quote__r.NSP_Opportunity_Type__c,
                                            SBQQ__RenewedContract__r.SBQQ__Quote__r.NSP_Client_For_Life__c, SBQQ__RenewedContract__r.SBQQ__Quote__r.SBQQ__Partner__c, SBQQ__RenewedContract__r.SBQQ__Quote__r.NSP_Opportunity_Primary_Product__c, SBQQ__RenewedContract__r.SBQQ__Quote__r.SBQQ__PrimaryContact__c,SBQQ__RenewedContract__r.SBQQ__Quote__r.NSP_Invoice_To_Email__c, SBQQ__AmendedContract__r.SBQQ__Quote__r.NSP_BPS_Billing_Frequency__c,
                                            SBQQ__RenewedContract__r.SBQQ__Quote__c, SBQQ__RenewedContract__r.SBQQ__Order__c ,SBQQ__RenewedContract__r.NSP_PrimaryProduct__c, SBQQ__RenewedContract__r.NSP_Client_For_Life__c,SBQQ__RenewedContract__r.NSP_Partner__c, SBQQ__RenewedContract__r.NSP_Invoice_To_Email__c, SBQQ__RenewedContract__r.SBQQ__Order__r.blng__BillingAccount__c, SBQQ__RenewedContract__r.SBQQ__Order__r.NSP_Billing_Address__c, SBQQ__RenewedContract__r.SBQQ__Order__r.NSP_Shipping_Address__c,
                                            SBQQ__AmendedContract__r.SBQQ__Quote__c, SBQQ__AmendedContract__r.SBQQ__Order__c, SBQQ__AmendedContract__r.NSP_PrimaryProduct__c, SBQQ__AmendedContract__r.NSP_Client_For_Life__c,SBQQ__AmendedContract__r.NSP_Partner__c, SBQQ__AmendedContract__r.NSP_Invoice_To_Email__c, SBQQ__AmendedContract__r.SBQQ__Order__r.blng__BillingAccount__c, SBQQ__AmendedContract__r.SBQQ__Order__r.NSP_Billing_Address__c, SBQQ__AmendedContract__r.SBQQ__Order__r.NSP_Shipping_Address__c

                                            FROM Opportunity WHERE Id IN:opportunityIds AND (SBQQ__AmendedContract__c!=null OR SBQQ__RenewedContract__c!=null) ] ){ //AND (SBQQ__AmendedContract__c!=null AND SBQQ__AmendedContract__r.SBQQ__Quote__c!=null) OR (SBQQ__RenewedContract__c!=null AND SBQQ__RenewedContract__r.SBQQ__Quote__c!=null) ] {

            renewAmendOpptys.put(opp.Id,opp);
}

        if(renewAmendOpptys.size()>0) {
            for(SBQQ__Quote__c raquote : renewAmendQuotes) {
                if(raquote.SBQQ__Type__c==NSP_CPQConstants.QUOTE_TYPE_RENEWAL) {
                    if(renewAmendOpptys.containskey(raquote.SBQQ__Opportunity2__c)){
                        Opportunity raOppty = renewAmendOpptys.get(raquote.SBQQ__Opportunity2__c);
                        raquote.NSP_Quantity_of_Estimated_Employees__c = raOppty.SBQQ__RenewedContract__r.NSP_Number_of_Employees__c;
                        raquote.NSP_Pricing_Model__c = raOppty.SBQQ__RenewedContract__r.NSP_Pricing_Model__c;
                        raquote.NSP_Product_Type__c = raOppty.SBQQ__RenewedContract__r.NSP_Product_Type__c;
                        raquote.NSP_Opportunity_Type__c = NSP_CPQConstants.QUOTE_TYPE_RENEWAL;

                        if(raOppty.SBQQ__RenewedContract__r.SBQQ__Quote__c != null) {
                        raquote.NSP_Opportunity_Primary_Product__c = raOppty.SBQQ__RenewedContract__r.SBQQ__Quote__r.NSP_Opportunity_Primary_Product__c;
                        raquote.NSP_Client_For_Life__c = raOppty.SBQQ__RenewedContract__r.SBQQ__Quote__r.NSP_Client_For_Life__c;
                        raquote.SBQQ__Partner__c = raOppty.SBQQ__RenewedContract__r.SBQQ__Quote__r.SBQQ__Partner__c;
                        raquote.NSP_Invoice_To_Email__c = raOppty.SBQQ__RenewedContract__r.SBQQ__Quote__r.NSP_Invoice_To_Email__c;
                        raquote.NSP_Billing_Account__c = raOppty.SBQQ__RenewedContract__r.SBQQ__Quote__r.NSP_Billing_Account__c;
                        raquote.NSP_Billing_Address__c = raOppty.SBQQ__RenewedContract__r.SBQQ__Quote__r.NSP_Billing_Address__c;
                        raquote.NSP_Shipping_Address__c = raOppty.SBQQ__RenewedContract__r.SBQQ__Quote__r.NSP_Shipping_Address__c;
                        raquote.NSP_Customer_Billing_Address__c = raOppty.SBQQ__RenewedContract__r.SBQQ__Quote__r.NSP_Customer_Billing_Address__c;
                        raquote.NSP_Customer_Shipping_Address__c = raOppty.SBQQ__RenewedContract__r.SBQQ__Quote__r.NSP_Customer_Shipping_Address__c;
                        }
                        else {
                        raquote.NSP_Opportunity_Primary_Product__c = raOppty.SBQQ__RenewedContract__r.NSP_PrimaryProduct__c;
                        raquote.NSP_Client_For_Life__c = raOppty.SBQQ__RenewedContract__r.NSP_Client_For_Life__c;
                        raquote.SBQQ__Partner__c = raOppty.SBQQ__RenewedContract__r.NSP_Partner__c;
                        raquote.NSP_Invoice_To_Email__c = raOppty.SBQQ__RenewedContract__r.NSP_Invoice_To_Email__c;
                        raquote.NSP_Billing_Account__c = raOppty.SBQQ__RenewedContract__r.SBQQ__Order__r.blng__BillingAccount__c;
                        raquote.NSP_Billing_Address__c = raOppty.SBQQ__RenewedContract__r.SBQQ__Order__r.NSP_Billing_Address__c;
                        raquote.NSP_Shipping_Address__c = raOppty.SBQQ__RenewedContract__r.SBQQ__Order__r.NSP_Shipping_Address__c;
                        raquote.NSP_Customer_Billing_Address__c = raOppty.SBQQ__RenewedContract__r.SBQQ__Order__r.NSP_Billing_Address__c;
                        raquote.NSP_Customer_Shipping_Address__c = raOppty.SBQQ__RenewedContract__r.SBQQ__Order__r.NSP_Shipping_Address__c;

                        }
                        if(raquote.NSP_Opportunity_Primary_Product__c == 'Time & Attendance') {
                            raquote.NSP_Budgetary_Quote__c = true;
                        }
                    }
                }
                if(raquote.SBQQ__Type__c!=NSP_CPQConstants.QUOTE_TYPE_RENEWAL && raquote.SBQQ__Type__c!=NSP_CPQConstants.QUOTE_TYPE_NEW) {
                    if(renewAmendOpptys.containskey(raquote.SBQQ__Opportunity2__c)){
                        Opportunity raOppty = renewAmendOpptys.get(raquote.SBQQ__Opportunity2__c);

                        raquote.NSP_Quantity_of_Estimated_Employees__c = raOppty.SBQQ__AmendedContract__r.NSP_Number_of_Employees__c;
                        raquote.NSP_Pricing_Model__c = raOppty.SBQQ__AmendedContract__r.NSP_Pricing_Model__c;
                        raquote.NSP_Opportunity_Type__c = NSP_CPQConstants.OPPORTUNITY_TYPE_EXISTING_BUSINESS;
                        raquote.NSP_Product_Type__c = raOppty.SBQQ__AmendedContract__r.NSP_Product_Type__c;

                        if(raOppty.SBQQ__AmendedContract__r.SBQQ__Quote__c != null) {
                        raquote.NSP_Opportunity_Primary_Product__c = raOppty.SBQQ__AmendedContract__r.SBQQ__Quote__r.NSP_Opportunity_Primary_Product__c;
                        raquote.NSP_Client_For_Life__c = raOppty.SBQQ__AmendedContract__r.SBQQ__Quote__r.NSP_Client_For_Life__c;
                        raquote.NSP_Product_Type__c = raOppty.SBQQ__AmendedContract__r.SBQQ__Quote__r.NSP_Product_Type__c;
                        raquote.SBQQ__Partner__c = raOppty.SBQQ__AmendedContract__r.SBQQ__Quote__r.SBQQ__Partner__c;
                        raquote.NSP_Invoice_To_Email__c = raOppty.SBQQ__AmendedContract__r.SBQQ__Quote__r.NSP_Invoice_To_Email__c;
                        raquote.NSP_Billing_Account__c = raOppty.SBQQ__AmendedContract__r.SBQQ__Quote__r.NSP_Billing_Account__c;
                        raquote.NSP_Billing_Address__c = raOppty.SBQQ__AmendedContract__r.SBQQ__Quote__r.NSP_Billing_Address__c;
                        raquote.NSP_Shipping_Address__c = raOppty.SBQQ__AmendedContract__r.SBQQ__Quote__r.NSP_Shipping_Address__c;
                        raquote.NSP_Customer_Billing_Address__c = raOppty.SBQQ__AmendedContract__r.SBQQ__Quote__r.NSP_Customer_Billing_Address__c;
                        raquote.NSP_Customer_Shipping_Address__c = raOppty.SBQQ__AmendedContract__r.SBQQ__Quote__r.NSP_Customer_Shipping_Address__c;
                        raquote.NSP_BPS_Billing_Frequency__c = raOppty.SBQQ__AmendedContract__r.SBQQ__Quote__r.NSP_BPS_Billing_Frequency__c;
                        }
                        else {
                        raquote.NSP_Opportunity_Primary_Product__c = raOppty.SBQQ__AmendedContract__r.NSP_PrimaryProduct__c;
                        raquote.NSP_Client_For_Life__c = raOppty.SBQQ__AmendedContract__r.NSP_Client_For_Life__c;
                        raquote.SBQQ__Partner__c = raOppty.SBQQ__AmendedContract__r.NSP_Partner__c;
                        raquote.NSP_Invoice_To_Email__c = raOppty.SBQQ__AmendedContract__r.NSP_Invoice_To_Email__c;
                        raquote.NSP_Billing_Account__c = raOppty.SBQQ__AmendedContract__r.SBQQ__Order__r.blng__BillingAccount__c;
                        raquote.NSP_Billing_Address__c = raOppty.SBQQ__AmendedContract__r.SBQQ__Order__r.NSP_Billing_Address__c;
                        raquote.NSP_Shipping_Address__c = raOppty.SBQQ__AmendedContract__r.SBQQ__Order__r.NSP_Shipping_Address__c;
                        raquote.NSP_Customer_Billing_Address__c = raOppty.SBQQ__AmendedContract__r.SBQQ__Order__r.NSP_Billing_Address__c;
                        raquote.NSP_Customer_Shipping_Address__c = raOppty.SBQQ__AmendedContract__r.SBQQ__Order__r.NSP_Shipping_Address__c;
                        List<SBQQ__Subscription__c> subBillingFreq = [Select id, SBQQ__BillingFrequency__c FROM SBQQ__Subscription__c WHERE SBQQ__Contract__c =:raOppty.SBQQ__AmendedContract__c LIMIT 1];
                            if(subBillingFreq.size()>0){
                                raquote.NSP_BPS_Billing_Frequency__c = subBillingFreq[0].SBQQ__BillingFrequency__c != null ? subBillingFreq[0].SBQQ__BillingFrequency__c : NSP_CPQConstants.MONTHLY;
                            }
                        }


                        if(String.isNotEmpty(raquote.NSP_Product_Type__c) && raquote.NSP_TransactionType__c==NSP_CPQConstants.SUPPLEMENTAL_ONLY_TRANSACTION_TYPE
                        && (raquote.NSP_Product_Type__c.contains(NSP_CPQConstants.QUOTE_PRODUCT_TYPE_WX) || raquote.NSP_Product_Type__c.contains(NSP_CPQConstants.QUOTE_PRODUCT_TYPE_WA))) {
                            String[] ptypelist = raquote.NSP_Product_Type__c.split(';');
                            ptypelist.add(NSP_CPQConstants.QUOTE_PRODUCT_TYPE_HRCS);
                            raquote.NSP_Product_Type__c=String.join(ptypelist,';');
                        }
                    }
                }
            }
        }
    }
}

    //
    // Method Name : stampQuoteOwnerGroup
    // Description : Method to stamp Quote Owner group on quote on update.
    // Author : Rakesh Das       Date : 26/07/2021
    // @param QuoteNewMap Map of New Quote.
    // @param QuoteOldMap Map of Old Quote.
    // @return void
    //
    public void stampQuoteOwnerGroup(Map<Id, SBQQ__Quote__c> quoteNewMap,Map<Id, SBQQ__Quote__c> quoteOldMap) {
        List<Id> ownerIds = new List<Id>();
        Map<Id, String> OwnerIdToGroupMap = new Map<Id,String>();
        Map<Id, String> OwnerIdToL2Map = new Map<Id,String>();
        Map<Id, Boolean> isQuoteIdToValidOwnerChangeMap = new Map<Id,Boolean>();
        Map<Id, Boolean> isQuoteIdToStampNeededMap = new Map<Id,Boolean>();

        set<string> groupname = new set<string>(system.label.NSP_ApprovalSubmitterGroups.split(','));
        set<string> SE_Approval_Chain = new set<string>{'NSP_SE_Group_1','NSP_SE_Group_2','NSP_SE_MidMarket','NSP_SE_Group_3'};
        //Current User Id to check for same group
        String currUserId = UserInfo.getUserId();
        String currUserGroupName;
        //Filter logic to check if quote owner is changed
        for(SBQQ__Quote__c newQuote : quoteNewMap.values()) {

            isQuoteIdToValidOwnerChangeMap.put(newQuote.Id,false);
            isQuoteIdToStampNeededMap.put(newQuote.Id,false);

        if(newQuote.OwnerId!=null){

            if(String.isEmpty(newQuote.NSP_Submitted_User_Role__c)){
                isQuoteIdToStampNeededMap.put(newQuote.Id,true);
                ownerIds.add(newQuote.OwnerId);

            }
            if(newQuote.OwnerId != quoteOldMap.get(newQuote.Id).OwnerId){
                isQuoteIdToValidOwnerChangeMap.put(newQuote.Id,true);
                isQuoteIdToStampNeededMap.put(newQuote.Id,true);
                ownerIds.add(newQuote.OwnerId);
            }
            if(newQuote.OwnerId == quoteOldMap.get(newQuote.Id).OwnerId){
                ownerIds.add(currUserId);
                ownerIds.add(newQuote.OwnerId);
            }
        }

        }



        if(ownerIds.size()>0){
        // Querying Owner Group Name and storing in Maps to put into quote fields below
         for(groupMember  objmember : [select id,UserOrGroupId,GroupId,Group.DeveloperName,Group.Name from groupMember
                                      WHERE UserOrGroupId IN: ownerIds AND Group.DeveloperName IN : groupname  ]){
            if(objmember.UserOrGroupId == currUserId) {
                currUserGroupName = objmember.Group.Name;
            }

            if(SE_Approval_Chain.contains(objmember.Group.DeveloperName)) {
                OwnerIdToGroupMap.put(objmember.UserOrGroupId, NSP_CPQConstants.SE_APPROVAL_Chain);  //objQuote.NSP_Submitted_User_Role__c = NSP_CPQConstants.SE_APPROVAL_Chain ;
                OwnerIdToL2Map.put(objmember.UserOrGroupId,objmember.Group.Name); //objQuote.NSP_Submitted_User_Role_L2__c = objmember.Group.Name ;
            }
            else {
                // objQuote.NSP_Submitted_User_Role__c = objmember.Group.Name ;
                OwnerIdToGroupMap.put(objmember.UserOrGroupId, objmember.Group.Name);
                OwnerIdToL2Map.put(objmember.UserOrGroupId,objmember.Group.Name);

            }

        }
        // Assigning Owner Group Name to respective quote fields
         for(SBQQ__Quote__c newQuote : quoteNewMap.values()) {
             Boolean isValidOwnerUpdate = isQuoteIdToValidOwnerChangeMap.get(newQuote.Id);
             Boolean isStampingreqd = isQuoteIdToStampNeededMap.get(newQuote.Id);
            Boolean isOwnerchanged = false; // Added is as part of code fix
             if(OwnerIdToL2Map.containskey(newQuote.OwnerId) && newQuote.OwnerId!=currUserId) {
                if(OwnerIdToL2Map.get(newQuote.OwnerId) == currUserGroupName && !isValidOwnerUpdate) {
                    newQuote.OwnerId = currUserId;
                    isOwnerchanged = true;
                }
             }
           // Added as part of default setting for search filter issue fix
           if(!OwnerIdToGroupMap.containskey(newQuote.OwnerId)) {
             newQuote.NSP_Submitted_User_Role__c = NSP_CPQConstants.NOT_ASSIGNED;
             newQuote.NSP_Submitted_User_Role_L2__c = NSP_CPQConstants.NOT_ASSIGNED;
           }
           if( OwnerIdToGroupMap.containskey(newQuote.OwnerId) && (isValidOwnerUpdate || isStampingreqd || isOwnerchanged)) {
           newQuote.NSP_Submitted_User_Role__c = OwnerIdToGroupMap.get(newQuote.OwnerId);
           newQuote.NSP_Submitted_User_Role_L2__c = OwnerIdToL2Map.get(newQuote.OwnerId);
           }


          }

        }
    }

    //
    // @MethodName : updateScholarshipEligibilityUpdate
    // @param newQuoteList List of New Quote.
    // @Description : Method added for STY-01332 to check if Scholarship pricing is eligible based on Opportunity BPA and Partner
    // @return void
    //
    public void updateScholarshipEligibility( List<SBQQ__Quote__c> newQuoteList ) {
        List<String> userList = this.buildUserList();
        List<String> partnerList = this.buildPartnerList();
        for ( SBQQ__Quote__c quote: newQuoteList ) {
            if ( quote.NSP_Pricing_Model__c == NSP_CPQConstants.WX_PRICE_MODEL ) {
                if ( userList.contains( quote.NSP_Opportunity_BPA__c ) ) {
                    quote.NSP_IsScholarshipEligibleBPA__c = true;
                } else {
                    quote.NSP_IsScholarshipEligibleBPA__c = false;
                }
                if ( quote.NSP_Opportunity_Partner_Name__c != null
                    && partnerList.contains( quote.NSP_Opportunity_Partner_Name__c.toUpperCase() )
                    )
                {
                    quote.NSP_IsScholarshipEligiblePartner__c = true;
                    quote.NSP_Is_Partner_CS_Applicable__c = false;
                } else {
                    quote.NSP_IsScholarshipEligiblePartner__c = false;
                }
            }
        }
    }

    // helper method to defeat sonar cognitive complexity...
    private List<String> buildUserList() {
        List<String> userList = new List<String>();
        List<Group> groupM = [
            SELECT ( SELECT UserOrGroupId FROM GroupMembers )
            FROM Group
            WHERE ( Name = :NSP_CPQConstants.SCHOLARSHIP_PUBLIC_GROUP )
        ];
        if ( !groupM.isEmpty() ) {
            for ( GroupMember member : groupM[0].GroupMembers ) {
                userList.add( member.UserOrGroupId );
            }
        }
        return userList;
    }

    // helper method to defeat sonar cognitive complexity...
    private List<String> buildPartnerList() {
        List<String> partnerList = new List<String>();
        //Fetch Custom metadata which holds the eligible partner accounts
        List<NSP_Scholarship_Eligibility__mdt> eligiblePartner = NSP_Scholarship_Eligibility__mdt.getAll().values();
        for ( NSP_Scholarship_Eligibility__mdt partner : eligiblePartner ) {
            if ( partner.NSP_Partner__c != null ) {
                partnerList.add( partner.NSP_Partner__c.toUpperCase() );
            }
        }
        return partnerList;
    }

    //
    // Method Name : stampQuoteOwnerGrouponInsert
    // Description : Method to stamp Quote Owner group on quote on insert.
    // Author : Rakesh Das       Date : 09/06/2021
    // @param newQuotesList List of New Quote.
    // @return void
    //
    public void stampQuoteOwnerGrouponInsert( List<SBQQ__Quote__c> newQuotesList ) {
        List<Id> ownerIds = new List<Id>();
        Map<Id,String> ownerIdToGroupMap = new Map<Id,String>();
        Map<Id,String> ownerIdToL2Map = new Map<Id,String>();
        Set<string> groupname = new set<string>( System.label.NSP_ApprovalSubmitterGroups.split( ',' ) );
        Set<string> seApprovalChain = new set<string>{
            'NSP_SE_Group_1' ,
            'NSP_SE_Group_2' ,
            'NSP_SE_MidMarket' ,
            'NSP_SE_Group_3'
        };
        for ( SBQQ__Quote__c newQuote : newQuotesList ) {
            if ( newQuote.OwnerId != null ) {
                ownerIds.add( newQuote.OwnerId );
            }
            //Added as part of DF-01372 to nullify the approval related fields on clone.
            if ( newQuote.isClone() ) {
                newQuote.NSP_Submitter_Comment__c = null;
                newQuote.ApprovalStatus__c = null;
                newQuote.SubmittedUser__c = null;
                newQuote.SubmittedDate__c = null;
                newQuote.SBQQ__Status__c = NSP_CPQConstants.QUOTE_STATUS_RECALLED;
            }
        }
        if ( !ownerIds.isEmpty() ) {
            for ( GroupMember  objmember : [
                        SELECT Id , UserOrGroupId , GroupId , Group.DeveloperName , Group.Name
                        FROM GroupMember
                        WHERE (
                            ( UserOrGroupId IN :ownerIds )
                            AND ( Group.DeveloperName IN :groupname )
                        )
                    ]
                )
            {
                if ( seApprovalChain.contains( objmember.Group.DeveloperName ) ) {
                    ownerIdToGroupMap.put( objmember.UserOrGroupId , NSP_CPQConstants.SE_APPROVAL_Chain );
                    ownerIdToL2Map.put( objmember.UserOrGroupId , objmember.Group.Name );
                } else {
                    ownerIdToGroupMap.put( objmember.UserOrGroupId , objmember.Group.Name );
                    ownerIdToL2Map.put( objmember.UserOrGroupId , objmember.Group.Name );
                }
            }
            // Assigning Owner Group Name to respective quote fields
            this.populateSubmittedUserRoleFields( newQuotesList , ownerIdToGroupMap , ownerIdToL2Map );
        }
    }

    // helper method to defeat sonar cognitive complexity...
    private void populateSubmittedUserRoleFields( List<SBQQ__Quote__c> newQuotesList , Map<Id,String> ownerIdToGroupMap , Map<Id,String> ownerIdToL2Map ) {
        if ( ( newQuotesList != null ) && !newQuotesList.isEmpty() ) {
            for ( SBQQ__Quote__c newQuote : newQuotesList )  {
                if ( ( ownerIdToGroupMap != null )
                    && ownerIdToGroupMap.containskey( newQuote.OwnerId )
                    )
                {
                    newQuote.NSP_Submitted_User_Role__c = ownerIdToGroupMap.get( newQuote.OwnerId );
                }
                if ( ( ownerIdToL2Map != null )
                    && ownerIdToL2Map.containskey( newQuote.OwnerId )
                    )
                {
                    newQuote.NSP_Submitted_User_Role_L2__c = ownerIdToL2Map.get( newQuote.OwnerId );
                }
            }
        }
    }

    //
    // Method Name : populateInsperitySigner
    // Description : Method to populate Insperity Signer on Opportunity
    // Author : Rakesh Das       Date : 14/09/2021
    // @param QuoteNewMap Map of New Quote.
    // @param QuoteOldMap Map of Old Quote.
    // @return void
    //
    public void populateInsperitySigner( Map<Id,SBQQ__Quote__c> quoteNewMap , Map<Id,SBQQ__Quote__c> quoteOldMap )  {
        Map<Id,String> opportunityIdWithProductType = new Map<Id,String>();
        Set<String> signerUsernames = new Set<String> ();
        Set<String> quoteProductTypes = new Set<String> ();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        Map<String, NSP_DocuSign_Signers__mdt> docusignSignerConfigs = NSP_DocuSign_Signers__mdt.getAll();
        Map<String,String> userNameToIdMap = new Map<String,String>();
        Map<String,String> productTypeWithSigner = new Map<String,String>();
        map<Id,Id> opportunityIdToQuotePricebookId = new map<Id,Id>();
        for(SBQQ__Quote__c newQuote : quoteNewMap.values()) {
            if(newQuote.SBQQ__Opportunity2__c!=null && newQuote.NSP_Opportunity_Primary_Product__c !=null
            && ((newQuote.NSP_Opportunity_Primary_Product__c != quoteOldMap.get(newQuote.Id).NSP_Opportunity_Primary_Product__c) || (newQuote.SBQQ__Primary__c != quoteOldMap.get(newQuote.Id).SBQQ__Primary__c && newQuote.SBQQ__Status__c == NSP_CPQConstants.QUOTE_APPROVAL_STATUS_APPROVED && newQuote.SBQQ__Primary__c==true ) ||
            (newQuote.SBQQ__Status__c != quoteOldMap.get(newQuote.Id).SBQQ__Status__c && newQuote.SBQQ__Status__c == NSP_CPQConstants.QUOTE_APPROVAL_STATUS_APPROVED && newQuote.SBQQ__Primary__c==true))) {
                quoteProductTypes.add(newQuote.NSP_Opportunity_Primary_Product__c);
                opportunityIdWithProductType.put(newQuote.SBQQ__Opportunity2__c,newQuote.NSP_Opportunity_Primary_Product__c);
            }
        }
        if(quoteProductTypes.size()>0) {
            for(NSP_DocuSign_Signers__mdt docsigner : docusignSignerConfigs.values()) {
                if(quoteProductTypes.contains(docsigner.NSP_Product_Type__c)) {
                    signerUsernames.add(docsigner.NSP_Signer_Username__c);
                    productTypeWithSigner.put(docsigner.NSP_Product_Type__c,docsigner.NSP_Signer_Username__c);
                }
            }
            for(User usr : [Select Id, Username from User WHERE Username IN:signerUsernames]) {
                userNameToIdMap.put(usr.Username,usr.Id);
            }
            for ( Opportunity op : [Select  Id, Name, NSP_Customer_Signer__c, NSP_Insperity_Signer__c,Pricebook2Id from Opportunity
                                            WHERE Id IN : opportunityIdWithProductType.keySet()
                                            OR Id IN : opportunityIdToQuotePricebookId.keySet() ]) {
                Id newSigner = userNameToIdMap.get(productTypeWithSigner.get(opportunityIdWithProductType.get(op.Id)));
                if(op.NSP_Insperity_Signer__c != newSigner) {
                    op.NSP_Insperity_Signer__c = newSigner;
                    opportunitiesToUpdate.add(op);
                }
            }
        }
        if(opportunitiesToUpdate.size()>0) {
            try{
                database.update(opportunitiesToUpdate);
            } catch ( Exception e ) {
                NSP_QuoteTriggerHelper.handleException( e , 'populateInsperitySigner' );
            }
        }
    }

    //
    // Method Name : updateBillingAccountOnQuote
    // Description : Method to Billing Account on Quote for STY-00478
    // Author : sumit       Date : 21/09/2021
    // @param QuoteNewMap Map of New Quote.
    // @param QuoteOldMap Map of Old Quote.
    // @return void
    //
    public static void updateBillingAccountOnQuote( List<SBQQ__Quote__c> newQuotesList , Map<Id,SBQQ__Quote__c> quoteOldMap ) {
        Map<String,NSP_PriceBook_Billing_Account_Mapping__mdt> pricebookBillingAccountMap = new Map<String,NSP_PriceBook_Billing_Account_Mapping__mdt>();
        Set<String> accountNameSet = new Set<String>();
        Map<String,Id> accountNameToIdMap = new Map<String,Id>();
        Map<String, Id> pbNamesWithId = new Map<String,Id> ();
        // query account data and map
        if(!STOP_ACCOUNT_QUERY){
            for (PriceBook2 pb : [SELECT Id, Name FROM PriceBook2 WHERE IsActive=TRUE]) {
                pbNamesWithId.put(pb.Name, pb.Id);
            }
            // get metadate and create map
            for(NSP_PriceBook_Billing_Account_Mapping__mdt setting : NSP_PriceBook_Billing_Account_Mapping__mdt.getAll().values()){
                if(pbNamesWithId.containsKey(setting.NSP_PriceBookId__c)){
                    pricebookBillingAccountMap.put(pbNamesWithId.get(setting.NSP_PriceBookId__c),setting);
                }
                accountNameSet.add(setting.NSP_WO_Account__c);
            }
            STOP_ACCOUNT_QUERY = true;
            for(Account eachAccount : [SELECT Id,Name from Account WHERE Name IN : accountNameSet]) {
                accountNameToIdMap.put(eachAccount.Name,eachAccount.Id);
            }
        }
        for(SBQQ__Quote__c newQuote : newQuotesList ) {
            SBQQ__Quote__c oldQuote = quoteOldMap != null ? quoteOldMap.get(newQuote.Id): null;
            if(Trigger.IsInsert
            || newQuote.SBQQ__PricebookId__c != oldQuote.SBQQ__PricebookId__c
            || newQuote.NSP_Pricing_Model__c != oldQuote.NSP_Pricing_Model__c){
                // check if pricebook is changed or pricing model is changed
                if(newQuote.SBQQ__PricebookId__c != null && pricebookBillingAccountMap.containsKey(newQuote.SBQQ__PricebookId__c )){
                        // get corrosponding metadata
                        NSP_PriceBook_Billing_Account_Mapping__mdt eachmtd = pricebookBillingAccountMap.get(newQuote.SBQQ__PricebookId__c );
                        // if pricing model is defined at metadata check for equal
                        if(String.isNotBlank(eachmtd.NSP_Applicable_Pricing_Model__c) && String.isNotBlank(newQuote.NSP_Pricing_Model__c)){
                            set<String> pricingModelSet = new set<String>(eachmtd.NSP_Applicable_Pricing_Model__c.split(','));
                            if(pricingModelSet.Contains(newQuote.NSP_Pricing_Model__c) && accountNameToIdMap.containsKey(eachmtd.NSP_WO_Account__c)){
                                newQuote.NSP_Billing_Account__c = accountNameToIdMap.get(eachmtd.NSP_WO_Account__c);
                            }
                        }  // if product type is defined at metadata check for not equal
                        else if(accountNameToIdMap.containsKey(eachmtd.NSP_WO_Account__c) && String.isNotBlank(eachmtd.NSP_Product_Type__c)){
                            set<String> primaryProductSet = new set<String>(eachmtd.NSP_Product_Type__c.split(','));
                            if((String.isBlank(newQuote.NSP_Opportunity_Primary_Product__c) || !primaryProductSet.Contains(newQuote.NSP_Opportunity_Primary_Product__c) )){
                                newQuote.NSP_Billing_Account__c = accountNameToIdMap.get(eachmtd.NSP_WO_Account__c);
                            }
                        }
                        else if(accountNameToIdMap.containsKey(eachmtd.NSP_WO_Account__c) && String.isNotBlank(newQuote.SBQQ__PricebookId__c ) ){
                            newQuote.NSP_Billing_Account__c = accountNameToIdMap.get(eachmtd.NSP_WO_Account__c);
                            newQuote.SBQQ__Partner__c = accountNameToIdMap.get(eachmtd.NSP_WO_Account__c);
                        }
                }
            }
        }
    }

    //
    // Method Name : updateBillingAndShippringAddressOnQuote
    // Description : Method to update billing and shipping addresses on Quote for STY-01516
    // Author : sumit       Date : 29/10/2021
    // @param QuoteNewMap Map of New Quote.
    // @param QuoteOldMap Map of Old Quote.
    // @return void
    //
    public static void updateBillingAndShippringAddressOnQuote( List<SBQQ__Quote__c> newQuotesList , Map<Id,SBQQ__Quote__c> quoteOldMap ) {
        Set<Id> addressIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id,NSP_Address__c> addressMap;
        Map<Id,Account> accountMap;


        for(SBQQ__Quote__c newQuote : newQuotesList){
            SBQQ__Quote__c oldQuote = quoteOldMap != null ? quoteOldMap.get(newQuote.Id):null;

            if(Trigger.isInsert
            || newQuote.NSP_Billing_Account__c  != oldQuote.NSP_Billing_Account__c
            || newQuote.NSP_Billing_Address__c  != oldQuote.NSP_Billing_Address__c
            || newQuote.NSP_Shipping_Address__c  != oldQuote.NSP_Shipping_Address__c
            || newQuote.NSP_Customer_Billing_Address__c != oldQuote.NSP_Customer_Billing_Address__c
            || newQuote.NSP_Customer_Shipping_Address__c != oldQuote.NSP_Customer_Shipping_Address__c
            || (newQuote.NSP_Sync_Account_Standard_Address__c &&  !oldQuote.NSP_Sync_Account_Standard_Address__c )){

                if( newQuote.NSP_Billing_Address__c != null){
                    addressIdSet.add(newQuote.NSP_Billing_Address__c);
                }

                if( newQuote.NSP_Shipping_Address__c != null){
                    addressIdSet.add(newQuote.NSP_Shipping_Address__c);
                }

                if( newQuote.NSP_Customer_Billing_Address__c != null){
                    addressIdSet.add(newQuote.NSP_Customer_Billing_Address__c);
                }

                if( newQuote.NSP_Customer_Shipping_Address__c != null){
                    addressIdSet.add(newQuote.NSP_Customer_Shipping_Address__c);
                }

                if(newQuote.NSP_Billing_Account__c != null){
                    accountIdSet.add(newQuote.NSP_Billing_Account__c);
                }
                accountIdSet.add(newQuote.SBQQ__Account__c);
            }
        }

        if(addressIdSet.Size() > 0){
            addressMap  = new Map<Id,NSP_Address__c>([SELECT    Id,NSP_Street__c,NSP_Street_Address_2__c,Name,
                                                                NSP_City__c,NSP_State__c,NSP_Country__c,
                                                                NSP_Postal_Code__c FROM NSP_Address__c
                                                                WHERE Id IN : addressIdSet]);
        }

        if(accountIdSet.Size() > 0){
            accountMap = new Map<Id,Account>([SELECT Id,Name,BillingStreet,BillingCity,BillingState,BillingCountry,BillingPostalCode,
                                                        ShippingStreet,ShippingCity,ShippingState,ShippingCountry,ShippingPostalCode
                                                        FROM Account WHERE Id IN: accountIdSet]);
        }

        for(SBQQ__Quote__c newQuote : newQuotesList){
            SBQQ__Quote__c oldQuote = quoteOldMap != null ? quoteOldMap.get(newQuote.Id):null;

            if(Trigger.isInsert
            || newQuote.NSP_Billing_Account__c  != oldQuote.NSP_Billing_Account__c
            || newQuote.NSP_Billing_Address__c  != oldQuote.NSP_Billing_Address__c
            || newQuote.NSP_Shipping_Address__c  != oldQuote.NSP_Shipping_Address__c
            || newQuote.NSP_Customer_Billing_Address__c != oldQuote.NSP_Customer_Billing_Address__c
            || newQuote.NSP_Customer_Shipping_Address__c != oldQuote.NSP_Customer_Shipping_Address__c
            || (newQuote.NSP_Sync_Account_Standard_Address__c &&  !oldQuote.NSP_Sync_Account_Standard_Address__c )){
                boolean hasBillingAddress = false;
                boolean hasShippingAddress = false;
                boolean hasCustomerBillingAddress = false;
                boolean hasCustomerShippingAddress = false;
                boolean hasBillinAccount = false;
                // copy address from billing address lookup
                if( newQuote.NSP_Billing_Address__c != null && addressMap != null && addressMap.containsKey(newQuote.NSP_Billing_Address__c)){
                    hasBillingAddress = true;
                    NSP_Address__c billingaddress       = addressMap.get(newQuote.NSP_Billing_Address__c);
                    copyBillingAddress(newQuote,null,billingaddress,NSP_CPQConstants.ADDRESS);
                }
                // copy address from shipping address lookup
                if( newQuote.NSP_Shipping_Address__c != null && addressMap != null && addressMap.containsKey(newQuote.NSP_Shipping_Address__c)){
                    hasShippingAddress = true;
                    NSP_Address__c shippingaddress       = addressMap.get(newQuote.NSP_Shipping_Address__c);
                    copyShippingAddress(newQuote,null,shippingaddress,NSP_CPQConstants.ADDRESS);
                }
                // copy address from customer billing address lookup
                if( newQuote.NSP_Customer_Billing_Address__c != null && addressMap != null && addressMap.containsKey(newQuote.NSP_Customer_Billing_Address__c)){
                    hasCustomerBillingAddress = true;
                    NSP_Address__c customerbillingaddress       = addressMap.get(newQuote.NSP_Customer_Billing_Address__c);
                    copyCustomerBillingAddress(newQuote,null,customerbillingaddress,NSP_CPQConstants.ADDRESS);
                    if(!hasBillingAddress && newQuote.NSP_Billing_Address__c == null && newQuote.NSP_Billing_Account__c == null){
                        copyBillingAddress(newQuote,null,customerbillingaddress ,NSP_CPQConstants.ADDRESS);
                        newQuote.NSP_Billing_Address__c = newQuote.NSP_Customer_Billing_Address__c;
                        hasBillingAddress = true;
                    }
                }
                // copy address from customer shipping address lookup
                if( newQuote.NSP_Customer_Shipping_Address__c != null && addressMap != null && addressMap.containsKey(newQuote.NSP_Customer_Shipping_Address__c)){
                    hasCustomerShippingAddress = true;
                    NSP_Address__c customershippingaddress  = addressMap.get(newQuote.NSP_Customer_Shipping_Address__c);
                    copyCustomerShippingAddress(newQuote,null,customershippingaddress,NSP_CPQConstants.ADDRESS);
                }
                // when customer billing address is changed and billing address is blank copy the billing address details from customer biling address data for defect DF-00873
                if(oldQuote != null && newQuote.NSP_Customer_Billing_Address__c != oldQuote.NSP_Customer_Billing_Address__c &&  newQuote.NSP_Billing_Account__c == null){
                    newQuote.NSP_Billing_Address__c = newQuote.NSP_Customer_Billing_Address__c;
                    if(newQuote.NSP_Customer_Billing_Address__c != null){
                        NSP_Address__c customerbillingaddress       = addressMap.get(newQuote.NSP_Customer_Billing_Address__c);
                        copyBillingAddress(newQuote,null,customerbillingaddress,NSP_CPQConstants.ADDRESS);
                        hasBillingAddress = true;
                    }
                    else{
                        hasBillingAddress = false;
                    }
                }
                // when customer shipping address is changed and shipping address is blank copy the shipping address details from customer biling address data DF-00873
                if(oldQuote != null && newQuote.NSP_Customer_Shipping_Address__c != oldQuote.NSP_Customer_Shipping_Address__c && newQuote.NSP_Billing_Account__c == null){
                    newQuote.NSP_Shipping_Address__c = newQuote.NSP_Customer_Shipping_Address__c;

                    if(newQuote.NSP_Customer_Shipping_Address__c != null){
                        NSP_Address__c customershippingaddress  = addressMap.get(newQuote.NSP_Customer_Shipping_Address__c);
                        copyShippingAddress(newQuote,null,customershippingaddress ,NSP_CPQConstants.ADDRESS);
                        hasShippingAddress = true;
                    }
                    else{
                        hasShippingAddress = false;
                    }
                }


                // copy address from billing account
                if(newQuote.NSP_Billing_Account__c != null && accountMap != null && accountMap.containsKey(newQuote.NSP_Billing_Account__c)){
                    Account billingAccount = accountMap.get(newQuote.NSP_Billing_Account__c);
                    hasBillinAccount = true;
                    if(!hasBillingAddress){
                        copyBillingAddress(newQuote,billingAccount,null,NSP_CPQConstants.ACCOUNT);
                    }

                    if(!hasShippingAddress){
                        copyShippingAddress(newQuote,billingAccount,null,NSP_CPQConstants.ACCOUNT);
                    }
                }
                // copy address from quote Account
                if(newQuote.SBQQ__Account__c != null && accountMap != null && accountMap.containsKey(newQuote.SBQQ__Account__c )){
                    Account objAccount = accountMap.get(newQuote.SBQQ__Account__c);
                    if(!hasBillingAddress && !hasBillinAccount){
                        copyBillingAddress(newQuote,objAccount,null,NSP_CPQConstants.ACCOUNT);
                    }

                    if(!hasShippingAddress && !hasBillinAccount){
                        copyShippingAddress(newQuote,objAccount,null,NSP_CPQConstants.ACCOUNT);
                    }

                    if(!hasCustomerBillingAddress){
                        copyCustomerBillingAddress(newQuote,objAccount,null,NSP_CPQConstants.ACCOUNT);
                    }

                    if(!hasCustomerShippingAddress){
                        copyCustomerShippingAddress(newQuote,objAccount,null,NSP_CPQConstants.ACCOUNT);
                    }
                }

                newQuote.NSP_Sync_Account_Standard_Address__c = false;

            }
        }

    }

    public static void copyBillingAddress(
        SBQQ__Quote__c newQuote ,
        Account objAccount ,
        NSP_Address__c objAddress ,
        String copyFrom
        )
    {
        if ( ( copyFrom == NSP_CPQConstants.ACCOUNT ) && ( objAccount != null ) ) {
            newQuote.SBQQ__BillingStreet__c = objAccount.BillingStreet;
            newQuote.SBQQ__BillingState__c = objAccount.BillingState;
            newQuote.SBQQ__BillingCity__c = objAccount.BillingCity;
            newQuote.SBQQ__BillingPostalCode__c = objAccount.BillingPostalCode;
            newQuote.SBQQ__BillingCountry__c = objAccount.BillingCountry;
            newQuote.SBQQ__BillingName__c = objAccount.Name;
            newQuote.NSP_Bill_To_Street_2__c = null;
        } else{
            newQuote.SBQQ__BillingStreet__c = objAddress.NSP_Street__c;
            newQuote.NSP_Bill_To_Street_2__c = objAddress.NSP_Street_Address_2__c;
            newQuote.SBQQ__BillingState__c = objAddress.NSP_State__c;
            newQuote.SBQQ__BillingCity__c = objAddress.NSP_City__c;
            newQuote.SBQQ__BillingPostalCode__c = objAddress.NSP_Postal_Code__c;
            newQuote.SBQQ__BillingCountry__c = objAddress.NSP_Country__c;
            newQuote.SBQQ__BillingName__c = objAddress.Name;
        }
    }

    public static void copyShippingAddress(
        SBQQ__Quote__c newQuote ,
        Account objAccount ,
        NSP_Address__c objAddress ,
        String copyFrom
        )
    {
        if ( ( copyFrom == NSP_CPQConstants.ACCOUNT ) && ( objAccount != null ) ) {
            newQuote.SBQQ__ShippingStreet__c = objAccount.ShippingStreet;
            newQuote.SBQQ__ShippingState__c = objAccount.ShippingState;
            newQuote.SBQQ__ShippingCity__c = objAccount.ShippingCity;
            newQuote.SBQQ__ShippingPostalCode__c = objAccount.ShippingPostalCode;
            newQuote.SBQQ__ShippingCountry__c = objAccount.ShippingCountry;
            newQuote.SBQQ__ShippingName__c = objAccount.Name;
            newQuote.NSP_Ship_To_Street_2__c = null;
        } else{
            newQuote.SBQQ__ShippingStreet__c = objAddress.NSP_Street__c;
            newQuote.NSP_Ship_To_Street_2__c = objAddress.NSP_Street_Address_2__c;
            newQuote.SBQQ__ShippingState__c = objAddress.NSP_State__c;
            newQuote.SBQQ__ShippingCity__c = objAddress.NSP_City__c;
            newQuote.SBQQ__ShippingPostalCode__c = objAddress.NSP_Postal_Code__c;
            newQuote.SBQQ__ShippingCountry__c = objAddress.NSP_Country__c;
            newQuote.SBQQ__ShippingName__c = objAddress.Name;
        }
    }

    public static void copyCustomerBillingAddress(
        SBQQ__Quote__c newQuote ,
        Account objAccount ,
        NSP_Address__c objAddress ,
        String copyFrom
        )
    {
        if ( ( copyFrom == NSP_CPQConstants.ACCOUNT ) && ( objAccount != null ) ) {
            newQuote.NSP_Bill_To_Street__c = objAccount.BillingStreet;
            newQuote.NSP_Bill_To_State__c = objAccount.BillingState;
            newQuote.NSP_Bill_To_City__c = objAccount.BillingCity;
            newQuote.NSP_Bill_To_Postal_Code__c = objAccount.BillingPostalCode;
            newQuote.NSP_Bill_To_Country__c = objAccount.BillingCountry;
            newQuote.NSP_Bill_To_Name__c = objAccount.Name;
            newQuote.NSP_Customer_Bill_To_Street_2__c = null;

        } else{
            newQuote.NSP_Bill_To_Street__c = objAddress.NSP_Street__c;
            newQuote.NSP_Customer_Bill_To_Street_2__c = objAddress.NSP_Street_Address_2__c;
            newQuote.NSP_Bill_To_State__c = objAddress.NSP_State__c;
            newQuote.NSP_Bill_To_City__c = objAddress.NSP_City__c;
            newQuote.NSP_Bill_To_Postal_Code__c = objAddress.NSP_Postal_Code__c;
            newQuote.NSP_Bill_To_Country__c = objAddress.NSP_Country__c;
            newQuote.NSP_Bill_To_Name__c = objAddress.Name;
        }
    }

    public static void copyCustomerShippingAddress(
        SBQQ__Quote__c newQuote ,
        Account objAccount ,
        NSP_Address__c objAddress ,
        String copyFrom
        )
    {
        if ( ( copyFrom == NSP_CPQConstants.ACCOUNT ) && ( objAccount != null ) ) {
            newQuote.NSP_Ship_To_Street__c = objAccount.ShippingStreet;
            newQuote.NSP_Ship_To_State__c = objAccount.ShippingState;
            newQuote.NSP_Ship_To_City__c = objAccount.ShippingCity;
            newQuote.NSP_Ship_To_Postal_Code__c = objAccount.ShippingPostalCode;
            newQuote.NSP_Ship_To_Country__c = objAccount.ShippingCountry;
            newQuote.NSP_Ship_To_Name__c = objAccount.Name;
            newQuote.NSP_Customer_Ship_To_Street_2__c = null;
        } else{
            newQuote.NSP_Ship_To_Street__c = objAddress.NSP_Street__c;
            newQuote.NSP_Customer_Ship_To_Street_2__c = objAddress.NSP_Street_Address_2__c;
            newQuote.NSP_Ship_To_State__c = objAddress.NSP_State__c;
            newQuote.NSP_Ship_To_City__c = objAddress.NSP_City__c;
            newQuote.NSP_Ship_To_Postal_Code__c = objAddress.NSP_Postal_Code__c;
            newQuote.NSP_Ship_To_Country__c = objAddress.NSP_Country__c;
            newQuote.NSP_Ship_To_Name__c = objAddress.Name;
        }
    }

    // Method Name : createEnrollmentFee
    // Description : Method to create enrollment fee record with associated opportunity once quote approved
    // Author : Samba Raju       Date : 22/09/2021
    // @param QuoteNewMap Map of New Quote.
    // @param QuoteOldMap Map of Old Quote.
    // @return void
    public void createEnrollmentFee( Map<Id,SBQQ__Quote__c> quoteNewMap , Map<Id,SBQQ__Quote__c> quoteOldMap ) {
        List<NSP_Enrollment_Fee_Payment__c> enrollmentRecs = new List<NSP_Enrollment_Fee_Payment__c>();
        List<Opportunity> optysToupdate = new List<Opportunity>();
        Map<Id,NSP_Enrollment_Fee_Payment__c> existingEnrollments =getExistingEnrollments(quoteNewMap);
        for(SBQQ__Quote__c newQuote : quoteNewMap.values()) {
            SBQQ__Quote__c oldQuote =quoteOldMap.get(newQuote.Id);
            if ( ( newQuote.SBQQ__Opportunity2__c != null )
                && ( newQuote.SBQQ__Type__c == 'New Product' )
                && ( ( newQuote.NSP_Opportunity_Primary_Product__c == 'WX' )
                    || ( newQuote.NSP_Opportunity_Primary_Product__c == 'WA' )
                    || ( newQuote.NSP_Opportunity_Primary_Product__c == 'Contractor Management' )
                    )
                && ( newQuote.SBQQ__Primary__c == true )
                && ( newQuote.SBQQ__Status__c == NSP_CPQConstants.QUOTE_APPROVAL_STATUS_APPROVED )
                && ( ( newQuote.SBQQ__Status__c != oldQuote.SBQQ__Status__c )
                    || ( newQuote.SBQQ__Primary__c != oldQuote.SBQQ__Primary__c )
                    )
                )
            {
                NSP_Enrollment_Fee_Payment__c enrollmentFee = new NSP_Enrollment_Fee_Payment__c();
                if ( existingEnrollments.containskey(newQuote.SBQQ__Opportunity2__c) ) {
                    enrollmentFee.Id=existingEnrollments.get(newQuote.SBQQ__Opportunity2__c).Id;
                    enrollmentFee.NSP_Opportunity__c=newQuote.SBQQ__Opportunity2__c;
                    enrollmentFee.NSP_WX_WA_Enrollment_Fee__c=newQuote.NSP_WX_WA_Enrollment_Fee__c;
                    enrollmentFee.NSP_Docupay_Upfront_fee__c=newQuote.NSP_Docupay_Upfront_fee__c;
                } else {
                    enrollmentFee.NSP_Opportunity__c=newQuote.SBQQ__Opportunity2__c;
                    enrollmentFee.NSP_WX_WA_Enrollment_Fee__c=newQuote.NSP_WX_WA_Enrollment_Fee__c;
                    enrollmentFee.NSP_Docupay_Upfront_fee__c=newQuote.NSP_Docupay_Upfront_fee__c;
                    enrollmentFee.NSP_Payment_Method__c='Card';
                }
                enrollmentRecs.add( enrollmentFee );
            }
            //if set up fee is zero,set non docupay flag on Opportunity to true
            if(newQuote.NSP_WX_WA_Enrollment_Fee__c==0){
                Opportunity opty = new Opportunity(
                    Id=newQuote.SBQQ__Opportunity2__c ,
                    NSP_Non_docupay__c=true
                );
                optysToupdate.add( opty );
            } else if(newQuote.NSP_WX_WA_Enrollment_Fee__c>0 ){
                Opportunity opty;
                if( newQuote.SBQQ__Status__c == NSP_CPQConstants.QUOTE_STATUS_APPROVED
                    && oldQuote != null
                    && newQuote.SBQQ__Status__c != oldQuote.SBQQ__Status__c
                    )
                {
                    if(newQuote.SBQQ__Primary__c == true) {
                        opty =new Opportunity(Id=newQuote.SBQQ__Opportunity2__c,NSP_Non_docupay__c=false);
                    }
                } else if(
                    newQuote.SBQQ__Primary__c == true
                    && oldQuote != null
                    && newQuote.SBQQ__Primary__c != oldQuote.SBQQ__Primary__c
                    )
                {
                    if(newQuote.SBQQ__Status__c == NSP_CPQConstants.QUOTE_STATUS_APPROVED  ) {
                        opty =new Opportunity(Id=newQuote.SBQQ__Opportunity2__c,NSP_Non_docupay__c=false);
                    }
                }
                if ( ( opty != null ) && ( opty.Id != null ) ) {
                    optysToupdate.add( opty );
                }
            }
        }
        if ( !enrollmentRecs.isEmpty() ) {
            try {
                upsert enrollmentRecs;
            } catch ( Exception e ) {
                NSP_QuoteTriggerHelper.handleException( e , 'createEnrollmentFee:upsert' );
            }
        }
        if ( !optysToupdate.isEmpty() ) {
            try {
                update optysToupdate;
            } catch ( Exception e ) {
                NSP_QuoteTriggerHelper.handleException( e , 'createEnrollmentFee:update' );
            }
        }
    }

    //
    // Method Name : getExistingEnrollments
    // Description : Method to retrieve existing enrollements related to opportunities
    // Author : Samba Raju       Date : 10/03/2022
    // @param QuoteNewMap Map of Enrollments.
    // @return void
    //
    public Map<Id,NSP_Enrollment_Fee_Payment__c> getExistingEnrollments( Map<Id,SBQQ__Quote__c> quoteNewMap ) {
        Set<Id> optyIds = new Set<Id>();
        Map<Id,NSP_Enrollment_Fee_Payment__c> enrollmentFeeMap = new Map<Id,NSP_Enrollment_Fee_Payment__c>(); //key as Opportunity and values are Enrollment Fee associated to it
        for ( SBQQ__Quote__c quote : quoteNewMap.values() ) {
            if ( quote.SBQQ__Opportunity2__c != null ) {
                optyIds.add( quote.SBQQ__Opportunity2__c );
            }
        }
        for ( NSP_Enrollment_Fee_Payment__c fee : [
                    SELECT
                        Id ,
                        NSP_Opportunity__c ,
                        NSP_WX_WA_Enrollment_Fee__c ,
                        NSP_Docupay_Upfront_fee__c
                    FROM NSP_Enrollment_Fee_Payment__c
                    WHERE ( NSP_Opportunity__c IN :optyIds )
                ]
            )
        {
            enrollmentFeeMap.put( fee.NSP_Opportunity__c , fee );
        }
        return enrollmentFeeMap;
    }

    //
    // Method Name :  calcTaxOnOpportunity
    // Description : Method to trigger Calculate Tax checkbox on opportunity
    // Author : Rakesh Das       Date : 10/18/2022
    // @param QuoteNewMap Map of New Quote.
    // @param QuoteOldMap Map of Old Quote.
    // @return void
    //
    public void calcTaxOnOpportunity( Map<Id,SBQQ__Quote__c> quoteNewMap , Map<Id,SBQQ__Quote__c> quoteOldMap ) {
        try {
            List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
            for ( SBQQ__Quote__c newQuote : quoteNewMap.values() ) {
                if ( ( newQuote.SBQQ__Primary__c == true )
                    && ( newQuote.NSP_Budgetary_Quote__c == true )
                    && ( newQuote.SBQQ__Status__c == NSP_CPQConstants.QUOTE_STATUS_APPROVED )
                    && ( newQuote.SBQQ__Status__c != quoteOldMap.get( newQuote.Id ).SBQQ__Status__c )
                    )
                {
                    Opportunity op = new Opportunity();
                    op.Id = newQuote.SBQQ__Opportunity2__c;
                    op.AVA_SFCLOUD__Calculate_Tax__c = true;
                    opportunitiesToUpdate.add( op );
                }
            }
            if ( !opportunitiesToUpdate.isEmpty() ) {
                List<Database.SaveResult> updateResults = Database.update( opportunitiesToUpdate , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_QuoteTriggerHelper.class.getName() ,
                    'calcTaxOnOpportunity:update' ,
                    updateResults
                );
            }
        } catch ( Exception e ) {
            NSP_QuoteTriggerHelper.handleException( e , 'calcTaxOnOpportunity' );
        }
    }

    //
    // Method Name : syncQuoteAndOptyPriceBookIfNotSame
    // Description : Method to sync price books on Opty and Quote ()
    // Author : Samba Raju       Date : 12/19/2022
    // @param quotes list;
    // @return void
    //
    public void syncQuoteAndOptyPriceBookIfNotSame( List<SBQQ__Quote__c> quotes ) {
        Set<Id> optyId = new Set<Id>();
        List<Opportunity> optysToUpdate = new List<Opportunity>();
        try {
            for ( SBQQ__Quote__c objQuote : quotes ) {
                if ( String.isNotBlank( objQuote.SBQQ__Opportunity2__c ) ) {
                    optyId.add( objQuote.SBQQ__Opportunity2__c );
                }
            }
            Map<Id,Opportunity> optyMap = new Map<Id,Opportunity>(
                [
                    SELECT Id , Pricebook2Id
                    FROM Opportunity
                    WHERE ( Id IN :optyId )
                ]
            );
            for ( SBQQ__Quote__c objQuote : quotes ) {
                //set Quote Price book on Opty, if both Price books not same
                if ( optyMap.containsKey( objQuote.SBQQ__Opportunity2__c )
                    && ( optyMap.get( objQuote.SBQQ__Opportunity2__c ).Pricebook2Id != objQuote.SBQQ__PriceBook__c )
                    )
                {
                    optysToUpdate.add(
                        new Opportunity(
                            Id=objQuote.SBQQ__Opportunity2__c ,
                            Pricebook2Id=objQuote.SBQQ__PriceBook__c
                        )
                    );
                }
            }
            if ( !optysToUpdate.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( optysToUpdate , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_QuoteTriggerHelper.class.getName() ,
                    'syncQuoteAndOptyPriceBookIfNotSame' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_QuoteTriggerHelper.handleException( e , 'syncQuoteAndOptyPriceBookIfNotSame' );
        }
    }

    //
    // Method Name : unCheckPrimaryQuotesIfExist
    // Description : Method to mark old quotes as non primary (CPQ will take care this OOB but we are calling this before system make it non primary)
    // Author : Samba Raju       Date : 12/20/2022
    // @param quotes list;
    // @return void
    //
    private void unCheckPrimaryQuotesIfExist( List<SBQQ__Quote__c> quotes ) {
        Set<Id> optyIds = new Set<Id>();
        for ( SBQQ__Quote__c objQuote : quotes ) {
            if ( String.isNotBlank( objQuote.SBQQ__Opportunity2__c )
                && ( objQuote.SBQQ__Primary__c == true )
                )
            {
                optyIds.add( objQuote.SBQQ__Opportunity2__c );
            }
        }
        List<SBQQ__Quote__c> primaryQuotes = [
            SELECT Id , Name , SBQQ__Primary__c
            FROM SBQQ__Quote__c
            WHERE (
                ( SBQQ__Opportunity2__c IN :optyIds )
                AND ( SBQQ__Primary__c = true )
            )
        ];
        for ( SBQQ__Quote__c quote : primaryQuotes ) {
            quote.SBQQ__Primary__c = false;
        }
        if ( !primaryQuotes.isEmpty() ) {
            List<Database.SaveResult> results = Database.update( primaryQuotes , false );
            NSP_ErrorLogHandler.logResults(
                NSP_QuoteTriggerHelper.class.getName() ,
                'unCheckPrimaryQuotesIfExist' ,
                results
            );
        }
    }

    //
    // Method Name : validateQuote
    // Description : Method to throw valdiation error if customer has an active or onboarding asset. This will enforce them to amendment
    // Author : Samba Raju       Date : 06/01/2023
    // @param quotes list;
    // @return void
    //
    private void validateQuote(List<SBQQ__Quote__c> quotes){

        Map<String, String> productRecordTypeMap = new Map<String, String>();
        List<String> quoteValidationMdtKeys = new List<String>();

        Map<String,Quote_Validation__mdt> validationRecords = Quote_Validation__mdt.getAll();
        for (Quote_Validation__mdt validationRecord : validationRecords.values()) {
        	productRecordTypeMap.put(validationRecord.Opportunity_Primary_Product__c, validationRecord.Asset_Record_Type__c);
            string uiqueKey = validationRecord.Opportunity_Primary_Product__c+'_'+validationRecord.Opportunity_Primary_Bundle__c+'_'+validationRecord.Asset_Product_Bundle__c +'_'+validationRecord.Asset_Record_Type__c;
            quoteValidationMdtKeys.add(uiqueKey);
    	}
        List<Id> accountIds= new List<Id>();
        for(SBQQ__Quote__c newQuote:quotes){
            if(newQuote.SBQQ__Type__c.equals(NSP_CPQConstants.QUOTE_TYPE_NEW) && productRecordTypeMap.containsKey(newQuote.NSP_Opportunity_Primary_Product__c)){
                accountIds.add(newQuote.SBQQ__Account__c);
            }
        }
        Map<Id, Map<String, Asset>> accountAssetMap = getAccountAssetMap(accountIds, productRecordTypeMap);

        for(SBQQ__Quote__c newQuote:quotes){
            if(newQuote.SBQQ__Type__c.equals(NSP_CPQConstants.QUOTE_TYPE_NEW) &&
               productRecordTypeMap.containsKey(newQuote.NSP_Opportunity_Primary_Product__c) &&
               accountAssetMap.ContainsKey(newQuote.SBQQ__Account__c)
            ){
                Map<String,Asset> recTypeAssetMap = accountAssetMap.get(newQuote.SBQQ__Account__c);
                String assetRecordType = productRecordTypeMap.get(newQuote.NSP_Opportunity_Primary_Product__c);
                if(recTypeAssetMap.containsKey(assetRecordType)){
                    Asset ast = recTypeAssetMap.get(assetRecordType);
                    String key = newQuote.NSP_Opportunity_Primary_Product__c + '_' + newQuote.NSP_Opportunity_Primary_Bundle__c + '_' + ast.NSP_ProductBundle__c + '_' + ast.RecordType.DeveloperName;
                    if(quoteValidationMdtKeys.contains(key)){
                        newQuote.addError(WX_WA_QUOTE_VALIDATION_ERROR);
                    }
                }
            }
        }
    }

    private Map<Id, Map<String, Asset>> getAccountAssetMap(List<Id> accountIds, Map<String, String> productRecordTypeMap) {
        Map<Id, Map<String, Asset>> accountAssetMap = new Map<Id, Map<String, Asset>>();
        if (!accountIds.isEmpty()) {
            for (Asset rec : [SELECT Id, AccountId, NSP_ProductBundle__c, RecordType.DeveloperName, NSP_Product_Line__c
                            FROM Asset
                            WHERE AccountId IN :accountIds
                            AND RecordType.DeveloperName IN :productRecordTypeMap.values()
                            AND Status IN ('Onboarding', 'Active')
                            ORDER BY CreatedDate ASC]) {
                if (!accountAssetMap.containsKey(rec.AccountId)) {
                    accountAssetMap.put(rec.AccountId, new Map<String, Asset>());
                }
                accountAssetMap.get(rec.AccountId).put(rec.RecordType.DeveloperName, rec);
            }
        }
        return accountAssetMap;
    }

    //
    // Description: This method accepts various parameters from which it
    // Passes the opportunity list to createTaskForPrimaryQuote
    // @params: LIST newList , Map quoteOldMap
    // Created as part of 128436
    // Modification History:
    // -------------------------------------------------------------------------------------
    // author           | Date              | Description
    // -------------------------------------------------------------------------------------
    // RAHUL SINGH       11-17-2022          created this new method
    //
    public void updatePrimaryQuote( List<SBQQ__Quote__c> newList , Map<Id, SBQQ__Quote__c> quoteOldMap ) {
        List<Opportunity> opportunitiesWithPrimaryQuote = new List<Opportunity>();
        Set<Id> oppIdSet = new Set<Id>();
        for ( SBQQ__Quote__c newQuote : newList ) {
            SBQQ__Quote__c oldQuote = ( ( quoteOldMap != null ) ? quoteOldMap.get( newQuote.Id ) : null );
            if ( ( ( newQuote.SBQQ__Primary__c == true ) && Trigger.isInsert )
                || ( Trigger.isUpdate && ( newQuote.SBQQ__Primary__c != oldQuote.SBQQ__Primary__c ) && ( newQuote.SBQQ__Primary__c == true ) )
                )
            {
                oppIdSet.add( newQuote.SBQQ__Opportunity2__c );
            }
        }
        if ( !oppIdSet.isEmpty() ) {
            opportunitiesWithPrimaryQuote = [
                SELECT Id , OwnerId , NSP_PrimaryProduct__c , NSP_Client_For_Life__c , CloseDate
                FROM Opportunity
                WHERE ( Id IN :oppIdSet )
            ];
        }
        if ( !opportunitiesWithPrimaryQuote.isEmpty() ) {
             NSP_EventAndTaskHelperFunctions.createTaskForPrimaryQuote( opportunitiesWithPrimaryQuote );
        }
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_QuoteTriggerHelper.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_QuoteTriggerHelper.class.getName() ,
            methodName ,
            e
        );
    }

}
//