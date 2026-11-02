public without sharing class NSP_CreateReferralLead {
    // test w/ NSP_CreateReferralLeadTest (84%)

    private static final String ErrorOccured=' Error occured: ';
    private static final String ReferralTask='Referral_Task';
    private static final String objectName='Lead';
    private static final string Customerpotential = 'NSP_Howdoyouknowthepotentialcustomer__c';
    private static final string Industry ='Industry';
    private static final string Productinterted ='NSP_Product_Interest__c';

    // Fetches the owner of the account record
    // @param LeadObject String json holds the values in the account object.
    // @return String
    @AuraEnabled
    public static taskClass getAccountOwner( String recordID ) {
        taskClass taskObject = new taskClass();
        Account accountRecord = null;
        try{
            List<Account> accounts = [SELECT ownerid FROM Account WHERE id = :recordID];

            if(!accounts.isEmpty()){
                accountRecord = accounts[0];
            }
            taskObject.recordOwnerId = accountRecord.ownerid;
            taskObject.taskrecordtypeId =Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get(ReferralTask).getRecordTypeId();
            taskReferralRecord(taskObject.taskrecordtypeId);
            return taskObject ;
        }catch(Exception Ex){
            throw new AuraHandledException(ErrorOccured + ex.getMessage());
        }
    }

    // Creates referral Lead from the information that is provided on the site by the user
    // @param LeadObject String json holds the values in the account object.
    // @return String
    @AuraEnabled
    public static String createReferralLead( String leadObject ) {
        //Response String
        String response;

        try{
            //Deserialising the Lead object
            Lead leadRecord =(Lead)JSON.deserialize(leadObject,Lead.class);

            //set the account reocord type as Partner
            leadRecord.Recordtypeid = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Referral').getRecordTypeId();
            //By passing the duplicate rules
            Database.DMLOptions dbDML = new Database.DMLOptions();
            dbDML.DuplicateRuleHeader.allowSave = true;
            dbDML.DuplicateRuleHeader.runAsCurrentUser = true;

            //Inseting the leads
            Database.insert(leadRecord, dbDML);

            //Setting response as success
            response = NSP_SalesConstants.successResponse;
        }catch(Exception ex){
            response = ex.getMessage();
            throw new AuraHandledException(ex.getMessage());
        }

        return response;
    }

    // Method to get picklist values of the picklist fields for an object
    // @return picklistValueClass
    @AuraEnabled
    public static picklistValueClass returnAllPickListValues() {


        //Instantiating the wrapper class
        picklistValueClass picklistValueClassObject = new picklistValueClass();
        try{
            //Setting the sobject
            //Passing the sobject name and field API name
            picklistValueClassObject.industry = NSP_CreatePartnerAccount.getPiklistValues(objectName,Industry);
            picklistValueClassObject.potentialCustomer = NSP_CreatePartnerAccount.getPiklistValues(objectName,Customerpotential);
        }Catch(Exception Ex){
            throw new AuraHandledException(ex.getMessage());
        }
        return picklistValueClassObject;

    }

    // Method to get dependent picklist values
    // @param objDetail sObject  defines the sobject on which the field is present.
    // @return String  contrfieldApiName controlling field name
    // @return String  depfieldApiName controldependent field name
    @AuraEnabled
    public static Map<String,List<String>> getDependentMap(
        SObject objDetail ,
        String contrfieldApiName ,
        String depfieldApiName
        )
    {
        try{
        //Controlling field name to lower case
        String controllingField = contrfieldApiName.toLowerCase();
        //dependent field name to lower case
        String dependentField = depfieldApiName.toLowerCase();

        //Map to store the dependent picklist value
        Map<String,List<String>> objResults = new Map<String,List<String>>();

        //Fetching the sobject type
        Schema.sObjectType objType = objDetail.getSObjectType();
        if (objType==null){
            return objResults;
        }

        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();

        if (!objFieldMap.containsKey(controllingField) || !objFieldMap.containsKey(dependentField)){
            return objResults;
        }

        //get dependent field
        Schema.SObjectField theField = objFieldMap.get(dependentField);
        //get controlling field
        Schema.SObjectField ctrlField = objFieldMap.get(controllingField);
        //Controlling field picklist values
        List<Schema.PicklistEntry> contrEntries = ctrlField.getDescribe().getPicklistValues();
        //Dependent field picklist values
        List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(theField.getDescribe().getPicklistValues());
        List<String> controllingValues = new List<String>();

        //Fetching the lables of the controlling field
        for (Schema.PicklistEntry ple : contrEntries) {
            String label = ple.getLabel();
            objResults.put(label, new List<String>());
            controllingValues.add(label);
        }

        //Fetching the lables of the dependent field
        for (PicklistEntryWrapper plew : depEntries) {
            String label = plew.label;
            String validForBits = base64ToBits(plew.validFor);
            for (Integer counter = 0; counter < validForBits.length(); counter++) {
                String bit = validForBits.mid(counter, 1);
                if (bit == '1') {
                    //system.debug('hello'+objResults.get(controllingValues.get(i)));
                    objResults.get(controllingValues.get(counter)).add(label);
                }
            }
        }

        return objResults;
        }
            catch (Exception ex) {
            throw new AuraHandledException(ErrorOccured +ex.getMessage());
        }
    }

    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }

    public static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) {
            return '';
        }

        String validForBits = '';

        for (Integer counter = 0; counter < validFor.length(); counter++) {
            String thisChar = validFor.mid(counter, 1);
            Integer val = base64Chars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }

        return validForBits;
    }

    private static final String base64Chars = '' +
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
        'abcdefghijklmnopqrstuvwxyz' +
        '0123456789+/';


    private static List<PicklistEntryWrapper> wrapPicklistEntries( List<Schema.PicklistEntry> PLEs ) {
        return (List<PicklistEntryWrapper>)
            JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
    }

    public class PicklistEntryWrapper {
        public String active {get;set;}
        public String defaultValue {get;set;}
        public String label {get;set;}
        public String value {get;set;}
        public String validFor {get;set;}
        public PicklistEntryWrapper(){
        }
    }

    public  class picklistValueClass {
        @AuraEnabled public List<String> industry;
        @AuraEnabled public  List<String> potentialCustomer;
        @AuraEnabled public   List<String> productofinterest;
    }

    public  class taskClass {
        @AuraEnabled public String recordOwnerId;
        @AuraEnabled public  String taskrecordtypeId;
    }

    // @MethodName: taskReferralRecord
    // @Description: Created to provide permission set on click of UPSELL button
    // @return void
    @AuraEnabled
    public static void taskReferralRecord( String recordTypeId ) {
        PermissionSet permSet = null;
        List<PermissionSet> permissionSets = [SELECT Id, Name, Label FROM PermissionSet WHERE Name = 'NSP_Task_Referral_Task'];
        if (!permissionSets.isEmpty()){
            permSet = permissionSets[0];
        }
        Schema.DescribeSObjectResult R = Task.SObjectType.getDescribe();
        List<Schema.RecordTypeInfo> recrdType = R.getRecordTypeInfos();
        Boolean hasRecordTypePermission = false;
        //Permission to the record type is not assigned but need to create a Referral Task Record -->Upsell Button
        for (Schema.RecordTypeInfo rTI : recrdType) {
            if (!rTI.isAvailable() && rTI.getRecordTypeId() == recordTypeId){
                hasRecordTypePermission = true;
            }
        }
        if(hasRecordTypePermission){
            List<PermissionSetAssignment> permissionSetList = new List<PermissionSetAssignment>();
            Map<Id,User> users = new Map<Id,user>([SELECT id,profile.Name from user where id=:userInfo.getUserId()]);
            if(users.containsKey(userInfo.getUserId())){
                PermissionSetAssignment psa = new PermissionSetAssignment (PermissionSetId = permSet.Id, AssigneeId = userInfo.getUserId());
                permissionSetList.add(psa);
            }
            //assignment of Permission set to the user
            try{
                if(!permissionSetList.isEmpty()){
                    insert permissionSetList;
                }
            }catch (Exception ex) {
                NSP_ErrorLogHandler.logSaveException('NSP_CaseTriggerHelper', 'taskReferralRecord', ex.getMessage());
            }
        }
    }

    // @MethodName: deletePermissionSet
    // @Description: Create to remove permission set on click of UPSELL button
    // @return void
    @AuraEnabled
    public static void deletePermissionSet() {
       NSP_TaskTriggerHelper.removePermissionSet();
    }

}
//
