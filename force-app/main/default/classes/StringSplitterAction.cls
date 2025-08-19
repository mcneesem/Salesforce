public with sharing class StringSplitterAction {
    // test w/ StringSplitterActionTest (100%)

    @InvocableMethod(label='Split String' description='Returns a list that contains each substring of the String that is terminated by either the seperator or the end of the String.')
    public static List<FlowOutput> splitString( List<FlowInput> inputs ) {
        List<FlowOutput> outputs = new List<FlowOutput>();
        if( ( inputs != null ) && !inputs.isEmpty() ){
            for ( FlowInput input : inputs ) {
                FlowOutput output = new FlowOutput();
                output.resultList = new List<String>();
                if ( String.isNotBlank( input.inputString )
                    && String.isNotBlank( input.inputSeparator )
                    )
                {
                    output.resultList = input.inputString.split( input.inputSeparator );
                }
                outputs.add( output );
            }
        }
        return outputs;
    }

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

}
//