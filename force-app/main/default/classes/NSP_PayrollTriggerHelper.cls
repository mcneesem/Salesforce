public class NSP_PayrollTriggerHelper {
    // test w/ NSP_PayrollTriggerHelperTest (83%)

    public static list<NSP_Payroll_Data_Sheet_Event__e> payrollDataSheetEventListToBeInserted = new list <NSP_Payroll_Data_Sheet_Event__e>();
    public static final Id WOASSETRECTYPEID = NSP_GenericRecordType.getRecordTypeId( 'Asset' , NSP_ServiceConstants.WO_ASSET_RECORDTYPE );

    //
    // Iterates throught the list of new Payrolls and passes the
    // required attributes to other methods.
    // @param payrolltNewMap Map of New Payroll.
    // @param payrollOldMap Map of Old Payroll.
    // @param payrollNewList List of new Payroll.
    // @return void
    //
    public void fieldUpdatesAfterInsertUpdate(
        List<NSP_Payroll__c> newPayrollList ,
        Map<Id,NSP_Payroll__c> newPayrollMap ,
        Map<Id,NSP_Payroll__c> oldPayrollMap ,
        Boolean skipPayrollUpdate
        )
    {
        if ( newPayrollList == null ) {
            newPayrollList = newPayrollMap.values();
        }
        Boolean isPayrollSpecialist=false;
        Set<Id> contactidsSet = new Set<Id>();
        Set<Id> subClientIdsSet = new Set<Id>();
        Map<Id,NSP_Sub_Client__c> relatedSubClientsMap = new Map<Id,NSP_Sub_Client__c>();
        Map<Id,Contact> relatedContactsMap = new Map<Id,Contact>();
        for ( NSP_Payroll__c payrolls : newPayrollList ) {
            //AZD-509194 - Kill Switch for Create PDS,Implemented in Crate PDS Flow
            if ( !NSP_PayrollTriggerHelper.isEnabledCreateUpdatePDS ) {
                if ( ( ( newPayrollMap == null )
                        && ( payrolls.NSP_Sub_Client_Name__c != null )
                        )
                    || ( ( oldPayrollMap != null )
                        && ( newPayrollMap != null )
                        && ( oldPayrollMap.get( payrolls.Id ).NSP_Sub_Client_Name__c != newPayrollMap.get( payrolls.Id ).NSP_Sub_Client_Name__c )
                        )
                    )
                {
                    subClientIdsSet.add( payrolls.NSP_Sub_Client_Name__c );
                }
                // AZD-443324
                if ( ( ( newPayrollMap == null )
                        && ( payrolls.NSP_On_site_Supervisor__c != null )
                        && !NSP_PayrollTriggerHelper.isEnabledOnsiteSupervisor
                        )
                    || ( ( oldPayrollMap != null )
                        && ( newPayrollMap != null )
                        && ( oldPayrollMap.get( payrolls.Id ).NSP_On_site_Supervisor__c != newPayrollMap.get( payrolls.Id ).NSP_On_site_Supervisor__c )
                        )
                    )
                {
                    contactidsSet.add( payrolls.NSP_On_site_Supervisor__c );
                    payrolls.On_Site_View_Payroll_Paperwork__c = false;
                }
                // AZD-443324
                if ( ( ( newPayrollMap == null )
                        && ( payrolls.NSP_Primary_Payroll_Contact__c != null )
                        && !NSP_PayrollTriggerHelper.isEnabledPrimaryPayrollContact
                        )
                    || ( ( oldPayrollMap != null )
                        && ( newPayrollMap != null )
                        && ( oldPayrollMap.get( payrolls.Id ).NSP_Primary_Payroll_Contact__c != newPayrollMap.get( payrolls.Id ).NSP_Primary_Payroll_Contact__c )
                        )
                    )
                {
                    contactidsSet.add( payrolls.NSP_Primary_Payroll_Contact__c );
                    payrolls.Primary_View_Payroll_Paperwork__c = false;
                }
                // AZD-443324
                if ( ( ( newPayrollMap == null )
                        && ( payrolls.NSP_HR_Contact__c != null )
                        && !NSP_PayrollTriggerHelper.isEnabledHRContact
                        )
                    || ( ( oldPayrollMap != null )
                        && ( newPayrollMap != null )
                        && ( oldPayrollMap.get( payrolls.Id ).NSP_HR_Contact__c != newPayrollMap.get( payrolls.Id ).NSP_HR_Contact__c )
                        )
                    )
                {
                    contactidsSet.add( payrolls.NSP_HR_Contact__c );
                    payrolls.View_Payroll_Paperwork__c = false;
                }
                // AZD-443324
                if ( ( ( newPayrollMap == null )
                        && ( payrolls.NSP_Back_Up_Payroll_Contact__c != null )
                        && !NSP_PayrollTriggerHelper.isEnabledBackUpPayrollContact
                        )
                    || ( ( oldPayrollMap != null )
                        && ( newPayrollMap != null )
                        && oldPayrollMap.get( payrolls.Id ).NSP_Back_Up_Payroll_Contact__c != newPayrollMap.get( payrolls.Id ).NSP_Back_Up_Payroll_Contact__c
                        )
                    )
                {
                    contactidsSet.add( payrolls.NSP_Back_Up_Payroll_Contact__c );
                    payrolls.Back_Up_View_Payroll_Paperwork__c = false;
                }
            }
            if ( !isPayrollSpecialist && payrolls.Account__c != null ) {
                isPayrollSpecialist = true;
            }
        }
        if ( !subClientIdsSet.isEmpty() ) {
            relatedSubClientsMap = new Map<Id,NSP_Sub_Client__c>(
                [
                    SELECT Id , NSP_Asset__c , NSP_Account__c , NSP_States_of_Operations__c , NSP_Sub_Client__c
                    FROM NSP_Sub_Client__c
                    WHERE ( Id IN :subClientIdsSet )
                ]
            );
        }
        //If there is no contact(Primary, Backup, HR or Onsite) available
        //Or if it is called from Additional Payroll Contact Trigger.
        //AZD-509194 - Kill Switch for Create PDS,Follow Flow Process
        if ( ( contactidsSet.isEmpty() || !skipPayrollUpdate ) ) {
            this.updatePDSPayrollReviewersField( newPayrollList , skipPayrollUpdate );
        }
        if ( isPayrollSpecialist ) {
            this.updatePayrollSpecialistField( newPayrollList , skipPayrollUpdate );
        }
        //AZD-509194 - Kill Switch for Create PDS,Follow Flow Process
        if ( !relatedSubClientsMap.isEmpty() && !NSP_PayrollTriggerHelper.isEnabledCreateUpdatePDS ) {
            for ( NSP_Payroll__c payrolls : newPayrollList ) {
                //to Set Sub CLient #
                if ( ( payrolls.NSP_Sub_Client_Name__c != null )
                    && relatedSubClientsMap.containsKey( payrolls.NSP_Sub_Client_Name__c )
                    )
                {
                    payrolls.NSP_Sub_Client__c = relatedSubClientsMap.get( payrolls.NSP_Sub_Client_Name__c ).NSP_Sub_Client__c;
                }
                // to set account
                if ( ( payrolls.NSP_Sub_Client_Name__c != null )
                    && relatedSubClientsMap.containsKey( payrolls.NSP_Sub_Client_Name__c )
                    )
                {
                    payrolls.Account__c = relatedSubClientsMap.get( payrolls.NSP_Sub_Client_Name__c ).NSP_Account__c;
                }
                if ( !relatedSubClientsMap.isEmpty()
                    && ( payrolls.NSP_Sub_Client_Name__c != null )
                    )
                {
                    payrolls.NSP_States_of_Operation__c = relatedSubClientsMap.get(payrolls.NSP_Sub_Client_Name__c).NSP_States_of_Operations__c;
                }
            }
        }
    }

    //
    // Iterates throught the list of new Payrolls and passes the
    // required attributes to other methods.
    // @param payrollNewList List of new Payroll.
    // @return void
    //
    public static void createPayrollDataSheetEventRecord( List<NSP_Payroll__c> newList ) {
        for(NSP_Payroll__c payrollDataSheet : newList){
            NSP_Payroll_Data_Sheet_Event__e payroll = new NSP_Payroll_Data_Sheet_Event__e();
            payroll.NSP_ID__c = payrollDataSheet.Id;
            payroll.NSP_Sub_Client_Number__c = payrollDataSheet.NSP_Sub_Client_Number__c;
            payrollDataSheetEventListToBeInserted.add(payroll);

        }

        List<Database.SaveResult> results = EventBus.publish(payrollDataSheetEventListToBeInserted);

        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
            } else {
                for(Database.Error err : sr.getErrors()) {
                }
            }
        }
    }

    // dead code...
    public void checkSubClient(List<NSP_Payroll__c> Payrolls){
        Set<Id> subClientIds = new Set<Id>();
        for(NSP_Payroll__c newPayroll : Payrolls){
            if(newPayroll.NSP_Sub_Client_Name__c != null){
                subClientIds.add(newPayroll.NSP_Sub_Client_Name__c);
            }
        }

        Map<Id , NSP_Payroll__c> subclientByPayroll = New Map<Id , NSP_Payroll__c>();
        for( NSP_Payroll__c existingPayroll : [SELECT Id, NSP_Sub_Client_Name__c FROM NSP_Payroll__c WHERE NSP_Sub_Client_Name__c =: subClientIds]){
            subclientByPayroll.put(existingPayroll.NSP_Sub_Client_Name__c , existingPayroll);
        }
        for(NSP_Payroll__c newPayroll : Payrolls){
            if(subclientByPayroll.containsKey(newPayroll.NSP_Sub_Client_Name__c)){
                newPayroll.Adderror(System.Label.NSP_Payroll_Error);
            }
        }
    }

    @AuraEnabled
    public Static String deepCloneRec(String recordId, string subClientId){
        try {
            List<NSP_Related_Account__c> relatedAccounts = new List<NSP_Related_Account__c>();
            List<Additional_Payroll_Contact__c> additionalPayrollContacts = new List<Additional_Payroll_Contact__c>();
            List<ContentDocumentLink> contentDocumentLinks = new List<contentDocumentLink>();

            NSP_Payroll__c Payroll = [SELECT Id, Most_Recent_Pay_Period_End_Date__c, NSP_Additional_Report_Information__c, NSP_Additional_information__c,
            NSP_Additonal_Processing_Instructions__c, NSP_Ancillary__c, NSP_Asset__c, NSP_BackUpPayrollContactBest_Time_Of_Day__c,
            NSP_BackUpPayroll_Con_Located_Outside_US__c, NSP_BackUpPayroll_Contact_Contact_Method__c, NSP_BackUp_Payroll_Con_Internatiol_Phone__c,
            NSP_Union__c,
            NSP_Back_Up_Payroll_Contact__c,NSP_Backup_Payroll_Contact_SCC__c, NSP_Beginning_Date__c, NSP_Benefit_Classing__c, NSP_Certified_Reports__c, NSP_Client_Controlled_Rates__c,
            NSP_Client_Sponsored_Plans__c, NSP_Client_System_Additional_Information__c, NSP_Client_Unique_Additional_Information__c,
            NSP_Code_and_Code_Name__c, NSP_Complexity_Factor__c, NSP_Custom_Earnings_Code__c, NSP_Dental__c, NSP_Department__c, NSP_Departments__c,
            NSP_Dependent_Care__c, NSP_Ending_Date__c, NSP_Enter_of_Days_In_Arrears__c, NSP_FSA__c, NSP_FTP_File_Type__c, NSP_FTP__c, NSP_First_Pay_Date__c,
            NSP_Fringe_Details__c, NSP_Fringe__c, NSP_GL_GA_Report__c, NSP_Government_Contractor__c, NSP_HR_Con_Located_Outside_United_States__c,
            NSP_HR_Contact_Best_Time_Of_Day_to_Reach__c, NSP_HR_Contact_International_Phone__c,
            NSP_HR_Contact_Methods__c, NSP_HR_Contact__c, NSP_HSA__c, NSP_IRR__c, NSP_Job_Cost__c,
            NSP_Listof_reports_received_with_payroll__c, NSP_Medical__c, NSP_Most_Recent_Pay_Date__c, NSP_Most_Recent_Pay_Period__c, NSP_Next_Pay_Date__c,
            NSP_Non_Taxable_Cell_Phone__c, NSP_Note__c, NSP_Number_of_WSEE_FT__c, NSP_Number_of_WSEE_PT__c, NSP_Number_of_WSEE_Seasonal__c,
            NSP_ORK_Upload_CheckBox__c, NSP_ORK_Upload__c, NSP_On_site_Supervisor_Contact_Method__c, NSP_On_site_Supervisor__c, NSP_OnsiteSupervisor_Best_TimeOfDay_to_R__c,
            NSP_OnsiteSupervisor_International_Phone__c, NSP_Onsite_Super_Located_Outside_Unite__c, NSP_PTO_Accrual__c, NSP_Pay_Arrears__c, NSP_Pay_Current__c,
            NSP_Pay_Date__c, NSP_Pay_Day__c, NSP_Pay_Frequency__c, NSP_Pay_Type__c, NSP_Payroll_Data_Sheet_Name__c, NSP_Payroll_ProcessingSpecialInstruction__c,
            NSP_Payroll_Submittal_Type__c, NSP_Prevailing_Wage__c, NSP_PrimaryPayrollConta_International_Ph__c, NSP_PrimaryPayrollContc_Best_Time_Of_Day__c,
            NSP_Primary_Payroll_Con_Located_Outside__c, NSP_Primary_Payroll_Contact_Methods__c, NSP_Primary_Payroll_Contact__c, NSP_RRP__c, NSP_Received_Date__c,
            NSP_Reporting_Job_Cost__c, NSP_Return_to_client_deductions__c, NSP_SEO_Client__c, NSP_Seasonal_Employer__c, NSP_Shift_Differential__c, NSP_Ship_Date__c,
            NSP_States_of_Operation__c, NSP_Sub_Client_Name__c, NSP_Sub_Client_Number__c, NSP_System_being_used_if_known__c, NSP_Taxable_Reimbursements__c,
            NSP_Tips__c, NSP_Union_Employee__c, NSP_Vision__c, NSP_Work_Week__c, NSP_Worksheet_Type__c, XML_Type__c, User__c, NSP_Approvers__c, NSP_Union_Dues__c,
            NSP_Sub_Client__c, NSP_Sub_Client_Name__r.NSP_Sub_Client__c, NSP_Count_of_Payroll_Calendar__c FROM NSP_Payroll__c WHERE Id =: recordId];

            NSP_Payroll__c tempPayroll = Payroll.clone(false,true);
            tempPayroll.NSP_Sub_Client_Name__c = subClientId;
            insert tempPayroll;

            for(NSP_Related_Account__c existingRelatedAcc : [SELECT Id, NSP_Payroll_Data_Sheet__c, NSP_Account__c, NSP_AIMS_Client_Name__c,
                                                             NSP_AIMS_Client__c FROM NSP_Related_Account__c WHERE NSP_Payroll_Data_Sheet__c =: Payroll.Id]){
                                                                 NSP_Related_Account__c tempExistingRelatedAcc = existingRelatedAcc.clone(false,true);
                                                                 tempExistingRelatedAcc.NSP_Payroll_Data_Sheet__c = tempPayroll.Id;
                                                                 tempExistingRelatedAcc.NSP_Account__c = existingRelatedAcc.NSP_Account__c;
                                                                 relatedAccounts.add(tempExistingRelatedAcc);
                                                             }
            if(!relatedAccounts.isEmpty()) {
                insert relatedAccounts;
            }
            for(Additional_Payroll_Contact__c existingPayrollCon : [SELECT Id, Payroll__c, Contact__c, Contact_Type__c, NSP_Contact_Cell__c, NSP_Contact_Email__c,
                                                                    NSP_Contact_International_Phone__c, NSP_Contact_Office_Phone__c, NSP_Contact_Outside_US__c,
                                                                    NSP_Contact_Time_to_Reach__c FROM Additional_Payroll_Contact__c WHERE Payroll__c =: Payroll.Id]){
                                                                        Additional_Payroll_Contact__c tempExistingPayrollCon = existingPayrollCon.clone(false,true);
                                                                        tempExistingPayrollCon.Payroll__c = tempPayroll.Id;
                                                                        tempExistingPayrollCon.Contact__c = existingPayrollCon.Contact__c;
                                                                        additionalPayrollContacts.add(tempExistingPayrollCon);
                                                                    }
            if(!additionalPayrollContacts.isEmpty()) {
                insert additionalPayrollContacts;
            }

            for (ContentDocumentLink existingContentDocumentLink : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =: Payroll.Id]){
                ContentDocumentLink tempContentDocumentLink = existingContentDocumentLink.clone(false,true);
                tempContentDocumentLink.LinkedEntityId = tempPayroll.Id;
                contentDocumentLinks.add(tempContentDocumentLink);
            }
            if(!contentDocumentLinks.isEmpty()) {
                insert contentDocumentLinks;
            }
            return tempPayroll.Id;
        } catch(DmlException e) {

        }
        return null;
    }

    //
    // @MethodName: checkForGovernmentContractor
    // @Description: This method is used to map Government Contractor checkbox on before Insert
    // @param : List<NSP_Payroll__c> Payrolls
    // @createdDate : 10/11/2022
    // @Defect : STY-03277
    // @return void
    //
    public void checkForGovernmentContractor( List<NSP_Payroll__c> Payrolls ) {
        //AZD-509194 - Kill Switch for Create PDS . NSP_Government_Contractor__c Flag is now on Create PDS Flow
        if ( !NSP_PayrollTriggerHelper.isEnabledCreateUpdatePDS ) {
            Set<Id> subClientIdSet = new Set<Id>(); // To store Subclient
            Map<Id,Boolean> subClientGovConMap = new Map<Id,Boolean>(); // Map of SubCLient and Its related Asset Government Contrator
            for ( NSP_Payroll__c pRoll : Payrolls ) {
                if ( String.isNotBlank( pRoll.NSP_Sub_Client_Name__c ) ) {
                    subClientIdSet.add( pRoll.NSP_Sub_Client_Name__c );
                }
            }
            try {
                if ( !subClientIdSet.isEmpty() ) {
                    for ( NSP_Sub_Client__c subClient : [
                            SELECT
                                Id ,
                                NSP_Asset__c ,
                                NSP_Asset__r.NSP_Government_Contractor__c ,
                                NSP_Asset__r.RecordTypeId
                            FROM NSP_Sub_Client__c
                            WHERE (
                                ( Id IN :subClientIdSet )
                                AND ( NSP_Asset__r.RecordTypeId = :WOASSETRECTYPEID )
                            )
                        ]
                        )
                    {
                        subClientGovConMap.put(
                            subClient.Id ,
                            subClient.NSP_Asset__r.NSP_Government_Contractor__c
                        );
                    }
                    if ( !subClientGovConMap.isEmpty() ) {
                        for ( NSP_Payroll__c pRoll : Payrolls ) {
                            pRoll.NSP_Government_Contractor__c = subClientGovConMap.get( pRoll.NSP_Sub_Client_Name__c );
                        }
                    }
                }
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    NSP_PayrollTriggerHelper.class.getName() ,
                    'checkForGovernmentContractor' ,
                    e
                );
            }
        }
    }

    //
    // @MethodName: updatePDSRelatedContactFields
    // @Description: This method is used to update PDS Fields on before Insert
    // @param : List<NSP_Payroll__c> newList
    // @createdDate : 11/16/2022
    // @Defect : STY-03235
    // @AZD-443324 - Added Custom Settings ligic to eliminate automation for individual contacts
    // @return void
    //
    public static void updatePDSRelatedContactFields( List<NSP_Payroll__c> newList ) {
        //AZD-509194 - Kill Switch for Create PDS . Implemented in Create PDS Flow
        if ( !NSP_PayrollTriggerHelper.isEnabledCreateUpdatePDS ) {
            Set<Id> subClientIds = new Set<Id>();
            Set<Id> pdsHrContact = new Set<Id>();
            Set<Id> pdsBackupContacts = new Set<Id>();
            Map<Id,String> aimsByAccId  =new Map<Id,String>();
            Map<Id,String> perIdByCon =new Map<Id,String>();
            Map<Id,List<NSP_Sub_Client_Contact__c>> subClientConBySubCliIds = new Map<Id,List<NSP_Sub_Client_Contact__c>>();
            Map<Id,AccountContactRelation> acrByContactId = new Map<Id,AccountContactRelation>();
            String aimsByPerIdHr = '';
            String aimsByPerIdBackup = '';
            // Update Payroll field logic based on respective confirmation checkbox
            for ( NSP_Payroll__c pdsNew : newList ) {
                if ( pdsNew.NSP_Sub_Client_Name__c != null ) {
                    subClientIds.add( pdsNew.NSP_Sub_Client_Name__c );
                }
                if ( pdsNew.NSP_HR_Contact__c != null && !NSP_PayrollTriggerHelper.isEnabledHRContact ) {
                    pdsHrContact.add( pdsNew.NSP_HR_Contact__c );
                }
                if ( pdsNew.NSP_Back_Up_Payroll_Contact__c != null && !NSP_PayrollTriggerHelper.isEnabledBackUpPayrollContact ) {
                    pdsBackupContacts.add( pdsNew.NSP_Back_Up_Payroll_Contact__c );
                }
            }
            for ( NSP_Sub_Client__c subCliHR : [
                        SELECT
                            Id ,
                            NSP_Account__c ,
                            NSP_Account__r.NSP_AIMS_Client__c
                        FROM NSP_Sub_Client__c
                        WHERE (
                            ( Id = :subClientIds )
                            AND ( NSP_Account__c != null )
                        )
                    ]
                )
            {
                aimsByAccId.put(
                    subCliHR.Id ,
                    subCliHR.NSP_Account__r.NSP_AIMS_Client__c
                );
            }
            for ( Contact conHR : [
                        SELECT Id , NSP_Per_ID__c
                        FROM Contact
                        WHERE (
                            ( NSP_Per_ID__c != null )
                            AND (
                                ( Id = :pdsHrContact )
                                OR ( Id = :pdsBackupContacts )
                                )
                        )
                    ]
                )
            {
                perIdByCon.put( conHR.Id , conHR.NSP_Per_ID__c );
            }
            // Concatinate AIM Client # With PerId Logic
            for ( NSP_Payroll__c pdsValue : newList ) {
                if ( aimsByAccId.containsKey( pdsValue.NSP_Sub_Client_Name__c ) ) {
                    if ( perIdByCon.containsKey( pdsValue.NSP_HR_Contact__c )
                        && !NSP_PayrollTriggerHelper.isEnabledHRContact
                        )
                    {
                        aimsByPerIdHr = ''
                            + aimsByAccId.get( pdsValue.NSP_Sub_Client_Name__c )
                            +'-'
                            + perIdByCon.get( pdsValue.NSP_HR_Contact__c )
                            ;
                    }
                    if ( perIdByCon.containsKey( pdsValue.NSP_Back_Up_Payroll_Contact__c )
                        && !NSP_PayrollTriggerHelper.isEnabledBackUpPayrollContact
                        )
                    {
                        aimsByPerIdBackup = ''
                            + aimsByAccId.get( pdsValue.NSP_Sub_Client_Name__c )
                            + '-'
                            + perIdByCon.get( pdsValue.NSP_Back_Up_Payroll_Contact__c )
                            ;
                    }
                }
            }
            // get existing Sub Client Contact related to Sub Client
            for ( NSP_Sub_Client_Contact__c subCliCon : [
                        SELECT
                            Id ,
                            NSP_Sub_Client__c ,
                            NSP_Contact__c ,
                            NSP_On_Site_Supervisor__c ,
                            NSP_HR_Contact__c ,
                            NSP_Payroll_Contact__c ,
                            NSP_Background_Contact__c
                        FROM NSP_Sub_Client_Contact__c
                        WHERE (
                            ( NSP_Sub_Client__c = :subClientIds )
                            AND ( NSP_Contact__c != null )
                        )
                        ORDER BY CreatedDate
                    ]
                )
            {
                // Store in Map subclient with its related sub client contacts
                if ( subClientConBySubCliIds.containsKey( subCliCon.NSP_Sub_Client__c ) ) {
                    subClientConBySubCliIds.get( subCliCon.NSP_Sub_Client__c ).Add( subCliCon );
                } else {
                    subClientConBySubCliIds.put(
                        subCliCon.NSP_Sub_Client__c ,
                        new list<NSP_Sub_Client_Contact__c>{ subCliCon }
                    );
                }
            }
            // Update Payroll field logic based on respective confirmation checkbox
            for ( NSP_Payroll__c pdsNew : newList ) {
                // get all related subclient contacts for sub client
                if ( subClientConBySubCliIds.get( pdsNew.NSP_Sub_Client_Name__c ) != null ) {
                    List<NSP_Sub_Client_Contact__c> subCliConList = subClientConBySubCliIds.get( pdsNew.NSP_Sub_Client_Name__c );
                    if ( !subCliConList.isEmpty() ) {
                        for ( NSP_Sub_Client_Contact__c subClientCon : subCliConList ) {
                            // update PDS field On Site Supervisor Contact And On Site Supervisor Contact SCC
                            if ( ( subClientCon.NSP_On_Site_Supervisor__c == true )
                                && !NSP_PayrollTriggerHelper.isEnabledOnsiteSupervisor
                                )
                            {
                                pdsNew.NSP_On_Site_Supervisor__c = subClientCon.NSP_Contact__c;
                                pdsNew.NSP_OSS_SCC__c = subClientCon.Id;
                            }
                            // update PDS field Payroll Contact And Payroll Contact SCC
                            if ( ( subClientCon.NSP_Payroll_Contact__c == true )
                                && !NSP_PayrollTriggerHelper.isEnabledPrimaryPayrollContact
                                )
                            {
                                pdsNew.NSP_Primary_Payroll_Contact__c = subClientCon.NSP_Contact__c;
                                pdsNew.NSP_Payroll_SCC__c = subClientCon.Id;
                            }
                            // update PDS field HR Contact And HR Contact SCC
                            if ( ( subClientCon.NSP_HR_Contact__c == true )
                                && ( pdsNew.NSP_HR_Contact__c == null )
                                && !NSP_PayrollTriggerHelper.isEnabledHRContact
                                )
                            {
                                pdsNew.NSP_HR_Contact__c = subClientCon.NSP_Contact__c;
                                pdsNew.NSP_HR_Contact_SCC__c = subClientCon.Id;
                            }
                        }
                    }
                }
            }
        }
    }

    //
    // @MethodName   : validatePDSInsert
    // @Description  : This method is used to validate if there is already an PDS with Sub Client
    // @param        : List<NSP_Payroll__c> newList
    // @createdDate  : 28/03/2023
    // @Defect       : DF-03251
    // @return void
    //
    public static void validatePDSInsert( List<NSP_Payroll__c> newList ) {
        Map<Id ,NSP_Payroll__c> subClientByPds = new Map<Id ,NSP_Payroll__c >();
        Map<Id ,NSP_Payroll__c > subClientByPdsIns = new Map<Id ,NSP_Payroll__c >();
        //Loop on New Payroll Data Sheet Records
        for(NSP_Payroll__c payroll : newList) {
            if(payroll.NSP_Sub_Client_Name__c != null) {
                //Check if Bulk Records are getting inserted.
                if(subClientByPdsIns.containsKey(payroll.NSP_Sub_Client_Name__c)) {
                    payroll.addError(Label.NSP_PDS_Already_Exist);
                }else{
                    //Store Unique records
                    subClientByPdsIns.put(payroll.NSP_Sub_Client_Name__c, payroll);
                }
            }
        }
        //Build Map based on existin Sub Client and PDS
        if(!subClientByPdsIns.isEmpty()){
            for(NSP_Payroll__c pds :[SELECT Id, NSP_Sub_Client_Name__c FROM NSP_Payroll__c WHERE NSP_Sub_Client_Name__c =: subClientByPdsIns.keySet()] ) {
                subClientByPds.put(pds.NSP_Sub_Client_Name__c, pds);
            }
        }

        if(!subClientByPds.isEmpty()){
            for(NSP_Payroll__c pdsNew: newList) {
                //Error is PDS Already exists
                if( subClientByPds.containsKey(pdsNew.NSP_Sub_Client_Name__c)) {
                    pdsNew.addError(Label.NSP_PDS_Already_Exist);
                }
            }
        }
    }

    //
    // @MethodName   : updatePDSContactRelatedFields
    // @Description  : This method is used to Updated SCC on PDS based on HR COntact, Primary Contact, Supervisor, Backup contact
    // @param        : List<NSP_Payroll__c> newList and map<Id,NSP_Payroll__c> oldMap
    // @createdDate  : 02/05/2023
    // @Defect       : DF-03901
    // @return void
    //
    public void updatePDSContactRelatedFields( List<NSP_Payroll__c> newList , map<Id,NSP_Payroll__c> oldMap ) {
        //AZD-509194 - Kill Switch for Create PDS . Implemented on Create PDS Flow
        if ( !NSP_PayrollTriggerHelper.isEnabledCreateUpdatePDS ) {
            Map<Id,List<NSP_Sub_Client_Contact__c>> subClienBySCC = new Map<Id,List<NSP_Sub_Client_Contact__c>>();
            Boolean isCriteraMet = false;
            Set<Id> subClientIds = new Set<Id>();
            for ( NSP_Payroll__c payrolls : newList ) {
                if ( !NSP_PayrollTriggerHelper.isEnabledBackUpPayrollContact
                    && ( ( payrolls.NSP_Back_Up_Payroll_Contact__c != null && oldMap == null )
                        || ( oldMap != null && payrolls.NSP_Back_Up_Payroll_Contact__c != oldMap.get(payrolls.Id).NSP_Back_Up_Payroll_Contact__c )
                        )
                    )
                {
                    subClientIds.add( payrolls.NSP_Sub_Client_Name__c );
                }
                if ( !NSP_PayrollTriggerHelper.isEnabledOnsiteSupervisor
                    && ( ( payrolls.NSP_On_site_Supervisor__c != null && oldMap == null )
                        || ( oldMap != null && payrolls.NSP_On_site_Supervisor__c != oldMap.get(payrolls.Id).NSP_On_site_Supervisor__c )
                        )
                    )
                {
                    subClientIds.add( payrolls.NSP_Sub_Client_Name__c );
                }
                if ( !NSP_PayrollTriggerHelper.isEnabledPrimaryPayrollContact
                    && ( ( payrolls.NSP_Primary_Payroll_Contact__c != null && oldMap == null )
                        || ( oldMap != null && payrolls.NSP_Primary_Payroll_Contact__c != oldMap.get(payrolls.Id).NSP_Primary_Payroll_Contact__c )
                        )
                    )
                {
                    subClientIds.add( payrolls.NSP_Sub_Client_Name__c );
                }
                if ( !NSP_PayrollTriggerHelper.isEnabledHRContact
                    && ( ( payrolls.NSP_HR_Contact__c != null && oldMap == null )
                        || ( oldMap != null && payrolls.NSP_HR_Contact__c != oldMap.get(payrolls.Id).NSP_HR_Contact__c )
                        )
                    )
                {
                    subClientIds.add( payrolls.NSP_Sub_Client_Name__c );
                }
            }
            if ( !subClientIds.isEmpty() ) {
                for ( NSP_Sub_Client_Contact__c existingSCC : [
                            SELECT
                                Id ,
                                NSP_Contact__c ,
                                NSP_Paid_Non_Paid__c ,
                                NSP_Employee_Status__c ,
                                NSP_On_Site_Supervisor__c ,
                                NSP_Payroll_Contact__c ,
                                NSP_HR_Contact__c ,
                                NSP_Sub_Client__c
                            FROM NSP_Sub_Client_Contact__c
                            WHERE ( NSP_Sub_Client__c = :subClientIds )
                            ORDER BY LastModifiedDate DESC
                        ]
                    )
                {
                    if ( subClienBySCC.containsKey(existingSCC.NSP_Sub_Client__c ) ) {
                        subClienBySCC.get( existingSCC.NSP_Sub_Client__c ).add( existingSCC );
                    } else {
                        subClienBySCC.put(
                            existingSCC.NSP_Sub_Client__c ,
                            new list<NSP_Sub_Client_Contact__c>{ existingSCC }
                        );
                    }
                }
                if( !subClienBySCC.isEmpty() ){
                    Boolean isPayrollReviewer = false;
                    for ( NSP_Payroll__c payroll : newList ) {
                        Boolean isBackupFound = false;
                        Boolean isPrimaryFound = false;
                        Boolean isHrConFound = false;
                        Boolean isSupervisorFound = false;
                        if ( ( payroll.NSP_Sub_Client_Name__c != null )
                            && subClienBySCC.containsKey( payroll.NSP_Sub_Client_Name__c )
                            )
                        {
                            List<NSP_Sub_Client_Contact__c> subClientCons = subClienBySCC.get( payroll.NSP_Sub_Client_Name__c );
                            if ( ( subClientCons != null ) && !subClientCons.isEmpty() ) {
                                for ( NSP_Sub_Client_Contact__c subClientCon : subClientCons ) {
                                    //Check if backup payroll contact is set
                                    //AZD-443324
                                    if ( !NSP_PayrollTriggerHelper.isEnabledBackUpPayrollContact ) {
                                        if ( payroll.NSP_Back_Up_Payroll_Contact__c != null ) {
                                            if ( payroll.NSP_Back_Up_Payroll_Contact__c == subClientCon.NSP_Contact__c
                                                && !isBackupFound //is backup same as SCC contact
                                                )
                                            {
                                                payroll.NSP_Backup_Payroll_Contact_SCC__c = subClientCon.id;
                                                isBackupFound = true;
                                                if( !isPayrollReviewer ) {
                                                    isPayrollReviewer = true;
                                                }
                                            }
                                        } else {
                                            payroll.NSP_Back_Up_Payroll_Contact__c = null;
                                        }
                                    }
                                    //AZD-443324
                                    if ( !NSP_PayrollTriggerHelper.isEnabledPrimaryPayrollContact ) {
                                        if ( payroll.NSP_Primary_Payroll_Contact__c != null ) {
                                            if ( subClientCon.NSP_Payroll_Contact__c && !isPrimaryFound ) {
                                                payroll.NSP_Payroll_SCC__c = subClientCon.Id;
                                                payroll.NSP_Primary_Payroll_Contact__c = subClientCon.NSP_Contact__c;
                                                isPrimaryFound = true;
                                                if ( !isPayrollReviewer ) {
                                                    isPayrollReviewer = true;
                                                }
                                            }
                                        } else {
                                            payroll.NSP_Payroll_SCC__c = null;
                                        }
                                    }
                                    //AZD-443324
                                    if ( !NSP_PayrollTriggerHelper.isEnabledHRContact ) {
                                        if ( payroll.NSP_HR_Contact__c != null ) {
                                            if ( subClientCon.NSP_HR_Contact__c && !isHrConFound ) {
                                                payroll.NSP_HR_Contact_SCC__c = subClientCon.Id;
                                                payroll.NSP_HR_Contact__c = subClientCon.NSP_Contact__c;
                                                isHrConFound = true;
                                                if ( !isPayrollReviewer ) {
                                                    isPayrollReviewer = true;
                                                }
                                            }
                                        } else {
                                            payroll.NSP_HR_Contact_SCC__c = null;
                                        }
                                    }
                                    //AZD-443324
                                    if ( !NSP_PayrollTriggerHelper.isEnabledOnsiteSupervisor ) {
                                        if ( payroll.NSP_On_site_Supervisor__c != null ) {
                                            if ( subClientCon.NSP_On_site_Supervisor__c && !isSupervisorFound ) {
                                                payroll.NSP_OSS_SCC__c = subClientCon.Id;
                                                payroll.NSP_On_site_Supervisor__c = subClientCon.NSP_Contact__c;
                                                isSupervisorFound = true;
                                                if ( !isPayrollReviewer ) {
                                                    isPayrollReviewer = true;
                                                }
                                            }
                                        } else {
                                            payroll.NSP_OSS_SCC__c = null;
                                        }
                                    }
                                }
                            }
                        }
                    }
                    //If any contact out of Primary, Backup, HR and Onsite contact available.
                    if ( isPayrollReviewer ) {
                        this.updatePDSPayrollReviewersField( newList , isPayrollReviewer );
                    }
                }
            }
        }
    }

    //
    // @MethodName   : updatePayrollSpecialistField
    // @Description  : This method is used to Update Payroll Payroll Specialist field on PDS from related account's account team
    // @param        : List<NSP_Payroll__c> newList and map<Id,NSP_Payroll__c> oldMap
    // @createdDate  : 27/08/2024
    // @Defect       :
    // @return void
    //
    private void updatePayrollSpecialistField( List<NSP_Payroll__c> newPayrollList , Boolean skipPayrollUpdate ) {
        // All account IDs from the payroll list
        if ( ( newPayrollList != null ) && !newPayrollList.isEmpty() ) {
            Set<Id> accountIds = new Set<Id>();
            for ( NSP_Payroll__c payroll : newPayrollList ) {
                if ( payroll.Account__c != null ) {
                    accountIds.add( payroll.Account__c );
                }
            }
            //Account Team members with the role 'Payroll Specialist'
            Map<Id,String> accountTeamMap = new Map<Id,String>();
            if ( ( accountIds != null ) && !accountIds.isEmpty() ) {
                for ( NSP_Account_Team__c accountTeam : [
                            SELECT NSP_Account__c , NSP_User__r.Name
                            FROM NSP_Account_Team__c
                            WHERE (
                                NSP_Role__c = 'Payroll Specialist'
                                AND NSP_Account__c IN :accountIds
                            )
                        ]
                    )
                {
                    if ( accountTeamMap.containsKey( accountTeam.NSP_Account__c ) ) {
                        accountTeamMap.put(
                            accountTeam.NSP_Account__c ,
                            accountTeamMap.get( accountTeam.NSP_Account__c ) + '; ' + accountTeam.NSP_User__r.Name
                        );
                    } else {
                        accountTeamMap.put(
                            accountTeam.NSP_Account__c ,
                            accountTeam.NSP_User__r.Name
                        );
                    }
                }
                //Update Payroll Specialist field in the payroll list
                List<NSP_Payroll__c> lstOfUpdatePayrolls = new List<NSP_Payroll__c>();
                for ( NSP_Payroll__c payroll : newPayrollList ) {
                    if ( accountTeamMap.containsKey( payroll.Account__c ) ) {
                        payroll.Payroll_Specialist__c = accountTeamMap.get( payroll.Account__c );
                        if(!skipPayrollUpdate){
                            lstOfUpdatePayrolls.add(payroll);
                        }
                    }
                }
                if ( ( lstOfUpdatePayrolls != null )
                    && !lstOfUpdatePayrolls.isEmpty()
                    && !skipPayrollUpdate
                    )
                    {
                    try {
                        update lstOfUpdatePayrolls;
                    } catch ( DmlException e ) {
                        NSP_ErrorLogHandler.logException(
                            NSP_PayrollTriggerHelper.class.getName() ,
                            'updatePayrollSpecialistField' ,
                            e
                        );
                    }
                }
            }
        }
    }

    //
    // @MethodName   : updatePDSPayrollReviewersField
    // @Description  : This method is used to Update Payroll Reviewers field on PDS based on HR COntact, Primary Contact, Supervisor, Backup contact
    // @param        : List<NSP_Payroll__c> newPayrollList.
    // @createdDate  : 27/08/2024
    // @Defect       : STY-257071
    // @AZD-443324   : Added custom setting logic to eliminate automation for individual contacts
    // @return void
    //
    public void updatePDSPayrollReviewersField( List<NSP_Payroll__c> newPayrollList , Boolean skipPayrollUpdate ) {
        Set<Id> setContactIds = new Set<Id>();
        List<NSP_Payroll__c> lstOfUpdatePayrolls = new List<NSP_Payroll__c>();
        Map<Id,String> mapOfAPCReviewers = new Map<Id, String>();
        Map<Id, Contact> mapOfContacts= new Map<Id, Contact>();
        Map<Id, NSP_Payroll__c> newPayrollMap = new Map<Id, NSP_Payroll__c>();

        if((newPayrollList != null) && !newPayrollList.isEmpty()){
            for(NSP_Payroll__c payroll : newPayrollList){
                newPayrollMap.put(payroll.Id, payroll);
                if ( payroll.NSP_Back_Up_Payroll_Contact__c != null
                    && payroll.Back_Up_View_Payroll_Paperwork__c
                    )
                {
                    setContactIds.add(payroll.NSP_Back_Up_Payroll_Contact__c);
                }
                if ( payroll.NSP_On_site_Supervisor__c != null
                    && payroll.On_Site_View_Payroll_Paperwork__c
                    )
                {
                    setContactIds.add(payroll.NSP_On_site_Supervisor__c);
                }
                if ( payroll.NSP_Primary_Payroll_Contact__c != null
                    && payroll.Primary_View_Payroll_Paperwork__c
                    )
                {
                    setContactIds.add(payroll.NSP_Primary_Payroll_Contact__c);
                }
               if ( payroll.NSP_HR_Contact__c != null
                    && payroll.View_Payroll_Paperwork__c
                    )
                {
                    setContactIds.add(payroll.NSP_HR_Contact__c);
                }
            }
            if(setContactIds != null && !setContactIds.isEmpty()) {
                for(Contact contact : [SELECT Id, Name FROM Contact WHERE Id IN :setContactIds]) {
                    mapOfContacts.put(contact.Id, contact);
                }
            }
            if(newPayrollMap != null && !newPayrollMap.keySet().isEmpty()){
                for ( Additional_Payroll_Contact__c apContact : [
                            SELECT Id , Payroll__r.Id , Contact__r.Name
                            FROM Additional_Payroll_Contact__c
                            WHERE (
                                Payroll__r.Id IN :newPayrollMap.keySet()
                                AND View_Payroll_Paperwork__c = true
                            )
                        ]
                    )
                {
                    if (mapOfAPCReviewers.containsKey(apContact.Payroll__r.Id)) {
                        String reviewerName = mapOfAPCReviewers.get(apContact.Payroll__r.Id);
                        if(!reviewerName.contains(apContact.Contact__r.Name)){
                            mapOfAPCReviewers.put(apContact.Payroll__r.Id,reviewerName + '; ' + apContact.Contact__r.Name);
                        }
                    } else {
                        mapOfAPCReviewers.put(apContact.Payroll__r.Id, apContact.Contact__r.Name);
                    }
                }
            }
            for(NSP_Payroll__c payroll : newPayrollList){
                String payrollReviewers='';
                if ( !mapOfContacts.isEmpty() || !mapOfAPCReviewers.isEmpty() ) {
                    String APCReviewers = '';
                    if ( !mapOfAPCReviewers.isEmpty() && ( mapOfAPCReviewers.get(payroll.Id) != null ) ) {
                        APCReviewers = mapOfAPCReviewers.get(payroll.Id);
                    }
                    if(newPayrollMap.containsKey(payroll.Id)){
                        if((setContactIds != null) && !setContactIds.isEmpty()){
                            if ( newPayrollMap.get(payroll.Id).NSP_Primary_Payroll_Contact__c != null
                                && newPayrollMap.get(payroll.Id).Primary_View_Payroll_Paperwork__c
                                && mapOfContacts.get(newPayrollMap.get(payroll.Id).NSP_Primary_Payroll_Contact__c) != null
                                )
                            {
                                String reviewerName = mapOfContacts.get(newPayrollMap.get(payroll.Id).NSP_Primary_Payroll_Contact__c).Name;
                                if((!payrollReviewers.contains(reviewerName)) && (!APCReviewers.contains(reviewerName))){
                                    if(String.isNotBlank(payrollReviewers)){payrollReviewers=payrollReviewers+'; ';}
                                    payrollReviewers = payrollReviewers + reviewerName;
                                }
                            }
                            if ( newPayrollMap.get(payroll.Id).NSP_Back_Up_Payroll_Contact__c != null
                                && newPayrollMap.get(payroll.Id).Back_Up_View_Payroll_Paperwork__c
                                && mapOfContacts.get(newPayrollMap.get(payroll.Id).NSP_Back_Up_Payroll_Contact__c) != null
                                )
                            {
                                String reviewerName = mapOfContacts.get(newPayrollMap.get(payroll.Id).NSP_Back_Up_Payroll_Contact__c).Name;
                                if((!payrollReviewers.contains(reviewerName)) && (!APCReviewers.contains(reviewerName))){
                                    if(String.isNotBlank(payrollReviewers)){payrollReviewers=payrollReviewers+'; ';}
                                    payrollReviewers = payrollReviewers + reviewerName;
                                }
                            }
                            if ( newPayrollMap.get(payroll.Id).NSP_HR_Contact__c != null
                                && newPayrollMap.get(payroll.Id).View_Payroll_Paperwork__c
                                && mapOfContacts.get(newPayrollMap.get(payroll.Id).NSP_HR_Contact__c) != null
                                )
                            {
                                String reviewerName = mapOfContacts.get(newPayrollMap.get(payroll.Id).NSP_HR_Contact__c).Name;
                                if((!payrollReviewers.contains(reviewerName)) && (!APCReviewers.contains(reviewerName))){
                                    if(String.isNotBlank(payrollReviewers)){payrollReviewers=payrollReviewers+'; ';}
                                    payrollReviewers = payrollReviewers + reviewerName;
                                }
                            }
                            if ( newPayrollMap.get(payroll.Id).NSP_On_site_Supervisor__c != null
                                && newPayrollMap.get(payroll.Id).On_Site_View_Payroll_Paperwork__c
                                && mapOfContacts.get(newPayrollMap.get(payroll.Id).NSP_On_site_Supervisor__c) != null
                                )
                            {
                                String reviewerName = mapOfContacts.get(newPayrollMap.get(payroll.Id).NSP_On_site_Supervisor__c).Name;
                                if((!payrollReviewers.contains(reviewerName)) && (!APCReviewers.contains(reviewerName))){
                                    if(String.isNotBlank(payrollReviewers)){payrollReviewers=payrollReviewers+'; ';}
                                    payrollReviewers = payrollReviewers + reviewerName;
                                }
                            }
                        }
                        if(!newPayrollMap.keySet().isEmpty()){
                            if(mapOfAPCReviewers.containsKey(payroll.Id)){
                                if ( String.isNotBlank( payrollReviewers ) ) {
                                    payrollReviewers = payrollReviewers+'; ';
                                }
                                payrollReviewers = payrollReviewers + mapOfAPCReviewers.get(payroll.Id);
                            }
                        }
                    }
                }
                payroll.Payroll_Reviewers__c = payrollReviewers;
                if(!skipPayrollUpdate){
                    lstOfUpdatePayrolls.add(payroll);
                }
            }
            if ( !lstOfUpdatePayrolls.isEmpty() && !skipPayrollUpdate ) {
                try {
                    update lstOfUpdatePayrolls;
                } catch ( Exception e ) {
                    NSP_ErrorLogHandler.logException(
                        NSP_PayrollTriggerHelper.class.getName() ,
                        'updatePDSPayrollReviewersField' ,
                        e
                    );
                }
            }
        }
    }

    //
    // Custom Settings
    // AZD-443324 : AZD-443324 : Added Custom Settings to eliminate automation for individual contacts
    //

    // AZD-443324 :  Kill Switch for Payroll Contacts
    private static Payroll_Data_Sheet_Settings__c settings {
        private  get {
            if ( settings == null ) {
                settings = Payroll_Data_Sheet_Settings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    public static Boolean isEnabledHRContact {
        public get {
            if ( isEnabledHRContact == null ) {
                Boolean local = False;
                if ( settings != null ) {
                    local = settings.IsEnabledHRContact__c;
                }
                isEnabledHRContact = local;
            }
            return isEnabledHRContact;
        }
        private set;
    }

    public static Boolean isEnabledPrimaryPayrollContact {
        public get {
            if ( isEnabledPrimaryPayrollContact == null ) {
                Boolean local = False;
                if ( settings != null ) {
                    local = settings.IsEnabledPrimaryPayrollContact__c;
                }
                isEnabledPrimaryPayrollContact = local;
            }
            return isEnabledPrimaryPayrollContact;
        }
        private set;
    }

    public static Boolean isEnabledOnsiteSupervisor {
        public get {
            if ( isEnabledOnsiteSupervisor == null ) {
                Boolean local = False;
                if ( settings != null ) {
                    local = settings.IsEnabledOnsiteSupervisor__c;
                }
                isEnabledOnsiteSupervisor = local;
            }
            return isEnabledOnsiteSupervisor;
        }
        private set;
    }

    public static Boolean isEnabledBackUpPayrollContact {
        public get {
            if ( isEnabledBackUpPayrollContact == null ) {
                Boolean local = False;
                if ( settings != null ) {
                    local = settings.IsEnabledBackUpPayrollContact__c;
                }
                isEnabledBackUpPayrollContact = local;
            }
            return isEnabledBackUpPayrollContact;
        }
        private set;
    }

    public static Boolean isEnabledCreateUpdatePDS {
        public get {
            if ( isEnabledCreateUpdatePDS == null ) {
                Boolean local = False;
                if ( settings != null ) {
                    local = settings.IsEnabledCreateUpdatePDS__c;
                }
                isEnabledCreateUpdatePDS = local;
            }
            return isEnabledCreateUpdatePDS;
        }
        private set;
    }

}
//
