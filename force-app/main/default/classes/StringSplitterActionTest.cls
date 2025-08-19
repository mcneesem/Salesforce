@isTest
private class StringSplitterActionTest {
   @isTest
   private static void testSplitString() {
        // Test data setup
        StringSplitterAction.FlowInput input1 = new StringSplitterAction.FlowInput();
        input1.inputString = 'apple,banana,cherry';
        input1.inputSeparator = ',';

        StringSplitterAction.FlowInput input2 = new StringSplitterAction.FlowInput();
        input2.inputString = 'dog;cat;mouse';
        input2.inputSeparator = ';';

        List<StringSplitterAction.FlowInput> inputs = new List<StringSplitterAction.FlowInput>{
            input1,
            input2
        };

        // Call the method
        List<StringSplitterAction.FlowOutput> outputs = StringSplitterAction.splitString(inputs);

        // Assertions
        System.assertEquals(2, outputs.size());
        System.assertEquals(3, outputs[0].resultList.size());
        System.assertEquals('apple', outputs[0].resultList[0]);
        System.assertEquals('banana', outputs[0].resultList[1]);
        System.assertEquals('cherry', outputs[0].resultList[2]);

        System.assertEquals(3, outputs[1].resultList.size());
        System.assertEquals('dog', outputs[1].resultList[0]);
        System.assertEquals('cat', outputs[1].resultList[1]);
        System.assertEquals('mouse', outputs[1].resultList[2]);
    }
}