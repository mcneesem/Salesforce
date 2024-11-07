({
    onInit : function( component , event , helper ) {
        console.log( 'VerifyPlatformEvents.onInit' );
        // setup an empApi error handler on component initialization
        // get the empApi component...
        const empApi = component.find( 'empApi' );
        if ( empApi ) {
            // confirm if emp is enabled...
            empApi.isEmpEnabled().then( response => {
                console.log( 'VerifyPlatformEvents: isEmpEnabled: ' + response );
            });
            // enable debug logging (optional)...
            empApi.setDebugFlag( true );
            // register error listener and pass in the error handler function...
            empApi.onError( $A.getCallback( error => {
                console.log( 'VerifyPlatformEvents.empApi.onError.callback' );
                // error can be any type of error (subscribe, unsubscribe...)...
                console.error( error );
                console.error( 'VerifyPlatformEvents: EMP API Error: ' + JSON.stringify( error ) );
            }));
        } else {
            console.log( 'VerifyPlatformEvents.onInit ~ empApi not found.' );
        }
    } ,
    subscribe : function( component , event , helper ) {
        // invokes the subscribe method on the empApi component...
        console.log( 'VerifyPlatformEvents.subscribe' );
        // get the empApi component...
        const empApi = component.find( 'empApi' );
        if ( empApi ) {
            // get the channel from the component variable...
            const channel = component.get( 'v.channel' );
            // replay option to get new events only (-1)...
            const replayId = component.get( 'v.replayId' );
            console.log( channel );
            console.log( replayId );
            // subscribe to an event channel...
            empApi.subscribe( channel , replayId , $A.getCallback( eventReceived => {
                console.log( 'VerifyPlatformEvents.empApi.subscribe.callback' );
                // process event (this is called each time we receive an event)...
                console.log( eventReceived );
                console.log( 'VerifyPlatformEvents: Received Event (' + channel + '@' + replayId + '): ' + JSON.stringify( eventReceived ) );
            })).then( subscription => {
                console.log( 'VerifyPlatformEvents.empApi.subscribe.then' );
                // subscription response received...
                // we haven't received an event yet...
                console.log( 'VerifyPlatformEvents: Subscription Requested: ' + subscription.channel );
                // Save subscription to unsubscribe later
                component.set( 'v.subscription' , subscription );
            });
        } else {
            console.log( 'VerifyPlatformEvents.subscribe ~ empApi not found.' );
        }
    } ,
    unsubscribe : function( component , event , helper ) {
        // invokes the unsubscribe method on the empApi component...
        console.log( 'VerifyPlatformEvents.unsubscribe' );
        // get the empApi component...
        const empApi = component.find( 'empApi' );
        if ( empApi ) {
            // get the subscription promise that we saved after subscribing...
            const subscription = component.get( 'v.subscription' );
            // unsubscribe from event...
            empApi.unsubscribe( subscription , $A.getCallback( unsubscribed => {
                console.log( 'VerifyPlatformEvents.empApi.unsubscribe.callback' );
                // Confirm that we have unsubscribed from the event channel
                console.log( unsubscribed );
                console.log( 'VerifyPlatformEvents: Unsubscribed Channel: '+ unsubscribed.subscription);
                component.set( 'v.subscription' , null );
            }));
        } else {
            console.log( 'VerifyPlatformEvents.unsubscribe ~ empApi not found.' );
        }
    } ,
    reset : function( component , event , helper ) {
        console.log( 'VerifyPlatformEvents.reset' );
        component.set( 'v.subscription' , null );
        component.set( 'v.channel' , '/event/One_Time_Sync_Event__e' );
        component.set( 'v.replayId' , -1 );
    }
})