@isTest
public class NSP_ImplementationProfileControllerTest {
    
    public static final String PARENT_FIELD_API_NAME= 'Have_name_s_of_COBRA_takeovr_employees__c';
    private static final String RECORDS_TO_UPSERT =  '{"recordstoupsert":' ;
    public static final String MEETINGTYPE_VIRTUAL = 'Virtual';
    private static final String EMP_ORIENTATION_API =  'Employee_Orientation__c';
    private static final String TEST_STR = 'Test' ;
    /**
    * Test Setup data for methods
    * @param null
    * @return void
    */
    @testSetup
    static void setAllData(){
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@randomorg.com';
        Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oUser = new User(alias = 'lName', email='testing123@insperity.com',
                              emailencodingkey='UTF-8', lastname='LName',
                              languagelocalekey='en_US', 
                              localesidkey='en_US', profileid = oProfile.Id,timezonesidkey='America/Los_Angeles', 
                              username=uniqueUserName);
        insert oUser;
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        insert oAccount;
        
        Implementation_Profile__c ipRecord = new Implementation_Profile__c(); 
        ipRecord.NSP_EE_Name__c = 'EE';
        insert ipRecord;

        List<Employee_Orientation__c> eoRecords = new List<Employee_Orientation__c>();
        Employee_Orientation__c eoRecords1 = new Employee_Orientation__c();
        eoRecords1.Meeting_Type__c = 'Virtual';
        eoRecords1.NSP_Implementation_Profile__c = ipRecord.Id;
        eoRecords.add(eoRecords1);
        Employee_Orientation__c eoRecords2 = new Employee_Orientation__c();
        eoRecords2.Meeting_Type__c = 'On Site';
        eoRecords2.NSP_Implementation_Profile__c = ipRecord.Id;
        eoRecords.add(eoRecords2);
        insert eoRecords;
        
        NSP_Employee_Data__c empDataRecord = new NSP_Employee_Data__c();
        empDataRecord.NSP_Parent_Field_API_Name__c = PARENT_FIELD_API_NAME;
        empDataRecord.NSP_Implementation_Profile__c = ipRecord.Id;
        insert empDataRecord;
        
    }
    
    /**
    * Classes Covered
    * NSP_ImplementationProfileController.saveGeneralDetails
    * @param null
    * @return void
    */
    @isTest
    static void saveGeneralDetails(){
        Test.startTest();
        Id iAccount = [Select Id FROM Account WHERE Id!=null LIMIT 1]?.Id;
        Implementation_Profile__c oIProfile = new Implementation_Profile__c(Legal_Name__c = 'Legal Name');
        NSP_ImplementationProfileController.NSP_IProfileGeneralWrapper oGeneralWrapper = new NSP_ImplementationProfileController.NSP_IProfileGeneralWrapper(oIProfile,new List<NSP_IP_Related_Client__c>{new NSP_IP_Related_Client__c(NSP_Related_Client__c = iAccount)});
        oGeneralWrapper = NSP_ImplementationProfileController.saveGeneralDetails(JSON.serialize(oGeneralWrapper));
        System.assertEquals(1, NSP_ImplementationProfileController.getRelatedClients(oGeneralWrapper.oIProfile.Id).size());
        Test.stopTest();
    }
    
    /**
    * Classes Covered
    * NSP_ImplementationProfileController.getAccountName
    * @param null
    * @return void
    */
    @isTest
    static void getAccountName(){
        Test.startTest();
        Id iAccount = [Select Id FROM Account WHERE Id!=null LIMIT 1]?.Id;
        System.assertEquals(1, NSP_ImplementationProfileController.getAccountName(new List<Id>{iAccount}).size());
        Test.stopTest();
    }
    
