public with sharing class ServiceAppointmentSyncQueueable implements Queueable {
    // test w/ ServiceAppointmentSyncQueueableTest (93%)

    //
    // public entry points...
    //

    public static void enqueueJob( Set<Id> local ) {
        if ( local != null ) {
            ServiceAppointmentSyncQueueable.enqueueJob( new List<Id>( local ) );
        }
    }

    public static void enqueueJob( List<Id> local ) {
        if ( ( local != null )
            && ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() )
            )
        {
            System.enqueueJob( new ServiceAppointmentSyncQueueable( local ) );
        }
    }

    //
    // Queueable
    //

    private List<Id> serviceAppointmentIds = null;

    private ServiceAppointmentSyncQueueable( List<Id> local ) {
        if ( local != null ) {
            this.serviceAppointmentIds = local;
        }
    }

    public void execute( QueueableContext context ) {
        if ( this.serviceAppointmentIds != null ) {
            if ( !this.serviceAppointmentIds.isEmpty() ) {
                Id serviceAppointmentId = this.serviceAppointmentIds.remove( 0 ); // remove top serviceAppointmentId for each link in the queueable chain...
                this.syncServiceAppointment( serviceAppointmentId );
            }
            if ( !this.serviceAppointmentIds.isEmpty() ) {
                System.enqueueJob( new ServiceAppointmentSyncQueueable( this.serviceAppointmentIds ) ); // chain new queueable job for remaining serviceAppointmentIds...
            }
        }
    }

    private void syncServiceAppointment( Id serviceAppointmentId ) {
        try {
            ServiceAppointment record = this.selectServiceAppointment( serviceAppointmentId );
            WorkOrder newWorkOrder = this.populateWorkOrder( record );
            pse__Project_Task__c newProjectTask = this.populateProjectTask(
                record ,
                this.selectWorkOrder( record )
            );
            this.syncRecordOwnership( record );
            //
            if ( ( newWorkOrder != null ) && Schema.sObjectType.WorkOrder.isUpdateable() ) {
                List<Database.SaveResult> results = Database.update( new List<WorkOrder>{ newWorkOrder } , false );
                NSP_ErrorLogHandler.logResults(
                    ServiceAppointmentSyncQueueable.class.getName() ,
                    'syncServiceAppointment:WorkOrder' ,
                    results
                );
            }
            if ( ( newProjectTask != null ) && Schema.sObjectType.pse__Project_Task__c.isUpdateable() ) {
                List<Database.SaveResult> results = Database.update( new List<pse__Project_Task__c>{ newProjectTask } , false );
                NSP_ErrorLogHandler.logResults(
                    ServiceAppointmentSyncQueueable.class.getName() ,
                    'syncServiceAppointment:pse__Project_Task__c' ,
                    results
                );
            }
        } catch ( Exception e ) {
            ServiceAppointmentSyncQueueable.handleException( e , 'syncServiceAppointment' );
        }
    }

    // See: NSP_ServiceAppointmentTriggerHelper.syncProjTaskOwnerSA
    // ~ needs to be DEPRECATED and combined with previous DML on the exact same WorkOrder and pse__Project_Task__c records...
    private void syncRecordOwnership( ServiceAppointment record ) {
        // only process ServiceAppointment records with a parent WorkOrder record...
        if ( ( record != null ) && ( record.ParentRecordId != null ) ) {
            // build Map from ServiceAppointmentId to ServiceResourceId...
            Map<Id,Id> serviceAppointmentIdToServiceResourceIdMap = new Map<Id,Id>();
            AssignedResource recordAssignedResource = this.selectAssignedResource( record.Id );
            if ( recordAssignedResource != null ) {
                serviceAppointmentIdToServiceResourceIdMap.put(
                    recordAssignedResource.ServiceAppointmentId ,
                    recordAssignedResource.ServiceResourceId
                );
            }
            // build Map from ServiceResourceId to RelatedRecordId...
            Map<Id,Id> serviceResourceIdToRelatedRecordIdMap = new Map<Id,Id>();
            ServiceResource recordServiceResource = this.selectServiceResource( recordAssignedResource );
            if ( ( recordAssignedResource != null ) && ( recordServiceResource != null ) ) {
                serviceResourceIdToRelatedRecordIdMap.put(
                    recordAssignedResource.ServiceResourceId ,
                    recordServiceResource.RelatedRecordId
                );
            }
            // build Map from WorkOrderId to ServiceAppointment...
            Map<Id,ServiceAppointment> workOrderIdToServiceAppointmentMap = new Map<Id,ServiceAppointment>();
            workOrderIdToServiceAppointmentMap.put( record.ParentRecordId , record );
            //
            if ( !serviceAppointmentIdToServiceResourceIdMap.isEmpty() ) {
                //calling the method to syn the project task, workorder and service appointment ownerId
                // ~ needs to be DEPRECATED and combined with previous DML on the exact same WorkOrder and pse__Project_Task__c records...
                NSP_ServiceAppointmentTriggerHelper.syncProjTaskOwnerSA(
                    workOrderIdToServiceAppointmentMap ,
                    serviceAppointmentIdToServiceResourceIdMap ,
                    serviceResourceIdToRelatedRecordIdMap
                );
            }
        }
    }

    //
    //
    //

    // ServiceAppointment.ParentRecordId is-a polymorphic-Lookup
    // ~ Lookup( Work Order , Work Order Line Item , Account , Opportunity , Asset , Lead , Case , Product Service Campaign Item )
    private ServiceAppointment selectServiceAppointment( Id recordId ) {
        ServiceAppointment record = null;
        try {
            if ( recordId != null ) {
                List<ServiceAppointment> records = [
                    SELECT
                        Id ,
                        Status ,
                        Description ,
                        Subject ,
                        NSP_Orientation_Address__c ,
                        ServiceTerritoryId ,
                        ServiceTerritory.Name ,
                        ParentRecordId ,
                        ParentRecord.Name ,
                        EarliestStartTime ,
                        OwnerId ,
                        Duration ,
                        SchedStartTime ,
                        SchedEndTime,NSP_Meeting_Type__c
                    FROM ServiceAppointment
                    WHERE ( Id = :recordId )
                ];
                if ( ( records != null ) && !records.isEmpty() ) {
                    record = records[0];
                }
            }
        } catch ( Exception e ) {
            ServiceAppointmentSyncQueueable.handleException( e , 'selectServiceAppointment' );
        }
        return record;
    }

    private WorkOrder selectWorkOrder( ServiceAppointment child ) {
        WorkOrder record = null;
        if ( ( child != null ) && ( child.ParentRecordId != null ) ) {
            record = this.selectWorkOrder( child.ParentRecordId );
        }
        return record;
    }

    private WorkOrder selectWorkOrder( Id recordId ) {
        WorkOrder record = null;
        try {
            if ( recordId != null ) {
                List<WorkOrder> records = [
                    SELECT Id , NSP_Project_Task__c
                    FROM WorkOrder
                    WHERE ( Id = :recordId )
                    WITH SECURITY_ENFORCED
                ];
                if ( ( records != null ) && !records.isEmpty() ) {
                    record = records[0];
                }
            }
        } catch ( Exception e ) {
            ServiceAppointmentSyncQueueable.handleException( e , 'selectWorkOrder' );
        }
        return record;
    }

    private AssignedResource selectAssignedResource( Id serviceAppointmentId ) {
        AssignedResource record = null;
        try {
            if ( serviceAppointmentId != null ) {
                List<AssignedResource> records = [
                    SELECT Id , ServiceAppointmentId , ServiceResourceId
                    FROM AssignedResource
                    WHERE ( ServiceAppointmentId = :serviceAppointmentId )
                ];
                if ( ( records != null ) && !records.isEmpty() ) {
                    record = records[0];
                }
            }
        } catch ( Exception e ) {
            ServiceAppointmentSyncQueueable.handleException( e , 'selectAssignedResource' );
        }
        return record;
    }

    private ServiceResource selectServiceResource( AssignedResource recordAssignedResource ) {
        ServiceResource record = null;
        if ( recordAssignedResource != null ) {
            record = this.selectServiceResource( recordAssignedResource.ServiceResourceId );
        }
        return record;
    }

    private ServiceResource selectServiceResource( Id recordId ) {
        ServiceResource record = null;
        try {
            if ( recordId != null ) {
                List<ServiceResource> records = [
                    SELECT Id , RelatedRecordId
                    FROM ServiceResource
                    WHERE ( Id = :recordId )
                    WITH SECURITY_ENFORCED
                ];
                if ( ( records != null ) && !records.isEmpty() ) {
                    record = records[0];
                }
            }
        } catch ( Exception e ) {
            ServiceAppointmentSyncQueueable.handleException( e , 'selectServiceResource' );
        }
        return record;
    }

    //
    //
    //

    private WorkOrder populateWorkOrder( ServiceAppointment record ) {
        WorkOrder recordWorkOrder = null;
        if ( record != null ) {
            recordWorkOrder = this.populateWorkOrder(
                record.ParentRecordId ,
                record
            );
        }
        return recordWorkOrder;
    }

    private WorkOrder populateWorkOrder( Id workOrderId , ServiceAppointment record ) {
        WorkOrder recordWorkOrder = null;
        if ( ( workOrderId != null ) && ( record != null ) ) {
            recordWorkOrder = new WorkOrder();
            recordWorkOrder.Id = workOrderId;
            recordWorkOrder.Status = record.Status;
            recordWorkOrder.Description = record.Description;
            recordWorkOrder.Subject = record.Subject;
            recordWorkOrder.NSP_Meeting_Type__c = record.NSP_Meeting_Type__c;
            recordWorkOrder.NSP_Orientation_Address__c = record.NSP_Orientation_Address__c;
            recordWorkOrder.ServiceTerritoryId = record.ServiceTerritoryId;
            recordWorkOrder.Duration = record.Duration;
            recordWorkOrder.DurationType = 'Minutes';
            recordWorkOrder.StartDate = record.SchedStartTime;
            recordWorkOrder.EndDate = record.SchedEndTime;
        }
        return recordWorkOrder;
    }

    private pse__Project_Task__c populateProjectTask( ServiceAppointment record , WorkOrder parent ) {
        pse__Project_Task__c recordProjectTask = null;
        if ( ( parent != null ) && ( record != null ) ) {
            recordProjectTask = this.populateProjectTask(
                parent.NSP_Project_Task__c ,
                record ,
                ( ( record.ServiceTerritory != null ) ? record.ServiceTerritory.Name : '' )
            );
        }
        return recordProjectTask;
    }

    private pse__Project_Task__c populateProjectTask( Id projectTaskId , ServiceAppointment record , String serviceTerritoryName ) {
        pse__Project_Task__c recordProjectTask = null;
        if ( ( projectTaskId != null ) && ( record != null ) ) {
            recordProjectTask = new pse__Project_Task__c();
            recordProjectTask.Id = projectTaskId;
            recordProjectTask.pse__Status__c = record.Status;
            recordProjectTask.pse__Long_Description__c = record.Description;
            recordProjectTask.Name = record.Subject;
            recordProjectTask.NSP_Meeting_Type__c = record.NSP_Meeting_Type__c;
            recordProjectTask.NSP_Orientation_Address__c = record.NSP_Orientation_Address__c;
            recordProjectTask.NSP_Dispatch_Region__c = serviceTerritoryName;
            recordProjectTask.pse__Start_Date_Time__c = record.SchedStartTime;
            recordProjectTask.pse__End_Date_Time__c = record.SchedEndTime;
        }
        return recordProjectTask;
    }

    //
    //
    //

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            ServiceAppointmentSyncQueueable.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            ServiceAppointmentSyncQueueable.class.getName() ,
            methodName ,
            e
        );
    }

}
//