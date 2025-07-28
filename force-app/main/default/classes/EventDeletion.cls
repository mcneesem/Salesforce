//
// @description  :  Helper class for ServiceAppointment trigger.
// @date 07/28/2025
// Author : Ruchi
// Name : EventDeletion
//
public without sharing class EventDeletion {
// test w/ NSP_ServiceAppointmentTrigger_Test (80%)
    //
    // MethodName: deleteCancelledEvent
    // Description : delete evevt of cancelled SA
    // Params: Set<Id> saIdToDeletEvent
    //
    public static void deleteCancelledEvent( Set<Id> saIdToDeletEvent ) {
        try {
            if ( ( saIdToDeletEvent != null ) && !saIdToDeletEvent.isEmpty() ) {
                List<Event> eventRecListDelete = new List<Event>();
                for ( Event eachEvent : [
                    SELECT Id , WhatId
                    FROM Event
                    WHERE ( WhatId IN :saIdToDeletEvent )
                ]
                    )
                {
                    eachEvent.WhatId = null;
                    eventRecListDelete.add( eachEvent );
                }
                if( !eventRecListDelete.isEmpty() ) {
                    List<Database.SaveResult> results =  Database.update( eventRecListDelete , false );
                    NSP_ErrorLogHandler.logResults(
                        EventDeletion.class.getName() , 
                        'deleteCancelledEvent:update' ,
                        results
                    );
                    List<Database.DeleteResult> results1 = Database.delete( eventRecListDelete ,false); 
                    NSP_ErrorLogHandler.logResults(
                        EventDeletion.class.getName() , 
                        'deleteCancelledEvent:delete' ,
                        results1
                    );
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                EventDeletion.class.getName() , 
                'deleteCancelledEvent' ,
                e
            );
        }
    }
}