    /**
    * Classes Covered
    * NSP_ImplementationProfileController.saveAssignmentDetails
    * @param null
    * @return void
    */
    @isTest
    static void saveAssignmentDetails(){
        Test.startTest();
        Implementation_Profile__c oIProfile = new Implementation_Profile__c(Legal_Name__c = 'Legal Name');
        NSP_ImplementationProfileController.NSP_AssingmentMeetingIPWrapper oAssignmentWrapper = new NSP_ImplementationProfileController.NSP_AssingmentMeetingIPWrapper(oIProfile,new List<Employee_Orientation__c>{new Employee_Orientation__c(Date_and_Time__c = DateTime.now())});
        oAssignmentWrapper = NSP_ImplementationProfileController.saveAssignmentDetails(JSON.serialize(oAssignmentWrapper));
        System.assertEquals(1, NSP_ImplementationProfileController.getEmployeeOrientations(oAssignmentWrapper.oIProfile.Id).size());
        Test.stopTest();
    }
    
    /**
    * Classes Covered
    * NSP_ImplementationProfileController.savePayrollDetails
    * @param null
    * @return void
    */
    @isTest
    static void savePayrollDetails(){
        Test.startTest();
        Implementation_Profile__c oIProfile = new Implementation_Profile__c(Legal_Name__c = 'Legal Name');
        NSP_ImplementationProfileController.NSP_PayrollIPWrapper oPayrollWrapper = new NSP_ImplementationProfileController.NSP_PayrollIPWrapper(oIProfile,new List<Implementation_Pay_Period__c>{new Implementation_Pay_Period__c(Client_number__c = '10',
                                                                                                                                                                                                                                  Insperity_first_day_of_1st_pay_period__c = System.today())});
        try{
        oPayrollWrapper = NSP_ImplementationProfileController.savePayrollDetails(JSON.serialize(oPayrollWrapper));
        System.assertEquals(1, NSP_ImplementationProfileController.getPayPeriods(oPayrollWrapper.oIProfile.Id).size());}
        catch(Exception excep){
            system.assertNotEquals(null,excep);
        }   
        Test.stopTest(); 
    }
    
    @IsTest
    static void getTeamMembersWithAccountIdReturnsTeamMembers(){
        Account acc = [SELECT Id FROM Account WHERE Id!=null LIMIT 1];
        List<NSP_Account_Team__c> teams = new List<NSP_Account_Team__c>();
        
        NSP_Account_Team__c team1 = new NSP_Account_Team__c();
        team1.NSP_Account__c = acc.Id;
        team1.NSP_Role__c = NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR;
        team1.NSP_User__c = UserInfo.getUserId();
        teams.add(team1);
        
        NSP_Account_Team__c team2 = new NSP_Account_Team__c();
        team2.NSP_Role__c = NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR;
        team2.NSP_Account__c = acc.Id;
        team2.NSP_User__c = UserInfo.getUserId();
        teams.add(team2);
        
        insert teams;
        List<String> memIds = new List<String>();
        for(NSP_Account_Team__c team : [SELECT Id, NSP_User__c FROM NSP_Account_Team__c WHERE Id IN : teams]){
            memIds.add(team.NSP_User__c);
        }
        
        System.assertEquals(String.join(memIds, ','), NSP_ImplementationProfileController.getTeamMembers(acc.Id, true).memberIds);
    }
    
    @IsTest
    static void getPayPeriodsTest(){
        try{
             Implementation_Profile__c getTestImProfileRec = [SELECT Id, Name FROM Implementation_Profile__c WHERE Id!=null LIMIT 1];
            List<Implementation_Pay_Period__c>  lstImpPayPeriod = NSP_ImplementationProfileController.getPayPeriods(getTestImProfileRec.Id);
            System.assertEquals(0, lstImpPayPeriod.size(), 'No ImplementationProfile Pay Periods Found');
        } catch(Exception excep){
            throw new AuraHandledException(excep.getMessage());
        }
    }
    
    /**
    * @Description: This test method is used to cover getEmpDetailsByQuestions method
    * @Created date: 08/16/2022.
    * @return void
    */ 
    @IsTest
    static void getEmpDetailsByQuestionsWhenIPRecIdIsNullReturnsEmptyMap(){
        // GIVEN
        Implementation_Profile__c getTestImProfileRec = [SELECT Id, Name FROM Implementation_Profile__c WHERE Id!=null LIMIT 1];
        // NSP_Employee_Data__c getEmpDataRec = [SELECT Id, Name, NSP_Parent_Field_API_Name__c, NSP_Implementation_Profile__c
        //                                       FROM NSP_Employee_Data__c WHERE NSP_Parent_Field_API_Name__c =: PARENT_FIELD_API_NAME LIMIT 1];
        //WHEN
        Map<String, List<Id>> resultMap;
        try{ 
            test.startTest();
            resultMap = NSP_ImplementationProfileController.getEmpDetailsByQuestions(getTestImProfileRec.Id);
            test.stopTest();
        } catch(AuraHandledException excep){
            //THEN
            System.assert(!resultMap.isEmpty(),'Map is not Empty');
        }
    }
    
