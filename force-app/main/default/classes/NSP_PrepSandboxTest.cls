@isTest
class NSP_PrepSandboxTest {

    @isTest
    static void testSandboxPrep() {
        // Insert logic here to create records of the objects that the class your testing manipulates.
        Integer queueCount = 0;

        Test.startTest();
        //Execute test script with RunAsAutoProcUser set to true
        Test.testSandboxPostCopyScript(new NSP_PrepSandbox(), UserInfo.getOrganizationId(),
                UserInfo.getOrganizationId(), UserInfo.getOrganizationName(), true);
        Test.stopTest();

        // Insert assert statements here to check that the records you created above have the values you expect.        
        for(Group queue:[SELECT id, email FROM Group WHERE type = 'Queue' AND email > ''])
        {
            if(queue.email.indexOf('.invalid') == -1){
                queueCount++;
            }
        }
        System.assertEquals(0, queueCount);
    }

    @isTest(SeeAllData = True)
    static void testManualSteps() {
        Test.startTest();
        NSP_PrepSandbox.doE2CAddresses('test');
        NSP_PrepSandbox.doCLabels('merge');
        NSP_PrepSandbox.doCLabels('test');
        NSP_PrepSandbox.doCLabels('stage');
        NSP_PrepSandbox.doCSettings('merge');
        NSP_PrepSandbox.doCSettings('test');
        Test.stopTest();
    }

    @isTest
    static void testPageRef() {
        Test.startTest();
        PageReference pageRef = Page.SandboxManualSteps;
        Test.setCurrentPage(pageRef);
        NSP_PrepSandbox prep = new NSP_PrepSandbox();
        System.assertEquals(null,prep.resetResult());
        System.assertEquals(null,prep.doUserImportPage());
        System.assertEquals(null,prep.runManualStepsButton());
        System.assertEquals(null,prep.runManualStepsButton2());
        System.assertEquals(null,prep.runE2CAddressesButton());
        Test.stopTest();
    }
}