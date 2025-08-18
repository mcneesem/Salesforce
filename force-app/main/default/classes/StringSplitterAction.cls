public class StringSplitterAction {
    // test w/ StringSplitterActionTest (100%)
	public class FlowInput {
        @InvocableVariable(label='String to Split' required=true)
        public String inputString;
        
        @InvocableVariable(label='Seperator' required=true)
        public String inputSeparator;
    }
    
    public class FlowOutput {
        @InvocableVariable(label='Split String Results')
        public List<String> resultList;
    }
    
    @InvocableMethod(label='Split String to List' description='Splits a string and returns a list')
    public static List<FlowOutput> splitString(List<FlowInput> inputs) {

        FlowInput input = inputs[0];
        System.debug('input: ' + input);
        FlowOutput output = new FlowOutput();
        
        if (String.isNotBlank(input.inputString)) {
            output.resultList = input.inputString.split(input.inputSeparator);
        } else {
            output.resultList = new List<String>();
        }
        System.debug('output.resultList: ' + output.resultList);
        return new List<FlowOutput>{ output };
    }
}