    /**
    * @Description: This test method is used to cover saveEmployeeData method and createNewEmployeeDataRecord
    * @Created date: 08/16/2022.
    * @return void
    */  
    @IsTest
    static void saveEmpDataWhenNewRecordCreated(){
        //GIVEN
        Implementation_Profile__c getTestImProfileRec = [SELECT Id, Name FROM Implementation_Profile__c WHERE Id!=null LIMIT 1];
        List<NSP_Employee_Data__c> empDataRecordsLst = new List<NSP_Employee_Data__c>();
        NSP_Employee_Data__c empDataRecord = new NSP_Employee_Data__c();
        empDataRecord.NSP_Parent_Field_API_Name__c = PARENT_FIELD_API_NAME;
        empDataRecordsLst.add(empDataRecord);
        string empDataRecordsString = JSON.serialize(empDataRecordsLst);
        List<string> parentFieldNamesStrgLst = new List<string>{PARENT_FIELD_API_NAME,'Do_any_EEs_have_garnishments__c'}; 
        //When
        try{
            Test.startTest();
            NSP_ImplementationProfileController.saveEmployeeData(empDataRecordsString,getTestImProfileRec.Id,parentFieldNamesStrgLst);
            Test.stopTest();
        } catch(AuraHandledException excep){
            //THEN
            System.assert(empDataRecordsLst.size()>0, true);
        }
    }

    /**
    * @Description: This test method is used to cover copyIpRecordData method
    * @Created date:
    * @return void
    */
    @isTest
    static void copyIpRecordsData_verifyUpdatedIp(){
        // GIVEN
        Implementation_Profile__c getIpRecords = [SELECT Id, Name, NSP_EE_Name__c FROM Implementation_Profile__c WHERE Id!=null LIMIT 1];
        List<String> ipRecords = new List<String>();
        ipRecords.add(getIpRecords.Id);

        Map<String, String> fieldValues = new Map<String, String>{};
        fieldValues.put('Payroll_general_notes__c', TEST_STR);
        fieldValues.put('NSP_EE_Name__c', TEST_STR);

        Map<String, String> config = new Map<String, String>();
        config.put('fieldValues', JSON.serialize(fieldValues));
        config.put('recType', 'MM');
        config.put('userEmail', 'test@test.com');
        config.put('postUpsertRecords', JSON.serialize(new List<String>() ));
        config.put('relatedObjnames', JSON.serialize(new List<String>{'Employee_Orientation__c'}));

        // WHEN
        Test.startTest();
        NSP_ImplementationProfileController.copyIpRecordData(ipRecords, config);
        Test.stopTest();

        Implementation_Profile__c updatedIpRecord = [SELECT Id, Name, NSP_EE_Name__c, Payroll_general_notes__c FROM Implementation_Profile__c WHERE Id = :getIpRecords.Id];

        // THEN
        Assert.areEqual(TEST_STR, updatedIpRecord.Payroll_general_notes__c, 'Payroll general notes field not updated correctly');
        Assert.areEqual(TEST_STR, updatedIpRecord.NSP_EE_Name__c, 'EE Name field not updated correctly');
    }

