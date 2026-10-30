/* **************************************************************************************************
Component Name :  NSP_CreateQuote class
Version              :  1.0
Created Date         :  August 2021
Function             :  This class copies values from Opportunity in context to new Quote under creation
					 :  The Fields are mapped in metadata NSP_Opportunity_To_Quote_Data_Map__mdt
Story                :
Modification Log     :
*	CPQ Team           August 2021          First Iteration
*
***************************************************************************************************
*/

public class NSP_CreateQuote {
    // test w/ NSP_CreateQuoteTest (80%)

     /**
    * @param  opportunity record id
    * @return      ResponseWrapper
    * @Author Utpal Utkalit
    *
    */

    @AuraEnabled
    public static ResponseWrapper validateQuoteCreationfromOpp(String opportunityId){

        Opportunity opp = null;
        Map<String, object> quoteRecordFieldValues = new Map<String, object>();
        Map<String,NSP_Opportunity_To_Quote_Data_Map__mdt> primaryProductToRecordTypeMap = new Map<String,NSP_Opportunity_To_Quote_Data_Map__mdt>();
        set<String> partnerNames = new set<String>();
        ResponseWrapper responseWrapper = new ResponseWrapper();
        try {
            List<Opportunity> opportunities =[Select Id,NSP_PrimaryProduct__c,NSP_Client_For_Life__c,StageName,Type FROM Opportunity WHERE Id =: opportunityId LIMIT 1];
            if(!opportunities.isEmpty()){
                opp = opportunities[0];
            }
            if(opp.StageName == NSP_SalesConstants.DISCOVERY_STAGE){
                responseWrapper.isSuccess = false;
                responseWrapper.errorMessage=System.Label.NSP_MoveOpportunityToAnalysisiStage;
                return responseWrapper;
            }
            //Validation for WO Opportunity where creating a Quote is not allowed
            /*if(opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WO)
            {
                responseWrapper.isSuccess = false;
                responseWrapper.errorMessage=System.label.NSP_NoQuoteForWOProducts;
                return responseWrapper;
            }*/

            // Validation on Opportunity Primary Product
            if(String.isBlank(opp.NSP_PrimaryProduct__c)){
                responseWrapper.isSuccess = false;
                responseWrapper.errorMessage=System.Label.NSP_Primary_Product_Required_on_Create_Quote;
                return responseWrapper;
            }

            // 12/28/22 NL Validation on Opportunity Primary Product - Performance Management only available on Type Renewal
            if(opp.NSP_PrimaryProduct__c == 'Performance Management' && opp.Type == 'New Product' && opp.NSP_Client_For_Life__c != 'WO/WS'){
                responseWrapper.isSuccess = false;
                responseWrapper.errorMessage=System.Label.NSP_Opp_Performance_Management_Only_Available_For_Renewal;
                return responseWrapper;
            }

            // 12/28/22 NL Validation on Opportunity Primary Product - WO/WS No Quoting Available
            if(opp.NSP_PrimaryProduct__c == 'WO' || opp.NSP_PrimaryProduct__c == 'WS'){
                responseWrapper.isSuccess = false;
                responseWrapper.errorMessage=System.Label.NSP_Opp_No_Quoting_for_WO_WS;
                return responseWrapper;
            }

            // Validation on Opportunity Client for Life
            if(String.isBlank(opp.NSP_Client_For_Life__c)){
                responseWrapper.isSuccess = false;
                responseWrapper.errorMessage=System.Label.NSP_Client_For_Life_to_Create_Quote;
                return responseWrapper;
            }

            // Validation on quote object create access
            if(!Schema.sObjectType.SBQQ__Quote__c.isCreateable()){
                responseWrapper.isSuccess = false;
                responseWrapper.errorMessage=System.Label.NSP_Cannot_Create_Quote;
                return responseWrapper;
            }

            List<NSP_OpportunityQuoteMapping__mdt> opptyQuoteMappingMdt = new List<NSP_OpportunityQuoteMapping__mdt>();
            opptyQuoteMappingMdt = [SELECT Id, NSP_SourceField__r.QualifiedApiName, NSP_SourceObject__r.QualifiedApiName,
                                    NSP_TargetField__r.QualifiedApiName,NSP_TargetObject__r.QualifiedApiName FROM NSP_OpportunityQuoteMapping__mdt WHERE NSP_TargetObject__c!=NULL LIMIT 50000];

            //generate opportunity query
            String opportunityQuery = constructOpportunityQuery(opptyQuoteMappingMdt,opp.Id);
            Opportunity sourceOpportunityRecord = Database.query(opportunityQuery); //get the first opportunity record from the list
            SBQQ__Quote__c quoteRecord = getOpportunityDataIntoQuote(opptyQuoteMappingMdt, sourceOpportunityRecord);

           // get metadata for quote default values
            for(NSP_Opportunity_To_Quote_Data_Map__mdt pc : NSP_Opportunity_To_Quote_Data_Map__mdt.getAll().values() ) {
                String partnerCode = string.isnotBlank(pc.NSP_Partner__c) ? pc.NSP_Partner__c : NSP_CPQConstants.NONE_VALUE;
                String uniqKey = pc.NSP_Opportunity_Primary_Product__c+'_'+pc.NSP_Client_for_Life__c+'_'+partnerCode;
                primaryProductToRecordTypeMap.put(uniqKey,pc);
            }

            // get partner list
            for(NSP_Partner_Configurations__mdt partc : NSP_Partner_Configurations__mdt.getAll().values()) {
                if(partc.NSP_Use_For_Partner_Key_Internal__c) {
                    partnerNames.add(partc.NSP_Partner_Unique_Code__c);
                }
            }
            // generating quotekey to fetch metadata for quote create automation
            string quoteKey = '';
            if(String.isNotBlank(sourceOpportunityRecord.NSP_Partner_Name__c) && partnerNames.contains(sourceOpportunityRecord.NSP_Partner_Name__c)){
                quoteKey = sourceOpportunityRecord.NSP_PrimaryProduct__c+'_'+sourceOpportunityRecord.NSP_Client_For_Life__c+'_'+sourceOpportunityRecord.NSP_Partner_Name__c;
            }
            else{
                quoteKey = sourceOpportunityRecord.NSP_PrimaryProduct__c+'_'+sourceOpportunityRecord.NSP_Client_For_Life__c+'_'+NSP_CPQConstants.NONE_VALUE;
            }

            // set quote default values
            if(sourceOpportunityRecord != null && String.isNotBlank(quoteKey) && primaryProductToRecordTypeMap.containsKey(quoteKey)){
                NSP_Opportunity_To_Quote_Data_Map__mdt qconfig = primaryProductToRecordTypeMap.get(quoteKey);
                Id recordTypeIdstr = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName().get(qconfig.NSP_Default_Recordtype__c).getRecordTypeId();
                quoteRecordFieldValues.put('NSP_Pricing_Model__c', qconfig.NSP_Pricing_Model__c);
                quoteRecordFieldValues.put('NSP_Product_Type__c',qconfig.NSP_Product_Type__c);
                quoteRecordFieldValues.put('RecordTypeId',recordTypeIdstr);
                quoteRecordFieldValues.put('NSP_Opportunity_Type__c',sourceOpportunityRecord.Type);
                if(sourceOpportunityRecord.Type == NSP_CPQConstants.OPPORTUNITY_TYPE_EXISTING_BUSINESS) {
                    quoteRecordFieldValues.put(NSP_CPQConstants.SBQQ_TYPE_FIELD_API,NSP_CPQConstants.QUOTE_TYPE_AMENDMENT);
                }
                else if (sourceOpportunityRecord.Type == NSP_CPQConstants.QUOTE_TYPE_RENEWAL) {
                    quoteRecordFieldValues.put(NSP_CPQConstants.SBQQ_TYPE_FIELD_API,NSP_CPQConstants.QUOTE_TYPE_RENEWAL);
                }
                else if (sourceOpportunityRecord.Type == NSP_CPQConstants.QUOTE_TYPE_TERMINATION) {
                    quoteRecordFieldValues.put(NSP_CPQConstants.SBQQ_TYPE_FIELD_API,NSP_CPQConstants.QUOTE_TYPE_TERMINATION);
                }
                else {
                    quoteRecordFieldValues.put(NSP_CPQConstants.SBQQ_TYPE_FIELD_API,NSP_CPQConstants.OPPORTUNITY_TYPE_NEW_BUSINESS);
                }

            }
            //STY-01705 - Marking Quote as Primary
            if(sourceOpportunityRecord != null && String.isBlank(sourceOpportunityRecord.SBQQ__PrimaryQuote__c)
               && sourceOpportunityRecord.NSP_PrimaryProduct__c != NSP_SalesConstants.WO && sourceOpportunityRecord.NSP_PrimaryProduct__c != NSP_SalesConstants.WS){
                quoteRecordFieldValues.put('SBQQ__Primary__c',true);
            }

            //create QuoteField and QuoteFieldValue Map to initialise values on quote record
            responseWrapper.isSuccess = true;
            for(NSP_OpportunityQuoteMapping__mdt oppQuoteMapping : opptyQuoteMappingMdt){
                if(oppQuoteMapping.NSP_TargetField__r.QualifiedApiName != null){
                    quoteRecordFieldValues.put(oppQuoteMapping.NSP_TargetField__r.QualifiedApiName, quoteRecord.get(oppQuoteMapping.NSP_TargetField__r.QualifiedApiName));
                }

            }
            responseWrapper.quoteRecordValues = quoteRecordFieldValues;


        }
        catch(Exception ex){
            responseWrapper.errorMessage = JSON.serialize(ex.getMessage());
            responseWrapper.isSuccess = false;
            NSP_CustomException.LogException(ex);
            throw new AuraHandledException(ex.getMessage());
        }
        return responseWrapper;
    }


