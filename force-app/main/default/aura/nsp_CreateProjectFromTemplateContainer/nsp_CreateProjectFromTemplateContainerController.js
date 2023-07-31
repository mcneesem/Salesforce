({
    closeQuickAction : function(cmp){
        $A.get("e.force:closeQuickAction").fire();
    },
    navigateToRecord : function(cmp,event){
        let recordId = event.getParams().id;
        let navService = cmp.find("navService");
        navService.navigate({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }
})