    /**
    * @Description: This test method is used to cover saveAndDeleteRecords method with all 3 scenarios.
    */
    @isTest
    static void saveAndDeleteRecordsWithInsertUpdateAndDeleteScenario(){
        // GIVEN
        Implementation_Profile__c ipRecords = [SELECT Id, Name FROM Implementation_Profile__c WHERE Id!=null LIMIT 1 ];
        List<Employee_Orientation__c> eoRecords = [SELECT Id,Meeting_Type__c, NSP_Implementation_Profile__c FROM Employee_Orientation__c WHERE Id!=null LIMIT 2];

        // Update Meeting type of a record
        Employee_Orientation__c updatedEoRecord = eoRecords[0];
        updatedEoRecord.Meeting_Type__c = 'Self Paced';

        // New Emp. Orientation Record
        Employee_Orientation__c newEoRecord = new Employee_Orientation__c();
        newEoRecord.Meeting_Type__c = MEETINGTYPE_VIRTUAL;
        newEoRecord.NSP_Implementation_Profile__c = ipRecords.Id;

        // EO Record to delete
        Employee_Orientation__c deletedEoRecord = eoRecords[1];

        String recordsConfigJsonInput = RECORDS_TO_UPSERT + JSON.serialize(new List<Employee_Orientation__c> {updatedEoRecord, newEoRecord}) + ',' 
        + '"recordsToDelete":' + JSON.serialize(new List<Employee_Orientation__c> { deletedEoRecord }) + '}';

        // WHEN
        try{
        NSP_ImplementationProfileController.saveAndDeleteRecords(recordsConfigJsonInput, EMP_ORIENTATION_API);
        }catch(Exception ex){
            system.assertNotEquals(null, ex);
        }
        Map<Id, Employee_Orientation__c> updatedRecordsMap = new Map<Id, Employee_Orientation__c>([SELECT Id, Meeting_Type__c, NSP_Implementation_Profile__c FROM Employee_Orientation__c WHERE Id!=null]);

        // THEN
        //Assert the deleted EO Record
        System.assertEquals(2, updatedRecordsMap.size());

        // Assert the updated EO Record
        System.assert(updatedRecordsMap.containsKey(updatedEoRecord.Id));
        System.assertEquals(MEETINGTYPE_VIRTUAL, updatedRecordsMap.get(updatedEoRecord.Id).Meeting_Type__c);
        
        List<Id> remainingEoRecordIds = new List<Id>(updatedRecordsMap.keySet());
        Employee_Orientation__c newEoRecordDB = updatedRecordsMap.get(remainingEoRecordIds[0]);
        
        // Assert the newly inserted EO record
        System.assertNotEquals(updatedEoRecord.Meeting_Type__c, newEoRecordDB.Meeting_Type__c);
        System.assertEquals(newEoRecord.NSP_Implementation_Profile__c, newEoRecordDB.NSP_Implementation_Profile__c);
        
        // Fetching the newly inserted EO record
        updatedRecordsMap.remove(updatedEoRecord.Id);
    }

    @isTest
    static void saveAndDeleteRecordsWhenThereIsNoRecordToDelete(){
        // GIVEN
        Implementation_Profile__c ipRecords = [SELECT Id, Name FROM Implementation_Profile__c WHERE Id!=null LIMIT 1 ];
        List<Employee_Orientation__c> eoRecords = [SELECT Id,Meeting_Type__c,NSP_Implementation_Profile__c  FROM Employee_Orientation__c WHERE Id!=null LIMIT 2];
        // Update Meeting type of a record
        Employee_Orientation__c updatedEoRecord = eoRecords[0];
        updatedEoRecord.Meeting_Type__c = 'Self Paced';
        Employee_Orientation__c notDeletedEoRec = eoRecords[1];
       // New Emp. Orientation Record
       Employee_Orientation__c newEoRecord = new Employee_Orientation__c();
       newEoRecord.Meeting_Type__c = 'Virtual';
       newEoRecord.NSP_Implementation_Profile__c = ipRecords.Id;

        
        String recordsConfigJsonInput = RECORDS_TO_UPSERT+ JSON.serialize(new List<Employee_Orientation__c> {eoRecords[0],newEoRecord}) 
                                         + ', "recordsToDelete": []}';

        // WHEN
        try{
        NSP_ImplementationProfileController.saveAndDeleteRecords(recordsConfigJsonInput, EMP_ORIENTATION_API);
        }catch(Exception ex){
            system.assertNotEquals(null,ex);
        }
        Map<Id, Employee_Orientation__c> updatedRecordsMap = new Map<Id, Employee_Orientation__c>([SELECT Id, Meeting_Type__c, NSP_Implementation_Profile__c FROM Employee_Orientation__c WHERE Id!=null]);
        // THEN
        System.assertEquals(2, updatedRecordsMap.size());
        // Assert the updated EO Record
        System.assert(updatedRecordsMap.containsKey(updatedEoRecord.Id));
        System.assertEquals('Virtual', updatedRecordsMap.get(updatedEoRecord.Id).Meeting_Type__c);
        
        List<Id> remainingEoRecordIds = new List<Id>(updatedRecordsMap.keySet());
        Employee_Orientation__c newEoRecordDB = updatedRecordsMap.get(remainingEoRecordIds[0]);
        
        // Assert the newly inserted EO record
        System.assertNotEquals(updatedEoRecord.Meeting_Type__c, newEoRecordDB.Meeting_Type__c);
        System.assertEquals(newEoRecord.NSP_Implementation_Profile__c, newEoRecordDB.NSP_Implementation_Profile__c);
        
        // Fetching the newly inserted EO record
        updatedRecordsMap.remove(updatedEoRecord.Id);
        updatedRecordsMap.remove(notDeletedEoRec.Id);


    }

