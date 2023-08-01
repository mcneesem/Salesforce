({
    doInit : function(component, event, helper) {
        //get current user Id
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        var action = component.get("c.isUserPermittedToCreateProject");
        action.setParams({ currentUserId : userId });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                component.set("v.userInfo", storeResponse);
                 //Check if current user is allowed to create Project Record 
                if( component.get("v.userInfo") == true){
                    //call createRecord method
                    helper.showCreateRecordScreen(component, event, helper);
                }
                else{
                    //show error if non admin user
                    helper.showError();
                    helper.navigateBackToList(component, event);
                    }
                }
            });
            $A.enqueueAction(action);
    },

    onPageReferenceChanged: function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
    }
})