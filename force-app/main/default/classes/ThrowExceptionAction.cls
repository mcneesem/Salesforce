public with sharing class ThrowExceptionAction {
    // test w/ ThrowExceptionActionTest (82%)
    private static final String CLASS_NAME = ' ~ ThrowExceptionAction';

    @InvocableMethod(label='Throw Exception')
    public static void throwAction( List<Request> requests ) {
        String METHOD_NAME = 'throwAction';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        Boolean isFuture = False;
        if ( requests != null ) {
            for ( Request r : requests ) {
                System.debug( DEBUG_PREFIX + ' ~ r=' + r );
                if ( r.isFuture != null ) {
                    isFuture = r.isFuture;
                }
            }
        }
        System.debug( DEBUG_PREFIX + ' ~ isFuture=' + isFuture );
        if ( isFuture ) {
            ThrowExceptionAction.throwFuture();
        } else {
            ThrowExceptionAction.throwNow();
        }
    }

    public class Request {
        @InvocableVariable(label='Is Future')
        public Boolean isFuture;
    }

    //
    //
    //

    @future public static void throwFuture() {
        ThrowExceptionAction.throwNow();
    }

    public static void throwNow() {
        //ThrowExceptionAction.throwQueryException();
        ThrowExceptionAction.throwCustomException();
    }

    //private static void throwQueryException() {
    //    // FATAL_ERROR System.QueryException: List has no rows for assignment to SObject
    //    Lead record = [
    //        SELECT Id
    //        FROM Lead
    //        WHERE (
    //            ( Name = 'TEST' )
    //            AND ( Name != 'TEST' )
    //        )
    //    ];
    //}

    private static void throwCustomException() {
        // FATAL_ERROR ThrowExceptionAction.CustomException: TEST
        throw new CustomException( 'TEST' );
    }

    private class CustomException extends Exception {}

}
//