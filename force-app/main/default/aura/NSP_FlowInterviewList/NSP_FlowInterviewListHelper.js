({
    populateTable : function(component, event, helper) {
        var action = component.get("c.getInterviews");
        action.setParams({
            recordId: component.get("v.recordId")
        });
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Push interviews fetched by the Apex controller to the component
                var recordRelations = response.getReturnValue();
                var interviews = [];
                for (var i = 0; i < recordRelations.length; i++) {
                    interviews.push(
                        {
                            Id: recordRelations[i].ParentId,
                            InterviewLabel: recordRelations[i].Parent.InterviewLabel,
                            PauseLabel: recordRelations[i].Parent.PauseLabel,
                            CurrentElement: recordRelations[i].Parent.CurrentElement,
                            PausedDate: recordRelations[i].Parent.CreatedDate,
                            PausedBy: recordRelations[i].Parent.Owner.Name
                        });
                }
                component.set('v.Interviews', interviews);
            } 
        }));
        $A.enqueueAction(action);
    },
    
    handleShowModal: function (component, id) {
        // On resume, render the interview in a modal
        $A.createComponent("lightning:flow", {"onstatuschange": component.get("c.statusChange")},
            function (content, status) {
                if (status === "SUCCESS") {
                    component.find('overlayLib').showCustomModal({
                        body: content,
                        showCloseButton: true,
                        closeCallback: function () {
                            $A.get('e.force:refreshView').fire();
                        }
                    }).then(function(overlay) {
                        // Use to close the modal later
                        component.set("v.overlay", overlay);
                    });
                    content.resumeFlow(id);
                }
            });
    },
    
        handleResume: function (component, id) {
            var flow = component.find("flowData");
          // If an interview ID was returned, resume it in the component
          // whose aura:id is "flowData".
          if ( id !== null ) { 
             flow.resumeFlow(id);
          }
    },
    
    handleDelete: function (component, event, helper, id) {
        // On delete, pass the interview ID to the Apex controller        
        var action = component.get("c.deleteInterview");
        action.setParams({
            interviewId: id
        });
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Automatically refresh the table
                helper.populateTable(component, event, helper);
            } 
        }));
        $A.enqueueAction(action);
    }
})