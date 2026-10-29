({
    doInit: function(component, event, helper) {
        const action = component.get('c.getDashboardSettings');
        action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === 'SUCCESS') {
                const settings  = response.getReturnValue();
                const field     = component.get('v.dashboardField');
                const dashName  = settings[field];

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
                            const mount = component.find('dashboardMount');
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
