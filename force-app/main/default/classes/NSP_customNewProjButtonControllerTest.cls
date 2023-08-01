/* Description : Test class for NSP_customNewProjButtonController
    Date        : 02/02/2023 */
    @isTest
    private class NSP_customNewProjButtonControllerTest {
    
        @testSetup
        static void setupUserData(){
            
        }
    
        @isTest
        static void isadminUserPermissionToCreateProjectTest(){
            //Given
            User UserRec = [ SELECT Id FROM USER WHERE NSP_Profile_Name__c = 'System Administrator' LIMIT 1];
    
            //When
            test.startTest();
             Boolean isUserPemitted = NSP_customNewProjButtonController.isUserPermittedToCreateProject(UserRec.Id);
            test.stopTest();
            //then
            System.assertEquals(true , isUserPemitted, 'user is permitted to create proj rec');
        }
    }