({
    setGuidanceMessages : function ( component ) {
        component.set( "v.guidanceMessage" , "" );
        let opportunityRecord = component.get( "v.opportunityRecord" );
        if ( opportunityRecord ) {
            if ( opportunityRecord.hasOwnProperty( "StageName" )
                && opportunityRecord.hasOwnProperty( "NSP_PrimaryProduct__c" )
                )
            {
                let product = opportunityRecord.NSP_PrimaryProduct__c;
                let segment = "";
                if ( ( product == "WX" )
                    && opportunityRecord.NSP_Account_Segment__c
                    && ( ( opportunityRecord.NSP_Account_Segment__c == "MidMarket" )
                        || ( opportunityRecord.NSP_Account_Segment__c == "Enterprise" )
                        )
                    )
                {
                    segment = "MidMarket";
                }
                let action = component.get( "c.getMessage" );
                action.setParams({
                    stageName : opportunityRecord.StageName ,
                    primaryProduct : opportunityRecord.NSP_PrimaryProduct__c ,
                    accountSegment : segment
                });
                action.setCallback( this , function ( response ) {
                    let state = response.getState();
                    if ( state === "SUCCESS" ) {
                        component.set( "v.guidanceMessage" , response.getReturnValue() );
                    }
                });
                $A.enqueueAction( action );
            }
        }
    }
})