/* Description : Test class for NSP_SAEmail_DateTimeController
    Date        : 06/08/2023 */
    @IsTest
    public class NSP_SAEmail_DateTimeControllerTest {
        private static final String PEOProjectTaskRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT_TASK_SOBJECT_TYPE,NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE);
        private static final Id peoProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', 'PEO_Project');
        @testSetup
        private static void setupProjectTaskdata(){
            
             //Creating Account
            User newUser = [select Id,NSP_Salesforce_Field_Service__c FROM User WHERE ID =: userInfo.getUserId()];
            newUser.NSP_Salesforce_Field_Service__c = 'Dispatcher';
            Update newUser;
            Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', true);
            WorkType oWorkType = (WorkType)NSP_TestExtendedDataFactory.createSObject(new WorkType(), 'NSP_TestDataFactory.WorkTypeDefaults', false);
            oWorkType.Name = NSP_ServiceConstants.WORKTYPE_NAME;
            Database.insert(oWorkType);
            
            // Creating Project
            test.startTest();
            pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
            oProject.Name = 'Proj1';
            oProject.RecordTypeId = peoProjectRecordTypeId;
            oProject.Templates_Used__c = 'Temp Used';
            oProject.pse__Start_Date__c = System.today();
            oProject.pse__End_Date__c = System.today()+1;
            oProject.pse__Project_Type__c = 'Implementation';
            insert oProject;
            
            // Creating Project Task
            pse__Project_Task__c oProjectTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
            oProjectTask.pse__Project__c = oProject.Id;
            oProjectTask.Name = 'Test rec';
            oProjectTask.RecordTypeId = PEOProjectTaskRecordTypeId;
            oProjectTask.NSP_Percentage_Complete__c = '100%';
            oProjectTask.pse__Start_Date_Time__c = system.now();
            oProjectTask.pse__End_Date_Time__c = system.now().addMinutes(60);
            oProjectTask.NSP_Create_Work_Order__c = true;
            oProjectTask.OwnerId = newUser.Id;
            oProjectTask.NSP_Dispatch_Region__c = 'Central';
            insert oProjectTask;
            
            test.stopTest();
     
        }
        
        @isTest
        public static void testGetAssignedResource() {
            Test.startTest();
            FSL.GlobalAPIS.addStatusTransition('Unscheduled', 'Scheduled');
            pse__Proj__c oproj = [SELECT Id, Name FROM pse__Proj__c WHERE Templates_Used__c = 'Temp Used'];
            pse__Project_Task__c oprojTask = [SELECT Id, Name, OwnerId FROM pse__Project_Task__c WHERE pse__Project__c =: oProj.Id];
            
            WorkOrder workOrder = [SELECT Id, NSP_Project_Task__c, StartDate, Description, OwnerId FROM WorkOrder WHERE NSP_Project_Task__c =: oprojTask.Id];
            
            ServiceAppointment sappointment = [SELECT Id, NSP_IsDispatched__c,Status,SchedEndTime, SchedStartTime,Description, OwnerId FROM ServiceAppointment WHERE ParentRecordId!=null AND ParentRecordId =: workOrder.Id LIMIT 1];
            sappointment.Description = 'Updated from test clas';
            sappointment.SchedEndTime = system.today().addDays(10);
            sappointment.SchedStartTime =system.today().addDays(1);   
            Database.update(sappointment);  
            
            ServiceResource  srv = new ServiceResource();
            srv.IsActive= true;
            srv.Name = 'Test';
            srv.RelatedRecordId = userInfo.getUserId();
            insert srv;
            
            OperatingHours opHrs = new OperatingHours();
            opHrs.Name ='EST';
            insert opHRS;
            
            ServiceTerritory serTer = new ServiceTerritory();
            serTer.IsActive = true;
            serTer.Name = 'Test';
            serTer.OperatingHoursId = opHrs.Id;
            insert serTer;
            
            ServiceTerritoryMember stm = new ServiceTerritoryMember();
            stm.ServiceResourceId = srv.Id;
            stm.ServiceTerritoryId = serTer.Id;
            stm.EffectiveStartDate = system.today();
            insert stm;
            
            AssignedResource assRes = new AssignedResource();
            assRes.ServiceAppointmentId = sappointment.Id;
            assRes.ServiceResourceId = srv.Id;
            insert assRes;
            test.stopTest();
            
            NSP_SAEmail_DateTimeController.setrecId(sappointment.Id);
            NSP_SAEmail_DateTimeController controller = new NSP_SAEmail_DateTimeController();
            AssignedResource actualAssignedResource = controller.getAssignedResource();
            
            System.assertEquals(assRes.ServiceAppointmentId, actualAssignedResource.ServiceAppointmentId);
            
            String actualOperatingHours = controller.getOperatingHours();
            System.assertEquals('EST', actualOperatingHours);
            
            String actualOperatingHoursName = controller.getOperatingHoursName();
            System.assertEquals('Eastern Time', actualOperatingHoursName);
            
            controller.date_time = DateTime.newInstanceGmt(2023, 6, 8, 10, 30, 0);
            controller.defined_format = 'MM/dd/yyyy hh:mm aa';
            String formattedDatetime = controller.getFormattedDatetime();
            System.assertNotEquals(null, formattedDatetime);
        }
        
        @IsTest
        static void testGetStartTime() {
            NSP_SAEmail_DateTimeController controller = new NSP_SAEmail_DateTimeController();
            controller.date_time = DateTime.newInstanceGmt(2023, 6, 8, 9, 0, 0);
            String startTime = controller.getStartTime();
               System.assertNotEquals(null, startTime);
        }
        
        @IsTest
        static void testGetEndTime() {
            NSP_SAEmail_DateTimeController controller = new NSP_SAEmail_DateTimeController();
            controller.endDate = DateTime.newInstanceGmt(2023, 6, 8, 18, 30, 0);
            String endTime = controller.getEndTime();
            System.assertNotEquals(null, endTime);
        }
    }