@isTest
private class NSP_RelatedIPPayPeriodControllerTest{
    @TestSetup
    static void setupData(){
        // Create Implementation Profile record
        Implementation_Profile__c impProfileObj = new Implementation_Profile__c ();
        insert impProfileObj;

		// Create Implementation Profile Pay Period records
        List<Implementation_Pay_Period__c> payPeriods = new List<Implementation_Pay_Period__c>();
        Implementation_Pay_Period__c payPeriodObj = new Implementation_Pay_Period__c();
        payPeriodObj.NSP_Implementation_Profile__c = impProfileObj.Id;
        payPeriods.add(payPeriodObj);

        Implementation_Pay_Period__c payPeriodObj1 = new Implementation_Pay_Period__c();
        payPeriodObj1.NSP_Implementation_Profile__c = impProfileObj.Id;
        payPeriods.add(payPeriodObj1);

        insert payPeriods;
        
        // Create Implementation Profile Pay Period records
        List<NSP_IP_Additional_Client_Contact__c> iaccList = new List<NSP_IP_Additional_Client_Contact__c>();
        NSP_IP_Additional_Client_Contact__c iacc = new NSP_IP_Additional_Client_Contact__c();
        iacc.NSP_Implementation_Profile__c = impProfileObj.Id;
        iaccList.add(iacc);

        NSP_IP_Additional_Client_Contact__c iacc1 = new NSP_IP_Additional_Client_Contact__c();
        iacc1.NSP_Implementation_Profile__c = impProfileObj.Id;
        iaccList.add(iacc1);

        insert iaccList;
    }

    @isTest
    static void relatedIPpayPeriods_shouldReturnEmptyList_whenRecordIdIsNull(){
        // GIVEN, WHEN
        List<Implementation_Pay_Period__c> records = NSP_RelatedIPPayPeriodController.relatedIPpayPeriods;
        
        // THEN
        System.assertEquals(null, records, 'List should be null.');
    }

    @isTest
    static void relatedIPpayPeriods_shouldReturnCorrectList_whenValidRecordIdIsGiven(){
        // GIVEN
        Implementation_Profile__c ipObj = [SELECT Id FROM Implementation_Profile__c WHERE Id != null LIMIT 1];
        NSP_RelatedIPPayPeriodController.setrecId(ipObj.Id);
        
        // WHEN
        List<Implementation_Pay_Period__c> records = NSP_RelatedIPPayPeriodController.relatedIPpayPeriods;
        
        // THEN
        System.assertEquals(ipObj.Id, NSP_RelatedIPPayPeriodController.getrecId(), 'Record Id should be same.');
    }
    
    @isTest
    static void additionalClientCont_shouldReturnEmptyList_whenRecordIdIsNull(){
        // GIVEN, WHEN
        List<NSP_IP_Additional_Client_Contact__c> records = NSP_RelatedIPPayPeriodController.additionalClientContacts;
        
        // THEN
        System.assertEquals(null, records, 'List should be null.');
    }

    @isTest
    static void additionalClientCont_shouldReturnCorrectList_whenValidRecordIdIsGiven(){
        // GIVEN
        Implementation_Profile__c ipObj = [SELECT Id FROM Implementation_Profile__c WHERE Id != null LIMIT 1];
        NSP_RelatedIPPayPeriodController.setrecId(ipObj.Id);
        
        // WHEN
        List<NSP_IP_Additional_Client_Contact__c> records = NSP_RelatedIPPayPeriodController.additionalClientContacts;
        
        // THEN
        System.assertEquals(ipObj.Id, NSP_RelatedIPPayPeriodController.getrecId(), 'Record Id should be same.');
    }
    @isTest
    static void additionalArrearageFrequency_shouldReturnEmptyList_whenRecordIdIsNull(){
        // GIVEN, WHEN
        List<Implementation_Pay_Period__c> records = NSP_RelatedIPPayPeriodController.additionalArrearageFrequency;
        
        // THEN
        System.assertEquals(null, records, 'List should be null.');
    }

    @isTest
    static void additionalArrearageFrequency_shouldReturnCorrectList_whenValidRecordIdIsGiven(){
        // GIVEN
        Implementation_Profile__c ipObj = [SELECT Id FROM Implementation_Profile__c WHERE Id != null LIMIT 1];
        NSP_RelatedIPPayPeriodController.setrecId(ipObj.Id);
        
        // WHEN
        List<Implementation_Pay_Period__c> records = NSP_RelatedIPPayPeriodController.additionalArrearageFrequency;
        
        // THEN
        System.assertEquals(ipObj.Id, NSP_RelatedIPPayPeriodController.getrecId(), 'Record Id should be same.');
    }
}