/**
    Apex Class Name      :  NSP_QueryBuilderTest
    Version              :  1.0   
    Author               :  Srushti Bikkannavar
    Created Date         :  9/30/2022
    Function             :  This class is used as a test class to NSP_QueryBuilder
    Story                :
*/

@isTest
private class NSP_QueryBuilderTest {
    private static final String OBJECT_NAME = 'Implementation_Profile__c';
    private static List<String> FIELDS = new List<String>{'NSP_Assignment_Notes__c', 'NSP_Benefit_Notes__c'};

    //This Method will test the query without any filters
    @isTest
    static void buildQueryWithoutFilter(){
        // GIVEN, WHEN
        String query = new NSP_QueryBuilder(OBJECT_NAME, FIELDS).build();
        
        // THEN
        System.assertEquals('SELECT NSP_Assignment_Notes__c, NSP_Benefit_Notes__c FROM ' + OBJECT_NAME + ' WITH SECURITY_ENFORCED ', query);
    }

    //This method will test the query when the input is object name 
    @isTest
    static void buildQueryWithObjectNameOnly(){
        // GIVEN, WHEN
        String query = new NSP_QueryBuilder(OBJECT_NAME).build();
        
        // THEN
        System.assertEquals('SELECT Name FROM ' + OBJECT_NAME +' WITH SECURITY_ENFORCED ', query);
    }

    @isTest
    static void buildQueryWithoutSecurityEnforce(){
        String query = new NSP_QueryBuilder(OBJECT_NAME).setSecurityEnforce(false).build();

        System.assertEquals('SELECT Name FROM ' + OBJECT_NAME , query);
        
    }

    //This method will check the query when the input fields are null
    @isTest
    static void buildQueryWhenFieldNameisNull(){
        // GIVEN, WHEN
        String query = new NSP_QueryBuilder(OBJECT_NAME, null).build();
     
        // THEN
        System.assertEquals('SELECT Name FROM ' + OBJECT_NAME + ' WITH SECURITY_ENFORCED ', query);
    }

    //This method will check the query when where condition is given i.e when filter is added
    @isTest
    static void buildQueryWithWhereConditionOnly(){
        // GIVEN
        String expectedQuery = 'SELECT NSP_Assignment_Notes__c, NSP_Benefit_Notes__c FROM Implementation_Profile__c WHERE NSP_Benefit_Notes__c = \'Test Benefit\' WITH SECURITY_ENFORCED ';

        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder(OBJECT_NAME, FIELDS);
        queryBuilder.addFilter('NSP_Benefit_Notes__c', 'Test Benefit' , NSP_QueryBuilder.Operator.EQUALS,true);

        // WHEN
        String actualQuery = queryBuilder.build();
        System.assertEquals(expectedQuery, actualQuery);
    }

    //This method will check the query when multiple where conditions are given as input
    @istest
    static void buildQueryWithMultipleWhereConditions(){
        // GIVEN
        String expectedQuery = 'SELECT NSP_Assignment_Notes__c, NSP_Benefit_Notes__c FROM Implementation_Profile__c WHERE NSP_Assignment_Notes__c = 123 AND NSP_Assignment_Notes__c = 12345 AND NSP_Benefit_Notes__c LIKE \'Test Benefit\' AND FSA_Notes__c NOT IN (\'Test FSA\') AND NSP_RS_Contact_Work_Phone__c IN (9876543210) AND NSP_Form_Completed__c = true AND NSP_Check_to_create_the_RRP_Case__c != true AND NSP_Assignment_Notes__c = \'aA33C0000004aWsSAI\' AND NSP_Assignment_Notes__c IN (\'aA33C0000004aWsSAI\', \'aA33C0000004aX2SAI\') WITH SECURITY_ENFORCED ';
        Id impId = 'aA33C0000004aWsSAI';
        Integer sampleData = 12345;
        List<String> fieldValues = new List<String>{'aA33C0000004aWsSAI', 'aA33C0000004aX2SAI'};
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder(OBJECT_NAME, FIELDS);

        // WHEN
        queryBuilder.addFilter('NSP_Assignment_Notes__c', '123' , NULL,false)
            .addFilter('NSP_Assignment_Notes__c', sampleData)
            .addFilter('NSP_Benefit_Notes__c', 'Test Benefit' , NSP_QueryBuilder.Operator.LIKES,true)
            .addFilter('FSA_Notes__c', 'Test FSA' , NSP_QueryBuilder.Operator.NOT_IN,true)
            .addFilter('NSP_RS_Contact_Work_Phone__c', '9876543210' , NSP_QueryBuilder.Operator.INCLUDES,false)
            .addFilter('NSP_Form_Completed__c', true , NSP_QueryBuilder.Operator.EQUALS,false)
            .addFilter('NSP_Check_to_create_the_RRP_Case__c', true , NSP_QueryBuilder.Operator.NOT_EQUALS,false)
            .addFilter('NSP_Assignment_Notes__c', impId)
            .addFilter('NSP_Assignment_Notes__c', fieldValues , NSP_QueryBuilder.Operator.INCLUDES);

        String actualQuery = queryBuilder.build();

        // THEN
        System.assertEquals(expectedQuery, actualQuery);
    }
    
