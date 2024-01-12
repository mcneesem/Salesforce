/**
    Apex Class Name      :  NSP_LookupOptionTest
    Version              :  1.0
    Created Date         :  11/7/2022
    Function             :  This class is used as a test class of NSP_LookupOption class
    Author               :  Renuka
    Story                :   
*/
@isTest
private class NSP_LookupOptionTest {
    @isTest
    static void checkingEqualsShouldReturnTrueWhenObjectValuesAreEqual() {
        //GIVEN
        NSP_LookupOption obj1 = new NSP_LookupOption(NSP_CPQConstants.TESTLABEL,NSP_CPQConstants.TESTVALUE,NSP_CPQConstants.TESTINFO,NSP_CPQConstants.TESTICONNAME,true);
        NSP_LookupOption obj2 = new NSP_LookupOption(NSP_CPQConstants.TESTLABEL,NSP_CPQConstants.TESTVALUE,NSP_CPQConstants.TESTINFO,NSP_CPQConstants.TESTICONNAME,true);

        //WHEN
        Boolean isResultTrue = obj1.equals(obj2);

        //THEN
        System.assertEquals(true, isResultTrue);
    }

    @isTest
    static void checkingEqualsShouldReturnFalseWhenObjectisNull() {
        //GIVEN
        NSP_LookupOption obj1 = new NSP_LookupOption(NSP_CPQConstants.TESTLABEL,NSP_CPQConstants.TESTVALUE,NSP_CPQConstants.TESTINFO,NSP_CPQConstants.TESTICONNAME,true);
        NSP_LookupOption obj2 = null;

        //WHEN
        Boolean isResultFalse = obj1.equals(obj2);

        //THEN
        System.assertEquals(false, isResultFalse);
    }

    @isTest
    static void checkingEqualsShouldReturnTrueWhenObjectReferencesAreSame() {
        //GIVEN
        NSP_LookupOption obj1 = new NSP_LookupOption(NSP_CPQConstants.TESTLABEL,NSP_CPQConstants.TESTVALUE,NSP_CPQConstants.TESTINFO,NSP_CPQConstants.TESTICONNAME,true);
        NSP_LookupOption obj2 = obj1;

        //WHEN
        Boolean isResultTrue = obj1.equals(obj2);

        //THEN
        System.assertEquals(true, isResultTrue);
    }

    @isTest
    static void checkingEqualsShouldReturnFalseWhenObjectIsNotAnInstance() {
        //GIVEN
        NSP_LookupOption obj1 = new NSP_LookupOption(NSP_CPQConstants.TESTLABEL,NSP_CPQConstants.TESTVALUE,NSP_CPQConstants.TESTINFO,NSP_CPQConstants.TESTICONNAME,true);
        Account obj2 = new Account();

        //WHEN
        Boolean isResultFalse = obj1.equals(obj2);

        //THEN
        System.assertEquals(false, isResultFalse);
    }

    @isTest
    static void hashCodeGeneration() {
        //GIVEN
        NSP_LookupOption loopUpOptionVar = new NSP_LookupOption(NSP_CPQConstants.TESTLABEL,NSP_CPQConstants.TESTVALUE,NSP_CPQConstants.TESTINFO,NSP_CPQConstants.TESTICONNAME,true);

        //WHEN
        Integer result = loopUpOptionVar.hashCode();

        //THEN
        System.assertNotEquals(null, result);
    }
}