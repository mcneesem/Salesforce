/**
* @description  :  Controller class for all Account Profile related methods
* @date 10/28/2022
* Author : Nishkarsh Manav
* Name : NSP_AccountProfileController
*/
public with sharing class NSP_AccountProfileController {
    // test w/ NSP_AccountProfileController (90%)

    // Only for testing purpose
    @TestVisible
    private static Map<String,Schema.SObjectField> ACC_FIELDS = Schema.SObjectType.Account.fields.getMap();

    /**
     * @description - Returns all the relevant data of given account.
     * @param {String} - accId - Id of the account
     * @return Map<String, Map<String,String>> - Map wih field API name as key and all details in value.
     */
    private static final String TYPE = 'type';
    private static final String CHECKBOX = 'checkbox';
    private static final String TRUE_VALUE = 'TRUE';
    private static final String FALSE_VALUE = 'False';
    private static final String IS_CHECKED = 'isChecked';

    @AuraEnabled(cacheable=true)
    public static Map<String, Map<String,String>> getAccountProfileRelatedInfo(String accId){
        if(String.isBlank(accId)){
            return new Map<String, Map<String,String>>();
        }

        try {
            Map<String, Map<String,String>> fieldValues = new Map<String, Map<String,String>>();

            populateAccountFields(accId, fieldValues);
            populateAccGroupMember(accId, fieldValues);
            populateAccTeamMember(accId, fieldValues);

            Asset woAssetObj = getActiveWoAssetByAccId(accId);
            if(woAssetObj != null){
                populateAssetFields(woAssetObj, fieldValues);
                populateSubClientFields(woAssetObj.Id, fieldValues);
            }

            Asset retAssetObj =  getRTAssetByAccId(accId);

            if(retAssetObj != null){
                populateRTAssetFields(retAssetObj, fieldValues);
                populateEligibilityFields(retAssetObj.Id, fieldValues);
                populateRetEducationField(retAssetObj.Id, fieldValues);
                populateSaaSActivityField(retAssetObj.Id, fieldValues);
            }

            Asset insuranceAsset = getRTInsuranceAccId(accId);
            if(insuranceAsset != null){
                populateInsuranceFields(insuranceAsset, fieldValues);
            }

            return fieldValues;
        } catch (Exception excep) {
            throw new AuraHandledException(excep.getMessage());
        }
    }

    /**
     * @description - Returns a set of API names of fields that have been updated recently.
     * @param {String} - accId - Id of the account
     * @return List<String> - List of recently updated field names.
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getRecentlyUpdatedFields(String accId){
        try{
        Integer noOfDays = Integer.valueOf(System.Label.NSP_Ap_Changes_Tracking_Duration_In_Days);
        Date lastDate = System.today() - noOfDays;
        Set<String> fieldNames = new Set<String>();
        for (AccountHistory accHistory : [SELECT Id, Field FROM AccountHistory WHERE AccountId = :accId AND CreatedDate > :lastDate WITH SECURITY_ENFORCED]) {
            fieldNames.add(accHistory.Field);            
        }

        return new List<String>(fieldNames);
        }catch (Exception ex) {
            throw NSP_Utilities.getAuraException(ex);
        }
    }
    
    private static void populateAccountFields(String accId, Map<String, Map<String,String>> fieldValues){
        Account acc = getAccountById(accId);
        fieldValues.put('Website', getLabelValueMap('Client Website', acc.Website));
        fieldValues.put('TickerSymbol', getLabelValueMap('Ticker Symbol', acc.TickerSymbol));
        fieldValues.put('NSP_Year_Established__c', getLabelValueMap('Year Established', acc.NSP_Year_Established__c));
    }

    private static void populateAssetFields(Asset assetObj, Map<String, Map<String,String>> fieldValues){
        fieldValues.put('NSP_Business_Type__c', getLabelValueMapByField('NSP_Business_Type__c', assetObj.NSP_Business_Type__c));
        fieldValues.put('NSP_NAISC__c', getLabelValueMapByField('NSP_NAISC__c', assetObj.NSP_NAICS_Code__c));
        fieldValues.put('NSP_SIC__c', getLabelValueMapByField('NSP_SIC__c', assetObj.NSP_SIC_Code__c));
        fieldValues.put('NSP_States_Employees_work_in__c', getLabelValueMapByField('NSP_States_Employees_work_in__c', assetObj.NSP_States_of_Operations__c));
        if(String.isNotBlank(assetObj.NSP_Legal_Entity_Description__c)){
            Map<String, String> corporationType = getLabelValueMap('What type of corporation is it? (C Corp, S Corp, etc)',assetObj.NSP_Legal_Entity_Description__c);
            fieldValues.put('NSP_What_type_of_corporation_is_it__c', corporationType);
        }
        fieldValues.put('NSP_Client_AIMS__c', getLabelValueMapByField('NSP_Client_AIMS__c', assetObj.NSP_Client__c));
        fieldValues.put('NSP_Handbook_Status__c', getLabelValueMapByField('NSP_Handbook_Status__c', assetObj.NSP_Handbook_Status__c));
        
        //Make the fields read only if the AIMS status is other than 'Terminated'
        if(assetObj.NSP_Account_Status__c != 'Terminated'){
            //Show Union employee field as checkbox on UI
            Map<String, String> unionEmpValueMap = getLabelValueMapByField('NSP_Union_Employees__c', assetObj.NSP_Union_Employees__c);
            unionEmpValueMap.put(TYPE, CHECKBOX);
            String valueChekbox = assetObj.NSP_Union_Employees__c ? TRUE_VALUE : FALSE_VALUE;
            unionEmpValueMap.put(IS_CHECKED,valueChekbox);
            fieldValues.put('NSP_Union_Employees__c', unionEmpValueMap);

            // Show Government contractor field as checkbox on UI
            Map<String,String> govtContractorMap = getLabelValueMapByField('NSP_Government_Contractor__c', assetObj.NSP_Government_Contractor__c);
            govtContractorMap.put(TYPE, CHECKBOX);
            valueChekbox = assetObj.NSP_Government_Contractor__c ? TRUE_VALUE : FALSE_VALUE;
            govtContractorMap.put(IS_CHECKED,valueChekbox);
            fieldValues.put('NSP_Government_Contractor__c', govtContractorMap);

            // Show Pre employment drug testing field as checkbox on UI
            Map<String,String> drugTestingMap = getLabelValueMapByField('NSP_Pre_employment_drug_testing__c', assetObj.NSP_Pre_Emp_Drug_Testing__c);
            drugTestingMap.put(TYPE, CHECKBOX);
            valueChekbox = assetObj.NSP_Pre_Emp_Drug_Testing__c ? TRUE_VALUE : FALSE_VALUE;
            drugTestingMap.put(IS_CHECKED,valueChekbox);
            fieldValues.put('NSP_Pre_employment_drug_testing__c', drugTestingMap);

            // Show IES e Verify Client field as checkbox on UI
            Map<String,String> eVerifyMap = getLabelValueMap('Does the client use IES E-Verify?',assetObj.NSP_IES_e_Verify_Client__c);
            eVerifyMap.put(TYPE, CHECKBOX);
            valueChekbox = assetObj.NSP_IES_e_Verify_Client__c ? TRUE_VALUE : FALSE_VALUE; 
            eVerifyMap.put(IS_CHECKED,valueChekbox);
            fieldValues.put('NSP_IES_e_Verify_Client__c', eVerifyMap);
        }
    }

    private static Map<String, String> getLabelValueMapByField(String fieldName, Object value){
        String label = ACC_FIELDS.get(fieldName).getDescribe().getLabel();

        return getLabelValueMap(label, value);
    }

    private static Map<String, String> getLabelValueMap(String label, Object value){
        return new Map<String, String>{
            'value' => String.valueOf(value),
            'label' => label
        };
    }

    private static Account getAccountById(String accId){
        List<String> accFields = new List<String>{
            'Id', 'Website', 'TickerSymbol',
            'NSP_Year_Established__c'
        };

        return (Account) new NSP_sObjectSelector('Account', accFields).selectById(accId);
    }

    private static Asset getActiveWoAssetByAccId(String accId){
        List<String> assetFields = new List<String>{ 
            'Id', 'NSP_Account_Status__c',
            'NSP_Business_Type__c', 'NSP_NAICS_Code__c', 
            'NSP_SIC_Code__c', 'NSP_Union_Employees__c', 
            'NSP_Government_Contractor__c',
            'NSP_States_of_Operations__c',
            'NSP_IES_e_Verify_Client__c',
            'NSP_Legal_Entity_Description__c',
            'NSP_Client__c',
            'NSP_Handbook_Status__c',
            'NSP_Pre_Emp_Drug_Testing__c'
        };

        String query = new NSP_QueryBuilder('Asset', assetFields)
                .addFilter('RecordType.DeveloperName', NSP_ServiceConstants.WO_ASSET_RECORDTYPE)
                .addFilter('Status','Active')
                .addFilter('AccountId', accId).addLimit(1).build();

        List<Asset> assets = (List<Asset>) Database.query(query);

        return assets.isEmpty() ? null : assets[0];
    }

    private static Asset getRTAssetByAccId(String accId){
        List<String> rtFields = new List<String>{
            'Id',
            'NSP_RET_Product_Category__c',
            'NSP_ORK_Plan_Vendor__c'
        };
        List<String> recordTypes = new List<String>{NSP_ServiceConstants.RET_CHOICE_ASSET_RECORDTYPE, NSP_ServiceConstants.RET_WO_ASSET_RECORDTYPE};
        String query = new NSP_QueryBuilder('Asset', rtFields)
            .addFilter('RecordType.DeveloperName', recordTypes ,NSP_QueryBuilder.Operator.INCLUDES)
            .addFilter('Status','Active')
            .addFilter('AccountId', accId).addLimit(1).build();

        List<Asset> assets = (List<Asset>) Database.query(query);

        return assets.isEmpty() ? null : assets[0];
    }

    private static Asset getRTInsuranceAccId(String accId){
        List<String> rtFields = new List<String>{
            'Id',
            'Name'
        };
        String query = new NSP_QueryBuilder('Asset', rtFields)
            .addFilter('RecordType.DeveloperName', NSP_ServiceConstants.INSURANCE_SERVICES_RECORDTYPE ,NSP_QueryBuilder.Operator.INCLUDES)
            .addFilter('Status','Active')
            .addFilter('AccountId', accId).addLimit(1).build();

        List<Asset> assets = (List<Asset>) Database.query(query);

        return assets.isEmpty() ? null : assets[0];
    }

    private static NSP_Plan_SubPlan__c getRETSubPlanId(String assetId){
        List<String> rtClientFields = new List<String>{
            'Id',
            'NSP_Current_Subplan__c',
            'NSP_Plan_Subplan_Relationship__c',
            'NSP_Asset__c'
        };
        String query = new NSP_QueryBuilder('NSP_Client_Sub_Plan_History__c', rtClientFields)
            .addFilter('NSP_Asset__c', assetId)
            .addFilter('NSP_Current_Subplan__c', true)
            .addLimit(1).build();
        List<NSP_Client_Sub_Plan_History__c> retClientSubPlanId = (List<NSP_Client_Sub_Plan_History__c>) Database.query(query);
        if(retClientSubPlanId.isEmpty()){
            return null;
        }
            List<String> rtSubPlanFields = new List<String>{
            'Name',
            'NSP_Subplan_Lead_Parent__c',
            'NSP_Plan_Type__c'
        };
        query = new NSP_QueryBuilder('NSP_Plan_SubPlan__c', rtSubPlanFields)
                    .addFilter('Id', retClientSubPlanId[0].NSP_Plan_Subplan_Relationship__c)
                    .addLimit(1).build();
        List<NSP_Plan_SubPlan__c> retSubPlanId = (List<NSP_Plan_SubPlan__c>) Database.query(query);
        return retSubPlanId.isEmpty() ? null: retSubPlanId[0];
    }

    private static void populateRTAssetFields(Asset assetObj, Map<String, Map<String,String>> fieldValues){
        fieldValues.put('NSP_Insperity_Plan_Custom_Plan_or_ORK__c', getLabelValueMapByField('NSP_Insperity_Plan_Custom_Plan_or_ORK__c', assetObj.NSP_RET_Product_Category__c));
        fieldValues.put('NSP_If_ORK_who_is_their_administrator__c', getLabelValueMapByField('NSP_If_ORK_who_is_their_administrator__c', assetObj.NSP_ORK_Plan_Vendor__c));
        NSP_Plan_SubPlan__c subPlan = getRETSubPlanId(assetObj.Id);
        if(subPlan!=null && subPlan.NSP_Plan_Type__c!=null){
            String assetPlanTypeVal = subPlan.NSP_Plan_Type__c.Contains('Safe Harbor') ? 'Yes' : 'No';
            fieldValues.put('NSP_Is_it_a_Safe_Harbor_plan__c', getLabelValueMapByField('NSP_Is_it_a_Safe_Harbor_plan__c', assetPlanTypeVal));
        }

    }

    private static void populateInsuranceFields(Asset assetObj, Map<String, Map<String,String>> fieldValues){
        Map<String, String> insuranceService = getLabelValueMap('Do they have any policies through Insperity Insurance Services?', 'Yes');
        insuranceService.put(TYPE, 'Picklist');
        insuranceService.put('isDisable', 'FALSE');
        fieldValues.put('NSP_Do_they_hv_any_policies_thrgh_Insty__c', insuranceService);
    }

    private static void populateSubClientFields(String assetId, Map<String, Map<String,String>> fieldValues){
        NSP_Sub_Client__c subClientObject = getSubClientByAssetId(assetId);

        if(subClientObject != null){
            fieldValues.put('NSP_Full_time_Margin_Part_time_Margin__c', getLabelValueMapByField('NSP_Full_time_Margin_Part_time_Margin__c', subClientObject.NSP_Margin__c +'/'+subClientObject.NSP_Part_Time_Margin__c));
            fieldValues.put('NSP_Full_time_Reserve_Part_time_Reserve__c', getLabelValueMapByField('NSP_Full_time_Reserve_Part_time_Reserve__c', subClientObject.NSP_Reserve__c +'/'+ subClientObject.NSP_Part_Time_Reserve__c));
            fieldValues.put('NSP_Benefits_Package__c', getLabelValueMapByField('NSP_Benefits_Package__c', subClientObject.NSP_Benefit_Package_Name__c));
            fieldValues.put('NSP_Wait_Period__c', getLabelValueMapByField('NSP_Wait_Period__c', subClientObject.NSP_Client_Wait_Period__c));
        }
    }

    private static  NSP_Sub_Client__c getSubClientByAssetId(String assetId){
        List<NSP_Sub_Client__c> subclients = [SELECT NSP_Margin__c, NSP_Part_Time_Margin__c,
            NSP_Reserve__c,NSP_Part_Time_Reserve__c, NSP_Benefit_Package_Name__c,
            NSP_Client_Wait_Period__c FROM NSP_Sub_Client__c
            WHERE NSP_Asset__c =: assetId AND NSP_Sub_Client__c LIKE '%00'];

            return subclients.isEmpty() ? null : subclients[0];
    }
    
    private static String getAccGroupMemberNames(String accId){
        Set<Id> uniqueAccGroups = new Set<Id>();
        for (NSP_Account_Group_Member__c member : [SELECT NSP_Group__c FROM NSP_Account_Group_Member__c WHERE NSP_Member_Account__c = :accId AND NSP_Type__c = 'Common Ownership']) {
            uniqueAccGroups.add(member.NSP_Group__c);
        }
        Map<String,List<String>> groupMemberNames = new Map<String,List<String>>();
        for (NSP_Account_Group_Member__c member : [SELECT NSP_Group__r.Name, NSP_Member_Account__r.Name, Name FROM NSP_Account_Group_Member__c WHERE NSP_Group__c IN :uniqueAccGroups]) {
            List<String> members = groupMemberNames.get(member.NSP_Group__r.Name);
            if(members == null){
                members = new List<String>();
            }

            members.add(member.NSP_Member_Account__r.Name);

            groupMemberNames.put(member.NSP_Group__r.Name, members);
        }

        String groupNameWithMembers = ''; 
        for (String groupName : groupMemberNames.keySet()){
            String memberNames =  String.join(groupMemberNames.get(groupName), ', ');

            groupNameWithMembers += groupNameWithMembers + groupName + ': ' + memberNames + '<br>'+'<br>';
        }

        return groupNameWithMembers;
    }

    private static void populateAccGroupMember(String accId, Map<String, Map<String,String>> fieldValues){
        String accGroupMemberNames = getAccGroupMemberNames(accId);

        if(String.isNotBlank(accGroupMemberNames)){
            Map<String, String> accGroupData = getLabelValueMapByField('NSP_Common_Ownership_related_clients__c', accGroupMemberNames);
            accGroupData.put('checkRichText', TRUE_VALUE);
            fieldValues.put('NSP_Common_Ownership_related_clients__c', accGroupData);
        }
    }

    private static NSP_Account_Team__c getAccTeamMember(String accId){
        List<String> acctTeamFields = new List<String>{
            'Name',
            'NSP_User__r.Name'
        };

        String query = new NSP_QueryBuilder('NSP_Account_Team__c',acctTeamFields)
                        .addFilter('NSP_Account__c', accId )
                        .addFilter('NSP_Role__c', '401k Plan Consultant')
                        .addLimit(1).build();

        List<NSP_Account_Team__c> accTeam = (List<NSP_Account_Team__c>) Database.query(query);

        return accTeam.isEmpty() ? null : accTeam[0];
    }

    private static void populateAccTeamMember(String accId, Map<String, Map<String,String>> fieldValues){
        NSP_Account_Team__c accTeamObject = getAccTeamMember(accId);

        if(accTeamObject != null){
            fieldValues.put('NSP_Assigned_RS_Specialist__c', getLabelValueMap('Who is the assigned Retirement Services Specialist?', accTeamObject.NSP_User__r.Name));
        }
    }

    private static NSP_Eligibility__c getEligibilityRecord(String assetId){
        List<NSP_Eligibility__c> retEligibleObj = new List<NSP_Eligibility__c>();
        NSP_Plan_SubPlan__c subPlanObj = getRETSubPlanId(assetId);
        if(subPlanObj!=NULL){
            List<String> rtEligibleFields = new List<String>{
                'Name',
                'NSP_Asset__r.Name',
                'NSP_Plan_Subplan_Relationship__c'
            };
            String query = new NSP_QueryBuilder('NSP_Eligibility__c', rtEligibleFields)
                    .addFilter('NSP_Plan_Subplan_Relationship__c', subPlanObj.Id)
                    .orderBy('CreatedDate','DESC', true).addLimit(1).build();
            retEligibleObj = (List<NSP_Eligibility__c>) Database.query(query);
        }
        return retEligibleObj.isEmpty() ? null : retEligibleObj[0];
    }


    private static void populateEligibilityFields(String assetId, Map<String, Map<String,String>> fieldValues){
        NSP_Eligibility__c eligibility = getEligibilityRecord(assetId);
        
        if(eligibility != null) {
            String urlEligibilty = URL.getSalesforceBaseUrl().toExternalForm()+ '/'+eligibility.Id;
            String labelName= eligibility.Name;
            Map<String, String> orkWaitPeriod = getLabelValueMapByField('NSP_401K_ORK_wait_period__c', urlEligibilty);
            orkWaitPeriod.put(TYPE, 'url');
            orkWaitPeriod.put('isURL',TRUE_VALUE);
            orkWaitPeriod.put('urlLabel',labelName);
            fieldValues.put('NSP_401K_ORK_wait_period__c', orkWaitPeriod);
            Map<String, String> eligibiltyReq = getLabelValueMapByField('NSP_Eligibility_requirements__c', urlEligibilty);
            eligibiltyReq.put(TYPE, 'url');
            eligibiltyReq.put('isURL',TRUE_VALUE);
            eligibiltyReq.put('urlLabel',labelName);
            fieldValues.put('NSP_Eligibility_requirements__c', eligibiltyReq);
        }
    }

    private static AssetRETEducationAssociation__c getRetEducationField(String assetId){
        List<String> retEduFields = new List<String>{
            'Name'
        };
        String query = new NSP_QueryBuilder('AssetRETEducationAssociation__c', retEduFields)
                .addFilter('NSP_Education_Client__c', assetId)
                .orderBy('CreatedDate','DESC', true)
                .addLimit(1).build();
        List<AssetRETEducationAssociation__c> retEduObj = (List<AssetRETEducationAssociation__c>) Database.query(query);

        return retEduObj.isEmpty() ? null : retEduObj[0];
    }

    private static void populateRetEducationField(String assetId, Map<String, Map<String,String>> fieldValues){
        AssetRETEducationAssociation__c eduFields = getRetEducationField(assetId);

        if (eduFields != null){
            String urlLastEmployee = URL.getSalesforceBaseUrl().toExternalForm()+ '/'+eduFields.Id;
            String labelName = eduFields.Name;
            Map<String, String> lastEmployeeEdu = getLabelValueMap('When was their last employee 401k education webinar if on the NSP plan', urlLastEmployee);
            lastEmployeeEdu.put(TYPE, 'url');
            lastEmployeeEdu.put('isURL',TRUE_VALUE);
            lastEmployeeEdu.put('urlLabel',labelName);
            fieldValues.put('NSP_last_employee_401k_education_webinar__c', lastEmployeeEdu);
        }
    }

    private static NSP_Participation_SaaS_Activity__c getSaaSActivityField(String assetId){
        List<NSP_Participation_SaaS_Activity__c> saasFields = new List<NSP_Participation_SaaS_Activity__c>();
        NSP_Plan_SubPlan__c subPlanObj = getRETSubPlanId(assetId);
        if(subPlanObj!=NULL){
            List<String> retParticipateFields = new List<String>{
                'Name',
                'NSP_Eligible_Participating_Count__c',
                'NSP_Asset__c'
            };
            String query = new NSP_QueryBuilder('NSP_Participation_SaaS_Activity__c', retParticipateFields)
                    .addFilter('NSP_Subplan_Plan_Details_Record__c', subPlanObj.Id)
                    .orderBy('CreatedDate','DESC', true)
                    .addLimit(1).build();
            saasFields = (List<NSP_Participation_SaaS_Activity__c>) Database.query(query);
        }
        return saasFields.isEmpty() ? null : saasFields[0];
    }

    private static void populateSaaSActivityField(String assetId, Map<String, Map<String,String>> fieldValues){
        NSP_Participation_SaaS_Activity__c saasFields = getSaaSActivityField(assetId);

        if (saasFields != null){
            Map<String, String> employeeEntrolled = getLabelValueMap('How many employees are enrolled in their 401k?',saasFields.NSP_Eligible_Participating_Count__c);
            fieldValues.put('NSP_How_many_emplys_enrolled_in_401k__c', employeeEntrolled);
        }
    }
}