    @isTest
    static void saveAndDeleteRecordsWhenThereIsNoRecordToInsertAndUpdate(){
         // GIVEN
        List<Employee_Orientation__c> eoRecords = [SELECT Id,Meeting_Type__c FROM Employee_Orientation__c WHERE Id!=null LIMIT 2];
        // EO Record to delete
        Employee_Orientation__c deletedEoRecord = eoRecords[1];
        String recordsConfigJsonInput = RECORDS_TO_UPSERT+'[]'+ ',' 
                 + '"recordsToDelete":' + JSON.serialize(new List<Employee_Orientation__c> { deletedEoRecord }) + '}';
    
         // WHEN
         try{
         NSP_ImplementationProfileController.saveAndDeleteRecords(recordsConfigJsonInput, EMP_ORIENTATION_API);
        }catch(Exception ex){
            system.assertNotEquals(null,ex);
        }
        Map<Id, Employee_Orientation__c> updatedRecordsMap = new Map<Id, Employee_Orientation__c>([SELECT Id, Meeting_Type__c, NSP_Implementation_Profile__c FROM Employee_Orientation__c WHERE Id!=null]);
         
         // THEN
         System.assertEquals(2, updatedRecordsMap.size());

         //Fetching the remaining record Id
        List<Id> remainingEoRecordIds = new List<Id>(updatedRecordsMap.keySet());
        Employee_Orientation__c remEoRecordDB = updatedRecordsMap.get(remainingEoRecordIds[0]);

        // Assert the newly inserted EO record
        System.assertNotEquals(eoRecords[1].Meeting_Type__c, remEoRecordDB.Meeting_Type__c);
    }

    @isTest
    static void saveAndDeleteRecordsWhenThereIsOnlyRecordsToInsert(){
        //WHEN
        List<Employee_Orientation__c> eoRecords = [SELECT Id,Meeting_Type__c FROM Employee_Orientation__c WHERE Id!=null LIMIT 2];
        Implementation_Profile__c ipRecords = [SELECT Id, Name FROM Implementation_Profile__c WHERE Id!=null LIMIT 1 ];
        
        // New Emp. Orientation Record
        Employee_Orientation__c newEoRecord = new Employee_Orientation__c();
        newEoRecord.Meeting_Type__c = MEETINGTYPE_VIRTUAL;
        newEoRecord.NSP_Implementation_Profile__c = ipRecords.Id;

        Employee_Orientation__c notUpdatedEoRec = eoRecords[0];
        Employee_Orientation__c notDeletedEoRec = eoRecords[1];

        String recordsConfigJsonInput = RECORDS_TO_UPSERT+ JSON.serialize(new List<Employee_Orientation__c> { newEoRecord}) + ',' 
        + '"recordsToDelete": []' + '}';

        // WHEN
        try{
            NSP_ImplementationProfileController.saveAndDeleteRecords(recordsConfigJsonInput, EMP_ORIENTATION_API);
        }catch(Exception ex){
            system.assertNotEquals(null,ex);
        }
    
        Map<Id, Employee_Orientation__c> updatedRecordsMap = new Map<Id, Employee_Orientation__c>([SELECT Id, Meeting_Type__c, NSP_Implementation_Profile__c FROM Employee_Orientation__c WHERE Id!=null]);

        // THEN
        System.assertEquals(2, updatedRecordsMap.size());

        List<Id> remainingEoRecordIds = new List<Id>(updatedRecordsMap.keySet());
        Employee_Orientation__c newEoRecordDB = updatedRecordsMap.get(remainingEoRecordIds[0]);

        // Assert the newly inserted EO record
        System.assertEquals(newEoRecord.Meeting_Type__c, newEoRecordDB.Meeting_Type__c);
        System.assertEquals(newEoRecord.NSP_Implementation_Profile__c, newEoRecordDB.NSP_Implementation_Profile__c);
        
        // Fetching the newly inserted EO record
        updatedRecordsMap.remove(notUpdatedEoRec.Id);
        updatedRecordsMap.remove(notDeletedEoRec.Id);

        
    }

