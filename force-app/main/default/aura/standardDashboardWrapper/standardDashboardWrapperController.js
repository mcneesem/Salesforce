({
    doInit: function(component, event, helper) {
        var action = component.get('c.getDashboardSettings');
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var settings  = response.getReturnValue();
                var field     = component.get('v.dashboardField');
                var dashName  = settings[field];

                if (!dashName) {
                    component.set('v.isLoading', false);
                    component.set('v.isError', true);
                    return;
                }

                $A.createComponent(
                    'desktopDashboards:embeddedDashboard',
                    {
                        dashboardName : dashName,
                        height        : '1000',
                        hideOnError   : true
                    },
                    function(dashboardCmp, status, errorMessage) {
                        component.set('v.isLoading', false);
                        if (status === 'SUCCESS') {
                            var mount = component.find('dashboardMount');
                            mount.set('v.body', [dashboardCmp]);
                        } else {
                            component.set('v.isError', true);
                        }
                    }
                );
            } else {
                component.set('v.isLoading', false);
                component.set('v.isError', true);
            }
        });
        $A.enqueueAction(action);
    }
})