    //This method will check the query when we pass limit of the records 
    @istest
    static void buildQueryByAddingLimit(){
        //GIVEN
        String expectedQuery = 'SELECT NSP_Assignment_Notes__c, NSP_Benefit_Notes__c FROM Implementation_Profile__c WITH SECURITY_ENFORCED  LIMIT 1';
        Integer recordSize = 1;
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder(OBJECT_NAME, FIELDS);

        //WHEN
        queryBuilder.addLimit(recordSize);
        String actualQuery = queryBuilder.build();

        //THEN
        System.assertEquals(expectedQuery, actualQuery);
    }

    //This method will check the query when there is no limit
    @istest
    static void addingLimitWhenRecordSizeIsNull(){
        //GIVEN
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder(OBJECT_NAME, FIELDS);
        Integer recordSize = null;

        //WHEN
        String query = queryBuilder.addLimit(recordSize).build();

        //THEN
        System.assertEquals('SELECT NSP_Assignment_Notes__c, NSP_Benefit_Notes__c FROM ' + OBJECT_NAME + ' WITH SECURITY_ENFORCED ', query);
    }

    //This method will check the query when where and limit conditions are given as input
    @isTest
    static void buildQueryWithWhereConditionAndLimit(){
        // GIVEN
        String expectedQuery = 'SELECT NSP_Assignment_Notes__c, NSP_Benefit_Notes__c FROM Implementation_Profile__c WHERE NSP_Benefit_Notes__c = \'Test Benefit\' WITH SECURITY_ENFORCED  LIMIT 1';
        Integer recordSize = 1;
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder(OBJECT_NAME, FIELDS);

        //WHEN
        queryBuilder.addFilter('NSP_Benefit_Notes__c', 'Test Benefit' , NSP_QueryBuilder.Operator.EQUALS);
        queryBuilder.addLimit(recordSize);
        String actualQuery = queryBuilder.build();

        //THEN
        System.assertEquals(expectedQuery, actualQuery);
    }

    @isTest
    static void buildQueryWithMultipleWhereConditionAndLimit(){
        // GIVEN
        String expectedQuery = 'SELECT NSP_Assignment_Notes__c, NSP_Benefit_Notes__c FROM Implementation_Profile__c WHERE NSP_Assignment_Notes__c = \'Test\' AND NSP_Benefit_Notes__c LIKE \'%Test Benefit%\' AND FSA_Notes__c NOT IN (\'Test FSA\') AND NSP_Form_Completed__c = true WITH SECURITY_ENFORCED  LIMIT 10';
        Integer recordSize = 10;
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder(OBJECT_NAME, FIELDS);

        //WHEN
        queryBuilder.addFilter('NSP_Assignment_Notes__c', 'Test')
        .addContainsFilter('NSP_Benefit_Notes__c', 'Test Benefit')
        .addFilter('FSA_Notes__c', 'Test FSA' , NSP_QueryBuilder.Operator.NOT_IN)
        .addFilter('NSP_Form_Completed__c', true , NSP_QueryBuilder.Operator.EQUALS);
        
        queryBuilder.addLimit(recordSize);
        String actualQuery = queryBuilder.build();

        //THEN
        System.assertEquals(expectedQuery, actualQuery);
    }
    
    @isTest
    static void buildQueryWithStartAndEndFilters(){
        //GIVEN
        String ExpectedQuery = 'SELECT NSP_Assignment_Notes__c, NSP_Benefit_Notes__c FROM Implementation_Profile__c WHERE NSP_Assignment_Notes__c LIKE \'Test%\' AND NSP_Benefit_Notes__c LIKE \'%Test Benefit\' WITH SECURITY_ENFORCED ';
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder(OBJECT_NAME, FIELDS);

        //WHEN
        queryBuilder.addStartsWithFilter('NSP_Assignment_Notes__c','Test')
                    .addEndsWithFilter('NSP_Benefit_Notes__c','Test Benefit');
        String actualQuery = queryBuilder.build();

        //THEN
        System.assertEquals(expectedQuery, actualQuery);
    }
}