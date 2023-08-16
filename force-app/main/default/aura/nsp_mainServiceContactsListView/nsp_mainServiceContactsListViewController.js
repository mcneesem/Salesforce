({
    doInit : function(component, event, helper) {
        
        let ref = component.get('v.pageReference');    
        
        //Am traversing down the object to fetch the data
        let recordId = ref.state.c__recordId;
        let fullView = ref.state.c__fullView;
        
        //Assigning the data back to an attribute
        component.set( 'v.recordId', recordId);
        component.set( 'v.fullView', fullView);
    }
})