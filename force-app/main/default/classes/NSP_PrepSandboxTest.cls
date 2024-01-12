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
        NSP_PrepSandbox.runManualSteps();
        NSP_PrepSandbox.runManualSteps2();
        NSP_PrepSandbox.doUserImport('sandbox');
        Test.stopTest();
    }
}