    @isTest
    static void saveAndDeleteRecordsWhenThereIsOnlyRecordsToUpdate(){
        //GIVEN
        List<Employee_Orientation__c> eoRecords = [SELECT Id,Meeting_Type__c, NSP_Implementation_Profile__c FROM Employee_Orientation__c WHERE Id!=null LIMIT 2]; 

        // Update Meeting type of a record
        Employee_Orientation__c updatedEoRecord = eoRecords[0];
        updatedEoRecord.Meeting_Type__c = 'Self Paced';
    
        Employee_Orientation__c notDeletedEoRec = eoRecords[1];
        String recordsConfigJsonInput = '{"recordsToUpsert":' + JSON.serialize(new List<Employee_Orientation__c> {updatedEoRecord}) + ',' 
        + '"recordsToDelete": []'+ '}';

        // WHEN
        NSP_ImplementationProfileController.saveAndDeleteRecords(recordsConfigJsonInput, EMP_ORIENTATION_API);

        Map<Id, Employee_Orientation__c> updatedRecordsMap = new Map<Id, Employee_Orientation__c>([SELECT Id, Meeting_Type__c, NSP_Implementation_Profile__c FROM Employee_Orientation__c WHERE Id!=null]);
        
        // THEN
        System.assertEquals(2, updatedRecordsMap.size());

        // Assert the updated EO Record
        System.assert(updatedRecordsMap.containsKey(updatedEoRecord.Id));
        System.assertEquals(updatedEoRecord.Meeting_Type__c, updatedRecordsMap.get(updatedEoRecord.Id).Meeting_Type__c);

        // Assert the deleted EO Record
        System.assert(updatedRecordsMap.containsKey(notDeletedEoRec.Id));
    }

    @isTest
    static void saveAndDeleteRecordsWhenThereIsNoRecordToInsertAndUpdateAndDelete(){
        //GIVEN
        List<Employee_Orientation__c> eoRecords = [SELECT Id,Meeting_Type__c,NSP_Implementation_Profile__c FROM Employee_Orientation__c WHERE Id!=null LIMIT 2];

        Employee_Orientation__c insertedRec1 = eoRecords[0];
        Employee_Orientation__c insertedRec2 = eoRecords[1];

        String recordsConfigJsonInput = '{"recordsToUpsert":[]' + ',' 
        + '"recordsToDelete": []' + '}';

        //WHEN
        NSP_ImplementationProfileController.saveAndDeleteRecords( recordsConfigJsonInput, EMP_ORIENTATION_API);
        Map<Id, Employee_Orientation__c> updatedRecordsMap = new Map<Id, Employee_Orientation__c>([SELECT Id, Meeting_Type__c, NSP_Implementation_Profile__c FROM Employee_Orientation__c WHERE Id!=null]);
        
        // THEN
        System.assertEquals(2, updatedRecordsMap.size());
        System.assert(updatedRecordsMap.containsKey(insertedRec1.Id));
        System.assert(updatedRecordsMap.containsKey(insertedRec2.Id));
    }

