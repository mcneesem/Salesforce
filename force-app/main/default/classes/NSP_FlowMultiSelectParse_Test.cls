@isTest
public class NSP_FlowMultiSelectParse_Test{
    @isTest
    static void NSP_FlowMultiSelectParse(){
        List<string> tempLst = new list<string>();
        tempLst.add('Sales Office 1');
        tempLst.add('Sales Office 2');
        NSP_FlowMultiSelectParse.CheckValues(tempLst);
    }

}