     /**
    * It will fetch Opportunity Data.
    * @param  Opportunity Quote Mapping,Opportunity record
    * @return      Quote
    * @Author Utpal Utkalit
    * @Since Nov 18, 2020
    */
    public static SBQQ__Quote__c getOpportunityDataIntoQuote(List<NSP_OpportunityQuoteMapping__mdt> opportunityQuoteMappingList, Opportunity opp){
        SBQQ__Quote__c quote=new SBQQ__Quote__c();
        //looping through metadata reocrds to fetch the field api names
        for(NSP_OpportunityQuoteMapping__mdt oppQuoteMapping : opportunityQuoteMappingList){
            if(String.isNotBlank(oppQuoteMapping.NSP_TargetField__r.QualifiedApiName) && String.isNotBlank(oppQuoteMapping.NSP_SourceField__r.QualifiedApiName)){
                quote.put(oppQuoteMapping.NSP_TargetField__r.QualifiedApiName, opp.get(oppQuoteMapping.NSP_SourceField__r.QualifiedApiName));
            }
        }
        return quote;
    }

        /**
    * It will construct Quote Query.
    * @param  Quote Contract Mapping,quote record id
    * @return      String
    * @Author Utpal Utkalit
    * @Since August 2021
    */
    public static String constructOpportunityQuery(List<NSP_OpportunityQuoteMapping__mdt> opportunityQuoteMappingList,  Id recordId){
        Set<String> fieldsToQuerySet = new Set<String>();
        for(NSP_OpportunityQuoteMapping__mdt opportunityQuoteMapping : opportunityQuoteMappingList){
            if(String.isNotBlank(opportunityQuoteMapping.NSP_SourceField__r.QualifiedApiName)){
                fieldsToQuerySet.add(opportunityQuoteMapping.NSP_SourceField__r.QualifiedApiName);
            }
        }
        List<String> fieldsToQueryList = new List<String>(fieldsToQuerySet);
        // fields need to set the default value and record type on quote
        fieldsToQueryList.add('NSP_Partner_Name__c');
        fieldsToQueryList.add('Type');
        fieldsToQueryList.add('SBQQ__PrimaryQuote__c');
        //fieldsToQueryList.add('NSP_PrimaryProduct__c');
        String objectToQuery = '';
        for(NSP_OpportunityQuoteMapping__mdt opportunityQuoteMapping: opportunityQuoteMappingList){
            if(opportunityQuoteMapping.NSP_SourceObject__c != null){
                objectToQuery = opportunityQuoteMapping.NSP_SourceObject__r.QualifiedApiName;
                break;
            }
        }
        Map<String, String> filterMap = new Map<String,String>{ 'Id' => recordId};
            String query = getQuery(fieldsToQueryList,objectToQuery,filterMap,null);
        return query;
    }
    /**
    * It will form the query.
    * @param  fieldsToQueryList,objectToQuery,filterMap,range
    * @return      String
    * @Author Utpal Utkalit
    * @Since Nov 18, 2020
    */
    public static String getQuery(List<String> fieldsToQueryList, String objectToQuery, Map<String, String> filterMap, Integer range){
        //query construction
        String fieldsToQuery = String.join(fieldsToQueryList, ',');
        String query = 'SELECT '+fieldsToQuery+' FROM '+ objectToQuery;
        String filter = '';
        if(!filterMap.isEmpty()){
            for(String key : filterMap.keySet()){
                filter += String.escapeSingleQuotes(key) + '= \'' + String.escapeSingleQuotes(filterMap.get(key)) + '\' ';
            }
        }
        if(String.isNotBlank(filter)){
            query += ' WHERE ' + filter;
        }
        if(range != null){
            query += ' LIMIT ' + range;
        }
        return query;
    }
    // Response Wrapper Class
    public class ResponseWrapper{
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Map<String, object> quoteRecordValues = new Map<String, object>();
        @AuraEnabled public SBQQ__Quote__c quote{get;set;}
        @AuraEnabled public boolean isSuccess = false;
    }


    }