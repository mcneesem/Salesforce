@isTest
private class StringSplitterActionTest {
    @isTest
    static void testSplitBySpace() {
        // Setup test data
        StringSplitterAction.FlowInput input = new StringSplitterAction.FlowInput();
        input.inputString = 'test1@insperity.com test2@insperity.com';
        input.inputSeparator = ' ';
        
        List<StringSplitterAction.FlowInput> inputs = new List<StringSplitterAction.FlowInput>{input};
        
        // Execute the test
        Test.startTest();
        List<StringSplitterAction.FlowOutput> outputs = StringSplitterAction.splitString(inputs);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, outputs.size(), 'Should return a single output object');
        List<String> results = outputs[0].resultList;
        System.assertEquals(2, results.size(), 'Should split into 2 email addresses');
        System.assertEquals('test1@insperity.com', results[0], 'First email should match');
        System.assertEquals('test2@insperity.com', results[1], 'Second email should match');
    }
    
    @isTest
    static void testSplitByComma() {
        // Test with comma separator
        StringSplitterAction.FlowInput input = new StringSplitterAction.FlowInput();
        input.inputString = 'john.doe@example.com,jane.doe@example.com,admin@example.com';
        input.inputSeparator = ',';
        
        List<StringSplitterAction.FlowInput> inputs = new List<StringSplitterAction.FlowInput>{input};
        
        Test.startTest();
        List<StringSplitterAction.FlowOutput> outputs = StringSplitterAction.splitString(inputs);
        Test.stopTest();
        
        System.assertEquals(1, outputs.size());
        List<String> results = outputs[0].resultList;
        System.assertEquals(3, results.size(), 'Should split into 3 email addresses');
        System.assertEquals('john.doe@example.com', results[0]);
        System.assertEquals('jane.doe@example.com', results[1]);
        System.assertEquals('admin@example.com', results[2]);
    }
    
    @isTest
    static void testEmptyString() {
        // Test with empty input string
        StringSplitterAction.FlowInput input = new StringSplitterAction.FlowInput();
        input.inputString = '';
        input.inputSeparator = ' ';
        
        List<StringSplitterAction.FlowInput> inputs = new List<StringSplitterAction.FlowInput>{input};
        
        Test.startTest();
        List<StringSplitterAction.FlowOutput> outputs = StringSplitterAction.splitString(inputs);
        Test.stopTest();
        
        System.assertEquals(1, outputs.size());
        List<String> results = outputs[0].resultList;
        System.assertEquals(0, results.size(), 'Empty string should return empty list');
    }
    
    @isTest
    static void testNullString() {
        // Test with null input string
        StringSplitterAction.FlowInput input = new StringSplitterAction.FlowInput();
        input.inputString = null;
        input.inputSeparator = ' ';
        
        List<StringSplitterAction.FlowInput> inputs = new List<StringSplitterAction.FlowInput>{input};
        
        Test.startTest();
        List<StringSplitterAction.FlowOutput> outputs = StringSplitterAction.splitString(inputs);
        Test.stopTest();
        
        System.assertEquals(1, outputs.size());
        List<String> results = outputs[0].resultList;
        System.assertEquals(0, results.size(), 'Null string should return empty list');
    }
    
    @isTest
    static void testMultipleInputs() {
        // Test handling of multiple inputs (should only process first)
        StringSplitterAction.FlowInput input1 = new StringSplitterAction.FlowInput();
        input1.inputString = 'first@example.com second@example.com';
        input1.inputSeparator = ' ';
        
        StringSplitterAction.FlowInput input2 = new StringSplitterAction.FlowInput();
        input2.inputString = 'ignored@example.com';
        input2.inputSeparator = ' ';
        
        List<StringSplitterAction.FlowInput> inputs = new List<StringSplitterAction.FlowInput>{input1, input2};
        
        Test.startTest();
        List<StringSplitterAction.FlowOutput> outputs = StringSplitterAction.splitString(inputs);
        Test.stopTest();
        
        System.assertEquals(1, outputs.size(), 'Should only return one output object');
        List<String> results = outputs[0].resultList;
        System.assertEquals(2, results.size(), 'Should split into 2 email addresses from first input only');
        System.assertEquals('first@example.com', results[0]);
        System.assertEquals('second@example.com', results[1]);
    }
}