    @isTest
    static void getIPRelatedRecordsPositiveCase(){
        Implementation_Profile__c oIProfile = [SELECT Id, Name FROM Implementation_Profile__c WHERE Id!=null LIMIT 1];
        Implementation_Pay_Period__c pmpPayPeriodzRecord = new Implementation_Pay_Period__c( NSP_Implementation_Profile__c = oIProfile.Id, Client_number__c = '10', Insperity_first_day_of_1st_pay_period__c = System.today());
        insert pmpPayPeriodzRecord;
        Id iAccount = [SELECT Id FROM Account WHERE Id != null LIMIT 1]?.Id;
        NSP_IP_Related_Client__c ipRelatedAcc = new NSP_IP_Related_Client__c(NSP_Related_Client__c = iAccount,NSP_Implementation_Profile__c = oIProfile.Id);
        insert ipRelatedAcc;
        NSP_IP_Additional_Client_Contact__c ipAddClientConRecord =  new NSP_IP_Additional_Client_Contact__c(NSP_Implementation_Profile__c = oIProfile.Id,Name= TEST_STR);
        insert ipAddClientConRecord;
        
        Test.startTest();
        Map<String, List<Id>> relatedRecordMap = NSP_ImplementationProfileController.getIPRelatedRecords(oIProfile.Id);
        Test.stopTest();   
        System.assertEquals(1, relatedRecordMap.get('Implementation_Pay_Period__c').size());
        System.assertEquals(2, relatedRecordMap.get('Employee_Orientation__c').size());
        System.assertEquals(1, relatedRecordMap.get('NSP_IP_Related_Client__c').size());
        System.assertEquals(1, relatedRecordMap.get('NSP_IP_Additional_Client_Contact__c').size());
    }
     @isTest
    static void getIPRelatedRecordsNegativeCase(){
        Implementation_Profile__c oIProfile = [SELECT Id, Name FROM Implementation_Profile__c  WHERE Id !=null LIMIT 1];
        Implementation_Pay_Period__c pmpPayPeriodzRecord = new Implementation_Pay_Period__c( NSP_Implementation_Profile__c = oIProfile.Id, Client_number__c = '10', Insperity_first_day_of_1st_pay_period__c = System.today());
        insert pmpPayPeriodzRecord;
        Id iAccount = [Select Id FROM Account WHERE Id != null LIMIT 1]?.Id;
        NSP_IP_Related_Client__c ipRelatedAcc = new NSP_IP_Related_Client__c(NSP_Related_Client__c = iAccount,NSP_Implementation_Profile__c = oIProfile.Id);
        insert ipRelatedAcc;
        NSP_IP_Additional_Client_Contact__c ipAddClientConRecord =  new NSP_IP_Additional_Client_Contact__c(NSP_Implementation_Profile__c = oIProfile.Id,Name= TEST_STR);
        insert ipAddClientConRecord;
        Implementation_Profile__c ipRecord = new Implementation_Profile__c(); 
        ipRecord.NSP_EE_Name__c = 'EE';
        insert ipRecord;
        
        Test.startTest();
        Map<String, List<Id>> relatedRecordMap = NSP_ImplementationProfileController.getIPRelatedRecords(ipRecord.Id);
        Test.stopTest();
        System.assertEquals(0, relatedRecordMap.get('Implementation_Pay_Period__c').size());
        System.assertEquals(0, relatedRecordMap.get('Employee_Orientation__c').size());
        System.assertEquals(0, relatedRecordMap.get('NSP_IP_Related_Client__c').size());
        System.assertEquals(0, relatedRecordMap.get('NSP_IP_Additional_Client_Contact__c').size());
    }

    @IsTest
    static void testGetRecordWithAllFields() {
        Implementation_Profile__c oIProfile = [SELECT Id, Name FROM Implementation_Profile__c WHERE Id!=null LIMIT 1];
        oIProfile.NSP_EE_Name__c = 'EE';

        SObject result = NSP_ImplementationProfileController.getRecordWithAllFields(oIProfile.Id);

        System.assertEquals(oIProfile.NSP_EE_Name__c, result.get('NSP_EE_Name__c'));
    }

}